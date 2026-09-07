---
title: Campaign coverage
sql:
  campaigns: data/campaigns.parquet
  admin_units: data/admin_units.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Campaign coverage

How many people each campaign set out to reach and how many it did — by year, by state,
and by LGA when you drill into a state. People targeted is the round's planning denominator
(an `ICRTargetPopulation` Group); people reached and administrative coverage come from the
round's reconciled administrative coverage report (`IcrCoverage` view); surveys are the
independent post-campaign estimates.

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
const fmtCompact = (v) => v >= 1e6 ? `${+(v / 1e6).toFixed(1)}M` : v >= 1e3 ? `${Math.round(v / 1e3)}k` : String(Math.round(v));
// Same breaks and colours as the coverage map ramp.
const COVERAGE_BREAKS = [0.5, 0.65, 0.8, 0.9, 0.95, 1.05];
const COVERAGE_COLORS = ["#fde0dd", "#fcc5c0", "#fa9fb5", "#c7e9c0", "#a1d99b", "#74c476", "#238b45"];
```

```js
const years = toRows(await sql`SELECT DISTINCT year FROM campaigns WHERE level = 'lga' ORDER BY year`).map((d) => d.year);
const states = toRows(await sql`SELECT DISTINCT state FROM campaigns WHERE level = 'lga' AND state IS NOT NULL AND country = 'NGA' ORDER BY state`).map((d) => d.state);
const programmes = toRows(await sql`SELECT programme, count(*) n FROM campaigns WHERE level = 'lga' GROUP BY 1 ORDER BY 2 DESC`).map((d) => d.programme);
const combos = toRows(await sql`SELECT year, state, programme, count(*) AS n FROM campaigns WHERE level = 'lga' AND country = 'NGA' GROUP BY 1, 2, 3`);
const programmeData = ["All", ...programmes], yearData = ["All", ...years], stateData = ["All", ...states];
const stateBounds = new Map(toRows(await sql`SELECT name, xmin, ymin, xmax, ymax FROM admin_units WHERE admin_level = 1 AND country = 'NGA'`).map((d) => [d.name, [[d.xmin, d.ymin], [d.xmax, d.ymax]]]));
```

<div class="grid grid-cols-3" style="gap: 12px; margin-bottom: 8px">
  <div>${programmeInput}</div>
  <div>${yearInput}</div>
  <div>${stateInput}</div>
</div>

```js
const programmeInput = Inputs.select(programmeData, {label: "Programme", value: "All"});
const programme = Generators.input(programmeInput);
const yearInput = Inputs.select(yearData, {label: "Year", value: 2025, format: (d) => String(d)});
const year = Generators.input(yearInput);
const stateInput = Inputs.select(stateData, {label: "State", value: "All"});
const state = Generators.input(stateInput);
```

```js
// Smart pulldowns: grey out choices with no rounds under the other two filters.
{
  constrain(programmeInput, programmeData, available(combos, "programme", {year, state}));
  constrain(yearInput, yearData, available(combos, "year", {programme, state}));
  constrain(stateInput, stateData, available(combos, "state", {programme, year}));
}
```

```js
// Every LGA round for the programme × state selection, all years; the year filter is applied
// separately so the by-year charts and table always show the whole window.
const selWhere = [
  programme === "All" ? "TRUE" : `programme = '${String(programme).replace(/'/g, "''")}'`,
  state === "All" ? "TRUE" : `state = '${String(state).replace(/'/g, "''")}'`
].join(" AND ");
const allRows = toRows(await sql([`SELECT * FROM campaigns WHERE level = 'lga' AND country = 'NGA' AND ${selWhere} ORDER BY year, state, location_name`]));
const stateSurveyRows = toRows(await sql([`SELECT year, state, programme, survey_coverage, survey_ci_low, survey_ci_high, survey_n FROM campaigns WHERE level = 'state' AND country = 'NGA' AND survey_coverage IS NOT NULL AND ${selWhere}`]));
const yearRows = year === "All" ? allRows : allRows.filter((d) => d.year === Number(year));
const drilled = state !== "All";
const unitLabel = drilled ? "LGA" : "State";
const unitWord = drilled ? "LGA" : "state";
```

```js
// Roll rounds up to one row per unit (state, or LGA when drilled) × year.
function rollup(rows) {
  const m = new Map();
  for (const d of rows) {
    const unit = drilled ? d.location_name : d.state;
    const id = `${unit}|${d.year}`;
    let g = m.get(id);
    if (!g) {
      g = {unit, year: d.year, state: d.state, location_id: d.location_id, rounds: 0, reported: 0, noReport: 0, inProgress: 0, planned: 0,
           targeted: 0, reportedTargeted: 0, reached: 0, surveys: [], lgaSurveys: [], lqasPass: 0, lqasN: 0, programmes: new Set()};
      m.set(id, g);
    }
    g.rounds += 1;
    g.targeted += d.targeted ?? 0;
    g.programmes.add(d.programme);
    if (d.admin_coverage != null) { g.reported += 1; g.reportedTargeted += d.targeted ?? 0; g.reached += d.reached ?? 0; }
    else if (d.result_status === "in progress") g.inProgress += 1;
    else if (d.result_status === "planned") g.planned += 1;
    else g.noReport += 1;
    if (d.survey_coverage != null) (drilled ? g.surveys : g.lgaSurveys).push(d);
    if (d.lqas_result) { g.lqasN += 1; if (d.lqas_result === "pass") g.lqasPass += 1; }
  }
  // State-level post-campaign surveys attach to the state × year row.
  if (!drilled) for (const s of stateSurveyRows) m.get(`${s.state}|${s.year}`)?.surveys.push(s);
  return Array.from(m.values()).map((g) => {
    const coverage = g.reportedTargeted > 0 ? g.reached / g.reportedTargeted : null;
    const sv = g.surveys;
    return {
      ...g,
      programmes: g.programmes.size,
      coverage,
      coverage_text: coverage != null ? fmtPct(coverage) : g.inProgress ? "in progress" : g.planned === g.rounds ? "planned" : "no report",
      reported_text: g.reported ? `${g.reported} of ${g.rounds}` : g.planned === g.rounds ? "planned" : g.inProgress ? `0 of ${g.rounds} (in progress)` : `0 of ${g.rounds}`,
      reached_text: g.reported ? fmtInt(g.reached) : "",
      survey_text: sv.length === 0 ? (g.lgaSurveys.length ? `${g.lgaSurveys.length} LGA survey${g.lgaSurveys.length === 1 ? "" : "s"}` : "") : sv.length === 1
        ? `${fmtPct(sv[0].survey_coverage)} (${Math.round(sv[0].survey_ci_low * 100)}–${Math.round(sv[0].survey_ci_high * 100)})`
        : `${fmtPct(Math.min(...sv.map((s) => s.survey_coverage)))}–${fmtPct(Math.max(...sv.map((s) => s.survey_coverage)))} (${sv.length} surveys)`,
      lqas_text: g.lqasN ? `${g.lqasPass}/${g.lqasN} pass` : ""
    };
  }).sort((a, b) => a.unit.localeCompare(b.unit) || a.year - b.year);
}
const byYear = rollup(allRows);
const units = Array.from(new Set(byYear.map((d) => d.unit))).sort();
```

```js
const reportedRows = yearRows.filter((d) => d.admin_coverage != null);
const kpi = {
  rounds: yearRows.length,
  lgas: new Set(yearRows.map((d) => d.location_id)).size,
  targeted: yearRows.reduce((s, d) => s + (d.targeted ?? 0), 0),
  reached: reportedRows.reduce((s, d) => s + (d.reached ?? 0), 0),
  reportedTargeted: reportedRows.reduce((s, d) => s + (d.targeted ?? 0), 0),
  reported: reportedRows.length,
  noReport: yearRows.filter((d) => d.result_status === "no report").length,
  inProgress: yearRows.filter((d) => d.result_status === "in progress").length,
  planned: yearRows.filter((d) => d.result_status === "planned").length,
  above: reportedRows.filter((d) => d.admin_coverage >= 0.95).length,
  below: reportedRows.filter((d) => d.admin_coverage < 0.8).length
};
kpi.coverage = kpi.reportedTargeted > 0 ? kpi.reached / kpi.reportedTargeted : null;
const yearSurveys = stateSurveyRows.filter((s) => year === "All" || s.year === Number(year));
const yearLgaSurveys = yearRows.filter((d) => d.survey_coverage != null);
const scope = `${programme === "All" ? "all programmes" : programme} · ${state === "All" ? "five states" : `${state} State`} · ${year === "All" ? "all years" : year}`;
const red = (t) => html`<span style="color:#b91c1c">${t}</span>`;
const sep = (parts) => parts.filter(Boolean).flatMap((p, i) => i ? [" · ", p] : [p]);
const coverageNote = html`<span>${kpi.reported ? sep([`${fmtInt(kpi.above)} round${kpi.above === 1 ? "" : "s"} at ≥ 95%`, kpi.below ? red(`${fmtInt(kpi.below)} below 80%`) : "none below 80%"]) : "—"}</span>`;
const nSurveys = yearSurveys.length + yearLgaSurveys.length;
const reportingParts = sep([
  kpi.noReport ? red(`${fmtInt(kpi.noReport)} not reported`) : "",
  kpi.inProgress ? `${fmtInt(kpi.inProgress)} in progress` : "",
  kpi.planned ? `${fmtInt(kpi.planned)} planned` : "",
  nSurveys ? `${fmtInt(nSurveys)} post-campaign survey${nSurveys === 1 ? "" : "s"}` : ""
]);
const reportingNote = html`<span>${reportingParts.length ? reportingParts : "every round reported"}</span>`;
```

<div class="grid grid-cols-4" style="gap: 12px">
  <div class="card"><h2>People targeted</h2><span class="big">${fmtInt(kpi.targeted)}</span><div class="muted">${fmtInt(kpi.rounds)} LGA round${kpi.rounds === 1 ? "" : "s"} in ${fmtInt(kpi.lgas)} LGA${kpi.lgas === 1 ? "" : "s"} · ${scope}</div></div>
  <div class="card"><h2>People reached</h2><span class="big">${kpi.reported ? fmtInt(kpi.reached) : "—"}</span><div class="muted">${kpi.reported ? `of ${fmtInt(kpi.reportedTargeted)} targeted in the ${fmtInt(kpi.reported)} reported round${kpi.reported === 1 ? "" : "s"}` : "no administrative reports"}</div></div>
  <div class="card"><h2>Administrative coverage</h2><span class="big">${kpi.coverage != null ? fmtPct(kpi.coverage) : "—"}</span><div class="muted">${coverageNote}</div></div>
  <div class="card"><h2>Reporting</h2><span class="big">${fmtInt(kpi.reported)}<span class="muted" style="font-size:16px"> of ${fmtInt(kpi.rounds)}</span></span><div class="muted">${reportingNote}</div></div>
</div>

<div class="grid grid-cols-2" style="gap: 12px; margin-top: 12px">
  <div class="card" style="padding: 0; overflow: hidden">
    <div class="map-title">People targeted per LGA, ${year === "All" ? "all years" : year}</div>
    ${mapTargeted}
  </div>
  <div class="card" style="padding: 0; overflow: hidden">
    <div class="map-title">Administrative coverage per LGA, ${year === "All" ? "all years" : year} <span class="muted">(reached ÷ targeted over reported rounds; grey = no report)</span></div>
    ${mapCoverage}
  </div>
</div>

```js
const pmtiles = await FileAttachment("data/admin.pmtiles").arrayBuffer();
const stateLabels = toRows(await sql`SELECT id, name, lon, lat FROM admin_units WHERE admin_level = 1 AND country = 'NGA'`);
const mapTargeted = campaignMap({pmtiles, height: 440, basemap: BASEMAP, labels: stateLabels, metric: "targeted"});
const mapCoverage = campaignMap({pmtiles, height: 440, basemap: BASEMAP, labels: stateLabels, metric: "coverage"});
syncMaps(mapTargeted, mapCoverage);
const DEFAULT_BOUNDS = [[7.4, 8.8], [13.9, 13.9]];
```

```js
mapTargeted.update(yearRows);
mapCoverage.update(yearRows);
```

```js
// Zoom to the drilled state (the maps are synced, so moving one moves both).
{
  const b = drilled ? stateBounds.get(state) ?? DEFAULT_BOUNDS : DEFAULT_BOUNDS;
  if (mapTargeted.clientWidth > 0) mapTargeted.map.fitBounds(b, {padding: 20, duration: 400});
}
```

<div class="grid grid-cols-2" style="gap: 12px; margin-top: 12px">
  <div class="card">
    <h2>People targeted and reached by year${drilled ? `, ${state} State` : ""}</h2>
    <div class="muted" style="margin-bottom: 6px">Per year${drilled ? "" : ", one panel per state"}: the grey bar is people targeted (planning denominators of every round), the green bar inside it is people reached in the reported rounds. Later years are still planned or in progress, so reached lags targeted and 2027 has none yet.</div>
    ${peoplePlot}
  </div>
  <div class="card">
    <h2>Administrative coverage by year and ${unitWord}</h2>
    <div class="muted" style="margin-bottom: 6px">Reached ÷ targeted over the reported rounds of each ${unitWord} and year. Grey cells have no reported round yet.${drilled ? "" : " Pick a state above to drill into its LGAs."}</div>
    ${heatmap}
  </div>
</div>

```js
// One bar per year × series; stacked by state at the top level, a single summed bar when drilled.
const peopleRows = drilled
  ? years.flatMap((y) => {
      const rows = byYear.filter((d) => d.year === y);
      return [
        {year: y, unit: state, series: "targeted", value: d3.sum(rows, (d) => d.targeted)},
        {year: y, unit: state, series: "reached", value: d3.sum(rows, (d) => d.reached)}
      ];
    })
  : byYear.flatMap((d) => [
      {year: d.year, unit: d.unit, series: "targeted", value: d.targeted},
      {year: d.year, unit: d.unit, series: "reached", value: d.reached}
    ]);
