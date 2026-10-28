---
title: Georegistry
sql:
  boundaries: data/boundaries.parquet
  points: data/points.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Georegistry

The places on the DIGIT server, each a FHIR Location. DIGIT's boundaries come in several hierarchies, one per demo country or set-up, and each boundary points at its parent with `partOf`. The boundaries have names and codes but no geometry, so they cannot be drawn on a map. Health facilities and household dwellings have coordinates and are shown below.

```js
import {toRows, fmtInt} from "./components/digit.js";
import {pointsMap, KINDS} from "./components/points-map.js";
```

```js
const units = toRows(await sql`SELECT * FROM boundaries`);
const byId = new Map(units.map((d) => [d.location_id, d]));
const pointRows = toRows(await sql`SELECT * FROM points`);
const hierarchies = d3.rollups(units, (v) => v.length, (d) => d.hierarchy ?? "unknown").sort((a, b) => b[1] - a[1]);
```

<div class="grid" style="gap: 12px; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr))">
  <div class="card"><h2>Boundary hierarchies</h2><span class="big">${hierarchies.length}</span><div class="muted">${hierarchies.map(([h]) => h).join(", ")}</div></div>
  <div class="card"><h2>Boundaries</h2><span class="big">${fmtInt(units.length)}</span><div class="muted">admin units, no geometry</div></div>
  <div class="card"><h2>Health facilities</h2><span class="big">${fmtInt(d3.sum(units, (d) => d.facilities))}</span><div class="muted">under a boundary; ${fmtInt(pointRows.filter((d) => d.kind === "facility").length)} with coordinates</div></div>
  <div class="card"><h2>Household dwellings</h2><span class="big">${fmtInt(pointRows.filter((d) => d.kind === "dwelling").length)}</span><div class="muted">with coordinates</div></div>
</div>

## Boundaries by hierarchy and level

```js
const levels = d3.rollups(units, (v) => ({hierarchy: v[0].hierarchy ?? "unknown", level: v[0].level, level_name: v[0].level_name, boundaries: v.length,
  facilities: d3.sum(v, (d) => d.facilities)}), (d) => d.hierarchy, (d) => d.level)
  .flatMap(([, ls]) => ls.map(([, v]) => v))
  .sort((a, b) => d3.ascending(a.hierarchy, b.hierarchy) || d3.ascending(a.level, b.level));
```

```js
Plot.plot({
  width,
  height: 40 + 26 * new Set(levels.map((d) => d.hierarchy)).size * 1.4,
  marginLeft: 120,
  x: {label: "Level", tickFormat: (d) => `${d}`},
  y: {label: null},
  color: {type: "log", scheme: "blues", legend: true, label: "Boundaries"},
  marks: [
    Plot.cell(levels, {x: "level", y: "hierarchy", fill: "boundaries", inset: 1.5, rx: 3, tip: true,
      title: (d) => `${d.hierarchy}, level ${d.level} (${d.level_name})\n${d.boundaries.toLocaleString("en")} boundaries`}),
    Plot.text(levels, {x: "level", y: "hierarchy", text: (d) => d.boundaries >= 1000 ? `${Math.round(d.boundaries / 1000)}k` : `${d.boundaries}`,
      fill: (d) => d.boundaries > 300 ? "white" : "black", fontSize: 10})
  ]
})
```

```js
Inputs.table(levels, {
  columns: ["hierarchy", "level", "level_name", "boundaries", "facilities"],
  header: {hierarchy: "Hierarchy", level: "Level", level_name: "Level name", boundaries: "Boundaries", facilities: "Facilities directly under them"},
  format: {boundaries: fmtInt, facilities: fmtInt},
  select: false, rows: 12
})
```

## Find a boundary

Choose a hierarchy, search, and click a row to see where the boundary sits and what is under it.

```js
const hierarchyInput = Inputs.select(hierarchies.map(([h]) => h), {label: "Hierarchy", format: (h) => `${h} (${fmtInt(hierarchies.find((x) => x[0] === h)[1])})`});
const hierarchy = view(hierarchyInput);
```

