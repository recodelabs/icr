// Uganda's map: Observatory's adminMap (@recodelabs/observatory-components) at the country's
// bounds. The boundary tiles come from fhir-pipes (admin.pmtiles), with the layer names in the
// Uganda profile (ig/fhir-pipes-profile-uganda.toml): `regions`, and `districts` for the
// districts and cities.
import {adminMap} from "@recodelabs/observatory-components";
export {quantileBreaks, colorsFor, BLUES, DIVERGING} from "@recodelabs/observatory-components";

export const UGANDA_BOUNDS = [[29.5, -1.5], [35.1, 4.3]];

export const UGANDA_LAYERS = {units: "districts", regions: "regions", country: "country"};

/** adminMap at Uganda's bounds and layers: {pmtiles, labels, height, choropleth}. */
export function ugandaMap(options) {
  return adminMap({bounds: UGANDA_BOUNDS, ...options, layers: {...UGANDA_LAYERS, ...options?.layers}});
}
