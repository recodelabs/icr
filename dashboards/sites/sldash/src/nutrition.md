---
title: Nutrition
sql:
  values: data/values.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Nutrition

```js
import {item, pie, pivot} from "./components/dhis2.js";
import {columns, thematic} from "./components/charts.js";
import {load, pick, relative, DISTRICTS} from "./components/page.js";
import {unitMap} from "./components/unit-map.js";

// DHIS2 uids of the items on the demo's Nutrition dashboard.
const DX = {
  childHealthRate: "BfMAe6Itzgt.REPORTING-RATE",
  wfh70: "vKWOc4itBo2", wfh7079: "nfG18MJZX5o", wfh80: "GQHKiAe3DHR"
};
const RATES = [DX.wfh70, DX.wfh7079, DX.wfh80];
const all = await load(sql, Object.values(DX));
const years = Array.from(new Set(all.filter((d) => d.period_type === "Yearly").map((d) => d.period))).sort();
const geojson = await FileAttachment("data/units.geojson").json();
const nameOf = (dx) => all.find((d) => d.dx === dx)?.name ?? dx;
// User org unit (Sierra Leone) and its children (the districts), in DHIS2's order.
const UNITS = ["Sierra Leone", ...DISTRICTS];
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
// The country and its districts (DHIS2's user org unit and its children).
const countryAndDistricts = (dx, periods) => pick(all, {dx, periods}).filter((d) => d.admin_level === 0 || d.admin_level === 1);
```

<div class="d2-filter">${yearInput}<span class="muted">DHIS2's relative periods (this year) count from this year.</span></div>

<div class="grid grid-cols-2" style="gap: 16px">
${item(`Reporting Rates: Child Health by orgunit ${year}`,
  columns(cat(countryAndDistricts(DX.childHealthRate, [P.thisYear]), (d) => d.location_name, (d) => d.name),
    {width: w(2), yLabel: "%", categoryOrder: UNITS}),
  {note: "Actual ÷ expected Child Health reports."})}
${item(`Nutrition: Weight for height rates ${year}`,
  pie(RATES.map((dx) => ({name: nameOf(dx), value: pick(all, {dx, level: 0, periods: [P.thisYear]})[0]?.value ?? 0})), {width: w(2)}),
  {note: "Each slice is a rate (%) for Sierra Leone; the three add up to about 100."})}
${item(`Nutrition: Weight for height <70% rate by orgunit ${year}`,
  columns(cat(countryAndDistricts(DX.wfh70, [P.thisYear]), (d) => d.location_name, (d) => d.name),
    {width: w(2), yLabel: "%", categoryOrder: UNITS}))}
${item(`Nutrition: Weight for height <70% rate by orgunit ${year}`, wfhMap, {note: "The districts (DHIS2's user org unit children)."})}
</div>

<div style="margin-top: 16px">
${item(`Nutrition: Weight for height rates by orgunit ${year}`,
  pivot(countryAndDistricts(RATES, [P.thisYear]),
    {row: (d) => d.location_name, col: (d) => `${d.period} · ${d.name}`, rowOrder: UNITS,
     colOrder: RATES.map((dx) => `${P.thisYear} · ${nameOf(dx)}`), rowLabel: "Org unit"}))}
</div>

```js
const wfhMap = unitMap({geojson, height: 380});
thematic(wfhMap, pick(all, {dx: DX.wfh70, level: 1, periods: [P.thisYear]}), {level: 1, label: "Weight for height <70% rate (%)"});
```

<div class="muted d2-footer">
Rebuilt from the demo DHIS2's <b>Nutrition</b> dashboard (play.dhis2.org, Sierra Leone) with the values
imported into the registry by <code>kiln dhis2</code>: all 5 data items. Not shown: the messages item,
which holds no data.
</div>
