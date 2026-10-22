// Choropleth of one admin level from a GeoJSON source keyed by Location id (a DHIS2
// Maps thematic layer). The boundaries are small enough to ship whole.
import maplibregl from "npm:maplibre-gl@5";
export const DEFAULT_BASEMAP = {
  tiles: ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],
  attribution: "© OpenStreetMap contributors",
  opacity: 0.45,
  saturation: -0.9
};

const NO_VALUE = "#e5e7eb";

/** [[xmin, ymin], [xmax, ymax]] over every coordinate of the features. */
function bbox(features) {
  let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
  const walk = (c) => {
    if (typeof c[0] === "number") {
      if (c[0] < x0) x0 = c[0];
      if (c[0] > x1) x1 = c[0];
      if (c[1] < y0) y0 = c[1];
      if (c[1] > y1) y1 = c[1];
    } else c.forEach(walk);
  };
  for (const f of features) if (f.geometry) walk(f.geometry.coordinates);
  return Number.isFinite(x0) ? [[x0, y0], [x1, y1]] : null;
}

/**
 * Build the map. Returns a container with `update({level, values, stops, colors, legend, popup})`:
 * `values` maps Location id → number, `stops`/`colors` are a step ramp (colors has one
 * more entry than stops), `legend` is [label, format(stop)], `popup(id)` returns HTML.
 */
