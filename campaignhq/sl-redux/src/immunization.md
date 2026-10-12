---
title: Immunization
sql:
  values: data/values.parquet
  strata: data/strata.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Immunization

<p class="rx-lede">Coverage of each vaccine in children under one, how many drop out between doses, and ten years of trends by district. The same items as the DHIS2 Immunization dashboard.</p>

```js
import {load, loadStrata, pick, periods, yearsOf, namer, periodDate, districtIds, DIM, DISTRICTS, COUNTRY, COUNTRY_ID} from "./components/data.js";
import {filterBar, explore, headline, itemOf} from "./components/compare.js";
import {panel, heatmap, ladder, shares, scatter, slope, stackedArea, multiples, swatches, scaleKey} from "./components/viz.js";
import {SERIES, colorOf} from "./components/theme.js";

const DX = {
  bcgCov: "FnYCr2EAzWS", opv0Cov: "n5nS0SmkUpq", opv1Cov: "YlTWksXEhEO", opv3Cov: "JoEzWYGdX7s",
  penta1Cov: "i7WSgSJpnfu", penta3Cov: "tUIlpyeeX9N", measlesCov: "FbKK4ofIv5R", fic: "eTDtyyaSA7f",
  drop13: "EdN7qlmI5FS", dropMeasles: "d9thHOJMROr",
  bcg: "s46m5MS0hxu", measles: "YtbsuPPo010", yf: "l6byfWFUGaP", penta1: "fClA2Erf6IO", penta2: "I78gJm4KBo7",
  penta3: "n6aMJNLdvep", ficCount: "UOlfIjgN8X6"
};
const ANTIGENS = [DX.bcgCov, DX.opv0Cov, DX.opv1Cov, DX.opv3Cov, DX.penta1Cov, DX.penta3Cov, DX.measlesCov, DX.fic];
const DOSES = [DX.bcg, DX.measles, DX.yf];
const all = await load(sql, Object.values(DX));
const byType = await loadStrata(sql, [DX.ficCount], DIM.facilityType);
const byPlace = await loadStrata(sql, [DX.bcg, DX.measles, DX.yf, DX.penta1, DX.penta2, DX.penta3], DIM.fixedOutreach);
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
const at = (dx, place, period = P.year) => all.find((d) => d.dx === dx && d.period === period && d.location_name === place)?.value;
const yearTick = (d) => String(d.getUTCFullYear());
const tenYears = P.years.slice(-10);
const series = (dx, places) => all.filter((d) => d.dx === dx && tenYears.includes(d.period) && (d.admin_level === 0 || (d.admin_level === 1 && places.includes(d.location_name))))
  .map((d) => ({name: d.location_name, level: d.admin_level, period: d.period, date: periodDate(d.period), value: d.value}));
const placeIds = [COUNTRY_ID, ...Array.from(ids.keys()).filter((id) => id !== COUNTRY_ID && shown.includes(ids.get(id)))];
```

<div class="rx-block">${headline({all, dxs: [DX.bcgCov, DX.penta3Cov, DX.measlesCov, DX.fic, DX.drop13, DX.dropMeasles], nameOf, F, P})}</div>

<h2 class="rx-section">Compare districts</h2>

<div class="rx-block">${resize((w) => explore({all, dxs: [DX.penta3Cov, ...ANTIGENS.filter((d) => d !== DX.penta3Cov), DX.drop13, DX.dropMeasles, DX.bcg, DX.measles, DX.yf, DX.ficCount], nameOf, geojson, F, P, state, width: w - 30}))}</div>

<h2 class="rx-section">Vaccines side by side</h2>

```js
const order = shown.slice().sort((a, b) => (at(DX.penta3Cov, b) ?? 0) - (at(DX.penta3Cov, a) ?? 0));
const essential = [DX.bcgCov, DX.penta1Cov, DX.penta3Cov, DX.measlesCov, DX.fic];
const ladderRows = essential.flatMap((dx) => [COUNTRY, ...order].map((n) => ({category: n, series: nameOf(dx), value: at(dx, n)})));
const dropRows = [COUNTRY, ...shown].map((n) => ({name: n, level: n === COUNTRY ? 0 : 1, x: at(DX.penta1Cov, n), y: at(DX.penta3Cov, n)}));
```

<div class="rx-grid">
${panel(`Essential vaccines, ${P.year}`, resize((w) => ladder(ladderRows, {categoryOrder: [COUNTRY, ...order], seriesOrder: essential.map(nameOf), width: w, target: 80})),
  {subtitle: "Coverage of each vaccine per district, sorted by Penta 3; green line at the 80% target", legend: swatches(essential.map(nameOf))})}
${panel(`Penta 1 against Penta 3, ${P.year}`, resize((w) => scatter(dropRows, {xItem: itemOf(all, DX.penta1Cov, nameOf), yItem: itemOf(all, DX.penta3Cov, nameOf),
    xLabel: "Penta 1 coverage (%)", yLabel: "Penta 3 coverage (%)", focus: F.districts, width: w, height: 300, diagonal: true})),
  {subtitle: "The further a district sits below the dashed line, the more children start the series and do not finish it"})}
</div>

<h2 class="rx-section">Ten years</h2>

