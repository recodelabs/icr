---
title: Georegistry
sql:
  counts: data/georegistry_counts.parquet
  admin_units: data/admin_units.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Georegistry

Every layer the location registry exports — country, states, LGAs, health facilities and
settlements — as it is on the map. Each layer is a PMTiles archive cut from the registry's
GeoParquet by `tools/warehouse/tiles.sh`; the point layers are built with no dropping, so
every facility and settlement in the registry is drawn at every zoom. Toggle layers, narrow
to a state or LGA, and click any point or LGA to see its properties.

```js
import {georegistryMap, LAYERS, FACILITY_LEVELS} from "./components/georegistry-map.js";
import {DEFAULT_BASEMAP} from "./components/map.js";
const BASEMAP = DEFAULT_BASEMAP;

const toRows = (table) => Array.from(table, (r) => {
  const o = typeof r.toJSON === "function" ? r.toJSON() : {...r};
  for (const k in o) if (typeof o[k] === "bigint") o[k] = Number(o[k]);
  return o;
});
const fmtInt = (n) => n == null ? "—" : Math.round(Number(n)).toLocaleString("en");
```

```js
const countRows = toRows(await sql`SELECT * FROM counts WHERE country = 'NGA'`);
const admin = toRows(await sql`SELECT id, name, admin_level, admin1_name, lon, lat, xmin, ymin, xmax, ymax FROM admin_units WHERE country = 'NGA' ORDER BY admin_level, name`);
const states = admin.filter((d) => d.admin_level === 1).map((d) => d.name);
const lgasByState = d3.group(admin.filter((d) => d.admin_level === 2), (d) => d.admin1_name);
const stateLabels = admin.filter((d) => d.admin_level === 1);
```

<div class="grid grid-cols-4" style="gap: 12px; margin-bottom: 8px">
  <div>${layersInput}</div>
  <div>${stateInput}</div>
  <div id="lga-slot"></div>
  <div>${levelInput}</div>
</div>

```js
const layersInput = Inputs.checkbox(Object.keys(LAYERS), {label: "Layers", value: ["country", "states", "lgas", "facilities", "settlements"], format: (k) => LAYERS[k].label});
const activeLayers = Generators.input(layersInput);
const stateInput = Inputs.select(["All", ...states], {label: "State", value: "All"});
const state = Generators.input(stateInput);
// Multiple select; nothing selected means every level.
const levelInput = Inputs.select(FACILITY_LEVELS.map(([l]) => l), {label: "Facility level", multiple: true, size: 4, value: []});
const levelsPicked = Generators.input(levelInput);
```

```js
// The LGA list follows the state: the select is rebuilt whenever the state changes and dropped into its slot.
const lgaOptions = state === "All" ? ["All"] : ["All", ...(lgasByState.get(state) ?? []).map((d) => d.name).sort()];
const lgaInput = Inputs.select(lgaOptions, {label: "LGA", value: "All", disabled: state === "All"});
document.getElementById("lga-slot").replaceChildren(lgaInput);
const lga = Generators.input(lgaInput);
```

```js
const levelSet = new Set(levelsPicked);
const levelOn = (l) => levelSet.size === 0 || levelSet.has(l);
const levelLabel = levelSet.size === 0 ? "" : levelsPicked.length === 1 ? levelsPicked[0] : `${levelsPicked.length} levels`;
const selWhere = (d) => (state === "All" || d.state === state) && (lga === "All" || d.lga === lga);
const inSel = countRows.filter(selWhere);
const n = (layer) => d3.sum(inSel.filter((d) => d.layer === layer), (d) => d.n);
const kpi = {
  states: state === "All" ? d3.sum(countRows.filter((d) => d.layer === "admin-unit" && d.admin_level === 1), (d) => d.n) : 1,
  lgas: lga !== "All" ? 1 : new Set(inSel.filter((d) => d.layer === "admin-unit" && d.admin_level === 2).map((d) => d.lga ?? d.state)).size,
  facilities: d3.sum(inSel.filter((d) => d.layer === "facility" && levelOn(d.facility_level)), (d) => d.n),
  settlements: n("settlement")
};
const scope = lga !== "All" ? `${lga} LGA, ${state}` : state !== "All" ? `${state} State` : "Nigeria";
```

<div class="grid grid-cols-4" style="gap: 12px">
  <div class="card"><h2>States</h2><span class="big">${fmtInt(kpi.states)}</span><div class="muted">${scope}</div></div>
  <div class="card"><h2>LGAs</h2><span class="big">${fmtInt(kpi.lgas)}</span><div class="muted">admin level 2</div></div>
  <div class="card"><h2>Health facilities</h2><span class="big">${fmtInt(kpi.facilities)}</span><div class="muted">${levelSet.size === 0 ? "all levels" : `${levelLabel} · of ${fmtInt(n("facility"))} in ${scope}`}</div></div>
  <div class="card"><h2>Settlements</h2><span class="big">${fmtInt(kpi.settlements)}</span><div class="muted">GRID3 settlement points</div></div>
</div>

<div class="grid grid-cols-3" style="gap: 12px; margin-top: 12px; grid-template-columns: 2fr 1fr">
  <div class="card" style="padding: 0; overflow: hidden">
    ${mapEl}
  </div>
  <div style="display:flex; flex-direction:column; gap: 12px">
    <div class="card">
      <h2>Facility levels in ${scope}</h2>
      ${levelChart}
    </div>
    <div class="card" style="flex: 1">
      <h2>Selected feature</h2>
      ${inspector}
    </div>
  </div>
