// A choropleth of Nigeria's LGAs (GRID3, admin.geojson) for one campaign: LGAs with a value are
// shaded in quantile classes, the other LGAs are outlined only, with state borders on top. The LGAs
// DIGIT has keep the georegistry map's darker border. DIGIT itself holds no geometry; values are
// attributed to GRID3 LGAs through DIGIT's partOf hierarchy (see data/lga_visits.parquet.sh).
import maplibregl from "npm:maplibre-gl@5";

const SHADES = ["#eff3ff", "#bdd7e7", "#6baed6", "#3182bd", "#08519c"];
const BASEMAP = {tiles: ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"], attribution: "© OpenStreetMap contributors"};
const LGA = ["==", ["get", "kind"], "lga"], STATE = ["==", ["get", "kind"], "state"];
const IN_DIGIT = ["==", ["get", "in_digit"], true];

/**
 * @param admin  GeoJSON FeatureCollection (properties id, name, kind state|lga, state, pcode, in_digit)
 * Returns the container, with setValues(Map GRID3 id → number, label) to shade and describe the
 * LGAs, fitTo(ids) to zoom to some units (all of Nigeria when empty), and a `value` (the clicked
 * LGA's properties and value) updated and an "input" event dispatched on click.
 */
export function lgaMap(admin, {height = 520} = {}) {
  const container = document.createElement("div");
  container.style.cssText = `width:100%;height:${height}px;border-radius:8px;overflow:hidden;position:relative;background:#f8fafc`;
  const byId = new Map(admin.features.map((f) => [f.properties.id, f]));
  const all = boundsOf(admin.features);
  const map = new maplibregl.Map({
    container,
    style: {
      version: 8,
      sources: {
        basemap: {type: "raster", tiles: BASEMAP.tiles, tileSize: 256, maxzoom: 19, attribution: BASEMAP.attribution},
        admin: {type: "geojson", data: admin}
      },
      layers: [
        {id: "basemap", type: "raster", source: "basemap", paint: {"raster-opacity": 0.45, "raster-saturation": -0.9}},
        {id: "lga-fill", type: "fill", source: "admin", filter: LGA, paint: {"fill-color": "#ffffff", "fill-opacity": 0.01}},
        {id: "lga-line", type: "line", source: "admin", filter: ["all", LGA, ["!", IN_DIGIT]],
         paint: {"line-color": "#cbd5e1", "line-width": ["interpolate", ["linear"], ["zoom"], 5, 0.3, 10, 0.8]}},
        {id: "lga-digit-line", type: "line", source: "admin", filter: ["all", LGA, IN_DIGIT],
         paint: {"line-color": "#334155", "line-width": ["interpolate", ["linear"], ["zoom"], 5, 0.9, 10, 1.8]}},
        {id: "state-line", type: "line", source: "admin", filter: STATE,
         paint: {"line-color": "#64748b", "line-width": ["interpolate", ["linear"], ["zoom"], 5, 1, 10, 2.2]}}
      ]
    },
    bounds: all, fitBoundsOptions: {padding: 24},
    attributionControl: {compact: true}
  });
  let pending = null, loaded = false;
  new ResizeObserver(() => { if (container.clientWidth) map.resize(); }).observe(container);
  map.addControl(new maplibregl.NavigationControl({showCompass: false}), "top-right");
  map.addControl(new maplibregl.FullscreenControl({container}), "top-right");
  map.addControl(new maplibregl.ScaleControl({unit: "metric"}), "bottom-right");

  let values = new Map(), label = "";
  const fmt = (n) => (n ?? 0).toLocaleString("en");
  const popup = new maplibregl.Popup({closeButton: false, closeOnClick: false, offset: 8});
  let hovered = null;
  const unhover = () => { if (hovered != null) map.setFeatureState({source: "admin", id: hovered}, {hover: false}); hovered = null; };
  map.on("mousemove", "lga-fill", (e) => {
    const f = e.features?.[0]; if (!f) return;
    if (hovered !== f.id) { unhover(); hovered = f.id; map.setFeatureState({source: "admin", id: f.id}, {hover: true}); }
    const p = f.properties;
    popup.setLngLat(e.lngLat).setHTML(`<div style="font:12px system-ui;line-height:1.35"><b>${escape(p.name)}</b> · LGA, ${escape(p.state ?? "")}<br>P-code ${escape(p.pcode ?? "—")}<br>${values.has(p.id) ? `${fmt(values.get(p.id))} ${escape(label)}` : `<span style="color:#64748b">no ${escape(label)} in this campaign${p.in_digit ? "" : " · not in DIGIT"}</span>`}</div>`).addTo(map);
  });
  map.on("mouseleave", "lga-fill", () => { unhover(); popup.remove(); });
  map.on("click", "lga-fill", (e) => {
    const f = e.features?.[0]; if (!f) return;
    container.value = {...f.properties, measure: label, count: values.get(f.properties.id) ?? 0};
    container.dispatchEvent(new Event("input", {bubbles: true}));
  });

  const legend = document.createElement("div");
  legend.style.cssText = "position:absolute;left:8px;bottom:8px;background:rgba(255,255,255,.92);padding:6px 10px;border-radius:6px;font:12px system-ui;color:#334155;box-shadow:0 1px 3px rgba(0,0,0,.15)";
  container.appendChild(legend);

  const apply = () => {
    const v = [...values.values()].filter((x) => x > 0).sort((a, b) => a - b);
    const breaks = v.length ? [...new Set([0.2, 0.4, 0.6, 0.8].map((q) => v[Math.floor(q * (v.length - 1))]))].filter((b) => b > 1) : [];
    const ids = [...values.keys()];
    // A step expression needs at least one stop; with a single class the colour is constant.
    const stepped = breaks.length ? ["step", ["coalesce", ["get", "value"], 0], SHADES[0], ...breaks.flatMap((b, i) => [b, SHADES[i + 1]])] : SHADES[2];
    // The values ride on the features, so the fill can step on them.
    for (const f of admin.features) f.properties.value = values.get(f.properties.id) ?? null;
    map.getSource("admin").setData(admin);
    map.setPaintProperty("lga-fill", "fill-color", ["case", ["in", ["get", "id"], ["literal", ids]], stepped, "#ffffff"]);
    map.setPaintProperty("lga-fill", "fill-opacity", ["case", ["in", ["get", "id"], ["literal", ids]],
      ["case", ["boolean", ["feature-state", "hover"], false], 0.95, 0.8], ["case", ["boolean", ["feature-state", "hover"], false], 0.3, 0.01]]);
    const edges = [1, ...breaks];
    legend.innerHTML = ids.length
      ? `<div>LGAs by ${escape(label)}</div>` + edges.map((b, i) => `<div style="display:flex;align-items:center;gap:6px;line-height:1.5"><span style="display:inline-block;width:12px;height:10px;background:${breaks.length ? SHADES[i] : SHADES[2]}"></span>${fmt(b)}${i < edges.length - 1 ? `–${fmt(edges[i + 1] - 1)}` : "+"}</div>`).join("") +
        `<div style="display:flex;align-items:center;gap:6px;line-height:1.5"><span style="display:inline-block;width:12px;height:10px;background:#fff;border:1px solid #cbd5e1"></span>none</div>` +
        `<div style="display:flex;align-items:center;gap:6px;line-height:1.5"><span style="display:inline-block;width:12px;height:10px;border:2px solid #334155"></span>LGA in DIGIT</div>`
      : `<span style="color:#64748b">No ${escape(label)} on the map</span>`;
  };
  map.on("load", () => { loaded = true; if (pending) { pending(); pending = null; } });
  const whenLoaded = (fn) => { if (loaded) fn(); else pending = fn; };
  container.setValues = (m, l) => { values = m; label = l; whenLoaded(apply); };
  container.fitTo = (ids) => {
    const fs = (ids ?? []).map((id) => byId.get(id)).filter(Boolean);
    const b = fs.length ? boundsOf(fs) : all;
    whenLoaded(() => map.fitBounds(b, {padding: 40, duration: 0, maxZoom: 9}));
  };
  container.map = map;
  container.value = null;
  return container;
}

function boundsOf(features) {
  let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
  const walk = (c) => { if (typeof c[0] === "number") { x0 = Math.min(x0, c[0]); x1 = Math.max(x1, c[0]); y0 = Math.min(y0, c[1]); y1 = Math.max(y1, c[1]); } else c.forEach(walk); };
  for (const f of features) if (f.geometry) walk(f.geometry.coordinates);
  return isFinite(x0) ? [[x0, y0], [x1, y1]] : [[2.6, 4.2], [14.7, 13.9]];
}
function escape(s) { return String(s ?? "").replace(/[&<>"]/g, (c) => ({"&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;"})[c]); }
