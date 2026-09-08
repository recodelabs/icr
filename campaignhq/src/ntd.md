---
title: NTD endemicity
sql:
  campaigns: data/campaigns.parquet
  endemicity: data/endemicity.parquet
  admin_units: data/admin_units.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# NTD endemicity and MDA coverage

Show where each NTD is endemic according to NTD classifications based on the LGA level baseline compared against the administered NTD campaigns.

```js
import {campaignMap, syncMaps, DEFAULT_BASEMAP} from "./components/map.js";
import {constrain, available} from "./components/filters.js";
const BASEMAP = DEFAULT_BASEMAP;

const toRows = (table) => Array.from(table, (r) => {
  const o = typeof r.toJSON === "function" ? r.toJSON() : {...r};
  for (const k in o) if (typeof o[k] === "bigint") o[k] = Number(o[k]);
  return o;
});
const fmtInt = (n) => n == null ? "—" : Math.round(Number(n)).toLocaleString("en");
const fmtPct = (x) => x == null ? "" : `${Math.round(x * 100)}%`;
const fmtDate = (d) => d == null ? "" : new Date(d).toISOString().slice(0, 10);
const today = new Date();

// Disease → the programmes whose rounds treat it (programme labels as in campaigns.parquet).
const DISEASES = {
  lf: {label: "Lymphatic filariasis", programmes: ["LF / onchocerciasis MDA"], target: 0.65, targetLabel: "WHO ≥ 65% epidemiological coverage"},
  oncho: {label: "Onchocerciasis", programmes: ["LF / onchocerciasis MDA", "Onchocerciasis CDTI"], target: 0.80, targetLabel: "≥ 80% therapeutic coverage"},
  trachoma: {label: "Trachoma", programmes: ["Trachoma MDA"], target: 0.80, targetLabel: "≥ 80% coverage"},
  schisto: {label: "Schistosomiasis", programmes: ["Schisto / STH school MDA"], target: 0.75, targetLabel: "≥ 75% of school-age children"},
  sth: {label: "Soil-transmitted helminths", programmes: ["Schisto / STH school MDA"], target: 0.75, targetLabel: "≥ 75% of school-age children"}
};
const STATUS_LABEL = {
  "endemic-under-mda": "Endemic, under MDA", "endemic-mda-not-started": "Endemic, MDA not started",
  "post-mda-surveillance": "Post-MDA surveillance", "elimination-validated": "Elimination validated",
  "non-endemic": "Non-endemic", "unknown": "Unknown"
};
const STATUS_ORDER = ["endemic-under-mda", "endemic-mda-not-started", "post-mda-surveillance", "elimination-validated", "non-endemic", "unknown"];
```

```js
const years = toRows(await sql`SELECT DISTINCT year FROM campaigns WHERE level = 'lga' AND campaign_type = 'mda' ORDER BY year`).map((d) => d.year);
const states = toRows(await sql`SELECT DISTINCT state FROM campaigns WHERE level = 'lga' AND state IS NOT NULL AND country = 'NGA' ORDER BY state`).map((d) => d.state);
// Every disease × year × state with at least one MDA round of one of the disease's programmes.
const mdaCombos = toRows(await sql`SELECT year, state, programme, count(*) AS n FROM campaigns WHERE level = 'lga' AND country = 'NGA' AND campaign_type = 'mda' GROUP BY 1, 2, 3`);
const combos = Object.entries(DISEASES).flatMap(([disease, D]) => mdaCombos.filter((c) => D.programmes.includes(c.programme)).map((c) => ({disease, year: c.year, state: c.state})));
const diseaseData = Object.keys(DISEASES), stateData = ["All", ...states];
```

<div class="grid grid-cols-3" style="gap: 12px; margin-bottom: 8px">
  <div>${diseaseInput}</div>
  <div>${yearInput}</div>
  <div>${stateInput}</div>
</div>

