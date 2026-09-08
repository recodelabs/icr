---
title: ODK Locations
sql:
  locations: data/locations.parquet
---

# ODK Locations

Filter the ICR location registry — health facilities, settlements, LGA and
state boundaries — and export an ODK entity CSV, ready for ODK Central's or
Ona Data's bulk entity upload. Filtering runs in DuckDB (WebAssembly) against
the registry parquet; the conversion (`odk-locations`, compiled to
WebAssembly) runs in the same tab. Nothing is uploaded anywhere.

```js
import init, {convert_to_entities} from "./components/odk-locations/odk_locations.js";
await init({module_or_path: FileAttachment("components/odk-locations/odk_locations_bg.wasm").href});

const toRows = (table) => Array.from(table, (r) => {
  const o = typeof r.toJSON === "function" ? r.toJSON() : {...r};
  for (const k in o) if (typeof o[k] === "bigint") o[k] = Number(o[k]);
  return o;
});
const fmtInt = (n) => n == null ? "—" : Math.round(Number(n)).toLocaleString("en");
```

```js
// One row per layer: how it maps to the `type`/`admin_level` columns, and
// which property columns are worth exporting (state/lga/ward for point
// layers only make sense once the boundary itself isn't the export).
const LAYERS = {
  facility: {label: "Health facilities", where: "type = 'facility'", props: ["state", "lga", "ward", "facility_level", "ownership", "pcode", "nhfr_code", "status"]},
  settlement: {label: "Settlements", where: "type = 'settlement'", props: ["state", "lga", "ward", "settlement_type", "pcode", "status"]},
  lga: {label: "LGA boundaries", where: "type = 'admin-unit' AND admin_level = 2", props: ["state", "pcode", "status"]},
  state: {label: "State boundaries", where: "type = 'admin-unit' AND admin_level = 1", props: ["pcode", "status"]}
};
const states = toRows(await sql`SELECT DISTINCT state FROM locations WHERE state IS NOT NULL ORDER BY state`).map((d) => d.state);
const facilityLevels = toRows(await sql`SELECT DISTINCT facility_level FROM locations WHERE type = 'facility' AND facility_level IS NOT NULL ORDER BY facility_level`).map((d) => d.facility_level);
```

<div class="grid grid-cols-4" style="gap: 12px; margin-bottom: 8px">
  <div>${layerInput}</div>
  <div>${stateInput}</div>
  <div id="lga-slot"></div>
  <div>${levelInput}</div>
</div>

```js
const layerInput = Inputs.radio(Object.keys(LAYERS), {label: "Export", value: "facility", format: (k) => LAYERS[k].label});
const layer = Generators.input(layerInput);
const stateInput = Inputs.select(["All", ...states], {label: "State", value: "All"});
const state = Generators.input(stateInput);
```

```js
// LGA follows State — same cascading pattern as the campaign dashboards.
const lgaOptions = state === "All" ? ["All"] : ["All", ...toRows(await sql([`SELECT DISTINCT lga FROM locations WHERE state = '${state.replace(/'/g, "''")}' AND lga IS NOT NULL ORDER BY lga`])).map((d) => d.lga)];
const lgaInput = Inputs.select(lgaOptions, {label: "LGA", value: "All", disabled: state === "All"});
document.getElementById("lga-slot").replaceChildren(lgaInput);
const lga = Generators.input(lgaInput);
```

```js
import {checkboxSelect} from "./components/filters.js";
const levelInput = layer === "facility"
  ? checkboxSelect(facilityLevels, {label: "Facility level", emptyLabel: "All levels"})
  : html`<div></div>`;
