// ConceptMaps (working doc §17.2 C1, §18.3/§18.4; espen-v4 round).
// ICR adverse-event causality ↔ WHO SMART Immunizations AEFI causality. ICR's
// codes are the top-level WHO/CIOMS categories (A/B/C/D); the immunization arm of
// ICRAdverseEvent is meant to specialize WHO IMMZ.AdverseEvent, so a campaign AEFI
// is a valid WHO immunization adverse event. TARGET CODES ARE PROVISIONAL — confirm
// against the published smart.who.int/immunizations IG before relying on them.

Instance: icr-aefi-causality-to-immz
InstanceOf: ConceptMap
Title: "ICR ↔ WHO IMMZ AEFI Causality"
Usage: #definition
* url = "https://icr.healthcampaigns.org/ConceptMap/icr-aefi-causality-to-immz"
* status = #draft
* experimental = false
* name = "ICRAEFICausalityToIMMZ"
* description = "Maps ICRAdverseEventCausalityCS (WHO/CIOMS A/B/C/D) to the WHO SMART Immunizations AEFI causality categories. Provisional — target codes to be confirmed against the published IMMZ IG (§18.3)."
* sourceCanonical = "https://icr.healthcampaigns.org/ValueSet/icr-adverse-event-causality"
* targetCanonical = "http://smart.who.int/immunizations/ValueSet/IMMZ-aefi-causality"
* group.source = $AdverseEventCausality
* group.target = $IMMZAdverseEventCausality
* group.element[0].code = #a-consistent
* group.element[0].display = "A — Consistent causal association"
* group.element[0].target.code = #A
* group.element[0].target.display = "Consistent causal association to immunization"
* group.element[0].target.equivalence = #equivalent
* group.element[1].code = #b-indeterminate
* group.element[1].display = "B — Indeterminate"
* group.element[1].target.code = #B
* group.element[1].target.display = "Indeterminate"
* group.element[1].target.equivalence = #equivalent
* group.element[2].code = #c-coincidental
* group.element[2].display = "C — Coincidental / inconsistent"
* group.element[2].target.code = #C
* group.element[2].target.display = "Coincidental (inconsistent causal association)"
* group.element[2].target.equivalence = #equivalent
* group.element[3].code = #d-unclassifiable
* group.element[3].display = "D — Unclassifiable"
* group.element[3].target.code = #D
* group.element[3].target.display = "Unclassifiable"
* group.element[3].target.equivalence = #equivalent

// ICR referral reasons → SNOMED CT (project/ig-gaps-from-digit.md §2). Follows the
// SMART pattern: the data carries ICR codes, the IG publishes the map, so SNOMED
// licensing stays out of the data. Pinned to the SNOMED CT International Edition
// 2025-02-01; all targets were checked active on tx.fhir.org (Oct 26, 2026).
// equivalence is the R4 value, read as "the target is … the source". R4 cmd-1
// requires a comment on narrower and inexact maps; every narrower, wider and
// relatedto target carries one.

Instance: icr-referral-reason-to-snomed
InstanceOf: ConceptMap
Title: "ICR Referral Reason to SNOMED CT"
Usage: #definition
* url = "https://icr.healthcampaigns.org/ConceptMap/icr-referral-reason-to-snomed"
* status = #draft
* experimental = false
* name = "ICRReferralReasonToSNOMED"
* description = "Maps ICRReferralReasonCS to SNOMED CT (International Edition 2025-02-01), with the equivalence of each target. The data carries ICR codes; this map is for analysis and exchange with systems that use SNOMED CT."
* copyright = "This ConceptMap includes content from SNOMED CT, which is copyright © 2002+ International Health Terminology Standards Development Organisation (SNOMED International), and distributed by agreement between SNOMED International and HL7. Implementer use of SNOMED CT is not covered by this agreement."
* sourceCanonical = "https://icr.healthcampaigns.org/ValueSet/icr-referral-reason"
* targetCanonical = "http://snomed.info/sct?fhir_vs"
* group.source = $ReferralReason
* group.target = $SCT
* group.targetVersion = "http://snomed.info/sct/900000000000207008/version/20250201"
* group.element[0].code = #vaccine-adverse-event
* group.element[0].display = "Adverse event after a vaccine"
* group.element[0].target.code = #293104008
* group.element[0].target.display = "Vaccine adverse reaction"
* group.element[0].target.equivalence = #narrower
* group.element[0].target.comment = "The target asserts the vaccine caused the event; ICRAdverseEvent keeps causality separate."
* group.element[1].code = #drug-adverse-event
* group.element[1].display = "Adverse event after a drug"
* group.element[1].target.code = #62014003
* group.element[1].target.display = "Adverse reaction to drug"
* group.element[1].target.equivalence = #narrower
* group.element[1].target.comment = "The target asserts the drug caused the event; ICRAdverseEvent keeps causality separate."
* group.element[2].code = #fever
* group.element[2].display = "Fever"
* group.element[2].target.code = #386661006
* group.element[2].target.display = "Fever"
* group.element[2].target.equivalence = #equivalent
* group.element[3].code = #suspected-malaria
* group.element[3].display = "Suspected malaria"
* group.element[3].target.code = #772168000
* group.element[3].target.display = "Malaria suspected"
* group.element[3].target.equivalence = #equivalent
* group.element[4].code = #acute-malnutrition
* group.element[4].display = "Acute malnutrition"
* group.element[4].target.code = #762497007
* group.element[4].target.display = "Acute malnutrition in childhood"
* group.element[4].target.equivalence = #narrower
* group.element[4].target.comment = "The target is childhood only. A search on Oct 26, 2026 found no 'severe acute malnutrition' concept; severity comes from the MUAC measurement."
* group.element[5].code = #zero-dose-to-routine
* group.element[5].display = "Zero-dose child, to routine immunization"
* group.element[5].target.code = #401179006
* group.element[5].target.display = "No previous immunizations"
* group.element[5].target.equivalence = #relatedto
* group.element[5].target.comment = "The target is the finding; the referral purpose is in the ICR code."
* group.element[6].code = #illness
* group.element[6].display = "Excluded for illness"
* group.element[6].target.code = #39104002
* group.element[6].target.display = "Illness"
* group.element[6].target.equivalence = #wider
* group.element[6].target.comment = "The ICR code is illness found at a campaign contact."
* group.element[7].code = #pregnancy
* group.element[7].display = "Pregnancy"
* group.element[7].target.code = #77386006
* group.element[7].target.display = "Pregnancy"
* group.element[7].target.equivalence = #equivalent
* group.element[8].code = #other
* group.element[8].display = "Other"
* group.element[8].target.equivalence = #unmatched
* group.element[8].target.comment = "No SNOMED CT target; the reason is in text."
