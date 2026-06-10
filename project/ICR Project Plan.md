---
title: ICR Project Plan
type: project-plan
status: draft
source: "[[ICR Technical Proposal Ona Final]]"
client: UNICEF
prime: Ona
partner: Crosscut
project_lead: Matt Berg
duration_months: 17
start: 2026-05
end: 2027-09
tags: [icr, planning, linear]
---

# ICR — Project Plan & Summary of Activities
> [!note] Purpose This plan decomposes the [[ICR Technical Proposal Ona Final|technical proposal]] into a phased work breakdown ready to seed **Linear**. Each **phase → Linear milestone**, each **activity → Linear issue** (the `Issues` tables below are the issue backlog). Owners, dependencies, and the proposal deliverable each activity satisfies are tagged inline.
## At a glance
|     |     |
| --- | --- |
| **Client** | UNICEF (system owner; HQ NTD, Community Health, Digital Health, DAPM + ROs/COs) |
| **Consortium** | Ona (prime — IG, platform, integration, PM, training) + Crosscut (geospatial microplanning, DHIS2, ESPEN integration) |
| **Project lead** | Matt Berg (Ona) — PM, system architect, named FHIR IG author |
| **Duration** | 17 months, 6 phases — **May 2026 → Sep 2027** |
| **Pilot countries** | Côte d'Ivoire (Matt Berg in-country lead) + Sierra Leone (Coite Manuel / Clara Burgert) |
| **Core principle** | Standards-based **reference solution**, not a platform. The HL7 FHIR IG is the DNA; components are interchangeable & open source (Apache 2.0). Enhance country systems, don't replace them. |
### Phase timeline
| Phase | Months | Calendar | Focus |
| --- | --- | --- | --- |
| **1** | M1–2 | May–Jun 2026 | HL7 FHIR Implementation Guide |
| **2** | M3–6 | Jul–Oct 2026 | Platform development + 2-country pilot |
| **3** | M7–12 | Nov 2026–Apr 2027 | Capacity building, SOPs, documentation |
| **4** | M13–17 | May–Sep 2027 | Global/national reporting alignment (JAP) |
| **5** | M13–17 | May–Sep 2027 | Systems integration (DHIS2, warehouse, Microplanner) |
| **6** | M13–17 | May–Sep 2027 | Sustainability, handover, replication toolkit |

> Phases 4, 5, 6 run **concurrently** across M13–17.
## Project governance (cross-cutting)
> [!info] Recurring cadence — set up as Linear recurring/cycle items, not one-off issues
> 
> - **Weekly** check-ins with UNICEF project contact + HQ (e.g. Sean Blaschke)
>   
> - **Bi-weekly** sprint demos during active development (Phase 2, 5)
>   
> - **Quarterly** steering committee reviews with broader stakeholders
>   
> - **Phase-gate decision review** at the end of each phase before proceeding
>   
> - Two-week Agile sprints; shared PM platform (Linear); Berg ↔ Manuel sync
>   

* * *
## Phase 1 — HL7 FHIR Implementation Guide (M1–2)
> [!abstract] Goal Produce the IG that is the DNA of the whole system. **Any delay here cascades into Phase 2.** Deliverables: (a) project workplan, (b) draft IG, (c) data-element & reporting-requirements spec, (d) revised IG endorsed for pilot.

