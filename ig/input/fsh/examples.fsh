// Example instances — a coherent measles–rubella SIA scenario over a small location
// hierarchy with GERS identifiers: national umbrella campaign + district round
// (partOf pattern), a Type A fixed-post site-session task (pre-planned), a Type B
// house-to-house mop-up task (field-registered), the admin-vs-survey coverage pair
// (never-merged lineages), plus an MDA treatment event (Type C) and an ITN delivery.
// Population side: a household and a community delivery unit (the generalized
// Group+Location pattern), target populations with computable geography
// characteristics, and a supervisory area overlaying the admin hierarchy.

// --- Location hierarchy: country → district → settlement → dwelling ----------

Instance: example-country
InstanceOf: ICRLocation
Title: "Example Country"
Usage: #example
* name = "Sierra Leone"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#jdn "Jurisdiction"
* type = $LocationType#admin-unit "Administrative unit"
* identifier[pcode].system = $PCode
* identifier[pcode].value = "SL"
* identifier[gers].system = $GERSId
* identifier[gers].value = "08f2a3b4c5d6e7f8-division-country-example"

Instance: example-district
InstanceOf: ICRLocation
Title: "Example District"
Usage: #example
* name = "Kambia District"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#jdn "Jurisdiction"
* type = $LocationType#admin-unit "Administrative unit"
* partOf = Reference(example-country)
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

Instance: example-fixed-post
InstanceOf: ICRLocation
Title: "Example Fixed Post — Rokupr CHC"
Usage: #example
* name = "Rokupr Community Health Centre — fixed vaccination post"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#si "Site"
* partOf = Reference(example-settlement)
* position.longitude = -12.9465
* position.latitude = 9.0140
* identifier[gers].system = $GERSId
* identifier[gers].value = "08f2a3b4c5d6e7f8-building-chc-example"
* extension[deliveryStrategy].valueCodeableConcept = $DeliveryStrategy#fixed-post "Fixed post"

// Operational geography: a supervisory area is NOT in the admin partOf chain — it
// overlays the admin units it covers via the overlays-admin-unit extension
// (linkable-but-distinct, working doc §9 identity principle 3).

Instance: example-supervisory-area
InstanceOf: ICRLocation
Title: "Example Supervisory Area"
Usage: #example
* name = "Kambia supervision zone 2 (Rokupr axis)"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#area "Area"
* type = $LocationType#supervisory-area "Supervisory area"
* extension[overlaysAdminUnit].valueReference = Reference(example-district)

// --- Population: a household, a community, and the planning denominators -----

Instance: example-child
InstanceOf: ICRPatient
Title: "Example Child"
Usage: #example
* identifier[nationalId].system = $NationalId
* identifier[nationalId].value = "SL-2023-04-0099812"
* name.given = "Aminata"
* name.family = "Kamara"
* gender = #female
* birthDate = "2023-04-12"

Instance: example-household
InstanceOf: ICRDeliveryUnit
Title: "Example Household"
Usage: #example
* type = #person
* actual = true
* code = $GroupKind#household "Household"
* quantity = 6
* member.entity = Reference(example-child)
* extension[groupLocation].valueReference = Reference(example-dwelling)

// The mainline house-to-house shape: every member enumerated, each an ICRPatient.
// quantity equals the member count because nobody is left un-enumerated (contrast
// example-household above, which enumerates only the one child it serves).

Instance: example-head
InstanceOf: ICRPatient
Title: "Example Head of Household"
Usage: #example
* identifier[nationalId].system = $NationalId
* identifier[nationalId].value = "SL-1989-11-0042317"
* name.given = "Mohamed"
* name.family = "Kamara"
* gender = #male
* birthDate = "1989-11-03"

Instance: example-sibling
InstanceOf: ICRPatient
Title: "Example Sibling"
Usage: #example
* identifier[nationalId].system = $NationalId
* identifier[nationalId].value = "SL-2019-08-0071554"
* name.given = "Fatmata"
* name.family = "Kamara"
* gender = #female
* birthDate = "2019-08-21"

Instance: example-household-enumerated
InstanceOf: ICRDeliveryUnit
Title: "Example Household — fully enumerated"
Usage: #example
* type = #person
* actual = true
* code = $GroupKind#household "Household"
* quantity = 3
* member[0].entity = Reference(example-head)
* member[1].entity = Reference(example-sibling)
* member[2].entity = Reference(example-child)
* extension[groupLocation].valueReference = Reference(example-dwelling)

// A community delivery unit (Type C): the same Group + Location pattern as the
// household, with the settlement as its Location — what a CDD's MDA register
// entries and community-level Tasks act on.

