---
title: Microplan — NIPDs, Toro LGA
sql:
  visits: data/microplan.parquet
  admin_units: data/admin_units.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

<div class="title-row">
  <h1 style="margin: 0">Microplan — National Immunization Plus Days (NIPDs), Toro LGA</h1>
  <div class="card round-card">
    <div class="round-cell"><div class="round-big">Day 3 <span class="round-of">of 5</span></div><div class="muted">as of end of day, Tue 9 Sep 2026</div></div>
    <div class="round-cell"><div class="round-big">7–11 Sep 2026</div><div class="muted">nOPV2 round 2 · house-to-house · Toro LGA, Bauchi</div></div>
  </div>
</div>

```js
import {microplanMap, STATUS, METRICS, CATCHMENT_METRICS, COVERAGE_BREAKS, COVERAGE_COLORS} from "./components/microplan-map.js";
import {DEFAULT_BASEMAP} from "./components/map.js";
import {checkboxSelect} from "./components/filters.js";
const BASEMAP = DEFAULT_BASEMAP;
const toRows = (table) => Array.from(table, (r) => {
  const o = typeof r.toJSON === "function" ? r.toJSON() : {...r};
  for (const k in o) if (typeof o[k] === "bigint") o[k] = Number(o[k]);
  return o;
});
const fmtInt = (n) => n == null ? "—" : Math.round(Number(n)).toLocaleString("en");
const fmtPct = (x) => x == null ? "—" : `${Math.round(x * 100)}%`;
const STATUS_LABEL = Object.fromEntries(STATUS.map(([v, l]) => [v, l]));
const STATUS_COLOR = Object.fromEntries(STATUS.map(([v, , c]) => [v, c]));
const DAYS = ["2026-09-07", "2026-09-08", "2026-09-09", "2026-09-10", "2026-09-11"];
const AS_OF = "2026-09-09";
const dayN = (d) => DAYS.indexOf(String(d).slice(0, 10)) + 1;
```

```js
// DuckDB-WASM hands a DATE column back as a JS Date (midnight UTC); keep the calendar day as text.
const isoDay = (d) => d instanceof Date ? d.toISOString().slice(0, 10) : String(d).slice(0, 10);
const all = toRows(await sql`SELECT * FROM visits`).map((r) => ({
  ...r, day: isoDay(r.day), day_n: dayN(isoDay(r.day)),
  coverage: r.status === "completed" && r.u5 > 0 ? r.treated / r.u5 : null
}));
const facilityNames = Array.from(new Set(all.map((d) => d.facility))).filter(Boolean).sort();
const toro = toRows(await sql`SELECT name, admin1_name, xmin, ymin, xmax, ymax FROM admin_units WHERE admin_level = 2 AND name = 'Toro' AND admin1_name = 'Bauchi'`)[0];
const LGA = {name: toro.name, admin1_name: toro.admin1_name, bounds: [[toro.xmin, toro.ymin], [toro.xmax, toro.ymax]]};
```

<div class="grid grid-cols-2" style="gap: 12px; margin-bottom: 8px">
  <div>${facilityInput}</div>
  <div>${statusInput}</div>
</div>

```js
const facilityInput = Inputs.select(["All", ...facilityNames], {label: "Facility catchment", value: "All"});
const facility = Generators.input(facilityInput);
const statusInput = checkboxSelect(STATUS.map(([v]) => v), {label: "Settlement status", format: (v) => STATUS_LABEL[v], emptyLabel: "All statuses"});
const statusPicked = Generators.input(statusInput);
const metricInput = Inputs.select(Object.keys(METRICS), {label: "Settlements", value: "status", format: (k) => METRICS[k].label});
const metric = Generators.input(metricInput);
const catchmentInput = Inputs.select(Object.keys(CATCHMENT_METRICS), {label: "Facility catchment fill", value: "progress", format: (k) => CATCHMENT_METRICS[k].label});
const catchmentMetric = Generators.input(catchmentInput);
```

