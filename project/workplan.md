---
title: ICR Project Workplan
type: deliverable
status: v1.0 — initial deliverable
client: UNICEF
duration_months: 17
start: 2026-05
end: 2027-09
tags: [icr, workplan]
---

# Integrated Campaign Registry (ICR) — Project Workplan
`v1.0 · Prepared for UNICEF · Jul 2026`

### Phase timeline
| Phase | Months | Calendar | Focus |
| --- | --- | --- | --- |
| **1** | M1–2 | May–Jun 2026 | HL7 FHIR Implementation Guide |
| **2** | M3–6 | Jul–Oct 2026 | Platform development + two-country pilot |
| **3** | M7–12 | Nov 2026–Apr 2027 | Capacity building, SOPs, documentation |
| **4** | M13–17 | May–Sep 2027 | Global & national reporting alignment (JAP) |
| **5** | M13–17 | May–Sep 2027 | Systems integration (DHIS2, warehouse, Microplanner) |
| **6** | M13–17 | May–Sep 2027 | Sustainability, handover, replication toolkit |

> Phases 4, 5 and 6 run **concurrently** across M13–17.
## Project governance (cross-cutting)
- **Weekly** check-ins with the UNICEF project contact and HQ focal points
- **Bi-weekly** sprint demos during active development phases (Phases 2 and 5)
- **Quarterly** steering-committee reviews with the broader stakeholder group
- **Phase-gate review** at the end of each phase before proceeding
- Two-week Agile sprints throughout, on a shared project-management platform

* * *
## Phase 1 — HL7 FHIR Implementation Guide (M1–2)
Goal Produce the FHIR Implementation Guide (IG) that underpins the whole system. **Deliverables:** (a) project workplan, (b) draft IG, (c) data-element & reporting-requirements specification, (d) revised IG endorsed for pilot.

**Stages:** Inception & campaign data review (Wk 1–3) → Draft IG authoring (Wk 3–6) → Revision & endorsement (Wk 6–8).

**Activities**

1. Project inception with UNICEF; workplan and stakeholder-engagement plan signed off *(deliverable a)*
2. Obtain and review data from 3–4 existing campaigns (NTD MDA, immunization, polio, malaria); catalogue the data elements *(c)*
3. Synthesize a canonical campaign data model — target populations, households, locations, services, commodities, teams, metadata *(c)*
4. Define real-time vs. campaign-close data components, with rationale *(c)*
5. Map terminology and ValueSets (CVX, WHO ATC, GS1 GTIN, EML); plan ConceptMaps for local code alignment *(b, c)*
6. Profile FHIR R4 resources on the CarePlan architecture (PlanDefinition, ActivityDefinition, Task, CareTeam, Group, and the delivery-event resources) *(b)*
7. Extend the Location resource — GeoJSON boundaries and multi-system identifiers (P-codes, Overture GERS, national codes) *(b)*
8. Author the IG in FHIR Shorthand with automated build and validation on every change *(b)*
9. Test data conformance by converting real campaign datasets into the model; log gaps *(b)*
10. Publish the v0.1 draft IG — versioned, browsable, public repository *(b)*
11. Circulate the draft for stakeholder and FHIR-community review (MoH, UNICEF, WHO, ESPEN, partners); track feedback openly *(b, d)*
12. Incorporate feedback and publish the revised IG endorsed for pilot, with changelog *(d)*

**Status note (Jul 2026).** The v0.1 draft IG is built and published for partner review and feedback, together with a companion summary document — activities 1–10 are complete and the stakeholder-review cycle (11–12) is underway.

**Key dependencies:** UNICEF facilitates timely access to campaign datasets; stakeholder availability for the review window; sufficient campaign data quality.

* * *
## Phase 2 — ICR Platform Development & Deployment (M3–6)
> [!abstract] Goal Build, deploy and validate the reference solution in the **two pilot countries**, working in two-week sprints. In-country trips (subject to UNICEF approval) double as prototype testing and initial hands-on training. The data warehouse and DHIS2 integration are Phase 5.

**Cadence:** M3–4 first-country pilot → M5 pilot feedback & v2 update → M6 second-country deployment.

**Activities**

1. Stand up the FHIR store in the agreed cloud environment; load IG profiles, extensions, and terminology
2. Deploy the data-browsing, validation and quality-management layer
3. Build data-collection connectors for the first country's two campaigns (ODK / DHIS2 Tracker / CommCare → FHIR) and test end-to-end loading
4. Configure deduplication and data-quality functions for the first country's data (cross-campaign household/location dedup)
5. First-country visit — end-to-end testing with live data, cross-campaign reuse validation, user acceptance testing, hands-on MoH/country-office training
6. Document the first country's integration workflows (data-flow diagrams, connector configuration, data-quality procedures)
7. Produce the v2 IG and system update from pilot feedback (model gaps, edge cases, performance, usability)
8. Deploy v2 in the second country — connectors for its two campaigns, adapted ValueSets/ConceptMaps, Location hierarchy configuration
9. Second-country visit — testing, training and stakeholder engagement (English/French as needed)
10. Assemble the packaged ICR solution — user manual, administration guide, replication documentation, security & data-protection documentation, Apache 2.0 licensing