```js
const diseaseInput = Inputs.select(diseaseData, {label: "Disease", value: "lf", format: (d) => DISEASES[d].label});
const disease = Generators.input(diseaseInput);
const yearInput = Inputs.select(years, {label: "MDA year", value: 2025, format: (d) => String(d)});
const year = Generators.input(yearInput);
const stateInput = Inputs.select(stateData, {label: "State", value: "All"});
const state = Generators.input(stateInput);
```

```js
// Smart pulldowns: grey out diseases / years / states with no MDA round under the other two filters.
// Disease and year have no "All", so an invalid choice falls back to the first valid one.
{
  constrain(diseaseInput, diseaseData, available(combos, "disease", {year, state}), {keep: null});
  constrain(yearInput, years, available(combos, "year", {disease, state}), {keep: null});
  constrain(stateInput, stateData, available(combos, "state", {disease, year}));
}
```

```js
const D = DISEASES[disease];
const stateWhere = state === "All" ? "TRUE" : `state = '${String(state).replace(/'/g, "''")}'`;
// The assertion history per LGA for the disease; the classification AS OF the selected year is the
// newest assertion dated on or before 31 December of that year (so 2023 shows the 2023 picture).
const history = toRows(await sql([`SELECT * FROM endemicity WHERE disease = '${disease}' AND admin_level = 2 AND country = 'NGA' AND ${stateWhere} ORDER BY effective`]));
const cutoff = new Date(`${Number(year)}-12-31T23:59:59Z`);
const current = Array.from(
  history.filter((d) => new Date(d.effective) <= cutoff).reduce((m, d) => m.set(d.location_id, d), new Map()).values()
).sort((a, b) => a.state.localeCompare(b.state) || a.location_name.localeCompare(b.location_name));
// The disease's MDA rounds in the year, per LGA.
const progList = D.programmes.map((p) => `'${p.replace(/'/g, "''")}'`).join(", ");
const rounds = toRows(await sql([`SELECT * FROM campaigns WHERE level = 'lga' AND programme IN (${progList}) AND year = ${Number(year)} AND ${stateWhere} ORDER BY state, location_name`]));
```

```js
// Join: one row per LGA with its classification and the year's MDA outcome.
const byLga = new Map(current.map((d) => [d.location_id, d]));
const roundsByLga = new Map();
for (const r of rounds) {
  const cur = roundsByLga.get(r.location_id) ?? {rounds: 0, targeted: 0, reached: 0, reportedTargeted: 0, statuses: new Set(), survey: null, lqas: null, first: null};
  cur.rounds += 1;
  cur.targeted += r.targeted ?? 0;
  if (r.reached != null && r.targeted) { cur.reached += r.reached; cur.reportedTargeted += r.targeted; }
  cur.statuses.add(r.result_status);
  if (r.survey_coverage != null) cur.survey = r;
  if (r.lqas_result) cur.lqas = r.lqas_result;
  if (!cur.first || r.period_start < cur.first) cur.first = r.period_start;
  roundsByLga.set(r.location_id, cur);
}
// Baseline prevalence per LGA: the earliest assertion carrying a % figure (survives a later
// transition whose figure is the stop-survey result, e.g. TAS positives).
const baselineByLga = new Map();
for (const h of history) if (h.figure_unit === "%" && h.figure_value != null && !baselineByLga.has(h.location_id)) baselineByLga.set(h.location_id, h);
const lgaRows = current.map((d) => {
  const rr = roundsByLga.get(d.location_id);
  const bl = baselineByLga.get(d.location_id);
  const coverage = rr && rr.reportedTargeted > 0 ? rr.reached / rr.reportedTargeted : null;
  return {
    location_id: d.location_id, location_name: d.location_name, state: d.state,
    status: d.status, status_label: STATUS_LABEL[d.status] ?? d.status,
    effective: d.effective, method: d.method, figure_label: d.figure_label, figure_value: d.figure_value, figure_unit: d.figure_unit,
    figure_text: d.figure_value == null ? "" : `${d.figure_value}${d.figure_unit === "%" ? "%" : ` ${d.figure_unit}`}`,
    baseline: bl?.figure_value ?? null, baseline_text: bl ? `${bl.figure_value}%` : "", baseline_label: bl?.figure_label ?? "",
    rounds: rr?.rounds ?? 0, targeted: rr?.targeted ?? null, reached: rr?.reportedTargeted ? rr.reached : null, coverage,
    coverage_text: coverage != null ? fmtPct(coverage) : rr ? (rr.statuses.has("in progress") ? "in progress" : rr.statuses.has("planned") ? "planned" : "no report") : "",
    survey_text: rr?.survey ? `${fmtPct(rr.survey.survey_coverage)} (${Math.round(rr.survey.survey_ci_low * 100)}–${Math.round(rr.survey.survey_ci_high * 100)})` : "",
    lqas: rr?.lqas ?? "",
    gap: d.status === "endemic-under-mda" && !rr ? "endemic, no round" : d.status !== "endemic-under-mda" && rr ? "round in non-MDA LGA" : "",
    detail: `${d.figure_label ? `${d.figure_label}: ${d.figure_value}${d.figure_unit === "%" ? "%" : ""}` : ""}${d.effective ? `<br>assessed ${fmtDate(d.effective)}` : ""}`
  };
});
// Rows for the two maps: the endemicity map wants status + detail; the coverage map wants per-round rows.
const statusRows = lgaRows.map((d) => ({location_id: d.location_id, location_name: d.location_name, state: d.state, status: d.status, detail: d.detail, rounds: 0, targeted: 0}));
```

```js
const counts = Object.fromEntries(STATUS_ORDER.map((s) => [s, lgaRows.filter((d) => d.status === s).length]));
const endemic = lgaRows.filter((d) => d.status === "endemic-under-mda");
const endemicWithRound = endemic.filter((d) => d.rounds > 0);
const endemicReported = endemic.filter((d) => d.coverage != null);
const kpi = {
  endemic: endemic.length,
  surveillance: counts["post-mda-surveillance"],
  nonEndemic: counts["non-endemic"],
  unknown: counts["unknown"],
  covered: endemicWithRound.length,
  gaps: endemic.length - endemicWithRound.length,
  targeted: endemicWithRound.reduce((s, d) => s + (d.targeted ?? 0), 0),
  reached: endemicReported.reduce((s, d) => s + (d.reached ?? 0), 0),
  reportedTargeted: endemicReported.reduce((s, d) => s + (d.targeted ?? 0), 0),
  belowTarget: endemicReported.filter((d) => d.coverage < D.target).length
};
kpi.coverage = kpi.reportedTargeted > 0 ? kpi.reached / kpi.reportedTargeted : null;
```

<div class="grid grid-cols-4" style="gap: 12px">
  <div class="card"><h2>LGAs endemic, under MDA (as of ${year})</h2><span class="big">${fmtInt(kpi.endemic)}</span><div class="muted">${fmtInt(kpi.surveillance)} in post-MDA surveillance · ${fmtInt(kpi.nonEndemic)} non-endemic · ${fmtInt(kpi.unknown)} unmapped</div></div>
  <div class="card"><h2>Endemic LGAs with a ${year} round</h2><span class="big">${fmtInt(kpi.covered)}<span class="muted" style="font-size:16px"> of ${fmtInt(kpi.endemic)}</span></span><div class="muted">${kpi.gaps ? html`<span style="color:#b91c1c">${fmtInt(kpi.gaps)} endemic LGA${kpi.gaps === 1 ? "" : "s"} had no round</span>` : "every endemic LGA was targeted"}</div></div>
  <div class="card"><h2>People targeted in endemic LGAs</h2><span class="big">${fmtInt(kpi.targeted)}</span><div class="muted">${D.programmes.join(" + ")}, ${year}</div></div>
  <div class="card"><h2>Coverage in endemic LGAs</h2><span class="big">${kpi.coverage != null ? fmtPct(kpi.coverage) : "—"}</span><div class="muted">${kpi.coverage != null ? `${fmtInt(kpi.reached)} reached · ${fmtInt(kpi.belowTarget)} of ${fmtInt(endemicReported.length)} reported LGAs below ${D.targetLabel}` : "no reports yet"}</div></div>
</div>

<div class="grid grid-cols-2" style="gap: 12px; margin-top: 12px">
  <div class="card" style="padding: 0; overflow: hidden">
    <div class="map-title">${D.label} — classification per LGA as of ${year}</div>
    ${mapStatus}
  </div>
  <div class="card" style="padding: 0; overflow: hidden">
    <div class="map-title">${D.label} MDA coverage, ${year} <span class="muted">(reached ÷ targeted; grey = no round or no report)</span></div>
    ${mapCoverage}
  </div>
</div>

```js
const pmtiles = await FileAttachment("data/admin.pmtiles").arrayBuffer();
const stateLabels = toRows(await sql`SELECT id, name, lon, lat FROM admin_units WHERE admin_level = 1 AND country = 'NGA'`);
const mapStatus = campaignMap({pmtiles, height: 440, basemap: BASEMAP, labels: stateLabels, metric: "endemicity"});
const mapCoverage = campaignMap({pmtiles, height: 440, basemap: BASEMAP, labels: stateLabels, metric: "coverage"});
syncMaps(mapStatus, mapCoverage);
```

```js
mapStatus.update(statusRows);
mapCoverage.update(rounds);
```

<div class="card" style="margin-top: 12px">
  <div style="display:flex; justify-content:space-between; align-items:baseline; gap:12px; flex-wrap:wrap">
    <h2>Coverage by LGA, ${year}</h2>
    <div>${sortInput}</div>
  </div>
  ${coveragePlot}
</div>

<div class="card" style="margin-top: 12px">
  <h2>Classification by LGA and year</h2>
  ${statusTimeline}
</div>

```js
const sortInput = Inputs.radio(new Map([["Sort by coverage", "coverage"], ["Sort by endemicity", "baseline"]]), {value: "coverage"});
const sortMode = Generators.input(sortInput);
```

```js
const dots = lgaRows.filter((d) => d.coverage != null);
// Only the classes that actually occur in the plotted rows go in the colour scale / legend.
const presentStatuses = STATUS_ORDER.filter((st) => dots.some((d) => d.status === st));
const STATUS_COLOR = {"endemic-under-mda": "#c2410c", "endemic-mda-not-started": "#f97316", "post-mda-surveillance": "#2563eb", "elimination-validated": "#0f766e", "non-endemic": "#9ca3af", "unknown": "#eab308"};
const COLOR = {domain: presentStatuses.map((st) => STATUS_LABEL[st]), range: presentStatuses.map((st) => STATUS_COLOR[st])};
const xDomain = [0, Math.max(1.1, ...dots.map((d) => d.coverage))];
const dotTitle = (d) => `${d.location_name} LGA, ${d.state}\n${d.status_label}${d.baseline_text ? `\nbaseline prevalence: ${d.baseline_text}` : ""}${d.figure_text && d.figure_label !== d.baseline_label ? `\n${d.figure_label}: ${d.figure_text}` : ""}\n${fmtInt(d.reached)} reached of ${fmtInt(d.targeted)} targeted (${fmtPct(d.coverage)})${d.survey_text ? `\nsurvey: ${d.survey_text}` : ""}`;
// Highest first; LGAs without a baseline figure sink to the bottom when sorting by endemicity.
const byCoverage = (rows) => sortMode === "baseline"
  ? rows.slice().sort((a, b) => (b.baseline ?? -1) - (a.baseline ?? -1) || b.coverage - a.coverage)
  : rows.slice().sort((a, b) => b.coverage - a.coverage);
