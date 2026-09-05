// Example instances — a coherent measles–rubella SIA scenario over a small location
// hierarchy with GERS identifiers: national umbrella campaign + district round
// (partOf pattern), a fixed-post site-session task (pre-planned), a
// house-to-house mop-up task (field-registered), the admin-vs-survey coverage pair
// (never-merged lineages), plus a community-directed MDA treatment event and an
// ITN delivery.
// Population side: household, community, and school-cohort delivery units (the
// generalized Group+Location pattern), target populations with computable geography
// characteristics, and a supervisory area attached to the admin tree as a typed
// non-admin node.

// --- Location hierarchy: country → district → settlement → dwelling ----------

Instance: example-country
InstanceOf: ICRLocation
Title: "Example Country"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* meta.tag[+] = $ProjectTag#mda "MDA (Rokupr)"
* name = "Sierra Leone"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#jdn "Jurisdiction"
* type = $LocationType#admin-unit "Administrative unit"
* identifier[isoCountry].use = #official
* identifier[isoCountry].system = $ISO3166
* identifier[isoCountry].value = "SL"
* identifier[pcode].system = $PCode
* identifier[pcode].value = "SL"
* identifier[gers].system = $GERSId
* identifier[gers].value = "08f2a3b4c5d6e7f8-division-country-example"

Instance: example-district
InstanceOf: ICRLocation
Title: "Example District"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* meta.tag[+] = $ProjectTag#mda "MDA (Rokupr)"
* name = "Kambia District"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#jdn "Jurisdiction"
* type = $LocationType#admin-unit "Administrative unit"
* partOf = Reference(example-country)
* identifier[pcode].use = #official
* identifier[pcode].system = $PCode
* identifier[pcode].value = "SL0201"
* identifier[gers].system = $GERSId
* identifier[gers].value = "08f2a3b4c5d6e7f8-division-example"
* extension[boundary].valueAttachment.contentType = #application/geo+json
* extension[boundary].valueAttachment.data = "eyJ0eXBlIjoiUG9seWdvbiIsImNvb3JkaW5hdGVzIjpbW1stMTMuMDUsOC45NV0sWy0xMi44NSw4Ljk1XSxbLTEyLjg1LDkuMTVdLFstMTMuMDUsOS4xNV0sWy0xMy4wNSw4Ljk1XV1dfQ=="

// A country using its OWN coding scheme: the open identifier slicing means a
// national code (here a DHIS2 orgUnit UID under an MoH system URI) rides the
// identifier list with NO profile change, marked use = official — that mark is
// the uniform join key (identifier.where(use = 'official')). No GERS ID and no
// P-code yet: the enrichment lifecycle (create unmatched → conflate → backfill
// GERS with Provenance) applies. The icr-loc-admin-id invariant is satisfied
// because an admin unit needs at least one identifier from ANY system.
Instance: example-ward
InstanceOf: ICRLocation
Title: "Example Ward — national DHIS2 code only"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* name = "Kambia Ward 3 (Magbema)"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#jdn "Jurisdiction"
* type = $LocationType#admin-unit "Administrative unit"
* partOf = Reference(example-district)
* identifier[0].use = #official
* identifier[0].system = "https://mohs.gov.sl/identifiers/dhis2-orgunit"
* identifier[0].value = "Ax9uP3kL2mN"

Instance: example-settlement
InstanceOf: ICRLocation
Title: "Example Settlement"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* meta.tag[+] = $ProjectTag#mda "MDA (Rokupr)"
* name = "Rokupr"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#area "Area"
* partOf = Reference(example-district)
* position.longitude = -12.9469
* position.latitude = 9.0144
* identifier[gers].system = $GERSId
* identifier[gers].value = "08f2a3b4c5d6e7f8-place-example"
* extension[settlementType].valueCodeableConcept = $SettlementType#rural "Rural"

Instance: example-dwelling
InstanceOf: ICRLocation
Title: "Example Dwelling"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
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
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* name = "Rokupr Community Health Centre — fixed vaccination post"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#si "Site"
* type = $LocationType#facility "Health facility"
* partOf = Reference(example-settlement)
* position.longitude = -12.9465
* position.latitude = 9.0140
* identifier[gers].system = $GERSId
* identifier[gers].value = "08f2a3b4c5d6e7f8-building-chc-example"

// Operational geography lives in the same single partOf tree, distinguished by
// type — not tree position. A supervisory area attaches at the lowest admin unit
// that fully contains it (here: the district; a zone spanning districts would
// attach at region/state level). Admin rollups filter on type = admin-unit and
// skip it (working doc §9).

Instance: example-supervisory-area
InstanceOf: ICRLocation
Title: "Example Supervisory Area"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* meta.tag[+] = $ProjectTag#mda "MDA (Rokupr)"
* name = "Kambia supervision zone 2 (Rokupr axis)"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#area "Area"
* type = $LocationType#supervisory-area "Supervisory area"
* partOf = Reference(example-district)

// --- Population: a household, a community, and the planning denominators -----

Instance: example-child
InstanceOf: ICRPatient
Title: "Example Child"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
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
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
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
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
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
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
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
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* type = #person
* actual = true
* code = $GroupKind#household "Household"
* quantity = 3
* member[0].entity = Reference(example-head)
* member[1].entity = Reference(example-sibling)
* member[2].entity = Reference(example-child)
* extension[groupLocation].valueReference = Reference(example-dwelling)

// Person-data governance: the head of household permits the child's campaign
// data to be held and shared in the registry (a v1 starting point — §6.4/§14).

Instance: example-consent
InstanceOf: ICRConsent
Title: "Example Consent — registry data sharing"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* status = #active
* scope = $ConsentScope#patient-privacy "Privacy Consent"
* category = $LOINC#59284-0 "Consent Document"
* patient = Reference(example-child)
* dateTime = "2026-06-15"
* performer = Reference(example-head)
* policyRule.text = "UNICEF ICR person-data governance policy v1 (placeholder pending publication)"
* provision.type = #permit

// A community delivery unit: the same Group + Location pattern as the
// household, with the settlement as its Location — what a CDD's MDA register
// entries and community-level Tasks act on.

Instance: example-community
InstanceOf: ICRDeliveryUnit
Title: "Example Community — Rokupr"
Usage: #example
* meta.tag[+] = $ProjectTag#mda "MDA (Rokupr)"
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
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
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
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
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

// The calculated/aggregated case (working-doc §5.2 c10): a district figure summed
// from ward microplanning estimates. is-calculated marks it as NON-independent —
// it corroborates nothing about its inputs and goes stale when any ward revises.
// It sits beside the independent GRID3 and enumeration estimates for the same
// district: three competing estimates, each with its provenance.

Instance: example-target-population-ward-sum
InstanceOf: ICRTargetPopulation
Title: "Example Target Population — children 9m–14y, Kambia District (sum of ward microplan estimates, calculated)"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* type = #person
* actual = false
* name = "Children 9 months–14 years, Kambia District (sum of ward microplanning estimates — calculated, not independently sourced)"
* quantity = 50120
* characteristic[geography].code = $GroupCharacteristic#geography "Geographic scope"
* characteristic[geography].valueReference = Reference(example-district)
* characteristic[geography].exclude = false
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#microcensus "Microcensus / enumeration"
* extension[estimateDate].valueDate = "2026-03-10"
* extension[isPlanningDenominator].valueBoolean = false
* extension[isCalculated].valueBoolean = true

Instance: example-target-population-national
InstanceOf: ICRTargetPopulation
Title: "Example Target Population — children 9m–14y, Sierra Leone (national)"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
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
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* status = #active
* kind = #Task
* title = "Administer measles-containing vaccine, 9 months–14 years"
* code.text = "Vaccinate"
* topic = $CampaignType#vaccination-sia "Vaccination campaign (SIA)"
* productCodeableConcept = $CVX#05 "measles virus vaccine"
* dosage.text = "0.5 mL subcutaneous, single dose"

// Three more activity definitions spanning the campaign types — the protocol layer
// carries the clinical/commodity content once; thousands of Tasks instantiate it.
// Note none of them name a concrete target: WHAT lives here, the thing acted on
// (this household, this structure) is each Task's focus.
// Activities are a shared CATALOG, not children of a protocol: any protocol may
// reference any activity via action.definitionCanonical. topic tags the menu by
// campaign type (advisory filtering only). Eligibility (the 5–14 age band) is
// deliberately NOT here — base ActivityDefinition has no eligibility element;
// it lives on the protocol's subject (see example-sth-eligible-population).

