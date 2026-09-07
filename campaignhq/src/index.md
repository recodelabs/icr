---
title: Campaign calendar
sql:
  campaigns: data/campaigns.parquet
  admin_units: data/admin_units.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Campaign calendar

What is planned, running and done, where — from the Integrated Campaign Registry.
Every row is one campaign round in one geography (a CarePlan), flattened by the IG's
`IcrCampaignCalendar` view and joined to the location registry. Filter, then read the
map, the timeline and the table together.

```js
import {campaignMap, syncMaps, DEFAULT_BASEMAP} from "./components/map.js";

// Basemap under the choropleth. DEFAULT_BASEMAP is OpenStreetMap as a placeholder;
// replace with your tile layer, e.g. {tiles: ["https://…/{z}/{x}/{y}.png"], attribution: "…"}
// or a vector style URL "https://…/style.json". `false` draws boundaries only.
const BASEMAP = DEFAULT_BASEMAP;

// ---- helpers -------------------------------------------------------------
const toRows = (table) => Array.from(table, (r) => {
  const o = typeof r.toJSON === "function" ? r.toJSON() : {...r};
  for (const k in o) if (typeof o[k] === "bigint") o[k] = Number(o[k]);
  return o;
});
const fmtInt = (n) => n == null ? "—" : Math.round(Number(n)).toLocaleString("en");
const fmtDate = (d) => d == null ? "" : new Date(d).toISOString().slice(0, 10);
const today = new Date();
```

```js
// ---- dimension values for the filters --------------------------------------
const years = toRows(await sql`SELECT DISTINCT year FROM campaigns WHERE level = 'lga' ORDER BY year`).map((d) => d.year);
const states = toRows(await sql`SELECT DISTINCT state FROM campaigns WHERE level = 'lga' AND state IS NOT NULL ORDER BY state`).map((d) => d.state);
const programmes = toRows(await sql`SELECT programme, count(*) n FROM campaigns WHERE level = 'lga' GROUP BY 1 ORDER BY 2 DESC`).map((d) => d.programme);
const statuses = ["completed", "active", "draft"];
```

<div class="grid grid-cols-4" style="gap: 12px; margin-bottom: 8px">
  <div>${yearInput}</div>
  <div>${stateInput}</div>
  <div>${programmeInput}</div>
  <div>${statusInput}</div>
</div>

```js
const yearInput = Inputs.select(["All", ...years], {label: "Year", value: 2026, format: (d) => String(d)});
const year = Generators.input(yearInput);
const stateInput = Inputs.select(["All", ...states], {label: "State", value: "All"});
const state = Generators.input(stateInput);
const programmeInput = Inputs.select(["All", ...programmes], {label: "Programme", value: "All"});
const programme = Generators.input(programmeInput);
const statusInput = Inputs.select(["All", ...statuses], {label: "Status", value: "All", format: (s) => s === "draft" ? "planned (draft)" : s});
const status = Generators.input(statusInput);
```

