---
title: Disease Surveillance
sql:
  values: data/values.parquet
  groups: data/groups.parquet
---

# Disease Surveillance

```js
import {item, pivot, rows} from "./components/dhis2.js";
import {columns} from "./components/charts.js";
import {load, relative, DISTRICTS} from "./components/page.js";

// DHIS2 uids of the items on the demo's Disease Surveillance dashboard.
const DX = {morbidityRate: "eZDhcZi6FLP.REPORTING-RATE", diarrhoea: "JIVMtpjVZqJ"};
// The two data element group sets the "Cases by Diagnosis" table is laid out by.
const DIAGNOSIS = "jp826jAJHUc", MORBIDITY_MORTALITY = "lv8UXn17ZOm";
const MM_ORDER = ["New cases", "Follow-up", "Referrals", "Deaths"];
const groups = rows(await sql([`SELECT * FROM groups WHERE group_set IN ('${DIAGNOSIS}', '${MORBIDITY_MORTALITY}')`]));
const diagnosisOf = new Map(groups.filter((g) => g.group_set === DIAGNOSIS).map((g) => [g.dx, g.group_name]));
const typeOf = new Map(groups.filter((g) => g.group_set === MORBIDITY_MORTALITY).map((g) => [g.dx, g.group_name]));
const caseDx = Array.from(diagnosisOf.keys());
const all = await load(sql, [...Object.values(DX), ...caseDx]);
const years = Array.from(new Set(all.filter((d) => d.period_type === "Yearly" && Object.values(DX).includes(d.dx)).map((d) => d.period))).sort();
```

```js
const yearInput = Inputs.select(years, {label: "This year", value: years.at(-1)});
const selectedYear = Generators.input(yearInput);
```

```js
const year = Number(selectedYear);
const P = relative(all, year);
const w = (n) => Math.max(320, (width - 24) / n - 24);
// DHIS2's "user org unit and its children": the country, then the districts.
const OU = ["Sierra Leone", ...DISTRICTS];
const byOu = (dx) => columns(
  all.filter((d) => d.dx === dx && (d.admin_level === 0 || d.admin_level === 1) && d.period === P.thisYear)
     .map((d) => ({category: d.location_name, series: d.name, value: d.value})),
  {width: w(2), yLabel: "%", categoryOrder: OU});
```

```js
// Cases by Diagnosis: the country's counts for the year, each morbidity data element added to
// its Diagnosis group (rows) and its Morbidity/Mortality group (columns). Counts of data
// elements may be summed; DHIS2 sums them the same way for a group set.
const cells = new Map();
for (const d of all) {
  if (d.admin_level !== 0 || d.period !== P.thisYear || !diagnosisOf.has(d.dx) || d.value == null) continue;
  const key = `${diagnosisOf.get(d.dx)}\u0000${typeOf.get(d.dx) ?? "Other"}`;
  cells.set(key, (cells.get(key) ?? 0) + d.value);
}
const caseRows = Array.from(cells, ([k, value]) => {
  const [diagnosis, type] = k.split("\u0000");
  return {diagnosis, type: `${P.thisYear} · ${type}`, value};
});
const diagnoses = Array.from(new Set(caseRows.map((d) => d.diagnosis))).sort((a, b) => a.localeCompare(b));
const types = MM_ORDER.filter((t) => caseRows.some((d) => d.type === `${P.thisYear} · ${t}`)).map((t) => `${P.thisYear} · ${t}`);
```

<div class="d2-filter">${yearInput}<span class="muted">DHIS2's "this year" is the year chosen here.</span></div>

<div class="grid grid-cols-2" style="gap: 16px">
${item(`Reporting rates: Morbidity by orgunit ${year}`, byOu(DX.morbidityRate))}
${item(`DS: Cases by Diagnosis ${year}`, caseRows.length
  ? html`<div style="max-height: 520px; overflow: auto">${pivot(caseRows, {row: (d) => d.diagnosis, col: (d) => d.type, rowOrder: diagnoses, colOrder: types, digits: 0, rowLabel: "Diagnosis"})}</div>`
  : html`<p class="muted">No morbidity counts imported for ${year}; the registry holds them for 2025 and 2026.</p>`,
  {note: "Sierra Leone. Each cell adds up the morbidity data elements in that Diagnosis group and Morbidity/Mortality group; diagnoses with no cases are left out, as in DHIS2."})}
${item(`DS: Diarrhoea <5y incidence rate (%) by orgunit ${year}`, byOu(DX.diarrhoea))}
</div>

<div class="muted d2-footer">
Rebuilt from the demo DHIS2's <b>Disease Surveillance</b> dashboard (play.dhis2.org, Sierra Leone) with the
values imported into the registry by <code>kiln dhis2</code>. 3 of 4 items are shown; the first item is
DHIS2's messages box, which is not data. "User org unit and its children" is Sierra Leone and its 13 districts.
</div>
