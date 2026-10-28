// Measure definitions (working doc §14 gap; §17.2 B2; espen-v3 round).
// The canonical Measures the coverage MeasureReports instance — each declares its
// numerator/denominator and the STANDARD stratifier axes (sex / age-band /
// delivery-strategy / disposition / geography), so disaggregated coverage is
// comparable across campaigns and countries. Criteria expressions are placeholders
// (text/cql) until the executable CQL is authored; the structural contract — what
// is counted and how it disaggregates — is what these pin down. Alignment to WHO
// IMMZ Measures (IMMZIND01–45) and VCQI/Annex L is the §18.4 / §17.2 B2 work.

Instance: icr-admin-coverage
InstanceOf: Measure
Title: "ICR Administrative Coverage Measure"
Usage: #definition
* url = "https://icr.healthcampaigns.org/Measure/icr-admin-coverage"
* status = #active
* experimental = false
* name = "ICRAdminCoverage"
* title = "ICR Administrative Coverage"
* description = "Doses/treatments delivered ÷ planning denominator, from tallies. Disaggregable by sex, age band, delivery strategy and geography. For an integrated campaign there is one report per activity (campaign-activity), each divided by that activity's own planning denominator."
* scoring = $MeasureScoring#proportion "Proportion"
* group.population[0].code = $MeasurePopulation#numerator "Numerator"
* group.population[0].criteria.language = #text/cql
* group.population[0].criteria.expression = "Doses/treatments administered in the period (record-origin = campaign); when the report names a campaign-activity, only that activity's (events naming it in campaign-activity, or from tasks instantiating it). Counted per visit Task and activity, never both ways: the distinct people with a completed event for the activity when the events are complete (their number equals the activity's treated-count, or the Task has none), otherwise the Task's treated-count. not-done events never count"
* group.population[1].code = $MeasurePopulation#denominator "Denominator"
* group.population[1].criteria.language = #text/cql
* group.population[1].criteria.expression = "Planning denominator: when the report names a campaign-activity, the planning-denominator(s) on the campaign's activity.detail for that activity (summed when several); otherwise, or when that activity names none, the campaign's planning-denominator"
* group.stratifier[0].code = $CoverageStratifier#sex "Sex"
* group.stratifier[0].criteria.language = #text/cql
* group.stratifier[0].criteria.expression = "Patient.gender"
* group.stratifier[1].code = $CoverageStratifier#age-band "Age band"
* group.stratifier[1].criteria.language = #text/cql
* group.stratifier[1].criteria.expression = "Eligibility age band"
* group.stratifier[2].code = $CoverageStratifier#delivery-strategy "Delivery strategy"
* group.stratifier[2].criteria.language = #text/cql
* group.stratifier[2].criteria.expression = "Task.delivery-strategy"
* group.stratifier[3].code = $CoverageStratifier#geography "Geography"
* group.stratifier[3].criteria.language = #text/cql
* group.stratifier[3].criteria.expression = "Reporting Location"

Instance: icr-survey-coverage
InstanceOf: Measure
Title: "ICR Survey Coverage Measure"
Usage: #definition
* url = "https://icr.healthcampaigns.org/Measure/icr-survey-coverage"
* status = #active
* experimental = false
* name = "ICRSurveyCoverage"
* title = "ICR Survey Coverage"
* description = "Independently-measured coverage (cluster survey / LQAS / RCM). A separately-sourced measure of the same quantity as administrative coverage; the two routinely diverge and must never be merged."
* scoring = $MeasureScoring#proportion "Proportion"
* group.population[0].code = $MeasurePopulation#numerator "Numerator"
* group.population[0].criteria.language = #text/cql
* group.population[0].criteria.expression = "Persons found covered in the survey sample"
* group.population[1].code = $MeasurePopulation#denominator "Denominator"
* group.population[1].criteria.language = #text/cql
* group.population[1].criteria.expression = "Survey sample (the sample IS the denominator)"
* group.stratifier[0].code = $CoverageStratifier#sex "Sex"
* group.stratifier[0].criteria.language = #text/cql
* group.stratifier[0].criteria.expression = "Patient.gender"
* group.stratifier[1].code = $CoverageStratifier#age-band "Age band"
* group.stratifier[1].criteria.language = #text/cql
* group.stratifier[1].criteria.expression = "Eligibility age band"
* group.stratifier[2].code = $CoverageStratifier#disposition "Disposition"
* group.stratifier[2].description = "Survey disposition — covered / not covered for cluster surveys; the lot verdict (pass / intermediate / fail, children missed) for LQAS"

