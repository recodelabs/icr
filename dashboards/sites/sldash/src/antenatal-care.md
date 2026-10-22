---
title: Antenatal care
sql:
  values: data/values.parquet
  strata: data/strata.parquet
  facilities: data/facilities.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Antenatal care

```js
import {item, pie, legendKey, rows} from "./components/dhis2.js";
import {columns, lines, yearOverYear, thematic, periodName} from "./components/charts.js";
import {load, loadStrata, pick, pickStrata, relative, DIM, COUNTRY_ID} from "./components/page.js";
import {unitMap} from "./components/unit-map.js";

// DHIS2 uids of the items on the demo's Antenatal Care dashboard.
const DX = {
  anc1Cov: "Uvn6LCg7dVU", anc2Cov: "OdiHJayrsKo", anc3Cov: "sB79w2hiLp8", ipt2Cov: "c8fABiNpT0B", llitnCov: "Tt5TAvdfdVK",
  anc1: "fbfJHSPpUQD", anc2: "cYeuwXTCPkU", anc3: "Jtf34kNZhzP", anc4: "hfdmMSPBgLG"
};
const VISITS = [DX.anc1, DX.anc2, DX.anc3, DX.anc4];
const all = await load(sql, Object.values(DX));
const byType = await loadStrata(sql, VISITS, DIM.facilityType);
const byPlace = await loadStrata(sql, VISITS, DIM.fixedOutreach);
const facilities = rows(await sql`SELECT * FROM facilities`);
const years = Array.from(new Set(all.filter((d) => d.period_type === "Yearly").map((d) => d.period))).sort();
const geojson = await FileAttachment("data/units.geojson").json();
const nameOf = (dx) => all.find((d) => d.dx === dx)?.name ?? dx;
// The demo's "ANC Coverage" legend set (used on its ANC maps).
const ANC_LEGEND = [
  {name: "Low", start: 0, end: 30, color: "#BD0026"},
  {name: "Medium", start: 30, end: 50, color: "#F03B20"},
  {name: "Medium Pl.", start: 50, end: 70, color: "#FD8D3C"},
  {name: "High", start: 70, end: 80, color: "#FEB24C"},
  {name: "High Plus", start: 80, end: 90, color: "#FED976"},
  {name: "Great", start: 90, end: 120, color: "#FFFFB2"},
  {name: "Invalid", start: 120, end: 1000, color: "#CCCCCC"}
];
```

```js
const yearInput = Inputs.select(years, {label: "This year", value: years.at(-1)});
const selectedYear = Generators.input(yearInput);
```

```js
const year = Number(selectedYear);
const P = relative(all, year);
const w = (n) => Math.max(320, (width - 24) / n - 24);
const cat = (rows, category, series) => rows.map((d) => ({category: category(d), series: series(d), value: d.value}));
// Facility values (admin_level null) of one item for one period.
const atFacilities = (dx, period) => all.filter((d) => d.dx === dx && d.admin_level == null && d.period === period);
```

<div class="d2-filter">${yearInput}<span class="muted">DHIS2's relative periods (this year, last 4 quarters, last 12 months) count from this year.</span></div>

<div class="grid grid-cols-2" style="gap: 16px">
${item("ANC: Coverage by quarter and district (two-category)",
  columns(pick(all, {dx: [DX.anc1Cov, DX.anc2Cov], level: 1, periods: P.last4Quarters, places: ["Bo", "Bombali", "Bonthe", "Kailahun", "Kambia"]})
      .map((d) => ({category: `${d.period} · ${d.location_name}`, series: d.name, value: d.value})),
    {width: w(2), yLabel: "%", seriesOrder: ["ANC 1 Coverage", "ANC 2 Coverage"],
     categoryOrder: P.last4Quarters.flatMap((q) => ["Bo", "Bombali", "Bonthe", "Kailahun", "Kambia"].map((n) => `${q} · ${n}`)), rotate: -50}))}
${item("ANC Overview", html`<div class="d2-text">
  <p><b>ANC Overview</b></p>
  <p>The ANC dashboard provides a <i>comprehensive</i> overview of ANC activity.</p>
  <p class="muted">The text item from the DHIS2 dashboard. In DHIS2 each item opens in its own app
  (pivot tables, charts, maps); here each is drawn from the registry's copy of the same values.</p></div>`)}
${item(`ANC: ANC 1 coverage year over year (${year - 1} and ${year})`,
  yearOverYear(pick(all, {dx: DX.anc1Cov, level: 0, periods: [...P.monthsLastYear, ...P.monthsThisYear]})
      .map((d) => ({year: Number(d.period.slice(0, 4)), month: Number(d.period.slice(4)), value: d.value})),
    {width: w(2), yLabel: "%"}),
  {note: "Annualised: each month's value is scaled to a year, so a month can exceed 100%."})}
