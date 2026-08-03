// Scenario-validation instances (scenario-validation branch).
// One integrated world — a Nigeria (Kogi State) SCH/STH MDA umbrella campaign —
// plus three satellites (IRS, ITN, Measles-Rubella SIA), built to stress-test the
// data model against the 21 review concerns (S1–S21) in
// scratch/scenario-generation/test-scenarios.md. Verdicts and evidence live in
// scratch/scenario-generation/validation-report.md.
// All ids are prefixed sc- to stay clear of the shipped example-* gallery.

// =============================================================================
// Cluster 1a — Admin hierarchy: country → state → LGA → ward → settlement → dwelling
// (S5 depth, S10 drill-down, S21 cross-LGA wards)
// =============================================================================

Instance: sc-nigeria
InstanceOf: ICRLocation
Title: "Scenario — Nigeria"
Usage: #example
* name = "Nigeria"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#jdn "Jurisdiction"
* type = $LocationType#admin-unit "Administrative unit"
* identifier[pcode].system = $PCode
* identifier[pcode].value = "NG"

Instance: sc-kogi-state
InstanceOf: ICRLocation
Title: "Scenario — Kogi State"
Usage: #example
* name = "Kogi State"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#jdn "Jurisdiction"
* type = $LocationType#admin-unit "Administrative unit"
* partOf = Reference(sc-nigeria)
* identifier[pcode].system = $PCode
* identifier[pcode].value = "NG023"

Instance: sc-lokoja-lga
InstanceOf: ICRLocation
Title: "Scenario — Lokoja LGA"
Usage: #example
* name = "Lokoja Local Government Area"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#jdn "Jurisdiction"
* type = $LocationType#admin-unit "Administrative unit"
* partOf = Reference(sc-kogi-state)
* identifier[pcode].system = $PCode
* identifier[pcode].value = "NG023013"

Instance: sc-ajaokuta-lga
InstanceOf: ICRLocation
Title: "Scenario — Ajaokuta LGA"
Usage: #example
* name = "Ajaokuta Local Government Area"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#jdn "Jurisdiction"
* type = $LocationType#admin-unit "Administrative unit"
* partOf = Reference(sc-kogi-state)
* identifier[pcode].system = $PCode
* identifier[pcode].value = "NG023002"

Instance: sc-felele-ward
InstanceOf: ICRLocation
Title: "Scenario — Felele Ward (Lokoja LGA)"
Usage: #example
* name = "Felele Ward"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#jdn "Jurisdiction"
* type = $LocationType#admin-unit "Administrative unit"
* partOf = Reference(sc-lokoja-lga)
* identifier[pcode].system = $PCode
* identifier[pcode].value = "NG023013004"

Instance: sc-adankolo-ward
InstanceOf: ICRLocation
Title: "Scenario — Adankolo Ward (Lokoja LGA)"
Usage: #example
* name = "Adankolo Ward"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#jdn "Jurisdiction"
* type = $LocationType#admin-unit "Administrative unit"
* partOf = Reference(sc-lokoja-lga)
* identifier[pcode].system = $PCode
* identifier[pcode].value = "NG023013001"

Instance: sc-geregu-ward
InstanceOf: ICRLocation
Title: "Scenario — Geregu Ward (Ajaokuta LGA)"
Usage: #example
* name = "Geregu Ward"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#jdn "Jurisdiction"
* type = $LocationType#admin-unit "Administrative unit"
* partOf = Reference(sc-ajaokuta-lga)
* identifier[pcode].system = $PCode
* identifier[pcode].value = "NG023002003"

Instance: sc-felele-central
InstanceOf: ICRLocation
Title: "Scenario — Felele-Central settlement"
Usage: #example
* name = "Felele-Central"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#area "Area"
* type = $LocationType#settlement "Settlement"
* partOf = Reference(sc-felele-ward)
* position.longitude = 6.7315
* position.latitude = 7.7823
* identifier[gers].system = $GERSId
* identifier[gers].value = "08f2c4d5e6f7a8b9-place-felele-central"
* extension[settlementType].valueCodeableConcept = $SettlementType#urban "Urban"

Instance: sc-geregu-riverside
InstanceOf: ICRLocation
Title: "Scenario — Geregu-Riverside settlement"
Usage: #example
* name = "Geregu-Riverside"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#area "Area"
* type = $LocationType#settlement "Settlement"
* partOf = Reference(sc-geregu-ward)
* position.longitude = 6.6541
* position.latitude = 7.5433
* identifier[gers].system = $GERSId
* identifier[gers].value = "08f2c4d5e6f7a8b9-place-geregu-riverside"
* extension[settlementType].valueCodeableConcept = $SettlementType#rural "Rural"

Instance: sc-dwelling-a12
InstanceOf: ICRLocation
Title: "Scenario — Dwelling, Felele-Central block A house 12"
Usage: #example
* name = "Dwelling — Felele-Central block A, house 12"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#ho "House"
* type = $LocationType#household "Household dwelling"
* partOf = Reference(sc-felele-central)
* position.longitude = 6.7318
* position.latitude = 7.7825
* identifier[gers].system = $GERSId
* identifier[gers].value = "08f2c4d5e6f7a8b9-building-a12"

Instance: sc-dwelling-g07
InstanceOf: ICRLocation
Title: "Scenario — Dwelling, Geregu-Riverside house 7"
Usage: #example
* name = "Dwelling — Geregu-Riverside, house 7"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#ho "House"
* type = $LocationType#household "Household dwelling"
* partOf = Reference(sc-geregu-riverside)
* position.longitude = 6.6544
* position.latitude = 7.5436
* identifier[gers].system = $GERSId
* identifier[gers].value = "08f2c4d5e6f7a8b9-building-g07"

// S16 — one Location, two campaign roles: a school that is also a community
// distribution point. Base Location.type is 0..*, so both codes ride one resource.
Instance: sc-felele-school
InstanceOf: ICRLocation
Title: "Scenario — Felele Model Primary School (school + community distribution point)"
Usage: #example
* name = "Felele Model Primary School"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#bu "Building"
* type[0] = $LocationType#school "School"
* type[1] = $LocationType#community-distribution-point "Community distribution point"
* partOf = Reference(sc-felele-central)
* position.longitude = 6.7309
* position.latitude = 7.7819
* identifier[gers].system = $GERSId
* identifier[gers].value = "08f2c4d5e6f7a8b9-building-felele-school"
* extension[deliveryStrategy].valueCodeableConcept = $DeliveryStrategy#school "School-based"

// --- Supply-chain node Locations (S2, S19) -----------------------------------

Instance: sc-national-store
InstanceOf: ICRLocation
Title: "Scenario — National medical store, Abuja"
Usage: #example
* name = "National Strategic Medical Store, Abuja"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#bu "Building"
* type = $LocationType#facility "Health facility"
* partOf = Reference(sc-nigeria)

Instance: sc-kogi-state-store
InstanceOf: ICRLocation
Title: "Scenario — Kogi State medical store"
Usage: #example
* name = "Kogi State Medical Store, Lokoja"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#bu "Building"
* type = $LocationType#facility "Health facility"
* partOf = Reference(sc-kogi-state)

Instance: sc-lokoja-lga-store
InstanceOf: ICRLocation
Title: "Scenario — Lokoja LGA staging store"
Usage: #example
* name = "Lokoja LGA cold store / campaign staging point"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#bu "Building"
* type = $LocationType#facility "Health facility"
* partOf = Reference(sc-lokoja-lga)

Instance: sc-felele-health-post
InstanceOf: ICRLocation
Title: "Scenario — Felele health post"
Usage: #example
* name = "Felele Ward health post"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#bu "Building"
* type = $LocationType#facility "Health facility"
* partOf = Reference(sc-felele-central)

// --- IRS structures (Satellite A, S9) ----------------------------------------

Instance: sc-structure-g07-main
InstanceOf: ICRLocation
Title: "Scenario — Structure: G07 main building"
Usage: #example
* name = "Geregu-Riverside house 7 — main building (4 rooms)"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#bu "Building"
* partOf = Reference(sc-dwelling-g07)
* identifier[gers].system = $GERSId
* identifier[gers].value = "08f2c4d5e6f7a8b9-building-g07-main"

Instance: sc-structure-g07-kitchen
InstanceOf: ICRLocation
Title: "Scenario — Structure: G07 kitchen outbuilding"
Usage: #example
* name = "Geregu-Riverside house 7 — kitchen outbuilding (1 room)"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#bu "Building"
* partOf = Reference(sc-dwelling-g07)
* identifier[gers].system = $GERSId
* identifier[gers].value = "08f2c4d5e6f7a8b9-building-g07-kitchen"

// =============================================================================
// Cluster 1b — Operational geography: supervisory areas in three configurations
// (S15) and the cross-LGA target footprint (S21)
// =============================================================================

