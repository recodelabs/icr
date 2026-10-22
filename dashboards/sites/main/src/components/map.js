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

// One pmtiles protocol shared by every map on the page (and by georegistry-map.js).
export const protocol = new Protocol();
maplibregl.addProtocol("pmtiles", protocol.tile);
const registered = new WeakSet();

/** Colour ramps per metric: [label, stops(max) → [[value, colour]…]] */
const METRICS = {
  count: {
    label: "Campaign rounds per LGA",
    state: "count",
    // ColorBrewer Purples, 6 classes — lighter at the top than the old blues, so the
    // basemap still reads through the busiest LGAs.
    colors: ["#f2f0f7", "#dadaeb", "#bcbddc", "#9e9ac8", "#756bb1", "#54278f"],
    // Rescales to the selection: 0..max when max is small, else 0, 1 and four evenly spaced
    // integer stops up to the busiest LGA, so one year or one programme still shows contrast.
    stops: (max) => {
      const m = Math.max(1, Math.round(max));
      if (m <= 5) return Array.from({length: m + 1}, (_, i) => i);
      return [0, ...[0, 1, 2, 3, 4].map((k) => Math.round(1 + (k * (m - 1)) / 4))];
    },
    format: (v) => String(v)
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
    // ColorBrewer YlGnBu, the same ramp as the WorldPop population map on the targeting page.
    colors: ["#ffffcc", "#c7e9b4", "#7fcdbb", "#41b6c4", "#2c7fb8", "#253494"],
    stops: (max) => {
      const top = niceCeil(max);
      return [0, top * 0.1, top * 0.25, top * 0.5, top * 0.75, top];
    },
    format: (v) => v >= 1e6 ? `${+(v / 1e6).toFixed(1)}M` : v >= 1e3 ? `${Math.round(v / 1e3)}k` : String(Math.round(v))
  },
  // Denominator metrics (Campaign targeting page): rows carry one value per LGA,
  // read straight from the row rather than accumulated across campaign rounds.
  population: {
    label: "Population per LGA (WorldPop)",
    state: "population",
    field: "worldpop",
    // ColorBrewer YlGnBu, 6 classes.
    colors: ["#ffffcc", "#c7e9b4", "#7fcdbb", "#41b6c4", "#2c7fb8", "#253494"],
    stops: (max) => {
      const top = niceCeil(max);
      return [0, top * 0.1, top * 0.25, top * 0.5, top * 0.75, top];
    },
    format: (v) => v >= 1e6 ? `${+(v / 1e6).toFixed(1)}M` : v >= 1e3 ? `${Math.round(v / 1e3)}k` : String(Math.round(v)),
    popup: (s, fmt) => `WorldPop: ${fmt(s.worldpop)}` + (s.census != null ? `<br>census projection: ${fmt(s.census)}` : "")
  },
  delta: {
    label: "WorldPop vs census projection",
    state: "delta",
    field: "delta_share",
    // Diverging: blue where WorldPop is below the census projection, orange where above; grey at zero.
    colors: ["#2166ac", "#67a9cf", "#d1e5f0", "#f1f1f1", "#fddbc7", "#ef8a62", "#b2182b"],
    stops: (max) => {
      // Symmetric about 0, capped at ±50% so a single outlier does not flatten the ramp.
      const m = Math.min(0.5, Math.max(0.05, niceCeil(max)));
      return [-m, -m * 2 / 3, -m / 3, 0, m / 3, m * 2 / 3, m];
    },
    format: (v, i, arr) => {
      const pct = `${v > 0 ? "+" : ""}${Math.round(v * 100)}%`;
      return i === 0 ? `≤${pct}` : i === arr.length - 1 ? `≥${pct}` : pct;
    },
    popup: (s, fmt) => s.census == null
      ? `WorldPop: ${fmt(s.worldpop)}<br>no census projection for this LGA`
      : `WorldPop: ${fmt(s.worldpop)}<br>census projection: ${fmt(s.census)}<br>difference: ${s.delta > 0 ? "+" : ""}${fmt(s.delta)} (${s.delta_share > 0 ? "+" : ""}${(s.delta_share * 100).toFixed(1)}%)`
  }
};

/** Categorical metrics: a fixed colour per value of a string feature-state. */
export const CATEGORIES = {
  endemicity: {
    label: "Endemicity classification",
    state: "status",
    categorical: true,
    values: [
      ["endemic-under-mda", "Endemic, under MDA", "#c2410c"],
      ["endemic-mda-not-started", "Endemic, MDA not started", "#f97316"],
      ["post-mda-surveillance", "Post-MDA surveillance", "#2563eb"],
      ["elimination-validated", "Elimination validated", "#0f766e"],
      ["non-endemic", "Non-endemic", "#d1d5db"],
      ["unknown", "Unknown (mapping required)", "#fde68a"]
    ]
  }
};