Instance: example-albendazole-activity
InstanceOf: ICRCampaignActivity
Title: "Administer albendazole — MDA activity definition"
Usage: #example
* meta.tag[+] = $ProjectTag#mda "MDA (Rokupr)"
* status = #active
* kind = #Task
* title = "Administer albendazole to school-age children 5–14 years (STH preventive chemotherapy)"
* code.text = "Treat"
* topic = $CampaignType#mda "Mass drug administration (NTD preventive chemotherapy)"
* productCodeableConcept = $ATC#P02CA03 "albendazole"
* dosage.text = "400 mg single dose; tablet count determined by dose-pole height band"

Instance: example-itn-activity
InstanceOf: ICRCampaignActivity
Title: "Distribute ITNs — activity definition"
Usage: #example
* meta.tag[+] = $ProjectTag#gallery "Gallery"
* status = #active
* kind = #Task
* title = "Distribute long-lasting insecticidal nets, 1 net per 2 household members"
* code.text = "Distribute"
* topic = $CampaignType#itn-distribution "ITN mass distribution"
* productCodeableConcept.text = "Long-lasting insecticidal net (LLIN)"

Instance: example-irs-activity
InstanceOf: ICRCampaignActivity
Title: "Spray structure — IRS activity definition"
Usage: #example
* meta.tag[+] = $ProjectTag#gallery "Gallery"
* status = #active
* kind = #Task
* title = "Spray interior walls of eligible structures (indoor residual spraying)"
* code.text = "Spray"
* topic = $CampaignType#irs "Indoor residual spraying"
* productCodeableConcept.text = "Pirimiphos-methyl 300CS (IRS insecticide)"

// IRS gallery completed into a runnable chain (ig-compare §9 item 7): protocol →
// denominator → round → structure-targeted Task. For structure-applied work the
// Task IS the event (§6.4) — spray results ride Task.output; no delivery-event
// resource hangs off it.

Instance: example-irs-protocol
InstanceOf: ICRCampaignProtocol
Title: "IRS protocol — annual indoor residual spraying"
Usage: #example
* meta.tag[+] = $ProjectTag#gallery "Gallery"
* status = #active
* version = "1.0.0"
* title = "Indoor residual spraying, all eligible structures, annual round"
* type = $CampaignType#irs
* goal.description.text = "≥85% of targeted structures sprayed"
* action.title = "Spray eligible structures (Pirimiphos-methyl 300CS)"
* action.definitionCanonical = Canonical(example-irs-activity)
* extension[deliveryStrategy].valueCodeableConcept = $DeliveryStrategy#house-to-house "House-to-house"

Instance: example-target-population-irs
InstanceOf: ICRTargetPopulation
Title: "Example Target Population — population protected, Rokupr IRS"
Usage: #example
* meta.tag[+] = $ProjectTag#gallery "Gallery"
* type = #person
* actual = false
* name = "Population protected by IRS, Rokupr settlement (resident population of targeted structures)"
* quantity = 4100
* characteristic[geography].code = $GroupCharacteristic#geography "Geographic scope"
* characteristic[geography].valueReference = Reference(example-settlement)
* characteristic[geography].exclude = false
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#govt-estimate "Government estimate"
* extension[denominatorType].valueCode = #at-risk
* extension[estimateDate].valueDate = "2026-04-01"
* extension[isPlanningDenominator].valueBoolean = true

Instance: example-irs-round
InstanceOf: ICRCampaign
Title: "IRS Rokupr — 2026 annual round"
Usage: #example
* meta.tag[+] = $ProjectTag#gallery "Gallery"
* instantiatesCanonical = Canonical(example-irs-protocol)
* status = #completed
* intent = #order
* title = "IRS, Rokupr settlement, 2026 annual round"
* category = $CampaignType#irs
* subject = Reference(example-target-population-irs)
* period.start = "2026-05-04"
* period.end = "2026-05-15"
* extension[targetGeography].valueReference = Reference(example-settlement)
* extension[planningDenominator].valueReference = Reference(example-target-population-irs)

Instance: example-irs-task
InstanceOf: ICRCampaignTask
Title: "IRS structure visit — Rokupr block 4, house 12"
Usage: #example
* meta.tag[+] = $ProjectTag#gallery "Gallery"
* status = #completed
* intent = #order
* code.text = "Spray structure — Pirimiphos-methyl 300CS"
* basedOn = Reference(example-irs-round)
* instantiatesCanonical = Canonical(example-irs-activity)
* for = Reference(example-dwelling)
* location = Reference(example-dwelling)
* executionPeriod.start = "2026-05-06T10:15:00Z"
* executionPeriod.end = "2026-05-06T10:40:00Z"
* extension[deliveryStrategy].valueCodeableConcept = $DeliveryStrategy#house-to-house "House-to-house"
* extension[taskOrigin].valueCode = #pre-planned
* output[0].type.text = "Structure sprayed — rooms treated"
* output[0].valueUnsignedInt = 4

Instance: example-mr-sia-protocol
InstanceOf: ICRCampaignProtocol
Title: "Measles–Rubella SIA Protocol"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
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
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
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
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* instantiatesCanonical = Canonical(example-mr-sia-protocol)
* status = #active
* intent = #order
* title = "Measles–rubella SIA, Kambia District, June 2026 (round 1)"
* category = $CampaignType#vaccination-sia "Vaccination campaign (SIA)"
* subject = Reference(example-target-population)
* period.start = "2026-06-15"
* period.end = "2026-06-26"
* careTeam = Reference(example-careteam)
* partOf = Reference(example-mr-sia-national)
* extension[campaignRound].valuePositiveInt = 1
* extension[targetGeography].valueReference = Reference(example-district)
* extension[planningDenominator].valueReference = Reference(example-target-population)
* extension[socialMobilization].extension[populationInformed].valueBoolean = true
* extension[socialMobilization].extension[channel][0].valueCodeableConcept = $CommunicationChannel#radio "Radio"
* extension[socialMobilization].extension[channel][1].valueCodeableConcept = $CommunicationChannel#community-leaders "Community leaders"

// --- The operational units: a fixed-post site-session and a house-to-house mop-up visit --

Instance: example-site-session-task
InstanceOf: ICRCampaignTask
Title: "Site session — Rokupr CHC fixed post, campaign day 3"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* status = #completed
* intent = #order
* code.text = "Fixed-post vaccination session"
* basedOn = Reference(example-mr-sia-2026)
* instantiatesCanonical = Canonical(example-mcv-activity)
* for = Reference(example-fixed-post)
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
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* status = #completed
* intent = #order
* code.text = "House-to-house mop-up: vaccinate children missed at fixed posts"
* basedOn = Reference(example-mr-sia-2026)
* instantiatesCanonical = Canonical(example-mcv-activity)
* for = Reference(example-household)
* owner = Reference(example-careteam)
* location = Reference(example-dwelling)
* executionPeriod.start = "2026-06-24T09:30:00Z"
* executionPeriod.end = "2026-06-24T09:50:00Z"
* extension[deliveryStrategy].valueCodeableConcept = $DeliveryStrategy#house-to-house "House-to-house"
* extension[taskOrigin].valueCode = #field-registered
// Everything the visit produced is a coded output (task-outputs round): the
// house-to-house tally axes, the reason, and the reference to the dose captured
// inside the visit workflow.
* output[0].type = $TaskOutputType#eligible-present "Eligible persons present"
* output[0].valueUnsignedInt = 2
* output[1].type = $TaskOutputType#eligible-absent "Eligible persons absent"
* output[1].valueUnsignedInt = 1
* output[2].type = $TaskOutputType#missed-reason "Missed reason"
* output[2].valueCodeableConcept = $MissedReason#absent "Absent"
* output[3].type = $TaskOutputType#children-already-marked "Children already finger-marked"
* output[3].valueUnsignedInt = 1
* output[4].type = $TaskOutputType#delivery-event "Delivery event reference"
* output[4].valueReference = Reference(example-mcv-dose)

// --- Delivery events ----------------------------------------------------------

Instance: example-mcv-dose
InstanceOf: ICRImmunizationEvent
Title: "MCV dose — campaign record"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* status = #completed
* vaccineCode = $CVX#05 "measles virus vaccine"
* patient = Reference(example-child)
* occurrenceDateTime = "2026-06-24T09:40:00Z"
* location = Reference(example-dwelling)
* lotNumber = "MRV-2026-0412"
* manufacturer.display = "Serum Institute of India"
* performer.actor.display = "Mop-up team 4, Rokupr"
* protocolApplied.doseNumberPositiveInt = 1
* extension[campaign].valueReference = Reference(example-mr-sia-2026)
* extension[recordOrigin].valueCode = #campaign
* extension[priorDoseStatus].valueCode = #zero-dose

