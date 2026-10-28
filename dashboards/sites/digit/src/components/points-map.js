// Facilities and household dwellings as points on MapLibre, from rows with lon/lat, over the
// boundaries that exist: DIGIT itself holds no geometry, and only the Nigerian states and LGAs
// matched to GRID3 (168 units, admin.geojson) carry a boundary from the ICR's registry. Both the
// ADMIN and the NIGERIA hierarchy cover parts of Nigeria, so the map shows one hierarchy's
// boundaries at a time (setHierarchy).
import maplibregl from "npm:maplibre-gl@5";

export const KINDS = [
  ["facility", "Health facility", "#c2410c"],
  ["dwelling", "Household dwelling", "#2563eb"]
];

const BASEMAP = {tiles: ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"], attribution: "© OpenStreetMap contributors"};

export const BOUNDARY_LAYERS = [["state", "States"], ["lga", "LGAs"]];
// ColorBrewer Blues, 5 classes, for shading LGAs by a count.
const SHADES = ["#eff3ff", "#bdd7e7", "#6baed6", "#3182bd", "#08519c"];

/**
 * @param rows   [{location_id, name, kind, boundary_name, hierarchy, lon, lat}]
 * @param admin  GeoJSON FeatureCollection of boundaries (properties id, name, kind state|lga,
 *               hierarchy, level_name, parent, pcode, and counts), or null
 * Returns the container, with setKinds(Set of kinds and boundary layers), setHierarchy(name),
 * setShade(property or null) → the legend breaks, fit() and a `value` (the clicked point's or
 * boundary's properties) updated and an "input" event dispatched on click.
 */
export function pointsMap(rows, {height = 560, admin = null} = {}) {
  const container = document.createElement("div");
  container.style.cssText = `width:100%;height:${height}px;border-radius:8px;overflow:hidden;position:relative;background:#f8fafc`;
  const features = rows.map((d, i) => ({type: "Feature", id: i,
    properties: {id: d.location_id, name: d.name, kind: d.kind, boundary: d.boundary_name, hierarchy: d.hierarchy},
    geometry: {type: "Point", coordinates: [d.lon, d.lat]}}));
  // The demo data has stray points (a device default near San Francisco, 123.45° E), so the map
  // opens on the 1st to 99th percentile of the points rather than all of them.
  const bounds = rows.length > 10
    ? [[quantile(rows, "lon", 0.01), quantile(rows, "lat", 0.01)], [quantile(rows, "lon", 0.99), quantile(rows, "lat", 0.99)]]
    : rows.length ? [[d3min(rows, "lon"), d3min(rows, "lat")], [d3max(rows, "lon"), d3max(rows, "lat")]] : [[-20, -35], [55, 38]];
  const color = ["match", ["get", "kind"], ...KINDS.flatMap(([k, , c]) => [k, c]), "#6b7280"];
  const map = new maplibregl.Map({
    container,
    style: {
      version: 8,
      sources: {
        basemap: {type: "raster", tiles: BASEMAP.tiles, tileSize: 256, maxzoom: 19, attribution: BASEMAP.attribution},
        points: {type: "geojson", data: {type: "FeatureCollection", features}},
        admin: {type: "geojson", data: admin ?? {type: "FeatureCollection", features: []}}
      },
      layers: [
        {id: "basemap", type: "raster", source: "basemap", paint: {"raster-opacity": 0.5, "raster-saturation": -0.9}},
        {id: "lga-fill", type: "fill", source: "admin", filter: ["==", ["get", "kind"], "lga"],
         paint: {"fill-color": "#cbd5e1", "fill-opacity": ["case", ["boolean", ["feature-state", "hover"], false], 0.55, 0.3]}},
        {id: "lga-line", type: "line", source: "admin", filter: ["==", ["get", "kind"], "lga"],
         paint: {"line-color": "#64748b", "line-width": ["interpolate", ["linear"], ["zoom"], 5, 0.4, 10, 1.2]}},
        {id: "state-fill", type: "fill", source: "admin", filter: ["==", ["get", "kind"], "state"],
         paint: {"fill-color": "#000", "fill-opacity": 0}},
        {id: "state-line", type: "line", source: "admin", filter: ["==", ["get", "kind"], "state"],
         paint: {"line-color": "#0f172a", "line-width": ["interpolate", ["linear"], ["zoom"], 5, 1.2, 10, 2.5]}},
        {id: "dwellings", type: "circle", source: "points", filter: ["==", ["get", "kind"], "dwelling"],
         paint: {"circle-radius": ["interpolate", ["linear"], ["zoom"], 3, 1, 8, 2, 13, 4.5], "circle-color": color, "circle-opacity": 0.6}},
        {id: "facilities", type: "circle", source: "points", filter: ["==", ["get", "kind"], "facility"],
         paint: {"circle-radius": ["interpolate", ["linear"], ["zoom"], 3, 2, 8, 3.5, 13, 7], "circle-color": color, "circle-opacity": 0.9,
                 "circle-stroke-color": "#fff", "circle-stroke-width": ["interpolate", ["linear"], ["zoom"], 3, 0, 8, 0.8]}}
      ]
    },
    bounds, fitBoundsOptions: {padding: 30},
    attributionControl: {compact: true}
  });
  let fitted = false;
  new ResizeObserver(() => {
    if (container.clientWidth === 0) return;
    map.resize();
    if (!fitted) { map.fitBounds(bounds, {padding: 30, duration: 0}); fitted = true; }
  }).observe(container);
  map.addControl(new maplibregl.NavigationControl({showCompass: false}), "top-right");
  map.addControl(new maplibregl.FullscreenControl({container}), "top-right");
  map.addControl(new maplibregl.ScaleControl({unit: "metric"}), "bottom-right");

  const popup = new maplibregl.Popup({closeButton: false, closeOnClick: false, offset: 8});
  const POINT_LAYERS = ["facilities", "dwellings"];
  const fmt = (n) => (n ?? 0).toLocaleString("en");
  // Boundaries: hover highlights an LGA; points win over polygons, LGAs over states.
  let hovered = null;
  const unhover = () => { if (hovered != null) map.setFeatureState({source: "admin", id: hovered}, {hover: false}); hovered = null; };
  for (const layer of ["lga-fill", "state-fill"]) {
    const above = layer === "state-fill" ? [...POINT_LAYERS, "lga-fill"] : POINT_LAYERS;
    const covered = (e) => map.queryRenderedFeatures(e.point, {layers: above.filter((l) => map.getLayoutProperty(l, "visibility") !== "none")}).length > 0;
    map.on("mousemove", layer, (e) => {
      const f = e.features?.[0]; if (!f || covered(e)) return;
      if (layer === "lga-fill" && hovered !== f.id) { unhover(); hovered = f.id; map.setFeatureState({source: "admin", id: f.id}, {hover: true}); }
      const p = f.properties;
      popup.setLngLat(e.lngLat).setHTML(`<div style="font:12px system-ui;line-height:1.35"><b>${escape(p.name ?? "—")}</b> ${escape(p.level_name ?? "")}${p.parent ? `, ${escape(p.parent)}` : ""}<br>P-code ${escape(p.pcode ?? "—")}<br>${fmt(p.households)} households registered · ${fmt(p.visits)} visits</div>`).addTo(map);
    });
    map.on("mouseleave", layer, () => { unhover(); popup.remove(); });
    map.on("click", layer, (e) => {
      const f = e.features?.[0]; if (!f || covered(e)) return;
      container.value = {...f.properties, layer: "boundary", lngLat: [e.lngLat.lng, e.lngLat.lat]};
      container.dispatchEvent(new Event("input", {bubbles: true}));
    });
  }
  for (const layer of POINT_LAYERS) {
    map.on("mousemove", layer, (e) => {
      const p = e.features?.[0]?.properties; if (!p) return;
      map.getCanvas().style.cursor = "pointer";
      const kind = KINDS.find(([k]) => k === p.kind)?.[1] ?? p.kind;
      popup.setLngLat(e.lngLat).setHTML(`<div style="font:12px system-ui;line-height:1.35"><b>${escape(p.name ?? "—")}</b><br>${kind}${p.boundary ? ` · ${escape(p.boundary)}` : ""}</div>`).addTo(map);
    });
    map.on("mouseleave", layer, () => { map.getCanvas().style.cursor = ""; popup.remove(); });
    map.on("click", layer, (e) => {
      const p = e.features?.[0]?.properties; if (!p) return;
      container.value = {...p, layer: "point", lngLat: [e.lngLat.lng, e.lngLat.lat]};
      container.dispatchEvent(new Event("input", {bubbles: true}));
    });
  }

  const legend = document.createElement("div");
  legend.style.cssText = "position:absolute;left:8px;bottom:8px;background:rgba(255,255,255,.92);padding:6px 10px;border-radius:6px;font:12px system-ui;color:#334155;box-shadow:0 1px 3px rgba(0,0,0,.15)";
  const counts = new Map(KINDS.map(([k]) => [k, rows.filter((d) => d.kind === k).length]));
  const pointLegend = KINDS.map(([k, label, c]) => `<div style="display:flex;align-items:center;gap:6px;line-height:1.5"><span style="display:inline-block;width:10px;height:10px;border-radius:50%;background:${c}"></span>${label} (${counts.get(k).toLocaleString("en")})</div>`).join("");
  container.appendChild(legend);

  let ready = false, kinds = new Set([...KINDS.map(([k]) => k), ...BOUNDARY_LAYERS.map(([k]) => k)]), hierarchy = null, shade = null;
  // Breaks for shading: the LGAs' quintiles of the property, among LGAs with a value above 0.
  const breaksFor = (prop) => {
    const v = (admin?.features ?? []).filter((f) => f.properties.kind === "lga" && (!hierarchy || f.properties.hierarchy === hierarchy))
      .map((f) => f.properties[prop] ?? 0).filter((x) => x > 0).sort((a, b) => a - b);
    if (!v.length) return [];
    return [...new Set([0.2, 0.4, 0.6, 0.8].map((q) => v[Math.floor(q * (v.length - 1))]))];
  };
  const apply = () => {
    if (!ready) return;
    const vis = (on) => on ? "visible" : "none";
    map.setLayoutProperty("facilities", "visibility", vis(kinds.has("facility")));
    map.setLayoutProperty("dwellings", "visibility", vis(kinds.has("dwelling")));
    for (const id of ["lga-fill", "lga-line"]) map.setLayoutProperty(id, "visibility", vis(kinds.has("lga")));
    for (const id of ["state-fill", "state-line"]) map.setLayoutProperty(id, "visibility", vis(kinds.has("state")));
    const h = hierarchy ? [["==", ["get", "hierarchy"], hierarchy]] : [];
    map.setFilter("lga-fill", ["all", ["==", ["get", "kind"], "lga"], ...h]);
    map.setFilter("lga-line", ["all", ["==", ["get", "kind"], "lga"], ...h]);
    map.setFilter("state-fill", ["all", ["==", ["get", "kind"], "state"], ...h]);
    map.setFilter("state-line", ["all", ["==", ["get", "kind"], "state"], ...h]);
    let shadeLegend = "";
    if (shade) {
      const breaks = breaksFor(shade.property);
      const stepped = ["step", ["coalesce", ["get", shade.property], 0], "#f1f5f9", 1, SHADES[0], ...breaks.flatMap((b, i) => [b, SHADES[i + 1]])];
      map.setPaintProperty("lga-fill", "fill-color", stepped);
      map.setPaintProperty("lga-fill", "fill-opacity", ["case", ["boolean", ["feature-state", "hover"], false], 0.9, 0.7]);
      const edges = [1, ...breaks];
      shadeLegend = `<div style="margin-top:4px">LGAs by ${escape(shade.label)}</div>` +
        `<div style="display:flex;align-items:center;gap:6px;line-height:1.5"><span style="display:inline-block;width:12px;height:10px;background:#f1f5f9;border:1px solid #cbd5e1"></span>0</div>` +
        edges.map((b, i) => `<div style="display:flex;align-items:center;gap:6px;line-height:1.5"><span style="display:inline-block;width:12px;height:10px;background:${SHADES[i]}"></span>${fmt(b)}${i < edges.length - 1 ? `–${fmt(edges[i + 1] - 1)}` : "+"}</div>`).join("");
    } else {
      map.setPaintProperty("lga-fill", "fill-color", "#cbd5e1");
      map.setPaintProperty("lga-fill", "fill-opacity", ["case", ["boolean", ["feature-state", "hover"], false], 0.55, 0.3]);
    }
    legend.innerHTML = pointLegend + (kinds.has("lga") ? shadeLegend : "");
  };
  legend.innerHTML = pointLegend;
  map.on("load", () => { ready = true; apply(); });
  container.setKinds = (k) => { kinds = new Set(k); apply(); };
  container.setHierarchy = (h) => { hierarchy = h; apply(); };
  container.setShade = (s) => { shade = s; apply(); };
  container.fit = () => map.fitBounds(bounds, {padding: 30, duration: 500});
  container.flyTo = (lngLat, zoom = 13) => map.flyTo({center: lngLat, zoom});
  container.map = map;
  container.value = null;
  return container;
}

function quantile(rows, k, q) { const v = rows.map((d) => d[k]).sort((a, b) => a - b); return v[Math.floor(q * (v.length - 1))]; }
function d3min(rows, k) { let m = Infinity; for (const d of rows) if (d[k] < m) m = d[k]; return m; }
function d3max(rows, k) { let m = -Infinity; for (const d of rows) if (d[k] > m) m = d[k]; return m; }
function escape(s) { return String(s).replace(/[&<>"]/g, (c) => ({"&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;"})[c]); }
