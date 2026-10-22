---
title: Visits ANC
sql:
  values: data/values.parquet
---

# Visits ANC

```js
import {item, gauge, GAUGE_LEGEND} from "./components/dhis2.js";
import {load, pick, relative} from "./components/page.js";

// DHIS2 uids of the items on the demo's Visits ANC dashboard.
const DX = {anc3Cov: "sB79w2hiLp8", anc2Cov: "OdiHJayrsKo", llitnCov: "Tt5TAvdfdVK"};
const all = await load(sql, Object.values(DX));
const years = Array.from(new Set(all.filter((d) => d.period_type === "Yearly").map((d) => d.period))).sort();
```

```js
const yearInput = Inputs.select(years, {label: "This year", value: years.at(-1)});
const selectedYear = Generators.input(yearInput);
```

```js
const year = Number(selectedYear);
const P = relative(all, year);
const w = (n) => Math.max(260, (width - 24) / n - 24);
// One gauge of a coverage indicator for Sierra Leone (DHIS2's user org unit) this year.
const dial = (dx) => {
  const d = pick(all, {dx, level: 0, periods: [P.thisYear]})[0];
  return html`<div style="display:flex;justify-content:center">${gauge(d?.value, {max: 120, label: `${d?.name ?? dx} (%)`, width: Math.min(340, w(3)), legend: GAUGE_LEGEND})}</div>`;
};
```

<div class="d2-filter">${yearInput}<span class="muted">DHIS2's relative period "this year" counts from this year.</span></div>

<div class="grid grid-cols-3" style="gap: 16px">
${item(`ANC: ANC 3 coverage ${year} (gauge)`, dial(DX.anc3Cov))}
${item(`ANC: ANC 2 coverage ${year} (gauge)`, dial(DX.anc2Cov))}
${item(`ANC: ANC LLITN coverage ${year} (gauge)`, dial(DX.llitnCov))}
</div>

<div class="muted d2-footer">
Rebuilt from the demo DHIS2's <b>Visits ANC</b> dashboard (play.dhis2.org, Sierra Leone) with the values
imported into the registry by <code>kiln dhis2</code>: all 3 gauges, for Sierra Leone. Gauge colours
follow the Immunization Coverage legend's bands, in softer colours than DHIS2's.
</div>