// Config 1: a supervisory area CUTTING ACROSS wards — overlays two wards, neither
// of which it fully contains. partOf is deliberately absent (no single admin parent).
Instance: sc-sa-cross
InstanceOf: ICRLocation
Title: "Scenario — Supervisory area A (cuts across Felele & Adankolo wards)"
Usage: #example
* name = "Lokoja MDA supervision axis A (Felele east + Adankolo north)"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#area "Area"
* type = $LocationType#supervisory-area "Supervisory area"
* extension[overlaysAdminUnit][0].valueReference = Reference(sc-felele-ward)
* extension[overlaysAdminUnit][1].valueReference = Reference(sc-adankolo-ward)

// Config 2: a supervisory area NESTING UNDER a ward — it covers settlements inside
// one ward. overlays-admin-unit points at the settlement (per c72: the extension is
// not target-type-restricted to admin units) — the finer-grained anchor.
Instance: sc-sa-nested
InstanceOf: ICRLocation
Title: "Scenario — Supervisory area B (nests under Felele Ward)"
Usage: #example
* name = "Felele Ward supervision zone B (Felele-Central settlements)"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#area "Area"
* type = $LocationType#supervisory-area "Supervisory area"
* extension[overlaysAdminUnit].valueReference = Reference(sc-felele-central)

// Config 3: a supervisory area GROUPING WHOLE wards — overlays each ward it groups.
Instance: sc-sa-grouping
InstanceOf: ICRLocation
Title: "Scenario — Supervisory area C (groups whole wards)"
Usage: #example
* name = "Kogi MDA supervision cluster C (Felele + Adankolo + Geregu wards)"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#area "Area"
* type = $LocationType#supervisory-area "Supervisory area"
* extension[overlaysAdminUnit][0].valueReference = Reference(sc-felele-ward)
* extension[overlaysAdminUnit][1].valueReference = Reference(sc-adankolo-ward)
* extension[overlaysAdminUnit][2].valueReference = Reference(sc-geregu-ward)

// S21 — the campaign footprint as an operational-area Location: the round targets a
// subset of wards drawn from DIFFERENT LGAs (Felele/Lokoja + Geregu/Ajaokuta). The
// footprint Location exists so the round's denominator can be geography-scoped to
// the exact target set (ICRTargetPopulation.characteristic[geography] is 0..1 and
// can reference only ONE Location).
Instance: sc-target-footprint
InstanceOf: ICRLocation
Title: "Scenario — Kogi 2026 SCH round target footprint (cross-LGA ward subset)"
Usage: #example
* name = "Kogi SCH 2026 round footprint: Felele Ward (Lokoja LGA) + Geregu Ward (Ajaokuta LGA)"
* status = #active
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#area "Area"
* type = $LocationType#operational-area "Operational area"
* extension[overlaysAdminUnit][0].valueReference = Reference(sc-felele-ward)
* extension[overlaysAdminUnit][1].valueReference = Reference(sc-geregu-ward)

// =============================================================================
// Cluster 1c — People and delivery-unit Groups (S1, S10, S12, S14, S18)
// =============================================================================

Instance: sc-amina
InstanceOf: ICRPatient
Title: "Scenario — Amina Bello (child, 9y)"
Usage: #example
* identifier[nationalId].system = $NationalId
* identifier[nationalId].value = "NG-NIN-2017-44120987"
* name.given = "Amina"
* name.family = "Bello"
* gender = #female
* birthDate = "2017-03-04"

Instance: sc-musa-head
InstanceOf: ICRPatient
Title: "Scenario — Musa Bello (head of household A12)"
Usage: #example
* identifier[nationalId].system = $NationalId
* identifier[nationalId].value = "NG-NIN-1985-00341276"
* name.given = "Musa"
* name.family = "Bello"
* gender = #male
* birthDate = "1985-06-11"

Instance: sc-hafsat
InstanceOf: ICRPatient
Title: "Scenario — Hafsat Bello (household A12 member)"
Usage: #example
* identifier[nationalId].system = $NationalId
* identifier[nationalId].value = "NG-NIN-1990-00877154"
* name.given = "Hafsat"
* name.family = "Bello"
* gender = #female
* birthDate = "1990-01-23"

Instance: sc-tunde
InstanceOf: ICRPatient
Title: "Scenario — Tunde Ojo (student, 10y)"
Usage: #example
* identifier[registryId].system = $RegistryId
* identifier[registryId].value = "ICR-KG-2026-000482"
* name.given = "Tunde"
* name.family = "Ojo"
* gender = #male
* birthDate = "2016-05-19"

Instance: sc-zainab
InstanceOf: ICRPatient
Title: "Scenario — Zainab Abubakar (child, household G07)"
Usage: #example
* identifier[registryId].system = $RegistryId
* identifier[registryId].value = "ICR-KG-2026-000731"
* name.given = "Zainab"
* name.family = "Abubakar"
* gender = #female
* birthDate = "2022-09-02"

Instance: sc-baba
InstanceOf: ICRPatient
Title: "Scenario — Baba Abubakar (adult, household G07)"
Usage: #example
* identifier[registryId].system = $RegistryId
* identifier[registryId].value = "ICR-KG-2026-000732"
* name.given = "Baba"
* name.family = "Abubakar"
* gender = #male
* birthDate = "1978-12-30"

// Household A12: fully enumerated household at dwelling A12 (S10 drill-down anchor).
Instance: sc-household-a12
InstanceOf: ICRDeliveryUnit
Title: "Scenario — Household A12 (Bello family)"
Usage: #example
* type = #person
* actual = true
* code = $GroupKind#household "Household"
* quantity = 3
* member[0].entity = Reference(sc-musa-head)
* member[1].entity = Reference(sc-hafsat)
* member[2].entity = Reference(sc-amina)
* extension[groupLocation].valueReference = Reference(sc-dwelling-a12)

Instance: sc-household-g07
InstanceOf: ICRDeliveryUnit
Title: "Scenario — Household G07 (Abubakar family)"
Usage: #example
* type = #person
* actual = true
* code = $GroupKind#household "Household"
* quantity = 2
* member[0].entity = Reference(sc-baba)
* member[1].entity = Reference(sc-zainab)
* extension[groupLocation].valueReference = Reference(sc-dwelling-g07)

// Community delivery units (S12, S14): same profile as the households, different
// group-kind code. The household→community containment is NOT a Group link — it is
// inferred: household's dwelling partOf settlement == community's group-location.
Instance: sc-community-felele
InstanceOf: ICRDeliveryUnit
Title: "Scenario — Felele-Central community"
Usage: #example
* type = #person
* actual = true
* code = $GroupKind#community "Community"
* name = "Felele-Central community"
* quantity = 5200
* extension[groupLocation].valueReference = Reference(sc-felele-central)

Instance: sc-community-geregu
InstanceOf: ICRDeliveryUnit
Title: "Scenario — Geregu-Riverside community"
Usage: #example
* type = #person
* actual = true
* code = $GroupKind#community "Community"
* name = "Geregu-Riverside community"
* quantity = 1400
* extension[groupLocation].valueReference = Reference(sc-geregu-riverside)

// S1 — the school-based delivery unit: enrolled children as a school cohort.
Instance: sc-school-cohort-felele
InstanceOf: ICRDeliveryUnit
Title: "Scenario — Felele Model Primary School cohort"
Usage: #example
* type = #person
* actual = true
* code = $GroupKind#school-cohort "School cohort"
* name = "Felele Model Primary School — enrolled pupils 2025/26"
* quantity = 640
* member[0].entity = Reference(sc-amina)
* member[1].entity = Reference(sc-tunde)
* extension[groupLocation].valueReference = Reference(sc-felele-school)

// =============================================================================
// Cluster 1d — Population estimates
// S6: three sources for Kogi school-aged children, each paired with the SAME
//     source's total-population estimate (sibling Groups, denominator-type axis).
// S8: different sources at different admin levels + the ward→LGA sum-check pair.
// S21: the round denominator scoped to the cross-LGA footprint.
// =============================================================================

// --- S6: Kogi State — census projection (SAC + total) ------------------------

Instance: sc-pop-kogi-sac-censusproj
InstanceOf: ICRTargetPopulation
Title: "Scenario — SAC 5–14, Kogi State (census projection)"
Usage: #example
* type = #person
* actual = false
* name = "School-aged children 5–14, Kogi State — census projection"
* quantity = 118000
* characteristic[geography].code = $GroupCharacteristic#geography "Geographic scope"
* characteristic[geography].valueReference = Reference(sc-kogi-state)
* characteristic[geography].exclude = false
* characteristic[1].code = $GroupCharacteristic#age-band "Age band"
* characteristic[1].valueCodeableConcept.text = "5–14 years"
* characteristic[1].exclude = false
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#census-projection "Census projection"
* extension[denominatorType].valueCode = #at-risk
* extension[estimateDate].valueDate = "2025-12-01"
* extension[isPlanningDenominator].valueBoolean = true