export function unitMap({geojson, height = 460, basemap = DEFAULT_BASEMAP} = {}) {
  const container = document.createElement("div");
  container.style.cssText = `width:100%;height:${height}px;border-radius:8px;overflow:hidden;position:relative;background:#f8fafc`;

  const sources = {units: {type: "geojson", data: geojson, promoteId: "id"}};
  const layers = [];
  if (basemap) {
    sources.basemap = {type: "raster", tiles: basemap.tiles, tileSize: basemap.tileSize ?? 256,
                       maxzoom: basemap.maxzoom ?? 19, attribution: basemap.attribution ?? ""};
    layers.push({id: "basemap", type: "raster", source: "basemap",
                 paint: {"raster-opacity": basemap.opacity ?? 0.5, "raster-saturation": basemap.saturation ?? 0}});
  }
  // Facility points (DHIS2's facility-level thematic layers): colour and value are set per update.
  sources.points = {type: "geojson", data: {type: "FeatureCollection", features: []}};
  layers.push(
    {id: "unit-fill", type: "fill", source: "units", filter: ["==", ["get", "admin_level"], -1],
     paint: {"fill-color": NO_VALUE, "fill-opacity": ["case", ["boolean", ["feature-state", "hover"], false], 0.95, 0.8]}},
    {id: "unit-line", type: "line", source: "units", filter: ["==", ["get", "admin_level"], -1],
     paint: {"line-color": "#94a3b8", "line-width": 0.5}},
    {id: "parent-line", type: "line", source: "units", filter: ["==", ["get", "admin_level"], -1],
     paint: {"line-color": "#334155", "line-width": 1.2}},
    {id: "points", type: "circle", source: "points",
     paint: {"circle-radius": ["interpolate", ["linear"], ["zoom"], 6, 3, 10, 7], "circle-color": ["get", "color"],
             "circle-stroke-color": "#334155", "circle-stroke-width": 0.6}}
  );

  const all = bbox(geojson.features) ?? [[-180, -60], [180, 75]];
  const map = new maplibregl.Map({container, style: {version: 8, sources, layers}, bounds: all,
                                  fitBoundsOptions: {padding: 20}, attributionControl: {compact: true}});
  map.addControl(new maplibregl.NavigationControl({showCompass: false}), "top-right");
  map.scrollZoom.disable();
  let fit = all;
  let fitted = false;
  new ResizeObserver(() => {
    if (container.clientWidth === 0) return;
    map.resize();
    if (!fitted) { map.fitBounds(fit, {padding: 20, duration: 0}); fitted = true; }
  }).observe(container);

  const legend = document.createElement("div");
  legend.style.cssText = "position:absolute;left:8px;bottom:8px;max-width:calc(100% - 52px);background:rgba(255,255,255,.92);padding:6px 10px;border-radius:6px;font:12px system-ui;color:#334155;box-shadow:0 1px 3px rgba(0,0,0,.15)";
  container.appendChild(legend);

  const popup = new maplibregl.Popup({closeButton: false, closeOnClick: false, offset: 8});
  let hovered = null;
  let current = {popup: () => ""};
  map.on("mousemove", "unit-fill", (e) => {
    const f = e.features?.[0];
    if (!f) return;
    map.getCanvas().style.cursor = "pointer";
    if (hovered !== null && hovered !== f.id) map.setFeatureState({source: "units", id: hovered}, {hover: false});
    hovered = f.id;
    map.setFeatureState({source: "units", id: hovered}, {hover: true});
    const where = f.properties.admin1_name && f.properties.admin1_name !== f.properties.name ? `, ${f.properties.admin1_name}` : "";
    popup.setLngLat(e.lngLat)
      .setHTML(`<div style="font:12px system-ui;line-height:1.35"><b>${f.properties.name}</b>${where}<br>${current.popup(f.id)}</div>`)
      .addTo(map);
  });
  map.on("mousemove", "points", (e) => {
    const f = e.features?.[0];
    if (!f) return;
    map.getCanvas().style.cursor = "pointer";
    popup.setLngLat(e.lngLat).setHTML(`<div style="font:12px system-ui;line-height:1.35"><b>${f.properties.name}</b><br>${f.properties.popup ?? ""}</div>`).addTo(map);
  });
  map.on("mouseleave", "points", () => { map.getCanvas().style.cursor = ""; popup.remove(); });
  map.on("mouseleave", "unit-fill", () => {
    map.getCanvas().style.cursor = "";
    if (hovered !== null) map.setFeatureState({source: "units", id: hovered}, {hover: false});
    hovered = null;
    popup.remove();
  });

  let ready = false;
  let pending = null;
  let applied = [];
  /**
   * `level` is the admin level to colour (0 country, 1 district, 2 chiefdom), or null to colour
   * no areas; `outline` the level whose boundaries are drawn when no level is coloured;
   * `points` facility rows {name, lon, lat, value, popup} coloured on the same ramp.
   */
  function apply({level, values = new Map(), stops, colors, legend: [label, format], popup: popupHtml, points = [], outline = 1}) {
    current = {popup: popupHtml};
    const fillLevel = level ?? -1;
    const atLevel = ["==", ["get", "admin_level"], fillLevel];
    map.setFilter("unit-fill", atLevel);
    map.setFilter("unit-line", ["==", ["get", "admin_level"], level ?? outline]);
    map.setFilter("parent-line", ["==", ["get", "admin_level"], (level ?? outline + 1) - 1]);
    const colorOf = (v) => { let c = colors[0]; stops.forEach((s, i) => { if (v >= s) c = colors[i + 1]; }); return c; };
    map.getSource("points").setData({type: "FeatureCollection", features: points.filter((p) => p.lon != null && p.value != null).map((p) => ({
      type: "Feature", properties: {name: p.name, popup: p.popup ?? "", color: colorOf(p.value)}, geometry: {type: "Point", coordinates: [p.lon, p.lat]}}))});
    for (const id of applied) map.setFeatureState({source: "units", id}, {value: null});
    applied = [];
    for (const [id, v] of values) {
      map.setFeatureState({source: "units", id}, {value: v});
      applied.push(id);
    }
    const step = ["step", ["feature-state", "value"], colors[0]];
    stops.forEach((s, i) => step.push(s, colors[i + 1]));
    map.setPaintProperty("unit-fill", "fill-color", ["case", ["==", ["feature-state", "value"], null], NO_VALUE, step]);
    legend.innerHTML = `<div style="margin-bottom:4px">${label}</div><div style="display:flex;align-items:center;gap:4px;flex-wrap:wrap">` +
      colors.map((c, i) => `<span style="display:inline-block;width:20px;height:12px;background:${c};border:1px solid #cbd5e1"></span>` +
        `<span style="margin-right:4px">${i === 0 ? `&lt;${format(stops[0])}` : format(stops[i - 1]) + (i === colors.length - 1 ? "+" : "")}</span>`).join("") +
      `<span style="display:inline-block;width:20px;height:12px;background:${NO_VALUE};border:1px solid #cbd5e1;margin-left:6px"></span><span>no value</span></div>`;
    const b = bbox(geojson.features.filter((f) => f.properties.admin_level === (level ?? outline)));
    if (b && JSON.stringify(b) !== JSON.stringify(fit)) {
      fit = b;
      if (container.clientWidth > 0) map.fitBounds(fit, {padding: 20, duration: 300});
    }
  }
  map.on("load", () => {
    for (const el of container.querySelectorAll(".maplibregl-ctrl-attrib")) {
      el.classList.remove("maplibregl-compact-show");
      el.removeAttribute("open");
    }
    ready = true;
    if (pending) apply(pending);
  });

  container.update = (opts) => {
    pending = opts;
    if (ready) apply(opts);
  };
  container.map = map;
  return container;
}
