---
title: Immunization
sql:
  values: data/values.parquet
  strata: data/strata.parquet
  facilities: data/facilities.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Immunization

```js
import {rows, item, gauge, pie, pivot, legendKey, COVERAGE_LEGEND, PALETTE, fmt} from "./components/dhis2.js";
import {columns, thematic, periodName} from "./components/charts.js";
import {load, loadStrata, pick, pickStrata, relative, DISTRICTS, DIM, COUNTRY_ID} from "./components/page.js";
import {unitMap} from "./components/unit-map.js";

// DHIS2 uids of the items on the demo's Immunization dashboard.
const DX = {
  bcgCov: "FnYCr2EAzWS", opv0Cov: "n5nS0SmkUpq", opv1Cov: "YlTWksXEhEO", opv3Cov: "JoEzWYGdX7s",
  penta1Cov: "i7WSgSJpnfu", penta3Cov: "tUIlpyeeX9N", measlesCov: "FbKK4ofIv5R", fic: "eTDtyyaSA7f",
  drop13: "EdN7qlmI5FS", dropMeasles: "d9thHOJMROr",
  bcg: "s46m5MS0hxu", measles: "YtbsuPPo010", yf: "l6byfWFUGaP", penta1: "fClA2Erf6IO", penta2: "I78gJm4KBo7",
  penta3: "n6aMJNLdvep", ficCount: "UOlfIjgN8X6"
};
const all = await load(sql, Object.values(DX));
const fixedOutreach = await loadStrata(sql, [DX.ficCount, DX.measles, DX.yf, DX.penta1, DX.penta2, DX.penta3], DIM.fixedOutreach);
const byType = await loadStrata(sql, [DX.ficCount], DIM.facilityType);
const facilities = rows(await sql`SELECT * FROM facilities`);
const years = Array.from(new Set(all.filter((d) => d.period_type === "Yearly").map((d) => d.period))).sort();
const geojson = await FileAttachment("data/units.geojson").json();
const nameOf = (dx) => all.find((d) => d.dx === dx)?.name ?? dx;
```

```js
const yearInput = Inputs.select(years, {label: "This year", value: years.at(-1)});
const selectedYear = Generators.input(yearInput);
```

```js
const year = Number(selectedYear);
```

<div class="d2-filter">${yearInput}<span class="muted">DHIS2's relative periods (this year, last 10 years, last six-month, last month) count from this year.</span></div>

```js
const P = relative(all, year);
const w = (n) => Math.max(320, (width - 24) / n - 24);
const cat = (rows, category, series) => rows.map((d) => ({category: category(d), series: series(d), value: d.value}));
// "2026S1" → "Jan–Jun 2026"; other codes as periodName prints them.
const halfName = (p) => /^\d{4}S[12]$/.test(p ?? "") ? `${p.endsWith("1") ? "Jan–Jun" : "Jul–Dec"} ${p.slice(0, 4)}` : periodName(p ?? "");
// Facility-level values of one item and period (facilities have no admin level).
const atFacilities = (dx, period) => all.filter((d) => d.dx === dx && d.admin_level == null && d.period === period);
const dosesPie = () => pie([DX.measles, DX.bcg, DX.yf, DX.penta1, DX.penta2].map((dx) => {
  const d = pick(all, {dx, level: 0, periods: [P.thisYear]})[0];
  return {name: d?.name ?? nameOf(dx), value: d?.value ?? 0};
}), {width: w(2)});
```

<div class="grid grid-cols-2" style="gap: 16px">
${item("Immunization: Fully immunized by districts and last 10 years stacked",
  columns(cat(pick(all, {dx: DX.fic, level: 1, periods: P.last10Years, places: ["Kailahun", "Kambia", "Bo", "Bonthe", "Bombali"]}), (d) => d.period, (d) => d.location_name),
    {stacked: true, width: w(2), categoryOrder: P.last10Years, seriesOrder: ["Kailahun", "Kambia", "Bo", "Bonthe", "Bombali"]}))}
${item(`Immunization: Penta 3 Coverage Chiefdoms ${halfName(P.lastSixMonth ?? P.thisYear)}`, penta3Map,
  {note: P.lastSixMonth ? "DHIS2's \"last six-month\": the last complete half-year." : "No half-year values for this year; showing the year."})}
${item("Immunization: BCG, measles, yellow fever last 10 years (stacked)",
  columns(cat(pick(all, {dx: [DX.bcg, DX.measles, DX.yf], level: 0, periods: P.last10Years}), (d) => d.period, (d) => d.name),
    {stacked: true, width: w(2), categoryOrder: P.last10Years, seriesOrder: ["BCG doses given", "Measles doses given", "Yellow Fever doses given"]}))}