**Key dependencies:** the endorsed Phase 1 IG; country offices identify the two campaigns per country before M3 and facilitate MoH engagement; campaign schedules overlap the pilot window; country system API availability (with file/bulk-export fallback); written travel approval.

* * *
## Phase 3 — Capacity Building & Training (M7–12)
> [!abstract] Goal Hands-on training begins during the Phase 2 site visits. Phase 3 **formalizes, documents and extends** it into reusable materials so UNICEF and MoH teams can operate the ICR independently.

**Activities**

1. Develop role-based, step-by-step job aids grounded in the pilot workflows (online format)
2. Write SOPs for integrating ICR data across current and future campaigns
3. Produce visual workflow documentation (campaign tools ↔ ICR ↔ DHIS2 ↔ reporting)
4. Write troubleshooting guides for the issues encountered in the pilots
5. Document the training delivered during Phase 2 — attendance and curricula
6. Guide UNICEF planning teams on accessing ICR data for microplanning

**Key dependencies:** a working ICR from Phase 2.

* * *
## Phase 4 — Global & National Reporting Alignment (M13–17, concurrent)
> [!abstract] Goal UNICEF-supported MDA campaigns report in **WHO JAP-aligned** formats, embedded in national reporting cycles so the practice outlives the project.

**Activities**

1. Map ICR data elements to JAP form fields (coverage by admin unit, drug consumption/wastage, demographics, performance indicators) with WHO/ESPEN focal points
2. Configure export modules that generate submission-ready JAP outputs, documented so future JAP changes need no vendor involvement
3. Validate reporting outputs against WHO and national requirements; document the MoH self-service generate-and-submit procedure
4. Establish and document data-access workflows for real-time programme monitoring

**Key dependencies:** an operational ICR with real data; current JAP specifications and validation from WHO/ESPEN; availability of UNICEF data & analytics counterparts.

* * *
## Phase 5 — Systems Integration (M13–17, concurrent)
> [!abstract] Goal The Phase 2 connectors cover data collection. Phase 5 adds **DHIS2**, the **analytics data warehouse**, and the **two-way WHO Geospatial Microplanner** integration.

**Activities**

1. Build the SQL-on-FHIR data-warehouse layer, driven by ViewDefinition resources published in the IG, automated to feed JAP and country reporting
2. Build a bidirectional DHIS2 connector (organisation units, aggregate indicators, import and export) — open, documented, and included in the toolkit
3. Feed ICR FHIR data into geospatial microplanning — catchment areas, population estimates, risk scores, supervisory zones
4. Push microplanning-enriched data back into the ICR FHIR store and test the flow in both directions

**Key dependencies:** a stable ICR with real data; DHIS2 API availability per country (import/export fallback available).

* * *
## Phase 6 — Sustainability & Continuity (M13–17, concurrent)
> [!abstract] Goal Formalize the sustainability designed in from Phase 1 — institutionalize the ICR in national cycles, hand it over to government, and package it for replication.

**Activities**

1. Embed ICR reporting into national MoH reporting cycles (DHIS2/JAP); support directives, SOPs and calendar integration per country
2. Structured system handover — source repositories, CI/CD documentation, and build/deploy instructions to MoH counterparts
3. Deliver the system administration & maintenance guide (FHIR store management, connector monitoring, data-quality procedures, troubleshooting)
4. Assemble the replication toolkit — the published IG with localization guidance, the deployable ICR package, connector templates, and the Phase 3 training materials — public, Apache 2.0

**Key dependencies:** successful Phases 2 and 3; MoH institutional commitment; lessons from both pilots.

* * *
## Scope boundaries
> [!warning] Out of scope (changes require a formal Change Order)
> 
> - No integration with UNICEF internal systems, or custom/bespoke local solutions
> - The ICR does **not** replace data collection tools
> - The consortium does not procure or distribute medicines, run MDAs, or lead microplanning
> - No generation of geospatial source data (footprints, imagery, population estimates) — these are provided by UNICEF, MoH or public sources
> - Deployment is limited to the **two pilot countries**; scale-up is out of scope (the replication toolkit enables it)
> - The 17-month period only; maintenance and support beyond it is an optional extension
> - Data ownership rests with governments; shareability is not guaranteed
