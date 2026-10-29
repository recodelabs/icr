// Stock by place, on Nigeria's states and LGAs from GRID3 (admin.geojson): for each LGA (or state,
// for state stores), three circles side by side, sized by the number of movements: dispatched
// from it, received in it, and dispatched from it but not yet received. DIGIT itself holds no
// geometry and almost no facility has coordinates, so a facility is placed in its LGA, or its
// state, through DIGIT's partOf hierarchy (see data/stock.parquet.sh). LGAs DIGIT has keep the
// darker border used on the other maps.
import maplibregl from "npm:maplibre-gl@5";

export const STATES = [
  ["dispatched", "Dispatched", "#2563eb"],
  ["received", "Received", "#16a34a"],
  ["pending", "Dispatched, not yet received", "#ea580c"]
];
const OFFSET = {dispatched: -1, received: 0, pending: 1};
const BASEMAP = {tiles: ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"], attribution: "© OpenStreetMap contributors"};
const LGA = ["==", ["get", "kind"], "lga"], STATE = ["==", ["get", "kind"], "state"];
const IN_DIGIT = ["==", ["get", "in_digit"], true];

/**
 * @param admin  GeoJSON FeatureCollection (properties id, name, kind state|lga, state, pcode, in_digit)
 * Returns the container, with setData(rows) — rows [{unit_id, state, movements, quantity, products}],
 * unit_id the GRID3 id of an LGA or a state —
 * where products is [{product, unit, quantity}] — setStates(Set) and a `value` (the clicked LGA's
 * figures) updated and an "input" event dispatched on click.
 */
export function stockMap(admin, {height = 540} = {}) {
  const container = document.createElement("div");
  container.style.cssText = `width:100%;height:${height}px;border-radius:8px;overflow:hidden;position:relative;background:#f8fafc`;
  const lgas = new Map(admin.features.map((f) => [f.properties.id, f]));
  const centre = new Map([...lgas].map(([id, f]) => [id, centreOf(f)]));
  const all = boundsOf(admin.features);
  const map = new maplibregl.Map({
    container,
    style: {
      version: 8,
      sources: {
        basemap: {type: "raster", tiles: BASEMAP.tiles, tileSize: 256, maxzoom: 19, attribution: BASEMAP.attribution},
        admin: {type: "geojson", data: admin},
        stock: {type: "geojson", data: {type: "FeatureCollection", features: []}}
      },
      layers: [
        {id: "basemap", type: "raster", source: "basemap", paint: {"raster-opacity": 0.45, "raster-saturation": -0.9}},
        {id: "lga-fill", type: "fill", source: "admin", filter: LGA, paint: {"fill-color": ["case", IN_DIGIT, "#94a3b8", "#ffffff"], "fill-opacity": ["case", IN_DIGIT, 0.15, 0.01]}},
        {id: "lga-line", type: "line", source: "admin", filter: ["all", LGA, ["!", IN_DIGIT]],
         paint: {"line-color": "#cbd5e1", "line-width": ["interpolate", ["linear"], ["zoom"], 5, 0.3, 10, 0.8]}},
        {id: "lga-digit-line", type: "line", source: "admin", filter: ["all", LGA, IN_DIGIT],
         paint: {"line-color": "#334155", "line-width": ["interpolate", ["linear"], ["zoom"], 5, 0.9, 10, 1.8]}},
        {id: "state-line", type: "line", source: "admin", filter: STATE,
         paint: {"line-color": "#64748b", "line-width": ["interpolate", ["linear"], ["zoom"], 5, 1, 10, 2.2]}},
        ...STATES.map(([state, , colour]) => ({
          id: `stock-${state}`, type: "circle", source: "stock", filter: ["==", ["get", "state"], state],
          paint: {"circle-radius": ["get", "r"], "circle-color": colour, "circle-opacity": 0.75, "circle-stroke-color": "#fff", "circle-stroke-width": 1,
                  "circle-translate": [OFFSET[state] * 10, 0]}
        }))
      ]
    },
    bounds: all, fitBoundsOptions: {padding: 24},
    attributionControl: {compact: true}
  });
  let loaded = false, queued = [];
  map.on("load", () => { loaded = true; queued.forEach((f) => f()); queued = []; });
  const whenLoaded = (f) => loaded ? f() : queued.push(f);
  new ResizeObserver(() => { if (container.clientWidth) map.resize(); }).observe(container);
  map.addControl(new maplibregl.NavigationControl({showCompass: false}), "top-right");
  map.addControl(new maplibregl.FullscreenControl({container}), "top-right");
  map.addControl(new maplibregl.ScaleControl({unit: "metric"}), "bottom-right");

  let byLga = new Map();
  const fmt = (n) => Math.round(n ?? 0).toLocaleString("en");
  const describe = (id) => {
    const f = lgas.get(id), p = f?.properties ?? {}, d = byLga.get(id) ?? {};
    const lines = STATES.map(([s, label, c]) => {
      const x = d[s];
      if (!x) return `<div><span style="color:${c}">●</span> ${label}: none</div>`;
      return `<div><span style="color:${c}">●</span> ${label}: ${fmt(x.movements)} movement${x.movements === 1 ? "" : "s"}` +
        `<div style="color:#475569;margin-left:12px">${x.products.slice(0, 4).map((q) => `${fmt(q.quantity)} ${escape(q.unit ?? "")} ${escape(q.product)}`).join("<br>")}${x.products.length > 4 ? "<br>…" : ""}</div></div>`;
    }).join("");
    const what = p.kind === "state" ? "State (state stores)" : `LGA, ${escape(p.state ?? "")}`;
    return `<div style="font:12px system-ui;line-height:1.35"><b>${escape(p.name ?? id)}</b> · ${what}<br>P-code ${escape(p.pcode ?? "—")}${p.in_digit ? "" : " · not in DIGIT"}${lines}</div>`;
  };
  const popup = new maplibregl.Popup({closeButton: false, closeOnClick: false, offset: 8, maxWidth: "320px"});
  const LAYERS = ["lga-fill", ...STATES.map(([s]) => `stock-${s}`)];
  for (const layer of LAYERS) {
    map.on("mousemove", layer, (e) => {
      const f = e.features?.[0]; if (!f) return;
      const id = layer === "lga-fill" ? f.properties.id : f.properties.unit_id;
      map.getCanvas().style.cursor = "pointer";
      popup.setLngLat(e.lngLat).setHTML(describe(id)).addTo(map);
    });
    map.on("mouseleave", layer, () => { map.getCanvas().style.cursor = ""; popup.remove(); });
  }
  map.on("click", (e) => {
    const hit = map.queryRenderedFeatures(e.point, {layers: LAYERS})[0]; if (!hit) return;
    const id = hit.layer.id === "lga-fill" ? hit.properties.id : hit.properties.unit_id;
    container.value = {...(lgas.get(id)?.properties ?? {id}), ...(byLga.get(id) ?? {})};
    container.dispatchEvent(new Event("input", {bubbles: true}));
  });

  const legend = document.createElement("div");
  legend.style.cssText = "position:absolute;left:8px;bottom:8px;background:rgba(255,255,255,.92);padding:6px 10px;border-radius:6px;font:12px system-ui;color:#334155;box-shadow:0 1px 3px rgba(0,0,0,.15)";
  container.appendChild(legend);

  let states = new Set(STATES.map(([s]) => s));
  container.setData = (rows) => {
    byLga = new Map();
    for (const r of rows) {
      if (!byLga.has(r.unit_id)) byLga.set(r.unit_id, {});
      byLga.get(r.unit_id)[r.state] = r;
    }
    const max = Math.max(1, ...rows.map((r) => r.movements));
    const radius = (n) => 3 + 17 * Math.sqrt(n / max);
    const features = rows.filter((r) => centre.has(r.unit_id)).map((r) => ({type: "Feature",
      properties: {unit_id: r.unit_id, state: r.state, movements: r.movements, r: radius(r.movements)},
      geometry: {type: "Point", coordinates: centre.get(r.unit_id)}}))
      .sort((a, b) => b.properties.movements - a.properties.movements);
    const sample = [max, Math.max(1, Math.round(max / 10))].filter((v, i, a) => a.indexOf(v) === i);
    legend.innerHTML = STATES.map(([, label, c]) => `<div style="display:flex;align-items:center;gap:6px;line-height:1.5"><span style="display:inline-block;width:10px;height:10px;border-radius:50%;background:${c}"></span>${label}</div>`).join("") +
      `<div style="margin-top:4px;color:#64748b">Circle area: movements per LGA (or state)</div>` +
      sample.map((v) => `<div style="display:flex;align-items:center;gap:6px;line-height:1.6"><span style="display:inline-block;width:${2 * radius(v)}px;height:${2 * radius(v)}px;border-radius:50%;border:1px solid #64748b"></span>${fmt(v)}</div>`).join("") +
      `<div style="display:flex;align-items:center;gap:6px;line-height:1.5;margin-top:4px"><span style="display:inline-block;width:12px;height:10px;border:2px solid #334155"></span>LGA in DIGIT</div>`;
    whenLoaded(() => {
      map.getSource("stock").setData({type: "FeatureCollection", features});
      const ids = rows.map((r) => r.unit_id).filter((id) => lgas.has(id));
      map.fitBounds(ids.length ? boundsOf(ids.map((id) => lgas.get(id))) : all, {padding: 50, duration: 0, maxZoom: 9});
    });
  };
  container.setStates = (s) => { states = new Set(s); whenLoaded(() => { for (const [st] of STATES) map.setLayoutProperty(`stock-${st}`, "visibility", states.has(st) ? "visible" : "none"); }); };
  container.map = map;
  container.value = null;
  return container;
}

function boundsOf(features) {
  let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
  const walk = (c) => { if (typeof c[0] === "number") { x0 = Math.min(x0, c[0]); x1 = Math.max(x1, c[0]); y0 = Math.min(y0, c[1]); y1 = Math.max(y1, c[1]); } else c.forEach(walk); };
  for (const f of features) if (f?.geometry) walk(f.geometry.coordinates);
  return isFinite(x0) ? [[x0, y0], [x1, y1]] : [[2.6, 4.2], [14.7, 13.9]];
}
// The centre of an LGA's bounding box: good enough to anchor its circles.
function centreOf(f) { const [[x0, y0], [x1, y1]] = boundsOf([f]); return [(x0 + x1) / 2, (y0 + y1) / 2]; }
function escape(s) { return String(s ?? "").replace(/[&<>"]/g, (c) => ({"&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;"})[c]); }
