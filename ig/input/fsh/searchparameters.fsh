// Search parameters (campaign-visibility round).
// The registry's core question — "which campaigns target this place, in this window?" —
// hinges on ICRCampaign.extension[targetGeography], and extensions are not searchable
// without a SearchParameter. This one makes the geography link a first-class reference
// search on CarePlan, so a server that loads the IG can answer:
//   CarePlan?target-geography=Location/<id>                 exact geography
//   CarePlan?target-geography.partof=Location/<id>          campaigns in the direct children
//   CarePlan?target-geography=<id1>,<id2>,…&date=ge…&date=le…   a subtree (ids resolved via
//       Location?_id=<root>&_revinclude:iterate=Location:partof) within a date window
//   Location?_id=<root>&_revinclude:iterate=Location:partof&_revinclude:iterate=CarePlan:target-geography
//       the whole subtree AND every campaign targeting any node of it, in one call
// Servers generally do not implement :above/:below on references (HAPI 8 does not), so
// subtree queries resolve the Location subtree first and OR the ids — see tools/hapi/README.
// The same gap exists for denominators: ICRTargetPopulation's geography characteristic is a
// plain Group.characteristic.valueReference, which base Group search cannot reach (its
// `value` parameter is token-typed). The second parameter below makes "every estimate
// scoped to this place" one query, and lets a campaign's denominators and its geography be
// pulled together from a Location.

Instance: icr-campaign-target-geography
InstanceOf: SearchParameter
Usage: #definition
Title: "ICR Campaign — target geography"
Description: "Search ICRCampaign (CarePlan) by the Location it targets — the target-geography extension. Reference-typed, so it chains (target-geography.partof=…) and reverse-includes (Location?_revinclude=CarePlan:target-geography). This is the parameter behind campaign visibility: what is planned where, and which campaigns are heading for the same geography in the same window."
* name = "ICRCampaignTargetGeography"
* status = #active
* experimental = false
* version = "1.0.0"
* code = #target-geography
* base = #CarePlan
* type = #reference
* expression = "CarePlan.extension('https://icr.healthcampaigns.org/StructureDefinition/target-geography').value.as(Reference)"
* xpathUsage = #normal
* target = #Location

Instance: icr-target-population-geography
InstanceOf: SearchParameter
Usage: #definition
Title: "ICR Target Population — geography"
Description: "Search ICRTargetPopulation (Group) by the Location its estimate is scoped to — the geography characteristic. Base Group search cannot reach a characteristic's valueReference (its value parameter is token-typed), so without this parameter 'all denominators for this ward' is not a query. Reference-typed, so it chains (geography.partof=…) and reverse-includes (Location?_revinclude=Group:geography)."
* name = "ICRTargetPopulationGeography"
* status = #active
* experimental = false
* version = "1.0.0"
* code = #geography
* base = #Group
* type = #reference
* expression = "Group.characteristic.where(code.coding.where(system='https://icr.healthcampaigns.org/CodeSystem/icr-group-characteristic-cs' and code='geography').exists()).value.as(Reference)"
* xpathUsage = #normal
* target = #Location

// Spatial index cells (spatial-index round). Both are STRING parameters on the cell
// key. FHIR string search matches by prefix, and quadkeys are prefix-hierarchical,
// so Location?quadkey=0313131 returns every point inside that coarser tile and
// Location?quadkey=<18 digits> the exact level-18 cell. H3 indexes are not prefix-
// hierarchical as strings: use Location?h3:exact=<cell> (or the full cell, which
// only matches itself since all H3 cells are 15 characters).
Instance: icr-location-quadkey
InstanceOf: SearchParameter
Usage: #definition
Title: "ICR Location — quadkey cell"
Description: "Search Location by its quadkey spatial-index cell (spatial-index extension, system = quadkey). String-typed on purpose: quadkeys are prefix-hierarchical, so the default starts-with match answers tile containment at any coarser zoom — Location?quadkey=0313131 is every point in that zoom-7 tile — with no geometry engine. Use :exact for one cell."
* name = "ICRLocationQuadkey"
* status = #active
* experimental = false
* version = "1.0.0"
* code = #quadkey
* base = #Location
* type = #string
* expression = "Location.extension('https://icr.healthcampaigns.org/StructureDefinition/spatial-index').where(extension('system').value = 'quadkey').extension('cell').value.as(string)"
* xpathUsage = #normal

Instance: icr-location-h3
InstanceOf: SearchParameter
Usage: #definition
Title: "ICR Location — H3 cell"
Description: "Search Location by its H3 spatial-index cell (spatial-index extension, system = h3). H3 indexes are fixed 15-character strings and are not prefix-hierarchical, so a full cell matches only itself; join on the exact cell."
* name = "ICRLocationH3"
* status = #active
* experimental = false
* version = "1.0.0"
* code = #h3
* base = #Location
* type = #string
* expression = "Location.extension('https://icr.healthcampaigns.org/StructureDefinition/spatial-index').where(extension('system').value = 'h3').extension('cell').value.as(string)"
* xpathUsage = #normal