const stateGroups = d3.groups(dots, (d) => d.state).sort((a, b) => a[0].localeCompare(b[0]));

const legend = html`<div style="display:flex; gap: 18px; flex-wrap: wrap; align-items: center; font-size: 12px; margin: 4px 0 2px">
  ${presentStatuses.map((st) => html`<span><span style="display:inline-block;width:10px;height:10px;border-radius:50%;background:${STATUS_COLOR[st]};margin-right:5px;vertical-align:-1px"></span>coverage · ${STATUS_LABEL[st]}</span>`)}
  <span><span style="display:inline-block;width:8px;height:8px;border:1.5px solid #475569;transform:rotate(45deg);margin:0 6px 0 2px;vertical-align:0"></span>baseline prevalence</span>
</div>`;

const coveragePlot = html`<div>
  ${legend}
  ${stateGroups.map(([st, rows], i) => {
    const last = i === stateGroups.length - 1;
    const cov = d3.sum(rows, (d) => d.reached) / d3.sum(rows, (d) => d.targeted);
    const withBaseline = rows.filter((d) => d.baseline != null);
    const meanPrev = withBaseline.length ? d3.mean(withBaseline, (d) => d.baseline) : null;
    return html`<div style="font-weight:600; margin: 8px 0 -6px 4px">${st} <span class="muted" style="font-weight:400">· ${rows.length} reported LGA${rows.length === 1 ? "" : "s"} · <b>${fmtPct(cov)}</b> coverage${meanPrev != null ? html` · mean baseline prevalence <b>${meanPrev.toFixed(1)}%</b>` : ""}</span></div>
      ${Plot.plot({
        width: Math.max(320, width - 80),
        height: 22 + 18 * rows.length + (last ? 34 : 6),
        marginLeft: 120, marginRight: 20, marginTop: 6, marginBottom: last ? 34 : 6,
        x: {label: last ? "percent (● administrative coverage · ◇ baseline prevalence)" : null, tickFormat: ".0%", domain: xDomain, grid: true, axis: last ? "bottom" : null},
        y: {label: null, domain: byCoverage(rows).map((d) => d.location_name)},
        color: COLOR,
        marks: [
          Plot.ruleX([D.target], {stroke: "#111", strokeDasharray: "4,3"}),
          Plot.ruleX([1], {stroke: "#9ca3af"}),
          Plot.ruleY(rows, {x: "coverage", y: "location_name", stroke: "#e5e7eb"}),
          Plot.dot(withBaseline, {x: (d) => d.baseline / 100, y: "location_name", symbol: "diamond2", r: 4.5, stroke: "#475569", strokeWidth: 1.5, fill: "white", tip: true,
            title: (d) => `${d.location_name} LGA, ${d.state}\n${d.baseline_label}: ${d.baseline_text}`}),
          Plot.dot(rows, {x: "coverage", y: "location_name", fill: "status_label", r: 5, tip: true, title: dotTitle})
        ]
      })}`;
  })}
</div>`;
```

```js
// Classification of every LGA at the end of every year, from the assertion history.
const yearEnds = years.map((y) => [y, new Date(`${Number(y)}-12-31T23:59:59Z`)]);
const gridRows = [];
for (const [id, hs] of d3.groups(history, (d) => d.location_id)) {
  // Nothing to see for LGAs that are non-endemic or unmapped throughout.
  if (!hs.some((h) => h.status !== "non-endemic" && h.status !== "unknown")) continue;
  let prev = null, firstChange = null;
  const rows = [];
  for (const [y, end] of yearEnds) {
    const cur = hs.filter((h) => new Date(h.effective) <= end).at(-1);
    const status = cur?.status ?? "unknown";
    const changed = prev != null && status !== prev;
    if (changed && firstChange == null) firstChange = y;
    rows.push({location_id: id, location_name: hs[0].location_name, state: hs[0].state, year: y, status, status_label: STATUS_LABEL[status] ?? status,
      changed, from: changed ? STATUS_LABEL[prev] : null, effective: cur?.effective, method: cur?.method, figure_label: cur?.figure_label, figure_value: cur?.figure_value, figure_unit: cur?.figure_unit});
    prev = status;
  }
  for (const r of rows) gridRows.push({...r, firstChange});
}
const hiddenLgas = new Set(history.map((d) => d.location_id)).size - new Set(gridRows.map((d) => d.location_id)).size;
const tlStatuses = STATUS_ORDER.filter((st) => gridRows.some((d) => d.status === st));
const tlGroups = d3.groups(gridRows, (d) => d.state).sort((a, b) => a[0].localeCompare(b[0]));
const tlOrder = (rows) => Array.from(new Set(rows.slice().sort((a, b) => (a.firstChange ?? 9999) - (b.firstChange ?? 9999) || a.location_name.localeCompare(b.location_name)).map((d) => d.location_name)));
const cellTitle = (d) => `${d.location_name} LGA, ${d.state} — end of ${d.year}\n${d.status_label}${d.changed ? `\nchanged from ${d.from} on ${fmtDate(d.effective)}` : ""}${d.method ? `\n${d.method}` : ""}${d.figure_value != null ? `\n${d.figure_label}: ${d.figure_value}${d.figure_unit === "%" ? "%" : ` ${d.figure_unit}`}` : ""}`;

