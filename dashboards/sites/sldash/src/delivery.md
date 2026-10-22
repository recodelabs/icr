---
title: Delivery
sql:
  values: data/values.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Delivery

```js
import {item, pivot, legendKey} from "./components/dhis2.js";
import {columns, thematic, periodName} from "./components/charts.js";
import {load, pick, relative, DISTRICTS} from "./components/page.js";
import {unitMap} from "./components/unit-map.js";

// DHIS2 uids of the items on the demo's Delivery dashboard.
const DX = {
  phuByBirths: "EoYar8UxddG", phuByAnc1: "n0GE1ISYrdM", phuByPop: "Q3M7Htpzg1Y",
  skilledBirths: "ulgL07PF8rq", skilledPop: "elTqMUTRgdk",
  birthsPhu: "Rigf2d2Zbjp", birthsCommunity: "RdkKj1rVp8R",
  anc1Cov: "Uvn6LCg7dVU", anc4Cov: "AUqdhY4mpvp", liveBirths: "gQNFkFkObU8",
  rhRate: "QX4ZTUbOt3a.REPORTING-RATE"
};
const RATES = [DX.phuByBirths, DX.phuByAnc1, DX.phuByPop];
// The 14 facilities DHIS2's "Live births in facilities" table lists.
const BIRTH_FACILITIES = ["Baoma Station CHP", "Blamawo MCHP", "Faabu CHP", "Gerehun CHC", "Golu MCHP", "Jembe CHC", "Jormu MCHP",
  "Kigbai MCHP", "Kpumbu MCHP", "Mbundorbu MCHP", "Pelewahun (Baoma) MCHP", "Tugbebu CHP", "Yakaji MCHP", "Yamandu CHC"];
// The demo's "ANC Coverage" legend set (used on the chiefdom map).
const ANC_LEGEND = [
  {name: "Low", start: 0, end: 30, color: "#BD0026"},
  {name: "Medium", start: 30, end: 50, color: "#F03B20"},
  {name: "Medium Pl.", start: 50, end: 70, color: "#FD8D3C"},
  {name: "High", start: 70, end: 80, color: "#FEB24C"},
  {name: "High Plus", start: 80, end: 90, color: "#FED976"},
  {name: "Great", start: 90, end: 120, color: "#FFFFB2"},
  {name: "Invalid", start: 120, end: 1000, color: "#CCCCCC"}
];
const all = await load(sql, Object.values(DX));
const years = Array.from(new Set(all.filter((d) => d.period_type === "Yearly").map((d) => d.period))).sort();
const geojson = await FileAttachment("data/units.geojson").json();
const nameOf = (dx) => all.find((d) => d.dx === dx)?.name ?? dx;
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
const sortedBy = (dx) => pick(all, {dx, level: 1, periods: [P.thisYear]}).sort((a, b) => b.value - a.value).map((d) => d.location_name);
// DHIS2's "user org unit and its children": the country, then the districts.
const OU = ["Sierra Leone", ...DISTRICTS];
const byOrgUnit = (dx, periods) => all.filter((d) => [].concat(dx).includes(d.dx) && (d.admin_level === 0 || d.admin_level === 1) && periods.includes(d.period));
const facilityBirths = all.filter((d) => d.dx === DX.liveBirths && d.admin_level == null && BIRTH_FACILITIES.includes(d.location_name) && P.last4Quarters.includes(d.period));
```

<div class="d2-filter">${yearInput}<span class="muted">DHIS2's relative periods (this year, last 4 quarters) count from this year.</span></div>

<div style="margin-bottom: 16px">
${item(`Delivery: Institutional delivery rates ${year}`,
  columns(cat(pick(all, {dx: RATES, level: 1, periods: [P.thisYear]}), (d) => d.location_name, (d) => d.name),
    {width: width - 40, yLabel: "%", categoryOrder: DISTRICTS, seriesOrder: RATES.map(nameOf)}))}
</div>