${item("ANC: ANC 3 coverage by districts last 12 months",
  columns(cat(pick(all, {dx: DX.anc3Cov, level: 1, periods: P.last12Months, places: ["Port Loko", "Kono", "Pujehun", "Moyamba", "Koinadugu"]}), (d) => periodName(d.period), (d) => d.location_name),
    {width: w(2), yLabel: "%", categoryOrder: P.last12Months.map(periodName), seriesOrder: ["Port Loko", "Kono", "Pujehun", "Moyamba", "Koinadugu"]}))}
${item(`ANC: IPT 2 Coverage ${year} (chiefdoms)`, iptMap)}
${item("ANC: LLITN coverage district and facility 2025", html`${llitnMap}${legendKey(ANC_LEGEND)}`,
  {note: "Districts as areas, facilities with coordinates as points; DHIS2's fixed period 2025."})}
${item(`ANC: ANC 1 coverage western chiefdoms ${year}`,
  columns(cat(pick(all, {dx: DX.anc1Cov, level: 2, periods: [P.thisYear], inDistricts: ["Bo", "Bombali", "Bonthe", "Kailahun"]})
      .sort((a, b) => a.district.localeCompare(b.district) || a.location_name.localeCompare(b.location_name)), (d) => d.location_name, (d) => d.name),
    {width: w(2), yLabel: "%", rotate: -60}))}
${item("ANC: ANC 1st visits last 12 months cumulative values", lines(cumulative, {width: w(2), categoryOrder: P.last12Months, format: periodName,
    seriesOrder: ["Kailahun", "Kambia", "Moyamba", "Kenema", "Pujehun"]}))}
${item(`ANC: 4+ visits by Facility Type ${year}`,
  pie(pickStrata(byType, {dx: DX.anc4, location_id: COUNTRY_ID, periods: [P.thisYear]})
      .map((d) => ({name: d.option_name, value: d.value})).sort((a, b) => a.name.localeCompare(b.name)), {width: w(2)}))}
${item("ANC: ANC 3rd visits by facility type last 12 months 100% stacked columns",
  columns(pickStrata(byType, {dx: DX.anc3, location_id: COUNTRY_ID, periods: P.last12Months})
      .map((d) => ({category: periodName(d.period), series: d.option_name, value: d.value})),
    {width: w(2), stacked: true, percent: true, categoryOrder: P.last12Months.map(periodName),
     seriesOrder: ["CHC", "CHP", "Clinic", "Hospital", "MCHP"], yLabel: "share of visits"}))}
${item(`ANC: Fixed vs Outreach ${year}`,
  columns(pickStrata(byPlace, {dx: VISITS, location_id: COUNTRY_ID, periods: [P.thisYear]})
      .map((d) => ({category: nameOf(d.dx), series: d.option_name, value: d.value})),
    {width: w(2), stacked: true, categoryOrder: VISITS.map(nameOf), seriesOrder: ["Fixed", "Outreach"]}))}
</div>

```js
const iptMap = unitMap({geojson, height: 380});
thematic(iptMap, pick(all, {dx: DX.ipt2Cov, level: 2, periods: [P.thisYear]}), {level: 2, label: "ANC IPT 2 Coverage (%)"});
const llitnMap = unitMap({geojson, height: 380});
thematic(llitnMap, [...pick(all, {dx: DX.llitnCov, level: 1, periods: ["2025"]}), ...atFacilities(DX.llitnCov, "2025")],
  {level: 1, legend: ANC_LEGEND, label: "ANC LLITN coverage (%)", points: facilities});
```

```js
// A running total of a count over the last 12 months, per district (DHIS2's "cumulative values").
const cumulative = ["Kailahun", "Kambia", "Moyamba", "Kenema", "Pujehun"].flatMap((name) => {
  let sum = 0;
  return P.last12Months.map((p) => {
    sum += pick(all, {dx: DX.anc1, level: 1, periods: [p], places: [name]})[0]?.value ?? 0;
    return {category: p, series: name, value: sum};
  });
});
```

<div class="muted d2-footer">
Rebuilt from the demo DHIS2's <b>Antenatal Care</b> dashboard (play.dhis2.org, Sierra Leone) with the
values imported into the registry by <code>kiln dhis2</code>, all 11 items. The facility-type and
fixed/outreach items read the breakdowns DHIS2 computes for the country (<code>kiln dhis2 reports --breakdown</code>).
The LLITN map shows only the 601 facilities DHIS2 has coordinates for.
</div>
