---
version: 0.5.0
last_modified: 2026-06-15T18:30:00.000Z
tags: [icr, fhir, ig, review]
---

# ICR FHIR IG v0.1 — {==Reviewer's Explainer==}{>>For each of the sections can we create an example resource or resources in FHIR /json to illustrate these. eg the care plan or ActivityDefinition.  Do them from a common campaign so they are interlinked and make sense.<<}{id="c67" by="mberg" at="2026-06-15T17:20:30.567Z"}
`v0.5.0 · Last modified Jun 15, 2026 at 2:30 PM EDT`

⁠

> [!note] What this document is A component-by-component walkthrough of the draft FHIR IG in `ig/`, written for review. For every artifact it covers **what it is**, **the rationale** (with pointers back to [[icr-v1]] sections), and **questions worth asking** before this hardens into v1.0. It describes the IG exactly as committed — every cardinality, binding, and fixed value below was checked against the FSH source.

> [!tip] v0.5.0 — annotated FHIR/JSON examples inlined (this doc's comments c64–c67) The campaign-architecture sections now carry the **actual resource JSON**, all drawn from the one Sierra Leone MR SIA scenario so every example interlinks: the **protocol** (§5.1), its **activity** (§5.3), the **umbrella + round CarePlans** (§5.2), and a **house-to-house Task** that chains through `Task.output` to the **MCV dose** (§5.4 → §7.1), plus the identity resources they reference (**Location** §6.3, **delivery-unit** and **denominator Groups** §6.1/§6.2) and the divergent **coverage pair** (§8). §5.2 also gains a **lifecycle diagram** (microplan `plan` → execution `order`, umbrella → rounds) answering c64, and a worked answer to "do the geographies sum to the national total?" (c65): they don't have to — each scope carries its own denominator from its own source. Every block is annotated field-by-field beneath the JSON. **No IG/FSH artifacts changed in this pass** — these render `examples.fsh` instances already in the IG (the §11 table) as readable JSON for reviewers.

> [!tip] v0.4.0 — third-pass revision applied (this doc's comments c1–c49) Your review comments on THIS doc, and the agreed replies, are now **applied to the IG** (commit `4b49ab0`, SUSHI-clean: 0 errors / 0 warnings) and folded into this doc's main text. The substance: **naming stays** — ICR-prefixed profile names and "Protocol" confirmed (c42/c45); a **protocol walk-through** (§5.1) and an **activity-definition gallery** (§5.3) are now in the main text (c44/c46); the **who-vs-where split and nested-population stack** explained in §5.2 (c8); the **one-Task-per-visit pattern with the person-targeted follow-up exception** documented in §5.4 and `Task.focus` widened to allow `Patient` for follow-ups (c48); `dataLineage` now **MS on ICRCampaign** (c9) and **required (1..1) on both coverage profiles with "absent ⇒ realtime" as the documented default** (c20); `children-present/absent` **renamed** `eligible-present/absent` (c18); `school-cohort` added as a third group kind (c49); `groupLocation` documented as **residence, not service point** (c13); the **async GERS-enrichment lifecycle** stated as the expected workflow in the IG narrative (c16); §6.2 gains a **competing-denominator walk-through** with a new third example (c15/c19). New examples: albendazole/ITN/IRS activity definitions + the Kambia enumeration estimate (26 total). Linear: **BERG-46** (GERS system URI, c2).

> [!tip] v0.3.0 — second-pass revision applied (icr-v1 comments c69–c75) Matt's Jun 12 review comments on the working doc, and the agreed replies, have been **applied to the IG** (commit `6a0ac4b`, SUSHI-clean: 0 errors / 0 warnings) and this doc updated to match. The substance: **ICRHousehold → ICRDeliveryUnit** — one Group profile for households _and_ communities, distinguished by a required `group-kind` code, with `household-location` generalized to `group-location` (c72); a profiled, computable **geography characteristic** on ICRTargetPopulation → Reference(ICRLocation) at any admin level (c70 — closes old §6.2 q2); **operational geography gets a real mechanism** — a new location-type CodeSystem (incl. `supervisory-area` / `operational-area`, bound extensible to `Location.type`, closing old §6.3 q5) plus an `overlays-admin-unit` extension (c74); a **required coded** `task-origin` (pre-planned / field-registered) on ICRCampaignTask (c75); `Task.focus` **narrowed** to `ICRDeliveryUnit | ICRLocation` (the old looseness reason disappeared with the generalization) and `ICRMedicationAdministration.subject` narrowed to `Patient | ICRDeliveryUnit`; and the **campaign-work-vs-routine-Encounter boundary** stated in the background narrative (c71). Three new examples: country Location, community delivery unit, supervisory area.

> [!tip] v0.2.0 — first-pass revision applied The cheap fixes and missing examples from this doc's original §15 checklist have been **applied to the IG** (commit `843ab18`, SUSHI-clean: 0 errors / 0 warnings) and this doc updated to match: FR designations on all five required-binding code systems; MDA ValueSet description corrected; new `SampleDesign` extension on survey coverage; reference-target tightening (target-geography → ICRLocation, planning-denominator → ICRTargetPopulation, household-location → ICRLocation); protocol `action.definition` locked to ICRCampaignActivity; delivery-strategy wired into ICRLocation for sites; Task.focus looseness documented as deliberate; and 7 new examples (activity definition, national umbrella + `partOf` round, Type A site-session task, fixed-post site, national denominator, admin-vs-survey coverage pair). Items needing a project decision (§15) remain open.

* * *
## 1. Orientation — what's in the IG
The IG consists of FHIR Shorthand (FSH), compiled by SUSHI into FHIR R4 artifacts.

| Layer | Count | Artifacts |
| --- | --- | --- |
| **Profiles — campaign architecture** | 4   | ICRCampaignProtocol (PlanDefinition), ICRCampaign (CarePlan), ICRCampaignActivity (ActivityDefinition), ICRCampaignTask (Task) |
| **Profiles — population & geography** | 3   | ICRDeliveryUnit (Group — household/community/school-cohort), ICRTargetPopulation (Group), ICRLocation (Location) |
| **Profiles — delivery events** | 3   | ICRImmunizationEvent (Immunization), ICRMedicationAdministration (MedicationAdministration), ICRSupplyDelivery (SupplyDelivery) |
| **Profiles — coverage** | 2   | ICRAdministrativeCoverage (MeasureReport), ICRSurveyCoverage (MeasureReport) |
| **Extensions** | 23  | See §8 |
| **CodeSystems** | 12  | campaign-type, delivery-strategy, record-origin, missed-reason, noncompliance-reason, denominator-source, data-lineage, coverage-source, group-kind, task-origin, location-type, group-characteristic |
| **ValueSets** | 13  | One per code system (except group-characteristic, used as a fixed code), plus a narrowed independent-coverage set and an ATC-based MDA medication set |
| **Example instances** | 26  | A coherent measles–rubella SIA scenario (umbrella + round, Type A & B tasks, coverage pair, country→dwelling hierarchy, household + community delivery units, supervisory area, competing denominators) + an activity gallery (MCV, albendazole, ITN, IRS) + an MDA event + an ITN delivery (§11) |
| **Narrative pages** | 2   | `index.md` (home), `background.md` (design rationale & open questions) |

File map (`ig/input/fsh/`): `aliases.fsh`, `codesystems.fsh`, `valuesets.fsh`, `extensions.fsh`, `profiles-campaign.fsh`, `profiles-population.fsh`, `profiles-delivery.fsh`, `profiles-coverage.fsh`, `examples.fsh`.

**Build:** `sushi build .` compiles FSH → JSON; `./_genonce.sh` renders the IG website (needs Java 17+). The commit is SUSHI-clean (compiles without errors).

* * *
## 2. IG metadata (`sushi-config.yaml`)
| Field | Value | Notes |
|---|---|---|
| `id` | `unicef.fhir.icr` | NPM-style package id |
| `canonical` | `https://fhir.icr.unicef.org` | Base URL of every profile/extension/CS/VS |
| `name` / `title` | `ICR` / "Integrated Campaign Registry (ICR) Implementation Guide" | |
| `status` / `version` | `draft` / `0.1.0` | |
| `fhirVersion` | `4.0.1` | FHIR **R4** (per proposal) |
| `license` | `Apache-2.0` | |
| `jurisdiction` | UN M49 `001` "World" | Global IG, not country-specific |
| `copyrightYear` | `2026+` | |
| `releaseLabel` | `ci-build` | |
| `publisher` | "UNICEF Integrated Campaign Registry project (Ona + Crosscut)", url `https://ona.io` | |
| `menu` | Home, Background, Artifacts | |
| `parameters` | `show-inherited-invariants: false`, `shownav: true` | |

{==**Rationale.** The canonical `https://fhir.icr.unicef.org` stakes out a UNICEF-owned namespace; the same base hosts the two provisional identifier-system URIs (§3). The toolchain (FSH/SUSHI/IG Publisher) deliberately matches WHO SMART Guidelines practice (working doc §11).==}{>>These are all open questions we need to determine.  Don't know yet.<<}{id="c1" by="mberg" at="2026-06-12T20:19:31.927Z"}{>>Understood — all four stay open. Nothing in the IG hardens them yet: canonical URL, publisher attribution, package id, and dependency declarations are each a one-line edit until first publication, after which the canonical becomes painful to change. Suggest batching all four for the first UNICEF technical review. Want a Linear task to track that batch, or fold it into an existing review milestone?<<}{id="c22" by="claude" at="2026-06-12T21:03:09.000Z" re="c1"}

> [!warning] Questions
> 
> 1. **Canonical URL ownership** — does UNICEF actually control `fhir.icr.unicef.org` (or intend to)? Changing canonicals after publication is painful; this needs early confirmation.
>   
> 2. **Publisher attribution** — is "(Ona + Crosscut)" with `ona.io` as URL the right public attribution, or should UNICEF be the publisher of record?
>   
> 3. **No dependencies declared** — the background page commits to aligning with WHO SMART Immunizations / the Immunization DAK, but the config declares no dependency on it (or on IHE mCSD, etc.). Intentional for v0.1, but worth deciding when the dependency gets declared and what "alignment" concretely means.
>   
> 4. `id: unicef.fhir.icr` — confirm this fits the package-naming convention UNICEF wants (most are `<org>.fhir.<scope>`, so it's plausible, but it's permanent).
>   

* * *
## 3. Aliases & identifier systems (`aliases.fsh`)
Three groups:

- **External terminologies:** `$CVX` (`http://hl7.org/fhir/sid/cvx`, vaccine codes), `$MeasurePopulation` (the HL7 measure-population code system, used by the coverage examples), `$ATC` (`http://www.whocc.no/atc`, WHO drug classification), `$VaccineCodeVS` (the core FHIR vaccine-code ValueSet).
  
- **ICR identifier-system URIs** (explicitly marked _provisional — to be confirmed before v1.0_):
  
  - `$GERSId = https://fhir.icr.unicef.org/identifiers/overture-gers` — Overture Maps GERS IDs
    
  - `$PCode = https://fhir.icr.unicef.org/identifiers/pcode` — OCHA P-codes
    
- **ICR code systems:** twelve `$...` aliases, one per CodeSystem in §10.
  

{==**Rationale.** GERS and P-codes need _some_ system URI to live under i==}{>>Add as a task in linear to figure out how to add a URI for overture gers.  Speak to the foundation about this.<<}{id="c2" by="mberg" at="2026-06-12T20:21:12.610Z"}{>>I need more info on how these are supposed to work.  Can you point me towards docs or explain what this system URI would contain and it's purpose?<<}{id="c3" by="mberg" at="2026-06-12T20:21:46.568Z" re="c2"}{>>How it works: every FHIR Identifier is a PAIR — `system` (a URI naming the namespace) + `value` (the ID itself). The system URI doesn't "contain" anything and doesn't need to resolve to a webpage; its only job is to make the value globally unambiguous. Without it, "08f2a3b4…" is just a string; with system = our GERS URI, any consumer knows "this is an Overture GERS ID" and can join on it safely — that's the entire mechanism behind multi-system identity on ICRLocation (GERS + P-code + national codes side by side, each tagged by its system). Convention is that the org that OWNS the namespace publishes the URI (e.g. CVX's is `http://hl7.org/fhir/sid/cvx`). Overture hasn't published one, so we minted a provisional URI under our own canonical — works fine, but if an official one appears later, stored data needs migrating; hence BERG-46. Docs: FHIR Identifier — hl7.org/fhir/R4/datatypes.html#Identifier; system-URI guidance — hl7.org/fhir/R4/terminologies-systems.html; NamingSystem (the FHIR resource for declaring such namespaces, which the IG can ship) — hl7.org/fhir/R4/namingsystem.html; GERS itself — docs.overturemaps.org/gers.<<}{id="c24" by="claude" at="2026-06-12T21:03:09.000Z" re="c3"}{>>Task filed: [BERG-46](https://linear.app/recodelabs/issue/BERG-46/determine-the-fhir-identifier-system-uri-for-overture-gers-ids-engage) — review GERS docs, engage the Overture Foundation, check the HL7 terminology registry, decide adopt-vs-mint, same check for P-codes.<<}{id="c23" by="claude" at="2026-06-12T21:03:09.000Z" re="c2"}n `Location.identifier`; parking them under the ICR canonical is the pragmatic v0.1 choice. CVX/ATC/GS1 as the international product-code backbone is working doc §8.

> [!warning] Questions
> 
> 1. **Should ICR mint the GERS/P-code system URIs at all?** If Overture or OCHA ever publish official URIs, every stored identifier would need migration — or ICR's URIs become permanent aliases. Worth raising on chat.fhir.org / with Overture.
>   
> 2. GS1 is named in the narrative ("commodity (GS1)") but has **no alias and no binding** anywhere — `ICRSupplyDelivery.suppliedItem.item[x]` is left uncoded. Intentional looseness or a gap?
>   

* * *
## 4. The architecture at a glance
FHIR has no native `Campaign` resource, so the IG profiles core will be based on the CarePlan resource.

```mermaid
graph TD
    PD["ICRCampaignProtocol<br/>(PlanDefinition)<br/><i>the reusable template</i>"]
    AD["ICRCampaignActivity<br/>(ActivityDefinition)<br/><i>a discrete work type</i>"]
    CP["ICRCampaign<br/>(CarePlan)<br/><i>one campaign execution / round</i>"]
    CPU["ICRCampaign (umbrella)"]
    T["ICRCampaignTask<br/>(Task)<br/><i>operational unit of work</i>"]
    TP["ICRTargetPopulation<br/>(Group, actual=false)<br/><i>denominator w/ provenance</i>"]
    HH["ICRDeliveryUnit<br/>(Group, actual=true)<br/><i>household or community</i>"]
    L["ICRLocation<br/><i>admin hierarchy + GERS identity</i>"]
    IMM["ICRImmunizationEvent"]
    MED["ICRMedicationAdministration"]
    SUP["ICRSupplyDelivery"]
    AC["ICRAdministrativeCoverage<br/>(MeasureReport)"]
    SC["ICRSurveyCoverage<br/>(MeasureReport)"]

    PD -- "action" --> AD
    CP -- "instantiatesCanonical 1..1" --> PD
    CP -- "partOf (rounds)" --> CPU
    CP -- "subject" --> TP
    CP -- "activity.reference" --> T
    T -- "focus: DeliveryUnit|Location" --> HH
    T -- "location 1..1" --> L
    T -- "output →" --> IMM
    T -- "output →" --> MED
    T -- "output →" --> SUP
    HH -- "group-location ext" --> L
    L -- "partOf" --> L
    CP -. "planning-denominator ext" .-> TP
    CP -. "target-geography ext" .-> L
    AC -. "never merged" .- SC
```

Reading order for a reviewer: protocol → campaign → task → delivery events is the _operational_ spine; Group/Location is the _identity_ spine; MeasureReport is the _analytics_ readout. Five cross-cutting invariants recur everywhere (§12): coded delivery strategy, campaign-vs-routine record origin, real-time-vs-reconciled lineage, denominator provenance, and never-merged coverage lineages.

* * *
## 5. Campaign-architecture profiles (`profiles-campaign.fsh`)
### 5.1 ICRCampaignProtocol — `PlanDefinition`
_The reusable, version-controlled template for a campaign type — what a measles SIA_ **_is_** _(products, age bands, activity sequence, coverage goals), instantiated by every execution in every country._ (working doc §7.1)

| Element | Constraint |
|---|---|
| `status`, `version`, `title` | MS |
| `type` | **1..1 MS**, bound **required** to ICRCampaignTypeVS |
| `subject[x]` | MS — "Target population definition (age band, eligibility)" |
| `goal` | MS — "Coverage targets / thresholds (e.g. ≥95% admin coverage; ≥65% epidemiological coverage for LF)" |
| `action` | MS — "The activity sequence, instantiated as ICRCampaignActivity definitions" |
| `action.definition[x]` | MS, only `Canonical(ICRCampaignActivity)` — the activity wiring is enforced, not just narrated |
| `extension[deliveryStrategy]` | **1..\* MS** — "Delivery strategies this protocol uses — campaigns routinely mix them" |

**Rationale.** Separating protocol from execution is design decision #2: a country defines "measles–rubella SIA, 9m–14y" once and every district/round instantiates it, giving cross-campaign comparability for free. Delivery strategy is **mandatory and repeatable** at protocol level because hybrid strategies are the norm (background page: "an ITN campaign is B then A"). Naming: "Protocol" is retained per review — it is FHIR's own term for what PlanDefinition holds, so it signals the exact resource and usage pattern to IG reviewers.

{==**What a protocol actually looks like.** A protocol is the reusable recipe card for a campaign type — the IG's `example-mr-sia-protocol` in full:

| Field | Value | Meaning |
|---|---|---|
| `version` | `1.0.0` | Protocols are versioned — "MR SIA per 2026 guidance" and its 2028 revision are distinct, citable things |
| `type` | `vaccination-sia` | What kind of campaign this is (the required campaign-type code) |
| `extension[deliveryStrategy]` | `fixed-post` **and** `house-to-house` | The strategies this campaign type uses — MR SIAs run posts, then mop up door-to-door |
| `goal` | "≥95% administrative coverage in every district, verified by post-campaign survey" | The coverage target every execution inherits |
| `action` | → "Administer MCV, 9 months–14 years" (`example-mcv-activity`) | The activity sequence; a bigger protocol lists several actions — vaccinate, then mop up — each pointing at its ActivityDefinition |

Every execution then points back at it: the national umbrella and the Kambia round both carry `instantiatesCanonical → example-mr-sia-protocol`. That single link is what makes "all MR SIA rounds, anywhere, comparable" a query instead of a research project — and it is why `instantiatesCanonical` is 1..1.==}{>>ADDED in v0.4.0 (your c7/c44): the inline protocol walk-through.<<}{id="c51" by="claude" at="2026-06-13T01:31:20.000Z" re="c44"}

{==**The protocol as FHIR/JSON.** The same `example-mr-sia-protocol`, rendered (the fields a reviewer cares about; `meta.text` and narrative elided):

```json
{
  "resourceType": "PlanDefinition",
  "id": "example-mr-sia-protocol",
  "meta": { "profile": ["https://fhir.icr.unicef.org/StructureDefinition/ICRCampaignProtocol"] },
  "status": "active",
  "version": "1.0.0",
  "title": "Measles–Rubella SIA — 2026 national guidance",
  "type": {
    "coding": [{
      "system": "https://fhir.icr.unicef.org/CodeSystem/icr-campaign-type",
      "code": "vaccination-sia"
    }]
  },
  "extension": [
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/delivery-strategy",
      "valueCodeableConcept": { "coding": [{
        "system": "https://fhir.icr.unicef.org/CodeSystem/icr-delivery-strategy",
        "code": "fixed-post"
      }] }
    },
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/delivery-strategy",
      "valueCodeableConcept": { "coding": [{
        "system": "https://fhir.icr.unicef.org/CodeSystem/icr-delivery-strategy",
        "code": "house-to-house"
      }] }
    }
  ],
  "goal": [{
    "description": { "text": "≥95% administrative coverage in every district, verified by post-campaign survey" }
  }],
  "action": [{
    "title": "Administer MCV, 9 months–14 years",
    "definitionCanonical": "https://fhir.icr.unicef.org/ActivityDefinition/example-mcv-activity"
  }]
}
```

Annotated: `type` is the **required** campaign-type code (what kind of campaign this is); the two `delivery-strategy` extensions are the `1..*` repeat saying MR SIAs run posts **and** mop-up; `goal.description` is the coverage target every execution inherits; `action.definitionCanonical` is the wiring to the activity in §5.3 — **locked to `Canonical(ICRCampaignActivity)`**, so the protocol→activity link is machine-checked, not just narrated. Note what is **absent**: no geography, no dates, no denominator — those live on the executions (§5.2) that point back here via `instantiatesCanonical`.==}{>>ADDED in v0.5.0 (your c67): the protocol rendered as annotated FHIR/JSON, interlinked with the §5.3 activity it references.<<}{id="c68" by="agent" at="2026-06-15T18:30:00.000Z" re="c67"}

> {==[!warning] Questions==}{>>It would be helpful to get an example of what a campaign protocols would look. i don't really understand how this is structured.<<}{id="c7" by="mberg" at="2026-06-12T20:32:58.665Z"}{>>There IS one in the IG — `example-mr-sia-protocol` (ig/input/fsh/examples.fsh) — and its shape in plain terms: a protocol is the reusable recipe card for a campaign type. Concretely it holds (1) `type` = vaccination-sia — what kind of campaign this is; (2) the delivery strategies it uses — fixed-post AND house-to-house, because MR SIAs do both; (3) `goal` — "≥95% administrative coverage in every district, verified by post-campaign survey"; (4) `action` — the activity sequence, here one action pointing at the "Administer MCV, 9m–14y" ActivityDefinition (a bigger protocol would list several: vaccinate, then mop-up, each its own action); (5) version "1.0.0" — protocols are versioned, so "MR SIA per 2026 guidance" vs 2028 revision are distinct citable things. Then EVERY execution — national umbrella, each district round — points at it via instantiatesCanonical, which is what makes "all MR SIA rounds anywhere, comparable" a query instead of a research project. I'll inline a rendered walk-through of this example into §5.1 in the next rewrite so the structure is visible right here in the memo.<<}{id="c27" by="claude" at="2026-06-12T21:03:09.000Z" re="c7"}{>>great please add these details with an example inline in the doc when you do a rewrite.<<}{id="c44" by="mberg" at="2026-06-13T01:17:45.552Z" re="c27"}
> 
> 1. `type` is 1..1, but `PlanDefinition.type` semantically distinguishes plan kinds (order-set vs protocol…) in base FHIR — here it's repurposed for campaign type. Reasonable, but reviewers may ask whether `topic` or a dedicated extension is cleaner.
>   
> 2. No `library`/eligibility-logic story yet (age-band eligibility as CQL?) — presumably deferred along with the DAK alignment.
>   
> 
> _Resolved in first pass:_ `action.definition[x]` is now constrained to `Canonical(ICRCampaignActivity)`, so the protocol→activity wiring is machine-enforced.
### 5.2 ICRCampaign — `CarePlan` (the keystone)
{==_A specific campaign execution. Begins life as a microplan (_`intent=plan`_) and evolves into the execution record as Tasks complete and coverage accumulates. Rounds are sibling ICRCampaigns under an umbrella campaign via_ `partOf`_._ (working doc §7.2, §6.3)==}{>>Can we create a mermaid illustration and add a section showing how this works?<<}{id="c64" by="mberg" at="2026-06-15T17:15:15.708Z"}

{==**How a campaign moves through its life (`plan → order`).** A campaign is born as a *microplan* and matures into the *execution record* of the **same** `ICRCampaign` resource — `intent` flips `plan → order`, `status` walks `draft → active → completed`, and Tasks plus coverage accumulate against it. Rounds are sibling executions under a national umbrella via `partOf`, and every one of them points at the single versioned protocol:

```mermaid
graph LR
    PD["ICRCampaignProtocol<br/>(PlanDefinition)<br/>versioned recipe"]
    U["Umbrella ICRCampaign<br/>intent: plan · status: active<br/>subject: national denominator"]
    R1["Kambia round<br/>intent: order · status: completed<br/>subject: district denominator"]
    R2["Port Loko round<br/>intent: order · status: active"]
    T["ICRCampaignTask(s)<br/>→ delivery events"]
    PD -- "instantiatesCanonical 1..1" --> U
    PD -- "instantiatesCanonical 1..1" --> R1
    PD -- "instantiatesCanonical 1..1" --> R2
    R1 -- "partOf" --> U
    R2 -- "partOf" --> U
    R1 -- "activity.reference" --> T
```

The umbrella stays `intent = plan` — it is the planning shell that holds the national denominator and binds the rounds together; each round goes `plan → order` as it executes. Because every box points at the **same** protocol, "all MR SIA rounds, anywhere" is one query, not a research project (§5.1). The actual JSON for the umbrella and a round is below, after the who-vs-where explanation.==}{>>ADDED in v0.5.0 (your c64): a lifecycle diagram of the microplan→execution and umbrella→round flow.<<}{id="c69" by="agent" at="2026-06-15T18:30:00.000Z" re="c64"}

| Element | Constraint |
|---|---|
| `instantiatesCanonical` | **1..1 MS**, only `Canonical(ICRCampaignProtocol)` |
| `status` | MS — "draft → active → completed" |
| `intent` | MS — "plan (microplan) transitioning to order (execution)" |
| `category` | **1..\* MS**, bound **required** to ICRCampaignTypeVS |
| `subject` | MS, only `Reference(ICRTargetPopulation)` |
| `period` | **1..1 MS** — campaign/round dates |
| `careTeam`, `addresses` | MS (`addresses` = the disease/condition targeted) |
| `partOf` | only `Reference(ICRCampaign)` — umbrella/round pattern |
| `activity` | MS; `activity.reference` only `Reference(ICRCampaignTask)` |
| Extensions | `campaignRound` 0..1 MS (positiveInt) · `targetGeography` 0..\* MS (→Location) · `planningDenominator` 0..1 MS (→Group) · `dataLineage` 0..1 MS |

**Rationale.** CarePlan won over a custom resource, Encounter, and RequestGroup (design decision #1) because it natively supports plan→execution lifecycle, `instantiatesCanonical`, population subjects, and `partOf` composition. **Every campaign must point at its protocol** (1..1) — that is what makes campaign data reusable rather than ad-hoc. `subject` typed to ICRTargetPopulation makes the denominator a first-class participant rather than an afterthought; `planningDenominator` additionally disambiguates _which_ estimate is THE denominator when several exist (§6.2).

{=={==**Who vs where, and nested scopes.** Each CarePlan has exactly **one** `subject` — the WHO, an ICRTargetPopulation ("children 9m–14y, Kambia, 48,250"). The WHERE is separate and plural: `targetGeography` is 0..*, so one campaign can name several geographies. Multiple and nested populations are carried by the **umbrella/round stack**, not by overloading one CarePlan:==}{>>I'm a bit confused here.  So this means that the target would be like say a hundred thousand then you'd have multiple geographies with populations that equal with a hundred thousand. Is that how it works?<<}{id="c65" by="mberg" at="2026-06-15T17:16:32.246Z"}{>>Not quite — the geographies don't have to **sum** to the parent total, and a campaign's subject isn't "100k split across geographies." Each scope carries its **own** denominator from its **own** source: the national umbrella's subject is 2,150,000 (census projection, Nov 2025); the Kambia round's subject is 48,250 (GRID3, Jan 2026); Port Loko's round has its own. They nest *conceptually* (districts roll up to the nation via `partOf`) but they will **not** add up exactly, because they come from different methods at different times — and that mismatch is real and expected, not an error (it's the same denominator-disagreement the §6.2 walk-through is about). So: one denominator per CarePlan scope, as many CarePlans as scopes, linked by `partOf` — not a single number partitioned across geographies. The JSON just below makes the two scopes concrete.<<}{id="c70" by="agent" at="2026-06-15T18:30:00.000Z" re="c65"}

```mermaid
graph TD
    N["National umbrella CarePlan<br/>subject: 2,150,000 (census projection)"]
    D1["Kambia round CarePlan<br/>subject: 48,250 (GRID3)"]
    D2["Port Loko round CarePlan<br/>subject: its own denominator"]
    W["Per-ward targets<br/>more ICRTargetPopulations,<br/>each geography-scoped — referenced,<br/>not subjects"]
    D1 -- partOf --> N
    D2 -- partOf --> N
    D1 -.uses.-> W
```

One subject per CarePlan; as many CarePlans as the campaign has nested scopes, linked by `partOf`; finer-grained targets (per-ward) exist as additional geography-scoped ICRTargetPopulation Groups that planning and coverage reference without being anyone's `subject`.==}{>>ADDED in v0.4.0 (your c8): the who-vs-where explanation and nested-population stack, as promised in c28.<<}{id="c52" by="claude" at="2026-06-13T01:31:20.000Z" re="c28"}

{==**The campaign as FHIR/JSON — umbrella + round.** Two `ICRCampaign` (CarePlan) instances from the scenario. First the **national umbrella** (the microplan shell):

```json
{
  "resourceType": "CarePlan",
  "id": "example-mr-sia-national",
  "meta": { "profile": ["https://fhir.icr.unicef.org/StructureDefinition/ICRCampaign"] },
  "instantiatesCanonical": ["https://fhir.icr.unicef.org/PlanDefinition/example-mr-sia-protocol"],
  "status": "active",
  "intent": "plan",
  "category": [{ "coding": [{
    "system": "https://fhir.icr.unicef.org/CodeSystem/icr-campaign-type",
    "code": "vaccination-sia"
  }] }],
  "subject": { "reference": "Group/example-target-population-national" },
  "period": { "start": "2026-06-15", "end": "2026-12-18" },
  "addresses": [{ "display": "Measles and rubella" }],
  "extension": [{
    "url": "https://fhir.icr.unicef.org/StructureDefinition/planning-denominator",
    "valueReference": { "reference": "Group/example-target-population-national" }
  }]
}
```

Then the **Kambia June round**, a child execution of that umbrella:

```json
{
  "resourceType": "CarePlan",
  "id": "example-mr-sia-2026",
  "meta": { "profile": ["https://fhir.icr.unicef.org/StructureDefinition/ICRCampaign"] },
  "instantiatesCanonical": ["https://fhir.icr.unicef.org/PlanDefinition/example-mr-sia-protocol"],
  "status": "completed",
  "intent": "order",
  "category": [{ "coding": [{
    "system": "https://fhir.icr.unicef.org/CodeSystem/icr-campaign-type",
    "code": "vaccination-sia"
  }] }],
  "subject": { "reference": "Group/example-target-population" },
  "period": { "start": "2026-06-15", "end": "2026-06-26" },
  "partOf": [{ "reference": "CarePlan/example-mr-sia-national" }],
  "addresses": [{ "display": "Measles and rubella" }],
  "activity": [
    { "reference": { "reference": "Task/example-site-session-task" } },
    { "reference": { "reference": "Task/example-mopup-task" } }
  ],
  "extension": [
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/campaign-round",
      "valuePositiveInt": 1
    },
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/target-geography",
      "valueReference": { "reference": "Location/example-district" }
    },
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/planning-denominator",
      "valueReference": { "reference": "Group/example-target-population" }
    }
  ]
}
```

Annotated, reading the links out: `instantiatesCanonical` (**1..1**) makes both campaigns point at the one protocol in §5.1. `intent` is the lifecycle dial — the umbrella stays `plan`, the round is `order` (executing). `subject` is the WHO — each scope its own ICRTargetPopulation denominator Group (national 2,150,000 vs Kambia 48,250; §6.2), which is the concrete answer to c65: different numbers from different sources, *not* a partition of one total. `partOf` makes the round a child of the umbrella. `activity.reference` lists the round's Tasks (§5.4). The three extensions carry exactly what the protocol omits: which `campaign-round` this is, the `target-geography` (WHERE, `0..*` — here the district Location, §6.3), and the `planning-denominator` that singles out *the* denominator coverage is computed against. (`addresses` is R4 `Reference(Condition)` — shown here as a display-only reference for the disease.)==}{>>ADDED in v0.5.0 (your c66): the umbrella and round CarePlans as annotated FHIR/JSON, with every reference resolved to the section that defines its target.<<}{id="c71" by="agent" at="2026-06-15T18:30:00.000Z" re="c66"}

> [!warning] Questions
> 
> 1. `instantiatesCanonical` **1..1 is strict** — every ad-hoc/emergency campaign must first author a protocol. Is that the intended forcing function, or does it deserve a relief valve (0..1 with a flag)?
>   
> 2. {==`subject` only ICRTargetPopulation: a sub-national CarePlan whose subject is a _geography_ rather than a population must route through `targetGeography` instead. Is the split (subject=who, extension=where) clearly enough documented?==}{>>I don't understand this.  Please explain further.  A campaign could contain multiple target population/geographies.  They may be nested too.<<}{id="c8" by="mberg" at="2026-06-12T20:34:15.253Z"}{>>Unpacking. CarePlan.subject is a single slot answering "WHO is this plan for" — we point it at one ICRTargetPopulation Group (e.g. "children 9m–14y, Kambia, 48,250"). "WHERE" is separate: the target-geography extension, which is 0..* — a campaign can list MULTIPLE geographies already. Your multiple/nested case is exactly what the umbrella/round pattern carries: the national umbrella CarePlan has the national denominator as subject; each district round (partOf the umbrella) has its own district-level population; nesting falls out of partOf + each population's geography characteristic pointing at its admin level. So: one subject PER CarePlan, but as many CarePlans as the campaign has nested scopes — and within one round, finer-grained populations (per-ward targets) exist as additional ICRTargetPopulation Groups linked by geography, they just aren't THE subject. The memo's question was narrower: is this who-vs-where split documented clearly enough in the IG narrative — your confusion answers that (no). I'll add a worked explanation + diagram of the national→district→ward population stack in the rewrite.<<}{id="c28" by="claude" at="2026-06-12T21:03:09.000Z" re="c8"}
>   
> 3. The umbrella campaign is itself an ICRCampaign, so it too needs `instantiatesCanonical`, `category`, `subject`, `period` — i.e. the umbrella must carry its own (national) denominator. The new umbrella example demonstrates this works, but confirm it's the intended modeling burden.
>   
> 4. {==`dataLineage` is the only campaign extension _not_ marked MS — deliberate (lineage matters more on Task/MeasureReport) or an oversight?==}{>>I don't understand this elaborate further.<<}{id="c9" by="mberg" at="2026-06-12T20:35:14.865Z"}{>>Background first: MS = Must Support, a FHIR conformance flag meaning "implementations claiming conformance must be able to populate and process this element" — it's about implementation obligation, not whether data is required (that's cardinality). The observation here: ICRCampaign carries four extensions; three are flagged MS (campaign round, target geography, planning denominator) but dataLineage — the realtime-vs-reconciled flag — is not. Practical consequence: a conformant implementation may completely ignore lineage at the campaign level. That's defensible (lineage filtering really happens on Tasks and MeasureReports — a CarePlan is mostly metadata that doesn't get "reconciled"), but it was never stated as a decision, which is why I flagged it. Recommendation: mark it MS for consistency — costs implementers almost nothing — or write one sentence of rationale for why campaign-level lineage is optional. I'll do the former in the next IG pass unless you prefer the latter.<<}{id="c29" by="claude" at="2026-06-12T21:03:09.000Z" re="c9"}{>>APPLIED in v0.4.0: dataLineage is now MS on ICRCampaign (IG commit 4b49ab0) — the extensions row above reflects it.<<}{id="c53" by="claude" at="2026-06-13T01:31:20.000Z" re="c29"}
>   
> 5. {==`activity.reference` locked to Task only — excludes the R4 alternative `activity.detail` (inline activities). Worth stating in narrative that inline activities are out.==}{>>Can we create an example CarePlan in this section following the IG to illustrate how this works.  Show the actual JSON and annotate it.<<}{id="c66" by="mberg" at="2026-06-15T17:18:48.153Z"}
>   
### 5.3 ICRCampaignActivity — {==`ActivityDefinition`==}{>>Woud really help to have some real examples.<<}{id="c10" by="mberg" at="2026-06-12T20:36:45.686Z"}{>>One exists (`example-mcv-activity`: "Administer MCV, 9m–14y" — kind=Task, product=CVX 05, dosage "0.5 mL subcutaneous") but agreed, one isn't enough to make the concept land. In the rewrite I'll inline a trio spanning the campaign types: (1) "Administer albendazole, 5–14y" — ATC P02CA03, dose-pole-derived tablet count (Type C MDA); (2) "Distribute 1 ITN per 2 household members" — GS1 commodity, household-level (Type B-then-A); (3) "Spray interior structure walls" — IRS, structure-level (Type B). Together with the MCV one they show the point of the layer: the protocol carries the clinical/commodity content ONCE, and thousands of Tasks instantiate it without repeating it.<<}{id="c30" by="claude" at="2026-06-12T21:03:09.000Z" re="c10"}{>>Add this to the main text during rewrite<<}{id="c46" by="mberg" at="2026-06-13T01:20:49.728Z" re="c30"}
_A discrete work type within a campaign — "administer albendazole to children 5–14", "distribute ITNs to households" — instantiated as ICRCampaignTask resources._ (working doc §7.3)

| Element | Constraint |
|---|---|
| `status` | MS |
| `kind` | fixed `#Task` |
| `code` | **1..1 MS** — "The intervention: vaccinate / treat / distribute / spray" |
| `product[x]` | MS — "Vaccine (CVX) / drug (ATC) / commodity (GS1)" |
| `dosage` | MS — "Where applicable; dose-pole logic references an Observation" |
| `extension[deliveryStrategy]` | 0..1 MS |

{==**The activity gallery.** Four ActivityDefinitions now ship in the IG, spanning the campaign types — each says only WHAT, never which concrete target:

| Instance | Intervention | Product | Dosage / rule |
|---|---|---|---|
| `example-mcv-activity` | Vaccinate (Type A/B) | CVX `05` measles virus vaccine | 0.5 mL subcutaneous, single dose |
| `example-albendazole-activity` | Treat (Type C MDA) | ATC `P02CA03` albendazole | 400 mg single dose; tablet count by **dose-pole height band** |
| `example-itn-activity` | Distribute (Type B→A) | LLIN (free-text pending GS1) | 1 net per 2 household members |
| `example-irs-activity` | Spray (Type B) | Pirimiphos-methyl 300CS | interior walls of eligible structures |

**What lives here vs what lives on the Task.** The ActivityDefinition is deliberately **target-agnostic**: it carries the intervention, product, and dosage rule — and at most the _kind_ of eligible target (`subject[x]` can say "children 9m–14y" as a category). The concrete thing acted on — THIS household, THIS structure, THIS school session — is each **Task's** `focus`, assigned per unit of work. So "spray house" Tasks focus on structures (Locations), "vaccinate" Tasks focus on households (Groups) with per-child detail in the Immunization records off `Task.output`, and a hypothetical "set fly trap" activity would produce Tasks focusing on trap sites. The protocol carries the clinical/commodity content **once**; thousands of Tasks instantiate it without repeating it. (Boundary note: vector-control work like traps and larviciding is outside the v0.1 program scope and has no delivery-event profile — flag it if entomological surveillance enters ICR's future.)==}{>>ADDED in v0.4.0 (your c10/c46 + c11/c47): the activity gallery is in the IG as real instances (commit 4b49ab0) and the what-vs-focus explanation is now main text.<<}{id="c54" by="claude" at="2026-06-13T01:31:20.000Z" re="c46"}

{==**Rationale.** `kind = #Task` hard-wires the instantiation target: activities become Tasks, not ServiceRequests. Product and dosage ride on the definition so the protocol carries the clinical content once.==}{>>Do activityies need to have a focus? or can that be defined at the task level.  Eg if the activity is spray house then the target would be the household structure.  if it's vaccinate it would be a child in the household, if it's get a fly trap it wouldl be the fly trap.<<}{id="c11" by="mberg" at="2026-06-12T20:42:16.549Z"}{>>Exactly as you intuit: defined at the Task level. The ActivityDefinition is deliberately target-agnostic — it says WHAT (spray / vaccinate / set trap, with product and dosage) and at most what KIND of target is eligible (subject[x] can say "children 9m–14y" as a category); the concrete thing acted on — THIS structure, THIS child's household, THIS trap site — is Task.focus, per unit of work. Your three examples land as: spray-house activity → Tasks whose focus is each structure (a Location); vaccinate activity → Tasks whose focus is the household Group, with the per-child detail in the Immunization records hanging off Task.output (see my c32 reply below on the per-member question); fly-trap activity → Tasks whose focus is the trap site (a Location). One honest gap your examples expose: vector-control work (traps, larviciding) is in neither the working doc's program scope nor the delivery-event profiles — fine for v0.1, but if entomological surveillance is in ICR's future, flag it now and I'll add it to the open questions.<<}{id="c31" by="claude" at="2026-06-12T21:03:09.000Z" re="c11"}{>>flesh this out in the rewrite<<}{id="c47" by="mberg" at="2026-06-13T01:21:24.473Z" re="c31"}{>>APPLIED in v0.4.0: fleshed out in the "activity gallery / what lives here vs what lives on the Task" block just above this paragraph, with your three examples (spray→structure, vaccinate→household+Immunizations, fly trap→site) worked in and the vector-control scope boundary noted.<<}{id="c55" by="claude" at="2026-06-13T01:31:20.000Z" re="c47"}

{==**The activity as FHIR/JSON.** `example-mcv-activity` — the activity the protocol's `action` points at:

```json
{
  "resourceType": "ActivityDefinition",
  "id": "example-mcv-activity",
  "meta": { "profile": ["https://fhir.icr.unicef.org/StructureDefinition/ICRCampaignActivity"] },
  "status": "active",
  "name": "AdministerMCV",
  "title": "Administer MCV, 9 months–14 years",
  "kind": "Task",
  "code": { "text": "Vaccinate — measles–rubella–containing vaccine" },
  "productCodeableConcept": {
    "coding": [{ "system": "http://hl7.org/fhir/sid/cvx", "code": "05", "display": "measles virus vaccine" }]
  },
  "dosage": [{
    "route": { "text": "subcutaneous" },
    "doseAndRate": [{ "doseQuantity": {
      "value": 0.5, "unit": "mL", "system": "http://unitsofmeasure.org", "code": "mL"
    } }]
  }],
  "extension": [{
    "url": "https://fhir.icr.unicef.org/StructureDefinition/delivery-strategy",
    "valueCodeableConcept": { "coding": [{
      "system": "https://fhir.icr.unicef.org/CodeSystem/icr-delivery-strategy",
      "code": "fixed-post"
    }] }
  }]
}
```

Annotated: `kind` is **fixed to `Task`** — instantiating this activity produces ICRCampaignTasks (§5.4), not ServiceRequests; `code` is the intervention; `productCodeableConcept` is the CVX vaccine code (the albendazole / ITN / IRS activities in the gallery above swap in an ATC code or free-text product instead); `dosage` rides on the definition so the clinical content is stated **once**. What's *not* here is any concrete target — no household, no child: the activity is target-agnostic, and the thing acted on is each Task's `focus`. The same shape holds for the other three gallery activities.==}{>>ADDED in v0.5.0 (your c10/c67): the activity as annotated FHIR/JSON, the product end of the §5.1 `action.definitionCanonical` link.<<}{id="c72" by="agent" at="2026-06-15T18:30:00.000Z" re="c67"}

> [!warning] Questions
> 
> 1. `product[x]` is MS but **unbound** — CVX/ATC are mentioned in the `^short` only. The delivery-event profiles do bind product codes; should the definition side bind too, for consistency?
>   
> 2. `deliveryStrategy` is 0..1 here but 1..* on the protocol and 1..1 on the Task — the asymmetry is defensible (strategy resolved per-task) but worth a sentence of narrative.
>   
> 
> _Resolved in first pass:_ an example now exists (`example-mcv-activity`), and the protocol example wires it in via `action.definitionCanonical`.
### 5.4 ICRCampaignTask — `Task`
_The assignable, trackable operational unit of work — one Task per site-session (Type A, focus = the site Location) or per household_ {==_(Type B, focus = the household Group)_==}{>>This can also go down to a household member within a household.  Eg a polio would be at the household member level not household.  The task could be to visit the household but would be recored with multiple immunizations. would that close one task or would you record a task for each child vaccinated?<<}{id="c12" by="mberg" at="2026-06-12T20:43:38.912Z"}{>>As drafted: ONE Task per household visit, closed when the visit completes — and the per-child records are the Immunization resources hanging off Task.output (one per child vaccinated, each pointing at its Patient). So polio IS captured at member level, just in the delivery-event layer rather than the Task layer: the Task is the unit of WORK (one doorstep visit), the Immunizations are the units of SERVICE (three drops given). The IG's mop-up example shows exactly this — one household Task, output → the MCV dose for Aminata. You COULD model a Task per child, but it multiplies Task volume ~5× (the open-question-#1 scale concern) while adding nothing the Immunization records don't already carry. The one place a per-child Task IS the right tool: follow-up — a specific missed/zero-dose child spawns a new Task targeting that child (the §4.4 routine-enrolment pattern). Caveat: Task.focus is currently narrowed to ICRDeliveryUnit|ICRLocation, so a child-targeted follow-up Task doesn't conform — I'll widen focus to include Patient (or add the follow-up pattern explicitly) in the next IG pass. Good catch.<<}{id="c32" by="claude" at="2026-06-12T21:03:09.000Z" re="c12"}{>>ok this sounds good. let's document this better in the text during the rewrtie but call out the exception.<<}{id="c48" by="mberg" at="2026-06-13T01:23:26.588Z" re="c32"}_. Tasks may be pre-planned from the microplan or field-registered on discovery (the required task-origin code records which). Whether Tasks are assigned at village or household level is a configuration choice._ (working doc §7.4)

| Element | Constraint |
|---|---|
| `status` | MS — "requested → in-progress → completed / failed" |
| `intent`, `for`, `owner`, `executionPeriod`, `output` | MS |
| `code` | **1..1 MS** |
| `focus` | **1..1 MS**, only `Reference(ICRDeliveryUnit or ICRLocation or Patient)` — "site Location (Type A), household/community delivery-unit Group (Type B/C), or — for person-targeted follow-up tasks only — a Patient" |
| `location` | **1..1 MS**, only `Reference(ICRLocation)` |
| `output` | MS — "references to Immunization / MedicationAdministration / SupplyDelivery, or aggregate counts" |
| Extensions | `deliveryStrategy` **1..1 MS** · `taskOrigin` **1..1 MS** (code: pre-planned \| field-registered, required binding) · `housesVisited` 0..1 · `eligiblePresent` 0..1 · `eligibleAbsent` 0..1 · `missedReason` 0..\* · `noncomplianceReason` 0..\* · `fingerMarked` 0..1 · `dataLineage` 0..1 |

{==**Task granularity: one Task per visit, person-level detail in the delivery events.** A polio team's doorstep visit is **one** Task — it closes when the visit completes — and each child vaccinated gets their own `Immunization` resource hanging off `Task.output`, pointing at their `Patient`. So person-level capture happens in the **delivery-event layer**, not by multiplying Tasks: the Task is the unit of _work_ (one visit), the delivery events are the units of _service_ (three drops given). The IG's mop-up example shows the full chain: one household Task → output → the MCV dose for one child. **The deliberate exception is person-targeted follow-up**: when a specific missed or zero-dose child needs chasing, a new Task is spawned whose `focus` IS that child's `Patient` record (the §4.4 routine-enrolment pattern) — which is exactly why `focus` allows `Patient` alongside the delivery-unit Group and the site Location, and it is the _only_ intended use of a person-focused Task. Routine per-child Tasks would multiply Task volume ~5× (the open-question-#1 scale concern) while adding nothing the Immunization records don't already carry.==}{>>ADDED in v0.4.0 (your c12/c48): the one-Task-per-visit pattern documented with the follow-up exception called out; Task.focus widened to admit Patient for exactly that case (IG commit 4b49ab0).<<}{id="c56" by="claude" at="2026-06-13T01:31:20.000Z" re="c48"}

**Rationale.** This is where campaign type A/B/C polymorphism lands: the _same_ profile serves a fixed-post site-session and a house-to-house visit, discriminated by `focus` type and the mandatory coded `deliveryStrategy`. The optional count/reason extensions are exactly the house-to-house data elements (houses visited, present/absent, missed/noncompliance reasons, finger marking) that only exist for strategy B — they're 0..x because they're meaningless for fixed-post tallies. `taskOrigin` **is mandatory** (the same required-coded-attribute pattern as delivery strategy and record origin): Tasks need not be pre-generated — a team that discovers an unenumerated household creates the ICRDeliveryUnit and its Task on the spot — and the count of field-registered Tasks per area is itself a measurement of how incomplete the microplan's enumeration was, feeding the next round's denominators. Delivery events hang off `Task.output` because **R4 Immunization has no** `basedOn` (the reverse link doesn't exist; see §7).

{==**The Task as FHIR/JSON.** `example-mopup-task` — the Type-B house-to-house visit, the richer of the two Task shapes and the one that chains to a delivery event:

```json
{
  "resourceType": "Task",
  "id": "example-mopup-task",
  "meta": { "profile": ["https://fhir.icr.unicef.org/StructureDefinition/ICRCampaignTask"] },
  "status": "completed",
  "intent": "order",
  "code": { "text": "Administer MCV — house-to-house mop-up visit" },
  "focus": { "reference": "Group/example-household" },
  "for": { "reference": "Group/example-household" },
  "location": { "reference": "Location/example-dwelling" },
  "executionPeriod": { "start": "2026-06-24", "end": "2026-06-24" },
  "owner": { "display": "CDD team 7, Rokupr" },
  "output": [{
    "type": { "text": "Immunization administered" },
    "valueReference": { "reference": "Immunization/example-mcv-dose" }
  }],
  "extension": [
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/delivery-strategy",
      "valueCodeableConcept": { "coding": [{
        "system": "https://fhir.icr.unicef.org/CodeSystem/icr-delivery-strategy",
        "code": "house-to-house"
      }] }
    },
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/task-origin",
      "valueCode": "field-registered"
    },
    { "url": "https://fhir.icr.unicef.org/StructureDefinition/eligible-present", "valueUnsignedInt": 2 },
    { "url": "https://fhir.icr.unicef.org/StructureDefinition/eligible-absent", "valueUnsignedInt": 1 },
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/missed-reason",
      "valueCodeableConcept": { "coding": [{
        "system": "https://fhir.icr.unicef.org/CodeSystem/icr-missed-reason",
        "code": "absent"
      }] }
    },
    { "url": "https://fhir.icr.unicef.org/StructureDefinition/finger-marked", "valueBoolean": true }
  ]
}
```

Annotated, with the links read out: `focus` and `for` point at the **household delivery-unit Group** (§6.1) — this is the Type-B shape (a Type-A site-session Task instead focuses on the fixed-post Location); `location` is where the work happened (the dwelling, §6.3). `output` is the **whole Task→event mechanism** — it references the `Immunization` in §7.1 (R4 Immunization has no `basedOn`, so the link runs this way). The mandatory coded extensions are `delivery-strategy` (1..1) and `task-origin` — here **`field-registered`**, the discovery-mode pattern: this household wasn't in the microplan; the team created it and its Task on the doorstep. The house-to-house tally extensions (`eligible-present` 2 / `eligible-absent` 1, `missed-reason absent`, `finger-marked`) only exist for strategy B — they'd be meaningless on a fixed-post session.==}{>>ADDED in v0.5.0 (your c12/c67): the Task as annotated FHIR/JSON, showing the `Task.output → Immunization` chain into §7.1.<<}{id="c73" by="agent" at="2026-06-15T18:30:00.000Z" re="c67"}

> [!warning] Questions
> 
> 1. **Task granularity at scale** is the IG's own #1 open question (one Task per household × national campaign = millions of Tasks). The profile keeps both options open — and field-registration (lazy Task creation on discovery) softens the pre-generation side of the worst case — but make sure pilots test the household-level path.
>   
> 2. _(Resolved in second pass; amended in third.)_ `focus` was narrowed to `ICRDeliveryUnit or ICRLocation` once ICRDeliveryUnit generalized the household profile — and then widened to also admit `Patient`, exclusively for person-targeted follow-up tasks (see the granularity block above).
>   
> 3. The count extensions (`housesVisited`, `eligiblePresent`/`Absent`) are unsignedInt **point values** — no age-band or sex disaggregation. Real tally sheets disaggregate; is the answer "use `output` with aggregate counts" and if so, where's the pattern documented?
>   
> 4. `missedReason`/`noncompliance` at Task level aggregates over the whole visit — per-child reasons would need person-level records. Worth stating which level the data is expected at.
>   
> 5. No constraint ties `output.valueReference` to the three delivery-event profiles — the `^short` says it; the profile doesn't enforce it.
>   
> 6. `taskOrigin` 1..1 means **retrofitting existing datasets requires assigning an origin** — acceptable forcing function, or should historical imports get a third code (`unknown`)?
>   

* * *
## 6. Population & geography profiles (`profiles-population.fsh`)
### 6.1 ICRDeliveryUnit — `Group` (household / community / school cohort)
_The actual Group of people a campaign Task acts on — a household (Type B house-to-house), a community (Type C MDA), or a school cohort (school-based delivery), distinguished by the required group-kind code. The validated Group + Location pattern, generalized: the Group is who, the Location (group-location extension) is where it lives or is based — the dwelling for a household, the settlement or community point for a community, the school for a school cohort. Type A's delivery unit is a site, which is a Location, not a Group._ (working doc §3.2, §7.5, §9.1)

| Element | Constraint |
|---|---|
| `type` | fixed `#person` |
| `actual` | fixed `true` |
| `code` | **1..1 MS**, bound **required** to ICRGroupKindVS (`household` \| `community` \| `school-cohort`) |
| `member` | MS; `member.entity` only `Reference(Patient)` |
| `quantity` | MS — "Group size where individuals are not enumerated" |
| `extension[groupLocation]` | **1..1 MS** → `Reference(ICRLocation)` — **residence/base, not service point**: the dwelling (household), settlement/community point (community), or school (school-cohort) |

**Rationale.** Separating _who_ (Group) from _where_ (Location) means the location's identity (GERS building/place ID) survives group composition changes, and the group survives re-mapping. The second-pass generalization (was: ICRHousehold) reflects that households and communities are the _same pattern at two scales_ — one profile with a coded kind beats two near-identical profiles, and it lets `Task.focus` and `MedicationAdministration.subject` be narrowed to ICR-conformant targets; `school-cohort` (third pass) demonstrates the kind list extends to non-obvious delivery units (nomadic groups, camp populations) as country demand appears. `quantity` covers the common case where campaigns count members without registering individuals — person-level `member` entries are optional by design. {==`groupLocation` **is residence, not service point**: where service actually happened is `Task.location` and the delivery event's own `location`. A household that walks to a village distribution center keeps its dwelling here unchanged — the Task records the center.==}{>>ADDED in v0.4.0 (your c13): the residence-vs-service-point decoupling stated explicitly, here and in the IG extension definition.<<}{id="c57" by="claude" at="2026-06-13T01:31:20.000Z" re="c33"}

{==**The delivery unit as FHIR/JSON.** `example-household` — the Type-B unit a mop-up Task focuses on:

```json
{
  "resourceType": "Group",
  "id": "example-household",
  "meta": { "profile": ["https://fhir.icr.unicef.org/StructureDefinition/ICRDeliveryUnit"] },
  "type": "person",
  "actual": true,
  "code": { "coding": [{
    "system": "https://fhir.icr.unicef.org/CodeSystem/icr-group-kind",
    "code": "household"
  }] },
  "quantity": 6,
  "member": [{ "entity": { "reference": "Patient/example-child" } }],
  "extension": [{
    "url": "https://fhir.icr.unicef.org/StructureDefinition/group-location",
    "valueReference": { "reference": "Location/example-dwelling" }
  }]
}
```

Annotated: `code` is the **required** group-kind (`household` here; `community` or `school-cohort` for the other delivery units, same profile); `quantity` 6 is the head-count even though only one `member` (the child, `Patient/example-child`, §7.1) is individually enumerated; `group-location` is the dwelling Location (§6.3) — **residence, not service point** (where service actually happened is the Task's `location`). Swap `code` to `community` and point `group-location` at a settlement and this same JSON becomes the Type-C community delivery unit.==}{>>ADDED in v0.5.0 (your c67): the delivery-unit Group as annotated FHIR/JSON, the target of the §5.4 Task `focus`.<<}{id="c74" by="agent" at="2026-06-15T18:30:00.000Z" re="c67"}

> [!warning] Questions
> 
> 1. {==No `Group.identifier` guidance — how is a _household_ itself identified across campaigns (vs its dwelling)? The cross-campaign record-linkage question is acknowledged as open; flagging that the profile is silent here.==}{>>I think an open question is should the structure be linked to the household or can it be different.  For some campaigns households will go to a village center to receive the service so that needs to be decoupled.<<}{id="c13" by="mberg" at="2026-06-12T20:45:06.704Z"}{>>Good news: they're already decoupled. The groupLocation extension on the household answers "where does this household LIVE" (the dwelling — its stable identity anchor), while where service happened is a different element entirely: Task.location / Immunization.location. So your village-center case works today: household's groupLocation stays the dwelling; the Task for the distribution has location = the village center; the household members' delivery events record the center too. The dwelling link never moves. What I'd add in the rewrite is a sentence making this explicit — "groupLocation is residence, not service point" — because you're the second person to read it as where-service-happens, which means the doc invites the misreading.<<}{id="c33" by="claude" at="2026-06-12T21:03:09.000Z" re="c13"}
>   
> 2. {==`actual = true` + `type = #person` is right, but `member.entity` locked to Patient excludes RelatedPerson — fine for campaigns, just confirming it's deliberate.==}{>>Need to discuss this further.  Is everyone in fhir a patient or are there person resource?<<}{id="c14" by="mberg" at="2026-06-12T20:46:02.602Z"}{>>FHIR has four person-shaped resources: Patient (anyone receiving care — despite the name, a healthy child getting a polio drop or a household member receiving a net is a Patient; it's the resource ALL clinical/delivery records point at, e.g. Immunization.patient can ONLY reference Patient), RelatedPerson (someone in relation to a patient — a caregiver consenting for a child), Practitioner (workers — our CDDs and vaccinators), and Person (a linkage resource: one human matched across multiple Patient/Practitioner records in different systems — identity plumbing, not a care-record subject; it may matter later for cross-campaign person dedup, open question #9). So for ICR: every enumerated household member who might receive a service is a Patient — the standard pattern in household-registration systems (it's how OpenSRP does it). And a correction to my own q2 while we're here: R4 Group.member doesn't permit RelatedPerson at all (that arrives in R5), so "locked to Patient" excludes Practitioner/Device etc., not RelatedPerson — I'll fix that sentence in the rewrite.<<}{id="c34" by="claude" at="2026-06-12T21:03:09.000Z" re="c14"}
>   
> 3. _(Resolved in third pass.)_ `school-cohort` added as the third group kind (with FR designation), per your c49 — chosen over nomadic/camp/institutional candidates to demonstrate extensibility with a clearly in-scope case; the others wait for pilot demand.
>   
> 
> _Resolved in first pass:_ `groupLocation` (née `householdLocation`) targets `Reference(ICRLocation)`. _Resolved in second pass:_ the household/community split (working-doc comment c72) — one profile, required coded kind. _Note on q2's wording (my error, caught in the c14 thread):_ R4 `Group.member` never allowed RelatedPerson — locking to Patient excludes Practitioner/Device/etc., and RelatedPerson membership only arrives in R5.
### 6.2 ICRTargetPopulation — `Group`
_A target-population denominator: a conceptual cohort (_`actual=false`_) with a count, eligibility characteristics, and — critically — source and date provenance. Multiple competing estimates per geography are retained; exactly one is flagged as the planning denominator._ (working doc §7.6, §4.2)

| Element | Constraint |
|---|---|
| `type` | fixed `#person` |
| `actual` | fixed `false` |
| `quantity` | **1..1 MS** — the denominator count |
| `characteristic` | MS — "Age band, sex, eligibility rule, geography"; **sliced (pattern on `code`, open)** |
| `characteristic[geography]` | 0..1 MS — `code` fixed to `icr-group-characteristic-cs#geography`; `value[x]` only `Reference(ICRLocation)`; `exclude` fixed `false` |
| Extensions | `denominatorSource` **1..1 MS** (CodeableConcept, extensible) · `estimateDate` **1..1 MS** (date) · `isPlanningDenominator` 0..1 MS (boolean) · `confidence` 0..1 (string) |

{==**Rationale.** Design decision #6 ("denominator-first"): the denominator is the dominant error source in campaign analytics, so an estimate without source+date is not allowed to exist — both provenance extensions are **mandatory**. Keeping _competing_ estimates (census projection vs GRID3 vs microcensus) as sibling Groups and flagging one==}{>>This sounds good. can we illustrate with some examples?<<}{id="c15" by="mberg" at="2026-06-12T20:47:18.444Z"}{>>The IG's two example denominators already show half the story — Kambia district: 48,250 from GRID3 (Jan 2026), flagged planning denominator; national: 2,150,000 from census projection (Nov 2025) — i.e. different sources at different levels coexisting. What's missing is true COMPETITION: two estimates for the SAME geography. In the rewrite I'll add a third instance — Kambia again, but from house-to-house microcensus enumeration (say 51,800, Mar 2026, isPlanningDenominator=false) — so the example set shows the actual scenario the design exists for: GRID3 says 48k, enumeration says 52k, both retained with source+date, exactly one flagged as what coverage is computed against, and the 7% disagreement is visible instead of silently overwritten. (That disagreement is the §4.1 Cuamba lesson upstream: the denominator you pick changes the coverage you report.)<<}{id="c35" by="claude" at="2026-06-12T21:03:09.000Z" re="c15"} (`isPlanningDenominator`) preserves the audit trail instead of overwriting. The second-pass **geography characteristic** makes the estimate's scope computable at **any level** — country, district, ward, settlement, or operational area (working-doc comment c70: target populations are _not_ household-bound; that's what ICRDeliveryUnit is for) — so estimates are joinable to the location hierarchy by reference, not by parsing `name`.

{==**Worked example — competing denominators, as shipped in the IG.** Three ICRTargetPopulation instances now tell the whole story:

| Instance | Geography | Count | Source | Date | Planning? |
| --- | --- | --- | --- | --- | --- |
| `example-target-population` | → Kambia District | **48,250** | GRID3 modelled | 2026-01-15 | **true** |
| `example-target-population-enumerated` | → Kambia District | **51,800** | microcensus / H2H enumeration | 2026-03-02 | false |
| `example-target-population-national` | → Sierra Leone | 2,150,000 | census projection | 2025-11-30 | true (national) |

The first two are **the same geography disagreeing by ~7%**: GRID3 says 48k, the enumeration says 52k. Both are retained — each with its source and date — and exactly one carries the planning flag, so coverage is computed against a _declared_ choice while the disagreement stays visible instead of being silently overwritten. Run the consequence: 47,766 children reached is **99% coverage against GRID3 but 92% against the enumeration** — the denominator you pick changes the answer, which is the §4.1 Cuamba lesson in miniature and the entire reason source + date are mandatory.==}{>>ADDED in v0.4.0 (your c15/c19): the competing-denominator walk-through; the third (enumeration) instance is new in the IG (commit 4b49ab0).<<}{id="c58" by="claude" at="2026-06-13T01:31:20.000Z" re="c35"}

{==**The denominator as FHIR/JSON.** `example-target-population` — Kambia's GRID3 planning denominator (the `subject` of the round CarePlan in §5.2):

```json
{
  "resourceType": "Group",
  "id": "example-target-population",
  "meta": { "profile": ["https://fhir.icr.unicef.org/StructureDefinition/ICRTargetPopulation"] },
  "type": "person",
  "actual": false,
  "quantity": 48250,
  "characteristic": [{
    "code": { "coding": [{
      "system": "https://fhir.icr.unicef.org/CodeSystem/icr-group-characteristic",
      "code": "geography"
    }] },
    "valueReference": { "reference": "Location/example-district" },
    "exclude": false
  }],
  "extension": [
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/denominator-source",
      "valueCodeableConcept": { "coding": [{
        "system": "https://fhir.icr.unicef.org/CodeSystem/icr-denominator-source",
        "code": "grid3"
      }] }
    },
    { "url": "https://fhir.icr.unicef.org/StructureDefinition/estimate-date", "valueDate": "2026-01-15" },
    { "url": "https://fhir.icr.unicef.org/StructureDefinition/is-planning-denominator", "valueBoolean": true }
  ]
}
```

Annotated: `actual: false` is what makes this a *conceptual cohort* — a denominator, not a roster of real people (contrast `example-household`, `actual: true`). `quantity` is the denominator count. The `geography` characteristic is the **computable** scope link — `valueReference` → the district Location (§6.3), so estimates join to the hierarchy by reference, not by parsing a name. The two provenance extensions are **mandatory** (`denominator-source: grid3`, `estimate-date: 2026-01-15`) — no denominator without source + date. `is-planning-denominator: true` flags this as *the* one coverage is computed against. The competing `example-target-population-enumerated` (51,800, microcensus, `is-planning-denominator: false`) is the identical shape with a different source, date, and flag — which is exactly how the same geography keeps two disagreeing estimates side by side.==}{>>ADDED in v0.5.0 (your c67): the planning denominator as annotated FHIR/JSON, the `subject` end of the §5.2 CarePlan.<<}{id="c75" by="agent" at="2026-06-15T18:30:00.000Z" re="c67"}

> [!warning] Questions
> 
> 1. **"Exactly one is the planning denominator" is not machine-enforced** — no invariant prevents two Groups for the same geography both setting the flag true (or none). Enforceable only with an invariant scoped to "same geography + campaign", which is hard; the `ICRCampaign.planningDenominator` extension (which _is_ singular, 0..1) may be the real enforcement point. Worth documenting that resolution.
>   
> 2. _(Resolved in second pass.)_ Geography linkage is now a profiled characteristic slice — `code = geography`, `valueReference(ICRLocation)` — and all three example denominators exercise it (district ×2 and country). Remaining nuance: the slice is 0..1, so a geography-less estimate is still conformant; consider 1..1 once pilot data confirms every estimate has a Location.
>   
> 3. `confidence` as free string — fine for v0.1; consider coded confidence later.
>   
### 6.3 ICRLocation — `Location`
_The most-customized ICR resource: nested administrative hierarchy (6+ levels), operational geography linkable-but-distinct from admin units, GeoJSON boundaries, and multi-system geospatial identity — GERS IDs as the preferred cross-campaign join key, with P-codes and national codes as coequal aliases._ (working doc §7.7, §9)

| Element | Constraint |
|---|---|
| `name`, `status` | MS |
| `partOf` | MS, only `Reference(ICRLocation)` — "country → region → district → ward → settlement" |
| `physicalType` | MS — "jurisdiction / site / building / household" |
| `type` | MS, bound **extensible** to **ICRLocationTypeVS** — admin-unit / settlement / facility / school / community-distribution-point / temporary-post / household / **supervisory-area** / **operational-area** |
| `position` | MS — GPS point |
| `identifier` | MS, **sliced by `system` (value discriminator, open)**: `gers` 0..1 MS (system = `$GERSId`) · `pcode` 0..1 MS (system = `$PCode`) |
| `extension[boundary]` | 0..1 MS — GeoJSON Attachment, "the geometry Crosscut enriches and pushes back" |
| `extension[deliveryStrategy]` | 0..1 — "For delivery sites (fixed/temporary posts): the strategy this site serves" |
| `extension[overlaysAdminUnit]` | 0..\* → `Reference(ICRLocation)` — for operational geography: the admin unit(s) this area overlays |

{==**Rationale.** Design decision #8. Open slicing means national location codes coexist with GERS/P-codes without profile changes. The GERS `^short` carries an operationally crucial instruction: **record the Overture release version alongside the ID** (GERS IDs are stable but the registry versions).==}{>>We sohuld be able to assign multiple external ids to locations.  Ideally GERS  Id can be the unique identifier.  the system will need to generate an internal unique location id too.  In many cases new locations will not have a GERS ID.  The system will be built to try and update these new locations with a GERS ID after they have been added in an async way.<<}{id="c16" by="mberg" at="2026-06-12T20:50:18.299Z"}{>>The profile already supports every piece of that workflow: (1) multiple external IDs — identifier slicing is OPEN, so any number of identifier systems coexist (GERS, P-code, national facility code, project codes); (2) internal unique ID — every FHIR resource has a server-assigned Resource.id, so that's free; (3) GERS as 0..1 not 1..1 — precisely because new/unmapped locations won't have one at creation; (4) async enrichment — adding a GERS ID later is just an update to the Location appending the gers identifier slice, with FHIR versioning + Provenance recording when/how it was matched. So nothing blocks the build-flow you describe. What the IG does NOT yet say is that this async-enrichment loop is the EXPECTED lifecycle (create unmatched → conflate → backfill GERS — the §9.1 OSM→Overture loop, operationalized). I'll add that as explicit implementer guidance in the next IG pass, plus one open design point it raises: should an enrichment job also be allowed to MERGE two Locations it discovers are the same place (ties into the dedup open question #9)?<<}{id="c36" by="claude" at="2026-06-12T21:03:09.000Z" re="c16"}{>>APPLIED in v0.4.0: the IG background page now states the async-enrichment lifecycle as the EXPECTED workflow ("Location identity lifecycle: GERS enrichment" section, commit 4b49ab0) — create with internal id + national codes → async match against Overture (directly or via the OSM→Overture loop) → append the GERS identifier to the same resource with versioning + Provenance, recording the Overture release version — and parks the merge-on-enrichment question alongside the record-linkage open question.<<}{id="c59" by="claude" at="2026-06-13T01:31:20.000Z" re="c36"} The boundary extension mirrors the R5 standard extension on R4 (working doc §10 q6). {==The second-pass additions give **"operational ≠ administrative geography" a real mechanism** (working-doc comment c74): `partOf` can express only _one_ hierarchy, so a supervisory/operational area is typed via the new location-type codes and linked to the admin units it covers via `overlays-admin-unit` — that is what makes it linkable-but-distinct rather than just distinct.==}{>>I don't understand this explain it further.<<}{id="c17" by="mberg" at="2026-06-12T20:53:01.299Z"}{>>Plain version. The admin hierarchy is the official tree: country → district → ward, expressed by each Location's partOf pointing at its single parent. Campaign programs draw their OWN areas that don't respect that tree — a polio supervision zone might cover all of ward 3 plus half of ward 4. Problem: partOf gives a location exactly one parent, so the zone can't sit INSIDE the admin tree without lying about the hierarchy (which ward would be its parent?). Old state of the IG: we said "keep operational areas distinct" but gave you no way to relate them to admin units at all — distinct but UNLINKABLE, so you couldn't answer "which districts does zone 2's data roll up into?". The fix: the zone is its own Location, typed supervisory-area, NOT in any partOf chain, carrying an overlays-admin-unit extension that points at the admin unit(s) it covers (can be several). Concrete: example-supervisory-area "Kambia supervision zone 2" overlays Kambia District — so zone-level tallies can be related to district reporting, while the official hierarchy stays clean. That's all "linkable-but-distinct" means: distinct = not in the admin tree; linkable = the overlays pointer.<<}{id="c37" by="claude" at="2026-06-12T21:03:09.000Z" re="c17"}

{==**The location as FHIR/JSON.** `example-district` — Kambia District, showing the multi-system identity and the admin hierarchy:

```json
{
  "resourceType": "Location",
  "id": "example-district",
  "meta": { "profile": ["https://fhir.icr.unicef.org/StructureDefinition/ICRLocation"] },
  "status": "active",
  "name": "Kambia District",
  "physicalType": { "coding": [{
    "system": "http://terminology.hl7.org/CodeSystem/location-physical-type",
    "code": "jdn", "display": "Jurisdiction"
  }] },
  "type": [{ "coding": [{
    "system": "https://fhir.icr.unicef.org/CodeSystem/icr-location-type",
    "code": "admin-unit"
  }] }],
  "partOf": { "reference": "Location/example-country" },
  "identifier": [
    { "system": "https://fhir.icr.unicef.org/identifiers/pcode", "value": "SL0201" },
    { "system": "https://fhir.icr.unicef.org/identifiers/overture-gers", "value": "overture-division-kambia-example" }
  ]
}
```

Annotated: `partOf` climbs the admin tree (district → `example-country`; the full chain runs country → district → settlement → dwelling, each its own ICRLocation). `type` is the ICR location-type (`admin-unit`); `physicalType` carries the base-FHIR shape. The **sliced `identifier`** is the multi-system identity — a P-code **and** a GERS ID coexisting, each tagged by its `system` URI (the mechanism behind cross-campaign joins, §3); both slices are `0..1`, so a brand-new unmapped location can exist with national codes only and get its GERS ID back-filled async (the lifecycle described just above). A delivery-site Location (the fixed post) additionally carries a `delivery-strategy` extension; a supervisory area carries `overlays-admin-unit` *instead of* sitting in the `partOf` tree.==}{>>ADDED in v0.5.0 (your c67): a Location as annotated FHIR/JSON — the target shared by `target-geography`, the denominator's geography characteristic, and `group-location`.<<}{id="c76" by="agent" at="2026-06-15T18:30:00.000Z" re="c67"}

> [!warning] Questions
> 
> 1. **Overture release version has no field** — the `^short` says to record it, but there's no extension/element to put it in (Identifier has no version slot; `identifier.period` is a stretch). Needs a concrete pattern before pilot data exists.
>   
> 2. `partOf` only ICRLocation forces the _entire_ hierarchy to be ICR-conformant — pragmatic, but means you can't hang an ICR site off a non-ICR national registry Location without re-profiling it.
>   
> 3. Both GERS and P-code slices are 0..1 — so a Location with **no stable identifier at all** is conformant. Should at least one identifier be required at, say, admin-unit levels?
>   
> 4. The 6+-level `partOf` chain's query performance (deep `Location.partOf` recursion on mobile) is a flagged open question — nothing in the profile mitigates it (no `ancestor` denormalization extension). Fine for v0.1; track it.
>   
> 5. _(Resolved in second pass.)_ `Location.type` is now bound (extensible) to the new ICRLocationTypeVS. Note the base R4 binding on `Location.type` is also extensible (v3 ServiceDeliveryLocationRoleType); re-binding is common IG practice but a strict base-binding validator may flag codes like `supervisory-area` — worth a Connectathon sanity check.
>   
> 6. Should an operational area's `overlays-admin-unit` be **required** when `type = supervisory-area/operational-area`? An invariant could enforce it; left loose for v0.1.
>   

* * *
## 7. Delivery-event profiles (`profiles-delivery.fsh`)
All three share two design constants: a **mandatory** `record-origin` **extension (1..1 MS)** — campaign vs routine, so SIA doses never contaminate routine coverage analytics (working doc §4.4) — and the **Task→event link running through** `Task.output` because R4 Immunization has no `basedOn` element to point back with.
### 7.1 ICRImmunizationEvent — `Immunization`
| Element | Constraint |
|---|---|
| `status`, `patient`, `occurrence[x]`, `location`, `lotNumber`, `manufacturer`, `performer` | MS |
| `vaccineCode` | MS, bound **extensible** to the core FHIR vaccine-code VS (CVX) — "local codes map back via ConceptMap" |
| `protocolApplied` | MS — "Dose number / series — supports multi-dose campaigns (OCV) and routine integration" |
| `extension[recordOrigin]` | **1..1 MS** (code: campaign \| routine, required binding) |

`lotNumber`/`manufacturer` MS = lot accountability (AEFI traceability); `protocolApplied` is the bridge to routine-immunization series logic.

{==**The dose as FHIR/JSON.** `example-mcv-dose` — the delivery event the mop-up Task's `output` points at, closing the chain protocol → activity → campaign → task → **dose → patient**:

```json
{
  "resourceType": "Immunization",
  "id": "example-mcv-dose",
  "meta": { "profile": ["https://fhir.icr.unicef.org/StructureDefinition/ICRImmunizationEvent"] },
  "status": "completed",
  "vaccineCode": { "coding": [{ "system": "http://hl7.org/fhir/sid/cvx", "code": "05", "display": "measles virus vaccine" }] },
  "patient": { "reference": "Patient/example-child" },
  "occurrenceDateTime": "2026-06-24",
  "location": { "reference": "Location/example-dwelling" },
  "lotNumber": "MRV-2026-0412",
  "manufacturer": { "display": "Serum Institute of India" },
  "performer": [{ "actor": { "display": "CDD team 7, Rokupr" } }],
  "protocolApplied": [{ "doseNumberPositiveInt": 1 }],
  "extension": [{
    "url": "https://fhir.icr.unicef.org/StructureDefinition/record-origin",
    "valueCode": "campaign"
  }]
}
```

Annotated: `patient` is the **person-level capture** — the same `example-child` who is the household's `member` (§6.1) — which is how polio-style member-level data lands without multiplying Tasks (§5.4): one Task per visit, one Immunization per child off `Task.output`. `vaccineCode` is the CVX matching the activity's product (§5.3). The **mandatory** `record-origin: campaign` is the firewall keeping SIA doses out of routine coverage analytics. `lotNumber`/`manufacturer` give AEFI lot traceability; `protocolApplied.doseNumber` bridges to routine-series logic.==}{>>ADDED in v0.5.0 (your c67): the dose as annotated FHIR/JSON — the terminal link of the interlinked chain, `Task.output → Immunization → Patient`.<<}{id="c77" by="agent" at="2026-06-15T18:30:00.000Z" re="c67"}
### 7.2 ICRMedicationAdministration — `MedicationAdministration`
| Element | Constraint |
|---|---|
| `status`, `effective[x]` | MS |
| `medication[x]` | only CodeableConcept; bound **extensible** to ICRMDAMedicationVS (WHO ATC) |
| `subject` | MS, only `Reference(Patient or ICRDeliveryUnit)` — "the treated person, **or the community/household delivery-unit Group** for register-level capture" |
| `dosage` | MS — "Tablet count — usually derived from a dose-pole height band Observation" |
| `supportingInformation` | MS — "e.g. the dose-pole Observation the dosage was derived from" |
| Extensions | `recordOrigin` **1..1 MS** · `directlyObserved` 0..1 MS (boolean — MDA DOC protocol) |

The dose-pole pattern (dosage _derived from_ a height-band Observation referenced via `supportingInformation`) is the distinctly-MDA piece; `directlyObserved` captures the supervision protocol that distinguishes "handed out" from "swallowed".
### 7.3 ICRSupplyDelivery — `SupplyDelivery`
| Element | Constraint |
| --- | --- |
| `status` | MS  |
| `suppliedItem`, `suppliedItem.quantity`, `suppliedItem.item[x]` | MS — "GS1 GTIN-coded commodity where applicable" |
| `destination` | MS — "Where the commodity went (post, household)" |
| `extension[recordOrigin]` | **1..1 MS** |

> [!warning] Questions (delivery layer)
> 
> 1. **Aggregate vs individual records** is a flagged open question; these profiles are individual-event-shaped. `ICRMedicationAdministration.subject` pointing at a Group is the aggregate escape hatch — but Immunization.patient cannot be a Group in R4, so **type-A tally-only campaigns have no Immunization representation**; presumably aggregate counts live in `Task.output`/MeasureReport. The narrative should state this split explicitly.
>   
> 2. `vaccineCode` binds to the generic FHIR VS rather than an ICR-curated SIA vaccine subset — fine (extensible), but countries will ask which codes to use for MR/bOPV/nOPV2.
>   
> 3. No GS1 binding/alias for `suppliedItem.item[x]` (§3 q2). The ITN example uses free text only.
>   
> 4. `recordOrigin` is the only mandatory extension — `dataLineage` (realtime/reconciled) is _absent_ from delivery events (it lives on CarePlan/Task/MeasureReport). If individual events arrive in both streams, can a consumer tell? (Presumably via the parent Task — worth one narrative sentence.)
>   

* * *
## 8. Coverage profiles (`profiles-coverage.fsh`)
_Administrative and independently-measured coverage are distinct lineages of the same conceptual quantity — separately profiled, never merged._ (working doc §4.1; the recurring evidence: **Cuamba, Mozambique — ~99% admin vs ~76% survey**.) Measure definitions are meant to align with what ministries already owe: WHO JAP, ICG M&E minimum dataset, ESPEN treatment-coverage schema, WHO EPI — the `Measure` resources themselves are deferred (§13).
### 8.1 ICRAdministrativeCoverage — `MeasureReport`
| Element | Constraint |
| --- | --- |
| `status`, `type`, `reporter`, `group` | MS  |
| `period` | **1..1 MS** |
| Extensions | `coverageSource` **1..1 MS**, **fixed** `valueCode = #administrative` · `denominatorSource` 0..1 MS · `dataLineage` **1..1 MS** |
### 8.2 ICRSurveyCoverage — `MeasureReport`
| Element | Constraint |
|---|---|
| `status`, `type`, `reporter`, `group` | MS |
| `period` | **1..1 MS** |
| Extensions | `coverageSource` **1..1 MS**, value bound **required** to ICRIndependentCoverageSourceVS (survey \| lqas \| rcm) · `sampleDesign` 0..1 MS (string — "WHO 30×10 cluster survey…") · `dataLineage` **1..1 MS** |

**Rationale.** The "never merge" rule is enforced _structurally_: the admin profile pins `coverageSource` to the single code `administrative`; the survey profile re-binds the same extension to a value set that _excludes_ `administrative`. A resource can't be both. Admin coverage additionally carries its denominator's provenance (because admin coverage is only as good as its denominator). {==**Lineage is now required (1..1) on both coverage profiles** (third pass): coverage reports are where the realtime/reconciled distinction has teeth — preliminary in-campaign figures vs final close-out figures must be machine-distinguishable, including preliminary-vs-final survey results. Elsewhere (CarePlan, Task) the flag stays optional with a documented default: **absent ⇒ realtime**.==}{>>ADDED in v0.4.0 (your c20): both fixes from the c40 thread — documented default + 1..1 on coverage MeasureReports (commit 4b49ab0).<<}{id="c60" by="claude" at="2026-06-13T01:31:20.000Z" re="c40"}

{==**The coverage pair as FHIR/JSON — 99% vs 76%.** The two MeasureReports for the **same** Kambia round — the structural "never merge":

```json
{
  "resourceType": "MeasureReport",
  "id": "example-admin-coverage",
  "meta": { "profile": ["https://fhir.icr.unicef.org/StructureDefinition/ICRAdministrativeCoverage"] },
  "status": "complete",
  "type": "summary",
  "measure": "https://fhir.icr.unicef.org/Measure/icr-admin-coverage",
  "reporter": { "reference": "Location/example-district" },
  "period": { "start": "2026-06-15", "end": "2026-06-26" },
  "group": [{
    "measureScore": { "value": 0.99 },
    "population": [
      { "code": { "coding": [{ "system": "http://terminology.hl7.org/CodeSystem/measure-population", "code": "numerator" }] }, "count": 47766 },
      { "code": { "coding": [{ "system": "http://terminology.hl7.org/CodeSystem/measure-population", "code": "denominator" }] }, "count": 48250 }
    ]
  }],
  "extension": [
    { "url": "https://fhir.icr.unicef.org/StructureDefinition/coverage-source", "valueCode": "administrative" },
    { "url": "https://fhir.icr.unicef.org/StructureDefinition/denominator-source", "valueCodeableConcept": { "coding": [{ "system": "https://fhir.icr.unicef.org/CodeSystem/icr-denominator-source", "code": "grid3" }] } },
    { "url": "https://fhir.icr.unicef.org/StructureDefinition/realtime-vs-reconciled", "valueCode": "reconciled" }
  ]
}
```

```json
{
  "resourceType": "MeasureReport",
  "id": "example-survey-coverage",
  "meta": { "profile": ["https://fhir.icr.unicef.org/StructureDefinition/ICRSurveyCoverage"] },
  "status": "complete",
  "type": "summary",
  "measure": "https://fhir.icr.unicef.org/Measure/icr-survey-coverage",
  "reporter": { "reference": "Location/example-district" },
  "period": { "start": "2026-07-06", "end": "2026-07-12" },
  "group": [{ "measureScore": { "value": 0.76 } }],
  "extension": [
    { "url": "https://fhir.icr.unicef.org/StructureDefinition/coverage-source", "valueCode": "survey" },
    { "url": "https://fhir.icr.unicef.org/StructureDefinition/sample-design", "valueString": "WHO 30×10 cluster survey, post-campaign" },
    { "url": "https://fhir.icr.unicef.org/StructureDefinition/realtime-vs-reconciled", "valueCode": "reconciled" }
  ]
}
```

Annotated: the same conceptual quantity — coverage of the Kambia round — reported **23 points apart** (mirroring Cuamba's 99-vs-76). They can never be merged because `coverage-source` is structurally pinned: `administrative` is **fixed** on the first profile, and the survey profile binds the same extension to a value set that *excludes* `administrative`. The admin report shows its `numerator`/`denominator` populations (47,766 / 48,250 = 99% against GRID3 — against the enumerated 51,800 it would read 92%, §6.2); the survey carries its `sample-design` *instead of* a denominator (its denominator IS the sample). `realtime-vs-reconciled` is **1..1** on both — these are final close-out figures (`reconciled`), machine-distinguishable from preliminary in-campaign numbers.==}{>>ADDED in v0.5.0 (your c67): the admin-vs-survey coverage pair as annotated FHIR/JSON — the never-merge rule made literal.<<}{id="c78" by="agent" at="2026-06-15T18:30:00.000Z" re="c67"}

> [!warning] Questions
> 
> 1. MeasureReport-vs-Observation for coverage is a flagged open question; MeasureReport won for v0.1. The strongest argument to document: MeasureReport's numerator/denominator `group.population` structure matches coverage natively.
>   
> 2. Neither profile constrains `measure` (the canonical Measure being reported) — unavoidable until the Measure definitions ship, but it means v0.1 coverage reports aren't yet comparable by measure identity. (The new examples use placeholder canonicals under the ICR namespace.)
>   
> 3. _(Resolved in third pass.)_ `ICRSurveyCoverage` now carries `dataLineage` 1..1 — preliminary vs final survey results ARE a lineage distinction, answering this question in the affirmative. It still has no `denominatorSource` (correct: a survey's denominator is its sample design).
>   
> 
> _Resolved in first pass:_ sample design now has a home — the new `SampleDesign` extension (string, 0..1 MS) — and both profiles have examples (`example-admin-coverage` / `example-survey-coverage`, a 99%-vs-76% divergent pair).

* * *
## 9. Extensions (`extensions.fsh`) — all 23
_FHIR has no native campaign semantics; these extensions carry them on profiled core resources._ (working doc §7)

**Campaign mechanics**

| Extension (id) | Context | Type / binding | Card. where used |
|---|---|---|---|
| DeliveryStrategy (`delivery-strategy`) | PlanDefinition, ActivityDefinition, Task, Location | CodeableConcept, **required** → ICRDeliveryStrategyVS | Protocol 1..\*, Activity 0..1, Task 1..1, Location 0..1 |
| CampaignRound (`campaign-round`) | CarePlan | positiveInt | 0..1 |
| TargetGeography (`target-geography`) | CarePlan | Reference(ICRLocation) | 0..\* |
| PlanningDenominator (`planning-denominator`) | CarePlan | Reference(ICRTargetPopulation) | 0..1 |
| RealtimeVsReconciled (`realtime-vs-reconciled`) | CarePlan, Task, MeasureReport | code, **required** → ICRDataLineageVS; documented default: **absent ⇒ realtime** | CarePlan 0..1 MS, Task 0..1, coverage MeasureReports **1..1 MS** |
| TaskOrigin (`task-origin`) | Task | code, **required** → ICRTaskOriginVS (pre-planned \| field-registered) | Task **1..1** |

**House-to-house task data** (all Context: Task)

| Extension (id) | Type / binding |
| --- | --- |
| HousesVisited (`houses-visited`) | unsignedInt |
| {==ChildrenPresent (`children-present`)==}{>>Let's see how common this.  Eg should it say children or do we include target patients or something.  children can be fine jsut want a bit more info on this.<<}{id="c18" by="mberg" at="2026-06-12T20:56:33.978Z"}{>>Where "children" comes from: the house-to-house vocabulary is polio's — doorstep tallies count children <5 present/absent, and the working doc inherited it. But the same present/absent-at-the-door concept applies wherever H2H is used for other targets: MDA treats whole communities and school-age bands, ITN registration counts household members, vitamin A is 6–59 months. So "children" is accurate for the dominant H2H program (polio) and wrong as a generic label. Recommendation: rename to eligible-present / eligible-absent ("eligible persons per the campaign's protocol definition") — semantics identical, label program-neutral, and renaming costs nothing NOW versus a breaking change after pilot data exists. Unless you want to keep polio's field vocabulary on polio's own data elements, I'll rename in the next IG pass. (Same comment appears on four spans — answering once here.)<<}{id="c38" by="claude" at="2026-06-12T21:03:09.000Z" re="c18"}{>>APPLIED in v0.4.0: renamed to EligiblePresent (`eligible-present`) / EligibleAbsent (`eligible-absent`) in the IG (commit 4b49ab0) — "eligible persons per the campaign protocol's target definition", program-neutral across polio/MDA/ITN/vitamin A. The rows below now show the new names; your original comment is kept for the record.<<}{id="c61" by="claude" at="2026-06-13T01:31:20.000Z" re="c38"} → now **EligiblePresent (**`eligible-present`**)** | {==unsignedInt==}{>>Let's see how common this.  Eg should it say children or do we include target patients or something.  children can be fine jsut want a bit more info on this.<<}{id="c18" by="mberg" at="2026-06-12T20:56:33.978Z"} |
| {==ChildrenAbsent (`children-absent`)==}{>>Let's see how common this.  Eg should it say children or do we include target patients or something.  children can be fine jsut want a bit more info on this.<<}{id="c18" by="mberg" at="2026-06-12T20:56:33.978Z"} → now **EligibleAbsent (**`eligible-absent`**)** | {==unsignedInt==}{>>Let's see how common this.  Eg should it say children or do we include target patients or something.  children can be fine jsut want a bit more info on this.<<}{id="c18" by="mberg" at="2026-06-12T20:56:33.978Z"} |
| MissedReason (`missed-reason`) | CodeableConcept, **extensible** → ICRMissedReasonVS |
| NoncomplianceReason (`noncompliance-reason`) | CodeableConcept, **extensible** → ICRNoncomplianceReasonVS |
| FingerMarked (`finger-marked`) | boolean — "the in-field 'already covered' flag" |

{==**Population & denominator provenance**==}{>>some examples would be great<<}{id="c19" by="mberg" at="2026-06-12T20:57:26.361Z"}{>>Will do — same plan as my c35 reply above: the rewrite gets a worked denominator walk-through (district GRID3 vs district microcensus vs national census-projection, sources + dates + one planning flag), shown both as the resource shapes and as the "what the reviewer sees" story. The four extensions in this table are exactly the fields that walk-through exercises: denominator-source (GRID3/microcensus/census-projection), estimate-date (Jan vs Mar vs Nov), is-planning-denominator (exactly one true per geography), confidence (free-text qualifier for now).<<}{id="c39" by="claude" at="2026-06-12T21:03:09.000Z" re="c19"}

| Extension (id) | Context | Type / binding |
| --- | --- | --- |
| GroupLocation (`group-location`) | Group | Reference(ICRLocation) — the Group+Location pattern: dwelling (household), settlement/community point (community), or school (school-cohort); **residence/base, not service point** |
| DenominatorSource (`denominator-source`) | Group, MeasureReport | CodeableConcept, **extensible** → ICRDenominatorSourceVS |
| EstimateDate (`estimate-date`) | Group | date — "denominators decay fast (1–3 years)" |
| IsPlanningDenominator (`is-planning-denominator`) | Group | boolean |
| EstimateConfidence (`estimate-confidence`) | Group | string |

**Geospatial, delivery & coverage**

| Extension (id) | Context | Type / binding |
|---|---|---|
| LocationBoundaryGeoJson (`location-boundary-geojson`) | Location | Attachment, `contentType` fixed `application/geo+json` — R4 mirror of the R5 standard boundary extension |
| OverlaysAdminUnit (`overlays-admin-unit`) | Location | Reference(ICRLocation) — links operational geography to the admin unit(s) it overlays |
| RecordOrigin (`record-origin`) | Immunization, MedicationAdministration, SupplyDelivery | code, **required** → ICRRecordOriginVS |
| DirectlyObservedConsumption (`directly-observed-consumption`) | MedicationAdministration | boolean |
| CoverageSource (`coverage-source`) | MeasureReport | code, **required** → ICRCoverageSourceVS |
| SampleDesign (`sample-design`) | MeasureReport | string — survey/LQAS/RCM method & sample-design detail |

**Rationale highlights.** The binding-strength pattern is deliberate: **structural discriminators** (delivery strategy, record origin, lineage, coverage source) are `required` — analytics must be able to branch on them; **field-reality vocabularies** (missed/noncompliance reasons, denominator sources) are `extensible` — countries add local codes, mapped back via ConceptMap. Code vs CodeableConcept also tracks this: pure discriminators use bare `code`; concepts countries extend use CodeableConcept (text + local codings survive).

> [!warning] Questions
> 
> 1. {==`RealtimeVsReconciled`==}{>>Elaborate what you mean.<<}{id="c20" by="mberg" at="2026-06-12T20:58:49.186Z"}{>>The extension itself: a two-value flag (realtime | reconciled) marking which data stream a record belongs to — the live feed during the campaign (tonight's tallies, possibly messy) vs the corrected close-out figures (reconciled stock, final coverage). One structure serves both; consumers filter: dashboards read realtime, the JAP export reads reconciled (working doc §4.3). The problem I'm flagging: the flag is OPTIONAL everywhere (0..1), so records that never set it are in NEITHER stream — a "reconciled only" JAP query silently drops every unflagged record, or includes them, depending on how someone writes the query. Two fixes, not mutually exclusive: (a) write the default into the IG — "absent means realtime", which matches reality since reconciled figures are deliberately produced at close-out and can be required to carry the flag; (b) make it REQUIRED (1..1) on MeasureReport specifically, since coverage reports are where the realtime/reconciled distinction has teeth (the 99%-admin-vs-76%-survey kind of stakes). My recommendation is both; I'll apply in the next IG pass unless you object.<<}{id="c40" by="claude" at="2026-06-12T21:03:09.000Z" re="c20"} — _(Resolved in third pass.)_ Both fixes applied: the default is documented (**absent ⇒ realtime**) and the flag is **1..1 on both coverage profiles** (§8).
>   
> 2. _(Resolved in third pass.)_ Renamed to `eligible-present` / `eligible-absent` before the names ossified (your c18).
>   
> 3. `LocationBoundaryGeoJson`: when ICR eventually moves to R5 (or the cross-version extension), migration of stored attachments is trivial, but the **URL** changes — the alignment path is parked as working doc §10 q6; keep it on the v1.0 checklist.
>   
> 
> _Resolved in first pass:_ `TargetGeography`/`PlanningDenominator`/`HouseholdLocation` (since renamed `GroupLocation`) now target ICRLocation/ICRTargetPopulation; `DeliveryStrategy`'s Location context is now used — ICRLocation carries it (0..1) for delivery sites; `SampleDesign` added (the §8 fix). _Added in second pass:_ `TaskOrigin` (required on Task), `OverlaysAdminUnit` (operational geography). _Changed in third pass:_ `children-present/absent` → `eligible-present/absent`; lineage default + coverage cardinality; `GroupLocation` residence semantics.

* * *
## 10. Terminology (`codesystems.fsh`, `valuesets.fsh`)
Pattern (working doc §8): **ICR defines only campaign semantics**; product codes come from CVX/ATC/GS1; local codes join via ConceptMap (deferred). All 12 code systems are `caseSensitive` and non-experimental.

| CodeSystem | Codes | FR? | Bound (strength) |
| --- | --- | --- | --- |
| ICRCampaignTypeCS | `vaccination-sia`, `mda`, `itn-distribution`, `irs`, `vitamin-a`, `integrated` (6) | ✔   | Protocol.type, Campaign.category (**required**) |
| ICRDeliveryStrategyCS | `fixed-post`, `temporary-post`, `mobile`, `school`, `house-to-house`, `community-directed` (6) | ✔   | delivery-strategy ext (**required**) |
| ICRRecordOriginCS | `campaign`, `routine` (2) | ✔   | record-origin ext (**required**) |
| ICRGroupKindCS | {==`household`, `community`==}{>>Are there any other potential ones we should consider?<<}{id="c21" by="mberg" at="2026-06-12T20:59:23.580Z"}{>>Candidates, in rough order of likelihood ICR meets them: (1) school-cohort — school-based HPV/MDA/deworming is squarely in scope; today a school session's Task focuses on the school Location, which works for tallies, but a country wanting "the enrolled children of school X" as a trackable group needs this code (already flagged as §6.1 q3); (2) nomadic/mobile group — pastoralist bands and transhumant communities are a real campaign delivery unit (polio and MDA both chase them) and they're precisely NOT anchored to one dwelling, so groupLocation semantics need a note if we add it; (3) camp population — IDP/refugee camp blocks; arguably a community at a Location, so maybe covered; (4) institutional — orphanage, prison, barracks: campaign-relevant in outbreak response (OCV), probably coverable as community until proven otherwise. My lean: add school-cohort now (clear in-scope demand), hold the rest until a pilot or country asks — the CodeSystem is ICR-owned so each addition is a one-line change, and a too-long required-bound list invites misclassification. Agree?<<}{id="c41" by="claude" at="2026-06-12T21:03:09.000Z" re="c21"}{>>sounds good. let's add this extra one just to show this can be extended to support additional things that may be non-obvious.<<}{id="c49" by="mberg" at="2026-06-13T01:25:03.374Z" re="c41"}{>>APPLIED in v0.4.0: `school-cohort` added with FR designation "Cohorte scolaire" (commit 4b49ab0); its definition text explicitly notes the system extends to further kinds (nomadic groups, camp populations) as demand appears.<<}{id="c62" by="claude" at="2026-06-13T01:31:20.000Z" re="c49"} + `school-cohort` (3) | ✔   | ICRDeliveryUnit.code (**required**) |
| ICRTaskOriginCS | `pre-planned`, `field-registered` (2) | ✔   | task-origin ext (**required**) |
| ICRLocationTypeCS | `admin-unit`, `settlement`, `facility`, `school`, `community-distribution-point`, `temporary-post`, `household`, `supervisory-area`, `operational-area` (9) | —   | ICRLocation.type (extensible) |
| ICRGroupCharacteristicCS | `geography` (1) | —   | fixed code on the geography characteristic slice (no VS) |
| ICRMissedReasonCS | `absent`, `sleeping`, `sick`, `refusal`, `inaccessible`, `not-visited`, `other` (7) | —   | missed-reason ext (extensible) |
| ICRNoncomplianceReasonCS | `safety-concern`, `religious-objection`, `no-felt-need`, `campaign-fatigue`, `misinformation`, `other` (6) | —   | noncompliance-reason ext (extensible) |
| ICRDenominatorSourceCS | `census`, `census-projection`, `microcensus`, `worldpop`, `grid3`, `hmis`, `other` (7) | —   | denominator-source ext (extensible) |
| ICRDataLineageCS | `realtime`, `reconciled` (2) | ✔   | realtime-vs-reconciled ext (**required**) |
| ICRCoverageSourceCS | `administrative`, `survey`, `lqas`, `rcm` (4) | ✔   | coverage-source ext (**required**) |

Value sets: one whole-system VS per code system (except ICRGroupCharacteristicCS, whose single code is fixed directly in the characteristic slice), plus:

- **ICRIndependentCoverageSourceVS** — enumerates `survey`, `lqas`, `rcm` only (excludes `administrative`); the ICRSurveyCoverage binding. This little VS is what makes "never merge the lineages" structurally enforceable.
  
- **ICRMDAMedicationVS** — includes **all of ATC** (extensible binding on MDA medication); the description now states this explicitly, lists the typical PC-NTD codes (albendazole P02CA03, ivermectin P02CA01, praziquantel P02BA01, azithromycin J01FA10, DEC P02CB02), and defers subtree restriction until country formularies are reviewed.
  

Domain notes a reviewer might verify: `sleeping` is the polio doorstep convention; `community-directed` is CDTI, the NTD-MDA backbone; campaign types are grouped **by delivery model, not disease** (the background page's Type A/B/C table); `integrated` exists because co-delivered campaigns are the norm and component activities carry their own types.

> [!warning] Questions
> 
> 1. The **required**-bound `code`-typed extensions have no `other` escape — confirm the closed sets (campaign/routine; realtime/reconciled; 4 coverage sources) really are exhaustive. E.g. is _post-campaign administrative correction_ a third lineage? Is _desk review_ a coverage source?
>   
> 2. Campaign-type granularity: `vaccination-sia` lumps measles, polio (preventive), HPV, YF, OCV — disease lives in `CarePlan.addresses`. Confirm partners (esp. polio program) accept disease-agnostic campaign typing.
>   
> 3. The new FR designations were drafted in-pass — **have a francophone public-health reviewer check them** (esp. "Monitorage rapide de convenance" for RCM). Localization policy generally (which languages, where) still deserves a stated rule.
>   
> 
> _Resolved in first pass:_ FR designations now cover **all five** required-binding systems and the file comment matches; the MDA VS description matches its content.

* * *
## 11. Examples (`examples.fsh`) — the scenario walkthrough
One coherent story: a **Sierra Leone measles–rubella SIA, 2026** — a national umbrella campaign with the **Kambia District June round** as `partOf` child — exercising fixed-post (Type A) and house-to-house mop-up (Type B) tasks, the divergent admin-vs-survey coverage pair, plus a standalone MDA event (Type C) and an ITN delivery. Second pass added the country level, a community delivery unit, and a supervisory area. {==Third pass added the activity gallery (albendazole / ITN / IRS) and the competing enumeration denominator.==}{>>ADDED in v0.4.0: rows 11, 14–16 below are the new instances; the table is renumbered accordingly.<<}{id="c63" by="claude" at="2026-06-13T01:31:20.000Z"}

| # | Instance | Profile | Key content |
|---|---|---|---|
| 1 | `example-country` | ICRLocation | "Sierra Leone", `jdn`, type **admin-unit**; P-code `SL` + GERS division ID |
| 2 | `example-district` | ICRLocation | "Kambia District", `jdn`, type admin-unit, **partOf country**; P-code `SL0201` + GERS division ID |
| 3 | `example-settlement` | ICRLocation | "Rokupr", `area`, partOf district, GPS point, GERS place ID |
| 4 | `example-dwelling` | ICRLocation | house (`ho`), partOf settlement, GPS, GERS building ID |
| 5 | `example-fixed-post` | ICRLocation | "Rokupr CHC — fixed vaccination post", site (`si`), partOf settlement, GERS building ID, **deliveryStrategy `fixed-post`** |
| 6 | `example-supervisory-area` | ICRLocation | "Kambia supervision zone 2", type **supervisory-area** — **NOT in the partOf chain**; **overlaysAdminUnit → district** (operational ≠ administrative geography, demonstrated) |
| 7 | `example-child` | **plain Patient** | Aminata Kamara, f, b. 2023-04-12 |
| 8 | `example-household` | ICRDeliveryUnit | **code `household`**, quantity 6, member → child, groupLocation → dwelling |
| 9 | `example-community` | ICRDeliveryUnit | **code `community`** — "Rokupr community", quantity 3,480, groupLocation → settlement: the same Group+Location pattern at community scale (the Type C unit) |
| 10 | `example-target-population` | ICRTargetPopulation | 48,250 children 9m–14y, Kambia; source **GRID3**, estimateDate 2026-01-15, isPlanningDenominator true; **geography characteristic → district** |
| 11 | `example-target-population-enumerated` | ICRTargetPopulation | **NEW** — 51,800 children 9m–14y, Kambia; source **microcensus/enumeration**, estimateDate 2026-03-02, isPlanningDenominator **false**; geography → district — the **competing estimate** for the same geography (§6.2 walk-through) |
| 12 | `example-target-population-national` | ICRTargetPopulation | 2,150,000 children 9m–14y, national; source **census-projection**, estimateDate 2025-11-30 — a *different* denominator source than the district's GRID3; **geography characteristic → country** |
| 13 | `example-mcv-activity` | ICRCampaignActivity | "Administer MCV"; kind Task; productCodeableConcept CVX `05`; dosage "0.5 mL subcutaneous" |
| 14 | `example-albendazole-activity` | ICRCampaignActivity | **NEW** — "Administer albendazole, 5–14y"; ATC `P02CA03`; "400 mg single dose; tablet count by dose-pole height band" (Type C) |
| 15 | `example-itn-activity` | ICRCampaignActivity | **NEW** — "Distribute LLINs, 1 net per 2 household members"; free-text product pending GS1 (Type B→A) |
| 16 | `example-irs-activity` | ICRCampaignActivity | **NEW** — "Spray interior walls of eligible structures"; Pirimiphos-methyl 300CS (Type B) |
| 17 | `example-mr-sia-protocol` | ICRCampaignProtocol | v1.0.0; type `vaccination-sia`; **two** deliveryStrategy values; goal "≥95% administrative coverage…"; **action.definitionCanonical → #13** |
| 18 | `example-mr-sia-national` | ICRCampaign | the **umbrella**: instantiates #17, **intent `plan`**, subject & planningDenominator → #12, period Jun 15–Dec 18 2026 |
| 19 | `example-mr-sia-2026` | ICRCampaign | the **round**: instantiates #17; **intent `order`**, **partOf → #18**; subject & planningDenominator → #10; period Jun 15–26; round 1; targetGeography → district |
| 20 | `example-site-session-task` | ICRCampaignTask | **Type A**: focus & location → fixed post, for → target population; strategy fixed-post; **taskOrigin `pre-planned`**; dataLineage realtime; output "Children vaccinated (session tally)" = 412 |
| 21 | `example-mopup-task` | ICRCampaignTask | **Type B**: completed; focus & for → household, location → dwelling; strategy house-to-house; **taskOrigin `field-registered`** (the discovery-mode pattern); eligiblePresent 2 / absent 1; missedReason `absent`; fingerMarked true; output → #22 |
| 22 | `example-mcv-dose` | ICRImmunizationEvent | CVX `05`; patient → child; at the dwelling; lot `MRV-2026-0412`; manufacturer, performer & doseNumber 1 (MS elements exercised); **recordOrigin `campaign`** |
| 23 | `example-albendazole-administration` | ICRMedicationAdministration | ATC `P02CA03`; dosage "1 tablet (400 mg), **dose-pole band B**"; directlyObserved true; recordOrigin campaign |
| 24 | `example-itn-delivery` | ICRSupplyDelivery | 3 nets (UCUM `{Net}`), free-text LLIN, destination → dwelling; recordOrigin campaign |
| 25 | `example-admin-coverage` | ICRAdministrativeCoverage | numerator 47,766 / denominator 48,250, **measureScore 99%**; denominatorSource GRID3; dataLineage reconciled; coverageSource administrative |
| 26 | `example-survey-coverage` | ICRSurveyCoverage | post-campaign (Jul 6–12), **measureScore 76%**; coverageSource survey; sampleDesign "WHO 30×10 cluster survey…"; **dataLineage reconciled** (now required) — the same quantity as #25, **23 points apart**, mirroring the canonical Cuamba divergence |

What the scenario _demonstrates_: the full Location chain with GERS at every level, country → dwelling, plus a delivery site; **operational geography overlaying (not inside) the admin hierarchy**; the generalized delivery-unit pattern at **both scales** (household and community); **competing denominators for the same geography** (GRID3 vs enumeration, 7% apart, one planning flag) alongside the cross-level contrast (district GRID3 vs national census-projection), all computably geography-scoped; the **activity gallery** across campaign types; protocol→activity→campaign wiring; the umbrella/round `partOf` lifecycle (`plan` umbrella, `order` round); **both Task shapes** of the focus polymorphism _and_ **both task origins** (pre-planned session, field-registered mop-up); a Type-B trail end-to-end down to the dose; both non-vaccine delivery types; and the never-merge rule made visible by a 99-vs-76 coverage pair on the same round.

> [!warning] Questions
> 
> 1. The albendazole event references the child from the MR scenario for an MDA that has **no campaign/protocol/task instances** — the community delivery unit (#9) and the albendazole activity (#14) now exist, but the Type-C thread still dangles: no CDTI protocol, no community-focused Task wiring #9/#14 → #23. Worth completing in a future pass.
>   
> 2. GERS values are placeholder-format (`…-example`) — fine, but before pilots confirm real GERS ID syntax so examples validate against the eventual identifier pattern.
>   
> 3. The coverage examples point at **placeholder Measure canonicals** (`…/Measure/icr-admin-coverage`) that don't resolve — expected until the Measure definitions ship, but the IG Publisher will likely warn.
>   

* * *
## 12. Narrative pages (`index.md`, `background.md`)
- `index.md` — the pitch (campaigns re-collect the same data; ICR makes collection compound), the one-paragraph architecture (mirrors §4 above), status (v0.1, Phase 1, to be revised against real datasets and FHIR community review), and the deferred-items list.
  
- `background.md` — the Type A/B/C campaign-typology table; the **twelve design decisions** (numbered, with rejected alternatives noted for the keystone choice — #3 now covers pre-planned vs field-registered tasks, #7 the generalized household/community delivery unit); two second-pass sections: **"Campaign work vs routine encounters"** (Task-based campaign delivery, Encounter retained for routine, `record-origin` as the discriminator — working-doc comment c71) and **"Operational vs administrative geography"** (the location-type + overlays-admin-unit mechanism); a third-pass section **"Location identity lifecycle: GERS enrichment"** (create unmatched → async conflation → backfill GERS with versioning + Provenance — your c16) and the per-child follow-up exception folded into design decision #3; the **open design questions** taken to the FHIR community (Task granularity, aggregate vs individual records, deep partOf hierarchies, MeasureReport vs Observation, denominator representation, GeoJSON on R4, Task focus typing, Bulk Data access patterns, record-linkage); and the WHO SMART Guidelines relationship (reuse DAK elements, align conventions, same toolchain).
  

These two pages are honest about maturity — the open questions are printed in the IG itself rather than hidden in the working doc. Design decisions #5, #11, #12 (three lineages; provenance on everything ingested; ViewDefinitions in the IG) are stated in narrative but only partially realized in v0.1 artifacts — see §13.

* * *
## 13. Cross-cutting design invariants (the things to hold the review against)
1. **Delivery strategy is first-class and coded** — required binding; mandatory on Protocol (1..*) and Task (1..1), optional on Activity and site Locations. _The_ discriminator, because strategy determines which data elements exist.
  
2. **Record origin is mandatory on every delivery event** (1..1, required binding) — the firewall between SIA doses and routine coverage.
  
3. **Three lineages, never merged** — planned (CarePlan/Group), delivered (Task/events → admin coverage), independently measured (survey coverage). Enforced by the fixed `#administrative` code on one profile and the exclusion VS on the other.
  
4. **No denominator without provenance** — source + date are 1..1 on ICRTargetPopulation; competing estimates coexist; one planning flag.
  
5. **Geospatial identity is multi-system with GERS preferred** — open identifier slicing on Location; the Group+Location delivery-unit pattern keys households and communities to GERS IDs; operational geography overlays the admin hierarchy rather than pretending to be it.
  
6. **Real-time vs reconciled is one structure, filtered by lineage** — hardened in the third pass: documented default (absent ⇒ realtime) and 1..1 on both coverage profiles, where the distinction has teeth.
  
7. **Task origin is first-class and coded** (second pass) — pre-planned vs field-registered, 1..1 required; discovery-mode field registration is a supported workflow, and its counts are a microplan-completeness measurement.
  

* * *
## 14. Known gaps (acknowledged, deferred to later drafts)
Stated in the README/index — i.e., absent **by design**, not oversight:

- **SQL-on-FHIR** `ViewDefinition`**s** (design decision #12 — "the analytics layer is as portable as the data model")
  
- `ConceptMap` **scaffolds** for country/local code localization (the mechanism §10's extensible bindings rely on)
  
- `Consent` **guidance** (household/person data governance)
  
- `Measure` **definitions** aligned to WHO JAP / ICG / ESPEN / WHO EPI reporting minimums (what MeasureReports will point at)
  
- **Data conformance testing** against real campaign datasets; **FHIR community review** (chat.fhir.org, WG calls, Connectathons)
  
- No `CapabilityStatement`, search-parameter, or Bulk-Data/cohort-export guidance yet (the access-pattern open question)
  

* * *
## 15. Consolidated review checklist
**✅ Addressed in the first-pass revision (commit** `843ab18`**)**

- ~~FR designations vs the "two Required systems" comment~~ — FR now on all 5 required-binding systems (§10); _needs francophone review_.
  
- ~~ICRMDAMedicationVS description vs content~~ — description corrected, PC-NTD codes enumerated (§10).
  
- ~~Survey "sample design" element~~ — new `SampleDesign` extension, 0..1 MS on ICRSurveyCoverage (§8).
  
- ~~Reference-target tightening~~ — target-geography → ICRLocation, planning-denominator → ICRTargetPopulation, household-location → ICRLocation; Task.focus was deliberately left loose at the time — _superseded in second pass_: now narrowed to `ICRDeliveryUnit | ICRLocation` (§5.4/§6/§9).
  
- ~~Protocol→activity wiring unenforced~~ — `action.definition[x] only Canonical(ICRCampaignActivity)` (§5.1).
  
- ~~DeliveryStrategy's unused Location context~~ — wired into ICRLocation 0..1 for sites (§6.3/§9).
  
- ~~Missing examples~~ — added: activity definition, fixed-post site, national denominator, umbrella + `partOf` round (plan/order lifecycle), Type-A site-session task, and the 99%-vs-76% admin-vs-survey coverage pair; MCV dose now exercises its MS elements (§11).
  

**✅ Addressed in the second-pass revision (commit** `6a0ac4b`**, from icr-v1 comments c69–c75)**

- ~~How a target-population estimate links to its geography, computably~~ — profiled geography characteristic slice → Reference(ICRLocation), exercised by both denominator examples (§6.2).
  
- `Location.type` ~~unbound~~ — bound extensible to the new ICRLocationTypeVS (§6.3).
  
- ~~Operational geography had no structural mechanism~~ — supervisory/operational-area types + `overlays-admin-unit` extension + example (§6.3).
  
- ~~Household-only Group profile~~ — generalized to ICRDeliveryUnit (household | community), `Task.focus` and MDA `subject` narrowed accordingly, community example added (§6.1).
  
- ~~Pre-planned vs field-registered Tasks uncapturable~~ — required `task-origin` code + both examples (§5.4).
  
- ~~Campaign-vs-routine-Encounter boundary unstated~~ — explicit section in `background.md` (§12).
  

**✅ Addressed in the third-pass revision (commit** `4b49ab0`**, from this doc's comments c1–c49)**

- ~~Naming (ICR prefix, "Protocol")~~ — confirmed as-is by review (c42/c45).
  
- ~~Lineage default + enforcement~~ — absent ⇒ realtime documented; 1..1 on both coverage profiles; MS on ICRCampaign (§5.2/§8/§9).
  
- ~~"Children" count-extension naming~~ — renamed `eligible-present`/`eligible-absent` (§9).
  
- `group-kind` ~~extensibility~~ — `school-cohort` added with FR designation (§6.1/§10).
  
- ~~Per-child Task question~~ — one-Task-per-visit documented with the person-targeted follow-up exception; `Task.focus` admits `Patient` for that case only (§5.4).
  
- ~~Residence vs service point~~ — `groupLocation` semantics stated in profile, extension, and memo (§6.1).
  
- ~~Async GERS enrichment~~ — expected lifecycle documented in the IG background (§6.3/§12).
  
- ~~Missing worked examples~~ — protocol walk-through (§5.1), activity gallery + what-vs-focus (§5.3), competing-denominator triple (§6.2), four new IG instances (§11).
  
- GERS system URI — engagement with Overture tracked as Linear **BERG-46** (c2).
  

**Decisions needed (open — for Matt / project)**

1. Canonical URL + publisher attribution confirmed with UNICEF (§2) — all four §2 items, per your c1.
  
2. GERS/P-code identifier system URIs — BERG-46 (engage Overture); plus a concrete slot for the **Overture release version** (§6.3) — boundary-alignment work tracked as Linear **BERG-45**.
  
3. Aggregate-vs-individual representation for Type-A tally campaigns — the site-session example uses `Task.output` counts; document the `Task.output` / MeasureReport split as the official pattern (§7).
  
4. Closed required-bound code sets exhaustive? `taskOrigin` for historical imports (`unknown` code? §5.4 q6)? Disease-agnostic campaign typing OK with polio program? (§9/§10).
  
5. FR translations reviewed by a francophone public-health reviewer — now also group-kind (incl. school-cohort) and task-origin (§10).
  
6. Geography characteristic 0..1 → 1..1 once pilots confirm every estimate has a Location (§6.2 q2)? `overlays-admin-unit` required on operational-area types (§6.3 q6)?
  
7. Vector control / entomological surveillance — in ICR's future scope or not (§5.3 boundary note)?
  

**Hold for community review (already flagged in the IG)** 8. Task granularity at scale; deep partOf performance; MeasureReport vs Observation; GeoJSON on R4; record-linkage pattern; Bulk Data access (§12 of background page).
