---
title: "ICR FHIR Implementation Guide — Campaign Data Model & Structure (v1 Working Doc)"
project: ICR
status: draft
version: 0.3.0
last_modified: 2026-06-10T04:54:39.000Z
authors: [Ona, Crosscut]
audience: [Ona, Crosscut, UNICEF, WHO]
created: 2026-06-09
tags: [icr, fhir, ig, data-model, campaigns, working-doc]
---

# ICR FHIR Implementation Guide — Campaign Data Model & Structure
`v0.3.0 · Last modified Jun 10, 2026 at 12:54 AM EDT`

> [!abstract] What this document is A working design document that grounds the **ICR FHIR Implementation Guide (IG)** before Phase 1 authoring begins. It moves in four deliberate steps:
> 
> 1. **The nature of campaigns** — what a campaign is, its lifecycle and operational tempo, who touches the data, and what gets recorded in the field (§1) — and which of those data assets are reusable across campaigns and programs, the ICR's core thesis (§2).
>   
> 2. **Campaign types** — how campaigns actually differ, grouped by _delivery model_ rather than by disease (§3).
>   
> 3. **Data-model components** — the entities and concepts public-health practitioners use to describe campaigns: microplans, denominators, coverage, sessions, registers (§4).
>   
> 4. **FHIR mapping & proposed IG profiles** — how each component maps onto HL7 FHIR R4 resources, and the concrete profiles the ICR IG should define (§5–12).
>   
> 
> It is technical and opinionated, but written to be circulated to UNICEF and WHO as a v1 thinking piece. It is **not** the IG itself — it is the design rationale the IG will encode. Source research lives in [[Immunization Campaign Data Models Research]], [[immunization-campaign-data-models-report]], [[chatpgpt-campaigns]], and the [[ICR Technical Proposal Ona Final]].

* * *
## 1. The nature of public health campaigns
A public health campaign is a **time-bounded, population-level delivery event**: over days to weeks, a health system mobilizes thousands of temporary workers to bring a product — a vaccine, a deworming tablet, a bed net, a vitamin A capsule — to everyone in a defined target population, regardless of whether they ever visit a health facility. Campaigns complement routine services; they do not replace them. Where routine immunization waits for the child to come to the system, **the campaign sends the system to the child**.
### 1.1 The programs in scope
The ICR spans public health campaign programs across diseases and delivery models — the UNICEF-supported programs below are representative examples, not the limit of scope. They look different on the surface but share deep structure:

| Program | Product | Typical target | Cadence & operational shape |
| --- | --- | --- | --- |
| **Polio SIA / outbreak response** | OPV (oral drops) | All children <5 | Multiple rounds; house-to-house sweeps over ~1 week, same-day mop-up |
| **Measles–rubella SIA** | Injectable MCV (cold chain, AEFI monitoring) | 9 months–14 years | Every 2–4 years; fixed & temporary posts over 1–2 weeks |
| **NTD MDA** (LF, oncho, schisto, STH, trachoma) | Albendazole, ivermectin, praziquantel, azithromycin… | Whole at-risk communities or school-age | Annual/biannual rounds sustained for years; community drug distributors |
| **Malaria ITN distribution** | Long-lasting insecticidal nets | All households | Mass replacement ~every 3 years; registration then distribution |
| **Malaria IRS** | Insecticide spraying | All eligible structures | Seasonal, ahead of transmission; structure-by-structure visits |
| **Vitamin A supplementation** | High-dose capsule | 6–59 months | Semiannual; usually co-delivered (child health days, polio rounds) |

These programs frequently target **the same communities and the same beneficiaries** — which is the premise of the ICR: data collected for one round should be an asset for the next, across programs.
### 1.2 The campaign lifecycle
Every campaign, regardless of program, moves through the same lifecycle — and each phase produces and consumes data:

```mermaid
flowchart LR
    MACRO["<b>Macroplanning</b><br/>national · 6–12 mo out<br/>scope, geography, budget,<br/>supply forecast"]
    MICRO["<b>Microplanning</b><br/>district/facility level<br/>maps, target populations,<br/>sites & sessions, teams, logistics"]
    READY["<b>Readiness</b><br/>assessment scores,<br/>training, stock positioning"]
    DELIVER["<b>Campaign delivery</b><br/>days–weeks"]
    CLOSE["<b>Close-out</b><br/>stock reconciliation,<br/>coverage survey, mop-up,<br/>HMIS / JAP / Gavi reporting"]
    MACRO --> MICRO --> READY --> DELIVER --> CLOSE
    DELIVER --> LOOP
    subgraph LOOP["The daily loop (command-and-control)"]
        direction LR
        TALLY[Tally / register] --> SUP[Supervisor review<br/>RCM spot checks] --> DASH[Dashboard /<br/>district review] --> ACT[Corrective action:<br/>redeploy · resupply · mop-up] --> TALLY
    end
    CLOSE -.assets feed the next campaign.-> MICRO
```

Two phases deserve emphasis because they dominate the data model:

**Microplanning produces the campaign's core dataset.** In a well-run campaign the microplan is not a narrative document but a **structured dataset**: every village in the catchment with its target population, hard-to-reach flags, session type (fixed / outreach / mobile), team assignments, transport, and commodity needs — the WHO RED strategy formalized this for routine immunization and campaigns inherited it. The quality payoff is measurable: in Kano State, Nigeria, revised _household-based_ microplanning increased enumerated settlements by 38% and corrected inflated target counts, directly improving the subsequent campaign.

