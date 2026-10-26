---
title: IG additions from the DIGIT mapping — design decisions
version: 0.3.0
last_modified: 2026-10-26T23:30:00Z
status: decided; reviewed twice by Codex (Oct 26, 2026); not yet implemented in the IG
tags:
  - icr
  - ig
  - digit
  - design-decision
---

# IG additions from the DIGIT mapping — design decisions

<sub>`v0.3.0 · Last modified Oct 26, 2026 at 7:30 PM EDT`</sub>

Mapping DIGIT HCM onto the ICR ([[digit]]) showed six things the IG cannot yet record.
This note records what was decided for each, the options that were rejected and why, and
the element-level design to implement. The decisions were made in a review session on
Oct 26, 2026, checked against the WHO SMART Guidelines IGs (smart.who.int: Immunizations,
HIV, Base) because the ICR aims to follow SMART conventions ([[ig-summary-v2]] §13.3),
and then reviewed by Codex against the R4 core definitions, twice. Versions 0.2.0 and
0.3.0 apply those reviews; "Changes after review" at the end lists what changed.

## Summary

| Gap | Decision | New IG artifacts |
| --- | --- | --- |
| 1. Head of household | One reference head per household, other heads coded co-head; each member's relationship to the reference head | Extension `relationship-to-head`; CodeSystem `ICRHouseholdRelationshipCS`; ValueSet `ICRRelationshipToHeadVS`; invariants `icr-du-one-head` (error), `icr-du-head` (warning) |
| 2. Referrals | ServiceRequest for the referral, Task for the facility's follow-up | Profiles `ICRReferral` (ServiceRequest), `ICRReferralFulfilment` (Task); extension `referring-task`; CodeSystem `ICRReferralReasonCS` + ConceptMap to SNOMED CT; Task output `referred-count` |
| 3. Household denominators | Unit of count as a modifier extension on the target population | Modifier extension `unit-of-count`; CodeSystem/ValueSet `ICRCountUnit`; Measure `icr-household-coverage`; `denominator` slice on coverage reports |
| 4. Stock counts | A count at a facility or store is an Observation | Profile `ICRStockCount` (Observation); extensions `supplied-item`, `stock-count-basis` |
| 5. Registration | `registered-count` and `registered-household` outputs on any Task; a `register` Task only for a separate registration visit | Activity code `register`; Task outputs `registered-count`, `registered-household`, `voucher`, `entitlement` |
| 6. Microplan resource estimates | Per-area estimate of each resource as an Observation | Profile `ICRResourceEstimate` (Observation); extension `estimate-basis`; CodeSystem `ICRResourceTypeCS` |
| — Per-person outcomes | Not-delivered vaccine and drug doses are delivery events with `status = not-done`; events name their activity | Extension `campaign-activity` on delivery events; IG text in §6, §7 and principle 8 |

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

- Extension `relationship-to-head`, context `Group.member`, `valueCodeableConcept`,
  `0..1`, MS. It records how the member relates to the household's **reference head**,
  the question census and DHS household rosters ask.
- **One reference head, any number of co-heads.** The reference head is coded `head`;
  every relationship code on the other members is relative to that person. Other heads
  are coded `co-head`. A co-head's own relationship to the reference head (often spouse)
  is not recorded in this version.
- ValueSet `ICRRelationshipToHeadVS`, **extensible** binding. The value set includes the
  v3 RoleCode concepts below **and their descendants** (compose filter
  `concept is-a <code>`), so a form that records `SON`, `WIFE` or `HUSB` is valid as it
  stands. `FAMMEMB` is included as the single code only, because its descendants are every
  family relationship.

| Census / DHS category | Code | Value-set rule |
| --- | --- | --- |
| Head (reference person) | ICR `head` | code |
| Other head | ICR `co-head` | code |
| Wife / husband | v3 RoleCode `SPS` | is-a |
| Son / daughter | v3 RoleCode `CHILD` | is-a (includes `SON`, `DAU`, `NCHILD`, …) |
| Son / daughter-in-law | v3 RoleCode `CHLDINLAW` | is-a |
| Grandchild | v3 RoleCode `GRNDCHILD` | is-a |
| Parent | v3 RoleCode `PRN` | is-a |
| Parent-in-law | v3 RoleCode `PRNINLAW` | is-a |
| Brother / sister | v3 RoleCode `SIB` | is-a |
| Adopted / foster / stepchild | v3 RoleCode `CHLDADOPT`, `CHLDFOST`, `STPCHLD` | is-a (these are also under `CHILD`) |
| Other relative | v3 RoleCode `FAMMEMB` | code only |
| Not related | ICR `non-relative` | code |
| Don't know | v3 NullFlavor `UNK` | code |

