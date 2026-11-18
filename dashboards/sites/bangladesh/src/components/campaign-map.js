// MR campaign coverage on a map, from data/campaign-coverage.parquet and data/boundaries.pmtiles.
import {unitMap} from "./unit-map.js";
import {thematic} from "./charts.js";
import {CAMPAIGN_LEGEND} from "./dhis2.js";

/**
 * `tiles`: the ArrayBuffer of data/boundaries.pmtiles. `rows`: {location_id, value, vaccinated,
 * target}. `level` 2 colours districts and city corporations, 3 upazilas (and CC zones and wards).
 */
export function coverageMap(tiles, rows, {level = 2, height = 480, label = "MR campaign coverage (%)"} = {}) {
  const map = unitMap({pmtiles: tiles, height});
  thematic(map, rows.map((d) => ({location_id: d.location_id, value: d.value, numerator: d.vaccinated, denominator: d.target})),
    {level, legend: CAMPAIGN_LEGEND, label});
  return map;
}
