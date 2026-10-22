---
title: ICHD targets
sql:
  targets: data/targets.parquet
  population: data/population.parquet
  registry: data/registry.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# ICHD targets, October 2026

The Ministry of Health's targets for the Integrated Child Health Days (ICHDs) round of October 2026, by district and city. In the [Integrated Campaign Registry](https://icr.healthcampaigns.org) each district has one draft campaign, and the campaign names a target for each of its six activities. The round is a plan: nothing has started.

```js
import {ACTIVITIES, ACTIVITY, toRows, fmtInt, fmtCompact} from "./components/ichd.js";
import {ugandaMap, quantileBreaks, BLUES, UGANDA_BOUNDS} from "./components/uganda-map.js";
```

```js
const rows = toRows(await sql`SELECT * FROM targets`);
const pop = new Map(toRows(await sql`SELECT * FROM population`).map((d) => [d.location_id, d]));
const regionsList = toRows(await sql`SELECT id, name, lon, lat, xmin, ymin, xmax, ymax FROM registry WHERE admin_level = 1 ORDER BY name`);
// Target per place and activity: the sum of the activity's target Groups (MR2 and catch-up have two).
const total = d3.rollup(rows, (v) => d3.sum(v, (d) => d.quantity), (d) => d.location_id, (d) => d.activity_key);
const places = new Map(rows.map((d) => [d.location_id, {id: d.location_id, name: d.location_name, level: d.admin_level, region: d.region, campaign: d.campaign_id}]));
// There are national and district campaigns only, so a region's target is the sum of its districts'.
const regionTotal = (name, key) => d3.sum([...places.values()].filter((p) => p.level === 2 && p.region === name), (p) => total.get(p.id)?.get(key) ?? 0);
const targetFor = (region, key) => region === "All" ? total.get("uga")?.get(key) ?? null : regionTotal(region, key);
// What each activity's target is made of, from the national campaign's Groups.
const parts = d3.rollup(rows.filter((d) => d.admin_level === 0), (v) => v.map((d) => d.target_name), (d) => d.activity_key);
```

<div class="grid grid-cols-2" style="gap: 12px; margin-bottom: 8px">
  <div>${activityInput}</div>
  <div>${regionInput}</div>
</div>

```js
const activityInput = Inputs.select(ACTIVITIES.map((a) => a.key), {label: "Activity", value: "uga-ichd-mr2", format: (k) => ACTIVITY.get(k).label});
const activity = Generators.input(activityInput);
const regionInput = Inputs.select(["All", ...regionsList.map((d) => d.name)], {label: "Region", value: "All"});
const region = Generators.input(regionInput);
```

```js
const A = ACTIVITY.get(activity);
const scopeId = region === "All" ? "uga" : regionsList.find((d) => d.name === region).id;
const scopeName = region === "All" ? "Uganda" : region;
const districts = [...places.values()].filter((p) => p.level === 2 && (region === "All" || p.region === region));
const districtRows = districts.map((p) => {
  const r = {location_id: p.id, district: p.name, region: p.region.replace(" Region", ""), population: pop.get(p.id)?.moh_2026 ?? null};
  for (const a of ACTIVITIES) r[a.key] = total.get(p.id)?.get(a.key) ?? null;
  return r;
});
const scopeTarget = targetFor(region, activity);
const scopePop = pop.get(scopeId);
```

<div class="grid grid-cols-4" style="gap: 12px">
  <div class="card"><h2>${A.short} target, ${scopeName}</h2><span class="big">${fmtInt(scopeTarget)}</span><div class="muted">${(parts.get(activity) ?? []).join(" + ")}</div></div>
  <div class="card"><h2>Population 2026</h2><span class="big">${fmtInt(scopePop?.moh_2026)}</span><div class="muted">Ministry of Health · WorldPop ${fmtCompact(scopePop?.worldpop_2026)}</div></div>
  <div class="card"><h2>Districts and cities</h2><span class="big">${fmtInt(districts.length)}</span><div class="muted">one draft campaign each, with a target per activity</div></div>
  <div class="card"><h2>Share of the population</h2><span class="big">${scopeTarget && scopePop?.moh_2026 ? `${(scopeTarget / scopePop.moh_2026 * 100).toFixed(scopeTarget / scopePop.moh_2026 < 0.01 ? 2 : 1)}%` : "—"}</span><div class="muted">${A.short} target ÷ population 2026</div></div>
</div>

<div class="card" style="margin-top: 12px">
  <h2>Targets by activity, ${scopeName}</h2>
  ${activityChart}
  <div class="muted" style="margin-top: 4px">Deworming and vitamin A share one target, the workbook's "Deworming+VitA" column. MR2 adds two birth cohorts (April 2025 and April 2024); catch-up adds unimmunized and under-immunized children under 1.</div>
</div>

```js
const scopeTotals = ACTIVITIES.map((a) => ({key: a.key, label: a.label, target: targetFor(region, a.key) ?? 0, selected: a.key === activity}));
const activityChart = Plot.plot({
  width,
  height: 34 + 28 * scopeTotals.length,
  marginLeft: 230, marginRight: 90,
  x: {label: null, grid: true, tickFormat: "s"},
  y: {label: null, domain: scopeTotals.map((d) => d.label), tickSize: 0},
  marks: [
    Plot.barX(scopeTotals, {x: "target", y: "label", fill: (d) => d.selected ? "#08519c" : "#9ecae1", insetTop: 5, insetBottom: 5, rx: 2,
      tip: true, title: (d) => `${d.label}\n${fmtInt(d.target)} in ${scopeName}`}),
    Plot.text(scopeTotals, {x: "target", y: "label", text: (d) => fmtInt(d.target), textAnchor: "start", dx: 6, fontSize: 11}),
    Plot.ruleX([0])
  ]
});
```

