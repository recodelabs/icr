---
title: ODK Locations
---

# ODK Locations

Select from available location data (health facilities, settlements, LGA and
state boundaries) from the ICR location registry and export as ODK entities.
These can be uploaded into platforms like Ona Data or ODK to enable field based
data collection on these points. Data collected is linked to the unique ID
provided for each point from the ICR.

```js
import init, {convert_to_entities} from "./components/odk-locations/odk_locations.js";
await init({module_or_path: FileAttachment("components/odk-locations/odk_locations_bg.wasm").href});

// One DuckDB instance for the whole page — created once, reused across every
// layer switch below (spinning up a fresh instance would re-download and
// re-instantiate the ~36 MB WASM engine every time).
const db = await DuckDBClient.of();

const toRows = (table) => Array.from(table, (r) => {
  const o = typeof r.toJSON === "function" ? r.toJSON() : {...r};
  for (const k in o) if (typeof o[k] === "bigint") o[k] = Number(o[k]);
  return o;
});
const fmtInt = (n) => n == null ? "—" : Math.round(Number(n)).toLocaleString("en");
// Points ship as bare lon/lat (see src/data/locations-*.parquet.sh); polygons still
// carry real geometry_geojson text. Build the GeoJSON object client-side either way.
const toGeometry = (d) => d.geometry_geojson ? JSON.parse(d.geometry_geojson)
  : (d.lon != null && d.lat != null ? {type: "Point", coordinates: [d.lon, d.lat]} : null);
```

```js
// One parquet file per layer (see src/data/locations-*.parquet.sh — kiln already
// partitions the registry this way). Picking "Health facilities" (the default)
// fetches ~3.5 MB instead of the ~27 MB every-layer-combined file this used to be;
// settlement/lga/state only get fetched if you switch to them.
// FileAttachment() needs a literal path to be picked up by Framework's build-time
// static analysis (a computed path like LAYERS[layer].file would be invisible to it,
// and the loader would silently never run) — so every path is called out literally
// here, once. The FileAttachment object itself is cheap; only .url() on the one for
// the current layer, below, actually resolves/fetches anything.
const LAYERS = {
  facility: {label: "Health facilities", file: FileAttachment("data/locations-facility.parquet"), props: ["state", "lga", "ward", "facility_level", "ownership", "pcode", "nhfr_code", "status"]},
  settlement: {label: "Settlements", file: FileAttachment("data/locations-settlement.parquet"), props: ["state", "lga", "ward", "settlement_type", "pcode", "status"]},
  lga: {label: "LGA boundaries", file: FileAttachment("data/locations-lga.parquet"), props: ["state", "pcode", "status"]},
  state: {label: "State boundaries", file: FileAttachment("data/locations-state.parquet"), props: ["pcode", "status"]}
};
const layerInput = Inputs.radio(Object.keys(LAYERS), {label: "Export", value: "facility", format: (k) => LAYERS[k].label});
const layer = Generators.input(layerInput);
```

```js
// Swaps the "locations" table's source file whenever the layer changes, reusing
// `db` above. Downstream cells depend on `loadedLayer` (not just `layer`) so they
// don't run against a half-swapped table.
const fileUrl = await LAYERS[layer].file.url();
await db.query(`CREATE OR REPLACE TABLE locations AS SELECT * FROM parquet_scan('${fileUrl}')`);
const loadedLayer = layer;
```

```js
const states = toRows(await db.sql`SELECT DISTINCT state FROM locations WHERE state IS NOT NULL ORDER BY state`).map((d) => d.state);
const facilityLevels = loadedLayer === "facility"
  ? toRows(await db.sql`SELECT DISTINCT facility_level FROM locations WHERE facility_level IS NOT NULL ORDER BY facility_level`).map((d) => d.facility_level)
  : [];
```

<div class="grid grid-cols-4" style="gap: 12px; margin-bottom: 8px">
  <div>${layerInput}</div>
  <div>${stateInput}</div>
  <div id="lga-slot"></div>
  <div>${levelInput}</div>
</div>

```js
const stateInput = Inputs.select(["All", ...states], {label: "State", value: "All"});
const state = Generators.input(stateInput);
```

```js
// LGA follows State — same cascading pattern as the campaign dashboards.
const lgaOptions = state === "All" ? ["All"] : ["All", ...toRows(await db.sql([`SELECT DISTINCT lga FROM locations WHERE state = '${state.replace(/'/g, "''")}' AND lga IS NOT NULL ORDER BY lga`])).map((d) => d.lga)];
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
// The layer itself is no longer a WHERE clause — the loaded file already only
// contains that layer's rows (see LAYERS above). Only the remaining filters apply.
const where = [
  state === "All" ? "TRUE" : `state = '${state.replace(/'/g, "''")}'`,
  lga === "All" ? "TRUE" : `lga = '${lga.replace(/'/g, "''")}'`,
  levelsPicked.length === 0 ? "TRUE" : `facility_level IN (${levelsPicked.map((l) => `'${l.replace(/'/g, "''")}'`).join(", ")})`
].join(" AND ");
const cols = ["id", "name", "geometry_geojson", "lon", "lat", ...LAYERS[layer].props];
const previewRows = toRows(await db.sql([`SELECT ${cols.join(", ")} FROM locations WHERE ${where} LIMIT 200`]));
const countRow = toRows(await db.sql([`SELECT count(*) AS n FROM locations WHERE ${where}`]))[0];
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
const previewTable = Inputs.table(previewRows.map((d) => ({...d, geometry: toGeometry(d)?.type})), {
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
      const allCols = ["id", "name", labelColumn, "geometry_geojson", "lon", "lat", ...LAYERS[layer].props];
      const all = toRows(await db.sql([`SELECT ${[...new Set(allCols)].join(", ")} FROM locations WHERE ${where}`]));
      const rows = all.map((d) => ({
        label: d[labelColumn] ?? null,
        geometry: toGeometry(d),
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
