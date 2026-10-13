---
title: Antenatal Care
sql:
  values: data/values.parquet
  strata: data/strata.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Antenatal Care

<p class="rx-lede">How many pregnant women reach their first, second and third antenatal visit, where they are seen, and how the districts compare. The same items as the DHIS2 Antenatal Care dashboard.</p>

```js
import {load, loadStrata, pick, periods, yearsOf, namer, periodName, periodDate, DIM, DISTRICTS, COUNTRY, COUNTRY_ID, districtIds} from "./components/data.js";
import {filterBar, explore, headline, itemOf} from "./components/compare.js";
import {panel, heatmap, trend, shares, backToBack, stackedArea, swatches, scaleKey} from "./components/viz.js";
import {SERIES, PERFORMANCE, fmt, fmtShort, colorOf} from "./components/theme.js";

const DX = {
  anc1Cov: "Uvn6LCg7dVU", anc2Cov: "OdiHJayrsKo", anc3Cov: "sB79w2hiLp8", ipt2Cov: "c8fABiNpT0B", llitnCov: "Tt5TAvdfdVK",
  anc1: "fbfJHSPpUQD", anc2: "cYeuwXTCPkU", anc3: "Jtf34kNZhzP", anc4: "hfdmMSPBgLG"
};
const COVERAGE = [DX.anc1Cov, DX.anc2Cov, DX.anc3Cov, DX.ipt2Cov, DX.llitnCov];
const VISITS = [DX.anc1, DX.anc2, DX.anc3, DX.anc4];
const all = await load(sql, Object.values(DX));
const byType = await loadStrata(sql, VISITS, DIM.facilityType);
const byPlace = await loadStrata(sql, VISITS, DIM.fixedOutreach);
const nameOf = namer(all);
const geojson = await FileAttachment("data/units.geojson").json();
const ids = districtIds(all);
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
const dated = (rows) => rows.map((d) => ({name: d.location_name, level: d.admin_level, period: d.period, date: periodDate(d.period), value: d.value}));
const monthTick = (d) => d.toLocaleString("en", {month: "short", year: "2-digit", timeZone: "UTC"});
```

<div class="rx-block">${headline({all, dxs: COVERAGE, nameOf, F, P})}</div>

<h2 class="rx-section">Compare districts</h2>

<div class="rx-block">${resize((w) => explore({all, dxs: [...COVERAGE, ...VISITS], nameOf, geojson, F, P, state, width: w - 30}))}</div>

<h2 class="rx-section">Coverage over time</h2>

```js
// ANC 1, 2, 3 coverage by district and quarter: one heatmap per visit.
const quarterMaps = [DX.anc1Cov, DX.anc2Cov, DX.anc3Cov].map((dx) => {
  const item = itemOf(all, dx, nameOf);
  const rows = pick(all, {dx, level: 1, periods: P.last4Quarters, districts: F.districts}).map((d) => ({x: d.period, y: d.location_name, value: d.value}));
  return panel(item.name, resize((w) => heatmap(rows, {item, xOrder: P.last4Quarters, yOrder: shown, xFormat: (p) => periodName(p), width: w})),
    {subtitle: "Last 4 quarters, by district"});
});
```

<div class="rx-grid-3">${quarterMaps}</div>

```js
const anc3Item = itemOf(all, DX.anc3Cov, nameOf);
const anc3Months = pick(all, {dx: DX.anc3Cov, level: 1, periods: P.last12Months, districts: F.districts});
const anc3Order = shown.slice().sort((a, b) => (anc3Months.filter((d) => d.location_name === b).at(-1)?.value ?? 0) - (anc3Months.filter((d) => d.location_name === a).at(-1)?.value ?? 0));

// ANC 1 coverage, this year against last, month by month: the gap as bars.
const anc1Item = itemOf(all, DX.anc1Cov, nameOf);
const placeName = F.districts.length === 1 ? F.districts[0] : COUNTRY;
const yoy = P.monthsThisYear.filter((p) => P.months.includes(p)).map((p) => {
  const lastP = `${+p.slice(0, 4) - 1}${p.slice(4)}`;
  const now = all.find((d) => d.dx === DX.anc1Cov && d.period === p && d.location_name === placeName)?.value;
  const before = all.find((d) => d.dx === DX.anc1Cov && d.period === lastP && d.location_name === placeName)?.value;
  return {month: periodName(p, {short: true}), now, before, diff: now != null && before != null ? now - before : null};
});
```

