// Coverage & analytics profiles (working doc §7.9, §4.1).
// Administrative and independently-measured coverage are distinct lineages of the
// same conceptual quantity — separately profiled, never merged. Measure definitions
// behind these reports align with the reporting minimums ministries already owe
// (WHO JAP, ICG M&E minimum dataset, ESPEN treatment-coverage schema, WHO EPI).

// Coverage reports name their denominator (project/ig-gaps-from-digit.md §3). This
// applies to the Measures whose denominator is a target population:
// icr-household-coverage (households) and icr-admin-coverage and
// icr-mda-treatment-coverage (people). Other coverage Measures divide by a count
// that is not a target population (people reached, survey sample, units
// targeted). Each marked reference must resolve before its unit is tested: a
// reference the validator cannot resolve fails the unit check rather than passing
// unseen (R4 resolve() drops unresolved items), hence warning severity.
Invariant: icr-coverage-denominator-named
Description: "A report for icr-household-coverage, icr-admin-coverage or icr-mda-treatment-coverage that reports a denominator count names the target population(s) it divided by in evaluatedResource, marked evaluated-role = denominator."
Severity: #warning
Expression: "((measure.startsWith('https://icr.healthcampaigns.org/Measure/icr-household-coverage') or measure.startsWith('https://icr.healthcampaigns.org/Measure/icr-admin-coverage') or measure.startsWith('https://icr.healthcampaigns.org/Measure/icr-mda-treatment-coverage')) and group.population.where(code.coding.where(code = 'denominator').exists() and count.exists()).exists()) implies evaluatedResource.where(extension('https://icr.healthcampaigns.org/StructureDefinition/evaluated-role').value = 'denominator').exists()"

Invariant: icr-coverage-denominator-unit
Description: "Every marked denominator resolves to a Group, and on an icr-household-coverage report has unit-of-count = household; on an icr-admin-coverage or icr-mda-treatment-coverage report it has no unit other than person. A denominator the validator cannot resolve fails this check."
Severity: #warning
Expression: "(measure.startsWith('https://icr.healthcampaigns.org/Measure/icr-household-coverage') implies evaluatedResource.where(extension('https://icr.healthcampaigns.org/StructureDefinition/evaluated-role').value = 'denominator').all(resolve().exists() and resolve().modifierExtension.where(url = 'https://icr.healthcampaigns.org/StructureDefinition/unit-of-count').value = 'household')) and ((measure.startsWith('https://icr.healthcampaigns.org/Measure/icr-admin-coverage') or measure.startsWith('https://icr.healthcampaigns.org/Measure/icr-mda-treatment-coverage')) implies evaluatedResource.where(extension('https://icr.healthcampaigns.org/StructureDefinition/evaluated-role').value = 'denominator').all(resolve().exists() and (resolve().modifierExtension.where(url = 'https://icr.healthcampaigns.org/StructureDefinition/unit-of-count').empty() or resolve().modifierExtension.where(url = 'https://icr.healthcampaigns.org/StructureDefinition/unit-of-count').value = 'person')))"

Profile: ICRAdministrativeCoverage
Parent: MeasureReport
Id: ICRAdministrativeCoverage
Title: "ICR Administrative Coverage"
Description: "Administrative coverage: doses/treatments delivered ÷ planning denominator, computed from tallies. Carries denominator provenance and is permanently marked source=administrative. Names the ICRTargetPopulation(s) it divided by in evaluatedResource[denominator]."
* ^experimental = false
* obeys icr-coverage-denominator-named and icr-coverage-denominator-unit
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
* evaluatedResource MS
* evaluatedResource ^slicing.discriminator.type = #value
* evaluatedResource ^slicing.discriminator.path = "extension('https://icr.healthcampaigns.org/StructureDefinition/evaluated-role').value"
* evaluatedResource ^slicing.rules = #open
* evaluatedResource contains denominator 0..* MS
* evaluatedResource[denominator] only Reference(ICRTargetPopulation)
* evaluatedResource[denominator] ^short = "The ICRTargetPopulation(s) this report divided by, marked evaluated-role = denominator. Expected whenever an icr-household-coverage, icr-admin-coverage or icr-mda-treatment-coverage report gives a denominator count (icr-coverage-denominator-named). Each must resolve; on icr-household-coverage each has unit-of-count = household, on the person Measures none has a non-person unit (icr-coverage-denominator-unit)"
* evaluatedResource[denominator].extension contains EvaluatedRole named evaluatedRole 1..1 MS
* evaluatedResource[denominator].extension[evaluatedRole].valueCode = #denominator
* extension contains
    Campaign named campaign 0..1 MS and
    CampaignActivity named campaignActivity 0..1 MS and
    ReporterTeam named reporterTeam 0..1 MS and
    CoverageSource named coverageSource 1..1 MS and
    DenominatorSource named denominatorSource 0..1 MS and
    DenominatorType named denominatorType 0..1 MS and
    CoverageUnit named coverageUnit 0..1 MS and
    RealtimeVsReconciled named dataLineage 1..1 MS
* extension[campaign] ^short = "The campaign (round) this coverage figure reports against — the direct MeasureReport→ICRCampaign join (same extension as the delivery events). Expected on every campaign coverage report; only transiently absent on form-extracted reports before ingestion enrichment assigns the round"
* extension[campaignActivity] ^short = "In an integrated campaign, the activity this figure covers: the denominator is that activity's planning denominator (CarePlan.activity.detail), the numerator only its doses or treatments. One report per activity"
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
    Campaign named campaign 0..1 MS and
    CampaignActivity named campaignActivity 0..1 MS and
    ReporterTeam named reporterTeam 0..1 MS and
    CoverageSource named coverageSource 1..1 MS and
    SampleDesign named sampleDesign 0..1 MS and
    ConfidenceInterval named confidenceInterval 0..1 MS and
    DenominatorType named denominatorType 0..1 MS and
    CoverageUnit named coverageUnit 0..1 MS and
    RealtimeVsReconciled named dataLineage 1..1 MS
* extension[campaign] ^short = "The campaign (round) this survey/LQAS measurement assesses — the direct MeasureReport→ICRCampaign join (same extension as the delivery events)"
* extension[campaignActivity] ^short = "In an integrated campaign, the activity this survey measures coverage of (a survey usually asks about each intervention separately)"
* extension[confidenceInterval] ^short = "Structured CI of the estimate (low / high / level), same unit as measureScore — so dashboards can draw it and admin-vs-survey comparisons can test containment"
* extension[coverageSource].value[x] from ICRIndependentCoverageSourceVS (required)
* extension[sampleDesign] ^short = "Method / sample design of the independent measurement (e.g. WHO 30×10 cluster survey)"
* extension[dataLineage] ^short = "Required on coverage reports: preliminary survey results (realtime) vs final results (reconciled)"