Instance: example-community
InstanceOf: ICRDeliveryUnit
Title: "Example Community — Rokupr"
Usage: #example
* type = #person
* actual = true
* code = $GroupKind#community "Community"
* name = "Rokupr community"
* quantity = 3480
* extension[groupLocation].valueReference = Reference(example-settlement)

Instance: example-target-population
InstanceOf: ICRTargetPopulation
Title: "Example Target Population — children 9m–14y, Kambia District"
Usage: #example
* type = #person
* actual = false
* name = "Children 9 months–14 years, Kambia District (MR SIA 2026 planning denominator)"
* quantity = 48250
* characteristic[geography].code = $GroupCharacteristic#geography "Geographic scope"
* characteristic[geography].valueReference = Reference(example-district)
* characteristic[geography].exclude = false
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#grid3 "GRID3 modelled estimate"
* extension[estimateDate].valueDate = "2026-01-15"
* extension[isPlanningDenominator].valueBoolean = true

// A COMPETING estimate for the same geography: house-to-house enumeration says
// 51,800 where GRID3 says 48,250 — a 7% disagreement that stays visible because
// both estimates are retained with source + date, and exactly one carries the
// planning flag. The denominator you pick changes the coverage you report.

Instance: example-target-population-enumerated
InstanceOf: ICRTargetPopulation
Title: "Example Target Population — children 9m–14y, Kambia District (enumeration estimate)"
Usage: #example
* type = #person
* actual = false
* name = "Children 9 months–14 years, Kambia District (house-to-house enumeration, competing estimate)"
* quantity = 51800
* characteristic[geography].code = $GroupCharacteristic#geography "Geographic scope"
* characteristic[geography].valueReference = Reference(example-district)
* characteristic[geography].exclude = false
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#microcensus "Microcensus / enumeration"
* extension[estimateDate].valueDate = "2026-03-02"
* extension[isPlanningDenominator].valueBoolean = false

Instance: example-target-population-national
InstanceOf: ICRTargetPopulation
Title: "Example Target Population — children 9m–14y, Sierra Leone (national)"
Usage: #example
* type = #person
* actual = false
* name = "Children 9 months–14 years, Sierra Leone (MR SIA 2026 national planning denominator)"
* quantity = 2150000
* characteristic[geography].code = $GroupCharacteristic#geography "Geographic scope"
* characteristic[geography].valueReference = Reference(example-country)
* characteristic[geography].exclude = false
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#census-projection "Census projection"
* extension[estimateDate].valueDate = "2025-11-30"
* extension[isPlanningDenominator].valueBoolean = true

// --- The campaign: protocol + activity + umbrella + round --------------------

Instance: example-mcv-activity
InstanceOf: ICRCampaignActivity
Title: "Administer MCV — campaign activity definition"
Usage: #example
* status = #active
* kind = #Task
* title = "Administer measles-containing vaccine, 9 months–14 years"
* code.text = "Vaccinate"
* productCodeableConcept = $CVX#05 "measles virus vaccine"
* dosage.text = "0.5 mL subcutaneous, single dose"

// Three more activity definitions spanning the campaign types — the protocol layer
// carries the clinical/commodity content once; thousands of Tasks instantiate it.
// Note none of them name a concrete target: WHAT lives here, the thing acted on
// (this household, this structure) is each Task's focus.

Instance: example-albendazole-activity
InstanceOf: ICRCampaignActivity
Title: "Administer albendazole — MDA activity definition"
Usage: #example
* status = #active
* kind = #Task
* title = "Administer albendazole to school-age children 5–14 years (STH preventive chemotherapy)"
* code.text = "Treat"
* productCodeableConcept = $ATC#P02CA03 "albendazole"
* dosage.text = "400 mg single dose; tablet count determined by dose-pole height band"

Instance: example-itn-activity
InstanceOf: ICRCampaignActivity
Title: "Distribute ITNs — activity definition"
Usage: #example
* status = #active
* kind = #Task
* title = "Distribute long-lasting insecticidal nets, 1 net per 2 household members"
* code.text = "Distribute"
* productCodeableConcept.text = "Long-lasting insecticidal net (LLIN)"

Instance: example-irs-activity
InstanceOf: ICRCampaignActivity
Title: "Spray structure — IRS activity definition"
Usage: #example
* status = #active
* kind = #Task
* title = "Spray interior walls of eligible structures (indoor residual spraying)"
* code.text = "Spray"
* productCodeableConcept.text = "Pirimiphos-methyl 300CS (IRS insecticide)"

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
* action.definitionCanonical = Canonical(example-mcv-activity)

