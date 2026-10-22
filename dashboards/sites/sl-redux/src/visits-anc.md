---
title: Visits ANC
sql:
  values: data/values.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Visits ANC

<p class="rx-lede">Second and third antenatal visit coverage and bed nets given in pregnancy, against last year and across districts. The same items as the DHIS2 Visits ANC dashboard, which shows them as gauges.</p>

```js
import {load, periods, yearsOf, namer, placeOf, DISTRICTS, COUNTRY} from "./components/data.js";
import {filterBar, explore, itemOf} from "./components/compare.js";
import {panel, bullet, ladder, swatches} from "./components/viz.js";

const DX = {anc3Cov: "sB79w2hiLp8", anc2Cov: "OdiHJayrsKo", llitnCov: "Tt5TAvdfdVK"};
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
const order = [COUNTRY, ...shown.slice().sort((a, b) => (at(DX.anc3Cov, b) ?? 0) - (at(DX.anc3Cov, a) ?? 0))];
const rows = Object.values(DX).flatMap((dx) => order.map((n) => ({category: n, series: nameOf(dx), value: at(dx, n)})));
```

<div class="rx-grid-3">
${Object.values(DX).map((dx) => panel(`${nameOf(dx)}, ${P.year}`, resize((w) => bullet({item: itemOf(all, dx, nameOf), value: at(dx, place), prev: at(dx, place, P.prevYear), width: w})),
  {subtitle: `${place}; black bar ${P.year}, purple tick ${P.prevYear}, bands orange (worse) to blue (better)`}))}
</div>

<div class="rx-grid" style="margin-top: 14px">
${panel(`The three by district, ${P.year}`, resize((w) => ladder(rows, {categoryOrder: order, seriesOrder: Object.values(DX).map(nameOf), width: w})),
  {subtitle: "Sorted by ANC 3", legend: swatches(Object.values(DX).map(nameOf))})}
</div>

<h2 class="rx-section">Compare districts</h2>

<div class="rx-block">${resize((w) => explore({all, dxs: Object.values(DX), nameOf, geojson, F, P, state, width: w - 30}))}</div>

<div class="rx-footer">
Same items as the DHIS2 <b>Visits ANC</b> dashboard and sldash, from the values <code>kiln dhis2</code> imported into the registry. Pick one district to see its own bullets.
</div>