```js
// The selection: one facility catchment or the whole LGA; the status filter narrows the map and the settlement table only.
const inFacility = facility === "All" ? all : all.filter((d) => d.facility === facility);
const statusSet = new Set(statusPicked);
const rows = statusSet.size ? inFacility.filter((d) => statusSet.has(d.status)) : inFacility;
const scope = facility === "All" ? "Toro LGA" : `${facility} catchment`;

function facilityRollup(list) {
  const m = new Map();
  for (const d of list) {
    let g = m.get(d.facility_id);
    if (!g) { g = {facility_id: d.facility_id, facility: d.facility, facility_level: d.facility_level, facility_lon: d.facility_lon, facility_lat: d.facility_lat, catchment_id: d.catchment_id,
                   visits: 0, planned: 0, fieldRegistered: 0, completed: 0, inProgress: 0, pending: 0, u5: 0, worldpop: 0, u5Completed: 0, treated: 0, houses: 0, below80: 0, lons: [], lats: []}; m.set(d.facility_id, g); }
    g.visits += 1;
    if (d.origin === "field-registered") g.fieldRegistered += 1; else g.planned += 1;
    if (d.status === "completed") g.completed += 1; else if (d.status === "in-progress") g.inProgress += 1; else g.pending += 1;
    g.u5 += d.u5 ?? 0;
    g.worldpop += d.worldpop ?? 0;
    if (d.status === "completed") { g.treated += d.treated ?? 0; g.houses += d.houses ?? 0; g.u5Completed += d.u5 ?? 0; if (d.coverage != null && d.coverage < 0.8) g.below80 += 1; }
    if (d.lon != null) { g.lons.push(d.lon); g.lats.push(d.lat); }
  }
  return Array.from(m.values()).map((g) => ({
    ...g, progress: g.visits ? g.completed / g.visits : null,
    coverage: g.u5Completed > 0 ? g.treated / g.u5Completed : null,
    bounds: g.lons.length ? [[Math.min(...g.lons, g.facility_lon), Math.min(...g.lats, g.facility_lat)], [Math.max(...g.lons, g.facility_lon), Math.max(...g.lats, g.facility_lat)]] : null
  })).sort((a, b) => a.facility.localeCompare(b.facility));
}
const facilities = facilityRollup(all);
const facilitiesShown = facility === "All" ? facilities : facilities.filter((f) => f.facility === facility);
```

```js
const done = inFacility.filter((d) => d.status === "completed");
const donePlanned = done.filter((d) => d.u5 > 0);
const kpi = {
  settlements: inFacility.length,
  planned: inFacility.filter((d) => d.origin === "pre-planned").length,
  found: inFacility.filter((d) => d.origin === "field-registered").length,
  u5: d3.sum(inFacility, (d) => d.u5 ?? 0),
  teams: new Set(inFacility.map((d) => d.facility_id)).size,
  completed: done.length,
  inProgress: inFacility.filter((d) => d.status === "in-progress").length,
  pending: inFacility.filter((d) => d.status === "requested").length,
  treated: d3.sum(done, (d) => d.treated ?? 0),
  u5Done: d3.sum(donePlanned, (d) => d.u5),
  below80: donePlanned.filter((d) => d.coverage < 0.8).length,
  houses: d3.sum(done, (d) => d.houses ?? 0)
};
kpi.progress = kpi.settlements ? kpi.completed / kpi.settlements : null;
kpi.coverage = kpi.u5Done > 0 ? d3.sum(donePlanned, (d) => d.treated) / kpi.u5Done : null;
const red = (t) => html`<span style="color:#b91c1c">${t}</span>`;
```

<div class="grid" style="gap: 12px; grid-template-columns: repeat(6, minmax(0, 1fr))">
  <div class="card kpi-plan"><h2>Settlements to visit</h2><span class="big">${fmtInt(kpi.settlements)}</span><div class="muted">${scope}</div></div>
  <div class="card kpi-plan"><h2>Children 0–59 months targeted</h2><span class="big">${fmtInt(kpi.u5)}</span><div class="muted">WorldPop 2026 under-5 population</div></div>
  <div class="card kpi-plan"><h2>Vaccination teams</h2><span class="big">${fmtInt(kpi.teams)}</span><div class="muted">one per facility catchment</div></div>
  <div class="card kpi-mon"><h2>Settlements completed</h2><span class="big">${fmtInt(kpi.completed)}<span class="muted" style="font-size:16px"> · ${fmtPct(kpi.progress)}</span></span><div class="muted">${fmtInt(kpi.inProgress)} in progress · ${fmtInt(kpi.pending)} pending</div></div>
  <div class="card kpi-mon"><h2>Children vaccinated</h2><span class="big">${fmtInt(kpi.treated)}</span><div class="muted">${fmtInt(kpi.houses)} houses visited</div></div>
  <div class="card kpi-mon"><h2>Coverage, completed settlements</h2><span class="big">${fmtPct(kpi.coverage)}</span><div class="muted">${kpi.below80 ? red(`${fmtInt(kpi.below80)} settlements below 80%`) : "none below 80%"} · revisit candidates</div></div>
</div>

