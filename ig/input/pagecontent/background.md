### Design rationale

This IG encodes the analysis in the ICR working design document (*ICR FHIR
Implementation Guide — Campaign Data Model & Structure*). The essentials:

#### Campaigns differ by delivery model, not disease

The delivery strategy — not the disease — determines the level at which a single
record is created and which entities even exist. The coded **delivery strategy**
(`fixed-post`, `temporary-post`, `mobile`, `school`, `house-to-house`,
`community-directed`, `outreach`) records *how* teams deliver; the **delivery
unit** — the target of a Task — records *what* they act on. One rule decides the
delivery unit's type:

- **A delivery unit with members is a Group** (`ICRDeliveryUnit`): a household, a
  community, or a school cohort — each has members and an associated Location (the
  dwelling, the settlement, the school).
- **A delivery unit without members is a Location**: a household *structure* in an
  IRS campaign (nobody is a member of a structure); a church or market serving as a
  temporary service point (people are not members of the site, and the next campaign
  may use a different one); or an area target — a settlement, ward, or district that
  persons are registered to directly when their dwellings are unknown (a ward rolls
  up to its district via `Location.partOf`).

The discriminator is the data, not the kind of place: an enumerated community
register is a Group; an un-enumerated area target is a Location.

Hybrids are the norm (an ITN campaign registers house-to-house and distributes at
posts; measles SIAs add house-to-house mop-up) — which is exactly why **delivery
strategy is a first-class coded attribute of the activity/task**, not of the
campaign.

#### The twelve design decisions

1. **CarePlan is the keystone** — campaigns are population-scale care plans
   (alternatives considered and rejected: custom resource, Encounter, RequestGroup).
2. **PlanDefinition = reusable protocol; CarePlan = execution** — rounds are sibling
   CarePlans under an umbrella via `partOf`. The CarePlan sits at the **reporting
   scope** — the highest level that carries the campaign's global target (typically
   the district round), with that scope's denominator as `subject`. Operational
   sub-units (wards, villages, communities) hang under it through the Location
   hierarchy and their own geography-scoped denominator estimates — they do **not**
   each get a CarePlan, so a district with hundreds of communities is still one
   campaign resource. Child CarePlans are reserved for genuine sub-rounds with
   their own period or reporting obligation. A person is never a CarePlan subject:
   individuals appear only in the delivery events (`Immunization.patient`,
   `MedicationAdministration.subject`).
3. **Task is the operational unit** — one per site-session or per household,
   community, or school-cohort visit;
   `Task.output` holds the visit-level result (the tally). Person-level detail
   lives in the delivery events, not in extra Tasks — and a delivery event does
   not depend on a Task: it stands alone on its patient, its `record-origin`
   flag, and its own campaign link (the standard `event-basedOn` extension,
   constrained to the ICR campaign). Individuals are usually not known in
   advance, so the mainline close-out is a tally; where the visit workflow
   captures the doses, `Task.output` may additionally reference one
   `Immunization` per child vaccinated. Person-level rollups run through Group
   membership (dose → patient → household/community/school cohort), not through
   Task outputs. The
   deliberate exception is **person-targeted follow-up**: a specific missed or
   zero-dose child can spawn a Task whose `for` is that `Patient`. Tasks may be
   **pre-planned** from the microplan or **field-registered** on discovery (an
   unenumerated household found mid-sweep); the required `task-origin` code
   records which — and field-registered counts per area measure how incomplete
   the microplan's enumeration was.
4. **Delivery strategy is a first-class coded attribute** of the activity/task.
5. **Three lineages — planned / delivered / independently-measured — never merged.**
6. **Denominator-first**, with provenance and date on every estimate and coverage figure.
7. **Household / community / school cohort = Group + Location** (the validated Ona
   household pattern, generalized): one `ICRDeliveryUnit` profile serves the
   household, the community, and the school cohort,
   distinguished by the required `group-kind` code, each anchored
   to its Location (dwelling, settlement, or school). Delivery units without
   members (structures, temporary sites, area targets) are Locations, not Groups.
8. **Location is the most-customized resource** — multi-identifier with **GERS as the
   cross-campaign join key** alongside P-codes and national codes, GeoJSON boundaries,
   performance-tuned hierarchy.
9. **Terminology: international codes required, local codes allowed, ConceptMaps bridge.**
10. **Every delivery event is flagged campaign vs routine** (`record-origin`).
11. **Provenance on everything ingested** — lineage is a model feature, not an ETL
    afterthought.
