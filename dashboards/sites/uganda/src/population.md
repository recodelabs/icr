---
title: Population estimates
sql:
  population: data/population.parquet
  registry: data/registry.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Population estimates, 2026

The ICHD targets are calculated from the Ministry of Health's population figures. The ICR keeps a second, independent estimate beside them for every place: WorldPop's 2026 total population, summed over each district's boundary. Where the two disagree, the targets may need a second look.

```js
import {toRows, fmtInt, fmtPct, fmtCompact} from "./components/ichd.js";
import {ugandaMap, DIVERGING, UGANDA_BOUNDS} from "./components/uganda-map.js";
```

```js
const all = toRows(await sql`SELECT * FROM population`);
for (const d of all) {
  d.ratio = d.moh_2026 && d.worldpop_2026 ? d.worldpop_2026 / d.moh_2026 : null;
  d.difference = d.moh_2026 != null && d.worldpop_2026 != null ? d.worldpop_2026 - d.moh_2026 : null;
  d.region_short = (d.region ?? "").replace(" Region", "");
}
const regionsList = toRows(await sql`SELECT id, name, lon, lat, xmin, ymin, xmax, ymax FROM registry WHERE admin_level = 1 ORDER BY name`);
```

<div style="max-width: 320px; margin-bottom: 8px">${regionInput}</div>

```js
const regionInput = Inputs.select(["All", ...regionsList.map((d) => d.name)], {label: "Region", value: "All"});
const region = Generators.input(regionInput);
```

```js
const scope = all.find((d) => region === "All" ? d.admin_level === 0 : d.admin_level === 1 && d.location_name === region);
const districts = all.filter((d) => d.admin_level === 2 && (region === "All" || d.region === region));
const within = districts.filter((d) => d.ratio != null && Math.abs(d.ratio - 1) <= 0.2).length;
const scopeName = region === "All" ? "Uganda" : region;
```

<div class="grid grid-cols-4" style="gap: 12px">
  <div class="card"><h2>Ministry of Health, 2026</h2><span class="big">${fmtInt(scope?.moh_2026)}</span><div class="muted">${scopeName} · targets workbook</div></div>
  <div class="card"><h2>WorldPop, 2026</h2><span class="big">${fmtInt(scope?.worldpop_2026)}</span><div class="muted">R2025A, summed over the boundaries</div></div>
  <div class="card"><h2>Difference</h2><span class="big">${scope?.ratio != null ? `${scope.ratio >= 1 ? "+" : ""}${((scope.ratio - 1) * 100).toFixed(1)}%` : "—"}</span><div class="muted">WorldPop against the Ministry, ${fmtCompact(Math.abs(scope?.difference ?? 0))} people ${scope?.difference >= 0 ? "more" : "fewer"}</div></div>
  <div class="card"><h2>Districts within ±20%</h2><span class="big">${fmtInt(within)}<span class="muted" style="font-size: 16px"> of ${fmtInt(districts.length)}</span></span><div class="muted">${fmtInt(districts.length - within)} differ by more than a fifth</div></div>
</div>

<div class="grid" style="gap: 12px; margin-top: 12px; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr)">
  <div class="card" style="padding: 0; overflow: hidden">
    <div class="map-title">WorldPop ÷ Ministry of Health, by district and city</div>
    ${mapEl}
  </div>
  <div class="card">
    <h2>Each district: Ministry of Health (across) against WorldPop (up)</h2>
    ${scatter}
    <div class="muted">Both axes logarithmic. On the grey line the two agree; the dashed lines are ±20%.</div>
  </div>
</div>

```js
const pmtiles = await FileAttachment("data/admin.pmtiles").arrayBuffer();
const mapEl = ugandaMap({pmtiles, labels: regionsList, height: 500});
```