${item(`Immunization: Measles Cov Facilities ${year}`, html`${measlesFacilityMap}${legendKey()}`,
  {note: "Facilities with coordinates in DHIS2 (601 of 1,166); values imported for 2025 and 2026."})}
${item(`Immunization: BCG, Measles, YF doses comparison ${year}`, dosesPie())}
${item("Immunization: Measles coverage by districts last 10 years",
  columns(cat(pick(all, {dx: DX.measlesCov, level: 1, periods: P.last10Years, places: ["Kailahun", "Kambia", "Bo", "Bonthe", "Bombali", "Kenema"]}), (d) => d.period, (d) => d.location_name),
    {width: w(2), categoryOrder: P.last10Years, seriesOrder: ["Kailahun", "Kambia", "Bo", "Bonthe", "Bombali", "Kenema"], yLabel: "%"}))}
${item(`Immunization: BCG and FIC Coverage ${year}`, html`${bcgFicMap}${legendKey()}`,
  {note: "Two layers as in DHIS2: FIC <1y by district (areas) and BCG Coverage <1y by facility (points)."})}
${item(`Immunization: BCG Cov Districts ${halfName(P.lastSixMonth ?? P.thisYear)}`, html`${bcgMap}${legendKey()}`)}
</div>

<div style="margin-top: 16px">
${item(`Immunization: Essential vaccines ${year}`,
  columns(cat(pick(all, {dx: [DX.bcgCov, DX.opv0Cov, DX.penta3Cov, DX.measlesCov, DX.fic], level: 1, periods: [P.thisYear]}), (d) => d.location_name, (d) => d.name),
    {width: width - 40, categoryOrder: DISTRICTS, seriesOrder: ["BCG Coverage <1y", "OPV 0 Coverage <1y", "Penta 3 Coverage <1y", "Measles Coverage <1y", "FIC <1y"], yLabel: "%"}),
  {note: "DHIS2 also draws a target line at 80%."})}
</div>

<div style="margin-top: 16px">
${item("Immunization: Indicators last 10 years with legend set", html`${indicatorPivot}${legendKey()}`)}
</div>

<div class="grid grid-cols-2" style="gap: 16px; margin-top: 16px">
${item(`Immunization: BCG, Measles, YF doses comparison ${year}`, dosesPie(),
  {note: "DHIS2's dashboard has this pie twice."})}
${item("Immunization: Penta 1 coverage by districts last 10 years",
  columns(cat(pick(all, {dx: DX.penta1Cov, level: 1, periods: P.last10Years, places: ["Kailahun", "Port Loko", "Kono", "Kambia", "Bo", "Kenema", "Bombali", "Bonthe", "Koinadugu", "Moyamba"]}), (d) => d.location_name, (d) => d.period),
    {width: w(2), categoryOrder: ["Kailahun", "Port Loko", "Kono", "Kambia", "Bo", "Kenema", "Bombali", "Bonthe", "Koinadugu", "Moyamba"], seriesOrder: P.last10Years, yLabel: "%"}))}
${item(`Immunization: OPV 3 coverage, ${periodName(P.lastMonth ?? "")}`,
  html`<div style="display:flex;justify-content:center">${gauge(pick(all, {dx: DX.opv3Cov, level: 0, periods: [P.lastMonth]})[0]?.value, {max: 120, label: "OPV 3 Coverage <1y (%)", width: Math.min(360, w(2))})}</div>`,
  {note: "DHIS2 shows this month and last month together; the registry holds each month on its own, so this is the latest month."})}
${item("Health Facilities by Type with Radius SL", html`${typeMap}${typeKey}`,
  {note: "Facilities with coordinates in DHIS2 (601 of 1,166), coloured by DHIS2's Facility Type group set. DHIS2 also draws a catchment radius around each facility."})}
${item(`Immunization: Doses administered by location fixed/outreach ${year}`,
  columns(pickStrata(fixedOutreach, {location_id: COUNTRY_ID, periods: [P.thisYear], dx: [DX.ficCount, DX.measles, DX.yf, DX.penta1, DX.penta2, DX.penta3]})
      .map((d) => ({category: d.option_name, series: nameOf(d.dx), value: d.value})),
    {width: w(2), categoryOrder: ["Fixed", "Outreach"], seriesOrder: [DX.ficCount, DX.measles, DX.yf, DX.penta1, DX.penta2, DX.penta3].map(nameOf)}))}
${item(`Immunization: Measles Coverage Chiefdoms in Bo and Bombali ${year}`,
  columns(cat(pick(all, {dx: DX.measlesCov, level: 2, periods: [P.thisYear], inDistricts: ["Bo", "Bombali"]}).sort((a, b) => a.district.localeCompare(b.district) || a.location_name.localeCompare(b.location_name)), (d) => d.location_name, (d) => d.name),
    {width: w(2), yLabel: "%", rotate: -60}))}
