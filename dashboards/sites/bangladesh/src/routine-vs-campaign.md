---
title: Routine vs MR campaign
sql:
  routine: data/routine.parquet
  campaign: data/campaign-coverage.parquet
---

# Routine immunization vs the MR campaign 2026

```js
import * as Plot from "npm:@observablehq/plot";
import {item, pivot, fmt, rows, legendKey, MAP_LEGEND, CAMPAIGN_LEGEND, DELTA_LEGEND} from "./components/dhis2.js";
import {thematic} from "./components/charts.js";
import {unitMap} from "./components/unit-map.js";
import {CAMPAIGN} from "./components/mr.js";

const short = (n) => (n ?? "").replace(/ (District|Upazila)$/, "");
const boundaries = await FileAttachment("data/boundaries.json").json();
const BASELINES = [
  ["12m", "12 months before the campaign (Apr 2025 – Mar 2026)", "202504", "202603"],
  ["2025", "Calendar year 2025", "202501", "202512"],
  ["2026", "2026 so far (Jan – Oct)", "202601", "202610"]
];
```

```js
const baselineInput = Inputs.select(BASELINES, {label: "Routine period", format: (b) => b[1], value: BASELINES[0]});
const baseline = Generators.input(baselineInput);
const doseInput = Inputs.select(["mr1", "mr2"], {label: "Routine dose", format: (k) => k === "mr1" ? "MR-1" : "MR-2", value: "mr1"});
const dose = Generators.input(doseInput);
const levelInput = Inputs.select([2, 3], {label: "Compare by", format: (l) => l === 2 ? "District and city corporation" : "Upazila", value: 2});
const level = Generators.input(levelInput);
```

<div class="d2-filter">${baselineInput}${doseInput}${levelInput}<span class="muted">Campaign: MR coverage for the whole campaign, ${CAMPAIGN.start} to ${CAMPAIGN.end}, children 9 months to under 15 years. Routine: ${dose === "mr1" ? "MR-1" : "MR-2"} doses ÷ target, children 0–11 months.</span></div>

```js
// Routine coverage over the chosen months, from summed doses and targets (months whose year
// has an implausible target are left out).
const routine = rows(await sql`
  SELECT location_id, any_value(location_name) AS location_name, any_value(district) AS district,
         sum(numerator) AS doses, sum(denominator) AS target, 100.0 * sum(numerator) / nullif(sum(denominator), 0) AS value,
         count(*) AS months
  FROM routine
  WHERE key = ${dose + "-coverage"} AND period_type = 'Monthly' AND period BETWEEN ${baseline[2]} AND ${baseline[3]}
    AND target_ok AND admin_level = ${level}
  GROUP BY location_id`);
const campaign = rows(await sql`SELECT * FROM campaign`);
const camp = new Map(campaign.map((d) => [d.location_id, d]));
const both = routine.map((r) => ({...r, name: short(r.location_name), campaign: camp.get(r.location_id)?.value,
    campaign_vaccinated: camp.get(r.location_id)?.vaccinated, campaign_target: camp.get(r.location_id)?.target}))
  .filter((d) => d.value != null && d.campaign != null);
const median = (xs) => { const s = xs.filter((x) => x != null).sort((a, b) => a - b); return s.length ? s[Math.floor(s.length / 2)] : null; };
const weakRoutineReached = both.filter((d) => d.value < 80 && d.campaign >= 95);
const bothLow = both.filter((d) => d.campaign < 95 && d.value < 80);
const kpi = (label, v, digits = 0, sub = "") => html`<div style="text-align:center;padding:18px 0 10px"><div class="d2-kpi">${v == null ? "—" : fmt(v, digits)}</div>
  <div class="muted" style="font-size:12px;margin-top:6px">${label}</div>${sub ? html`<div class="muted" style="font-size:11px;margin-top:2px">${sub}</div>` : ""}</div>`;
const unit = level === 2 ? "districts and city corporations" : "upazilas";
const w = (n) => Math.max(320, (width - 24) / n - 24);
```

