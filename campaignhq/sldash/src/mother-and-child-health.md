---
title: Mother and Child Health
sql:
  values: data/values.parquet
  strata: data/strata.parquet
  facilities: data/facilities.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Mother and Child Health

```js
import {item, pie, pivot, legendKey, rows, fmt, PALETTE, RAMP, INVALID, ALERT} from "./components/dhis2.js";
import {columns, lines, thematic, periodName} from "./components/charts.js";
import {load, loadStrata, pick, pickStrata, relative, DISTRICTS, DIM, COUNTRY_ID} from "./components/page.js";
import {unitMap} from "./components/unit-map.js";

// DHIS2 uids of the items on the demo's Mother and Child Health dashboard.
const DX = {
  anc1Cov: "Uvn6LCg7dVU", anc2Cov: "OdiHJayrsKo", anc3Cov: "sB79w2hiLp8", dropout13: "ReUHfIn0pTQ",
  ipt1Cov: "dwEq7wi6nXV", ipt2Cov: "c8fABiNpT0B", llitnCov: "Tt5TAvdfdVK", slept: "nkjlWUMIdHh",
  anc1: "fbfJHSPpUQD", anc2: "cYeuwXTCPkU", anc3: "Jtf34kNZhzP", anc4: "hfdmMSPBgLG"
};
const all = await load(sql, Object.values(DX));
const byType = await loadStrata(sql, [DX.anc1, DX.anc2, DX.anc3, DX.anc4], DIM.facilityType);
const byPlace = await loadStrata(sql, [DX.anc1, DX.anc2, DX.anc3], DIM.fixedOutreach);
const facilities = rows(await sql`SELECT * FROM facilities`);
const years = Array.from(new Set(all.filter((d) => d.period_type === "Yearly").map((d) => d.period))).sort();
const geojson = await FileAttachment("data/units.geojson").json();
const nameOf = (dx) => all.find((d) => d.dx === dx)?.name ?? dx;
// The demo's "ANC Coverage" legend set (used on its ANC maps).
const ANC_LEGEND = [
  {name: "Low", start: 0, end: 30, color: RAMP[0]},
  {name: "Medium", start: 30, end: 50, color: RAMP[1]},
  {name: "Medium Pl.", start: 50, end: 70, color: RAMP[2]},
  {name: "High", start: 70, end: 80, color: RAMP[3]},
  {name: "High Plus", start: 80, end: 90, color: RAMP[4]},
  {name: "Great", start: 90, end: 120, color: RAMP[5]},
  {name: "Invalid", start: 120, end: 1000, color: INVALID}
];
const TYPES = ["CHC", "CHP", "Clinic", "Hospital", "MCHP"];
```

```js
const yearInput = Inputs.select(years, {label: "This year", value: years.at(-1)});
const selectedYear = Generators.input(yearInput);
```

```js
const year = Number(selectedYear);
const P = relative(all, year);
const w = (n) => Math.max(320, (width - 24) / n - 24);
const cat = (rows, category, series) => rows.map((d) => ({category: category(d), series: series(d), value: d.value}));
// Facility values (admin_level null) of one item for one period.
const atFacilities = (dx, period) => all.filter((d) => d.dx === dx && d.admin_level == null && d.period === period);
```

<div class="d2-filter">${yearInput}<span class="muted">DHIS2's relative periods (this year, last 12 months) count from this year.</span></div>

<div class="grid grid-cols-2" style="gap: 16px">
${item(`ANC: Slept under LLITN last night chiefdom ${year}`, html`${sleptMap}${legendKey(ANC_LEGEND)}`)}
${item("ANC: LLITN last 12 months (user org unit)",
  columns(cat(pick(all, {dx: [DX.llitnCov, DX.slept], level: 0, periods: P.last12Months}), (d) => periodName(d.period), (d) => d.name),
    {width: w(2), yLabel: "%", categoryOrder: P.last12Months.map(periodName), seriesOrder: [nameOf(DX.llitnCov), nameOf(DX.slept)]}))}
${item(`ANC: 4+ visits by Facility ${year}`,
  pie(pickStrata(byType, {dx: DX.anc4, location_id: COUNTRY_ID, periods: [P.thisYear]})
      .map((d) => ({name: d.option_name, value: d.value})).sort((a, b) => a.name.localeCompare(b.name)), {width: w(2)}),
  {note: "By facility type, as in DHIS2."})}
${item(`ANC: ANC IPT 2 and LLITN coverage ${year}`, html`${iptLlitnMap}${legendKey(ANC_LEGEND)}`,
  {note: "LLITN coverage per chiefdom as areas; IPT 2 coverage per facility as points (facilities with coordinates only)."})}
${item(`ANC: IPT 2 Cov Chiefdom ${year}`, html`${iptMap}${legendKey(ANC_LEGEND)}`)}
${item(`ANC: Visits by facility type ${year}`,
  columns(pickStrata(byType, {dx: [DX.anc1, DX.anc2, DX.anc3], location_id: COUNTRY_ID, periods: [P.thisYear]})
      .map((d) => ({category: d.option_name, series: nameOf(d.dx), value: d.value})),
    {width: w(2), categoryOrder: TYPES, seriesOrder: [DX.anc1, DX.anc2, DX.anc3].map(nameOf)}))}
