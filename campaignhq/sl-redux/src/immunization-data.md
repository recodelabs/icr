---
title: Immunization data
sql:
  values: data/values.parquet
  strata: data/strata.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Immunization data

<p class="rx-lede">Doses given and coverage for every vaccine, month by month and district by district. The same items as the DHIS2 Immunization data dashboard.</p>

```js
import {load, loadStrata, periods, yearsOf, namer, periodName, periodDate, monthPairs, placeOf, districtIds, DIM, DISTRICTS, COUNTRY, COUNTRY_ID} from "./components/data.js";
import {filterBar, explore, headline, itemOf} from "./components/compare.js";
import {panel, heatmap, ladder, shares, bars, stackedArea, scorecard, yearOnYear, swatches, scaleKey} from "./components/viz.js";
import {SERIES, colorOf} from "./components/theme.js";

const DX = {
  bcgCov: "FnYCr2EAzWS", opv0Cov: "n5nS0SmkUpq", opv1Cov: "YlTWksXEhEO", opv2Cov: "QsuBK2pMfkk", opv3Cov: "JoEzWYGdX7s",
  penta1Cov: "i7WSgSJpnfu", penta2Cov: "Om2QoRtsncL", penta3Cov: "tUIlpyeeX9N", measlesCov: "FbKK4ofIv5R", fic: "eTDtyyaSA7f",
  drop13: "EdN7qlmI5FS", dropMeasles: "d9thHOJMROr",
  bcg: "s46m5MS0hxu", ficCount: "UOlfIjgN8X6", measles: "YtbsuPPo010", opv0: "x3Do5e7g4Qo", opv1: "pikOziyCXbM",
  opv2: "O05mAByOgAv", opv3: "vI2csg55S9C", penta1: "fClA2Erf6IO", penta2: "I78gJm4KBo7", penta3: "n6aMJNLdvep", yf: "l6byfWFUGaP"
};
const COVERAGE = [DX.bcgCov, DX.opv0Cov, DX.opv1Cov, DX.opv2Cov, DX.opv3Cov, DX.penta1Cov, DX.penta2Cov, DX.penta3Cov, DX.measlesCov, DX.fic];
const DOSES = [DX.bcg, DX.opv0, DX.opv1, DX.opv2, DX.opv3, DX.penta1, DX.penta2, DX.penta3, DX.measles, DX.yf, DX.ficCount];
const all = await load(sql, Object.values(DX));
const byType = await loadStrata(sql, DOSES, DIM.facilityType);
const nameOf = namer(all);
const ids = districtIds(all);
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
const coverageColor = colorOf(itemOf(all, DX.bcgCov, nameOf), [90]);
```

<div class="rx-block">${headline({all, dxs: [DX.bcg, DX.penta3, DX.measles, DX.ficCount, DX.fic], nameOf, F, P})}</div>

<h2 class="rx-section">Compare districts</h2>

<div class="rx-block">${resize((w) => explore({all, dxs: [DX.fic, ...COVERAGE.filter((d) => d !== DX.fic), DX.drop13, DX.dropMeasles, ...DOSES], nameOf, geojson, F, P, state, width: w - 30}))}</div>

<h2 class="rx-section">Month by month</h2>

```js
const covRows = COVERAGE.flatMap((dx) => P.last12Months.map((p) => ({x: p, y: nameOf(dx), value: at(dx, place, p)})));
const ficItem = itemOf(all, DX.fic, nameOf);
```

<div class="rx-grid">
${panel(`Coverage by vaccine, last 12 months: ${place}`, resize((w) => heatmap(covRows, {item: ficItem, colorFn: coverageColor, xOrder: P.last12Months, yOrder: COVERAGE.map(nameOf), xFormat: (p) => periodName(p, {short: true}), width: w})),
  {subtitle: "Monthly values are annualised, so a month can pass 100%; DHIS2 plotted this between 50% and 120%", legend: scaleKey(itemOf(all, DX.bcgCov, nameOf), [90])})}
