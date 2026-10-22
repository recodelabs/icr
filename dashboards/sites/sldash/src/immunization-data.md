---
title: Immunization data
sql:
  values: data/values.parquet
  strata: data/strata.parquet
  facilities: data/facilities.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Immunization data

```js
import {rows, item, pivot, PALETTE, fmt} from "./components/dhis2.js";
import {columns, yearOverYear, thematic, periodName} from "./components/charts.js";
import {load, loadStrata, pick, pickStrata, relative, DISTRICTS, DIM} from "./components/page.js";
import {unitMap} from "./components/unit-map.js";

// DHIS2 uids of the items on the demo's Immunization data dashboard.
const DX = {
  bcgCov: "FnYCr2EAzWS", opv0Cov: "n5nS0SmkUpq", opv1Cov: "YlTWksXEhEO", opv2Cov: "QsuBK2pMfkk", opv3Cov: "JoEzWYGdX7s",
  penta1Cov: "i7WSgSJpnfu", penta2Cov: "Om2QoRtsncL", penta3Cov: "tUIlpyeeX9N", measlesCov: "FbKK4ofIv5R", fic: "eTDtyyaSA7f",
  drop13: "EdN7qlmI5FS", dropMeasles: "d9thHOJMROr",
  bcg: "s46m5MS0hxu", ficCount: "UOlfIjgN8X6", measles: "YtbsuPPo010", opv0: "x3Do5e7g4Qo", opv1: "pikOziyCXbM",
  opv2: "O05mAByOgAv", opv3: "vI2csg55S9C", penta1: "fClA2Erf6IO", penta2: "I78gJm4KBo7", penta3: "n6aMJNLdvep", yf: "l6byfWFUGaP"
};
// The data elements of the two "Data by … last 4 quarters" tables, in DHIS2's order.
const DOSES = [DX.bcg, DX.ficCount, DX.measles, DX.opv0, DX.opv1, DX.opv2, DX.opv3, DX.penta1, DX.penta2, DX.penta3, DX.yf];
const all = await load(sql, Object.values(DX));
const byType = await loadStrata(sql, DOSES, DIM.facilityType);
const fixedOutreach = await loadStrata(sql, DOSES, DIM.fixedOutreach);
const facilities = rows(await sql`SELECT * FROM facilities`);
const years = Array.from(new Set(all.filter((d) => d.period_type === "Yearly").map((d) => d.period))).sort();
const geojson = await FileAttachment("data/units.geojson").json();
const nameOf = (dx) => all.find((d) => d.dx === dx)?.name ?? dx;
// Location id → district name, for the breakdown tables (strata carry ids only).
const districtOf = new Map(all.filter((d) => d.admin_level === 1).map((d) => [d.location_id, d.location_name]));
```

```js
const yearInput = Inputs.select(years, {label: "This year", value: years.at(-1)});
const selectedYear = Generators.input(yearInput);
```

```js
const year = Number(selectedYear);
```

<div class="d2-filter">${yearInput}<span class="muted">DHIS2's relative periods (this year, last 10 years, last 4 quarters, last 12 months) count from this year.</span></div>

```js
const P = relative(all, year);
const w = (n) => Math.max(320, (width - 24) / n - 24);
const cat = (rows, category, series) => rows.map((d) => ({category: category(d), series: series(d), value: d.value}));
const COVERAGE_12 = [DX.fic, DX.measlesCov, DX.opv0Cov, DX.opv1Cov, DX.opv2Cov, DX.opv3Cov, DX.penta1Cov, DX.penta2Cov, DX.penta3Cov];
const MIXED = [DX.bcgCov, DX.measlesCov, DX.fic, DX.bcg, DX.measles, DX.ficCount];
const ALL_VACCINES = [DX.bcg, DX.opv0, DX.opv1, DX.opv2, DX.opv3, DX.penta1, DX.penta2, DX.penta3, DX.measles, DX.ficCount];
```

