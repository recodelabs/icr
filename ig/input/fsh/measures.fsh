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
* url = "https://fhir.icr.unicef.org/Measure/icr-admin-coverage"
* status = #active
* experimental = false
* name = "ICRAdminCoverage"
* title = "ICR Administrative Coverage"
* description = "Doses/treatments delivered ÷ planning denominator, from tallies. Disaggregable by sex, age band, delivery strategy and geography."
* scoring = $MeasureScoring#proportion "Proportion"
* group.population[0].code = $MeasurePopulation#numerator "Numerator"
* group.population[0].criteria.language = #text/cql
* group.population[0].criteria.expression = "Doses/treatments administered in the period (record-origin = campaign)"
* group.population[1].code = $MeasurePopulation#denominator "Denominator"
* group.population[1].criteria.language = #text/cql
* group.population[1].criteria.expression = "Planning denominator (the flagged ICRTargetPopulation for the geography)"
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
* url = "https://fhir.icr.unicef.org/Measure/icr-survey-coverage"
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

Instance: icr-mda-treatment-coverage
InstanceOf: Measure
Title: "ICR MDA Treatment Coverage Measure"
Usage: #definition
* url = "https://fhir.icr.unicef.org/Measure/icr-mda-treatment-coverage"
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
* url = "https://fhir.icr.unicef.org/Measure/icr-geographic-coverage"
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