Instance: sc-pop-kogi-total-censusproj
InstanceOf: ICRTargetPopulation
Title: "Scenario — Total population, Kogi State (census projection)"
Usage: #example
* type = #person
* actual = false
* name = "Total population, Kogi State — census projection"
* quantity = 3595000
* characteristic[geography].code = $GroupCharacteristic#geography "Geographic scope"
* characteristic[geography].valueReference = Reference(sc-kogi-state)
* characteristic[geography].exclude = false
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#census-projection "Census projection"
* extension[denominatorType].valueCode = #total-population
* extension[estimateDate].valueDate = "2025-12-01"

// --- S6: Kogi State — GRID3 (SAC + total) ------------------------------------

Instance: sc-pop-kogi-sac-grid3
InstanceOf: ICRTargetPopulation
Title: "Scenario — SAC 5–14, Kogi State (GRID3)"
Usage: #example
* type = #person
* actual = false
* name = "School-aged children 5–14, Kogi State — GRID3 modelled"
* quantity = 126500
* characteristic[geography].code = $GroupCharacteristic#geography "Geographic scope"
* characteristic[geography].valueReference = Reference(sc-kogi-state)
* characteristic[geography].exclude = false
* characteristic[1].code = $GroupCharacteristic#age-band "Age band"
* characteristic[1].valueCodeableConcept.text = "5–14 years"
* characteristic[1].exclude = false
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#grid3 "GRID3 modelled estimate"
* extension[denominatorType].valueCode = #at-risk
* extension[estimateDate].valueDate = "2026-01-20"
* extension[isPlanningDenominator].valueBoolean = false

Instance: sc-pop-kogi-total-grid3
InstanceOf: ICRTargetPopulation
Title: "Scenario — Total population, Kogi State (GRID3)"
Usage: #example
* type = #person
* actual = false
* name = "Total population, Kogi State — GRID3 modelled"
* quantity = 3830000
* characteristic[geography].code = $GroupCharacteristic#geography "Geographic scope"
* characteristic[geography].valueReference = Reference(sc-kogi-state)
* characteristic[geography].exclude = false
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#grid3 "GRID3 modelled estimate"
* extension[denominatorType].valueCode = #total-population
* extension[estimateDate].valueDate = "2026-01-20"

// --- S6: Kogi State — HMIS (SAC + total) -------------------------------------

Instance: sc-pop-kogi-sac-hmis
InstanceOf: ICRTargetPopulation
Title: "Scenario — SAC 5–14, Kogi State (HMIS)"
Usage: #example
* type = #person
* actual = false
* name = "School-aged children 5–14, Kogi State — HMIS-derived"
* quantity = 109000
* characteristic[geography].code = $GroupCharacteristic#geography "Geographic scope"
* characteristic[geography].valueReference = Reference(sc-kogi-state)
* characteristic[geography].exclude = false
* characteristic[1].code = $GroupCharacteristic#age-band "Age band"
* characteristic[1].valueCodeableConcept.text = "5–14 years"
* characteristic[1].exclude = false
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#hmis "HMIS-derived"
* extension[denominatorType].valueCode = #at-risk
* extension[estimateDate].valueDate = "2026-02-10"
* extension[isPlanningDenominator].valueBoolean = false

Instance: sc-pop-kogi-total-hmis
InstanceOf: ICRTargetPopulation
Title: "Scenario — Total population, Kogi State (HMIS)"
Usage: #example
* type = #person
* actual = false
* name = "Total population, Kogi State — HMIS-derived"
* quantity = 3310000
* characteristic[geography].code = $GroupCharacteristic#geography "Geographic scope"
* characteristic[geography].valueReference = Reference(sc-kogi-state)
* characteristic[geography].exclude = false
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#hmis "HMIS-derived"
* extension[denominatorType].valueCode = #total-population
* extension[estimateDate].valueDate = "2026-02-10"

// --- S8: different sources at different levels + ward→LGA sum-check ----------
// State = census projection (above); LGA = GRID3; wards = microcensus.
// Sum-check demo: Felele 9,800 + Adankolo 8,400 = 18,200 vs Lokoja GRID3 19,500
// (−6.7% divergence, visible but only via a query convention).

Instance: sc-pop-lokoja-sac-grid3
InstanceOf: ICRTargetPopulation
Title: "Scenario — SAC 5–14, Lokoja LGA (GRID3)"
Usage: #example
* type = #person
* actual = false
* name = "School-aged children 5–14, Lokoja LGA — GRID3 modelled"
* quantity = 19500
* characteristic[geography].code = $GroupCharacteristic#geography "Geographic scope"
* characteristic[geography].valueReference = Reference(sc-lokoja-lga)
* characteristic[geography].exclude = false
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#grid3 "GRID3 modelled estimate"
* extension[denominatorType].valueCode = #at-risk
* extension[estimateDate].valueDate = "2026-01-20"
* extension[isPlanningDenominator].valueBoolean = true

Instance: sc-pop-felele-sac-micro
InstanceOf: ICRTargetPopulation
Title: "Scenario — SAC 5–14, Felele Ward (microcensus)"
Usage: #example
* type = #person
* actual = false
* name = "School-aged children 5–14, Felele Ward — CDD microcensus"
* quantity = 9800
* characteristic[geography].code = $GroupCharacteristic#geography "Geographic scope"
* characteristic[geography].valueReference = Reference(sc-felele-ward)
* characteristic[geography].exclude = false
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#microcensus "Microcensus / enumeration"
* extension[denominatorType].valueCode = #at-risk
* extension[estimateDate].valueDate = "2026-03-15"
* extension[isPlanningDenominator].valueBoolean = true

Instance: sc-pop-adankolo-sac-micro
InstanceOf: ICRTargetPopulation
Title: "Scenario — SAC 5–14, Adankolo Ward (microcensus)"
Usage: #example
* type = #person
* actual = false
* name = "School-aged children 5–14, Adankolo Ward — CDD microcensus"
* quantity = 8400
* characteristic[geography].code = $GroupCharacteristic#geography "Geographic scope"
* characteristic[geography].valueReference = Reference(sc-adankolo-ward)
* characteristic[geography].exclude = false
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#microcensus "Microcensus / enumeration"
* extension[denominatorType].valueCode = #at-risk
* extension[estimateDate].valueDate = "2026-03-15"
* extension[isPlanningDenominator].valueBoolean = true

// --- S21: the round denominator, scoped to the cross-LGA footprint -----------

Instance: sc-pop-footprint-sac
InstanceOf: ICRTargetPopulation
Title: "Scenario — SAC 5–14, Kogi SCH round footprint (Felele + Geregu wards)"
Usage: #example
* type = #person
* actual = false
* name = "School-aged children 5–14 in the 2026 round footprint (Felele Ward, Lokoja + Geregu Ward, Ajaokuta) — microcensus"
* quantity = 17500
* characteristic[geography].code = $GroupCharacteristic#geography "Geographic scope"
* characteristic[geography].valueReference = Reference(sc-target-footprint)
* characteristic[geography].exclude = false
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#microcensus "Microcensus / enumeration"
* extension[denominatorType].valueCode = #at-risk
* extension[estimateDate].valueDate = "2026-03-15"
* extension[isPlanningDenominator].valueBoolean = true

// --- Satellite denominators (each CarePlan needs a subject) ------------------

Instance: sc-pop-geregu-residents
InstanceOf: ICRTargetPopulation
Title: "Scenario — Residents of Geregu Ward (IRS protected population)"
Usage: #example
* type = #person
* actual = false
* name = "Residents of Geregu Ward — population protected by the IRS round"
* quantity = 21400
* characteristic[geography].code = $GroupCharacteristic#geography "Geographic scope"
* characteristic[geography].valueReference = Reference(sc-geregu-ward)
* characteristic[geography].exclude = false
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#govt-estimate "Government estimate"
* extension[denominatorType].valueCode = #total-population
* extension[isPlanningDenominator].valueBoolean = true

Instance: sc-pop-lokoja-residents
InstanceOf: ICRTargetPopulation
Title: "Scenario — Residents of Lokoja LGA (ITN campaign)"
Usage: #example
* type = #person
* actual = false
* name = "Residents of Lokoja LGA — ITN universal-coverage denominator"
* quantity = 610000
* characteristic[geography].code = $GroupCharacteristic#geography "Geographic scope"
* characteristic[geography].valueReference = Reference(sc-lokoja-lga)
* characteristic[geography].exclude = false
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#census-projection "Census projection"
* extension[denominatorType].valueCode = #total-population
* extension[isPlanningDenominator].valueBoolean = true

Instance: sc-pop-kogi-mr-children
InstanceOf: ICRTargetPopulation
Title: "Scenario — Children 9m–14y, Kogi State (MR SIA)"
Usage: #example
* type = #person
* actual = false
* name = "Children 9 months–14 years, Kogi State — MR SIA planning denominator"
* quantity = 1290000
* characteristic[geography].code = $GroupCharacteristic#geography "Geographic scope"
* characteristic[geography].valueReference = Reference(sc-kogi-state)
* characteristic[geography].exclude = false
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#census-projection "Census projection"
* extension[denominatorType].valueCode = #at-risk
* extension[isPlanningDenominator].valueBoolean = true