**Campaign delivery runs on a daily operational rhythm.** During the delivery window the campaign is run on a same-day command-and-control cycle rather than the monthly or quarterly reporting cadence of routine programs: tally sheets are reviewed nightly, supervisors run rapid convenience monitoring (RCM) during the day, dashboards drive next-morning redeployment, and mop-up teams revisit missed households within a day or two. Any data model that cannot support this same-day loop — capture → aggregate → decide → act — fails the campaign manager no matter how well it serves the epidemiologist afterward.
### 1.3 Actors — who creates and consumes data
| Actor | Creates | Consumes |
| --- | --- | --- |
| National program manager (EPI / NTD / malaria) | Macroplan, protocol, targets | National dashboards, JAP/Gavi/WHO reports |
| District health management team | Microplan, team rosters, logistics plan | Daily coverage vs target, stock alerts |
| Field supervisor | Supervision checklists, RCM forms, mop-up lists | Team tallies, missed-area flags |
| Vaccination team / community drug distributor (CDD) | Tally sheets, registers, treatment records | Movement plan, household lists, dose-pole charts |
| Independent monitor | Post-campaign household checks, LQAS | Microplan denominators |
| Community mobilizer | Refusal/absence notes, session announcements | Session schedule |
### 1.4 How records are captured{>>Trimmed this to a digitization-first paragraph that keeps the artifact vocabulary later sections (§3, §4, §7) rely on. Keep it at this level, or cut the artifact list entirely and lean on those later sections?<<}{id="c37" by="claude" at="2026-06-10T04:19:01.000Z"}
For this project we assume campaign data is captured digitally — through ODK/XLSForm, DHIS2, CommCare, or OpenSRP — or digitized shortly after capture. Going from paper to a digital form changes _how_ data is recorded, not _what_ it is: a digital form is still the same tally sheet, register, or dose-pole reading underneath. The ICR's job is to give those underlying instruments a standard, reusable representation rather than to change field practice. The artifacts the model must represent are the doorstep **tally sheet** (people reached by age band; houses visited), the **CDD community register** (household-by-household treatment records), the **dose pole** (height bands mapped to tablet counts in MDA), finger- and chalk-**marking** (in-field "already covered" flags), and the family-held **home-based record** (child health card, checked for zero-dose detection).

> [!note] Legacy paper is increasingly digitizable Where paper records persist, AI/OCR can now convert tally sheets and registers into structured data in ways that were impractical before — promising for backfilling historical campaigns, though out of scope for this design.

* * *
## 2. What campaigns record — and what is reusable
### 2.1 The five layers of campaign data
Across all programs, well-run campaigns organize their data in the same layered structure:

| Layer | What it holds | Typical artifacts |
| --- | --- | --- |
| **Campaign layer** | Dates, targets, geography, teams, commodities, partners | Campaign plan, microplan, budget |
| **Delivery layer** | Facilities, posts, schools, households, routes | Site lists, team movement plans, operational maps |
| **Service layer** | Doses given / not given, treatments, nets delivered, structures sprayed | Tally sheets, registers, individual records |
| **Supervision & quality layer** | Refusals, missed children + reasons, stock reconciliation, RCM, LQAS | Checklists, monitoring forms, mop-up lists |
| **Analytics layer** | Coverage, dropout, zero-dose, wastage, data quality | Dashboards, HMIS reports, JAP forms |
### 2.2 The disposability problem
Campaign delivery has been **verticalized for decades**: each program builds its own systems, remaps the same communities, re-registers the same people, and re-estimates the same denominators every round. Data from one program is rarely available to the next even when both serve the same villages. The clearest case is NTDs: MDA campaigns could run on the household maps, population denominators, and geographic data that better-funded polio and immunization campaigns have _already collected_ — but siloed systems make that impossible. Campaign data is rarely carried forward: once a round closes, little effort goes into preserving it or putting it in a form the next campaign could use.

Several forces explain why{>>These reasons are inferred from the research and general program structure — do they match your field experience, or are there bigger drivers (e.g. no budget line for data stewardship, donor reporting that ends at close-out) I should foreground?<<}{id="c36" by="claude" at="2026-06-10T04:19:01.000Z"}:

- **Vertical funding and accountability.** Each program is financed and evaluated on its own round; nothing rewards one campaign for leaving behind assets a later campaign could use, so reuse is no one's mandate.
  
- **Data collected for control, not reuse.** The operational job is to hit coverage during the window; once that is achieved the data has served its purpose, and its value to a future campaign is rarely considered at design time.
  
- **No shared home and no common identifiers.** Without a registry and a standard format, records sit in program-specific tools or on paper, in incompatible schemas, with no agreed way to join one campaign's data to the next.
  
- **Temporary workforce, thin institutional memory.** Campaigns run on short-term staff who disperse at close-out, taking undocumented local knowledge with them.
  
- **Sensitivity and unclear ownership.** Household- and person-level lists carry real privacy obligations; absent clear governance, the safe default is to lock them away rather than hand them on.
  

The ICR's thesis is to invert this: make each campaign a contributor to a **cumulative, reusable corpus of public health intelligence**, so that data collection cost becomes an investment that compounds across programs and over time.
### 2.3 The reusable data assets
The reusable core — what the ICR exists to capture, standardize, and hand to the next campaign — is the data that holds value beyond the round it was collected in (the transient remainder is catalogued in §2.4):

| Reusable asset | Typically produced by | Reused for | Refresh cadence{>>Renamed "Stability / decay" → "Refresh cadence" (how often the asset must be re-collected to stay trustworthy). Alternatives if you prefer: "Update cadence" or "Refresh frequency / stability." Good with this?<<}{id="c35" by="claude" at="2026-06-10T04:19:01.000Z"} |
| --- | --- | --- | --- |
| **Admin hierarchy & location registry** | National georegistry, any campaign | Every campaign + routine services | Very stable (years); changes with boundary reforms |
| **Settlement & household maps** (incl. building footprints / GERS IDs) | House-to-house campaigns (polio, IRS, ITN registration); geospatial tooling | Microplanning of _any_ program in the same geography | Durable; needs refresh for new/abandoned settlements |
| **Population denominators** | Microcensus & enumeration, modelled estimates (WorldPop, GRID3) | All targeting and every coverage calculation | **Decays fast** (1–3 years); must carry source + date |
| **Catchment polygons & supervisory areas** | Microplanning tools (Crosscut, ESPEN Microplanner) | Session planning, fair team workloads, travel-time analysis | Stable until the facility network changes |
| **Target lists & zero-dose lists** | Campaign delivery + routine HMIS analysis | The next campaign's focus areas; routine catch-up | Months; **sensitive** — household-level, access-controlled |
| **Team rosters & site lists** | Campaign operations | The next round or the next program's campaign | Semi-durable; people and posts turn over |
| **Campaign protocols** (what a measles SIA _is_: products, age bands, activity sequence) | Program design, WHO guidance | Every instantiation, every country | Durable; versioned, evolves with guidance |
| **Coverage results & missed-area lists** | Monitoring & post-campaign evaluation | The next microplan's risk targeting | One planning cycle |