**Stages:** Inception & campaign data review (Wk 1–3) → Draft IG authoring (Wk 3–6) → Revision & endorsement (Wk 6–8).
### Issues
| #   | Activity | Owner | Deliverable | Depends on |
| --- | --- | --- | --- | --- |
| 1.1 | Project inception calls with UNICEF; draft & sign off project workplan + stakeholder engagement plan | Ona (Berg) | (a) | —   |
| 1.2 | {==Obtain & review data from 3–4 existing campaigns (NTD MDA SCH/STH, immunization, polio, malaria); catalogue data elements==}{>>Get campaign stuff from Coite.  Try and get sample survey and datasets.  Can have him deidentify. Just need data structure and how locations are handled in particular.<<}{id="c1" by="user" at="2026-06-10T03:28:53.947Z"} | Ona + Crosscut (McKinnon) | (c) | UNICEF data access |
| 1.3 | Synthesize canonical campaign data model (target pops, households, locations, services, commodities, teams, metadata) | Ona | (c) | 1.2 |
| 1.4 | Define real-time vs. campaign-close data components, with rationale per classification | Ona | (c) | 1.2 |
| 1.5 | Map terminology / ValueSets (CVX, WHO ATC, GS1 GTIN, EML); plan ConceptMaps for local code alignment | Ona | (b)(c) | 1.3 |
| 1.6 | Profile FHIR R4 resources on CarePlan architecture (PlanDefinition, ActivityDefinition, Task, CareTeam, Group, Immunization/MedicationAdministration/SupplyDelivery) | Ona | (b) | 1.3 |
| 1.7 | Extend Location resource — GeoJSON boundaries + multi-identifier (P-codes, Overture GERS, national facility codes); address deep-hierarchy performance | Ona + Crosscut | (b) | 1.6 |
| 1.8 | Author IG in FSH; compile via SUSHI + HL7 IG Publisher; configure CI to build & validate every change | Ona | (b) | 1.6 |
| 1.9 | Data conformance testing — convert real campaign datasets into the model; log model gaps | Ona | (b) | 1.8 |
| 1.10 | Publish v0.1 draft IG (versioned, browsable, public GitHub repo) | Ona | (b) | 1.8 |
| 1.11 | Circulate draft for stakeholder + FHIR community review (chat.fhir.org, WG calls, MoH/UNICEF/WHO/ESPEN/partners); track feedback in GitHub | Ona | (b)(d) | 1.10 |
| 1.12 | Incorporate feedback; resolve conformance issues; publish revised IG endorsed for pilot + changelog | Ona | (d) | 1.11 |

**Key dependencies:** UNICEF facilitates timely campaign data access; stakeholder availability for a 2-week review window (Wk 6–8); sufficient campaign data quality.

* * *
## Phase 2 — ICR Platform Development & Deployment (M3–6)
> [!abstract] Goal Build, deploy and validate the reference solution in **two pilot countries** via two-week sprints. Optional in-country trips (≤10 days each, UNICEF-approved) double as prototype testing **and** initial hands-on training. Excludes warehouse & DHIS2 (those are Phase 5).

**Cadence:** M3–4 first pilot (Sprints 1–4) → M5 pilot feedback & v2 update → M6 second-country deployment.
### Issues
| #   | Activity | Owner | Deliverable | Depends on |
| --- | --- | --- | --- | --- |
| 2.1 | {==Stand up FHIR store (HAPI FHIR / Google Healthcare API) in agreed cloud env; load IG profiles, extensions, terminology==}{>>Can do his now.<<}{id="c2" by="user" at="2026-06-10T03:36:00.170Z"} | Ona (Mashuma) | Prototype | Phase 1 (d) |
| 2.2 | {==Deploy Cinder for data browsing, validation & quality management==}{>>Can do this now<<}{id="c3" by="user" at="2026-06-10T03:36:12.177Z"} | Ona | Prototype | 2.1 |
| 2.3 | Build OpenFn connectors for the 2 first-country campaigns (ODK / DHIS2 Tracker / CommCare → FHIR); test loading | Ona | Prototype + workflow docs | 2.1, country campaign ID |
| 2.4 | {==Configure Cinder deduplication & data-quality functions for first-country data types (cross-campaign household/location dedup)==}{>>Might be something OpenFN can do.<<}{id="c4" by="user" at="2026-06-10T03:37:37.593Z"} | Ona | Prototype | 2.2, 2.3 |
| 2.5 | First-country in-country trip — end-to-end testing with live data, cross-campaign reuse validation, UAT, hands-on MoH/CO training | Ona (Berg) + Crosscut | Prototype + Phase 3 training | 2.3, UNICEF travel approval |
| 2.6 | Document first-country integration workflows (data-flow diagrams, connector configs, DQ procedures) | Ona | Workflow docs | 2.5 |
| 2.7 | Produce v2 IG + ICR system update from pilot feedback (model gaps, edge cases, performance, usability); update changelogs | Ona | v2  | 2.5 |
| 2.8 | Second-country deployment of v2 — configure connectors for its 2 campaigns; adapt ValueSets/ConceptMaps; configure Location hierarchy | Ona + Crosscut | Second-country deployment | 2.7, country campaign ID |
| 2.9 | Second-country in-country trip — testing + training + stakeholder engagement (EN/FR as needed) | Ona/Crosscut (Manuel, Burgert) | Second-country deployment + training | 2.8, travel approval |
| 2.10 | Assemble packaged ICR solution — user manual, admin guide, replication tech docs, security/data-protection docs, Apache 2.0 licensing | Ona | Packaged solution | 2.6, 2.8 |