Instance: sc-pop-nigeria-sac
InstanceOf: ICRTargetPopulation
Title: "Scenario — SAC 5–14, Nigeria (umbrella denominator)"
Usage: #example
* type = #person
* actual = false
* name = "School-aged children 5–14, Nigeria — national SCH/STH umbrella denominator"
* quantity = 41200000
* characteristic[geography].code = $GroupCharacteristic#geography "Geographic scope"
* characteristic[geography].valueReference = Reference(sc-nigeria)
* characteristic[geography].exclude = false
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#census-projection "Census projection"
* extension[denominatorType].valueCode = #at-risk
* extension[isPlanningDenominator].valueBoolean = true

Instance: sc-pop-nigeria-2plus
InstanceOf: ICRTargetPopulation
Title: "Scenario — Population 2y+, Nigeria (protocol-standard umbrella denominator)"
Usage: #example
* type = #person
* actual = false
* name = "Entire population 2 years and older, Nigeria — the protocol-standard SCH target"
* quantity = 195000000
* characteristic[geography].code = $GroupCharacteristic#geography "Geographic scope"
* characteristic[geography].valueReference = Reference(sc-nigeria)
* characteristic[geography].exclude = false
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#census-projection "Census projection"
* extension[denominatorType].valueCode = #at-risk
* extension[isPlanningDenominator].valueBoolean = true

// =============================================================================
// Cluster 2 — Campaign architecture (S2, S4, S5, S21) + team
// =============================================================================

// The SOP: national SCH policy treats EVERYONE 2 years and older (S4 baseline).
Instance: sc-sch-protocol
InstanceOf: ICRCampaignProtocol
Title: "Scenario — Nigeria SCH MDA protocol (praziquantel, everyone 2y+)"
Usage: #example
* status = #active
* version = "2.0.0"
* title = "Schistosomiasis MDA (praziquantel) — national policy: entire population 2 years and older"
* type = $CampaignType#mda "Mass drug administration (NTD preventive chemotherapy)"
* subjectCodeableConcept.text = "Entire population 2 years and older (national SCH policy)"
* goal.description.text = "≥75% epidemiological coverage of the eligible population in every endemic LGA"
* action[0].title = "Administer praziquantel (dose-pole banded)"
* action[0].definitionCanonical = Canonical(sc-pzq-activity)
* action[1].title = "Position drug stock at LGA staging stores"
* action[1].definitionCanonical = Canonical(sc-logistics-activity)
* extension[deliveryStrategy][0].valueCodeableConcept = $DeliveryStrategy#community-directed "Community-directed distribution"
* extension[deliveryStrategy][1].valueCodeableConcept = $DeliveryStrategy#school "School-based"

Instance: sc-pzq-activity
InstanceOf: ICRCampaignActivity
Title: "Scenario — Administer praziquantel (MDA activity)"
Usage: #example
* status = #active
* kind = #Task
* title = "Administer praziquantel, dose-pole banded"
* code.text = "Treat"
* productCodeableConcept = $ATC#P02BA01 "praziquantel"
* dosage.text = "40 mg/kg equivalent via dose-pole height band; tablet count per band"

// S2 — a SUPPORTING activity, not an intervention: moving drugs to the district
// staging location. The activity `code` is unbound, so the logistics work type is
// definable; the friction appears on its Tasks (see sc-task-logistics-leg).
Instance: sc-logistics-activity
InstanceOf: ICRCampaignActivity
Title: "Scenario — Deliver drugs to district staging location (supporting activity)"
Usage: #example
* status = #active
* kind = #Task
* title = "Deliver praziquantel from state store to LGA staging stores"
* code.text = "Deliver drugs to district staging location"

Instance: sc-irs-spray-activity
InstanceOf: ICRCampaignActivity
Title: "Scenario — Spray structure (IRS activity)"
Usage: #example
* status = #active
* kind = #Task
* title = "Spray interior walls of eligible structures"
* code.text = "Spray"
* productCodeableConcept.text = "Pirimiphos-methyl 300CS"
* dosage.text = "Units per eligible structure: 1 sachet per 250 m² sprayable surface (typically 1–2 sachets per structure)"

// The national umbrella (intent=plan) and the Kogi round (intent=order).
Instance: sc-mda-umbrella
InstanceOf: ICRCampaign
Title: "Scenario — Nigeria SCH MDA 2026 (national umbrella)"
Usage: #example
* instantiatesCanonical = Canonical(sc-sch-protocol)
* status = #active
* intent = #plan
* title = "Nigeria schistosomiasis MDA, 2026 — national umbrella campaign"
* category = $CampaignType#mda "Mass drug administration (NTD preventive chemotherapy)"
* subject = Reference(sc-pop-nigeria-2plus)
* period.start = "2026-05-01"
* period.end = "2026-12-15"
* extension[planningDenominator].valueReference = Reference(sc-pop-nigeria-2plus)

// S4 — the DEVIATION: the protocol targets everyone 2y+, but this round's PZQ stock
// expires in August and covers only school-aged children, so the round's subject is
// the narrower SAC denominator. The deviation is visible by comparing round.subject
// against the protocol's subject template; the REASON lives only in free text (note).
// S21 — targetGeography lists wards from two DIFFERENT LGAs directly.
Instance: sc-kogi-round
InstanceOf: ICRCampaign
Title: "Scenario — Kogi SCH round, June 2026 (descoped to SAC; cross-LGA ward subset)"
Usage: #example
* instantiatesCanonical = Canonical(sc-sch-protocol)
* status = #active
* intent = #order
* title = "Kogi SCH MDA round, June 2026 — school-aged children only (expiring PZQ stock); Felele + Geregu wards"
* category = $CampaignType#mda "Mass drug administration (NTD preventive chemotherapy)"
* subject = Reference(sc-pop-footprint-sac)
* period.start = "2026-06-01"
* period.end = "2026-06-12"
* partOf = Reference(sc-mda-umbrella)
* note.text = "Round deviates from protocol: praziquantel lot PZQ-NG-2025-771 expires 2026-08-31 and quantity covers only school-aged children; state programme descoped this round to SAC 5–14 in the two highest-prevalence wards."
* extension[campaignRound].valuePositiveInt = 1
* extension[targetGeography][0].valueReference = Reference(sc-felele-ward)
* extension[targetGeography][1].valueReference = Reference(sc-geregu-ward)
* extension[planningDenominator].valueReference = Reference(sc-pop-footprint-sac)
* extension[dataLineage].valueCode = #realtime
* activity[0].reference = Reference(sc-task-school-session)
* activity[1].reference = Reference(sc-task-community-felele)
* activity[2].reference = Reference(sc-task-household-a12)
* activity[3].reference = Reference(sc-task-logistics-leg)
* activity[4].reference = Reference(sc-task-settlement-sweep)
* activity[5].reference = Reference(sc-task-ward-mobilization)

Instance: sc-cdd-team-felele
InstanceOf: ICRCareTeam
Title: "Scenario — CDD team, Felele Ward"
Usage: #example
* status = #active
* name = "Felele CDD team 3"
* subject = Reference(sc-pop-felele-sac-micro)
* participant[0].role = $TeamRole#cdd "Community drug distributor (CDD)"
* participant[0].member.display = "Mariam Adamu (CDD)"
* participant[1].role = $TeamRole#supervisor "Supervisor"
* participant[1].member.display = "Emeka Okafor (LGA NTD supervisor)"
* managingOrganization.display = "Lokoja LGA Health Department"
* extension[overseesArea].valueReference = Reference(sc-sa-cross)
* extension[workloadTarget].extension[targetArea].valueReference = Reference(sc-felele-ward)
* extension[workloadTarget].extension[targetPopulation].valueUnsignedInt = 9800
* extension[workloadTarget].extension[targetDays].valueUnsignedInt = 10

// --- Satellite campaign shells ------------------------------------------------

Instance: sc-irs-protocol
InstanceOf: ICRCampaignProtocol
Title: "Scenario — Kogi IRS protocol"
Usage: #example
* status = #active
* version = "1.0.0"
* title = "Indoor residual spraying ahead of malaria transmission season"
* type = $CampaignType#irs "Indoor residual spraying"
* action.title = "Spray eligible structures"
* action.definitionCanonical = Canonical(sc-irs-spray-activity)
* extension[deliveryStrategy].valueCodeableConcept = $DeliveryStrategy#house-to-house "House-to-house"