<div class="rx-grid">
${panel(`${anc3Item.name}, last 12 months`, resize((w) => heatmap(anc3Months.map((d) => ({x: d.period, y: d.location_name, value: d.value})),
  {item: anc3Item, xOrder: P.last12Months, yOrder: anc3Order, xFormat: (p) => periodName(p, {short: true}), width: w})),
  {subtitle: "Districts sorted by the latest month", legend: scaleKey(anc3Item, anc3Months.map((d) => d.value))})}
${panel(`${anc1Item.name}: ${P.year} against ${P.prevYear}`, resize((w) => Plot.plot({
  width: w, height: 220, marginLeft: 40, marginTop: 10, marginBottom: 24, style: {fontSize: "11px", fontFamily: "Inter, system-ui"},
  x: {domain: yoy.map((d) => d.month), label: null, tickSize: 0},
  y: {label: null, grid: true, tickFormat: (v) => `${v > 0 ? "+" : ""}${v} pts`},
  marks: [
    Plot.barY(yoy, {x: "month", y: "diff", fill: (d) => d.diff >= 0 ? PERFORMANCE[4] : PERFORMANCE[1], rx: 2}),
    Plot.ruleY([0]),
    Plot.tip(yoy, Plot.pointerX({x: "month", y: "diff", title: (d) => `${d.month}\n${P.year}: ${fmt(d.now)}%\n${P.prevYear}: ${fmt(d.before)}%`}))
  ]})), {subtitle: `${placeName}: each month's change on the same month last year (hover for the values)`})}
</div>

```js
// ANC 1st visits, running total over the last 12 months.
const cumulative = [];
for (const name of [COUNTRY, ...shown]) {
  let sum = 0;
  for (const p of P.last12Months) {
    const d = all.find((r) => r.dx === DX.anc1 && r.period === p && r.location_name === name);
    sum += d?.value ?? 0;
    cumulative.push({name, level: name === COUNTRY ? 0 : 1, period: p, date: periodDate(p), value: sum});
  }
}
const anc1Count = itemOf(all, DX.anc1, nameOf);
```

<div class="rx-grid">
${panel("ANC 1st visits, running total over the last 12 months", resize((w) => trend(cumulative.filter((r) => r.level === 1), {item: anc1Count, focus: F.districts, width: w, height: 220, xFormat: monthTick, band: false})),
  {subtitle: F.districts.length ? "The picked districts" : "Every district; pick districts above to label them"})}
${panel("ANC 1st visits by district, last 12 months", resize((w) => Plot.plot({
  width: w, height: 24 + shown.length * 17, marginLeft: 90, marginRight: 50, marginTop: 4, marginBottom: 18, style: {fontSize: "11px", fontFamily: "Inter, system-ui"},
  x: {label: null, grid: true, tickFormat: fmtShort},
  y: {label: null, tickSize: 0, domain: shown.slice().sort((a, b) => (cumulative.findLast((r) => r.name === b)?.value ?? 0) - (cumulative.findLast((r) => r.name === a)?.value ?? 0))},
  marks: [
    Plot.barX(shown.map((n) => ({name: n, value: cumulative.findLast((r) => r.name === n)?.value})), {x: "value", y: "name", fill: SERIES[0], rx: 2, insetTop: 3, insetBottom: 3}),
    Plot.text(shown.map((n) => ({name: n, value: cumulative.findLast((r) => r.name === n)?.value})), {x: "value", y: "name", text: (d) => fmtShort(d.value), textAnchor: "start", dx: 4, fill: "#6b7280"})
  ]})), {subtitle: `${P.last12Months.map((p) => periodName(p)).at(0)} – ${periodName(P.lastMonth)}`})}
</div>