const targetedRows = peopleRows.filter((d) => d.series === "targeted");
const reachedRows = peopleRows.filter((d) => d.series === "reached" && d.value > 0);
const barTitle = (d) => `${d.year} · ${d.unit}${drilled ? " State" : ""}\n${d.series === "targeted" ? "people targeted" : "people reached (reported rounds)"}: ${fmtInt(d.value)}`;
const peoplePlot = Plot.plot({
  width: Math.max(320, width / 2 - 40),
  height: 300,
  marginLeft: 50, marginBottom: 30,
  ...(drilled ? {} : {fx: {label: null, domain: states, padding: 0.15}}),
  x: {label: null, domain: years, ticks: drilled ? years : years.filter((_, i) => i % 2 === 0), tickFormat: (d) => drilled ? String(d) : `’${String(d).slice(2)}`, tickSize: 0, padding: 0.15},
  y: {label: "people", grid: true, tickFormat: fmtCompact},
  color: {domain: ["targeted", "reached"], range: ["#cbd5e1", "#238b45"], legend: true},
  marks: [
    Plot.barY(targetedRows, {...(drilled ? {} : {fx: "unit"}), x: "year", y: "value", fill: "series", tip: true, title: barTitle}),
    Plot.barY(reachedRows, {...(drilled ? {} : {fx: "unit"}), x: "year", y: "value", fill: "series", insetLeft: 3, insetRight: 3, tip: true, title: barTitle}),
    Plot.ruleY([0])
  ]
});
```

```js
const cellRows = byYear;
const missing = cellRows.filter((d) => d.coverage == null);
const heatmap = Plot.plot({
  width: Math.max(320, width / 2 - 40),
  height: 60 + 24 * Math.max(4, units.length),
  marginLeft: drilled ? 110 : 70, marginTop: 24,
  x: {label: null, domain: years, tickFormat: (d) => String(d), axis: "top"},
  y: {label: null, domain: units},
  color: {type: "threshold", domain: COVERAGE_BREAKS, range: COVERAGE_COLORS, legend: true, tickFormat: (d) => `${Math.round(d * 100)}%`, label: "administrative coverage"},
  marks: [
    Plot.cell(missing, {x: "year", y: "unit", fill: "#eef0f3", inset: 1}),
    Plot.cell(cellRows.filter((d) => d.coverage != null), {x: "year", y: "unit", fill: "coverage", inset: 1, tip: true,
      title: (d) => `${d.unit}, ${d.year}\n${fmtInt(d.reached)} reached of ${fmtInt(d.reportedTargeted)} targeted (${fmtPct(d.coverage)})\n${d.reported} of ${d.rounds} rounds reported${d.survey_text ? `\nsurvey: ${d.survey_text}` : ""}`}),
    Plot.text(cellRows, {x: "year", y: "unit", text: (d) => d.coverage != null ? fmtPct(d.coverage) : d.coverage_text === "planned" ? "planned" : d.coverage_text === "in progress" ? "…" : "no report",
      fill: (d) => d.coverage != null ? "#111" : "#94a3b8", fontSize: 11})
  ]
});
```

## By year and ${unitWord}

```js
const search = view(Inputs.search(byYear, {placeholder: `Search ${unitWord}, year…`, columns: ["unit", "year", "coverage_text", "survey_text"]}));
```

```js
Inputs.table(search, {
  columns: ["year", "unit", "programmes", "reported_text", "targeted", "reached_text", "coverage_text", "survey_text", "lqas_text"],
  header: {year: "Year", unit: unitLabel, programmes: "Programmes", reported_text: "Rounds reported", targeted: "Targeted", reached_text: "Reached", coverage_text: "Admin cov.", survey_text: "Survey", lqas_text: "LQAS"},
  format: {year: (d) => String(d), targeted: (d) => fmtInt(d)},
  align: {reached_text: "right", coverage_text: "right", survey_text: "right", lqas_text: "right"},
  width: {year: 55, unit: 120, programmes: 90, reported_text: 130, targeted: 100, reached_text: 100, coverage_text: 90, survey_text: 120, lqas_text: 90},
  rows: 20
})
```

<div class="muted" style="margin-top: 8px">
  ${fmtInt(search.length)} of ${fmtInt(byYear.length)} ${unitWord} × year rows${drilled ? ` for ${state} State` : ""}.
  Targeted sums every round's planning denominator${programme === "All" ? " across programmes, so a person targeted by two campaigns counts twice" : ""};
  reached and administrative coverage use only the rounds with a reconciled report. Coverage above 100% means the
  projection undercounted the population. Survey is the post-campaign coverage survey${drilled ? " (LGA coverage evaluation survey)" : " (state-level, on the state's campaign)"}
  with its 95% confidence interval; LQAS counts the polio and MR lots that passed.
</div>

<style>
.big { font-size: 28px; font-weight: 600; line-height: 1.1; }
.map-title { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); padding: 10px 14px 6px; }
.card h2 { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); margin: 0 0 4px; }
.maplibregl-popup-content { padding: 6px 9px; }
</style>