Instance: sc-irs-round
InstanceOf: ICRCampaign
Title: "Scenario — Geregu Ward IRS round, April 2026"
Usage: #example
* instantiatesCanonical = Canonical(sc-irs-protocol)
* status = #completed
* intent = #order
* title = "Geregu Ward IRS round, April 2026"
* category = $CampaignType#irs "Indoor residual spraying"
* subject = Reference(sc-pop-geregu-residents)
* period.start = "2026-04-06"
* period.end = "2026-04-24"
* extension[targetGeography].valueReference = Reference(sc-geregu-ward)
* activity[0].reference = Reference(sc-task-spray-main)
* activity[1].reference = Reference(sc-task-spray-kitchen)

Instance: sc-itn-protocol
InstanceOf: ICRCampaignProtocol
Title: "Scenario — Kogi ITN mass distribution protocol"
Usage: #example
* status = #active
* version = "1.0.0"
* title = "ITN universal-coverage mass distribution (1 net per 2 people)"
* type = $CampaignType#itn-distribution "ITN mass distribution"
* extension[deliveryStrategy][0].valueCodeableConcept = $DeliveryStrategy#house-to-house "House-to-house"
* extension[deliveryStrategy][1].valueCodeableConcept = $DeliveryStrategy#fixed-post "Fixed post"

Instance: sc-itn-round
InstanceOf: ICRCampaign
Title: "Scenario — Lokoja LGA ITN distribution, October 2026"
Usage: #example
* instantiatesCanonical = Canonical(sc-itn-protocol)
* status = #active
* intent = #order
* title = "Lokoja LGA ITN mass distribution, October 2026"
* category = $CampaignType#itn-distribution "ITN mass distribution"
* subject = Reference(sc-pop-lokoja-residents)
* period.start = "2026-10-05"
* period.end = "2026-10-16"
* extension[targetGeography].valueReference = Reference(sc-lokoja-lga)

Instance: sc-mr-protocol
InstanceOf: ICRCampaignProtocol
Title: "Scenario — Measles-Rubella SIA protocol (Kogi)"
Usage: #example
* status = #active
* version = "1.0.0"
* title = "Measles–rubella SIA, 9 months–14 years"
* type = $CampaignType#vaccination-sia "Vaccination campaign (SIA)"
* extension[deliveryStrategy][0].valueCodeableConcept = $DeliveryStrategy#fixed-post "Fixed post"
* extension[deliveryStrategy][1].valueCodeableConcept = $DeliveryStrategy#house-to-house "House-to-house"

Instance: sc-mr-round
InstanceOf: ICRCampaign
Title: "Scenario — Kogi MR SIA round, November 2026"
Usage: #example
* instantiatesCanonical = Canonical(sc-mr-protocol)
* status = #active
* intent = #order
* title = "Kogi State measles–rubella SIA, November 2026"
* category = $CampaignType#vaccination-sia "Vaccination campaign (SIA)"
* subject = Reference(sc-pop-kogi-mr-children)
* period.start = "2026-11-09"
* period.end = "2026-11-20"
* extension[targetGeography].valueReference = Reference(sc-kogi-state)
* activity[0].reference = Reference(sc-task-mr-house-visit)

// =============================================================================
// Cluster 3 — Tasks (S1, S2, S5, S9, S11, S13) and delivery events
// (S3, S17, S18). NOTE ON focus/for: the compiled FSH profile constrains
// Task.focus (1..1, DeliveryUnit|Location|Patient) as the TARGET slot and leaves
// Task.for unconstrained; the prose doc (§4.4, v0.28.1) documents the OPPOSITE
// (for = target 1..1, focus = workflow lineage). Instances follow the FSH.
// Both fields are populated so the divergence is visible in the data.
// =============================================================================

// S1 — school-based SCH distribution: a Type-A site session at the school, with
// the enrolled cohort Group as the unit acted on.
Instance: sc-task-school-session
InstanceOf: ICRCampaignTask
Title: "Scenario — School session, Felele Model Primary (SCH MDA day 2)"
Usage: #example
* status = #completed
* intent = #order
* code.text = "School-based praziquantel session"
* focus = Reference(sc-school-cohort-felele)
* for = Reference(sc-school-cohort-felele)
* owner = Reference(sc-cdd-team-felele)
* location = Reference(sc-felele-school)
* executionPeriod.start = "2026-06-02T08:30:00+01:00"
* executionPeriod.end = "2026-06-02T14:00:00+01:00"
* extension[deliveryStrategy].valueCodeableConcept = $DeliveryStrategy#school "School-based"
* extension[taskOrigin].valueCode = #pre-planned
* extension[dataLineage].valueCode = #realtime
* extension[exclusionReason].valueCodeableConcept = $ExclusionReason#under-height-age "Below dose-pole minimum (height/age)"
* output[0].type.text = "Pupils treated (session tally)"
* output[0].valueUnsignedInt = 402
* output[1].type.text = "Treatment event (person-level)"
* output[1].valueReference = Reference(sc-pzq-tunde)

// S2 — the logistics leg as a Task. The activity code is free, but the profile
// REQUIRES delivery-strategy 1..1 from a value set of population-facing delivery
// modes — none of which describes a stock movement. #mobile is used under protest;
// this forced mislabel is the S2 finding.
Instance: sc-task-logistics-leg
InstanceOf: ICRCampaignTask
Title: "Scenario — Deliver PZQ to Lokoja LGA staging store"
Usage: #example
* status = #completed
* intent = #order
* code.text = "Deliver drugs to district staging location"
* focus = Reference(sc-lokoja-lga-store)
* for = Reference(sc-kogi-round)
* location = Reference(sc-lokoja-lga-store)
* executionPeriod.start = "2026-05-27"
* executionPeriod.end = "2026-05-27"
* extension[deliveryStrategy].valueCodeableConcept = $DeliveryStrategy#mobile "Mobile team"
* extension[taskOrigin].valueCode = #pre-planned
* output.type.text = "Stock receipt at staging store"
* output.valueReference = Reference(sc-supply-state-to-lokoja)

// S13 — one distributor, BOTH counts: people treated (treatment home) and tablets
// dispensed (stock home), on their two respective resources off one Task.
// S7 — this Task is the real-time stream (same-day CDD phone submission).
Instance: sc-task-community-felele
InstanceOf: ICRCampaignTask
Title: "Scenario — Community-directed MDA, Felele-Central"
Usage: #example
* status = #completed
* intent = #order
* code.text = "Community-directed praziquantel distribution"
* reasonCode.text = "Schistosomiasis"
* focus = Reference(sc-community-felele)
* for = Reference(sc-community-felele)
* owner = Reference(sc-cdd-team-felele)
* location = Reference(sc-felele-central)
* executionPeriod.start = "2026-06-03"
* executionPeriod.end = "2026-06-06"
* extension[deliveryStrategy].valueCodeableConcept = $DeliveryStrategy#community-directed "Community-directed distribution"
* extension[taskOrigin].valueCode = #pre-planned
* extension[dataLineage].valueCode = #realtime
* extension[noncomplianceReason].valueCodeableConcept = $NoncomplianceReason#no-felt-need "No felt need"
* output[0].type.text = "Persons treated (people count → treatment home)"
* output[0].valueUnsignedInt = 312
* output[1].type.text = "Register-level treatment event"
* output[1].valueReference = Reference(sc-medadmin-community-felele)
* output[2].type.text = "Tablets dispensed (stock count → stock-accountability home)"
* output[2].valueReference = Reference(sc-supply-post-to-cdd)
* output[3].type.text = "Disaggregated treatment tally"
* output[3].valueReference = Reference(sc-tally-felele)

// S10 — the household visit that treats Amina; S7 — reconciled lineage (this record
// was corrected at close-out after the paper register was reconciled).
Instance: sc-task-household-a12
InstanceOf: ICRCampaignTask
Title: "Scenario — Household visit, Felele-Central A12"
Usage: #example
* status = #completed
* intent = #order
* code.text = "House-to-house praziquantel visit (register catch-up)"
* focus = Reference(sc-household-a12)
* for = Reference(sc-household-a12)
* owner = Reference(sc-cdd-team-felele)
* location = Reference(sc-dwelling-a12)
* executionPeriod.start = "2026-06-05T10:00:00+01:00"
* executionPeriod.end = "2026-06-05T10:20:00+01:00"
* extension[deliveryStrategy].valueCodeableConcept = $DeliveryStrategy#house-to-house "House-to-house"
* extension[taskOrigin].valueCode = #field-registered
* extension[dataLineage].valueCode = #reconciled
* extension[eligiblePresent].valueUnsignedInt = 1
* output.type.text = "Treatment event (person-level)"
* output.valueReference = Reference(sc-pzq-amina)