const statusTimeline = html`<div>
  <div style="display:flex; gap: 18px; flex-wrap: wrap; align-items: center; font-size: 12px; margin: 4px 0 6px">
    ${tlStatuses.map((st) => html`<span><span style="display:inline-block;width:10px;height:10px;border-radius:50%;background:${STATUS_COLOR[st]};margin-right:5px;vertical-align:-1px"></span>${STATUS_LABEL[st]}</span>`)}
  </div>
  <div style="display:flex; flex-wrap: wrap; gap: 6px 28px; align-items: flex-start">
  ${tlGroups.map(([st, rows]) => {
    const lgas = tlOrder(rows);
    const moved = new Set(rows.filter((d) => d.changed).map((d) => d.location_id)).size;
    return html`<div>
      <div style="font-weight:600; margin: 6px 0 -2px 4px">${st} <span class="muted" style="font-weight:400">· ${lgas.length} LGA${lgas.length === 1 ? "" : "s"} · <b>${moved}</b> changed</span></div>
      ${Plot.plot({
        width: 110 + 30 * years.length,
        height: 24 + 16 * lgas.length,
        marginLeft: 105, marginRight: 8, marginTop: 20, marginBottom: 4,
        x: {label: null, domain: years, tickFormat: (d) => String(d).slice(2), axis: "top", tickSize: 0, padding: 0},
        y: {label: null, domain: lgas, tickSize: 0},
        color: {domain: tlStatuses, range: tlStatuses.map((s) => STATUS_COLOR[s])},
        marks: [
          Plot.dot(rows, {x: "year", y: "location_name", fill: "status", r: 5, tip: true, title: cellTitle})
        ]
      })}
    </div>`;
  })}
  </div>
  ${hiddenLgas ? html`<div class="muted" style="margin-top: 8px; font-size: 12px">${hiddenLgas} LGA${hiddenLgas === 1 ? "" : "s"} classified non-endemic or unmapped throughout are not shown.</div>` : ""}
</div>`;
```

## LGAs

```js
const search = view(Inputs.search(lgaRows, {placeholder: "Search LGA, state, status…", columns: ["location_name", "state", "status_label", "gap", "lqas"]}));
```

```js
Inputs.table(search, {
  columns: ["state", "location_name", "status_label", "figure_text", "effective", "rounds", "targeted", "reached", "coverage_text", "survey_text", "lqas", "gap"],
  header: {state: "State", location_name: "LGA", status_label: "Classification", figure_text: "Baseline / survey figure", effective: "Assessed", rounds: `${year} rounds`, targeted: "Targeted", reached: "Reached", coverage_text: "Admin cov.", survey_text: "Survey", lqas: "LQAS", gap: "Flag"},
  format: {effective: fmtDate, targeted: (d) => d == null ? "" : fmtInt(d), reached: (d) => d == null ? "" : fmtInt(d)},
  align: {targeted: "right", reached: "right", coverage_text: "right", survey_text: "right"},
  width: {state: 70, location_name: 120, status_label: 160, figure_text: 120, effective: 95, rounds: 60, targeted: 85, reached: 85, coverage_text: 80, survey_text: 110, lqas: 80},
  sort: "status_label",
  rows: 22
})
```

<style>
.big { font-size: 28px; font-weight: 600; line-height: 1.1; }
.card h2 { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); margin: 0 0 4px; }
.map-title { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); padding: 10px 14px 6px; }
.maplibregl-popup-content { padding: 6px 9px; }
</style>
