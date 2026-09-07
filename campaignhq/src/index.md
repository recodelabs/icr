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
  <div style="display:flex; justify-content:space-between; align-items:baseline; gap:12px; flex-wrap:wrap">
    <div>
      <h2>Rounds over time</h2>
      <div class="muted" style="margin-bottom: 6px">${timelineMode === "By state"
        ? "One bar per state round, coloured by programme; overlapping bars are programmes in the same state at the same time."
        : "One lane per LGA, grouped by state — click a state to collapse or expand it."} The red dotted line is today.</div>
    </div>
    <div>${timelineModeInput}</div>
  </div>
  ${timelineEl}
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
const timelineModeInput = Inputs.radio(["By state", "By LGA"], {value: "By state"});
const timelineMode = Generators.input(timelineModeInput);
```

```js
const laneStates = states.filter((s) => stateRows.some((d) => d.state === s));
// One shared time axis for every chart so the LGA blocks line up with each other.
const allRows = [...stateRows, ...lgaRows];
const pad = 7 * 864e5;
const xDomain = allRows.length
  ? [new Date(Math.min(...allRows.map((d) => +new Date(d.period_start))) - pad), new Date(Math.max(...allRows.map((d) => +new Date(d.period_end))) + pad)]
  : [new Date(`${year === "All" ? 2022 : year}-01-01`), new Date(`${year === "All" ? 2027 : year}-12-31`)];
const barTitle = (d) => `${d.title}\n${fmtDate(d.period_start)} → ${fmtDate(d.period_end)} · ${d.status === "draft" ? "planned" : d.status}\npeople targeted: ${fmtInt(d.targeted)}`;

const timeline = Plot.plot({
  width,  // Framework's reactive main-column width: fill the card, re-render on resize
  height: 60 + 46 * Math.max(1, laneStates.length),
  marginLeft: 70,
  marginRight: 20,
  x: {type: "utc", label: null, grid: true, domain: xDomain},
  y: {label: null, domain: laneStates},
  color: {legend: true, domain: programmes},
  marks: [
    Plot.barX(stateRows, {
      x1: "period_start", x2: "period_end", y: "state", fill: "programme", fillOpacity: 0.75,
      insetTop: 6, insetBottom: 6, rx: 2, stroke: "white", strokeWidth: 0.5,
      tip: true, title: barTitle
    }),
    Plot.ruleX([today], {stroke: "#ef4444", strokeDasharray: "3,3"})
  ]
});

// LGA view: one chart per state (own lane list), inside a native <details> so each
// state collapses independently. Same width, margins and x domain as the state view.
function lgaTimeline(stateName) {
  const rows = lgaRows.filter((d) => d.state === stateName);
  const lanes = [...new Set(rows.map((d) => d.location_name))].sort((a, b) => a.localeCompare(b));
  return Plot.plot({
    width,
    height: 34 + 16 * lanes.length,
    marginLeft: 110, marginRight: 20, marginTop: 4, marginBottom: 26,
    x: {type: "utc", label: null, grid: true, domain: xDomain},
    y: {label: null, domain: lanes, tickSize: 0},
    color: {domain: programmes},
    marks: [
      Plot.barX(rows, {
        x1: "period_start", x2: "period_end", y: "location_name", fill: "programme", fillOpacity: 0.85,
        insetTop: 2, insetBottom: 2, rx: 1.5, tip: true, title: barTitle
      }),
      Plot.ruleX([today], {stroke: "#ef4444", strokeDasharray: "3,3"})
    ]
  });
}

const timelineEl = timelineMode === "By state"
  ? timeline
  : html`<div>
      ${Plot.legend({color: {domain: programmes}})}
      ${laneStates.map((st) => {
        const n = lgaRows.filter((d) => d.state === st).length;
        const lgas = new Set(lgaRows.filter((d) => d.state === st).map((d) => d.location_id)).size;
        return html`<details class="tl-state" open>
          <summary><span>${st}</span><span class="muted">${fmtInt(n)} rounds · ${lgas} LGA${lgas === 1 ? "" : "s"}</span></summary>
          ${lgaTimeline(st)}
        </details>`;
      })}
    </div>`;
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
.tl-state { border-top: 1px solid var(--theme-foreground-faintest); padding: 6px 0 2px; }
.tl-state > summary { cursor: pointer; display: flex; justify-content: space-between; align-items: baseline; font-weight: 500; padding: 4px 0; list-style: none; }
.tl-state > summary::before { content: "▾"; display: inline-block; width: 1.2em; color: var(--theme-foreground-muted); }
.tl-state:not([open]) > summary::before { content: "▸"; }
.tl-state > summary > span:first-child { flex: 1; }
.card h2 { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); margin: 0 0 4px; }
.maplibregl-popup-content { padding: 6px 9px; }
</style>