Instance: example-albendazole-administration
InstanceOf: ICRMedicationAdministration
Title: "Albendazole administration — MDA register entry"
Usage: #example
* meta.tag[+] = $ProjectTag#mda "MDA (Rokupr)"
* status = #completed
* medicationCodeableConcept = $ATC#P02CA03 "albendazole"
* subject = Reference(example-child)
* effectiveDateTime = "2026-02-10T11:00:00Z"
* dosage.text = "1 tablet (400 mg), dose-pole band B"
* extension[campaign].valueReference = Reference(example-mda-round)
* extension[recordOrigin].valueCode = #campaign
* extension[directlyObserved].valueBoolean = true
* extension[dosePoleBand].valueCodeableConcept.text = "Dose-pole band B (height 110–124 cm → 1 tablet)"

// Last-mile distribution vs node-to-node movement are separate profiles
// (supply-split round): this one is the coverage-bearing DISTRIBUTION — the
// recipient household Group is the per-capita join (3 nets ÷ Group.quantity).
Instance: example-itn-delivery
InstanceOf: ICRSupplyDistribution
Title: "ITN distribution to household"
Usage: #example
* meta.tag[+] = $ProjectTag#gallery "Gallery"
* status = #completed
* suppliedItem.quantity = 3 '{Net}' "nets"
* suppliedItem.itemCodeableConcept = $CommodityClass#llin "Long-lasting insecticidal net (LLIN)"
* destination = Reference(example-dwelling)
* extension[recipient].valueReference = Reference(example-household)
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
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* status = #complete
* type = #summary
* measure = "https://icr.healthcampaigns.org/Measure/icr-admin-coverage"
* period.start = "2026-06-15"
* period.end = "2026-06-26"
* reporter.display = "Kambia District Health Management Team"
* extension[campaign].valueReference = Reference(example-mr-sia-2026)
* extension[reporterTeam].valueReference = Reference(example-careteam)
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
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* status = #complete
* type = #summary
* measure = "https://icr.healthcampaigns.org/Measure/icr-survey-coverage"
* period.start = "2026-07-06"
* period.end = "2026-07-12"
* reporter.display = "Independent post-campaign coverage survey team"
* extension[campaign].valueReference = Reference(example-mr-sia-2026)
// The populations are SAMPLE counts (found vaccinated / children surveyed) —
// a survey's denominator IS its sample, unlike the admin report's population
// denominator. Shape deliberately parallels example-admin-coverage (same round).
* group.population[0].code = $MeasurePopulation#numerator "Numerator"
* group.population[0].count = 1596
* group.population[1].code = $MeasurePopulation#denominator "Denominator"
* group.population[1].count = 2100
* group.measureScore = 76 '%' "%"
* group.stratifier[0].code = $CoverageStratifier#sex "Sex"
* group.stratifier[0].stratum[0].value.text = "female"
* group.stratifier[0].stratum[0].measureScore = 78 '%' "%"
* group.stratifier[0].stratum[1].value.text = "male"
* group.stratifier[0].stratum[1].measureScore = 74 '%' "%"
* group.stratifier[1].code = $CoverageStratifier#age-band "Age band"
* group.stratifier[1].stratum[0].value.text = "9–59 months"
* group.stratifier[1].stratum[0].measureScore = 71 '%' "%"
* group.stratifier[1].stratum[1].value.text = "5–14 years"
* group.stratifier[1].stratum[1].measureScore = 79 '%' "%"
* extension[coverageSource].valueCode = #survey
* extension[sampleDesign].valueString = "WHO 30×10 cluster survey (n = 2,100), district-representative; evidence: vaccination card + caregiver recall; 76% (95% CI 72–80)"
* extension[dataLineage].valueCode = #reconciled

// LQAS — the second independent method (coverage-source #lqas). LQAS is an
// ACCEPT/REJECT decision rule per lot, not a coverage estimate: each lot
// (here a supervision area) samples 19 children and is rejected if more than
// 3 are unvaccinated. The report therefore counts LOTS (coverage-unit =
// implementation-units): 12 of 15 accepted; the rejected lots — each of which
// triggers mop-up — land in a disposition stratifier. The per-lot decision
// threshold lives in sample-design; explicit pass/fail + trigger semantics
// remain a §13.2 roadmap item.
Instance: example-lqas-coverage
InstanceOf: ICRSurveyCoverage
Title: "LQAS lot assessment — Kambia MR SIA, June 2026 round"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* status = #complete
* type = #summary
* measure = "https://icr.healthcampaigns.org/Measure/icr-survey-coverage"
* period.start = "2026-06-29"
* period.end = "2026-07-03"
* reporter.display = "Kambia District LQAS monitoring team"
* extension[campaign].valueReference = Reference(example-mr-sia-2026)
* group.population[0].code = $MeasurePopulation#numerator "Numerator"
* group.population[0].count = 12
* group.population[1].code = $MeasurePopulation#denominator "Denominator"
* group.population[1].count = 15
* group.measureScore = 80 '%' "%"
* group.stratifier[0].code = $CoverageStratifier#disposition "Disposition"
* group.stratifier[0].stratum[0].value.text = "lot rejected — mop-up triggered (Rokupr zone 1)"
* group.stratifier[0].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[0].stratum[0].population[0].count = 1
* group.stratifier[0].stratum[1].value.text = "lot rejected — mop-up triggered (Mambolo zone 2)"
* group.stratifier[0].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[0].stratum[1].population[0].count = 1
* group.stratifier[0].stratum[2].value.text = "lot rejected — mop-up triggered (Magbema zone 4)"
* group.stratifier[0].stratum[2].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[0].stratum[2].population[0].count = 1
* extension[coverageSource].valueCode = #lqas
* extension[coverageUnit].valueCode = #implementation-units
* extension[sampleDesign].valueString = "LQAS: 15 lots (supervision areas), 19 children sampled per lot; decision rule: reject the lot if >3 of 19 unvaccinated"
* extension[dataLineage].valueCode = #reconciled

// --- ESPEN MDA scenario: aggregate community-directed treatment ----------------
// The PC-NTD path the ESPEN demo forms collect (community-directed, register-level,
// no per-person record). Demonstrates v0.18.0 additions (espen.md recs 1-3, 7):
//   • a DRUG SupplyDelivery ATC-coded (rec 3) — same code as the administration;
//   • a community Task carrying exclusion reasons (rec 2) and an area-level missed
//     reason (rec 7), with aggregate counts on Task.output;
//   • the disaggregated treatment tally as a STRATIFIED MeasureReport (rec 1 / §2.1)
//     — sex × age-band stratifiers are how the drug×sex×age cube lands when there
//     is no person to attach a MedicationAdministration to.
// The campaign frame (protocol → round) gives the community Task its basedOn
// target — every Task points at its campaign; the CarePlan never lists tasks.

// Protocol-level eligibility: the age restriction lives on the PROTOCOL, not the
// ActivityDefinition (which has no eligibility element in base R4). subject carries
// a definitional Group — actual=false, no count, no geography — whose age-band
// characteristic is a computable valueRange, so downstream systems can evaluate
// "who is this protocol for" without parsing title text. Note this is definitional,
// not enforcement: point-of-delivery enforcement is form logic / dose pole, and an
// out-of-band administration stays recordable as a protocol deviation.
Instance: example-sth-eligible-population
InstanceOf: Group
Title: "STH MDA eligible population — school-age children 5–14 years (definitional)"
Usage: #example
* meta.tag[+] = $ProjectTag#mda "MDA (Rokupr)"
* type = #person
* actual = false
* name = "School-age children 5–14 years (STH MDA protocol eligibility)"
* characteristic[0].code = $GroupCharacteristic#age-band "Age band"
* characteristic[0].valueRange.low = 5 'a' "years"
* characteristic[0].valueRange.high = 14 'a' "years"
* characteristic[0].exclude = false

Instance: example-sth-mda-protocol
InstanceOf: ICRCampaignProtocol
Title: "STH MDA protocol — albendazole, community-directed"
Usage: #example
* meta.tag[+] = $ProjectTag#mda "MDA (Rokupr)"
* status = #active
* version = "1.0.0"
* title = "Soil-transmitted helminthiasis MDA (albendazole), community-directed distribution"
* type = $CampaignType#mda "Mass drug administration"
* subjectReference = Reference(example-sth-eligible-population)
* goal.description.text = "≥75% epidemiological coverage of the at-risk population"
* action.title = "Administer albendazole 400 mg single dose, community-directed"
* action.definitionCanonical = Canonical(example-albendazole-activity)
* extension[deliveryStrategy].valueCodeableConcept = $DeliveryStrategy#community-directed "Community-directed distribution"

