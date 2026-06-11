// Example instances — a coherent measles–rubella SIA scenario (Type A fixed-post,
// with a Type B house-to-house mop-up task) over a small location hierarchy with
// GERS identifiers, plus an MDA treatment event (Type C).

// --- Location hierarchy: district → settlement → dwelling --------------------

Instance: example-district
InstanceOf: ICRLocation
Title: "Example District"
Usage: #example
* name = "Kambia District"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#jdn "Jurisdiction"
* identifier[pcode].system = $PCode
* identifier[pcode].value = "SL0201"
* identifier[gers].system = $GERSId
* identifier[gers].value = "08f2a3b4c5d6e7f8-division-example"

Instance: example-settlement
InstanceOf: ICRLocation
Title: "Example Settlement"
Usage: #example
* name = "Rokupr"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#area "Area"
* partOf = Reference(example-district)
* position.longitude = -12.9469
* position.latitude = 9.0144
* identifier[gers].system = $GERSId
* identifier[gers].value = "08f2a3b4c5d6e7f8-place-example"

Instance: example-dwelling
InstanceOf: ICRLocation
Title: "Example Dwelling"
Usage: #example
* name = "Dwelling — Rokupr block 4, house 12"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#ho "House"
* partOf = Reference(example-settlement)
* position.longitude = -12.9471
* position.latitude = 9.0149
* identifier[gers].system = $GERSId
* identifier[gers].value = "08f2a3b4c5d6e7f8-building-example"

// --- Population: a household and the campaign's planning denominator ---------

Instance: example-child
InstanceOf: Patient
Title: "Example Child"
Usage: #example
* name.given = "Aminata"
* name.family = "Kamara"
* gender = #female
* birthDate = "2023-04-12"

Instance: example-household
InstanceOf: ICRHousehold
Title: "Example Household"
Usage: #example
* type = #person
* actual = true
* quantity = 6
* member.entity = Reference(example-child)
* extension[householdLocation].valueReference = Reference(example-dwelling)

Instance: example-target-population
InstanceOf: ICRTargetPopulation
Title: "Example Target Population — children 9m–14y, Kambia District"
Usage: #example
* type = #person
* actual = false
* name = "Children 9 months–14 years, Kambia District (MR SIA 2026 planning denominator)"
* quantity = 48250
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#grid3 "GRID3 modelled estimate"
* extension[estimateDate].valueDate = "2026-01-15"
* extension[isPlanningDenominator].valueBoolean = true

// --- The campaign: protocol + execution --------------------------------------

Instance: example-mr-sia-protocol
InstanceOf: ICRCampaignProtocol
Title: "Measles–Rubella SIA Protocol"
Usage: #example
* status = #active
* version = "1.0.0"
* title = "Measles–rubella SIA, 9 months–14 years"
* type = $CampaignType#vaccination-sia "Vaccination campaign (SIA)"
* extension[deliveryStrategy][0].valueCodeableConcept = $DeliveryStrategy#fixed-post "Fixed post"
* extension[deliveryStrategy][1].valueCodeableConcept = $DeliveryStrategy#house-to-house "House-to-house"
* goal.description.text = "≥95% administrative coverage in every district, verified by post-campaign survey"
* action.title = "Administer MCV to all children 9 months–14 years regardless of prior vaccination status"

Instance: example-mr-sia-2026
InstanceOf: ICRCampaign
Title: "Kambia MR SIA — June 2026 round"
Usage: #example
* instantiatesCanonical = Canonical(example-mr-sia-protocol)
* status = #active
* intent = #plan
* title = "Measles–rubella SIA, Kambia District, June 2026"
* category = $CampaignType#vaccination-sia "Vaccination campaign (SIA)"
* subject = Reference(example-target-population)
* period.start = "2026-06-15"
* period.end = "2026-06-26"
* extension[campaignRound].valuePositiveInt = 1
* extension[targetGeography].valueReference = Reference(example-district)
* extension[planningDenominator].valueReference = Reference(example-target-population)

// --- The operational unit: a house-to-house mop-up visit ---------------------

Instance: example-mopup-task
InstanceOf: ICRCampaignTask
Title: "Mop-up household visit — Rokupr block 4, house 12"
Usage: #example
* status = #completed
* intent = #order
* code.text = "House-to-house mop-up: vaccinate children missed at fixed posts"
* focus = Reference(example-household)
* for = Reference(example-household)
* location = Reference(example-dwelling)
* executionPeriod.start = "2026-06-24T09:30:00Z"
* executionPeriod.end = "2026-06-24T09:50:00Z"
* extension[deliveryStrategy].valueCodeableConcept = $DeliveryStrategy#house-to-house "House-to-house"
* extension[childrenPresent].valueUnsignedInt = 2
* extension[childrenAbsent].valueUnsignedInt = 1
* extension[missedReason].valueCodeableConcept = $MissedReason#absent "Absent"
* extension[fingerMarked].valueBoolean = true
* output.type.text = "Immunization delivered"
* output.valueReference = Reference(example-mcv-dose)

// --- Delivery events ----------------------------------------------------------

Instance: example-mcv-dose
InstanceOf: ICRImmunizationEvent
Title: "MCV dose — campaign record"
Usage: #example
* status = #completed
* vaccineCode = $CVX#05 "measles virus vaccine"
* patient = Reference(example-child)
* occurrenceDateTime = "2026-06-24T09:40:00Z"
* location = Reference(example-dwelling)
* lotNumber = "MRV-2026-0412"
* extension[recordOrigin].valueCode = #campaign

Instance: example-albendazole-administration
InstanceOf: ICRMedicationAdministration
Title: "Albendazole administration — MDA register entry"
Usage: #example
* status = #completed
* medicationCodeableConcept = $ATC#P02CA03 "albendazole"
* subject = Reference(example-child)
* effectiveDateTime = "2026-02-10T11:00:00Z"
* dosage.text = "1 tablet (400 mg), dose-pole band B"
* extension[recordOrigin].valueCode = #campaign
* extension[directlyObserved].valueBoolean = true

Instance: example-itn-delivery
InstanceOf: ICRSupplyDelivery
Title: "ITN delivery to household"
Usage: #example
* status = #completed
* suppliedItem.quantity = 3 '{Net}' "nets"
* suppliedItem.itemCodeableConcept.text = "Long-lasting insecticidal net (LLIN)"
* destination = Reference(example-dwelling)
* extension[recordOrigin].valueCode = #campaign
