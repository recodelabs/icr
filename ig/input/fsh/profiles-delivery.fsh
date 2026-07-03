// Delivery-event profiles (working doc §7.8).
// Every delivery event carries the required record-origin extension (campaign vs
// routine — working doc §4.4). R4 Immunization has no basedOn, so the Task→event
// link runs through Task.output (working doc §7.8 note).

Profile: ICRImmunizationEvent
Parent: Immunization
Id: ICRImmunizationEvent
Title: "ICR Immunization Event"
Description: "A vaccination delivery event: CVX-coded, with lot accountability and the required campaign-vs-routine record origin."
* ^experimental = false
* status MS
* vaccineCode MS
* vaccineCode from $VaccineCodeVS (extensible)
* vaccineCode ^short = "CVX-coded; local codes map back via ConceptMap (working doc §8)"
* patient MS
* occurrence[x] MS
* location MS
* lotNumber MS
* manufacturer MS
* performer MS
* protocolApplied MS
* protocolApplied ^short = "Dose number / series — supports multi-dose campaigns (OCV) and routine integration"
* extension contains
    RecordOrigin named recordOrigin 1..1 MS and
    PriorDoseStatus named priorDoseStatus 0..1 MS
* extension[priorDoseStatus] ^short = "Prior-dose (zero-dose) status of the antigen at this contact — zero-dose | previously-received | no-recall (v0.21.0)"

Profile: ICRMedicationAdministration
Parent: MedicationAdministration
Id: ICRMedicationAdministration
Title: "ICR Medication Administration"
Description: "An MDA treatment event: ATC-coded preventive chemotherapy with directly-observed consumption, dosage derived from a dose-pole height Observation, and the required record origin."
* ^experimental = false
* status MS
* medication[x] only CodeableConcept
* medicationCodeableConcept from ICRMDAMedicationVS (extensible)
* medicationCodeableConcept ^short = "WHO ATC-coded (albendazole, ivermectin, praziquantel, azithromycin…)"
* subject MS
* subject only Reference(Patient or ICRDeliveryUnit)
* subject ^short = "The treated person, or the community/household delivery-unit Group for register-level capture"
* effective[x] MS
* dosage MS
* dosage ^short = "Tablet count — in the field usually derived from a dose-pole height band Observation"
* supportingInformation MS
* supportingInformation ^short = "e.g. the dose-pole Observation the dosage was derived from"
* extension contains
    RecordOrigin named recordOrigin 1..1 MS and
    DirectlyObservedConsumption named directlyObserved 0..1 MS and
    DosePoleBand named dosePoleBand 0..1 MS and
    PriorDoseStatus named priorDoseStatus 0..1 MS
* extension[dosePoleBand] ^short = "The measured dose-pole height band that set the tablet count (machine-readable height-band → dose, v0.19.0)"
* extension[priorDoseStatus] ^short = "Prior-dose (zero-dose) status at this contact — zero-dose | previously-received | no-recall (v0.21.0)"

Profile: ICRSupplyDelivery
Parent: SupplyDelivery
Id: ICRSupplyDelivery
Title: "ICR Supply Delivery"
Description: "A commodity distribution event — ITNs, IRS consumables, vitamin A capsules — GS1 GTIN-coded where applicable, with the required record origin."
* ^experimental = false
* status MS
* suppliedItem MS
* suppliedItem.quantity MS
* suppliedItem.item[x] MS
* suppliedItem.itemCodeableConcept from ICRSuppliedItemVS (extensible)
* suppliedItem.item[x] ^short = "Drug commodity → WHO ATC (shares the ICRMedicationAdministration code); physical commodity → GS1 GTIN where applicable, else text"
* destination MS
* destination ^short = "Where the commodity went (post, household)"
* extension contains
    RecordOrigin named recordOrigin 1..1 MS and
    StockAccountability named stockAccountability 0..1 MS
* extension[stockAccountability] ^short = "Vial/commodity accountability & wastage — received/used/remaining/not-usable/returned, concordance, VVM (v0.20.0)"
