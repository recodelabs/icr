---
title: Measles
sql:
  values: data/values.parquet
  strata: data/strata.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Measles

<p class="rx-lede">Measles vaccine coverage, how many children drop out before it, and measles cases seen at health units, by district and chiefdom. The same items as the DHIS2 Measles dashboard.</p>

```js
import {load, loadStrata, periods, yearsOf, namer, placeOf, districtIds, DIM, DISTRICTS, COUNTRY, COUNTRY_ID} from "./components/data.js";
import {filterBar, explore, headline, itemOf} from "./components/compare.js";
import {panel, scatter, stackBars, shares, swatches} from "./components/viz.js";
import {SERIES} from "./components/theme.js";

const DX = {
  dropMeasles: "d9thHOJMROr", measlesCov: "FbKK4ofIv5R",
  followUp: "uCVKV6PGGNB", newCases: "GCvqIM3IzN0", referrals: "eomLLbWJfcx"
};
const CASES = [DX.newCases, DX.followUp, DX.referrals];
const all = await load(sql, Object.values(DX));
const byType = await loadStrata(sql, CASES, DIM.facilityType);
const nameOf = namer(all);
const ids = districtIds(all);
const geojson = await FileAttachment("data/units.geojson").json();
const filters = filterBar(yearsOf(all.filter((d) => d.dx === DX.newCases)));
const state = {};
const CASE_COLORS = [SERIES[3], SERIES[0], SERIES[2]];
```

<div>${filters}</div>

```js
const F = Generators.input(filters);
```

```js
const P = periods(all, F.year);
const shown = F.districts.length ? F.districts : DISTRICTS;
const at = (dx, where, period = P.year) => all.find((d) => d.dx === dx && d.period === period && d.location_name === where)?.value;
const caseNames = CASES.map(nameOf);
```

<div class="rx-block">${headline({all, dxs: [DX.measlesCov, DX.dropMeasles, DX.newCases, DX.followUp, DX.referrals], nameOf, F, P})}</div>

<h2 class="rx-section">Compare districts</h2>

<div class="rx-block">${resize((w) => explore({all, dxs: [DX.measlesCov, DX.dropMeasles, ...CASES], nameOf, geojson, F, P, state, width: w - 30}))}</div>

<h2 class="rx-section">Coverage and cases</h2>

```js
const covRows = [COUNTRY, ...shown].map((n) => ({name: n, level: n === COUNTRY ? 0 : 1, x: at(DX.measlesCov, n), y: at(DX.dropMeasles, n)}));
const districtCases = shown.flatMap((n) => CASES.map((dx) => ({category: n, series: nameOf(dx), value: at(dx, n)})));
// Chiefdoms with most new cases, in the picked districts.
const chiefdoms = all.filter((d) => d.admin_level === 2 && CASES.includes(d.dx) && d.period === P.year && shown.includes(d.district));
const chiefTotals = d3.rollup(chiefdoms, (v) => d3.sum(v, (d) => d.value), (d) => `${d.location_name} (${d.district})`);
const topChiefdoms = Array.from(chiefTotals.keys()).sort((a, b) => chiefTotals.get(b) - chiefTotals.get(a)).slice(0, 15);
const chiefRows = chiefdoms.map((d) => ({category: `${d.location_name} (${d.district})`, series: nameOf(d.dx), value: d.value})).filter((r) => topChiefdoms.includes(r.category));
const TYPES = ["MCHP", "CHP", "CHC", "Clinic", "Hospital"];
const placeIds = [COUNTRY_ID, ...Array.from(ids.keys()).filter((id) => id !== COUNTRY_ID && shown.includes(ids.get(id)))];
const typeRows = placeIds.flatMap((id) => TYPES.map((t) => ({category: ids.get(id), series: t,
  value: d3.sum(byType.filter((d) => d.location_id === id && d.period === P.year && d.option_name === t), (d) => d.value)})));
```

<div class="rx-grid">
${panel(`Coverage and drop-out, ${P.year}`, resize((w) => scatter(covRows, {xItem: itemOf(all, DX.measlesCov, nameOf), yItem: itemOf(all, DX.dropMeasles, nameOf),
    xLabel: "Measles coverage <1y (%)", yLabel: "Drop-out Penta 1 to measles (%)", focus: F.districts, width: w, height: 280})),
  {subtitle: "Best in the bottom right: high coverage, few children lost after Penta 1"})}
${panel(`Measles cases by district, ${P.year}`, resize((w) => stackBars(districtCases, {seriesOrder: caseNames, colors: CASE_COLORS, width: w})),
  {subtitle: "New cases, follow-ups and referrals; most first", legend: swatches(caseNames, CASE_COLORS)})}
${panel(`Chiefdoms with most measles cases, ${P.year}`, resize((w) => stackBars(chiefRows, {seriesOrder: caseNames, colors: CASE_COLORS, width: w})),
  {subtitle: `The 15 chiefdoms with most cases${F.districts.length ? " in the picked districts" : ""}`, legend: swatches(caseNames, CASE_COLORS)})}
${panel(`Measles cases by facility type, ${P.year}`, resize((w) => shares(typeRows, {categoryOrder: [COUNTRY, ...shown], seriesOrder: TYPES, width: w})),
  {subtitle: "New cases, follow-ups and referrals added up, by type of facility", legend: swatches(TYPES)})}
</div>

<div class="rx-footer">
Same items as the DHIS2 <b>Measles</b> dashboard and sldash, from the values <code>kiln dhis2</code> imported into the registry.
The DHIS2 tables by district, chiefdom and facility type are drawn here as bars; the coverage map is in the comparison above (choose Chiefdoms).
</div>
