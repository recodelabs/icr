// Facilities and household dwellings as points on MapLibre, from rows with lon/lat. DIGIT's
// boundaries have no geometry, so unlike the Uganda map (Observatory's adminMap over boundary
// tiles) there are no polygons: only the points and a light basemap.
import maplibregl from "npm:maplibre-gl@5";

export const KINDS = [
  ["facility", "Health facility", "#c2410c"],
  ["dwelling", "Household dwelling", "#2563eb"]
];

const BASEMAP = {tiles: ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"], attribution: "© OpenStreetMap contributors"};

/**
 * @param rows   [{location_id, name, kind, boundary_name, hierarchy, lon, lat}]
 * Returns the container, with setKinds(Set of kinds), fit() and a `value` (the clicked point's
 * properties) updated and an "input" event dispatched on click.
 */
export function pointsMap(rows, {height = 560} = {}) {
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
        points: {type: "geojson", data: {type: "FeatureCollection", features}}
      },
      layers: [
        {id: "basemap", type: "raster", source: "basemap", paint: {"raster-opacity": 0.5, "raster-saturation": -0.9}},
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
  for (const layer of ["facilities", "dwellings"]) {
    map.on("mousemove", layer, (e) => {
      const p = e.features?.[0]?.properties; if (!p) return;
      map.getCanvas().style.cursor = "pointer";
      const kind = KINDS.find(([k]) => k === p.kind)?.[1] ?? p.kind;
      popup.setLngLat(e.lngLat).setHTML(`<div style="font:12px system-ui;line-height:1.35"><b>${escape(p.name ?? "—")}</b><br>${kind}${p.boundary ? ` · ${escape(p.boundary)}` : ""}</div>`).addTo(map);
    });
    map.on("mouseleave", layer, () => { map.getCanvas().style.cursor = ""; popup.remove(); });
    map.on("click", layer, (e) => {
      const p = e.features?.[0]?.properties; if (!p) return;
      container.value = {...p, lngLat: [e.lngLat.lng, e.lngLat.lat]};
      container.dispatchEvent(new Event("input", {bubbles: true}));
    });
  }

  const legend = document.createElement("div");
  legend.style.cssText = "position:absolute;left:8px;bottom:8px;background:rgba(255,255,255,.92);padding:6px 10px;border-radius:6px;font:12px system-ui;color:#334155;box-shadow:0 1px 3px rgba(0,0,0,.15)";
  const counts = new Map(KINDS.map(([k]) => [k, rows.filter((d) => d.kind === k).length]));
  legend.innerHTML = KINDS.map(([k, label, c]) => `<div style="display:flex;align-items:center;gap:6px;line-height:1.5"><span style="display:inline-block;width:10px;height:10px;border-radius:50%;background:${c}"></span>${label} (${counts.get(k).toLocaleString("en")})</div>`).join("");
  container.appendChild(legend);

  let ready = false, kinds = new Set(KINDS.map(([k]) => k));
  const apply = () => {
    if (!ready) return;
    map.setLayoutProperty("facilities", "visibility", kinds.has("facility") ? "visible" : "none");
    map.setLayoutProperty("dwellings", "visibility", kinds.has("dwelling") ? "visible" : "none");
  };
  map.on("load", () => { ready = true; apply(); });
  container.setKinds = (k) => { kinds = new Set(k); apply(); };
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
