// MR campaign coverage on a map, from data/campaign-coverage.parquet and data/boundaries.json.
import {unitMap} from "./unit-map.js";
import {thematic} from "./charts.js";
import {CAMPAIGN_LEGEND} from "./dhis2.js";

/**
 * `rows`: {location_id, value, vaccinated, target}. `level` 2 colours districts and city
 * corporations, 3 upazilas (and CC zones and wards). `areas` limits the map to these
 * district or city corporation names (e.g. ["Khulna District", "Khulna CC"]) and what is in them.
 */
export function coverageMap(boundaries, rows, {level = 2, areas = null, height = 480, label = "MR campaign coverage (%)"} = {}) {
  const keep = areas && new Set(areas);
  const features = keep
    ? boundaries.features.filter((f) => keep.has(f.properties.name) || keep.has(f.properties.district))
    : boundaries.features;
  const map = unitMap({geojson: {type: "FeatureCollection", features}, height});
  thematic(map, rows.map((d) => ({location_id: d.location_id, value: d.value, numerator: d.vaccinated, denominator: d.target})),
    {level, legend: CAMPAIGN_LEGEND, label});
  return map;
}