- `FAMMEMB` is broader than the census "other relative": it does not say "none of the
  listed relationships". Where the source category matters, keep it in `text`.
- CodeSystem `ICRHouseholdRelationshipCS` holds the three ICR codes: `head`, `co-head`,
  `non-relative`.
- **Active member**, for both invariants: `inactive` is not true and `period.end` is
  absent.
- Invariant `icr-du-one-head`, **error**: at most one active member is coded `head`.
- Invariant `icr-du-head`, **warning**: a household (`code = household`) with at least one
  active member should have an active member coded `head`.
- **Choosing the reference head** is persistent: once a member is the reference head they
  stay so until they leave the household or the source names a different head. An
  importer picks the source's head; if the source marks several, the one registered first
  (earliest client creation time) is the reference head and the others are co-heads.
- **When the reference head changes**, every other member's relationship code was relative
  to the old head and may no longer be true. Re-code them from the source if it gives
  relationships to the new head; otherwise remove the codes (leave the extension absent)
  rather than keep codes that refer to someone else. The earlier codes stay in the Group's
  version history.
- Update the IG text in §5.1: the head is identified by the code, not by list order.

**Rejected.** A complex extension with separate role and relationship parts;
`Group.managingEntity` (R4 allows only Organization, RelatedPerson, Practitioner or
PractitionerRole, so the head would need a second record); an ICR-only census code system
(SMART alignment favours HL7 codes); the full v3 RoleCode as the value set (hundreds of
codes, no `head`, no "not related"); several members coded `head` with no stated anchor
(a member coded `CHILD` would not say whose child).

