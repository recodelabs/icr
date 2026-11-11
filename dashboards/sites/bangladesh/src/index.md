---
title: MR Vaccination Campaign 2026
sql:
  values: data/values.parquet
  campaign: data/campaign-coverage.parquet
---

# MR Vaccination Campaign 2026

```js
import {item, pivot, fmt, rows} from "./components/dhis2.js";
import {columns, lines} from "./components/charts.js";
import {DX, COUNTRY_ID, CAMPAIGN, load, total, coverage, campaignDays, index, countOf} from "./components/mr.js";

const all = await load(sql, [DX.target, DX.vaccinated, DX.coverage]);
const at = index(all);
const days = campaignDays(all);
const places = (level, division) => Array.from(new Map(all.filter((d) => d.level === level && (!division || d.division === division)
  && (level < 3 || d.place_kind === "district")).map((d) => [d.location_id, d])).values())
  .sort((a, b) => a.location_name.localeCompare(b.location_name));
const divisions = places(2).filter((d) => d.division !== "X-Org Units");
const districts = places(3);
// Districts lose " District"; divisions keep " Division", since Barishal, Sylhet and others name both.
const short = (name) => name.replace(/ District$/, "");
```

```js
const dayInput = Inputs.select(days, {label: "Day", format: (d) => d.label, value: days.find((d) => d.period === "20260430") ?? days.at(-1)});
const day = Generators.input(dayInput);
```

```js
const camp = (dx, id = COUNTRY_ID) => at(dx, id, CAMPAIGN.period);
const kpi = (label, v, digits = 0) => html`<div style="text-align:center;padding:22px 0 14px"><div class="d2-kpi">${v == null ? "—" : fmt(v, digits)}</div>
  <div class="muted" style="font-size:12px;margin-top:6px">${label}</div></div>`;
const prev = days[days.findIndex((d) => d.period === day.period) - 1];
// One row per place for a day: target, vaccinated and coverage as DHIS2 shows them.
const dayRow = (p, period, label) => [
  {row: short(p.location_name), col: `${label} · Target`, value: countOf(at(DX.target, p.location_id, period))},
  {row: short(p.location_name), col: `${label} · Vaccinated`, value: countOf(at(DX.vaccinated, p.location_id, period))},
  {row: short(p.location_name), col: `${label} · Coverage (%)`, value: at(DX.coverage, p.location_id, period)?.value}
];
const w = (n) => Math.max(320, (width - 24) / n - 24);
```

## Totals for the whole campaign

<div class="muted" style="margin:-8px 0 12px">${CAMPAIGN.start} to ${CAMPAIGN.end}, children 9 months to under 15 years, school and community.</div>

<div class="grid grid-cols-3" style="gap: 16px">
${item("Total Target - MR Campaign 2026", kpi("Total Target (School + Community)", countOf(camp(DX.target))))}
${item("Total Vaccinated - MR Campaign 2026", kpi("Total Vaccinated (School + Community)", countOf(camp(DX.vaccinated))))}
${item("Total Coverage - MR Campaign 2026", kpi("MR vaccination coverage (%)", camp(DX.coverage)?.value, 1))}
</div>

## Targets and vaccinated by day

<div style="margin-top: 8px">
${item("Targets, Vaccinated and Coverage of MR campaign 2026 - Bangladesh (By dates) (Line Graph)", lines(days.flatMap((d) => [
    {category: d.label, series: "Total Target (School + Community)", value: countOf(at(DX.target, COUNTRY_ID, d.period))},
    {category: d.label, series: "Total Vaccinated (School + Community)", value: countOf(at(DX.vaccinated, COUNTRY_ID, d.period))}
  ]).filter((d) => d.value != null), {width: width - 40, height: 420, format: (c) => c.slice(5)}),
  {note: "DHIS2 draws coverage on the same axis, where it shows as a flat line near zero; daily coverage is in the table below."})}
</div>

<div style="margin-top: 16px">
${item("Targets, Vaccinated and Coverage of MR campaign 2026 - Bangladesh (By dates)", html`<details><summary class="muted" style="cursor:pointer;font-size:12px;margin-bottom:8px">Show the table, one row per campaign day</summary>${pivot(days.flatMap((d) => dayRow({location_name: d.label, location_id: COUNTRY_ID}, d.period, "").map((c) => ({...c, col: c.col.replace(/^ · /, "")}))),
  {row: (d) => d.row, col: (d) => d.col, value: (d) => d.value, rowLabel: "Date", digits: 1})}</details>`)}
</div>

## Coverage by place

