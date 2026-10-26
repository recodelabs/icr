---
title: IG additions from the DIGIT mapping — design decisions
version: 0.1.0
last_modified: 2026-10-26T19:50:00Z
status: decided; not yet implemented in the IG
tags:
  - icr
  - ig
  - digit
  - design-decision
---

# IG additions from the DIGIT mapping — design decisions

<sub>`v0.1.0 · Last modified Oct 26, 2026 at 3:50 PM EDT`</sub>

Mapping DIGIT HCM onto the ICR ([[digit]]) showed six things the IG cannot yet record.
This note records what was decided for each, the options that were rejected and why, and
the element-level design to implement. The decisions were made in a review session on
Oct 26, 2026. Each one was checked against the WHO SMART Guidelines IGs
(smart.who.int: Immunizations, HIV, Base), because the ICR aims to follow SMART
conventions ([[ig-summary-v2]] §13.3).

## Summary

| Gap | Decision | New IG artifacts |
| --- | --- | --- |
| 1. Head of household | Coded relationship to the head on each household member; several heads allowed | Extension `relationship-to-head`; CodeSystem `ICRHouseholdRelationshipCS`; ValueSet `ICRRelationshipToHeadVS`; invariant `icr-du-head` (warning) |
| 2. Referrals | ServiceRequest for the referral, Task for the facility's follow-up | Profiles `ICRReferral` (ServiceRequest) and `ICRReferralFulfilment` (Task); CodeSystem `ICRReferralReasonCS` + ConceptMap to SNOMED CT; Task output `referred-count` |
| 3. Household denominators | Unit of count on the target population | Extension `unit-of-count`; CodeSystem/ValueSet `ICRCountUnit`; Measure `icr-household-coverage` |
| 4. Stock counts | A count at a facility or store is an Observation | Profile `ICRStockCount` (Observation) |
| 5. Registration | A `register` activity and Task, only when registration is a separate visit | Activity code `register`; Task outputs `voucher` and `entitlement` |
| 6. Microplan resource estimates | Per-area estimate of each resource as an Observation | Profile `ICRResourceEstimate` (Observation); CodeSystem `ICRResourceTypeCS` |

## SMART Guidelines findings that shaped the decisions

- **Immunizations** has a caregiver profile, `IMMZ.Caregiver` (RelatedPerson, `relationship`
  1..1) that adds no binding of its own, so it uses base FHIR's patient-relationship
  binding (mostly HL7 v3 RoleCode). Its client-registration model (`IMMZ.C4`) lists
  caregivers by name only. There is no household or head-of-household concept.
- **HIV** has a referral workflow (`HIV.I`) as a logical model only, with no FHIR
  profile: emergency referral, reason (an HIV-specific code list), treatment given before
  referral, scheduled appointment date and place, date the referral was made, referring
  provider and facility, notes.
- **SMART coding pattern:** each IG defines its own concept codes (for example
  `HIV.I.DE3`) with stable ids and publishes mappings to SNOMED CT, ICD-11 and LOINC.
  Each coded element has a paired ValueSet.
- **No SMART IG models stock or inventory.** FHIR's `InventoryReport` exists only in R5.
- The WHO example caregiver uses a malformed code-system URL
  (`http://terminology.hl7.org/5.1.0/CodeSystem-v3-RoleClass.html`); do not copy it.

## 1. Head of household

**Problem.** DIGIT marks the head on each household member (`isHeadOfHousehold`) and
records relationships between members. The IG lists members on `ICRDeliveryUnit.member`
and treats the head as the anchor for linking a household across campaigns
([[ig-summary-v2]] §5.1), but marks the head only by listing them first.

**Decision.**

- Extension `relationship-to-head` on `ICRDeliveryUnit.member`, `valueCodeableConcept`,
  `0..1`, MS. It records how the member relates to the head, the question census and DHS
  household rosters ask. A head is coded `head`.
- **Several heads are allowed**: code each of them `head`. Most households have one.
- ValueSet `ICRRelationshipToHeadVS`, **extensible** binding, so a form that records a
  finer v3 code (`SON`, `WIFE`) stays valid:

| Census / DHS category | Code |
| --- | --- |
| Head | ICR `head` (HL7 has no code) |
| Wife / husband | v3 RoleCode `SPS` |
| Son / daughter | v3 RoleCode `CHILD` |
| Son / daughter-in-law | v3 RoleCode `CHLDINLAW` |
| Grandchild | v3 RoleCode `GRNDCHILD` |
| Parent | v3 RoleCode `PRN` |
| Parent-in-law | v3 RoleCode `PRNINLAW` |
| Brother / sister | v3 RoleCode `SIB` |
| Other relative | v3 RoleCode `FAMMEMB` |
| Adopted / foster / stepchild | v3 RoleCode `CHLDADOPT`, `CHLDFOST`, `STPCHLD` |
| Not related | ICR `non-relative` (v3 has only friend, roommate, neighbour) |
| Don't know | v3 NullFlavor `UNK` |

- CodeSystem `ICRHouseholdRelationshipCS` holds the two ICR codes, `head` and
  `non-relative`.
- Invariant `icr-du-head`, **warning**: a household (`code = household`) with at least
  one `member` should have at least one member coded `head`. It does not limit the number
  of heads.
- Update the IG text in §5.1: the head is identified by the code, not by list order.

**Rejected.**

- A complex extension with separate `role` and `relationship` parts: two fields for what
  one code says.
- `Group.managingEntity`: R4 allows only Organization, RelatedPerson, Practitioner or
  PractitionerRole, so the head would need a second record as a RelatedPerson.
- An ICR-only census code system: SMART alignment favours HL7 codes where they exist.
- The full v3 RoleCode as the value set: hundreds of codes, no `head`, no "not related".
- An error-level rule allowing one head: households with two heads exist.

