// Uganda's map: Observatory's adminMap (@recodelabs/observatory-components) at the country's
// bounds. The boundary tiles come from fhir-pipes (admin.pmtiles), which names the layers the
// Nigerian way for every country: `states` holds Uganda's regions and `lgas` its districts and
// cities. Those are adminMap's default layer names.
import {adminMap} from "@recodelabs/observatory-components";
export {quantileBreaks, colorsFor, BLUES, DIVERGING} from "@recodelabs/observatory-components";

export const UGANDA_BOUNDS = [[29.5, -1.5], [35.1, 4.3]];

/** adminMap at Uganda's bounds: {pmtiles, labels, height, choropleth}. */
export function ugandaMap(options) {
  return adminMap({bounds: UGANDA_BOUNDS, ...options});
}