// S11 — Task targeting a SETTLEMENT-level Location.
Instance: sc-task-settlement-sweep
InstanceOf: ICRCampaignTask
Title: "Scenario — Settlement mop-up sweep, Geregu-Riverside"
Usage: #example
* status = #completed
* intent = #order
* code.text = "Settlement-level mop-up sweep (absentees from register days)"
* focus = Reference(sc-geregu-riverside)
* for = Reference(sc-geregu-riverside)
* owner = Reference(sc-cdd-team-felele)
* location = Reference(sc-geregu-riverside)
* executionPeriod.start = "2026-06-09"
* executionPeriod.end = "2026-06-10"
* extension[deliveryStrategy].valueCodeableConcept = $DeliveryStrategy#house-to-house "House-to-house"
* extension[taskOrigin].valueCode = #pre-planned
* extension[housesVisited].valueUnsignedInt = 61
* output.type.text = "Persons treated on sweep"
* output.valueUnsignedInt = 44

// S11 — Task targeting a WARD-level Location. A ward has no delivery strategy of
// its own; #community-directed is the least-wrong required code (same friction
// family as S2).
Instance: sc-task-ward-mobilization
InstanceOf: ICRCampaignTask
Title: "Scenario — Ward-level pre-round mobilization, Felele Ward"
Usage: #example
* status = #completed
* intent = #order
* code.text = "Ward-wide social mobilization ahead of the SCH round"
* focus = Reference(sc-felele-ward)
* for = Reference(sc-felele-ward)
* owner = Reference(sc-cdd-team-felele)
* location = Reference(sc-felele-ward)
* executionPeriod.start = "2026-05-25"
* executionPeriod.end = "2026-05-31"
* extension[deliveryStrategy].valueCodeableConcept = $DeliveryStrategy#community-directed "Community-directed distribution"
* extension[taskOrigin].valueCode = #pre-planned
* extension[SocialMobilization].extension[populationInformed].valueBoolean = true
* extension[SocialMobilization].extension[channel][0].valueCodeableConcept = $CommunicationChannel#town-criers "Town criers"
* extension[SocialMobilization].extension[channel][1].valueCodeableConcept = $CommunicationChannel#schools "Schools"

// S9 — IRS: the Task IS the event; per-house insecticide quantity rides Task.output.
Instance: sc-task-spray-main
InstanceOf: ICRCampaignTask
Title: "Scenario — Spray structure G07 main building"
Usage: #example
* status = #completed
* intent = #order
* code.text = "Spray structure (IRS)"
* focus = Reference(sc-structure-g07-main)
* for = Reference(sc-household-g07)
* location = Reference(sc-structure-g07-main)
* executionPeriod.start = "2026-04-08T09:10:00+01:00"
* executionPeriod.end = "2026-04-08T09:55:00+01:00"
* extension[deliveryStrategy].valueCodeableConcept = $DeliveryStrategy#house-to-house "House-to-house"
* extension[taskOrigin].valueCode = #pre-planned
* output[0].type.text = "Structure spray status"
* output[0].valueCodeableConcept.text = "sprayed"
* output[1].type.text = "Insecticide used"
* output[1].valueQuantity = 2 '{sachet}' "sachets"
* output[2].type.text = "Rooms sprayed"
* output[2].valueUnsignedInt = 4

Instance: sc-task-spray-kitchen
InstanceOf: ICRCampaignTask
Title: "Scenario — Spray structure G07 kitchen outbuilding"
Usage: #example
* status = #completed
* intent = #order
* code.text = "Spray structure (IRS)"
* focus = Reference(sc-structure-g07-kitchen)
* for = Reference(sc-household-g07)
* location = Reference(sc-structure-g07-kitchen)
* executionPeriod.start = "2026-04-08T10:00:00+01:00"
* executionPeriod.end = "2026-04-08T10:15:00+01:00"
* extension[deliveryStrategy].valueCodeableConcept = $DeliveryStrategy#house-to-house "House-to-house"
* extension[taskOrigin].valueCode = #field-registered
* output[0].type.text = "Structure spray status"
* output[0].valueCodeableConcept.text = "sprayed"
* output[1].type.text = "Insecticide used"
* output[1].valueQuantity = 1 '{sachet}' "sachets"
* output[2].type.text = "Rooms sprayed"
* output[2].valueUnsignedInt = 1

// S3 — the MR SIA house visit where the caregiver refuses: visit-level refusal
// reason on the Task (the IG's mainline mechanism).
Instance: sc-task-mr-house-visit
InstanceOf: ICRCampaignTask
Title: "Scenario — MR SIA house-to-house visit, household G07"
Usage: #example
* status = #completed
* intent = #order
* code.text = "House-to-house MR vaccination visit"
* focus = Reference(sc-household-g07)
* for = Reference(sc-household-g07)
* location = Reference(sc-dwelling-g07)
* executionPeriod.start = "2026-11-12T11:00:00+01:00"
* executionPeriod.end = "2026-11-12T11:10:00+01:00"
* extension[deliveryStrategy].valueCodeableConcept = $DeliveryStrategy#house-to-house "House-to-house"
* extension[taskOrigin].valueCode = #pre-planned
* extension[eligiblePresent].valueUnsignedInt = 1
* extension[noncomplianceReason].valueCodeableConcept = $NoncomplianceReason#safety-concern "Safety concern / fear of adverse events"
* output.type.text = "Refusal record (person-level, not-done)"
* output.valueReference = Reference(sc-mcv-refusal)

// --- Delivery events ----------------------------------------------------------

// S10 — Amina's treatment: the person-level anchor of the drill-down chain.
Instance: sc-pzq-amina
InstanceOf: ICRMedicationAdministration
Title: "Scenario — Praziquantel to Amina Bello (household visit)"
Usage: #example
* status = #completed
* medicationCodeableConcept = $ATC#P02BA01 "praziquantel"
* subject = Reference(sc-amina)
* effectiveDateTime = "2026-06-05T10:12:00+01:00"
* dosage.text = "3 tablets (600 mg × 3), dose-pole band C"
* dosage.dose = 1800 'mg' "mg"
* extension[recordOrigin].valueCode = #campaign
* extension[directlyObserved].valueBoolean = true
* extension[dosePoleBand].valueCodeableConcept.text = "Band C (125–137 cm → 3 tablets)"

// S1 — the dose to a student during the school session.
Instance: sc-pzq-tunde
InstanceOf: ICRMedicationAdministration
Title: "Scenario — Praziquantel to Tunde Ojo (school session)"
Usage: #example
* status = #completed
* medicationCodeableConcept = $ATC#P02BA01 "praziquantel"
* subject = Reference(sc-tunde)
* effectiveDateTime = "2026-06-02T09:40:00+01:00"
* dosage.text = "3 tablets, dose-pole band C"
* dosage.dose = 1800 'mg' "mg"
* extension[recordOrigin].valueCode = #campaign
* extension[directlyObserved].valueBoolean = true
* extension[dosePoleBand].valueCodeableConcept.text = "Band C (125–137 cm → 3 tablets)"

// S18 — the register-level Group-subject administration. directlyObserved=true here
// can only mean "the DOC protocol was applied to this administration" — it cannot
// say WHO swallowed. The partial-observation numbers live in the tally's strata.
Instance: sc-medadmin-community-felele
InstanceOf: ICRMedicationAdministration
Title: "Scenario — Praziquantel, Felele-Central community (register-level)"
Usage: #example
* status = #completed
* medicationCodeableConcept = $ATC#P02BA01 "praziquantel"
* subject = Reference(sc-community-felele)
* effectivePeriod.start = "2026-06-03"
* effectivePeriod.end = "2026-06-06"
* dosage.text = "Dose-pole banded; 650 tablets dispensed across 312 persons"
// mad-1 requires dosage.dose; on a Group-subject administration the only coherent
// value is the TOTAL dispensed — per-person dose varies by dose-pole band and is
// unrecoverable from this record (S18 semantic blur, see validation report).
* dosage.dose = 650 '{tbl}' "tablets"
* extension[recordOrigin].valueCode = #campaign
* extension[directlyObserved].valueBoolean = true

// S18 — the person-level contrast: Kemi received tablets but was NOT observed to
// swallow and spat them out; recorded as status=not-done with a reason.
Instance: sc-kemi
InstanceOf: ICRPatient
Title: "Scenario — Kemi Adewale (child, Felele-Central)"
Usage: #example
* identifier[registryId].system = $RegistryId
* identifier[registryId].value = "ICR-KG-2026-000915"
* name.given = "Kemi"
* name.family = "Adewale"
* gender = #female
* birthDate = "2018-08-14"

Instance: sc-pzq-kemi-notdone
InstanceOf: ICRMedicationAdministration
Title: "Scenario — Praziquantel NOT taken — Kemi Adewale (not observed to swallow)"
Usage: #example
* status = #not-done
* statusReason.text = "Tablets dispensed but child spat them out; consumption not completed under observation"
* medicationCodeableConcept = $ATC#P02BA01 "praziquantel"
* subject = Reference(sc-kemi)
* effectiveDateTime = "2026-06-04"
* extension[recordOrigin].valueCode = #campaign
* extension[directlyObserved].valueBoolean = false