<div class="grid grid-cols-3" style="gap: 12px; margin-top: 12px; grid-template-columns: 2fr 1fr">
  <div class="card" style="padding: 0; overflow: hidden">
    <div class="map-controls">
      <div class="map-title" style="padding: 0; flex: 1">${scope}${statusSet.size ? ` · ${statusPicked.map((v) => STATUS_LABEL[v]).join(", ")}` : ""}</div>
      <div>${metricInput}</div>
      <div>${catchmentInput}</div>
    </div>
    ${mapEl}
  </div>
  <div style="display:flex; flex-direction:column; gap: 12px">
    <div class="card">
      <h2>Houses visited by day, ${scope}</h2>
      ${dayChart}
    </div>
    <div class="card" style="flex: 1">
      <h2>Selected</h2>
      ${inspector}
    </div>
  </div>
</div>

```js
const urls = {admin: FileAttachment("data/admin.pmtiles").href, catchments: FileAttachment("data/catchments.pmtiles").href};
const mapEl = microplanMap({urls, lga: LGA, height: 640, basemap: BASEMAP});
const selected = Generators.input(mapEl);
```

```js
mapEl.update(rows, facilitiesShown);
mapEl.setMetric(metric);
mapEl.setCatchmentMetric(catchmentMetric);
```

```js
{
  const f = facility === "All" ? null : facilities.find((d) => d.facility === facility);
  mapEl.fit(f?.bounds ?? LGA.bounds);
}
```

```js
// Houses visited per day of the round, from the completed visits' tallies.
const houseRows = DAYS.map((day, i) => {
  const visits = inFacility.filter((d) => d.day === day && d.status === "completed");
  return {day: `Day ${i + 1}`, date: day, houses: d3.sum(visits, (d) => d.houses ?? 0), visits: visits.length, treated: d3.sum(visits, (d) => d.treated ?? 0)};
});
const dayChart = Plot.plot({
  width: Math.max(280, width / 3 - 60), height: 190, marginLeft: 44, marginBottom: 28,
  x: {label: null, domain: DAYS.map((_, i) => `Day ${i + 1}`), tickSize: 0},
  y: {label: "houses visited", grid: true, tickFormat: (d) => d >= 1e3 ? `${Math.round(d / 1e3)}k` : String(d)},
  marks: [
    Plot.barY(houseRows.filter((d) => d.houses > 0), {x: "day", y: "houses", fill: STATUS_COLOR.completed, insetLeft: 4, insetRight: 4, tip: true,
      title: (d) => `${d.day} (${d.date})\n${fmtInt(d.houses)} houses visited in ${fmtInt(d.visits)} settlements\n${fmtInt(d.treated)} children vaccinated`}),
    Plot.text(houseRows.filter((d) => d.houses > 0), {x: "day", y: "houses", text: (d) => fmtInt(d.houses), dy: -6, fontSize: 10, fill: "#475569"}),
    Plot.text(houseRows.filter((d) => d.houses === 0), {x: "day", y: 0, text: () => "pending", dy: -6, fontSize: 10, fill: "#94a3b8"}),
    Plot.ruleY([0])
  ]
});
```


```js
const inspector = !selected
  ? html`<div class="muted">Click a settlement or a facility on the map.</div>`
  : selected.kind === "facility"
    ? html`<div><div style="font-weight:600;font-size:15px">${selected.facility}</div><div class="muted">${selected.facility_level ?? ""} · ${fmtInt(selected.visits)} settlements</div>
        <table class="kv"><tr><td>Completed</td><td>${fmtInt(selected.completed)} (${fmtPct(selected.progress)})</td></tr><tr><td>In progress / pending</td><td>${fmtInt(selected.inProgress)} / ${fmtInt(selected.pending)}</td></tr><tr><td>Target 0–59 m</td><td>${fmtInt(selected.u5)}</td></tr><tr><td>Vaccinated</td><td>${fmtInt(selected.treated)} (${fmtPct(selected.coverage)} of completed targets)</td></tr><tr><td>Found in the field</td><td>${fmtInt(selected.fieldRegistered)}</td></tr></table></div>`
    : html`<div><div style="font-weight:600;font-size:15px">${selected.settlement}</div><div class="muted">${selected.facility} catchment · day ${selected.day_n} (${selected.day})${selected.origin === "field-registered" ? " · found in the field, not in the microplan" : ""}</div>
        <table class="kv"><tr><td>Status</td><td><span style="color:${STATUS_COLOR[selected.status]}">●</span> ${STATUS_LABEL[selected.status]}</td></tr>
        <tr><td>Target 0–59 m</td><td>${selected.u5 != null ? fmtInt(selected.u5) : "no estimate (not in the plan)"}</td></tr><tr><td>WorldPop 2026</td><td>${fmtInt(selected.worldpop)}</td></tr>
        ${selected.status === "completed" ? html`<tr><td>Houses visited</td><td>${fmtInt(selected.houses)}</td></tr><tr><td>Children present / absent</td><td>${fmtInt(selected.present)} / ${fmtInt(selected.absent)}</td></tr><tr><td>Vaccinated</td><td>${fmtInt(selected.treated)}${selected.coverage != null ? ` (${fmtPct(selected.coverage)})` : ""}</td></tr><tr><td>Already marked</td><td>${fmtInt(selected.marked)}</td></tr>` : ""}
        </table></div>`;
```

