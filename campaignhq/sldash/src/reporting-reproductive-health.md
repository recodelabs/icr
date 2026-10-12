---
title: Reporting Reproductive Health
sql:
  values: data/values.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Reporting Reproductive Health

```js
import {item, pivot} from "./components/dhis2.js";
import {columns, thematic, periodName} from "./components/charts.js";
import {load, pick, relative, DISTRICTS} from "./components/page.js";
import {unitMap} from "./components/unit-map.js";

// DHIS2 uids of the items on the demo's Reporting Reproductive Health dashboard: the
// reporting rates (actual ÷ expected reports, in percent) of the three major PHU forms.
const DX = {childHealth: "BfMAe6Itzgt.REPORTING-RATE", rh: "QX4ZTUbOt3a.REPORTING-RATE", morbidity: "eZDhcZi6FLP.REPORTING-RATE"};
const MAJOR = [DX.childHealth, DX.rh, DX.morbidity];
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
// DHIS2's "user org unit and its children": the country, then the districts.
const OU = ["Sierra Leone", ...DISTRICTS];
const byOrgUnit = (dx, periods) => all.filter((d) => [].concat(dx).includes(d.dx) && (d.admin_level === 0 || d.admin_level === 1) && periods.includes(d.period));
const byOu = (dx, periods) => columns(cat(byOrgUnit(dx, periods), (d) => d.location_name, (d) => d.name), {width: w(2), yLabel: "%", categoryOrder: OU});
const monthNote = "DHIS2 shows this month and last month together; the registry holds each month on its own, so this is the latest complete month.";
```

<div class="d2-filter">${yearInput}<span class="muted">DHIS2's relative periods (this year, last month, last 12 months) count from this year.</span></div>

<div class="grid grid-cols-2" style="gap: 16px">
${item("Reporting rates: Major forms last 12 months",
  columns(cat(pick(all, {dx: MAJOR, level: 0, periods: P.last12Months}), (d) => periodName(d.period), (d) => d.name),
    {width: w(2), yLabel: "%", categoryOrder: P.last12Months.map(periodName), seriesOrder: MAJOR.map(nameOf)}))}
${item(`Reporting rates: Major forms ${year}`,
  columns(cat(pick(all, {dx: MAJOR, level: 0, periods: [P.thisYear]}), (d) => d.period, (d) => d.name),
    {width: w(2), yLabel: "%", seriesOrder: MAJOR.map(nameOf)}))}
${item(`Reporting Rates: RH by orgunit, ${periodName(P.lastMonth ?? "")}`, byOu(DX.rh, [P.lastMonth]), {note: monthNote})}
${item(`Reporting Rates: RH by orgunit ${year}`, byOu(DX.rh, [P.thisYear]))}
${item(`Reporting rates: Major forms by orgunit ${year}`, html`<div style="max-height: 420px; overflow: auto">${pivot(byOrgUnit(MAJOR, [P.thisYear]),
    {row: (d) => d.location_name, col: (d) => d.name, rowOrder: OU, colOrder: MAJOR.map(nameOf), rowLabel: "Org unit"})}</div>`)}
${item(`Reporting rates: Child Health by orgunit ${year}`, byOu(DX.childHealth, [P.thisYear]))}
${item(`Reporting rates: Morbidity by orgunit ${year}`, byOu(DX.morbidity, [P.thisYear]))}
${item(`Reporting rates: Child Health by district, ${periodName(P.lastMonth ?? "")}`, childMonthMap, {note: monthNote})}
${item(`Reporting rates: Child health by district ${year}`, childYearMap)}
${item("Reporting rates: Major forms last 12 months (table)", html`<div style="max-height: 420px; overflow: auto">${pivot(pick(all, {dx: MAJOR, level: 0, periods: P.last12Months}),
    {row: (d) => periodName(d.period), col: (d) => d.name, rowOrder: P.last12Months.map(periodName), colOrder: MAJOR.map(nameOf), rowLabel: "Month"})}</div>`)}
</div>

```js
const childMonthMap = unitMap({geojson, height: 380});
thematic(childMonthMap, pick(all, {dx: DX.childHealth, level: 1, periods: [P.lastMonth]}), {level: 1, label: "Child Health - Reporting rate (%)"});
const childYearMap = unitMap({geojson, height: 380});
thematic(childYearMap, pick(all, {dx: DX.childHealth, level: 1, periods: [P.thisYear]}), {level: 1, label: "Child Health - Reporting rate (%)"});
```

<div class="muted d2-footer">
Rebuilt from the demo DHIS2's <b>Reporting Reproductive Health</b> dashboard (play.dhis2.org, Sierra
Leone) with the values imported into the registry by <code>kiln dhis2</code>. 10 of 11 items are shown; the
first item is DHIS2's messages box, which is not data. "User org unit and its children" is Sierra Leone
and its 13 districts, as for the demo's admin user; the two maps colour the districts.
</div>