<div class="grid grid-cols-4" style="gap: 16px">
${item("Places compared", kpi(`${unit} with both figures`, both.length))}
${item("Median routine coverage", kpi(`${dose === "mr1" ? "MR-1" : "MR-2"}, ${baseline[1]}`, median(both.map((d) => d.value)), 1, "%"))}
${item("Median campaign coverage", kpi("MR campaign 2026", median(both.map((d) => d.campaign)), 1, "%"))}
${item("Campaign reached where routine is weak", kpi(`routine under 80%, campaign 95% or more`, weakRoutineReached.length, 0,
  `${bothLow.length} ${unit} are under 80% routine and under 95% in the campaign`))}
</div>

```js
const scatter = Plot.plot({
  width: w(2), height: 460, marginLeft: 50, marginBottom: 40, grid: true,
  x: {label: `Routine ${dose === "mr1" ? "MR-1" : "MR-2"} coverage (%)`, domain: [0, Math.max(120, ...both.map((d) => Math.min(d.value, 200)))], clamp: true},
  // Campaign coverage sits near 100% almost everywhere, so the axis starts just below the lowest place.
  y: {label: "MR campaign coverage (%)", domain: [Math.min(90, Math.floor(Math.min(...both.map((d) => d.campaign)) / 5) * 5 - 5),
      Math.max(110, Math.min(200, Math.ceil(Math.max(...both.map((d) => d.campaign)) / 5) * 5 + 5))], clamp: true},
  marks: [
    Plot.rectY([{x1: 0, x2: 80, y1: 95, y2: 200}], {x1: "x1", x2: "x2", y1: "y1", y2: "y2", fill: "#eef6ea"}),
    Plot.rectY([{x1: 0, x2: 80, y1: 0, y2: 95}], {x1: "x1", x2: "x2", y1: "y1", y2: "y2", fill: "#fbeeee"}),
    Plot.ruleX([80], {stroke: "#94a3b8", strokeDasharray: "4,3"}),
    Plot.ruleY([95], {stroke: "#94a3b8", strokeDasharray: "4,3"}),
    Plot.text(["weak routine, campaign reached"], {frameAnchor: "top-left", dx: 6, dy: 6, fill: "#4b5563", fontSize: 11}),
    Plot.text(["weak in both"], {frameAnchor: "bottom-left", dx: 6, dy: -6, fill: "#4b5563", fontSize: 11}),
    Plot.dot(both, {x: (d) => Math.min(d.value, 200), y: (d) => Math.min(d.campaign, 200), r: level === 2 ? 5 : 3.5,
      fill: "#518cc3", fillOpacity: 0.75, stroke: "white", strokeWidth: 1,
      tip: true, title: (d) => `${d.name}${level === 3 ? `, ${d.district}` : ""}\nRoutine: ${fmt(d.value)}% (${fmt(d.doses, 0)} ÷ ${fmt(d.target, 0)})\nCampaign: ${fmt(d.campaign)}% (${fmt(d.campaign_vaccinated, 0)} ÷ ${fmt(d.campaign_target, 0)})`}),
    ...(level === 2 ? [Plot.text(both.filter((d) => d.value < 25 || d.campaign < 90 || d.value > 95), {x: (d) => Math.min(d.value, 200), y: (d) => Math.min(d.campaign, 200), text: "name", dx: 7, textAnchor: "start", fontSize: 10, fill: "#334155"})] : [])
  ]
});
```

<div class="grid grid-cols-2" style="gap: 16px; margin-top: 16px">
${item(`Routine against campaign coverage, by ${level === 2 ? "district and city corporation" : "upazila"}`, scatter,
  {note: "Each dot is a place. Dashed lines: 80% routine, 95% campaign. Values over 200% are drawn at 200. Low routine figures can be missing e-Tracker reports rather than missed children."})}