${item(`Immunization: Fully Immunised by Facility Type ${year}`,
  pie(pickStrata(byType, {dx: DX.ficCount, location_id: COUNTRY_ID, periods: [P.thisYear]}).map((d) => ({name: d.option_name, value: d.value})), {width: w(2)}),
  {note: "Fully Immunized child for the country, broken down by DHIS2's Facility Type group set; types with no value are left out."})}
</div>

```js
const penta3Map = unitMap({geojson, height: 380});
thematic(penta3Map, pick(all, {dx: DX.penta3Cov, level: 2, periods: [P.lastSixMonth ?? P.thisYear]}), {level: 2, label: "Penta 3 Coverage <1y (%)"});
const measlesFacilityMap = unitMap({geojson, height: 380});
thematic(measlesFacilityMap, atFacilities(DX.measlesCov, P.thisYear), {level: null, legend: COVERAGE_LEGEND, label: "Measles Coverage <1y (%)", points: facilities});
const bcgFicMap = unitMap({geojson, height: 380});
thematic(bcgFicMap, [...pick(all, {dx: DX.fic, level: 1, periods: [P.thisYear]}), ...atFacilities(DX.bcgCov, P.thisYear)],
  {level: 1, legend: COVERAGE_LEGEND, label: "FIC <1y (districts) · BCG Coverage <1y (facilities) (%)", points: facilities});
const bcgMap = unitMap({geojson, height: 380});
thematic(bcgMap, pick(all, {dx: DX.bcgCov, level: 1, periods: [P.lastSixMonth ?? P.thisYear]}), {level: 1, legend: COVERAGE_LEGEND, label: "BCG Coverage <1y (%)"});
```

```js
// Health facilities by type: one colour per DHIS2 facility type (points only, no area fill).
const TYPES = ["CHC", "CHP", "MCHP", "Clinic", "Hospital"];
const typeMap = unitMap({geojson, height: 380});
typeMap.update({
  level: null, outline: 1, stops: [1, 2, 3, 4], colors: PALETTE.slice(0, 5), legend: ["Facility type", () => ""],
  points: facilities.filter((f) => TYPES.includes(f.facility_type)).map((f) => ({
    name: f.name, lon: f.lon, lat: f.lat, value: TYPES.indexOf(f.facility_type),
    popup: `${f.facility_type}<br>${f.chiefdom ?? ""}${f.district ? `, ${f.district}` : ""}`
  })),
  popup: () => ""
});
// The map's own legend shows thresholds; the facility types get a key of their own below it.
for (const el of typeMap.children) if (el.style.left === "8px" && el.style.bottom === "8px") el.style.display = "none";
const typeKey = html`<div style="display:flex;flex-wrap:wrap;gap:10px;font:11px system-ui;color:#475569;margin-top:6px">
  ${TYPES.map((t, i) => html`<span><span style="display:inline-block;width:10px;height:10px;border-radius:50%;background:${PALETTE[i]};border:1px solid #334155;margin-right:4px;vertical-align:-1px"></span>${t} (${facilities.filter((f) => f.facility_type === t && f.lon != null).length})</span>`)}
</div>`;
```

```js
const PIVOT_DX = [DX.bcgCov, DX.drop13, DX.dropMeasles, DX.fic, DX.measlesCov, DX.opv0Cov, DX.opv1Cov, DX.opv3Cov, DX.penta3Cov];
const pivotRows = pick(all, {dx: PIVOT_DX, level: 1, periods: P.last10Years});
const names = PIVOT_DX.map(nameOf);
const rowKey = (d) => `${d.period} · ${d.location_name}`;
const indicatorPivot = html`<div style="max-height: 520px; overflow: auto">${pivot(pivotRows, {
  row: rowKey, col: (d) => d.name, colOrder: names, legend: COVERAGE_LEGEND, rowLabel: "Period · district",
  rowOrder: P.last10Years.flatMap((p) => DISTRICTS.map((n) => `${p} · ${n}`))
})}</div>`;
```

<div class="muted d2-footer">
Rebuilt from the demo DHIS2's <b>Immunization</b> dashboard (play.dhis2.org, Sierra Leone): all 17
items, from the values imported into the registry by <code>kiln dhis2</code>. Facility-level values were
imported for 2025 and 2026 only, so the facility maps are empty for earlier years. Differences from
DHIS2: the essential-vaccines chart has no 80% target line, the facilities map has no catchment
radius, and the OPV 3 gauge shows the latest month rather than this and last month combined.
</div>
