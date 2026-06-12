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

ValueSet: ICRMDAMedicationVS
Id: icr-mda-medication
Title: "ICR MDA Medication"
Description: "WHO ATC-coded preventive-chemotherapy medications. Binding: extensible — local formulary codes map back via ConceptMap. Includes the full ATC system; typical PC-NTD codes are albendazole P02CA03, ivermectin P02CA01, praziquantel P02BA01, azithromycin J01FA10, diethylcarbamazine P02CB02. Restricting to a PC-NTD subtree is deferred until country formularies are reviewed."
* ^experimental = false
* include codes from system $ATC