<div class="card" style="margin-top: 12px">
  <h2>Children targeted and vaccinated by ${facility === "All" ? "facility catchment" : "settlement"}${facility === "All" ? "" : `, ${facility} catchment`}</h2>
  <div class="muted" style="margin-bottom: 6px">Children 0–59 months. Grey: targeted across the catchment. Green: vaccinated so far. Beside each bar: how many of the catchment’s settlements are complete, with a green tick once all of them are. Pick a facility catchment above to see its settlements.</div>
  <div style="max-height: 560px; overflow-y: auto">${targetPlot}</div>
</div>

```js
// Bar-in-bar, as the coverage page: the target bar with the vaccinated bar inset, one row per
// facility catchment (or per settlement when one catchment is picked), largest target first.
const barRows = (facility === "All"
  ? facilities.map((f) => ({unit: f.facility, targeted: f.u5, reached: f.treated, completed: f.completed, visits: f.visits, coverage: f.coverage,
      progress: `${fmtInt(f.completed)} of ${fmtInt(f.visits)} settlements` + (f.completed === f.visits ? " \u2713" : ""), done: f.completed === f.visits}))
  : inFacility.map((d) => ({unit: d.settlement, targeted: d.u5 ?? 0, reached: d.status === "completed" ? d.treated ?? 0 : 0, coverage: d.coverage,
      progress: STATUS_LABEL[d.status] + (d.status === "completed" ? " \u2713" : "") + (d.origin === "field-registered" ? " \u00b7 found in the field" : ""), done: d.status === "completed"}))
).sort((a, b) => b.targeted - a.targeted);
const barTitle = (d) => `${d.unit}\n${d.progress}\ntargeted: ${fmtInt(d.targeted)} \u00b7 vaccinated: ${fmtInt(d.reached)}${d.coverage != null ? ` (${fmtPct(d.coverage)} of the completed settlements' target)` : ""}`;
const xMax = d3.max(barRows, (d) => Math.max(d.targeted, d.reached)) ?? 0;
const targetPlot = Plot.plot({
  width: Math.max(600, width - 60),
  height: 30 + 16 * barRows.length,
  marginLeft: 300, marginRight: 170, marginTop: 24, marginBottom: 10,
  x: {label: null, axis: "top", grid: true, ticks: 8, tickFormat: (d) => d.toLocaleString("en"), domain: [0, xMax * 1.02]},
  y: {label: null, domain: barRows.map((d) => d.unit), tickSize: 0},
  color: {domain: ["targeted", "vaccinated"], range: ["#cbd5e1", "#238b45"], legend: true},
  marks: [
    Plot.barX(barRows, {x: "targeted", y: "unit", fill: () => "targeted", tip: true, title: barTitle}),
    Plot.barX(barRows.filter((d) => d.reached > 0), {x: "reached", y: "unit", fill: () => "vaccinated", insetTop: 3, insetBottom: 3}),
    // Completion written beside each bar: "18 of 27 settlements"; green with a tick once every settlement is done.
    Plot.text(barRows, {x: "targeted", y: "unit", text: "progress", textAnchor: "start", dx: 6, fontSize: 11, fill: (d) => d.done ? "#15803d" : "#64748b"}),
    Plot.ruleX([0])
  ]
});
```

## Facility catchments

```js
const facilitySearch = view(Inputs.search(facilitiesShown, {placeholder: "Search facility…", columns: ["facility", "facility_level"]}));
```

