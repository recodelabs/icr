# Immunization & Mass-Campaign Data Models in Global Health
### A grounded "lay of the land" to inform an implementation guide and a tiered data model for campaigns and microplanning

**Scope.** This report maps how immunization and mass-treatment campaigns are planned, delivered, and recorded in low- and middle-income settings, and the data models that underpin them. It draws on standardized guidance and field manuals from WHO, UNICEF, Gavi, PAHO, the GPEI, GTFCC, ESPEN, and ministries of health, plus peer-reviewed implementation literature.

It covers six delivery programs that, together, span the full range of campaign archetypes you are likely to need to represent:

1. **Routine immunization (EPI)** — the baseline system that campaigns supplement.
2. **Polio** — Supplementary Immunization Activities (SIAs), the most data-intensive house-to-house model.
3. **Measles–rubella** — injectable-vaccine SIAs, the standardized "high-quality SIA" model.
4. **Yellow fever** — preventive mass vaccination campaigns (EYE strategy), all-age targeting.
5. **Oral cholera vaccine (OCV)** — two-dose outbreak/preventive campaigns via the ICG stockpile.
6. **NTD mass drug administration (MDA)** — the household/community archetype (preventive chemotherapy).

> **On the "two tropical diseases."** You mentioned you already have two in scope but didn't name them. I've treated **yellow fever**, **cholera (OCV)**, and **NTD MDA (preventive chemotherapy)** as the most instructive tropical-disease campaign archetypes, because each represents a *distinct* data model (all-age vaccine campaign; multi-dose vaccine campaign with a strong admin-vs-survey coverage gap; and drug-treatment campaigns with community-directed delivery). If your two are specific (e.g. yellow fever + cholera, or two preventive-chemotherapy NTDs), tell me and I'll deepen those sections and trim the rest.

---

## 1. The campaign landscape: three structural models

Almost every campaign you'll model is a variant of one of three structures, and the data model differs accordingly.

**Routine immunization (RI / EPI).** Continuous, facility- and outreach-based delivery of a national schedule to successive birth cohorts. Each child is (ideally) tracked over time. This is the substrate campaigns plug into and, increasingly, the system whose data is reused for campaign planning.

**Supplementary Immunization Activities (SIAs).** Time-bound mass vaccination events that aim to reach many people in a short window *irrespective of prior vaccination status*, to rapidly raise population immunity. The WHO white paper on harmonizing coverage measures defines SIAs as mass events that complement but do not replace routine immunization, usually national but sometimes subnational or outbreak-driven, used for measles, rubella, polio and others. Polio and measles–rubella are the canonical SIAs; yellow fever and cholera campaigns are structurally similar vaccine SIAs.

**Mass drug administration (MDA) / preventive chemotherapy.** Periodic (annual or biannual) treatment of entire at-risk communities with donated medicines, for the five preventive-chemotherapy NTDs. Structurally a campaign, but the "dose" is an oral treatment and delivery leans heavily on community volunteers rather than health workers.

**The single most important cross-cutting fact for your data model:** every program distinguishes **administrative coverage** (doses given ÷ estimated target, from tally sheets) from **survey coverage** (independently measured in a population survey). These routinely diverge — in a pre-emptive OCV campaign in Cuamba, Mozambique, administrative coverage was reported at ~99% while the post-campaign survey found ~76% for the first dose. Your model must represent both as first-class, separately-sourced measures of the same conceptual quantity, never collapse them into one "coverage" field.

---

## 2. Where the standardized manuals live (the canonical guidance)

These are the authoritative documents that define methods, tools, and—critically for you—the recording/reporting forms and data elements. Full URLs in §11.