```mermaid
flowchart LR
    P1["Polio campaign<br/>(house-to-house)"] -->|household maps,<br/>denominators, settlements| ICR[("ICR<br/>FHIR registry")]
    ICR -->|microplanning inputs| M1["NTD MDA<br/>microplan"]
    M1 --> C1["MDA round"] -->|updated maps, coverage,<br/>missed areas| ICR
    ICR -->|zero-dose lists,<br/>refreshed denominators| M2["Measles SIA /<br/>vitamin A microplan"]
    M2 --> C2["Next campaign"] -->|...| ICR
```

> [!warning] Reuse is only safe with provenance A 2024 denominator silently reused in 2027 is worse than no denominator — it produces confident, wrong coverage figures. Every reusable asset must carry **its source, its date, and its method**, and consumers must see that metadata at the point of reuse. This is why the data model (§4) makes provenance a first-class feature of Tier 1, not an ETL detail.
### 2.4 What is not reusable{>>New section per your c11 — check this list of transient/non-reusable data matches where you'd draw the line.<<}{id="c39" by="claude" at="2026-06-10T04:19:01.000Z"}
The counterpart to the reusable core is a large volume of **transient operational data** that does its job during the round and has little value afterward. It must still be captured — it drives the daily loop — but the ICR does not need to standardize or preserve it long-term:

- **Per-team, per-hour tallies** once aggregated to site/day coverage;
  
- **Redeployment and mop-up decisions** — which team moved where on which morning;
  
- **Ephemeral operational state** — stock-on-hand at a post mid-day, transport status, daily attendance;
  
- **Old estimates that newer ones have replaced** — kept for the audit trail, not used to plan future campaigns.
  

The boundary is not always sharp: some transient data becomes reusable in aggregate (e.g. patterns of missed areas across days inform the next microplan). The model should make the distinction explicit rather than treat everything as equally permanent.

The rest of this document turns this picture into a formal model: first the campaign types grouped structurally (§3), then the components public health already has names for (§4), then their FHIR expression (§5 onward).

* * *
## 3. Campaign types — by delivery model
A campaign's data model is determined primarily by its **delivery model, not its disease** — the delivery strategy determines the level at which a single record is created (a site-session in fixed-post campaigns, a household in house-to-house, a person in an MDA register) and which entities even exist. The proposal's program scope (immunization, polio, NTD MDA, malaria, vitamin A) collapses into **three campaign types**, plus **routine immunization** as the substrate they all plug into.

```mermaid
flowchart TD
    RI[Routine Immunization / EPI<br/><i>the substrate</i>]
    RI --> A
    RI --> B
    RI --> C
    A[<b>Type A</b><br/>Fixed-post / outreach<br/>vaccine SIA]
    B[<b>Type B</b><br/>House-to-house<br/>rapid delivery]
    C[<b>Type C</b><br/>Community / MDA<br/>preventive chemotherapy]
    A --- A1[Measles–Rubella SIA<br/>HPV school-based<br/>Yellow fever PMVC<br/>OCV<br/>ITN fixed-point distribution<br/>Vitamin A child health days / schools]
    B --- B1[Polio SIA / outbreak<br/>OCV mop-up<br/>Malaria IRS structure visits<br/>ITN household registration]
    C --- C1[LF, onchocerciasis,<br/>schistosomiasis, STH,<br/>trachoma]
```

> [!note] Hybrids are the norm, not the exception Real campaigns mix types. A mass **ITN campaign** is typically a _house-to-house registration phase_ (Type B — enumerate households, issue vouchers, compute net allocation) followed by a _fixed-point distribution phase_ (Type A). **Vitamin A** is usually co-delivered through child health days (A) or piggybacked on polio house-to-house rounds (B). A measles SIA adds house-to-house _mop-up_ after fixed-post delivery. This is exactly why delivery strategy must be an attribute of the **activity/task**, not of the campaign.
### 3.1 The campaign types at a glance
| Type | Delivery unit & **grain** of record | Core records / planning artifacts | Distinctive data elements | Reporting rhythm |
| --- | --- | --- | --- | --- |
| **A. Fixed-post / outreach vaccine SIA** (measles–rubella, HPV, yellow fever, OCV, vitamin A) | Site → _site-session_ (fixed post, temporary post, **school**, mobile) | Daily tally sheets by age band, vial accountability, cold-chain logs, AEFI line lists, RCM, readiness assessment | Doses by antigen × age band; wastage; AEFI; readiness score; per-round/per-dose coverage (OCV) | Daily tally review; post-campaign survey / mop-up |
| **B. House-to-house rapid delivery** (polio, OCV mop-up; malaria IRS/ITN structurally) | Household → _household visit_ (+ child within household) | Team movement plans, operational maps, doorstep tally sheets, finger/house-marking, LQAS, RCM | Houses visited; children present/absent; **missed + reason**; **noncompliance reason**; chronically missed settlements | Daily team & supervisor review; same-day mop-up |
| **C. Community / MDA preventive chemotherapy** (NTD: LF, oncho, schisto, STH, trachoma) | Community / household → _community treatment register_ (by a CDD) | CDD treatment registers, household visit logs, supervision forms, side-event reports | Directly-observed consumption; **dose-pole height → tablet count**; chronic-morbidity line lists (lymphoedema, hydrocele) | Often daily during round; aggregated program / epidemiological / geographic coverage |
| **(Substrate) Routine immunization / EPI** | Facility / outreach → child over time | Home-based record, facility register, tally sheets → monthly HMIS report | Coverage by antigen-dose; drop-out (Penta1→Penta3); zero-dose (no DTP1); MOV | Monthly reporting; quarterly microplan revision |
### 3.2 Why the campaign type matters for FHIR
The campaign type dictates the **finest grain** at which a record exists, and therefore which FHIR resource carries the delivery event and at what cardinality:

