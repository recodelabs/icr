---
version: 0.2.0
last_modified: 2026-06-22T18:30:02.000Z
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

# ESPEN MDA Forms ↔ ICR IG — Data-Model Fit Analysis (v2, post-changes)
<sub>`v0.2.0 · Last modified Jun 22, 2026 at 2:30 PM EDT`</sub>

⁠

> [!note] What this document is
> A **re-run** of the [[espen]] fit analysis after implementing its §7 recommendations in the IG. Same six **ESPEN NTD-MDA demo forms** (`forms/espen mda/`), same method — map every form/field to the data model and flag matches, tensions, and gaps — but against the IG **as of `ig/` commit `<this round>` / [[ig-info]] v0.18.0**, which committed four of v1's recommendations and reworded three more. The point of v2 is to show **what closed, what's now demonstrated by a concrete example, and what remains open**. Cross-refs: [[espen]] (v1, the original analysis), [[ig-info]] (§n), [[icr-v1]].

* * *

## 0. What changed between v1 and v2

v1 made seven recommendations (espen.md §7). This round implemented four in FSH and reworded three as backlog/decisions. SUSHI-clean throughout: **14 profiles, 24 extensions, 13 CodeSystems, 15 ValueSets, 33 examples** (was 23 / 12 / 13 / 30).

| v1 rec | Action taken | Where |
|---|---|---|
| **1. Stratified aggregate tally** | ✅ **Implemented** — resolved to a **`MeasureReport` with `group.stratifier`**; new `example-mda-treatment-tally` (sex × age-band) | examples.fsh; [[ig-info]] §7.3, §8.1 |
| **2. Eligibility-exclusion reasons** | ✅ **Implemented** — new `exclusion-reason` extension (Task, 0..\*) + `ICRExclusionReasonCS`/`VS` | extensions.fsh, codesystems.fsh, valuesets.fsh, profiles-campaign.fsh |
| **3. ATC on drug `SupplyDelivery`** | ✅ **Implemented** — `suppliedItem.item` bound extensible to new `ICRSuppliedItemVS` (ATC); new `example-albendazole-supply` | profiles-delivery.fsh, valuesets.fsh |
| **7. Area-level non-treatment reasons** | ✅ **Implemented** — `ICRMissedReasonCS` + `medication-shortage`, `insecurity`, `difficult-access`, `not-required` | codesystems.fsh |
| **5. AEFI intervention-neutral** | 📝 **Reworded** (still proposed) — §17.2 C1 now covers MDA drug pharmacovigilance, not AEFI-only | [[ig-info]] §17.2 C1 |
| **4. Supervision/QA scope** | 📝 **Decision** — confirmed load-bearing, **deferred past v1** with rationale | [[ig-info]] §17.3 |
| **6. Co-bundled surveillance** | 📝 **Note added** — boundary enforced in the *ingestion mapping*, not the model | [[ig-info]] §17.6 |

New `example-mda-community-task` ties the implemented pieces together (Type-C community-directed Task with exclusion + area reasons, output → the stratified tally).

* * *

## 1. Verdict (TL;DR) — v2

**The fit is now materially tighter.** The two v1 *modelling tensions* are both closed, and two of the field-evidence *gaps* are filled with committed, SUSHI-clean artifacts and worked examples. What remains open is, by design, the **larger structural work** (supervision/QA, intervention-neutral adverse events, the full coverage denominator-type/unit rework) and the **one scope tension** (co-bundled surveillance) — all now explicitly tracked with a decision or reworded backlog item.

- **Tensions → resolved.** The disaggregated tally has a canonical FHIR-native home (`group.stratifier`); drug supplies share one ATC code with their administration.
- **Gaps → two filled, rest triaged.** Eligibility-exclusion reasons and area-level non-treatment reasons are in the IG; AEFI/supervision/social-mobilization are reworded/deferred with rationale rather than left as undifferentiated backlog.
- **Spine → unchanged and still validated.** Everything v1 found to *match* still matches; nothing regressed.

The honest residual: an MDA round reported through ESPEN's six forms is now **substantially** representable (registration, denominator, supply, treatment cube, dispositions, geographic non-treatment), but **supervision/QA (Forms 5 & 6) and drug pharmacovigilance remain only partially modelled** pending the next round.

* * *

## 2. The headline match — now with a worked aggregate example (§7.3 closed)

v1's strongest finding stands: Form 3's `census_method` toggle ("Household-Level Digitization" vs "Aggregate Reporting") *is* the IG's §7.3 individual-vs-aggregate rule. v2 adds the missing half.

### 2.1 The disaggregation tension — RESOLVED

v1's **#1 tension**: ESPEN aggregate treatment data is a **cube** (drug × sex × age band × disposition), which a single Group-subject `MedicationAdministration` can't hold, and the IG named no structure.

