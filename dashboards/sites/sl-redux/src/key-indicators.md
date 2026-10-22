---
title: Key Indicators
sql:
  values: data/values.parquet
  groups: data/groups.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Key Indicators

<p class="rx-lede">The headline indicators across programmes, every district in one table, coloured from worse (orange) to better (blue). The same items as the DHIS2 Key Indicators dashboard.</p>

```js
import {load, rows, periods, yearsOf, namer, placeOf, DISTRICTS, COUNTRY} from "./components/data.js";
import {filterBar, explore, headline, itemOf} from "./components/compare.js";
import {panel, scorecard, ladder, shares, stackBars, swatches} from "./components/viz.js";
import {SERIES, PERFORMANCE} from "./components/theme.js";

const DX = {
  morbidityRate: "eZDhcZi6FLP.REPORTING-RATE",
  anc1Cov: "Uvn6LCg7dVU", anc3Cov: "sB79w2hiLp8", anc4Cov: "AUqdhY4mpvp", phuDelivery: "Q3M7Htpzg1Y",
  bcgCov: "FnYCr2EAzWS", opv0Cov: "n5nS0SmkUpq", opv1Cov: "YlTWksXEhEO", opv2Cov: "QsuBK2pMfkk", opv3Cov: "JoEzWYGdX7s",
  penta1Cov: "i7WSgSJpnfu", penta2Cov: "Om2QoRtsncL", penta3Cov: "tUIlpyeeX9N", measlesCov: "FbKK4ofIv5R", fic: "eTDtyyaSA7f",
  wfhBelow70: "vKWOc4itBo2", wfh70to79: "nfG18MJZX5o", wfhAbove80: "GQHKiAe3DHR"
};
const DIAGNOSIS = "jp826jAJHUc", MORBIDITY_MORTALITY = "lv8UXn17ZOm";
const groups = rows(await sql([`SELECT * FROM groups WHERE group_set IN ('${DIAGNOSIS}', '${MORBIDITY_MORTALITY}')`]));
const diagnosisOf = new Map(groups.filter((g) => g.group_set === DIAGNOSIS).map((g) => [g.dx, g.group_name]));
const typeOf = new Map(groups.filter((g) => g.group_set === MORBIDITY_MORTALITY).map((g) => [g.dx, g.group_name]));
const all = await load(sql, [...Object.values(DX), ...diagnosisOf.keys()]);
const nameOf = namer(all);
const geojson = await FileAttachment("data/units.geojson").json();
const filters = filterBar(yearsOf(all.filter((d) => d.dx === DX.anc1Cov)));
const state = {};
const KEY = Object.values(DX);
```

<div>${filters}</div>

```js
const F = Generators.input(filters);
```

```js
const P = periods(all, F.year);
const shown = F.districts.length ? F.districts : DISTRICTS;
const at = (dx, where, period = P.year) => all.find((d) => d.dx === dx && d.period === period && d.location_name === where)?.value;
const items = KEY.map((dx) => itemOf(all, dx, nameOf));
const short = (it) => it.name.replace(" Coverage", "").replace(" <1y", "").replace("Weight for height", "WfH").replace(" - Reporting rate", " reports").replace("PHU delivery rate (by expected pregnancies)", "PHU delivery");
```

<div class="rx-block">${headline({all, dxs: [DX.anc1Cov, DX.phuDelivery, DX.penta3Cov, DX.fic, DX.wfhBelow70, DX.morbidityRate], nameOf, F, P})}</div>

<h2 class="rx-section">Every district, every key indicator</h2>

<div class="rx-block">${panel(`Key indicators by district, ${P.year}`, scorecard(all.filter((d) => d.period === P.year && KEY.includes(d.dx)), {items, places: [COUNTRY, ...shown], focus: F.districts,
  prevValues: all.filter((d) => d.period === P.prevYear && KEY.includes(d.dx)), shortName: short}),
  {subtitle: "Each column on its own scale, orange worse to blue better (for malnutrition and drop-out, lower is better); ↑↓ change on last year; hover a cell for the full name"})}</div>

<h2 class="rx-section">Compare districts</h2>

<div class="rx-block">${resize((w) => explore({all, dxs: KEY, nameOf, geojson, F, P, state, width: w - 30}))}</div>