```js
const ficItem = itemOf(all, DX.fic, nameOf);
const ficRows = all.filter((d) => d.dx === DX.fic && d.admin_level === 1 && tenYears.includes(d.period) && shown.includes(d.location_name))
  .map((d) => ({x: d.period, y: d.location_name, value: d.value}));
const ficOrder = shown.slice().sort((a, b) => (at(DX.fic, b) ?? 0) - (at(DX.fic, a) ?? 0));
const penta1Item = itemOf(all, DX.penta1Cov, nameOf);
const first = tenYears[0];
const slopeRows = shown.map((n) => ({name: n, from: at(DX.penta1Cov, n, first), to: at(DX.penta1Cov, n)}));
const doseRows = DOSES.flatMap((dx) => all.filter((d) => d.dx === dx && d.admin_level === 0 && tenYears.includes(d.period))
  .map((d) => ({date: periodDate(d.period), series: nameOf(dx), value: d.value, period: d.period})));
const tableItems = [DX.bcgCov, DX.opv3Cov, DX.penta3Cov, DX.measlesCov, DX.fic].map((dx) => itemOf(all, dx, nameOf));
const placeName = F.districts.length === 1 ? F.districts[0] : COUNTRY;
const tableRows = tableItems.flatMap((it) => tenYears.map((p) => ({x: p, y: it.name, value: at(it.dx, placeName, p)})));
```

<div class="rx-grid">
${panel("Fully immunised children, ten years", resize((w) => heatmap(ficRows, {item: ficItem, xOrder: tenYears, yOrder: ficOrder, width: w})),
  {subtitle: `FIC coverage <1y by district and year; sorted by ${P.year}`, legend: scaleKey(ficItem, ficRows.map((r) => r.value))})}
${panel(`${penta1Item.name}, ${first} and ${P.year}`, resize((w) => slope(slopeRows, {item: penta1Item, fromLabel: first, toLabel: P.year, focus: F.districts, width: w, height: 300})),
  {subtitle: "Blue: up over ten years; orange: down"})}
${panel(`Coverage by vaccine and year, ${placeName}`, resize((w) => heatmap(tableRows, {item: ficItem, colorFn: colorOf(itemOf(all, DX.bcgCov, nameOf), [90]), xOrder: tenYears, yOrder: tableItems.map((i) => i.name), width: w, cell: 24})),
  {subtitle: "Coloured on the coverage scale: orange under 55%, blue from 80%", legend: scaleKey(itemOf(all, DX.bcgCov, nameOf), [90])})}
${panel("BCG, measles and yellow fever doses, ten years", resize((w) => stackedArea(doseRows, {seriesOrder: DOSES.map(nameOf), width: w, height: 220, xFormat: yearTick})),
  {subtitle: COUNTRY, legend: swatches(DOSES.map(nameOf))})}
</div>

```js
const measlesItem = itemOf(all, DX.measlesCov, nameOf);
```

<div class="rx-block">${panel(`${measlesItem.name} by district, ten years`, resize((w) => multiples(series(DX.measlesCov, shown), {item: measlesItem, names: shown, columns: w > 1000 ? 7 : w > 700 ? 5 : 3, width: w, focus: F.districts})),
  {subtitle: `${tenYears[0]}–${P.year}, each district on the same scale; dashed line is ${COUNTRY}`})}</div>

<h2 class="rx-section">Where children are vaccinated</h2>

```js
const TYPES = ["MCHP", "CHP", "CHC", "Clinic", "Hospital"];
const ficTypes = placeIds.flatMap((id) => byType.filter((d) => d.location_id === id && d.period === P.year).map((d) => ({category: ids.get(id), series: d.option_name, value: d.value})));
const placeRows = placeIds.flatMap((id) => ["Fixed", "Outreach"].map((s) => ({category: ids.get(id), series: s,
  value: d3.sum(byPlace.filter((d) => d.location_id === id && d.period === P.year && d.option_name === s), (d) => d.value)})));
const outreach = (n) => { const r = placeRows.filter((x) => x.category === n); const t = d3.sum(r, (x) => x.value); return t ? (r.find((x) => x.series === "Outreach")?.value ?? 0) / t : 0; };
const doseShare = [COUNTRY, ...shown].flatMap((n) => DOSES.map((dx) => ({category: n, series: nameOf(dx), value: at(dx, n)})));
```

<div class="rx-grid">
${panel(`Fully immunised children by facility type, ${P.year}`, resize((w) => shares(ficTypes, {categoryOrder: [COUNTRY, ...shown], seriesOrder: TYPES, width: w})),
  {subtitle: "Share of fully immunised children, by type of facility", legend: swatches(TYPES)})}
${panel(`Doses given at the facility and in outreach, ${P.year}`, resize((w) => shares(placeRows, {categoryOrder: [COUNTRY, ...shown.slice().sort((a, b) => outreach(b) - outreach(a))], seriesOrder: ["Fixed", "Outreach"], colors: [SERIES[0], SERIES[2]], width: w})),
  {subtitle: "BCG, measles, yellow fever and Penta doses added up; most outreach first", legend: swatches(["Fixed", "Outreach"], [SERIES[0], SERIES[2]])})}
${panel(`BCG, measles and yellow fever doses compared, ${P.year}`, resize((w) => shares(doseShare, {categoryOrder: [COUNTRY, ...shown], seriesOrder: DOSES.map(nameOf), width: w})),
  {subtitle: "Share of the three vaccines' doses", legend: swatches(DOSES.map(nameOf))})}
</div>

<div class="rx-footer">
Same items as the DHIS2 <b>Immunization</b> dashboard and sldash, from the values <code>kiln dhis2</code> imported into the registry.
The facility-type map of the DHIS2 dashboard shows facilities rather than an indicator and is left out here; the facility-level coverage maps are covered by the chiefdom view above.
</div>
