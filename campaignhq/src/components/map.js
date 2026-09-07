// LGA choropleth of campaign counts on MapLibre, boundaries from a PMTiles
// archive that is loaded fully into memory (no HTTP range requests needed, so
// it works from any static host and from the Framework preview server).
import maplibregl from "npm:maplibre-gl@5";
import {PMTiles, Protocol} from "npm:pmtiles@4";

/** A pmtiles Source over an ArrayBuffer already in memory. */
class BufferSource {
  constructor(buffer, key) {
    this.buffer = buffer;
    this.key = key;
  }
  getKey() {
    return this.key;
  }
  async getBytes(offset, length) {
    return {data: this.buffer.slice(offset, offset + length)};
  }
}

export const DEFAULT_BASEMAP = {
  // Placeholder only — swap for your own tile layer or style URL.
  tiles: ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],
  attribution: "© OpenStreetMap contributors",
  opacity: 0.45,
  saturation: -0.9
};

// One pmtiles protocol shared by every map on the page.
const protocol = new Protocol();
maplibregl.addProtocol("pmtiles", protocol.tile);
const registered = new WeakSet();

/** Colour ramps per metric: [label, stops(max) → [[value, colour]…]] */
const METRICS = {
  count: {
    label: "Campaign rounds per LGA",
    state: "count",
    colors: ["#eef2f7", "#c7dbef", "#8fbfe0", "#4a90c4", "#1f5fa3", "#0b3b7a"],
    stops: () => [0, 1, 3, 6, 10, 18],
    format: (v, i, arr) => i === arr.length - 1 ? `${v}+` : String(v)
  },
  coverage: {
    label: "Administrative coverage per LGA",
    state: "coverage",
    colors: ["#fde0dd", "#fcc5c0", "#fa9fb5", "#c7e9c0", "#74c476", "#238b45"],
    stops: () => [0.5, 0.65, 0.8, 0.9, 0.95, 1.05],
    format: (v, i, arr) => (i === 0 ? `<${Math.round(v * 100)}%` : i === arr.length - 1 ? `${Math.round(v * 100)}%+` : `${Math.round(v * 100)}%`)
  },
  targeted: {
    label: "People targeted per LGA",
    state: "targeted",
    colors: ["#fff5eb", "#fdd0a2", "#fdae6b", "#f16913", "#d94801", "#7f2704"],
    stops: (max) => {
      const top = niceCeil(max);
      return [0, top * 0.1, top * 0.25, top * 0.5, top * 0.75, top];
    },
    format: (v) => v >= 1e6 ? `${+(v / 1e6).toFixed(1)}M` : v >= 1e3 ? `${Math.round(v / 1e3)}k` : String(Math.round(v))
  }
};

function niceCeil(x) {
  if (!(x > 0)) return 1;
  const p = 10 ** Math.floor(Math.log10(x));
  const m = x / p;
  return (m <= 1 ? 1 : m <= 2 ? 2 : m <= 2.5 ? 2.5 : m <= 5 ? 5 : 10) * p;
}

function rampExpression(metric, stops) {
  const ramp = ["interpolate", ["linear"], ["coalesce", ["feature-state", metric.state], 0]];
  stops.forEach((v, i) => ramp.push(v, metric.colors[i]));
  // No value (null feature-state) → neutral grey rather than the bottom of the ramp.
  return ["case", ["==", ["feature-state", metric.state], null], "#e5e7eb", ramp];
}

/** Keep two maps' viewports in lockstep. */
export function syncMaps(a, b) {
  let lock = false;
  const follow = (from, to) => () => {
    if (lock) return;
    lock = true;
    to.jumpTo({center: from.getCenter(), zoom: from.getZoom(), bearing: from.getBearing(), pitch: from.getPitch()});
    lock = false;
  };
  a.map.on("move", follow(a.map, b.map));
  b.map.on("move", follow(b.map, a.map));
}

/**
 * Build the map. Returns a container element with an `update(rows)` method:
 * rows are LGA-level campaign rows (location_id, location_name, state, targeted).
 */
/**
 * `basemap` is one of:
 *   - false                      no basemap (boundaries on a plain background)
 *   - {tiles: [urlTemplate], attribution, tileSize?, maxzoom?, opacity?, saturation?}
 *                                a raster XYZ layer under the boundaries
 *   - "https://…/style.json"     a full MapLibre vector style; the boundary layers are
 *                                added on top once it loads
 */
