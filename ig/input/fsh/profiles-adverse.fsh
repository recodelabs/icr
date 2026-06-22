// Adverse-event profile (working doc §17.2 C1, espen-v3 round).
// Intervention-neutral by design: one profile for an adverse event following ANY
// campaign intervention — AEFI after a vaccine dose AND a side-effect after an MDA
// drug (the ESPEN treatment/supervision forms count both). The immunization arm is
// intended to align with / specialize WHO IMMZ.AdverseEvent (§18.3); ICR adds the
// campaign-vs-routine record-origin firewall so a campaign AE stays separable from
// routine pharmacovigilance.

Profile: ICRAdverseEvent
Parent: AdverseEvent
Id: ICRAdverseEvent
Title: "ICR Adverse Event"
Description: "An adverse event following a campaign intervention — vaccine (AEFI) or MDA drug (pharmacovigilance) alike. The suspected product/event is referenced via suspectEntity; causality uses the WHO/CIOMS classification; seriousness/severity carry the minor-vs-serious distinction the field forms collect. Carries the required campaign-vs-routine record origin. Intervention-neutral so it serves both the immunization and MDA arms (working doc §17.2 C1)."
* ^experimental = false
* actuality MS
* actuality ^short = "actual | potential"
* category MS
* event MS
* event ^short = "What happened (fever, abscess, abdominal pain, anaphylaxis…) — code from a clinical terminology"
* subject MS
* subject only Reference(Patient or ICRDeliveryUnit)
* subject ^short = "The affected person, or the community/household delivery-unit Group for aggregate pharmacovigilance counts"
* date MS
* seriousness MS
* seriousness from ICRAdverseEventSeriousnessVS (extensible)
* seriousness ^short = "Serious vs non-serious — the ESPEN minor/serious side-effect distinction"
* severity MS
* severity ^short = "mild | moderate | severe"
* suspectEntity MS
* suspectEntity.instance MS
* suspectEntity.instance only Reference(ICRImmunizationEvent or ICRMedicationAdministration or Medication or Substance)
* suspectEntity.instance ^short = "The suspected product or delivery event — the campaign vaccine dose or MDA administration (or the Medication/Substance itself)"
* suspectEntity.causality MS
* suspectEntity.causality.assessment from ICRAdverseEventCausalityVS (extensible)
* suspectEntity.causality.assessment ^short = "WHO/CIOMS causality category (A/B/C/D); immunization may use IMMZ finer A1–A4 subtypes"
* extension contains
    RecordOrigin named recordOrigin 1..1 MS and
    SeriousCriteria named seriousCriteria 0..* MS
* extension[seriousCriteria] ^short = "Why it is serious — WHO/CIOMS criteria (death, life-threatening, hospitalization…); present when seriousness = serious (v0.20.0)"