Instance: example-target-population-sth
InstanceOf: ICRTargetPopulation
Title: "Example Target Population — at-risk population, Rokupr community (STH MDA)"
Usage: #example
* meta.tag[+] = $ProjectTag#mda "MDA (Rokupr)"
* type = #person
* actual = false
* name = "At-risk population, Rokupr community (STH MDA 2026 planning denominator)"
* quantity = 3200
* characteristic[geography].code = $GroupCharacteristic#geography "Geographic scope"
* characteristic[geography].valueReference = Reference(example-settlement)
* characteristic[geography].exclude = false
// The concrete denominator mirrors the protocol's definitional age band
// (example-sth-eligible-population) — same characteristic, same computable range.
* characteristic[1].code = $GroupCharacteristic#age-band "Age band"
* characteristic[1].valueRange.low = 5 'a' "years"
* characteristic[1].valueRange.high = 14 'a' "years"
* characteristic[1].exclude = false
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#microcensus "Microcensus / enumeration"
* extension[denominatorType].valueCode = #at-risk
* extension[estimateDate].valueDate = "2026-01-20"
* extension[isPlanningDenominator].valueBoolean = true

Instance: example-mda-round
InstanceOf: ICRCampaign
Title: "STH MDA, Rokupr community — February 2026 round"
Usage: #example
* meta.tag[+] = $ProjectTag#mda "MDA (Rokupr)"
* instantiatesCanonical = Canonical(example-sth-mda-protocol)
* status = #completed
* intent = #order
* title = "STH MDA (albendazole), Rokupr community, February 2026"
* category = $CampaignType#mda "Mass drug administration"
* subject = Reference(example-target-population-sth)
* period.start = "2026-02-08"
* period.end = "2026-02-12"
* extension[targetGeography].valueReference = Reference(example-settlement)
* extension[planningDenominator].valueReference = Reference(example-target-population-sth)
* extension[dataLineage].valueCode = #reconciled

// The stock-bearing MOVEMENT side of the supply split: receipt at the community
// staging point, with the full accountability ledger. The onward issue to the
// CDD team below chains back here via partOf.
Instance: example-albendazole-supply
InstanceOf: ICRSupplyMovement
Title: "Albendazole receipt — Rokupr community (ATC-coded drug supply)"
Usage: #example
* meta.tag[+] = $ProjectTag#mda "MDA (Rokupr)"
* status = #completed
* suppliedItem.quantity = 3600 '{tbl}' "tablets"
* suppliedItem.itemCodeableConcept = $ATC#P02CA03 "albendazole"
* destination = Reference(example-settlement)
* extension[campaign].valueReference = Reference(example-mda-round)
* extension[recordOrigin].valueCode = #campaign
* extension[stockAccountability].extension[received].valueQuantity = 3600 '{tbl}' "tablets"
* extension[stockAccountability].extension[used].valueQuantity = 3080 '{tbl}' "tablets"
* extension[stockAccountability].extension[remaining].valueQuantity = 500 '{tbl}' "tablets"
* extension[stockAccountability].extension[notUsable].valueQuantity = 20 '{tbl}' "tablets"
* extension[stockAccountability].extension[concordant].valueBoolean = true

// Field-team daily stock: one issuance per team per day, ledger closes the day.
// partOf → the community receipt makes the chain explicit and queryable.
Instance: example-team-issuance
InstanceOf: ICRSupplyMovement
Title: "Albendazole issue — CDD team 7, day 1 (field-team daily stock)"
Usage: #example
* meta.tag[+] = $ProjectTag#mda "MDA (Rokupr)"
* status = #completed
* suppliedItem.quantity = 400 '{tbl}' "tablets"
* suppliedItem.itemCodeableConcept = $ATC#P02CA03 "albendazole"
* destination = Reference(example-settlement)
* partOf = Reference(example-albendazole-supply)
* extension[campaign].valueReference = Reference(example-mda-round)
* extension[recordOrigin].valueCode = #campaign
* extension[issuedToTeam].valueReference = Reference(example-careteam)
* extension[stockAccountability].extension[received].valueQuantity = 400 '{tbl}' "tablets"
* extension[stockAccountability].extension[used].valueQuantity = 360 '{tbl}' "tablets"
* extension[stockAccountability].extension[remaining].valueQuantity = 38 '{tbl}' "tablets"
* extension[stockAccountability].extension[notUsable].valueQuantity = 2 '{tbl}' "tablets"
* extension[stockAccountability].extension[concordant].valueBoolean = true

Instance: example-mda-community-task
InstanceOf: ICRCampaignTask
Title: "Community-directed MDA — Rokupr, albendazole round"
Usage: #example
* meta.tag[+] = $ProjectTag#mda "MDA (Rokupr)"
* status = #completed
* intent = #order
* code.text = "Community-directed MDA: albendazole (STH preventive chemotherapy)"
// Per-village disease scoping (minor-issue fix): the disease(s) treated in THIS
// community ride Task.reasonCode (here STH only); a co-endemic village would
// instantiate additional disease-specific activities/Tasks, so disease varies by
// village without overloading Campaign.addresses.
* reasonCode.text = "Soil-transmitted helminthiasis (STH)"
* basedOn = Reference(example-mda-round)
* instantiatesCanonical = Canonical(example-albendazole-activity)
* for = Reference(example-community)
* owner = Reference(example-careteam)
* location = Reference(example-settlement)
* executionPeriod.start = "2026-02-08"
* executionPeriod.end = "2026-02-12"
* extension[deliveryStrategy].valueCodeableConcept = $DeliveryStrategy#community-directed "Community-directed distribution"
* extension[taskOrigin].valueCode = #pre-planned
* extension[dataLineage].valueCode = #reconciled
* output[0].type = $TaskOutputType#treated-count "Persons treated / vaccinated (scalar tally)"
* output[0].valueUnsignedInt = 2900
* output[1].type = $TaskOutputType#exclusion-reason "Exclusion reason"
* output[1].valueCodeableConcept = $ExclusionReason#under-height-age "Below dose-pole minimum (height/age)"
* output[2].type = $TaskOutputType#exclusion-reason "Exclusion reason"
* output[2].valueCodeableConcept = $ExclusionReason#pregnant "Pregnant"
* output[3].type = $TaskOutputType#exclusion-reason "Exclusion reason"
* output[3].valueCodeableConcept = $ExclusionReason#breastfeeding "Breastfeeding / lactating"
* output[4].type = $TaskOutputType#missed-reason "Missed reason"
* output[4].valueCodeableConcept = $MissedReason#absent "Absent"
* output[5].type = $TaskOutputType#noncompliance-reason "Refusal reason"
* output[5].valueCodeableConcept = $NoncomplianceReason#no-felt-need "No felt need"
* output[6].type = $TaskOutputType#coverage-report "Coverage report reference"
* output[6].valueReference = Reference(example-mda-treatment-tally)