Instance: icr-mda-treatment-coverage
InstanceOf: Measure
Title: "ICR MDA Treatment Coverage Measure"
Usage: #definition
* url = "https://icr.healthcampaigns.org/Measure/icr-mda-treatment-coverage"
* status = #active
* experimental = false
* name = "ICRMDATreatmentCoverage"
* title = "ICR MDA Treatment Coverage"
* description = "PC-NTD treatment coverage: persons treated ÷ at-risk/eligible population, disaggregated by sex, age band and treatment disposition (treated vs not-treated reason). The Measure behind the ESPEN treatment-form tally."
* scoring = $MeasureScoring#proportion "Proportion"
* group.population[0].code = $MeasurePopulation#numerator "Numerator"
* group.population[0].criteria.language = #text/cql
* group.population[0].criteria.expression = "Persons treated with a qualifying PC-NTD drug in the round"
* group.population[1].code = $MeasurePopulation#denominator "Denominator"
* group.population[1].criteria.language = #text/cql
* group.population[1].criteria.expression = "At-risk/eligible population for the round (denominator-type = at-risk)"
* group.stratifier[0].code = $CoverageStratifier#sex "Sex"
* group.stratifier[0].criteria.language = #text/cql
* group.stratifier[0].criteria.expression = "Patient.gender"
* group.stratifier[1].code = $CoverageStratifier#age-band "Age band"
* group.stratifier[1].criteria.language = #text/cql
* group.stratifier[1].criteria.expression = "Eligibility age band (5–14, 15+)"
* group.stratifier[2].code = $CoverageStratifier#disposition "Disposition"
* group.stratifier[2].criteria.language = #text/cql
* group.stratifier[2].criteria.expression = "Treatment disposition (treated | absent | refused | excluded-...)"

Instance: icr-geographic-coverage
InstanceOf: Measure
Title: "ICR Geographic Coverage Measure"
Usage: #definition
* url = "https://icr.healthcampaigns.org/Measure/icr-geographic-coverage"
* status = #active
* experimental = false
* name = "ICRGeographicCoverage"
* title = "ICR Geographic Coverage"
* description = "Implementation-unit coverage: settlements/areas treated ÷ total targeted (coverage-unit = implementation-units). The ESPEN supervision-form 'villages treated / total' figure, with non-treatment reasons as a stratifier."
* scoring = $MeasureScoring#proportion "Proportion"
* group.population[0].code = $MeasurePopulation#numerator "Numerator"
* group.population[0].criteria.language = #text/cql
* group.population[0].criteria.expression = "Implementation units (settlements/areas) treated in the round"
* group.population[1].code = $MeasurePopulation#denominator "Denominator"
* group.population[1].criteria.language = #text/cql
* group.population[1].criteria.expression = "Implementation units targeted in the round"
* group.stratifier[0].code = $CoverageStratifier#disposition "Disposition"
* group.stratifier[0].criteria.language = #text/cql
* group.stratifier[0].criteria.expression = "Non-treatment reason (medication-shortage | insecurity | difficult-access | not-required)"
* group.stratifier[1].code = $CoverageStratifier#geography "Geography"
* group.stratifier[1].criteria.language = #text/cql
* group.stratifier[1].criteria.expression = "Admin level of the reporting unit"

// --- DIGIT-mapping additions (project/ig-gaps-from-digit.md §3) ---------------
// Household coverage for ITN and other household-targeted campaigns. Both groups
// divide by the activity's planning denominator, which must count households
// (unit-of-count = household; icr-coverage-denominator-unit). Geography follows the
// household's residence (group-location), not the handover place. A household
// counts once per group however many handovers or registrations it had.

