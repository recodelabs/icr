---
title: Reporting Reproductive Health
sql:
  values: data/values.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Reporting Reproductive Health

<p class="rx-lede">The three major monthly forms (child health, reproductive health, morbidity): how many came in, by district, this year and last month. The same items as the DHIS2 Reporting Reproductive Health dashboard.</p>

```js
import {load, periods, yearsOf, namer, periodName, placeOf, DISTRICTS, COUNTRY} from "./components/data.js";
import {filterBar, explore, headline, itemOf} from "./components/compare.js";
import {panel, heatmap, rank, ladder, scorecard, swatches, scaleKey} from "./components/viz.js";

const DX = {childHealth: "BfMAe6Itzgt.REPORTING-RATE", rh: "QX4ZTUbOt3a.REPORTING-RATE", morbidity: "eZDhcZi6FLP.REPORTING-RATE"};
const MAJOR = [DX.childHealth, DX.rh, DX.morbidity];
const all = await load(sql, Object.values(DX));
const nameOf = namer(all);
const short = (dx) => nameOf(dx).replace(" - Reporting rate", "");
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
const rhItem = itemOf(all, DX.rh, nameOf);
```

<div class="rx-block">${headline({all, dxs: MAJOR, nameOf, F, P})}</div>

<h2 class="rx-section">Major forms</h2>

```js
const monthRows = MAJOR.flatMap((dx) => P.last12Months.map((p) => ({x: p, y: short(dx), value: at(dx, place, p)})));
const rhRows = shown.map((n) => ({name: n, value: at(DX.rh, n, P.lastMonth), prev: at(DX.rh, n)}));
const order = [COUNTRY, ...shown.slice().sort((a, b) => (at(DX.rh, b) ?? 0) - (at(DX.rh, a) ?? 0))];
const ladderRows = MAJOR.flatMap((dx) => order.map((n) => ({category: n, series: short(dx), value: at(dx, n)})));
```

<div class="rx-grid">
${panel(`Major forms, last 12 months: ${place}`, resize((w) => heatmap(monthRows, {item: rhItem, xOrder: P.last12Months, yOrder: MAJOR.map(short), xFormat: (p) => periodName(p, {short: true}), width: w, cell: 26})),
  {subtitle: "Reports received (%) per form and month", legend: scaleKey(rhItem, monthRows.map((r) => r.value))})}
${panel(`Reproductive health reports, ${periodName(P.lastMonth)} against ${P.year}`, resize((w) => rank(rhRows, {item: rhItem, national: at(DX.rh, COUNTRY, P.lastMonth), focus: F.districts, width: w, prevLabel: P.year})),
  {subtitle: `Dot: ${periodName(P.lastMonth)}, the latest complete month; ring: the whole of ${P.year}`})}
</div>

<div class="rx-grid">
${panel(`The three forms by district, ${P.year}`, resize((w) => ladder(ladderRows, {categoryOrder: order, seriesOrder: MAJOR.map(short), width: w})),
  {subtitle: "Sorted by reproductive health", legend: swatches(MAJOR.map(short))})}
${panel(`Major forms by district, ${P.year}`, scorecard(all.filter((d) => d.period === P.year), {items: MAJOR.map((dx) => itemOf(all, dx, nameOf)), places: [COUNTRY, ...shown], focus: F.districts,
  prevValues: all.filter((d) => d.period === P.prevYear), shortName: (it) => short(it.dx)}), {subtitle: "↑↓ change on last year"})}
</div>

<h2 class="rx-section">Compare districts</h2>

<div class="rx-block">${resize((w) => explore({all, dxs: [DX.childHealth, DX.rh, DX.morbidity], nameOf, geojson, F, P, state, width: w - 30}))}</div>

<div class="rx-footer">
Same items as the DHIS2 <b>Reporting Reproductive Health</b> dashboard and sldash, from the values <code>kiln dhis2</code> imported into the registry.
DHIS2 shows "this month and last month" together; the registry holds each month on its own, so the latest complete month is shown.
</div>