Instance: example-mda-treatment-tally
InstanceOf: ICRAdministrativeCoverage
Title: "MDA treatment coverage — Rokupr albendazole round (sex × age stratified)"
Usage: #example
* meta.tag[+] = $ProjectTag#mda "MDA (Rokupr)"
* status = #complete
* type = #summary
* measure = "https://icr.healthcampaigns.org/Measure/icr-mda-treatment-coverage"
* period.start = "2026-02-08"
* period.end = "2026-02-12"
* reporter.display = "Rokupr health-area CDD supervisor"
* extension[campaign].valueReference = Reference(example-mda-round)
* group.population[0].code = $MeasurePopulation#numerator "Numerator"
* group.population[0].count = 2900
* group.population[1].code = $MeasurePopulation#denominator "Denominator"
* group.population[1].count = 3200
* group.measureScore = 91 '%' "%"
// The drug × sex × age-band × disposition cube the ESPEN treatment form collects,
// carried as MeasureReport stratifiers keyed by the standard ICRCoverageStratifier
// axes the Measure (icr-mda-treatment-coverage) declares — the canonical, now-
// conformant home for a disaggregated aggregate tally (v0.19.0).
* group.stratifier[0].code = $CoverageStratifier#sex "Sex"
* group.stratifier[0].stratum[0].value.text = "female"
* group.stratifier[0].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[0].stratum[0].population[0].count = 1500
* group.stratifier[0].stratum[1].value.text = "male"
* group.stratifier[0].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[0].stratum[1].population[0].count = 1400
* group.stratifier[1].code = $CoverageStratifier#age-band "Age band"
* group.stratifier[1].stratum[0].value.text = "5–14 years"
* group.stratifier[1].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[1].stratum[0].population[0].count = 1100
* group.stratifier[1].stratum[1].value.text = "15+ years"
* group.stratifier[1].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[1].stratum[1].population[0].count = 1800
// Disposition axis (minor-issue fix): the not-treated cube unified into the same
// report — treated vs the exclusion/missed/refusal dispositions the Task counts.
* group.stratifier[2].code = $CoverageStratifier#disposition "Disposition"
* group.stratifier[2].stratum[0].value.text = "treated"
* group.stratifier[2].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[2].stratum[0].population[0].count = 2900
* group.stratifier[2].stratum[1].value.text = "not treated — excluded (under-height/pregnant/breastfeeding)"
* group.stratifier[2].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[2].stratum[1].population[0].count = 180
* group.stratifier[2].stratum[2].value.text = "not treated — absent"
* group.stratifier[2].stratum[2].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[2].stratum[2].population[0].count = 95
* group.stratifier[2].stratum[3].value.text = "not treated — refused"
* group.stratifier[2].stratum[3].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[2].stratum[3].population[0].count = 25
* extension[coverageSource].valueCode = #administrative
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#microcensus "Microcensus / enumeration"
* extension[denominatorType].valueCode = #at-risk
* extension[coverageUnit].valueCode = #people
* extension[dataLineage].valueCode = #reconciled

// --- v0.19.0: geographic coverage, adverse events, team & supervision ----------

// Geographic (implementation-unit) coverage — the ESPEN supervision-form "villages
// treated / total" figure, with non-treatment reasons as a disposition stratifier
// (coverage-unit = implementation-units; §17.2 B1).
Instance: example-geographic-coverage
InstanceOf: ICRAdministrativeCoverage
Title: "Geographic coverage — Kambia MDA (villages treated / total)"
Usage: #example
* meta.tag[+] = $ProjectTag#mda "MDA (Rokupr)"
* status = #complete
* type = #summary
* measure = "https://icr.healthcampaigns.org/Measure/icr-geographic-coverage"
* period.start = "2026-02-08"
* period.end = "2026-02-26"
* reporter.display = "Kambia District NTD supervisor"
// No campaign link here on purpose: this district-scope figure reports against a
// Kambia-district MDA round whose CarePlan is not modeled in the example set
// (example-mda-round is the Rokupr community round) — also demonstrates the
// link's 0..1 cardinality.
* group.population[0].code = $MeasurePopulation#numerator "Numerator"
* group.population[0].count = 188
* group.population[1].code = $MeasurePopulation#denominator "Denominator"
* group.population[1].count = 200
* group.measureScore = 94 '%' "%"
* group.stratifier[0].code = $CoverageStratifier#disposition "Disposition"
* group.stratifier[0].stratum[0].value.text = "not treated — insecurity"
* group.stratifier[0].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[0].stratum[0].population[0].count = 7
* group.stratifier[0].stratum[1].value.text = "not treated — medication shortage"
* group.stratifier[0].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[0].stratum[1].population[0].count = 5
* extension[coverageSource].valueCode = #administrative
* extension[coverageUnit].valueCode = #implementation-units
* extension[dataLineage].valueCode = #reconciled

// AEFI — the immunization arm (a child with fever after the MCV dose, #22).
Instance: example-aefi
InstanceOf: ICRAdverseEvent
Title: "AEFI — fever following MCV dose"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* actuality = #actual
* event.text = "Fever within 48h of measles-containing vaccine"
* subject = Reference(example-child)
* date = "2026-06-26"
* seriousness.text = "Non-serious"
* severity.text = "mild"
* suspectEntity.instance = Reference(example-mcv-dose)
* suspectEntity.causality.assessment = $AdverseEventCausality#a-consistent "A — Consistent causal association"
* extension[recordOrigin].valueCode = #campaign

// MDA pharmacovigilance arm — a drug side-effect after albendazole (#23). Same
// profile, intervention-neutral: subject is a person, suspect is the MDA event.
Instance: example-mda-adverse-event
InstanceOf: ICRAdverseEvent
Title: "Adverse event — abdominal pain following albendazole"
Usage: #example
* meta.tag[+] = $ProjectTag#mda "MDA (Rokupr)"
* actuality = #actual
* event.text = "Transient abdominal pain following albendazole"
* subject = Reference(example-child)
* date = "2026-02-10"
* seriousness.text = "Non-serious"
* severity.text = "mild"
* suspectEntity.instance = Reference(example-albendazole-administration)
* suspectEntity.causality.assessment = $AdverseEventCausality#c-coincidental "C — Coincidental / inconsistent"
* extension[recordOrigin].valueCode = #campaign

// A SERIOUS AEFI — demonstrates seriousness + the serious-criteria extension.
Instance: example-aefi-serious
InstanceOf: ICRAdverseEvent
Title: "AEFI — anaphylaxis following MCV dose (serious)"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* actuality = #actual
* event.text = "Anaphylaxis shortly after measles-containing vaccine"
* subject = Reference(example-child)
* date = "2026-06-24"
* seriousness.text = "Serious"
* severity.text = "severe"
* suspectEntity.instance = Reference(example-mcv-dose)
* suspectEntity.causality.assessment = $AdverseEventCausality#a-consistent "A — Consistent causal association"
* extension[recordOrigin].valueCode = #campaign
* extension[seriousCriteria][0].valueCodeableConcept = $SeriousCriteria#life-threatening "Life-threatening"
* extension[seriousCriteria][1].valueCodeableConcept = $SeriousCriteria#hospitalization "Requires/prolongs hospitalization"

// The delivery team and its supervisor (working doc §5.5) — the team that owns the
// mop-up Task and whose supervisor reports Kambia's coverage.
Instance: example-careteam
InstanceOf: ICRCareTeam
Title: "Care team — CDD team 7, Rokupr"
Usage: #example
* meta.tag[+] = $ProjectTag#mda "MDA (Rokupr)"
* status = #active
* name = "CDD team 7, Rokupr"
* subject = Reference(example-target-population)
* participant[0].role = $TeamRole#vaccinator "Vaccinator"
* participant[0].member.display = "Fatmata Sesay (vaccinator)"
* participant[1].role = $TeamRole#cdd "Community drug distributor (CDD)"
* participant[1].member.display = "Mariama Bangura (CDD)"
* participant[2].role = $TeamRole#supervisor "Supervisor"
* participant[2].member.display = "Ibrahim Conteh (supervisor)"
* managingOrganization.display = "Kambia District Health Management Team"
* extension[overseesArea].valueReference = Reference(example-supervisory-area)
* extension[workloadTarget].extension[targetArea].valueReference = Reference(example-supervisory-area)
* extension[workloadTarget].extension[targetPopulation].valueUnsignedInt = 3200
* extension[workloadTarget].extension[targetHouseholds].valueUnsignedInt = 640
* extension[workloadTarget].extension[targetDays].valueUnsignedInt = 5

// Structured supervision-visit record (ESPEN Form 6 CDD-observation): an
// ICRCampaignFormResponse against the icr-mda-supervision-checklist — the
// questionnaire canonical is the form-type discriminator, each answer links to
// a coded question, and basedOn ties the submission to its round.
Instance: example-supervision-report
InstanceOf: ICRCampaignFormResponse
Title: "Supervision report — CDD observation, Rokupr"
Usage: #example
* meta.tag[+] = $ProjectTag#mda "MDA (Rokupr)"
* questionnaire = "https://icr.healthcampaigns.org/Questionnaire/icr-mda-supervision-checklist"
* status = #completed
* basedOn = Reference(example-mda-round)
* subject = Reference(example-community)
* authored = "2026-02-10"
* author.display = "Ibrahim Conteh (supervisor), CDD team 7"
* item[0].linkId = "cdd-observation"
* item[0].text = "CDD observation"
* item[0].item[0].linkId = "cdd.doc"
* item[0].item[0].text = "Medicine taken in the presence of the distributor (DOC)"
* item[0].item[0].answer.valueBoolean = true
* item[0].item[1].linkId = "cdd.height-chart-used"
* item[0].item[1].text = "Height chart used correctly"
* item[0].item[1].answer.valueBoolean = true
* item[0].item[2].linkId = "cdd.ineligibles"
* item[0].item[2].text = "Ineligible individuals correctly identified"
* item[0].item[2].answer.valueBoolean = true
* item[1].linkId = "stock"
* item[1].text = "Stock & wastage"
* item[1].item[0].linkId = "stock.concordant"
* item[1].item[0].text = "Physical stock matches theoretical stock"
* item[1].item[0].answer.valueBoolean = false

