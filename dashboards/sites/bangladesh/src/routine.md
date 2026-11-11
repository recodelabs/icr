---
title: Routine immunization (EPI e-Tracker)
sql:
  routine: data/routine.parquet
---

# Routine immunization (EPI e-Tracker)

```js
import {item, pivot, gauge, fmt, rows, legendKey, COVERAGE_LEGEND, MAP_LEGEND, GAUGE_LEGEND} from "./components/dhis2.js";
import {columns, lines, yearOverYear, thematic} from "./components/charts.js";
import {unitMap} from "./components/unit-map.js";

const VACCINES = [["bcg", "BCG"], ["penta1", "Penta-1"], ["penta2", "Penta-2"], ["penta3", "Penta-3"], ["mr1", "MR-1"], ["mr2", "MR-2"]];
const VNAME = new Map(VACCINES);
const COUNTRY = "bgd-I9x3B8oQvZH";
const short = (n) => (n ?? "").replace(/ (District|Upazila)$/, "");
const boundaries = await FileAttachment("data/boundaries.json").json();
const areas = rows(await sql`SELECT DISTINCT location_id, location_name, admin_level FROM routine WHERE admin_level = 2 ORDER BY location_name`);
```

```js
const yearInput = Inputs.select(["2026", "2025", "2024"], {label: "Year", value: "2025"});
const year = Generators.input(yearInput);
const vaccineInput = Inputs.select(VACCINES.map(([k]) => k), {label: "Vaccine", format: (k) => VNAME.get(k), value: "mr1"});
const vaccine = Generators.input(vaccineInput);
const areaInput = Inputs.select([null, ...areas], {label: "Area", format: (d) => d ? short(d.location_name) : "Bangladesh (by district)", value: null});
const area = Generators.input(areaInput);
```

<div class="d2-filter">${yearInput}${vaccineInput}${areaInput}<span class="muted">Children 0–11 months. 2026 runs January to October, with October still being reported.</span></div>

```js
const placeId = area?.location_id ?? COUNTRY;
const placeName = area ? short(area.location_name) : "Bangladesh";
// Units shown on the map and in the tables: districts and city corporations, or the upazilas of one.
const unitLevel = area ? 3 : 2;
const yearly = rows(await sql`SELECT * FROM routine WHERE period = ${year}`);
const here = (key, id = placeId) => yearly.find((d) => d.key === key && d.location_id === id);
const target = here("target");
const doses = here(`${vaccine}-doses`);
const cov = here(`${vaccine}-coverage`);
const covDash = here(`${vaccine}-coverage-dashboard`);
const zero = here("penta1-unvaccinated");
const units = area
  ? yearly.filter((d) => d.admin_level === 3 && d.district === short(area.location_name))
  : yearly.filter((d) => d.admin_level === 2);
const unitIds = new Set(units.map((d) => d.location_id));
const unitNames = Array.from(new Map(units.map((d) => [d.location_id, short(d.location_name)])).entries())
  .sort((a, b) => a[1].localeCompare(b[1]));
const kpi = (label, v, digits = 0, sub = "") => html`<div style="text-align:center;padding:18px 0 10px"><div class="d2-kpi">${v == null ? "—" : fmt(v, digits)}</div>
  <div class="muted" style="font-size:12px;margin-top:6px">${label}</div>${sub ? html`<div class="muted" style="font-size:11px;margin-top:2px">${sub}</div>` : ""}</div>`;
const w = (n) => Math.max(320, (width - 24) / n - 24);
```

<div class="grid grid-cols-4" style="gap: 16px">
${item(`Target children 0–11 months, ${placeName} ${year}`, kpi("Annual target (male + female)", target?.count, 0,
  target && !target.target_ok ? "Implausible: far from this place's other years, so coverage is not shown" : ""))}
${item(`${VNAME.get(vaccine)} doses given, ${placeName} ${year}`, kpi("Doses recorded in the e-Tracker", doses?.count, 0, year === "2026" ? "January to October" : ""))}
${item(`${VNAME.get(vaccine)} coverage, ${placeName} ${year}`, html`<div style="text-align:center">${gauge(cov?.value, {max: 100, label: "Doses ÷ target for the period (%)", width: 240, legend: MAP_LEGEND})}
  <div class="muted" style="font-size:11px">The GIS dashboard shows ${covDash?.value == null ? "—" : fmt(covDash.value) + "%"} (capped at 100)</div></div>`)}
${item(`Penta-1 zero-dose children, ${placeName} ${year}`, kpi("Target minus Penta-1 doses, by sub-block", zero?.count, 0, target?.count ? `${fmt(100 * zero.count / target.count)}% of the target` : ""))}
</div>

```js
const map = unitMap({geojson: boundaries, height: 520});
const covUnits = units.filter((d) => d.key === `${vaccine}-coverage`);
thematic(map, covUnits.map((d) => ({location_id: d.location_id, value: d.value, numerator: d.numerator, denominator: d.denominator})),
  {level: unitLevel, legend: MAP_LEGEND, label: `${VNAME.get(vaccine)} coverage ${year} (%)`});
const monthly = rows(await sql`SELECT period, value FROM routine WHERE key = ${vaccine + "-coverage"} AND location_id = ${placeId} AND period_type = 'Monthly' ORDER BY period`);
```

