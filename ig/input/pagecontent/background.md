### Design rationale

This IG encodes the analysis in the ICR working design document (*ICR FHIR
Implementation Guide — Campaign Data Model & Structure*). The essentials:

#### Campaigns differ by delivery model, not disease

The delivery strategy — not the disease — determines the level at which a single
record is created and which entities even exist. The program scope collapses into
three campaign types, plus routine immunization as the substrate:

| Type | Delivery unit & level of record | Examples |
|---|---|---|
| **A. Fixed-post / outreach vaccine SIA** | Site → *site-session* | Measles–rubella, HPV, yellow fever PMVC, OCV, vitamin A |
| **B. House-to-house rapid delivery** | Household → *household visit* | Polio, OCV mop-up, IRS, ITN registration |
| **C. Community / MDA preventive chemotherapy** | Community → *treatment register entry* | LF, oncho, schisto, STH, trachoma |

Hybrids are the norm (an ITN campaign is B then A; measles SIAs add B-style mop-up) —
which is exactly why **delivery strategy is a first-class coded attribute of the
activity/task**, not of the campaign.

#### The twelve design decisions

1. **CarePlan is the keystone** — campaigns are population-scale care plans
   (alternatives considered and rejected: custom resource, Encounter, RequestGroup).
2. **PlanDefinition = reusable protocol; CarePlan = execution** — rounds are sibling
   CarePlans under an umbrella via `partOf`.
3. **Task is the operational unit** — one per site-session (A) or household (B);
   delivery events hang off `Task.output`.
4. **Delivery strategy is a first-class coded attribute** of the activity/task.
5. **Three lineages — planned / delivered / independently-measured — never merged.**
6. **Denominator-first**, with provenance and date on every estimate and coverage figure.
7. **Household = Group + Location** (the validated Ona pattern).
8. **Location is the most-customized resource** — multi-identifier with **GERS as the
   cross-campaign join key** alongside P-codes and national codes, GeoJSON boundaries,
   performance-tuned hierarchy.
9. **Terminology: international codes required, local codes allowed, ConceptMaps bridge.**
10. **Every delivery event is flagged campaign vs routine** (`record-origin`).
11. **Provenance on everything ingested** — lineage is a model feature, not an ETL
    afterthought.
12. **ViewDefinitions ship in the IG** — the analytics layer is as portable as the
    data model (planned for the next draft).

#### Open design questions

Taken to the FHIR community during IG development: Task granularity at scale
(village vs household); aggregate vs individual delivery records; deep `partOf`
Location hierarchies (6+ levels) and mobile/web performance; coverage as
MeasureReport vs Observation; denominator provenance representation; GeoJSON on R4
Location; Task `focus` by campaign type; population-scale access patterns (Bulk Data,
Group-based cohort export); and the conformant record-linkage/deduplication pattern
for cross-campaign household and location identity.

#### Relationship to WHO SMART Guidelines

The ICR IG declares its relationship to the WHO SMART Immunizations IG and the
Immunization DAK rather than evolving in parallel: it reuses DAK core data elements
and indicator definitions where they overlap, aligns profile conventions where
campaigns meet routine immunization (zero-dose detection, catch-up enrolment), and is
authored with the same FSH / SUSHI / IG Publisher toolchain.
