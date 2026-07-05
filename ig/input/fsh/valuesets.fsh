// ICR value sets (working doc §8): ICR-defined sets for campaign semantics,
// international product codes (CVX / ATC) with local codes joined via ConceptMap.

ValueSet: ICRCampaignTypeVS
Id: icr-campaign-type
Title: "ICR Campaign Type"
Description: "Campaign types by delivery model. Binding: required on ICRCampaignProtocol.type and ICRCampaign.category."
* ^experimental = false
* include codes from system ICRCampaignTypeCS

ValueSet: ICRDeliveryStrategyVS
Id: icr-delivery-strategy
Title: "ICR Delivery Strategy"
Description: "Delivery strategies. Binding: required on the delivery-strategy extension."
* ^experimental = false
* include codes from system ICRDeliveryStrategyCS

ValueSet: ICRRecordOriginVS
Id: icr-record-origin
Title: "ICR Record Origin"
Description: "Campaign vs routine record origin. Binding: required on the record-origin extension."
* ^experimental = false
* include codes from system ICRRecordOriginCS

ValueSet: ICRGroupKindVS
Id: icr-group-kind
Title: "ICR Group Kind"
Description: "Delivery-unit Group kinds (household / community). Binding: required on ICRDeliveryUnit.code."
* ^experimental = false
* include codes from system ICRGroupKindCS

ValueSet: ICRTaskOriginVS
Id: icr-task-origin
Title: "ICR Task Origin"
Description: "Pre-planned vs field-registered task origin. Binding: required on the task-origin extension."
* ^experimental = false
* include codes from system ICRTaskOriginCS

ValueSet: ICRLocationTypeVS
Id: icr-location-type
Title: "ICR Location Type"
Description: "Campaign-relevant location types, including operational geography. Binding: extensible on ICRLocation.type — countries may add local types."
* ^experimental = false
* include codes from system ICRLocationTypeCS

ValueSet: ICRMissedReasonVS
Id: icr-missed-reason
Title: "ICR Missed Reason"
Description: "Reasons an eligible person/household was missed. Binding: extensible — countries may add local codes."
* ^experimental = false
* include codes from system ICRMissedReasonCS

ValueSet: ICRNoncomplianceReasonVS
Id: icr-noncompliance-reason
Title: "ICR Noncompliance Reason"
Description: "Reasons for refusal/noncompliance. Binding: extensible — countries may add local codes."
* ^experimental = false
* include codes from system ICRNoncomplianceReasonCS

ValueSet: ICRExclusionReasonVS
Id: icr-exclusion-reason
Title: "ICR Exclusion Reason"
Description: "Reasons a present, age-eligible person was clinically excluded from treatment (under-height/age, pregnant, breastfeeding, acutely ill). Binding: extensible — countries may add local codes."
* ^experimental = false
* include codes from system ICRExclusionReasonCS

ValueSet: ICRSuppliedItemVS
Id: icr-supplied-item
Title: "ICR Supplied Item"
Description: "Coded products distributed via ICRSupplyDelivery. Binding: extensible. Drug commodities (MDA receipts/distribution) use WHO ATC; physical commodities (ITNs, IRS consumables, vitamin A) use GS1 GTIN where a local binding exists, otherwise text. Added v0.18.0 (espen.md rec 3) so a drug receipt → administration → reconciliation share one ATC code."
* ^experimental = false
* include codes from system $ATC

ValueSet: ICRDenominatorSourceVS
Id: icr-denominator-source
Title: "ICR Denominator Source"
Description: "Sources of population denominators. Binding: extensible."
* ^experimental = false
* include codes from system ICRDenominatorSourceCS

ValueSet: ICRDataLineageVS
Id: icr-data-lineage
Title: "ICR Data Lineage"
Description: "Real-time vs reconciled lineage. Binding: required on the realtime-vs-reconciled extension."
* ^experimental = false
* include codes from system ICRDataLineageCS

ValueSet: ICRCoverageSourceVS
Id: icr-coverage-source
Title: "ICR Coverage Source"
Description: "All coverage measurement lineages."
* ^experimental = false
* include codes from system ICRCoverageSourceCS

ValueSet: ICRIndependentCoverageSourceVS
Id: icr-independent-coverage-source
Title: "ICR Independent Coverage Source"
Description: "Independently-measured coverage lineages only (survey / LQAS / RCM) — the ICRSurveyCoverage binding."
* ^experimental = false
* ICRCoverageSourceCS#survey
* ICRCoverageSourceCS#lqas
* ICRCoverageSourceCS#rcm