- **Fixed-post / outreach (Type A)** produces _site-session aggregates_ → modeled as a `Task` per site-session whose `focus`/`location` is the `Location` (fixed post, temporary post, school), with aggregate outputs — and optionally individual `Immunization` where person-level capture exists.
  
- **House-to-house (Type B)** produces _household visits_ → modeled as a `Task` per household whose `focus` is the household `Group` and whose `location` is the dwelling, carrying missed/noncompliance reasons natively.
  
- **Community / MDA (Type C)** produces _community register entries_ → modeled as `MedicationAdministration` (with dose-pole `Observation`) linked to a community/household `Group`.
  

In all three, the `Task` carries a `location` (the site, the dwelling, or the community point); the types differ in the `focus` — a `Location` for A, a household `Group` for B, a community/household `Group` for C.{>>Check: this fixes A's focus to a Location and B's to a household Group (per your c15/c16). Confirm this is the modeling you want — it propagates into the §6 crosswalk and the §7.4 ICRCampaignTask profile, which currently describe focus mainly as the household Group.<<}{id="c40" by="claude" at="2026-06-10T04:19:01.000Z"}{>>I think so but need to give it more thought to confirm.<<}{id="c44" by="user" at="2026-06-10T04:34:40.304Z" re="c40"}

> [!tip] First-class attribute **Delivery strategy must be a first-class, coded attribute** of every campaign activity / site / task. A single campaign routinely mixes strategies (e.g. fixed post + house-to-house mop-up), and the available data elements change with the strategy.

* * *
## 4. Public-health data-model components
Public-health practitioners do not think in FHIR resources; they think in **microplans, denominators, sessions, tally sheets, registers, and coverage**. Synthesizing the six programs in the research, the recurring structure is a **six-tier model**. The ICR IG must be able to express all six tiers.

```mermaid
flowchart TB
    T0["<b>Tier 0 — Geography & org units</b><br/>admin hierarchy · operational geography · catchment polygons · settlements/structures"]
    T1["<b>Tier 1 — Population & denominators</b><br/>target population per geography · source/provenance · age–sex bands · competing estimates"]
    T2["<b>Tier 2 — Microplan & resources</b><br/>microplan · sites/posts (w/ strategy) · teams · resource requirements"]
    T3["<b>Tier 3 — Delivery / encounters (grain layer)</b><br/>site-session tally · household visit · community treatment register · individual event"]
    T4["<b>Tier 4 — Monitoring & coverage</b><br/>administrative coverage · survey coverage · RCM · LQAS · readiness · coverage targets"]
    T5["<b>Tier 5 — Supply, logistics & cost</b><br/>lots & stockpile source · cold chain · wastage · campaign cost"]
    T0 --> T1 --> T2 --> T3 --> T4
    T2 --> T5
    T3 --> T5
```
### 4.1 The three data lineages (do not merge them)
The single most important cross-cutting rule from the evidence: a campaign carries **three distinct lineages of the same quantities**, and they must never be collapsed into one field.

```mermaid
flowchart LR
    PLAN["<b>PLANNED</b><br/>microplan targets,<br/>planning denominator"] -->|compare| DELIVER
    DELIVER["<b>DELIVERED</b><br/>administrative coverage<br/>(doses ÷ planning denom.)"] -->|compare| VERIFY
    VERIFY["<b>INDEPENDENTLY MEASURED</b><br/>survey / LQAS / RCM coverage"]
    PLAN -.joinable but separate.- VERIFY
```

> [!warning] The admin-vs-survey gap is real and must be representable In a pre-emptive OCV campaign in Cuamba, Mozambique, **administrative coverage was ~99% while the post-campaign survey found ~76%** for the first dose. The model must hold _administrative_ and _survey_ coverage as **separately-sourced, first-class measures** of the same conceptual quantity — each with method, denominator source, and date attached.
### 4.2 Denominator-first
The denominator (target population) is the dominant source of error in campaign analytics. Every population estimate and every coverage figure must carry **provenance and a date**: census/projection, microcensus/enumeration, or modelled gridded estimates (WorldPop, GRID3), intersected with catchment polygons. Multiple competing estimates per geography should be retained, with **one flagged as the planning denominator**.
### 4.3 Real-time vs post-campaign reconciliation
The IG must distinguish components captured/reported **in real time during an active campaign** from those **reconciled at campaign close** — using a _single structure_ that supports both, rather than two systems.

| Real-time (operational monitoring) | Post-campaign (reconciliation & reporting) |
| --- | --- |
| Doses / commodities administered | Reconciled stock counts & wastage |
| Locations visited, progress vs target | Final coverage calculations (admin + survey) |
| Team redeployment, mop-up triggers | Data-quality review, deduplication |
| Daily dashboards | JAP / Gavi / ICG-aligned consolidated reporting |
### 4.4 Campaign ↔ routine integration and zero-dose
Campaigns are no longer just blanket-coverage events — they are increasingly **precision instruments for finding zero-dose children** (no DTP/Penta1) and pulling them into the routine system (the Big Catch-Up pattern). Two concrete model requirements follow:

1. **Every delivery event carries a coded record-origin** (`campaign-SIA` vs `routine-facility-visit`). Without it, SIA doses contaminate routine coverage analytics — and conversely routine history (card checked / zero-dose detected during a campaign) can't be analyzed. This is a required element on all ICR delivery-event profiles, not an option.
  