// S17 — vaccine dose carrying lotNumber AND expirationDate side by side.
Instance: sc-mcv-dose-ok
InstanceOf: ICRImmunizationEvent
Title: "Scenario — MR dose to Tunde Ojo (lot + expiry)"
Usage: #example
* status = #completed
* vaccineCode = $CVX#04 "measles and rubella virus vaccine"
* patient = Reference(sc-tunde)
* occurrenceDateTime = "2026-11-10T10:05:00+01:00"
* location = Reference(sc-felele-school)
* lotNumber = "MR-KJ-2026-118"
* expirationDate = "2027-03-31"
* manufacturer.display = "Serum Institute of India"
* performer.actor.display = "Kogi MR SIA team 12"
* protocolApplied.doseNumberPositiveInt = 1
* extension[recordOrigin].valueCode = #campaign
* extension[priorDoseStatus].valueCode = #previously-received

// S3 — the refusal, person-level: Immunization status=not-done + statusReason,
// carrying the refusal reason "concerned about negative side effects".
Instance: sc-mcv-refusal
InstanceOf: ICRImmunizationEvent
Title: "Scenario — MR vaccination REFUSED — Zainab Abubakar"
Usage: #example
* status = #not-done
* statusReason = $NoncomplianceReason#safety-concern "Safety concern / fear of adverse events"
* statusReason.text = "Caregiver concerned about negative side effects"
* vaccineCode = $CVX#04 "measles and rubella virus vaccine"
* patient = Reference(sc-zainab)
* occurrenceDateTime = "2026-11-12T11:05:00+01:00"
* location = Reference(sc-dwelling-g07)
* extension[recordOrigin].valueCode = #campaign

// =============================================================================
// Cluster 4 — Supply chain (S2, S19, Satellite B) and coverage (S5, S7, S8, S13, S18)
// =============================================================================

// S19 leg 1 — national store → state store (upstream custody transfer).
Instance: sc-supply-national-to-state
InstanceOf: ICRSupplyDelivery
Title: "Scenario — PZQ transfer: national store → Kogi state store"
Usage: #example
* status = #completed
* suppliedItem.quantity = 600000 '{tbl}' "tablets"
* suppliedItem.itemCodeableConcept = $ATC#P02BA01 "praziquantel"
* occurrenceDateTime = "2026-05-15"
* supplier.display = "National Strategic Medical Store, Abuja"
* destination = Reference(sc-kogi-state-store)
* extension[recordOrigin].valueCode = #campaign

// S19 leg 2 / S2 — state store → LGA staging store. Stock-accountability here is
// the RECEIVING node's ledger. Note the ledger identity received = used + remaining
// + notUsable + returned does NOT balance at a mid-chain node: 120,000 received but
// 102,000 went onward as separate SupplyDeliveries, for which the extension has no
// field. 0 + 13,000 + 1,000 + 4,000 = 18,000 ≠ 120,000.
Instance: sc-supply-state-to-lokoja
InstanceOf: ICRSupplyDelivery
Title: "Scenario — PZQ transfer: Kogi state store → Lokoja LGA staging"
Usage: #example
* status = #completed
* suppliedItem.quantity = 120000 '{tbl}' "tablets"
* suppliedItem.itemCodeableConcept = $ATC#P02BA01 "praziquantel"
* occurrenceDateTime = "2026-05-27"
* supplier.display = "Kogi State Medical Store"
* destination = Reference(sc-lokoja-lga-store)
* extension[recordOrigin].valueCode = #campaign
* extension[stockAccountability].extension[received].valueQuantity = 120000 '{tbl}' "tablets"
* extension[stockAccountability].extension[used].valueQuantity = 0 '{tbl}' "tablets"
* extension[stockAccountability].extension[remaining].valueQuantity = 13000 '{tbl}' "tablets"
* extension[stockAccountability].extension[notUsable].valueQuantity = 1000 '{tbl}' "tablets"
* extension[stockAccountability].extension[returned].valueQuantity = 4000 '{tbl}' "tablets"
* extension[stockAccountability].extension[concordant].valueBoolean = false

// S19 leg 3 — LGA staging → ward health post (onward issue, its own SupplyDelivery).
Instance: sc-supply-lokoja-to-post
InstanceOf: ICRSupplyDelivery
Title: "Scenario — PZQ transfer: Lokoja staging → Felele health post"
Usage: #example
* status = #completed
* suppliedItem.quantity = 24000 '{tbl}' "tablets"
* suppliedItem.itemCodeableConcept = $ATC#P02BA01 "praziquantel"
* occurrenceDateTime = "2026-05-30"
* supplier.display = "Lokoja LGA cold store / campaign staging point"
* destination = Reference(sc-felele-health-post)
* extension[recordOrigin].valueCode = #campaign

// S19 leg 4 — health post → CDD. The receiving party is a PERSON, not a place:
// destination (Location-only) cannot name the CDD; receiver carries her.
// This node's ledger DOES balance: 800 = 650 used + 140 remaining + 10 notUsable.
Instance: sc-supply-post-to-cdd
InstanceOf: ICRSupplyDelivery
Title: "Scenario — PZQ issue: Felele post → CDD Mariam Adamu"
Usage: #example
* status = #completed
* suppliedItem.quantity = 800 '{tbl}' "tablets"
* suppliedItem.itemCodeableConcept = $ATC#P02BA01 "praziquantel"
* occurrenceDateTime = "2026-06-02"
* supplier.display = "Felele Ward health post"
* destination = Reference(sc-felele-central)
* receiver.display = "Mariam Adamu (CDD, Felele CDD team 3)"
* extension[recordOrigin].valueCode = #campaign
* extension[stockAccountability].extension[received].valueQuantity = 800 '{tbl}' "tablets"
* extension[stockAccountability].extension[used].valueQuantity = 650 '{tbl}' "tablets"
* extension[stockAccountability].extension[remaining].valueQuantity = 140 '{tbl}' "tablets"
* extension[stockAccountability].extension[notUsable].valueQuantity = 10 '{tbl}' "tablets"
* extension[stockAccountability].extension[concordant].valueBoolean = true

// S19 leg 5 — the return leg back UP the chain (near-expiry stock sent back).
Instance: sc-supply-return-to-state
InstanceOf: ICRSupplyDelivery
Title: "Scenario — PZQ return: Lokoja staging → Kogi state store (near-expiry)"
Usage: #example
* status = #completed
* suppliedItem.quantity = 4000 '{tbl}' "tablets"
* suppliedItem.itemCodeableConcept = $ATC#P02BA01 "praziquantel"
* occurrenceDateTime = "2026-06-14"
* supplier.display = "Lokoja LGA cold store / campaign staging point"
* destination = Reference(sc-kogi-state-store)
* extension[recordOrigin].valueCode = #campaign

// Satellite B / S19 — the ITN pair: an upstream transfer and a last-mile handover
// share one resource type, distinguished only by the destination's level.
Instance: sc-itn-post-delivery
InstanceOf: ICRSupplyDelivery
Title: "Scenario — ITN transfer: LGA store → Felele health post (upstream)"
Usage: #example
* status = #completed
* suppliedItem.quantity = 5000 '{Net}' "nets"
* suppliedItem.itemCodeableConcept.text = "LLIN — long-lasting insecticidal net"
* occurrenceDateTime = "2026-10-02"
* supplier.display = "Lokoja LGA cold store / campaign staging point"
* destination = Reference(sc-felele-health-post)
* extension[recordOrigin].valueCode = #campaign

Instance: sc-itn-household-handover
InstanceOf: ICRSupplyDelivery
Title: "Scenario — ITN handover to household A12 (last-mile service delivery)"
Usage: #example
* status = #completed
* suppliedItem.quantity = 2 '{Net}' "nets"
* suppliedItem.itemCodeableConcept.text = "LLIN — long-lasting insecticidal net"
* occurrenceDateTime = "2026-10-08"
* supplier.display = "ITN distribution team 5, Felele post"
* destination = Reference(sc-dwelling-a12)
* extension[recordOrigin].valueCode = #campaign

// --- Coverage (S5, S7, S8, S13, S18) -----------------------------------------

