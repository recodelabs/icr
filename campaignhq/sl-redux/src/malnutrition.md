---
title: Malnutrition
sql:
  values: data/values.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Malnutrition

<p class="rx-lede">Moderate and severe malnutrition among children weighed, the share well nourished, and exclusive breastfeeding. The same items as the DHIS2 Malnutrition dashboard.</p>

```js
import {load, periods, yearsOf, namer, periodName, periodDate, placeOf, DISTRICTS, COUNTRY} from "./components/data.js";
import {filterBar, explore, headline, itemOf} from "./components/compare.js";
import {panel, heatmap, lines, scorecard, multiples, swatches, scaleKey} from "./components/viz.js";

const DX = {moderate: "joIQbN4L1Ok", severe: "vhzPbO1eEyr", well: "aGByu8NFs9m", breastfeeding: "X3taFC1HtE5"};
const all = await load(sql, Object.values(DX));
const nameOf = namer(all);
const geojson = await FileAttachment("data/units.geojson").json();
const filters = filterBar(yearsOf(all));
const state = {};
```

<div>${filters}</div>

```js
const F = Generators.input(filters);
```

```js
const P = periods(all, F.year);
const shown = F.districts.length ? F.districts : DISTRICTS;
const place = placeOf(F);
const at = (dx, where, period = P.year) => all.find((d) => d.dx === dx && d.period === period && d.location_name === where)?.value;
const items = Object.values(DX).map((dx) => itemOf(all, dx, nameOf));
```

<div class="rx-block">${headline({all, dxs: Object.values(DX), nameOf, F, P})}</div>

<h2 class="rx-section">Compare districts</h2>

<div class="rx-block">${resize((w) => explore({all, dxs: [DX.moderate, DX.severe, DX.well, DX.breastfeeding], nameOf, geojson, F, P, state, width: w - 30}))}</div>

<h2 class="rx-section">Over time</h2>

```js
const span = P.last12Months.length >= 6 ? P.last12Months : P.years.slice(-10);
const trendRows = Object.values(DX).flatMap((dx) => span.map((p) => ({date: periodDate(p), period: p, series: nameOf(dx), value: at(dx, place, p)}))).filter((r) => r.value != null);
const severe = itemOf(all, DX.severe, nameOf);
const severeRows = all.filter((d) => d.dx === DX.severe && P.last12Months.includes(d.period) && d.admin_level === 1 && shown.includes(d.location_name))
  .map((d) => ({x: d.period, y: d.location_name, value: d.value}));
const severeOrder = shown.slice().sort((a, b) => (at(DX.severe, b) ?? 0) - (at(DX.severe, a) ?? 0));
const moderate = itemOf(all, DX.moderate, nameOf);
const tenYears = P.years.slice(-10);
const moderateSeries = all.filter((d) => d.dx === DX.moderate && tenYears.includes(d.period) && (d.admin_level === 0 || (d.admin_level === 1 && shown.includes(d.location_name))))
  .map((d) => ({name: d.location_name, level: d.admin_level, period: d.period, date: periodDate(d.period), value: d.value}));
```

<div class="rx-grid">
${panel(`Malnutrition and well nourished, last 12 months: ${place}`, resize((w) => lines(trendRows, {seriesOrder: Object.values(DX).map(nameOf), width: w, height: 220, unit: "%",
    xFormat: (d) => d.toLocaleString("en", {month: "short", year: "2-digit", timeZone: "UTC"})})),
  {legend: swatches(Object.values(DX).map(nameOf))})}
${panel(`${severe.name} by district, last 12 months`, resize((w) => heatmap(severeRows, {item: severe, xOrder: P.last12Months, yOrder: severeOrder, xFormat: (p) => periodName(p, {short: true}), width: w})),
  {subtitle: `Worst in ${P.year} first; lower is better`, legend: scaleKey(severe, severeRows.map((r) => r.value))})}
</div>

<div class="rx-block">${panel(`Malnutrition indicators by district, ${P.year}`, scorecard(all.filter((d) => d.period === P.year), {items, places: [COUNTRY, ...shown], focus: F.districts,
  prevValues: all.filter((d) => d.period === P.prevYear)}), {subtitle: "Each column on its own scale, orange worse to blue better"})}</div>

<div class="rx-block">${panel(`${moderate.name} by district, ten years`, resize((w) => multiples(moderateSeries, {item: moderate, names: shown, columns: w > 1000 ? 7 : w > 700 ? 5 : 3, width: w, focus: F.districts})),
  {subtitle: `${tenYears[0]}–${P.year}, each district on the same scale; dashed line is ${COUNTRY}`})}</div>

<div class="rx-footer">
Same items as the DHIS2 <b>Malnutrition</b> dashboard and sldash, from the values <code>kiln dhis2</code> imported into the registry.
The two boundary maps of the DHIS2 dashboard show facilities and chiefdoms rather than an indicator; the map above draws the same boundaries.
</div>
