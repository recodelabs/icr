---
title: Georegistry
sql:
  boundaries: data/boundaries.parquet
  points: data/points.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Georegistry

The places on the DIGIT server, each a FHIR Location. DIGIT's boundaries come in several hierarchies, one per demo country or set-up, and each boundary points at its parent with `partOf`. DIGIT holds names and codes for its boundaries but no geometry.

The map below shows all of Nigeria's states and LGAs from GRID3, as the ICR's location registry holds them. The ones highlighted are the units in DIGIT's hierarchies: 168 DIGIT units in the ADMIN hierarchy (states and LGAs) and the NIGERIA hierarchy (provinces and districts, which are Nigeria's states and LGAs) were matched to GRID3. Each of them carries the GRID3 boundary, its P-code and the id of the matching ICR Location; where GRID3 spells the name differently, GRID3's spelling is kept as an alias. Both hierarchies can match the same GRID3 unit. DIGIT's other boundaries have no geometry. Health facilities and household dwellings have coordinates.

```js
import {toRows, fmtInt} from "./components/digit.js";
import {pointsMap, KINDS, BOUNDARY_LAYERS} from "./components/points-map.js";
```

```js
const units = toRows(await sql`SELECT * FROM boundaries`);
const byId = new Map(units.map((d) => [d.location_id, d]));
const pointRows = toRows(await sql`SELECT * FROM points`);
const admin = await FileAttachment("data/admin.geojson").json();
const hierarchies = d3.rollups(units, (v) => v.length, (d) => d.hierarchy ?? "unknown").sort((a, b) => b[1] - a[1]);
```

<div class="grid" style="gap: 12px; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr))">
  <div class="card"><h2>Boundary hierarchies</h2><span class="big">${hierarchies.length}</span><div class="muted">${hierarchies.map(([h]) => h).join(", ")}</div></div>
  <div class="card"><h2>Boundaries</h2><span class="big">${fmtInt(units.length)}</span><div class="muted">admin units</div></div>
  <div class="card"><h2>With a GRID3 boundary</h2><span class="big">${fmtInt(units.filter((d) => d.has_boundary).length)}</span><div class="muted">Nigerian states and LGAs</div></div>
  <div class="card"><h2>Health facilities</h2><span class="big">${fmtInt(d3.sum(units, (d) => d.facilities))}</span><div class="muted">under a boundary; ${fmtInt(pointRows.filter((d) => d.kind === "facility").length)} with coordinates</div></div>
  <div class="card"><h2>Household dwellings</h2><span class="big">${fmtInt(pointRows.filter((d) => d.kind === "dwelling").length)}</span><div class="muted">with coordinates</div></div>
</div>

## Boundaries by hierarchy and level

```js
const levels = d3.rollups(units, (v) => ({hierarchy: v[0].hierarchy ?? "unknown", level: v[0].level, level_name: v[0].level_name, boundaries: v.length,
  facilities: d3.sum(v, (d) => d.facilities), with_boundary: v.filter((d) => d.has_boundary).length}), (d) => d.hierarchy, (d) => d.level)
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
  columns: ["hierarchy", "level", "level_name", "boundaries", "with_boundary", "facilities"],
  header: {hierarchy: "Hierarchy", level: "Level", level_name: "Level name", boundaries: "Boundaries", with_boundary: "With a GRID3 boundary", facilities: "Facilities directly under them"},
  format: {boundaries: fmtInt, with_boundary: (v) => v ? fmtInt(v) : "", facilities: fmtInt},
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
const onlyMatched = view(Inputs.toggle({label: "Only units with a GRID3 boundary", value: false}));
```

```js
const inHierarchy = units.filter((d) => (d.hierarchy ?? "unknown") === hierarchy && (!onlyMatched || d.has_boundary));
const search = view(Inputs.search(inHierarchy, {placeholder: "Search name, code or P-code…", columns: ["name", "code", "pcode", "alias", "level_name", "parent_name"]}));
```

```js
const picked = view(Inputs.table(search, {
  columns: ["name", "level", "level_name", "parent_name", "code", "has_boundary", "pcode", "child_boundaries", "facilities"],
  header: {name: "Boundary", level: "Level", level_name: "Level name", parent_name: "Parent", code: "Code", has_boundary: "GRID3 boundary", pcode: "P-code", child_boundaries: "Boundaries under it", facilities: "Facilities"},
  format: {child_boundaries: fmtInt, facilities: fmtInt, has_boundary: (v) => v ? "yes" : ""},
  width: {name: 200, level: 50, parent_name: 160, code: 240, has_boundary: 70, pcode: 70},
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
  ${picked.has_boundary ? html`<div style="margin-bottom: 8px">GRID3 boundary · P-code ${picked.pcode} · ICR Location <code>${picked.icr_location_id}</code>${picked.alias ? ` · GRID3 spelling: ${picked.alias}` : ""}</div>` : ""}
  <div style="margin-bottom: 8px">${ancestors(picked).map((a) => html`<span>${a.name} <span class="muted">(${a.level_name})</span> › </span>`)}<b>${picked.name}</b></div>
  <div>${children.length ? `${fmtInt(children.length)} boundaries directly under it: ${children.slice(0, 40).map((c) => c.name).join(", ")}${children.length > 40 ? ", …" : ""}.` : "No boundaries under it."}
  ${picked.facilities ? `${fmtInt(picked.facilities)} facilities.` : ""} ${picked.other_places ? `${fmtInt(picked.other_places)} other places (dwellings).` : ""}</div>`
  : html`<span class="muted">No boundary selected.</span>`}</div>`);
```