```js
const facilityTable = view(Inputs.table(facilitySearch, {
  columns: ["facility", "facility_level", "visits", "u5", "completed", "inProgress", "pending", "treated", "coverage", "below80", "fieldRegistered"],
  header: {facility: "Facility", facility_level: "Level", visits: "Settlements", u5: "Target 0–59 m", completed: "Completed", inProgress: "In progress", pending: "Pending", treated: "Vaccinated", coverage: "Coverage", below80: "< 80%", fieldRegistered: "Found"},
  format: {u5: fmtInt, treated: fmtInt, coverage: (d) => d == null ? "" : fmtPct(d)},
  width: {facility: 220, facility_level: 140},
  rows: 14, multiple: false, required: false
}));
```

## Settlements${facilityTable ? html` — ${facilityTable.facility} catchment` : facility !== "All" ? html` — ${facility} catchment` : ""}

```js
const settlementRows = (facilityTable ? rows.filter((d) => d.facility_id === facilityTable.facility_id) : rows)
  .map((d) => ({...d, status_label: STATUS_LABEL[d.status], day_label: `Day ${d.day_n} · ${d.day.slice(5)}`}));
const settlementSearch = view(Inputs.search(settlementRows, {placeholder: "Search settlement, facility, status…", columns: ["settlement", "facility", "status_label", "origin"]}));
```

```js
Inputs.table(settlementSearch, {
  columns: ["settlement", "facility", "day_label", "status_label", "origin", "u5", "houses", "present", "absent", "treated", "coverage"],
  header: {settlement: "Settlement", facility: "Facility", day_label: "Planned", status_label: "Status", origin: "Origin", u5: "Target 0–59 m", houses: "Houses", present: "Present", absent: "Absent", treated: "Vaccinated", coverage: "Coverage"},
  format: {u5: (d) => d == null ? "—" : fmtInt(d), coverage: (d) => d == null ? "" : fmtPct(d), houses: (d) => d == null ? "" : fmtInt(d), present: (d) => d == null ? "" : fmtInt(d), absent: (d) => d == null ? "" : fmtInt(d), treated: (d) => d == null ? "" : fmtInt(d)},
  width: {settlement: 180, facility: 200, status_label: 220},
  rows: 18
})
```

<footer class="muted" style="margin-top: 24px; padding-top: 12px; border-top: 1px solid var(--theme-foreground-faintest); font-size: 12px; line-height: 1.6">
  <p style="margin: 0 0 8px">
    The round is one <code>ICRCampaign</code> for Toro LGA with a facility-level campaign per health-facility catchment
    (<code>partOf</code> the round); each settlement is one <code>ICRCampaignTask</code> (a house-to-house sweep of the whole settlement) (<code>basedOn</code> its
    facility's campaign, house-to-house, one per settlement) whose tally rides <code>Task.output</code>; the vaccination
    team is the task's <code>owner</code>. The under-5 target per settlement is an <code>ICRTargetPopulation</code>
    Group scoped to the settlement catchment: the catchment's WorldPop 2026 total (kiln population) × Toro's under-5 share.
    Settlements found in the field carry <code>task-origin = field-registered</code> and have no target — they measure how
    incomplete the microplan's enumeration was. Data: <code>IcrCampaignTask</code> and <code>IcrTargetPopulation</code>
    views over the local registry (synthetic tallies, tools/microplan-builder).
  </p>
  <p style="margin: 0">${fmtInt(settlementSearch.length)} of ${fmtInt(settlementRows.length)} settlements listed.</p>
</footer>

<style>
.title-row { display: flex; gap: 24px; align-items: flex-start; justify-content: space-between; flex-wrap: wrap; margin: 0 0 16px; }
.title-row h1 { flex: 1 1 420px; }
.round-card { display: flex; gap: 28px; padding: 10px 18px; margin: 0; flex: 0 0 auto; }
.round-cell { white-space: nowrap; }
.round-big { font-size: 24px; font-weight: 650; line-height: 1.15; letter-spacing: -0.01em; }
.round-of { font-size: 15px; font-weight: 500; color: var(--theme-foreground-muted); }
.big { font-size: 26px; font-weight: 600; line-height: 1.1; }
.map-title { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); padding: 10px 14px 6px; }
.map-controls { display: flex; gap: 16px; align-items: center; flex-wrap: wrap; padding: 8px 14px 6px; }
.map-controls form { margin: 0; }
.card h2 { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); margin: 0 0 4px; }
.kpi-plan { border-top: 3px solid #7c3aed; }
.kpi-mon { border-top: 3px solid #15803d; }
.kv { font-size: 12px; border-collapse: collapse; width: 100%; margin-top: 6px; }
.kv td { padding: 2px 8px 2px 0; vertical-align: top; }
.kv td:first-child { color: #64748b; white-space: nowrap; }
.maplibregl-popup-content { padding: 6px 9px; }
</style>