**v2 resolution** — the cube lands as an **`ICRAdministrativeCoverage` `MeasureReport` with `group.stratifier`**, FHIR's native disaggregation mechanism. The scalar per-visit count still rides `Task.output`; the stratified report hangs off it.

> [!check] Demonstrated by `example-mda-treatment-tally`
> An albendazole community round: numerator 2,900 / denominator 3,200 ≈ **91%**, stratified by **sex** (1,500 F / 1,400 M) and **age band** (1,100 at 5–14 / 1,800 at 15+). `example-mda-community-task.output[1]` references it; `output[0]` carries the 2,900 scalar. This is exactly the Form 3 treated-counts cube.

**Residual (tracked, not blocking).** v0.1 does not yet *constrain* the stratifier axes (no required `stratifier.code` value set) and the report isn't bound to a `Measure`. Formalising the standard sex/age/strategy stratification + Measure binding is the §17.2 **B1/B2** rework — the stratified example is "the pattern, not yet the rule" ([[ig-info]] §8.1). The exclusion-disposition arm of the cube currently lives as Task `exclusion-reason` counts rather than a stratifier stratum — fine for v1, worth unifying in B1.

* * *

## 3. Form-by-form — what changed

### Form 1 — Location / village registration → `ICRLocation` + `ICRTargetPopulation`
**Unchanged — still a clean ✅.** Admin chain → `partOf`, GPS → `position`, population bands → `ICRTargetPopulation` (microcensus). No v1 issue here; nothing to fix.

### Form 2 — Medicine receipt → `ICRSupplyDelivery`
| v1 status | v2 status |
|---|---|
| ⚠️ drug receipt wants ATC; IG only GS1-coded `suppliedItem.item` | ✅ **RESOLVED** — `suppliedItem.item` bound **extensible to `ICRSuppliedItemVS`** (ATC for drugs; GS1/text for commodities). `example-albendazole-supply` shows ATC `P02CA03` on a 3,600-tablet receipt — the **same code** as the `ICRMedicationAdministration`, so receipt → administration → reconciliation join on one code. |

Per-village disease/medicine variation (co-endemicity) still maps at the Activity/Task level — unchanged, no artifact needed.

### Form 3 — Treatment reporting → tally + dispositions
| ESPEN field | v1 status | v2 status |
|---|---|---|
| `census_method` toggle | ✅ validates §7.3 | ✅ unchanged |
| `<drug>_<band>_<sex>_treated` cube | ⚠️ no disaggregation shape | ✅ **RESOLVED** — stratified `MeasureReport` (§2.1) |
| `<drug>_child` (<90 cm), `_pregnant`, `_breastfeeding` | ❌ gap (only `#sick` partial) | ✅ **RESOLVED** — new `exclusion-reason` extension + `ICRExclusionReasonCS` (`under-height-age`, `pregnant`, `breastfeeding`, `acute-illness`, `other`); on `example-mda-community-task` |
| `<drug>_absent` | ✅ `#absent` | ✅ unchanged |
| `<drug>_refusal` | ✅ `#refusal` + noncompliance | ✅ unchanged |
| dose-pole / <90 cm dosing | ✅ concept; ❌ exclusion code | ◑ exclusion code now exists (`under-height-age`); structured dose-band still proposed (§17.4) |
| CDD workforce counts | ❌ gap | ❌ **still open** — workforce/CareTeam, deferred (§17.3) |

> [!check] Eligibility-exclusion = its own axis (v1 rec 2)
> The IG now distinguishes three *non-treatment* dispositions cleanly: **missed** (not reached — `ICRMissedReasonCS`), **noncompliance** (present but declined — `ICRNoncomplianceReasonCS`), and **exclusion** (present and age-eligible but *clinically contraindicated* — `ICRExclusionReasonCS`). That three-way split is exactly what Form 3's "reasons not treated" sub-groups encode. `#sick` (missed, deferral sense) and `acute-illness` (exclusion, contraindication sense) are flagged for reconciliation in §17.2 C3.

### Form 4 — Use & case management
| ESPEN data | v1 status | v2 status |
|---|---|---|
| `p_total_<drug>_dist` (distributed) | ✅ reconciliation via lineage | ✅ unchanged; now ATC-coded supply chain (Form 2 fix) makes received−remaining=distributed computable on one code |
| `p_minor_side_effect`, `p_serious_side_effect` | ❌ AEFI gap | ◑ **reworded, still open** — §17.2 C1 now **intervention-neutral** so MDA drug side-effects are in scope; profile not yet built |
| guinea worm / leish / Buruli / LF morbidity | 🛑 scope tension | 🛑 **acknowledged with ingestion note** — §17.6 now says the *mapping* must route this to a surveillance/morbidity store, not the model |

