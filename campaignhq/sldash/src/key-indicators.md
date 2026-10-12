---
title: Key Indicators
sql:
  values: data/values.parquet
  groups: data/groups.parquet
---

# Key Indicators

```js
import {rows, item, pie, pivot, fmt} from "./components/dhis2.js";
import {columns} from "./components/charts.js";
import {load, pick, relative, DISTRICTS} from "./components/page.js";

// DHIS2 uids of the items on the demo's Key Indicators dashboard.
const DX = {
  morbidityRate: "eZDhcZi6FLP.REPORTING-RATE",
  anc1Cov: "Uvn6LCg7dVU", anc3Cov: "sB79w2hiLp8", anc4Cov: "AUqdhY4mpvp", phuDelivery: "Q3M7Htpzg1Y",
  bcgCov: "FnYCr2EAzWS", opv0Cov: "n5nS0SmkUpq", opv1Cov: "YlTWksXEhEO", opv2Cov: "QsuBK2pMfkk", opv3Cov: "JoEzWYGdX7s",
  penta1Cov: "i7WSgSJpnfu", penta2Cov: "Om2QoRtsncL", penta3Cov: "tUIlpyeeX9N", measlesCov: "FbKK4ofIv5R", fic: "eTDtyyaSA7f",
  wfhBelow70: "vKWOc4itBo2", wfh70to79: "nfG18MJZX5o", wfhAbove80: "GQHKiAe3DHR"
};
// The morbidity data elements and their groups in DHIS2's Diagnosis and Morbidity/Mortality group sets.
const SET = {diagnosis: "jp826jAJHUc", morbidityMortality: "lv8UXn17ZOm"};
const groups = rows(await sql([`SELECT * FROM groups WHERE group_set IN ('${SET.diagnosis}', '${SET.morbidityMortality}')`]));
const morbidityDx = Array.from(new Set(groups.filter((g) => g.group_set === SET.diagnosis).map((g) => g.dx)));
const all = await load(sql, [...Object.values(DX), ...morbidityDx]);
const years = Array.from(new Set(all.filter((d) => d.period_type === "Yearly").map((d) => d.period))).sort();
const nameOf = (dx) => all.find((d) => d.dx === dx)?.name ?? dx;
```

```js
const yearInput = Inputs.select(years, {label: "This year", value: years.at(-1)});
const selectedYear = Generators.input(yearInput);
```

```js
const year = Number(selectedYear);
```

<div class="d2-filter">${yearInput}<span class="muted">DHIS2's "this year" is the year chosen here. The user org unit is Sierra Leone; its children are the districts.</span></div>

```js
const P = relative(all, year);
const w = (n) => Math.max(320, (width - 24) / n - 24);
const cat = (rows, category, series) => rows.map((d) => ({category: category(d), series: series(d), value: d.value}));
// The user org unit and its children: Sierra Leone, then the 13 districts.
const PLACES = ["Sierra Leone", ...DISTRICTS];
const countryAndDistricts = (dx) => [...pick(all, {dx, level: 0, periods: [P.thisYear]}), ...pick(all, {dx, level: 1, periods: [P.thisYear]})];
const COVERAGE = [DX.bcgCov, DX.opv0Cov, DX.opv1Cov, DX.opv2Cov, DX.opv3Cov, DX.penta1Cov, DX.penta2Cov, DX.penta3Cov, DX.measlesCov, DX.fic];
const ANC_VS_PHU = [DX.anc1Cov, DX.anc4Cov, DX.phuDelivery];
const WFH = [DX.wfhBelow70, DX.wfh70to79, DX.wfhAbove80];
```

<div class="grid grid-cols-2" style="gap: 16px">
${item(`Reporting rates: Morbidity by orgunit ${year}`,
  columns(cat(countryAndDistricts(DX.morbidityRate), (d) => d.location_name, (d) => d.name),
    {width: w(2), yLabel: "%", categoryOrder: PLACES}))}
