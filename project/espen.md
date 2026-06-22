---
version: 0.1.0
last_modified: 2026-06-22T17:55:27.000Z
tags:
  - icr
  - fhir
  - ig
  - espen
  - mda
  - ntd
  - field-evidence
public: true
---

# ESPEN MDA Forms ↔ ICR IG — Data-Model Fit Analysis
<sub>`v0.1.0 · Last modified Jun 22, 2026 at 1:55 PM EDT`</sub>

⁠

> [!note] What this document is
> A field-evidence check of the **ESPEN NTD-MDA demo forms** (`forms/espen mda/`) against the draft ICR FHIR IG (`ig/`) as walked through in [[ig-info]]. For each form it asks: **does the campaign data these forms collect fit the proposed data model, or does it conflict?** The forms are a real (demo, DR Congo–shaped) set of **ODK XLSForms** for a community-directed PC-NTD mass-drug-administration round — exactly the `campaign-type = mda` + `community-directed` strategy the IG models. The companion **Country Deck** frames the strategic context: five-country **campaign integration** (Sierra Leone, Uganda, DR Congo, Angola, Rep. of Congo), with DRC already running a *5-disease NTD MDA co-administered with polio*. Cross-refs are to [[ig-info]] sections (§n) and the source design doc [[icr-v1]].

* * *

## 0. Sources analysed

| File | What it is | XLSForm shape |
|---|---|---|
| `demo_mda_9999_1_location.xlsx` | **Village/location registration** — admin hierarchy, population, GPS | Cascading `select_one` state→district→HF→village→village-id; `int` population bands; `geopoint` |
| `demo_mda_9999_2_part.xlsx` | **Medicine receipt** — drugs received at the village | `select_multiple` disease + medicine (with disease↔medicine consistency constraints); per-drug `integer` qty received |
| `demo_mda_9999_3_med_treatment.xlsx` | **Treatment reporting (the core form)** — who was treated, by drug × sex × age band, and reasons not treated | `census_method` toggle; per-drug groups of treated counts + reason-not-treated counts; CDD workforce counts |
| `demo_mda_9999_4_case_mngnt.xlsx` | **Medicine use & case management** — distributed totals, side-effects, other-NTD case finding | `med_distr` group; `other_ntd_rep` group (guinea worm / leish / buruli / LF morbidity) |
| `demo_mda_9999_5_supervision_hf.xlsx` | **Supervision — health-facility level** — geographic coverage, stock, training, mobilisation, pharmacovigilance | Many `field-list` groups; villages treated/not + reasons; per-drug stock concordance |
| `demo_mda_9999_6_supervision_CDD.xlsx` | **Supervision — CDD observation** — direct observation of a community drug distributor | Skills/attitude observation checklist; supplies; training session detail |
| `ESPEN Campaign Integration Country Deck` (pptx) | Strategic framing — 5-country integration calendars & co-delivery archetypes | (context only) |

Drug/disease vocabulary across all forms: diseases **LF, ONCHO, SCHISTO, STH, TRACHOMA**; medicines **IVM, IVM+ALB, IVM+ALB+DEC, ALB, MEB, PZQ, PZQ+ALB, PZQ+MEB, AZM (tab/susp), TETRA** — the PC-NTD backbone.

* * *

## 1. Verdict (TL;DR)

**The IG's spine fits ESPEN cleanly, and ESPEN is strong, concrete field-validation for the IG's design — including several decisions the IG made deliberately.** No element of the ESPEN forms *contradicts* the data model. The fit splits three ways:

1. **Direct matches (the model already handles it).** Admin hierarchy → `ICRLocation.partOf`; GPS → `ICRLocation.position`; village population/age-bands → `ICRTargetPopulation`; ATC drugs → `ICRMedicationAdministration`; directly-observed consumption → `directly-observed-consumption`; dose-pole/height dosing → `dosage` derived from a height Observation; **and most importantly the aggregate-vs-individual capture mode** — Form 3's `census_method` toggle (**"Household-Level Digitization" vs "Aggregate Reporting"**) is *literally* the IG's §7.3 rule, written into the data-collection tool. That is the single best validation in the set.