export function campaignMap({pmtiles, bounds, height = 520, basemap = DEFAULT_BASEMAP, labels = [], metric = "count"} = {}) {
  const container = document.createElement("div");
  container.style.cssText = `width:100%;height:${height}px;border-radius:8px;overflow:hidden;position:relative;background:#f8fafc`;
  const M = METRICS[metric] ?? METRICS.count;

  if (!registered.has(pmtiles)) {
    protocol.add(new PMTiles(new BufferSource(pmtiles, "admin")));
    registered.add(pmtiles);
  }

  const sources = {
    admin: {type: "vector", url: "pmtiles://admin", promoteId: {lgas: "id", states: "id"}},
    // Label anchors as points (one per state) so names are not repeated per tile.
    labels: {type: "geojson", data: {type: "FeatureCollection", features: labels.map((d) => ({
      type: "Feature", id: d.id, properties: {name: d.name}, geometry: {type: "Point", coordinates: [d.lon, d.lat]}}))}}
  };
  const layers = [];
  const styleUrl = typeof basemap === "string" ? basemap : null;
  if (basemap && !styleUrl) {
    sources.basemap = {
      type: "raster",
      tiles: basemap.tiles,
      tileSize: basemap.tileSize ?? 256,
      maxzoom: basemap.maxzoom ?? 19,
      attribution: basemap.attribution ?? ""
    };
    // Muted so the choropleth reads on top; boundaries still render if the tiles do not load.
    layers.push({id: "basemap", type: "raster", source: "basemap",
                 paint: {"raster-opacity": basemap.opacity ?? 0.5, "raster-saturation": basemap.saturation ?? 0}});
  }
  layers.push(
    {id: "lga-fill", type: "fill", source: "admin", "source-layer": "lgas",
     paint: {"fill-color": rampExpression(M, M.stops(1)), "fill-opacity": ["case", ["boolean", ["feature-state", "hover"], false], 0.95, 0.8]}},
    {id: "lga-line", type: "line", source: "admin", "source-layer": "lgas",
     paint: {"line-color": "#94a3b8", "line-width": 0.4}},
    {id: "state-line", type: "line", source: "admin", "source-layer": "states",
     paint: {"line-color": "#334155", "line-width": 1.2}},
    {id: "state-label", type: "symbol", source: "labels",
     layout: {"text-field": ["get", "name"], "text-size": 12, "text-font": ["Open Sans Semibold"], "text-allow-overlap": false},
     paint: {"text-color": "#1e293b", "text-halo-color": "#ffffff", "text-halo-width": 1.5}}
  );

  const ownStyle = {version: 8, glyphs: "https://demotiles.maplibre.org/font/{fontstack}/{range}.pbf", sources, layers};
  const fit = bounds ?? [[7.4, 8.8], [13.9, 13.9]];
  const map = new maplibregl.Map({
    container,
    style: styleUrl ?? ownStyle,
    bounds: fit,
    fitBoundsOptions: {padding: 20},
    attributionControl: {compact: true}
  });
  // The element is created before it is in the DOM (width 0), so resize + refit
  // once it is laid out, and again whenever the card changes width.
  let fitted = false;
  new ResizeObserver(() => {
    if (container.clientWidth === 0) return;
    map.resize();
    if (!fitted) { map.fitBounds(fit, {padding: 20, duration: 0}); fitted = true; }
  }).observe(container);
  map.addControl(new maplibregl.NavigationControl({showCompass: false}), "top-right");
  map.scrollZoom.disable();

  // Legend
  const legend = document.createElement("div");
  legend.style.cssText = "position:absolute;left:8px;bottom:8px;background:rgba(255,255,255,.92);padding:6px 10px;border-radius:6px;font:12px system-ui;color:#334155;box-shadow:0 1px 3px rgba(0,0,0,.15)";
  function renderLegend(stops) {
    legend.innerHTML = `<div style="margin-bottom:4px">${M.label}</div>
      <div style="display:flex;align-items:center;gap:4px">
        ${stops.map((v, i) => `<span style="display:inline-block;width:22px;height:12px;background:${M.colors[i]};border:1px solid #cbd5e1"></span><span style="margin-right:6px">${M.format(v, i, stops)}</span>`).join("")}
      </div>`;
  }
  renderLegend(M.stops(1));
  container.appendChild(legend);

  // Hover popup
  const popup = new maplibregl.Popup({closeButton: false, closeOnClick: false, offset: 8});
  let hovered = null;
  let stats = new Map(); // location_id -> {count, targeted, name, state}
  map.on("mousemove", "lga-fill", (e) => {
    const f = e.features?.[0];
    if (!f) return;
    map.getCanvas().style.cursor = "pointer";
    if (hovered !== null && hovered !== f.id) map.setFeatureState({source: "admin", sourceLayer: "lgas", id: hovered}, {hover: false});
    hovered = f.id;
    map.setFeatureState({source: "admin", sourceLayer: "lgas", id: hovered}, {hover: true});
    const s = stats.get(f.id);
    const fmt = (n) => n == null ? "—" : Number(n).toLocaleString("en");
    popup.setLngLat(e.lngLat).setHTML(
      `<div style="font:12px system-ui;line-height:1.35"><b>${f.properties.name}</b> LGA, ${f.properties.admin1_name}<br>` +
      `${s ? `${s.count} campaign round${s.count === 1 ? "" : "s"}<br>people targeted: ${fmt(s.targeted)}<br>people reached: ${s.reportedTargeted ? fmt(s.reached) : "no report"}` +
        `${s.coverage != null ? `<br>admin coverage: ${Math.round(s.coverage * 100)}%` : ""}` : "no campaigns in this selection"}</div>`
    ).addTo(map);
  });
  map.on("mouseleave", "lga-fill", () => {
    map.getCanvas().style.cursor = "";
    if (hovered !== null) map.setFeatureState({source: "admin", sourceLayer: "lgas", id: hovered}, {hover: false});
    hovered = null;
    popup.remove();
  });

  let ready = false;
  let pending = null;
  let applied = new Set();
  function apply(rows) {
    // Clear previous counts, then set the new ones.
    for (const id of applied) map.setFeatureState({source: "admin", sourceLayer: "lgas", id}, {count: 0, targeted: null, coverage: null});
    applied = new Set();
    stats = new Map();
    for (const r of rows) {
      const cur = stats.get(r.location_id) ?? {count: 0, targeted: 0, reached: 0, reportedTargeted: 0, name: r.location_name, state: r.state};
      cur.count += 1;
      cur.targeted += Number(r.targeted ?? 0);
      if (r.reached != null && r.targeted) {
        cur.reached += Number(r.reached);
        cur.reportedTargeted += Number(r.targeted);
      }
      stats.set(r.location_id, cur);
    }
    for (const [id, s] of stats) {
      s.coverage = s.reportedTargeted > 0 ? s.reached / s.reportedTargeted : null;
      map.setFeatureState({source: "admin", sourceLayer: "lgas", id}, {count: s.count, targeted: s.targeted, coverage: s.coverage});
      applied.add(id);
    }
    // Rescale the ramp to the selection (matters for people targeted).
    const max = Math.max(0, ...Array.from(stats.values(), (s) => s[M.state] ?? 0));
    const stops = M.stops(max);
    if (map.getLayer("lga-fill")) map.setPaintProperty("lga-fill", "fill-color", rampExpression(M, stops));
    renderLegend(stops);
  }
  map.on("load", () => {
    // Start with the attribution collapsed to its "i" button (it opens expanded on wide maps).
    for (const el of container.querySelectorAll(".maplibregl-ctrl-attrib")) {
      el.classList.remove("maplibregl-compact-show");
      el.removeAttribute("open");
    }
    if (styleUrl) {
      // Vector-style basemap: add our sources and layers on top of it.
      map.addSource("admin", sources.admin);
      map.addSource("labels", sources.labels);
      for (const l of layers) map.addLayer(l);
    }
    ready = true;
    // feature-state needs the source's tiles to be known; apply once idle.
    map.once("idle", () => { if (pending) apply(pending); });
  });
  // Tiles for other zooms load lazily; re-apply state when new tiles arrive.
  map.on("sourcedata", (e) => { if (e.sourceId === "admin" && e.isSourceLoaded && pending) apply(pending); });

  container.update = (rows) => {
    pending = rows;
    if (ready && map.isSourceLoaded("admin")) apply(rows);
  };
  container.map = map;
  return container;
}
