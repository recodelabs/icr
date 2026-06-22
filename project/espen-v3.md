---
version: 0.3.0
last_modified: 2026-06-22T18:58:48.000Z
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

# ESPEN MDA Forms ↔ ICR IG — Mapping (v3, post-v0.19.0)
`v0.3.0 · Last modified Jun 22, 2026 at 2:58 PM EDT`

⁠

> [!note] What this document is The **updated field-by-field mapping** of the six **ESPEN NTD-MDA demo forms** (`forms/espen mda/`) onto the ICR IG **as of [[ig-info]] v0.19.0** — after building the three big espen-v2 follow-ups (coverage formalisation, intervention-neutral adverse event, team/supervision) and the four minor fixes. Where [[espen]] (v1) found gaps and [[espen-v2]] (v2) tracked them, v3 is the **near-complete map**: for every form region it names the concrete IG artifact (profile · element · extension · CodeSystem · example) it lands in, and flags the residue. Cross-refs: [[ig-info]] (§n), [[icr-v1]].

* * *
## 0. What changed v2 → v3 (IG v0.19.0)
SUSHI-clean: **17 profiles, 28 extensions, 18 CodeSystems, 20 ValueSets, 4 Measures, 38 examples** (was 14 / 24 / 13 / 15 / 0 / 33).

| Area | v2 status | v3 (now in `ig/`) |
| --- | --- | --- |
| Stratified tally | ◑ pattern only | ✅ **rule**: 4 `Measure`s, `MeasureReport.measure` MS, `ICRCoverageStratifierCS` (sex/age-band/strategy/disposition/geography); tally upgraded |
| Denominator-type / unit (B1) | ❌   | ✅ `denominator-type` (total/at-risk) + `coverage-unit` (people/implementation-units) extensions; `example-geographic-coverage` |
| Adverse event (C1) | ◑ reworded | ✅ `ICRAdverseEvent` (intervention-neutral) + `ICRAdverseEventCausalityCS`; `record-origin` on AdverseEvent; AEFI + MDA examples |
| {==Supervision / CareTeam==}{>>What is dose-pole band mean? Can you provide an example of what this is used for?<<}{id="c1" by="mberg" at="2026-06-22T19:11:53.096Z"} | {==◑ deferred==}{>>What is dose-pole band mean? Can you provide an example of what this is used for?<<}{id="c1" by="mberg" at="2026-06-22T19:11:53.096Z"} | {==✅ first slice: `ICRCareTeam` + `ICRTeamRoleCS` + `oversees-area`; lightweight `ICRSupervisionReport`; examples==}{>>What is dose-pole band mean? Can you provide an example of what this is used for?<<}{id="c1" by="mberg" at="2026-06-22T19:11:53.096Z"} |
| {==Dose-pole band==}{>>What is dose-pole band mean? Can you provide an example of what this is used for?<<}{id="c1" by="mberg" at="2026-06-22T19:11:53.096Z"} | {==◑ free text==}{>>What is dose-pole band mean? Can you provide an example of what this is used for?<<}{id="c1" by="mberg" at="2026-06-22T19:11:53.096Z"} | {==✅ `dose-pole-band` extension==}{>>What is dose-pole band mean? Can you provide an example of what this is used for?<<}{id="c1" by="mberg" at="2026-06-22T19:11:53.096Z"} |
| Per-village disease | ◑ note | ✅ demonstrated via `Task.reasonCode` |
| Not-treated disposition | ◑ Task counts | ✅ folded into the tally as a `disposition` stratifier |
| Campaign-day | ◑ open | ✅ handled as event dates / `executionPeriod` (doc note) |

* * *
## 1. Verdict (TL;DR) — v3
**An ESPEN NTD-MDA round, across all six forms, now maps onto committed ICR artifacts end to end — registration, denominator (total *and* at-risk), supply, the disaggregated treatment cube, all three not-treated dispositions, geographic coverage, adverse events, the team, and supervision findings.** What's left is **refinement, not absence**: executable CQL behind the Measures, a structured `sample-design`, the fuller supervision/microplan/stock/social-mobilization bundle, and the deliberate surveillance-stays-out scope line. Nothing in the forms now lacks *a* home; the open items are about making the homes richer or more constrained.

