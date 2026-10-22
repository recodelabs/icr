---
title: Overview
sql:
  values: data/values.parquet
---

# Sierra Leone Demo Dashboards (DHIS2 ported to FHIR)

<p class="rx-lede">The DHIS2 demo's Sierra Leone dashboards, with the same indicators as sldash, redrawn for comparing districts. Each card shows a dashboard's headline indicator for the country, its change on last year, and the 13 districts on one line (black tick: Sierra Leone). Pick districts to outline them here and to filter every page.</p>

```js
import {load, periods, yearsOf, namer, periodDate, DISTRICTS, COUNTRY} from "./components/data.js";
import {filterBar, itemOf} from "./components/compare.js";
import {panel, scorecard, dotStrip} from "./components/viz.js";
import {direction, fmt, fmtValue} from "./components/theme.js";

// Each dashboard and the indicator that leads it.
const DASHBOARDS = [
  {name: "Antenatal Care", path: "./antenatal-care", dx: "Uvn6LCg7dVU", about: "First to third visits, where women are seen"},
  {name: "Delivery", path: "./delivery", dx: "Q3M7Htpzg1Y", about: "Births at health units and skilled attendance"},
  {name: "Disease Surveillance", path: "./disease-surveillance", dx: "JIVMtpjVZqJ", about: "Cases by diagnosis, diarrhoea under five"},
  {name: "Immunization", path: "./immunization", dx: "tUIlpyeeX9N", about: "Coverage by vaccine, drop-out, ten years"},
  {name: "Immunization data", path: "./immunization-data", dx: "eTDtyyaSA7f", about: "Doses and coverage month by month"},
  {name: "Key Indicators", path: "./key-indicators", dx: "FbKK4ofIv5R", about: "Every district against every key indicator"},
  {name: "Malnutrition", path: "./malnutrition", dx: "vhzPbO1eEyr", about: "Moderate and severe malnutrition"},
  {name: "Measles", path: "./measles", dx: "d9thHOJMROr", about: "Coverage, drop-out and cases"},
  {name: "Mother and Child Health", path: "./mother-and-child-health", dx: "ReUHfIn0pTQ", about: "ANC drop-out, IPT and bed nets"},
  {name: "Nutrition", path: "./nutrition", dx: "vKWOc4itBo2", about: "Weight for height"},
  {name: "Reporting Rates", path: "./reporting-rates", dx: "eZDhcZi6FLP.REPORTING-RATE", about: "Every form by district and month"},
  {name: "Reporting Reproductive Health", path: "./reporting-reproductive-health", dx: "QX4ZTUbOt3a.REPORTING-RATE", about: "The three major forms"},
  {name: "Staffing", path: "./staffing", dx: "Lzg9LtG1xg3", about: "Staff by cadre, workload"},
  {name: "Visits ANC", path: "./visits-anc", dx: "sB79w2hiLp8", about: "ANC 2, ANC 3 and bed nets against last year"}
];
const all = await load(sql, DASHBOARDS.map((d) => d.dx));
const nameOf = namer(all);
const filters = filterBar(yearsOf(all.filter((d) => d.dx === "Uvn6LCg7dVU")), {level: false});
```

<div>${filters}</div>

```js
const F = Generators.input(filters);
```

```js
const P = periods(all, F.year);
const shown = F.districts.length ? F.districts : DISTRICTS;
const at = (dx, where, period = P.year) => all.find((d) => d.dx === dx && d.period === period && d.location_name === where)?.value;
const card = (b) => {
  const item = itemOf(all, b.dx, nameOf);
  const now = at(b.dx, COUNTRY), before = at(b.dx, COUNTRY, P.prevYear);
  const delta = now != null && before != null ? now - before : null;
  const good = delta == null || direction(item) == null ? null : (delta >= 0) === (direction(item) === "up");
  const rows = DISTRICTS.map((n) => ({name: n, value: at(b.dx, n)}));
  const best = rows.filter((r) => r.value != null).sort((a, c) => direction(item) === "down" ? a.value - c.value : c.value - a.value);
  return html`<a class="rx-card" href=${b.path}>
    <h3>${b.name}</h3><p>${b.about}</p>
    <div class="rx-kpi-label" style="min-height:0">${item.name}, ${P.year}</div>
    <div class="rx-kpi-row"><span class="rx-kpi-value">${fmtValue(item, now)}</span>
      ${delta != null ? html`<span class="rx-delta ${good === true ? "up" : good === false ? "down" : ""}">${delta >= 0 ? "▲" : "▼"} ${fmt(Math.abs(delta))}${item.factor === 100 ? " pts" : ""} on ${P.prevYear}</span>` : ""}</div>
    ${dotStrip(rows, {item, national: now, width: 250, focus: F.districts})}
    <div class="rx-kpi-sub">${best.length ? html`Best ${best[0].name} (${fmtValue(item, best[0].value)}), worst ${best.at(-1).name} (${fmtValue(item, best.at(-1).value)})` : ""}</div>
  </a>`;
};
```

<div class="rx-cards">${DASHBOARDS.map(card)}</div>

<h2 class="rx-section">Every district, one headline indicator per dashboard</h2>

```js
const items = Array.from(new Set(DASHBOARDS.map((d) => d.dx))).map((dx) => itemOf(all, dx, nameOf));
const short = (it) => it.name.replace(" - Reporting rate", " reports").replace(" Coverage", "").replace(" <1y", "").replace("PHU delivery rate (by expected pregnancies)", "PHU delivery").replace("Weight for height", "WfH").replace("ANC visits per clinical professional", "ANC visits per clinician");
```

<div class="rx-block">${panel(`Headline indicators by district, ${P.year}`, scorecard(all.filter((d) => d.period === P.year), {items, places: [COUNTRY, ...shown], focus: F.districts,
  prevValues: all.filter((d) => d.period === P.prevYear), shortName: short}),
  {subtitle: "Each column on its own scale, orange worse to blue better (lower is better for drop-out, malnutrition and diarrhoea); ↑↓ change on last year"})}</div>

<div class="rx-footer">
The values are DHIS2's own, imported into the ICR registry with <code>kiln dhis2</code> and read from the warehouse parquet (<code>IcrIndicatorValue</code>). Same data as sldash, which follows the DHIS2 layout item by item.
</div>
