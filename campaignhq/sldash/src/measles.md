---
title: Measles
sql:
  values: data/values.parquet
  strata: data/strata.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Measles

```js
import {item, pivot, legendKey, COVERAGE_LEGEND, fmt} from "./components/dhis2.js";
import {columns, thematic, periodName} from "./components/charts.js";
import {load, loadStrata, pick, pickStrata, relative, DISTRICTS, DIM, COUNTRY_ID} from "./components/page.js";
import {unitMap} from "./components/unit-map.js";

// DHIS2 uids of the items on the demo's Measles (user org unit) dashboard.
const DX = {
  dropMeasles: "d9thHOJMROr", measlesCov: "FbKK4ofIv5R",
  followUp: "uCVKV6PGGNB", newCases: "GCvqIM3IzN0", referrals: "eomLLbWJfcx"
};
const COUNTS = [DX.followUp, DX.newCases, DX.referrals];
const all = await load(sql, Object.values(DX));
const byType = await loadStrata(sql, [...COUNTS, DX.measlesCov, DX.dropMeasles], DIM.facilityType);
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

<div class="d2-filter">${yearInput}<span class="muted">DHIS2's relative periods (this year, last 4 quarters) count from this year. The user org unit is Sierra Leone: its children are the districts, its grandchildren the chiefdoms.</span></div>

```js
const P = relative(all, year);
const w = (n) => Math.max(320, (width - 24) / n - 24);
const cat = (rows, category, series) => rows.map((d) => ({category: category(d), series: series(d), value: d.value}));
const TYPES = ["CHC", "CHP", "Clinic", "Hospital", "MCHP"];
```

<div class="grid grid-cols-2" style="gap: 16px">
${item(`Measles: Coverage and drop-out (user org unit children) ${year}`,
  columns(cat(pick(all, {dx: [DX.dropMeasles, DX.measlesCov], level: 1, periods: [P.thisYear]}), (d) => d.location_name, (d) => d.name),
    {width: w(2), yLabel: "%", categoryOrder: DISTRICTS, seriesOrder: [DX.dropMeasles, DX.measlesCov].map(nameOf)}))}
${item("Measles: Follow-up, new, referrals (user org unit children)", districtPivot)}
${item(`Measles: Follow-up, new, referrals (user org unit grand children) ${year}`, chiefdomPivot,
  {note: "Chiefdoms with no measles cases are left out."})}
${item(`Measles: Follow-up, new, referrals by facility type (user org unit) ${year}`,
  columns(pickStrata(byType, {dx: COUNTS, location_id: COUNTRY_ID, periods: [P.thisYear]})
      .map((d) => ({category: nameOf(d.dx), series: d.option_name, value: d.value})),
    {width: w(2), categoryOrder: COUNTS.map(nameOf), seriesOrder: TYPES}),
  {note: "Sierra Leone, broken down by DHIS2's Facility Type group set."})}
${item("Measles: Follow-up, new, referrals by facility type (user org unit)", typePivot,
  {note: "DHIS2's title; the table holds Measles coverage and the Penta 1 – Measles dropout rate for Sierra Leone, by facility type."})}
${item(`Measles: Coverage ${year} (user org unit grand children)`, html`${coverageMap}${legendKey()}`)}
</div>

```js
// Districts × last 4 quarters, one column per count.
const districtRows = pick(all, {dx: COUNTS, level: 1, periods: P.last4Quarters});
const districtPivot = html`<div style="max-height: 420px; overflow: auto">${pivot(districtRows, {
  row: (d) => `${d.location_name} · ${periodName(d.period)}`, col: (d) => d.name, colOrder: COUNTS.map(nameOf), digits: 0,
  rowLabel: "District · quarter", rowOrder: DISTRICTS.flatMap((n) => P.last4Quarters.map((q) => `${n} · ${periodName(q)}`))
    .filter((k) => districtRows.some((d) => `${d.location_name} · ${periodName(d.period)}` === k))
})}</div>`;
```

```js
// Chiefdoms (with their district), this year.
const chiefdomRows = pick(all, {dx: COUNTS, level: 2, periods: [P.thisYear]});
const chiefdomKey = (d) => `${d.location_name} (${d.district})`;
const chiefdomPivot = html`<div style="max-height: 420px; overflow: auto">${pivot(chiefdomRows, {
  row: chiefdomKey, col: (d) => d.name, colOrder: COUNTS.map(nameOf), digits: 0, rowLabel: "Chiefdom (district)",
  rowOrder: Array.from(new Set(chiefdomRows.sort((a, b) => a.district.localeCompare(b.district) || a.location_name.localeCompare(b.location_name)).map(chiefdomKey)))
})}</div>`;
```

```js
// Sierra Leone × last 4 quarters; columns indicator · facility type.
const typeRows = pickStrata(byType, {dx: [DX.measlesCov, DX.dropMeasles], location_id: COUNTRY_ID, periods: P.last4Quarters});
const typePivot = html`<div style="overflow: auto">${pivot(typeRows, {
  row: (d) => `Sierra Leone · ${periodName(d.period)}`, col: (d) => `${nameOf(d.dx)} · ${d.option_name}`,
  colOrder: [DX.measlesCov, DX.dropMeasles].flatMap((dx) => TYPES.map((t) => `${nameOf(dx)} · ${t}`))
    .filter((k) => typeRows.some((d) => `${nameOf(d.dx)} · ${d.option_name}` === k)),
  rowLabel: "Org unit · quarter", rowOrder: P.last4Quarters.map((q) => `Sierra Leone · ${periodName(q)}`)
})}</div>`;
```

```js
const coverageMap = unitMap({geojson, height: 380});
thematic(coverageMap, pick(all, {dx: DX.measlesCov, level: 2, periods: [P.thisYear]}), {level: 2, legend: COVERAGE_LEGEND, label: "Measles Coverage <1y (%)"});
```

<div class="muted d2-footer">
Rebuilt from the demo DHIS2's <b>Measles (user org unit)</b> dashboard (play.dhis2.org, Sierra Leone):
all 6 items, from the values imported into the registry by <code>kiln dhis2</code>, with the demo's user
org unit, Sierra Leone. Quarters were imported for the last four quarters and this year, and the
facility-type breakdowns for 2025 and 2026, so earlier years leave those items empty.
</div>