2. **A few real modelling tensions** that need a drafting answer — chiefly **how to carry a multi-dimensional aggregate tally** (drug × sex × age band × disposition) when there is no person, and **ATC-coding a drug `SupplyDelivery`**.

3. **A long list of things ESPEN collects that the IG does not yet model — but almost every one is already on the §17 proposed-additions backlog.** ESPEN is therefore not a source of *surprises*; it is a **priority signal** confirming which §17 items are load-bearing in a real MDA (supervision/QA, AEFI for drugs, geographic coverage, stock/wastage, workforce, social mobilisation, eligibility-exclusion reasons).

The one genuine **scope tension** is Form 4's bundled **other-NTD case-finding and LF morbidity** data, which collides with the IG's deliberate §17.6 "*surveillance — reference, don't model*" stance.

* * *

## 2. The headline match — aggregate tally vs individual record (§7.3 validated)

The IG's §7.3 rule states: **individual record when you have a person; aggregate count on `Task.output` when you don't; `MeasureReport` only for derived coverage.** And `ICRMedicationAdministration.subject` is explicitly typed `Reference(Patient or ICRDeliveryUnit)` so a community-register aggregate is a valid MedicationAdministration against the community **Group**.

Form 3 encodes exactly this choice as a first field:

```
select_one census_method | census_method | Census method
  → Household-Level Digitization
  → Aggregate Reporting
```

- **"Household-Level Digitization"** → the IG's *individual* path: enumerate `ICRPatient`s into an `ICRDeliveryUnit` (community/household Group), mint a person-level `ICRMedicationAdministration` per treatment (subject = `ICRPatient`), `directlyObserved` true.
- **"Aggregate Reporting"** (the prevailing field reality) → the IG's *aggregate* path: subject = the community `ICRDeliveryUnit`, or coded counts on `ICRCampaignTask.output`, with `ICRAdministrativeCoverage` for the derived rate.

