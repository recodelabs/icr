---
title: ICR Profiles and Their Base Resources
status: reference note — how StructureDefinitions work and which core resource each ICR profile builds on
last_modified: 2026-08-11T21:55:00Z
tags:
  - icr
  - fhir
  - ig
  - reference
---

# ICR Profiles and Their Base Resources
<sub>`Reference note · Aug 11, 2026`</sub>

A short reference for how the ICR IG's profiles relate to core FHIR. Companion background: [[ig-summary]] §3 explains how to read a profile; this note explains the machinery underneath.

## What a StructureDefinition is

A **StructureDefinition is itself a FHIR resource**. Its content describes the shape of other resources: a list of elements, each with a path, a cardinality, a data type, and (for coded elements) a binding. FHIR is self-describing — the rules travel as data.

The same resource type plays three roles:

1. **Base resource definitions.** HL7 defines every core type (`Patient`, `Task`, `Immunization`…) as a StructureDefinition with `derivation: specialization`. Only HL7 can create new resource *types* — a third-party `resourceType: "Campaign"` would be rejected by every standard FHIR server and validator.
2. **Profiles.** A profile is a StructureDefinition with `derivation: constraint` and a `baseDefinition` pointing at the type it tightens. It can only narrow — require optional elements, restrict reference targets, bind ValueSets, fix values, add extensions. Profiled data therefore always remains valid plain FHIR.
3. **Extensions.** Each extension (`record-origin`, `dose-pole-band`, …) is its own StructureDefinition of `type: Extension`. The `url` in an instance points at it.

**How an instance connects:** the instance carries a claim, not the rules — `meta.profile: ["…/StructureDefinition/ICRMedicationAdministration"]`. A validator resolves that canonical URL, loads the StructureDefinition, and checks the instance element by element.

**The inheritance chain** (worked example):

```
ICRMedicationAdministration              (ICR IG · derivation: constraint)
  └─ MedicationAdministration            (HL7 core · specialization — the clinical shape)
       └─ DomainResource                 (text, contained, extension slots)
            └─ Resource                  (id, meta — meta.profile lives here)
```

**Toolchain:** FSH (`Profile:` in `ig/input/fsh/`) → SUSHI compiles to StructureDefinition JSON → IG Publisher renders the pages and validates every example against the snapshot. The published package `unicef.fhir.icr` is, at heart, a set of StructureDefinitions plus terminology resources.

## When to profile vs when you cannot

A profile + extensions is what you use when a concept has **no core resource** (there is no `Campaign` — so ICR constrains `CarePlan`) or when you need an **existing resource tightened** for one use-case (ICR's `MedicationAdministration` for MDA). Two escape hatches exist but are rarely the right answer: **logical models** (`kind: logical` — arbitrary shapes for design/mapping, never exchanged as instances; WHO DAK data dictionaries use these) and the **`Basic`** resource (wire-legal but semantically opaque; last resort).

## The 18 ICR profiles and their hosts

| ICR profile | Built on (baseDefinition) | Notes |
| --- | --- | --- |
| ICRCampaignProtocol | PlanDefinition | The reusable campaign template. |
| ICRCampaign | CarePlan | FHIR has no Campaign resource; CarePlan is the chosen host (see background.md design decision #1). |
| ICRCampaignActivity | ActivityDefinition | The work definition (product, dose). |
| ICRCampaignTask | Task | The operational unit of work. |
| ICRCareTeam | CareTeam | Delivery team + supervisor. |
| ICRSupervisionReport | QuestionnaireResponse | Structured supervision checklist answers. |
| ICRDeliveryUnit | **Group** | Same host as below — split by fixed `actual = true` (a real, enumerable group). |
| ICRTargetPopulation | **Group** | Fixed `actual = false` (a conceptual denominator cohort). |
| ICRLocation | Location | Admin hierarchy + geospatial identity. |
| ICRPatient | Patient | The registered individual. |
| ICRFacilityOrganization | Organization | The accountable facility entity (mCSD pairing with ICRLocation). |
| ICRImmunizationEvent | Immunization | A campaign vaccine dose. |
| ICRMedicationAdministration | MedicationAdministration | An MDA drug administration. |
| ICRSupplyDelivery | SupplyDelivery | A commodity/stock custody transfer. |
| ICRAdverseEvent | AdverseEvent | One profile serves AEFI and MDA pharmacovigilance. |
| ICRAdministrativeCoverage | **MeasureReport** | Same host as below — fixed `coverage-source = administrative`. |
| ICRSurveyCoverage | **MeasureReport** | `coverage-source` bound to the survey-only ValueSet, which excludes `administrative` — so the two can never merge. |
| ICRConsent | Consent | Person-data governance. |

## The doubled-host idiom

Two base resources each carry **two** ICR profiles: `Group` and `MeasureReport`. In both cases, fixed values make the pair mutually exclusive (`Group.actual` true/false; the coverage-source codes). This is the standard profiling idiom for "we need two distinct concepts and FHIR gives us one resource": the same StructureDefinition machinery *splits* a base type instead of just narrowing it. A validator can always tell which profile an instance claims — and the fixed value makes a false claim fail validation.
