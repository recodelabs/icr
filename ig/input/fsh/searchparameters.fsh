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