> [!check] This is the strongest single confirmation in the set
> The IG did not invent the aggregate/individual duality — the ESPEN tool ships with the toggle. The model and the form agree on the *same seam*. (See the §2.1 caveat for where they don't quite line up.)

### 2.1 …but the aggregate path loses ESPEN's disaggregation — the #1 tension

ESPEN aggregate treatment data (Form 3) is not a single number. For **each drug** it is a **cube**: treated counts by **sex** (M/F) × **age band** (5–14 / 15+, plus AZM's 6mo–<7 / >7) **and** a parallel cube of *reasons not treated* (under-height / pregnant / breastfeeding / absent / refusal).

A single Group-subject `ICRMedicationAdministration` carries **one** `dosage`/quantity — it cannot hold the sex × age split. The IG's stated home for this is "**coded aggregate counts on `Task.output`**" (§5.4 disaggregation pattern, §7.3) or a **stratified `MeasureReport`** — but **neither is worked out structurally** in v0.1. ESPEN is the concrete requirement that forces the question:

- **What is the canonical shape of a stratified MDA tally?** Options: (a) many `Task.output` coded counts keyed by a drug+sex+ageband+disposition coding; (b) a stratified `ICRAdministrativeCoverage` `MeasureReport` with `group`/`stratifier` per sex×age; (c) one `ICRMedicationAdministration` per (drug × sex × ageband) cell with a Group subject and `quantity` — abusing the resource as a tally row.

> [!warning] Recommendation
> Pick and **document one stratified-tally structure**, using the ESPEN drug × sex × age-band × disposition cube as the worked example. This is the most actionable IG gap the forms expose, and it sits underneath §17.2 B1 (the coverage **unit/denominator-type** rework) and §17.6's "administrative-coverage stratification" refinement (*stratify by strategy + age band*).

* * *

## 3. Form-by-form mapping to the IG

### Form 1 — Location / village registration → `ICRLocation` + `ICRTargetPopulation`
| ESPEN field | ICR home | Fit |
|---|---|---|
| `l_state → l_district → l_health_facility → l_location → l_location_id` (cascading) | `ICRLocation` chain via `partOf` (admin-unit → admin-unit → facility → settlement); `l_location_id` → `ICRLocation.identifier` | ✅ strong — `ICRLocationTypeCS` has `admin-unit`, `facility`, `settlement` |
| `l_gps` (geopoint) | `ICRLocation.position` | ✅ |
| `l_total_pop`, `I_total_popn_1_4`, `I_total_popn_5_14`, `I_total_popn_15_More` | `ICRTargetPopulation.quantity` + `characteristic` (age bands) | ✅ — `denominator-source = #microcensus`, `estimate-date` set, `characteristic[geography]` → this Location |
| `l_eligible_pop` (calc = 1–4 + 5–14 + 15+) | `ICRTargetPopulation.quantity` with an eligibility `characteristic` (MDA-eligible = age ≥1) | ✅ |
| `l_recorder_id`, `l_submitting_report` | `MeasureReport.reporter` / provenance / `CareTeam` | ⚠️ workforce — see §4 gaps |

**Notes.** ESPEN's 4-level admin chain (province → district → health-area/HF → village) maps directly onto arbitrary `partOf` nesting. The village population captured here is a **microcensus denominator with provenance** — exactly the IG's denominator-with-provenance model (§6.2). The MDA-specific bands (1–4, 5–14, 15+) are "configurable age bands," which §17.1 already lists as *validated, do not change*.

### Form 2 — Medicine receipt → `ICRSupplyDelivery`
| ESPEN field | ICR home | Fit |
|---|---|---|
| `p_disease` (LF/ONCHO/SCHISTO/STH/TRACHOMA) | `ICRCampaign.addresses` (condition); per-Activity scoping | ✅ (see §3 tension on per-village variation) |
| `p_medicine` (+ disease↔medicine constraints) | `ICRCampaignActivity.product` (ATC); the constraint logic is microplan validation, not stored data | ✅ |
| `p_total_pzq / _alb / _meb / _ivm / _dec / _az_sus / _az_tab / _tetra` (qty received) | `ICRSupplyDelivery.suppliedItem.quantity` + `.item[x]` | ⚠️ **item coding gap** — see below |

> [!warning] Tension — drug `SupplyDelivery` wants ATC, IG only GS1-codes it
> `ICRSupplyDelivery.suppliedItem.item[x]` is documented "**GS1 GTIN-coded** commodity where applicable" — fine for ITNs/IRS consumables, but an MDA **drug receipt** is naturally **ATC-coded** (the same `ICRMDAMedicationVS` that binds `ICRMedicationAdministration`). Recommend the IG **allow ATC on `SupplyDelivery.suppliedItem.item`** for drug commodities (or note the ATC/GS1 either-or), so receipt → administration → reconciliation share one drug code. Relates to the §7.3 "no GS1 binding/alias yet" note.

### Form 3 — Treatment reporting → `ICRMedicationAdministration` / `Task.output` / `ICRAdministrativeCoverage`
This is the core; the structural fit is in §2 + §2.1. Field-level:
| ESPEN field | ICR home | Fit |
|---|---|---|
| `census_method` toggle | the §7.3 individual-vs-aggregate switch | ✅✅ validates the model |
| `census` group (households, men, women) | in-round `ICRTargetPopulation` refresh (microcensus) or `Task.output` | ✅ |
| `<drug>_<band>_<sex>_treated` cube | `ICRMedicationAdministration` (individual) **or** stratified tally (aggregate) | ⚠️ disaggregation — §2.1 |
| `<drug>_child` (under <90 cm), `_pregnant`, `_breastfeeding` | **eligibility-exclusion** reasons | ❌ **gap** — see §4 (only `#sick` partially covers it) |
| `<drug>_absent` | `ICRMissedReasonCS#absent` (Task `missed-reason`) | ✅ |
| `<drug>_refusal` | `ICRMissedReasonCS#refusal` + `noncompliance-reason` | ✅ |
| `<90 cm` / height-band logic (AZM by age, TETRA) | dose-pole: `dosage` derived from a height Observation (§7.2 `supportingInformation`) | ✅ concept; ❌ the *exclusion* below the pole needs a code |
| `p_campaign_day` (Day 1–10) | event `occurrence`/`effective` date; `Task.executionPeriod` | ✅ (finer than `campaign-round`) |
| `cd_who_distributed_*`, `cd_trained`, `cd_recycled` | **workforce / CareTeam** | ❌ gap — §4 |

### Form 4 — Use & case management → `ICRSupplyDelivery` (reconciliation) + **AEFI gap** + **surveillance scope tension**
| ESPEN field | ICR home | Fit |
|---|---|---|
| `p_total_<drug>_dist` (distributed) | reconciliation: received − remaining = distributed → `realtime` vs `reconciled` lineage on the close-out figures | ✅ lineage axis fits |
| `p_minor_side_effect`, `p_serious_side_effect` | **AEFI / pharmacovigilance** | ❌ **gap** (§17.2 C1) — and ICR's AEFI is *immunization*-framed; MDA needs drug AEFI |
| `p_guinea_worm_rumor`, `p_leish_suspect`, `p_buruli_ulcer_suspect` | other-NTD **case finding / surveillance** | 🛑 **scope tension** — §17.6 says *reference, don't model* |
| `p_Lymphoedema_LF`, `P_hydrocele_LF` | LF **morbidity management** (NTD programme data, not MDA delivery) | 🛑 out of MDA-delivery scope |

> [!bug] Scope tension — Form 4 bundles surveillance into the campaign report
> The IG made a deliberate call (§17.6): case-based surveillance and lab data are the *trigger/evaluation context* of a campaign, not its execution data — hold a thin reference, link out to a VPD/NTD-surveillance IG. But the **real ESPEN form collects guinea-worm rumours, suspected leish/Buruli, and LF lymphoedema/hydrocele on the same submission as the treatment tally.** The model is defensible, but ingestion must decide where this co-bundled data goes — a **passthrough/reference**, or explicit drop. Worth a §17.6 note that the *form* does not respect the modelling boundary, so the **ingestion mapping** must.

### Forms 5 & 6 — Supervision → **the biggest unmodelled block**
Forms 5 (HF-level) and 6 (CDD observation) are **supervision/QA instruments end to end**, and the IG has **no supervision profile** (proposed §17.3 + the §5.5 `ICRCareTeam` draft). Mapping by theme:
| ESPEN theme (forms 5/6) | ICR home today | Status |
|---|---|---|
| Villages total / treated / **not treated** + reasons | **geographic coverage** (unit = implementation-units) | ❌ §17.2 B1 — *ESPEN is the validation* |
| Reasons for non-treatment (insecurity, med shortage, difficult access, not required) | **area-level** missed reasons | ❌ partial — `#inaccessible`/`#not-visited` only; needs `medication-shortage`, `insecurity`, `not-required` (§17.2 C3) |
| Per-drug stock: remaining / **expired** / physical-vs-theoretical concordance | **wastage / stock-readiness** | ❌ §17.2 C2 + §17.4 |
| Distributor training counts, manual used, training topics | **workforce / CareTeam / microplan** | ❌ §17.3 (CDD performer role, Team profile) |
| Social mobilisation: informed?, channels (radio, criers, leaders, schools, posters) | **social-mobilisation / demand axis** | ❌ §17.3 |
| Pharmacovigilance: adverse / serious adverse | AEFI | ❌ §17.2 C1 |
| Supervisor level (National/Regional/District/Partner/HF) | `ICRCareTeam` role; `MeasureReport.reporter` | ◑ §5.5 draft |
| **DOC observed** ("medicine taken in presence of DC"); finger/concession marking; height-chart use | `directly-observed-consumption`; `finger-marked`; dose-pole | ✅ **validates existing extensions** |

* * *

## 4. Consolidated gaps — and the §17 backlog they validate

Almost every ESPEN field the IG can't yet hold maps to an **existing §17 proposed addition**. ESPEN's contribution is the **priority signal**: these aren't theoretical: a single routine DRC MDA round collects all of them.

| ESPEN data | IG gap | Already in backlog? | Signal |
|---|---|---|---|
| Under-height / pregnant / breastfeeding "not treated" (Form 3) | **Eligibility-exclusion reasons** distinct from *missed* (only `#sick` partial) | §17.4 NTD specifics (**P3**) | **Promote** — appears for *every* drug on the core form |
| Minor/serious side effects (Forms 4, 5) | **AEFI profile**, intervention-neutral (drugs too, not just vaccines) | §17.2 **C1** (P1) | Confirmed for MDA; widen scope beyond AEFI-of-immunization |
| Villages treated / total (Form 5) | **Geographic coverage** (unit axis) | §17.2 **B1** (P1) | Direct validation |
| Stock remaining/expired/concordance (Form 5) | **Wastage / stock-readiness** | §17.2 **C2** + §17.4 | Direct validation |
| Distributor counts/training; CDD performance (Forms 3, 5, 6) | **Supervision/QA profile + CDD performer + CareTeam/microplan** | §17.3 + §5.5 draft | **Major** — 2 of 6 forms are entirely this |
| Social mobilisation channels (Form 5) | **Social-mobilisation / demand axis** | §17.3 | Direct validation |
| Non-treatment reasons: insecurity, shortage, access, not-required (Forms 5, 6) | **Area-level missed-reason** codes | §17.2 **C3** | Add the codes |
| Sex × age × drug × disposition tally (Form 3) | **Stratified-tally structure** (no worked shape) | implied by §17.2 B1 / §17.6 | **New, actionable** — see §2.1 |
| ATC on drug `SupplyDelivery` (Forms 2, 4) | item coding GS1-only | §7.3 note | **New, small** |
| Other-NTD case finding + LF morbidity (Form 4) | surveillance co-bundled in form | §17.6 (reference-don't-model) | Ingestion-mapping decision |

* * *

## 5. What the IG expects that ESPEN omits (the inverse check)

These are IG elements with **no ESPEN counterpart** — not conflicts, but worth noting for the ingestion mapping and for what "MDA aggregate reporting" structurally cannot supply:

- **`record-origin` (campaign vs routine)** — the forms are inherently campaign-context, so the value is a *constant* (`campaign`) the mapper injects; ESPEN never asks. ✅ no conflict.
- **`task-origin` (pre-planned vs field-registered)** — ESPEN has no microplan-vs-discovery flag; everything is reported against the pre-loaded village list (Form 1 feeds the others via `db_get`). Mapper defaults to `pre-planned`.
- **`finger-marked` / `houses-visited` / `eligible-present`/`-absent`** — these are *house-to-house* (Type B vaccination) telemetry; ESPEN's **community-directed** (Type C) model reports at village-aggregate level and so doesn't produce them. Consistent with the IG's design that the available data elements change with the delivery strategy (§3, validated §17.1).
- **GERS / P-code location identity** — ESPEN uses local cascading names + a numeric `location_id`; no GERS/P-code. The IG's multi-system identity (§6.3) is precisely the join layer that would *enrich* ESPEN villages with stable IDs — an ingestion enrichment opportunity, not a gap in ESPEN.
- **Person-level identity (`ICRPatient` name/ID, consent)** — only relevant in the "Household-Level Digitization" mode; the aggregate mode (the default) never collects it. The IG's `ICRPatient`/`ICRConsent` (v0.16/v0.17) are for the digitization path the form's toggle anticipates.

* * *

## 6. Integration context (from the deck) — why this matters for ICR

The Country Deck reframes the forms: the ESPEN agenda is **campaign integration** — co-administration (one ivermectin-based CDD round covering LF + Oncho ± SCH/STH/Trachoma) and co-delivery (school-based PZQ + ALB; child-health days bundling Vitamin A + deworming + MR/YF). DRC already runs a **5-disease NTD MDA co-administered with polio**.

This directly exercises ICR features the forms alone don't show:
- **`campaign-type = integrated`** + per-Activity intervention typing — the multi-disease, multi-drug round (`p_disease` / `p_medicine` are multi-select for exactly this reason).
- **Shared denominator across co-delivered interventions** — §17.1 lists "integrated multi-intervention on a shared denominator" as *validated*. The deck's co-delivery archetypes are the use-case.
- **Per-village disease/medicine variation** (co-endemicity differs by village) → confirms the model must scope disease/product at the **Activity/Task** level, not only `Campaign.addresses`. Minor tension flagged in §3 (Form 2).

> [!note] One direction
> The deck's closing slide — "*co-delivery is already happening; the task is to make it systematic … invest in digital campaign management*" — is the ICR thesis. The ESPEN forms are precisely the **ODK source data** an ingestion pipeline (OpenFn → FHIR) would transform into the profiles above. The fit analysis says that transform is viable today for the spine, with the §2.1 stratified-tally shape as the main piece to design first.

* * *

## 7. Recommended next steps (priority order)

1. **Design the stratified aggregate-tally structure** (§2.1) — the one genuinely-new, blocking modelling question. Use the Form 3 drug × sex × age-band × disposition cube as the worked example; decide `Task.output` coded counts vs stratified `MeasureReport`. Couple with §17.2 B1.
2. **Promote eligibility-exclusion reasons** (under-height/pregnant/breastfeeding) from §17.4 P3 — they're on the core treatment form for every drug, not an edge case. Decide the home (extend `ICRMissedReasonCS` vs a distinct `exclusion-reason` axis; note these are *present-but-contraindicated*, not *missed*).
3. **Allow ATC on `ICRSupplyDelivery.suppliedItem.item`** for drug receipts (§3, Form 2) — small, unblocks receipt↔administration↔reconciliation on one code.
4. **Confirm the supervision/QA + CareTeam scope** (§17.3 / §5.5) — Forms 5 & 6 are 1/3 of the form set and entirely unmodelled; at minimum decide whether v1 carries a supervision profile or defers.
5. **Make the AEFI proposal (§17.2 C1) intervention-neutral** so MDA drug side-effects (Forms 4/5) are in scope, not just AEFI-of-immunization.
6. **Add a §17.6 note**: the ESPEN treatment form co-bundles surveillance/morbidity data, so the *ingestion mapping* (not the model) must decide passthrough-vs-drop — the "reference, don't model" boundary lives in the pipeline, not the form.
7. **Add area-level non-treatment reason codes** (insecurity, medication-shortage, difficult-access, not-required) under §17.2 C3.

* * *

> [!abstract] Bottom line
> ESPEN MDA reporting **fits the ICR data model's spine without conflict**, and validates several deliberate IG choices (aggregate/individual duality, ATC MDA administration, directly-observed consumption, dose-pole dosing, configurable age bands, integrated shared-denominator campaigns). It surfaces **one new actionable modelling task** (the stratified tally, §2.1), **two small fixes** (ATC on SupplyDelivery; promote eligibility-exclusion reasons), and otherwise acts as **field-evidence prioritisation for the existing §17 backlog** — most loudly for supervision/QA, AEFI-for-drugs, geographic coverage, and stock/wastage. The only real *scope* friction is Form 4's co-bundled surveillance data versus §17.6.
