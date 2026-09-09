// Georegistry map: every layer exported from the location registry (country, states, LGAs,
// facilities, settlements, facility + settlement catchments) as PMTiles, streamed over HTTP range requests so the large
// no-drop point archives are never downloaded whole. Layers can be toggled, filtered to a
// state / LGA, and points clicked to inspect.
import maplibregl from "npm:maplibre-gl@5";
import {PMTiles} from "npm:pmtiles@4";
import {protocol, DEFAULT_BASEMAP} from "./map.js";

export const FACILITY_LEVELS = [
  ["Teaching/Tertiary Hospital", "#7c2d12"],
  ["Specialized Hospital", "#9a3412"],
  ["General Hospital", "#c2410c"],
  ["Primary Health Center", "#2563eb"],
  ["Primary Health Clinic", "#0ea5e9"],
  ["Health Post", "#14b8a6"],
  ["Unknown", "#9ca3af"]
];
const facilityColor = ["match", ["get", "facility_level"], ...FACILITY_LEVELS.flat(), "#9ca3af"];

/** The layers the page can toggle: id → {label, source, sourceLayer, kind}. */
export const LAYERS = {
  country: {label: "Country", source: "admin", sourceLayer: "country", kind: "polygon"},
  states: {label: "States", source: "admin", sourceLayer: "states", kind: "polygon"},
  lgas: {label: "LGAs", source: "admin", sourceLayer: "lgas", kind: "polygon"},
  facilities: {label: "Health facilities", source: "facilities", sourceLayer: "facilities", kind: "point", minzoom: 4},
  settlements: {label: "Settlements", source: "settlements", sourceLayer: "settlements", kind: "point", minzoom: 8},
  facilityCatchments: {label: "Facility catchments", source: "catchments", sourceLayer: "facility_catchments", kind: "polygon", minzoom: 6},
  settlementCatchments: {label: "Settlement catchments", source: "catchments", sourceLayer: "settlement_catchments", kind: "polygon", minzoom: 9}
};
const CATCHMENT_COLORS = {facility: "#7c3aed", settlement: "#d97706"};

const registered = new Set();
function pmtilesSource(url) {
  const abs = new URL(url, location.href).href;
  if (!registered.has(abs)) { protocol.add(new PMTiles(abs)); registered.add(abs); }
  return {type: "vector", url: `pmtiles://${abs}`};
}

/**
 * @param urls   {admin, facilities, settlements, catchments?} — PMTiles URLs (FileAttachment hrefs);
 *               without `catchments` the two catchment layers are not created
 * @param labels state centroids [{id, name, lon, lat}]
 * Returns the container with: setLayers(Set), setFilter({state, lga, level}), fit(bounds), and a
 * `value` ({layer, properties, lngLat}) updated + "input" event dispatched on click.
 */