* * *
## 2. Full form-by-form mapping (the centerpiece)
Legend: ✅ committed home · ◑ partial / lightweight home · 🛑 deliberately out of model scope.
### Form 1 — Location / village registration
| ESPEN field(s) | ICR home |     |
| --- | --- | --- |
| `l_state → l_district → l_health_facility → l_location` (cascade) | `ICRLocation` chain via `partOf`; types `admin-unit`/`facility`/`settlement` (`ICRLocationTypeCS`) | ✅   |
| `l_location_id` | `ICRLocation.identifier` (local) — GERS/P-code enrich on ingestion | ✅   |
| `l_gps` | `ICRLocation.position` | ✅   |
| `l_total_pop` | `ICRTargetPopulation.quantity` with `denominator-type = total-population` (v0.19.0) | ✅   |
| `I_total_popn_1_4/5_14/15_More`, `l_eligible_pop` | a second `ICRTargetPopulation` with `denominator-type = at-risk` + age-band `characteristic`; `denominator-source = microcensus` | ✅   |
| `l_recorder_id`, `l_submitting_report` | `ICRCareTeam` (recorder role) / `MeasureReport.reporter` | ✅   |
### Form 2 — Medicine receipt
| ESPEN field(s) | ICR home |     |
| --- | --- | --- |
| `p_disease` (LF/ONCHO/SCHISTO/STH/TRACHOMA) | `ICRCampaign.addresses`; per-village via `Task.reasonCode` (v0.19.0) | ✅   |
| `p_medicine` package + consistency constraints | `ICRCampaignActivity.product` (ATC); constraints = microplan validation | ✅   |
| `p_total_<drug>` received | `ICRSupplyDelivery.suppliedItem` — **ATC-coded** via `ICRSuppliedItemVS` (`example-albendazole-supply`) | ✅   |
### Form 3 — Treatment reporting (the core)
| ESPEN field(s) | ICR home |     |
| --- | --- | --- |
| `census_method` toggle | the §7.3 individual-vs-aggregate switch | ✅   |
| `census` (households/men/women) | in-round `ICRTargetPopulation` refresh / `Task.output` | ✅   |
| `<drug>_<band>_<sex>_treated` cube | **stratified** `MeasureReport` (`icr-mda-treatment-coverage`) — sex + age-band stratifiers (`example-mda-treatment-tally`) | ✅   |
| `<drug>_child`(<90 cm)/`_pregnant`/`_breastfeeding` not treated | `exclusion-reason` (`ICRExclusionReasonCS`: under-height-age/pregnant/breastfeeding) **and** the **disposition** stratifier of the tally | ✅   |
| `<drug>_absent` / `_refusal` | `missed-reason` `#absent` / `noncompliance-reason`; disposition stratum | ✅   |
| dose-pole / height bands (AZM age, <90 cm) | `dose-pole-band` extension on the administration (v0.19.0) | ✅   |
| `p_campaign_day` (Day 1–10) | event `occurrence` / `Task.executionPeriod` date (ordinal day derivable) | ✅   |
| `cd_who_distributed_*`, `cd_trained`, `cd_recycled` | `ICRCareTeam` participants (cdd role) + counts | ◑ counts not yet a typed workforce element |
### Form 4 — Use & case management
| ESPEN field(s) | ICR home |     |
| --- | --- | --- |
| `p_total_<drug>_dist` (distributed) | reconciliation: `realtime` vs `reconciled` lineage; ATC supply chain | ✅   |
| `p_minor_side_effect` / `p_serious_side_effect` | `ICRAdverseEvent` (`seriousness`); `example-mda-adverse-event` | ✅   |
| guinea worm / leish / Buruli / **LF morbidity** | surveillance/morbidity store via the **ingestion mapping** (§17.6) — *not* ICR campaign resources | 🛑 by design |
### Form 5 — Supervision (health-facility)
| ESPEN field(s) | ICR home |     |
| --- | --- | --- |
| villages total / treated / not-treated | **geographic coverage** — `coverage-unit = implementation-units` (`example-geographic-coverage`) | ✅   |
| reasons for non-treatment (insecurity, shortage, access, not-required) | area-level `ICRMissedReasonCS` codes (v0.18.0) → disposition stratifier | ✅   |
| supervisor level (National…HF) | `ICRCareTeam` (supervisor role) + `managingOrganization`; `oversees-area` | ✅   |
| per-drug stock remaining/expired/concordance | `ICRSupervisionReport` components (lightweight) | ◑ structured stock-readiness/wastage deferred (§17.2 C2) |
| training counts; manual used | `ICRSupervisionReport` components / `ICRCareTeam` | ◑ typed workforce/microplan deferred |
| social mobilisation (informed?, channels) | `ICRSupervisionReport` components | ◑ demand axis deferred (§17.3) |
| pharmacovigilance (adverse/serious) | `ICRAdverseEvent` | ✅   |
### Form 6 — Supervision (CDD observation)
| ESPEN field(s) | ICR home |     |
| --- | --- | --- |
| whole checklist (vest, greetings, height-chart, correct dosage, DOC, form completion, ineligibles, side-effect procedure) | `ICRSupervisionReport` components (`example-supervision-report`) | ✅ (lightweight) |
| MDA supplies (height chart, register, checklist, med bag) | `ICRSupervisionReport` components | ✅ (lightweight) |
| "medicine taken in presence of DC" (DOC) | validates `directly-observed-consumption`; observed via supervision report | ✅   |
| height chart / measuring stick | `dose-pole-band` (delivery) + supervision component | ✅   |
| training session (date, duration, topics) | `ICRCareTeam` / `ICRSupervisionReport` | ◑ typed training element deferred |
| "marking concessions" (house/finger marking) | `finger-marked` extension | ✅   |