function niceCeil(x) {
  if (!(x > 0)) return 1;
  const p = 10 ** Math.floor(Math.log10(x));
  const m = x / p;
  return (m <= 1 ? 1 : m <= 2 ? 2 : m <= 2.5 ? 2.5 : m <= 5 ? 5 : 10) * p;
}

/** Spread the metric's palette over however many stops the ramp has (fewer stops → skip shades). */
function colorAt(metric, i, n) {
  const last = metric.colors.length - 1;
  return metric.colors[n <= 1 ? last : Math.round((i * last) / (n - 1))];
}

function rampExpression(metric, stops) {
  if (metric.categorical) {
    const match = ["match", ["coalesce", ["feature-state", metric.state], ""]];
    for (const [value, , color] of metric.values) match.push(value, color);
    match.push("#eef2f7");
    return match;
  }
  const ramp = ["interpolate", ["linear"], ["coalesce", ["feature-state", metric.state], 0]];
  stops.forEach((v, i) => ramp.push(v, colorAt(metric, i, stops.length)));
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
  const M = METRICS[metric] ?? CATEGORIES[metric] ?? METRICS.count;

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
     paint: {"fill-color": rampExpression(M, M.categorical ? null : M.stops(1)), "fill-opacity": ["case", ["boolean", ["feature-state", "hover"], false], 0.95, 0.8]}},
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
  function renderLegend(stops, present) {
    if (M.categorical) {
      // Only the classes present in the current rows (all of them before the first update).
      const values = present ? M.values.filter(([v]) => present.has(v)) : M.values;
      legend.innerHTML = `<div style="margin-bottom:4px">${M.label}</div>` + values.map(([, label, color]) =>
        `<div style="display:flex;align-items:center;gap:6px;line-height:1.5"><span style="display:inline-block;width:14px;height:12px;background:${color};border:1px solid #cbd5e1"></span>${label}</div>`).join("");
      return;
    }
    legend.innerHTML = `<div style="margin-bottom:4px">${M.label}</div>
      <div style="display:flex;align-items:center;gap:4px">
        ${stops.map((v, i) => `<span style="display:inline-block;width:22px;height:12px;background:${colorAt(M, i, stops.length)};border:1px solid #cbd5e1"></span><span style="margin-right:6px">${M.format(v, i, stops)}</span>`).join("")}
      </div>`;
  }
  renderLegend(M.categorical ? null : M.stops(1));
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
    const body = !s ? (M.categorical ? "no assertion" : M.popup ? "no estimate in this selection" : "no campaigns in this selection")
      : M.categorical
        ? `${(M.values.find(([v]) => v === s.status) ?? [, s.status ?? "—"])[1]}${s.detail ? `<br>${s.detail}` : ""}`
        : M.popup
          ? M.popup(s, fmt)
          : `${s.count} campaign round${s.count === 1 ? "" : "s"}<br>people targeted: ${fmt(s.targeted)}<br>people reached: ${s.reportedTargeted ? fmt(s.reached) : "no report"}` +
            `${s.coverage != null ? `<br>admin coverage: ${Math.round(s.coverage * 100)}%` : ""}`;
    popup.setLngLat(e.lngLat).setHTML(
      `<div style="font:12px system-ui;line-height:1.35"><b>${f.properties.name}</b> LGA, ${f.properties.admin1_name}<br>${body}</div>`
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
    for (const id of applied) map.setFeatureState({source: "admin", sourceLayer: "lgas", id}, {count: 0, targeted: null, coverage: null, status: null, population: null, delta: null});
    applied = new Set();
    stats = new Map();
    for (const r of rows) {
      const cur = stats.get(r.location_id) ?? {count: 0, targeted: 0, reached: 0, reportedTargeted: 0, name: r.location_name, state: r.state};
      if (r.status != null) cur.status = r.status;
      if (r.detail != null) cur.detail = r.detail;
      // Denominator rows: one per LGA, values read as-is.
      if (r.worldpop != null) cur.worldpop = Number(r.worldpop);
      if (r.census != null) cur.census = Number(r.census);
      if (r.delta != null) cur.delta = Number(r.delta);
      if (r.delta_share != null) cur.delta_share = Number(r.delta_share);
      if (r.rounds != null) cur.count += Number(r.rounds) - 1;  // pre-aggregated rows
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
      map.setFeatureState({source: "admin", sourceLayer: "lgas", id}, {count: s.count, targeted: s.targeted, coverage: s.coverage, status: s.status ?? null,
        population: s.worldpop ?? null, delta: s.delta_share ?? null});
      applied.add(id);
    }
    if (M.categorical) { renderLegend(null, new Set(Array.from(stats.values(), (s) => s.status).filter((v) => v != null))); return; }
    // Rescale the ramp to the selection (matters for people targeted); diverging ramps use the largest magnitude.
    const stateValue = (s) => M.field ? s[M.field] : s[M.state];
    const max = Math.max(0, ...Array.from(stats.values(), (s) => Math.abs(stateValue(s) ?? 0)));
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