| Program | Canonical guidance / tools | What it standardizes |
|---|---|---|
| **Microplanning (RI)** | WHO *Microplanning for immunization service delivery using the Reaching Every District (RED) strategy* (2009); *Immunization in Practice* Module 4 (Reaching Every Community); UNICEF/WHO Microplanning e-learning | Health-centre maps, catchment population tables, session plans |
| **Geo-enabled microplanning** | WHO GIS Centre for Health *Geo-enabled Microplanning Handbook* | Population estimation, catchment polygons, site/team georegistry |
| **Measles–rubella SIA** | WHO (2016) *Planning and Implementing High-Quality SIAs for Injectable Vaccines …* (the "SIA field guide") + 8 e-learning modules; *Targeted and selective strategies …* (2025 interim) | Macro/microplan, SIA Readiness Assessment tool, RCM, post-SIA independent monitoring |
| **Polio SIA** | GPEI SIA field guidance; national Pulse Polio / NPHCDA operational guides (e.g. India, Nigeria) | House-to-house tally forms, finger-marking, LQAS, independent monitoring |
| **Yellow fever** | WHO *EYE Strategy*; *Estimating and monitoring yellow fever reactive campaign vaccination coverage: overview of survey and monitoring methods* | PMVC/catch-up/reactive activity types; coverage monitoring |
| **Oral cholera vaccine** | GTFCC *Cholera Outbreak Response Field Manual* §9; WHO *OCV in Mass Immunization Campaigns*; ICG M&E requirements; generic post-campaign coverage survey protocol; **CholTool** costing tool | Two-dose delivery, M&E metrics, cost-per-fully-immunized-person |
| **NTD MDA** | WHO *Guide for preparing a master plan for national NTD programmes*; ESPEN portal & **ESPEN Microplanner**; preventive-chemotherapy guidance | National master plans, treatment registers, program/epi coverage |
| **Coverage measurement** | WHO *Vaccination Coverage Cluster Surveys: Reference Manual* (2018, WHO/IVB/18.09); *Analysis and Use of Health Facility Data: guidance for immunization programme managers* | Cluster survey design, admin-vs-survey consistency checks |
| **Digital systems** | DHIS2 Health Campaigns / Immunization implementation docs; IASO; ESPEN Microplanner | Org-unit hierarchies, datasets, tracker vs aggregate, dashboards |

---

## 3. Delivery models — and the "is it household-level?" question

Delivery strategy is the strongest single driver of the data model, because it sets the **grain** of recording (who/where a record represents) and which entities exist (sessions vs houses vs individuals). The same program often uses several strategies in one campaign.

**Fixed post / fixed site.** Vaccination at a health facility or a designated temporary post; people come to the site. Grain = *site-session*. Dominant for measles–rubella SIAs, yellow fever PMVCs, and OCV.

**Outreach / mobile / temporary post.** Teams set up at schools, markets, places of worship, transit points. Grain = *site-session*, but sites are not facilities, so the data model needs non-facility location entities.

**House-to-house (door-to-door).** Teams systematically visit every dwelling. Grain = *household visit* (and child-within-household). This is the polio model and is used in OCV mop-up and some NTD MDA. It is the only model that natively produces **"houses visited," "children present/absent," and "noncompliance reason"** as data elements.

**School-based.** Treatment/vaccination delivered through schools, targeting school-age children. Heavy in NTD MDA (STH, schistosomiasis) and many MR SIAs. Grain = *school-session*; needs an enrolment denominator and a non-enrolled catch-up channel.