```js
{
  const thresholds = [0.5, 0.8, 0.95, 1.05, 1.25, 2];
  mapEl.setValues(new Map(districts.map((d) => [d.location_id, d.ratio])), {
    thresholds, colors: DIVERGING, label: "WorldPop ÷ Ministry", legendFormat: (v) => `×${v}`,
    describe: (id) => {
      const d = districts.find((r) => r.location_id === id);
      if (!d) return "outside the selection";
      return `Ministry of Health: ${fmtInt(d.moh_2026)}<br>WorldPop: ${fmtInt(d.worldpop_2026)}<br>${d.ratio != null ? `WorldPop is ×${d.ratio.toFixed(2)}` : "no comparison"}`;
    }
  });
  mapEl.setRegion(region === "All" ? null : region);
  const r = regionsList.find((d) => d.name === region);
  mapEl.fit(r ? [[r.xmin, r.ymin], [r.xmax, r.ymax]] : UGANDA_BOUNDS);
}
```

```js
const pts = districts.filter((d) => d.moh_2026 > 0 && d.worldpop_2026 > 0);
const lo = d3.min(pts, (d) => Math.min(d.moh_2026, d.worldpop_2026)) * 0.8, hi = d3.max(pts, (d) => Math.max(d.moh_2026, d.worldpop_2026)) * 1.25;
const line = (k) => [{x: lo, y: lo * k}, {x: hi, y: hi * k}];
const scatter = Plot.plot({
  width: Math.max(300, width / 2 - 40),
  height: 440,
  marginLeft: 50,
  x: {type: "log", domain: [lo, hi], label: "Ministry of Health, 2026", tickFormat: "~s", grid: true},
  y: {type: "log", domain: [lo, hi], label: "WorldPop, 2026", tickFormat: "~s", grid: true},
  marks: [
    Plot.line(line(1), {x: "x", y: "y", stroke: "#94a3b8"}),
    Plot.line(line(1.2), {x: "x", y: "y", stroke: "#94a3b8", strokeDasharray: "3,3"}),
    Plot.line(line(0.8), {x: "x", y: "y", stroke: "#94a3b8", strokeDasharray: "3,3"}),
    Plot.dot(pts, {x: "moh_2026", y: "worldpop_2026", r: 4, fill: (d) => Math.abs(d.ratio - 1) > 0.2 ? "#8c510a" : "#3182bd", fillOpacity: 0.8, stroke: "white", strokeWidth: 0.6,
      tip: true, title: (d) => `${d.location_name}, ${d.region_short}\nMinistry: ${fmtInt(d.moh_2026)}\nWorldPop: ${fmtInt(d.worldpop_2026)}\n×${d.ratio.toFixed(2)}`}),
    Plot.text(pts.filter((d) => Math.abs(Math.log(d.ratio)) > Math.log(1.6)), {x: "moh_2026", y: "worldpop_2026", text: "location_name", dy: -9, fontSize: 10, fill: "currentColor"})
  ]
});
```

## Districts and cities

```js
const search = view(Inputs.search(districts, {placeholder: "Search district or region…", columns: ["location_name", "region_short"]}));
```

```js
Inputs.table(search, {
  columns: ["location_name", "region_short", "moh_2026", "catch_2025", "worldpop_2026", "difference", "ratio"],
  header: {location_name: "District / city", region_short: "Region", moh_2026: "Ministry 2026", catch_2025: "Catch population 2025", worldpop_2026: "WorldPop 2026", difference: "Difference", ratio: "WorldPop ÷ Ministry"},
  format: {moh_2026: fmtInt, catch_2025: fmtInt, worldpop_2026: fmtInt, difference: (d) => d == null ? "—" : `${d > 0 ? "+" : ""}${fmtInt(d)}`, ratio: (d) => d == null ? "—" : `×${d.toFixed(2)}`},
  sort: "ratio", reverse: true,
  rows: 20
})
```

<div class="muted" style="margin-top: 16px; font-size: 13px; line-height: 1.6; max-width: 900px">
The Ministry's figures are the targets workbook's "Population_2026" and "Catch Population_2025" columns; WorldPop's are the R2025A 2026 constrained estimates summed under each boundary. Lira City's outline is the 2020 Lira Municipality, smaller than the city today, so WorldPop finds far fewer people there and far more in Lira District. The ICR keeps both estimates, each with its source and date, and marks which one a campaign plans against.
</div>

<style>
.big { font-size: 28px; font-weight: 600; line-height: 1.1; font-variant-numeric: tabular-nums; }
.map-title { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); padding: 10px 14px 6px; }
.card h2 { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); margin: 0 0 4px; }
.maplibregl-popup-content { padding: 6px 9px; }
</style>
