---
title: Mother and Child Health
sql:
  values: data/values.parquet
  strata: data/strata.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Mother and Child Health

<p class="rx-lede">Antenatal visits, malaria prevention in pregnancy (IPT and bed nets) and the drop-out between the first and third visit. The same items as the DHIS2 Mother and Child Health dashboard.</p>

```js
import {load, loadStrata, periods, yearsOf, namer, periodDate, placeOf, districtIds, DIM, DISTRICTS, COUNTRY, COUNTRY_ID} from "./components/data.js";
import {filterBar, explore, headline, itemOf} from "./components/compare.js";
import {panel, ladder, rank, lines, shares, swatches} from "./components/viz.js";
import {SERIES} from "./components/theme.js";

const DX = {
  anc1Cov: "Uvn6LCg7dVU", anc2Cov: "OdiHJayrsKo", anc3Cov: "sB79w2hiLp8", dropout13: "ReUHfIn0pTQ",
  ipt1Cov: "dwEq7wi6nXV", ipt2Cov: "c8fABiNpT0B", llitnCov: "Tt5TAvdfdVK", slept: "nkjlWUMIdHh",
  anc1: "fbfJHSPpUQD", anc2: "cYeuwXTCPkU", anc3: "Jtf34kNZhzP", anc4: "hfdmMSPBgLG"
};
const VISITS = [DX.anc1, DX.anc2, DX.anc3, DX.anc4];
const COVERAGE = [DX.anc1Cov, DX.anc2Cov, DX.anc3Cov, DX.ipt1Cov, DX.ipt2Cov, DX.llitnCov];
const all = await load(sql, Object.values(DX));
const byType = await loadStrata(sql, VISITS, DIM.facilityType);
const byPlace = await loadStrata(sql, VISITS, DIM.fixedOutreach);
const nameOf = namer(all);
const ids = districtIds(all);
const geojson = await FileAttachment("data/units.geojson").json();
const filters = filterBar(yearsOf(all.filter((d) => d.dx === DX.anc1Cov)));
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
const monthTick = (d) => d.toLocaleString("en", {month: "short", year: "2-digit", timeZone: "UTC"});
const monthly = (dxs) => dxs.flatMap((dx) => P.last12Months.map((p) => ({date: periodDate(p), period: p, series: nameOf(dx), value: at(dx, place, p)}))).filter((r) => r.value != null);
const placeIds = [COUNTRY_ID, ...Array.from(ids.keys()).filter((id) => id !== COUNTRY_ID && shown.includes(ids.get(id)))];
```

<div class="rx-block">${headline({all, dxs: [DX.anc1Cov, DX.anc3Cov, DX.dropout13, DX.ipt2Cov, DX.llitnCov, DX.slept], nameOf, F, P})}</div>

<h2 class="rx-section">Compare districts</h2>

<div class="rx-block">${resize((w) => explore({all, dxs: [DX.slept, ...COVERAGE, DX.dropout13, ...VISITS], nameOf, geojson, F, P, state, width: w - 30}))}</div>

<h2 class="rx-section">Key coverages</h2>

```js
const order = [COUNTRY, ...shown.slice().sort((a, b) => (at(DX.anc3Cov, b) ?? 0) - (at(DX.anc3Cov, a) ?? 0))];
const covRows = COVERAGE.flatMap((dx) => order.map((n) => ({category: n, series: nameOf(dx), value: at(dx, n)})));
const dropItem = itemOf(all, DX.dropout13, nameOf);
const dropRows = shown.map((n) => ({name: n, value: at(DX.dropout13, n), prev: at(DX.dropout13, n, P.prevYear)}));
const ancPair = [DX.anc1Cov, DX.anc3Cov].flatMap((dx) => order.map((n) => ({category: n, series: nameOf(dx), value: at(dx, n)})));
```

<div class="rx-grid">
${panel(`Key coverages, ${P.year}`, resize((w) => ladder(covRows, {categoryOrder: order, seriesOrder: COVERAGE.map(nameOf), width: w})),
  {subtitle: "ANC visits, IPT doses and bed nets per district, sorted by ANC 3", legend: swatches(COVERAGE.map(nameOf))})}