<div class="grid grid-cols-2" style="gap: 16px; margin-top: 16px">
${item(`${VNAME.get(vaccine)} coverage ${year} by ${area ? "upazila" : "district and city corporation"}`, map,
  {note: "Coverage is doses ÷ the target for the period, not capped. Grey: no e-Tracker figures (Chattogram, Rajbari and Shariatpur districts are not linked to the e-Tracker in the GIS dashboard)."})}
${item(`${VNAME.get(vaccine)} monthly coverage, ${placeName} (year over year)`, yearOverYear(monthly.filter((d) => d.value != null).map((d) => ({year: d.period.slice(0, 4), month: Number(d.period.slice(4)), value: d.value})),
  {width: w(2), height: 470, yLabel: "% of the monthly target"}),
  {note: "The monthly target is the annual target ÷ 12. A month far below the others is often missing reports rather than missed children."})}
</div>

```js
const byVaccine = ["2024", "2025", "2026"].flatMap((y) => VACCINES.map(([k, n]) => ({y, k, n})));
const allYears = rows(await sql`SELECT key, period, value FROM routine WHERE location_id = ${placeId} AND period_type = 'Yearly'`);
const yv = (key, y) => allYears.find((d) => d.key === key && d.period === y)?.value;
```

<div class="grid grid-cols-2" style="gap: 16px; margin-top: 16px">
${item(`Coverage by vaccine, ${placeName}`, columns(byVaccine.map(({y, k, n}) => ({category: n, series: y, value: yv(`${k}-coverage`, y)})).filter((d) => d.value != null),
  {width: w(2), height: 340, yLabel: "%"}))}
${item(`Dropout rates, ${placeName}`, pivot(["2024", "2025", "2026"].flatMap((y) => [
    {row: y, col: "Penta-1 → Penta-3 (%)", value: yv("dropout-penta1-penta3", y)},
    {row: y, col: "MR-1 → MR-2 (%)", value: yv("dropout-mr1-mr2", y)}
  ]), {row: (d) => d.row, col: (d) => d.col, rowLabel: "Year", digits: 1}),
  {note: "(first dose − last dose) ÷ first dose, the WHO definition. What the GIS dashboard calls \"dropout\" is the target minus doses."})}
</div>

```js
const order = unitNames.map(([, n]) => n);
const unitLabel = area ? "Upazila" : "District / CC";
```

<div class="grid grid-cols-2" style="gap: 16px; margin-top: 16px">
${item(`Coverage ${year} by ${area ? "upazila" : "district and city corporation"} (%)`, html`${pivot(
    units.filter((d) => d.metric === "coverage" && VNAME.has(d.vaccine)).map((d) => ({row: short(d.location_name), col: VNAME.get(d.vaccine), value: d.value})),
    {row: (d) => d.row, col: (d) => d.col, rowOrder: order, colOrder: VACCINES.map(([, n]) => n), rowLabel: unitLabel, digits: 1, legend: MAP_LEGEND})}${legendKey(MAP_LEGEND)}`)}
${item(`Target and dropout ${year} by ${area ? "upazila" : "district and city corporation"}`, pivot([
    ...units.filter((d) => d.key === "target").map((d) => ({row: short(d.location_name), col: "Target 0–11 m", value: d.count})),
    ...units.filter((d) => d.key === "penta1-unvaccinated").map((d) => ({row: short(d.location_name), col: "Penta-1 zero-dose", value: d.count})),
    ...units.filter((d) => d.metric === "dropout").map((d) => ({row: short(d.location_name), col: d.vaccine === "penta1-penta3" ? "Dropout Penta 1→3 (%)" : "Dropout MR 1→2 (%)", value: d.value}))
  ], {row: (d) => d.row, col: (d) => d.col, rowOrder: order,
      colOrder: ["Target 0–11 m", "Penta-1 zero-dose", "Dropout Penta 1→3 (%)", "Dropout MR 1→2 (%)"], rowLabel: unitLabel, digits: 1}))}
</div>

```js
const badTargets = rows(await sql`SELECT location_name, left(period, 4) AS year, count FROM routine
  WHERE key = 'target' AND NOT target_ok ORDER BY year, location_name`);
```

<div class="d2-footer muted">

**Targets left out.** The dashboard's target for these places and years is more than three times, or under a third of, the place's usual target, so coverage and zero-dose are not shown for them: ${badTargets.map((d) => `${short(d.location_name)} ${d.year} (${fmt(d.count, 0)})`).join("; ")}.

</div>

<div class="d2-footer muted">

**Source.** The DGHS GIS Microplanning dashboard (gisdashboard.dghs.gov.bd), which computes these figures from the DHIS2 EPI e-Tracker; downloaded on 20 October 2026 and loaded into the local FHIR server as `bd-ri-*` Measures. Upazila boundaries are the dashboard's; city corporation wards come from the city corporations' own shapefiles.

**Coverage.** Doses ÷ target for the period: the annual target for a year, ÷ 12 for a month, the months so far for 2026. The dashboard's own figure divides by the year-to-date target and caps at 100%; it is shown under the gauge for comparison.

**Care with low figures.** Many upazilas report far fewer doses from mid-2025 (Bagerhat Sadar: 255 BCG doses in January 2025, 10–16 a month from June). That pattern is more likely e-Tracker reporting than missed children. Seven dashboard upazilas hold the unions of two or three upazilas (Raninagar with Niamatpur, for example); their figures appear under the dashboard's name.

</div>
