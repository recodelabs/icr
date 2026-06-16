---
version: 0.12.0
last_modified: 2026-06-16T18:30:00.000Z
tags: [icr, fhir, ig, review]
---

# ICR FHIR IG v0.1 — Reviewer's Explainer
`v0.12.0 · Last modified Jun 16, 2026 at 2:30 PM EDT`

⁠

> [!note] What this document is A component-by-component walkthrough of the draft **ICR** (Integrated Campaign Registry) **FHIR** (Fast Healthcare Interoperability Resources) Implementation Guide (**IG**) in `ig/`, written for review. _New here? See the_ **_Abbreviations & glossary_** _immediately below — every abbreviation used in this document is defined there, and the common ones are also spelled out on first use._ For every artifact it covers **what it is** and **the rationale** (with pointers back to [[icr-v1]] sections). It describes the IG as committed through v0.6.x — every cardinality, binding, and fixed value was checked against the FSH source — with later additions folded into the prose but **not yet committed to** `ig/`. Open decisions still awaiting a project call are consolidated in **§15**; the prioritized proposal backlog for the next IG-editing round lives in **§17** (field-evidence synthesis) and **§18** (WHO SMART alignment). As of v0.12.0 the review-comment threads have been resolved and the per-section question callouts retired — the doc now reads as settled narrative plus the §15/§17/§18 backlog.

* * *
## Abbreviations & glossary
_Quick reference for every abbreviation used in this document, grouped by area. The common ones are also written out in full on their first use in §1 onward. Names in_ `code font` _(e.g._ `ICRCampaign`_) are FHIR artifacts defined in the section noted, not abbreviations._

**Campaign types & public-health programmes**

| Abbrev. | Meaning |
| --- | --- |
| **ICR** | Integrated Campaign Registry — the project and FHIR IG this document describes |
| **SIA** | Supplementary Immunization Activity — a **mass vaccination campaign** (as opposed to routine immunization) |
| **PMVC** | Preventive Mass Vaccination Campaign (e.g. yellow-fever) |
| **MDA** | Mass Drug Administration — a campaign giving a drug to a whole eligible population |
| **ITN / LLIN** | Insecticide-Treated Net / Long-Lasting Insecticidal Net (bed-net distribution) |
| **IRS** | Indoor Residual Spraying (anti-malaria) |
| **RI** | Routine Immunization — the everyday schedule (contrast SIA) |
| **EPI** | Expanded Programme on Immunization — the routine-immunization programme |
| **NTD / PC-NTD** | Neglected Tropical Disease / Preventive-Chemotherapy NTD |
| **CDD** | Community Drug Distributor — the front-line MDA worker |
| **CDTI** | Community-Directed Treatment with Ivermectin — the NTD-MDA delivery model |
| **RCM** | Rapid Convenience Monitoring — a quick, non-probability in-campaign check; **pass/fail with a trigger, not a coverage rate** |
| **LQAS** | Lot Quality Assurance Sampling — a small-sample accept/reject decision rule |
| **AEFI** | Adverse Event Following Immunization |
| **DOC** | Directly Observed Consumption — in MDA, the drug is swallowed under supervision |
| **TAS** | Transmission Assessment Survey — an NTD-elimination decision gate |
| **RED** | Reaching Every District — WHO microplanning approach |
| **EYE** | Eliminate Yellow fever Epidemics — WHO strategy |
| **FIP** | Fully Immunized Person |
| **Type A / B / C** | the campaign delivery-model typology — A = fixed/temporary-post session, B = house-to-house, C = community/MDA (`background.md`) |

**Vaccines, diseases & product codings**

| Abbrev. | Meaning |
| --- | --- |
| **MR** | Measles–Rubella |
| **MCV** | Measles-Containing Vaccine |
| **OCV** | Oral Cholera Vaccine |
| **YF** | Yellow Fever |
| **HPV** | Human Papillomavirus |
| **bOPV / nOPV2** | bivalent / novel-type-2 Oral Polio Vaccine |
| **CVX** | the US-CDC vaccine-code system (standard vaccine codes) |
| **ATC** | Anatomical Therapeutic Chemical classification — WHO drug codes |
| **GS1 / GTIN** | global commodity-coding standards / Global Trade Item Number |
| **UCUM** | Unified Code for Units of Measure |
| **VVM / WMF** | Vaccine Vial Monitor / Wastage Monitoring Form |

**Geography & identifiers**

| Abbrev. | Meaning |
| --- | --- |
| **GERS** | Global Entity Reference System — Overture Maps' stable place IDs |
| **P-code** | Place code — OCHA humanitarian administrative-area code |
| **OCHA** | UN Office for the Coordination of Humanitarian Affairs |
| **ISO 3166** | the ISO country (-1) and subdivision (-2) code standard |
| **GIS / MFL** | Geographic Information System / Master Facility List |
| **GeoJSON** | a geospatial JSON data format |
| **GPS** | Global Positioning System — a coordinate point |
| **OSM** | OpenStreetMap |
| **PSU / EA** | Primary Sampling Unit / Enumeration Area (survey sampling, §17) |

**FHIR & technical**

| Abbrev. | Meaning |
| --- | --- |
| **FHIR** | Fast Healthcare Interoperability Resources — the HL7 health-data standard |
| **IG** | Implementation Guide — a packaged set of FHIR profiles/rules for one use-case |
| **FSH / SUSHI** | FHIR Shorthand (the authoring language) / its compiler |
| **R4 / R5** | FHIR Release 4 (this IG) / Release 5 |
| **MS** | Must Support — a FHIR conformance flag ("implementations must populate/process this element") |
| **VS / CS** | ValueSet / CodeSystem |
| **CQL** | Clinical Quality Language — decision logic |
| **IPS** | International Patient Summary |
| **SNOMED CT / ICD-11 / LOINC** | clinical terminologies (concepts / diseases / observations) |
| **JSON** | JavaScript Object Notation |
| **FR** | French-language (`fr`) designations on code systems |

**WHO SMART Guidelines, organizations & reporting (mostly §17–§18)**

| Abbrev. | Meaning |
| --- | --- |
| **WHO / UNICEF** | World Health Organization / UN Children's Fund |
| **DAK** | Digital Adaptation Kit — WHO SMART-Guidelines content |
| **IMMZ** | the artifact prefix of the WHO SMART Immunizations IG |
| **L1 / L2 / L3** | WHO SMART-Guidelines "levels of knowledge representation" — narrative / semi-structured / machine-readable FHIR |
| **VPD** | Vaccine-Preventable Disease (surveillance) |
| **HMIS / DHIS2** | Health Management Information System / District Health Information Software 2 |
| **JAP** | Joint Appraisal — annual immunization-programme report |
| **ICG** | International Coordinating Group — vaccine-stockpile provision (OCV/YF) |
| **ESPEN** | Expanded Special Project for Elimination of NTDs (WHO-AFRO) |
| **GTFCC** | Global Task Force on Cholera Control |
| **VCQI** | Vaccination Coverage Quality Indicators — survey toolkit |
| **M&E** | Monitoring and Evaluation |
| **mCSD** | Mobile Care Services Discovery — an IHE location-directory profile |
| **CPG / CRMI / SDC** | HL7 frameworks: Clinical Practice Guidelines / Canonical Resource Management Infrastructure / Structured Data Capture |

* * *

> [!tip] v0.12.0 — review comments incorporated; per-section question/proposed callouts retired (your Jun 16 request) This pass **folds your open review comments into the main text and resolves the threads**, and **removes the per-section "[!warning] Questions" and "[!warning] Proposed (§17/§18)" callouts** — the proposed-addition pointers are redundant with §17/§18, and the genuinely-open project decisions are consolidated in **§15**. Substantive changes incorporated this round: **§4** — the **CareTeam / supervisor** gap is now stated in the architecture (supervisor is both a delivery actor and typically the reporter; an `ICRCareTeam` profile is the next-round fix, folded together with §17.3's supervision/QA work) and CareTeam added to the §4 diagram (c131/c136); **§5.1** — the `activity-type`**/**`sia-type` axis is now described in the main body as **orthogonal to** `campaign-type` (c137/c154), and age-band-eligibility-as-CQL is explicitly **deferred** (c155); **§5.4** — `Task.for` now carries the **target** (household / patient / community) and `Task.focus` is reserved for **workflow lineage** (CarePlan / activity / prior Task), per your traceability steer (c156), and a **disaggregation pattern** (age/sex via coded `Task.output` or person-level events) is documented (c157); **§6.1** — the residence Location extension stays `group-location` (it generalizes household/community/school — can't revert to `household-location` without losing the non-household cases), now stated at the example (c158); **§6.2** — **denominator source + date relaxed from mandatory (1..1) to recommended (0..1 MS)** since the population is often unknown up front (c159), with §13 #4 updated; **§6.3** — accessibility/travel-time, georegistry-match-status, endemicity, and the TAS gate are **rejected as out-of-IG-scope** (link externally by location ID), leaving only the `structure`/footprint location-type as a possible keeper (c138/c139); **§7** — "AEFI" is spelled out and the aggregate-vs-individual rule is stated (individual record when you have a person; aggregate on `Task.output` when you don't; `MeasureReport` only for derived coverage; MDA may use `subject = Group`) (c140/c141); **§8/§9/§10** — RCM is defined inline, structured `sample-design` is confirmed **deferred (free-text for v1)**, and the "is minting a CodeSystem normal?" / disease-agnostic-campaign-type questions are answered in prose (c142/c143/c144/c145). No FSH/profile artifact changed in this pass; the implied IG edits are tracked in §15/§17/§18 for the next round.

> [!tip] v0.11.0 — Abbreviations spelled out + a glossary added at the top (your Jun 16 request) A new **Abbreviations & glossary** section now sits right under the intro note — a grouped quick-reference for **every** abbreviation in the document (campaign types & programmes, vaccines/products, geography/identifiers, FHIR/technical, WHO-SMART/reporting). The headline abbreviations are also **written out in full on first use** in the intro and §1 — e.g. **SIA** → Supplementary Immunization Activity, plus MDA / ITN / IRS / MCV and FHIR / IG / FSH / SUSHI / R4. This is a documentation-only pass — no profile/FSH change — and the glossary is the canonical reference for any abbreviation used deeper in the doc that isn't expanded inline at its first occurrence.

> [!tip] v0.10.0 — WHO SMART Immunizations comparison folded in as §18 (addresses §2 c129) New **§18. WHO SMART Immunizations alignment** delivers the WHO SMART-Guidelines comparison the §2 thread (c129/c130) asked for, vs `smart-immunizations` (`smart.who.int.immunizations#0.2.0`). Headline: the **WHO IG is routine-immunization only** — no Campaign/CarePlan, denominator, coverage-survey, or operational-geography model — so **ICR is its campaign complement**, and (per your steer) alignment means **adopting WHO's IG structure where possible** and **reusing WHO artifacts at the seams**. Concrete proposals: adopt the WHO **SMART-Guidelines IG skeleton** (L1 Home / L2 Business Requirements / Data Models & Exchange / Deployment / Indices — the biggest structural gap, §18.2); make `ICRImmunizationEvent` **derived-from** `IMMZ.Immunization` and **reuse** `IMMZ.AdverseEvent` instead of a new AEFI VS (§18.3, supersedes §17 C1); add **ConceptMaps ICR ↔** `IMMZ.*` terminology and **derive coverage** `Measure`**s from** `IMMZIND01–45` (§18.4); declare `dependsOn smart.who.int.base` (§18.5). All **proposed** — no FSH change. Each affected section (§2, §3, §5.1, §6.1, §6.3, §7, §7.1, §8, §10, §12) now carries an inline **"[!info] WHO SMART alignment (§18)"** callout.

> [!tip] v0.9.0 — field-evidence synthesis folded in as §17 (a prioritized list of _proposed_ IG additions for a subsequent round) New **§17. Research-validated proposed additions** rolls up the eight-document global-health field-evidence synthesis (`_SYNTHESIS-research-vs-ICR-IG.md`: WHO SIA/RED/measles guides, the cluster-survey manual, GTFCC OCV, NTD-MDA, WHO EYE/yellow-fever, and geo-microplanning) into one decision-ready change-list. The headline: the evidence **validates the IG's spine** (plan→order lifecycle, one-Task-per-visit, the campaign/routine `record-origin` firewall, denominator-with-provenance, the never-merged coverage lineages, and operational-geography-overlays-admin — the standout win) and surfaces a **prioritized set of additions** — the highest-priority themes being a **programme-semantics quartet** (activity/SIA-type, coverage-target-as-data, stockpile-source, dosing-regimen) and a **coverage-model overhaul** (denominator-type + unit axes, structured `sample-design`, `Measure` bindings, a multi-dose "fully-immunized" measure). **Everything in §17 is _proposed_ — like the v0.7.0 items, nothing here is committed to** `ig/`; the actual IG/FSH edits are deferred to a subsequent round. §14 (Known gaps) and §15 (checklist) point at §17, and each affected section (§4, §5.1–5.3, §6.2/§6.3, §7, §8, §9, §10) now carries a short inline **"[!warning] Proposed (§17)"** callout linking back, so the proposal is visible where the artifact is described. This pass adds the synthesis section + cross-reference callouts only — no profile/FSH change and no change to the IG-as-committed prose.

> [!tip] v0.8.0 — section Question-blocks pruned to OPEN items only; resolved questions archived to §16 Each section's "[!warning] Questions" callout now lists **only genuinely-open questions**; every question already addressed/resolved was moved to the new **§16. Closed questions — archive** (grouped by section) so nothing is lost. Open decisions that still carry live comment threads stay in place (§2 WHO SMART alignment c129; §6.3 Overture release-version c86 and `partOf`-typing c87, plus the addressed-but-awaiting-confirm admin-identifier c88 and breadcrumb c89). This is a documentation-organization pass — no profile/FSH change.

