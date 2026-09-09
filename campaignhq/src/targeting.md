---
title: Campaign targeting
sql:
  denominators: data/denominators.parquet
  admin_units: data/admin_units.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Campaign targeting

Two estimates of how many people live in each LGA — the WorldPop grid summed over the LGA boundary, and the census projection the campaigns were planned against — and where they disagree.

```js
import {campaignMap, syncMaps, DEFAULT_BASEMAP} from "./components/map.js";
import {constrain, available} from "./components/filters.js";
const BASEMAP = DEFAULT_BASEMAP;

const toRows = (table) => Array.from(table, (r) => {
  const o = typeof r.toJSON === "function" ? r.toJSON() : {...r};
  for (const k in o) if (typeof o[k] === "bigint") o[k] = Number(o[k]);
  return o;
});
const fmtInt = (n) => n == null ? "—" : Math.round(Number(n)).toLocaleString("en");
const fmtSigned = (n) => n == null ? "—" : `${n > 0 ? "+" : n < 0 ? "−" : ""}${Math.abs(Math.round(Number(n))).toLocaleString("en")}`;
const fmtPct1 = (x) => x == null ? "—" : `${x > 0 ? "+" : x < 0 ? "−" : ""}${Math.abs(x * 100).toFixed(1)}%`;
const fmtCompact = (v) => v >= 1e6 ? `${+(v / 1e6).toFixed(1)}M` : v >= 1e3 ? `${Math.round(v / 1e3)}k` : String(Math.round(v));
// Same breaks and colours as the delta map ramp.
const DELTA_COLORS = ["#2166ac", "#67a9cf", "#d1e5f0", "#f1f1f1", "#fddbc7", "#ef8a62", "#b2182b"];
```

```js
const years = toRows(await sql`SELECT DISTINCT year FROM denominators WHERE level = 'lga' ORDER BY year DESC`).map((d) => d.year);
const states = toRows(await sql`SELECT DISTINCT state FROM denominators WHERE level = 'lga' AND state IS NOT NULL AND country = 'NGA' ORDER BY state`).map((d) => d.state);
const combos = toRows(await sql`SELECT year, state, count(*) AS n, count(census) AS with_census FROM denominators WHERE level = 'lga' AND country = 'NGA' GROUP BY 1, 2`);
const yearData = years, stateData = ["All", ...states];
const stateBounds = new Map(toRows(await sql`SELECT name, xmin, ymin, xmax, ymax FROM admin_units WHERE admin_level = 1 AND country = 'NGA'`).map((d) => [d.name, [[d.xmin, d.ymin], [d.xmax, d.ymax]]]));
const statesWithCensus = new Set(combos.filter((c) => c.with_census > 0).map((c) => c.state));
```

<div class="grid grid-cols-3" style="gap: 12px; margin-bottom: 8px">
  <div>${yearInput}</div>
  <div>${stateInput}</div>
  <div>${scopeInput}</div>
</div>

```js
const yearInput = Inputs.select(yearData, {label: "Year", value: years[0], format: (d) => String(d)});
const year = Generators.input(yearInput);
const stateInput = Inputs.select(stateData, {label: "State", value: "All", format: (d) => d === "All" ? "All" : statesWithCensus.has(d) ? d : `${d} (WorldPop only)`});
const state = Generators.input(stateInput);
const scopeInput = Inputs.radio(["Compared LGAs", "All LGAs"], {label: "Show", value: "Compared LGAs"});
const scope = Generators.input(scopeInput);
```

```js
// Grey out states with no LGA rows in the chosen year.
{
  constrain(stateInput, stateData, available(combos, "state", {year}));
}
```