</div>

```js
const urls = {
  admin: FileAttachment("data/admin.pmtiles").href,
  facilities: FileAttachment("data/facilities.pmtiles").href,
  settlements: FileAttachment("data/settlements.pmtiles").href
};
const mapEl = georegistryMap({urls, height: 640, basemap: BASEMAP, labels: stateLabels, bounds: [[2.5, 4.0], [14.8, 14.0]]});
const selected = Generators.input(mapEl);
// True while the map is in fullscreen (the ⛶ control); the inspector then moves onto the map.
const fullscreen = Generators.observe((notify) => {
  const read = () => notify(mapEl.fullscreen === true);
  read();
  mapEl.addEventListener("fullscreenchange", read);
  return () => mapEl.removeEventListener("fullscreenchange", read);
});
```

```js
mapEl.setLayers(activeLayers);
```

```js
{
  mapEl.setFilter({state: state === "All" ? null : state, lga: lga === "All" ? null : lga, level: levelsPicked.length ? levelsPicked : null});
  const unit = lga !== "All" ? admin.find((d) => d.admin_level === 2 && d.name === lga && d.admin1_name === state)
             : state !== "All" ? admin.find((d) => d.admin_level === 1 && d.name === state) : null;
  mapEl.fit(unit ? [[unit.xmin, unit.ymin], [unit.xmax, unit.ymax]] : null);
}
```

```js
// Distribution of facility levels in the state / LGA selection; the chosen level is highlighted, the rest fade.
const levelRows = FACILITY_LEVELS.map(([l, color]) => ({level: l, color, n: d3.sum(inSel.filter((d) => d.layer === "facility" && d.facility_level === l), (d) => d.n)}));
const levelChart = Plot.plot({
  width: Math.max(280, width / 3 - 60),
  height: 30 + 22 * levelRows.length,
  marginLeft: 150, marginRight: 50, marginTop: 4, marginBottom: 24,
  x: {label: "facilities", grid: true, tickFormat: (d) => d >= 1e3 ? `${Math.round(d / 1e3)}k` : String(d)},
  y: {label: null, domain: levelRows.map((d) => d.level), tickSize: 0},
  marks: [
    Plot.barX(levelRows, {x: "n", y: "level", fill: (d) => d.color, fillOpacity: (d) => levelOn(d.level) ? 1 : 0.25, tip: true,
      title: (d) => `${d.level}: ${fmtInt(d.n)} facilities`}),
    Plot.text(levelRows, {x: "n", y: "level", text: (d) => fmtInt(d.n), textAnchor: "start", dx: 4, fontSize: 11, fill: "#475569"})
  ]
});
```

```js
const LABELS = {id: "Location id", name: "Name", type: "Type", status: "Status", admin1_name: "State", admin2_name: "LGA", admin3_name: "Ward",
  admin_level: "Admin level", path: "Path", pcode: "P-code", gers_id: "GERS id", nhfr_code: "NHFR code", nhfr_uid: "NHFR uid",
  facility_level: "Facility level", ownership: "Ownership", settlement_type: "Settlement type", managing_organization: "Managing organization",
  part_of: "Part of", last_updated: "Last updated", lon: "Longitude", lat: "Latitude"};
const inspectorEl = !selected
  ? html`<div class="muted">Click a facility, settlement or LGA on the map. Every property below comes straight from the feature in the PMTiles layer.</div>`
  : html`<div>
      <div style="font-weight:600; font-size: 15px; margin-bottom: 2px">${selected.properties.name ?? "—"}</div>
      <div class="muted" style="margin-bottom: 8px">${selected.layer === "lga" ? "LGA boundary" : selected.layer === "facility" ? "Health facility" : "Settlement"}${selected.properties.facility_level ? ` · ${selected.properties.facility_level}` : ""}</div>
      <table style="font-size: 12px; border-collapse: collapse; width: 100%">
        ${Object.entries(selected.properties).filter(([, v]) => v != null && v !== "").map(([k, v]) => html`<tr>
          <td style="color:#64748b; padding: 2px 8px 2px 0; vertical-align: top; white-space: nowrap">${LABELS[k] ?? k}</td>
          <td style="padding: 2px 0; word-break: break-all">${String(v)}</td></tr>`)}
      </table>
    </div>`;
// In fullscreen the card is off-screen, so the same element goes into the map's overlay panel instead.
if (fullscreen) mapEl.panel.replaceChildren(html`<div style="font-size:13px;font-weight:500;color:#64748b;margin-bottom:6px">Selected feature</div>`, inspectorEl);
const inspector = fullscreen ? html`<div class="muted">Shown on the fullscreen map.</div>` : inspectorEl;
```

<div class="muted" style="margin-top: 8px">
  Boundaries are GRID3 administrative units; facilities carry their NHFR code, level and ownership; settlements
  their GERS id and the state and LGA they fall in. The archives are served with HTTP range requests, so the browser
  only fetches the tiles in view. Rebuild with <code>tools/warehouse/refresh.sh --tiles</code> after a registry refresh.
</div>

<style>
.big { font-size: 28px; font-weight: 600; line-height: 1.1; }
.map-title { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); padding: 10px 14px 6px; }
.card h2 { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); margin: 0 0 4px; }
.maplibregl-popup-content { padding: 6px 9px; }
</style>