<div class="grid" style="gap: 12px; margin-top: 12px; grid-template-columns: minmax(0, 3fr) minmax(0, 2fr)">
  <div class="card" style="padding: 0; overflow: hidden">
    <div class="map-title" style="display:flex; justify-content:space-between; align-items:center; gap:8px; flex-wrap:wrap"><span>${A.short} target by district and city</span>${metricInput}</div>
    ${mapEl}
  </div>
  <div style="display:flex; flex-direction:column; gap: 12px; min-width: 0">
    <div class="card"><h2>${A.short} target by region</h2>${regionChart}</div>
    <div class="card"><h2>Largest ${A.short} targets${region === "All" ? "" : `, ${region}`}</h2>${topChart}</div>
  </div>
</div>

```js
const metricInput = Inputs.radio(["Target", "Per 1,000 people"], {value: "Target"});
const metric = Generators.input(metricInput);
```

```js
const pmtiles = await FileAttachment("data/admin.pmtiles").arrayBuffer();
const mapEl = ugandaMap({pmtiles, labels: regionsList, height: 520});
```

```js
{
  const perK = metric === "Per 1,000 people";
  const values = new Map(districtRows.map((d) => [d.location_id, d[activity] == null ? null : perK ? (d.population ? d[activity] / d.population * 1000 : null) : d[activity]]));
  const thresholds = quantileBreaks([...values.values()]);
  const fmt = perK ? (v) => v < 10 ? v.toFixed(1) : fmtInt(v) : fmtCompact;
  mapEl.setValues(values, {
    thresholds, colors: BLUES.slice(BLUES.length - thresholds.length - 1),
    label: perK ? `${A.short} target per 1,000 people` : `${A.short} target`, legendFormat: fmt,
    describe: (id) => {
      const d = districtRows.find((r) => r.location_id === id);
      if (!d) return "outside the selection";
      return `${A.short} target: ${fmtInt(d[activity])}<br>population 2026: ${fmtInt(d.population)}${d.population ? `<br>${(d[activity] / d.population * 1000).toFixed(1)} per 1,000 people` : ""}`;
    }
  });
  mapEl.setRegion(region === "All" ? null : region);
  const r = regionsList.find((d) => d.name === region);
  mapEl.fit(r ? [[r.xmin, r.ymin], [r.xmax, r.ymax]] : UGANDA_BOUNDS);
}
```

```js
const regionTotals = regionsList.map((r) => ({region: r.name.replace(" Region", ""), target: regionTotal(r.name, activity), selected: region === "All" || r.name === region}));
const regionChart = Plot.plot({
  width: Math.max(260, width * 0.38),
  height: 30 + 26 * regionTotals.length,
  marginLeft: 70, marginRight: 70,
  x: {label: null, grid: true, tickFormat: "s"},
  y: {label: null, domain: regionTotals.map((d) => d.region), tickSize: 0},
  marks: [
    Plot.barX(regionTotals, {x: "target", y: "region", fill: (d) => d.selected ? "#3182bd" : "#c6dbef", insetTop: 4, insetBottom: 4, rx: 2}),
    Plot.text(regionTotals, {x: "target", y: "region", text: (d) => fmtInt(d.target), textAnchor: "start", dx: 5, fontSize: 11}),
    Plot.ruleX([0])
  ]
});
const top = districtRows.filter((d) => d[activity] != null).sort((a, b) => b[activity] - a[activity]).slice(0, 10);
const topChart = Plot.plot({
  width: Math.max(260, width * 0.38),
  height: 30 + 22 * top.length,
  marginLeft: 110, marginRight: 70,
  x: {label: null, grid: true, tickFormat: "s"},
  y: {label: null, domain: top.map((d) => d.district), tickSize: 0},
  marks: [
    Plot.barX(top, {x: activity, y: "district", fill: "#3182bd", insetTop: 3, insetBottom: 3, rx: 2, tip: true, title: (d) => `${d.district}, ${d.region}\n${fmtInt(d[activity])}`}),
    Plot.text(top, {x: activity, y: "district", text: (d) => fmtInt(d[activity]), textAnchor: "start", dx: 5, fontSize: 11}),
    Plot.ruleX([0])
  ]
});
```

## Targets by district and city

```js
const search = view(Inputs.search(districtRows, {placeholder: "Search district or region…", columns: ["district", "region"]}));
```

```js
Inputs.table(search, {
  columns: ["district", "region", "population", ...ACTIVITIES.map((a) => a.key)],
  header: {district: "District / city", region: "Region", population: "Population 2026", ...Object.fromEntries(ACTIVITIES.map((a) => [a.key, a.short]))},
  format: {population: fmtInt, ...Object.fromEntries(ACTIVITIES.map((a) => [a.key, fmtInt]))},
  sort: activity, reverse: true,
  rows: 20
})
```

<div class="muted" style="margin-top: 16px; font-size: 13px; line-height: 1.6; max-width: 900px">
Source: the Ministry of Health's targets workbook for the October 2026 ICHDs (sheet Target_refined), loaded as ICRTargetPopulation Groups, one per target column and place; region and country figures are the sums of their districts. Counts are rounded to whole people. Still to confirm with the Ministry: the ages for deworming, vitamin A, HPV and Td2+; whether the April 2025 column is an MR2 target (the workbook also counts it in the under-1 total); and what "Catch Population" is. See the <a href="./plan">campaign plan</a> for the campaigns and tasks.
</div>

<style>
.big { font-size: 28px; font-weight: 600; line-height: 1.1; font-variant-numeric: tabular-nums; }
.map-title { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); padding: 10px 14px 6px; }
.card h2 { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); margin: 0 0 4px; }
.maplibregl-popup-content { padding: 6px 9px; }
</style>