* * *
## 3. Gap scorecard — v1 → v2 → v3
| ESPEN data | v1  | v2  | v3  | Artifact (v0.19.0) |
| --- | --- | --- | --- | --- |
| Disaggregated treatment cube | ❌   | ◑ pattern | ✅ **rule** | `Measure` + `ICRCoverageStratifierCS` + 3-axis tally |
| Eligibility-exclusion reasons | ❌   | ✅   | ✅   | `exclusion-reason` + disposition stratum |
| ATC on drug supply | ⚠️  | ✅   | ✅   | `ICRSuppliedItemVS` |
| Area-level non-treatment reasons | ❌   | ✅   | ✅   | `ICRMissedReasonCS` + geographic coverage |
| Geographic-coverage unit axis | ❌   | ◑   | ✅   | `coverage-unit` + `example-geographic-coverage` |
| Denominator total vs at-risk | ❌   | ❌   | ✅   | `denominator-type` (coverage + TargetPopulation) |
| Adverse events (AEFI + MDA) | ❌   | ◑ reworded | ✅   | `ICRAdverseEvent` + causality CS |
| Team / supervisor model | ❌   | ❌   | ✅   | `ICRCareTeam` + `ICRTeamRoleCS` + `oversees-area` |
| Supervision findings (Forms 5/6) | ❌   | ◑ deferred | ◑ **lightweight** | `ICRSupervisionReport` |
| Dose-pole band | ❌   | ◑   | ✅   | `dose-pole-band` |
| Per-village disease scoping | ◑   | ◑   | ✅   | `Task.reasonCode` |
| Measure definitions (§14) | ❌   | ❌   | ✅   | 4 `Measure`s |
| Stock / wastage / cold-chain | ❌   | ❌   | ◑   | lightweight only — typed axis P2 |
| Workforce/training/microplan (typed) | ❌   | ❌   | ◑   | CareTeam only — microplan P2 |
| Social-mobilization / demand axis | ❌   | ❌   | ◑   | lightweight only — axis P2 |
| Co-bundled surveillance | 🛑  | 🛑  | 🛑  | ingestion-mapping rule (§17.6) |
| Executable CQL / structured sample-design | —   | —   | ◑   | placeholder CQL; B2 remainder |

**Net:** every ESPEN data element now has at least a ◑ home; **12 items fully closed** since v1, the rest are lightweight-now / richer-later or out-of-scope by decision.

* * *
## 4. Remaining (post-v3 backlog)
These are refinements, each tracked in §17:

1. **Executable CQL + structured** `sample-design` (§17.2 B2 remainder) — the Measures carry placeholder CQL; author real logic and break `sample-design` into sub-elements; align to VCQI/IMMZ.
2. **Fuller supervision bundle** (§17.3) — a typed microplan/Team-workload resource, a stock-readiness/wastage axis (C2), a social-mobilization/demand axis, and a structured QA profile to replace the lightweight `ICRSupervisionReport` components.
3. **Wire** `Task.owner` **→** `Reference(ICRCareTeam)` — today still a display string; this makes "who worked this" and "who reported this number" real joins, and lets `MeasureReport.reporter` be promoted from MS to required (§15 #7-bis).
4. **Adverse-event finish** (§17.2 C1 remainder) — serious-criteria value set + the WHO `IMMZ.AdverseEvent` ConceptMap (§18.3).
5. **ESPEN ingestion mapping as an artifact** — the OpenFn transform, enforcing the §17.6 surveillance-routing rule; the truest validation of this whole exercise.
6. **Complete the Type-C campaign thread** — a CDTI protocol/CarePlan tying the per-person administration to the community Task (the §11 scenario note).

* * *

> [!abstract] Bottom line (v3) Three rounds in, the ESPEN MDA forms map onto the ICR IG **with no remaining structural gap**: the disaggregated treatment cube is a conformant stratified `MeasureReport` bound to a `Measure`; total-vs-at-risk and people-vs-implementation-unit coverage are first-class; adverse events are intervention-neutral; the team and supervision findings have committed homes. The residue is **depth, not coverage** — executable measure logic, a structured supervision/stock/demand bundle, `Task.owner` wiring, and the ingestion-pipeline enforcement of the surveillance boundary — each a tracked refinement rather than an open question about whether the data fits.
