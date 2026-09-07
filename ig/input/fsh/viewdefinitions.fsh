// SQL-on-FHIR ViewDefinitions — the analytics layer shipped with the data model
// (design decision #12). A ViewDefinition is a portable, runner-independent
// projection of FHIR resources into a flat table; any conformant runner
// (octofhir-sof, FlatQuack, Pathling, fhir-data-pipes, Aidbox …) produces the
// same rows. See the SQL-on-FHIR IG: http://hl7.org/fhir/uv/sql-on-fhir

Alias: $ViewDefinition = https://sql-on-fhir.org/ig/StructureDefinition/ViewDefinition
Alias: $SDCampaignRound = https://icr.healthcampaigns.org/StructureDefinition/campaign-round
Alias: $SDTargetGeography = https://icr.healthcampaigns.org/StructureDefinition/target-geography

Instance: IcrCampaignCalendar
InstanceOf: $ViewDefinition
Usage: #definition
Title: "ICR campaign calendar"
Description: """
One row per campaign (CarePlan) per target geography: **what is planned or ran,
where, and when** — the table behind the campaign calendar and the
campaign-visibility use case (an official registry of what is planned where,
viewable as a map and a calendar).

Join `location_id` to the location registry (Location, or its parquet export) to
roll campaigns up or down the administrative hierarchy; `parent_campaign_id`
links a round to its umbrella campaign; `round` is the round number within the
programme-year. Umbrella campaigns without a `target-geography` still appear
(one row, `location_id` empty) thanks to `forEachOrNull`.

Column types are declared so runners that support native temporal types write
`period_start` / `period_end` as dates rather than strings.
"""
* url = "https://icr.healthcampaigns.org/ViewDefinition/IcrCampaignCalendar"
* name = "IcrCampaignCalendar"
* title = "ICR campaign calendar"
* status = #draft
* fhirVersion = #4.0.1
* resource = #CarePlan
* select[0].column[0].name = "campaign_id"
* select[0].column[0].path = "getResourceKey()"
* select[0].column[0].type = "id"
* select[0].column[0].description = "The CarePlan id"
* select[0].column[1].name = "title"
* select[0].column[1].path = "title"
* select[0].column[1].type = "string"
* select[0].column[2].name = "status"
* select[0].column[2].path = "status"
* select[0].column[2].type = "code"
* select[0].column[2].description = "draft (planned) | active | completed | …"
* select[0].column[3].name = "intent"
* select[0].column[3].path = "intent"
* select[0].column[3].type = "code"
* select[0].column[3].description = "plan (microplan / umbrella) | order (execution)"
* select[0].column[4].name = "campaign_type"
* select[0].column[4].path = "category.first().coding.first().code"
* select[0].column[4].type = "code"
* select[0].column[4].description = "First category: vaccination-sia | mda | itn-distribution | irs | vitamin-a | integrated"
* select[0].column[5].name = "period_start"
* select[0].column[5].path = "period.start"
* select[0].column[5].type = "date"
* select[0].column[6].name = "period_end"
* select[0].column[6].path = "period.end"
* select[0].column[6].type = "date"
* select[0].column[7].name = "round"
* select[0].column[7].path = "extension('https://icr.healthcampaigns.org/StructureDefinition/campaign-round').value.ofType(positiveInt)"
* select[0].column[7].type = "positiveInt"
* select[0].column[8].name = "parent_campaign_id"
* select[0].column[8].path = "partOf.first().getReferenceKey(CarePlan)"
* select[0].column[8].type = "string"
* select[0].column[8].description = "The umbrella campaign this round belongs to"
* select[0].column[9].name = "protocol"
* select[0].column[9].path = "instantiatesCanonical.first()"
* select[0].column[9].type = "canonical"
* select[0].column[9].description = "The PlanDefinition (protocol) this campaign instantiates"
* select[0].column[10].name = "denominator_id"
* select[0].column[10].path = "extension('https://icr.healthcampaigns.org/StructureDefinition/planning-denominator').value.ofType(Reference).getReferenceKey(Group)"
* select[0].column[10].type = "string"
* select[0].column[10].description = "The ICRTargetPopulation Group this campaign plans against — join key to the target_population view for people targeted"
* select[1].forEachOrNull = "extension('https://icr.healthcampaigns.org/StructureDefinition/target-geography')"
* select[1].column[0].name = "location_id"
* select[1].column[0].path = "value.ofType(Reference).getReferenceKey(Location)"
* select[1].column[0].type = "string"
* select[1].column[0].description = "The Location this campaign targets — join key to the location registry. One row per target geography; empty for umbrella campaigns with none."