12. **ViewDefinitions are planned, not yet shipped** — SQL-on-FHIR view definitions
    will make the analytics layer as portable as the data model (targeted for the
    next draft; none ship in v0.1).

#### Campaign work vs routine encounters

Campaign delivery is **Task-based**: `Encounter` was rejected for campaign sessions
because site-sessions and household visits are *work*, not patient visits — Task
carries assignment, status, location, and outputs natively, with or without a
`Patient`. Routine delivery keeps its Encounters: where genuine person-level
encounters occur (EIR-grade capture, routine facility visits), `Encounter` remains
available *alongside* the campaign Task. When both lineages land in the same
registry, the required **`record-origin`** code on every delivery event is the
discriminator — campaign records never contaminate routine coverage analytics, and
routine history observed during a campaign (card checks, zero-dose detection) stays
analyzable.

#### Operational vs administrative geography

Polio operational boundaries often differ from routine-immunization catchments (the
Nigeria lesson). The ICR keeps **one containment tree**: every Location — admin unit,
settlement, facility, or operational area — has a single `partOf` parent that fully
contains it. What separates official administrative units from operational geography
is the **`type` code, not tree position**: administrative rollups, official-identifier
rules, and DHIS2 pushes key on `type = admin-unit` and skip typed operational nodes
(`supervisory-area`, `operational-area`), exactly as they already skip settlements and
facilities. An operational area is its own first-class shape (own identity, own
GeoJSON boundary) that attaches at the **lowest admin unit fully containing it** — a
supervision zone inside one district is `partOf` that district; a zone spanning two
districts attaches at the region/state level instead. This trades district-level
attribution of cross-boundary areas for a single, unambiguous, DHIS2-compatible
hierarchy; where district reporting matters, operational areas should be drawn within
district boundaries.

#### Location identity lifecycle: GERS enrichment

GERS is the **preferred** cross-campaign join key, not a required one, because new
and informal locations won't be in Overture at creation time. The expected lifecycle:
a field-registered Location is created with only its internal id (and any national
codes); an **asynchronous enrichment process** later matches it against Overture —
directly, or via the OSM→Overture contribution loop — and appends the GERS
identifier to the existing resource, with FHIR versioning and `Provenance` recording
when and how the match was made. Implementations should record the **Overture
release version** alongside each GERS ID. Open question: whether enrichment jobs may
also *merge* two Locations they discover to be the same place, which folds into the
record-linkage question below.

#### Open design questions

Taken to the FHIR community during IG development: Task granularity at scale
(village vs household); aggregate vs individual delivery records; deep `partOf`
Location hierarchies (6+ levels) and mobile/web performance; coverage as
MeasureReport vs Observation; denominator provenance representation; GeoJSON on R4
Location; Task `for` by delivery model; population-scale access patterns (Bulk Data,
Group-based cohort export); and the conformant record-linkage/deduplication pattern
for cross-campaign household and location identity.

#### Relationship to the WHO IDHC toolkit

The WHO AFRO **Integrated Digitization of Health Campaigns toolkit** (WHO + CHAI,
UNICEF co-branded, 2026) defines the reference architecture, use-case taxonomy and
MLE indicator bank for campaign digitization — and deliberately stops short of a
data standard, naming HL7 FHIR (FHIR Questionnaire for forms, FHIR-based aggregate
exchange), GS1 and ICD-11 as the standards solutions should adopt. The ICR IG is
that missing layer: the IDHC shared data registries (georegistry + master lists +
terminology service) map to ICR Location / Practitioner / Group / Patient and the
IG's terminology; the IDHC three-phase lifecycle (planning, readiness and execution,
monitoring and response) is the CarePlan lifecycle; and IDHC vocabulary (beneficiary,
enumerator, refusal, campaign worker, master list) is adopted throughout the IG.
Deliberately out of ICR scope, with the toolkit as the reference: training, payments,
grievance redressal, device management and costing.

#### Relationship to WHO SMART Guidelines

The ICR IG declares its relationship to the WHO SMART Immunizations IG and the
Immunization DAK rather than evolving in parallel: it reuses DAK core data elements
and indicator definitions where they overlap, aligns profile conventions where
campaigns meet routine immunization (zero-dose detection, catch-up enrolment), and is
authored with the same FSH / SUSHI / IG Publisher toolchain.
