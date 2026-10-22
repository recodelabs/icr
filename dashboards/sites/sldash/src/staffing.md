---
title: Staffing
sql:
  values: data/values.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Staffing

```js
import {item} from "./components/dhis2.js";
import {columns, thematic, periodName} from "./components/charts.js";
import {load, pick, relative} from "./components/page.js";
import {unitMap} from "./components/unit-map.js";

// DHIS2 uids of the items on the demo's Staffing dashboard.
const VISITS_PER_CLINICIAN = "Lzg9LtG1xg3";
const STAFF = ["LSJ5mKpyEv1", "vBu1MTGwcZh", "EzR5Y2V0JF9", "nlQztbooKAj", "zSl1hUZBDHY", "kFmyXB7IYrK", "eizakNwF2ep",
               "v0Shu9zrSh0", "q7QXzNnSstn", "OKj6vV8hmTP", "DUtltDE5ma1", "viFyEk7JmVd", "dIqx7rdnVc9", "zgeAdnpSY5K",
               "hkfMucdRMQG", "iVla5mEZiZo", "nu3vYkWgl2x", "Nz5YtOpDyuV"];
const all = await load(sql, [VISITS_PER_CLINICIAN, ...STAFF]);
const years = Array.from(new Set(all.filter((d) => d.period_type === "Yearly").map((d) => d.period))).sort();
const geojson = await FileAttachment("data/units.geojson").json();
// DHIS2 names of the staff data elements; some (Doctor) have no values to read a name from.
const STAFF_NAMES = {LSJ5mKpyEv1: "CHO", vBu1MTGwcZh: "Community Health Assistant (CHA)", EzR5Y2V0JF9: "Dispenser", nlQztbooKAj: "Doctor", zSl1hUZBDHY: "EDC Unit Assitant", kFmyXB7IYrK: "EHO", eizakNwF2ep: "Laboratory Assistant", v0Shu9zrSh0: "Laboratory Technician", q7QXzNnSstn: "MCH Aide", OKj6vV8hmTP: "Midwife", DUtltDE5ma1: "Nursing Aide", viFyEk7JmVd: "Other staff", dIqx7rdnVc9: "PH Aide", zgeAdnpSY5K: "Porter", hkfMucdRMQG: "SECHN", iVla5mEZiZo: "Security worker", nu3vYkWgl2x: "SRN", Nz5YtOpDyuV: "Vaccinator"};
const nameOf = (dx) => STAFF_NAMES[dx] ?? all.find((d) => d.dx === dx)?.name ?? dx;
// Half-year codes as DHIS2 prints them: 2026S1 → January - June 2026.
const halfName = (p) => /^\d{4}S[12]$/.test(p) ? `${p.endsWith("S1") ? "January - June" : "July - December"} ${p.slice(0, 4)}` : periodName(p);
```

```js
const yearInput = Inputs.select(years, {label: "This year", value: years.at(-1)});
const selectedYear = Generators.input(yearInput);
```

```js
const year = Number(selectedYear);
const P = relative(all, year);
const w = (n) => Math.max(320, (width - 24) / n - 24);
```

<div class="d2-filter">${yearInput}<span class="muted">DHIS2's relative period "last 2 six-months" counts from this year. The map uses DHIS2's fixed period, March 2026.</span></div>

<div class="grid grid-cols-2" style="gap: 16px">
${item("Staffing: ANC visits/clinical professional with boundary (March 2026)", visitsMap,
  {note: "Per chiefdom, DHIS2's fixed period 202603, with chiefdom boundaries."})}
${item("Staffing: Staff numbers by period",
  columns(pick(all, {dx: STAFF, level: 0, periods: P.last2SixMonths}).map((d) => ({category: halfName(d.period), series: d.name, value: d.value})),
    {width: w(2), height: 380, categoryOrder: P.last2SixMonths.map(halfName), seriesOrder: STAFF.map(nameOf)}),
  {note: "Sierra Leone, the last two complete half-years."})}
</div>

```js
const visitsMap = unitMap({geojson, height: 420});
thematic(visitsMap, pick(all, {dx: VISITS_PER_CLINICIAN, level: 2, periods: ["202603"]}), {level: 2, label: "ANC visits per clinical professional"});
```

<div class="muted d2-footer">
Rebuilt from the demo DHIS2's <b>Staffing</b> dashboard (play.dhis2.org, Sierra Leone) with the values
imported into the registry by <code>kiln dhis2</code>: both items. Staff numbers are DHIS2 data element
values for the country; ANC visits per clinical professional is a ratio indicator (factor 1).
</div>
