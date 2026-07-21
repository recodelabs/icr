---
version: 0.2.0
last_modified: 2026-07-21T18:40:40Z
tags:
  - icr
  - crosscut
  - sow
  - budget
public: true
comments: true
---

# Crosscut SOW
`v0.2.0 · Last modified Jul 21, 2026 at 2:40 PM EDT`

{>>Rewrite pass. Phase 2 has been restructured around your six proposed activities — the six `c1` comments were the same instruction repeated on each bullet, so they're resolved together. Every relevant item from the old 2.1–2.11 has been folded into one of the six buckets and the old numbering retired; where an old activity moved, the bucket says so. The doc had no frontmatter or version stamp, so I've added them and treated the version you created as v0.1.0 → this pass is v0.2.0. Open questions are in the comments below (budget delta, displaced pilot support, bucket 1 sizing, bucket 6 scoping, ESPEN's home, Phase 5/6 duplicate title).<<}{id="c2" by="claude" at="2026-07-21T18:40:40.000Z"}
# Phase 1: IG Development Support (Months 1–2) - $10,360
Crosscut participates in the FHIR Implementation Guide (IG) design process, contributing domain expertise in geospatial microplanning and campaign data flows.
## 1.1 - IG Review: General review - $4,000
**Lead:** James McKinnon

Support design of the initial HL7 FHIR IG through a detailed review of the draft, providing comments and suggested edits. This includes cross-referencing the data model against typical NTD microplan data, WHO JAP reporting requirements for NTD programs, known CommCare/ODK data models in use by NTD implementing partners, supply chain management requirements.
## 1.2 - IG Review: Crosscut App Integration Requirements - $3,360
**Lead:** Brianna Poulos, Coite Manuel

Review the draft IG from Crosscut's perspective as a geospatial data consumer. Specifically review and provide feedback on:  
• FHIR Location resource extensions for GeoJSON boundary polygons, administrative hierarchies, and multi-identifier systems (P-codes, Overture GERS IDs, national facility codes)  
• CarePlan/Task resource structure for representing campaign execution at geographic units  
• Data elements needed for Crosscut App to generate catchment areas to pass back to ICR (e.g. site coordinates, population data, administrative level assignments)

• Data elements needed for Crosscut App to generate geospatial layers (e.g. travel time isochrone layer) to pass back to ICR (e.g. travel time color thresholds)  
• Terminology ValueSets relevant to microplanning outputs (campaign types, drug/vaccine products, reporting indicators)
## 1.3 - Integration Request/Response Schema Design - $3,000
**Lead:** Brianna Poulos, Sam Hoogewind

Author the technical schema that defines data exchange between the ICR (via OpenFn) and the Crosscut API. This covers:  
• Input schema: structure for pushing geographic hierarchies, geocoded sites, campaign events, and survey data to Crosscut, including required vs. optional fields, coordinate formats, and attribute specifications  
• Output schema: structure for returning catchment area polygons with attributes, accessibility/isochrone layers, and tile references  
• Parameter schema: how external callers specify desired algorithm type (site-based, settlement-based), travel-time/distance limits, population thresholds, and output format preferences  
• Error response schema: validation errors, partial success handling  
• Authentication and authorization model for API access by ICR/OpenFn
# Phase 2: Platform Development and Country Pilots (Months 3–6) - $90,000
{>>**Budget check.** The six activities below total **$90,000** against the original Phase 2 figure of **$89,262** — a **+$738** delta, trivial to absorb but worth truing up. The bigger consequence: because the six buckets consume the whole phase, the old **Country Pilot Support** block (2.12 pilot campaign-data analysis $7,970 · 2.13 on-site Sierra Leone support, up to 10 days in-country, $7,970 · 2.14 second-country deployment support $7,970 = **$23,910**) no longer has a line. Three ways to land it: **(a)** carve pilot support back out and size the six buckets to ~$65K; **(b)** keep the six at $90K and fund Crosscut's pilot participation from Ona's pilot budget instead; **(c)** absorb pilot work into the buckets (validation-against-real-data is already written into 2.5, and country adaptation into 2.2) and accept that the Sierra Leone travel drops. My recommendation is **(b)** if UNICEF will wear it, since it preserves your $40K/$50K intent intact — but the in-country days are the thing I'd least want to lose, so this needs your call rather than a default.<<}{id="c3" by="claude" at="2026-07-21T18:40:40.000Z"}

> [!note] Framing (Matt, Jul 21)
> 
> - I would rather define what are the core APIs that need to be built within crosscut that support the current data model and then support the specific integration work via OpenFN. Don't want to spend the entire budget on API integrations and not adding new functionality to help address the needs of the project.
> - Need to understand the use cases for viewing data within crosscut. I think there is value but we need to discuss how crosscut fits in that capacity.
> - Want to preserve budget for new activities which include the potential of new tools outside of crosscut and/or the new catchment area calculators ideas you showed me.
> 
> In summary — I'd like to do proper walk through of Crosscut platform to understand the proposed integrations and improvements to the project. Ideally I would like to keep the Crosscut platform improvements to ~$40K so we can have ~$50K, for crosscut team to contribute to core tool building and innovations for the project. We can shift this once we have better discussions on role of crosscut platform. Right now the two main things are catchment area generation / data enrichment. Data enrichment can be done generically with a lot of non-proprietary tools so I'm a bit on the fence on that and as an interface for microplanning.
> 
> Main thing is to leverage the Crosscut team to help bring your capabilities and experience to help figure out how to make the ICR work and be adopted. That's the core focus on the grant. I want crosscut platform to play an important role in that but I am hoping to be able to work together to pursue new ideas / opportunities that emerge through this work where we think we can have the most impact.
## Proposed activities
| #   | Activity | Amount |
| --- | --- | --- |
| 2.1 | Strengthening of the Crosscut APIs and internal data models to meet ICR needs | $5,000 |
| 2.2 | OpenFn integrations for ingesting and exporting ICR and enriched data | $10,000 |
| 2.3 | Static asset / map tile generation | $5,000 |
| 2.4 | Crosscut App improvements — to better visualize ICR data | $10,000 |
| 2.5 | Catchment area calculation and sharing | $30,000 |
| 2.6 | New ICR tool development — community identifier / de-duplicator | $30,000 |
|     | **Total** | **$90,000** |

{>>**Does this hit the split you asked for?** Buckets 2.1–2.4 are the *Crosscut platform improvements* line and come to **$30,000**; 2.5–2.6 are *core tool building and innovation* at **$60,000**. You asked for ~$40K / ~$50K. The gap is 2.5 — new catchment approaches are arguably platform work (they run in the Crosscut engine) even though they're genuinely new capability, so where you file it swings the ratio by $30K. If you want the stated $40K/$50K exactly, the cleanest lever is moving ~$10K from 2.5 into 2.1/2.4. Tell me which reading you want and I'll re-cut the numbers.<<}{id="c4" by="claude" at="2026-07-21T18:40:40.000Z"}

This is the core development phase. Crosscut strengthens its APIs and internal data model to carry ICR concepts, builds the OpenFn-mediated exchange with the ICR FHIR store, improves how ICR data is visualized, and — the majority of the budget — develops new campaign-planning capability: additional catchment approaches with a sharing model, and a new open tool for community identity and de-duplication. Development follows two-week Agile sprints coordinated with Recode Labs.
### 2.1 — Strengthening of the Crosscut APIs and internal data models to meet ICR needs - $5,000
**Lead:** Sam Hoogewind

**Note - 1.3 can be part of this.**

Make the Crosscut data model able to hold what the ICR carries, and make the platform's existing capabilities callable by machines rather than only by frontend users. This is deliberately about the *core* API and model — the ICR-specific plumbing lives in 2.2.

Technical scope:  
• Extend the internal data model to store concepts Crosscut does not hold today: **campaign events** (doses administered, commodities distributed, coverage results) and **survey/assessment results**, each associable with land blocks, catchment areas, and admin units  
• Generalize the geographic-hierarchy and site models so externally-sourced admin hierarchies (admin levels 0–5, boundary versions, land-block associations) and geocoded sites load without bespoke per-country handling, including multi-identifier support — P-codes, Overture GERS IDs, national facility codes *(absorbs old 2.1, 2.2)*  
• Ingest validation: coordinate integrity, hierarchy consistency (no orphaned nodes), polygon validity, duplicate site detection
### 2.2 — OpenFn integrations for ingesting and exporting ICR and enriched data - $10,000
**Lead:** Sam Hoogewind (Crosscut), with Ona OpenFn support · Emmanuel Koh (ESPEN)

Build the actual exchange between the ICR FHIR store and Crosscut as OpenFn jobs, against the schema authored in 1.3. Keeping this in OpenFn rather than in bespoke Crosscut endpoints means the mapping is inspectable, versioned, and reusable by other ICR consumers.

Technical scope:  
• **Inbound jobs** reading FHIR from the ICR store and loading Crosscut: `Location` (admin hierarchy with GeoJSON boundaries; facilities, schools, community distribution sites), `Task` / `Immunization` / `MedicationAdministration` / `SupplyDelivery` / `Observation` (campaign events), and survey/assessment results *(absorbs old 2.1–2.4 ingestion paths)*  
• **Outbound jobs** writing Crosscut's enriched outputs back as FHIR: catchment polygons with attributes (assigned sites, population estimates, area, admin assignments), population estimates at catchment/admin level, accessibility layers, and supply-plan parameters derived from population estimates *(absorbs old 2.7)*  
• Support for incremental updates between campaign rounds, and for partial results during an active campaign as well as post-campaign reconciliation  
• Production hardening: error handling and retry for failed ingestion or analysis jobs, idempotent re-runs, partial-success semantics, monitoring and alerting on pipeline health, performance for large-country datasets *(absorbs old 2.10)*  
• **Two-way WHO ESPEN Geospatial Microplanner flow** over the same pipeline — ICR facility locations, survey data and campaign targets into the Microplanner to define catchment areas, assign population estimates, calculate risk scores and delineate supervisory zones; Microplanner outputs (catchment areas, population estimates, treatment plans, supply estimates) back into the ICR FHIR store. Leverages Emmanuel Koh's existing ESPEN API and boundary-matching work across 40+ countries; both endpoints are within Crosscut's technical control, which materially lowers integration risk *(absorbs old 2.9)*
### 2.3 — Static asset / map tile generation - $5,000
**Lead:** Sam Hoogewind

Produce map assets that work without Crosscut's Lambda tile server, so ICR geospatial outputs survive offline, low-connectivity, and third-party rendering contexts.

Technical scope:  
• Extend the existing tile pipeline to emit downloadable **static tile packages** — MBTiles, PMTiles, or equivalent *(absorbs old 2.8)*  
• Package catchment boundaries, population layers, and travel-time/accessibility heatmaps for offline field use  
• **Static export of accessibility/isochrone layers** — walking/driving isochrones with configurable time bands — as GeoJSON/FlatGeobuf for consumers that cannot take tiles; today this data is generated but reachable only by authenticated Crosscut frontend users.  
• Distribution via the ICR or direct download; the specific format is chosen against how downstream consumers (DHIS2 Maps, IASO, ODK) will render it.
### 2.4 — Crosscut App improvements — to better visualize ICR data - $10,000
**Lead:** Coite Manuel, Sam Hoogewind

Make the Crosscut App a useful reading surface for ICR data, not only a place where catchments are computed. Scope is deliberately held open pending the platform walkthrough and the "who is looking at this, and to decide what?" question raised in the framing above.

Technical scope:  
• Bring ICR-sourced campaign data into the App as viewable layers: coverage by admin unit and by catchment, doses and commodities delivered, missed or under-covered areas, and round-over-round comparison  
• Surface survey and assessment layers alongside catchments as inputs to risk scoring and prioritization  
• Make ICR-scoped accessibility/travel-time layers visible to the intended audiences (MoH microplanners, UNICEF DAPM) outside of Cross rather than only to Crosscut account holders  
• Support improvements to microplanning workflows.
### 2.5 — Catchment area calculation and sharing - $30,000
**Lead:** Sam Hoogewind, James McKinnon

Develop **at least two new catchment delineation approaches** beyond the current engine, and build the sharing model that lets a catchment computed once be reused by the next campaign — which is the ICR thesis applied to geospatial artifacts.

Technical scope:  
• **New approaches (≥2)**, selected in the platform walkthrough from candidates including: population-threshold balancing, workload-balanced delineation (structures-per-operator-day, households-per-CDD-day), travel-time-constrained catchments, settlement-based delineation refinements, and supervisory-zone delineation for MDA  
• **Parameterized, on-demand execution**: algorithm type, travel-time (minutes) and distance (km) limits, target population and workload targets, geographic scope (boundary ID, admin-level restriction), against previously ingested sites and boundaries  
• **Sharing model**: stable identifiers for catchment areas, versioning across campaign rounds and boundary versions, provenance (which algorithm, which parameters, which inputs), and export in the formats downstream tools consume — so a catchment is a reusable registry artifact rather than a one-off job output  
• **Validation** against known facility service areas using real pilot-country geography and campaign data, feeding corrections back into the algorithms.
### 2.6 — New ICR tool development - eg. community identifier / de-duplicator - $30,000
**Lead:** TBD (Crosscut), with Ona

Build a new, standalone, non-proprietary tool addressing the identity problem underneath every campaign dataset: the same settlement or community appears under different names, spellings, languages, and codes across rounds, partners, and source systems, which is what makes cross-campaign data reuse fail in practice. This is the clearest "new tool outside of Crosscut" opportunity in the SOW and is sized accordingly.

Technical scope:  
• **Community identifier assignment**: mint and maintain stable identifiers for settlements/communities, reconciled against existing identifier systems — national P-codes, Overture GERS IDs, DHIS2 org unit IDs, health facility codes  
• **Matching and de-duplication** across incoming datasets: fuzzy name matching across languages and transliterations, geometry and proximity matching, and detection of the same place arriving under multiple codes  
• **Human-in-the-loop review** for ambiguous matches — a reviewer UI with accept/reject/merge and an audit trail, since fully automatic matching is not credible at national scale  
• **FHIR-native output**: reconciliation published as `Location` identifiers plus ConceptMap-style crosswalks, so the resolved identity lands in the ICR and is available to every downstream consumer rather than staying inside a tool  
• Delivered as an **open component usable independently of the Crosscut platform**

{>>**This is the largest single line and the least specified — it needs a scoping session before it can be committed to.** Three questions decide its shape: **(1)** What is the unit of identity — settlement/village, household, or health facility? The forms corpus shows the pain at all three levels but the tool is very different in each case. **(2)** Is this reconciling *within* the ICR (records arriving from several campaigns) or *against an external authority* (national gazetteer, Overture GERS)? **(3)** Who operates it — is it a service the ICR runs continuously, or a batch tool a country team runs at the start of a campaign round? Related evidence: [[crosscut-forms]] §5 documents the same concept appearing in EN/FR/PT across 33 real forms (`Fokontany` / `Colline` / `Tabanca` / `Arrondissement`, plus outright spelling drift like `Health Distrcit`), which is the strongest argument that this tool is worth $30K.<<}{id="c9" by="claude" at="2026-07-21T18:40:40.000Z"}
# Phase 3: Capacity Building and Training (Months 7–12) - $9,620
Phase 3 focuses on documentation and training materials for the integration components that Crosscut is responsible for. In-country training is delivered during the Phase 2 pilot trips; this phase formalizes those learnings into reusable materials.
## 3.1 — Integration Technical Documentation - $3,000
**Lead:** Sam Hoogewind, James McKinnon

Develop technical documentation for the Crosscut integration components:  
• API reference documentation for all new endpoints (request/response formats, authentication, error codes)  
• Data flow diagrams showing the complete pipeline from ICR → Crosscut → ICR/downstream  
• Configuration guide for adapting the integration to new countries (boundary versions, admin levels, parameter defaults)  
• Troubleshooting guide for common integration issues
## 3.2 — Microplanning Workflow Guidance - $6,620
**Lead:** James McKinnon

Provide guidance to UNICEF DAPM teams on accessing and using ICR data for microplanning purposes through the Crosscut platform.  
• Document how catchment areas, population estimates, and accessibility layers generated through the ICR integration can be used for campaign microplanning  
• Support DAPM in establishing data access workflows
# Phase 4: Global and National Reporting Alignment (Months 13–17) - $4,440
Crosscut supports the alignment of ICR outputs with WHO Joint Application Package (JAP) reporting formats and national reporting requirements.
## 4.1 — JAP Output Coordination for NTD/MDA Reporting - $4,440
**Lead:** James McKinnon

Work with Recode, WHO, and ESPEN focal points to map ICR outputs to specific JAP form fields.

• Map data elements (coverage by administrative unit, population denominators, drug consumption and wastage, demographic breakdowns) to JAP reporting fields  
• Support configuration of export modules that generate JAP-compatible outputs from enriched ICR data
# Phase 5: Sustainability and Continuity (Months 13–17) - $0
{>>Phase 5 and Phase 6 carry the same title. Per the proposal, Phase 5 is *Systems Integration* and Phase 6 is *Sustainability and Continuity* — I've left the text alone since it's outside what you asked for, but the Phase 5 heading looks like a copy/paste error. Want me to retitle it, or drop the $0 phase entirely?<<}{id="c10" by="claude" at="2026-07-21T18:40:40.000Z"}
# Phase 6: Sustainability and Continuity (Months 13–17) - $11,840
## 6.1 — Integration Maintenance Documentation - $4,000
**Lead:** Sam Hoogewind, James McKinnon

Deliver system maintenance documentation for the integration components:  
• Source code repository documentation (build/deploy instructions, CI/CD pipeline)  
• System administration guide for the integration API endpoints  
• Runbook for common operational tasks (adding new countries, updating boundaries, troubleshooting failed jobs)
## 6.2 — Replication Toolkit Contributions - $4,000
**Lead:** James McKinnon

Contribute Crosscut-specific components to the project's replication toolkit for expansion to additional countries:  
• Country configuration templates (boundary versions, admin levels, parameter defaults)  
• Integration connector templates for the Crosscut API  
• Documentation of country-specific adaptations from both pilot deployments  
• Guide for setting up Crosscut's geographic data pipeline for new countries
## 6.3 — Ongoing Technical Support - $3,840
**Lead:** Coite Manuel, James McKinnon

Provide ongoing strategic advisory and technical support throughout the sustainability phase:  
• Participate in stakeholder engagement and steering committee activities  
• Support system handover to MoH technical counterparts  
• Advise on institutionalization of the integration within national reporting cycles