<div class="grid grid-cols-2" style="gap: 16px">
${item(`Immunization: FIC year over year (${year - 1} and ${year})`,
  yearOverYear(pick(all, {dx: DX.fic, level: 0, periods: [...P.monthsLastYear, ...P.monthsThisYear]})
      .map((d) => ({year: Number(d.period.slice(0, 4)), month: Number(d.period.slice(4)), value: d.value})),
    {width: w(2), yLabel: "%"}),
  {note: "Annualised: each month's value is scaled to a year, so a month can exceed 100%."})}
${item("Immunization: BCG, measles, yellow fever last 10 years (stacked)",
  columns(cat(pick(all, {dx: [DX.bcg, DX.measles, DX.yf], level: 0, periods: P.last10Years}), (d) => d.period, (d) => d.name),
    {stacked: true, width: w(2), categoryOrder: P.last10Years, seriesOrder: [DX.bcg, DX.measles, DX.yf].map(nameOf)}))}
${item("Immunisation: Fully Imm. Child by Chiefdom 2025", ficMap,
  {note: "DHIS2 fixes this map's period at 2025, whatever the year chosen above."})}
${item(`Immunization: Indicators MCHP in Bo ${year}`, mchpPivot,
  {note: "Facility-level values of the MCHPs (DHIS2 Facility Type) in Bo district; values were imported for 2025 and 2026."})}
${item(`Immunization: BCG doses given at facility, Fixed ${year}`, bcgFixedMap,
  {note: "DHIS2 maps BCG doses given for its \"Fixed, <1y\" option; the registry holds the Fixed/Outreach breakdown over all ages, so this is the Fixed part for all ages. Facilities with coordinates only."})}
${item(`Immunization: Coverage last 12 months 50–120% range`, coverage12(),
  {note: "Annualised monthly values, on DHIS2's fixed 50–120% axis; bars outside the range are cut off."})}
</div>

<div style="margin-top: 16px">
${item("Immunization: Data by facility type last 4 quarters", typePivot,
  {note: "Each district's doses broken down by DHIS2's Facility Type group set; types with no doses are left out."})}
</div>

<div style="margin-top: 16px">
${item("Immunization: Data by districts last 4 quarters", fixedPivot)}
</div>

<div class="grid grid-cols-2" style="gap: 16px; margin-top: 16px">
${item("Immunization: BCG, Measles, FIC coverage and doses administered",
  columns(cat(pick(all, {dx: MIXED, level: 0, periods: P.last12Months}), (d) => periodName(d.period), (d) => d.name),
    {width: w(2), categoryOrder: P.last12Months.map(periodName), seriesOrder: MIXED.map(nameOf)}),
  {note: "As in DHIS2, coverage (%) and doses (counts) share one axis, so the coverage bars are near zero; hover a bar for its value."})}
${item(`Immunization: All Vaccines Yearly ${year}`,
  columns(cat(pick(all, {dx: ALL_VACCINES, level: 0, periods: [P.thisYear]}), (d) => d.name, (d) => d.location_name),
    {width: w(2), categoryOrder: ALL_VACCINES.map(nameOf)}))}
</div>

```js
// Coverage last 12 months with DHIS2's fixed 50–120% range axis.
function coverage12() {
  const data = cat(pick(all, {dx: COVERAGE_12, level: 0, periods: P.last12Months}), (d) => periodName(d.period), (d) => d.name);
  const series = COVERAGE_12.map(nameOf);
  return Plot.plot({
    width: w(2), height: 360, marginLeft: 45, marginBottom: 70,
    color: {domain: series, range: PALETTE, legend: true},
    fx: {domain: P.last12Months.map(periodName), label: null, tickRotate: -40, padding: 0.15, axis: "bottom"},
    x: {domain: series, axis: null, padding: 0.05},
    y: {domain: [50, 120], label: "%", grid: true},
    marks: [
      Plot.barY(data, {fx: "category", x: "series", y1: 50, y2: (d) => Math.max(50, Math.min(120, d.value)), fill: "series",
        tip: true, title: (d) => `${d.category}\n${d.series}: ${fmt(d.value)}`})
    ]
  });
}
```