```js
// ---- the filtered rows (LGA level drives map, KPIs and table; state level drives the timeline)
const where = [
  year === "All" ? "TRUE" : `year = ${Number(year)}`,
  state === "All" ? "TRUE" : `state = '${String(state).replace(/'/g, "''")}'`,
  programme === "All" ? "TRUE" : `programme = '${String(programme).replace(/'/g, "''")}'`,
  status === "All" ? "TRUE" : `status = '${status}'`
].join(" AND ");
const lgaRows = toRows(await sql([`SELECT * FROM campaigns WHERE level = 'lga' AND ${where} ORDER BY period_start, state, location_name`]));
const stateRows = toRows(await sql([`SELECT * FROM campaigns WHERE level = 'state' AND country = 'NGA' AND ${where} ORDER BY period_start`]));
```

```js
const kpi = {
  rounds: lgaRows.length,
  lgas: new Set(lgaRows.map((d) => d.location_id)).size,
  targeted: lgaRows.reduce((s, d) => s + (d.targeted ?? 0), 0),
  active: lgaRows.filter((d) => d.status === "active").length,
  planned: lgaRows.filter((d) => d.status === "draft").length,
  programmes: new Set(lgaRows.map((d) => d.programme)).size
};
```

<div class="grid grid-cols-4" style="gap: 12px">
  <div class="card"><h2>Campaign rounds</h2><span class="big">${fmtInt(kpi.rounds)}</span><div class="muted">LGA-level rounds in selection</div></div>
  <div class="card"><h2>LGAs covered</h2><span class="big">${fmtInt(kpi.lgas)}</span><div class="muted">across ${kpi.programmes} programme${kpi.programmes === 1 ? "" : "s"}</div></div>
  <div class="card"><h2>People targeted</h2><span class="big">${fmtInt(kpi.targeted)}</span><div class="muted">sum of planning denominators</div></div>
  <div class="card"><h2>People reached</h2><span class="big muted">—</span><div class="muted">delivery data not yet loaded</div></div>
</div>

<div class="grid grid-cols-2" style="gap: 12px; margin-top: 12px">
  <div class="card" style="padding: 0; overflow: hidden">
    <div class="map-title">Campaign rounds per LGA</div>
    ${mapEl}
  </div>
  <div class="card" style="padding: 0; overflow: hidden">
    <div class="map-title">People targeted per LGA</div>
    ${mapTargeted}
  </div>
</div>

<div class="card" style="margin-top: 12px">
  <h2>Rounds over time, by state</h2>
  <div class="muted" style="margin-bottom: 6px">One bar per state round, coloured by programme; overlapping bars are programmes in the same state at the same time. The red dotted line is today.</div>
  ${timeline}
</div>

```js
const pmtiles = await FileAttachment("data/admin.pmtiles").arrayBuffer();
const stateLabels = toRows(await sql`SELECT id, name, lon, lat FROM admin_units WHERE admin_level = 1 AND country = 'NGA'`);
const mapEl = campaignMap({pmtiles, height: 480, basemap: BASEMAP, labels: stateLabels, metric: "count"});
const mapTargeted = campaignMap({pmtiles, height: 480, basemap: BASEMAP, labels: stateLabels, metric: "targeted"});
syncMaps(mapEl, mapTargeted);
```

```js
// Reactive: push the current selection into both maps' feature-state.
mapEl.update(lgaRows);
mapTargeted.update(lgaRows);
```

```js
const laneStates = states.filter((s) => stateRows.some((d) => d.state === s));
const timeline = Plot.plot({
  height: 60 + 46 * Math.max(1, laneStates.length),
  marginLeft: 70,
  marginRight: 20,
  x: {type: "utc", label: null, grid: true},
  y: {label: null, domain: laneStates},
  color: {legend: true, domain: programmes},
  marks: [
    Plot.barX(stateRows, {
      x1: "period_start", x2: "period_end", y: "state", fill: "programme", fillOpacity: 0.75,
      insetTop: 6, insetBottom: 6, rx: 2, stroke: "white", strokeWidth: 0.5,
      tip: true,
      title: (d) => `${d.title}\n${fmtDate(d.period_start)} → ${fmtDate(d.period_end)} · ${d.status === "draft" ? "planned" : d.status}\npeople targeted: ${fmtInt(d.targeted)}`
    }),
    Plot.ruleX([today], {stroke: "#ef4444", strokeDasharray: "3,3"})
  ]
});
```

## Campaign rounds

```js
const search = view(Inputs.search(lgaRows, {placeholder: "Search title, LGA, state…", columns: ["title", "location_name", "state", "programme"]}));
```

```js
Inputs.table(search, {
  columns: ["period_start", "period_end", "programme", "state", "location_name", "status", "round", "targeted", "title"],
  header: {period_start: "Start", period_end: "End", programme: "Programme", state: "State", location_name: "LGA", status: "Status", round: "Round", targeted: "Targeted", title: "Campaign"},
  format: {
    period_start: fmtDate, period_end: fmtDate,
    targeted: (d) => fmtInt(d),
    status: (s) => s === "draft" ? "planned" : s
  },
  width: {period_start: 90, period_end: 90, programme: 170, state: 70, location_name: 120, status: 80, round: 50, targeted: 90},
  sort: "period_start", reverse: false,
  rows: 18
})
```

<div class="muted" style="margin-top: 8px">
  ${fmtInt(search.length)} of ${fmtInt(lgaRows.length)} rounds shown. Status is derived from the registry as of the last refresh:
  <em>completed</em> ended before the refresh date, <em>active</em> spans it, <em>planned</em> starts after it.
  People targeted is the campaign's planning denominator (an ICRTargetPopulation Group); people reached will come
  from delivery events once they are loaded.
</div>

<style>
.big { font-size: 28px; font-weight: 600; line-height: 1.1; }
.map-title { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); padding: 10px 14px 6px; }
.card h2 { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); margin: 0 0 4px; }
.maplibregl-popup-content { padding: 6px 9px; }
</style>