const levelsPicked = layer === "facility" ? Generators.input(levelInput) : [];
```

```js
// Which columns become properties in the export, on top of the two that are
// always there: location_id (the only stable, unique key — not offered as a
// choice here, it's never optional) and label (picked separately below; it's
// ODK's display name for the entity, not a stand-in for the data).
const availableFields = ["name", ...LAYERS[layer].props];
const fieldsInput = checkboxSelect(availableFields, {value: availableFields, emptyLabel: "None (location_id + label only)", fullLabel: "All fields"});
const fieldsPicked = Generators.input(fieldsInput);
```

```js
const where = [
  LAYERS[layer].where,
  state === "All" ? "TRUE" : `state = '${state.replace(/'/g, "''")}'`,
  lga === "All" ? "TRUE" : `lga = '${lga.replace(/'/g, "''")}'`,
  levelsPicked.length === 0 ? "TRUE" : `facility_level IN (${levelsPicked.map((l) => `'${l.replace(/'/g, "''")}'`).join(", ")})`
].join(" AND ");
const cols = ["id", "name", "geometry_geojson", ...LAYERS[layer].props];
const previewRows = toRows(await sql([`SELECT ${cols.join(", ")} FROM locations WHERE ${where} LIMIT 200`]));
const countRow = toRows(await sql([`SELECT count(*) AS n FROM locations WHERE ${where}`]))[0];
const matched = countRow?.n ?? 0;
```

```js
const isPolygonLayer = layer === "lga" || layer === "state";
const labelInput = Inputs.select(["name", "pcode", "nhfr_code"].filter((c) => cols.includes(c) || c === "name"), {value: "name"});
const labelColumn = Generators.input(labelInput);
// Facility/settlement rows are already points — geoshape vs. centroid only means
// anything for the LGA/state boundary layers, so point layers default to (and
// stay pinned at) Centroid rather than showing a Boundary choice that's a no-op.
const geomInput = Inputs.radio(new Map([["Boundary (geoshape)", "boundary"], ["Centroid (geopoint)", "centroid"]]), {value: isPolygonLayer ? "boundary" : "centroid", disabled: !isPolygonLayer});
const geomMode = Generators.input(geomInput);
const maxVerticesInput = Inputs.range([50, 2000], {value: 500, step: 50, label: "Max vertices"});
const maxVertices = Generators.input(maxVerticesInput);
```

<div class="grid grid-cols-4" style="gap: 12px">
  <div class="card"><h2>Matching ${LAYERS[layer].label.toLowerCase()}</h2><span class="big">${fmtInt(matched)}</span><div class="muted">${state === "All" ? "Nigeria" : lga === "All" ? `${state} State` : `${lga} LGA, ${state}`}</div></div>
  <div class="card"><h2>Label column</h2>${labelInput}</div>
  <div class="card"><h2>Geometry</h2>${geomInput}${isPolygonLayer && geomMode === "boundary" ? maxVerticesInput : ""}</div>
  <div class="card"><h2>Fields to export</h2>${fieldsInput}</div>
</div>

<div class="card" style="margin-top: 12px">
  <div style="display:flex; justify-content:space-between; align-items:center; gap:12px; flex-wrap:wrap">
    <div>
      <h2>Preview</h2>
      <div class="muted">First 200 of ${fmtInt(matched)} matching rows. The export button converts and downloads all of them.</div>
    </div>
    <button id="export-btn" style="font:inherit; padding:8px 16px; border-radius:6px; border:solid 1px var(--theme-foreground-focus,#2563eb); background:var(--theme-foreground-focus,#2563eb); color:#fff; cursor:pointer">Export ODK entities CSV</button>
  </div>
  <div id="export-status" class="muted" style="margin-top: 6px"></div>
  ${previewTable}
</div>

```js
const previewTable = Inputs.table(previewRows.map((d) => ({...d, geometry: JSON.parse(d.geometry_geojson).type})), {
  columns: ["name", "id", ...fieldsPicked.filter((f) => f !== "name"), "geometry"],
  header: {name: "Name", id: "Location id", geometry: "Geometry"},
  width: {id: 220},
  rows: 12
});
```

```js
// The export button runs the full (unlimited) filtered query, converts it
// via the wasm module, and triggers a download — all in this tab.
{
  const btn = document.getElementById("export-btn");
  const status = document.getElementById("export-status");
  btn.onclick = async () => {
    btn.disabled = true;
    status.textContent = `fetching ${fmtInt(matched)} rows…`;
    try {
      const allCols = ["id", "name", labelColumn, "geometry_geojson", ...LAYERS[layer].props];
      const all = toRows(await sql([`SELECT ${[...new Set(allCols)].join(", ")} FROM locations WHERE ${where}`]));
      const rows = all.map((d) => ({
        label: d[labelColumn] ?? null,
        geometry: d.geometry_geojson ? JSON.parse(d.geometry_geojson) : null,
        // location_id is always included, whatever's checked above — it's the only stable,
        // unique key back to the FHIR store. Everything else is exactly what was picked in
        // "Fields to export". ("name" collides with ODK's own reserved attribute of that
        // name, so the converter renames it to "name_" when it's included.)
        properties: {location_id: d.id, ...Object.fromEntries(fieldsPicked.map((c) => [c, d[c] ?? null]))}
      }));
      const options = {geometry: geomMode, max_vertices: maxVertices ?? 500};
      status.textContent = "converting…";
      const result = JSON.parse(convert_to_entities(JSON.stringify(rows), JSON.stringify(options)));
      const blob = new Blob([result.csv], {type: "text/csv"});
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      const stamp = new Date().toISOString().slice(0, 10);
      a.href = url;
      a.download = `${layer}-entities-${stamp}.csv`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
      const renamedNote = result.renamed.length ? ` · renamed ${result.renamed.map(([o, n]) => `${o}→${n}`).join(", ")}` : "";
      status.textContent = `${fmtInt(result.written)} written, ${fmtInt(result.skipped)} skipped (no geometry)${renamedNote}`;
    } catch (err) {
      status.textContent = `error: ${err}`;
    } finally {
      btn.disabled = false;
    }
  };
}
```

<div class="muted" style="margin-top: 12px; padding-top: 12px; border-top: 1px solid var(--theme-foreground-faintest); font-size: 12px">
  Geometry: points always export as ODK geopoints. LGA/state boundaries export as a geoshape (the
  polygon's exterior ring, simplified under the vertex cap) unless you choose Centroid. Labels:
  the chosen column's value, or <code>feature-N</code> when blank; duplicates get " (2)", " (3)"….
  Property names are sanitized to ODK's rules; renamed columns are reported after export.
</div>

<style>
.big { font-size: 28px; font-weight: 600; line-height: 1.1; }
.card h2 { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); margin: 0 0 4px; }
</style>
