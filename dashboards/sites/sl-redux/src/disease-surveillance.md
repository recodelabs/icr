---
title: Disease Surveillance
sql:
  values: data/values.parquet
  groups: data/groups.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Disease Surveillance

<p class="rx-lede">Cases seen at health units by diagnosis, diarrhoea in children under five, and whether the morbidity reports behind them came in. The same items as the DHIS2 Disease Surveillance dashboard.</p>

```js
import {load, rows, periods, yearsOf, namer, DISTRICTS, COUNTRY} from "./components/data.js";
import {filterBar, explore, headline, itemOf} from "./components/compare.js";
import {panel, stackBars, heatmap, scatter, swatches} from "./components/viz.js";
import {SERIES, QUANTITY} from "./components/theme.js";

const DX = {morbidityRate: "eZDhcZi6FLP.REPORTING-RATE", diarrhoea: "JIVMtpjVZqJ"};
// The two data element group sets the "Cases by Diagnosis" table is laid out by.
const DIAGNOSIS = "jp826jAJHUc", MORBIDITY_MORTALITY = "lv8UXn17ZOm";
const MM_ORDER = ["New cases", "Follow-up", "Referrals", "Deaths"];
const groups = rows(await sql([`SELECT * FROM groups WHERE group_set IN ('${DIAGNOSIS}', '${MORBIDITY_MORTALITY}')`]));
const diagnosisOf = new Map(groups.filter((g) => g.group_set === DIAGNOSIS).map((g) => [g.dx, g.group_name]));
const typeOf = new Map(groups.filter((g) => g.group_set === MORBIDITY_MORTALITY).map((g) => [g.dx, g.group_name]));
const all = await load(sql, [...Object.values(DX), ...diagnosisOf.keys()]);
const nameOf = namer(all);
const geojson = await FileAttachment("data/units.geojson").json();
const filters = filterBar(yearsOf(all.filter((d) => Object.values(DX).includes(d.dx))));
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
```

<div class="rx-block">${headline({all, dxs: [DX.morbidityRate, DX.diarrhoea], nameOf, F, P})}</div>

<h2 class="rx-section">Compare districts</h2>

<div class="rx-block">${resize((w) => explore({all, dxs: [DX.diarrhoea, DX.morbidityRate], nameOf, geojson, F, P, state, width: w - 30}))}</div>

<h2 class="rx-section">Cases by diagnosis</h2>

```js
// Morbidity data elements added up by Diagnosis group and Morbidity/Mortality group, as DHIS2
// adds them for a group set. For the country, or for the picked districts together.
const places = F.districts.length ? F.districts : [COUNTRY];
const caseRows = [];
for (const d of all) {
  if (d.period !== P.year || !diagnosisOf.has(d.dx) || d.value == null || !places.includes(d.location_name)) continue;
  caseRows.push({category: diagnosisOf.get(d.dx), series: typeOf.get(d.dx) ?? "Other", value: d.value});
}
const summed = Array.from(d3.rollup(caseRows, (v) => d3.sum(v, (r) => r.value), (r) => r.category, (r) => r.series),
  ([category, m]) => Array.from(m, ([series, value]) => ({category, series, value}))).flat();
const types = MM_ORDER.filter((t) => summed.some((r) => r.series === t));
// New cases by diagnosis and district: the diagnoses with most cases nationally.
const newDx = Array.from(diagnosisOf.keys()).filter((dx) => typeOf.get(dx) === "New cases");
const byDistrict = [];
for (const dx of newDx) for (const n of shown) {
  const v = at(dx, n);
  if (v != null) byDistrict.push({x: n, y: diagnosisOf.get(dx), value: v});
}
const diagTotals = d3.rollup(byDistrict, (v) => d3.sum(v, (r) => r.value), (r) => r.y);
const topDiagnoses = Array.from(diagTotals.keys()).sort((a, b) => diagTotals.get(b) - diagTotals.get(a)).slice(0, 14);
const countItem = {dx: "count", name: "New cases", factor: 1, kind: "data element"};
```

<div class="rx-grid">
${panel(`Cases by diagnosis, ${P.year}`, summed.length ? resize((w) => stackBars(summed, {seriesOrder: types, colors: [SERIES[0], SERIES[1], SERIES[2], SERIES[9]], width: w})) : html`<p class="rx-sub">No morbidity counts for ${P.year}; the registry holds them for 2025 and 2026.</p>`,
  {subtitle: `${F.districts.length ? F.districts.join(", ") : COUNTRY}: new cases, follow-ups, referrals and deaths added up per diagnosis`, legend: swatches(types, [SERIES[0], SERIES[1], SERIES[2], SERIES[9]])})}
${panel(`New cases by diagnosis and district, ${P.year}`, byDistrict.length ? resize((w) => heatmap(byDistrict.filter((r) => topDiagnoses.includes(r.y)), {item: countItem, xOrder: shown, yOrder: topDiagnoses, width: w, cell: 20})) : html`<p class="rx-sub">No values.</p>`,
  {subtitle: "The 14 diagnoses with most new cases; darker is more cases"})}
</div>

```js
const scatterRows = [COUNTRY, ...shown].map((n) => ({name: n, level: n === COUNTRY ? 0 : 1, x: at(DX.morbidityRate, n), y: at(DX.diarrhoea, n)}));
```

<div class="rx-grid">
${panel(`Reports received against diarrhoea recorded, ${P.year}`, resize((w) => scatter(scatterRows, {xItem: itemOf(all, DX.morbidityRate, nameOf), yItem: itemOf(all, DX.diarrhoea, nameOf),
    xLabel: "Morbidity reports received (%)", yLabel: "Diarrhoea <5y incidence (%)", focus: F.districts, width: w, height: 280})),
  {subtitle: "A district with few reports received may show low incidence because cases were not reported"})}
</div>

<div class="rx-footer">
Same items as the DHIS2 <b>Disease Surveillance</b> dashboard and sldash (the messages box is not data), from the values <code>kiln dhis2</code> imported into the registry.
Case counts are added up across data elements of a group, as DHIS2 does for a group set; rates are DHIS2's own values.
</div>