<h2 class="rx-section">By programme</h2>

```js
const ancOrder = [COUNTRY, ...shown.slice().sort((a, b) => (at(DX.anc3Cov, b) ?? 0) - (at(DX.anc3Cov, a) ?? 0))];
const ancRows = [DX.anc1Cov, DX.anc3Cov, DX.anc4Cov, DX.phuDelivery].flatMap((dx) => ancOrder.map((n) => ({category: n, series: short(itemOf(all, dx, nameOf)), value: at(dx, n)})));
const immItems = [DX.bcgCov, DX.opv3Cov, DX.penta3Cov, DX.measlesCov, DX.fic];
const immOrder = [COUNTRY, ...shown.slice().sort((a, b) => (at(DX.penta3Cov, b) ?? 0) - (at(DX.penta3Cov, a) ?? 0))];
const immRows = immItems.flatMap((dx) => immOrder.map((n) => ({category: n, series: short(itemOf(all, dx, nameOf)), value: at(dx, n)})));
const WFH = [DX.wfhAbove80, DX.wfh70to79, DX.wfhBelow70];
const wfhRows = [COUNTRY, ...shown].flatMap((n) => WFH.map((dx) => ({category: n, series: short(itemOf(all, dx, nameOf)), value: at(dx, n)})));
const place = placeOf(F);
const MM = ["New cases", "Follow-up", "Referrals", "Deaths"];
const caseRows = Array.from(d3.rollup(all.filter((d) => d.period === P.year && diagnosisOf.has(d.dx) && d.location_name === place && d.value != null),
  (v) => d3.sum(v, (d) => d.value), (d) => diagnosisOf.get(d.dx), (d) => typeOf.get(d.dx) ?? "Other"), ([category, m]) => Array.from(m, ([series, value]) => ({category, series, value}))).flat();
```

<div class="rx-grid">
${panel(`Antenatal care and delivery, ${P.year}`, resize((w) => ladder(ancRows, {categoryOrder: ancOrder, seriesOrder: [DX.anc1Cov, DX.anc3Cov, DX.anc4Cov, DX.phuDelivery].map((dx) => short(itemOf(all, dx, nameOf))), width: w})),
  {subtitle: "Sorted by ANC 3", legend: swatches([DX.anc1Cov, DX.anc3Cov, DX.anc4Cov, DX.phuDelivery].map((dx) => short(itemOf(all, dx, nameOf))))})}
${panel(`Immunization coverage, ${P.year}`, resize((w) => ladder(immRows, {categoryOrder: immOrder, seriesOrder: immItems.map((dx) => short(itemOf(all, dx, nameOf))), width: w, target: 80})),
  {subtitle: "Sorted by Penta 3; green line at 80%", legend: swatches(immItems.map((dx) => short(itemOf(all, dx, nameOf))))})}
${panel(`Weight for height, ${P.year}`, resize((w) => shares(wfhRows, {categoryOrder: [COUNTRY, ...shown.slice().sort((a, b) => (at(DX.wfhBelow70, b) ?? 0) - (at(DX.wfhBelow70, a) ?? 0))],
    seriesOrder: WFH.map((dx) => short(itemOf(all, dx, nameOf))), colors: [PERFORMANCE[4], PERFORMANCE[2], PERFORMANCE[0]], width: w})),
  {subtitle: "Children weighed, by weight for height; most under 70% first", legend: swatches(WFH.map((dx) => short(itemOf(all, dx, nameOf))), [PERFORMANCE[4], PERFORMANCE[2], PERFORMANCE[0]])})}
${panel(`Cases by diagnosis, ${P.year}: ${place}`, caseRows.length ? resize((w) => stackBars(caseRows, {seriesOrder: MM.filter((t) => caseRows.some((r) => r.series === t)), colors: [SERIES[0], SERIES[1], SERIES[2], SERIES[9]], width: w})) : html`<p class="rx-sub">No case counts for ${P.year}.</p>`,
  {legend: swatches(MM, [SERIES[0], SERIES[1], SERIES[2], SERIES[9]])})}
</div>

<div class="rx-footer">
Same items as the DHIS2 <b>Key Indicators</b> dashboard and sldash, from the values <code>kiln dhis2</code> imported into the registry. Each figure is DHIS2's own value for its place and year.
</div>
