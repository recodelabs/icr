### Integrated Campaign Registry (ICR) Implementation Guide

Public health campaigns — measles–rubella SIAs, polio rounds, NTD mass drug
administration, malaria ITN/IRS, vitamin A supplementation — repeatedly target **the
same communities and the same beneficiaries**, yet each program re-maps the same
villages, re-registers the same households, and re-estimates the same denominators
every round. The ICR inverts this: each campaign becomes a contributor to a
**cumulative, reusable corpus of public health intelligence**, so that data collection
cost compounds across programs and over time.

This Implementation Guide is the "DNA" of that registry. It defines how campaign
semantics — protocols, microplans, denominators, households, delivery events,
coverage — are expressed in **HL7 FHIR R4**, so that interchangeable open-source
components (data collection, transformation, FHIR store, data quality, geospatial
microplanning, analytics) can share one model.

The IG is the FHIR data layer of the **WHO AFRO Integrated Digitization of Health
Campaigns (IDHC) reference architecture** (WHO:AFRO/ARD:2025-10): its shared data
registries — the **georegistry** and master lists (administrative boundaries, health
facilities, schools, health workers, households, **beneficiaries**) and the
**terminology list(s)** — are ICR Location, Practitioner/CareTeam, Group, Patient,
and the IG's code systems, and its content standards (FHIR Questionnaire for data
collection forms, FHIR-based aggregate reporting) are how the ICR ships forms and
coverage. IDHC vocabulary is used throughout: the person receiving an intervention
is a **beneficiary** (the FHIR resource is `Patient` by necessity, but human-facing
language never is), the front-line data collector is an **enumerator**, declines are
**refusals**, and the campaign lifecycle follows the IDHC phases — *campaign
planning*, *campaign readiness and execution*, *campaign monitoring and response*.

#### The architecture in one paragraph

FHIR has no native `Campaign` resource, so the IG profiles existing resources —
the same community-validated approach used for households (`Group` + `Location`).
**CarePlan is the keystone**: [ICRCampaignProtocol](StructureDefinition-ICRCampaignProtocol.html)
(`PlanDefinition`) is the reusable campaign protocol; [ICRCampaign](StructureDefinition-ICRCampaign.html)
(`CarePlan`) is a specific execution that begins as a microplan and evolves into the
execution record; [ICRCampaignTask](StructureDefinition-ICRCampaignTask.html) (`Task`)
is the operational unit — one per site-session or per household, community, or
school-cohort visit — carrying the coded
**delivery strategy** and house-to-house data elements natively; the delivery events —
[ICRImmunizationEvent](StructureDefinition-ICRImmunizationEvent.html),
[ICRMedicationAdministration](StructureDefinition-ICRMedicationAdministration.html), and
[ICRSupplyDelivery](StructureDefinition-ICRSupplyDelivery.html) — each carry their own
campaign link (the standard `event-basedOn` extension) and are permanently
flagged **campaign vs routine** (`record-origin`), with `Task.output` holding the
visit-level tally and optional event references. [ICRDeliveryUnit](StructureDefinition-ICRDeliveryUnit.html)
(`Group` — a household, a community, or a school cohort, the generalized Group + Location pattern) and
[ICRTargetPopulation](StructureDefinition-ICRTargetPopulation.html) (`Group`) carry
people and denominators — every estimate with **source, date provenance, and a
computable geographic scope** — and
[ICRLocation](StructureDefinition-ICRLocation.html) carries the administrative
hierarchy and **geospatial identity**, with Overture Maps **GERS IDs** as the
cross-campaign join key alongside P-codes and national codes. Administrative and
survey coverage are **separate, never-merged lineages**
([ICRAdministrativeCoverage](StructureDefinition-ICRAdministrativeCoverage.html),
[ICRSurveyCoverage](StructureDefinition-ICRSurveyCoverage.html)).

#### The model at a glance

```mermaid
graph TD
  PD["ICRCampaignProtocol (PlanDefinition)"] -->|reusable protocol| CP["ICRCampaign (CarePlan)"]
  PD -->|action| AD["ICRCampaignActivity (ActivityDefinition)"]
  CP -->|operational unit| TASK["ICRCampaignTask (Task)"]
  AD -->|instantiated as| TASK
  TASK -->|"acts on (unit with members)"| DU["ICRDeliveryUnit (Group: household / community / school cohort)"]
  TASK -->|"acts on (no members: site / structure / area)"| LOC["ICRLocation (GERS join key)"]
  DU -->|group-location| LOC
  DU -->|member| PT["ICRPatient (beneficiary)"]
  TASK -->|"Task.output: tally + optional event refs"| EV["Delivery events: ICRImmunizationEvent · ICRMedicationAdministration · ICRSupplyDelivery"]
  EV -.->|"campaign link (event-basedOn)"| CP
  EV -->|"patient / subject"| PT
  TP["ICRTargetPopulation (denominator)"] -.->|denominator| CP
  CP --> AC["ICRAdministrativeCoverage"]
  CP --> SC["ICRSurveyCoverage"]
```

<sub>CarePlan is the keystone: a reusable protocol instantiates each campaign execution, and defines its discrete work types once as [ICRCampaignActivity](StructureDefinition-ICRCampaignActivity.html) definitions that thousands of Tasks instantiate. A Task acts on a delivery unit — a **Group** where the unit has members (household, community, school cohort), a **Location** where it does not (a site, a structure under IRS, an area target) — and closes with a visit-level tally on `Task.output`, optionally referencing events captured in the visit workflow. Each delivery event stands alone: it points at its [ICRPatient](StructureDefinition-ICRPatient.html) (or a delivery-unit Group for register-level capture) and carries its own campaign link via the standard `event-basedOn` extension, so per-round queries never depend on Task wiring; person-level rollups run through Group membership. Denominators and geography flow in from the Group/Location model, and the two coverage lineages stay separate.</sub>

#### Status

This is the **v0.1 draft** produced in Phase 1 of the UNICEF ICR project. It encodes the design rationale of the ICR working design document
(*ICR FHIR Implementation Guide — Campaign Data Model & Structure*); see
[Background](background.html) for the design decisions and open questions. It will be
revised against real campaign datasets (data conformance testing) and FHIR community
review (chat.fhir.org, working-group calls, Connectathons) before pilot use.

Planned for subsequent drafts: SQL-on-FHIR `ViewDefinition` resources (the portable
analytics layer), `ConceptMap` scaffolds for country code localization, `Consent`
guidance, and `Measure` definitions aligned to WHO JAP / ICG / ESPEN reporting
minimums.