**Deferred.** Relationships between two members neither of whom is the reference head (for
example a child's caregiver), and a co-head's relationship to the reference head. When
taken up, model a caregiver as a `RelatedPerson` conforming to `IMMZ.Caregiver`.

## 2. Referrals

**Problem.** DIGIT records referrals from the field (`Referral`: referrer, recipient type
and id, reasons, linked side effect) and referrals a facility received (`HFReferral`).
Campaign uses: an adverse event after a dose; fever or suspected malaria during SMC;
acute malnutrition (red MUAC) at a child-health campaign; a child excluded for illness;
a zero-dose child sent to routine immunization; a pregnant woman excluded from MDA and
sent to antenatal care. The IG has no referral record.

**Decision.** The referral is a **ServiceRequest**; what the facility did with it is a
**Task**.

- **Why two resources.** The ServiceRequest says what was asked: who, to which facility,
  why, how urgent, and for when. The Task records the facility's follow-up: received,
  arrived, seen, or never came. A Task alone would have to be a second Task profile anyway
  (ICRCampaignTask is for campaign work: `basedOn` a campaign, a delivery strategy, a place
  of campaign work), has no appointment time and allows one reason only. Systems that take
  FHIR referrals, and IHE 360X closed-loop referral, expect ServiceRequest plus Task.
- **Lifecycle.** The request's content (subject, reason, performer, priority, dates) is
  not changed after it is made. Its `status` does change:
  - `active` when made;
  - `completed` when a fulfilment Task completes (the person was seen);
  - `revoked` only by the referring programme (referral withdrawn);
  - a fulfilment that fails (did not arrive) does **not** revoke the request; the request
    stays `active` until it is completed, revoked or closed at the end of the campaign
    follow-up period (`completed` is not used then; set `revoked` with a note).
  Whoever imports or manages the fulfilment (the ICR importer, or the facility system)
  updates the request's status.

**`ICRReferral` (ServiceRequest)** — the SMART HIV.I elements mapped to ServiceRequest:

| Element | Cardinality | Content |
| --- | --- | --- |
| `status` | 1..1 MS | see lifecycle |
| `intent` | 1..1 | fixed `order` |
| `category` | 1..1 MS | fixed ICR `campaign-referral` |
| `priority` | MS | `urgent` for an emergency referral, otherwise `routine` (SMART: emergency referral) |
| `subject` | 1..1 MS | `Reference(ICRPatient)` |
| `basedOn` | 1..1 MS | `Reference(ICRCampaign)` |
| `requester` | MS | `Reference(Practitioner \| PractitionerRole)` — the referring worker (SMART: provider who made referral, provider facility) |
| `performer` | MS | `Reference(ICRFacilityOrganization \| Organization \| PractitionerRole \| Practitioner)` — whom the person is referred to. A Location is not a legal performer |
| `locationReference` | MS | `Reference(ICRLocation)` — the facility (SMART: location of appointment) |
| `authoredOn` | 1..1 MS | when the referral was made (SMART: date referral was made) |
| `occurrence[x]` | MS | the scheduled appointment, where given (SMART: date of scheduled appointment) |
| `reasonCode` | 1..* MS | from `ICRReferralReasonVS` (extensible) |
| `supportingInfo` | MS | `Reference(ICRAdverseEvent \| ICRMedicationAdministration \| ICRImmunizationEvent)` — the adverse event that caused the referral, and treatment given before referral (SMART). R4 `reasonReference` cannot reference an AdverseEvent |
| `note` | MS | referral notes |
| `extension[referringTask]` | 0..1 MS | `referring-task` (context ServiceRequest), `Reference(ICRCampaignTask)` — the visit where the referral was made |

**`ICRReferralFulfilment` (Task)** — a separate workflow from ICRCampaignTask; it is
excluded from campaign visit counts.

| Element | Cardinality | Content |
| --- | --- | --- |
| `focus` | 1..1 MS | `Reference(ICRReferral)` |
| `for` | 1..1 MS | `Reference(ICRPatient)` |
| `status` | MS | `requested` → `received` / `accepted` → `completed` (arrived and seen) / `failed` (did not arrive) / `cancelled` |
| `businessStatus` | MS | finer outcome, for example "arrived", "not arrived", "referred on" |
| `owner` | MS | `Reference(ICRFacilityOrganization \| Organization \| PractitionerRole)` — the receiving facility's Organization |
| `location` | MS | `Reference(ICRLocation)` — the facility Location (not `owner`) |
| `executionPeriod` | MS | when the person was received |
| `intent` | 1..1 | fixed `order` |

**A facility referral with no field referral.** DIGIT's `HFReferral` can exist without a
`Referral` (the person came to the facility with a referral slip, or the field record was
never synced). The importer then creates an `ICRReferral` from the HFReferral:
`subject` from its beneficiary, `basedOn` from its project, `authoredOn` from its client
time, `reasonCode` from its symptom, `requester` absent, an `identifier` with the
HFReferral id, and id `<prefix>-hfr-<HFReferral id>`.

If a field `Referral` arrives later, the two are merged only when **exactly one** field
referral matches on all of: the same person, the same receiving facility, the same
campaign round, a compatible reason (the HFReferral symptom maps to one of the field
referral's reason codes), and an `authoredOn` up to 14 days before the facility visit.
On a merge, the fulfilment's `focus` moves to the field referral, the field referral gains
the HFReferral identifier, and the created request is set to `revoked` with a note naming
the referral it was merged into. When there are no matches or several, both stay separate
and the pair is listed for manual reconciliation. Receiving facilities resolve to
their Organization for `owner` and their Location for `locationReference` / `location`;
staff recipients resolve to a PractitionerRole where one exists, otherwise a Practitioner.

**Reason codes.** CodeSystem `ICRReferralReasonCS`; ValueSet `ICRReferralReasonVS`
(extensible); ConceptMap `ICRReferralReasonToSNOMED`, source ICR → target SNOMED CT,
pinned to SNOMED CT International Edition 2025-02-01
(`http://snomed.info/sct/900000000000207008/version/20250201`). Every `narrower`, `wider`
and `relatedto` target carries the note below in `target.comment` (R4 invariant `cmd-1`
requires a comment on narrower and inexact maps). This follows the SMART
pattern and keeps SNOMED licensing out of the data. All targets were verified active on
tx.fhir.org. `equivalence` is the R4 ConceptMap value, read as "the target is … the
source":

| ICR code | Meaning | SNOMED CT target | Equivalence | Note |
| --- | --- | --- | --- | --- |
| `vaccine-adverse-event` | Adverse event after a vaccine (causality not assessed) | `293104008` Vaccine adverse reaction | `narrower` | The target asserts the vaccine caused it; ICRAdverseEvent keeps causality separate |
| `drug-adverse-event` | Adverse event after an MDA or chemoprevention drug | `62014003` Adverse reaction to drug | `narrower` | as above |
| `fever` | Fever | `386661006` Fever | `equivalent` | |
| `suspected-malaria` | Suspected malaria | `772168000` Malaria suspected | `equivalent` | |
| `acute-malnutrition` | Acute malnutrition (for example red MUAC) | `762497007` Acute malnutrition in childhood | `narrower` | Target is childhood only; a search on Oct 26, 2026 found no "severe acute malnutrition" concept, severity comes from the MUAC measurement |
| `zero-dose-to-routine` | Zero-dose child, to routine immunization | `401179006` No previous immunizations | `relatedto` | The target is the finding; the referral purpose is in the ICR code |
| `illness` | Excluded for illness | `39104002` Illness | `wider` | The ICR code is illness found at a campaign contact |
| `pregnancy` | Pregnancy (excluded from MDA, to antenatal care) | `77386006` Pregnancy | `equivalent` | |
| `other` | Other (with text) | — | `unmatched` | |

**Task output.** New `ICRTaskOutputTypeCS` code `referred-count` (unsignedInt, 0..1) on
ICRCampaignTask: people referred at this visit, so visit tallies do not need to count
ServiceRequests and count-only capture can still report referrals.

**Rejected.** A follow-up ICRCampaignTask alone; counts only; SNOMED codes directly in the
data (licensing).

## 3. Denominators that count households

**Problem.** `ICRTargetPopulation` fixes `type = person`; its `quantity` is a number of
people. ITN campaigns target households, and IRS targets structures. DIGIT's boundary
data has total and targeted households alongside total and targeted individuals. R4
`Group.type` has no household value. `Group.quantity` counts members of the stated type,
so a plain extension saying "households" would still be read as a person count by any
consumer that ignores it.

**Clarification recorded during the review.** `ICRDeliveryUnit` Groups are the actual
households. Counting them gives the households *found and registered*, which exists only
after registration. The household *target* is set before the campaign, so it has to be a
number on an `ICRTargetPopulation`.

**Decision.**

- **Modifier extension** `unit-of-count` on `ICRTargetPopulation` (`modifierExtension`,
  `valueCode`, `0..1`, required binding to `ICRCountUnitVS`: `person` | `household` |
  `structure`). Absent means `person`. A modifier extension tells every consumer that it
  changes the meaning of the resource: a system that does not understand it must not read
  `quantity` as people. `Group.type` stays `person`, the nearest R4 value.
- `Group.quantity` counts units of the stated unit. One figure per Group. An ITN
  activity's `planning-denominator` points at the household Group; the same campaign's
  person figure is a separate Group.
- **The registered-household count is another estimate**, written by the warehouse or
  importer after registration: an ICRTargetPopulation with `unit-of-count = household`,
  `denominatorSource = microcensus` (the existing code, "local enumeration from
  microplanning or household registration"), `estimateDate` = the last registration
  date, `characteristic[geography]` = the area, and an `identifier` naming the campaign
  round it was counted in. `isCalculated` is **not** set: a direct count is independent
  evidence, not a roll-up of other estimates. A later count is a new Group; earlier counts
  are kept.
- `structure` is included now for IRS.
- **Measure `icr-household-coverage`** (proportion), two groups:
  - *Distribution coverage.* Numerator: distinct households that are the
    `extension[recipient]` of an `ICRSupplyDistribution` with `status = completed`,
    `suppliedItem.quantity > 0`, the activity's product, and `extension[campaign]` = the
    round. Geography follows the household's **residence** (`groupLocation`), not the
    handover place. Denominator: the activity's planning denominator, which must have
    `unit-of-count = household`.
  - *Registration coverage.* Numerator: distinct households in
    `output[registeredHousehold]` of the round's ICRCampaignTasks (see §5), filtered by
    the household's residence (`groupLocation`) within the report's geography.
    Denominator: as above.
- **Coverage reports name their denominator.** Add a `denominator` slice to
  `MeasureReport.evaluatedResource` (an extension on the reference, `evaluated-role` =
  `denominator`) on `ICRAdministrativeCoverage`, pointing at the ICRTargetPopulation(s)
  used. Invariant (warning): on a report for `icr-household-coverage`, every denominator
  Group has `unit-of-count = household`; on the person coverage Measures, none has a
  non-person unit.
- Warehouse: add a `unit` column to the `IcrTargetPopulation` view; CampaignHQ labels
  household targets as households.

**Rejected.** A plain (non-modifier) extension (consumers that ignore it would misread the
count); a household count beside `quantity` on the person Group; a separate
household-denominator profile; reusing `icr-admin-coverage` with a unit-dependent
numerator; counting the household registry without a campaign scope (it includes
households from earlier campaigns).

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
| `valueQuantity` | 1..1 MS | the physical count; `value` 1..1, `system` + `code` 1..1 (the product's base unit) |
| `component[expected]` | 0..1 MS | `code` fixed ICR `expected-stock-balance`; `valueQuantity` with `value` 1..1, same `system` and `code` as the count (invariant) |
| `extension[suppliedItem]` | 1..1 MS | `supplied-item` (context Observation), CodeableConcept from `ICRSuppliedItemVS` (extensible) — the same codes as the movements |
| `extension[basis]` | 0..* MS | `stock-count-basis`, `Reference(ICRSupplyMovement)` — the movements since the last count. R4 `derivedFrom` cannot reference a SupplyDelivery |
| `basedOn` | MS | `Reference(ICRCampaign)` |
| `performer` | MS | who counted (Practitioner, PractitionerRole, Organization) |
| `note` | MS | comments on the count |

The count and the record agree when `valueQuantity.value = component[expected].valueQuantity.value`;
no separate flag. Counts are for facilities and stores only; team end-of-day counts stay on
the issuance ledger.

**Rejected.** An R5 `InventoryReport` brought into R4; a SupplyMovement with no supplier;
leaving counts out of the ICR.

## 5. The registration step

**Problem.** In two-phase ITN campaigns, teams register households house to house
(members listed, entitlement worked out, voucher issued) and households redeem the
voucher later at a fixed post. In SMC and polio, registration happens during the delivery
visit. "Registered", "registered but not served" and "vouchers issued vs redeemed" are
standard indicators. DIGIT records registration as `ProjectBeneficiary` (with `tag` =
voucher and `dateOfRegistration`). The IG's principle 8 is one Task per visit, never one
per person.

**Decision.**

- **Two registration outputs on any ICRCampaignTask** (`ICRTaskOutputTypeCS`), used on
  register Tasks and delivery Tasks alike, so registration is counted in both workflows:
  - `registered-count` (unsignedInt, 0..1): the number of people registered into the
    campaign at this visit.
  - `registered-household` (Reference(ICRDeliveryUnit), 0..*): each household registered
    into the campaign at this visit. On a household visit it is the `for` household; on
    a site session it lists every household registered there. A household can be
    registered without any new person being registered.
  "Households registered" = distinct `registered-household` references in the round.
- **`taskOrigin` keeps its meaning**: whether the Task was generated from the microplan
  (`pre-planned`) or created on discovery (`field-registered`). It says nothing about
  whether people were registered at the visit. Where the source has no planning evidence,
  the importer uses a per-campaign default (for example `pre-planned` for microplanned
  site sessions, `field-registered` for house-to-house sweeps with no household list).
- `ICRCampaignActivity` code `register`; the ITN example gains a register activity beside
  its distribute activity.
- **A register Task only for a separate registration visit.** For a household
  registration visit: `for` = the household Group, `instantiatesCanonical` = the register
  activity, `executionPeriod` = the registration date, outputs `registered-count`,
  `registered-household`, `eligiblePresent`, `eligibleAbsent`, `voucher`, `entitlement`.
- **Not created in advance per household.** Register Tasks are created at the visit; they
  are never generated per household ahead of the campaign. Pre-planned work stays at area
  or team level. This keeps resource counts down.
- New outputs:
  - `voucher` (Identifier, 0..1): the voucher or QR code issued, with a `system` per
    campaign round.
  - `entitlement` (Quantity, 0..1): what the household is due, for example 3 LLINs.
- **Redemption.** The `ICRSupplyDistribution` that redeems a voucher carries the voucher
  as an `identifier` with the same `system` and `value` and `type` = ICR `voucher`, which
  separates it from the distribution's own identifier. A partial redemption (two handovers
  against one voucher) gives two distributions with the same voucher identifier.
  "Issued vs redeemed" is a match on `(system, value)`.
- Add to the IG text (§4.4 and principle 8) when a register Task is used.

**Rejected.** A register Task for every registration (more resources for the same
information); a `campaign-registration` extension on the Group or Patient (rewrites the
household record every campaign); EpisodeOfCare (R4 `EpisodeOfCare.patient` cannot be a
household Group); the voucher as an identifier on the household Group (it belongs to one
campaign); `taskOrigin = field-registered` as the registration record (it describes where
the work came from).

## 6. Microplan resource estimates

**Problem.** DIGIT's microplan stores, per locality, the estimated number of each resource
(`plan_resource`) and the assumptions and formulas behind it. The IG has targets, team
workload (`workloadTarget`) and budgeted cost, but no planned quantity of resources per
area. With estimates, planned vs used can be compared against what the IG already records.

**Decision.** Profile **`ICRResourceEstimate`** on Observation, one per Location ×
resource kind (× product for commodities), following `ICRCampaignCost`.

| Element | Cardinality | Content |
| --- | --- | --- |
| `status` | MS | `preliminary` while the plan is in draft; `final` once approved |
| `code` | 1..1 MS | from `ICRResourceTypeVS` (required) |
| `subject` | 1..1 MS | `Reference(ICRLocation)` — any level |
| `basedOn` | 1..1 MS | `Reference(ICRCampaign)` |
| `valueQuantity` | 1..1 MS | the estimate; `value` 1..1, `system` + `code` 1..1 |
| `extension[suppliedItem]` | 0..1 MS | the product, for commodity estimates; required when `code = commodity` (invariant) |
| `extension[basis]` | 0..* MS | `estimate-basis`, `Reference(ICRTargetPopulation)` — the targets the estimate was computed from. R4 `derivedFrom` cannot reference a Group |
| `derivedFrom` | MS | `Reference(DocumentReference)` — the source microplan file or configuration, where it is kept |
| `component` | 0..* MS | one per numeric assumption: `code` (CodeableConcept; `text` where the source has only a key) + `valueQuantity` with `value` 1..1 and a unit, for example persons per net 1.8, buffer 10 % |
| `identifier` | MS | the source plan and plan-row ids |
| `effective[x]` | MS | when the estimate was made |
| `performer` | MS | the accountable team or organization (Organization, CareTeam, Practitioner, PractitionerRole). A planning tool is not a legal performer |
| `device` | MS | the planning tool, as a Device, where it is recorded |
| `method` | MS | how it was made (microplanning tool, manual) |

**What is not kept.** The components hold the numeric input assumptions only. DIGIT's
formula chain (operators, order of operations, rounding) is not represented; the estimate
cannot be recomputed from the ICR. The source plan is referenced through `derivedFrom`
(the plan file as a DocumentReference) and `identifier`.

`ICRResourceTypeCS` (first version): `commodity`, `teams`, `team-days`, `supervisors`,
`vehicles`, `cold-chain-equipment` (vaccine carriers, cold boxes).

**Rejected.** Campaign totals only on `CarePlan.activity.detail.quantity`; leaving
estimates out of the ICR.

**Open.** Whether Crosscut's microplanning outputs land in `ICRResourceEstimate`. If they
do, the resource-type codes should be agreed with Crosscut before the IG release.

## Per-person outcomes in a household visit

**Problem.** One Task per household visit (principle 8) keeps one Task when one child is
treated, one refuses and one is excluded. Reason outputs on the Task do not say which
child, so a person-targeted follow-up Task cannot be created from them.

**Decision.** A person who was eligible but not given a **vaccine or drug** gets a
delivery event with **`status = not-done`** and `statusReason` (R4
`Immunization.statusReason`, `MedicationAdministration.statusReason`), coded from the IG's
missed, refusal and exclusion value sets, with `extension[campaign]` and `recordOrigin` as
for any delivery event. This keeps one Task per visit and gives a person-level record of
every outcome. The Task keeps the counts and the household-level reasons.

- **Commodities are different.** R4 SupplyDelivery has no `statusReason` and its status
  codes (`in-progress`, `completed`, `abandoned`, `entered-in-error`) cannot say "not
  given". A commodity not handed over creates **no** ICRSupplyDistribution; the reason is
  recorded on the visit Task (`missedReason`, `noncomplianceReason`). Commodity delivery
  is household-level, so no person is lost.
- **Events name their activity.** Delivery events gain the existing `campaign-activity`
  extension (canonical ICRCampaignActivity), 0..1 MS, required by invariant when the
  visit Task carries more than one activity. Per-activity results count events by this
  link, not by product code; a co-pack delivered as two administrations names the same
  activity on both.

- `Task.status` for a household visit: `completed` when the household was reached and any
  person outcome was recorded; `failed` when the household was not reached (closed, not
  found); `requested` when not yet visited.
- `treated-count` = distinct people with at least one event `status = completed` at the
  visit.
- **Two ways to count coverage, never added together.** The IG supports tally-only
  capture, where a Task carries `treated-count` and no person-level events. So a coverage
  numerator is computed per visit Task: if the Task references delivery events
  (`output[delivery-event]`), count **distinct people** with a `completed` event for the
  activity; otherwise use its `treated-count`. A visit never contributes both. The unit is
  people for the person Measures (two SPAQ administrations to one child count once) and
  households for `icr-household-coverage`.
- `not-done` events never count in a numerator; they feed missed-child lists and
  follow-up Tasks.

## Effect on the DIGIT mapping

Corrections to [[digit]] that follow from these decisions:

1. **DIGIT per-person tasks.** In individual-beneficiary campaigns (SMC, polio) DIGIT
   records one task per person per delivery. These map to **delivery events** (completed
   or not-done). The importer groups them into **one** ICRCampaignTask per visit.
   - **Grouping rule (a heuristic).** DIGIT has no visit identifier, so grouping is a
     best guess: source tasks of the same campaign round, household and worker whose
     client times fall within a visit window (default 2 hours from the visit's latest
     row, configurable) form one visit. Where the source has better evidence (one sync
     batch, one household-overview session) it is used first. Known limits: a failed
     attempt and a return within the window merge; two workers in one household make two
     visits.
   - **Site sessions** group by round + site + worker + session window, with `for` = the
     site Location. The delivery workflow (strategy) decides household vs site grouping,
     not whether the person has a household record.
   - **Stable visit identity.** A visit's id is assigned once, when its first row is
     imported: `<prefix>-visit-<clientReferenceId of that row>`. It is stored in the
     source index and never recomputed, so two visits cannot share an id and earlier rows
     that arrive later join the existing visit rather than renaming it.
2. **Many-to-one source index.** The importer keeps a table of DIGIT row id → visit id and
   ICR resource ids. When a source row changes or is deleted, the visit it belongs to is
   recomputed (status, counts, outputs, identifiers). When a correction moves rows out of
   a visit, the visit keeps its id for the rows that remain; the moved rows join or start
   another visit, and references to the old visit (`partOf` on revisit Tasks,
   `referring-task` on referrals) are updated through the index. A visit left with no rows
   is deleted. Resource ids are built from `clientReferenceId`, never switched to the
   server `id` after sync; the server `id` is an identifier.
3. **Registration.** A `ProjectBeneficiary` from a separate registration phase maps to a
   register Task with `registered-count`, `voucher` and `entitlement`; one registered
   during the delivery visit adds to that visit Task's `registered-count`. The voucher
   (`tag`) is not stored on the Group or Patient.
4. **Project targets.** `Project.targets.target` is mapped to an at-risk denominator only
   where the tenant confirms it is the eligible population. Where it is a performance goal
   (for example 80 % of eligible people) it is specific to that campaign and area, so it
   maps to a `Goal` resource referenced from the campaign's `CarePlan.goal`
   (`target.measure`, `target.detailQuantity`, `addresses` the geography in a note or
   extension), not to the shared protocol's `goal`. Project-target Groups get
   `denominatorSource` from the campaign's configuration where it names the source,
   `govt-estimate` only where the figure is known to be official, and `unknown`
   otherwise. `estimateDate` is left absent when unknown; the import date is provenance,
   not the estimate date.

The DIGIT entities that had no target now map as follows: `isHeadOfHousehold` →
`relationship-to-head = head` (first head) or `co-head`; `relationshipType` →
`relationship-to-head` where the relative is the reference head; `Referral` →
`ICRReferral`; `HFReferral` → `ICRReferralFulfilment`; household targets →
ICRTargetPopulation with `unit-of-count = household`; `StockReconciliation` →
`ICRStockCount`; `plan_resource` and assumptions → `ICRResourceEstimate`.

## Implementation checklist

- [ ] `extensions.fsh`: `relationship-to-head` (Group.member), `unit-of-count`
      (modifier, Group), `referring-task` (ServiceRequest), `supplied-item` (Observation),
      `stock-count-basis` (Observation), `estimate-basis` (Observation),
      `evaluated-role` (Reference, on MeasureReport.evaluatedResource); add Immunization,
      MedicationAdministration and SupplyDelivery to the context of `campaign-activity`
- [ ] `codesystems.fsh`: `ICRHouseholdRelationshipCS`, `ICRReferralReasonCS`,
      `ICRCountUnitCS`, `ICRResourceTypeCS`; new codes in `ICRTaskOutputTypeCS`
      (`referred-count`, `registered-count`, `registered-household`, `voucher`,
      `entitlement`); `stock-count`,
      `expected-stock-balance`, `campaign-referral` and identifier type `voucher`
- [ ] `valuesets.fsh`: `ICRRelationshipToHeadVS` (with `is-a` filters),
      `ICRReferralReasonVS`, `ICRCountUnitVS`, `ICRResourceTypeVS`
- [ ] `conceptmaps.fsh`: `ICRReferralReasonToSNOMED` with the equivalences above
- [ ] `profiles-population.fsh`: member extension, `icr-du-one-head` and `icr-du-head`
      on ICRDeliveryUnit; `unit-of-count` modifier on ICRTargetPopulation
- [ ] new profiles: `ICRReferral`, `ICRReferralFulfilment`, `ICRStockCount`,
      `ICRResourceEstimate`
- [ ] `profiles-campaign.fsh`: new output slices on ICRCampaignTask
- [ ] `profiles-coverage.fsh`: `denominator` slice and the unit invariant on
      ICRAdministrativeCoverage
- [ ] `measures.fsh`: `icr-household-coverage` (two groups)
- [ ] `examples.fsh`: reference head, co-head and relationships on the example household;
      a referral, its fulfilment, and an HFReferral-only referral; a household target and
      an enumeration estimate; a stock count; an ITN register activity and register Task
      with voucher, and the redeeming distribution; a not-done MedicationAdministration; a
      resource estimate
- [ ] `viewdefinitions.fsh` and `data/views`: `unit` on `IcrTargetPopulation`; event
      status in the coverage views; new views for referrals, stock counts and resource
      estimates if the warehouse needs them
- [ ] [[ig-summary-v2]]: new sections and updated §5.1, §5.2, §4.4, §6, §7, §8 and §13
- [ ] SUSHI and the IG Publisher build pass with no new errors
- [ ] [[digit]]: the corrections above

## Changes after review

Codex reviewed v0.1.0 on Oct 26, 2026 (22 findings). Changes in v0.2.0:

- R4 reference rules: `Observation.derivedFrom` cannot reference SupplyDelivery or Group,
  so stock counts and estimates use `stock-count-basis` and `estimate-basis` extensions;
  `ServiceRequest.reasonReference` cannot reference AdverseEvent, so the adverse event is
  in `supportingInfo`; a planning tool goes in `Observation.device`, not `performer`.
- `unit-of-count` became a modifier extension, because `Group.quantity` counts members of
  `Group.type`.
- Several heads: one reference head (`head`) plus `co-head`, so relationships have one
  anchor; inactive members are excluded from the head rules.
- The relationship value set includes v3 descendants through `is-a` filters, because an
  extensible binding does not by itself make `SON` valid against a value set listing
  `CHILD`.
- SNOMED mappings have stated equivalences and a pinned edition.
- Referral lifecycle and the HFReferral-only case are specified; Organization vs Location
  for the receiving facility is explicit.
- Registration is counted with `registered-count` on any Task; `taskOrigin` keeps its
  meaning; the enumeration estimate no longer sets `isCalculated`.
- Household coverage numerator and denominator are fully specified, and coverage reports
  name their denominator.
- Per-person outcomes use `not-done` delivery events; the visit key includes the campaign
  round and a visit window; a many-to-one source index handles replays and deletions.
- Quantities used in calculations require a numeric value and a coded unit; the loss of
  DIGIT's formula chain is stated.

Codex re-checked v0.2.0 the same day (11 of 22 resolved, 11 partly, 9 new issues).
Changes in v0.3.0:

- `not-done` applies to vaccine and drug events only; a commodity not handed over creates
  no SupplyDistribution (R4 SupplyDelivery has no `statusReason` or not-done status).
- Coverage numerators use events or the Task tally per visit, never both, and count
  distinct people; delivery events name their activity with `campaign-activity`.
- Visit identity is assigned once and stored, not derived from the window; the grouping
  rule is stated as a heuristic; corrections that move rows update references.
- `registered-household` output so site-session and household-only registrations count;
  residence filter on the registration numerator; a per-campaign `taskOrigin` default.
- Referral merges need a unique match on person, facility, round and reason; the merged
  request is `revoked`, not `entered-in-error`, and keeps the HFReferral identifier.
- Reference-head changes re-code or clear the other members' relationships; the reference
  head is chosen once; both head invariants use one definition of an active member.
- Unknown estimate dates stay absent; `unknown` source unless the figure is official;
  campaign-specific performance goals go on `CarePlan.goal`, not the protocol.
- ConceptMap notes go in `target.comment` (R4 `cmd-1`).
