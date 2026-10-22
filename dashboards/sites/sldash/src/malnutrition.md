---
title: Malnutrition
sql:
  values: data/values.parquet
  facilities: data/facilities.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Malnutrition

```js
import maplibregl from "npm:maplibre-gl@5";
import {item, pivot, rows} from "./components/dhis2.js";
import {columns, thematic, periodName} from "./components/charts.js";
import {load, pick, relative} from "./components/page.js";
import {unitMap, DEFAULT_BASEMAP} from "./components/unit-map.js";

// DHIS2 uids of the items on the demo's Malnutrition dashboard.
const DX = {
  moderate: "joIQbN4L1Ok", severe: "vhzPbO1eEyr", well: "aGByu8NFs9m", breastfeeding: "X3taFC1HtE5"
};
const all = await load(sql, Object.values(DX));
const facilities = rows(await sql`SELECT * FROM facilities`);
const years = Array.from(new Set(all.filter((d) => d.period_type === "Yearly").map((d) => d.period))).sort();
const geojson = await FileAttachment("data/units.geojson").json();
const nameOf = (dx) => all.find((d) => d.dx === dx)?.name ?? dx;
// The org units of the DHIS2 pivot table, in its order.
const PIVOT_UNITS = ["Western Area", "Pujehun", "Port Loko", "Bo", "Kenema", "Kailahun", "Tonkolili", "Kono", "Bombali",
                     "Moyamba", "Sierra Leone", "Bonthe", "Koinadugu", "Kambia"];
```

```js
const yearInput = Inputs.select(years, {label: "This year", value: years.at(-1)});
const selectedYear = Generators.input(yearInput);
```

```js
const year = Number(selectedYear);
const P = relative(all, year);
const w = (n) => Math.max(320, (width - 24) / n - 24);
const cat = (rows, category, series) => rows.map((d) => ({category: category(d), series: series(d), value: d.value}));
```

<div class="d2-filter">${yearInput}<span class="muted">DHIS2's relative periods (last 4 quarters) count from this year. Two items use DHIS2's fixed period 2026.</span></div>

<div class="grid grid-cols-2" style="gap: 16px">
${item("Nutrition: Moderate malnutrition rate 2013 (chiefdoms, 2026)", moderateMap,
  {note: "DHIS2's title says 2013; the item's period is 2026."})}
${item("Nutrition: Malnutrition and well nourished",
  columns(cat(pick(all, {dx: [DX.severe, DX.well], level: 0, periods: P.last4Quarters}), (d) => periodName(d.period), (d) => d.name),
    {width: w(2), yLabel: "%", categoryOrder: P.last4Quarters.map(periodName), seriesOrder: [nameOf(DX.severe), nameOf(DX.well)]}))}
${item("Nutrition: Malnutrition indicators (2026)",
  pivot(pick(all, {dx: [DX.breastfeeding, DX.severe, DX.moderate, DX.well], periods: ["2026"]}).filter((d) => d.admin_level === 0 || d.admin_level === 1),
    {row: (d) => d.location_name, col: (d) => d.name, rowOrder: PIVOT_UNITS,
     colOrder: [DX.breastfeeding, DX.severe, DX.moderate, DX.well].map(nameOf), rowLabel: "Org unit"}))}
${item("Boundaries: Facilities", boundaryMap({level: 1, points: facilities.filter((f) => f.lon != null)}),
  {note: "The 601 facilities DHIS2 has coordinates for, with district boundaries."})}
${item("Boundaries: Chiefdoms", boundaryMap({level: 2}))}
</div>

```js
const moderateMap = unitMap({geojson, height: 380});
thematic(moderateMap, pick(all, {dx: DX.moderate, level: 2, periods: ["2026"]}), {level: 2, label: "Moderate malnutrition rate (%)"});
```

```js
// A DHIS2 Maps boundary layer: outlines of one admin level, and facility points when given.
function boundaryMap({level, points = [], height = 380}) {
  const container = document.createElement("div");
  container.style.cssText = `width:100%;height:${height}px;border-radius:8px;overflow:hidden;background:#f8fafc`;
  const b = DEFAULT_BASEMAP;
  const lines = {type: "FeatureCollection", features: geojson.features.filter((f) => f.properties.admin_level === level)};
  const dots = {type: "FeatureCollection", features: points.map((p) => ({type: "Feature", properties: {name: p.name, type: p.facility_type ?? ""},
    geometry: {type: "Point", coordinates: [p.lon, p.lat]}}))};
  const map = new maplibregl.Map({
    container, attributionControl: {compact: true},
    bounds: [[-13.4, 6.9], [-10.2, 10.0]], fitBoundsOptions: {padding: 20},
    style: {version: 8, sources: {
        basemap: {type: "raster", tiles: b.tiles, tileSize: 256, attribution: b.attribution},
        lines: {type: "geojson", data: lines}, dots: {type: "geojson", data: dots}},
      layers: [
        {id: "basemap", type: "raster", source: "basemap", paint: {"raster-opacity": b.opacity, "raster-saturation": b.saturation}},
        {id: "lines", type: "line", source: "lines", paint: {"line-color": "#334155", "line-width": 1}},
        {id: "dots", type: "circle", source: "dots", paint: {"circle-radius": 3, "circle-color": "#518cc3", "circle-stroke-color": "#fff", "circle-stroke-width": 0.5}}
      ]}
  });
  map.scrollZoom.disable();
  map.addControl(new maplibregl.NavigationControl({showCompass: false}), "top-right");
  const popup = new maplibregl.Popup({closeButton: false, closeOnClick: false, offset: 8});
  map.on("mousemove", "dots", (e) => {
    const f = e.features?.[0];
    if (!f) return;
    popup.setLngLat(e.lngLat).setHTML(`<div style="font:12px system-ui"><b>${f.properties.name}</b>${f.properties.type ? `<br>${f.properties.type}` : ""}</div>`).addTo(map);
  });
  map.on("mouseleave", "dots", () => popup.remove());
  new ResizeObserver(() => { if (container.clientWidth > 0) map.resize(); }).observe(container);
  return container;
}
```

<div class="muted d2-footer">
Rebuilt from the demo DHIS2's <b>Malnutrition</b> dashboard (play.dhis2.org, Sierra Leone) with the values
imported into the registry by <code>kiln dhis2</code>: all 5 map and data items. Not shown: the messages
and resources items, which hold no data.
</div>