2. **A campaign encounter can spawn routine follow-up.** When a zero-dose child is found during a campaign, the model must support enrolling them (a `Patient` created from the household `Group` member) and generating routine follow-up — which is exactly what the `CarePlan`/`Task` machinery already provides, pointed at the routine schedule instead of the campaign protocol.
  

This is also the heart of the ICR's reuse thesis: the household maps, population denominators, and zero-dose lists that one campaign produces become **planning inputs (Tier 0–1) for the next** — across programs, not just within one.

* * *
## 5. The FHIR modeling challenge
Having described campaigns in their own terms, we can now confront the standard. FHIR was designed around the **clinical encounter**: a patient presents at a facility, a clinician delivers a service, a record is created. Campaigns **invert this model**. They are population-level, geographically driven, time-bounded events in which _teams move outward into communities_ to deliver services at scale. There is no native `Campaign` or `CampaignEvent` resource in FHIR.

The ICR IG's central task is therefore to **identify which existing FHIR resources can be profiled and extended to carry campaign semantics faithfully**, in a way that is architecturally sound and acceptable to the broader FHIR community. We have navigated this exact challenge before with the **household** concept (no native FHIR support → `Group` linked to `Location`, validated through the HL7 community process and since adopted in the ecosystem). We will follow the same methodology here.

```mermaid
flowchart LR
    subgraph Clinical["Clinical FHIR (encounter-centric)"]
        P[Patient arrives] --> S[Service delivered] --> R[Record created]
    end
    subgraph Campaign["Campaign reality (population-centric)"]
        M[Microplan: targets, geography, teams, supplies] --> T[Teams deploy outward]
        T --> D[Services delivered at scale<br/>house / post / school / community]
        D --> AGG[Aggregate up to coverage<br/>vs estimated denominator]
    end
    Campaign -.must be expressed using.-> Clinical
```

> [!note] Design north star **One configurable data model, many expressions.** Routine immunization, polio SIAs, measles–rubella SIAs, NTD MDA, malaria IRS/ITN, and vitamin A supplementation differ mostly in _delivery strategy, age band, dose/round count, and product type_ — all expressible as configuration over a shared model, rather than as separate per-disease schemas.

* * *
## 6. Mapping public-health components → FHIR resources
This is the crosswalk from the public-health vocabulary of §§2–4 to FHIR R4 resources. `CarePlan` **is the architectural foundation**: in clinical FHIR a CarePlan is a coordinated set of activities to address a health concern for a patient or group; _a campaign is the same concept at population scale_.

```mermaid
flowchart TD
    PD["<b>PlanDefinition</b><br/>reusable campaign protocol<br/>(the campaign 'type')"]
    PD -->|instantiatesCanonical| CP
    CP["<b>CarePlan</b><br/>a specific campaign execution<br/>(dates, geography, target, status)"]
    CP -->|subject| GRP["<b>Group</b><br/>target population / household"]
    CP -->|careTeam| CT["<b>CareTeam</b><br/>campaign teams"]
    CP -->|activity| AD["<b>ActivityDefinition</b><br/>discrete work type<br/>('administer albendazole 5–14')"]
    AD -->|instantiates| TASK
    TASK["<b>Task</b><br/>assignable, trackable unit of work<br/>tied to a Location, owned by a team member"]
    TASK -->|location| LOC["<b>Location</b><br/>admin hierarchy + geospatial<br/>settlement / school / household"]
    TASK -->|produces| IMM["<b>Immunization</b> (vaccines)"]
    TASK -->|produces| MA["<b>MedicationAdministration</b> (MDA drugs)"]
    TASK -->|produces| SD["<b>SupplyDelivery</b> (ITNs, commodities)"]
    GRP -->|member| PAT["<b>Patient</b> (where person-level)"]
    GRP -->|located at| LOC
    IMM -->|uses| LOT["lot / product<br/>CVX · ATC · GS1"]
```
### 6.1 Master crosswalk
| Public-health concept (Tier) | FHIR R4 resource | Notes / proposed ICR profile |
|---|---|---|
| Campaign protocol / "type" (T2) | `PlanDefinition` | Reusable template per campaign type → **ICRCampaignProtocol** |
| A specific campaign execution (T2–T4) | `CarePlan` | Dates, geography, target, status lifecycle → **ICRCampaign** |
| Discrete work type (T2) | `ActivityDefinition` | "Administer MCV to 9mo–14y" → **ICRCampaignActivity** |
| Assignable unit of work / session / visit (T3) | `Task` | Per site-session **or** per household; carries delivery strategy, missed/noncompliance → **ICRCampaignTask** |
| Admin hierarchy & service points (T0) | `Location` (+ `Organization`) | Nested `partOf`; geo extension → **ICRLocation** |
| Operational geography (settlements, supervisory areas) (T0) | `Location` | Linkable-but-distinct from admin units |
| Catchment polygon (T0) | `Location` + GeoJSON extension | Boundary geometry |
| Household (T3) | `Group` (type=person) + `Location` | The validated Ona pattern → **ICRHousehold** |
| Target population / denominator (T1) | `Group` (with `quantity`, characteristics) + provenance extension | → **ICRTargetPopulation** |
| Campaign team (T2) | `CareTeam` (+ `Practitioner`/`PractitionerRole`) | Members, roles, assigned sites |
| Person / caregiver (T3) | `Patient` (+ `RelatedPerson`) | Optional; only where person-level capture exists |
| Vaccination event (T3) | `Immunization` | CVX-coded; lot, performer, protocolApplied → **ICRImmunizationEvent** |
| MDA drug administration (T3) | `MedicationAdministration` | ATC-coded; dose-pole `Observation` drives `dosage` → **ICRMedicationAdministration** |
| Commodity distribution — ITN, IRS, vitamin A (T3) | `SupplyDelivery` | suppliedItem + quantity → **ICRSupplyDelivery** |
| Dose-pole height, finger-mark, "child present" (T3) | `Observation` | Proxy/operational observations |
| Adverse event (AEFI / side event) (T3) | `AdverseEvent` | Linked to the delivery event |
| Stock / cold-chain / wastage (T5) | `SupplyDelivery` / `Observation` / `InventoryReport`* | *R5 concept; in R4 use Observation/extension |
| Administrative coverage (T4) | `MeasureReport` (+ `Measure`) | doses ÷ planning denominator; denominator provenance attached |
| Survey / LQAS / RCM coverage (T4) | `MeasureReport` / `Observation` | Method, sample design, CI, date — **separate** from admin |
| Coverage target / threshold (T4) | `PlanDefinition.goal` / `Measure` | e.g. ≥95%, ≥65% (LF), EYE 50/60/80% |
| Supervision checklist / RCM form / readiness assessment (T4) | `Questionnaire` + `QuestionnaireResponse` | The natural landing zone for ODK/XLSForm instruments (SDC) |
| Data lineage / source system (all tiers) | `Provenance` | Which tool (ODK, DHIS2, CommCare), which transform (OpenFn), when — essential for a registry fed by many sources |
| Analytics projection (T4) | `ViewDefinition` (SQL-on-FHIR) | Part of the IG → portable warehouse schema |