// The umbrella campaign (national, intent=plan) and its first round (district,
// intent=order, partOf the umbrella) — the multi-round pattern (working doc §6.3).

Instance: example-mr-sia-national
InstanceOf: ICRCampaign
Title: "Sierra Leone MR SIA 2026 — national umbrella campaign"
Usage: #example
* instantiatesCanonical = Canonical(example-mr-sia-protocol)
* status = #active
* intent = #plan
* title = "Measles–rubella SIA, Sierra Leone, 2026"
* category = $CampaignType#vaccination-sia "Vaccination campaign (SIA)"
* subject = Reference(example-target-population-national)
* period.start = "2026-06-15"
* period.end = "2026-12-18"
* extension[planningDenominator].valueReference = Reference(example-target-population-national)

Instance: example-mr-sia-2026
InstanceOf: ICRCampaign
Title: "Kambia MR SIA — June 2026 round"
Usage: #example
* instantiatesCanonical = Canonical(example-mr-sia-protocol)
* status = #active
* intent = #order
* title = "Measles–rubella SIA, Kambia District, June 2026 (round 1)"
* category = $CampaignType#vaccination-sia "Vaccination campaign (SIA)"
* subject = Reference(example-target-population)
* period.start = "2026-06-15"
* period.end = "2026-06-26"
* partOf = Reference(example-mr-sia-national)
* extension[campaignRound].valuePositiveInt = 1
* extension[targetGeography].valueReference = Reference(example-district)
* extension[planningDenominator].valueReference = Reference(example-target-population)

// --- The operational units: a Type A site-session and a Type B mop-up visit --

Instance: example-site-session-task
InstanceOf: ICRCampaignTask
Title: "Site session — Rokupr CHC fixed post, campaign day 3"
Usage: #example
* status = #completed
* intent = #order
* code.text = "Fixed-post vaccination session"
* focus = Reference(example-fixed-post)
* for = Reference(example-target-population)
* location = Reference(example-fixed-post)
* executionPeriod.start = "2026-06-17T08:00:00Z"
* executionPeriod.end = "2026-06-17T17:00:00Z"
* extension[deliveryStrategy].valueCodeableConcept = $DeliveryStrategy#fixed-post "Fixed post"
* extension[taskOrigin].valueCode = #pre-planned
* extension[dataLineage].valueCode = #realtime
* output.type.text = "Children vaccinated (session tally)"
* output.valueUnsignedInt = 412

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
* extension[taskOrigin].valueCode = #field-registered
* extension[eligiblePresent].valueUnsignedInt = 2
* extension[eligibleAbsent].valueUnsignedInt = 1
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
* manufacturer.display = "Serum Institute of India"
* performer.actor.display = "Mop-up team 4, Rokupr"
* protocolApplied.doseNumberPositiveInt = 1
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

// --- Coverage: the admin-vs-survey pair (never-merged lineages) ---------------
// Same district, same round, same conceptual quantity — two separately-sourced
// figures that diverge (mirroring the canonical Cuamba example: ~99% admin vs
// ~76% survey, working doc §4.1). Measure canonicals are placeholders until the
// Measure definitions ship (see roadmap).

Instance: example-admin-coverage
InstanceOf: ICRAdministrativeCoverage
Title: "Administrative coverage — Kambia MR SIA, June 2026 round"
Usage: #example
* status = #complete
* type = #summary
* measure = "https://fhir.icr.unicef.org/Measure/icr-admin-coverage"
* period.start = "2026-06-15"
* period.end = "2026-06-26"
* reporter.display = "Kambia District Health Management Team"
* group.population[0].code = $MeasurePopulation#numerator "Numerator"
* group.population[0].count = 47766
* group.population[1].code = $MeasurePopulation#denominator "Denominator"
* group.population[1].count = 48250
* group.measureScore = 99 '%' "%"
* extension[coverageSource].valueCode = #administrative
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#grid3 "GRID3 modelled estimate"
* extension[dataLineage].valueCode = #reconciled

Instance: example-survey-coverage
InstanceOf: ICRSurveyCoverage
Title: "Post-campaign survey coverage — Kambia MR SIA, June 2026 round"
Usage: #example
* status = #complete
* type = #summary
* measure = "https://fhir.icr.unicef.org/Measure/icr-survey-coverage"
* period.start = "2026-07-06"
* period.end = "2026-07-12"
* reporter.display = "Independent post-campaign coverage survey team"
* group.measureScore = 76 '%' "%"
* extension[coverageSource].valueCode = #survey
* extension[sampleDesign].valueString = "WHO 30×10 cluster survey, district-representative; card + caregiver recall"
* extension[dataLineage].valueCode = #reconciled