**Key dependencies:** endorsed Phase 1 IG; COs identify the 2 campaigns per country before M3 + facilitate MoH engagement; campaign schedules overlap the timeline; country system API availability (file/bulk-export fallback); written travel approval.

* * *
## Phase 3 — Capacity Building & Training (M7–12)
> [!abstract] Goal In-country training happens in Phase 2 (during site visits). Phase 3 **formalizes, documents and extends** that into reusable materials so UNICEF/MoH can operate the ICR independently.
### Issues
| #   | Activity | Owner | Deliverable | Depends on |
| --- | --- | --- | --- | --- |
| 3.1 | Develop role-based step-by-step job aids grounded in pilot workflows (online format) | Ona (Mutua) | Role guides | Phase 2 |
| 3.2 | Write SOPs for integrating ICR data across current & future campaigns | Ona (Mutua) | SOPs | Phase 2 |
| 3.3 | Produce visual workflow docs (campaign tools ↔ ICR ↔ DHIS2 ↔ reporting) | Ona | SOPs | Phase 2 |
| 3.4 | Write troubleshooting guides for common pilot issues | Ona | Role guides | Phase 2 |
| 3.5 | Document ToT/training delivered in Phase 2 — attendance + curricula | Ona | Training record | 2.5, 2.9 |
| 3.6 | Guide UNICEF DAPM on accessing ICR data for microplanning; make Crosscut platform available if desired | Crosscut + Ona | Microplanning integration doc | Phase 2 |

**Key dependencies:** working ICR from Phase 2.

* * *
## Phase 4 — Global & National Reporting Alignment (M13–17, concurrent)
> [!abstract] Goal UNICEF-supported MDA campaigns report in **WHO JAP-aligned** formats, embedded in national reporting cycles so they survive past the project.
### Issues
| #   | Activity | Owner | Deliverable | Depends on |
| --- | --- | --- | --- | --- |
| 4.1 | Map ICR data elements → JAP form fields (coverage by admin unit, drug consumption/wastage, demographics, performance indicators) with WHO/ESPEN focal points | Ona + Crosscut (McKinnon) | JAP mapping | Phases 2–3 data; WHO/ESPEN |
| 4.2 | Configure ICR export modules to generate submission-ready JAP outputs; document mapping/export so future JAP changes need no vendor | Ona | JAP outputs | 4.1 |
| 4.3 | Validate reporting outputs against WHO + national requirements; document MoH self-service generate/submit procedure | Ona | Validated reporting | 4.2 |
| 4.4 | Establish & document DAPM data-access workflows for real-time monitoring | Ona | DAPM data access | Phase 2; DAPM availability |

**Key dependencies:** operational ICR with real data; WHO/ESPEN current JAP specs + validation (JAP spec changes may trigger a change order); DAPM availability.