**Deferred.** Relationships between two members who are not the head (for example a
child's caregiver). When this is taken up, model the caregiver as a `RelatedPerson`
conforming to `IMMZ.Caregiver`, not as a member-to-member extension.

## 2. Referrals

**Problem.** DIGIT records referrals from the field (`Referral`: referrer, recipient type
and id, reasons, linked side effect) and referrals a facility received (`HFReferral`).
Campaign uses: an adverse event after a dose; fever or suspected malaria during SMC;
acute malnutrition (red MUAC) at a child-health campaign; a child excluded for illness;
a zero-dose child sent to routine immunization; a pregnant woman excluded from MDA and
sent to antenatal care. The IG has no referral record.

**Decision.** The referral is a **ServiceRequest**; what the facility did with it is a
**Task**.

- **Why two resources.** The ServiceRequest is what was asked: who, to which facility,
  why, how urgent, and for when. The referring worker writes it and it does not change.
  The Task is the facility's follow-up: received, arrived, seen, or never came, with the
  date and who received the person. The facility updates it. A Task alone would have to
  be a second Task profile (ICRCampaignTask requires a campaign team as owner, a delivery
  strategy and a place of campaign work), would lack an appointment time and allows one
  reason only. Systems that take FHIR referrals, and IHE 360X closed-loop referral, expect
  ServiceRequest plus Task.

**`ICRReferral` (ServiceRequest)** — the SMART HIV.I elements mapped to ServiceRequest:

| Element | Cardinality | Content |
| --- | --- | --- |
| `status` | 1..1 MS | `active` when made; `completed` / `revoked` when closed |
| `intent` | 1..1 | fixed `order` |
| `category` | 1..1 MS | fixed ICR `campaign-referral` |
| `priority` | MS | `urgent` for an emergency referral, otherwise `routine` (SMART: emergency referral) |
| `subject` | 1..1 MS | `Reference(ICRPatient)` |
| `basedOn` | 1..1 MS | `Reference(ICRCampaign)` |
| `requester` | MS | `Reference(Practitioner \| PractitionerRole)` — the referring worker (SMART: provider who made referral, provider facility) |
| `performer` | MS | `Reference(ICRFacilityOrganization \| Organization \| PractitionerRole)` — whom the person is referred to |
| `locationReference` | MS | `Reference(ICRLocation)` — the facility (SMART: location of appointment) |
| `authoredOn` | 1..1 MS | when the referral was made (SMART: date referral was made) |
| `occurrence[x]` | MS | the scheduled appointment, where given (SMART: date of scheduled appointment) |
| `reasonCode` | 1..* MS | from `ICRReferralReasonVS` (extensible) |
| `reasonReference` | MS | `Reference(ICRAdverseEvent)` when the referral is for an adverse event |
| `supportingInfo` | MS | `Reference(ICRMedicationAdministration \| ICRImmunizationEvent)` — treatment given before referral (SMART) |
| `note` | MS | referral notes |
| `extension[referringTask]` | 0..1 MS | `Reference(ICRCampaignTask)` — the visit where the referral was made |

**`ICRReferralFulfilment` (Task)**

| Element | Cardinality | Content |
| --- | --- | --- |
| `focus` | 1..1 MS | `Reference(ICRReferral)` |
| `for` | 1..1 MS | `Reference(ICRPatient)` |
| `status` | MS | `requested` → `received` / `accepted` → `completed` (arrived and seen) / `failed` (did not arrive) / `cancelled` |
| `businessStatus` | MS | finer outcome, for example "arrived", "not arrived", "referred on" |
| `owner` | MS | the receiving facility Organization or PractitionerRole |
| `executionPeriod` | MS | when the person was received |
| `intent` | 1..1 | fixed `order` |

**Reason codes.** CodeSystem `ICRReferralReasonCS` with ICR codes; ValueSet
`ICRReferralReasonVS` (extensible); ConceptMap `ICRReferralReasonToSNOMED`. This follows
the SMART pattern (own codes, mapped to SNOMED CT) and keeps SNOMED licensing out of the
data, which matters in campaign countries outside SNOMED's free terms. SNOMED codes
below were looked up on tx.fhir.org on Oct 26, 2026.

| ICR code | Meaning | SNOMED CT (ConceptMap target) |
| --- | --- | --- |
| `vaccine-adverse-event` | Adverse event after a vaccine | `293104008` Vaccine adverse reaction |
| `drug-adverse-event` | Adverse event after an MDA or chemoprevention drug | `62014003` Adverse reaction to drug |
| `fever` | Fever | `386661006` Fever |
| `suspected-malaria` | Suspected malaria | `772168000` Malaria suspected |
| `acute-malnutrition` | Acute malnutrition (for example red MUAC) | `762497007` Acute malnutrition in childhood (no "severe acute malnutrition" concept found; severity comes from the MUAC measurement) |
| `zero-dose-to-routine` | Zero-dose child, to routine immunization | `401179006` No previous immunizations |
| `illness` | Excluded for illness | `39104002` Illness |
| `pregnancy` | Pregnancy (excluded from MDA, to antenatal care) | `77386006` Pregnancy |
| `other` | Other (with text) | — |

**Task output.** New `ICRTaskOutputTypeCS` code `referred-count` (unsignedInt) on
ICRCampaignTask, so visit tallies do not need to count ServiceRequests and count-only
capture can still report referrals.

**Rejected.** A follow-up ICRCampaignTask alone (no "referred to whom", no priority or
appointment); counts only (no follow-up possible); SNOMED codes directly in the data
(licensing).

## 3. Denominators that count households

**Problem.** `ICRTargetPopulation` fixes `type = person`; its `quantity` is a number of
people. ITN campaigns target households, and IRS targets structures. DIGIT's boundary
data has total and targeted households alongside total and targeted individuals. R4
`Group.type` has no household value.

**Clarification recorded during the review.** `ICRDeliveryUnit` Groups are the actual
households (one Group each, linked to a dwelling Location). Counting them gives the
households *found and registered*, which exists only after registration. The household
*target* is set before the campaign, when no household Groups exist, so it has to be a
number on an `ICRTargetPopulation`.

**Decision.**

- Extension `unit-of-count` on `ICRTargetPopulation`, `valueCode`, `0..1` MS, required
  binding to `ICRCountUnitVS`: `person` | `household` | `structure`. Absent means
  `person`. `Group.type` stays `person` (the nearest R4 value); consumers must read the
  unit.
- One figure per Group. An ITN activity's `planning-denominator` points at the household
  Group; the same campaign's person figure is a separate Group.
- **The registered-household count is another estimate.** The warehouse or importer
  writes an ICRTargetPopulation with `unit-of-count = household`,
  `denominatorSource = microcensus` (the existing code: "local enumeration from
  microplanning or household registration"), `isCalculated = true`, and the geography of
  the counted households. Competing estimates sit side by side as for people.
- `structure` is included now for IRS.
- New Measure `icr-household-coverage` (proportion): numerator = distinct households in
  `ICRSupplyDistribution.extension[recipient]` for the campaign and geography; denominator =
  an ICRTargetPopulation with `unit-of-count = household`. Registration coverage
  (registered ÷ targeted households) uses the same Measure with a register-Task numerator;
  decide during implementation whether that is a second group in the Measure or a second
  Measure.
- Invariant on the coverage MeasureReports (warning): the denominator population's unit
  must match the Measure.
- Warehouse: add a `unit` column to the `IcrTargetPopulation` view; CampaignHQ labels
  household targets as households.

**Rejected.** A household count beside `quantity` on the person Group (a household
figure could not be the planning denominator on its own, and the two figures often have
different sources); a separate household-denominator profile (duplicates every provenance
extension and view); reusing `icr-admin-coverage` with a unit-dependent numerator (harder
to explain and validate).

## 4. Stock counts at a facility

**Problem.** DIGIT's `StockReconciliation` is a physical count at a facility on a date
(`physicalCount` vs `calculatedCount`, with comments). The IG's `stockAccountability`
sits on an issuance (`ICRSupplyMovement`), which already covers a team's daily
reconciliation, but a count at a store is not a movement.

**Decision.** Profile **`ICRStockCount`** on Observation, one per place × product × count
date, following the IG's other Observation profiles (`ICRLocationStatus`,
`ICRCampaignCost`).

| Element | Cardinality | Content |
| --- | --- | --- |
| `status` | MS | `final` |
| `code` | 1..1 MS | fixed ICR `stock-count` |
| `subject` | 1..1 MS | `Reference(ICRLocation)` — a facility, warehouse or staging post |
| `effective[x]` | 1..1 MS | dateTime of the count |
| `valueQuantity` | 1..1 MS | the physical count, in the product's base unit |
| `component[expected]` | 0..1 MS | the balance according to the records |
| `extension[suppliedItem]` | 1..1 MS | CodeableConcept from `ICRSuppliedItemVS` (extensible) — the same codes as the movements |
| `basedOn` | MS | `Reference(ICRCampaign)` |
| `performer` | MS | who counted |
| `derivedFrom` | MS | `Reference(ICRSupplyMovement)` — the movements since the last count |
| `note` | MS | comments on the count |

Concordance is `valueQuantity = component[expected]`; no separate flag. Counts are for
facilities and stores only; team end-of-day counts stay on the issuance ledger.

**Rejected.** An R5 `InventoryReport` brought into R4 (poor R4 server and validator
support); a SupplyMovement with no supplier (a count is not a movement, and movement
totals would include it); leaving counts out of the ICR.

## 5. The registration step

**Problem.** In two-phase ITN campaigns, teams register households house to house
(members listed, entitlement worked out, voucher issued) and households redeem the
voucher later at a fixed post. "Registered but not served" and "vouchers issued vs
redeemed" are standard indicators. DIGIT records registration as `ProjectBeneficiary`
(with `tag` = voucher and `dateOfRegistration`). The IG's principle 8 is one Task per
visit, never one per person, and registration lives in the household's member list.

**Decision.**

- `ICRCampaignActivity` code `register`; the ITN example gains a register activity beside
  its distribute activity.
- An ICRCampaignTask for each **household registration visit** — `for` = the household
  Group, `instantiatesCanonical` = the register activity, `executionPeriod` = the
  registration date, existing outputs `eligiblePresent` (members listed) and
  `eligibleAbsent`.
- **Only when registration is a separate visit.** When registration and delivery happen
  in the same visit (SMC, polio), the delivery Task with `taskOrigin = field-registered`
  is the record.
- **Not created in advance.** Register Tasks are created at the visit
  (`taskOrigin = field-registered`); they are never generated per household ahead of the
  campaign. Pre-planned work stays at area or team level. This keeps resource counts down.
- New `ICRTaskOutputTypeCS` codes:
  - `voucher` (string, or Identifier) — the voucher or QR code issued to the household.
  - `entitlement` (Quantity) — what the household is due, for example 3 LLINs.
- The `ICRSupplyDistribution` that redeems a voucher carries the same code as an
  `identifier` (system per campaign), so issued vs redeemed is a match on the code.
- Add to the IG text (§4.4 and principle 8) when a register Task is used.

**Rejected.** A register Task for every registration, including same-visit ones (more
resources for no new information); a `campaign-registration` extension on the Group or
Patient (rewrites the household record every campaign, against stable household
identity); EpisodeOfCare (R4 `EpisodeOfCare.patient` cannot be a household Group); the
voucher as an identifier on the household Group (the voucher belongs to one campaign).

## 6. Microplan resource estimates

**Problem.** DIGIT's microplan stores, per locality, the estimated number of each resource
(`plan_resource`) and the assumptions and formulas behind it. The IG has targets, team
workload (`workloadTarget`) and budgeted cost, but no planned quantity of resources per
area. With estimates, planned vs used can be compared against what the IG already records
(`stockAccountability.used`, CareTeams, delivery events).

**Decision.** Profile **`ICRResourceEstimate`** on Observation, one per Location ×
resource kind (× product for commodities), following `ICRCampaignCost`.

| Element | Cardinality | Content |
| --- | --- | --- |
| `status` | MS | `preliminary` while the plan is in draft; `final` once approved |
| `code` | 1..1 MS | from `ICRResourceTypeVS` (required) |
| `subject` | 1..1 MS | `Reference(ICRLocation)` — any level |
| `basedOn` | 1..1 MS | `Reference(ICRCampaign)` |
| `valueQuantity` | 1..1 MS | the estimate |
| `extension[suppliedItem]` | 0..1 MS | the product, for commodity estimates (`ICRSuppliedItemVS`); required when `code = commodity` (invariant) |
| `derivedFrom` | MS | `Reference(ICRTargetPopulation)` — the target the estimate was computed from |
| `component` | 0..* MS | one per assumption: `code` (CodeableConcept; text where the source has only a key) + `valueQuantity`, for example persons per net 1.8, buffer 10 % |
| `effective[x]` | MS | when the estimate was made |
| `performer` | MS | who made it (planning team, tool) |
| `method` | MS | how it was made (microplanning tool, manual) |

`ICRResourceTypeCS` (first version): `commodity`, `teams`, `team-days`, `supervisors`,
`vehicles`, `cold-chain-equipment` (vaccine carriers, cold boxes).

**Rejected.** Campaign totals only on `CarePlan.activity.detail.quantity` (no per-area
figures, no teams or vehicles, no assumptions); leaving estimates out of the ICR.

**Open.** Whether Crosscut's microplanning outputs land in `ICRResourceEstimate`. If they
do, the resource-type codes should be agreed with Crosscut before the IG release.

## Effect on the DIGIT mapping

Two corrections to [[digit]] follow from these decisions and from principle 8:

1. **DIGIT per-person tasks.** In individual-beneficiary campaigns (SMC, polio) DIGIT
   records one task per person per delivery. These map to **delivery events only**. The
   importer groups the tasks of one household from the same visit (same household,
   worker and day) into **one** ICRCampaignTask with `for` = the household Group. A
   Patient-targeted Task is only for chasing a missed or zero-dose person.
2. **Registration.** A `ProjectBeneficiary` from a separate registration phase maps to a
   register Task (with `voucher` and `entitlement` outputs). One registered during the
   delivery visit maps to `taskOrigin = field-registered` on that visit's Task.

The DIGIT entities that had no target now map as follows: `isHeadOfHousehold` and
`relationshipType` → `relationship-to-head`; `Referral` → `ICRReferral`; `HFReferral` →
`ICRReferralFulfilment`; household targets → ICRTargetPopulation with
`unit-of-count = household`; `StockReconciliation` → `ICRStockCount`;
`plan_resource` and assumptions → `ICRResourceEstimate`.

## Implementation checklist

- [ ] `extensions.fsh`: `relationship-to-head`, `unit-of-count`, `referring-task`,
      `supplied-item` (shared by ICRStockCount and ICRResourceEstimate)
- [ ] `codesystems.fsh`: `ICRHouseholdRelationshipCS`, `ICRReferralReasonCS`,
      `ICRCountUnitCS`, `ICRResourceTypeCS`; new codes in `ICRTaskOutputTypeCS`
      (`referred-count`, `voucher`, `entitlement`); `stock-count` and
      `campaign-referral` codes
- [ ] `valuesets.fsh`: `ICRRelationshipToHeadVS`, `ICRReferralReasonVS`,
      `ICRCountUnitVS`, `ICRResourceTypeVS`
- [ ] `conceptmaps.fsh`: `ICRReferralReasonToSNOMED`
- [ ] `profiles-population.fsh`: member extension and `icr-du-head` on ICRDeliveryUnit;
      `unit-of-count` on ICRTargetPopulation
- [ ] new profiles: `ICRReferral`, `ICRReferralFulfilment`, `ICRStockCount`,
      `ICRResourceEstimate`
- [ ] `profiles-campaign.fsh`: new output slices on ICRCampaignTask
- [ ] `measures.fsh`: `icr-household-coverage`
- [ ] `examples.fsh`: head and relationships on the example household; a referral and
      its fulfilment; a household target; a stock count; an ITN register activity and
      register Task with voucher, and the redeeming distribution; a resource estimate
- [ ] `viewdefinitions.fsh` and `data/views`: `unit` on `IcrTargetPopulation`; new views
      for referrals, stock counts and resource estimates if the warehouse needs them
- [ ] [[ig-summary-v2]]: new sections and updated §5.1, §5.2, §4.4, §6.3, §7, §8 and §13
- [ ] SUSHI and the IG Publisher build pass with no new errors
- [ ] [[digit]]: apply the two corrections above