// --- v0.21.0 (forms-v1) examples ----------------------------------------------

// Person-targeted follow-up Task: the child absent at the mop-up visit
// (example-mopup-task) is traced on revisit and found already vaccinated. Task.focus
// is the Patient being followed up (the profile's person-targeted follow-up case),
// Task.partOf links the originating Task, and the revisit-outcome extension records
// the result (jul3-form-analysis §Aggregate #4).
Instance: example-followup-task
InstanceOf: ICRCampaignTask
Title: "Follow-up revisit — missed child, Rokupr block 4"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* status = #completed
* intent = #order
* code.text = "Revisit missed child from mop-up visit"
* basedOn = Reference(example-mr-sia-2026)
* for = Reference(example-child)
* partOf = Reference(example-mopup-task)
* owner = Reference(example-careteam)
* location = Reference(example-dwelling)
* executionPeriod.start = "2026-06-25T10:00:00Z"
* executionPeriod.end = "2026-06-25T10:10:00Z"
* extension[deliveryStrategy].valueCodeableConcept = $DeliveryStrategy#house-to-house "House-to-house"
* extension[taskOrigin].valueCode = #pre-planned
* output.type = $TaskOutputType#revisit-outcome "Revisit outcome"
* output.valueCodeableConcept = $RevisitOutcome#already-vaccinated "Already vaccinated"

// Pre-campaign readiness validation of the Kambia round at ward/operational level
// (UNICEF Preparedness Validation form): the SAME ICRCampaignFormResponse profile
// as the supervision report — the readiness checklist canonical is what makes it
// a readiness record — subject is the operational Location; rolls up via the
// icr-campaign-readiness Measure (jul3-form-analysis §Aggregate #2).
Instance: example-readiness-report
InstanceOf: ICRCampaignFormResponse
Title: "Readiness validation — Kambia supervision zone 2"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* questionnaire = "https://icr.healthcampaigns.org/Questionnaire/icr-campaign-readiness-checklist"
* status = #completed
* basedOn = Reference(example-mr-sia-2026)
* subject = Reference(example-supervisory-area)
* authored = "2026-06-12"
* author.display = "Ibrahim Conteh (national supervisor)"
* item[0].linkId = "microplan"
* item[0].text = "Microplan"
* item[0].item[0].linkId = "microplan.available"
* item[0].item[0].text = "Microplan document available"
* item[0].item[0].answer.valueBoolean = true
* item[0].item[1].linkId = "microplan.htra"
* item[0].item[1].text = "Hard-to-reach areas / special populations addressed with strategies"
* item[0].item[1].answer.valueBoolean = true
* item[1].linkId = "cold-chain"
* item[1].text = "Cold chain & logistics"
* item[1].item[0].linkId = "cc.temperature"
* item[1].item[0].text = "Refrigerator temperature maintained +2 to +8 C"
* item[1].item[0].answer.valueBoolean = true
* item[1].item[1].linkId = "cc.supplies-on-time"
* item[1].item[1].text = "Supplies arrived on time"
* item[1].item[1].answer.valueBoolean = false
* item[2].linkId = "trainings"
* item[2].text = "Trainings"
* item[2].item[0].linkId = "tr.teams-trained"
* item[2].item[0].text = "Supervisors and teams trained"
* item[2].item[0].answer.valueBoolean = true

// --- Supply-driven descoping (v0.1): the "planned per protocol vs targeted
// this round" comparison. The national SCH policy treats everyone 2 years and
// older, but this round's praziquantel supply covers only school-aged children —
// so the round's subject is a NARROWER denominator than the protocol's subject
// template, and the deviation stays visible by comparing the two. Targeting
// deviations (population or geography) never require a protocol change; a
// durable eligibility change would be a new protocol version (working doc §4.2).

// The two forms-v1 Measures instantiated (ig-compare §9 item 7): worked
// MeasureReports for zero-dose reach and pre-campaign readiness.

Instance: example-zero-dose-coverage
InstanceOf: ICRAdministrativeCoverage
Title: "Zero-dose reach — Kambia MR SIA, June 2026 round"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* status = #complete
* type = #summary
* measure = "https://icr.healthcampaigns.org/Measure/icr-zero-dose-coverage"
* period.start = "2026-06-15"
* period.end = "2026-06-26"
* reporter.display = "Kambia District Health Management Team"
* extension[campaign].valueReference = Reference(example-mr-sia-2026)
* extension[reporterTeam].valueReference = Reference(example-careteam)
* extension[coverageSource].valueCode = #administrative
* extension[dataLineage].valueCode = #reconciled
* group.population[0].code = $MeasurePopulation#numerator "Numerator"
* group.population[0].count = 2866
* group.population[1].code = $MeasurePopulation#denominator "Denominator"
* group.population[1].count = 47766
* group.measureScore = 6 '%' "%"
* group.stratifier[0].code = $CoverageStratifier#dose-history "Dose history / zero-dose status"
* group.stratifier[0].stratum[0].value.text = "zero-dose"
* group.stratifier[0].stratum[0].measureScore = 6 '%' "%"
* group.stratifier[0].stratum[1].value.text = "previously-received"
* group.stratifier[0].stratum[1].measureScore = 91 '%' "%"
* group.stratifier[0].stratum[2].value.text = "no-recall"
* group.stratifier[0].stratum[2].measureScore = 3 '%' "%"

Instance: example-readiness-coverage
InstanceOf: ICRAdministrativeCoverage
Title: "Campaign readiness roll-up — Kambia, pre-campaign validation"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* status = #complete
* type = #summary
* measure = "https://icr.healthcampaigns.org/Measure/icr-campaign-readiness"
* period.start = "2026-06-01"
* period.end = "2026-06-12"
* reporter.display = "Kambia District Health Management Team"
* extension[campaign].valueReference = Reference(example-mr-sia-2026)
* extension[reporterTeam].valueReference = Reference(example-careteam)
* extension[coverageSource].valueCode = #administrative
* extension[coverageUnit].valueCode = #implementation-units
* extension[dataLineage].valueCode = #realtime
* group.population[0].code = $MeasurePopulation#numerator "Numerator"
* group.population[0].count = 10
* group.population[1].code = $MeasurePopulation#denominator "Denominator"
* group.population[1].count = 12
* group.measureScore = 83 '%' "%"
* group.stratifier[0].code = $CoverageStratifier#readiness-domain "Readiness domain"
* group.stratifier[0].stratum[0].value.text = "microplan"
* group.stratifier[0].stratum[0].measureScore = 100 '%' "%"
* group.stratifier[0].stratum[1].value.text = "cold-chain"
* group.stratifier[0].stratum[1].measureScore = 83 '%' "%"
* group.stratifier[0].stratum[2].value.text = "social-mobilization"
* group.stratifier[0].stratum[2].measureScore = 75 '%' "%"
* group.stratifier[0].stratum[3].value.text = "trainings"
* group.stratifier[0].stratum[3].measureScore = 83 '%' "%"

Instance: example-sch-mda-protocol
InstanceOf: ICRCampaignProtocol
Title: "Schistosomiasis MDA protocol — national policy: everyone 2+"
Usage: #example
* meta.tag[+] = $ProjectTag#gallery "Gallery"
* status = #active
* version = "1.0.0"
* title = "Schistosomiasis MDA (praziquantel), entire population 2 years and older"
* type = $CampaignType#mda "Mass drug administration"
* subjectCodeableConcept.text = "Entire population 2 years and older (national SCH policy)"
* goal.description.text = "≥75% epidemiological coverage of the eligible population"
* extension[deliveryStrategy].valueCodeableConcept = $DeliveryStrategy#community-directed "Community-directed"