${item(`ANC: Key Coverages ${year}`,
  pivot(pick(all, {dx: [DX.anc1Cov, DX.anc2Cov, DX.anc3Cov], level: 0, periods: [P.thisYear]}),
    {row: (d) => `${d.period} · ${d.location_name}`, col: (d) => d.name, colOrder: [DX.anc1Cov, DX.anc2Cov, DX.anc3Cov].map(nameOf), rowLabel: "Period · org unit"}))}
${item("ANC: IPT 1 and 2 trends",
  lines(cat(pick(all, {dx: [DX.ipt1Cov, DX.ipt2Cov], level: 0, periods: P.last12Months}), (d) => d.period, (d) => d.name),
    {width: w(2), yLabel: "%", categoryOrder: P.last12Months, format: periodName, seriesOrder: [nameOf(DX.ipt1Cov), nameOf(DX.ipt2Cov)]}))}
${item(`ANC: ANC 1 Coverage Chiefdoms ${year}`, html`${anc1Map}${legendKey(ANC_LEGEND)}`)}
${item(`ANC: 1 and 3 coverage Yearly (${year})`,
  columns(cat(pick(all, {dx: [DX.anc1Cov, DX.anc3Cov], periods: [P.thisYear]}).filter((d) => d.admin_level === 0 || d.admin_level === 1), (d) => d.location_name, (d) => d.name),
    {width: w(2), horizontal: true, yLabel: "%", categoryOrder: ["Sierra Leone", ...DISTRICTS], seriesOrder: [nameOf(DX.anc1Cov), nameOf(DX.anc3Cov)]}))}
${item(`ANC: 1-3 dropout rate Yearly (${year})`, dropoutChart, {note: "Target line at 25%, as set on the DHIS2 chart."})}
${item(`ANC: 3rd visit coverage ${year} by district`, anc3Map)}
${item(`ANC: ANC visits by fixed/outreach ${year}`,
  columns(pickStrata(byPlace, {dx: [DX.anc1, DX.anc2, DX.anc3], location_id: COUNTRY_ID, periods: [P.thisYear]})
      .map((d) => ({category: d.option_name, series: nameOf(d.dx), value: d.value})),
    {width: w(2), categoryOrder: ["Fixed", "Outreach"], seriesOrder: [DX.anc1, DX.anc2, DX.anc3].map(nameOf)}))}
${item("ANC: 1st and 3rd trends Monthly",
  lines(cat(pick(all, {dx: [DX.anc1Cov, DX.anc3Cov], level: 0, periods: P.last12Months}), (d) => d.period, (d) => d.name),
    {width: w(2), yLabel: "%", categoryOrder: P.last12Months, format: periodName, seriesOrder: [nameOf(DX.anc1Cov), nameOf(DX.anc3Cov)]}),
  {note: "Annualised: each month's value is scaled to a year."})}
</div>

```js
const sleptMap = unitMap({geojson, height: 380});
thematic(sleptMap, pick(all, {dx: DX.slept, level: 2, periods: [P.thisYear]}), {level: 2, legend: ANC_LEGEND, label: "Slept under LLITN last night (%)"});
const iptLlitnMap = unitMap({geojson, height: 380});
thematic(iptLlitnMap, [...pick(all, {dx: DX.llitnCov, level: 2, periods: [P.thisYear]}), ...atFacilities(DX.ipt2Cov, P.thisYear)],
  {level: 2, legend: ANC_LEGEND, label: "LLITN (areas), IPT 2 (points) (%)", points: facilities});
const iptMap = unitMap({geojson, height: 380});
thematic(iptMap, pick(all, {dx: DX.ipt2Cov, level: 2, periods: [P.thisYear]}), {level: 2, legend: ANC_LEGEND, label: "ANC IPT 2 Coverage (%)"});
const anc1Map = unitMap({geojson, height: 380});
thematic(anc1Map, pick(all, {dx: DX.anc1Cov, level: 2, periods: [P.thisYear]}), {level: 2, legend: ANC_LEGEND, label: "ANC 1 Coverage (%)"});
const anc3Map = unitMap({geojson, height: 380});
thematic(anc3Map, pick(all, {dx: DX.anc3Cov, level: 1, periods: [P.thisYear]}), {level: 1, label: "ANC 3 Coverage (%)"});
```

```js
// COLUMN with DHIS2's target line: one bar per district, a rule at the target.
const dropoutRows = pick(all, {dx: DX.dropout13, level: 1, periods: [P.thisYear]});
const dropoutChart = Plot.plot({
  width: w(2), height: 340, marginLeft: 55, marginBottom: 80,
  x: {domain: DISTRICTS, label: null, tickRotate: -40},
  y: {label: "%", grid: true},
  marks: [
    Plot.barY(dropoutRows, {x: "location_name", y: "value", fill: PALETTE[0], tip: true,
      title: (d) => `${d.location_name}\n${d.name}: ${fmt(d.value)}`}),
    Plot.ruleY([25], {stroke: ALERT, strokeDasharray: "4,3"}),
    Plot.text([25], {x: DISTRICTS.at(-1), y: (d) => d, text: () => "Target 25", dy: -6, textAnchor: "end", fill: ALERT}),
    Plot.ruleY([0])
  ]
});
```

<div class="muted d2-footer">
Rebuilt from the demo DHIS2's <b>Mother and Child Health</b> dashboard (play.dhis2.org, Sierra Leone) with
the values imported into the registry by <code>kiln dhis2</code>: all 14 data items. Not shown: the
messages, reports and one empty item, which hold no data. Facility-type and fixed/outreach items read the
breakdowns DHIS2 computes for the country; facility points are the facilities DHIS2 has coordinates for.
</div>