> [!note] Why CarePlan rather than a bespoke resource CarePlan unifies **planning and execution in one record**: a CarePlan that begins as a microplan (what should happen, where, by whom, with what supplies) _evolves into_ a campaign execution record as Tasks complete and coverage accumulates. This directly supports the bidirectional flow with the WHO Geospatial Microplanner, where CarePlans, Tasks, and Locations move as FHIR resources.
### 6.2 Alternatives considered (and why not)
Reviewers will reasonably ask why not these — recording the reasoning up front:

- **A custom** `Campaign` **resource.** Tempting, but a non-standard resource has no community adoption path, no tooling support, and would isolate the ICR from the FHIR ecosystem the IG exists to join. Profiling existing resources is how household representation succeeded.
  
- `Encounter` **for delivery sessions.** Encounter is patient-centric (requires a subject) and carries clinical-visit semantics. Type A site-sessions and Type B household visits are _work_, not visits — `Task` carries assignment, status, location, and outputs natively, and works whether or not a `Patient` exists. Where genuine person-level encounters occur (e.g. EIR-grade capture), `Encounter` remains available _alongside_ the Task, not instead of it.
  
- `RequestGroup` **as the campaign container.** RequestGroup orchestrates related requests but has no lifecycle as an _executed plan_, no `careTeam`, no goal/outcome linkage, and no microplan→execution evolution. CarePlan does.
  
