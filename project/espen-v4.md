---
version: 0.4.0
last_modified: 2026-06-22T19:25:05.000Z
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

# ESPEN MDA Forms ↔ ICR IG — Mapping (v4, post-v0.20.0)
<sub>`v0.4.0 · Last modified Jun 22, 2026 at 3:25 PM EDT`</sub>

⁠

> [!note] What this document is
> The current **field-by-field mapping** of the six **ESPEN NTD-MDA demo forms** (`forms/espen mda/`) onto the ICR IG **as of [[ig-info]] v0.20.0** — after building the fuller supervision bundle, the CareTeam/reporter wiring, and the adverse-event finish (the post-v3 backlog). For every form region it names the concrete IG artifact (profile · element · extension · CodeSystem · example) it lands in, and flags the residue. This supersedes [[espen-v3]]; the lineage is [[espen]] (v1) → [[espen-v2]] → [[espen-v3]] → v4. Cross-refs: [[ig-info]] (§n), [[icr-v1]].

> [!tip] Dose-pole band — answering the v3 review question (c1)
> In PC-NTD MDA the correct dose depends on **body weight**, which can't be measured door-to-door, so the distributor stands the person against a **dose pole** — a height stick marked with bands — and gives the tablet count printed for the band they reach (height as a weight proxy). Example: a child at **band B (110–124 cm)** gets **2 praziquantel tablets**; the IG records `dosePoleBand = band B` next to `dosage = 2 tablets`, so the height→dose decision is auditable. The `<90 cm` cut-off is the bottom of the pole — too short to dose — captured as `exclusion-reason = under-height-age`.

* * *

## 0. What changed v3 → v4 (IG v0.20.0)

SUSHI-clean: **17 profiles, 32 extensions, 20 CodeSystems, 23 ValueSets, 4 Measures, 1 Questionnaire, 1 ConceptMap, 39 examples** (was 17 / 28 / 18 / 20 / 4 / 0 / 0 / 38).