${panel(`${dropItem.name}, ${P.year}`, resize((w) => rank(dropRows, {item: dropItem, national: at(DX.dropout13, COUNTRY), focus: F.districts, width: w, target: 25})),
  {subtitle: `Lowest first; ring is ${P.prevYear}; green line at the 25% target DHIS2 draws`})}
${panel(`ANC 1 and ANC 3 coverage, ${P.year}`, resize((w) => ladder(ancPair, {categoryOrder: order, seriesOrder: [DX.anc1Cov, DX.anc3Cov].map(nameOf), colors: [SERIES[0], SERIES[3]], width: w})),
  {subtitle: "The gap between the dots is the drop-out", legend: swatches([DX.anc1Cov, DX.anc3Cov].map(nameOf), [SERIES[0], SERIES[3]])})}
</div>

<h2 class="rx-section">Last 12 months: ${place}</h2>

<div class="rx-grid">
${panel("ANC 1st and 3rd visit coverage", resize((w) => lines(monthly([DX.anc1Cov, DX.anc3Cov]), {seriesOrder: [DX.anc1Cov, DX.anc3Cov].map(nameOf), colors: [SERIES[0], SERIES[3]], width: w, unit: "%", xFormat: monthTick})),
  {subtitle: "Monthly values are annualised"})}
${panel("IPT 1 and IPT 2 coverage", resize((w) => lines(monthly([DX.ipt1Cov, DX.ipt2Cov]), {seriesOrder: [DX.ipt1Cov, DX.ipt2Cov].map(nameOf), colors: [SERIES[1], SERIES[4]], width: w, unit: "%", xFormat: monthTick})))}
${panel("Bed nets: LLITN given and slept under last night", resize((w) => lines(monthly([DX.llitnCov, DX.slept]), {seriesOrder: [DX.llitnCov, DX.slept].map(nameOf), colors: [SERIES[5], SERIES[2]], width: w, unit: "%", xFormat: monthTick})))}
</div>

<h2 class="rx-section">Where women are seen</h2>

```js
const TYPES = ["MCHP", "CHP", "CHC", "Clinic", "Hospital"];
const typeRows = placeIds.flatMap((id) => TYPES.map((t) => ({category: ids.get(id), series: t,
  value: d3.sum(byType.filter((d) => d.location_id === id && d.period === P.year && d.option_name === t), (d) => d.value)})));
const anc4Types = placeIds.flatMap((id) => byType.filter((d) => d.dx === DX.anc4 && d.location_id === id && d.period === P.year).map((d) => ({category: ids.get(id), series: d.option_name, value: d.value})));
const placeRows = placeIds.flatMap((id) => ["Fixed", "Outreach"].map((s) => ({category: ids.get(id), series: s,
  value: d3.sum(byPlace.filter((d) => d.location_id === id && d.period === P.year && d.option_name === s), (d) => d.value)})));
```

<div class="rx-grid">
${panel(`ANC visits by facility type, ${P.year}`, resize((w) => shares(typeRows, {categoryOrder: [COUNTRY, ...shown], seriesOrder: TYPES, width: w})),
  {subtitle: "All four visits added up", legend: swatches(TYPES)})}
${panel(`ANC 4th or more visits by facility type, ${P.year}`, resize((w) => shares(anc4Types, {categoryOrder: [COUNTRY, ...shown], seriesOrder: TYPES, width: w})),
  {legend: swatches(TYPES)})}
${panel(`ANC visits at the facility and in outreach, ${P.year}`, resize((w) => shares(placeRows, {categoryOrder: [COUNTRY, ...shown], seriesOrder: ["Fixed", "Outreach"], colors: [SERIES[0], SERIES[2]], width: w})),
  {legend: swatches(["Fixed", "Outreach"], [SERIES[0], SERIES[2]])})}
</div>

<div class="rx-footer">
Same items as the DHIS2 <b>Mother and Child Health</b> dashboard and sldash, from the values <code>kiln dhis2</code> imported into the registry.
The four chiefdom maps of the DHIS2 dashboard (bed nets, IPT 2, ANC 1, ANC 3) are one map here: choose the indicator and Chiefdoms in the comparison.
</div>