// S7 — the REAL-TIME stream: campaign-night figure from the CDD phone submissions,
// before cleaning. Feeds the dashboard.
Instance: sc-cov-round-realtime
InstanceOf: ICRAdministrativeCoverage
Title: "Scenario — Kogi SCH round coverage (real-time, campaign night)"
Usage: #example
* status = #complete
* type = #summary
* measure = "https://icr.healthcampaigns.org/Measure/icr-mda-treatment-coverage"
* period.start = "2026-06-01"
* period.end = "2026-06-06"
* reporter.display = "Kogi State NTD coordinator"
* group.population[0].code = $MeasurePopulation#numerator "Numerator"
* group.population[0].count = 15900
* group.population[1].code = $MeasurePopulation#denominator "Denominator"
* group.population[1].count = 17500
* group.measureScore.value = 0.91
// The referenced Measure declares sex/age-band/disposition stratifiers, and the
// HL7 validator REQUIRES a report to include every declared stratifier — even this
// campaign-night quick figure (see validation report, cross-cutting finding).
* group.stratifier[0].code = $CoverageStratifier#sex "Sex"
* group.stratifier[0].stratum[0].value.text = "female"
* group.stratifier[0].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[0].stratum[0].population[0].count = 8100
* group.stratifier[0].stratum[1].value.text = "male"
* group.stratifier[0].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[0].stratum[1].population[0].count = 7800
* group.stratifier[1].code = $CoverageStratifier#age-band "Age band"
* group.stratifier[1].stratum[0].value.text = "5–9 years"
* group.stratifier[1].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[1].stratum[0].population[0].count = 8900
* group.stratifier[1].stratum[1].value.text = "10–14 years"
* group.stratifier[1].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[1].stratum[1].population[0].count = 7000
* group.stratifier[2].code = $CoverageStratifier#disposition "Disposition"
* group.stratifier[2].stratum[0].value.text = "treated"
* group.stratifier[2].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[2].stratum[0].population[0].count = 15900
* group.stratifier[2].stratum[1].value.text = "not treated"
* group.stratifier[2].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[2].stratum[1].population[0].count = 1600
* extension[coverageSource].valueCode = #administrative
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#microcensus "Microcensus / enumeration"
* extension[denominatorType].valueCode = #at-risk
* extension[dataLineage].valueCode = #realtime

// S7 — the RECONCILED stream: same round, same measure, corrected at close-out
// (duplicate register rows removed, late paper tallies added). Exported to ESPEN.
Instance: sc-cov-round-reconciled
InstanceOf: ICRAdministrativeCoverage
Title: "Scenario — Kogi SCH round coverage (reconciled close-out)"
Usage: #example
* status = #complete
* type = #summary
* measure = "https://icr.healthcampaigns.org/Measure/icr-mda-treatment-coverage"
* period.start = "2026-06-01"
* period.end = "2026-06-12"
* reporter.display = "Kogi State NTD coordinator"
* group.population[0].code = $MeasurePopulation#numerator "Numerator"
* group.population[0].count = 15200
* group.population[1].code = $MeasurePopulation#denominator "Denominator"
* group.population[1].count = 17500
* group.measureScore.value = 0.87
* group.stratifier[0].code = $CoverageStratifier#sex "Sex"
* group.stratifier[0].stratum[0].value.text = "female"
* group.stratifier[0].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[0].stratum[0].population[0].count = 7800
* group.stratifier[0].stratum[1].value.text = "male"
* group.stratifier[0].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[0].stratum[1].population[0].count = 7400
* group.stratifier[1].code = $CoverageStratifier#age-band "Age band"
* group.stratifier[1].stratum[0].value.text = "5–9 years"
* group.stratifier[1].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[1].stratum[0].population[0].count = 8500
* group.stratifier[1].stratum[1].value.text = "10–14 years"
* group.stratifier[1].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[1].stratum[1].population[0].count = 6700
* group.stratifier[2].code = $CoverageStratifier#disposition "Disposition"
* group.stratifier[2].stratum[0].value.text = "treated"
* group.stratifier[2].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[2].stratum[0].population[0].count = 15200
* group.stratifier[2].stratum[1].value.text = "not treated"
* group.stratifier[2].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[2].stratum[1].population[0].count = 2300
* extension[coverageSource].valueCode = #administrative
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#microcensus "Microcensus / enumeration"
* extension[denominatorType].valueCode = #at-risk
* extension[dataLineage].valueCode = #reconciled

// S5 — ward-level coverage without a ward CarePlan: geography scoping via
// MeasureReport.subject (base-R4 element, allowed but NOT profiled/MS in the IG).
Instance: sc-cov-felele-ward
InstanceOf: ICRAdministrativeCoverage
Title: "Scenario — Felele Ward coverage (reconciled)"
Usage: #example
* status = #complete
* type = #summary
* measure = "https://icr.healthcampaigns.org/Measure/icr-mda-treatment-coverage"
* subject = Reference(sc-felele-ward)
* period.start = "2026-06-01"
* period.end = "2026-06-12"
* reporter.display = "Emeka Okafor (LGA NTD supervisor)"
* group.population[0].code = $MeasurePopulation#numerator "Numerator"
* group.population[0].count = 8900
* group.population[1].code = $MeasurePopulation#denominator "Denominator"
* group.population[1].count = 9800
* group.measureScore.value = 0.91
* group.stratifier[0].code = $CoverageStratifier#sex "Sex"
* group.stratifier[0].stratum[0].value.text = "female"
* group.stratifier[0].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[0].stratum[0].population[0].count = 4600
* group.stratifier[0].stratum[1].value.text = "male"
* group.stratifier[0].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[0].stratum[1].population[0].count = 4300
* group.stratifier[1].code = $CoverageStratifier#age-band "Age band"
* group.stratifier[1].stratum[0].value.text = "5–9 years"
* group.stratifier[1].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[1].stratum[0].population[0].count = 4900
* group.stratifier[1].stratum[1].value.text = "10–14 years"
* group.stratifier[1].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[1].stratum[1].population[0].count = 4000
* group.stratifier[2].code = $CoverageStratifier#disposition "Disposition"
* group.stratifier[2].stratum[0].value.text = "treated"
* group.stratifier[2].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[2].stratum[0].population[0].count = 8900
* group.stratifier[2].stratum[1].value.text = "not treated"
* group.stratifier[2].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[2].stratum[1].population[0].count = 900
* extension[coverageSource].valueCode = #administrative
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#microcensus "Microcensus / enumeration"
* extension[denominatorType].valueCode = #at-risk
* extension[dataLineage].valueCode = #reconciled

// S13/S18 — the community tally: sex × disposition, PLUS a locally-defined
// "directly-observed consumption" stratifier (no standard code exists in
// ICRCoverageStratifierCS — carried as text, which is the S18 gap made visible).
Instance: sc-tally-felele
InstanceOf: ICRAdministrativeCoverage
Title: "Scenario — Felele-Central community treatment tally (stratified)"
Usage: #example
* status = #complete
* type = #summary
* measure = "https://icr.healthcampaigns.org/Measure/icr-mda-treatment-coverage"
* subject = Reference(sc-felele-central)
* period.start = "2026-06-03"
* period.end = "2026-06-06"
* reporter.display = "Mariam Adamu (CDD) via Emeka Okafor (supervisor)"
* group.population[0].code = $MeasurePopulation#numerator "Numerator"
* group.population[0].count = 312
* group.population[1].code = $MeasurePopulation#denominator "Denominator"
* group.population[1].count = 340
* group.measureScore.value = 0.92
* group.stratifier[0].code = $CoverageStratifier#sex "Sex"
* group.stratifier[0].stratum[0].value.text = "female"
* group.stratifier[0].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[0].stratum[0].population[0].count = 160
* group.stratifier[0].stratum[1].value.text = "male"
* group.stratifier[0].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[0].stratum[1].population[0].count = 152
* group.stratifier[1].code = $CoverageStratifier#disposition "Disposition"
* group.stratifier[1].stratum[0].value.text = "treated"
* group.stratifier[1].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[1].stratum[0].population[0].count = 312
* group.stratifier[1].stratum[1].value.text = "not treated — absent"
* group.stratifier[1].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[1].stratum[1].population[0].count = 18
* group.stratifier[1].stratum[2].value.text = "not treated — refused"
* group.stratifier[1].stratum[2].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[1].stratum[2].population[0].count = 6
* group.stratifier[1].stratum[3].value.text = "not treated — excluded (under-height)"
* group.stratifier[1].stratum[3].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[1].stratum[3].population[0].count = 4
// S18 — the partial-swallow split. There is NO standard stratifier axis for
// directly-observed consumption (ICRCoverageStratifierCS has none, and a locally-
// added stratifier fails full validation because it has no match in the Measure
// definition — see probe-tally-doc-stratifier in the validation report). The split
// therefore rides on disposition sub-strata, stretching "disposition" semantics.
* group.stratifier[1].stratum[4].value.text = "treated — swallowed under observation"
* group.stratifier[1].stratum[4].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[1].stratum[4].population[0].count = 305
* group.stratifier[1].stratum[5].value.text = "treated — dispensed, not observed to swallow"
* group.stratifier[1].stratum[5].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[1].stratum[5].population[0].count = 7
* group.stratifier[2].code = $CoverageStratifier#age-band "Age band"
* group.stratifier[2].stratum[0].value.text = "5–9 years"
* group.stratifier[2].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[2].stratum[0].population[0].count = 170
* group.stratifier[2].stratum[1].value.text = "10–14 years"
* group.stratifier[2].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group.stratifier[2].stratum[1].population[0].count = 142
* extension[coverageSource].valueCode = #administrative
* extension[denominatorSource].valueCodeableConcept = $DenominatorSource#microcensus "Microcensus / enumeration"
* extension[denominatorType].valueCode = #at-risk
* extension[dataLineage].valueCode = #reconciled
