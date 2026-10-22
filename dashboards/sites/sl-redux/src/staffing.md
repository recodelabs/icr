---
title: Staffing
sql:
  values: data/values.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Staffing

<p class="rx-lede">Health workers by cadre, and the antenatal workload per clinical professional. The same items as the DHIS2 Staffing dashboard.</p>

```js
import {load, periods, yearsOf, namer, periodName, DISTRICTS, COUNTRY} from "./components/data.js";
import {filterBar, explore, itemOf} from "./components/compare.js";
import {panel, rank, scorecard, kpi} from "./components/viz.js";

const VISITS_PER_CLINICIAN = "Lzg9LtG1xg3";
const STAFF = ["LSJ5mKpyEv1", "vBu1MTGwcZh", "EzR5Y2V0JF9", "nlQztbooKAj", "zSl1hUZBDHY", "kFmyXB7IYrK", "eizakNwF2ep",
               "v0Shu9zrSh0", "q7QXzNnSstn", "OKj6vV8hmTP", "DUtltDE5ma1", "viFyEk7JmVd", "dIqx7rdnVc9", "zgeAdnpSY5K",
               "hkfMucdRMQG", "iVla5mEZiZo", "nu3vYkWgl2x", "Nz5YtOpDyuV"];
// DHIS2 names of the staff data elements; some (Doctor) have no values to read a name from.
const STAFF_NAMES = {LSJ5mKpyEv1: "CHO", vBu1MTGwcZh: "Community Health Assistant (CHA)", EzR5Y2V0JF9: "Dispenser", nlQztbooKAj: "Doctor", zSl1hUZBDHY: "EDC Unit Assitant", kFmyXB7IYrK: "EHO", eizakNwF2ep: "Laboratory Assistant", v0Shu9zrSh0: "Laboratory Technician", q7QXzNnSstn: "MCH Aide", OKj6vV8hmTP: "Midwife", DUtltDE5ma1: "Nursing Aide", viFyEk7JmVd: "Other staff", dIqx7rdnVc9: "PH Aide", zgeAdnpSY5K: "Porter", hkfMucdRMQG: "SECHN", iVla5mEZiZo: "Security worker", nu3vYkWgl2x: "SRN", Nz5YtOpDyuV: "Vaccinator"};
const all = await load(sql, [VISITS_PER_CLINICIAN, ...STAFF]);
const nameOf = namer(all, STAFF_NAMES);
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
const at = (dx, where, period = P.year) => all.find((d) => d.dx === dx && d.period === period && d.location_name === where)?.value;
const [prevHalf, lastHalf] = P.last2Halves.length === 2 ? P.last2Halves : [P.prevYear, P.year];
const staffItems = STAFF.map((dx) => itemOf(all, dx, nameOf)).filter((it) => all.some((d) => d.dx === it.dx));
const visits = itemOf(all, VISITS_PER_CLINICIAN, nameOf);
const totalStaff = (where, period) => d3.sum(STAFF, (dx) => at(dx, where, period) ?? 0);
```

<div class="rx-kpis">
${kpi({label: `Staff in post, ${periodName(lastHalf)}`, item: {dx: "staff", factor: 1, kind: "data element"}, value: totalStaff(COUNTRY, lastHalf), prev: totalStaff(COUNTRY, prevHalf), prevLabel: periodName(prevHalf)})}
${kpi({item: visits, value: at(VISITS_PER_CLINICIAN, COUNTRY), prev: at(VISITS_PER_CLINICIAN, COUNTRY, P.prevYear), prevLabel: P.prevYear, sub: `· ${COUNTRY}, ${P.year}`})}
</div>

<h2 class="rx-section">Staff by cadre</h2>

```js
const cadreRows = staffItems.map((it) => ({name: it.name, value: at(it.dx, COUNTRY, lastHalf), prev: at(it.dx, COUNTRY, prevHalf)}));
const staffValues = all.filter((d) => STAFF.includes(d.dx) && d.period === lastHalf);
```

<div class="rx-grid">
${panel(`Staff numbers, ${periodName(prevHalf)} and ${periodName(lastHalf)}`, resize((w) => rank(cadreRows, {item: {dx: "staff", factor: 1, kind: "data element"}, focus: [], width: w, prevLabel: periodName(prevHalf)})),
  {subtitle: `${COUNTRY}; dot: ${periodName(lastHalf)}, ring: ${periodName(prevHalf)}`})}
</div>

<div class="rx-block" style="margin-top: 14px">${panel(`Staff by district and cadre, ${periodName(lastHalf)}`, scorecard(staffValues, {items: staffItems, places: [COUNTRY, ...shown], focus: F.districts,
  prevValues: all.filter((d) => STAFF.includes(d.dx) && d.period === prevHalf)}), {subtitle: "Each cadre coloured on its own scale; ↑↓ change on the half-year before"})}</div>

<h2 class="rx-section">Antenatal workload</h2>

<div class="rx-block">${resize((w) => explore({all, dxs: [VISITS_PER_CLINICIAN], nameOf, geojson, F, P, state, width: w - 30, title: "ANC visits per clinical professional"}))}</div>

<div class="rx-footer">
Same items as the DHIS2 <b>Staffing</b> dashboard and sldash, from the values <code>kiln dhis2</code> imported into the registry.
DHIS2's map uses the fixed month March 2026; here the year is the one chosen above (choose Chiefdoms for the chiefdom map).
Staff counts are added up across cadres only for the total.
</div>
