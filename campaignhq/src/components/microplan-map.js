// Microplan map: one LGA, its facility catchments (from catchments.pmtiles, coloured by
// each facility's progress), the settlements as circles (coloured by task status
// or by coverage), and the facilities as markers. Rows come from the microplan loader.
import maplibregl from "npm:maplibre-gl@5";
import {PMTiles} from "npm:pmtiles@4";
import {protocol, DEFAULT_BASEMAP} from "./map.js";

/** Task status: a status palette, fixed order (dataviz: never reused for series). */
export const STATUS = [
  ["requested", "Pending", "#94a3b8"],
  ["in-progress", "In progress", "#2563eb"],
  ["completed", "Completed", "#15803d"]
];
/** Coverage of completed settlements — the site's coverage ramp (coverage page, map.js). */
export const COVERAGE_BREAKS = [0.5, 0.65, 0.8, 0.9, 0.95, 1.05];
export const COVERAGE_COLORS = ["#fde0dd", "#fcc5c0", "#fa9fb5", "#c7e9c0", "#a1d99b", "#74c476", "#238b45"];
/** Facility progress (share of settlements completed): ColorBrewer Purples, as the calendar map. */
const PROGRESS_COLORS = ["#f2f0f7", "#dadaeb", "#bcbddc", "#9e9ac8", "#756bb1", "#54278f"];
/** Population: ColorBrewer YlGnBu, the site's population ramp (targeting / coverage pages). */
const POP_COLORS = ["#ffffcc", "#c7e9b4", "#7fcdbb", "#41b6c4", "#2c7fb8", "#253494"];
/** Distance to the facility: ColorBrewer Oranges, one hue light → dark. */
export const DISTANCE_BREAKS = [1, 2, 3, 5, 8];
export const DISTANCE_COLORS = ["#feedde", "#fdd0a2", "#fdae6b", "#fd8d3c", "#e6550d", "#a63603"];

/** What colours the settlement circles (and, for distance, the settlement catchment polygons). */
export const METRICS = {
  status: {label: "Settlement status"},
  coverage: {label: "Coverage (vaccinated ÷ under-5 target)"},
  distance: {label: "Distance to the health facility"}
};
/** What fills the facility catchments; the value comes from the page's facility rollup. */
export const CATCHMENT_METRICS = {
  progress: {label: "Share of settlements completed", state: "progress", colors: PROGRESS_COLORS, stops: () => [0, 0.2, 0.4, 0.6, 0.8, 1], format: (v) => `${Math.round(v * 100)}%`},
  u5: {label: "Children 0–59 months targeted", state: "u5", colors: POP_COLORS, stops: (max) => [0, 0.1, 0.25, 0.5, 0.75, 1].map((k) => k * niceCeil(max)), format: (v) => v >= 1e3 ? `${+(v / 1e3).toFixed(1)}k` : String(Math.round(v))},
  worldpop: {label: "Population (WorldPop 2026)", state: "worldpop", colors: POP_COLORS, stops: (max) => [0, 0.1, 0.25, 0.5, 0.75, 1].map((k) => k * niceCeil(max)), format: (v) => v >= 1e3 ? `${+(v / 1e3).toFixed(1)}k` : String(Math.round(v))},
  none: {label: "No fill"}
};
function niceCeil(x) {
  if (!(x > 0)) return 1;
  const p = 10 ** Math.floor(Math.log10(x));
  const m = x / p;
  return (m <= 1 ? 1 : m <= 2 ? 2 : m <= 2.5 ? 2.5 : m <= 5 ? 5 : 10) * p;
}

const registered = new Set();
function pmtilesSource(url, extra = {}) {
  const abs = new URL(url, location.href).href;
  if (!registered.has(abs)) { protocol.add(new PMTiles(abs)); registered.add(abs); }
  return {type: "vector", url: `pmtiles://${abs}`, ...extra};
}

const statusColor = ["match", ["get", "status"], ...STATUS.flatMap(([v, , c]) => [v, c]), "#94a3b8"];
const coverageColor = ["case", ["==", ["get", "coverage"], null], "#e5e7eb",
  ["step", ["get", "coverage"], COVERAGE_COLORS[0], ...COVERAGE_BREAKS.flatMap((b, i) => [b, COVERAGE_COLORS[i + 1]])]];
