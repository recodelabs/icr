---
title: Reporting Rates
sql:
  values: data/values.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Reporting Rates

```js
import {item, pivot, legendKey, COVERAGE_LEGEND} from "./components/dhis2.js";
import {columns, lines, thematic, periodName} from "./components/charts.js";
import {load, pick, relative, DISTRICTS} from "./components/page.js";
import {unitMap} from "./components/unit-map.js";

// DHIS2 uids of the items on the demo's Reporting Rates dashboard. A reporting rate is
// actual ÷ expected reports of a data set, in percent.
const DX = {
  morbidity: "eZDhcZi6FLP.REPORTING-RATE", childHealth: "BfMAe6Itzgt.REPORTING-RATE", rh: "QX4ZTUbOt3a.REPORTING-RATE",
  hiv: "EDzMBk0RRji.REPORTING-RATE", pmtct: "Rl58JxmKJo2.REPORTING-RATE", tb: "OsPTWNqq26W.REPORTING-RATE",
  anc3Cov: "sB79w2hiLp8", skilledPop: "elTqMUTRgdk", phuByPop: "Q3M7Htpzg1Y"
};
const PHUF = [DX.morbidity, DX.childHealth, DX.rh];
// The demo's "Reporting rates" legend set.
const REPORTING_LEGEND = [
  {name: "Non reporting", start: 0, end: 30, color: "#08519C"},
  {name: "Low", start: 30, end: 60, color: "#3182BD"},
  {name: "Medium", start: 60, end: 80, color: "#6baed6"},
  {name: "High", start: 80, end: 90, color: "#BDD7E7"},
  {name: "Excellent", start: 90, end: 100, color: "#EFF3FF"},
  {name: "Invalid", start: 100, end: 1000, color: "#CCCCCC"}
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
const monthly = (dxs) => cat(pick(all, {dx: dxs, level: 0, periods: P.last12Months}), (d) => d.period, (d) => d.name);
const lineOpts = (dxs) => ({width: w(2), yLabel: "%", categoryOrder: P.last12Months, seriesOrder: dxs.map(nameOf), format: periodName});
```

<div class="d2-filter">${yearInput}<span class="muted">DHIS2's relative periods (last month, last quarter, last 12 months, last 4 quarters) count from this year.</span></div>

<div class="grid grid-cols-2" style="gap: 16px">
${item(`Reporting rates: PHUF 3 at chiefdoms, ${periodName(P.lastMonth ?? "")}`, rhMap,
  {note: "DHIS2 shows this month and last month together; the registry holds each month on its own, so this is the latest complete month."})}
${item(`Reporting rates: PHUF 1 at chiefdoms, ${periodName(P.lastQuarter ?? "")}`, html`${morbidityMap}${legendKey(REPORTING_LEGEND)}`,
  {note: "DHIS2 shows this quarter and last quarter together; this is the latest complete quarter."})}
${item("Reporting Rates: PHUF Forms Trends", lines(monthly(PHUF), lineOpts(PHUF)))}
${item("Reporting Rates: PHUF Forms Last 4 Quarters",
  columns(cat(pick(all, {dx: PHUF, level: 0, periods: P.last4Quarters}), (d) => periodName(d.period), (d) => d.name),
    {width: w(2), yLabel: "%", categoryOrder: P.last4Quarters.map(periodName), seriesOrder: PHUF.map(nameOf)}))}
${item("Reporting Rates: PHU forms", html`<div style="max-height: 520px; overflow: auto">${pivot(
    all.filter((d) => PHUF.includes(d.dx) && (d.admin_level === 0 || d.admin_level === 1) && P.last4Quarters.includes(d.period)),
    {row: (d) => `${periodName(d.period)} · ${d.location_name}`, col: (d) => d.name, colOrder: PHUF.map(nameOf), rowLabel: "Period · org unit",
     rowOrder: P.last4Quarters.flatMap((q) => ["Sierra Leone", ...DISTRICTS].map((n) => `${periodName(q)} · ${n}`))})}</div>`)}
${item(`Reporting rates: PHUF 2 at chiefdoms, ${periodName(P.lastQuarter ?? "")}`, html`${childMap}${legendKey(COVERAGE_LEGEND)}`,
  {note: "DHIS2 shows this quarter and last quarter together; this is the latest complete quarter. DHIS2 colours this map with its Immunization Coverage legend set."})}
${item("Reporting Rates: HIV, PMTCT, TB Trends", lines(monthly([DX.hiv, DX.pmtct, DX.tb]), lineOpts([DX.hiv, DX.pmtct, DX.tb])))}
${item("RCH: ANC-Delivery-Reporting Rates Monthly",
  lines(monthly([DX.anc3Cov, DX.skilledPop, DX.phuByPop, DX.rh]), lineOpts([DX.anc3Cov, DX.skilledPop, DX.phuByPop, DX.rh])),
  {note: "The ANC and delivery indicators are annualised: each month's value is scaled to a year."})}
</div>

```js
const rhMap = unitMap({geojson, height: 380});
thematic(rhMap, pick(all, {dx: DX.rh, level: 2, periods: [P.lastMonth]}), {level: 2, label: "Reproductive Health - Reporting rate (%)"});
const morbidityMap = unitMap({geojson, height: 380});
thematic(morbidityMap, pick(all, {dx: DX.morbidity, level: 2, periods: [P.lastQuarter]}), {level: 2, legend: REPORTING_LEGEND, label: "Morbidity - Reporting rate (%)"});
const childMap = unitMap({geojson, height: 380});
thematic(childMap, pick(all, {dx: DX.childHealth, level: 2, periods: [P.lastQuarter]}), {level: 2, legend: COVERAGE_LEGEND, label: "Child Health - Reporting rate (%)"});
```

<div class="muted d2-footer">
Rebuilt from the demo DHIS2's <b>Reporting Rates</b> dashboard (play.dhis2.org, Sierra Leone) with the
values imported into the registry by <code>kiln dhis2</code>. All 8 items are shown. PHUF 1, 2 and 3 are the
Morbidity, Child Health and Reproductive Health forms. A reporting rate is the actual reports received
divided by the reports expected, so it is never summed across places or periods here.
</div>