<div class="grid grid-cols-2" style="gap: 16px">
${item("Delivery: Live births in facilities last 4 quarters", html`<div style="max-height: 420px; overflow: auto">${pivot(facilityBirths,
    {row: (d) => d.location_name, col: (d) => periodName(d.period), rowOrder: BIRTH_FACILITIES, colOrder: P.last4Quarters.map(periodName), digits: 0, rowLabel: "Facility"})}</div>`)}
${item(`Delivery: Births (registered) in PHU vs Community ${year}`,
  columns(cat(pick(all, {dx: [DX.birthsPhu, DX.birthsCommunity], level: 0, periods: [P.thisYear]}), (d) => d.name, (d) => d.period),
    {width: w(2), categoryOrder: [nameOf(DX.birthsPhu), nameOf(DX.birthsCommunity)]}))}
${item(`Delivery: Birth by skilled attendant (estimated vs population, sorted) ${year}`,
  columns(cat(pick(all, {dx: [DX.skilledBirths, DX.skilledPop], level: 1, periods: [P.thisYear]}), (d) => d.location_name, (d) => d.name),
    {width: w(2), yLabel: "%", categoryOrder: sortedBy(DX.skilledPop), seriesOrder: [nameOf(DX.skilledBirths), nameOf(DX.skilledPop)]}))}
${item(`Delivery: Birth by skilled attendant ${year} (sorted)`,
  columns(cat(pick(all, {dx: DX.skilledBirths, level: 1, periods: [P.thisYear]}), (d) => d.location_name, (d) => d.name),
    {width: w(2), yLabel: "%", categoryOrder: sortedBy(DX.skilledBirths)}))}
${item(`Delivery: PHU delivery rate (by pop) by chiefdom ${P.lastYear}`, html`${phuMap}${legendKey(ANC_LEGEND)}`)}
${item(`Reporting Rates: RH by orgunit ${year}`,
  columns(cat(byOrgUnit(DX.rhRate, [P.thisYear]), (d) => d.location_name, (d) => d.name),
    {width: w(2), yLabel: "%", categoryOrder: OU}))}
${item(`Delivery: ANC coverage vs PHU delivery rate ${year}`,
  columns(cat(pick(all, {dx: [DX.anc1Cov, DX.anc4Cov, DX.phuByPop], level: 0, periods: [P.thisYear]}), (d) => d.period, (d) => d.name),
    {width: w(2), yLabel: "%", seriesOrder: [nameOf(DX.anc1Cov), nameOf(DX.anc4Cov), nameOf(DX.phuByPop)]}))}
${item(`Delivery: PHU delivery rates ${year}`,
  columns(cat(pick(all, {dx: RATES, level: 0, periods: [P.thisYear]}), (d) => d.period, (d) => d.name),
    {width: w(2), yLabel: "%", seriesOrder: RATES.map(nameOf)}))}
${item(`Delivery: PHU delivery rate (by pop.) by orgunit ${year}`,
  columns(cat(byOrgUnit(DX.phuByPop, [P.thisYear]), (d) => d.location_name, (d) => d.name),
    {width: w(2), yLabel: "%", categoryOrder: OU}))}
${item(`Delivery: Births attended by skilled health personnel by orgunit ${year}`,
  columns(cat(byOrgUnit([DX.skilledBirths, DX.skilledPop], [P.thisYear]), (d) => d.location_name, (d) => d.name),
    {width: w(2), yLabel: "%", categoryOrder: OU, seriesOrder: [nameOf(DX.skilledBirths), nameOf(DX.skilledPop)]}))}
</div>

```js
const phuMap = unitMap({geojson, height: 380});
thematic(phuMap, pick(all, {dx: DX.phuByPop, level: 2, periods: [P.lastYear]}), {level: 2, legend: ANC_LEGEND, label: "PHU delivery rate (by expected pregnancies) (%)"});
```

<div class="muted d2-footer">
Rebuilt from the demo DHIS2's <b>Delivery</b> dashboard (play.dhis2.org, Sierra Leone) with the values
imported into the registry by <code>kiln dhis2</code>. All 11 items are shown. "User org unit and its
children" is Sierra Leone and its 13 districts, as for the demo's admin user.
</div>