> [!tip] v0.7.0 — fourth-pass revision: your Jun 15 comments folded into the main text (this doc's comments c80–c95) Your latest review round is now **incorporated into this doc's prose**, and each comment thread carries an **APPLIED in v0.7.0 … OK to close** note so you can decide which to close. The substance: **publisher → UNICEF** of record, Ona + Crosscut credited via `contact` (c94, §2); a **planned-vs-executed** explanation on the round CarePlans (c95, §5.2); a **worked** `dataLineage` **(realtime vs reconciled) example** (c80, §8); the **Patient-vs-RelatedPerson/Person** explanation folded into §6.1 with the q2 wording corrected (c83); **GRID3 → WorldPop** relabelled across the example denominators (c84, §6.2/§8/§11); a **two-hierarchy mermaid diagram** for Location (c85, §6.3); **admin-level identifier rules** — ≥1 identifier required at admin-unit level, plus national/internal-code and ISO 3166 slices (c88, §3/§6.3); a proposed `location-ancestors` **breadcrumb extension** for partOf-depth performance (c89, §6.3/§9); an `overlays-admin-unit` _1.. invariant_* on operational-area types (c90, §6.3); and an **inline albendazole MedicationAdministration example** for §7.2 (c91). Explanations were added for the Overture release-version purpose (c86) and the `partOf`-only-ICRLocation trade-off (c87), both left open pending your/Overture's decision. **This pass edits this explainer doc only** — IG/FSH artifact changes implied by c84/c88/c89/c90/c94 are flagged in-thread and tracked for the next IG build, not yet committed to `ig/`.

> [!tip] v0.5.0 — annotated FHIR/JSON examples inlined (this doc's comments c64–c67) The campaign-architecture sections now carry the **actual resource JSON**, all drawn from the one Sierra Leone MR SIA scenario so every example interlinks: the **protocol** (§5.1), its **activity** (§5.3), the **umbrella + round CarePlans** (§5.2), and a **house-to-house Task** that chains through `Task.output` to the **MCV dose** (§5.4 → §7.1), plus the identity resources they reference (**Location** §6.3, **delivery-unit** and **denominator Groups** §6.1/§6.2) and the divergent **coverage pair** (§8). §5.2 also gains a **lifecycle diagram** (microplan `plan` → execution `order`, umbrella → rounds) answering c64, and a worked answer to "do the geographies sum to the national total?" (c65): they don't have to — each scope carries its own denominator from its own source. Every block is annotated field-by-field beneath the JSON. **No IG/FSH artifacts changed in this pass** — these render `examples.fsh` instances already in the IG (the §11 table) as readable JSON for reviewers.

> [!tip] v0.4.0 — third-pass revision applied (this doc's comments c1–c49) Your review comments on THIS doc, and the agreed replies, are now **applied to the IG** (commit `4b49ab0`, SUSHI-clean: 0 errors / 0 warnings) and folded into this doc's main text. The substance: **naming stays** — ICR-prefixed profile names and "Protocol" confirmed (c42/c45); a **protocol walk-through** (§5.1) and an **activity-definition gallery** (§5.3) are now in the main text (c44/c46); the **who-vs-where split and nested-population stack** explained in §5.2 (c8); the **one-Task-per-visit pattern with the person-targeted follow-up exception** documented in §5.4 and `Task.focus` widened to allow `Patient` for follow-ups (c48); `dataLineage` now **MS on ICRCampaign** (c9) and **required (1..1) on both coverage profiles with "absent ⇒ realtime" as the documented default** (c20); `children-present/absent` **renamed** `eligible-present/absent` (c18); `school-cohort` added as a third group kind (c49); `groupLocation` documented as **residence, not service point** (c13); the **async GERS-enrichment lifecycle** stated as the expected workflow in the IG narrative (c16); §6.2 gains a **competing-denominator walk-through** with a new third example (c15/c19). New examples: albendazole/ITN/IRS activity definitions + the Kambia enumeration estimate (26 total). Linear: **BERG-46** (GERS system URI, c2).

> [!tip] v0.3.0 — second-pass revision applied (icr-v1 comments c69–c75) Matt's Jun 12 review comments on the working doc, and the agreed replies, have been **applied to the IG** (commit `6a0ac4b`, SUSHI-clean: 0 errors / 0 warnings) and this doc updated to match. The substance: **ICRHousehold → ICRDeliveryUnit** — one Group profile for households _and_ communities, distinguished by a required `group-kind` code, with `household-location` generalized to `group-location` (c72); a profiled, computable **geography characteristic** on ICRTargetPopulation → Reference(ICRLocation) at any admin level (c70 — closes old §6.2 q2); **operational geography gets a real mechanism** — a new location-type CodeSystem (incl. `supervisory-area` / `operational-area`, bound extensible to `Location.type`, closing old §6.3 q5) plus an `overlays-admin-unit` extension (c74); a **required coded** `task-origin` (pre-planned / field-registered) on ICRCampaignTask (c75); `Task.focus` **narrowed** to `ICRDeliveryUnit | ICRLocation` (the old looseness reason disappeared with the generalization) and `ICRMedicationAdministration.subject` narrowed to `Patient | ICRDeliveryUnit`; and the **campaign-work-vs-routine-Encounter boundary** stated in the background narrative (c71). Three new examples: country Location, community delivery unit, supervisory area.

> [!tip] v0.2.0 — first-pass revision applied The cheap fixes and missing examples from this doc's original §15 checklist have been **applied to the IG** (commit `843ab18`, SUSHI-clean: 0 errors / 0 warnings) and this doc updated to match: FR designations on all five required-binding code systems; MDA ValueSet description corrected; new `SampleDesign` extension on survey coverage; reference-target tightening (target-geography → ICRLocation, planning-denominator → ICRTargetPopulation, household-location → ICRLocation); protocol `action.definition` locked to ICRCampaignActivity; delivery-strategy wired into ICRLocation for sites; Task.focus looseness documented as deliberate; and 7 new examples (activity definition, national umbrella + `partOf` round, Type A site-session task, fixed-post site, national denominator, admin-vs-survey coverage pair). Items needing a project decision (§15) remain open.

* * *
## 1. Orientation — what's in the IG
The IG consists of FHIR Shorthand (FSH — a concise authoring language for FHIR), compiled by SUSHI (the FSH compiler) into FHIR R4 (Release 4) artifacts.

| Layer | Count | Artifacts |
| --- | --- | --- |
| **Profiles — campaign architecture** | 4   | ICRCampaignProtocol (PlanDefinition), ICRCampaign (CarePlan), ICRCampaignActivity (ActivityDefinition), ICRCampaignTask (Task) |
| **Profiles — population & geography** | 3   | ICRDeliveryUnit (Group — household/community/school-cohort), ICRTargetPopulation (Group), ICRLocation (Location) |
| **Profiles — delivery events** | 3   | ICRImmunizationEvent (Immunization), ICRMedicationAdministration (MedicationAdministration), ICRSupplyDelivery (SupplyDelivery) |
| **Profiles — coverage** | 2   | ICRAdministrativeCoverage (MeasureReport), ICRSurveyCoverage (MeasureReport) |
| **Extensions** | 23  | See §8 |
| **CodeSystems** | 12  | campaign-type, delivery-strategy, record-origin, missed-reason, noncompliance-reason, denominator-source, data-lineage, coverage-source, group-kind, task-origin, location-type, group-characteristic |
| **ValueSets** | 13  | One per code system (except group-characteristic, used as a fixed code), plus a narrowed independent-coverage set and an ATC-based MDA medication set |
| **Example instances** | 26  | A coherent measles–rubella **SIA** (Supplementary Immunization Activity — a mass vaccination campaign) scenario (umbrella + round, **Type A & B** tasks — fixed-post and house-to-house, coverage pair, country→dwelling hierarchy, household + community delivery units, supervisory area, competing denominators) + an activity gallery (**MCV** measles-containing vaccine, albendazole, **ITN** insecticide-treated net, **IRS** indoor residual spraying) + an **MDA** (Mass Drug Administration) event + an ITN delivery (§11) |
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
| `publisher` | "UNICEF", url `https://www.unicef.org` — publisher of record; the ICR project (delivered by Ona + Crosscut) credited via `contact` | Set to UNICEF per review (c94) |
| `menu` | Home, Background, Artifacts | |
| `parameters` | `show-inherited-invariants: false`, `shownav: true` | |

**Rationale.** The canonical `https://fhir.icr.unicef.org` stakes out a UNICEF-owned namespace; the same base hosts the two provisional identifier-system URIs (§3). The toolchain (FSH/SUSHI/IG Publisher) deliberately matches WHO SMART Guidelines practice (working doc §11).

> [!info] WHO SMART alignment (§18 — addresses c129) The toolchain already matches WHO practice. §18 proposes going further: adopt the WHO SMART-Guidelines IG **skeleton** (L1 Home / L2 Business Requirements / Data Models & Exchange / Deployment / Indices) and declare a formal `dependsOn smart.who.int.base` once alignment hardens — the concrete answer to §2 q2. The WHO IG is routine-only, so ICR is its **campaign complement**. See §18.

**Open with UNICEF (§15 #1).** Three metadata choices are permanent once published and need UNICEF confirmation before v1.0: that UNICEF controls (or intends to control) the canonical `fhir.icr.unicef.org`; that the package id `unicef.fhir.icr` fits UNICEF's `<org>.fhir.<scope>` naming convention; and **when the formal** `dependsOn` **is declared and what "alignment" concretely means** — now answered structurally in §18 (declare `dependsOn smart.who.int.base` once alignment hardens; the structured WHO SMART Guidelines comparison is delivered there, and is also tracked as a Linear work item alongside BERG-45/46, suggested title "ICR ↔ WHO SMART Immunizations DAK alignment pass").

* * *
## 3. Aliases & identifier systems (`aliases.fsh`)
Three groups:

- **External terminologies:** `$CVX` (`http://hl7.org/fhir/sid/cvx`, vaccine codes), `$MeasurePopulation` (the HL7 measure-population code system, used by the coverage examples), `$ATC` (`http://www.whocc.no/atc`, WHO drug classification), `$VaccineCodeVS` (the core FHIR vaccine-code ValueSet).
  
- **ICR identifier-system URIs** (explicitly marked _provisional — to be confirmed before v1.0_):
  
  - `$GERSId = https://fhir.icr.unicef.org/identifiers/overture-gers` — Overture Maps GERS IDs
    
  - `$PCode = https://fhir.icr.unicef.org/identifiers/pcode` — OCHA P-codes
    
  - `$ISO = urn:iso:std:iso:3166` — ISO 3166-1/-2 country & subdivision codes, for admin 0–3 (added v0.7.0, c88) — _WHO-aligned: matches WHO's_ `country-of-vaccination` _(ISO 3166-1) +_ `administrative-area` _extensions (§18.4)_
    
  - `$NationalAdminCode = https://fhir.icr.unicef.org/identifiers/national-admin-code` — the country/implementer's own administrative code, where they don't use a P-code (added v0.7.0, c88; the per-country base URI is expected to be overridden in implementation)
    
- **ICR code systems:** twelve `$...` aliases, one per CodeSystem in §10.
  

**Rationale.** GERS and P-codes need _some_ system URI to live under in `Location.identifier`; parking them under the ICR canonical is the pragmatic v0.1 choice. CVX/ATC/GS1 as the international product-code backbone is working doc §8.

**Two follow-ups carried forward.** (1) Whether ICR should mint the GERS/P-code system URIs at all — if Overture or OCHA ever publish official URIs, stored identifiers would need migration or ICR's URIs become permanent aliases; this is the Overture engagement tracked as **BERG-46** (§15 #2). (2) **GS1 is named in the narrative but has no alias and no binding** — `ICRSupplyDelivery.suppliedItem.item[x]` is left uncoded; binding a GS1 GTIN system is a known gap for the commodity profiles (§7.3).

* * *
## 4. The architecture at a glance
FHIR has no native `Campaign` resource, so the IG's core profiles are based on the CarePlan resource.

{==**Teams and the supervisor (the CareTeam gap).**==}{>>Please add a section for CareTeam with an example.<<}{id="c1" by="mberg" at="2026-06-16T20:56:17.828Z"} `ICRCampaign.careTeam` is already a **MS** element, so a campaign points at FHIR CareTeam(s) — but the team/worker model is **not yet fleshed out**: there is no `ICRCareTeam` profile, and team identity in the examples is **display-only** (`Task.owner` = "CDD team 7, Rokupr" is a plain string, not a CareTeam reference). This matters because the **supervisor is both a delivery actor and, very often, the one doing the reporting**. The next-round fix is an `ICRCareTeam` **profile** with roles (vaccinator / CDD, **supervisor**), wired to `Task.owner`/`Task.performer` and `ICRCampaign.careTeam`; the supervisor typically also owns the **supervisory-area** Location (§6.3) and is the `MeasureReport.reporter` on the rolled-up coverage — so "who reported this number" becomes queryable. This is folded together with §17.3's **Supervision/QA** proposal (one piece of work, not two). One open sub-decision for that round: whether **supervisor-as-reporter** is an explicit invariant (campaign MeasureReports SHALL name a `reporter`) or stays MS for v1 (§15 #7-bis). CareTeam is shown in the diagram below.

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
    CT["ICRCareTeam<br/>(CareTeam — proposed)<br/><i>vaccinator/CDD + supervisor</i>"]

    PD -- "action" --> AD
    CP -- "instantiatesCanonical 1..1" --> PD
    CP -- "partOf (rounds)" --> CPU
    CP -- "subject" --> TP
    CP -- "careTeam MS" --> CT
    CT -- "owner/performer" --> T
    CT -. "reporter" .-> AC
    CP -- "activity.reference" --> T
    T -- "for: DeliveryUnit|Location" --> HH
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
_Reading the element tables in §5–§9:_ **_MS_** _= Must Support (a FHIR conformance flag — a conformant implementation must be able to populate and process the element);_ **_1..1 / 0..* / 1..*_** _are cardinalities (min..max occurrences); a_ **_binding_** _ties a coded element to a ValueSet at a given strength (_**_required_** _= must use a code from it,_ **_extensible_** _= use one if it fits, else add your own)._
### 5.1 ICRCampaignProtocol — `PlanDefinition`
_The reusable, version-controlled template for a campaign type — what a measles SIA_ **_is_** _(products, age bands, activity sequence, coverage goals), instantiated by every execution in every country._ (working doc §7.1)

`activity-type` **/** `sia-type` **is a separate axis from** `campaign-type` **(proposed, §17.2 P1).** A campaign needs two **orthogonal** coded axes, not one. `campaign-type` answers **what intervention** (vaccination-sia / mda / itn-distribution / irs — the delivery model). The proposed `activity-type` / `sia-type` answers **the operational mode or trigger** of the round: routine / preventive-mass (pmvc) / catch-up / follow-up / mop-up / reactive-outbreak-response. They are genuinely different questions — a measles **follow-up SIA** (run every 2–4 years to clear accumulated susceptibles) and a measles **outbreak-response SIA** are _both_ `campaign-type = vaccination-sia` but differ in mode: different trigger, often a different target age band, analyzed separately. Keeping the axes orthogonal lets you query "all reactive campaigns, any disease" or "all measles, any mode" independently (WHO's EYE programme uses exactly this 4-type taxonomy). One caution when this is drafted: don't let `activity-type` overlap `record-origin` (campaign-vs-routine) — `routine` would only ever be an `activity-type` value for the RI baseline, not a campaign mode. A companion `coverage-target` element should store the programme-defined threshold (≥95% SIA / ≥65% LF epidemiological / EYE 50-60-80%), not just achieved coverage. Both are proposed for a subsequent round — see §17.2.

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

> [!info] WHO SMART alignment (§18) **Naming-collision caution:** WHO uses `PlanDefinition` for _decision-support schedules_ (`IMMZ.D2/D5/D18` — recommend/contraindication/next-visit), whereas ICR uses it for the _campaign protocol_. Same resource, opposite role — document the distinction so a WHO-familiar consumer isn't surprised. Age-band-eligibility-as-CQL (q2) could later reuse WHO's CQL libraries. See §18.3.

**What a protocol actually looks like.** A protocol is the reusable recipe card for a campaign type — the IG's `example-mr-sia-protocol` in full:

| Field | Value | Meaning |
|---|---|---|
| `version` | `1.0.0` | Protocols are versioned — "MR SIA per 2026 guidance" and its 2028 revision are distinct, citable things |
| `type` | `vaccination-sia` | What kind of campaign this is (the required campaign-type code) |
| `extension[deliveryStrategy]` | `fixed-post` **and** `house-to-house` | The strategies this campaign type uses — MR SIAs run posts, then mop up door-to-door |
| `goal` | "≥95% administrative coverage in every district, verified by post-campaign survey" | The coverage target every execution inherits |
| `action` | → "Administer MCV, 9 months–14 years" (`example-mcv-activity`) | The activity sequence; a bigger protocol lists several actions — vaccinate, then mop up — each pointing at its ActivityDefinition |

Every execution then points back at it: the national umbrella and the Kambia round both carry `instantiatesCanonical → example-mr-sia-protocol`. That single link is what makes "all MR SIA rounds, anywhere, comparable" a query instead of a research project — and it is why `instantiatesCanonical` is 1..1.

**The protocol as FHIR/JSON.** The same `example-mr-sia-protocol`, rendered (the fields a reviewer cares about; `meta.text` and narrative elided):

```json
{
  "resourceType": "PlanDefinition",
  "id": "example-mr-sia-protocol",
  "meta": {
    "profile": [
      "https://fhir.icr.unicef.org/StructureDefinition/ICRCampaignProtocol"
    ]
  },
  "status": "active",
  "version": "1.0.0",
  "title": "Measles–Rubella SIA — 2026 national guidance",
  "type": {
    "coding": [
      {
        "system": "https://fhir.icr.unicef.org/CodeSystem/icr-campaign-type",
        "code": "vaccination-sia"
      }
    ]
  },
  "extension": [
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/delivery-strategy",
      "valueCodeableConcept": {
        "coding": [
          {
            "system": "https://fhir.icr.unicef.org/CodeSystem/icr-delivery-strategy",
            "code": "fixed-post"
          }
        ]
      }
    },
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/delivery-strategy",
      "valueCodeableConcept": {
        "coding": [
          {
            "system": "https://fhir.icr.unicef.org/CodeSystem/icr-delivery-strategy",
            "code": "house-to-house"
          }
        ]
      }
    }
  ],
  "goal": [
    {
      "description": {
        "text": "≥95% administrative coverage in every district, verified by post-campaign survey"
      }
    }
  ],
  "action": [
    {
      "title": "Administer MCV, 9 months–14 years",
      "definitionCanonical": "https://fhir.icr.unicef.org/ActivityDefinition/example-mcv-activity"
    }
  ]
}
```

Annotated: `type` is the **required** campaign-type code (what kind of campaign this is); the two `delivery-strategy` extensions are the `1..*` repeat saying MR SIAs run posts **and** mop-up; `goal.description` is the coverage target every execution inherits; `action.definitionCanonical` is the wiring to the activity in §5.3 — **locked to** `Canonical(ICRCampaignActivity)`, so the protocol→activity link is machine-checked, not just narrated. Note what is **absent**: no geography, no dates, no denominator — those live on the executions (§5.2) that point back here via `instantiatesCanonical`.⁠

**Two notes carried forward.** `PlanDefinition.type` is `1..1` and repurposed here for campaign type (base FHIR uses it to distinguish plan kinds like order-set vs protocol) — reasonable, though reviewers may ask whether `topic` or a dedicated extension is cleaner. And **age-band eligibility as CQL** (a `library`/eligibility-logic story) is **explicitly deferred** to a later round — it pairs with the WHO DAK/CQL alignment (§18.3).
### 5.2 ICRCampaign — `CarePlan` (the keystone)
_A specific campaign execution. Begins life as a microplan (_`intent=plan`_) and evolves into the execution record as Tasks complete and coverage accumulates. Rounds are sibling ICRCampaigns under an umbrella campaign via_ `partOf`_._ (working doc §7.2, §6.3)

_Proposed for a subsequent round (§17.2): the_ `activity-type` _and_ `coverage-target` _axes (§5.1) also surface here on ICRCampaign, plus_ **_round1↔round2 linkage_** _for OCV/multi-round campaigns (§17.2 B3)._

**How a campaign moves through its life (**`plan → order`**).** A campaign is born as a _microplan_ and matures into the _execution record_ of the **same** `ICRCampaign` resource — `intent` flips `plan → order`, `status` walks `draft → active → completed`, and Tasks plus coverage accumulate against it. Rounds are sibling executions under a national umbrella via `partOf`, and every one of them points at the single versioned protocol:

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

The umbrella stays `intent = plan` — it is the planning shell that holds the national denominator and binds the rounds together; each round goes `plan → order` as it executes. Because every box points at the **same** protocol, "all MR SIA rounds, anywhere" is one query, not a research project (§5.1). The actual JSON for the umbrella and a round is below, after the who-vs-where explanation.

**Planned vs executed — is there a plan per sub-area?** Yes. Each sub-national scope (district/round) is its **own** ICRCampaign, a `partOf` child of the national umbrella — so a three-district campaign has three round CarePlans, each with its own `subject` denominator, `targetGeography`, and `period`. Planned-vs-executed is captured by the **lifecycle of that same resource**: it is born `intent = plan` (the microplan — planning denominator, target geography, planned period) and matures to `intent = order` as Tasks complete and coverage accrues against it. The planned target is **not** duplicated into a separate resource — the `planningDenominator` extension already holds it, and the planned-vs-actual audit trail comes from FHIR resource history / Provenance (the versioned states of the CarePlan), not a parallel snapshot. (Per c112: because the denominator is already retained, ICR does **not** mint a separate planning-snapshot Group.)

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

**Who vs where, and nested scopes.** Each CarePlan has exactly **one** `subject` — the WHO, an ICRTargetPopulation ("children 9m–14y, Kambia, 48,250"). The WHERE is separate and plural: `targetGeography` is 0..*, so one campaign can name several geographies. Multiple and nested populations are carried by the **umbrella/round stack**, not by overloading one CarePlan:

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

One subject per CarePlan; as many CarePlans as the campaign has nested scopes, linked by `partOf`; finer-grained targets (per-ward) exist as additional geography-scoped ICRTargetPopulation Groups that planning and coverage reference without being anyone's `subject`. These nested scopes do **not** sum to the parent total — each carries its own denominator from its own source and method (national 2,150,000 census-projection vs Kambia 48,250 GRID3), so a district and the nation legitimately disagree (§6.2); they nest _conceptually_ via `partOf`, not arithmetically.

**The campaign as FHIR/JSON — umbrella + round.** Two `ICRCampaign` (CarePlan) instances from the scenario. First the **national umbrella** (the microplan shell):

```json
{
  "resourceType": "CarePlan",
  "id": "example-mr-sia-national",
  "meta": {
    "profile": [
      "https://fhir.icr.unicef.org/StructureDefinition/ICRCampaign"
    ]
  },
  "instantiatesCanonical": [
    "https://fhir.icr.unicef.org/PlanDefinition/example-mr-sia-protocol"
  ],
  "status": "active",
  "intent": "plan",
  "category": [
    {
      "coding": [
        {
          "system": "https://fhir.icr.unicef.org/CodeSystem/icr-campaign-type",
          "code": "vaccination-sia"
        }
      ]
    }
  ],
  "subject": {
    "reference": "Group/example-target-population-national"
  },
  "period": {
    "start": "2026-06-15",
    "end": "2026-12-18"
  },
  "addresses": [
    {
      "display": "Measles and rubella"
    }
  ],
  "extension": [
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/planning-denominator",
      "valueReference": {
        "reference": "Group/example-target-population-national"
      }
    }
  ]
}
```

Then the **Kambia June round**, a child execution of that umbrella:

```json
{
  "resourceType": "CarePlan",
  "id": "example-mr-sia-2026",
  "meta": {
    "profile": [
      "https://fhir.icr.unicef.org/StructureDefinition/ICRCampaign"
    ]
  },
  "instantiatesCanonical": [
    "https://fhir.icr.unicef.org/PlanDefinition/example-mr-sia-protocol"
  ],
  "status": "completed",
  "intent": "order",
  "category": [
    {
      "coding": [
        {
          "system": "https://fhir.icr.unicef.org/CodeSystem/icr-campaign-type",
          "code": "vaccination-sia"
        }
      ]
    }
  ],
  "subject": {
    "reference": "Group/example-target-population"
  },
  "period": {
    "start": "2026-06-15",
    "end": "2026-06-26"
  },
  "partOf": [
    {
      "reference": "CarePlan/example-mr-sia-national"
    }
  ],
  "addresses": [
    {
      "display": "Measles and rubella"
    }
  ],
  "activity": [
    {
      "reference": {
        "reference": "Task/example-site-session-task"
      }
    },
    {
      "reference": {
        "reference": "Task/example-mopup-task"
      }
    }
  ],
  "extension": [
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/campaign-round",
      "valuePositiveInt": 1
    },
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/target-geography",
      "valueReference": {
        "reference": "Location/example-district"
      }
    },
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/planning-denominator",
      "valueReference": {
        "reference": "Group/example-target-population"
      }
    }
  ]
}
```

Annotated, reading the links out: `instantiatesCanonical` (**1..1**) makes both campaigns point at the one protocol in §5.1. `intent` is the lifecycle dial — the umbrella stays `plan`, the round is `order` (executing). `subject` is the WHO — each scope its own ICRTargetPopulation denominator Group (national 2,150,000 vs Kambia 48,250; §6.2), which is the concrete answer to c65: different numbers from different sources, _not_ a partition of one total. `partOf` makes the round a child of the umbrella. `activity.reference` lists the round's Tasks (§5.4). The three extensions carry exactly what the protocol omits: which `campaign-round` this is, the `target-geography` (WHERE, `0..*` — here the district Location, §6.3), and the `planning-denominator` that singles out _the_ denominator coverage is computed against. (`addresses` is R4 `Reference(Condition)` — shown here as a **display-only** reference because the scenario ships no Condition instance; in production it would point at a Condition coded to SNOMED CT / ICD-11, which is where the specific disease lives since campaign `type` is deliberately disease-agnostic.)

**Design notes.** `instantiatesCanonical` `1..1` is a deliberate forcing function — every campaign, including ad-hoc/emergency ones, authors a protocol first (the relief valve, if ever needed, is `0..1` with a flag). The umbrella is itself an ICRCampaign, so it carries its own (national) denominator, `category`, and `period` — the modeling burden the umbrella example demonstrates. And `activity.reference` is locked to Task: **inline activities (**`activity.detail`**) are out** — the work is always a referenced ICRCampaignTask.
### 5.3 ICRCampaignActivity — `ActivityDefinition`
_A discrete work type within a campaign — "administer albendazole to children 5–14", "distribute ITNs to households" — instantiated as ICRCampaignTask resources._ (working doc §7.3)

_Proposed for a subsequent round (§17.2 P1): a_ `dosing-regimen` _axis (single-dose-lifelong / multi-dose / fractional) on the activity (and event, §7.1), needed to define "fully immunized."_

| Element | Constraint |
|---|---|
| `status` | MS |
| `kind` | fixed `#Task` |
| `code` | **1..1 MS** — "The intervention: vaccinate / treat / distribute / spray" |
| `product[x]` | MS — "Vaccine (CVX) / drug (ATC) / commodity (GS1)" |
| `dosage` | MS — "Where applicable; dose-pole logic references an Observation" |
| `extension[deliveryStrategy]` | 0..1 MS |

**The activity gallery.** Four ActivityDefinitions now ship in the IG, spanning the campaign types — each says only WHAT, never which concrete target:

| Instance | Intervention | Product | Dosage / rule |
|---|---|---|---|
| `example-mcv-activity` | Vaccinate (Type A/B) | CVX `05` measles virus vaccine | 0.5 mL subcutaneous, single dose |
| `example-albendazole-activity` | Treat (Type C MDA) | ATC `P02CA03` albendazole | 400 mg single dose; tablet count by **dose-pole height band** |
| `example-itn-activity` | Distribute (Type B→A) | LLIN (free-text pending GS1) | 1 net per 2 household members |
| `example-irs-activity` | Spray (Type B) | Pirimiphos-methyl 300CS | interior walls of eligible structures |

**What lives here vs what lives on the Task.** The ActivityDefinition is deliberately **target-agnostic**: it carries the intervention, product, and dosage rule — and at most the _kind_ of eligible target (`subject[x]` can say "children 9m–14y" as a category). The concrete thing acted on — THIS household, THIS structure, THIS school session — is each **Task's** `focus`, assigned per unit of work. So "spray house" Tasks focus on structures (Locations), "vaccinate" Tasks focus on households (Groups) with per-child detail in the Immunization records off `Task.output`, and a hypothetical "set fly trap" activity would produce Tasks focusing on trap sites. The protocol carries the clinical/commodity content **once**; thousands of Tasks instantiate it without repeating it. (Boundary note: vector-control work like traps and larviciding is outside the v0.1 program scope and has no delivery-event profile — flag it if entomological surveillance enters ICR's future.)

**Rationale.** `kind = #Task` hard-wires the instantiation target: activities become Tasks, not ServiceRequests. Product and dosage ride on the definition so the protocol carries the clinical content once.

**The activity as FHIR/JSON.** `example-mcv-activity` — the activity the protocol's `action` points at:

```json
{
  "resourceType": "ActivityDefinition",
  "id": "example-mcv-activity",
  "meta": {
    "profile": [
      "https://fhir.icr.unicef.org/StructureDefinition/ICRCampaignActivity"
    ]
  },
  "status": "active",
  "name": "AdministerMCV",
  "title": "Administer MCV, 9 months–14 years",
  "kind": "Task",
  "code": {
    "text": "Vaccinate — measles–rubella–containing vaccine"
  },
  "productCodeableConcept": {
    "coding": [
      {
        "system": "http://hl7.org/fhir/sid/cvx",
        "code": "05",
        "display": "measles virus vaccine"
      }
    ]
  },
  "dosage": [
    {
      "route": {
        "text": "subcutaneous"
      },
      "doseAndRate": [
        {
          "doseQuantity": {
            "value": 0.5,
            "unit": "mL",
            "system": "http://unitsofmeasure.org",
            "code": "mL"
          }
        }
      ]
    }
  ],
  "extension": [
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/delivery-strategy",
      "valueCodeableConcept": {
        "coding": [
          {
            "system": "https://fhir.icr.unicef.org/CodeSystem/icr-delivery-strategy",
            "code": "fixed-post"
          }
        ]
      }
    }
  ]
}
```

Annotated: `kind` is **fixed to** `Task` — instantiating this activity produces ICRCampaignTasks (§5.4), not ServiceRequests; `code` is the intervention; `productCodeableConcept` is the CVX vaccine code (the albendazole / ITN / IRS activities in the gallery above swap in an ATC code or free-text product instead); `dosage` rides on the definition so the clinical content is stated **once**. What's _not_ here is any concrete target — no household, no child: the activity is target-agnostic, and the thing acted on is each Task's `focus`. The same shape holds for the other three gallery activities.⁠

**Design notes.** `product[x]` is MS but **unbound** (CVX/ATC appear in the `^short` only) — the delivery-event profiles _do_ bind product codes, so binding the definition side too, for consistency, is worth considering. And `deliveryStrategy` is `0..1` here but `1..*` on the protocol and `1..1` on the Task — a defensible asymmetry: the strategy is resolved per-task, so the activity need not pin it.
### 5.4 ICRCampaignTask — `Task`
_The assignable, trackable operational unit of work — one Task per site-session (Type A) or per household/community (Type B/C). The unit being_ **_targeted_** _(household, community, or a person for follow-up) is carried by_ `Task.for`_;_ `Task.focus` _is reserved for_ **_workflow lineage_** _— the CarePlan, activity, or prior Task this work derives from. Tasks may be pre-planned from the microplan or field-registered on discovery (the required task-origin code records which). Whether Tasks are assigned at village or household level is a configuration choice._ (working doc §7.4)

| Element | Constraint |
|---|---|
| `status` | MS — "requested → in-progress → completed / failed" |
| `intent`, `owner`, `executionPeriod`, `output` | MS |
| `code` | **1..1 MS** |
| `for` | **1..1 MS** — the unit being **targeted**: `Reference(ICRDeliveryUnit \| ICRLocation \| Patient)` — household/community delivery-unit Group (Type B/C), the site Location (Type A), or a Patient for person-targeted follow-up |
| `focus` | MS — **workflow lineage**: `Reference(CarePlan \| ActivityDefinition \| ServiceRequest \| Task)` — the campaign/activity this work instantiates, or the prior Task it follows (e.g. a mop-up Task following the session Task that missed a child) |
| `location` | **1..1 MS**, only `Reference(ICRLocation)` |
| `output` | MS — "references to Immunization / MedicationAdministration / SupplyDelivery, or aggregate counts" |
| Extensions | `deliveryStrategy` **1..1 MS** · `taskOrigin` **1..1 MS** (code: pre-planned \| field-registered, required binding) · `housesVisited` 0..1 · `eligiblePresent` 0..1 · `eligibleAbsent` 0..1 · `missedReason` 0..\* · `noncomplianceReason` 0..\* · `fingerMarked` 0..1 · `dataLineage` 0..1 |

**Task granularity: one Task per visit, person-level detail in the delivery events.** A polio team's doorstep visit is **one** Task — it closes when the visit completes — and each child vaccinated gets their own `Immunization` resource hanging off `Task.output`, pointing at their `Patient`. So person-level capture happens in the **delivery-event layer**, not by multiplying Tasks: the Task is the unit of _work_ (one visit), the delivery events are the units of _service_ (three drops given). The IG's mop-up example shows the full chain: one household Task → output → the MCV dose for one child. **The deliberate exception is person-targeted follow-up** (a key invariant — see §13 #8): when a specific missed or zero-dose child needs chasing, a new Task is spawned whose `for` IS that child's `Patient` record (the §4.4 routine-enrolment pattern), with `focus` pointing back at the originating session/mop-up Task that missed them — so person-level targeting lives in `for` and the workflow lineage in `focus`. This is the _only_ intended person-targeted Task. Routine per-child Tasks would multiply Task volume ~5× (the scale concern below) while adding nothing the Immunization records don't already carry.

**Rationale.** This is where campaign type A/B/C polymorphism lands: the _same_ profile serves a fixed-post site-session and a house-to-house visit, discriminated by `for` type (site Location vs household/community Group) and the mandatory coded `deliveryStrategy`. The optional count/reason extensions are exactly the house-to-house data elements (houses visited, present/absent, missed/noncompliance reasons, finger marking) that only exist for strategy B — they're 0..x because they're meaningless for fixed-post tallies. `taskOrigin` **is mandatory** (the same required-coded-attribute pattern as delivery strategy and record origin): Tasks need not be pre-generated — a team that discovers an unenumerated household creates the ICRDeliveryUnit and its Task on the spot — and the count of field-registered Tasks per area is itself a measurement of how incomplete the microplan's enumeration was, feeding the next round's denominators. Delivery events hang off `Task.output` because **R4 Immunization has no** `basedOn` (the reverse link doesn't exist; see §7).

**The Task as FHIR/JSON.** `example-mopup-task` — the Type-B house-to-house visit, the richer of the two Task shapes and the one that chains to a delivery event:

```json
{
  "resourceType": "Task",
  "id": "example-mopup-task",
  "meta": {
    "profile": [
      "https://fhir.icr.unicef.org/StructureDefinition/ICRCampaignTask"
    ]
  },
  "status": "completed",
  "intent": "order",
  "code": {
    "text": "Administer MCV — house-to-house mop-up visit"
  },
  "for": {
    "reference": "Group/example-household"
  },
  "focus": {
    "reference": "CarePlan/example-mr-sia-2026"
  },
  "location": {
    "reference": "Location/example-dwelling"
  },
  "executionPeriod": {
    "start": "2026-06-24",
    "end": "2026-06-24"
  },
  "owner": {
    "display": "CDD team 7, Rokupr"
  },
  "output": [
    {
      "type": {
        "text": "Immunization administered"
      },
      "valueReference": {
        "reference": "Immunization/example-mcv-dose"
      }
    }
  ],
  "extension": [
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/delivery-strategy",
      "valueCodeableConcept": {
        "coding": [
          {
            "system": "https://fhir.icr.unicef.org/CodeSystem/icr-delivery-strategy",
            "code": "house-to-house"
          }
        ]
      }
    },
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/task-origin",
      "valueCode": "field-registered"
    },
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/eligible-present",
      "valueUnsignedInt": 2
    },
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/eligible-absent",
      "valueUnsignedInt": 1
    },
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/missed-reason",
      "valueCodeableConcept": {
        "coding": [
          {
            "system": "https://fhir.icr.unicef.org/CodeSystem/icr-missed-reason",
            "code": "absent"
          }
        ]
      }
    },
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/finger-marked",
      "valueBoolean": true
    }
  ]
}
```

Annotated, with the links read out: `for` points at the **household delivery-unit Group** (§6.1) — the Type-B target (a Type-A site-session Task instead has `for` = the fixed-post Location); `focus` carries the **workflow lineage**, here the round CarePlan (§5.2), so the dose traces back to the campaign that ordered it; `location` is where the work happened (the dwelling, §6.3). `output` is the **whole Task→event mechanism** — it references the `Immunization` in §7.1 (R4 Immunization has no `basedOn`, so the link runs this way). The mandatory coded extensions are `delivery-strategy` (1..1) and `task-origin` — here `field-registered`, the discovery-mode pattern: this household wasn't in the microplan; the team created it and its Task on the doorstep. The house-to-house tally extensions (`eligible-present` 2 / `eligible-absent` 1, `missed-reason absent`, `finger-marked`) only exist for strategy B — they'd be meaningless on a fixed-post session.⁠

**Open task-level notes.** **Granularity at scale** remains the IG's #1 open question (one Task per household × a national campaign = millions of Tasks); the profile keeps both the household-level and site-level paths open, and field-registration (lazy Task creation on discovery) softens the pre-generation worst case — but pilots must exercise the household-level path (§15 hold-for-review).

**How to disaggregate (recommended pattern).** The count extensions (`eligible-present`/`eligible-absent`, `houses-visited`) are deliberately **point values** — a quick visit-level tally. Age-band/sex disaggregation should **not** be done by multiplying those extensions; do it one of two ways: (a) `Task.output` **as coded aggregate counts** — emit one output entry per stratum, each carrying a coded `type` for the age band / sex (e.g. "9–59 months, female"); or (b) where person-level data exists, **derive disaggregation from the individual** `Immunization`**/**`MedicationAdministration` **records**, which already carry the patient's age and sex. The point-value extensions stay as the visit-level summary; the disaggregated truth lives in `output` or the delivery events. The same principle governs per-child reasons: `missed-reason`/`noncompliance-reason` at Task level aggregate over the whole visit, so per-child reasons require person-level records.

Two smaller items: `output.valueReference` is not yet structurally constrained to the three delivery-event profiles (the `^short` says it; the profile doesn't enforce it); and `task-origin` `1..1` means historical imports must assign an origin — acceptable as a forcing function, or add an `unknown` code for back-loaded datasets (§15 #4).

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

**Rationale.** Separating _who_ (Group) from _where_ (Location) means the location's identity (GERS building/place ID) survives group composition changes, and the group survives re-mapping. The second-pass generalization (was: ICRHousehold) reflects that households and communities are the _same pattern at two scales_ — one profile with a coded kind beats two near-identical profiles, and it lets `Task.focus` and `MedicationAdministration.subject` be narrowed to ICR-conformant targets; `school-cohort` (third pass) demonstrates the kind list extends to non-obvious delivery units (nomadic groups, camp populations) as country demand appears. `quantity` covers the common case where campaigns count members without registering individuals — person-level `member` entries are optional by design. **Why** `member.entity` **is Patient (re c14/c83):** FHIR has four person-shaped resources — **Patient** (anyone who might receive a service: despite the name, a healthy child getting a measles dose or a household member receiving a net is a Patient, and it is the resource every clinical/delivery record points at — `Immunization.patient` can _only_ be a Patient), **RelatedPerson** (a caregiver in relation to a patient), **Practitioner** (workers — CDDs, vaccinators), and **Person** (an identity-linkage resource matching one human across systems — plumbing, not a care-record subject). So every enumerated household member is a Patient (the standard household-registration pattern, as in OpenSRP). Locking `member.entity` to Patient therefore excludes Practitioner/Device/etc. — **not** RelatedPerson, which R4 `Group.member` never permitted in the first place (RelatedPerson membership only arrives in R5). `groupLocation` **is residence, not service point**: where service actually happened is `Task.location` and the delivery event's own `location`. A household that walks to a village distribution center keeps its dwelling here unchanged — the Task records the center.

> [!info] WHO SMART alignment (§18) WHO's `IMMZ.Patient` profiles **base R4 Patient** (not IPS, despite its own narrative claiming so) with required identifier / name / phone / gender / birthDate / address. Proposed: align ICR's person records to `IMMZ.Patient` (or note a deliberate divergence) so household members are WHO-conformant. WHO's caregiver is `IMMZ.Caregiver` (RelatedPerson). See §18.3.

**The delivery unit as FHIR/JSON.** `example-household` — the Type-B unit a mop-up Task focuses on:

```json
{
  "resourceType": "Group",
  "id": "example-household",
  "meta": {
    "profile": [
      "https://fhir.icr.unicef.org/StructureDefinition/ICRDeliveryUnit"
    ]
  },
  "type": "person",
  "actual": true,
  "code": {
    "coding": [
      {
        "system": "https://fhir.icr.unicef.org/CodeSystem/icr-group-kind",
        "code": "household"
      }
    ]
  },
  "quantity": 6,
  "member": [
    {
      "entity": {
        "reference": "Patient/example-child"
      }
    }
  ],
  "extension": [
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/group-location",
      "valueReference": {
        "reference": "Location/example-dwelling"
      }
    }
  ]
}
```

Annotated: `code` is the **required** group-kind (`household` here; `community` or `school-cohort` for the other delivery units, same profile); `quantity` 6 is the head-count even though only one `member` (the child, `Patient/example-child`, §7.1) is individually enumerated; `group-location` is the dwelling Location (§6.3) — **residence, not service point** (where service actually happened is the Task's `location`). It is deliberately named `group-location`, **not** `household-location` (its name before the v0.3.0 generalization): the _same_ extension carries a community's settlement point and a school-cohort's school, so it can't be household-specific without losing those cases — swap `code` to `community` and point `group-location` at a settlement and this same JSON becomes the Type-C community delivery unit.⁠

**Household identity across campaigns (resolved approach).** A household is identified by its **members**, anchored on the head of household (keyed by `Patient.id` or, better, an established external ID such as a national ID); **cross-campaign linkage** joins on the **dwelling**, whose `group-location` Location carries a stable GERS building ID that survives household composition changes. `Group.identifier` itself stays light — identity is reconstructed from head-of-household + dwelling GERS ID — so this folds into the record-linkage work (background §12) rather than minting a new household-identifier scheme. Two follow-ups remain: whether to _also_ stamp a convenience `Group.identifier` for direct lookup, and how to handle head-of-household churn (death, migration, household splits) — the dwelling GERS ID is the durable join key, the person ID disambiguates which household at that structure.
### 6.2 ICRTargetPopulation — `Group`
_A target-population denominator: a conceptual cohort (_`actual=false`_) with a count, eligibility characteristics, and — critically — source and date provenance. Multiple competing estimates per geography are retained; exactly one is flagged as the planning denominator._ (working doc §7.6, §4.2)

_Proposed for a subsequent round (§17): an_ **_at-risk / eligible denominator_** _type to drive programme-vs-epidemiological coverage (§17.2 B1); a_ **_population-estimation-method + source-raster version/date_** _so two_ `worldpop` _estimates are distinguishable (§17.4); and a_ **_population-vulnerability / equity_** _characteristic (§17.3)._

| Element | Constraint |
|---|---|
| `type` | fixed `#person` |
| `actual` | fixed `false` |
| `quantity` | **1..1 MS** — the denominator count |
| `characteristic` | MS — "Age band, sex, eligibility rule, geography"; **sliced (pattern on `code`, open)** |
| `characteristic[geography]` | 0..1 MS — `code` fixed to `icr-group-characteristic-cs#geography`; `value[x]` only `Reference(ICRLocation)`; `exclude` fixed `false` |
| Extensions | `denominatorSource` **0..1 MS** (CodeableConcept, extensible — _recommended, not required: the population is often unknown up front_) · `estimateDate` **0..1 MS** (date — recommended) · `isPlanningDenominator` 0..1 MS (boolean) · `confidence` 0..1 (string) |

**Rationale.** Design decision #6 ("denominator-first"): the denominator is the dominant error source in campaign analytics, so provenance — source + date — is **strongly recommended** on every estimate (`0..1 MS`). It is deliberately **not mandatory**: the population is frequently unknown when planning begins, and forcing a source/date would block legitimate early or placeholder estimates — but wherever a denominator carries a real number, it should carry where and when that number came from. Keeping _competing_ estimates (census projection vs WorldPop vs microcensus) as sibling Groups and flagging one (`isPlanningDenominator`) preserves the audit trail instead of overwriting. The second-pass **geography characteristic** makes the estimate's scope computable at **any level** — country, district, ward, settlement, or operational area (working-doc comment c70: target populations are _not_ household-bound; that's what ICRDeliveryUnit is for) — so estimates are joinable to the location hierarchy by reference, not by parsing `name`.

**Worked example — competing denominators, as shipped in the IG.** Three ICRTargetPopulation instances now tell the whole story:

| Instance | Geography | Count | Source | Date | Planning? |
| --- | --- | --- | --- | --- | --- |
| `example-target-population` | → Kambia District | **48,250** | WorldPop modelled | 2026-01-15 | **true** |
| `example-target-population-enumerated` | → Kambia District | **51,800** | microcensus / H2H enumeration | 2026-03-02 | false |
| `example-target-population-national` | → Sierra Leone | 2,150,000 | census projection | 2025-11-30 | true (national) |

The first two are **the same geography disagreeing by ~7%**: WorldPop says 48k, the enumeration says 52k. Both are retained — each with its source and date — and exactly one carries the planning flag, so coverage is computed against a _declared_ choice while the disagreement stays visible instead of being silently overwritten. Run the consequence: 47,766 children reached is **99% coverage against WorldPop but 92% against the enumeration** — the denominator you pick changes the answer, which is the §4.1 Cuamba lesson in miniature and the entire reason source + date are strongly recommended on every estimate.⁠

**The denominator as FHIR/JSON.** `example-target-population` — Kambia's WorldPop planning denominator (the `subject` of the round CarePlan in §5.2):

```json
{
  "resourceType": "Group",
  "id": "example-target-population",
  "meta": {
    "profile": [
      "https://fhir.icr.unicef.org/StructureDefinition/ICRTargetPopulation"
    ]
  },
  "type": "person",
  "actual": false,
  "quantity": 48250,
  "characteristic": [
    {
      "code": {
        "coding": [
          {
            "system": "https://fhir.icr.unicef.org/CodeSystem/icr-group-characteristic",
            "code": "geography"
          }
        ]
      },
      "valueReference": {
        "reference": "Location/example-district"
      },
      "exclude": false
    }
  ],
  "extension": [
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/denominator-source",
      "valueCodeableConcept": {
        "coding": [
          {
            "system": "https://fhir.icr.unicef.org/CodeSystem/icr-denominator-source",
            "code": "worldpop"
          }
        ]
      }
    },
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/estimate-date",
      "valueDate": "2026-01-15"
    },
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/is-planning-denominator",
      "valueBoolean": true
    }
  ]
}
```

Annotated: `actual: false` is what makes this a _conceptual cohort_ — a denominator, not a roster of real people (contrast `example-household`, `actual: true`). `quantity` is the denominator count. The `geography` characteristic is the **computable** scope link — `valueReference` → the district Location (§6.3), so estimates join to the hierarchy by reference, not by parsing a name. The two provenance extensions are **strongly recommended** (`denominator-source: worldpop`, `estimate-date: 2026-01-15`) — populated wherever the number is known, though not required since the population is often unknown up front. `is-planning-denominator: true` flags this as _the_ one coverage is computed against. The competing `example-target-population-enumerated` (51,800, microcensus, `is-planning-denominator: false`) is the identical shape with a different source, date, and flag — which is exactly how the same geography keeps two disagreeing estimates side by side.⁠

**Two design notes.** "Exactly one planning denominator" is **not machine-enforced** — nothing stops two same-geography Groups both setting the flag (or none); the real enforcement point is the singular `ICRCampaign.planningDenominator` extension (`0..1`), which is where coverage actually reads its denominator from. And `confidence` is a free string for v0.1 — coded confidence is a later refinement.
### 6.3 ICRLocation — `Location`
_The most-customized ICR resource: nested administrative hierarchy (6+ levels), operational geography linkable-but-distinct from admin units, GeoJSON boundaries, and multi-system geospatial identity — GERS IDs as the preferred cross-campaign join key, with P-codes and national codes as coequal aliases._ (working doc §7.7, §9)

**Scope decision (c138/c139) — ICRLocation stays identity + hierarchy + geometry.** The §17.4 geography-refinement proposals that would attach **contextual** metadata to ICRLocation are **rejected as out of IG scope**: **accessibility / travel-time** is derived and volatile (it varies by season, transport, conflict — an analysis input, not registry truth); a **georegistry-match-status** value set is redundant, since the presence/absence of a GERS identifier already conveys match state; and **endemicity** + the **TAS/impact-survey gate** are NTD-programme state on their own cadence. The point of a stable location ID is that all of this contextual data links to the Location **externally by ID** rather than living in the core IG (consistent with §17.6, "surveillance — reference, don't model"). The only possible keeper from that list is a `structure`/footprint **location-type**, since that's identity, not context. Separately, the GeoJSON "open question" is **closed** — `location-boundary-geojson` already ships (§9). §17.4 carries these as rejected/out-of-scope.

**The two hierarchies, side by side.** The `partOf` chain is the **administrative** tree (one parent each); operational geography sits **beside** it — its own Location, _not_ in the `partOf` chain, linked to the admin unit(s) it covers by `overlays-admin-unit`:

```mermaid
graph TD
    C["Sierra Leone<br/>(country · admin-unit)"]
    D["Kambia District<br/>(district · admin-unit)"]
    S["Rokupr<br/>(settlement)"]
    H["dwelling<br/>(house)"]
    Z["Kambia supervision zone 2<br/>(supervisory-area)<br/><i>not in the partOf tree</i>"]
    D -- "partOf" --> C
    S -- "partOf" --> D
    H -- "partOf" --> S
    Z -. "overlays-admin-unit" .-> D
```

Reading it: every box on the solid `partOf` spine is an ICRLocation pointing at its single parent (country → district → settlement → dwelling — the chain runs 6+ levels in practice). "Kambia supervision zone 2" is the operational exception: it hangs off **nothing** in the admin tree (a supervisory zone can straddle several wards, so it _can't_ have one parent), and instead carries a dashed `overlays-admin-unit` pointer at the district it reports into — which is exactly what makes operational geography **linkable-but-distinct** (§6.3 rationale, c17/c37).

| Element | Constraint |
|---|---|
| `name`, `status` | MS |
| `partOf` | MS, only `Reference(ICRLocation)` — "country → region → district → ward → settlement" |
| `physicalType` | MS — "jurisdiction / site / building / household" |
| `type` | MS, bound **extensible** to **ICRLocationTypeVS** — admin-unit / settlement / facility / school / community-distribution-point / temporary-post / household / **supervisory-area** / **operational-area** |
| `position` | MS — GPS point |
| `identifier` | MS, **sliced by `system` (value discriminator, open)**: `gers` 0..1 MS (system = `$GERSId`) · `pcode` 0..1 MS (system = `$PCode`) · `national` 0..\* (the country/implementer's own admin code — system = `$NationalAdminCode`) · `iso` 0..\* (ISO 3166-1 alpha for admin-0, ISO 3166-2 for admin-1/-2/-3; system = `$ISO`) — **≥1 identifier required when `type = admin-unit`** (invariant `icr-loc-admin-id`, c88) |
| `extension[boundary]` | 0..1 MS — GeoJSON Attachment, "the geometry Crosscut enriches and pushes back" |
| `extension[deliveryStrategy]` | 0..1 — "For delivery sites (fixed/temporary posts): the strategy this site serves" |
| `extension[overlaysAdminUnit]` | 0..\* → `Reference(ICRLocation)` — for operational geography: the admin unit(s) this area overlays; **1..\* required when `type ∈ {supervisory-area, operational-area}`** (invariant `icr-loc-overlays`, c90) |
| `extension[locationAncestors]` | 0..\* (proposed, c89) — denormalized admin breadcrumb: per-level ancestor (`adm0`…`adm3+`) as a coded level + `Reference(ICRLocation)`, **server-maintained** from `partOf`, for fast hierarchy filtering without deep recursion |

> [!info] WHO SMART alignment (§18) WHO models geography only as `country-of-vaccination` (ISO 3166-1) + `administrative-area` extensions on the immunization event — ICRLocation (GERS, operational geography, GeoJSON, admin hierarchy) is far richer and maps onto WHO's `IMMZ.A` **Vaccination-location registration** process. ICR leads here; reuse WHO's two extensions where they overlap, and reference the `IMMZ.A` process. See §18.2–18.4.

**Rationale.** Design decision #8. Open slicing means national location codes coexist with GERS/P-codes without profile changes. The GERS `^short` carries an operationally crucial instruction: **record the Overture release version alongside the ID** (GERS IDs are stable but the registry versions). The boundary extension mirrors the R5 standard extension on R4 (working doc §10 q6). The second-pass additions give **"operational ≠ administrative geography" a real mechanism** (working-doc comment c74): `partOf` can express only _one_ hierarchy, so a supervisory/operational area is typed via the new location-type codes and linked to the admin units it covers via `overlays-admin-unit` — that is what makes it linkable-but-distinct rather than just distinct (the two-hierarchy diagram above shows it).

**Identity & hierarchy refinements (v0.7.0, from your Jun 15 review).**

- **Admin units must carry an identifier, and it needn't be a P-code (c88).** The identifier slicing stays open, but is now named to make the country's options first-class: alongside `gers` and `pcode`, a `national` slice holds the implementer's own admin code (many countries key on a national code, not a P-code) and an `iso` slice holds ISO 3166-1/-2 codes for the upper levels (admin 0–3). A new invariant (`icr-loc-admin-id`) requires **at least one** identifier — any system — when `type = admin-unit`, so an administrative area can't exist with no stable code, while sites and dwellings stay loose.
  
- `partOf` **typing is an open decision (c87).** Constraining `partOf` to `Reference(ICRLocation)` keeps the whole tree ICR-conformant (clean, fully queryable) but means you can't hang an ICR site directly under a Location from a pre-existing national MFL/GIS without re-profiling it. The relief valve is to widen `partOf` to `Reference(Location)`. Left as a project decision — it pairs with the c88 national-code work, since both govern how ICR coexists with existing registries.
  
- **Operational areas must declare what they overlay (c90).** The `overlays-admin-unit` extension is now required `1..*` when `type` is `supervisory-area`/`operational-area` (invariant `icr-loc-overlays`): an operational area that overlays nothing can't be rolled up to any admin reporting unit, so its data would float — the invariant forbids that.
  
- **A breadcrumb to tame deep** `partOf` **(c89).** A proposed, **server-maintained** `location-ancestors` extension denormalizes the chain into per-level pointers (`adm0`…`adm3+`), so "everything in Kambia District" is one indexed search instead of N `partOf` hops on a mobile client. It is derived data — re-computed on write and on re-parenting, never hand-authored out of sync with `partOf`.
  

**The location as FHIR/JSON.** `example-district` — Kambia District, showing the multi-system identity and the admin hierarchy:

```json
{
  "resourceType": "Location",
  "id": "example-district",
  "meta": {
    "profile": [
      "https://fhir.icr.unicef.org/StructureDefinition/ICRLocation"
    ]
  },
  "status": "active",
  "name": "Kambia District",
  "physicalType": {
    "coding": [
      {
        "system": "http://terminology.hl7.org/CodeSystem/location-physical-type",
        "code": "jdn",
        "display": "Jurisdiction"
      }
    ]
  },
  "type": [
    {
      "coding": [
        {
          "system": "https://fhir.icr.unicef.org/CodeSystem/icr-location-type",
          "code": "admin-unit"
        }
      ]
    }
  ],
  "partOf": {
    "reference": "Location/example-country"
  },
  "identifier": [
    {
      "system": "https://fhir.icr.unicef.org/identifiers/pcode",
      "value": "SL0201"
    },
    {
      "system": "https://fhir.icr.unicef.org/identifiers/overture-gers",
      "value": "overture-division-kambia-example"
    }
  ]
}
```

Annotated: `partOf` climbs the admin tree (district → `example-country`; the full chain runs country → district → settlement → dwelling, each its own ICRLocation). `type` is the ICR location-type (`admin-unit`); `physicalType` carries the base-FHIR shape. The **sliced** `identifier` is the multi-system identity — a P-code **and** a GERS ID coexisting, each tagged by its `system` URI (the mechanism behind cross-campaign joins, §3); both slices are `0..1`, so a brand-new unmapped location can exist with national codes only and get its GERS ID back-filled async (the lifecycle described just above). A delivery-site Location (the fixed post) additionally carries a `delivery-strategy` extension; a supervisory area carries `overlays-admin-unit` _instead of_ sitting in the `partOf` tree.⁠

**Two open decisions carried forward** (the admin-identifier and breadcrumb items above are applied; these two are not):

- **Overture release version has no field (§15 #2).** A GERS ID identifies a place, but Overture re-publishes the registry on a release cadence, and an ID's attributes (geometry, name, active/retired) can change between releases — so a stored ID is only reproducible if you also record **which release** you matched against. FHIR `Identifier` has no version slot (`identifier.period` means something else). This is **awaiting the Overture-side answer** (does Overture expose a stable release identifier, and in what form) before the field can be modeled — likely a small `gers-release` extension on the identifier slice.
  
- `partOf` **strict-typing vs widening (§15 #2).** `ICRLocation.partOf` is constrained to `Reference(ICRLocation)`, so the _entire_ ancestor chain must be ICR-conformant. Clean and fully queryable, but it means you can't hang an ICR site directly under a Location from a pre-existing national MFL/GIS without re-profiling that parent. The relief valve is to widen `partOf` to `Reference(Location)`. **Open design decision**, paired with the national/ISO admin-code work (c88) since both govern how ICR coexists with existing registries.
  

* * *
## 7. Delivery-event profiles (`profiles-delivery.fsh`)
All three share two design constants: a **mandatory** `record-origin` **extension (1..1 MS)** — campaign vs routine, so SIA doses never contaminate routine coverage analytics (working doc §4.4) — and the **Task→event link running through** `Task.output` because R4 Immunization has no `basedOn` element to point back with.

> [!info] WHO SMART alignment (§18) WHO already ships an `IMMZ.AdverseEvent` profile (base AdverseEvent, from `IMMZ.D17 Report AEFI`, bound to `IMMZ.D.DE95/DE107/DE115`) — **reuse it** rather than minting a new `aefi-causal-type` VS (supersedes §17 C1). The `record-origin` campaign/routine flag is ICR's own — it's the seam that lets a campaign `ICRImmunizationEvent` and a routine `IMMZ.Immunization` coexist in one store. See §18.1/§18.3.

_Proposed for a subsequent round (§17.2 P1 / §17.3): an_ **_AEFI profile_** _—_ **_AEFI = Adverse Event Following Immunization_**_, a safety event reported after a dose (fever, abscess, anaphylaxis, etc.). Rather than mint a new_ `aefi-causal-type` _value set, the plan is to_ **_reuse WHO's_** `IMMZ.AdverseEvent` _profile and its AEFI value sets (§18.3). Also proposed:_ **_wastage / vial-accountability_** _(C2) and a_ `stockpile-source` _axis (ICG / national / Gavi, A3) on ICRSupplyDelivery, and_ **_cold-chain / stock-readiness_** _beyond SupplyDelivery (§17.4). (On c141 — "can the record just be a MedicationAdministration?" — see the aggregate-vs-individual rule in §7.3.)_
### 7.1 ICRImmunizationEvent — `Immunization`
| Element | Constraint |
|---|---|
| `status`, `patient`, `occurrence[x]`, `location`, `lotNumber`, `manufacturer`, `performer` | MS |
| `vaccineCode` | MS, bound **extensible** to the core FHIR vaccine-code VS (CVX) — "local codes map back via ConceptMap" |
| `protocolApplied` | MS — "Dose number / series — supports multi-dose campaigns (OCV) and routine integration" |
| `extension[recordOrigin]` | **1..1 MS** (code: campaign \| routine, required binding) |

`lotNumber`/`manufacturer` MS = lot accountability (AEFI traceability); `protocolApplied` is the bridge to routine-immunization series logic.

> [!info] WHO SMART alignment (§18) WHO's `IMMZ.Immunization` is also base-R4 Immunization with required `vaccineCode`/`patient`/`occurrence` and `protocolApplied` series/dose (already aligned), plus type-of-dose / vaccine-brand / market-authorization-holder / country-of-vaccination extensions. Proposed: make `ICRImmunizationEvent` **compatible-with / derived-from** `IMMZ.Immunization` so a campaign dose is a valid WHO immunization carrying `record-origin`. One divergence to reconcile: WHO uses its own `IMMZ.Z` **vaccine codes**, not CVX → bridge via ConceptMap (§18.4). The type-of-dose extension overlaps the §17 A4 dosing-regimen proposal. See §18.3.

**The dose as FHIR/JSON.** `example-mcv-dose` — the delivery event the mop-up Task's `output` points at, closing the chain protocol → activity → campaign → task → **dose → patient**:

```json
{
  "resourceType": "Immunization",
  "id": "example-mcv-dose",
  "meta": {
    "profile": [
      "https://fhir.icr.unicef.org/StructureDefinition/ICRImmunizationEvent"
    ]
  },
  "status": "completed",
  "vaccineCode": {
    "coding": [
      {
        "system": "http://hl7.org/fhir/sid/cvx",
        "code": "05",
        "display": "measles virus vaccine"
      }
    ]
  },
  "patient": {
    "reference": "Patient/example-child"
  },
  "occurrenceDateTime": "2026-06-24",
  "location": {
    "reference": "Location/example-dwelling"
  },
  "lotNumber": "MRV-2026-0412",
  "manufacturer": {
    "display": "Serum Institute of India"
  },
  "performer": [
    {
      "actor": {
        "display": "CDD team 7, Rokupr"
      }
    }
  ],
  "protocolApplied": [
    {
      "doseNumberPositiveInt": 1
    }
  ],
  "extension": [
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/record-origin",
      "valueCode": "campaign"
    }
  ]
}
```

Annotated: `patient` is the **person-level capture** — the same `example-child` who is the household's `member` (§6.1) — which is how polio-style member-level data lands without multiplying Tasks (§5.4): one Task per visit, one Immunization per child off `Task.output`. `vaccineCode` is the CVX matching the activity's product (§5.3). The **mandatory** `record-origin: campaign` is the firewall keeping SIA doses out of routine coverage analytics. `lotNumber`/`manufacturer` give AEFI lot traceability; `protocolApplied.doseNumber` bridges to routine-series logic.⁠
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

**The MDA administration as FHIR/JSON.** `example-albendazole-administration` (#23, §11) — an NTD drug given house-to-house, the MedicationAdministration counterpart to the §7.1 dose:

```json
{
  "resourceType": "MedicationAdministration",
  "id": "example-albendazole-administration",
  "meta": {
    "profile": [
      "https://fhir.icr.unicef.org/StructureDefinition/ICRMedicationAdministration"
    ]
  },
  "status": "completed",
  "medicationCodeableConcept": {
    "coding": [
      {
        "system": "http://www.whocc.no/atc",
        "code": "P02CA03",
        "display": "albendazole"
      }
    ]
  },
  "subject": {
    "reference": "Patient/example-child"
  },
  "effectiveDateTime": "2026-06-24",
  "dosage": {
    "text": "1 tablet (400 mg), dose-pole band B",
    "dose": {
      "value": 400,
      "unit": "mg",
      "system": "http://unitsofmeasure.org",
      "code": "mg"
    }
  },
  "supportingInformation": [
    {
      "display": "Dose-pole height-band Observation (band B) — display-only; the scenario ships no Observation instance yet"
    }
  ],
  "extension": [
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/record-origin",
      "valueCode": "campaign"
    },
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/directly-observed-consumption",
      "valueBoolean": true
    }
  ]
}
```

Annotated, with the distinctly-MDA pieces called out: `medicationCodeableConcept` is the **ATC** drug code (`P02CA03` albendazole), the PC-NTD backbone (contrast §7.1's CVX vaccine code). `subject` is the treated child here, but the profile also allows an **ICRDeliveryUnit Group** — the community/household — for register-level MDA capture where individuals aren't enumerated. `dosage` is the tablet count, and `supportingInformation` is meant to reference the **dose-pole height-band Observation** the count was derived from (shown display-only because the scenario doesn't yet ship that Observation — the §11 q1 dangling-Type-C thread). The **mandatory** `record-origin: campaign` is the same routine-vs-campaign firewall as on the vaccine dose; `directly-observed-consumption: true` records the DOC supervision protocol — the MDA-specific distinction between "handed out" and "actually swallowed".⁠
### 7.3 ICRSupplyDelivery — `SupplyDelivery`
| Element | Constraint |
| --- | --- |
| `status` | MS  |
| `suppliedItem`, `suppliedItem.quantity`, `suppliedItem.item[x]` | MS — "GS1 GTIN-coded commodity where applicable" |
| `destination` | MS — "Where the commodity went (post, household)" |
| `extension[recordOrigin]` | **1..1 MS** |

**Aggregate vs individual records — the rule (resolves c141).** The split is: **individual record when you have a person; aggregate count on** `Task.output` **when you don't;** `MeasureReport` **only for derived coverage** (numerator/denominator/score), never a raw tally. Concretely — **MDA / drugs:** `ICRMedicationAdministration.subject` already allows an **ICRDeliveryUnit Group** (§7.2), so a community-register aggregate is a perfectly consistent MedicationAdministration (exactly the consistency c141 asks for). **Vaccines:** R4 `Immunization.patient` is `1..1 Reference(Patient)` and **cannot** point at a Group, and re-housing a vaccine tally as a MedicationAdministration would break the vaccine = Immunization convention (and the WHO `IMMZ.Immunization` alignment, §18.3); so a Type-A vaccine **session tally** lives as an aggregate count on `Task.output` (example #20 = 412 doses), and individual `Immunization`s are minted only when person-level data exists (the registry-need case). MeasureReport is not a tally store.

Three smaller delivery-layer items: `vaccineCode` binds to the generic FHIR VS rather than an ICR-curated SIA subset (fine — extensible — though countries will ask which codes to use for MR/bOPV/nOPV2); there is still **no GS1 binding/alias** for `suppliedItem.item[x]` (the ITN example uses free text, §3); and `recordOrigin` is the only mandatory delivery-event extension — `dataLineage` (realtime/reconciled) lives on CarePlan/Task/MeasureReport, not the events, so if an individual event arrives in both streams the consumer distinguishes them via the parent Task.

* * *
## 8. Coverage profiles (`profiles-coverage.fsh`)
_Administrative and independently-measured coverage are distinct lineages of the same conceptual quantity — separately profiled, never merged._ (working doc §4.1; the recurring evidence: **Cuamba, Mozambique — ~99% admin vs ~76% survey**.) Measure definitions are meant to align with what ministries already owe: WHO JAP, ICG M&E minimum dataset, ESPEN treatment-coverage schema, WHO EPI — the `Measure` resources themselves are deferred (§13).

_Proposed for a subsequent round (§17.2 P1 — the biggest coverage rework): coverage is keyed only by data-source today; add_ **_denominator-type_** _(total vs at-risk) and_ **_unit_** _(people vs implementation-units → geographic coverage) axes (B1);_ **_structure_** `sample-design` _into sub-elements and_ **_bind both coverage profiles to_** `Measure` _definitions (B2, closes the §14 Measure gap); and make_ **_RCM — Rapid Convenience Monitoring_** _(a quick,_ **_non-probability_** _in-campaign check at convenient spots — markets, a few houses — looking for finger-mark/card) explicitly_ **_pass/fail with a trigger, not a coverage rate_** _(B4), e.g. "if >10% of children checked are unvaccinated, this area needs mop-up." RCM stays distinct from the probability_ **_cluster survey_** _(the §8.2 example, a valid 76% estimate) and from_ **_LQAS_**_'s accept/reject decision rule — the three_ `ICRIndependentCoverageSourceVS` _codes, all kept separate from_ `administrative`_. See §17.2._
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

> [!info] WHO SMART alignment (§18) WHO defines **45 FHIR** `Measure`**s (**`IMMZIND01–45`**)** — coverage, drop-out, wastage, AEFI, session-completion — each a COUNT-numerator / target-denominator / disaggregation (admin-area, sex, age) template aggregating into HMIS/DHIS2. Proposed: **derive ICR's** `Measure` **definitions from the IMMZ ones where they overlap** (this is the support for §17 B2's "bind coverage to a Measure"), then add the campaign-only ones WHO lacks — **admin-vs-survey, RCM/LQAS, at-risk/epidemiological denominator, geographic coverage**. ICR's denominator-with-provenance and admin-vs-survey split are _richer_ than WHO's "denominator set by Member States". See §18.4.

**Rationale.** The "never merge" rule is enforced _structurally_: the admin profile pins `coverageSource` to the single code `administrative`; the survey profile re-binds the same extension to a value set that _excludes_ `administrative`. A resource can't be both. Admin coverage additionally carries its denominator's provenance (because admin coverage is only as good as its denominator). **Lineage is now required (1..1) on both coverage profiles** (third pass): coverage reports are where the realtime/reconciled distinction has teeth — preliminary in-campaign figures vs final close-out figures must be machine-distinguishable, including preliminary-vs-final survey results. Elsewhere (CarePlan, Task) the flag stays optional with a documented default: **absent ⇒ realtime**.

**What** `dataLineage` **actually means — a worked example (re c80).** The flag marks _which data stream_ a record belongs to, not lineage in the provenance/audit sense: it separates the **live in-field feed** from the **corrected close-out figures**. On campaign night, Kambia's admin-coverage MeasureReport is published with `realtime` — numerator 47,766 from the day's tally sheets, denominator from the planning estimate, score ~99% — and it feeds the live dashboard. Two weeks later, after stock reconciliation and data cleaning (duplicate doses removed, late tallies added), the **final** close-out MeasureReport for the same round carries `reconciled`, and _that_ is the figure exported to the WHO JAP. Same conceptual quantity, two records, distinguished only by this flag — so a "final figures only" query (`dataLineage = reconciled`) cleanly drops the preliminary one. This is exactly why the flag is **1..1 on the coverage profiles** (where the stakes are highest) while staying optional with the `absent ⇒ realtime` default elsewhere.

**The coverage pair as FHIR/JSON — 99% vs 76%.** The two MeasureReports for the **same** Kambia round — the structural "never merge":

```json
{
  "resourceType": "MeasureReport",
  "id": "example-admin-coverage",
  "meta": {
    "profile": [
      "https://fhir.icr.unicef.org/StructureDefinition/ICRAdministrativeCoverage"
    ]
  },
  "status": "complete",
  "type": "summary",
  "measure": "https://fhir.icr.unicef.org/Measure/icr-admin-coverage",
  "reporter": {
    "reference": "Location/example-district"
  },
  "period": {
    "start": "2026-06-15",
    "end": "2026-06-26"
  },
  "group": [
    {
      "measureScore": {
        "value": 0.99
      },
      "population": [
        {
          "code": {
            "coding": [
              {
                "system": "http://terminology.hl7.org/CodeSystem/measure-population",
                "code": "numerator"
              }
            ]
          },
          "count": 47766
        },
        {
          "code": {
            "coding": [
              {
                "system": "http://terminology.hl7.org/CodeSystem/measure-population",
                "code": "denominator"
              }
            ]
          },
          "count": 48250
        }
      ]
    }
  ],
  "extension": [
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/coverage-source",
      "valueCode": "administrative"
    },
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/denominator-source",
      "valueCodeableConcept": {
        "coding": [
          {
            "system": "https://fhir.icr.unicef.org/CodeSystem/icr-denominator-source",
            "code": "worldpop"
          }
        ]
      }
    },
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/realtime-vs-reconciled",
      "valueCode": "reconciled"
    }
  ]
}
```

```json
{
  "resourceType": "MeasureReport",
  "id": "example-survey-coverage",
  "meta": {
    "profile": [
      "https://fhir.icr.unicef.org/StructureDefinition/ICRSurveyCoverage"
    ]
  },
  "status": "complete",
  "type": "summary",
  "measure": "https://fhir.icr.unicef.org/Measure/icr-survey-coverage",
  "reporter": {
    "reference": "Location/example-district"
  },
  "period": {
    "start": "2026-07-06",
    "end": "2026-07-12"
  },
  "group": [
    {
      "measureScore": {
        "value": 0.76
      }
    }
  ],
  "extension": [
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/coverage-source",
      "valueCode": "survey"
    },
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/sample-design",
      "valueString": "WHO 30×10 cluster survey, post-campaign"
    },
    {
      "url": "https://fhir.icr.unicef.org/StructureDefinition/realtime-vs-reconciled",
      "valueCode": "reconciled"
    }
  ]
}
```

Annotated: the same conceptual quantity — coverage of the Kambia round — reported **23 points apart** (mirroring Cuamba's 99-vs-76). They can never be merged because `coverage-source` is structurally pinned: `administrative` is **fixed** on the first profile, and the survey profile binds the same extension to a value set that _excludes_ `administrative`. The admin report shows its `numerator`/`denominator` populations (47,766 / 48,250 = 99% against WorldPop — against the enumerated 51,800 it would read 92%, §6.2); the survey carries its `sample-design` _instead of_ a denominator (its denominator IS the sample). `realtime-vs-reconciled` is **1..1** on both — these are final close-out figures (`reconciled`), machine-distinguishable from preliminary in-campaign numbers.⁠

**Two design notes.** MeasureReport-vs-Observation for coverage is a flagged open question; **MeasureReport won for v0.1** because its numerator/denominator `group.population` structure matches coverage natively. And neither profile yet constrains `measure` (the canonical Measure being reported) — unavoidable until the Measure definitions ship (§14), so v0.1 coverage reports aren't yet comparable by measure identity (the examples use placeholder canonicals under the ICR namespace).

* * *
## 9. Extensions (`extensions.fsh`) — all 23
_FHIR has no native campaign semantics; these extensions carry them on profiled core resources._ (working doc §7)

_Proposed for a subsequent round (§17): the §17 additions imply_ **_new extensions_** _here —_ `activity-type`_,_ `coverage-target`_,_ `dosing-regimen`_,_ `stockpile-source`_,_ `wastage`_/vial-accountability,_ `aefi-causal-type`_, and an at-risk-denominator flag. A_ **_structured (complex)_** `sample-design` _would replace today's free-text string — but per review this is_ **_deferred: v1 keeps the free-text string_** _(enough to record the method narratively). Structuring it (method, #clusters, design-effect/ICC, sample size, evidence-source) makes survey quality machine-readable, but it's heavy and_ **_coupled to the Measure-binding work_** _(§17.2 B2) — both are "make coverage computable," so they ship together, not piecemeal. See §17._

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
| ChildrenPresent (`children-present`) → now **EligiblePresent (**`eligible-present`**)** | unsignedInt |
| ChildrenAbsent (`children-absent`) → now **EligibleAbsent (**`eligible-absent`**)** | unsignedInt |
| MissedReason (`missed-reason`) | CodeableConcept, **extensible** → ICRMissedReasonVS |
| NoncomplianceReason (`noncompliance-reason`) | CodeableConcept, **extensible** → ICRNoncomplianceReasonVS |
| FingerMarked (`finger-marked`) | boolean — "the in-field 'already covered' flag" |

**Population & denominator provenance**

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
| OverlaysAdminUnit (`overlays-admin-unit`) | Location | Reference(ICRLocation) — links operational geography to the admin unit(s) it overlays; **1..\* required on supervisory/operational-area types** (invariant `icr-loc-overlays`, v0.7.0) |
| LocationAncestors (`location-ancestors`) — _proposed v0.7.0 (c89), not yet in `extensions.fsh`_ | Location | complex: per-level `adm0…adm3+` code + Reference(ICRLocation); **server-maintained** denormalized breadcrumb of the `partOf` chain, for fast hierarchy filtering |
| RecordOrigin (`record-origin`) | Immunization, MedicationAdministration, SupplyDelivery | code, **required** → ICRRecordOriginVS |
| DirectlyObservedConsumption (`directly-observed-consumption`) | MedicationAdministration | boolean |
| CoverageSource (`coverage-source`) | MeasureReport | code, **required** → ICRCoverageSourceVS |
| SampleDesign (`sample-design`) | MeasureReport | string — survey/LQAS/RCM method & sample-design detail |

**Rationale highlights.** The binding-strength pattern is deliberate: **structural discriminators** (delivery strategy, record origin, lineage, coverage source) are `required` — analytics must be able to branch on them; **field-reality vocabularies** (missed/noncompliance reasons, denominator sources) are `extensible` — countries add local codes, mapped back via ConceptMap. Code vs CodeableConcept also tracks this: pure discriminators use bare `code`; concepts countries extend use CodeableConcept (text + local codings survive).

**Design note.** `LocationBoundaryGeoJson`: an eventual move to R5 (or the cross-version extension) migrates stored attachments trivially, but the **URL** changes — the alignment path is parked as working doc §10 q6 and kept on the v1.0 checklist.

* * *
## 10. Terminology (`codesystems.fsh`, `valuesets.fsh`)
Pattern (working doc §8): **ICR defines only campaign semantics**; product codes come from CVX/ATC/GS1; local codes join via ConceptMap (deferred). All 12 code systems are `caseSensitive` and non-experimental. (Defining your own CodeSystems/ValueSets is **standard IG practice** — mint a CS only for genuinely new semantics you own, and reuse a standard system for anything that already exists: vaccines → CVX, drugs → ATC, commodities → GS1, geography → ISO 3166. ICR's ~12 small CodeSystems are all campaign concepts FHIR lacks — `delivery-strategy`, `record-origin`, `task-origin`, `denominator-source`, `coverage-source`, … — none duplicating a standard system; WHO's own SMART Immunizations IG does the same with `IMMZ.Z`/`IMMZ.*` codes, §18.4.)

_Proposed for a subsequent round (§17): new/extended terminology — an_ `activity-type` _/_ `sia-type` _CodeSystem (A1), an_ `aefi-causal-type` _VS (C1), reconciling_ `missed-reason` _/_ `noncompliance-reason` _with the WHO RCM field lists (C3 — add_ `unaware-campaign`_,_ `post-distance`_,_ `post-stockout`_,_ `not-decision-maker`_…, and split out non-missed dispositions), and_ **_location-type / denominator-source_** _code additions (§17.4). See §17._

| CodeSystem | Codes | FR? | Bound (strength) |
| --- | --- | --- | --- |
| ICRCampaignTypeCS | `vaccination-sia`, `mda`, `itn-distribution`, `irs`, `vitamin-a`, `integrated` (6) | ✔   | Protocol.type, Campaign.category (**required**) |
| ICRDeliveryStrategyCS | `fixed-post`, `temporary-post`, `mobile`, `school`, `house-to-house`, `community-directed` (6) | ✔   | delivery-strategy ext (**required**) |
| ICRRecordOriginCS | `campaign`, `routine` (2) | ✔   | record-origin ext (**required**) |
| ICRGroupKindCS | `household`, `community` + `school-cohort` (3) | ✔   | ICRDeliveryUnit.code (**required**) |
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

> [!info] WHO SMART alignment (§18) WHO owns its terminology — `IMMZ.Z` vaccine codes, `IMMZ.<letter>.DE<n>` data elements (`IMMZ.C/D/I`), ConceptMaps out to **ICD-11 MMS / LOINC / SNOMED CT / ISO 3166-1**. Proposed: keep ICR's CVX/ATC/GS1 backbone but add **ConceptMaps ICR ↔** `IMMZ.*` — the concrete "reuse the DAK data elements where they align" action (c133) and the WHO-facing half of the §14 ConceptMap gap. ICR's `record-origin` / `delivery-strategy` / `denominator-source` / coverage-source etc. have **no WHO equivalent** and stay ICR-owned. Mirror WHO's _data-dictionary-row → stable artifact id + paired ValueSet_ discipline so a Mappings page can line them up 1:1. See §18.4–18.5.

**Three notes carried forward.** (1) The required-bound `code`-typed extensions have **no** `other` **escape** — confirm the closed sets (campaign/routine; realtime/reconciled; the four coverage sources) really are exhaustive (e.g. is _post-campaign administrative correction_ a third lineage? is _desk review_ a coverage source?). (2) **Campaign-type is deliberately disease-agnostic.** `campaign-type = vaccination-sia` does not encode which disease — the disease lives in `CarePlan.addresses` (the Condition) and the vaccine code (CVX). Worked example, two campaigns with the _same_ campaign-type: a **Measles–Rubella SIA** (`vaccination-sia`; `addresses` → "Measles and rubella"; product → CVX 05) and a **Polio SIA** (the _same_ `vaccination-sia`; `addresses` → "Poliomyelitis"; product → bOPV CVX) — you tell them apart by `addresses` + vaccine code, not by `campaign-type`. Disease-specific codes (`measles-sia`, `polio-sia`, `ocv`…) were rejected as duplicating `addresses`/product and exploding the code list (§17.6). The one thing to confirm with partners is acceptance — the **polio programme** is built around "polio campaigns" as a first-class thing, so check they're fine querying `campaign-type = vaccination-sia AND addresses = polio` (§15 #4). (3) The new **FR designations** were drafted in-pass — have a francophone public-health reviewer check them (esp. "Monitorage rapide de convenance" for RCM), and state the localization policy (which languages, where).

* * *
## 11. Examples (`examples.fsh`) — the scenario walkthrough
One coherent story: a **Sierra Leone measles–rubella SIA, 2026** — a national umbrella campaign with the **Kambia District June round** as `partOf` child — exercising fixed-post (Type A) and house-to-house mop-up (Type B) tasks, the divergent admin-vs-survey coverage pair, plus a standalone MDA event (Type C) and an ITN delivery. Second pass added the country level, a community delivery unit, and a supervisory area. Third pass added the activity gallery (albendazole / ITN / IRS) and the competing enumeration denominator.

**Where this scenario lives (re c93):** every instance below is defined in `ig/input/fsh/examples.fsh` and enumerated in the §11 table (rows #1–#26) — that table _is_ the index. The scenario is an **illustrative composite**, not a transcription of a specific published Sierra Leone SIA: the figures (48,250; 99% vs 76%; etc.) are constructed to exercise the profiles, with the 99-vs-76 divergence modelled on the documented Cuamba, Mozambique case (§8). To ground it in a real campaign dataset, supply one and the figures can be re-aligned.

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
| 10 | `example-target-population` | ICRTargetPopulation | 48,250 children 9m–14y, Kambia; source **WorldPop**, estimateDate 2026-01-15, isPlanningDenominator true; **geography characteristic → district** |
| 11 | `example-target-population-enumerated` | ICRTargetPopulation | **NEW** — 51,800 children 9m–14y, Kambia; source **microcensus/enumeration**, estimateDate 2026-03-02, isPlanningDenominator **false**; geography → district — the **competing estimate** for the same geography (§6.2 walk-through) |
| 12 | `example-target-population-national` | ICRTargetPopulation | 2,150,000 children 9m–14y, national; source **census-projection**, estimateDate 2025-11-30 — a *different* denominator source than the district's WorldPop; **geography characteristic → country** |
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
| 25 | `example-admin-coverage` | ICRAdministrativeCoverage | numerator 47,766 / denominator 48,250, **measureScore 99%**; denominatorSource WorldPop; dataLineage reconciled; coverageSource administrative |
| 26 | `example-survey-coverage` | ICRSurveyCoverage | post-campaign (Jul 6–12), **measureScore 76%**; coverageSource survey; sampleDesign "WHO 30×10 cluster survey…"; **dataLineage reconciled** (now required) — the same quantity as #25, **23 points apart**, mirroring the canonical Cuamba divergence |

What the scenario _demonstrates_: the full Location chain with GERS at every level, country → dwelling, plus a delivery site; **operational geography overlaying (not inside) the admin hierarchy**; the generalized delivery-unit pattern at **both scales** (household and community); **competing denominators for the same geography** (WorldPop vs enumeration, 7% apart, one planning flag) alongside the cross-level contrast (district WorldPop vs national census-projection), all computably geography-scoped; the **activity gallery** across campaign types; protocol→activity→campaign wiring; the umbrella/round `partOf` lifecycle (`plan` umbrella, `order` round); **both Task shapes** of the focus polymorphism _and_ **both task origins** (pre-planned session, field-registered mop-up); a Type-B trail end-to-end down to the dose; both non-vaccine delivery types; and the never-merge rule made visible by a 99-vs-76 coverage pair on the same round.

**Scenario notes for a future pass.** The albendazole event references the MR-scenario child for an MDA that has **no campaign/protocol/task instances** — the community delivery unit (#9) and albendazole activity (#14) exist, but the Type-C thread still dangles (no CDTI protocol, no community-focused Task wiring #9/#14 → #23); worth completing. GERS values are placeholder-format (`…-example`) — confirm real GERS ID syntax before pilots so examples validate against the eventual identifier pattern. And the coverage examples point at **placeholder Measure canonicals** (`…/Measure/icr-admin-coverage`) that don't resolve — expected until the Measure definitions ship (§14), though the IG Publisher will likely warn.

* * *
## 12. Narrative pages (`index.md`, `background.md`)
- `index.md` — the pitch (campaigns re-collect the same data; ICR makes collection compound), the one-paragraph architecture (mirrors §4 above), status (v0.1, Phase 1, to be revised against real datasets and FHIR community review), and the deferred-items list.
  
- `background.md` — the Type A/B/C campaign-typology table; the **twelve design decisions** (numbered, with rejected alternatives noted for the keystone choice — #3 now covers pre-planned vs field-registered tasks, #7 the generalized household/community delivery unit); two second-pass sections: **"Campaign work vs routine encounters"** (Task-based campaign delivery, Encounter retained for routine, `record-origin` as the discriminator — working-doc comment c71) and **"Operational vs administrative geography"** (the location-type + overlays-admin-unit mechanism); a third-pass section **"Location identity lifecycle: GERS enrichment"** (create unmatched → async conflation → backfill GERS with versioning + Provenance — your c16) and the per-child follow-up exception folded into design decision #3; the **open design questions** taken to the FHIR community (Task granularity, aggregate vs individual records, deep partOf hierarchies, MeasureReport vs Observation, denominator representation, GeoJSON on R4, Task focus typing, Bulk Data access patterns, record-linkage); and the WHO SMART Guidelines relationship (reuse DAK elements, align conventions, same toolchain).
  

These two pages are honest about maturity — the open questions are printed in the IG itself rather than hidden in the working doc. Design decisions #5, #11, #12 (three lineages; provenance on everything ingested; ViewDefinitions in the IG) are stated in narrative but only partially realized in v0.1 artifacts — see §13.

> [!info] WHO SMART alignment (§18 — the biggest structural gap) ICR ships only these two pages. §18.2 proposes restructuring them into the full WHO SMART-Guidelines IG **skeleton**: L1 **Home** (Summary/Changes/Dependencies/References/Country-adaptation), L2 **Business Requirements** (campaign personas, business processes mapped onto WHO's `IMMZ.A–I`, a Data Dictionary, Decision-support, Indicators, Functional/Non-functional Requirements), **Data Models & Exchange** (System Actors, Transactions, Codings, Measures), **Deployment** (Security/Testing/Test-Data/Reference-Impl/Trust/Downloads), and **Indices** (Artifact Index, **Mappings**, optionally a DAK-API surface) — filling campaign content and leaving titled stubs where pending, exactly as WHO does. See §18.2.

* * *
## 13. Cross-cutting design invariants (the things to hold the review against)
1. **Delivery strategy is first-class and coded** — required binding; mandatory on Protocol (1..*) and Task (1..1), optional on Activity and site Locations. _The_ discriminator, because strategy determines which data elements exist.
  
2. **Record origin is mandatory on every delivery event** (1..1, required binding) — the firewall between SIA doses and routine coverage.
  
3. **Three lineages, never merged** — planned (CarePlan/Group), delivered (Task/events → admin coverage), independently measured (survey coverage). Enforced by the fixed `#administrative` code on one profile and the exclusion VS on the other.
  
4. **Denominator provenance is recommended, not required** — source + date are `0..1 MS` on ICRTargetPopulation (the population is often unknown up front, so they can't be mandatory), but populated wherever the number is known; competing estimates coexist; one planning flag.
  
5. **Geospatial identity is multi-system with GERS preferred** — open identifier slicing on Location; the Group+Location delivery-unit pattern keys households and communities to GERS IDs; operational geography overlays the admin hierarchy rather than pretending to be it.
  
6. **Real-time vs reconciled is one structure, filtered by lineage** — hardened in the third pass: documented default (absent ⇒ realtime) and 1..1 on both coverage profiles, where the distinction has teeth.
  
7. **Task origin is first-class and coded** (second pass) — pre-planned vs field-registered, 1..1 required; discovery-mode field registration is a supported workflow, and its counts are a microplan-completeness measurement.
  
8. **One Task per visit; person detail lives in the delivery events** — a doorstep or site-session visit is a single Task; each person served gets their own Immunization/MedicationAdministration off `Task.output`. A person-focused Task (`focus = Patient`) is reserved **solely** for chasing a specific missed or zero-dose child — never routine per-child capture, which would multiply Task volume ~5× for nothing the delivery events don't already carry.
  

* * *
## 14. Known gaps (acknowledged, deferred to later drafts)
Stated in the README/index — i.e., absent **by design**, not oversight:

- **SQL-on-FHIR** `ViewDefinition`**s** (design decision #12 — "the analytics layer is as portable as the data model")
  
- `ConceptMap` **scaffolds** for country/local code localization (the mechanism §10's extensible bindings rely on)
  
- `Consent` **guidance** (household/person data governance)
  
- `Measure` **definitions** aligned to WHO JAP / ICG / ESPEN / WHO EPI reporting minimums (what MeasureReports will point at)
  
- **Data conformance testing** against real campaign datasets; **FHIR community review** (chat.fhir.org, WG calls, Connectathons)
  
- No `CapabilityStatement`, search-parameter, or Bulk-Data/cohort-export guidance yet (the access-pattern open question)
  

These are the gaps ICR already _knew_ about. **§17** adds a second, larger class: gaps surfaced by the **field-evidence synthesis** — programme-semantics axes, a coverage-model overhaul, AEFI/wastage/supervision, and more — each flagged there as a _proposed_ addition for a subsequent IG round (none committed yet).

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
  

**✅ Addressed in the fourth-pass revision (v0.7.0 — this doc only, from comments c80–c95; IG/FSH edits flagged in-thread, not yet committed)**

- ~~Publisher attribution~~ — **UNICEF** as publisher of record, Ona + Crosscut via `contact` (c94, §2).
  
- ~~Plan per sub-area / planned-vs-executed~~ — explained: each sub-area is its own round CarePlan, plan→order lifecycle, `planningDenominator` is the retained planned figure, history/Provenance for the rest; **no separate snapshot** per your c112 (§5.2).
  
- ~~What~~ `dataLineage` ~~means~~ — realtime-vs-reconciled worked example added (c80, §8).
  
- ~~Patient vs RelatedPerson/Person~~ — folded into §6.1; q2 wording corrected (c83).
  
- ~~GRID3 → WorldPop~~ — relabelled across the example denominators (c84, §6.2/§8/§11).
  
- ~~Location hierarchy diagram~~ — two-hierarchy mermaid added (c85, §6.3).
  
- ~~Admin-level identifiers~~ — `national` + `iso` slices, `icr-loc-admin-id` invariant (≥1 id at admin-unit level) (c88, §3/§6.3).
  
- ~~Operational-area overlays~~ — `icr-loc-overlays` invariant (1..* on supervisory/operational-area) (c90, §6.3).
  
- ~~Deep-~~`partOf` ~~performance~~ — proposed server-maintained `location-ancestors` breadcrumb extension (c89, §6.3/§9).
  
- ~~MDA example~~ — inline albendazole MedicationAdministration JSON added to §7.2 (c91).
  
- ~~Scenario provenance~~ — §11 notes it's an illustrative composite + points at `examples.fsh` (c93).
  
- _Still open (explained, awaiting your call):_ Overture release-version field (c86, pending Overture); `partOf` strict-typing vs widening (c87).
  

**✅ Addressed in the fifth-pass revision (v0.12.0 — this doc only, from comments c131–c159; per-section question/proposed callouts retired)**

- ~~CareTeam / supervisor missing~~ — stated in §4 (an `ICRCareTeam` profile with vaccinator/CDD + **supervisor** roles; supervisor is both a delivery actor and typically the reporter; folded with §17.3) and CareTeam added to the §4 diagram (c131/c136).
  
- `activity-type` ~~vs~~ `campaign-type` — described as **orthogonal axes** in the §5.1 main body (c137/c154); CQL/age-band eligibility explicitly deferred (c155).
  
- ~~Task~~ `focus`~~/~~`for` — `Task.for` now carries the **target** (household/community/patient) and `Task.focus` is reserved for **workflow lineage** (§5.4, c156); the age/sex **disaggregation pattern** is documented (c157).
  
- `group-location` ~~naming~~ — kept (it generalizes household/community/school — can't revert to `household-location`); explained at the §6.1 example (c158).
  
- ~~Denominator provenance mandatory~~ — **relaxed to** `0..1 MS` **(recommended, not required)** since the population is often unknown up front (§6.2, §13 #4, c159).
  
- ~~Geography metadata in the IG~~ — accessibility/travel-time, georegistry-match-status, endemicity, and the TAS gate **rejected as out-of-scope** (link externally by location ID); §17.4 marked accordingly (§6.3, c138/c139).
  
- ~~AEFI / aggregate-vs-individual~~ — AEFI spelled out + plan to **reuse** `IMMZ.AdverseEvent` (§7, §18.3); the aggregate-vs-individual rule stated (§7.3, c140/c141).
  
- ~~RCM /~~ `sample-design` ~~/ CodeSystem / disease-agnostic typing~~ — all answered in prose: RCM defined inline (§8), structured `sample-design` confirmed **deferred** (§9), minting CodeSystems confirmed standard practice (§10), disease-agnostic campaign-type worked example (§10) (c142–c145).
  

**Decisions needed (open — for Matt / project)**

1. Canonical URL ownership + dependency declaration + package-id confirmed with UNICEF (§2 q1/q3/q4). **Publisher attribution is now decided — UNICEF (c94, v0.7.0).**
  
2. GERS/P-code identifier system URIs — BERG-46 (engage Overture); plus a concrete slot for the **Overture release version** (§6.3) — boundary-alignment work tracked as Linear **BERG-45**.
  
3. Aggregate-vs-individual representation for Type-A tally campaigns — the site-session example uses `Task.output` counts; document the `Task.output` / MeasureReport split as the official pattern (§7).
  
4. Closed required-bound code sets exhaustive? `taskOrigin` for historical imports (`unknown` code? §5.4 q5)? Disease-agnostic campaign typing OK with polio program? (§9/§10).
  
5. FR translations reviewed by a francophone public-health reviewer — now also group-kind (incl. school-cohort) and task-origin (§10).
  
6. Geography characteristic 0..1 → 1..1 once pilots confirm every estimate has a Location (§6.2; the resolved geography-linkage question is archived to §16). _(The_ `overlays-admin-unit`_-required question is now resolved — enforced via the_ `icr-loc-overlays` _invariant, v0.7.0.)_
  
7. Vector control / entomological surveillance — in ICR's future scope or not (§5.3 boundary note)?
  

7-bis. **Supervisor-as-reporter** — when the `ICRCareTeam` profile is drafted, decide whether it's an explicit invariant (campaign MeasureReports SHALL name a `reporter`) or stays MS for v1 (§4).

**Hold for community review (already flagged in the IG)** 8. Task granularity at scale; deep partOf performance; MeasureReport vs Observation; GeoJSON on R4; record-linkage pattern; Bulk Data access (§12 of background page).

**🔬 Proposed from the field-evidence synthesis (v0.9.0 — for a subsequent IG round)** 9. A prioritized P1/P2/P3 change-list of research-validated additions — programme-semantics quartet, coverage-model overhaul, AEFI/wastage/supervision, geography refinements, and the surveillance "reference-don't-model" scope line — is captured in **§17**. None is committed to `ig/`; §17 is the working checklist for the next IG-editing pass.

* * *
## 16. Closed questions — archive
_Questions that were resolved/addressed, grouped by section, with how each was closed. This archive originally drained the per-section "[!warning] Questions" blocks; those blocks were_ **_fully retired in v0.12.0_** _— their remaining open items folded into the section prose or consolidated in §15 — so this is now the standing by-section record of what was settled. The pass-by-pass §15 checklist remains the changelog view._

**§5.1 — ICRCampaignProtocol**

- ✅ `action.definition[x]` was unenforced → now constrained to `Canonical(ICRCampaignActivity)`, so the protocol→activity wiring is machine-enforced (first pass).
  

**§5.2 — ICRCampaign**

- ✅ `dataLineage` was the only campaign extension not marked MS → now **MS** on ICRCampaign (v0.4.0); the §5.2 extensions row reflects it.
  

**§5.3 — ICRCampaignActivity**

- ✅ No real activity example → `example-mcv-activity` exists and the protocol wires it via `action.definitionCanonical` (first pass); the four-activity gallery was added (v0.4.0).
  

**§5.4 — ICRCampaignTask**

- ✅ `focus` typing → narrowed to `ICRDeliveryUnit | ICRLocation` (second pass), then widened to also admit `Patient` for person-targeted follow-up tasks only (third pass).
  

**§6.1 — ICRDeliveryUnit**

- ✅ `member.entity` = Patient → confirmed correct: it excludes Practitioner/Device, and R4 `Group.member` never allowed RelatedPerson (R5 only). Full explanation now in the §6.1 rationale (v0.7.0).
  
- ✅ `school-cohort` added as the third group kind, with FR designation (third pass).
  
- ✅ `groupLocation` (née `householdLocation`) targets `Reference(ICRLocation)` (first pass); household/community split → one profile + required coded kind (second pass).
  

**§6.2 — ICRTargetPopulation**

- ✅ Geography linkage → profiled `characteristic[geography]` slice → `Reference(ICRLocation)`, exercised by all three example denominators (second pass). Residual (slice 0..1 → 1..1 once pilots confirm) is tracked in §15 decision #6.
  

**§6.3 — ICRLocation**

- ✅ `Location.type` unbound → bound **extensible** to ICRLocationTypeVS (second pass). _Watch item:_ a strict base-binding validator may flag codes like `supervisory-area` — worth a Connectathon sanity check.
  
- ✅ `overlays-admin-unit` required on operational-area types → now enforced by the `icr-loc-overlays` invariant (1..* when `type ∈ {supervisory-area, operational-area}`) (v0.7.0).
  

**§8 — Coverage**

- ✅ Survey preliminary-vs-final lineage → `ICRSurveyCoverage.dataLineage` is now **1..1** (third pass); it still has no `denominatorSource` (correct — a survey's denominator is its sample design).
  
- ✅ Sample-design had no home → `SampleDesign` extension added, 0..1 MS on ICRSurveyCoverage (first pass); both coverage profiles now have examples.
  

**§9 — Extensions**

- ✅ `RealtimeVsReconciled` default + enforcement → `absent ⇒ realtime` documented and the flag **1..1 on both coverage profiles** (third pass).
  
- ✅ `children-present/absent` → renamed `eligible-present`/`eligible-absent` before the names ossified (third pass).
  
- ✅ Reference-target tightening (`TargetGeography`/`PlanningDenominator`/`GroupLocation`), `DeliveryStrategy` wired onto ICRLocation, `SampleDesign` (first pass); `TaskOrigin`, `OverlaysAdminUnit` added (second pass).
  

**§10 — Terminology**

- ✅ FR designations now cover all five required-binding systems and the file comment matches; the MDA VS description matches its content (first pass). _(Still open, kept in §10: francophone reviewer check + localization policy.)_
  

* * *
## 17. Research-validated proposed additions (field-evidence synthesis)
> [!note] Status — _proposed_, not committed Everything in §17 is a **proposed** change for a **subsequent IG round** — none of it is in `ig/` and no FSH/profile artifact changes in this pass. It rolls up `_SYNTHESIS-research-vs-ICR-IG.md`, which compared **eight** global-health source analyses against ICR IG v0.1.0 / this explainer. Proposed code names (CodeSystems, extensions, value sets) follow ICR's existing conventions (kebab-case, ICR-prefixed) but are **placeholders to be finalized when drafted** — confirm exact CodeSystem URLs against `ig/input/fsh/` before authoring. Source key for the matrix: **S**=WHO SIA-2016, **R**=WHO RED microplanning, **M**=WHO-AFRO Measles, **CS**=WHO Cluster-Survey Manual 2018, **O**=GTFCC OCV, **N**=NTD-MDA/PC, **Y**=WHO EYE/Yellow-Fever, **G**=Geo-enabled microplanning.

**The convergence is the signal.** Eight documents — across routine RI, polio/measles/YF/OCV vaccine SIAs, NTD drug campaigns, survey methodology, and GIS microplanning — converge on the same conclusions, and **no source contradicts the IG's spine**. Two themes dominate the proposed additions: (1) **programme semantics** is too thin — four coded axes show up as first-class in _every_ campaign type yet are absent from the IG; (2) the **coverage model** needs the biggest rework — it is keyed only by data-source and lacks the denominator-type and unit axes the evidence demands.
### 17.1 Validated — do **not** change (the spine holds)
The field evidence strongly endorses these; they are listed so the next round knows what is _settled_, not up for redesign (cross-ref §13):

- Plan→order lifecycle; one-Task-per-visit with per-person delivery events; the `record-origin` campaign/routine firewall; denominator-with-provenance; the three never-merged coverage lineages; realtime-vs-reconciled; coded delivery strategy.
  
- **Operational geography overlaying the admin hierarchy** (`overlays-admin-unit` / `supervisory-area`) — the **standout win**, validated by every GIS/operational source.
  
- GERS-preferred multi-system identity; configurable age bands (all-age PMVC works); `campaign-type = mda` + `community-directed` + `ICRMedicationAdministration` (ATC, subject = DeliveryUnit, directlyObserved) for NTD MDA; integrated multi-intervention on a shared denominator.
  
- **GeoJSON-on-R4 is effectively resolved already** — the IG _ships_ `location-boundary-geojson`; only `background.md`'s "open question" wording lags (see 17.4).
  
### 17.2 P1 — strongly convergent / load-bearing (do first)
**A. Programme-semantics quartet** — four small coded axes the IG lacks but every campaign type treats as first-class:

| # | Proposed addition | Where it lands | Sources |
|---|---|---|---|
| A1 | **`activity-type` / `sia-type`** CodeSystem + extension — `routine`, `pmvc`, `catch-up`, `follow-up`, `mop-up`, `reactive`/`outbreak-response`, `rolling-phased`. **Orthogonal** to `campaign-type` (intervention) and `record-origin` (campaign-vs-routine). | new CodeSystem + extension on ICRCampaignProtocol / ICRCampaign | S, M, Y (EYE's canonical 4-type taxonomy) |
| A2 | **`coverage-target`** element — store the *programme-defined threshold* (≥95% SIA; ≥65% LF epidemiological; EYE 50/60/80%), not just achieved coverage. | element/extension on ICRCampaignProtocol.`goal` / ICRCampaign | Y, N, O |
| A3 | **`stockpile-source`** axis — ICG / national / Gavi, with allocation/lot + request-to-delivery interval; one value set serves OCV and YF (same ICG mechanism). | extension on ICRSupplyDelivery | O, Y |
| A4 | **`dosing-regimen`** — single-dose-lifelong / multi-dose / fractional-dose; needed to define "fully immunized." | extension on ICRCampaignActivity / ICRImmunizationEvent | O, Y |

**B. Coverage-model overhaul** — the biggest analytic theme:

| # | Proposed addition | Where it lands | Sources |
|---|---|---|---|
| B1 | **Separate the three coverage axes.** Today coverage is keyed only by *data-source*. Add **denominator-type** (total-population vs at-risk/eligible → NTD programme-vs-epidemiological coverage) and **unit** (people vs implementation-units → a geographic-coverage Measure). Requires an **at-risk denominator** on ICRTargetPopulation. | new axes/extensions on both coverage profiles + ICRTargetPopulation | N decisive; O/Y/M corroborate |
| B2 | **Structure `sample-design`** (today a single free-text string, §8.2) into sub-elements — method, PSU/EA, #clusters, design-effect/ICC, sample size, weighting, evidence-source (card/recall/register), crude-vs-valid, CI/precision — **and bind `ICRSurveyCoverage` (and `ICRAdministrativeCoverage`) to `Measure` definitions** aligned to VCQI/Annex L. Closes the IG's own acknowledged "Measure definitions" gap (§14). | rework `sample-design` extension → complex; new `Measure` resources | CS |
| B3 | **Multi-dose "fully-immunized" measure + round1↔round2 linkage** for OCV/multi-round campaigns. | new Measure + round-linkage on ICRCampaign | O, Y |
| B4 | **Make RCM semantics explicit** — pass/fail + trigger thresholds, **not** a coverage rate, **not** a probability survey; LQAS needs its decision-rule documented. | narrative + profile note on ICRSurveyCoverage (`rcm`/`lqas`) | S, M, CS, R |

**C. Vaccine-cross-cutting operational data** (all three vaccine guides):

| #   | Proposed addition | Where it lands | Sources |
| --- | --- | --- | --- |
| C1  | **AEFI** profile + `aefi-causal-type` value set (5 WHO/CIOMS categories + serious criteria). | new profile + CodeSystem/VS | S, R, M, ~Y |
| C2  | **Wastage / vial-accountability** axis (WMF; received/opened/not-usable/returned; VVM) — reusable for vaccines, drugs, ITNs. | extension on ICRSupplyDelivery | S, R, M |
| C3  | **Reconcile** `missed-reason` **/** `noncompliance-reason` with the WHO RCM field lists — add `unaware-campaign`, `post-distance`, `post-stockout`, `not-decision-maker`, `unknown-declined`; split out non-missed dispositions (`already-vaccinated`, `plan-to-go-later`); decide one home for `sick`. | extend ICRMissedReasonCS / ICRNoncomplianceReasonCS (§10) | S, R, ~M, ~N |
### 17.3 P2 — convergent, more design work
- `stockpile-source`**,** `dosing-regimen` (also P1 above as A3/A4), `campaign-trigger` (reactive/preventive/outbreak), `campaign-cost` (cost-per-FIP/treated person, CholTool-aligned). _(O, Y; M ~; S/R ~ for cost.)_
  
- **Campaign-phase / readiness** lifecycle axis + a **readiness MeasureReport**. _(S, M; R ~.)_
  
- **Defaulter / dropout / zero-dose** disposition + a **dropout Measure** + zero-dose hand-off-to-routine. _(R, M; S/N ~.)_
  
- **Supervision / QA** profile; **social-mobilization / demand** axis; **population-vulnerability / equity** taxonomy (characteristic). _(S, R, M; N/G ~ for equity.)_ **Note (c131/c136):** the supervision/QA piece overlaps the open **ICRCareTeam / supervisor** gap flagged at §4 — the supervisor is a key delivery actor and often the reporter; fold the two together when drafting.
  
- `outreach` **delivery-strategy** (distinct from mobile/temporary-post); **CDD / community-distributor performer role**; a **Team / CareTeam + microplan-resource** profile (every geo/microplanning source models team-areas + workload; the IG has none — ties to the §4 CareTeam gap). _(R, N, G.)_
  
- **Survey evidence-source + crude-vs-valid coverage** (card/recall/register) — overlaps B2. _(CS.)_
  
### 17.4 P3 — narrower or partly routine-only
- **Geography refinements (G):** **adopt the already-shipped** `location-boundary-geojson` **extension as canonical and remove GeoJSON from "open question" status** in `background.md` (cheap; the extension already exists — §9); add a **population-estimation-method + source-raster version/date** on ICRTargetPopulation (two `worldpop` estimates are currently indistinguishable — relates to the §6.2 competing-denominator model and the §6.3 Overture-release-version thread c86); add a `structure`**/footprint** location-type (the one possible keeper). **Rejected — out of IG scope (c138/c139):** an **accessibility/travel-time** attribute (derived and volatile) and a **georegistry-match-status** value set (redundant — the presence/absence of a GERS identifier already conveys match state); these attach to a Location externally by ID, not in the core IG.
  
- **Cold-chain / logistics / stock-readiness** axis beyond SupplyDelivery. _(R, M; S/O ~.)_
  
- **NTD specifics (N):** **eligibility-exclusion reasons + dose-pole/height dosing** as structured data. **Rejected — out of IG scope (c139):** **endemicity status + TAS/impact-survey gate** on ICRLocation — NTD-programme state on its own cadence, held in a programme/surveillance dataset linked by location ID (§17.6 "reference, don't model").
  
- **Access-vs-utilization** problem-category typology _(R)_; **location-type / denominator-source code additions** — transit-point, health-camp, idp-camp; head-count, campaign-results, line-list-household _(S, R; M/N/G ~)_.
  
### 17.5 Convergence matrix (recommendation × document)
✓ = the document independently flags it; ~ = touched/implied; blank = out of that document's scope.

| Proposed IG addition | S   | R   | M   | CS  | O   | N   | Y   | G   | Priority |
| --- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | --- |
| Activity/SIA-type axis (A1) | ✓   | ~   | ✓   |     | ~   | ~   | ✓   |     | **P1** |
| Coverage-target as data (A2) |     |     | ~   | ~   | ✓   | ✓   | ✓   |     | **P1** |
| Coverage model: denominator-type + unit axes (B1) |     |     |     | ~   | ~   | ✓   | ~   |     | **P1** |
| Structured `sample-design` + bind coverage to a `Measure` (B2) | ~   |     | ~   | ✓   | ~   | ~   |     |     | **P1** |
| Multi-dose "fully-immunized" measure + round linkage (B3) |     |     |     | ~   | ✓   |     | ~   |     | **P1** |
| RCM = pass/fail + triggers, not a coverage rate (B4) | ✓   | ✓   | ✓   | ✓   |     |     |     |     | **P1** |
| AEFI profile + 5-category causal value set (C1) | ✓   | ✓   | ✓   |     |     |     | ~   |     | **P1** |
| Wastage / vial-accountability axis (C2) | ✓   | ✓   | ✓   |     | ~   |     |     |     | **P1** |
| Reconcile missed-/noncompliance-reason with WHO lists (C3) | ✓   | ✓   | ~   |     |     | ~   |     |     | **P1** |
| Stockpile-source axis (A3) |     |     |     |     | ✓   |     | ✓   |     | **P2** |
| Dosing-regimen (A4) |     |     |     |     | ✓   |     | ✓   |     | **P2** |
| Campaign-trigger |     |     | ~   |     | ✓   |     | ✓   |     | **P2** |
| Campaign-cost axis | ~   | ~   |     |     | ✓   |     |     |     | **P2** |
| Campaign-phase / readiness lifecycle | ✓   | ~   | ✓   |     |     |     |     |     | **P2** |
| Defaulter / dropout / zero-dose + dropout Measure | ~   | ✓   | ✓   |     |     | ~   |     |     | **P2** |
| Supervision / QA profile | ✓   | ✓   | ✓   |     |     | ~   |     |     | **P2** |
| Social-mobilization / demand axis | ✓   | ✓   | ✓   |     |     |     |     |     | **P2** |
| Population-vulnerability / equity taxonomy | ✓   | ✓   | ✓   |     |     | ~   |     | ✓   | **P2** |
| `outreach` delivery-strategy |     | ✓   |     |     |     | ~   |     | ~   | **P2** |
| CDD / community-distributor performer role |     |     |     |     |     | ✓   |     |     | **P2** |
| Team / CareTeam + microplan-resource profile |     | ~   |     |     |     | ~   |     | ✓   | **P2** |
| Survey evidence-source + crude-vs-valid coverage |     |     |     | ✓   |     |     |     |     | **P2** |
| Population-estimation method + source-raster version/date | ~   | ~   |     |     |     | ~   |     | ✓   | **P3** |
| Catchment-polygon geometry — adopt shipped GeoJSON ext |     |     |     |     |     |     |     | ✓   | **P3 (cheap)** |
| `structure`/footprint location-type + accessibility/travel-time |     | ~   |     |     |     |     |     | ✓   | **P3** |
| Cold-chain / logistics / stock-readiness axis | ~   | ✓   | ✓   |     | ~   |     |     |     | **P3** |
| Endemicity status + TAS/impact-survey gate (NTD) |     |     |     |     |     | ✓   |     |     | **P3** |
| Eligibility-exclusion reasons + dose-pole/height dosing (NTD) |     |     |     |     |     | ✓   |     |     | **P3** |
| Access-vs-utilization problem typology |     | ✓   |     |     |     |     |     |     | **P3** |
| Location-type / denominator-source code additions | ✓   | ✓   | ~   |     |     | ~   |     | ~   | **P3** |
| Surveillance / outbreak / lab — _reference, don't model_ |     | ~   | ✓   |     | ~   | ~   | ~   |     | **Scope** |
### 17.6 Scope decision & refinements to revisit
- **Surveillance & outbreak response — _reference, don't model_.** Case-based surveillance, lab specimen/confirmation, susceptibility/inter-epidemic modelling, and confirmed-case age-distribution are the **trigger and evaluation context** for a campaign, not its execution data. ICR should hold a **thin reference** (the signal/outbreak that justified the SIA + the case-age distribution that set the target age) and link out to a **VPD-surveillance IG**. Keep case/lab data out of the ICR campaign IG. _(M; O/N/Y/R ~.)_
  
- **Refinements (not new axes):**
  
  - **House-to-house _canvassing_ vs _vaccination_** — the single `house-to-house` code conflates Type A demand-generation (dose at post) with Type B door-delivery; canvassing is arguably a modifier. _(S.)_
    
  - **Administrative-coverage stratification** — all sources warn it is denominator-fragile; ensure ICRAdministrativeCoverage stratifies by strategy + age band and can carry a data-quality caveat. _(S, M, R.)_
    
  - **OCV/YF campaign-type** — keep `vaccination-sia` (it already names YF PMVC) rather than adding `ocv`/`yf` codes; document as a deliberate choice. _(O, Y.)_
    
### 17.7 Caveats on the evidence
- The **RED** source is the **2009** edition (not the 2017 revision).
  
- Some web sources 403'd or were thin (GTFCC §9, JHU stop-cholera, the WHO geo-handbook landing page); those analyses leaned on substituted primary sources, flagged inline in each file. A few measles-guide annexes are scanned images; two of its `missed-reason` proposals are inferred from body text.
  
- Downloaded source PDFs live in `docs/research/` (untracked). Each analysis checked the IG against the committed FSH; **confirm exact CodeSystem URLs against** `ig/input/fsh/` **before drafting changes.**
  

* * *
## 18. WHO SMART Immunizations alignment — comparison & proposed structural alignment
> [!note] Status — _proposed_, not committed; addresses §2 c129/c130 This section delivers the **WHO SMART Guidelines comparison** the §2 thread (c129/c130) asked for. It compares ICR against the **WHO SMART Immunizations IG** (`worldhealthorganization.github.io/smart-immunizations` — package `smart.who.int.immunizations#0.2.0`, canonical `http://smart.who.int/immunizations`, FHIR R4, publisher WHO, the L3 FHIR companion to the **WHO Immunization DAK** `smart.who.int.base`-based). Everything here is **proposed** for a subsequent round — no FSH/profile change in this pass. The stance per your steer: **align with the WHO IG's structure where possible**, and reuse WHO artifacts at the seams rather than re-inventing them.
### 18.1 The headline — ICR is the _campaign_ complement to WHO's _routine_ IG
The WHO IG is **routine-immunization only**. Its DAK explicitly scopes itself to routine RI; "mass immunization campaigns" appears in exactly **one** asserted sentence and has **no** dedicated persona, business process, data element, decision table, schedule, or indicator. There is **no** `Campaign`**/**`CarePlan` **concept, no denominator/coverage-survey model, and no operational-geography model** anywhere in it. So the two IGs are **largely complementary, not competing**: ICR models exactly the half WHO omits (campaigns: SIA/MDA/ITN/IRS, denominator-first analytics, operational geography, admin-vs-survey coverage). Alignment is therefore mostly about **shared structure + reuse at the touch-points** (the immunization event, the person, AEFI, terminology, indicators, geography), not about reconciling overlapping models. The clean framing to adopt: **ICR = "the campaign SMART-Guidelines IG"**, same skeleton and conventions as WHO, complementary content, joined by the `record-origin` campaign/routine firewall (§13 #2) — a campaign `ICRImmunizationEvent` and a routine `IMMZ.Immunization` should be able to coexist in one store, distinguished by that flag.
### 18.2 Structural alignment — adopt the WHO SMART-Guidelines IG skeleton (biggest structural gap)
WHO organizes every SMART-Guidelines IG into a standard skeleton (= the HL7 CPG "levels of knowledge representation"). ICR today ships only `index.md` + `background.md` (§12). **Proposed: restructure the ICR IG narrative to mirror this skeleton**, filling the campaign-specific content (and leaving titled stubs where content is pending, exactly as WHO does):

| WHO SMART layer | WHO pages | ICR today | Proposed ICR alignment |
|---|---|---|---|
| **L1 Home** | Summary, Changes, Dependencies, References, Country adaptation | `index.md` (pitch) | Split into the same Home set; add a **Dependencies** page (declare `dependsOn`, see 18.5) and a **Country-adaptation** page |
| **L2 Business Requirements** | Concepts, **Generic Personas**, User Scenarios, **Business Processes**, **Data Dictionary**, Decision-support Logic, **Indicators & Performance Metrics**, Functional / Non-functional Requirements | mostly absent (some rationale in `background.md`) | Add **campaign personas** (vaccinator/CDD team, supervisor, EPI/campaign manager, social-mob officer), **campaign business processes** (microplanning → mobilization → delivery → RCM/LQAS → survey → reconciliation), an ICR **Data Dictionary**, and **campaign indicators** |
| **L2 Data Models & Exchange** | System Actors, Sequence Diagrams, Transactions, Indicators & Measures, Codings | FSH profiles only | Add System Actors / Transactions / **Codings** pages; surface the coverage **Measures** |
| **Deployment** | Security & Privacy, Testing, Test Data, Reference Implementations, Trust Domains, Downloads | none | Add the same set (ties to the §14 gaps: Consent, conformance testing, CapabilityStatement) |
| **Indices** | Artifact Index, Mappings, **DAK API** | auto Artifact Index | Add a **Mappings** page (ICR ↔ WHO IMMZ data elements) and consider a **DAK-API**-style JSON-Schema/OpenAPI surface |

**Business-process mapping (ICR extends WHO's routine A–I).** WHO's processes are `IMMZ.A` Vaccination-location registration · `B` Plan service delivery · `C` Client registration · `D` Administer vaccine · `E` Client reminder · `F` Defaulter tracing · `G/H` De-duplication · `I` Report generation. ICR's spine slots in as the **campaign extension** of these — ICRLocation ≈ A, microplanning/Protocol/Campaign ≈ B, delivery events ≈ D, the proposed defaulter/zero-dose work (§17.3) ≈ F, coverage ≈ I — so ICR should **reference WHO's A–I numbering** and add campaign-only processes rather than coin an unrelated scheme.
### 18.3 Profile / resource alignment (reuse WHO's where they touch)
| Touch-point | WHO artifact | ICR today | Proposed alignment |
|---|---|---|---|
| **Immunization event** | `IMMZ.Immunization` (base R4 Immunization; required `vaccineCode`, `patient`, `occurrence`; `protocolApplied` series/dose; type-of-dose, vaccine-brand, market-authorization, country-of-vaccination extensions) | `ICRImmunizationEvent` (Immunization + `record-origin`) | Make `ICRImmunizationEvent` **compatible-with / derived-from `IMMZ.Immunization`** so a campaign dose is a valid WHO immunization + the `record-origin` flag; reuse `protocolApplied` (already aligned) and the **type-of-dose** extension (overlaps §17 A4 dosing-regimen) |
| **Person** | `IMMZ.Patient` (**base R4 Patient**, *not* IPS — IPS is only a narrative reference; required identifier/name/phone/gender/birthDate/address) | plain `Patient` (§6.1) | Align ICR's person records to `IMMZ.Patient` (or note the deliberate divergence) so household members are WHO-conformant |
| **Caregiver** | `IMMZ.Caregiver` (RelatedPerson) | none | Adopt if/when ICR models caregivers |
| **AEFI** | `IMMZ.AdverseEvent` (base AdverseEvent; from `IMMZ.D17 Report AEFI`; bindings `IMMZ.D.DE95/DE107/DE115`) | **proposed** (§17 C1) | **Reuse `IMMZ.AdverseEvent` + WHO's AEFI value sets** rather than minting a new `aefi-causal-type` VS — direct win, supersedes §17 C1's "new VS" |
| **Observation** | `IMMZ.Observation` (serostatus/HIV/screening feeding decision logic) | none | Reuse if ICR ever carries the dose-pole/eligibility Observation (§7.2 dangling thread) |
| **Decision support** | `PlanDefinition` + CQL (per-antigen schedules/contraindications, `IMMZ.D2/D5/D18`) | `PlanDefinition` = **campaign protocol** | **Naming-collision caution:** WHO uses PlanDefinition for *decision-support schedules*; ICR uses it for the *campaign protocol* (§5.1). Same resource, different role — document the distinction so a consumer isn't surprised. Age-band eligibility-as-CQL (the §5.1 q2 deferral) could later reuse WHO's CQL libraries |
| **Campaign spine** | *(none — WHO has no CarePlan/Campaign/Task/Group denominator/coverage model)* | ICRCampaign / Task / TargetPopulation / coverage / Location | **ICR's distinctive contribution** — keep as-is; offer it back as the campaign extension WHO lacks |
### 18.4 Terminology & indicators alignment - **Terminology ownership differs.** WHO owns its vaccine + data-element terminology (`IMMZ.Z` vaccine codes; `IMMZ.C/D/I` data elements as `IMMZ..DE`; ConceptMaps out to **ICD-11 MMS, LOINC, SNOMED CT, ISO 3166-1**). ICR uses **CVX/ATC/GS1**. **Proposed:** keep CVX/ATC (the international product backbone, §10) but **add ConceptMaps ICR ↔** `IMMZ.Z`**/**`IMMZ.D.DE*` — this is the concrete "reuse the DAK data elements where they align" action (c133), and it's the §14 ConceptMap gap pointed at WHO specifically. ICR's `record-origin`, `delivery-strategy`, `denominator-source`, coverage-source etc. have **no WHO equivalent** → they stay ICR-owned. - **ISO 3166 already aligned.** ICR's v0.7.0 `iso` identifier slice + `$ISO` alias (§3/§6.3, c88) matches WHO's `country-of-vaccination` (ISO 3166-1) and `administrative-area` extensions — note WHO's two Location-ish extensions as prior art for the ICRLocation work.
- **Indicators as FHIR** `Measure`**.** WHO defines **45 Measures** `IMMZIND01–45` (coverage, drop-out, wastage, AEFI, session-completion) with a COUNT-numerator / target-denominator / disaggregation (admin-area, sex, age) template, aggregating into HMIS/DHIS2. This is **strong support for §17 B2** (bind ICR coverage to `Measure` definitions) and §17.3 (dropout/defaulter, wastage): **derive ICR's Measures from the IMMZ ones where they overlap** (coverage, dropout, wastage, AEFI), then add the campaign-only ones WHO lacks — **admin-vs-survey coverage, RCM/LQAS, at-risk/epidemiological denominator, geographic coverage**. ICR's denominator-with-provenance and admin-vs-survey split are _richer_ than WHO (whose denominators are just "set by Member States").
  
### 18.5 Dependency & conventions
- **Declare a formal** `dependsOn` on `smart.who.int.base` (and, where ICR reuses immunization artifacts, `smart.who.int.immunizations`) once alignment hardens — this is the concrete answer to §2 q2 ("what alignment concretely means" / when the dependency is declared). The WHO base brings the CPG/CQL/CRMI/SDC stack if ICR adopts the DAK pattern.
  
- **Canonical / id conventions.** WHO: reverse-domain `smart.who.int.immunizations`, canonical `http://smart.who.int/immunizations`, data elements keyed `IMMZ.<letter>.DE<n>`. ICR: `unicef.fhir.icr`, canonical `https://fhir.icr.unicef.org`, ICR-prefixed kebab-case. **Keep ICR's** (it's a different publisher/namespace), but **mirror the _data-dictionary-row → artifact-id_ discipline** (every coded element gets a stable id + paired ValueSet) so a Mappings page can line ICR elements up against `IMMZ.*` 1:1.
  
- **Modeling-pattern divergence (optional, heavier lift).** WHO's source-of-truth is **LogicalModels → SDC Questionnaires → StructureMaps → thin profiled events**; ICR profiles resources directly. Full adoption (logical models + the DAK-API JSON-Schema/OpenAPI surface) would maximize structural alignment but is a large lift — flag as **aspirational**, not v1. The cheap, high-value subset is the **skeleton (18.2), the AEFI/Immunization reuse (18.3), the ConceptMaps and Measure derivation (18.4), and the declared dependency (18.5)**.
  
### 18.6 Caveats
- WHO IG is **v0.2.0, draft**, and **skeleton-heavy**: many Deployment/Indices pages are titled **stubs** ("Feel free to modify this index page…"). Align to the _skeleton and conventions_, but don't assume filled-in content behind every page.
  
- One narrative claim in the WHO IG (an **IPS Patient** dependency) is **not** borne out by its artifacts — `IMMZ.Patient` derives from **base R4 Patient** and IPS is not a declared dependency. Don't inherit the IPS assumption.
  
- This comparison was done against the WHO IG as published June 2026; re-verify artifact ids/bindings against the live IG before authoring the alignment FSH.
