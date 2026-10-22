---
title: Reporting Rates
sql:
  values: data/values.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Reporting Rates

<p class="rx-lede">Which health units sent their monthly forms: each form by district and month, so gaps in the data behind the other dashboards show up. The same items as the DHIS2 Reporting Rates dashboard.</p>

```js
import {load, periods, yearsOf, namer, periodName, periodDate, placeOf, DISTRICTS, COUNTRY} from "./components/data.js";
import {filterBar, explore, headline, itemOf} from "./components/compare.js";
import {panel, heatmap, lines, scorecard, swatches, scaleKey} from "./components/viz.js";
import {SERIES} from "./components/theme.js";

const DX = {
  morbidity: "eZDhcZi6FLP.REPORTING-RATE", childHealth: "BfMAe6Itzgt.REPORTING-RATE", rh: "QX4ZTUbOt3a.REPORTING-RATE",
  hiv: "EDzMBk0RRji.REPORTING-RATE", pmtct: "Rl58JxmKJo2.REPORTING-RATE", tb: "OsPTWNqq26W.REPORTING-RATE",
  anc3Cov: "sB79w2hiLp8", skilledPop: "elTqMUTRgdk", phuByPop: "Q3M7Htpzg1Y"
};
// The three PHU forms (PHUF 1–3) and the three HIV/TB forms.
const PHUF = [DX.morbidity, DX.childHealth, DX.rh];
const FORMS = [...PHUF, DX.hiv, DX.pmtct, DX.tb];
const all = await load(sql, Object.values(DX));
const nameOf = namer(all);
const short = (dx) => nameOf(dx).replace(" - Reporting rate", "").replace(" monthly summary", "");
const geojson = await FileAttachment("data/units.geojson").json();
const filters = filterBar(yearsOf(all));
const state = {};
```

<div>${filters}</div>

```js
const F = Generators.input(filters);
```

```js
const P = periods(all, F.year);
const shown = F.districts.length ? F.districts : DISTRICTS;
const place = placeOf(F);
const at = (dx, where, period = P.year) => all.find((d) => d.dx === dx && d.period === period && d.location_name === where)?.value;
const monthTick = (d) => d.toLocaleString("en", {month: "short", year: "2-digit", timeZone: "UTC"});
const monthly = (dxs, name = short) => dxs.flatMap((dx) => P.last12Months.map((p) => ({date: periodDate(p), period: p, series: name(dx), value: at(dx, place, p)}))).filter((r) => r.value != null);
```

<div class="rx-block">${headline({all, dxs: FORMS, nameOf, F, P})}</div>

<h2 class="rx-section">Each form by district and month</h2>

```js
const formInput = Inputs.radio(new Map(FORMS.map((dx) => [short(dx), dx])), {label: "Form", value: DX.rh});
const form = Generators.input(formInput);
```

<div class="rx-panel">
<header><h3>Reports received by district, last 12 months</h3><p>Pick a form; districts sorted by the latest month, worst first</p></header>
<div style="margin: 8px 0">${formInput}</div>
${resize((w) => {
  const item = itemOf(all, form, nameOf);
  const rows = all.filter((d) => d.dx === form && (d.admin_level === 0 || (d.admin_level === 1 && shown.includes(d.location_name))) && P.last12Months.includes(d.period))
    .map((d) => ({x: d.period, y: d.location_name, value: d.value}));
  const order = [COUNTRY, ...shown.slice().sort((a, b) => (at(form, a, P.lastMonth) ?? 0) - (at(form, b, P.lastMonth) ?? 0))];
  return html`<div class="rx-legend">${scaleKey(item, rows.map((r) => r.value))}</div>${heatmap(rows, {item, xOrder: P.last12Months, yOrder: order, xFormat: (p) => periodName(p, {short: true}), width: w - 30})}`;
})}
</div>

<h2 class="rx-section">Compare districts</h2>

<div class="rx-block">${resize((w) => explore({all, dxs: FORMS, nameOf, geojson, F, P, state, width: w - 30}))}</div>

<h2 class="rx-section">Forms side by side</h2>

```js
const quarterRows = FORMS.flatMap((dx) => P.last4Quarters.map((p) => ({x: p, y: short(dx), value: at(dx, place, p)})));
const rhItem = itemOf(all, DX.rh, nameOf);
const rch = [DX.rh, DX.anc3Cov, DX.skilledPop, DX.phuByPop];
```

<div class="rx-grid">
${panel(`PHU forms, last 12 months: ${place}`, resize((w) => lines(monthly(PHUF), {seriesOrder: PHUF.map(short), width: w, unit: "%", xFormat: monthTick})),
  {legend: swatches(PHUF.map(short))})}
${panel(`HIV, PMTCT and TB forms, last 12 months: ${place}`, resize((w) => lines(monthly([DX.hiv, DX.pmtct, DX.tb]), {seriesOrder: [DX.hiv, DX.pmtct, DX.tb].map(short), colors: SERIES.slice(3), width: w, unit: "%", xFormat: monthTick})),
  {legend: swatches([DX.hiv, DX.pmtct, DX.tb].map(short), SERIES.slice(3))})}
${panel(`Every form, last 4 quarters: ${place}`, resize((w) => heatmap(quarterRows, {item: rhItem, xOrder: P.last4Quarters, yOrder: FORMS.map(short), xFormat: (p) => periodName(p), width: w, cell: 24})),
  {legend: scaleKey(rhItem, quarterRows.map((r) => r.value))})}
${panel(`Reproductive health reports against ANC and delivery, last 12 months: ${place}`, resize((w) => lines(monthly(rch, (dx) => dx === DX.rh ? "RH reports received" : nameOf(dx).replace(" (estimated pregancies)", "").replace(" (by expected pregnancies)", "")),
    {width: w, unit: "%", xFormat: monthTick})),
  {subtitle: "When fewer reports come in, coverage drops with them"})}
</div>

<div class="rx-block">${panel(`PHU forms by district, ${P.year}`, scorecard(all.filter((d) => d.period === P.year && FORMS.includes(d.dx)), {items: FORMS.map((dx) => itemOf(all, dx, nameOf)), places: [COUNTRY, ...shown], focus: F.districts,
  prevValues: all.filter((d) => d.period === P.prevYear && FORMS.includes(d.dx)), shortName: (it) => short(it.dx)}),
  {subtitle: "Reports received (%) per form and district; ↑↓ change on last year"})}</div>

<div class="rx-footer">
Same items as the DHIS2 <b>Reporting Rates</b> dashboard and sldash, from the values <code>kiln dhis2</code> imported into the registry.
A reporting rate is the reports received divided by the reports expected. The DHIS2 chiefdom maps of PHUF 1–3 are in the comparison (choose Chiefdoms).
</div>