Instance: icr-household-coverage
InstanceOf: Measure
Title: "ICR Household Coverage Measure"
Usage: #definition
* url = "https://icr.healthcampaigns.org/Measure/icr-household-coverage"
* status = #active
* experimental = false
* name = "ICRHouseholdCoverage"
* title = "ICR Household Coverage"
* description = "Households reached ÷ households targeted, in two groups: distribution coverage (households that received the activity's product) and registration coverage (households registered into the round). The denominator is the activity's planning denominator, an ICRTargetPopulation with unit-of-count = household. Placeholder CQL pending executable logic."
* scoring = $MeasureScoring#proportion "Proportion"
* group[0].code.text = "Distribution coverage"
* group[0].description = "Households that received the activity's product in the round ÷ households targeted"
* group[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].population[0].criteria.language = #text/cql
* group[0].population[0].criteria.expression = "Distinct households (ICRDeliveryUnit) that are the extension[recipient] of an ICRSupplyDistribution with status = completed, suppliedItem.quantity > 0, the activity's product, and extension[campaign] = the round; counted where the household's group-location lies within the report geography"
* group[0].population[1].code = $MeasurePopulation#denominator "Denominator"
* group[0].population[1].criteria.language = #text/cql
* group[0].population[1].criteria.expression = "The activity's planning denominator (CarePlan.activity.detail planning-denominator, or the campaign's), which must have unit-of-count = household"
* group[0].stratifier[0].code = $CoverageStratifier#geography "Geography"
* group[0].stratifier[0].criteria.language = #text/cql
* group[0].stratifier[0].criteria.expression = "The household's residence (group-location), by admin level"
* group[1].code.text = "Registration coverage"
* group[1].description = "Households registered into the round ÷ households targeted"
* group[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[1].population[0].criteria.language = #text/cql
* group[1].population[0].criteria.expression = "Distinct households in output[registeredHousehold] of the round's ICRCampaignTasks, counted where the household's group-location lies within the report geography"
* group[1].population[1].code = $MeasurePopulation#denominator "Denominator"
* group[1].population[1].criteria.language = #text/cql
* group[1].population[1].criteria.expression = "The activity's planning denominator, which must have unit-of-count = household"
* group[1].stratifier[0].code = $CoverageStratifier#geography "Geography"
* group[1].stratifier[0].criteria.language = #text/cql
* group[1].stratifier[0].criteria.expression = "The household's residence (group-location), by admin level"

// --- v0.21.0 additions (forms-v1 round) ---------------------------------------

Instance: icr-zero-dose-coverage
InstanceOf: Measure
Title: "ICR Zero-dose Coverage Measure"
Usage: #definition
* url = "https://icr.healthcampaigns.org/Measure/icr-zero-dose-coverage"
* status = #active
* experimental = false
* name = "ICRZeroDoseCoverage"
* title = "ICR Zero-dose Coverage"
* description = "Zero-dose children reached in the round ÷ children reached, disaggregated by prior-dose status (dose-history). Turns the polio SIA tally's never/previously/no-recall split into a first-class measure of how many zero-dose children a campaign reaches — the equity signal behind zero-dose reduction. Placeholder CQL pending executable logic (forms-v1 / jul3-form-analysis §Aggregate #1)."
* scoring = $MeasureScoring#proportion "Proportion"
* group.population[0].code = $MeasurePopulation#numerator "Numerator"
* group.population[0].criteria.language = #text/cql
* group.population[0].criteria.expression = "Zero-dose children reached (prior-dose-status = zero-dose)"
* group.population[1].code = $MeasurePopulation#denominator "Denominator"
* group.population[1].criteria.language = #text/cql
* group.population[1].criteria.expression = "Children reached in the round"
* group.stratifier[0].code = $CoverageStratifier#dose-history "Dose history"
* group.stratifier[0].criteria.language = #text/cql
* group.stratifier[0].criteria.expression = "prior-dose-status (zero-dose | previously-received | no-recall)"
* group.stratifier[1].code = $CoverageStratifier#sex "Sex"
* group.stratifier[1].criteria.language = #text/cql
* group.stratifier[1].criteria.expression = "Patient.gender"
* group.stratifier[2].code = $CoverageStratifier#age-band "Age band"
* group.stratifier[2].criteria.language = #text/cql
* group.stratifier[2].criteria.expression = "Eligibility age band (0-11m, 12-59m, 5-9y)"

Instance: icr-campaign-readiness
InstanceOf: Measure
Title: "ICR Campaign Readiness Measure"
Usage: #definition
* url = "https://icr.healthcampaigns.org/Measure/icr-campaign-readiness"
* status = #active
* experimental = false
* name = "ICRCampaignReadiness"
* title = "ICR Campaign Readiness"
* description = "Pre-campaign readiness: operational units (wards/facilities) validated ready ÷ total targeted, from the readiness checklist (coverage-unit = implementation-units). Turns the UNICEF Preparedness Validation form into a roll-up readiness measure, stratified by readiness domain (microplan | cold-chain | social-mobilization | trainings). Placeholder CQL pending executable logic (forms-v1 / jul3-form-analysis §Aggregate #2)."
* scoring = $MeasureScoring#proportion "Proportion"
* group.population[0].code = $MeasurePopulation#numerator "Numerator"
* group.population[0].criteria.language = #text/cql
* group.population[0].criteria.expression = "Operational units validated ready (readiness checklist passed)"
* group.population[1].code = $MeasurePopulation#denominator "Denominator"
* group.population[1].criteria.language = #text/cql
* group.population[1].criteria.expression = "Operational units targeted for readiness validation"
* group.stratifier[0].code = $CoverageStratifier#geography "Geography"
* group.stratifier[0].criteria.language = #text/cql
* group.stratifier[0].criteria.expression = "Admin level of the reporting unit"
* group.stratifier[1].code = $CoverageStratifier#readiness-domain "Readiness domain"
* group.stratifier[1].criteria.language = #text/cql
* group.stratifier[1].criteria.expression = "Readiness checklist domain (microplan | cold-chain | social-mobilization | trainings)"

// --- cost-v1 -------------------------------------------------------------------

Instance: icr-campaign-cost
InstanceOf: Measure
Title: "ICR Campaign Cost Measure"
Usage: #definition
* url = "https://icr.healthcampaigns.org/Measure/icr-campaign-cost"
* status = #active
* experimental = false
* name = "ICRCampaignCost"
* title = "ICR Campaign Cost"
* description = "Total cost of a campaign (round) and its unit costs — per person targeted (÷ planning denominator), per person reached (÷ the administrative-coverage numerator for the same round, geography and data lineage) and per dose/treatment delivered — one group per figure (ICRCostFigureCS). Inputs are ICRCampaignCost line items filtered by the report's lineage, perspective, scope and allocation basis; the divisors are the same resources coverage already uses, so a unit cost never invents a denominator. Continuous-variable scoring: the money is the measureScore, the divisor sits in the group's denominator population. Placeholder CQL pending executable logic (cost-v1)."
* scoring = $MeasureScoring#continuous-variable "Continuous Variable"
* group[0].code = $CostFigure#total-cost "Total cost"
* group[0].population[0].code = $MeasurePopulation#measure-population "Measure Population"
* group[0].population[0].criteria.language = #text/cql
* group[0].population[0].criteria.expression = "ICRCampaignCost line items for the campaign whose subject is in the report geography's subtree (plus apportioned umbrella lines when fully-loaded), matching lineage / perspective / scope"
* group[0].stratifier[0].code = $CoverageStratifier#cost-category "Cost category"
* group[0].stratifier[0].criteria.language = #text/cql
* group[0].stratifier[0].criteria.expression = "ICRCampaignCost.code"
* group[0].stratifier[1].code = $CoverageStratifier#funding-source "Funding source"
* group[0].stratifier[1].criteria.language = #text/cql
* group[0].stratifier[1].criteria.expression = "ICRCampaignCost.funding-source"
* group[0].stratifier[2].code = $CoverageStratifier#geography "Geography"
* group[0].stratifier[2].criteria.language = #text/cql
* group[0].stratifier[2].criteria.expression = "ICRCampaignCost.subject (admin level)"
* group[1].code = $CostFigure#per-person-targeted "Cost per person targeted"
* group[1].population[0].code = $MeasurePopulation#denominator "Denominator"
* group[1].population[0].criteria.language = #text/cql
* group[1].population[0].criteria.expression = "Planning denominator, resolved as in icr-admin-coverage: the activity's (activity.detail) when the report names a campaign-activity, otherwise the campaign's; denominator-type as declared"
* group[1].stratifier[0].code = $CoverageStratifier#geography "Geography"
* group[1].stratifier[0].criteria.language = #text/cql
* group[1].stratifier[0].criteria.expression = "Reporting Location"
* group[2].code = $CostFigure#per-person-reached "Cost per person reached"
* group[2].population[0].code = $MeasurePopulation#denominator "Denominator"
* group[2].population[0].criteria.language = #text/cql
* group[2].population[0].criteria.expression = "icr-admin-coverage numerator for the same round, geography and data lineage"
* group[2].stratifier[0].code = $CoverageStratifier#delivery-strategy "Delivery strategy"
* group[2].stratifier[0].criteria.language = #text/cql
* group[2].stratifier[0].criteria.expression = "Task.delivery-strategy"
* group[2].stratifier[1].code = $CoverageStratifier#geography "Geography"
* group[2].stratifier[1].criteria.language = #text/cql
* group[2].stratifier[1].criteria.expression = "Reporting Location"
* group[3].code = $CostFigure#per-dose-delivered "Cost per dose / treatment delivered"
* group[3].population[0].code = $MeasurePopulation#denominator "Denominator"
* group[3].population[0].criteria.language = #text/cql
* group[3].population[0].criteria.expression = "Immunization / MedicationAdministration count in the round (record-origin = campaign)"
