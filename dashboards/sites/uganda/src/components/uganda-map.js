// Uganda's map: Observatory's adminMap (@recodelabs/observatory-components) at the country's
// bounds. The boundary tiles come from fhir-pipes (admin.pmtiles), which names one layer per
// admin level: admin0 the country, admin1 Uganda's regions, admin2 its districts and cities
// (fhir-pipes #140; the profile names no levels). adminMap's defaults are Nigeria's names
// (country, states, lgas), so the layers are given here.
import {adminMap} from "@recodelabs/observatory-components";
export {quantileBreaks, colorsFor, BLUES, DIVERGING} from "@recodelabs/observatory-components";

export const UGANDA_BOUNDS = [[29.5, -1.5], [35.1, 4.3]];
export const UGANDA_LAYERS = {units: "admin2", regions: "admin1", country: "admin0"};

/** adminMap at Uganda's bounds: {pmtiles, labels, height, choropleth}. */
export function ugandaMap(options) {
  return adminMap({bounds: UGANDA_BOUNDS, ...options, layers: {...UGANDA_LAYERS, ...(options?.layers ?? {})}});
}
