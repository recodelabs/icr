// Delivery-event profiles (working doc §7.8).
// Every delivery event carries the required record-origin extension (campaign vs
// routine — working doc §4.4) and its own campaign link: the local Campaign
// extension, Reference(ICRCampaign). (Formerly the HL7 event-basedOn extension,
// but its R4 context is Condition-only, so that use was context-invalid; the
// local extension also serves MeasureReport, giving one uniform record→campaign
// join.) R4 Immunization has no basedOn element, so the extension supplies it —
// a delivery event stands alone (patient + campaign + record-origin) and
// per-round queries never depend on Task wiring. Task.output carries the
// visit-level result (the tally) and may additionally reference events captured
// inside the visit workflow.

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
* expirationDate MS
* expirationDate ^short = "Vaccine expiry — field forms report it alongside the lot number (v0.1)"
* manufacturer MS
* performer MS
* protocolApplied MS
* protocolApplied ^short = "Dose number / series — supports multi-dose campaigns (OCV) and routine integration"
* extension contains
    Campaign named campaign 0..1 MS and
    RecordOrigin named recordOrigin 1..1 MS and
    PriorDoseStatus named priorDoseStatus 0..1 MS
* extension[campaign] ^short = "The campaign (round) this dose belongs to — supplies Immunization's missing basedOn, so 'all doses in this round' is a direct query, independent of Task wiring"
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
* subject ^short = "The treated person, or the delivery-unit Group (household, community, or school cohort) for register-level capture"
* effective[x] MS
* dosage MS
* dosage ^short = "Tablet count — in the field usually derived from a dose-pole height band Observation"
* supportingInformation MS
* supportingInformation ^short = "e.g. the dose-pole Observation the dosage was derived from"
* extension contains
    Campaign named campaign 0..1 MS and
    RecordOrigin named recordOrigin 1..1 MS and
    DirectlyObservedConsumption named directlyObserved 0..1 MS and
    DosePoleBand named dosePoleBand 0..1 MS and
    PriorDoseStatus named priorDoseStatus 0..1 MS
* extension[campaign] ^short = "The campaign (round) this treatment belongs to; per-round queries stay independent of Task wiring"
* extension[dosePoleBand] ^short = "The measured dose-pole height band that set the tablet count (machine-readable height-band → dose, v0.19.0)"
* extension[priorDoseStatus] ^short = "Prior-dose (zero-dose) status at this contact — zero-dose | previously-received | no-recall (v0.21.0)"

// Supply events split into two profiles (supply-split round) — the two roles the
// former ICRSupplyDelivery mixed. The doctrine: an event about a THING CHANGING
// HANDS is a supply event (distribution to beneficiaries, or movement between
// nodes); an event about an ACT PERFORMED ON A PLACE is a Task (IRS: the Task IS
// the event, §6.4 — insecticide sprayed onto a structure is consumed in the act,
// not distributed to anyone: its accounting rides the movement ledger, never a
// distribution record); a DRUG INTO A PERSON is always MedicationAdministration —
// pharma never downgrades to supply. The split keeps Measures safe: distributions
// count toward coverage; movements count toward stock/wastage only — one mixed
// profile would double-count (500 nets moved to a post + 250 handed over).

Profile: ICRSupplyDistribution
Parent: SupplyDelivery
Id: ICRSupplyDistribution
Title: "ICR Supply Distribution"
Description: "Last-mile distribution of a commodity to the people it serves — ITNs to a household, consumables handed to a community. The COVERAGE-bearing supply event: per-capita measures (1 net per 2 household members) join its quantity to the recipient delivery unit's size. Distinct from ICRSupplyMovement (node-to-node logistics, stock-bearing) — the split keeps coverage CQL from double-counting stock movements. Deliberately carries no stock-accountability ledger: a distribution is not a stock event. Structure-applied consumables (IRS insecticide) are NOT distributions — the spray Task is the event (§6.4) and consumption rides the movement ledger."
* ^experimental = false
* status MS
* suppliedItem MS
* suppliedItem.quantity MS
* suppliedItem.item[x] MS
* suppliedItem.itemCodeableConcept from ICRSuppliedItemVS (extensible)
* suppliedItem.item[x] ^short = "Drug commodity → WHO ATC; physical commodity → ICR commodity-class code (llin, rdt, …), optionally alongside a GS1 GTIN coding for the specific product; text as fallback"
* patient MS
* patient ^short = "The registered person receiving it, where person-level registration exists. The usual ICR recipient is a household/community Group — that join rides extension[recipient] (R4 SupplyDelivery.patient cannot target a Group)"
* destination MS
* destination ^short = "The place of the handover (dwelling, distribution post, school)"
* extension contains
    Campaign named campaign 0..1 MS and
    RecordOrigin named recordOrigin 1..1 MS and
    DistributionRecipient named recipient 0..1 MS
* extension[campaign] ^short = "The campaign (round) this distribution belongs to; per-round queries stay independent of Task wiring"
* extension[recipient] ^short = "Who received it — the delivery-unit Group (household, community, school cohort) or a registered person. The direct join per-capita coverage computes against"

Profile: ICRSupplyMovement
Parent: SupplyDelivery
Id: ICRSupplyMovement
Title: "ICR Supply Movement"
Description: "A commodity movement between supply-chain nodes — receipt at a facility, issue to a distribution post or field team, return of unused stock. The STOCK-bearing supply event: carries the stock-accountability ledger (received/used/remaining/not-usable/returned, concordance, VVM) and never counts toward coverage. Chains via partOf → the upstream movement (central store → district → post → team). v1 scope is campaign-tied movements only; routine inter-warehouse logistics is out of scope (OpenLMIS territory)."
* ^experimental = false
* status MS
* suppliedItem MS
* suppliedItem.quantity MS
* suppliedItem.item[x] MS
* suppliedItem.itemCodeableConcept from ICRSuppliedItemVS (extensible)
* suppliedItem.item[x] ^short = "Drug commodity → WHO ATC (shares the ICRMedicationAdministration code); physical commodity → ICR commodity-class code, optionally with a GS1 GTIN coding; text as fallback"
* destination MS
* destination ^short = "The receiving node (facility, staging post, settlement)"
* supplier MS
* supplier ^short = "The sending party (organization / officer), where recorded"
* partOf MS
* partOf only Reference(ICRSupplyMovement)
* partOf ^short = "The upstream movement this one draws from — makes the supply chain an explicit, queryable sequence"
* extension contains
    Campaign named campaign 0..1 MS and
    RecordOrigin named recordOrigin 1..1 MS and
    StockAccountability named stockAccountability 0..1 MS and
    IssuedToTeam named issuedToTeam 0..1 MS
* extension[campaign] ^short = "The campaign (round) this movement belongs to"
* extension[stockAccountability] ^short = "Vial/commodity accountability & wastage — received/used/remaining/not-usable/returned, concordance, VVM (v0.20.0). A node's ledger reconciles as received = used + remaining + notUsable + returned"
* extension[issuedToTeam] ^short = "The CareTeam this movement was issued to — one issuance per team per day plus its ledger is the field-team daily-stock pattern (R4 receiver cannot target a CareTeam)"
