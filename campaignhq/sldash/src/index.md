---
title: Sierra Leone Demo Dashboards
sql:
  values: data/values.parquet
---

# Sierra Leone Demo Dashboards (DHIS2 ported to FHIR)

```js
import {item, gauge, fmt} from "./components/dhis2.js";
import {load, pick} from "./components/page.js";

// One card per dashboard, in the menu's order: its page, a headline item (DHIS2 uid) and how to
// show it. Coverage-type percentages get a gauge; rates where lower is better, and counts, a figure.
const CARDS = [
  {name: "Antenatal Care", href: "./antenatal-care", dx: "Uvn6LCg7dVU", show: "gauge"},
  {name: "Delivery", href: "./delivery", dx: "Q3M7Htpzg1Y", show: "gauge"},
  {name: "Disease Surveillance", href: "./disease-surveillance", dx: "eZDhcZi6FLP.REPORTING-RATE", show: "gauge", max: 100},
  {name: "Immunization", href: "./immunization", dx: "tUIlpyeeX9N", show: "gauge"},
  {name: "Immunization data", href: "./immunization-data", dx: "eTDtyyaSA7f", show: "gauge"},
  {name: "Key Indicators", href: "./key-indicators", dx: "FnYCr2EAzWS", show: "gauge"},
  {name: "Malnutrition", href: "./malnutrition", dx: "vhzPbO1eEyr", show: "figure", unit: "%"},
  {name: "Measles", href: "./measles", dx: "FbKK4ofIv5R", show: "gauge"},
  {name: "Mother and Child Health", href: "./mother-and-child-health", dx: "c8fABiNpT0B", show: "gauge"},
  {name: "Nutrition", href: "./nutrition", dx: "vKWOc4itBo2", show: "figure", unit: "%"},
  {name: "Reporting Rates", href: "./reporting-rates", dx: "QX4ZTUbOt3a.REPORTING-RATE", show: "gauge", max: 100},
  {name: "Reporting Reproductive Health", href: "./reporting-reproductive-health", dx: "BfMAe6Itzgt.REPORTING-RATE", show: "gauge", max: 100},
  {name: "Staffing", href: "./staffing", dx: "Lzg9LtG1xg3", show: "figure", unit: ""},
  {name: "Visits ANC", href: "./visits-anc", dx: "OdiHJayrsKo", show: "gauge"}
];
const all = await load(sql, CARDS.map((c) => c.dx));
const year = Math.max(...all.filter((d) => d.period_type === "Yearly" && d.admin_level === 0).map((d) => Number(d.period)));
const national = (dx) => pick(all, {dx, level: 0, periods: [String(year)]})[0];
const card = (c) => {
  const d = national(c.dx);
  const label = d?.name ?? c.dx;
  const body = c.show === "gauge"
    ? html`<div style="display:flex;justify-content:center">${gauge(d?.value, {max: c.max ?? 120, width: 220, label})}</div>`
    : html`<div style="text-align:center;padding:24px 0 12px"><div class="d2-kpi">${d ? `${fmt(d.value)}${c.unit}` : "—"}</div>
        <div class="muted" style="font-size:12px;margin-top:6px">${label}</div></div>`;
  return item(html`<a href=${c.href}>${c.name}</a>`, body);
};
const grid = html`<div class="grid grid-cols-3" style="gap: 16px">${CARDS.map(card)}</div>`;
const yearNote = year === new Date().getFullYear()
  ? `Each card shows one national figure for ${year}, the year so far.`
  : `Each card shows one national figure for ${year}.`;
```

Health dashboards for Sierra Leone, rebuilt from the dashboards on the DHIS2 demo server
(play.dhis2.org) with the DHIS2 data held in the ICR registry. Each page follows one DHIS2
dashboard item by item. ${yearNote}

${grid}

<div class="muted d2-footer">
The DHIS2 demo's data is generated for training; it is not real Sierra Leone data. The values were
read from DHIS2's analytics with <code>kiln dhis2</code>, loaded into the registry as FHIR
<code>Measure</code> and <code>MeasureReport</code> resources, and flattened by the warehouse refresh
(<code>IcrIndicatorValue</code>). DHIS2 computes every value for its own place and period; nothing
here sums indicator values across places or periods.
</div>