export function georegistryMap({urls, height = 640, basemap = DEFAULT_BASEMAP, labels = [], bounds} = {}) {
  const container = document.createElement("div");
  container.style.cssText = `width:100%;height:${height}px;border-radius:8px;overflow:hidden;position:relative;background:#f8fafc`;

  const sources = {
    admin: pmtilesSource(urls.admin),
    facilities: pmtilesSource(urls.facilities),
    settlements: pmtilesSource(urls.settlements),
    ...(urls.catchments ? {catchments: pmtilesSource(urls.catchments)} : {}),
    labels: {type: "geojson", data: {type: "FeatureCollection", features: labels.map((d) => ({
      type: "Feature", id: d.id, properties: {name: d.name}, geometry: {type: "Point", coordinates: [d.lon, d.lat]}}))}}
  };
  const layers = [];
  if (basemap) {
    sources.basemap = {type: "raster", tiles: basemap.tiles, tileSize: basemap.tileSize ?? 256, maxzoom: basemap.maxzoom ?? 19, attribution: basemap.attribution ?? ""};
    layers.push({id: "basemap", type: "raster", source: "basemap", paint: {"raster-opacity": basemap.opacity ?? 0.5, "raster-saturation": basemap.saturation ?? 0}});
  }
  layers.push(
    {id: "lgas-fill", type: "fill", source: "admin", "source-layer": "lgas", paint: {"fill-color": "#cbd5e1", "fill-opacity": ["case", ["boolean", ["feature-state", "hover"], false], 0.35, 0.08]}},
    {id: "lgas-line", type: "line", source: "admin", "source-layer": "lgas", paint: {"line-color": "#94a3b8", "line-width": 0.6}},
    {id: "states-line", type: "line", source: "admin", "source-layer": "states", paint: {"line-color": "#334155", "line-width": 1.4}},
    {id: "country-line", type: "line", source: "admin", "source-layer": "country", paint: {"line-color": "#0f172a", "line-width": 2.2, "line-dasharray": [3, 2]}},
    // Catchment polygons sit between the admin boundaries and the points: facility catchments
    // tile their LGA, settlement catchments nest inside them.
    ...(urls.catchments ? [
      {id: "facility-catchments-fill", type: "fill", source: "catchments", "source-layer": "facility_catchments", minzoom: 6,
       paint: {"fill-color": CATCHMENT_COLORS.facility, "fill-opacity": ["case", ["boolean", ["feature-state", "hover"], false], 0.3, 0.1]}},
      {id: "facility-catchments-line", type: "line", source: "catchments", "source-layer": "facility_catchments", minzoom: 6,
       paint: {"line-color": CATCHMENT_COLORS.facility, "line-width": ["interpolate", ["linear"], ["zoom"], 6, 0.5, 12, 1.6], "line-opacity": 0.8}},
      {id: "settlement-catchments-fill", type: "fill", source: "catchments", "source-layer": "settlement_catchments", minzoom: 9,
       paint: {"fill-color": CATCHMENT_COLORS.settlement, "fill-opacity": ["case", ["boolean", ["feature-state", "hover"], false], 0.45, 0.2]}},
      {id: "settlement-catchments-line", type: "line", source: "catchments", "source-layer": "settlement_catchments", minzoom: 9,
       paint: {"line-color": CATCHMENT_COLORS.settlement, "line-width": ["interpolate", ["linear"], ["zoom"], 9, 0.3, 13, 1], "line-opacity": 0.7}}
    ] : []),
    {id: "settlements-pt", type: "circle", source: "settlements", "source-layer": "settlements", minzoom: 8,
     paint: {"circle-radius": ["interpolate", ["linear"], ["zoom"], 8, 1.6, 11, 3, 13, 5], "circle-color": "#6b7280", "circle-opacity": 0.75, "circle-stroke-color": "#fff", "circle-stroke-width": ["interpolate", ["linear"], ["zoom"], 8, 0, 11, 0.6]}},
    {id: "settlements-label", type: "symbol", source: "settlements", "source-layer": "settlements", minzoom: 12,
     layout: {"text-field": ["get", "name"], "text-size": 10, "text-font": ["Open Sans Semibold"], "text-offset": [0, 0.9], "text-anchor": "top", "text-optional": true},
     paint: {"text-color": "#475569", "text-halo-color": "#fff", "text-halo-width": 1}},
    {id: "facilities-pt", type: "circle", source: "facilities", "source-layer": "facilities", minzoom: 4,
     paint: {"circle-radius": ["interpolate", ["linear"], ["zoom"], 4, 1.5, 8, 3.5, 12, 6.5], "circle-color": facilityColor, "circle-opacity": 0.9, "circle-stroke-color": "#fff", "circle-stroke-width": ["interpolate", ["linear"], ["zoom"], 4, 0, 8, 0.8]}},
    {id: "facilities-label", type: "symbol", source: "facilities", "source-layer": "facilities", minzoom: 11,
     layout: {"text-field": ["get", "name"], "text-size": 11, "text-font": ["Open Sans Semibold"], "text-offset": [0, 1], "text-anchor": "top", "text-optional": true},
     paint: {"text-color": "#1e293b", "text-halo-color": "#fff", "text-halo-width": 1.2}},
    {id: "state-label", type: "symbol", source: "labels",
     layout: {"text-field": ["get", "name"], "text-size": 12, "text-font": ["Open Sans Semibold"], "text-allow-overlap": false},
     paint: {"text-color": "#1e293b", "text-halo-color": "#fff", "text-halo-width": 1.5}}
  );
  const LAYER_IDS = {country: ["country-line"], states: ["states-line", "state-label"], lgas: ["lgas-fill", "lgas-line"],
                     facilities: ["facilities-pt", "facilities-label"], settlements: ["settlements-pt", "settlements-label"],
                     ...(urls.catchments ? {facilityCatchments: ["facility-catchments-fill", "facility-catchments-line"],
                                            settlementCatchments: ["settlement-catchments-fill", "settlement-catchments-line"]} : {})};
  const CATCHMENT_FILLS = urls.catchments ? ["settlement-catchments-fill", "facility-catchments-fill"] : [];

  const fit = bounds ?? [[2.5, 4.0], [14.8, 14.0]];
  const map = new maplibregl.Map({
    container,
    style: {version: 8, glyphs: "https://demotiles.maplibre.org/font/{fontstack}/{range}.pbf", sources, layers},
    bounds: fit, fitBoundsOptions: {padding: 20},
    attributionControl: {compact: true}
  });
  let fitted = false;
  new ResizeObserver(() => {
    if (container.clientWidth === 0) return;
    map.resize();
    if (!fitted) { map.fitBounds(fit, {padding: 20, duration: 0}); fitted = true; }
  }).observe(container);
  map.addControl(new maplibregl.NavigationControl({showCompass: false}), "top-right");
  map.addControl(new maplibregl.FullscreenControl({container}), "top-right");
  map.addControl(new maplibregl.ScaleControl({unit: "metric"}), "bottom-right");

  // In fullscreen the page's feature card cannot be seen, so the page moves its inspector into
  // this overlay panel (container.panel) while document.fullscreenElement === container.
  const panel = document.createElement("div");
  panel.style.cssText = "display:none;position:absolute;top:10px;left:10px;width:340px;max-height:calc(100% - 20px);overflow:auto;background:rgba(255,255,255,.96);padding:12px 14px;border-radius:8px;font:13px system-ui;color:#0f172a;box-shadow:0 2px 8px rgba(0,0,0,.2);z-index:2";
  container.appendChild(panel);
  document.addEventListener("fullscreenchange", () => {
    container.fullscreen = document.fullscreenElement === container;
    panel.style.display = container.fullscreen ? "" : "none";
    container.dispatchEvent(new Event("fullscreenchange"));
  });
  container.panel = panel;
  container.fullscreen = false;

  // Zoom readout (settlements only draw from z8).
  const zoomBadge = document.createElement("div");
  zoomBadge.style.cssText = "position:absolute;right:8px;top:112px;background:rgba(255,255,255,.9);padding:2px 7px;border-radius:5px;font:11px system-ui;color:#334155;box-shadow:0 1px 3px rgba(0,0,0,.15)";
  container.appendChild(zoomBadge);
  const showZoom = () => { zoomBadge.textContent = `z${map.getZoom().toFixed(1)}`; };
  map.on("zoom", showZoom); map.on("load", showZoom);

  // Hover + click on points; hover on LGAs.
  const popup = new maplibregl.Popup({closeButton: false, closeOnClick: false, offset: 8});
  const POINT_LAYERS = ["facilities-pt", "settlements-pt"];
  for (const id of POINT_LAYERS) {
    map.on("mousemove", id, (e) => {
      const f = e.features?.[0]; if (!f) return;
      map.getCanvas().style.cursor = "pointer";
      const p = f.properties;
      popup.setLngLat(e.lngLat).setHTML(`<div style="font:12px system-ui;line-height:1.35"><b>${p.name ?? "—"}</b><br>${p.facility_level ?? (id.startsWith("settlements") ? "settlement" : "")}${p.admin2_name ? ` · ${p.admin2_name} LGA` : ""}${p.admin1_name ? `, ${p.admin1_name}` : ""}<br><span style="color:#64748b">click to inspect</span></div>`).addTo(map);
    });
    map.on("mouseleave", id, () => { map.getCanvas().style.cursor = ""; popup.remove(); });
    map.on("click", id, (e) => {
      const f = e.features?.[0]; if (!f) return;
      container.value = {layer: id.startsWith("facilities") ? "facility" : "settlement", properties: f.properties, lngLat: [e.lngLat.lng, e.lngLat.lat]};
      container.dispatchEvent(new Event("input", {bubbles: true}));
    });
  }
  // Catchments: hover highlights the polygon, click inspects it. Points win over polygons, and
  // the smaller settlement catchment wins over the facility catchment it sits in.
  const catchHover = {};
  for (const id of CATCHMENT_FILLS) {
    const kind = id.startsWith("facility") ? "facility" : "settlement";
    const sourceLayer = `${kind}_catchments`;
    const above = kind === "facility" ? [...POINT_LAYERS, "settlement-catchments-fill"] : POINT_LAYERS;
    const clearHover = () => { if (catchHover[kind] != null) map.setFeatureState({source: "catchments", sourceLayer, id: catchHover[kind]}, {hover: false}); catchHover[kind] = null; };
    map.on("mousemove", id, (e) => {
      const f = e.features?.[0]; if (!f) return;
      if (map.queryRenderedFeatures(e.point, {layers: above.filter((l) => map.getLayer(l))}).length) { clearHover(); return; }
      if (catchHover[kind] !== f.id) { clearHover(); catchHover[kind] = f.id; map.setFeatureState({source: "catchments", sourceLayer, id: f.id}, {hover: true}); }
      map.getCanvas().style.cursor = "pointer";
      const p = f.properties;
      popup.setLngLat(e.lngLat).setHTML(`<div style="font:12px system-ui;line-height:1.35"><b>${p.name ?? "—"}</b><br>${kind} catchment${p.admin2_name ? ` · ${p.admin2_name} LGA` : ""}${p.admin1_name ? `, ${p.admin1_name}` : ""}<br><span style="color:#64748b">click to inspect</span></div>`).addTo(map);
    });
    map.on("mouseleave", id, () => { clearHover(); map.getCanvas().style.cursor = ""; popup.remove(); });
    map.on("click", id, (e) => {
      if (map.queryRenderedFeatures(e.point, {layers: above.filter((l) => map.getLayer(l))}).length) return;
      const f = e.features?.[0]; if (!f) return;
      container.value = {layer: `${kind}-catchment`, properties: f.properties, lngLat: [e.lngLat.lng, e.lngLat.lat]};
      container.dispatchEvent(new Event("input", {bubbles: true}));
    });
  }
  let hovered = null;
  map.on("mousemove", "lgas-fill", (e) => {
    const f = e.features?.[0]; if (!f) return;
    if (map.queryRenderedFeatures(e.point, {layers: [...POINT_LAYERS, ...CATCHMENT_FILLS]}).length) return;  // points and catchments win
    if (hovered !== null && hovered !== f.id) map.setFeatureState({source: "admin", sourceLayer: "lgas", id: hovered}, {hover: false});
    hovered = f.id; map.setFeatureState({source: "admin", sourceLayer: "lgas", id: hovered}, {hover: true});
    popup.setLngLat(e.lngLat).setHTML(`<div style="font:12px system-ui;line-height:1.35"><b>${f.properties.name}</b> LGA, ${f.properties.admin1_name}<br><span style="color:#64748b">${f.properties.pcode ?? ""}</span></div>`).addTo(map);
  });
  map.on("mouseleave", "lgas-fill", () => { if (hovered !== null) map.setFeatureState({source: "admin", sourceLayer: "lgas", id: hovered}, {hover: false}); hovered = null; popup.remove(); });
  map.on("click", "lgas-fill", (e) => {
    if (map.queryRenderedFeatures(e.point, {layers: [...POINT_LAYERS, ...CATCHMENT_FILLS]}).length) return;
    const f = e.features?.[0]; if (!f) return;
    container.value = {layer: "lga", properties: f.properties, lngLat: [e.lngLat.lng, e.lngLat.lat]};
    container.dispatchEvent(new Event("input", {bubbles: true}));
  });

  // Legend
  const legend = document.createElement("div");
  legend.style.cssText = "position:absolute;left:8px;bottom:8px;background:rgba(255,255,255,.92);padding:6px 10px;border-radius:6px;font:12px system-ui;color:#334155;box-shadow:0 1px 3px rgba(0,0,0,.15)";
  container.appendChild(legend);
  function renderLegend(active) {
    const rows = [];
    if (active.has("facilities")) rows.push(`<div style="margin-bottom:2px">Health facilities</div>` + FACILITY_LEVELS.map(([l, c]) =>
      `<div style="display:flex;align-items:center;gap:6px;line-height:1.5"><span style="display:inline-block;width:10px;height:10px;border-radius:50%;background:${c};border:1px solid #fff;box-shadow:0 0 0 1px #cbd5e1"></span>${l}</div>`).join(""));
    if (active.has("settlements")) rows.push(`<div style="display:flex;align-items:center;gap:6px;line-height:1.5;margin-top:4px"><span style="display:inline-block;width:8px;height:8px;border-radius:50%;background:#6b7280"></span>Settlement <span style="color:#64748b">(from z8)</span></div>`);
    const swatch = (c) => `<span style="display:inline-block;width:12px;height:10px;background:${c}33;border:1.5px solid ${c}"></span>`;
    if (active.has("facilityCatchments")) rows.push(`<div style="display:flex;align-items:center;gap:6px;line-height:1.5;margin-top:4px">${swatch(CATCHMENT_COLORS.facility)}Facility catchment <span style="color:#64748b">(from z6)</span></div>`);
    if (active.has("settlementCatchments")) rows.push(`<div style="display:flex;align-items:center;gap:6px;line-height:1.5">${swatch(CATCHMENT_COLORS.settlement)}Settlement catchment <span style="color:#64748b">(from z9)</span></div>`);
    legend.innerHTML = rows.join("") || `<span style="color:#64748b">boundaries only</span>`;
    legend.style.display = rows.length || active.size ? "" : "none";
  }

  let ready = false;
  const state = {layers: new Set(Object.keys(LAYERS)), filter: {}};
  function applyLayers() {
    if (!ready) return;
    for (const [key, ids] of Object.entries(LAYER_IDS)) for (const id of ids) map.setLayoutProperty(id, "visibility", state.layers.has(key) ? "visible" : "none");
    renderLegend(state.layers);
  }
  function applyFilter() {
    if (!ready) return;
    const {state: st, lga, level} = state.filter;
    const pointFilter = ["all", ...(st ? [["==", ["get", "admin1_name"], st]] : []), ...(lga ? [["==", ["get", "admin2_name"], lga]] : [])];
    const levels = Array.isArray(level) ? level : level ? [level] : [];
    const facilityFilter = [...pointFilter, ...(levels.length ? [["in", ["get", "facility_level"], ["literal", levels]]] : [])];
    for (const id of ["settlements-pt", "settlements-label"]) map.setFilter(id, pointFilter.length > 1 ? pointFilter : null);
    for (const id of ["facilities-pt", "facilities-label"]) map.setFilter(id, facilityFilter.length > 1 ? facilityFilter : null);
    for (const id of Object.values(LAYER_IDS).flat().filter((l) => l.includes("catchments"))) map.setFilter(id, pointFilter.length > 1 ? pointFilter : null);
    const lgaFilter = ["all", ...(st ? [["==", ["get", "admin1_name"], st]] : []), ...(lga ? [["==", ["get", "name"], lga]] : [])];
    for (const id of ["lgas-fill", "lgas-line"]) map.setFilter(id, lgaFilter.length > 1 ? lgaFilter : null);
    map.setFilter("states-line", st ? ["==", ["get", "name"], st] : null);
    map.setFilter("state-label", st ? ["==", ["get", "name"], st] : null);
  }
  map.on("load", () => {
    for (const el of container.querySelectorAll(".maplibregl-ctrl-attrib")) { el.classList.remove("maplibregl-compact-show"); el.removeAttribute("open"); }
    ready = true; applyLayers(); applyFilter();
  });

  container.setLayers = (keys) => { state.layers = new Set(keys); applyLayers(); };
  container.setFilter = (f) => { state.filter = f ?? {}; applyFilter(); };
  container.fit = (b, opts = {}) => { if (container.clientWidth > 0) map.fitBounds(b ?? fit, {padding: 24, duration: 500, ...opts}); };
  container.flyTo = (lngLat, zoom = 13) => map.flyTo({center: lngLat, zoom: Math.max(map.getZoom(), zoom)});
  container.map = map;
  container.value = null;
  return container;
}
