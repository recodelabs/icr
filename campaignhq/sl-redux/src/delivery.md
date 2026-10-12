---
title: Delivery
sql:
  values: data/values.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Delivery

<p class="rx-lede">Where babies are born and who attends the birth: delivery rates at health units, skilled attendance, births at home and the reproductive health reports behind them. The same items as the DHIS2 Delivery dashboard.</p>

```js
import {load, pick, periods, yearsOf, namer, periodName, placeOf, DISTRICTS, COUNTRY} from "./components/data.js";
import {filterBar, explore, headline, itemOf} from "./components/compare.js";
import {panel, heatmap, ladder, shares, scatter, swatches, scaleKey} from "./components/viz.js";
import {SERIES} from "./components/theme.js";

const DX = {
  phuByBirths: "EoYar8UxddG", phuByAnc1: "n0GE1ISYrdM", phuByPop: "Q3M7Htpzg1Y",
  skilledBirths: "ulgL07PF8rq", skilledPop: "elTqMUTRgdk",
  birthsPhu: "Rigf2d2Zbjp", birthsCommunity: "RdkKj1rVp8R",
  anc1Cov: "Uvn6LCg7dVU", anc4Cov: "AUqdhY4mpvp", liveBirths: "gQNFkFkObU8",
  rhRate: "QX4ZTUbOt3a.REPORTING-RATE"
};
const RATES = [DX.phuByBirths, DX.phuByAnc1, DX.phuByPop];
// The 14 facilities DHIS2's "Live births in facilities" table lists (all in Bo district).
const BIRTH_FACILITIES = ["Baoma Station CHP", "Blamawo MCHP", "Faabu CHP", "Gerehun CHC", "Golu MCHP", "Jembe CHC", "Jormu MCHP",
  "Kigbai MCHP", "Kpumbu MCHP", "Mbundorbu MCHP", "Pelewahun (Baoma) MCHP", "Tugbebu CHP", "Yakaji MCHP", "Yamandu CHC"];
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
const at = (dx, place, period = P.year) => all.find((d) => d.dx === dx && d.period === period && d.location_name === place)?.value;
const byPop = itemOf(all, DX.phuByPop, nameOf);
const ladderOrder = shown.slice().sort((a, b) => (at(DX.phuByPop, b) ?? 0) - (at(DX.phuByPop, a) ?? 0));
```

<div class="rx-block">${headline({all, dxs: [...RATES, DX.skilledBirths, DX.skilledPop, DX.rhRate], nameOf, F, P})}</div>

<h2 class="rx-section">Compare districts</h2>

<div class="rx-block">${resize((w) => explore({all, dxs: [DX.phuByPop, ...RATES.filter((d) => d !== DX.phuByPop), DX.skilledBirths, DX.skilledPop, DX.birthsPhu, DX.birthsCommunity, DX.liveBirths, DX.rhRate], nameOf, geojson, F, P, state, width: w - 30}))}</div>

<h2 class="rx-section">Delivery rates side by side</h2>

```js
const rateRows = RATES.flatMap((dx) => [COUNTRY, ...ladderOrder].map((n) => ({category: n, series: nameOf(dx), value: at(dx, n)})));
const continuumItems = [[DX.anc1Cov, "ANC 1"], [DX.anc4Cov, "ANC 4+"], [DX.phuByPop, "PHU delivery"]].map(([dx, label]) => ({...itemOf(all, dx, nameOf), label}));
const continuumRows = continuumItems.flatMap((it) => [COUNTRY, ...ladderOrder].map((n) => ({x: it.label, y: n, value: at(it.dx, n)})));
```

<div class="rx-grid">
${panel(`Institutional delivery rates, ${P.year}`, resize((w) => ladder(rateRows, {categoryOrder: [COUNTRY, ...ladderOrder], seriesOrder: RATES.map(nameOf), width: w})),
  {subtitle: "The three ways DHIS2 counts deliveries at health units, per district; sorted by the rate by expected pregnancies", legend: swatches(RATES.map(nameOf))})}