<h2 class="rx-section">Where women are seen</h2>

```js
const TYPES = ["MCHP", "CHP", "CHC", "Clinic", "Hospital"];
const typeRows = (dx) => [COUNTRY_ID, ...Array.from(ids.keys()).filter((id) => id !== COUNTRY_ID && shown.includes(ids.get(id)))]
  .flatMap((id) => byType.filter((d) => d.dx === dx && d.location_id === id && d.period === P.year)
    .map((d) => ({category: ids.get(id), series: d.option_name, value: d.value})));
const typeOrder = (rows) => [COUNTRY, ...shown.slice().sort((a, b) => {
  const share = (n) => { const r = rows.filter((x) => x.category === n); const t = r.reduce((s, x) => s + x.value, 0); return t ? (r.find((x) => x.series === "MCHP")?.value ?? 0) / t : 0; };
  return share(b) - share(a);
})];
const anc4Types = typeRows(DX.anc4);
const anc3TypeMonths = byType.filter((d) => d.dx === DX.anc3 && d.location_id === COUNTRY_ID && P.last12Months.includes(d.period))
  .map((d) => ({date: periodDate(d.period), series: d.option_name, value: d.value}));
const placeRows = [COUNTRY_ID, ...Array.from(ids.keys()).filter((id) => id !== COUNTRY_ID && shown.includes(ids.get(id)))].flatMap((id) => {
  const r = byPlace.filter((d) => VISITS.includes(d.dx) && d.location_id === id && d.period === P.year);
  return ["Fixed", "Outreach"].map((s) => ({category: ids.get(id), series: s, value: r.filter((d) => d.option_name === s).reduce((t, d) => t + (d.value ?? 0), 0)}));
});
const outreachShare = (n) => { const r = placeRows.filter((x) => x.category === n); const t = r.reduce((s, x) => s + x.value, 0); return t ? (r.find((x) => x.series === "Outreach")?.value ?? 0) / t : 0; };
const visitRows = VISITS.flatMap((dx) => byPlace.filter((d) => d.dx === dx && d.location_id === COUNTRY_ID && d.period === P.year)
  .map((d) => ({category: nameOf(dx), series: d.option_name, value: d.value})));
```

<div class="rx-grid">
${panel(`ANC 4th or more visits by facility type, ${P.year}`, resize((w) => shares(anc4Types, {categoryOrder: typeOrder(anc4Types), seriesOrder: TYPES, width: w})),
  {subtitle: "Share of visits by type of facility; districts sorted by the share at MCHPs", legend: swatches(TYPES)})}
${panel("ANC 3rd visits by facility type, last 12 months", resize((w) => stackedArea(anc3TypeMonths, {seriesOrder: TYPES, width: w, height: 220, xFormat: monthTick})),
  {subtitle: COUNTRY, legend: swatches(TYPES)})}
${panel(`ANC visits at the facility and in outreach, ${P.year}`, resize((w) => shares(placeRows, {categoryOrder: [COUNTRY, ...shown.slice().sort((a, b) => outreachShare(b) - outreachShare(a))], seriesOrder: ["Fixed", "Outreach"], colors: [SERIES[0], SERIES[2]], width: w})),
  {subtitle: "Share of all four visits, by district; most outreach first", legend: swatches(["Fixed", "Outreach"], [SERIES[0], SERIES[2]])})}
${panel(`Fixed and outreach by visit, ${P.year}`, resize((w) => backToBack(visitRows, {left: "Fixed", right: "Outreach", categoryOrder: VISITS.map(nameOf), colors: [SERIES[0], SERIES[2]], width: w, rowHeight: 26})),
  {subtitle: COUNTRY, legend: swatches(["Fixed", "Outreach"], [SERIES[0], SERIES[2]])})}
</div>

<div class="rx-footer">
Same items as the DHIS2 <b>Antenatal Care</b> dashboard and sldash, from the values <code>kiln dhis2</code> imported into the registry.
Coverage is DHIS2's own figure for each place and period; counts of visits are added up only across visit numbers or facility types, as DHIS2 does.
</div>