```js
const ficMap = unitMap({geojson, height: 380});
thematic(ficMap, pick(all, {dx: DX.fic, level: 2, periods: ["2025"]}), {level: 2, label: "FIC <1y (%)"});
const bcgFixedMap = unitMap({geojson, height: 380});
const facilityIds = new Set(facilities.map((f) => f.id));
thematic(bcgFixedMap,
  fixedOutreach.filter((d) => d.dx === DX.bcg && d.option_name === "Fixed" && d.period === P.thisYear && facilityIds.has(d.location_id))
    .map((d) => ({location_id: d.location_id, value: d.value})),
  {level: null, label: "BCG doses given, Fixed", points: facilities});
```

```js
// MCHPs in Bo: the nine indicators per facility, from the facility-level values.
const MCHP_DX = [DX.bcgCov, DX.drop13, DX.dropMeasles, DX.fic, DX.measlesCov, DX.opv0Cov, DX.opv1Cov, DX.opv3Cov, DX.penta3Cov];
const mchpIds = new Set(facilities.filter((f) => f.facility_type === "MCHP" && f.district === "Bo").map((f) => f.id));
const mchpRows = all.filter((d) => MCHP_DX.includes(d.dx) && d.admin_level == null && d.period === P.thisYear && mchpIds.has(d.location_id));
const mchpPivot = mchpRows.length
  ? html`<div style="max-height: 380px; overflow: auto">${pivot(mchpRows, {
      row: (d) => d.location_name, col: (d) => d.name, colOrder: MCHP_DX.map(nameOf), rowLabel: "MCHP in Bo",
      rowOrder: Array.from(new Set(mchpRows.map((d) => d.location_name))).sort()})}</div>`
  : html`<p class="muted">No values for the MCHPs in Bo in ${year}; the DHIS2 demo has none either (checked for 2025 and 2026), so this item is empty there too.</p>`;
```

```js
// Data by facility type: rows quarter · district · type, one column per dose.
const typeRows = pickStrata(byType, {dx: DOSES, periods: P.last4Quarters}).filter((d) => districtOf.has(d.location_id));
const TYPES = ["CHC", "CHP", "Clinic", "Hospital", "MCHP"];
const typeRowKey = (d) => `${periodName(d.period)} · ${districtOf.get(d.location_id)} · ${d.option_name}`;
const typePresent = new Set(typeRows.map(typeRowKey));
const typePivot = html`<div style="max-height: 520px; overflow: auto">${pivot(typeRows, {
  row: typeRowKey, col: (d) => nameOf(d.dx), colOrder: DOSES.map(nameOf), digits: 0, rowLabel: "Quarter · district · facility type",
  rowOrder: P.last4Quarters.flatMap((q) => DISTRICTS.flatMap((n) => TYPES.map((t) => `${periodName(q)} · ${n} · ${t}`))).filter((k) => typePresent.has(k))
})}</div>`;
```

```js
// Data by districts: rows quarter · district, columns dose · Fixed/Outreach.
const fixedRows = pickStrata(fixedOutreach, {dx: DOSES, periods: P.last4Quarters}).filter((d) => districtOf.has(d.location_id));
const fixedPivot = html`<div style="max-height: 520px; overflow: auto">${pivot(fixedRows, {
  row: (d) => `${periodName(d.period)} · ${districtOf.get(d.location_id)}`,
  col: (d) => `${nameOf(d.dx)} · ${d.option_name}`, digits: 0, rowLabel: "Quarter · district",
  colOrder: DOSES.flatMap((dx) => ["Fixed", "Outreach"].map((o) => `${nameOf(dx)} · ${o}`)),
  rowOrder: P.last4Quarters.flatMap((q) => DISTRICTS.map((n) => `${periodName(q)} · ${n}`))
})}</div>`;
```

<div class="muted d2-footer">
Rebuilt from the demo DHIS2's <b>Immunization data</b> dashboard (play.dhis2.org, Sierra Leone): all 10
items, from the values imported into the registry by <code>kiln dhis2</code>. One substitution: the BCG
map shows the Fixed doses over all ages, since the registry holds the Fixed/Outreach breakdown but not
DHIS2's "Fixed, &lt;1y" option. Facility values were imported for 2025 and 2026, and quarters for the
last four quarters and this year, so earlier years leave those items empty.
</div>