```js
const inHierarchy = units.filter((d) => (d.hierarchy ?? "unknown") === hierarchy);
const search = view(Inputs.search(inHierarchy, {placeholder: "Search name or code…", columns: ["name", "code", "level_name", "parent_name"]}));
```

```js
const picked = view(Inputs.table(search, {
  columns: ["name", "level", "level_name", "parent_name", "code", "child_boundaries", "facilities"],
  header: {name: "Boundary", level: "Level", level_name: "Level name", parent_name: "Parent", code: "Code", child_boundaries: "Boundaries under it", facilities: "Facilities"},
  format: {child_boundaries: fmtInt, facilities: fmtInt},
  width: {name: 220, level: 50, parent_name: 200, code: 260},
  multiple: false, required: false, rows: 15
}));
```

```js
const ancestors = (d) => { const out = []; let p = d && byId.get(d.part_of_id); while (p && out.length < 20) { out.unshift(p); p = byId.get(p.part_of_id); } return out; };
const children = picked ? units.filter((d) => d.part_of_id === picked.location_id) : [];
```

```js
display(html`<div class="card">${picked ? html`<div style="font-weight: 600; font-size: 15px">${picked.name}</div>
  <div class="muted" style="margin-bottom: 8px">${picked.level_name}, level ${picked.level} of the ${picked.hierarchy} hierarchy · <code>${picked.location_id}</code></div>
  <div style="margin-bottom: 8px">${ancestors(picked).map((a) => html`<span>${a.name} <span class="muted">(${a.level_name})</span> › </span>`)}<b>${picked.name}</b></div>
  <div>${children.length ? `${fmtInt(children.length)} boundaries directly under it: ${children.slice(0, 40).map((c) => c.name).join(", ")}${children.length > 40 ? ", …" : ""}.` : "No boundaries under it."}
  ${picked.facilities ? `${fmtInt(picked.facilities)} facilities.` : ""} ${picked.other_places ? `${fmtInt(picked.other_places)} other places (dwellings).` : ""}</div>`
  : html`<span class="muted">No boundary selected.</span>`}</div>`);
```

## Facilities and dwellings

```js
const kindInput = Inputs.checkbox(KINDS.map(([k]) => k), {label: "Show", value: KINDS.map(([k]) => k), format: (k) => KINDS.find((x) => x[0] === k)[1]});
const kinds = view(kindInput);
```

<div class="grid" style="gap: 12px; grid-template-columns: minmax(0, 3fr) minmax(0, 1fr)">
  <div class="card" style="padding: 0; overflow: hidden">${mapEl}</div>
  <div class="card"><h2>Selected place</h2>${inspector}</div>
</div>

```js
const mapEl = pointsMap(pointRows, {height: 580});
const clicked = Generators.input(mapEl);
```

```js
mapEl.setKinds(kinds);
```

```js
const inspector = !clicked
  ? html`<div class="muted">Click a point on the map.</div>`
  : html`<div>
      <div style="font-weight: 600">${clicked.name ?? "—"}</div>
      <div class="muted">${KINDS.find(([k]) => k === clicked.kind)?.[1]}</div>
      <table style="font-size: 12px; margin-top: 6px">
        <tr><td class="muted" style="padding-right: 8px">Location id</td><td style="word-break: break-all">${clicked.id}</td></tr>
        <tr><td class="muted" style="padding-right: 8px">In</td><td>${clicked.boundary ?? "—"}</td></tr>
        <tr><td class="muted" style="padding-right: 8px">Hierarchy</td><td>${clicked.hierarchy ?? "—"}</td></tr>
        <tr><td class="muted" style="padding-right: 8px">Position</td><td>${clicked.lngLat.map((x) => x.toFixed(5)).reverse().join(", ")}</td></tr>
      </table>
    </div>`;
```

<style>
.big { font-size: 28px; font-weight: 600; line-height: 1.1; font-variant-numeric: tabular-nums; }
.card h2 { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); margin: 0 0 4px; }
.maplibregl-popup-content { padding: 6px 9px; }
</style>
