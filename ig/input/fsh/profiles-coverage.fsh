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
* measure MS
* measure ^short = "The canonical ICR coverage Measure this report instances — declares the populations and standard stratifiers (§8, v0.19.0)"
* period 1..1 MS
* reporter 1..1 MS
* reporter ^short = "Required (v0.20.0, §15 #7-bis): who reported this figure — the accountable supervisor (Practitioner/PractitionerRole) or their organization (the R4 reporter targets; CareTeam is not one — the team join rides extension[reporterTeam])"
* group MS
* group.stratifier MS
* group.stratifier.code from ICRCoverageStratifierVS (extensible)
* group.stratifier ^short = "Disaggregation by the standard axes (sex, age-band, delivery-strategy, disposition, geography) the Measure declares — extensible binding to ICRCoverageStratifierVS, so custom country axes stay legal (v0.19.0)"
* extension contains
    ReporterTeam named reporterTeam 0..1 MS and
    CoverageSource named coverageSource 1..1 MS and
    DenominatorSource named denominatorSource 0..1 MS and
    DenominatorType named denominatorType 0..1 MS and
    CoverageUnit named coverageUnit 0..1 MS and
    RealtimeVsReconciled named dataLineage 1..1 MS
* extension[coverageSource].valueCode = #administrative
* extension[denominatorType] ^short = "total-population vs at-risk/eligible (programme vs epidemiological coverage)"
* extension[coverageUnit] ^short = "people vs implementation-units (geographic coverage); absent ⇒ people"
* extension[dataLineage] ^short = "Required on coverage reports: preliminary in-campaign figures (realtime) vs final close-out figures (reconciled) must be distinguishable"

Profile: ICRSurveyCoverage
Parent: MeasureReport
Id: ICRSurveyCoverage
Title: "ICR Survey Coverage"
Description: "Independently-measured coverage — post-campaign cluster survey, LQAS, or RCM — with method, sample design, and date. A separately-sourced, first-class measure of the same quantity as administrative coverage: the two routinely diverge (Cuamba, Mozambique: ~99% admin vs ~76% survey) and must never be collapsed."
* ^experimental = false
* status MS
* type MS
* measure MS
* measure ^short = "The canonical ICR coverage Measure this survey report instances (§8, v0.19.0)"
* period 1..1 MS
* reporter 1..1 MS
* reporter ^short = "Required (v0.20.0, §15 #7-bis): who reported this figure — the accountable survey lead (Practitioner/PractitionerRole) or their organization (the R4 reporter targets; CareTeam is not one — the team join rides extension[reporterTeam])"
* group MS
* group.stratifier MS
* group.stratifier.code from ICRCoverageStratifierVS (extensible)
* group.stratifier ^short = "Disaggregation by the standard axes (ICRCoverageStratifierVS, extensible) the Measure declares (v0.19.0)"
* extension contains
    ReporterTeam named reporterTeam 0..1 MS and
    CoverageSource named coverageSource 1..1 MS and
    SampleDesign named sampleDesign 0..1 MS and
    DenominatorType named denominatorType 0..1 MS and
    CoverageUnit named coverageUnit 0..1 MS and
    RealtimeVsReconciled named dataLineage 1..1 MS
* extension[coverageSource].value[x] from ICRIndependentCoverageSourceVS (required)
* extension[sampleDesign] ^short = "Method / sample design of the independent measurement (e.g. WHO 30×10 cluster survey)"
* extension[dataLineage] ^short = "Required on coverage reports: preliminary survey results (realtime) vs final results (reconciled)"
