---
version: 0.1.0
last_modified: 2026-07-03T12:50:04.000Z
tags:
  - icr
  - fhir
  - ig
  - forms
  - gap-analysis
public: true
comments: true
---

# UNICEF Campaign Forms — Analysis against the ICR IG
`v0.1.0 · Last modified Jul 3, 2026 at 8:50 AM EDT`

> [!note] What this document is A form-by-form analysis of the ten UNICEF campaign forms in `forms/unicef/`, mapped against the draft **[[icr-ig|ICR FHIR Implementation Guide]]** (`project/icr-ig.md`, v0.1.0). Each section states what the form captures, maps its data elements onto ICR profiles / extensions / code systems, and flags alignment, conflicts, and proposed IG changes. The **[[#Aggregate findings]]** at the bottom consolidates the cross-form signal. Where a form element points at an IG item already labelled **(proposed)** in §13, that is noted — the forms are, in effect, a field-evidence test of the IG's own roadmap.
## The corpus at a glance
All ten forms are **polio SIA** artifacts — nine Kenya (nOPV2 outbreak response, `KEN-2024-11-01_nOPV`, Round 2) plus one Ghana (mOPV2 reactive campaign, 2019). Seven are Enketo/ODK digital forms (rendered from `enketo.whonghub.org`); three are Excel tally sheets. They fall into four functional families:

| Family | Forms | Primary ICR home |
| --- | --- | --- |
| **Delivery tally** (doses given) | TallySHeet.xlsx, Tally sheets_Combined.xls, Ghana Form 4 | `Task.output` → stratified `ICRAdministrativeCoverage` |
| **Vaccine stock / wastage** | Form A (Type 2), Consumption monitoring tool | `ICRSupplyDelivery` + `stock-accountability` ext |
| **Independent monitoring** (RCM / LQAS) | Inside Household, Outside House, LQA Data Collection | `ICRSurveyCoverage` (rcm / lqas) |
| **Readiness & supervision** | Preparedness Validation, Team Supervision Checklist | `ICRSupervisionReport` (QuestionnaireResponse) + readiness gap |

Two identity elements recur on every form and map cleanly: **Response Name** (`KEN-2024-11-01_nOPV`) → `ICRCampaign` identity, and **Round #** (`Rnd2`) → `ICRCampaign.extension[campaignRound]`. `antigen` (nOPV) + `doses_per_vial` (50) are protocol/activity content (`ICRCampaignActivity.product[x]`, CVX).

* * *
## 1. KEN SIA Form A for Type 2 Vaccines
**What it is.** An **end-of-round vaccine-stock accountability** form for Type 2 (nOPV2) vaccine, filled once per round per health structure at each level of the health pyramid (National / County / Sub-County / Facility), with cascading reporting deadlines (2/5/7/14 days). It reconciles usable and unusable vials across the round.

**Key elements.** Administration level; country → county → sub-county → facility; Vaccine Accountability Monitor; GPS; total children vaccinated; usable vials at start / received / resupplied / transferred / distributed / received-from-lower-level; unusable vials received / physically counted / disposed on site; theoretical vs physical stock; **Wastage Factor** and **Wastage Rate**; discrepancy checks.

**ICR mapping.**

- The vial flow maps to `ICRSupplyDelivery` with the `stock-accountability` extension (`received` / `used` / `remaining` / `notUsable` / `returned` + `concordant` + `vvmStage`) — §6.3. `record-origin = campaign` is mandatory.
- **Wastage Factor / Rate** and theoretical-vs-physical reconciliation are a derived quantity → an `ICRAdministrativeCoverage`-style `MeasureReport` (a wastage Measure), not a raw field. The IG notes deriving a wastage Measure from WHO `IMMZ` (§13.3) — this form is the concrete driver.
- `doses_per_vial` **(50)** is needed to convert vials↔doses for wastage; ICR has no explicit doses-per-vial field on `ICRCampaignActivity` / `ICRImmunizationEvent`.
- Health-pyramid level + reporting deadlines → `ICRLocation` hierarchy (`partOf`) and `MeasureReport.reporter` / `period`.

**Alignment & gaps.**

- ✅ `stock-accountability` fields are a near-exact match — strong validation of §6.3.
- ⚠️ **Multi-level stock transfer chain** (facility→team, district→facility, region→district, national→region) is a *flow between levels*. `SupplyDelivery` models a single `destination`; the round's cascading transfer/return reconciliation is a MeasureReport concern, and the "transferred to another facility/district/region" concept has no dedicated field. Document the aggregation pattern.
- ⚠️ `doses_per_vial` and **wastage factor/rate** — propose a small campaign/activity field for doses-per-vial and a canonical **wastage Measure** (currently only implied).
- ✅ VVM handled by `stock-accountability.vvmStage`.

* * *
## 2. KEN SIA Type 2 Vaccine Consumption Monitoring Tool
**What it is.** The **daily** sibling of Form A — one summary form per service point per day, totalling all vaccination teams, filled when teams collect vaccine in the morning and return it in the evening. Adds cold-chain observation.

**Key elements.** Same identity block; GPS; **temperature maintained +2–8 °C?**; **any vials at VVM discard point (stage 3/4)?**; usable vials at start / received / transferred / given to teams / returned; unusable vials returned; total children vaccinated (day); usable & unusable vials physically counted end-of-day; wastage factor / rate; discrepancy checks.

**ICR mapping.**

- Daily vial issue/return → `ICRSupplyDelivery` + `stock-accountability` at day granularity, `dataLineage = realtime`.
- **Cold-chain checks** (fridge temperature, VVM discard) → `ICRSupervisionReport` (QuestionnaireResponse), matching the supervision checklist's cold-chain items, and/or `stock-accountability.vvmStage`.
- "Usable vials given to teams" / "returned from teams" → the facility→team level of the same transfer chain as Form 1.

**Alignment & gaps.**

- ✅ Reinforces the `stock-accountability` design and the realtime/reconciled split (this is the realtime feed; Form A is the reconciled close-out — a clean worked example of `dataLineage`, §7.2).
- ⚠️ **Cold-chain / temperature monitoring** has no dedicated ICR home. Today it lands as free `QuestionnaireResponse` items. §13.2 lists "a cold-chain/logistics/stock-readiness axis beyond SupplyDelivery" as a candidate — this form supports that.
- ⚠️ Same doses-per-vial / wastage-Measure gap as Form 1.

* * *
## 3. KEN SIA Outside House Monitoring Form
**What it is.** **Rapid Convenience Monitoring (RCM)** at *outside-house* congregation points (markets, bus stations, water points, schools, churches). A monitor checks children 0–59 months at convenient sites for finger-marks. Repeats per site.

**Key elements.** Level of monitoring (large monitor-org list: AFINET, Africa CDC, AFRO, BMGF, CDC Partner, Independent Monitor, STOP Team, UNICEF/WHO officers, …); in-process vs end-process monitoring; country → county → sub-county → ward → settlement; **settlement type** (Urban / Rural / Slums / Refugees-IDP / Hard-to-Reach / Nomads-Pastoralists / Security-Compromised / Immigrants / Cross-Border); GPS; place of evaluation (Market / Bus Station / Play Area / Water Point / School / Street / Hospital / Church-Mosque); **Total Children Checked** and **Total Children Finger Marked** (0–59 months).

**ICR mapping.**

- Checked / finger-marked pass-rate → `ICRSurveyCoverage` with `coverage-source = rcm` (§7.2), the never-merge-with-administrative lineage. `reporter` carries the monitor / monitor-org.
- Place of evaluation → `ICRLocation.type` (extensible ICRLocationTypeVS — `community-distribution-point`, `temporary-post`; market/bus-station/water-point are local extensions).
- Finger-mark check → the field-level analogue of `Task.extension[fingerMarked]`.

**Alignment & gaps.**

- ✅ RCM is explicitly modelled as its own survey lineage (§7.3) — good match; the IG even notes RCM is pass/fail against a trigger, not a rate, which this form embodies.
- ⚠️ `settlement type` (a vulnerability / special-population taxonomy) recurs across most forms and has **no ICR home**. Candidate: a **population-vulnerability / equity** characteristic (§13.2 proposed) or an `ICRLocation` characteristic.
- ⚠️ **In-process vs end-process monitoring** is a monitoring-timing axis distinct from realtime/reconciled — not captured. Consider a coded axis on survey coverage.
- ⚠️ **RCM pass/fail semantics** (trigger threshold) are still proposed (§13.2 "explicit RCM/LQAS semantics"); this form is direct evidence.

* * *
## 4. KEN SIA Inside Household Monitoring
**What it is.** **House-to-house RCM** — 10 eligible households sampled per village (eligible = has 0–59-month children). The richest reason-taxonomy form in the corpus, repeated ten times.

**Key elements (per household).** Team visited? House properly marked? Children 0–59m present; eligible children vaccinated with finger-mark; where vaccinated (marketplace / playground / roadside / river crossing / water point / farm / church / busstop / shopping centre / school); **reasons not vaccinated** H1–H7 (Absent / Refusal / Not visited / House not revisited / Asleep / **Child vaccinated in routine** / Other); **absence sub-reasons** I1–I8 (play areas / market / school / farm / social event / travelling / parent not home / other); **refusal sub-reasons** J1–J9 (religious / vaccine side effects / too many doses / child sick / not decision maker / **"Africa is polio free"** / **concerns about nOPV** / concerns about COVID-19 / other); caregiver informed? how (community leader / health worker / IEC / mob van / social media / newspaper / radio / religious leader / school / social mobilizer-CBV / TV / volunteer CHW / other); **AFP surveillance** (any child <15 with limb weakness in last 6 months? count aware of in last 4 weeks); caregiver name + phone. Settlement summary: total missed children; "poorly covered area?" (Yes if >4 missed → notify supervisor).

**ICR mapping.**

- Coverage read-out → `ICRSurveyCoverage` (`coverage-source = rcm`).
- Reason axes map to the three ICR reason extensions on `Task`/coverage: `missed-reason` (absent, sleeping, not-visited, insecurity…), `noncompliance-reason` (religious-objection, safety-concern, no-felt-need, campaign-fatigue, misinformation), `exclusion-reason` (contraindication). House marking / finger-mark → `Task` field extensions.
- Caregiver-awareness → `social-mobilization` extension (`populationInformed` + `channel`, ICRCommunicationChannelVS).
- AFP limb-weakness → **surveillance, out of ICR scope** (§13.2 reference-don't-model).

**Alignment & gaps.**

- ✅ Strong validation of the three-axis reason design (missed / noncompliance / exclusion) and of the social-mobilization channel model.
- ⚠️ **Reason-code reconciliation needed** (already a §13.2 proposal, now field-proven):
  
  - "**Child vaccinated in routine**" is a *disposition*, not a miss → `record-origin = routine` / an `already-vaccinated` disposition (§13.2 "split out non-missed dispositions").
  - "**House not revisited**" and the revisit workflow → the follow-up `Task` pattern.
  - **Disease-specific misinformation** ("Africa is polio free", "concerns about nOPV", "too many doses/rounds" = campaign-fatigue, "not decision maker") are more specific than `ICRNoncomplianceReasonCS`. Extensible binding absorbs them, but the ICR set should be extended / ConceptMapped to the WHO RCM field list.
- ⚠️ **Channel list** — the form's awareness sources (health worker, religious leader, social mobilizer/CBV, mobile messaging/social media, newspaper, TV, IEC materials, mob van/PA, volunteer CHW, neighbour) exceed `ICRCommunicationChannelCS` (radio, town-criers, community-leaders, schools, posters, megaphone, sms, other). Expand the CS.
- ⚠️ **Modeling mismatch:** awareness here is captured *per household in a survey*, whereas ICR's `social-mobilization` lives on `CarePlan`/`Task` (the campaign side). In RCM this is survey-observed demand, not campaign-declared — arguably belongs as a survey-coverage stratifier/observation, not the campaign extension.
- ⚠️ **AFP co-bundling** — confirms §13.2's warning: the ingestion transform must route limb-weakness data to a surveillance store, not into ICR campaign resources.
- ⚠️ **Trigger rule** ("poorly covered if >4 missed") is exactly the RCM pass/fail trigger the IG proposes to make explicit (§13.2).

* * *
## 5. KEN SIA LQA Data Collection Form
**What it is.** **Lot Quality Assurance Sampling (LQAS)** — per lot, 6 clusters, 10 children per cluster, with a systematic house-skip rule (leave 1 house if <20 houses, 2 if more). Child-level (not household-level) capture.

**Key elements.** Country → county → sub-county → ward → settlement; sub-county **LOT number**; **cluster number** (1–6); surveyor + LQAS coordinator; settlement type (same 9-way taxonomy); starting-settlement <20 houses?; GPS; per child (×10): under-5 children seen belonging to HH; **age in months** (0–59); **sex**; **finger marked for OPV?**; reason finger not marked (absent / non-compliance-refusal / house not visited / vaccinated not marked / asleep / visitor / other) → refusal & absence sub-reasons; caregiver informed + how; **total OPV doses received from birth**; AFP awareness (any AFP case in last 2 months? count).

**ICR mapping.**

- LQAS accept/reject → `ICRSurveyCoverage` with `coverage-source = lqas`; `sample-design` carries the lot/cluster design (the IG's proposed structured `sample-design`: method, clusters, PSU/EA, sample size — §13.2 — is exactly this).
- Per-child **age / sex** → `ICRPatient.birthDate` / `gender` (both mandatory, §5.4) and MeasureReport stratifiers (sex, age-band).
- **OPV doses received from birth** → dose history; `Immunization.protocolApplied` (dose number/series) partially covers it; feeds zero-dose / fully-immunized logic.

**Alignment & gaps.**

- ✅ LQAS as a distinct independent-coverage source (excluded from administrative) is a direct fit for `ICRIndependentCoverageSourceVS`.
- ⚠️ **Structured** `sample-design` (lot / cluster count / skip rule / sample size) is still a free-text string in v0.1 — this form is the reason to build the structured sub-elements (§13.2).
- ⚠️ **"OPV doses from birth"** motivates a **dose-history / zero-dose** representation and the multi-dose **"fully-immunized" Measure** (§13.2 proposed dosing-regimen).
- ⚠️ Visitor ("Child is a visitor") is a residency disposition with no ICR code.

* * *
## 6. KEN SIA Preparedness Validation
**What it is.** A **pre-campaign readiness checklist** validated at ward/operational level. Entirely pre-execution — the one form with *no* delivery or coverage data.

**Key elements.** Four sections of Yes/No/NA checks: **I. Microplan** (MP document available? HTRA/special-population strategies? sketch maps? budget/cost? tally sheets arrived on time? funds on time? admin/partner commitment? activity plan/schedule?); **II. Cold Chain/Logistics** (fridge +2–8 °C? freezing capacity? VVM discard-point vials? supplies on time — days-to-campaign; adequate vaccine & droppers / markers & bags / chalk / tally sheets / vaccine carriers / masks & sanitizer / transport?); **III. Social Mobilization** (functional committee? activity plans? announcements started? HTRA targeted? stakeholders informed? plans on schedule?); **IV. Trainings** (supervisors/teams & social-mobilizers trained separately? small groups ≤30? agenda covers rationale / mapping-cold-chain-VVM / marking / recording-tally-supervision / IEC / vaccine retrieval / AFP sensitization / demonstrations?).

**ICR mapping.**

- Structurally a `QuestionnaireResponse` — the same shape as `ICRSupervisionReport` (§4.6), but scoped to *readiness*, not in-campaign supervision. No ICR profile targets the pre-campaign phase.
- Microplan/HTRA/sketch-map/budget items relate to the microplan (`ICRCampaign` at `intent = plan`, `ICRCareTeam.workload-target`) but as **readiness assertions**, not plan content.
- Cold-chain/logistics readiness → the proposed cold-chain axis (§13.2).

**Alignment & gaps.**

- ❗ **Biggest structural gap in the corpus.** ICR has **no campaign-phase / readiness model**. §13.2 proposes exactly "a campaign-phase/readiness lifecycle with a **readiness MeasureReport**" — this form is the strongest single piece of field evidence for it.
- ⚠️ Interim home: a readiness `QuestionnaireResponse` (extend the supervision-checklist pattern with a readiness Questionnaire) plus a readiness `MeasureReport` for the roll-up ("% of wards validated ready").
- ⚠️ **"Tally sheets / funds / supplies arrived on time"**, **"days to campaign supplies arrived"** — logistics-readiness timing, no ICR field.
- ✅ HTRA / special-population focus reappears — reinforces the vulnerability-taxonomy gap.

* * *
## 7. KEN SIA Team Supervision Checklist
**What it is.** **In-campaign team supervision** ("quick assessment for action"), per team per supervision day. The direct analogue of the IG's shipped MDA supervision checklist, but for a polio SIA vaccination team.

**Key elements.** **Team type** (House-to-House / Fixed Post) — a delivery-strategy discriminator; team number; supervision day (Day 1–5 / Mop-Up 1–2); geography; supervisor type (same monitor-org list); GPS; team trained? complete members (**1 vaccinator + 1 recorder**)? ≥1 person from the locality? spacing/PPE/COVID items; **daily movement plan? filled for all 5 days? maps? interpret maps?**; **houses correctly marked?**; **finger marked per guideline?**; **household vaccinations recorded during visit?**; **children vaccinated correspond to doses used?**; enough vaccine & droppers? dropper changed per vial? vials recorded on tally sheet? VVM phase I/II? interpret VVM? ice packs / foam pad / heat exposure; correct drops per child? supervisor present today? households aware before arrival? routine-EPI reminder? handwashing reminder? asked about AFP? Auto-summary flags (not trained / no movement plan / no map / not marking / insufficient doses / tally mismatch / not asking AFP).

**ICR mapping.**

- Direct fit for `ICRSupervisionReport` (QuestionnaireResponse, §4.6) — extend the shipped `icr-mda-supervision-checklist` with an **SIA/vaccination supervision** Questionnaire (supplies / team observation / cold-chain-VVM / recording / social mobilization sections). Coded `linkId`s make "% of teams with dose-tally concordance" a query.
- **Team type** → `delivery-strategy` (house-to-house / fixed-post); team composition → `ICRCareTeam.participant.role` (vaccinator, recorder — both in ICRTeamRoleCS).
- **Movement plan / maps / target for the day** → `ICRCareTeam.workload-target` (targetArea, targetDays) + operational geography (`ICRLocation` supervisory-area).
- **"Children vaccinated correspond to doses used"** → stock-vs-tally concordance (`stock-accountability.concordant`).

**Alignment & gaps.**

- ✅ Excellent alignment — this is essentially the vaccination-side twin of the MDA supervision checklist the IG already ships. Validates the supervision-bundle design (§4.6) across campaign types.
- ⚠️ Ship (or scaffold) a **vaccination/SIA supervision Questionnaire** alongside the MDA one; the two share structure but differ in items (dropper/VVM/drops vs dose-pole/DOC).
- ⚠️ **"At least one person from the locality"**, **PPE/COVID items** — local checklist items; extensible via Questionnaire, no profile change.

* * *
## 8. TallySHeet.xlsx (nOPV2 Outbreak-Response Tally)
**What it is.** A **delivery tally sheet** for cVDPV2 outbreak response. Front sheet = dose tally; back sheet = **missed children recording form**.

**Key elements.** Header: date / district / zone / facility / site name / health worker / **type of site** (Static / Outreach / House-to-House / Cross-Border Point) / team number / total & daily target / participating staff (recorder / mobilizers / vaccinators). **Dose tally** by **age band** (0–11m, 12–59m, 5–9y) × **sex** (M/F) × **prior-dose status** (**Never received nOPV2** / **Previously received nOPV2** / **No Recall/No information**), tallied by crossing out zeros. **Vaccine & Supplies** (nOPV vials, droppers, received / additional received / returned usable / returned unusable / total returned / batch number). **Surveillance** (suspected AFP cases). **Cross-Border Vaccinations**. Back: missed-children register (head of HH / village-landmark / phone / children not home / reason / refusal reason / revisit date / **outcome of revisit**: already vaccinated / vaccinated by team / still missing).

**ICR mapping.**

- The multi-dimensional tally (age × sex × prior-dose × site-type) → `Task.output` **aggregate + stratified** `ICRAdministrativeCoverage` **MeasureReport** (§7.3, the drug×sex×age "cube" — here vaccine×sex×age×dose-status). This is the canonical home for disaggregated tallies.
- Type of site → `delivery-strategy` (Static=fixed/temporary-post, Outreach=**outreach (proposed)**, House-to-House, Cross-Border=temporary-post at a border point).
- Vaccine & supplies → `ICRSupplyDelivery` + `stock-accountability` + batch → lot (`Immunization.lotNumber`).
- Missed-children register + revisit → **follow-up** `Task` (`for = Patient`, `focus = originating Task`), with revisit outcome as a disposition.

**Alignment & gaps.**

- ✅ The stratified-MeasureReport pattern (§7.3) is exactly right for this cube.
- ❗ **Prior-dose / zero-dose status** (Never / Previously / No-recall nOPV2) is a **first-class tally axis with no ICR representation.** This is the single most consistent gap across the tally forms. §13.2 proposes a "defaulter/dropout/**zero-dose** disposition with a dropout Measure and hand-off to routine immunization" — propose a `dose-history` **/** `zero-dose-status` **stratifier axis** (add to `ICRCoverageStratifierCS`, currently sex / age-band / delivery-strategy / disposition / geography).
- ⚠️ **Cross-border vaccination** as its own line item → an **outreach/cross-border delivery strategy** (§13.2 `outreach`) or a coverage disposition.
- ⚠️ **Revisit outcome** (already-vaccinated / vaccinated-by-team / still-missing) — a follow-up disposition set not yet coded.
- ⚠️ AFP line → surveillance, route out (as §4).

* * *
## 9. Tally sheets_Combined.xls (Kenya MOH Polio Tally — Form HH + OHH/SS)
**What it is.** The **official Kenya MOH** polio-campaign tally (Disease Surveillance & Response Unit, v. 12 Sep 2023). Front = in-household (Form HH); back = **outside-household / special-strategy** (OHH/SS); with summary totals, vaccine balance, and AFP surveillance.

**Key elements.** Header identity + **settlement type** (Ordinary / Urban slums / Refugees-IDP / Nomad-Pastoral / Security-compromised / Others-cross-border-immigrants). **Household tallies** (households visited incl. those without children). **Vaccination tallies** by **age band** (0–11m, 12–59m, **60–119m**) × **zero-dose vs not-zero-dose** (zero-dose = >2 wks old & never received OPV; not-zero = ≤2 wks or previously received) — lettered columns A–H. **Section G summary totals**; **Section H vaccine balance** (issued vials / unopened received / retrieved from team / additional received / returned: unopened-usable stage 1-2 / spoilt stage 3-4 / opened; total returned; VVM stages). **Back page**: special strategies — **Areas Outside Household** (playgrounds / streets / schools / markets / hotels / food distribution), **Fixed Health Facility**, **Water Points**, **Transit Points → Bus Stations**, **Border Crossing Points** — each with the same age×zero-dose grid. **Section I: AFP surveillance line-list** (name / age / sex / village / guardian phone).

**ICR mapping.**

- Household count → `ICRDeliveryUnit` roster / `Task.output`; the household is the Type-B unit.
- Age × zero-dose tally → **stratified** `ICRAdministrativeCoverage` (as §8).
- Special-strategy back page → `ICRLocation.type` (community-distribution-point, facility, temporary-post) + `delivery-strategy` (outreach/mobile), each site's tally as a strategy-stratified sub-report.
- Vaccine balance / VVM → `ICRSupplyDelivery` + `stock-accountability` (received / used / returned / notUsable / vvmStage) — a very close match.
- AFP line-list → surveillance store, route out.

**Alignment & gaps.**

- ✅ Confirms the delivery-unit + stratified-MeasureReport + stock-accountability trio end to end on a real national instrument.
- ❗ **Zero-dose vs not-zero-dose** is here a *primary* tally split (columns B–G) — again unrepresented in ICR (see §8). Note the polio-specific rule ("**>2 weeks old**" defines eligibility for zero-dose) — country business logic that would live in a Measure/CQL, not the profile.
- ⚠️ **Special-strategy site typology** (water points, transit/bus, border crossing, food-distribution) exceeds `ICRLocationTypeCS`; extensible binding absorbs it but the set should grow, and an `outreach` strategy (§13.2) is needed for the umbrella.
- ⚠️ **Settlement-type** taxonomy recurs — same vulnerability-taxonomy gap.
- ⚠️ **Households visited including those without children** — a denominator-completeness count (microplan enumeration) that maps loosely to `houses-visited` / `task-origin` (field-registered), but "visited but no eligible" has no clean code.

* * *
## 10. Ghana — Form 4 — Vaccination Team Tally Sheet (2019)
**What it is.** A **per-team daily tally** for the 2019 Ghana **mOPV2** polio outbreak reactive campaign (4–7 Sep 2019). Row-per-place-of-visit structure (vs the crossing-out grids of the Kenya sheets).

**Key elements.** Region → district → sub-district → town/community; team no/name; sheet n-of-m; supervisor phone; **house markings** (completed / partially completed); **target for the day**; VVM interpretation guide (stages 1–4). Per-row: **sequential no. / place of visit (house, school, market) / no. of children 0–59m usually living there / doses to 0–11m / doses to 12–59m** — with a separate **ZERO DOSE** sub-block and sub-totals / grand total. **Revisit register** (house/landmark / children to revisit / date / children vaccinated during revisit). **AFP** (child with limb weakness in last 4 weeks → landmark for supervisor). **Logistics** (mOPV2 bottles received / returned: empty / partially used / unopened VVM 1-2 / unopened VVM 3-4 / total / difference). **Vaccination team roster** (members + signatures). Page 2: **documentation of supervisor contacts** (name / level: International-National-Regional-District-Sub-district / time / observations / sign).

**ICR mapping.**

- Per-place-of-visit rows → one `ICRCampaignTask` **per visit** with `for` = household / site, `location` = ICRLocation, and dose counts on `Task.output`; **"children usually living there"** → a micro-denominator (`ICRTargetPopulation` / `quantity`).
- Zero-dose block → the same zero-dose axis (§8/§9).
- House markings (completed / partial) → `Task.status` (completed vs in-progress) + `finger-marked` / marking extensions.
- Logistics bottles + VVM → `ICRSupplyDelivery` + `stock-accountability`.
- Team roster → `ICRCareTeam.participant`; supervisor-contact log → supervision QuestionnaireResponse / Provenance.

**Alignment & gaps.**

- ✅ Cleanest illustration of the **one-Task-per-visit + micro-denominator** pattern (§4.4, §5.2); "children usually living in place of visit" is a per-site denominator with provenance.
- ❗ **Zero-dose** again a dedicated tally block — cross-country (Kenya + Ghana) confirmation of the gap.
- ⚠️ **"Partially completed" house marking** — a partial-visit status between requested/in-progress/completed; consider guidance.
- ⚠️ Supervisor-contact log (multi-level, timed) → maps to Provenance / a light supervision record; no dedicated ICR shape.
- ⚠️ Confirms **cross-model reuse**: an ATC/CVX-agnostic tally shape that is identical in spirit to the Kenya sheets — supports the IG's single-`ICRCampaignTask` convergence.

* * *
## Aggregate findings
### How the forms align with ICR
The corpus is a strong **positive validation** of the IG's core design. Every form maps onto existing ICR profiles without needing a new *base* resource, and several IG design bets are confirmed by real instruments:

1. **The three coverage lineages, never merged (§7).** The corpus cleanly separates **administrative tally** (forms 8–10) from **independent monitoring** — RCM (forms 3–4) and LQAS (form 5) — exactly the `administrative` / `rcm` / `lqas` split, with the never-merge value set (`ICRIndependentCoverageSourceVS`) doing real work.
2. **Realtime vs reconciled (§7.2).** The daily consumption tool (form 2) is the realtime feed; the end-of-round Form A (form 1) is the reconciled close-out — a textbook `dataLineage` pair.
3. **Stock accountability (§6.3).** The `stock-accountability` extension (received/used/remaining/notUsable/returned + concordant + vvmStage) matches the vaccine forms almost field-for-field.
4. **Stratified MeasureReport for tally cubes (§7.3).** Every tally sheet is a sex × age-band (× site-type) cube → the stratified `ICRAdministrativeCoverage` pattern.
5. **One Task per visit + micro-denominator (§4.4/§5.2).** The Ghana row-per-visit sheet is the pattern made literal.
6. **Supervision bundle (§4.6).** The Team Supervision checklist is the vaccination twin of the shipped MDA supervision checklist.
7. **Three-axis reason model + social mobilization (§4.4).** The Inside-Household reason trees populate `missed` / `noncompliance` / `exclusion` and the `social-mobilization` channels.
8. **Campaign / round / delivery-strategy identity.** Response Name → `ICRCampaign`, Round
  
  # → `campaignRound`, team type / site type → `delivery-strategy`.
### Conflicts & tensions
- {==**Disease-agnostic campaign typing vs a polio-first reality (§9 open question).** All ten forms are polio, keyed by **antigen** (nOPV2/mOPV2) and **round**, and the polio programme treats "polio campaigns" as a first-class thing. This is not a modelling error in ICR — `type = vaccination-sia` + `addresses = polio` + CVX handles it — but it reinforces the IG's own flagged need to get **polio-programme sign-off** on querying `campaign-type = vaccination-sia AND addresses = polio`==}{>>We need to keep disease agnostic and define with codes not add specific things into the data model. The core hting is can we handle with the core data model with codes / extensions.  I think the addresses approach is fine if that's the best FHIR way to do it.<<}{id="c1" by="mberg" at="2026-07-03T14:47:10.856Z"}.
- **Social-mobilization placement.** The RCM forms observe awareness *per child/household in a survey*, while ICR's `social-mobilization` extension sits on `CarePlan`/`Task` (campaign-declared). Survey-observed demand arguably belongs as survey-coverage data, not the campaign extension — a placement decision to document.
- **AFP surveillance co-bundling.** Six forms carry AFP/limb-weakness items on the same submission as tally/monitoring data. This does **not** conflict with the IG's reference-don't-model boundary (§13.2) — it *confirms* it — but it makes the boundary an **ingestion-transform requirement**, not a form property: the pipeline must split surveillance rows to a VPD store.
### Proposed IG changes (ranked by field-evidence strength)
| #   | Proposed change | Evidence | IG status |
| --- | --- | --- | --- |
| 1   | {==**Zero-dose / prior-dose-status axis** — add a coded dose-history / zero-dose stratifier (extend `ICRCoverageStratifierCS`; pair with a dropout/fully-immunized Measure)==}{>>approved<<}{id="c2" by="mberg" at="2026-07-03T14:49:46.103Z"} | Forms 4, 5, 8, 9, 10 (Kenya **and** Ghana; a *primary* tally split) | Proposed §13.2 — **now field-proven, promote** |
| 2   | {==**Readiness / campaign-phase model** — a readiness Questionnaire + readiness `MeasureReport` for the pre-campaign phase==}{>>Sure let's cature that<<}{id="c3" by="mberg" at="2026-07-03T14:50:13.983Z"} | Form 6 (whole form); readiness items in forms 1–2, 7 | Proposed §13.2 — **strongest single driver** |
| 3   | **RCM/LQAS explicit semantics** — pass/fail + trigger threshold (not a rate); structured `sample-design` (lot/cluster/skip-rule/sample-size) | Forms 3 ("poorly covered if >4 missed"), 4, 5 (6 clusters × 10) | Proposed §13.2 |
| 4   | {==**Reason-code reconciliation** — extend missed/noncompliance sets to WHO RCM field lists; split non-missed dispositions (`already-vaccinated`/`vaccinated-in-routine`, `visitor`, revisit outcomes); add disease-specific misinformation codes==}{>>Sounds good<<}{id="c4" by="mberg" at="2026-07-03T14:50:46.218Z"} | Form 4 (H/I/J trees), forms 8–10 (revisit outcomes) | Proposed §13.2 |
| 5   | {==**Vulnerability / special-population taxonomy** — settlement type (urban-slum / refugee-IDP / nomad-pastoralist / security-compromised / cross-border / immigrant / hard-to-reach) as a Location or population characteristic==}{>>yes.  would this be an extension?<<}{id="c5" by="mberg" at="2026-07-03T14:50:56.486Z"} | Forms 3, 4, 5, 9 (recurring 9-way list) | Proposed §13.2 (population-vulnerability/equity) |
| 6   | `outreach` **/ special-strategy + site typology** — an `outreach` delivery strategy and location types for water-point / transit-bus / border-crossing / food-distribution | Forms 3, 8, 9 (OHH/SS back pages) | Proposed §13.2 (`outreach`) |
| 7   | **Cold-chain / logistics-readiness axis** — temperature, supply-timeliness, doses-per-vial, wastage-factor/rate | Forms 1, 2, 6, 7 | Proposed §13.2 (cold-chain axis) |
| 8   | **Wastage Measure + doses-per-vial** — canonical wastage `Measure` and a doses-per-vial field to convert vials↔doses | Forms 1, 2 (Wastage Factor/Rate, `doses_per_vial`) | Implied via IMMZ alignment §13.3 |
| 9   | **Monitoring-timing + monitor-org** — in-process vs end-process monitoring axis; monitor-organization list on `reporter` | Forms 3, 4, 6, 7 (In/End process; 20+ monitor orgs) | New — minor |
| 10  | **Communication-channel expansion** — add health-worker / religious-leader / social-mobilizer-CBV / social-media / newspaper / TV / IEC / mob-van / volunteer-CHW / neighbour to `ICRCommunicationChannelCS` | Forms 4, 5 | New — extensible today |
### Bottom line
Nothing in these ten forms **contradicts** the ICR IG's architecture; the forms sit on the existing profiles. What they surface is a **prioritised, field-validated roadmap**: the single clearest gap is **zero-dose / prior-dose status** (a primary tally axis in five forms across two countries, and still only *proposed* in §13.2), followed by a **readiness/preparedness model** (an entire form with no ICR home). Both are already on the IG's §13.2 list — this analysis moves them from "proposed" to "evidenced." The remaining items (RCM/LQAS semantics, reason-code reconciliation, vulnerability taxonomy, outreach strategy, cold-chain axis) are refinements the extensible bindings can absorb in the interim but that should be scheduled for a drafting round.

*Sources:* `forms/unicef/` *(10 forms) compared against* `project/icr-ig.md` *v0.1.0 ([[icr-ig]]). PDFs extracted via* `pdftotext -layout`*; Excel via* `openpyxl`*/*`xlrd`*.*