- `Appointment`**/**`Schedule` **for sessions.** These model booked patient slots, not population-scale session plans; session planning lives in the microplan (CarePlan/Task/Location) instead.
  
### 6.3 Multi-round and multi-dose campaigns
Rounds are the norm (polio NIDs, OCV two doses ~14 days apart, annual MDA cycles). The mechanism: **each round is its own** `CarePlan` (instantiating the same **ICRCampaignProtocol**), linked via `CarePlan.partOf` to an umbrella campaign CarePlan. Per-round coverage is then a per-CarePlan `MeasureReport`, and derived measures ("fully immunized" = both OCV doses; "fully covered" across MDA cycles) are computed across sibling rounds — which requires stable person/household identity across rounds, another reason GERS-anchored household identifiers matter (§9).

* * *
## 7. Proposed ICR IG profiles
Concrete profiles for v0.1 of the IG. Each entry gives the **base resource, purpose, key constrained elements, extensions, and bindings**. (Full FSH is deferred to IG authoring; these are the design targets.) Profile URLs will follow the pattern `https://fhir.icr.unicef.org/StructureDefinition/<Name>`.
### 7.1 ICRCampaignProtocol — _profile of_ `PlanDefinition`
The reusable, version-controlled template for a campaign type.

| Element | Constraint |
|---|---|
| `type` | Fixed/extensible to a campaign-type code (vaccination-SIA, MDA, ITN-distribution, IRS, vitamin-A) |
| `subjectCodeableConcept` | Target population definition (age band, eligibility) |
| `action` | Nested actions = the activity sequence (instantiated as `ActivityDefinition`s) |
| `goal` | Coverage targets / thresholds (e.g. ≥65% epidemiological coverage for LF) |
| **Extension** | `campaign-delivery-strategy` (1..* coded) |
### 7.2 ICRCampaign — _profile of_ `CarePlan` (the keystone) A specific campaign execution.
| Element | Constraint |
|---|---|
| `instantiatesCanonical` | 1..1 → an **ICRCampaignProtocol** |
| `status` | draft → active → completed (campaign lifecycle) |
| `intent` | `plan` (microplan) transitioning to `order` |
| `category` | Campaign-type code (bound to ICR campaign-type ValueSet) |
| `subject` | → **ICRTargetPopulation** (`Group`) |
| `period` | Campaign / round dates |
| `careTeam` | → **ICRCampaignTeam** (`CareTeam`) |
| `addresses` | The disease/condition targeted (CodeableConcept/Condition) |
| `activity.reference` | → **ICRCampaignTask** resources |
| **Extensions** | `campaign-round` (int), `target-geography` (Reference(Location)), `planning-denominator` (Reference(Group)/quantity), `realtime-vs-reconciled` flag |
### 7.3 ICRCampaignActivity — _profile of_ `ActivityDefinition` A discrete work type within the campaign (e.g. "administer albendazole to children 5–14", "distribute ITNs to households").
| Element | Constraint |
|---|---|
| `kind` | `Task` |
| `code` | The intervention (vaccinate / treat / distribute) |
| `productCodeableConcept` \| `productReference` | Vaccine (CVX) / drug (ATC) / commodity (GS1) |
| `dosage` | Where applicable (and where dose-pole logic applies, references Observation) |
| **Extension** | `delivery-strategy` (coded) |
### 7.4 ICRCampaignTask — _profile of_ `Task` (the operational unit) The assignable, trackable unit of work — **one Task per site-session (Type A) or per household (Type B)**.
| Element | Constraint |
|---|---|
| `status` | requested → in-progress → completed / failed |
| `intent` | `order` |
| `code` | The activity being performed |
| `focus` | What the task acts on — e.g. an **ICRHousehold** (`Group`) for house-to-house |
| `for` | The target subject/population |
| `owner` | Assigned team member (`Practitioner`/`CareTeam`) |
| `location` | → **ICRLocation** (settlement, school, household) |
| `executionPeriod` | When the work happened |
| `output` | Delivery results (refs to `Immunization`/`MedicationAdministration`/`SupplyDelivery`, or aggregate counts) |
| **Extensions** | `delivery-strategy`; `houses-visited`; `children-present` / `children-absent`; `missed-reason` (coded); `noncompliance-reason` (coded); `finger-marked` (bool) |

> [!note] Granularity is a deliberate design question Whether Tasks are assigned at _village_ level or down to _individual household_ is a performance-vs-fidelity trade-off to validate at national scale against real data. The profile supports both; the choice is configuration.
### 7.5 ICRHousehold — _profile of_ `Group`
| Element | Constraint |
|---|---|
| `type` | `person` |
| `actual` | `true` |
| `member.entity` | → `Patient` (where person-level data is collected) |
| `quantity` | Household size where individuals not enumerated |
| **Extension** | `household-location` (Reference(Location)) — the dwelling |
### 7.6 ICRTargetPopulation — _profile of_ `Group`
| Element | Constraint |
|---|---|
| `type` | `person`; `actual` = `false` (a conceptual cohort) |
| `quantity` | The denominator count |
| `characteristic` | Age band, sex, eligibility rule, geography |
| **Extensions** | `denominator-source` (census / microcensus / WorldPop / GRID3), `estimate-date`, `is-planning-denominator` (bool), `confidence` |
### 7.7 ICRLocation — _profile of_ `Location` (most-customized resource) | Element | Constraint | | --- | --- | | `partOf` | Enables nested admin hierarchy (country → region → district → ward → settlement) | | `physicalType` | jurisdiction / site / building / household | | `type` | facility / school / community-distribution-point / temporary-post / household | | `position` | GPS point (long/lat/alt) | | `identifier` | **Multi-system**: P-codes (OCHA), Overture Maps GERS IDs, national facility codes | | **Extension** | `location-boundary-geojson` (polygon: district / settlement / catchment) |
> [!warning] Performance is a first-order concern Campaign countries commonly have **6+ levels** of administrative nesting. Deep `partOf` chains create query-performance challenges for mobile/web clients. This is an explicit focus area for IG development, drawing on production experience with nested FHIR location hierarchies at national scale (e.g. Uganda). ### 7.8 Delivery-event profiles

| Profile | Base | Key constraints / bindings |
|---|---|---|
| **ICRImmunizationEvent** | `Immunization` | `vaccineCode` ← CVX (required) + local codes via ConceptMap; `lotNumber`, `manufacturer`, `protocolApplied`; `location`; **`record-origin` extension (campaign-SIA / routine) — required** |
| **ICRMedicationAdministration** | `MedicationAdministration` | `medicationCodeableConcept` ← ATC (praziquantel, albendazole, ivermectin, mebendazole); `dosage` derived from dose-pole `Observation`; directly-observed-consumption flag; `record-origin` extension |
| **ICRSupplyDelivery** | `SupplyDelivery` | `suppliedItem` ← GS1 GTIN (ITN, IRS chemical, vitamin A); `quantity`; `destination` (Location); `record-origin` extension |

> [!note] Linking delivery events to their Task R4 `Immunization` has no `basedOn` element (it arrives in R5), so the link runs the other way: the `Task.output` **references the delivery events it produced**. Implementers query "events for this task" via the Task, and "task for this event" via a reverse include — a pattern to validate for performance during IG development.
### 7.9 Coverage & analytics profiles
| Profile | Base | Purpose |
|---|---|---|
| **ICRAdministrativeCoverage** | `MeasureReport` | doses ÷ planning denominator; denominator provenance attached; marked `source = administrative` |
| **ICRSurveyCoverage** | `MeasureReport` / `Observation` | survey / LQAS / RCM result with method, sample design, CI, date; marked `source = survey/lqas/rcm` |
| **ICR ViewDefinitions** | `ViewDefinition` (SQL-on-FHIR) | Shipped *in the IG* so any implementer generates the same warehouse schema for DHIS2/JAP reporting |

* * *
## 8. Terminology & ValueSets
Multi-program scope means the IG must define bindings that are **internationally standardized yet locally adaptable**.

| Domain | Code system | Binding strength |
| --- | --- | --- |
| Campaign type (vaccination / MDA / ITN / IRS / vitamin A) | **ICR-defined ValueSet** | Required |
| Delivery strategy (fixed-post / outreach / school / house-to-house / community-directed) | **ICR-defined ValueSet** | Required |
| Vaccines | **CVX** (CDC) | Required + local via ConceptMap |
| MDA pharmaceuticals | **WHO ATC** | Required + local via ConceptMap |
| Commodities (ITN, IRS chemicals, drug formulations) | **GS1 GTIN**; WHO EML categories | Extensible |
| Missed / noncompliance reasons | **ICR-defined ValueSet** | Extensible |
| Adverse events | Existing FHIR/WHO AEFI sets | Extensible |

> [!tip] Localization pattern Implementations **must** use IG-defined codes for core campaign types, **should** use international codes (CVX/ATC) for products where applicable, and **may** add local codes for country-specific products. `ConceptMap` resources in the IG show how local codes relate back to the international standards — keeping data comparable across countries while honoring national formularies and registration numbers.
### Alignment with WHO SMART Guidelines
The ICR IG should **declare its relationship to the WHO SMART Immunizations IG and the Immunization DAK** rather than evolve in parallel. Concretely: reuse DAK core data elements and indicator definitions where they overlap (vaccination event fields, coverage indicators), align profile design with SMART conventions where campaigns and routine immunization meet (the §4.4 integration boundary), and track the SMART work as it matures — it is still draft/demo status, which gives the ICR room to _lead_ on campaign semantics while staying compatible on the routine side. This mirrors how the ICR IG is authored with the same FSH/SUSHI/IG-Publisher toolchain WHO SMART Guidelines use.

* * *
## 9. Location, administrative hierarchy & geospatial identity
```mermaid
flowchart TD
    C[Country<br/>P-code · GERS] --> R[Region]
    R --> D[District]
    D --> SD[Sub-district / Ward]
    SD --> SET[Settlement / Village<br/>GeoJSON polygon]
    SET --> HH[Household<br/>Group + Location point · GERS building ID]
    SD -.operational geography.-> SUP[Supervisory area<br/>linkable-but-distinct]
    D --> FAC[Health facility<br/>national facility code]
    SET --> SCH[School / community<br/>distribution point]
```

Three identity principles:

1. **Stable cross-campaign identity.** Support multiple identifier systems on every Location — **P-codes** (OCHA admin boundaries), **Overture Maps GERS IDs** (2.6B+ buildings, 64M+ places — a consistent way to identify the _same_ household/settlement across campaigns), and country-specific facility-registry codes.
  
2. **Boundaries, not just points.** A `location-boundary-geojson` extension carries district polygons, settlement areas, and catchment zones — the geometry Crosscut enriches and pushes back.
  
3. **Operational ≠ administrative geography.** Polio operational boundaries often differ from RI catchment boundaries (the Nigeria lesson). Model operational geography as _linkable-but-distinct_ from the admin hierarchy.
  

* * *
## 10. Open design questions for the FHIR community
These are the questions we will take to chat.fhir.org, working-group calls, and Connectathons — and validate against real campaign data during IG development:

1. **Task granularity at scale** — village-level vs household-level Tasks: the performance vs fidelity trade-off for national deployments.
  
2. **Aggregate vs individual delivery records** — when a site-session tally is enough vs when individual `Immunization`/`MedicationAdministration` is warranted (and how to represent aggregates conformantly — `Task.output` counts vs `MeasureReport`).
  
3. **Deep Location hierarchies** — keeping `partOf` chains performant for mobile/web at 6+ levels.
  
4. **Coverage as MeasureReport vs Observation** — the cleanest conformant representation of admin vs survey coverage as distinct lineages.
  
5. **Denominator provenance** — extension vs `Group.characteristic` vs a dedicated profile.
  
6. **GeoJSON on Location in R4** — custom extension now; alignment path with the R4B/R5 standard boundary extension.
  

* * *
## 11. From this doc to the IG
```mermaid
flowchart LR
    THIS[This working doc<br/>v0.1 design] --> REVIEW[Review 3–4 real<br/>campaign datasets<br/>NTD MDA · immunization · polio]
    REVIEW --> FSH[Author in FSH]
    FSH --> SUSHI[SUSHI → FHIR R4<br/>conformance artifacts]
    SUSHI --> PUB[IG Publisher → browsable HTML]
    PUB --> CI[CI validation +<br/>data conformance testing]
    CI --> V01[v0.1 draft IG<br/>circulated for review]
    V01 --> V1[v1.0 production IG<br/>NPM package · stable URL]
```

- **Authoring:** FHIR Shorthand (FSH) → SUSHI → IG Publisher (the WHO SMART Guidelines toolchain), under version control in a public GitHub repo.
  
- **Validation:** automated CI on every change; **data conformance testing** by converting real campaign datasets into the ICR model to find where it fits and where it needs adjustment.
  
- **Release cadence:** v0.1 draft (Phase 1) → feedback-revised draft for pilot → pilot-informed updates (Phase 2) → v1.0 production-ready, each with changelog and migration guidance.
  

* * *
## 12. Summary of design decisions
> [!summary] The ICR IG in twelve decisions
> 
> 1. **CarePlan is the keystone** — campaigns are population-scale care plans (alternatives considered and rejected: custom resource, Encounter, RequestGroup — §6.2).
>   
> 2. **PlanDefinition = reusable protocol; CarePlan = execution** — planning and execution in one model; rounds are sibling CarePlans under an umbrella via `partOf`.
>   
> 3. **Task is the operational unit** — one per site-session (A) or per household (B); delivery events hang off `Task.output`.
>   
> 4. **Delivery strategy is a first-class coded attribute of the activity/task** — campaigns mix strategies, and the strategy governs which data elements exist.
>   
> 5. **Three lineages — planned / delivered / independently-measured — never merged.**
>   
> 6. **Denominator-first, with provenance and date on every estimate and coverage figure.**
>   
> 7. **Household = Group + Location** (the validated Ona pattern); target population = Group.
>   
> 8. **Location is the most-customized resource** — multi-identifier (P-code, GERS, national), GeoJSON boundaries, performance-tuned hierarchy.
>   
> 9. **Terminology: international codes required, local codes allowed, ConceptMaps bridge them.**
>   
> 10. **Every delivery event is flagged campaign vs routine** (`record-origin`) — so campaigns can find zero-dose children without contaminating routine analytics.
>   
> 11. **Provenance on everything ingested** — the registry is fed by ODK/DHIS2/CommCare via transforms; lineage is a model feature, not an ETL afterthought.
>   
> 12. **ViewDefinitions ship in the IG** — the analytics layer is as portable as the data model.
>   

* * *
## Source research
- [[Immunization Campaign Dataa Models Research]] — six-program campaign types, tiered model, three lineages
  
- [[immunization-campaign-data-models-report]] — methodologies, DAKs, delivery mechanics, DHIS2/FHIR
  
- [[chatpgpt-campaigns]] — campaign modalities, data domains, platform patterns, tiering
  
- [[ICR Technical Proposal Ona Final]] — the authoritative scope, CarePlan approach, IG toolchain
  
- [[ICR Project Plan]] — phases, deliverables, timeline