```js
import {coverageMap} from "./components/campaign-map.js";
const boundaries = await FileAttachment("data/boundaries.json").json();
const campaignRows = rows(await sql`SELECT * FROM campaign`);
const mapLevelInput = Inputs.radio(new Map([["District and city corporation", 2], ["Upazila", 3]]), {label: "Map by", value: 2});
const mapLevel = Generators.input(mapLevelInput);
```

```js
const campaignMapView = coverageMap(boundaries, campaignRows, {level: mapLevel, height: 520});
```


<div class="grid grid-cols-2" style="gap: 16px; margin-top: 8px">
${item(`MR campaign coverage, ${CAMPAIGN.start} to ${CAMPAIGN.end}`, html`${mapLevelInput}${campaignMapView}`,
  {note: "Vaccinated ÷ target for the whole campaign. Boundaries: the DGHS GIS dashboard, and the city corporations' ward shapefiles."})}
${item("Targets Vs. Vaccinated of MR campaign 2026 - (By Division)", columns(divisions.flatMap((p) => [
    {category: short(p.location_name), series: "Total Target (School + Community)", value: countOf(camp(DX.target, p.location_id))},
    {category: short(p.location_name), series: "Total Vaccinated (School + Community)", value: countOf(camp(DX.vaccinated, p.location_id))}
  ]), {width: w(2), height: 520}),
  {note: "DHIS2's title says 2025; its periods are the 2026 campaign days."})}
</div>

<div style="margin-top: 16px">
${item("Targets Vs. Vaccinated of MR campaign 2026 - (By District)", columns(districts.flatMap((p) => [
    {category: short(p.location_name), series: "Total Target (School + Community)", value: countOf(camp(DX.target, p.location_id))},
    {category: short(p.location_name), series: "Total Vaccinated (School + Community)", value: countOf(camp(DX.vaccinated, p.location_id))}
  ]), {width: width - 40, height: 380, rotate: -60}))}
</div>

## One campaign day

<div class="d2-filter">${dayInput}<span class="muted">The tables below follow this day; "yesterday" is the campaign day before it.</span></div>

```js
const bs = ["Barishal", "Sylhet"];
const bsPlaces = [...divisions.filter((p) => bs.includes(p.division)), ...districts.filter((p) => bs.includes(p.division))];
```

<div class="grid grid-cols-2" style="gap: 16px">
${item("Daily target Vs Vaccinated status", pivot([...places(1), ...divisions, ...districts].flatMap((p) => [
    {row: short(p.location_name), col: "Target-Community", value: countOf(at(DX.target, p.location_id, day.period))},
    {row: short(p.location_name), col: "Vaccinated-Community", value: countOf(at(DX.vaccinated, p.location_id, day.period))}
  ]), {row: (d) => d.row, col: (d) => d.col, rowLabel: `${day.label}`, digits: 0}),
  {note: "DHIS2 fixes this table on 2026-04-30; here it follows the day picked above."})}
<div style="display:flex;flex-direction:column;gap:16px">
${item("Bari_Syl_Total_Target_Vaccination_MR_Cam_26", pivot(bsPlaces.flatMap((p) => [
    ...(prev ? dayRow(p, prev.period, "Yesterday").slice(0, 2) : []), ...dayRow(p, day.period, "Today").slice(0, 2)]),
  {row: (d) => d.row, col: (d) => d.col, rowLabel: "Division · district", digits: 0}),
  {note: `Today = ${day.label}${prev ? `, yesterday = ${prev.label}` : ""}.`})}
${item("B_S_MR Campaign_Tar_Vac_Coverage_2026", prev ? pivot(bsPlaces.flatMap((p) => dayRow(p, prev.period, "Yesterday")),
  {row: (d) => d.row, col: (d) => d.col, rowLabel: "Division · district", digits: 1}) : html`<p class="muted">No campaign day before ${day.label}.</p>`)}
${item("Bari_Total_Vaccination_MR_Cam_26_Bar", prev ? columns([...divisions.filter((p) => p.division === "Barishal"), ...districts.filter((p) => p.division === "Barishal")].map((p) => (
    {category: short(p.location_name), series: "Total Vaccinated (School + Community)", value: countOf(at(DX.vaccinated, p.location_id, prev.period))})),
  {width: w(2), height: 300, horizontal: true}) : "", {note: prev ? `Yesterday = ${prev.label}.` : ""})}
</div>
</div>

<div class="muted d2-footer">
Rebuilt from the <b>MR Vaccination Campaign 2026</b> dashboard of the EPI campaign DHIS2 (epicampaign.dghs.gov.bd), from the values imported
into the Bangladesh ICR server (<code>kiln dhis2 reports</code>, now <code>fhir-pipes dhis2 reports</code>). The values are DHIS2's analytics as of its
last analytics run (15 September 2026). This site needs sign-in.
</div>