${item("Where the two disagree most", pivot(both.slice().sort((a, b) => (b.campaign - b.value) - (a.campaign - a.value)).slice(0, 25).flatMap((d) => [
    {row: d.name, col: "Routine (%)", value: d.value},
    {row: d.name, col: "Campaign (%)", value: d.campaign},
    {row: d.name, col: "Difference (points)", value: d.campaign - d.value}
  ]), {row: (d) => d.row, col: (d) => d.col, colOrder: ["Routine (%)", "Campaign (%)", "Difference (points)"], rowLabel: level === 2 ? "District / CC" : "Upazila", digits: 1}),
  {note: "The 25 places where the campaign's coverage is furthest above routine coverage."})}
</div>

```js
const routineMap = unitMap({geojson: boundaries, height: 480});
thematic(routineMap, both.map((d) => ({location_id: d.location_id, value: d.value, numerator: d.doses, denominator: d.target})),
  {level, legend: MAP_LEGEND, label: `Routine ${dose === "mr1" ? "MR-1" : "MR-2"} coverage (%)`});
const campaignMap = unitMap({geojson: boundaries, height: 480});
thematic(campaignMap, both.map((d) => ({location_id: d.location_id, value: d.campaign, numerator: d.campaign_vaccinated, denominator: d.campaign_target})),
  {level, legend: CAMPAIGN_LEGEND, label: "MR campaign coverage (%)"});
```

```js
const deltaMap = unitMap({geojson: boundaries, height: 560});
thematic(deltaMap, both.map((d) => ({location_id: d.location_id, value: +(d.campaign - d.value).toFixed(1)})),
  {level, legend: DELTA_LEGEND, label: "Campaign minus routine coverage (percentage points)"});
```

<div class="grid grid-cols-2" style="gap: 16px; margin-top: 16px">
${item(`Routine ${dose === "mr1" ? "MR-1" : "MR-2"} coverage, ${baseline[1]}`, routineMap)}
${item(`MR campaign coverage, ${CAMPAIGN.start} to ${CAMPAIGN.end}`, campaignMap)}
</div>

<div style="margin-top: 16px">
${item(`The gap the campaign filled: campaign minus routine ${dose === "mr1" ? "MR-1" : "MR-2"} coverage, by ${level === 2 ? "district and city corporation" : "upazila"}`, deltaMap,
  {note: "Percentage points. Dark red: the campaign reached far more of its target than routine immunization did, which is where routine is weakest (or its reporting). Blue: routine coverage is above the campaign's. Grey: no value in one of the two."})}
</div>

<div style="margin-top: 16px">
${item(`All ${unit}`, html`${pivot(both.slice().sort((a, b) => a.name.localeCompare(b.name)).flatMap((d) => [
    {row: d.name, col: "Routine (%)", value: d.value},
    {row: d.name, col: "Campaign (%)", value: d.campaign}
  ]), {row: (d) => d.row, col: (d) => d.col, colOrder: ["Routine (%)", "Campaign (%)"], rowLabel: level === 2 ? "District / CC" : "Upazila", digits: 1,
      legend: (c) => c.startsWith("Campaign") ? CAMPAIGN_LEGEND : MAP_LEGEND})}
  <div class="muted" style="font-size:11px;margin-top:6px">Routine</div>${legendKey(MAP_LEGEND)}
  <div class="muted" style="font-size:11px;margin-top:6px">Campaign</div>${legendKey(CAMPAIGN_LEGEND)}`)}
</div>

<div class="d2-footer muted">

**The two figures measure different things.** Routine coverage is the share of children aged 0–11 months who got ${dose === "mr1" ? "MR-1" : "MR-2"} through the EPI e-Tracker, from the DGHS GIS dashboard. Campaign coverage is the share of children aged 9 months to under 15 years vaccinated in the 2026 MR campaign, from the EPI campaign DHIS2. A place can reach every child in the campaign and still have weak routine coverage: that is what a campaign is for. Where the campaign is high and routine is low, the campaign filled a gap; where both are low, children were missed twice.

**Routine data quality.** Routine figures depend on e-Tracker reporting, which dropped in many upazilas from mid-2025, so a low routine figure can be missing reports. Places whose dashboard target is implausible for a year are left out of that year's months. Chattogram, Rajbari and Shariatpur districts have no routine figures (not linked to the e-Tracker in the dashboard).

</div>