${item(`ANC: 1st and 3rd visit coverage by orgunit ${year}`,
  columns(cat(countryAndDistricts([DX.anc1Cov, DX.anc3Cov]), (d) => d.location_name, (d) => d.name),
    {horizontal: true, width: w(2), yLabel: "%", categoryOrder: PLACES, seriesOrder: [DX.anc1Cov, DX.anc3Cov].map(nameOf)}))}
${item(`Delivery: ANC coverage vs PHU delivery rate ${year}`,
  columns(cat(pick(all, {dx: ANC_VS_PHU, level: 0, periods: [P.thisYear]}), (d) => d.period, (d) => d.name),
    {width: w(2), yLabel: "%", seriesOrder: ANC_VS_PHU.map(nameOf)}))}
${item(`Immunization: Coverage rates ${year}`,
  columns(cat(pick(all, {dx: COVERAGE, level: 0, periods: [P.thisYear]}), (d) => d.name, (d) => d.location_name),
    {width: w(2), yLabel: "%", categoryOrder: COVERAGE.map(nameOf)}))}
${item(`DS: Cases by Diagnosis ${year}`, diagnosisPivot,
  {note: "Sierra Leone: the morbidity data elements added up by their group in DHIS2's Diagnosis set (rows) and Morbidity/Mortality set (columns). Imported for 2025 and 2026."})}
${item(`Nutrition: Weight for height rates ${year}`,
  pie(WFH.map((dx) => ({name: nameOf(dx), value: pick(all, {dx, level: 0, periods: [P.thisYear]})[0]?.value ?? 0})), {width: w(2)}),
  {note: "Sierra Leone. The three rates are shares of the children weighed, so they add up to about 100%."})}
</div>

```js
// Morbidity counts by Diagnosis group × Morbidity/Mortality group, summed over the data elements
// in both (data element counts can be summed; DHIS2 does the same for a group set dimension).
// A few data elements sit in two Diagnosis groups; DHIS2 counts them under each, and so does this.
const diagnosisOf = new Map();
for (const g of groups.filter((g) => g.group_set === SET.diagnosis)) diagnosisOf.set(g.dx, [...(diagnosisOf.get(g.dx) ?? []), g.group_name]);
const kindOf = new Map(groups.filter((g) => g.group_set === SET.morbidityMortality).map((g) => [g.dx, g.group_name]));
const KINDS = ["New cases", "Follow-up", "Referrals", "Deaths"];
const cells = new Map();
for (const d of pick(all, {dx: morbidityDx, level: 0, periods: [P.thisYear]})) {
  const kind = kindOf.get(d.dx);
  if (!kind || d.value == null) continue;
  for (const diagnosis of diagnosisOf.get(d.dx) ?? []) {
    const key = `${diagnosis}\u0000${kind}`;
    cells.set(key, (cells.get(key) ?? 0) + d.value);
  }
}
const diagnosisRows = Array.from(cells, ([key, value]) => {
  const [diagnosis, kind] = key.split("\u0000");
  return {diagnosis, kind, value};
});
const diagnosisPivot = diagnosisRows.length
  ? html`<div style="max-height: 460px; overflow: auto">${pivot(diagnosisRows, {
      row: (d) => d.diagnosis, col: (d) => `${year} · ${d.kind}`, digits: 0, rowLabel: "Diagnosis",
      rowOrder: Array.from(new Set(diagnosisRows.map((d) => d.diagnosis))).sort(),
      colOrder: KINDS.filter((k) => diagnosisRows.some((d) => d.kind === k)).map((k) => `${year} · ${k}`)})}</div>`
  : html`<p class="muted">No morbidity counts for ${year}.</p>`;
```

<div class="muted d2-footer">
Rebuilt from the demo DHIS2's <b>Key Indicators</b> dashboard (play.dhis2.org, Sierra Leone): all 6 items,
from the values imported into the registry by <code>kiln dhis2</code>, with the demo's user org unit,
Sierra Leone. The diagnosis table is rebuilt from the morbidity data elements and their DHIS2 group sets;
those were imported for 2025 and 2026 only.
</div>