Instance: example-target-population-sac
InstanceOf: ICRTargetPopulation
Title: "Example Target Population — school-aged children 5–14, Kambia District (descoped round)"
Usage: #example
* meta.tag[+] = $ProjectTag#gallery "Gallery"
* type = #person
* actual = false
* name = "School-aged children 5–14, Kambia District — the narrower population actually targeted this round"
* quantity = 14800
* characteristic[geography].code = $GroupCharacteristic#geography "Geographic scope"
* characteristic[geography].valueReference = Reference(example-district)
* characteristic[geography].exclude = false
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#govt-estimate "Government estimate"
* extension[denominatorType].valueCode = #at-risk
* extension[estimateDate].valueDate = "2026-02-01"
* extension[isPlanningDenominator].valueBoolean = true

Instance: example-sch-descoped-round
InstanceOf: ICRCampaign
Title: "Kambia SCH MDA 2026 — descoped round (SAC only, supply-constrained)"
Usage: #example
* meta.tag[+] = $ProjectTag#gallery "Gallery"
* instantiatesCanonical = Canonical(example-sch-mda-protocol)
* status = #active
* intent = #order
* title = "SCH MDA, Kambia District, 2026 — school-aged children only (praziquantel supply shortfall)"
* category = $CampaignType#mda "Mass drug administration"
* subject = Reference(example-target-population-sac)
* period.start = "2026-09-07"
* period.end = "2026-09-18"
* extension[targetGeography].valueReference = Reference(example-district)
* extension[planningDenominator].valueReference = Reference(example-target-population-sac)

// School-based delivery: the school-cohort delivery unit — the same Group +
// Location pattern as the household and the community, with the school as its
// Location. The descoped SAC round delivers praziquantel through schools; one
// Task per school-session acts on the enrolled cohort.

Instance: example-school
InstanceOf: ICRLocation
Title: "Example School — Rokupr Primary School"
Usage: #example
* meta.tag[+] = $ProjectTag#gallery "Gallery"
* name = "Rokupr Primary School"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#bu "Building"
* type = $LocationType#school "School"
* partOf = Reference(example-settlement)
* position.longitude = -12.9458
* position.latitude = 9.0152
* identifier[gers].system = $GERSId
* identifier[gers].value = "08f2a3b4c5d6e7f8-building-school-example"

Instance: example-school-cohort
InstanceOf: ICRDeliveryUnit
Title: "Example School Cohort — Rokupr Primary School"
Usage: #example
* meta.tag[+] = $ProjectTag#gallery "Gallery"
* type = #person
* actual = true
* code = $GroupKind#school-cohort "School cohort"
* name = "Rokupr Primary School enrolled cohort"
* quantity = 260
* extension[groupLocation].valueReference = Reference(example-school)

Instance: example-school-mda-task
InstanceOf: ICRCampaignTask
Title: "School session — praziquantel MDA at Rokupr Primary School"
Usage: #example
* meta.tag[+] = $ProjectTag#gallery "Gallery"
* status = #completed
* intent = #order
* code.text = "School-based praziquantel administration, enrolled cohort"
* basedOn = Reference(example-sch-descoped-round)
* for = Reference(example-school-cohort)
* location = Reference(example-school)
* executionPeriod.start = "2026-09-09T09:00:00Z"
* executionPeriod.end = "2026-09-09T13:00:00Z"
* extension[deliveryStrategy].valueCodeableConcept = $DeliveryStrategy#school "School-based"
* extension[taskOrigin].valueCode = #pre-planned
* output.type = $TaskOutputType#treated-count "Persons treated / vaccinated (scalar tally)"
* output.valueUnsignedInt = 244

// mCSD-style facility pairing: the Organization is the accountable entity
// (registry codes, classification, ownership, reporting hierarchy); the
// Location is the physical place, linked via managingOrganization.

Instance: example-facility-org
InstanceOf: ICRFacilityOrganization
Title: "Example Facility Organization — Rokupr CHC"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* active = true
* name = "Rokupr Community Health Centre"
* type[+].coding = $OrgType#prov "Healthcare Provider"
* type[+].coding = $FacilityType#primary "Primary care facility"
* type[=].text = "Community Health Centre"
* type[+].coding = $Ownership#public "Public"
* identifier[+].system = $RegistryId
* identifier[=].value = "SL-MFL-0421"

Instance: example-facility
InstanceOf: ICRLocation
Title: "Example Facility — Rokupr CHC (place)"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* name = "Rokupr Community Health Centre"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#si "Site"
* type[+] = $LocationType#facility "Health facility"
// Duplicated classification (Organization.type stays authoritative):
* type[+].coding = $FacilityType#primary "Primary care facility"
* type[=].text = "Community Health Centre"
* type[+].coding = $Ownership#public "Public"
* partOf = Reference(example-settlement)
* managingOrganization = Reference(example-facility-org)
* position.longitude = -12.9465
* position.latitude = 9.0140
* identifier[gers].system = $GERSId
* identifier[gers].value = "08f2a3b4c5d6e7f8-place-chc-example"

// --- Location-status assertions (location-status round) -----------------------
// The JRSM district endemicity table as data: one Observation per district ×
// disease, subject = the Location — never a field inside Location (georegistry
// rule; endemicity is revisable epidemiological state with provenance, exactly
// the denominator epistemology). Two assertions on the same district give the
// co-endemicity read. An assertion covers the district's whole subtree unless
// a lower-level assertion overrides it.

Instance: example-lf-endemicity
InstanceOf: ICRLocationStatus
Title: "LF endemicity — Kambia District (endemic, under MDA)"
Usage: #example
* meta.tag[+] = $ProjectTag#gallery "Gallery"
* status = #final
* code = $LocationStatus#lf-endemicity "Lymphatic filariasis endemicity"
* subject = Reference(example-district)
* valueCodeableConcept = $EndemicityStatus#endemic-under-mda "Endemic, under MDA"
* effectiveDateTime = "2026-01-15"
* performer.display = "MoH NTD Programme — JRSM 2026 submission"
* method.text = "District-level LF mapping survey (2019), reconfirmed through annual JRSM reporting"
* derivedFrom.display = "LF mapping survey report, Kambia District, 2019"

Instance: example-oncho-endemicity
InstanceOf: ICRLocationStatus
Title: "Onchocerciasis endemicity — Kambia District (non-endemic)"
Usage: #example
* meta.tag[+] = $ProjectTag#gallery "Gallery"
* status = #final
* code = $LocationStatus#oncho-endemicity "Onchocerciasis endemicity"
* subject = Reference(example-district)
* valueCodeableConcept = $EndemicityStatus#non-endemic "Non-endemic"
* effectiveDateTime = "2026-01-15"
* performer.display = "MoH NTD Programme — JRSM 2026 submission"
* method.text = "Epidemiological mapping (REMO); no active transmission foci"

// --- cost-v1: the Kambia cost thread ------------------------------------------
// Line items are Observations pointing AT the campaign (basedOn) and attributed to
// a PLACE at the grain the source states: the vaccine is one national line on the
// umbrella (UNICEF-procured, Gavi-funded); the per diems and transport are district
// lines on the Kambia round (budget from the microplan, actuals from the DHMT
// expenditure return). The two cost reports divide the same total by the same
// denominators the coverage reports use — one full, one delivery-only — and list
// their inputs. Amounts are an illustrative composite (SLE ≈ 22.5 per USD).

Instance: example-cost-vaccine-national
InstanceOf: ICRCampaignCost
Title: "Cost line — MR vaccine, national procurement (actual, umbrella campaign)"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* status = #final
* basedOn = Reference(example-mr-sia-national)
* code = $CostCategory#commodities "Commodities"
* subject = Reference(example-country)
* effectivePeriod.start = "2026-04-01"
* effectivePeriod.end = "2026-06-14"
* performer.display = "UNICEF Sierra Leone Country Office"
* extension[costLineage].valueCode = #actual
* extension[costPerspective].valueCode = #financial
* extension[fundingSource].valueCodeableConcept = $FundingSource#gavi "Gavi"
* valueQuantity = 30000 $ISO4217#USD "USD"
* component[units].valueQuantity = 50000 '{dose}' "doses"
* component[unitCost].valueQuantity = 0.60 $ISO4217#USD "USD per dose"
* component[amountUsd].valueQuantity = 30000 $ISO4217#USD "USD"
* note.text = "MR vaccine for the Kambia round incl. freight and insurance; 50,000 doses procured against 48,250 targeted (wastage allowance). A NATIONAL line: apportioned to district reports only when fully-loaded."