* * *
## Phase 5 — Systems Integration (M13–17, concurrent)
> [!abstract] Goal Connectors built in Phase 2 cover collection. Phase 5 adds **DHIS2**, the **data warehouse**, and the **two-way WHO Geospatial Microplanner (Crosscut)** integration.
### Issues
| #   | Activity | Owner | Deliverable | Depends on |
| --- | --- | --- | --- | --- |
| 5.1 | Build SQL-on-FHIR → data warehouse layer driven by ViewDefinition resources (in the IG); automate to feed JAP/country reporting | Ona | Warehouse connector | Phase 2; Phase 4 reqs |
| 5.2 | Build bidirectional DHIS2 connector via OpenFn (org units, aggregate indicators import/export); open, documented, in toolkit | Ona | DHIS2 connector | 5.1; DHIS2 API |
| 5.3 | Crosscut consumes ICR FHIR data (facility locations) → catchment areas, population estimates, risk scores, supervisory zones | Crosscut (Hoogewind) | Microplanner integration | Phase 2 |
| 5.4 | Push Crosscut-enriched data back to ICR FHIR store (bidirectional flow); test ICR↔Microplanner both directions | Crosscut (Hoogewind, Koh) | Microplanner integration | 5.3 |

**Key dependencies:** stable ICR with real data; DHIS2 API availability per country (import/export fallback); Crosscut FHIR readiness (managed internally via joint sprints).

* * *
## Phase 6 — Sustainability & Continuity (M13–17, concurrent)
> [!abstract] Goal Formalize sustainability designed in from Phase 1 — institutionalize in national cycles, hand over to government, package for replication.
### Issues
| #   | Activity | Owner | Deliverable | Depends on |
| --- | --- | --- | --- | --- |
| 6.1 | Embed ICR reporting into national MoH reporting cycles (DHIS2/JAP); support MoH directives/SOPs/calendar integration per country | Ona + UNICEF | Institutionalization | Phases 2–3; MoH commitment |
| 6.2 | Structured system handover — source repo + CI/CD docs + build/deploy instructions to MoH counterparts | Ona | Handover | Phase 2 |
| 6.3 | Deliver system administration & maintenance guide (FHIR store mgmt, connector monitoring, DQ procedures, troubleshooting) | Ona | Handover | 6.2 |
| 6.4 | Assemble replication toolkit — published IG + localization guidance, ICR package + deploy scripts, connector templates (ODK/DHIS2 Tracker/CommCare), Phase 3 training materials; public GitHub Apache 2.0 | Ona | Replication toolkit | Phases 2–5 |

**Key dependencies:** successful Phase 2 & 3; MoH institutional commitment (political will UNICEF influences but vendor can't deliver alone); lessons from both pilots.

* * *
## Scope guardrails (exclusions)
> [!warning] Out of scope — keep off the Linear backlog unless via Change Order
> 
> - No integration with UNICEF internal systems, or custom/bespoke/local solutions.
>   
> - ICR does **not** replace data collection tools.
>   
> - Vendor does **not** procure/distribute medicines, run MDAs, or lead microplanning.
>   
> - No generation of geospatial source data (footprints, imagery, population estimates) — provided by UNICEF/MoH/public sources.
>   
> - Deployment limited to **two pilot countries**; scale-up out of scope (toolkit enables it).
>   
> - 17-month period only; maintenance/support beyond is an optional extension.
>   
> - Data ownership rests with governments; shareability not guaranteed.
>   
> - New requirements outside the ToR → formal **Change Order**.
>   
## Proposed Linear mapping
- **6 milestones** = the 6 phases (with the M13–17 three running concurrently).
  
- **~40 issues** = the activity rows above; use the `#` IDs as a temporary key while creating.
  
- **Labels:** `phase-1`…`phase-6`, `owner:ona` / `owner:crosscut`, `ig`, `platform`, `integration`, `training`, `reporting`, `sustainability`.
  
- **Recurring/cycle items** for governance cadence (weekly check-ins, sprint demos, steering reviews, phase gates).
  
- Suggest a **deliverable label** per proposal deliverable so contract reporting is traceable.
  

> [!todo] Next step Confirm the ICR Linear team + label/status IDs (CLAUDE.md notes these are still TBD — Matt to share), then create milestones + issues from the tables above.
