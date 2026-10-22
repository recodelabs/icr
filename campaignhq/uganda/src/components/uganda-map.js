// Uganda map on MapLibre: districts and cities, regions and the country from the boundary
// tiles fhir-pipes builds (admin.pmtiles, loaded whole into memory, so it works from any
// static host). fhir-pipes names the tile layers the Nigerian way: `states` holds Uganda's
// regions and `lgas` its districts and cities.
//
// One component for two uses:
//   - a choropleth: setValues(Map(location id → number), {thresholds, colors, label, format, describe})
//   - the georegistry: no values, districts outlined; click a district to inspect it.
// Both: setRegion(name or null) to show one region, fit(bounds), and `value` + an "input" event
// with the clicked district's tile properties.
import maplibregl from "npm:maplibre-gl@5";
import {PMTiles, Protocol} from "npm:pmtiles@4";

class BufferSource {
  constructor(buffer, key) { this.buffer = buffer; this.key = key; }
  getKey() { return this.key; }
  async getBytes(offset, length) { return {data: this.buffer.slice(offset, offset + length)}; }
}

const protocol = new Protocol();
maplibregl.addProtocol("pmtiles", protocol.tile);
const registered = new WeakSet();

export const UGANDA_BOUNDS = [[29.5, -1.5], [35.1, 4.3]];

