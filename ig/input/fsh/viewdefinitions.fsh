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
and `is_planning`. `denominator_type` separates an all-ages figure
(`total-population`, e.g. a WorldPop grid summed over the boundary) from an
eligible subset (`at-risk`); `is_calculated` marks a rollup or interpolation
rather than an independently sourced count. Two total-population rows for the
same `location_id` and `estimate_date` from different `source`s are the
comparison the Campaign Targeting dashboard draws.
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
* select[0].column[10].name = "denominator_type"
* select[0].column[10].path = "extension('https://icr.healthcampaigns.org/StructureDefinition/denominator-type').value.ofType(code)"
* select[0].column[10].type = "code"
* select[0].column[10].description = "total-population | at-risk; null on older Groups that predate the extension"
* select[0].column[11].name = "is_calculated"
* select[0].column[11].path = "extension('https://icr.healthcampaigns.org/StructureDefinition/is-calculated').value.ofType(boolean)"
* select[0].column[11].type = "boolean"
* select[0].column[11].description = "True for a rollup or interpolation rather than an independently sourced count"

Instance: IcrCoverage
InstanceOf: $ViewDefinition
Usage: #definition
Title: "ICR coverage reports"
Description: """
One row per coverage report (MeasureReport): the **results** — people reached
and coverage, whether from administrative tallies (`source = administrative`),
a post-campaign survey (`survey`) or LQAS (`lqas`), and whether preliminary
(`lineage = realtime`) or final (`reconciled`). Joined to the campaign
calendar on `campaign_id` this gives people reached and coverage per round;
grouping by `campaign_id` and `source` puts administrative and survey figures
side by side. Strata (sex, age band, delivery strategy, disposition,
geography) are in the companion view `IcrCoverageStrata`.
"""
* url = "https://icr.healthcampaigns.org/ViewDefinition/IcrCoverage"
* name = "IcrCoverage"
* title = "ICR coverage reports"
* status = #draft
* fhirVersion = #4.0.1
* resource = #MeasureReport
* where[0].path = "extension('https://icr.healthcampaigns.org/StructureDefinition/coverage-source').exists()"
* where[0].description = "Only ICR coverage reports (administrative, survey, LQAS) — not cost or readiness reports"
* select[0].column[0].name = "report_id"
* select[0].column[0].path = "getResourceKey()"
* select[0].column[0].type = "id"
* select[0].column[1].name = "campaign_id"
* select[0].column[1].path = "extension('https://icr.healthcampaigns.org/StructureDefinition/campaign').value.ofType(Reference).getReferenceKey(CarePlan)"
* select[0].column[1].type = "string"
* select[0].column[1].description = "The campaign (round) this report is about — join key to IcrCampaignCalendar"
* select[0].column[2].name = "location_id"
* select[0].column[2].path = "subject.getReferenceKey(Location)"
* select[0].column[2].type = "string"
* select[0].column[3].name = "measure"
* select[0].column[3].path = "measure"
* select[0].column[3].type = "canonical"
* select[0].column[4].name = "source"
* select[0].column[4].path = "extension('https://icr.healthcampaigns.org/StructureDefinition/coverage-source').value.ofType(code)"
* select[0].column[4].type = "code"
* select[0].column[4].description = "administrative | survey | lqas"
* select[0].column[5].name = "lineage"
* select[0].column[5].path = "extension('https://icr.healthcampaigns.org/StructureDefinition/realtime-vs-reconciled').value.ofType(code)"
* select[0].column[5].type = "code"
* select[0].column[5].description = "realtime (preliminary, in-campaign) | reconciled (final)"
* select[0].column[6].name = "denominator_type"
* select[0].column[6].path = "extension('https://icr.healthcampaigns.org/StructureDefinition/denominator-type').value.ofType(code)"
* select[0].column[6].type = "code"
* select[0].column[7].name = "status"
* select[0].column[7].path = "status"
* select[0].column[7].type = "code"
* select[0].column[8].name = "period_start"
* select[0].column[8].path = "period.start"
* select[0].column[8].type = "date"
* select[0].column[9].name = "period_end"
* select[0].column[9].path = "period.end"
* select[0].column[9].type = "date"
* select[0].column[10].name = "reported"
* select[0].column[10].path = "date"
* select[0].column[10].type = "dateTime"
* select[0].column[11].name = "numerator"
* select[0].column[11].path = "group.first().population.where(code.coding.code = 'numerator').first().count"
* select[0].column[11].type = "integer"
* select[0].column[11].description = "People reached (administrative) or sampled and covered (survey / LQAS)"
* select[0].column[12].name = "denominator"
* select[0].column[12].path = "group.first().population.where(code.coding.code = 'denominator').first().count"
* select[0].column[12].type = "integer"
* select[0].column[12].description = "Planning denominator (administrative) or sample size (survey / LQAS)"
* select[0].column[13].name = "score"
* select[0].column[13].path = "group.first().measureScore.value"
* select[0].column[13].type = "decimal"
* select[0].column[13].description = "Coverage as a proportion 0–1 (the ICR coverage Measures are proportion-scored; multiply by 100 for percent)"
* select[0].column[14].name = "ci_low"
* select[0].column[14].path = "extension('https://icr.healthcampaigns.org/StructureDefinition/confidence-interval').extension('low').value.ofType(decimal)"
* select[0].column[14].type = "decimal"
* select[0].column[15].name = "ci_high"
* select[0].column[15].path = "extension('https://icr.healthcampaigns.org/StructureDefinition/confidence-interval').extension('high').value.ofType(decimal)"
* select[0].column[15].type = "decimal"
* select[0].column[16].name = "sample_design"
* select[0].column[16].path = "extension('https://icr.healthcampaigns.org/StructureDefinition/sample-design').value.ofType(string)"
* select[0].column[16].type = "string"
* select[0].column[17].name = "reporter"
* select[0].column[17].path = "reporter.display"
* select[0].column[17].type = "string"

