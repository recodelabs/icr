// The site's choropleth map: adminMap from the components package on data/boundaries.pmtiles,
// which has a tile layer for districts and city corporations (admin level 2) and one for
// upazilas, CC zones and wards (3). Colour it with thematic() in charts.js; `map.map` is the
// MapLibre map, with the units in the layer "unit-fill" whichever level is shown.
import maplibregl from "maplibre-gl";
import {adminMap} from "@recodelabs/observatory-components/admin-map";

// Darker than the palest map colour (Spectral's pale yellow), so "no value" is never mistaken for it.
const NO_VALUE = "#c4c6cc";

/** `pmtiles`: the ArrayBuffer of data/boundaries.pmtiles. */
export function unitMap({pmtiles, height = 460} = {}) {
  const map = adminMap({pmtiles, levels: {2: "admin2", 3: "admin3"}, regionField: "district", noValue: NO_VALUE, height});
  map.map.addControl(new maplibregl.FullscreenControl(), "top-right");
  return map;
}