Instance: example-cost-perdiem-budget
InstanceOf: ICRCampaignCost
Title: "Cost line — vaccinator per diems, Kambia round (budgeted)"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* status = #final
* basedOn = Reference(example-mr-sia-2026)
* code = $CostCategory#per-diem-incentive "Per diems & incentives"
* subject = Reference(example-district)
* effectivePeriod.start = "2026-06-15"
* effectivePeriod.end = "2026-06-26"
* performer.display = "Kambia District Health Management Team"
* extension[costLineage].valueCode = #budgeted
* extension[fundingSource].valueCodeableConcept = $FundingSource#gavi "Gavi"
* valueQuantity = 640000 $ISO4217#SLE "SLE"
* component[units].valueQuantity = 3200 'd' "person-days"
* component[unitCost].valueQuantity = 200 $ISO4217#SLE "SLE per person-day"
* component[amountUsd].valueQuantity = 28400 $ISO4217#USD "USD"
* derivedFrom.display = "Kambia District MR SIA microplan budget, April 2026"
* note.text = "Generated from the microplan: 640 vaccinators × 5 days (workload-target) × the SLE 200 per-diem norm."

Instance: example-cost-perdiem-actual
InstanceOf: ICRCampaignCost
Title: "Cost line — vaccinator per diems, Kambia round (actual)"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* status = #final
* basedOn = Reference(example-mr-sia-2026)
* code = $CostCategory#per-diem-incentive "Per diems & incentives"
* subject = Reference(example-district)
* effectivePeriod.start = "2026-06-15"
* effectivePeriod.end = "2026-07-31"
* performer.display = "Kambia District Health Management Team"
* extension[costLineage].valueCode = #actual
* extension[costPerspective].valueCode = #financial
* extension[fundingSource].valueCodeableConcept = $FundingSource#gavi "Gavi"
* valueQuantity = 668000 $ISO4217#SLE "SLE"
* component[amountUsd].valueQuantity = 29650 $ISO4217#USD "USD"
* derivedFrom.display = "DHMT campaign expenditure return, July 2026"
* note.text = "SLE 28,000 over budget: two extra mop-up days for team 7 (see the mop-up Task)."

Instance: example-cost-transport-actual
InstanceOf: ICRCampaignCost
Title: "Cost line — transport & fuel, Kambia round (actual)"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* status = #final
* basedOn = Reference(example-mr-sia-2026)
* code = $CostCategory#transport "Transport & fuel"
* subject = Reference(example-district)
* effectivePeriod.start = "2026-06-15"
* effectivePeriod.end = "2026-07-31"
* performer.display = "Kambia District Health Management Team"
* extension[costLineage].valueCode = #actual
* extension[fundingSource].valueCodeableConcept = $FundingSource#government "Government"
* valueQuantity = 277000 $ISO4217#SLE "SLE"
* component[amountUsd].valueQuantity = 12300 $ISO4217#USD "USD"
* derivedFrom.display = "DHMT campaign expenditure return, July 2026"

Instance: example-cost-report
InstanceOf: ICRCostReport
Title: "Cost report — Kambia MR SIA, June 2026 round (actual · financial · full · fully-loaded)"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* status = #complete
* type = #summary
* measure = "https://icr.healthcampaigns.org/Measure/icr-campaign-cost"
* period.start = "2026-06-15"
* period.end = "2026-06-26"
* reporter.display = "Kambia District Health Management Team"
* extension[campaign].valueReference = Reference(example-mr-sia-2026)
* extension[costLineage].valueCode = #actual
* extension[costPerspective].valueCode = #financial
* extension[costScope].valueCode = #full
* extension[costAllocation].extension[basis].valueCode = #fully-loaded
* extension[costAllocation].extension[method].valueString = "National commodity line apportioned to the round per dose delivered"
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#grid3 "GRID3 modelled estimate"
* extension[denominatorType].valueCode = #total-population
* extension[dataLineage].valueCode = #reconciled
// Group 1 — the total, disaggregated by category
* group[0].code = $CostFigure#total-cost "Total cost"
* group[0].measureScore = 96500 $ISO4217#USD "USD"
* group[0].stratifier[0].code = $CoverageStratifier#cost-category "Cost category"
* group[0].stratifier[0].stratum[0].value = $CostCategory#commodities "Commodities"
* group[0].stratifier[0].stratum[0].measureScore = 30000 $ISO4217#USD "USD"
* group[0].stratifier[0].stratum[1].value = $CostCategory#per-diem-incentive "Per diems & incentives"
* group[0].stratifier[0].stratum[1].measureScore = 29650 $ISO4217#USD "USD"
* group[0].stratifier[0].stratum[2].value = $CostCategory#transport "Transport & fuel"
* group[0].stratifier[0].stratum[2].measureScore = 12300 $ISO4217#USD "USD"
* group[0].stratifier[0].stratum[3].value = $CostCategory#training "Training"
* group[0].stratifier[0].stratum[3].measureScore = 7000 $ISO4217#USD "USD"
* group[0].stratifier[0].stratum[4].value = $CostCategory#cold-chain "Cold chain"
* group[0].stratifier[0].stratum[4].measureScore = 6050 $ISO4217#USD "USD"
* group[0].stratifier[0].stratum[5].value = $CostCategory#social-mobilization "Social mobilization & communication"
* group[0].stratifier[0].stratum[5].measureScore = 5500 $ISO4217#USD "USD"
* group[0].stratifier[0].stratum[6].value = $CostCategory#supervision-monitoring "Supervision & monitoring"
* group[0].stratifier[0].stratum[6].measureScore = 4000 $ISO4217#USD "USD"
* group[0].stratifier[0].stratum[7].value = $CostCategory#waste-management "Waste management"
* group[0].stratifier[0].stratum[7].measureScore = 2000 $ISO4217#USD "USD"
// Group 2 — ÷ the planning denominator (48,250, GRID3)
* group[1].code = $CostFigure#per-person-targeted "Cost per person targeted"
* group[1].population[0].code = $MeasurePopulation#denominator "Denominator"
* group[1].population[0].count = 48250
* group[1].measureScore = 2.00 $ISO4217#USD "USD per person targeted"
// Group 3 — ÷ persons reached (the admin-coverage numerator, 47,766, reconciled)
* group[2].code = $CostFigure#per-person-reached "Cost per person reached"
* group[2].population[0].code = $MeasurePopulation#denominator "Denominator"
* group[2].population[0].count = 47766
* group[2].measureScore = 2.02 $ISO4217#USD "USD per person reached"
* evaluatedResource[+] = Reference(example-admin-coverage)
* evaluatedResource[+] = Reference(example-cost-perdiem-actual)
* evaluatedResource[+] = Reference(example-cost-transport-actual)
* evaluatedResource[+] = Reference(example-cost-vaccine-national)

Instance: example-cost-report-delivery
InstanceOf: ICRCostReport
Title: "Cost report — Kambia MR SIA, June 2026 round (actual · financial · delivery-only)"
Usage: #example
* meta.tag[+] = $ProjectTag#mr-sia "MR SIA (Sierra Leone)"
* status = #complete
* type = #summary
* measure = "https://icr.healthcampaigns.org/Measure/icr-campaign-cost"
* period.start = "2026-06-15"
* period.end = "2026-06-26"
* reporter.display = "Kambia District Health Management Team"
* extension[campaign].valueReference = Reference(example-mr-sia-2026)
* extension[costLineage].valueCode = #actual
* extension[costPerspective].valueCode = #financial
* extension[costScope].valueCode = #delivery-only
* extension[costAllocation].extension[basis].valueCode = #fully-loaded
* extension[costAllocation].extension[method].valueString = "As example-cost-report; the national commodity line is excluded by scope, so here fully-loaded equals direct"
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#grid3 "GRID3 modelled estimate"
* extension[denominatorType].valueCode = #total-population
* extension[dataLineage].valueCode = #reconciled
// The same round, the same divisors, commodities excluded: the figure donors compare across countries.
* group[0].code = $CostFigure#total-cost "Total cost"
* group[0].measureScore = 66500 $ISO4217#USD "USD"
* group[1].code = $CostFigure#per-person-targeted "Cost per person targeted"
* group[1].population[0].code = $MeasurePopulation#denominator "Denominator"
* group[1].population[0].count = 48250
* group[1].measureScore = 1.38 $ISO4217#USD "USD per person targeted"
* group[2].code = $CostFigure#per-person-reached "Cost per person reached"
* group[2].population[0].code = $MeasurePopulation#denominator "Denominator"
* group[2].population[0].count = 47766
* group[2].measureScore = 1.39 $ISO4217#USD "USD per person reached"
* evaluatedResource[+] = Reference(example-admin-coverage)
* evaluatedResource[+] = Reference(example-cost-perdiem-actual)
* evaluatedResource[+] = Reference(example-cost-transport-actual)