### Forms 5 & 6 — Supervision
| ESPEN theme | v1 status | v2 status |
|---|---|---|
| Villages treated / total + reasons | ❌ §17.2 B1 | ◑ **reasons partly in** — area-level `medication-shortage`/`insecurity`/`difficult-access`/`not-required` added to `ICRMissedReasonCS`; the geographic-coverage *unit axis* (villages-as-denominator) still B1 |
| Per-drug stock: remaining/expired/concordance | ❌ §17.2 C2 | ❌ still open (wastage/stock-readiness) |
| Distributor training/counts; CDD observation | ❌ §17.3 | ❌ **deferred with rationale** — supervision/QA confirmed load-bearing but past-v1 (§17.3) |
| Social mobilization channels | ❌ §17.3 | ❌ still open (demand axis) |
| DOC observed; finger/concession marking; height-chart | ✅ validates existing extensions | ✅ unchanged |

* * *

## 4. Gap scorecard — v1 → v2

| ESPEN data | v1 | v2 | Artifact |
|---|---|---|---|
| Disaggregated treatment cube | ❌ no shape | ✅ **closed** | `group.stratifier` + `example-mda-treatment-tally` |
| Eligibility-exclusion reasons | ❌ | ✅ **closed** | `exclusion-reason` ext + `ICRExclusionReasonCS`/VS |
| ATC on drug supply | ⚠️ | ✅ **closed** | `ICRSuppliedItemVS` binding + `example-albendazole-supply` |
| Area-level non-treatment reasons | ❌ partial | ✅ **closed** (4 codes) | `ICRMissedReasonCS` additions |
| AEFI / drug pharmacovigilance | ❌ | ◑ **reworded P1** | §17.2 C1 (intervention-neutral) |
| Supervision/QA + CDD + CareTeam | ❌ | ◑ **deferred, decided** | §17.3 (post-v1) |
| Geographic-coverage *unit* axis | ❌ | ◑ **reasons in, axis pending** | §17.2 B1 |
| Stock / wastage / cold-chain | ❌ | ❌ open | §17.2 C2 / §17.4 |
| Social mobilization / demand | ❌ | ❌ open | §17.3 |
| Co-bundled surveillance | 🛑 | 🛑 **scoped to pipeline** | §17.6 ingestion note |

**Closed: 4 of 4 implementable v1 items.** The rest are either genuinely large (supervision, full coverage rework) or out of model scope by deliberate decision (surveillance) — and all now carry an explicit status rather than sitting in undifferentiated backlog.

* * *

## 5. Inverse check — IG elements ESPEN still omits

Unchanged from v1 §5, and still not conflicts:
- `record-origin` (mapper injects constant `campaign`); `task-origin` (defaults `pre-planned`); house-to-house telemetry (`finger-marked`/`houses-visited`/`eligible-present` — Type-B, not Type-C community-directed); GERS/P-code identity (an ingestion *enrichment* opportunity); person-level identity + consent (only in the digitization mode the `census_method` toggle anticipates).

One v2 nuance: the new **`exclusion-reason`** is 0..\* and extensible, so a form that doesn't disaggregate dispositions simply omits it — no conformance pressure on the aggregate-only path.

* * *

## 6. Remaining recommendations (post-v2)

The implementable v1 items are done. What's left is the next round's agenda:

1. **Formalise the stratified tally into a rule** (§17.2 B1/B2) — bind a `Measure`, constrain the standard stratifier axes (sex, age band, strategy), and add the denominator-type (total vs at-risk) + unit (people vs implementation-units → geographic coverage) axes. The v0.18.0 stratified example is the down-payment; this makes it conformant and comparable.
2. **Build the intervention-neutral adverse-event profile** (§17.2 C1) — now that the wording covers MDA, ship the profile (reuse WHO `IMMZ.AdverseEvent` for the immunization arm).
3. **Scope the supervision/QA + CareTeam/microplan bundle** (§17.3) — the single biggest unmodelled block (Forms 5 & 6); decide its shape for the next major round.
4. **Wire the ESPEN ingestion mapping** as a concrete artifact — including the §17.6 surveillance-routing rule — to pressure-test the model against a real OpenFn transform (the truest validation, and what v1 §7 flagged as the eventual proof).
5. **Complete the Type-C example thread** — add a CDTI protocol/CarePlan and tie the per-person `example-albendazole-administration` to the community Task's output (the §11 scenario note).

* * *

> [!abstract] Bottom line (v2)
> Implementing v1's recommendations **closed both modelling tensions and four field-evidence gaps** with SUSHI-clean artifacts and worked examples — the ESPEN MDA forms now map onto the IG with no open *structural* conflict. The disaggregated treatment cube has a canonical home (`group.stratifier`), drug supplies and administrations share an ATC code, and the three non-treatment dispositions (missed / declined / contraindicated) are each first-class. What remains is **deliberately larger or deliberately out-of-scope**: the full coverage denominator/unit rework, an intervention-neutral adverse-event profile, the supervision/QA bundle, and the ingestion-pipeline enforcement of the surveillance boundary — each now carrying an explicit decision or reworded backlog entry rather than an open question.
