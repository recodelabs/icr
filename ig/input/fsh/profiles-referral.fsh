// Referral profiles (project/ig-gaps-from-digit.md §2).
// A referral made during campaign work is a ServiceRequest (ICRReferral): who, to
// which facility, why, how urgent and for when, mapped from the WHO SMART HIV.I
// referral logical model. What the receiving facility did with it is a Task
// (ICRReferralFulfilment): received, arrived, seen, or never came. This is the
// ServiceRequest + Task pair that FHIR referral systems and IHE 360X closed-loop
// referral expect. The fulfilment is a separate workflow from ICRCampaignTask and
// is not counted as a campaign visit.
//
// Lifecycle: the request's content is not changed after it is made; its status
// is. active when made; completed when a fulfilment completes (the person was
// seen); revoked only by the referring programme, or with a note when the
// campaign follow-up period closes. A failed fulfilment (did not arrive) does not
// revoke the request. Whoever manages the fulfilment updates the request status.

Profile: ICRReferral
Parent: ServiceRequest
Id: ICRReferral
Title: "ICR Referral"
Description: "A referral of a person from campaign work to a facility or provider: an adverse event after a dose, fever or suspected malaria during SMC, acute malnutrition, a child excluded for illness, a zero-dose child sent to routine immunization, a pregnant woman excluded from MDA and sent to antenatal care. The receiving facility's follow-up is an ICRReferralFulfilment whose focus is this request. A referral the facility recorded with no field referral (for example a DIGIT HFReferral) is also an ICRReferral, with requester absent and an identifier carrying the facility record's id."
* ^experimental = false
* identifier ^short = "Source record ids, for example the facility referral id when the request was created from a facility record"
* status MS
* status ^short = "active when made → completed when a fulfilment completes; revoked when withdrawn by the referring programme, merged into another referral, or closed at the end of the follow-up period (with a note). A failed fulfilment does not revoke it"
* intent = #order
* category 1..1 MS
* category = $ReferralCategory#campaign-referral
* category ^short = "Fixed: campaign-referral"
* priority MS
* priority ^short = "urgent for an emergency referral, otherwise routine"
* subject 1..1 MS
* subject only Reference(ICRPatient)
* subject ^short = "The person referred"
* basedOn 1..1 MS
* basedOn only Reference(ICRCampaign)
* basedOn ^short = "The campaign (round) in which the referral was made"
* requester MS
* requester only Reference(Practitioner or PractitionerRole)
* requester ^short = "The referring worker (and, through PractitionerRole, their facility). Absent on a referral created from a facility record"
* performer MS
* performer only Reference(ICRFacilityOrganization or Organization or PractitionerRole or Practitioner)
* performer ^short = "Whom the person is referred to: the receiving facility's Organization, or a named provider (PractitionerRole where one exists, otherwise Practitioner). A Location is not a legal performer"
* locationReference MS
* locationReference only Reference(ICRLocation)
* locationReference ^short = "The receiving facility's Location: where the person is to go"
* authoredOn 1..1 MS
* authoredOn ^short = "When the referral was made"
* occurrence[x] MS
* occurrence[x] ^short = "The scheduled appointment, where given"
* reasonCode 1..* MS
* reasonCode from ICRReferralReasonVS (extensible)
* reasonCode ^short = "Why the person was referred (ICR codes, mapped to SNOMED CT by ConceptMap icr-referral-reason-to-snomed)"
* supportingInfo MS
* supportingInfo only Reference(ICRAdverseEvent or ICRMedicationAdministration or ICRImmunizationEvent)
* supportingInfo ^short = "The adverse event that caused the referral, and any treatment given before referral. R4 reasonReference cannot reference an AdverseEvent"
* note MS
* note ^short = "Referral notes"
* extension contains ReferringTask named referringTask 0..1 MS
* extension[referringTask] ^short = "The campaign visit (ICRCampaignTask) at which the referral was made"

Profile: ICRReferralFulfilment
Parent: Task
Id: ICRReferralFulfilment
Title: "ICR Referral Fulfilment"
Description: "What the receiving facility did with an ICRReferral: received it, the person arrived and was seen, or never came. A separate workflow from ICRCampaignTask, excluded from campaign visit counts. When it completes, the referral's status becomes completed; when it fails, the referral stays active."
* ^experimental = false
* status MS
* status ^short = "requested → received / accepted → completed (arrived and seen) / failed (did not arrive) / cancelled"
* businessStatus MS
* businessStatus ^short = "Finer outcome, for example arrived, not arrived, referred on"
* intent = #order
* focus 1..1 MS
* focus only Reference(ICRReferral)
* focus ^short = "The referral this follow-up acts on"
* for 1..1 MS
* for only Reference(ICRPatient)
* for ^short = "The person referred"
* owner MS
* owner only Reference(ICRFacilityOrganization or Organization or PractitionerRole)
* owner ^short = "The receiving facility's Organization (or the receiving provider's PractitionerRole)"
* location MS
* location only Reference(ICRLocation)
* location ^short = "The receiving facility's Location"
* executionPeriod MS
* executionPeriod ^short = "When the person was received"