${panel(`${ficItem.name}: ${P.year} against ${P.prevYear}`, resize((w) => yearOnYear(monthPairs(all, DX.fic, P, place), {item: ficItem, width: w, height: 230})),
  {subtitle: `${place}: each month's change on the same month last year (hover for the values)`})}
</div>

<h2 class="rx-section">Doses</h2>

```js
const doseItems = DOSES.map((dx) => itemOf(all, dx, nameOf));
const placeRows = [COUNTRY, ...shown];
const doseValues = all.filter((d) => DOSES.includes(d.dx) && d.period === P.year && placeRows.includes(d.location_name) && (d.admin_level === 0 || d.admin_level === 1));
const doseBars = doseItems.map((it) => ({name: it.name, value: at(it.dx, place)}));
const TYPES = ["MCHP", "CHP", "CHC", "Clinic", "Hospital"];
const typeRows = DOSES.flatMap((dx) => TYPES.map((t) => ({category: nameOf(dx), series: t,
  value: d3.sum(byType.filter((d) => d.dx === dx && d.location_id === COUNTRY_ID && P.last4Quarters.includes(d.period) && d.option_name === t), (d) => d.value)})));
const bcgCovRows = [DX.bcgCov, DX.measlesCov, DX.fic].flatMap((dx) => [COUNTRY, ...shown].map((n) => ({category: n, series: nameOf(dx), value: at(dx, n)})));
const ladderOrder = [COUNTRY, ...shown.slice().sort((a, b) => (at(DX.fic, b) ?? 0) - (at(DX.fic, a) ?? 0))];
const tenYears = P.years.slice(-10);
const stackRows = [DX.bcg, DX.measles, DX.yf].flatMap((dx) => tenYears.map((p) => ({date: periodDate(p), period: p, series: nameOf(dx), value: at(dx, place, p)}))).filter((r) => r.value != null);
```

<div class="rx-grid">
${panel(`All vaccines, doses given in ${P.year}: ${place}`, resize((w) => bars(doseBars, {item: doseItems[0], width: w})), {subtitle: "Most doses first"})}
${panel(`BCG, measles and FIC coverage, ${P.year}`, resize((w) => ladder(bcgCovRows, {categoryOrder: ladderOrder, seriesOrder: [DX.bcgCov, DX.measlesCov, DX.fic].map(nameOf), width: w})),
  {subtitle: "Per district, sorted by FIC", legend: swatches([DX.bcgCov, DX.measlesCov, DX.fic].map(nameOf))})}
</div>

<div class="rx-block">${panel(`Doses by district, ${P.year}`, scorecard(doseValues, {items: doseItems, places: [COUNTRY, ...shown], focus: F.districts, prevValues: all.filter((d) => DOSES.includes(d.dx) && d.period === P.prevYear),
  shortName: (it) => it.name.replace(" doses given", "").replace("Fully Immunized child", "Fully immunised")}),
  {subtitle: "Each column coloured on its own scale; arrows mark a change on last year"})}</div>

<div class="rx-grid">
${panel("Doses by facility type, last 4 quarters", resize((w) => shares(typeRows, {categoryOrder: DOSES.map(nameOf), seriesOrder: TYPES, width: w})),
  {subtitle: `${COUNTRY}, ${periodName(P.last4Quarters[0])} – ${periodName(P.last4Quarters.at(-1))}`, legend: swatches(TYPES)})}
${panel(`BCG, measles and yellow fever doses, ten years: ${place}`, resize((w) => stackedArea(stackRows, {seriesOrder: [DX.bcg, DX.measles, DX.yf].map(nameOf), width: w, height: 230, xFormat: (d) => String(d.getUTCFullYear())})),
  {legend: swatches([DX.bcg, DX.measles, DX.yf].map(nameOf))})}
</div>

<div class="rx-footer">
Same items as the DHIS2 <b>Immunization data</b> dashboard and sldash, from the values <code>kiln dhis2</code> imported into the registry.
"Indicators MCHP in Bo" is left out because DHIS2 has no values for those facilities; the BCG facility map is covered by the chiefdom view above.
Pick one district to see its figures in the place-specific charts.
</div>