```js
const selWhere = [
  `year = ${Number(year)}`,
  state === "All" ? "TRUE" : `state = '${String(state).replace(/'/g, "''")}'`
].join(" AND ");
const lgaRows = toRows(await sql([`SELECT * FROM denominators WHERE level = 'lga' AND country = 'NGA' AND ${selWhere} ORDER BY state, location_name`]));
const stateRows = toRows(await sql([`SELECT * FROM denominators WHERE level = 'state' AND country = 'NGA' AND year = ${Number(year)} ORDER BY location_name`]));
const compared = lgaRows.filter((d) => d.census != null && d.worldpop != null);
const shown = scope === "All LGAs" ? lgaRows : compared;
const drilled = state !== "All";
```

```js
const kpi = {
  lgas: lgaRows.length,
  compared: compared.length,
  worldpop: compared.reduce((s, d) => s + d.worldpop, 0),
  census: compared.reduce((s, d) => s + d.census, 0),
  worldpopAll: lgaRows.reduce((s, d) => s + (d.worldpop ?? 0), 0),
  above: compared.filter((d) => d.delta_share > 0.05).length,
  below: compared.filter((d) => d.delta_share < -0.05).length
};
kpi.delta = kpi.worldpop - kpi.census;
kpi.deltaShare = kpi.census > 0 ? kpi.delta / kpi.census : null;
const shares = compared.map((d) => d.delta_share).sort((a, b) => a - b);
kpi.median = shares.length ? shares[Math.floor(shares.length / 2)] : null;
const scopeLabel = `${drilled ? `${state} State` : "Nigeria"} · ${year}`;
const red = (t) => html`<span style="color:#b91c1c">${t}</span>`;
const blue = (t) => html`<span style="color:#1d4ed8">${t}</span>`;
```

<div class="grid grid-cols-4" style="gap: 12px">
  <div class="card"><h2>WorldPop population</h2><span class="big">${fmtInt(kpi.worldpopAll)}</span><div class="muted">${fmtInt(kpi.lgas)} LGA${kpi.lgas === 1 ? "" : "s"} · ${scopeLabel}</div></div>
  <div class="card"><h2>Census projection</h2><span class="big">${kpi.compared ? fmtInt(kpi.census) : "—"}</span><div class="muted">${kpi.compared ? `${fmtInt(kpi.compared)} LGA${kpi.compared === 1 ? "" : "s"} with both estimates` : "no census projection in this selection"}</div></div>
  <div class="card"><h2>WorldPop − census</h2><span class="big">${kpi.compared ? fmtSigned(kpi.delta) : "—"}</span><div class="muted">${kpi.compared ? `${fmtPct1(kpi.deltaShare)} of the census projection, over the compared LGAs` : ""}</div></div>
  <div class="card"><h2>LGAs apart by more than 5%</h2><span class="big">${kpi.compared ? fmtInt(kpi.above + kpi.below) : "—"}</span><div class="muted">${kpi.compared ? html`${kpi.above ? red(`${fmtInt(kpi.above)} WorldPop higher`) : "none higher"} · ${kpi.below ? blue(`${fmtInt(kpi.below)} WorldPop lower`) : "none lower"} · median ${fmtPct1(kpi.median)}` : ""}</div></div>
</div>

<div class="grid grid-cols-2" style="gap: 12px; margin-top: 12px">
  <div class="card" style="padding: 0; overflow: hidden">
    <div class="map-title">WorldPop population per LGA, ${year}</div>
    ${mapPopulation}
  </div>
  <div class="card" style="padding: 0; overflow: hidden">
    <div class="map-title">WorldPop vs census projection, ${year} — % difference (grey: no census projection)</div>
    ${mapDelta}
  </div>
</div>

```js
const pmtiles = await FileAttachment("data/admin.pmtiles").arrayBuffer();
const stateLabels = toRows(await sql`SELECT id, name, lon, lat FROM admin_units WHERE admin_level = 1 AND country = 'NGA'`);
const mapPopulation = campaignMap({pmtiles, height: 440, basemap: BASEMAP, labels: stateLabels, metric: "population"});
const mapDelta = campaignMap({pmtiles, height: 440, basemap: BASEMAP, labels: stateLabels, metric: "delta"});
syncMaps(mapPopulation, mapDelta);
const DEFAULT_BOUNDS = [[2.6, 4.2], [14.7, 13.9]];
```

```js
mapPopulation.update(lgaRows);
mapDelta.update(lgaRows);
```

```js
// Zoom to the drilled state (the maps are synced, so moving one moves both).
{
  const b = drilled ? stateBounds.get(state) ?? DEFAULT_BOUNDS : DEFAULT_BOUNDS;
  if (mapPopulation.clientWidth > 0) mapPopulation.map.fitBounds(b, {padding: 20, duration: 400});
}
```

<div class="grid grid-cols-2" style="gap: 12px; margin-top: 12px">
  <div class="card">
    <h2>Difference by ${drilled ? "LGA" : "state"}, ${year}</h2>
    <div class="muted" style="margin-bottom: 6px">WorldPop minus the census projection as a share of the projection${drilled ? "" : ", summed over each state's compared LGAs. Pick a state above to see its LGAs"}.</div>
    ${deltaPlot}
  </div>
  <div class="card">
    <h2>WorldPop against the census projection, ${year}</h2>
    <div class="muted" style="margin-bottom: 6px">One dot per compared LGA; on the line the two agree. Dots above it are LGAs where WorldPop counts more people than the projection.</div>
    ${scatter}
  </div>
</div>

```js
const barRows = drilled
  ? compared.map((d) => ({unit: d.location_name, delta_share: d.delta_share, worldpop: d.worldpop, census: d.census, delta: d.delta}))
  : stateRows.filter((d) => d.census != null && d.worldpop != null).map((d) => ({unit: d.location_name, delta_share: d.delta_share, worldpop: d.worldpop, census: d.census, delta: d.delta}));