Instance: IcrTargetPopulation
InstanceOf: $ViewDefinition
Usage: #definition
Title: "ICR target populations"
Description: """
One row per target-population estimate (ICRTargetPopulation Group): the
**denominators** — how many people a campaign plans to reach, where, for which
age band, from which source. Joined to the campaign calendar on
`denominator_id` this gives "people targeted"; joined to coverage reports it
gives the denominator side of coverage.

`location_id` is the geography characteristic; `age_low` / `age_high` are the
age-band characteristic (units in `age_unit`, months or years); competing
estimates for the same geography are distinguished by `source`, `estimate_date`
and `is_planning`.
"""
* url = "https://icr.healthcampaigns.org/ViewDefinition/IcrTargetPopulation"
* name = "IcrTargetPopulation"
* title = "ICR target populations"
* status = #draft
* fhirVersion = #4.0.1
* resource = #Group
* where[0].path = "actual = false and quantity.exists()"
* where[0].description = "Definitional cohorts with a count — the ICRTargetPopulation profile; excludes households and other actual groups and the count-less eligibility definitions"
* select[0].column[0].name = "group_id"
* select[0].column[0].path = "getResourceKey()"
* select[0].column[0].type = "id"
* select[0].column[1].name = "name"
* select[0].column[1].path = "name"
* select[0].column[1].type = "string"
* select[0].column[2].name = "quantity"
* select[0].column[2].path = "quantity"
* select[0].column[2].type = "unsignedInt"
* select[0].column[2].description = "The denominator count"
* select[0].column[3].name = "location_id"
* select[0].column[3].path = "characteristic.where(code.coding.code = 'geography').first().value.ofType(Reference).getReferenceKey(Location)"
* select[0].column[3].type = "string"
* select[0].column[4].name = "age_low"
* select[0].column[4].path = "characteristic.where(code.coding.code = 'age-band').first().value.ofType(Range).low.value"
* select[0].column[4].type = "decimal"
* select[0].column[5].name = "age_high"
* select[0].column[5].path = "characteristic.where(code.coding.code = 'age-band').first().value.ofType(Range).high.value"
* select[0].column[5].type = "decimal"
* select[0].column[6].name = "age_unit"
* select[0].column[6].path = "characteristic.where(code.coding.code = 'age-band').first().value.ofType(Range).low.code"
* select[0].column[6].type = "code"
* select[0].column[6].description = "UCUM: mo | a"
* select[0].column[7].name = "source"
* select[0].column[7].path = "extension('https://icr.healthcampaigns.org/StructureDefinition/denominator-source').value.ofType(CodeableConcept).coding.first().code"
* select[0].column[7].type = "code"
* select[0].column[7].description = "census | census-projection | worldpop | grid3 | microcensus | hmis | govt-estimate | …"
* select[0].column[8].name = "estimate_date"
* select[0].column[8].path = "extension('https://icr.healthcampaigns.org/StructureDefinition/estimate-date').value.ofType(date)"
* select[0].column[8].type = "date"
* select[0].column[9].name = "is_planning"
* select[0].column[9].path = "extension('https://icr.healthcampaigns.org/StructureDefinition/is-planning-denominator').value.ofType(boolean)"
* select[0].column[9].type = "boolean"