const distanceColor = ["step", ["coalesce", ["get", "distance_km"], 0], DISTANCE_COLORS[0], ...DISTANCE_BREAKS.flatMap((b, i) => [b, DISTANCE_COLORS[i + 1]])];
const distanceStateColor = ["case", ["==", ["feature-state", "distance"], null], "rgba(0,0,0,0)",
  ["step", ["feature-state", "distance"], DISTANCE_COLORS[0], ...DISTANCE_BREAKS.flatMap((b, i) => [b, DISTANCE_COLORS[i + 1]])]];
function catchmentRamp(m, stops) {
  if (!m.state) return "rgba(0,0,0,0)";
  return ["case", ["==", ["feature-state", m.state], null], "#eef2f7",
    ["interpolate", ["linear"], ["feature-state", m.state], ...stops.flatMap((v, i) => [v, m.colors[i]])]];
}

/**
 * @param urls {admin, catchments} PMTiles hrefs
 * @param lga  {name, admin1_name, bounds}
 * Returns the container with update(rows, facilityRows), setMetric(key), fit(bounds), and a
 * `value` ({kind: "settlement" | "facility", ...row}) set on click ("input" event).
 */
export function microplanMap({urls, lga, height = 600, basemap = DEFAULT_BASEMAP} = {}) {
  const container = document.createElement("div");
  container.style.cssText = `width:100%;height:${height}px;border-radius:8px;overflow:hidden;position:relative;background:#f8fafc`;
  const empty = {type: "FeatureCollection", features: []};
  const sources = {
    admin: pmtilesSource(urls.admin),
    catchments: pmtilesSource(urls.catchments, {promoteId: {facility_catchments: "id", settlement_catchments: "id"}}),
    settlements: {type: "geojson", data: empty},
    facilities: {type: "geojson", data: empty}
  };
  const layers = [];
  if (basemap) {
    sources.basemap = {type: "raster", tiles: basemap.tiles, tileSize: basemap.tileSize ?? 256, maxzoom: basemap.maxzoom ?? 19, attribution: basemap.attribution ?? ""};
    layers.push({id: "basemap", type: "raster", source: "basemap", paint: {"raster-opacity": basemap.opacity ?? 0.5, "raster-saturation": basemap.saturation ?? 0}});
  }
  const lgaFilter = ["all", ["==", ["get", "name"], lga.name], ["==", ["get", "admin1_name"], lga.admin1_name]];
  layers.push(
    {id: "catchment-fill", type: "fill", source: "catchments", "source-layer": "facility_catchments",
     paint: {"fill-color": catchmentRamp(CATCHMENT_METRICS.progress, CATCHMENT_METRICS.progress.stops()), "fill-opacity": ["case", ["boolean", ["feature-state", "hover"], false], 0.75, 0.55]}},
    {id: "catchment-line", type: "line", source: "catchments", "source-layer": "facility_catchments",
     paint: {"line-color": "#7c3aed", "line-width": ["interpolate", ["linear"], ["zoom"], 8, 0.4, 12, 1.4], "line-opacity": 0.8}},
    // Settlement catchments: boundaries always drawn once zoomed in; filled only for the distance metric.
    {id: "settlement-catchment-fill", type: "fill", source: "catchments", "source-layer": "settlement_catchments", minzoom: 10,
     paint: {"fill-color": "rgba(0,0,0,0)", "fill-opacity": 0.5}},
    {id: "settlement-catchment-line", type: "line", source: "catchments", "source-layer": "settlement_catchments", minzoom: 10,
     paint: {"line-color": "#b45309", "line-width": ["interpolate", ["linear"], ["zoom"], 10, 0.3, 13, 0.9], "line-opacity": 0.6}},
    {id: "lga-line", type: "line", source: "admin", "source-layer": "lgas", filter: lgaFilter,
     paint: {"line-color": "#0f172a", "line-width": 2, "line-dasharray": [3, 2]}},
    {id: "settlement-pt", type: "circle", source: "settlements",
     paint: {"circle-radius": ["interpolate", ["linear"], ["zoom"], 8, 2.2, 11, 4.5, 13, 7],
             "circle-color": statusColor, "circle-opacity": 0.9,
             "circle-stroke-color": "#fff", "circle-stroke-width": ["interpolate", ["linear"], ["zoom"], 8, 0.4, 11, 1]}},
    {id: "settlement-label", type: "symbol", source: "settlements", minzoom: 12,
     layout: {"text-field": ["get", "settlement"], "text-size": 10, "text-font": ["Open Sans Semibold"], "text-offset": [0, 0.9], "text-anchor": "top", "text-optional": true},
     paint: {"text-color": "#475569", "text-halo-color": "#fff", "text-halo-width": 1}},
    {id: "facility-pt", type: "circle", source: "facilities",
     paint: {"circle-radius": ["interpolate", ["linear"], ["zoom"], 8, 3.5, 12, 7], "circle-color": "#1e293b", "circle-stroke-color": "#fff", "circle-stroke-width": 1.5}},
    {id: "facility-label", type: "symbol", source: "facilities", minzoom: 10.5,
     layout: {"text-field": ["get", "facility"], "text-size": 11, "text-font": ["Open Sans Semibold"], "text-offset": [0, 1], "text-anchor": "top", "text-optional": true},
     paint: {"text-color": "#1e293b", "text-halo-color": "#fff", "text-halo-width": 1.2}}
  );

  const fit = lga.bounds;
  const map = new maplibregl.Map({container, style: {version: 8, glyphs: "https://demotiles.maplibre.org/font/{fontstack}/{range}.pbf", sources, layers},
                                  bounds: fit, fitBoundsOptions: {padding: 20}, attributionControl: {compact: true}});
  let fitted = false;
  new ResizeObserver(() => { if (container.clientWidth === 0) return; map.resize(); if (!fitted) { map.fitBounds(fit, {padding: 20, duration: 0}); fitted = true; } }).observe(container);
  map.addControl(new maplibregl.NavigationControl({showCompass: false}), "top-right");
  map.addControl(new maplibregl.FullscreenControl({container}), "top-right");
  map.addControl(new maplibregl.ScaleControl({unit: "metric"}), "bottom-right");

  // Legend
  const legend = document.createElement("div");
  legend.style.cssText = "position:absolute;left:8px;bottom:8px;background:rgba(255,255,255,.92);padding:6px 10px;border-radius:6px;font:12px system-ui;color:#334155;box-shadow:0 1px 3px rgba(0,0,0,.15)";
  container.appendChild(legend);
  const dot = (c) => `<span style="display:inline-block;width:10px;height:10px;border-radius:50%;background:${c};border:1px solid #fff;box-shadow:0 0 0 1px #cbd5e1"></span>`;
  const sw = (c) => `<span style="display:inline-block;width:18px;height:11px;background:${c};border:1px solid #cbd5e1"></span>`;
  function renderLegend(metric, cm, stops) {
    const rows = metric === "status"
      ? STATUS.map(([, l, c]) => `<div style="display:flex;align-items:center;gap:6px;line-height:1.5">${dot(c)}${l}</div>`).join("")
      : metric === "coverage"
        ? `<div style="display:flex;align-items:center;gap:3px">${COVERAGE_BREAKS.map((b, i) => `${sw(COVERAGE_COLORS[i])}<span style="margin-right:4px">${i === 0 ? "<" : ""}${Math.round(b * 100)}%</span>`).join("")}${sw(COVERAGE_COLORS[6])}</div>
           <div style="display:flex;align-items:center;gap:6px;line-height:1.5;margin-top:2px">${dot("#e5e7eb")}not yet visited</div>`
        : `<div style="display:flex;align-items:center;gap:3px">${DISTANCE_BREAKS.map((b, i) => `${sw(DISTANCE_COLORS[i])}<span style="margin-right:4px">${i === 0 ? "<" : ""}${b} km</span>`).join("")}${sw(DISTANCE_COLORS[5])}<span>+</span></div>
           <div class="muted" style="margin-top:2px;color:#64748b">settlement point and (from z10) its catchment</div>`;
    const catchmentRows = cm.state
      ? `<div style="display:flex;align-items:center;gap:3px;margin-top:2px">${stops.map((v, i) => `${sw(cm.colors[i])}<span style="margin-right:4px">${cm.format(v)}</span>`).join("")}</div>`
      : "";
    legend.innerHTML = `<div style="margin-bottom:3px">${METRICS[metric].label}</div>${rows}
      <div style="display:flex;align-items:center;gap:6px;line-height:1.5;margin-top:4px">${dot("#1e293b")}Health facility</div>
      <div style="margin-top:4px">Facility catchment: ${cm.state ? cm.label.toLowerCase() : "boundary only"}</div>${catchmentRows}`;
  }

  // Hover + click
  const popup = new maplibregl.Popup({closeButton: false, closeOnClick: false, offset: 8});
  const fmt = (n) => n == null ? "—" : Number(n).toLocaleString("en");
  const pct = (x) => x == null ? "—" : `${Math.round(x * 100)}%`;
  for (const id of ["settlement-pt", "facility-pt"]) {
    map.on("mousemove", id, (e) => {
      const f = e.features?.[0]; if (!f) return;
      map.getCanvas().style.cursor = "pointer";
      const p = f.properties;
      const body = id === "facility-pt"
        ? `${p.facility_level ?? ""}<br>${p.completed} of ${p.visits} settlements completed · ${fmt(p.treated)} vaccinated of ${fmt(p.u5)} target`
        : `${(STATUS.find(([v]) => v === p.status) ?? [, p.status])[1]}${p.origin === "field-registered" ? " · field-registered" : ""} · day ${p.day_n}<br>` +
          (p.status === "completed" ? `${fmt(p.treated)} vaccinated of ${fmt(p.u5)} target (${pct(p.coverage)})` : `target ${fmt(p.u5)} children 0–59 months`) +
          (p.distance_km != null ? `<br>${Number(p.distance_km).toFixed(1)} km from ${p.facility}` : "");
      popup.setLngLat(e.lngLat).setHTML(`<div style="font:12px system-ui;line-height:1.35"><b>${p.settlement ?? p.facility}</b><br>${body}</div>`).addTo(map);
    });
    map.on("mouseleave", id, () => { map.getCanvas().style.cursor = ""; popup.remove(); });
    map.on("click", id, (e) => {
      const f = e.features?.[0]; if (!f) return;
      container.value = {kind: id === "facility-pt" ? "facility" : "settlement", ...f.properties};
      container.dispatchEvent(new Event("input", {bubbles: true}));
    });
  }
  let hovered = null;
  map.on("mousemove", "catchment-fill", (e) => {
    if (map.queryRenderedFeatures(e.point, {layers: ["settlement-pt", "facility-pt"]}).length) return;
    const f = e.features?.[0]; if (!f) return;
    if (hovered !== null && hovered !== f.id) map.setFeatureState({source: "catchments", sourceLayer: "facility_catchments", id: hovered}, {hover: false});
    hovered = f.id; map.setFeatureState({source: "catchments", sourceLayer: "facility_catchments", id: hovered}, {hover: true});
    const s = facilityStats.get(f.id);
    popup.setLngLat(e.lngLat).setHTML(`<div style="font:12px system-ui;line-height:1.35"><b>${f.properties.name}</b><br>${s ? `${s.completed} of ${s.visits} settlements completed (${pct(s.progress)})<br>${fmt(s.treated)} vaccinated of ${fmt(s.u5)} target<br>WorldPop 2026: ${fmt(s.worldpop)}` : "not in the plan"}</div>`).addTo(map);
  });
  map.on("mouseleave", "catchment-fill", () => { if (hovered !== null) map.setFeatureState({source: "catchments", sourceLayer: "facility_catchments", id: hovered}, {hover: false}); hovered = null; popup.remove(); });

  let ready = false, pending = null, metric = "status", catchmentMetric = "progress";
  let facilityStats = new Map();
  let applied = new Set(), appliedSettlements = new Set();
  function apply() {
    if (!ready || !pending) return;
    const {rows, facilities} = pending;
    map.getSource("settlements").setData({type: "FeatureCollection", features: rows.filter((r) => r.lon != null).map((r) => ({
      type: "Feature", id: r.task_id, properties: r, geometry: {type: "Point", coordinates: [r.lon, r.lat]}}))});
    map.getSource("facilities").setData({type: "FeatureCollection", features: facilities.filter((f) => f.facility_lon != null).map((f) => ({
      type: "Feature", id: f.facility_id, properties: f, geometry: {type: "Point", coordinates: [f.facility_lon, f.facility_lat]}}))});
    for (const id of applied) map.setFeatureState({source: "catchments", sourceLayer: "facility_catchments", id}, {progress: null, u5: null, worldpop: null});
    for (const id of appliedSettlements) map.setFeatureState({source: "catchments", sourceLayer: "settlement_catchments", id}, {distance: null});
    applied = new Set(); appliedSettlements = new Set(); facilityStats = new Map();
    for (const f of facilities) {
      facilityStats.set(f.catchment_id, f);
      map.setFeatureState({source: "catchments", sourceLayer: "facility_catchments", id: f.catchment_id}, {progress: f.progress, u5: f.u5, worldpop: f.worldpop});
      applied.add(f.catchment_id);
    }
    for (const r of rows) {
      if (r.distance_km == null) continue;
      const id = `catchment-${r.settlement_id}`;
      map.setFeatureState({source: "catchments", sourceLayer: "settlement_catchments", id}, {distance: r.distance_km});
      appliedSettlements.add(id);
    }
    applyMetric();
  }
  function applyMetric() {
    if (!ready) return;
    map.setPaintProperty("settlement-pt", "circle-color", metric === "status" ? statusColor : metric === "coverage" ? coverageColor : distanceColor);
    map.setPaintProperty("settlement-catchment-fill", "fill-color", metric === "distance" ? distanceStateColor : "rgba(0,0,0,0)");
    const cm = CATCHMENT_METRICS[catchmentMetric];
    const max = Math.max(0, ...Array.from(facilityStats.values(), (f) => Number(f[cm.state]) || 0));
    const stops = cm.state ? cm.stops(max) : [];
    map.setPaintProperty("catchment-fill", "fill-color", catchmentRamp(cm, stops));
    renderLegend(metric, cm, stops);
  }
  map.on("load", () => {
    for (const el of container.querySelectorAll(".maplibregl-ctrl-attrib")) { el.classList.remove("maplibregl-compact-show"); el.removeAttribute("open"); }
    ready = true; applyMetric(); map.once("idle", apply);
  });
  map.on("sourcedata", (e) => { if (e.sourceId === "catchments" && e.isSourceLoaded && pending) apply(); });
  map.on("mousemove", "settlement-catchment-fill", (e) => {
    if (metric !== "distance" || map.queryRenderedFeatures(e.point, {layers: ["settlement-pt", "facility-pt"]}).length) return;
    const f = e.features?.[0]; if (!f) return;
    const d = f.state?.distance;
    popup.setLngLat(e.lngLat).setHTML(`<div style="font:12px system-ui;line-height:1.35"><b>${f.properties.name}</b><br>${d != null ? `${Number(d).toFixed(1)} km from the facility` : "not in this selection"}</div>`).addTo(map);
  });
  map.on("mouseleave", "settlement-catchment-fill", () => popup.remove());

  container.update = (rows, facilities) => { pending = {rows, facilities}; if (ready && map.isSourceLoaded("catchments")) apply(); };
  container.setMetric = (m) => { metric = METRICS[m] ? m : "status"; applyMetric(); };
  container.setCatchmentMetric = (m) => { catchmentMetric = CATCHMENT_METRICS[m] ? m : "progress"; applyMetric(); };
  container.fit = (b, opts = {}) => { if (container.clientWidth > 0) map.fitBounds(b ?? fit, {padding: 30, duration: 500, maxZoom: 13, ...opts}); };
  container.map = map;
  container.value = null;
  return container;
}