## Map of the boundaries, facilities and dwellings

All 37 states and 774 LGAs of Nigeria from GRID3, with the facilities and dwellings on top. The units DIGIT has, in either hierarchy, have a grey fill and a darker border. Those LGAs can be shaded by a count over all campaigns: household dwellings, households registered or visits; the others stay unshaded. A place counts towards an LGA when it sits under the LGA's DIGIT unit in DIGIT's hierarchy (`partOf`); its coordinates are not used for this.

```js
const inDigit = admin.features.filter((f) => f.properties.in_digit);
const SHADE_BY = [[null, "No shading"], ["dwellings", "Household dwellings"], ["households", "Households registered"], ["visits", "Visits"]];
const LAYER_OPTIONS = [...KINDS, ...BOUNDARY_LAYERS];
```

<div style="display: flex; flex-wrap: wrap; gap: 4px 24px">
  <div>${shadeInput}</div>
</div>
<div>${layerInput}</div>

```js
const shadeInput = Inputs.select(SHADE_BY, {label: "Shade LGAs by", format: ([, l]) => l});
const shadeBy = Generators.input(shadeInput);
const layerInput = Inputs.checkbox(LAYER_OPTIONS.map(([k]) => k), {label: "Show", value: LAYER_OPTIONS.map(([k]) => k), format: (k) => LAYER_OPTIONS.find((x) => x[0] === k)[1]});
const layers = Generators.input(layerInput);
```

<div class="grid" style="gap: 12px; grid-template-columns: minmax(0, 3fr) minmax(0, 1fr)">
  <div class="card" style="padding: 0; overflow: hidden">${mapEl}</div>
  <div class="card"><h2>Selected place</h2>${inspector}</div>
</div>

```js
const mapEl = pointsMap(pointRows, {height: 600, admin});
const clicked = Generators.input(mapEl);
```

```js
mapEl.setKinds(layers);
mapEl.setShade(shadeBy[0] ? {property: shadeBy[0], label: shadeBy[1].toLowerCase()} : null);
```

```js
const row = (label, value) => html`<tr><td class="muted" style="padding-right: 8px; vertical-align: top">${label}</td><td style="word-break: break-word">${value ?? "—"}</td></tr>`;
const inspector = !clicked
  ? html`<div class="muted">Click a boundary or a point on the map.</div>`
  : clicked.layer === "boundary"
  ? html`<div>
      <div style="font-weight: 600">${clicked.name ?? "—"}</div>
      <div class="muted">${clicked.kind === "state" ? "State" : `LGA, ${clicked.state ?? ""}`} · ${clicked.in_digit ? `in DIGIT (${clicked.digit_hierarchies})` : "not in DIGIT"}</div>
      <table style="font-size: 12px; margin-top: 6px">
        ${row("ICR Location", clicked.id)}${row("P-code", clicked.pcode)}
        ${clicked.in_digit ? html`${row("DIGIT name", clicked.digit_names)}${row("DIGIT Location", clicked.digit_ids)}
        ${row("Dwellings", fmtInt(clicked.dwellings))}${row("Households registered", fmtInt(clicked.households))}${row("Visits", fmtInt(clicked.visits))}` : ""}
      </table>
    </div>`
  : html`<div>
      <div style="font-weight: 600">${clicked.name ?? "—"}</div>
      <div class="muted">${KINDS.find(([k]) => k === clicked.kind)?.[1]}</div>
      <table style="font-size: 12px; margin-top: 6px">
        ${row("Location id", clicked.id)}${row("In", clicked.boundary)}${row("Hierarchy", clicked.hierarchy)}
        ${row("Position", clicked.lngLat.map((x) => x.toFixed(5)).reverse().join(", "))}
      </table>
    </div>`;
```

<div class="muted" style="font-size: 12px">${fmtInt(admin.features.length)} boundaries from GRID3 Nigeria, through the ICR's location registry; ${fmtInt(inDigit.filter((f) => f.properties.kind === "state").length)} states and ${fmtInt(inDigit.filter((f) => f.properties.kind === "lga").length)} LGAs are in DIGIT. Geometry simplified to about 300 m.</div>

<style>
.big { font-size: 28px; font-weight: 600; line-height: 1.1; font-variant-numeric: tabular-nums; }
.card h2 { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); margin: 0 0 4px; }
.maplibregl-popup-content { padding: 6px 9px; }
</style>