barRows.sort((a, b) => b.delta_share - a.delta_share);
const barTitle = (d) => `${d.unit}${drilled ? "" : " State"}\nWorldPop ${fmtInt(d.worldpop)} · census projection ${fmtInt(d.census)}\ndifference ${fmtSigned(d.delta)} (${fmtPct1(d.delta_share)})`;
// Room for the value labels beyond the bar ends on both sides.
const barExtent = Math.max(0.1, ...barRows.map((d) => Math.abs(d.delta_share))) * 1.35;
const deltaPlot = barRows.length === 0 ? html`<div class="muted">No LGA in this selection has both estimates.</div>` : Plot.plot({
  width: Math.max(320, width / 2 - 40),
  height: 40 + 22 * Math.max(4, barRows.length),
  marginLeft: 130, marginRight: 40,
  x: {label: "WorldPop − census, % of census", tickFormat: (d) => `${d > 0 ? "+" : ""}${Math.round(d * 100)}%`, grid: true,
      domain: [Math.min(0, -barExtent * (barRows.some((d) => d.delta_share < 0) ? 1 : 0.2)), Math.max(0, barExtent * (barRows.some((d) => d.delta_share > 0) ? 1 : 0.2))]},
  y: {label: null, domain: barRows.map((d) => d.unit)},
  color: {type: "threshold", domain: [-0.3, -0.15, -0.05, 0.05, 0.15, 0.3], range: DELTA_COLORS, legend: false},
  marks: [
    Plot.barX(barRows, {x: "delta_share", y: "unit", fill: "delta_share", tip: true, title: barTitle}),
    // dx / textAnchor are constants in Plot, so positive and negative bars get their own label mark.
    Plot.text(barRows.filter((d) => d.delta_share >= 0), {x: "delta_share", y: "unit", text: (d) => fmtPct1(d.delta_share), dx: 4, textAnchor: "start", fontSize: 11, fill: "#334155"}),
    Plot.text(barRows.filter((d) => d.delta_share < 0), {x: "delta_share", y: "unit", text: (d) => fmtPct1(d.delta_share), dx: -4, textAnchor: "end", fontSize: 11, fill: "#334155"}),
    Plot.ruleX([0])
  ]
});
```

```js
const scatter = compared.length === 0 ? html`<div class="muted">No LGA in this selection has both estimates.</div>` : Plot.plot({
  width: Math.max(320, width / 2 - 40),
  height: 40 + 22 * Math.max(4, Math.min(barRows.length, 16)),
  marginLeft: 60, marginBottom: 36,
  grid: true,
  x: {label: "census projection →", tickFormat: fmtCompact},
  y: {label: "↑ WorldPop", tickFormat: fmtCompact},
  color: {type: "threshold", domain: [-0.3, -0.15, -0.05, 0.05, 0.15, 0.3], range: DELTA_COLORS, legend: true, tickFormat: (d) => `${d > 0 ? "+" : ""}${Math.round(d * 100)}%`, label: "WorldPop − census, % of census"},
  marks: [
    Plot.link([{x1: 0, y1: 0, x2: Math.max(...compared.map((d) => Math.max(d.census, d.worldpop))), y2: Math.max(...compared.map((d) => Math.max(d.census, d.worldpop)))}],
      {x1: "x1", y1: "y1", x2: "x2", y2: "y2", stroke: "#94a3b8", strokeDasharray: "4 3"}),
    Plot.dot(compared, {x: "census", y: "worldpop", fill: "delta_share", r: 4, stroke: "#334155", strokeWidth: 0.5, tip: true,
      title: (d) => `${d.location_name} LGA, ${d.state}\nWorldPop ${fmtInt(d.worldpop)} · census projection ${fmtInt(d.census)}\ndifference ${fmtSigned(d.delta)} (${fmtPct1(d.delta_share)})`})
  ]
});
```

## By LGA

```js
// Largest disagreement first; LGAs with only one estimate sort to the bottom.
const tableRows = shown.map((d) => ({
  ...d,
  delta_text: d.delta == null ? "" : fmtSigned(d.delta),
  share_text: d.delta_share == null ? "" : fmtPct1(d.delta_share),
  flag: d.delta_share == null ? "" : Math.abs(d.delta_share) > 0.15 ? "▲▲" : Math.abs(d.delta_share) > 0.05 ? "▲" : ""
})).sort((a, b) => (b.delta_share == null ? -1 : Math.abs(b.delta_share)) - (a.delta_share == null ? -1 : Math.abs(a.delta_share)));
const search = view(Inputs.search(tableRows, {placeholder: "Search LGA, state…", columns: ["location_name", "state"]}));
```

```js
Inputs.table(search, {
  columns: ["state", "location_name", "worldpop", "census", "delta_text", "share_text", "flag"],
  header: {state: "State", location_name: "LGA", worldpop: "WorldPop", census: "Census projection", delta_text: "WorldPop − census", share_text: "% of census", flag: "Flag"},
  format: {worldpop: (d) => fmtInt(d), census: (d) => d == null ? "—" : fmtInt(d)},
  align: {worldpop: "right", census: "right", delta_text: "right", share_text: "right", flag: "center"},
  width: {state: 110, location_name: 170, worldpop: 110, census: 130, delta_text: 130, share_text: 100, flag: 50},
  rows: 25
})
```

<footer class="muted" style="margin-top: 24px; padding-top: 12px; border-top: 1px solid var(--theme-foreground-faintest); font-size: 12px; line-height: 1.6">
  <p style="margin: 0 0 8px">
    Both figures are <code>ICRTargetPopulation</code> Groups on the same Location, flattened by the
    <code>IcrTargetPopulation</code> view (<code>denominator_type = total-population</code>) and paired on
    <code>location_id</code> and <code>estimate_date</code>. <b>WorldPop</b> is the constrained 100 m grid for the year
    summed over each LGA boundary by <code>kiln population</code> (a pixel counts for the LGA its centre falls in, so
    LGAs add up exactly to their state); <b>census projection</b> is the NPC 2006 census and 2022 projection
    interpolated geometrically to the year, the figure the demo campaigns were planned against, available for the five
    demo states only. Every other state shows WorldPop alone.
  </p>
  <p style="margin: 0">
    ${fmtInt(search.length)} of ${fmtInt(shown.length)} LGA rows${drilled ? ` for ${state} State` : ""} ·
    ▲ more than 5% apart, ▲▲ more than 15%. A large gap is a targeting risk in either direction: a projection above
    WorldPop means doses and teams planned for people who may not be there; below it means an under-supplied round and
    coverage that looks better than it is.
  </p>
</footer>

<style>
.big { font-size: 28px; font-weight: 600; line-height: 1.1; }
.map-title { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); padding: 10px 14px 6px; }
.card h2 { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); margin: 0 0 4px; }
.maplibregl-popup-content { padding: 6px 9px; }
</style>
