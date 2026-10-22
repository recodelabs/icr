---
title: Nutrition
sql:
  values: data/values.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Nutrition

<p class="rx-lede">Children weighed, by weight for height, and whether the child health reports that carry them came in. The same items as the DHIS2 Nutrition dashboard.</p>

```js
import {load, periods, yearsOf, namer, periodName, DISTRICTS, COUNTRY} from "./components/data.js";
import {filterBar, explore, headline, itemOf} from "./components/compare.js";
import {panel, shares, scatter, heatmap, swatches, scaleKey} from "./components/viz.js";
import {PERFORMANCE} from "./components/theme.js";

const DX = {
  childHealthRate: "BfMAe6Itzgt.REPORTING-RATE",
  wfh70: "vKWOc4itBo2", wfh7079: "nfG18MJZX5o", wfh80: "GQHKiAe3DHR"
};
const WFH = [DX.wfh80, DX.wfh7079, DX.wfh70];
const WFH_COLORS = [PERFORMANCE[4], PERFORMANCE[2], PERFORMANCE[0]];
const all = await load(sql, Object.values(DX));
const nameOf = namer(all);
const geojson = await FileAttachment("data/units.geojson").json();
const filters = filterBar(yearsOf(all.filter((d) => d.dx === DX.wfh70)));
const state = {};
```

<div>${filters}</div>

```js
const F = Generators.input(filters);
```

```js
const P = periods(all, F.year);
const shown = F.districts.length ? F.districts : DISTRICTS;
const at = (dx, where, period = P.year) => all.find((d) => d.dx === dx && d.period === period && d.location_name === where)?.value;
```

<div class="rx-block">${headline({all, dxs: [DX.wfh80, DX.wfh7079, DX.wfh70, DX.childHealthRate], nameOf, F, P})}</div>

<h2 class="rx-section">Compare districts</h2>

<div class="rx-block">${resize((w) => explore({all, dxs: [DX.wfh70, DX.wfh7079, DX.wfh80, DX.childHealthRate], nameOf, geojson, F, P, state, width: w - 30}))}</div>

<h2 class="rx-section">Weight for height</h2>

```js
const wfhRows = [COUNTRY, ...shown].flatMap((n) => WFH.map((dx) => ({category: n, series: nameOf(dx), value: at(dx, n)})));
const wfhOrder = [COUNTRY, ...shown.slice().sort((a, b) => (at(DX.wfh70, b) ?? 0) - (at(DX.wfh70, a) ?? 0))];
const repRows = [COUNTRY, ...shown].map((n) => ({name: n, level: n === COUNTRY ? 0 : 1, x: at(DX.childHealthRate, n), y: at(DX.wfh70, n)}));
const wfh70 = itemOf(all, DX.wfh70, nameOf);
const monthRows = all.filter((d) => d.dx === DX.wfh70 && d.admin_level === 1 && P.last12Months.includes(d.period) && shown.includes(d.location_name))
  .map((d) => ({x: d.period, y: d.location_name, value: d.value}));
```

<div class="rx-grid">
${panel(`Weight for height, ${P.year}`, resize((w) => shares(wfhRows, {categoryOrder: wfhOrder, seriesOrder: WFH.map(nameOf), colors: WFH_COLORS, width: w})),
  {subtitle: "Share of children weighed in each band; most under 70% first", legend: swatches(WFH.map(nameOf), WFH_COLORS)})}
${panel(`Child health reports against children under 70%, ${P.year}`, resize((w) => scatter(repRows, {xItem: itemOf(all, DX.childHealthRate, nameOf), yItem: wfh70,
    xLabel: "Child health reports received (%)", yLabel: "Weight for height <70% (%)", focus: F.districts, width: w, height: 300})),
  {subtitle: "A district with few reports received has fewer children weighed behind its rate"})}
</div>

<div class="rx-block">${panel(`${wfh70.name} by district, last 12 months`, resize((w) => heatmap(monthRows, {item: wfh70, xOrder: P.last12Months, yOrder: wfhOrder.slice(1), xFormat: (p) => periodName(p, {short: true}), width: w})),
  {subtitle: "Lower is better", legend: scaleKey(wfh70, monthRows.map((r) => r.value))})}</div>

<div class="rx-footer">
Same items as the DHIS2 <b>Nutrition</b> dashboard and sldash, from the values <code>kiln dhis2</code> imported into the registry. The three weight-for-height rates share a denominator and add up to about 100%.
</div>