const BASEMAP = {tiles: ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"], attribution: "© OpenStreetMap contributors"};
const NO_VALUE = "#e5e7eb";

export function ugandaMap({pmtiles, labels = [], height = 520, choropleth = true} = {}) {
  const container = document.createElement("div");
  container.style.cssText = `width:100%;height:${height}px;border-radius:8px;overflow:hidden;position:relative;background:#f8fafc`;
  if (!registered.has(pmtiles)) { protocol.add(new PMTiles(new BufferSource(pmtiles, "uga-admin"))); registered.add(pmtiles); }

  const sources = {
    basemap: {type: "raster", tiles: BASEMAP.tiles, tileSize: 256, maxzoom: 19, attribution: BASEMAP.attribution},
    admin: {type: "vector", url: "pmtiles://uga-admin", promoteId: {lgas: "id", states: "id"}},
    labels: {type: "geojson", data: {type: "FeatureCollection", features: labels.map((d) => ({
      type: "Feature", id: d.id, properties: {name: d.name}, geometry: {type: "Point", coordinates: [d.lon, d.lat]}}))}}
  };
  const layers = [
    {id: "basemap", type: "raster", source: "basemap", paint: {"raster-opacity": 0.45, "raster-saturation": -0.9}},
    {id: "district-fill", type: "fill", source: "admin", "source-layer": "lgas",
     paint: choropleth
       ? {"fill-color": NO_VALUE, "fill-opacity": ["case", ["boolean", ["feature-state", "hover"], false], 0.95, 0.8]}
       : {"fill-color": "#93c5fd", "fill-opacity": ["case", ["boolean", ["feature-state", "selected"], false], 0.55, ["boolean", ["feature-state", "hover"], false], 0.35, 0.08]}},
    {id: "district-line", type: "line", source: "admin", "source-layer": "lgas", paint: {"line-color": "#94a3b8", "line-width": 0.5}},
    {id: "region-line", type: "line", source: "admin", "source-layer": "states", paint: {"line-color": "#334155", "line-width": 1.3}},
    {id: "country-line", type: "line", source: "admin", "source-layer": "country", paint: {"line-color": "#0f172a", "line-width": 2, "line-dasharray": [3, 2]}},
    {id: "region-label", type: "symbol", source: "labels",
     layout: {"text-field": ["get", "name"], "text-size": 12, "text-font": ["Open Sans Semibold"], "text-allow-overlap": false},
     paint: {"text-color": "#1e293b", "text-halo-color": "#fff", "text-halo-width": 1.5}}
  ];
  const map = new maplibregl.Map({
    container,
    style: {version: 8, glyphs: "https://demotiles.maplibre.org/font/{fontstack}/{range}.pbf", sources, layers},
    bounds: UGANDA_BOUNDS, fitBoundsOptions: {padding: 16}, attributionControl: {compact: true}
  });
  let fitted = false;
  new ResizeObserver(() => {
    if (container.clientWidth === 0) return;
    map.resize();
    if (!fitted) { map.fitBounds(UGANDA_BOUNDS, {padding: 16, duration: 0}); fitted = true; }
  }).observe(container);
  map.addControl(new maplibregl.NavigationControl({showCompass: false}), "top-right");
  map.scrollZoom.disable();

  const legend = document.createElement("div");
  legend.style.cssText = "position:absolute;left:8px;bottom:8px;background:rgba(255,255,255,.94);padding:6px 10px;border-radius:6px;font:12px system-ui;color:#334155;box-shadow:0 1px 3px rgba(0,0,0,.15);max-width:calc(100% - 16px)";
  legend.style.display = "none";
  container.appendChild(legend);

  let values = new Map(), opts = {}, ready = false, pending = null, region = null, selectedId = null;
  const popup = new maplibregl.Popup({closeButton: false, closeOnClick: false, offset: 8});
  let hovered = null;
  const setState = (id, s) => map.setFeatureState({source: "admin", sourceLayer: "lgas", id}, s);

  map.on("mousemove", "district-fill", (e) => {
    const f = e.features?.[0]; if (!f) return;
    map.getCanvas().style.cursor = "pointer";
    if (hovered !== null && hovered !== f.id) setState(hovered, {hover: false});
    hovered = f.id; setState(hovered, {hover: true});
    const v = values.get(f.id);
    const body = opts.describe ? opts.describe(f.id, v)
      : choropleth ? (v == null ? "no value" : `${opts.label ?? ""}: ${(opts.format ?? String)(v)}`)
      : `<span style="color:#64748b">click to inspect</span>`;
    popup.setLngLat(e.lngLat).setHTML(`<div style="font:12px system-ui;line-height:1.4"><b>${f.properties.name}</b>, ${f.properties.admin1_name ?? ""}<br>${body}</div>`).addTo(map);
  });
  map.on("mouseleave", "district-fill", () => {
    map.getCanvas().style.cursor = "";
    if (hovered !== null) setState(hovered, {hover: false});
    hovered = null; popup.remove();
  });
  map.on("click", "district-fill", (e) => {
    const f = e.features?.[0]; if (!f) return;
    if (!choropleth) {
      if (selectedId !== null) setState(selectedId, {selected: false});
      selectedId = f.id; setState(selectedId, {selected: true});
    }
    container.value = {id: f.id, properties: f.properties};
    container.dispatchEvent(new Event("input", {bubbles: true}));
  });

  function renderLegend() {
    if (!choropleth || !opts.colors) { legend.style.display = "none"; return; }
    const t = opts.thresholds, c = opts.colors, f = opts.legendFormat ?? opts.format ?? String;
    const items = c.map((color, i) => {
      const text = i === 0 ? `< ${f(t[0])}` : i === c.length - 1 ? `≥ ${f(t[i - 1])}` : `${f(t[i - 1])}–${f(t[i])}`;
      return `<div style="display:flex;align-items:center;gap:6px;line-height:1.5"><span style="display:inline-block;width:14px;height:11px;background:${color};border:1px solid #cbd5e1"></span>${text}</div>`;
    }).join("");
    legend.innerHTML = `<div style="margin-bottom:3px;font-weight:500">${opts.label ?? ""}</div>${items}`
      + `<div style="display:flex;align-items:center;gap:6px;line-height:1.5"><span style="display:inline-block;width:14px;height:11px;background:${NO_VALUE};border:1px solid #cbd5e1"></span>no value</div>`;
    legend.style.display = "";
  }

  function apply() {
    if (!ready) return;
    if (choropleth && opts.colors) {
      const step = ["step", ["feature-state", "v"], opts.colors[0]];
      opts.thresholds.forEach((t, i) => step.push(t, opts.colors[i + 1]));
      map.setPaintProperty("district-fill", "fill-color", ["case", ["==", ["feature-state", "v"], null], NO_VALUE, step]);
      for (const f of map.querySourceFeatures("admin", {sourceLayer: "lgas"})) setState(f.id, {v: values.get(f.id) ?? null});
    }
    const regionFilter = region ? ["==", ["get", "admin1_name"], region] : null;
    for (const id of ["district-fill", "district-line"]) map.setFilter(id, regionFilter);
    map.setFilter("region-line", region ? ["==", ["get", "name"], region] : null);
    map.setFilter("region-label", region ? ["==", ["get", "name"], region] : null);
    renderLegend();
  }
  map.on("load", () => {
    for (const el of container.querySelectorAll(".maplibregl-ctrl-attrib")) { el.classList.remove("maplibregl-compact-show"); el.removeAttribute("open"); }
    ready = true; apply();
  });
  // Feature-state is per loaded tile; set the values again whenever new tiles arrive.
  map.on("sourcedata", (e) => { if (ready && e.sourceId === "admin" && e.isSourceLoaded && choropleth && opts.colors) apply(); });

  container.setValues = (v, o) => { values = v; opts = o ?? {}; apply(); };
  container.setRegion = (r) => { region = r; apply(); };
  container.fit = (b) => { if (container.clientWidth > 0) map.fitBounds(b ?? UGANDA_BOUNDS, {padding: 24, duration: 500}); };
  container.map = map;
  container.value = null;
  return container;
}

/** Five quantile class breaks (rounded) for a set of values. */
export function quantileBreaks(values, n = 6) {
  const v = values.filter((x) => x != null && Number.isFinite(x)).sort((a, b) => a - b);
  if (!v.length) return [];
  const q = (p) => v[Math.min(v.length - 1, Math.floor(p * v.length))];
  const nice = (x) => { if (x <= 0) return 0; const p = 10 ** Math.floor(Math.log10(x)); return Math.round(x / p * 2) / 2 * p; };
  return [...new Set(Array.from({length: n - 1}, (_, i) => nice(q((i + 1) / n))))];
}

// Sequential (one hue, light → dark) and diverging (two hues, grey middle) palettes.
export const BLUES = ["#eff6ff", "#c6dbef", "#9ecae1", "#6baed6", "#3182bd", "#08519c"];
export const DIVERGING = ["#8c510a", "#d8b365", "#f6e8c3", "#f2f2f2", "#c7eae5", "#5ab4ac", "#01665e"];