ValueSet: ICRCoverageStratifierVS
Id: icr-coverage-stratifier
Title: "ICR Coverage Stratifier"
Description: "Standard coverage disaggregation axes. Binding: extensible on the Measure/MeasureReport stratifier code (espen-v3 / §17.2 B1)."
* ^experimental = false
* include codes from system ICRCoverageStratifierCS

ValueSet: ICRDenominatorTypeVS
Id: icr-denominator-type
Title: "ICR Denominator Type"
Description: "Total-population vs at-risk/eligible denominator. Binding: required on the denominator-type extension."
* ^experimental = false
* include codes from system ICRDenominatorTypeCS

ValueSet: ICRCoverageUnitVS
Id: icr-coverage-unit
Title: "ICR Coverage Unit"
Description: "People vs implementation-units (geographic coverage). Binding: required on the coverage-unit extension."
* ^experimental = false
* include codes from system ICRCoverageUnitCS

ValueSet: ICRAdverseEventCausalityVS
Id: icr-adverse-event-causality
Title: "ICR Adverse Event Causality"
Description: "WHO/CIOMS causality categories. Binding: extensible on ICRAdverseEvent causality assessment."
* ^experimental = false
* include codes from system ICRAdverseEventCausalityCS

ValueSet: ICRTeamRoleVS
Id: icr-team-role
Title: "ICR Team Role"
Description: "Campaign CareTeam member roles. Binding: extensible on ICRCareTeam.participant.role."
* ^experimental = false
* include codes from system ICRTeamRoleCS

ValueSet: ICRCommunicationChannelVS
Id: icr-communication-channel
Title: "ICR Communication Channel"
Description: "Social-mobilization channels. Binding: extensible on the social-mobilization extension's channel."
* ^experimental = false
* include codes from system ICRCommunicationChannelCS

ValueSet: ICRAdverseEventSeriousnessVS
Id: icr-adverse-event-seriousness
Title: "ICR Adverse Event Seriousness"
Description: "Serious vs non-serious. Binding: extensible on ICRAdverseEvent.seriousness — uses the HL7 adverse-event-seriousness code system."
* ^experimental = false
* include codes from system $AESeriousness

ValueSet: ICRSeriousCriteriaVS
Id: icr-serious-criteria
Title: "ICR Serious-Event Criteria"
Description: "WHO/CIOMS serious-event criteria. Binding: extensible on the serious-criteria extension."
* ^experimental = false
* include codes from system ICRSeriousCriteriaCS

// --- v0.21.0 additions (forms-v1 round) ---------------------------------------

ValueSet: ICRDoseHistoryVS
Id: icr-dose-history
Title: "ICR Dose History / Zero-dose Status"
Description: "Prior-dose status (zero-dose / previously-received / no-recall). Binding: required on the prior-dose-status extension; also the value space of the dose-history coverage stratifier (forms-v1)."
* ^experimental = false
* include codes from system ICRDoseHistoryCS

ValueSet: ICRRevisitOutcomeVS
Id: icr-revisit-outcome
Title: "ICR Revisit Outcome"
Description: "Outcome of a follow-up revisit (already-vaccinated / vaccinated-on-revisit / still-missing). Binding: extensible on the revisit-outcome extension (forms-v1)."
* ^experimental = false
* include codes from system ICRRevisitOutcomeCS

ValueSet: ICRSettlementTypeVS
Id: icr-settlement-type
Title: "ICR Settlement / Special-population Type"
Description: "Settlement / special-population classification of a Location. Binding: extensible on the settlement-type extension — countries add local codes (forms-v1)."
* ^experimental = false
* include codes from system ICRSettlementTypeCS

ValueSet: ICRMDAMedicationVS
Id: icr-mda-medication
Title: "ICR MDA Medication"
Description: "WHO ATC-coded preventive-chemotherapy medications. Binding: extensible — local formulary codes map back via ConceptMap. Includes the full ATC system; typical PC-NTD codes are albendazole P02CA03, ivermectin P02CA01, praziquantel P02BA01, azithromycin J01FA10, diethylcarbamazine P02CB02. Restricting to a PC-NTD subtree is deferred until country formularies are reviewed."
* ^experimental = false
* include codes from system $ATC

// --- espen-forms ----------------------------------------------------------------

ValueSet: ICRNTDDiseaseVS
Id: icr-ntd-disease-vs
Title: "ICR NTD Disease"
Description: "Diseases covered by an MDA campaign (espen-forms)."
* ^experimental = false
* include codes from system ICRNTDDiseaseCS

ValueSet: ICRMDAMedicinePackageVS
Id: icr-mda-medicine-package-vs
Title: "ICR MDA Medicine Package"
Description: "MDA medicine packages, single and combined (espen-forms)."
* ^experimental = false
* include codes from system ICRMDAMedicinePackageCS