${panel(`From antenatal care to delivery, ${P.year}`, resize((w) => heatmap(continuumRows, {item: byPop, xOrder: continuumItems.map((i) => i.label), yOrder: [COUNTRY, ...ladderOrder], width: w, cell: 20})),
  {subtitle: "ANC 1 and ANC 4+ coverage beside the PHU delivery rate (by expected pregnancies): where women are lost between the first visit and the birth", legend: scaleKey(byPop, continuumRows.map((r) => r.value))})}
</div>

<h2 class="rx-section">Skilled attendance and place of birth</h2>

```js
const skilledRows = [COUNTRY, ...shown].map((n) => ({name: n, level: n === COUNTRY ? 0 : 1, x: at(DX.skilledBirths, n), y: at(DX.skilledPop, n)}));
const placeRows = [COUNTRY, ...shown].flatMap((n) => [
  {category: n, series: "At a health unit (PHU)", value: at(DX.birthsPhu, n)},
  {category: n, series: "In the community", value: at(DX.birthsCommunity, n)}]);
const homeShare = (n) => { const p = at(DX.birthsPhu, n) ?? 0, c = at(DX.birthsCommunity, n) ?? 0; return p + c ? c / (p + c) : 0; };
```

<div class="rx-grid">
${panel(`Births attended by skilled health personnel, ${P.year}`, resize((w) => scatter(skilledRows, {xItem: itemOf(all, DX.skilledBirths, nameOf), yItem: itemOf(all, DX.skilledPop, nameOf),
    xLabel: "% of registered live births", yLabel: "% of estimated pregnancies", focus: F.districts, width: w, height: 280, diagonal: true})),
  {subtitle: "Each district by the two denominators DHIS2 uses; below the dashed line, fewer births are registered than expected"})}
${panel(`Live births at a health unit and in the community, ${P.year}`, resize((w) => shares(placeRows, {categoryOrder: [COUNTRY, ...shown.slice().sort((a, b) => homeShare(b) - homeShare(a))],
    seriesOrder: ["At a health unit (PHU)", "In the community"], colors: [SERIES[0], SERIES[2]], width: w})),
  {subtitle: "Registered live births; most births in the community first", legend: swatches(["At a health unit (PHU)", "In the community"], [SERIES[0], SERIES[2]])})}
</div>

```js
const facilityRows = all.filter((d) => d.dx === DX.liveBirths && d.admin_level == null && BIRTH_FACILITIES.includes(d.location_name) && P.last4Quarters.includes(d.period))
  .map((d) => ({x: d.period, y: d.location_name, value: d.value}));
const facilityOrder = BIRTH_FACILITIES.slice().sort((a, b) => (facilityRows.filter((r) => r.y === b).reduce((s, r) => s + r.value, 0)) - (facilityRows.filter((r) => r.y === a).reduce((s, r) => s + r.value, 0)));
const rhItem = itemOf(all, DX.rhRate, nameOf);
const rhRows = [COUNTRY, ...shown].flatMap((n) => P.last12Months.map((p) => ({x: p, y: n, value: at(DX.rhRate, n, p)})));
```

<div class="rx-grid">
${panel("Live births in facilities, last 4 quarters", resize((w) => heatmap(facilityRows, {item: itemOf(all, DX.liveBirths, nameOf), xOrder: P.last4Quarters, yOrder: facilityOrder, xFormat: (p) => periodName(p), width: w})),
  {subtitle: "The 14 facilities of the DHIS2 table (all in Bo), most births first; not affected by the district filter"})}
${panel("Reproductive Health reports received, last 12 months", resize((w) => heatmap(rhRows, {item: rhItem, xOrder: P.last12Months, yOrder: [COUNTRY, ...shown], xFormat: (p) => periodName(p, {short: true}), width: w})),
  {subtitle: "Reporting rate (%) by district and month", legend: scaleKey(rhItem, rhRows.map((r) => r.value))})}
</div>

<div class="rx-footer">
Same items as the DHIS2 <b>Delivery</b> dashboard and sldash, from the values <code>kiln dhis2</code> imported into the registry. Every figure is DHIS2's own value for its place and period.
</div>
