// Coverage & analytics profiles (working doc §7.9, §4.1).
// Administrative and independently-measured coverage are distinct lineages of the
// same conceptual quantity — separately profiled, never merged. Measure definitions
// behind these reports align with the reporting minimums ministries already owe
// (WHO JAP, ICG M&E minimum dataset, ESPEN treatment-coverage schema, WHO EPI).

Profile: ICRAdministrativeCoverage
Parent: MeasureReport
Id: ICRAdministrativeCoverage
Title: "ICR Administrative Coverage"
Description: "Administrative coverage: doses/treatments delivered ÷ planning denominator, computed from tallies. Carries denominator provenance and is permanently marked source=administrative."
* ^experimental = false
* status MS
* type MS
* period 1..1 MS
* reporter MS
* group MS
* extension contains
    CoverageSource named coverageSource 1..1 MS and
    DenominatorSource named denominatorSource 0..1 MS and
    RealtimeVsReconciled named dataLineage 1..1 MS
* extension[coverageSource].valueCode = #administrative
* extension[dataLineage] ^short = "Required on coverage reports: preliminary in-campaign figures (realtime) vs final close-out figures (reconciled) must be distinguishable"

Profile: ICRSurveyCoverage
Parent: MeasureReport
Id: ICRSurveyCoverage
Title: "ICR Survey Coverage"
Description: "Independently-measured coverage — post-campaign cluster survey, LQAS, or RCM — with method, sample design, and date. A separately-sourced, first-class measure of the same quantity as administrative coverage: the two routinely diverge (Cuamba, Mozambique: ~99% admin vs ~76% survey) and must never be collapsed."
* ^experimental = false
* status MS
* type MS
* period 1..1 MS
* reporter MS
* group MS
* extension contains
    CoverageSource named coverageSource 1..1 MS and
    SampleDesign named sampleDesign 0..1 MS and
    RealtimeVsReconciled named dataLineage 1..1 MS
* extension[coverageSource].value[x] from ICRIndependentCoverageSourceVS (required)
* extension[sampleDesign] ^short = "Method / sample design of the independent measurement (e.g. WHO 30×10 cluster survey)"
* extension[dataLineage] ^short = "Required on coverage reports: preliminary survey results (realtime) vs final results (reconciled)"