**Community-directed / community-based distribution (CDTI / CDD).** Community-selected drug distributors treat their own communities, either door-to-door or at a central point (community centre, leader's home, market). This is the NTD MDA backbone (originating in onchocerciasis control). Grain = *community register* maintained by a distributor.

**So, is delivery household-level?** It depends on the program:
- **Polio: yes, primarily house-to-house** — the data model is explicitly household-anchored (settlements → households → eligible children), with revised "household-based microplanning" in high-risk areas (e.g. Kano/Kaduna, Nigeria) enumerating settlements, target households and target children to reduce "chronically missed children."
- **Measles–rubella, yellow fever, OCV: primarily fixed-post + outreach**, with house-to-house used selectively for mop-up or hard-to-reach areas.
- **NTD MDA: community/household-level**, but mediated by a community distributor's register rather than a health-worker tally.

A robust implementation guide should make **delivery strategy a first-class attribute** of a session/site, and allow a campaign to mix strategies, because the available data elements change with the strategy.

---

## 4. Microplanning — the planning data model

A **microplan** is, in WHO's words, an integrated set of detailed planning components created to support a public-health activity. It is where target populations, geography, sites, teams, and logistics are defined *before* delivery, and it is the planning half of your data model.

**Canonical microplan components** (from the RED/REC guidance and *Immunization in Practice* Module 4): a health-centre **map** showing every village/community in the catchment (including unreached and new settlements, urban-poor and migrant/displaced settlements, and landmarks such as markets, schools, places of worship), and a paired **table** giving, per community: total population, target population(s), and approximate distance/travel time. To this, campaigns add session/site plans, team rosters, vaccine and cold-chain requirements, transport, social mobilization, and supervision plans.

**Geo-enabled microplanning** is the current direction of travel, formalized in the WHO GIS Centre's *Geo-enabled Microplanning Handbook*. Instead of hand-drawn maps, programs build a geographic foundation of administrative boundaries, **catchment-area polygons**, georeferenced **settlements/structures**, and **vaccination sites**, then attach population estimates. Nigeria's conversion of hand-drawn RI maps to GIS catchments (Bauchi/Sokoto) and Bangladesh's ArcGIS-based EPI microplanning are reference implementations. A notable integration pitfall: in Nigeria, **polio (GPEI) operational boundaries are defined differently from RI catchment boundaries**, so population denominators were not directly transferable between the two — a concrete reason your model should treat "operational geography" and "administrative geography" as linkable-but-distinct.

**Population / denominator estimation** is the hardest part and the usual cause of the admin-vs-survey coverage gap. Sources your model should be able to reference per geography: national census/projections, microcensus/enumeration from the microplan, and modelled gridded estimates — **WorldPop** and **GRID3** (with age–sex breakdowns), plus building/settlement footprints (e.g. from Google/Maxar layers). Catchment denominators are often computed by intersecting these grids with catchment polygons.

**Tooling.** The microplanning data model is now commonly instantiated in:
- **DHIS2** (Health Campaigns / Immunization packages): org-unit hierarchy, catchment polygons imported as GeoJSON or built with the **CrossCut** app, external population layers (GRID3, WorldPop, Google Earth Engine), and campaign-specific sub-district org units.
- **IASO** (georegistry + mobile data collection, integrated with DHIS2): imports DHIS2/GeoPackage/GeoJSON/CSV geographies, lets field teams verify facility locations and catchment boundaries and register households/individuals via XLSForms, and supports **reuse** of microplans/teams/geographies across campaigns.
- **ESPEN Microplanner** (NTDs, WHO AFRO): generates sub-implementation-unit supervisory-area boundaries, travel-time and population heatmaps, flags hard-to-reach settlements, benchmarks collected microplan estimates against public population sources, and integrates with DHIS2 / ESPEN Collect / ESPEN Portal.

---

## 5. Data models by program

Below, for each program: delivery, the recording chain (what's written down, where), and the resulting data elements/indicators.

### 5.1 Routine immunization (EPI) — the substrate

**Recording chain.** Doses are recorded at point of service on (a) the child's **home-based record (HBR)** / child health card, (b) the facility **immunization register**, and (c) **tally sheets**; tallies are aggregated into **monthly facility reports** that flow up the org-unit hierarchy into the national HMIS (overwhelmingly **DHIS2**).

**Two DHIS2 modeling patterns you'll choose between:**
- **Aggregate EPI module** — counts of doses by antigen/dose, by month, by org unit, with age-group disaggregation (commonly 0–11 mo, 12–23 mo, ≥24 mo); plus cold-chain and stock indicators. This is the dominant national pattern.
- **Tracker / immunization eRegistry** — individual longitudinal records: each child registered and followed across the schedule, enabling defaulter tracking, clinical decision support, and derivation of standard EPI indicators from individual data.

**Core indicators / data elements:** coverage by antigen-dose (BCG, Penta1–3, OPV/IPV, PCV1–3, Rota, MCV1/MCV2, etc.); **drop-out rate** (e.g. Penta1→Penta3, or Penta1→MCV1); **zero-dose** children (no DTP/Penta1); missed opportunities for vaccination (MOV). **Data-quality rules** are part of the model: successive doses should not increase (Penta2 ≤ Penta1), co-scheduled antigens should roughly match (Penta1 ≈ OPV1 ≈ PCV1 ≈ Rota1), and outliers (>3 SD) are flagged.

**Why this matters for campaigns:** routine DHIS2 data is now a primary input to campaign microplanning — low-coverage areas, high drop-out, and zero-dose clusters identify where a campaign must focus. Your campaign model should be able to *read* RI coverage/drop-out by org unit as a planning input.

### 5.2 Polio SIA — the house-to-house, most data-intensive model

**Delivery:** primarily house-to-house over a few days (National/Sub-national Immunization Days), plus fixed booths, transit points, and mop-up rounds; OPV (oral) so no injection logistics.

**Recording chain.** Each vaccinator team uses a **tally sheet** recording *children immunized* and *houses visited* (and, on house-to-house days, missed children and **noncompliance**). In the Indian Pulse Polio system this is standardized as Form 8A (and 8C booth / 8D house-to-house), consolidated by supervisors on Form 9A. **Finger-marking** of vaccinated children is the in-field "already done" flag. Microplans enumerate **settlements → target households → target children**.

**Distinctive data elements:** houses visited; children vaccinated; **missed children and reasons** (child absent, sleeping, refusal); **noncompliance reasons** at household level (used in Nigeria to target "unmet needs" interventions); chronically missed settlements.

**Independent monitoring & coverage:**
- **Post-campaign independent monitoring** — monitors go house-to-house collecting from a fixed number of households per area (e.g. 20) on whether children were vaccinated and the information source.
- **Lot Quality Assurance Sampling (LQAS)** — accept/reject sampling to classify whether a lot (area) met a coverage threshold; cheaper than full surveys for "is this area good enough?" decisions.
- **Rapid Convenience Monitoring (RCM)** — quick, non-probabilistic spot checks during/after the campaign to find pockets of missed children for immediate mop-up.

### 5.3 Measles–rubella SIA — the standardized injectable-vaccine model

**Delivery:** mostly **fixed post + outreach** (schools, health posts, temporary sites); injectable, so cold chain, AEFI monitoring, and safe injection/waste are part of the model; house-to-house used selectively.

**Standardized by** the WHO 2016 SIA field guide (explicitly written to generalize to any injectable-vaccine SIA), which supplies the **SIA Readiness Assessment tool** and the monitoring suite: **RCM**, **mop-up**, and **post-SIA independent monitoring**.

**Distinctive data elements:** doses administered by site/day disaggregated by target age band (e.g. 9 mo–14 y in the India MR SIA); **readiness scores** per district/block ahead of the campaign; **reasons for non-vaccination** captured in RCM (the India SIA reported unvaccinated-child reason categories including AEFI fear, not informed, etc.); AEFI line lists. Some SIAs nest serosurveys (e.g. dried-blood-spot collection in Zambia) — a useful pattern if your guide must support integrated specimen/data collection.

### 5.4 Yellow fever — all-age preventive mass vaccination (EYE strategy)

**Delivery:** the EYE strategy (launched 2017) uses four activity types your model should enumerate: **routine infant immunization**, **preventive mass vaccination campaigns (PMVCs)** targeting all/most age groups, **preventive catch-up** campaigns (specific cohorts/subpopulations), and **reactive** outbreak campaigns. PMVCs target a wide age range (commonly 1–60 years), which means your target-population model must support **broad, configurable age bands**, not just under-5s.

**Supply & coordination:** vaccine for outbreak response is released from a global **emergency stockpile managed by the ICG (International Coordinating Group) on Vaccine Provision** — the same mechanism used for cholera, meningococcal and Ebola. Campaign lists are reconciled against ICG records.

**Data systems:** WHO has prototyped a **DHIS2 module for EYE** M&E, and published *Estimating and monitoring yellow fever reactive campaign vaccination coverage* covering survey and monitoring methods. Coverage targets are explicit (e.g. EYE interim/long-term targets of 50/60/80% of the target population) — so your model should store **campaign coverage targets** as data, not just achieved coverage.

### 5.5 Oral cholera vaccine — two-dose campaign via the global stockpile

**Delivery:** **two doses** (commonly ~14-day interval) of a WHO-prequalified killed whole-cell OCV (Shanchol, Euvichol-Plus), via **vaccination posts with teams** plus mop-up; can be reactive (outbreak), preventive (endemic hotspots), or in humanitarian crises. Often delivered through EPI campaign mechanisms without disrupting routine services.

**Supply & coordination:** the **global OCV stockpile** (since 2013) has an emergency component managed by the **ICG** and a non-emergency reserve; Gavi funds it; WHO, UNICEF, MSF and IFRC are partners. The **GTFCC** coordinates strategy.

**Distinctive data model features:**
- **Dose-level coverage** — round 1 and round 2 tracked separately, plus **"fully immunized" (both doses)**; your model must represent multi-dose campaigns with per-round coverage and a derived completion measure.
- **CholTool** — a standardized Excel costing tool producing **cost per fully immunized person**, differentiating financial vs economic costs by activity (procurement, training, microplanning, sensitization, social mobilization, rounds). If your guide tracks campaign costs, this is the reference schema.
- The **admin-vs-survey gap** is especially pronounced here and is the headline cautionary example (Mozambique: ~99% admin vs ~76% survey).
- **ICG M&E requirements** define the minimum reporting set (delivery strategy, target population, request-to-delivery interval, doses, AEFI, coverage, costs) that requestors must return after a campaign — effectively a ready-made minimum data set.

### 5.6 NTD MDA — preventive chemotherapy, the community/household archetype

**Delivery:** annual/biannual treatment of whole at-risk communities for the five **preventive-chemotherapy NTDs** — lymphatic filariasis (LF), onchocerciasis, schistosomiasis, soil-transmitted helminths (STH), trachoma — via **school-based** and **community-based** distribution (door-to-door/household or central point), with **community-directed treatment (CDTI)** by **community drug distributors (CDDs)** as the backbone.

**Recording chain.** CDDs record treatments in **community treatment registers** (by household/individual); these aggregate to implementation-unit (district) **treatment summaries** reported by ministries of health to WHO. National programs operate under a **national NTD master plan** (WHO master-plan guide) with 3–5 year strategy.

**Distinctive coverage concepts** your model must separate:
- **Program (reported) coverage** — number treated ÷ total population targeted.
- **Epidemiological coverage** — number treated ÷ population eligible/at-risk for that disease.
- **Geographic coverage** — proportion of endemic implementation units that conducted MDA.
- Disease-specific **drug-coverage thresholds** (e.g. LF elimination needs sustained ≥65% epidemiological coverage) are stored as targets.

**Data systems:** the **ESPEN portal** (WHO AFRO) curates **district-level endemicity and treatment-coverage data** reported by ministries of health for the five PC-NTDs, and **ESPEN Collect / ESPEN Microplanner** support sub-district microplanning and mapping. Note ESPEN's own documented limitation: coverage and reporting quality depend heavily on local context — another argument for explicit data-provenance/quality fields.

---

## 6. Cross-cutting entities and a proposed tiered data model

Synthesizing the six programs, the common structure is six layers. This is the "tier for representing campaigns and microplanning" you asked for — designed so a single model can express RI, polio, MR, YF, OCV and MDA by configuration rather than by separate schemas.

### Tier 0 — Geography & organizational units
- **AdminOrgUnit** (national → region → district → facility), reusing the national HMIS/DHIS2 hierarchy.
- **OperationalGeography** (campaign-specific units: settlements, neighbourhoods, supervisory areas, sub-IU zones) — *linkable to* but *distinct from* admin units (the Nigeria polio-vs-RI boundary lesson; the Mozambique "neighbourhood" SIA org units).
- **CatchmentArea** (polygon, GeoJSON), associated geometry for a site/facility.
- **Settlement / Structure** (georeferenced point/footprint, incl. urban-poor, migrant, displaced, "hard-to-reach" flags).

### Tier 1 — Population & denominators
- **TargetPopulation** per geography per campaign: source (census, microcensus, WorldPop, GRID3), age–sex bands (configurable: <5, 9 mo–14 y, 1–60 y, all-age, school-age…), eligibility rules, estimate date, confidence/provenance.
- Multiple competing estimates per geography retained for triangulation; one flagged "planning denominator."

### Tier 2 — Microplan & resources
- **Microplan** (per geography, per campaign round): linked map + community table.
- **Site / Post** (facility, outreach, school, transit, house-to-house zone) with **delivery strategy** attribute.
- **Team** (members, roles, assigned sites/zones, daily workload target).
- **ResourceRequirement** (vaccine/drug doses, cold-chain, transport, social mobilization, supervision).
- Reusable across campaigns (IASO/ESPEN pattern).

### Tier 3 — Delivery / encounters (the grain layer)
Model at the *finest grain the strategy supports*, then aggregate up:
- **SiteSessionTally** (fixed-post/outreach/school): date, site, team, doses by antigen-dose × age band; vaccine usage/wastage; AEFI count.
- **HouseholdVisit** (house-to-house): houses visited, children present/absent, vaccinated, **missed + reason**, **noncompliance reason**, finger-marked.
- **CommunityTreatmentRegister** (MDA/CDD): individuals treated by drug × age/sex; directly-observed-treatment flag.
- **IndividualVaccinationEvent** (optional tracker/eRegistry grain): for dose-level longitudinal tracking and multi-round linkage (OCV round 1↔2).

### Tier 4 — Monitoring & coverage
- **AdministrativeCoverage** (doses ÷ planning denominator) — derived, with denominator provenance attached.
- **SurveyCoverage** (cluster survey / LQAS / convenience), with method, sample design (PSU/EA, PPES), date, CI/lower bound.
- **RapidConvenienceMonitoring** (missed-children spot checks; reasons).
- **IndependentMonitoring** (post-campaign household checks; info-source).
- **ReadinessAssessment** (pre-campaign scores per unit — MR SIA pattern).
- **CoverageTarget** (program-defined threshold; e.g. ≥95%, ≥65%, EYE 50/60/80%).

### Tier 5 — Supply, logistics & cost
- **Vaccine/DrugLot** + stockpile source (**ICG**, national, Gavi-funded), shipment, cold-chain.
- **CampaignCost** (CholTool-style: financial vs economic, by activity; **cost per fully immunized/treated person**).

**Three modeling principles the evidence repeatedly points to:**
1. **Separate "planned" from "delivered" from "independently measured."** These are three different data lineages for the same quantities and must never be merged.
2. **Make delivery strategy a first-class attribute** of sites/sessions; it governs which data elements exist.
3. **Attach provenance and a date to every population estimate and coverage figure**, because the credibility of the whole campaign analysis rests on the denominator.

---

## 7. Minimum common data-element inventory

A starter set that recurs across programs (extend per program):

**Campaign metadata:** campaign ID; disease/antigen; activity type (routine / SIA / PMVC / catch-up / reactive / MDA); round number; planned start/end; geography scope; target age band(s); coverage target.

**Microplan:** geography ID; total population; target population + source/date; number of sites by strategy; number of teams; doses/drugs required; cold-chain/transport needs.

**Delivery (per site-day or per household/community):** date; geography; site/team ID; delivery strategy; doses/treatments administered by product × dose × age band × sex; houses visited; eligible present/absent; missed + reason; noncompliance reason; vaccine opened/used/wasted; AEFI count.

**Monitoring/coverage:** administrative coverage (+ denominator source); RCM missed-children %; LQAS lot decision; survey coverage % + CI + method + date; readiness score.

**Supply/cost:** lot/source/stockpile; quantity shipped/received/used; financial & economic cost by activity; cost per fully immunized/treated person.

---

## 8. Coverage measurement & monitoring methods (definitions)

- **Administrative coverage** — doses ÷ estimated target from routine tallies; fast and continuous, but only as good as the denominator.
- **Vaccination Coverage Cluster Survey** — gold-standard population estimate; multi-stage probability sampling (PSU/EA selected by **PPES**), card + recall + facility-record verification; standardized by WHO's 2018 Reference Manual. Also called EPI/Coverage Evaluation Surveys.
- **LQAS** — small-sample accept/reject classification of whether an area met a threshold; efficient for go/no-go decisions, not for precise point estimates.
- **Rapid Convenience Monitoring (RCM)** — non-probabilistic, near-real-time checks to find and fix missed pockets during/just after a campaign.
- **Post-campaign independent monitoring** — house-to-house verification by people not on the delivery teams.
- **External-consistency check** — compare administrative coverage against DHS/MICS/coverage-survey estimates (a core data-quality step in WHO's facility-data guidance).

---

## 9. Key implications for the implementation guide

1. **One configurable model, six expressions.** RI, polio, MR, YF, OCV and MDA differ mostly in delivery strategy, age band, dose count, and product type — all expressible as configuration over the tiered model above, avoiding per-disease schemas.
2. **Multi-round and multi-dose are the norm, not the exception** (polio rounds; OCV two doses; MDA annual cycles). First-class round/dose linkage and a derived "fully covered" measure are required.
3. **Denominator-first.** Build the population/catchment layer with provenance and multiple sources before anything else; it's the dominant source of error.
4. **Plan ↔ deliver ↔ verify as three lineages.** Keep them separate and joinable.
5. **Reuse routine (DHIS2) geography and coverage data** as planning inputs, but model operational geography separately where it diverges (polio).
6. **Align with existing reporting minimums** (ICG M&E set for YF/OCV; ESPEN treatment-coverage schema for NTDs; WHO EPI indicators for RI) so your model maps cleanly onto what ministries already report.
7. **Borrow the established tools' data structures** rather than reinventing: DHIS2 campaign packages (org units, datasets with open/close dates, catchment polygons), IASO (georegistry + XLSForm + reuse), ESPEN Microplanner (supervisory areas, population benchmarking).

---

## 10. Suggested next steps for grounding the guide further

- Pull the **actual recording forms** (polio tally Forms 8A/8C/8D/9A; the MR SIA field-guide monitoring tools; ICG OCV M&E template; an ESPEN treatment register) to extract exact field lists — these become your authoritative data-element dictionary.
- Decide **aggregate vs tracker grain** per program (DHIS2 has reference designs for both).
- Confirm your **two tropical diseases** so I can deepen those (e.g. add MenAfriVac/meningococcal or typhoid conjugate vaccine if relevant, or two specific PC-NTDs with their disease-specific coverage thresholds and registers).

---

## 11. Sources

**Microplanning & geo-enabled planning**
- WHO, *Microplanning for immunization service delivery using the RED strategy* — https://www.who.int/publications/i/item/microplanning-for-immunization-service-delivery-using-the-reaching-every-district-(-red)-strategy
- WHO, *Immunization in Practice*, Module 4 (Reaching Every Community) — https://watch.immunizationacademy.com/storage/documents/22OrBbE1FGbF6LfpvuAne7x6i1IpJdLuTSchDcgL.pdf
- UNICEF/WHO Microplanning e-learning — https://agora.unicef.org/course/info.php?id=6730
- Rocha et al., *Microplanning for designing vaccination campaigns … GeoAI framework*, Vaccine 2021 — https://pubmed.ncbi.nlm.nih.gov/34538526/
- *From paper maps to digital maps: routine immunisation microplanning in Northern Nigeria* — https://pubmed.ncbi.nlm.nih.gov/31321093/
- IASO, *Digitalizing health campaigns* (refs WHO Geo-enabled Microplanning Handbook) — https://www.openiaso.com/iaso-digitalizing-health-campaigns/
- ESPEN Geospatial Microplanner — https://espen.afro.who.int/sites/default/files/content/document/ESPEN%20Geospatial%20Microplanner.pdf
- PAHO, *Microplanning: key component to reduce vaccination gaps* — https://www.paho.org/sites/default/files/paho-cim-microplanning-webinar-english_0.pdf
- WHO, *Guidance on operational microplanning for COVID-19 vaccination* (8-step, geo-enabled) — https://www.who.int/publications/i/item/WHO-2019-nCoV-vaccination-microplanning-2023.1

**Digital systems / data models**
- DHIS2 Health Campaigns — https://dhis2.org/health/campaigns/
- DHIS2 Immunization campaigns: Design — https://docs.dhis2.org/en/implement/health/immunization/immunization-campaigns/design.html
- DHIS2 Immunization campaigns: Use (triangulation, real-time monitoring) — https://docs.dhis2.org/en/implement/health/immunization/immunization-campaigns/use.html
- DHIS2 EPI aggregate module: Design — https://docs.dhis2.org/en/implement/health/immunization/expanded-programme-on-immunization-epi-aggregate/design.html
- DHIS2 Immunization eRegistry (tracker): Design — https://docs.dhis2.org/en/implement/health/immunization/eir-immunization-eregistry/design.html
- Geo-enabled digital microplanning, Bangladesh (TechNet-21) — https://www.technet-21.org/en/community/blogs-newsletters/geo-enabled-digital-microplanning-revolutionizing-immunization-in-bangladesh

**Polio**
- *Revised Household-Based Microplanning in Polio SIAs, Kano State, Nigeria* — https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4818558/
- *Assessment of unmet needs / noncompliant households, Kaduna* — https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6291916/
- *Source of information for polio SIAs, Somali, Ethiopia* (independent monitoring) — https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5619920/
- Pulse Polio program & microplanning (tally Forms 8A/8C/8D/9A) — https://www.slideshare.net/slideshow/pulse-polio-program-and-microplanning/239603411

**Measles–rubella**
- WHO (2016) *Planning and Implementing High-Quality SIAs for Injectable Vaccines (MR example): field guide* — https://www.who.int/publications/i/item/9789241511254
- WHO (2025) *Targeted and selective strategies in MR vaccination campaigns: interim guidance* — https://www.who.int/publications/i/item/9789240103399
- High-Quality MR SIAs e-learning (UNICEF Agora) — https://agora.unicef.org/course/info.php?id=11289
- *MR SIA Readiness Assessment — India, 2017–2018* (MMWR) — https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6048977/
- Nested DBS serosurvey during MR SIA, Zambia — https://www.ncbi.nlm.nih.gov/pmc/articles/PMC11213301/

**Yellow fever (EYE)**
- WHO yellow fever fact sheet — https://www.who.int/news-room/fact-sheets/detail/yellow-fever
- EYE Strategy 2023 Highlights (DHIS2 EYE module; coverage-monitoring guidance) — https://cdn.who.int/media/docs/default-source/documents/emergencies/health-topics---yellow-fever/eye_2023_highlights.pdf
- *Assessing impact of PMVCs on YF outbreaks* (ICG reconciliation), PLOS Medicine — https://journals.plos.org/plosmedicine/article?id=10.1371%2Fjournal.pmed.1003523
- *Assessing YF outbreak potential & EYE coverage targets*, PLOS GPH — https://journals.plos.org/globalpublichealth/article?id=10.1371%2Fjournal.pgph.0003781

**Oral cholera vaccine**
- GTFCC *Cholera Outbreak Response Field Manual* §9 (OCV) — https://www.choleraoutbreak.org/book-page/section-9-oral-cholera-vaccine.html
- Stop Cholera / JHU GTFCC vaccine resources (ICG M&E; coverage protocol; OCV mass-campaign guidance) — https://publichealth.jhu.edu/stop-cholera/gtfcc-resources/vaccine
- Gavi, *Oral cholera vaccine support* (stockpile, ICG) — https://www.gavi.org/types-support/vaccine-support/oral-cholera
- *Global oral cholera vaccine use, 2013–2018* (reporting requirements) — https://www.sciencedirect.com/science/article/pii/S0264410X19311855
- *Pre-emptive OCV campaign, Cuamba, Mozambique* (admin vs survey coverage; CholTool) — https://pubmed.ncbi.nlm.nih.gov/36547726/
- *Costing OCV delivery with CholTool* — https://pmc.ncbi.nlm.nih.gov/articles/PMC8641596/

**NTD mass drug administration**
- About ESPEN (PC-NTDs; MDA) — https://espen.afro.who.int/node/8
- ESPEN database challenges (district-level endemicity/coverage reporting) — https://pmc.ncbi.nlm.nih.gov/articles/PMC12212196/
- *NTD MDA as a strategy for UHC — Liberia* (community-level treatment data) — https://academic.oup.com/inthealth/article/16/3/283/7164139
- *Changing NTD landscape in Africa* (ESPEN/Sightsavers forecasts) — https://academic.oup.com/healthaffairsscholar/article/3/7/qxaf136/8219720
- *Microplanning improves LF MDA engagement* — https://journals.plos.org/plosntds/article?id=10.1371/journal.pntd.0012105
- *Community drug distributors for MDA* (NTD master plans) — https://pmc.ncbi.nlm.nih.gov/articles/PMC6790237/
- NTD Toolbox: MDA delivery platforms (school/community/door-to-door) — https://www.eliminateschisto.org/resources/ntd-toolbox-resource-practical-who-guidance

**Coverage measurement & data quality**
- WHO (2018) *Vaccination Coverage Cluster Surveys: Reference Manual* (WHO/IVB/18.09) — https://www.who.int/publications/i/item/WHO-IVB-18.09
- WHO white paper, *Harmonizing vaccination coverage measures in household surveys* (SIA definition; HBR/register/tally) — https://www.who.int/docs/default-source/immunization/immunization-coverage/surveys_white_paper_immunization_2019.pdf
- WHO, *Analysis and Use of Health Facility Data: guidance for immunization programme managers* — https://cdn.who.int/media/docs/default-source/documents/ddi/facilityanalysisguide-immunization.pdf

*Prepared as a research brief to ground an implementation guide; coverage of the two tropical diseases can be refocused once the specific diseases are confirmed.*