Instance: IcrCoverageStrata
InstanceOf: $ViewDefinition
Usage: #definition
Title: "ICR coverage strata"
Description: """
One row per stratum of a coverage report: the disaggregations (sex, age band,
delivery strategy, disposition, geography) declared by the ICR coverage
Measures. Join to `IcrCoverage` on `report_id`.
"""
* url = "https://icr.healthcampaigns.org/ViewDefinition/IcrCoverageStrata"
* name = "IcrCoverageStrata"
* title = "ICR coverage strata"
* status = #draft
* fhirVersion = #4.0.1
* resource = #MeasureReport
* where[0].path = "extension('https://icr.healthcampaigns.org/StructureDefinition/coverage-source').exists()"
* select[0].column[0].name = "report_id"
* select[0].column[0].path = "getResourceKey()"
* select[0].column[0].type = "id"
* select[0].column[1].name = "campaign_id"
* select[0].column[1].path = "extension('https://icr.healthcampaigns.org/StructureDefinition/campaign').value.ofType(Reference).getReferenceKey(CarePlan)"
* select[0].column[1].type = "string"
* select[1].forEach = "group.first().stratifier"
* select[1].column[0].name = "stratifier"
* select[1].column[0].path = "code.coding.first().code"
* select[1].column[0].type = "code"
* select[1].column[0].description = "sex | age-band | delivery-strategy | disposition | geography | dose-history"
* select[1].select[0].forEach = "stratum"
* select[1].select[0].column[0].name = "stratum"
* select[1].select[0].column[0].path = "value.text"
* select[1].select[0].column[0].type = "string"
* select[1].select[0].column[1].name = "numerator"
* select[1].select[0].column[1].path = "population.where(code.coding.code = 'numerator').first().count"
* select[1].select[0].column[1].type = "integer"
* select[1].select[0].column[2].name = "denominator"
* select[1].select[0].column[2].path = "population.where(code.coding.code = 'denominator').first().count"
* select[1].select[0].column[2].type = "integer"
* select[1].select[0].column[3].name = "score"
* select[1].select[0].column[3].path = "measureScore.value"
* select[1].select[0].column[3].type = "decimal"

Instance: IcrLocationStatus
InstanceOf: $ViewDefinition
Usage: #definition
Title: "ICR location status"
Description: """
One row per location-status assertion (ICRLocationStatus Observation): the
revisable, provenance-carrying properties of a place — endemicity per NTD
first (`property` = lf-endemicity, oncho-endemicity, …; `status` = the JRSM
ladder), with who asserted it, when, by what method, and the baseline
prevalence or stop-survey figure it rests on (first two components). Read the
newest row per (location_id, property) for the current classification; join
`location_id` to the registry for "which LGAs are LF-endemic" maps.
"""
* url = "https://icr.healthcampaigns.org/ViewDefinition/IcrLocationStatus"
* name = "IcrLocationStatus"
* title = "ICR location status"
* status = #draft
* fhirVersion = #4.0.1
* resource = #Observation
* where[0].path = "code.coding.exists(system = 'https://icr.healthcampaigns.org/CodeSystem/icr-location-status-cs')"
* where[0].description = "Only location-status assertions (the ICR location-status code system)"
* select[0].column[0].name = "observation_id"
* select[0].column[0].path = "getResourceKey()"
* select[0].column[0].type = "id"
* select[0].column[1].name = "location_id"
* select[0].column[1].path = "subject.getReferenceKey(Location)"
* select[0].column[1].type = "string"
* select[0].column[2].name = "property"
* select[0].column[2].path = "code.coding.first().code"
* select[0].column[2].type = "code"
* select[0].column[2].description = "lf-endemicity | oncho-endemicity | schisto-endemicity | sth-endemicity | trachoma-endemicity | …"
* select[0].column[3].name = "status"
* select[0].column[3].path = "value.ofType(CodeableConcept).coding.first().code"
* select[0].column[3].type = "code"
* select[0].column[3].description = "endemic-mda-not-started | endemic-under-mda | post-mda-surveillance | elimination-validated | non-endemic | unknown"
* select[0].column[4].name = "effective"
* select[0].column[4].path = "effective.ofType(dateTime)"
* select[0].column[4].type = "dateTime"
* select[0].column[5].name = "performer"
* select[0].column[5].path = "performer.first().display"
* select[0].column[5].type = "string"
* select[0].column[6].name = "method"
* select[0].column[6].path = "method.text"
* select[0].column[6].type = "string"
* select[0].column[7].name = "evidence"
* select[0].column[7].path = "derivedFrom.first().display"
* select[0].column[7].type = "string"
* select[0].column[8].name = "figure_label"
* select[0].column[8].path = "component.first().code.text"
* select[0].column[8].type = "string"
* select[0].column[8].description = "What the first component measures (baseline prevalence at mapping, or the stop-survey result)"
* select[0].column[9].name = "figure_value"
* select[0].column[9].path = "component.first().value.ofType(Quantity).value"
* select[0].column[9].type = "decimal"
* select[0].column[10].name = "figure_unit"
* select[0].column[10].path = "component.first().value.ofType(Quantity).unit"
* select[0].column[10].type = "string"