| Area | v3 status | v4 (now in `ig/`) |
|---|---|---|
| Supervision / QA | ◑ lightweight Observation | ✅ **structured** `ICRSupervisionReport` = `QuestionnaireResponse` over a shipped `icr-mda-supervision-checklist` Questionnaire |
| Stock-readiness / wastage (C2) | ❌ | ✅ `StockAccountability` extension on `ICRSupplyDelivery` (received/used/remaining/not-usable/returned + concordance + VVM) |
| Social-mobilization / demand | ❌ | ✅ `SocialMobilization` extension (+ `ICRCommunicationChannelCS`) on `ICRCampaign`/Task |
| Microplan / team-workload | ◑ CareTeam only | ✅ `WorkloadTarget` extension on `ICRCareTeam` (area + population/households/days) |
| Task.owner → team | ❌ display string | ✅ `ICRCampaignTask.owner` = `Reference(ICRCareTeam)` |
| Reporter accountability | ◑ MS | ✅ `MeasureReport.reporter` **1..1** (required) on both coverage profiles (§15 #7-bis resolved) |
| Adverse-event finish (C1) | ◑ profile only | ✅ seriousness bound + `SeriousCriteria` extension + WHO `IMMZ` ConceptMap; `example-aefi-serious` |
| Dose-pole band | ✅ extension | ✅ + glossed (this doc; ig-info §7.2) per the c1 review question |
| Executable CQL / structured `sample-design` (B2 remainder) | ◑ | ◑ **deferred by decision** — not in scope this round |

* * *

## 1. Verdict (TL;DR) — v4

**Every region of all six ESPEN forms now maps onto a committed, SUSHI-clean ICR artifact — including the two supervision forms that were the last large gap.** Supervision findings are a structured QuestionnaireResponse; stock/wastage, social mobilization, and team workload are first-class; "who worked this" and "who reported this" are real joins. The only **intentionally** open item is the executable-measure layer (CQL + structured `sample-design`), explicitly deferred this round. There is no longer any ESPEN data element without at least a ◑ home, and the ◑ items are now narrow (typed training counts, a standalone microplan resource, executable CQL) rather than whole missing axes.

* * *

## 2. Full form-by-form mapping

Legend: ✅ committed home · ◑ partial / refine-later · 🛑 deliberately out of model scope.

### Form 1 — Location / village registration
| ESPEN field(s) | ICR home | |
|---|---|---|
| admin cascade (`l_state…l_location`), `l_location_id` | `ICRLocation` `partOf` chain + `identifier` | ✅ |
| `l_gps` | `ICRLocation.position` | ✅ |
| `l_total_pop` | `ICRTargetPopulation` (`denominator-type = total-population`) | ✅ |
| age bands, `l_eligible_pop` | `ICRTargetPopulation` (`denominator-type = at-risk`) + age-band `characteristic` | ✅ |
| `l_recorder_id`, `l_submitting_report` | `ICRCareTeam` (recorder) / `MeasureReport.reporter` (now required) | ✅ |

### Form 2 — Medicine receipt
| ESPEN field(s) | ICR home | |
|---|---|---|
| `p_disease` | `ICRCampaign.addresses`; per-village `Task.reasonCode` | ✅ |
| `p_medicine` | `ICRCampaignActivity.product` (ATC) | ✅ |
| `p_total_<drug>` received | `ICRSupplyDelivery.suppliedItem` (ATC) **+ `stock-accountability.received`** | ✅ |

### Form 3 — Treatment reporting (core)
| ESPEN field(s) | ICR home | |
|---|---|---|
| `census_method` toggle | §7.3 individual-vs-aggregate switch | ✅ |
| `<drug>_<band>_<sex>_treated` cube | stratified `MeasureReport` (`icr-mda-treatment-coverage`): sex × age × disposition | ✅ |
| `<drug>_child`/`_pregnant`/`_breastfeeding` | `exclusion-reason` + disposition stratum | ✅ |
| `<drug>_absent` / `_refusal` | `missed-reason` / `noncompliance-reason` + disposition stratum | ✅ |
| dose-pole / height bands (incl. <90 cm) | **`dose-pole-band`** extension (see gloss above); <90 cm → `exclusion-reason = under-height-age` | ✅ |
| `p_campaign_day` | event `occurrence` / `Task.executionPeriod` | ✅ |
| `cd_who_distributed_*`, `cd_trained`, `cd_recycled` | `ICRCareTeam` participants + supervision checklist | ◑ typed training *counts* still informal |

### Form 4 — Use & case management
| ESPEN field(s) | ICR home | |
|---|---|---|
| `p_total_<drug>_dist` | reconciliation (`realtime`/`reconciled`) + **`stock-accountability.used/remaining/notUsable`** | ✅ |
| `p_minor_side_effect` / `p_serious_side_effect` | `ICRAdverseEvent` (`seriousness` + **`serious-criteria`**); `example-aefi-serious` | ✅ |
| guinea worm / leish / Buruli / LF morbidity | surveillance/morbidity store via ingestion mapping (§17.6) | 🛑 by design |

### Form 5 — Supervision (health-facility)
| ESPEN field(s) | ICR home | |
|---|---|---|
| villages total / treated / not-treated | geographic coverage (`coverage-unit = implementation-units`) | ✅ |
| reasons for non-treatment | area-level `ICRMissedReasonCS` + disposition stratifier | ✅ |
| supervisor level | `ICRCareTeam` (supervisor role) + `managingOrganization` + `oversees-area` | ✅ |
| per-drug stock remaining/expired/concordance | **`stock-accountability`** on the supply + checklist items | ✅ |
| training counts; manual used | `ICRCareTeam` + supervision checklist; **`workload-target`** for planned volume | ✅ / ◑ counts informal |
| social mobilisation (informed?, channels) | **`social-mobilization`** extension (`ICRCommunicationChannelCS`) | ✅ |
| pharmacovigilance | `ICRAdverseEvent` | ✅ |

### Form 6 — Supervision (CDD observation)
| ESPEN field(s) | ICR home | |
|---|---|---|
| whole observation checklist | **`ICRSupervisionReport`** (QuestionnaireResponse over `icr-mda-supervision-checklist`); `example-supervision-report` | ✅ |
| MDA supplies present | checklist `supplies.*` items | ✅ |
| DOC observed | `directly-observed-consumption` + checklist `cdd.doc` | ✅ |
| height chart / measuring stick | `dose-pole-band` + checklist `cdd.height-chart-used` | ✅ |
| training session (date/duration/topics) | `ICRCareTeam` / checklist | ◑ typed training element later |
| "marking concessions" | `finger-marked` | ✅ |
| who supervised / which team | `ICRSupervisionReport.author` + `ICRCareTeam`; `Task.owner` → team | ✅ |

* * *

## 3. Gap scorecard — v1 → v2 → v3 → v4

| ESPEN data | v1 | v2 | v3 | v4 | Artifact (v0.20.0) |
|---|---|---|---|---|---|
| Disaggregated treatment cube | ❌ | ◑ | ✅ | ✅ | stratified Measure + tally |
| Eligibility-exclusion reasons | ❌ | ✅ | ✅ | ✅ | `exclusion-reason` |
| ATC drug supply | ⚠️ | ✅ | ✅ | ✅ | `ICRSuppliedItemVS` |
| Area-level non-treatment | ❌ | ✅ | ✅ | ✅ | `ICRMissedReasonCS` |
| Geographic coverage | ❌ | ◑ | ✅ | ✅ | `coverage-unit` |
| Denominator total vs at-risk | ❌ | ❌ | ✅ | ✅ | `denominator-type` |
| Adverse events | ❌ | ◑ | ✅ | ✅ **finished** | `ICRAdverseEvent` + `serious-criteria` + IMMZ ConceptMap |
| Team / supervisor | ❌ | ❌ | ✅ | ✅ | `ICRCareTeam` |
| **Supervision findings (Forms 5/6)** | ❌ | ◑ | ◑ | ✅ **structured** | `ICRSupervisionReport` (QR) + Questionnaire |
| **Stock / wastage / readiness** | ❌ | ❌ | ◑ | ✅ | `StockAccountability` |
| **Social-mobilization / demand** | ❌ | ❌ | ◑ | ✅ | `SocialMobilization` |
| **Microplan / team-workload** | ❌ | ❌ | ◑ | ✅ | `WorkloadTarget` (standalone resource ◑) |
| **Task.owner → team join** | ❌ | ❌ | ❌ | ✅ | `owner` = Reference(ICRCareTeam) |
| **Reporter accountability** | ❌ | ❌ | ◑ | ✅ | `reporter` 1..1 |
| Dose-pole band | ❌ | ◑ | ✅ | ✅ + glossed | `dose-pole-band` |
| Per-village disease | ◑ | ◑ | ✅ | ✅ | `Task.reasonCode` |
| Measure definitions (§14) | ❌ | ❌ | ✅ | ✅ | 4 `Measure`s |
| Co-bundled surveillance | 🛑 | 🛑 | 🛑 | 🛑 | ingestion-mapping rule |
| Executable CQL / structured `sample-design` | — | — | ◑ | ◑ **deferred** | B2 remainder (by decision) |

**Net:** the four v3-residual axes (supervision, stock, mobilization, workload) and the two wiring gaps (owner, reporter) all closed. Remaining ◑ are narrow refinements; one (CQL/sample-design) is deferred by explicit decision.

* * *

## 4. Remaining (post-v4)

1. **Executable CQL + structured `sample-design`** (§17.2 B2 remainder) — *explicitly deferred this round*; the Measures carry placeholder CQL and `sample-design` stays a free-text string.
2. **A standalone microplan resource** — today the microplan is the `ICRCampaign` (`intent=plan`) plus per-team `WorkloadTarget`; a dedicated resource (team × area × target × schedule grid) is a possible future convenience.
3. **Typed training/workforce counts** — distributor trained/recycled counts ride CareTeam participants + checklist items rather than a typed element.
4. **Confirm the WHO `IMMZ.AdverseEvent` ConceptMap targets** against the published IMMZ IG (currently provisional), and reuse IMMZ AEFI value sets where they align (§18.3).
5. **ESPEN ingestion mapping as an artifact** — the OpenFn transform, enforcing the §17.6 surveillance-routing rule — the truest end-to-end validation.
6. **Wire `MeasureReport.reporter` to the actual `ICRCareTeam`/Organization** in production data (examples use display strings) now that owner→CareTeam exists.

* * *

> [!abstract] Bottom line (v4)
> Four rounds in, the ESPEN MDA forms map onto the ICR IG with **no remaining structural gap and no whole-axis absence** — supervision/QA, stock/wastage, social mobilization, team workload, and the owner/reporter accountability joins all landed this round, on top of the v3 coverage/adverse-event/team work. What's left is **deliberately deferred** (executable measure logic) or a **narrow convenience** (a standalone microplan resource, typed training counts) — each tracked, none blocking. The model now represents a full community-directed MDA round — registration through supervision — end to end.
