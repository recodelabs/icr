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
* select[1].forEachOrNull = "extension('https://icr.healthcampaigns.org/StructureDefinition/target-geography')"
* select[1].column[0].name = "location_id"
* select[1].column[0].path = "value.ofType(Reference).getReferenceKey(Location)"
* select[1].column[0].type = "string"
* select[1].column[0].description = "The Location this campaign targets — join key to the location registry. One row per target geography; empty for umbrella campaigns with none."
