# WHO-AFRO Measles Field Guide (2011) vs ICR FHIR IG — Alignment & Gap Analysis

*Source: WHO Regional Office for Africa, "Measles SIAs Planning & Implementation Field Guide" (revised April 2010, 95 pp.). Compared against the ICR (Integrated Campaign Registry) FHIR R4 IG — IG v0.1.0 / explainer v0.7.0 (UNICEF publisher; Ona + Crosscut). Page cites (p.X) are to the printed page numbers as extracted; the PDF is a single disease-specific operational guide for measles supplementary immunization activities, with substantial monitoring, mop-up, AEFI and routine-immunization-linkage content.*

---

## 1. Executive summary

This guide is the **older, disease-specific sibling** of the WHO 2016 generic SIA field guide already analysed. Its **measles-SIA mechanics map cleanly onto the ICR IG spine.** A measles SIA is a bounded mass campaign (`campaign-type = vaccination-sia`, p.10) with an explicit time-phased plan of action driven by national and district planning tables (p.18–21), a microplanning step that produces target populations, denominators, vaccine/syringe/cold-chain/team estimates (p.22–30), three coded post types — permanent-fixed, temporary-fixed/outreach, and mobile (p.23) — that line up almost exactly with the IG's `delivery-strategy` codes and Type A/B/C typology, and three distinct coverage lineages (microplan target vs daily administrative coverage vs independent RCM vs post-campaign cluster survey, §9) that vindicate the IG's invariant that planned / administrative / independent-survey lineages must never be merged. The guide explicitly warns that administrative coverage "may not reflect the reality… where the denominator… is inaccurate" (p.69) — exactly the IG's "no denominator without provenance" invariant. The IG's spine (PlanDefinition / ActivityDefinition / CarePlan / Task / Immunization / Group / Location / MeasureReport) is **adequate for the measles-SIA half** of this document.

The **most important gaps are the same surrounding axes the 2016 analysis flagged, here independently corroborated with this guide's own page cites**, plus a cluster of measles-specific surveillance content. The guide elevates as first-class concepts: **SIA type** (catch-up vs follow-up, with mop-up as a distinct post-campaign decision — p.10, 75); **vaccine wastage / vial accountability** (WMF 1.18 at 15%, wastage as a district estimate and final-report field — p.24, 88, 94); a **5-category AEFI causal classification** with timing-of-onset tables, anaphylaxis kit and reporting form (p.54–58); **supervision / QA** as structured checklists with coded indicators (p.67, Annexes I–II, p.85–86); **social mobilization / demand** as a whole subcommittee with caregiver-awareness indicators (p.59–65, 67); **zero-dose** children as a routine-program-quality signal (p.70); and **hard-to-reach / special-population** equity typology (p.31–32). None of these has an ICR profile or value set yet. This guide therefore **corroborates** the campaign-phase, SIA-type, AEFI, wastage, supervision, social-mobilization, equity, and zero-dose/defaulter candidates already raised by the 2016-SIA and RED analyses — it does not contradict them.

The **NEW, measles-specific** content is **surveillance and case-based epidemiology**: case-based surveillance with case definitions, case investigation and laboratory specimen collection (p.38, training §4.4); laboratory-confirmed cases and outbreaks (p.8); susceptibility-profile / inter-epidemic modelling that drives **follow-up-SIA timing** (p.11, the TAG interval criteria); and age-distribution-of-confirmed-cases analysis that drives target-age-group selection (p.14, 91). My judgement: **this surveillance content is a separate domain that ICR should reference, not model.** It is the *trigger* and *evaluation context* for a campaign, not campaign execution data. ICR should hold a reference/pointer (the surveillance signal that justified the SIA, the confirmed-case age distribution used to set the age target) but the case-based surveillance and lab-confirmation data belong in a VPD-surveillance IG (e.g. a measles/rubella case-surveillance profile family) that ICR links to.

**Highest-value additions** (corroborating prior analyses, justified here): (1) an **SIA-type** value set (`catch-up`, `follow-up`, `mop-up`, `outbreak-response`) distinct from `delivery-strategy`; (2) a **vaccine-wastage / vial-accountability** axis; (3) an **AEFI** profile + 5-category causal value set; (4) a **zero-dose** flag on the immunization/coverage path; (5) explicit treatment of **RCM as a pass/fail trigger instrument** (≤1/20 OK, ≥2/20 act — p.71) distinct from administrative coverage and from the cluster survey; and (6) a thin **reference** to the surveillance signal that triggers/sizes the SIA, without absorbing surveillance into the IG.

---

## 2. Where the document ALIGNS with the IG

**SIA architecture & lifecycle → ICRCampaign (CarePlan) umbrella + per-area/round CarePlans, microplan=`plan` / execution=`order`.** The guide is built around macro-planning at national level (a "budgeted macro-plan", p.18) decomposed into district micro-plans (p.20, 22), with national review/validation that "may include some upward or downward revision of the district level planning figures" (p.22). This is exactly the IG's umbrella-CarePlan → per-area child-CarePlan (`partOf`) structure, with the microplan as the `plan`-intent layer and the executed SIA as `order`. The detailed countdown planning tables (Table 2, national, p.18–19; Table 3, district, p.20–21) express a time-phased lifecycle, supporting (but not yet matched by) a campaign-phase axis.

**Campaign type & delivery strategy → `campaign-type = vaccination-sia`; `delivery-strategy` CodeSystem; Type A/B/C.** Vaccination post types are explicitly coded: **Permanent-Fixed** posts at health facilities (p.23) = `delivery-strategy = fixed-post` / `location-type = facility` (Type A); **Temporary-Fixed / outreach** posts at "schools, churches, mosques, local administrators' offices, bus depots, roadblocks, market areas, border crossing points, village squares" (p.23) = `temporary-post` / `school` / `community-distribution-point` (Type A site-based); **Mobile** posts that "move from community to community… set up… for a few hours… then move" (p.23) = `mobile` (Type A temporary). Notably the guide says it is **"currently not recommended to use the house-to-house approach"** for measles in most African countries (p.28) — confirming that the IG's `house-to-house` / `community-directed` codes (Type B/C) are correctly campaign-type-dependent and not mandatory for measles SIAs.

**Target population & denominator → ICRTargetPopulation (Group actual=false) + denominator-source + provenance.** The guide insists all planners "use the same figures" from "an official source" (p.24), that "if different population figures are available, the higher figure should be used" / "better to over-estimate" (p.24), and crucially that administrative coverage "may not reflect the reality… where the denominator… is inaccurate… common… where there is substantial population movement" (p.69). This is the IG's invariant "no denominator without provenance" almost verbatim. **Denominator sources named**: official census, census projections from old census data (p.69), and **community line-listing / household enumeration** of target children (p.24) — the latter supports adding an enumeration/line-listing denominator source (see §5). Urban/rural split of the denominator (p.24) supports target-geography/group overlays.

**Delivery events → ICRImmunizationEvent (Immunization) + ICRSupplyDelivery; one Task per visit.** Each vaccinated child is recorded on a **tally sheet** "irrespective of previous vaccination history" (p.44) — i.e. aggregate per-session counts, not a per-person register; the guide even says **"do not record doses of measles vaccine given during SIAs on childhood immunization cards"** (p.48). This strongly supports the IG's **one-Task-per-visit / per-session** model with delivery counts as outputs rather than a per-individual longitudinal record. Vaccine, diluent, AD syringes, reconstitution syringes, safety boxes are "always distributed together in matching quantities" (bundled, p.35, 53) → ICRSupplyDelivery.

**Coverage — the three-lineage separation → ICRAdministrativeCoverage vs ICRSurveyCoverage, kept separate.** The guide cleanly separates: (a) the **microplan target / line-listing target** (planned, p.69); (b) **daily administrative coverage** = tallied doses ÷ target, charted cumulatively per area (p.69, Fig.11 p.70); (c) **independent monitoring / RCM** = pass/fail "quick look", explicitly "not a survey… not scientifically valid as a means of generating… coverage figures" and "methodologically erroneous to aggregate… across a wide area and refer to it as coverage" (p.71–72); and (d) the **post-campaign cluster coverage survey** (30×7 or 40×10, probability-proportional-to-size, "within 10 percentage points of the true value", p.73) led by "an independent team not linked to the SIAs" to *validate* administrative results (p.74). This is direct, page-cited confirmation of the IG invariant that **planned / administrative / independent-survey lineages must never be merged**, and that `coverage-source` distinguishes `administrative`, `survey`, `lqas`/`rcm`. The guide even equates RCM to "the lot quality assurance method" (p.71) → `coverage-source = lqas`/`rcm`, `sample-design`.

**Geography → ICRLocation admin hierarchy + operational geography overlay.** National → province/region → district → sub-district → post (p.18–23) is an admin hierarchy (`partOf`); microplanning mandates **mapping** of service-delivery posts, high-risk areas and stakeholders "as an essential part of the district micro-planning process" (p.23) — operational geography overlaid on admin units, the IG's "operational geography OVERLAYS admin" invariant.

**Record-origin firewall → `record-origin = campaign` vs `routine`.** The guide is emphatic that SIA doses are **campaign** doses, separate from routine: "do not record doses… given during SIAs on childhood immunization cards" (p.48); the SIA dose is "an extra dose" and a child turning 9 months during the SIA should "still receive their routine measles vaccine one month after the SIAs dose" (p.64). Chapter 11 ("Using the SIAs to reinforce routine immunisation", p.78–81) treats the two as linked-but-distinct streams. This is exactly the IG's mandatory `record-origin` campaign/routine boundary.

**Data lineage realtime vs reconciled → one structure.** Daily provisional administrative coverage during the SIA (p.69, the operations-control-room daily summaries, p.50) vs the post-campaign compiled/validated coverage and the cluster survey (p.74, 92) maps to the IG's `data-lineage = realtime | reconciled`.

**Integration with Vitamin A / deworming / ITN / OPV / TT → `campaign-type = integrated`.** The guide explicitly covers integrated SIAs delivering "Vitamin A, de-worming medicine, insecticide treated Bednets (ITNs), and oral polio vaccine" and TT for women (p.16), with a per-station flow (screening → Vitamin A + Mebendazole → measles → tally, Fig.8 p.46) and a **triage/screening card** to mark eligibility per intervention (p.17, Fig.5). This is the IG's `integrated` campaign type, ICRMedicationAdministration (Vit A, mebendazole), ICRSupplyDelivery (ITN), multiple ActivityDefinitions under one Campaign, and the triage card → an eligibility-screening artifact. Vitamin A is given to 6–59 months while measles targets 9 months–5/14 years (p.63–64) — different per-intervention target populations under one umbrella, which the IG models with per-activity ICRTargetPopulation.

---

## 3. Gaps & divergences

### 3a. Things the document requires that the IG does NOT yet represent

- **SIA type as a coded axis distinct from delivery strategy (real gap; corroborates 2016).** Catch-up SIA ("one-time… all children under 15", p.10) vs follow-up SIA ("every 2–4 years… reduce build-up of susceptibles", p.10) are first-class planning decisions with different target-age logic (p.11, 14). **Mop-up** is a further distinct post-campaign decision (Ch.10, p.75) driven by a decision matrix. ICR's `campaign-type = vaccination-sia` captures the intervention but not the SIA *strategic type*. Recommend a `sia-type` value set (§5).

- **Campaign-phase / time-phased lifecycle (real gap; corroborates 2016, weaker form).** Unlike the 2016 guide, this 2010 guide has **no formal "readiness assessment dashboard"**, but it does encode a strict countdown lifecycle in the national and district planning tables (6–8 months / 6–7 / 6 / 4–5 / 4 / 3 months / 8–1 weeks / day-of / daily / 1 week–1 month after — p.18–21) and weekly coordination monitoring of preparations (p.68). The IG has CarePlan status but no coded `campaign-phase`. Recommend a `campaign-phase` CodeSystem (planning / preparation / pre-implementation / implementation / mop-up / post-evaluation) (§6).

- **Vaccine wastage & vial accountability (real gap; corroborates 2016).** WMF = 100/(100−wastage); 15% → 1.18 used for ordering, with the balance going to routine (p.24); average measles SIA wastage "less than 10%" (p.24); "estimate vaccine coverage & wastage in district" is a district post-SIA step (p.21, 88); wastage is a final-report field (#22, p.94) and a post-campaign-review item (p.82). No ICR wastage/commodity-accountability axis. Recommend a wastage/vial-accountability extension or profile (§6).

- **AEFI surveillance (real gap; corroborates 2016 & RED).** A whole chapter (Ch.7, p.54–58): the **5-category causal classification** — programmatic/immunization error, vaccine reaction, coincidental, injection reaction, unknown (Table 4, p.54); **timing-of-onset → AEFI-type table** (anaphylaxis <24h, severe local/abscess/sepsis <5d, seizures/encephalopathy 6–12d, thrombocytopenia 15–35d — Table 5, p.55); **cluster detection** "by location… within a brief period… by vaccine or by type of reaction" (p.55); minimal case data set (site, vaccinee name/age/sex/address, date/time of vaccination, onset, detection — p.55); the **AEFI kit** (adrenaline, hydrocortisone, etc., p.56) and a standard **AEFI case investigation form** (Annex IV). No ICR AEFI profile or causal value set. Recommend an AEFI profile (AdverseEvent/Observation) + `aefi-causal-type` value set (§6).

- **Supervision / quality-assurance structured data (real gap; corroborates 2016 & RED).** Pre-campaign and intra-campaign **supervisory checklists** with coded Yes/No items and computed indicators: "% of districts with operational funds ≥7 days before", "% of sites with no shortfalls of vaccines and devices", "% of sites where used syringes are placed in safety boxes", "% of sites where tally sheets are filled correctly", "% of sites where vaccinators know AEFI reporting" (p.67); full checklists in Annex I (p.85) and Annex II (p.86). The IG has no supervision/QA profile family. Recommend Observation/MeasureReport supervision profiles (§6).

- **Social mobilization / demand / communication (real gap; corroborates 2016 & RED).** An entire chapter (Ch.8, p.59–65) plus a SMC subcommittee, advocacy targets, KAP studies / communication needs assessment (p.62), and a caregiver-awareness pre-campaign indicator: "proportion of caretakers who can identify the target disease, campaign dates, venues and age groups" (p.67); RCM also captures "source of information about the SIAs" (p.72, Annex V). No ICR demand/social-mobilization axis. Recommend (optional) a demand/awareness Observation axis (§6).

- **Hard-to-reach / special-population equity typology (real gap; corroborates RED).** A 13-item taxonomy of underserved groups: disproportionate-burden, urban/peri-urban under-immunized, poor-sanitation, mountainous-terrain, nomadic, undocumented urban settlers/squatters, migrant workers, refugees/IDPs/transient, marginalized/minority, religious-objection groups, civil-unrest areas, near-border, and affluent gated communities (p.31). The IG has `location-type = settlement` but **no population-vulnerability/equity axis** to code *why* a delivery unit/area is hard-to-reach. Recommend a `population-vulnerability` value set (§6).

- **Zero-dose identification (real gap, small; corroborates RED).** "If the tally sheets include provisions for identifying 'zero-dose' children, i.e., children receiving measles vaccination for the first time during the SIAs, the proportion of zero dose children is a strong indicator of the quality of the routine programme, and of the ability of the SIAs to 'reach' previously un-reached populations" (p.70). The IG has no `zero-dose` flag on the immunization/coverage path. Recommend an `eligible-present`-adjacent or coverage-stratifier zero-dose flag (§5/§6).

- **Mop-up decision logic & age-misclassification check (real gap, partly a Measure-definition concern).** The mop-up decision matrix (Table 6, p.76) combines **SIA administrative coverage** (<90 / 90–95 / ≥95%) × **routine coverage** (<60 / ≥60%) → a coded decision. The guide also warns of **age misclassification inflating coverage** ("children beyond 4 years… being vaccinated in SIAs targeting 9–47 months… look at the coverage data broken down into smaller age categories", p.75). These imply (a) a coded operational-decision axis akin to RED's access-vs-utilization category, and (b) age-band-stratified coverage Measures. Recommend age-band stratifiers on coverage Measures and a mop-up-decision code (§6).

### 3b. Things the IG models that the document treats differently (or contradicts)

- **Per-person record vs per-visit Task — agreement, with a hard constraint.** The guide is *more* aggregate than the IG: it explicitly forbids recording SIA doses on individual cards (p.48) and tallies anonymously (p.44). This **confirms** the IG's one-Task-per-visit / persons-on-output design and warns against any expectation of a per-person measles-SIA register. *Modelling alignment, not a gap.*

- **`house-to-house` not recommended for measles (modelling choice, not contradiction).** p.28 discourages house-to-house for measles; the IG offers it as a code but ties strategy to campaign type. *Not a gap — confirms delivery-strategy is context-dependent.*

- **RCM as pass/fail, NOT a coverage rate (already partly modelled; needs explicit guidance).** The IG has `coverage-source = rcm` and `sample-design`, but the guide is emphatic RCM is a **trigger** (≤1 unvaccinated of 20 → verify with 10 more; ≥2 of 20 → act/mop-up; Annex V: >2 of the 3–5 assessments → mop-up — p.71, 89), not an estimate, and must **never be aggregated into coverage** (p.72). The IG should state that an RCM MeasureReport carries a pass/fail + trigger threshold, not a coverage proportion. *Real-but-acknowledged refinement (corroborates 2016).*

- **Surveillance / outbreak-response content — separate domain, ICR should reference (key judgement).** The guide carries genuine surveillance content: the strategy rests on "epidemiologic surveillance with laboratory confirmation of cases and outbreaks" (p.8); **case-based surveillance** training covers "case definitions, case investigation and specimen collection procedures" and "tools for specimen collection and case reporting" (p.38); susceptibility-profile/inter-epidemic modelling and the **TAG interval criteria drive follow-up-SIA timing** (p.11); and the **age distribution of confirmed measles cases/deaths drives the target age group** (p.14, 91 — "Adequate analysis of surveillance data… description of investigated outbreaks"). **Judgement:** this is a *separate VPD-surveillance domain*. It is the trigger and the evaluation backdrop for an SIA, not SIA execution data. ICR should **reference** it (a pointer from the Campaign to the surveillance signal / outbreak that justified it, and to the confirmed-case age distribution used to set the age target) but should **not model** case-based surveillance, lab specimens, or case classification. Those belong in a measles/rubella case-surveillance IG that ICR links to. (This guide notably does **not** describe outbreak-response SIAs in operational detail — it is built around preventive catch-up/follow-up SIAs — so outbreak-response-SIA mechanics are a use case neither this guide nor the IG fully covers; see §7.)

---

## 4. Terminology comparison

| Measles guide term (p.X) | ICR IG equivalent | Aligns / Varies / Missing | Note |
|---|---|---|---|
| Supplementary Immunization Activity / mass campaign (p.10) | `campaign-type = vaccination-sia` | Aligns | Core mapping. |
| Catch-up SIA (p.10) | — | Missing | New `sia-type` axis. |
| Follow-up SIA (p.10) | — | Missing | New `sia-type` axis. |
| Mop-up vaccination (p.75) | — (per-area CarePlan) | Missing | New `sia-type` / phase; targeted revaccination round. |
| Rolling / split SIA (p.15) | per-area CarePlans (`partOf`) | Varies | Geography modelled; "rolling" not a coded type. |
| Permanent fixed post / health facility (p.23) | `delivery-strategy = fixed-post`; `location-type = facility` | Aligns | "Permanent = health facility". |
| Temporary fixed / outreach post (school, church, market, border) (p.23) | `temporary-post` / `school` / `community-distribution-point` | Aligns | Maps to several location types. |
| Mobile post (p.23) | `delivery-strategy = mobile` | Aligns | "set up… few hours… move". |
| Mobile-fixed site (p.33) | `mobile` + `temporary-post` | Aligns | Hybrid; expressible. |
| House-to-house (discouraged for measles) (p.28) | `delivery-strategy = house-to-house` | Aligns (context) | IG code exists; not used for measles. |
| Target population / eligible age group (p.14) | ICRTargetPopulation (Group actual=false) | Aligns | 9 mo–14 yr (catch-up) / 9–59 mo (follow-up). |
| Age bands 9 mo / 6 mo / 9–35 / 9–47 / 9–59 mo / <15 yr (p.11, 14) | age stratifiers on Group / Measures | Varies | Age logic present; needs coded age-band stratifiers. |
| Denominator / official population figures (p.24) | `denominator-source` (census, census-projection) | Aligns | "use higher figure / overestimate". |
| Community line-listing / household enumeration (p.24) | `denominator-source` | Missing value | Add `enumeration`/`line-listing`/`microcensus` (microcensus exists). |
| Administrative coverage (daily, cumulative) (p.69) | ICRAdministrativeCoverage (`coverage-source = administrative`) | Aligns | Daily + cumulative time series. |
| Rapid Convenience Monitoring (RCM), 20-child quick look (p.70–72) | `coverage-source = rcm`; `sample-design` | Aligns (varies) | Pass/fail trigger, NOT a coverage rate. |
| Lot Quality Assurance analogy (p.71) | `coverage-source = lqas` | Aligns | RCM "equated to LQA method". |
| Post-campaign cluster survey (30×7 / 40×10, PPS) (p.73) | ICRSurveyCoverage (`coverage-source = survey`) | Aligns | Independent, validates admin coverage. |
| Zero-dose children (first-ever measles dose) (p.70) | — | Missing | New `zero-dose` flag/stratifier. |
| Vaccine wastage / WMF 1.18 (p.24) | — | Missing | New wastage/vial-accountability axis. |
| Vaccine Vial Monitor (VVM) stage (p.51) | — | Missing | Cold-chain/commodity observation (with wastage). |
| AEFI 5 causal categories (p.54) | — | Missing | New AEFI profile + `aefi-causal-type` value set. |
| Anaphylaxis / severe AEFI by onset timing (p.55) | — | Missing | AEFI severity/onset attributes. |
| Suspected / clinical measles case, lab-confirmed, outbreak (p.8) | out of scope | Missing → reference | Separate VPD-surveillance domain. |
| Case-based surveillance / specimen collection (p.38) | out of scope | Missing → reference | Separate surveillance IG. |
| Confirmed-case age distribution (drives age target) (p.14, 91) | reference only | Missing → reference | Surveillance input to ICRTargetPopulation. |
| Missed/unvaccinated child + reasons (p.71, Annex V) | `missed-reason` / `noncompliance-reason` | Aligns (partial) | Reasons列 uncoded here; "unaware"/"post-too-far" not in IG. |
| Refusal / resistant group / religious objection (p.31, 65) | `noncompliance-reason` (refusal/religious-objection/misinformation) | Aligns | Maps well. |
| Hard-to-reach / special populations (13 types) (p.31) | `location-type = settlement` (only) | Missing | No population-vulnerability/equity axis. |
| Supervisory checklist / supervision indicators (p.67, Annex I/II) | — | Missing | New supervision/QA profile. |
| Social mobilization / caregiver awareness (p.59, 67) | — | Missing | New demand/awareness axis (optional). |
| Triage / screening card (integrated SIA) (p.17) | eligibility-screening artifact | Varies | Per-intervention eligibility marking. |
| Operations control room / daily monitoring (p.50, 69) | CarePlan + realtime data-lineage | Aligns | Realtime monitoring stream. |
| Record origin: SIA dose ≠ routine card (p.48, 64) | `record-origin = campaign` | Aligns | Strong confirmation of the firewall. |

---

## 5. Proposed terminology additions (flag for the IG)

**Corroborating prior-flagged additions (this guide's cites):**

- **NEW value set `sia-type`** (or extension on ICRCampaignProtocol/Campaign): `catch-up`, `follow-up`, `mop-up`, `outbreak-response`. Justified p.10 (catch-up/follow-up), p.75 (mop-up). *Corroborates 2016.* (`outbreak-response` is named in principle (p.8) though not operationalized here — see §7.)
- **To `denominator-source` CodeSystem:** add `enumeration` / `line-listing` (community household line-listing of target children, p.24) and `campaign-results` (using prior SIA results to sanity-check the denominator, implied p.24). `microcensus` already exists and covers the microcensus case. *Corroborates RED.*
- **To `missed-reason` CodeSystem:** add `unaware-campaign` (RCM captures "source of information about the SIAs" and social-mobilization gaps as a reason, p.67, 72, Annex V) and `post-too-far` (distance to post is an actionable, distinct miss vs `inaccessible`; p.31 hard-to-reach distance). *Corroborates 2016's RCM-reason analysis (this older guide's reason list is uncoded — p.89 — so these are inferred from text, not a printed code list).*
- **NEW `zero-dose` stratifier/flag** on the immunization/coverage path: a child receiving measles vaccine "for the first time during the SIAs" (p.70). Distinct from `eligible-present`; a routine-program-quality and reach indicator. *Corroborates RED.*

**Distinct NEW (measles-specific, judged reference-vs-model in §6):**

- **NEW `aefi-causal-type` value set** (for an AEFI profile): `programmatic-error` / `immunization-error`, `vaccine-reaction`, `coincidental`, `injection-reaction`, `unknown` (Table 4, p.54). *Corroborates 2016's AEFI flag with this guide's own 5-category cite.*
- **Surveillance terms (DO NOT add to ICR core — reference only):** suspected/clinical measles case, lab-confirmed, epi-linked, outbreak, confirmed-case age distribution (p.8, 14, 38). These belong in a referenced surveillance IG, not an ICR CodeSystem (§6, §7).

---

## 6. Categories / value sets worth adding

**Belongs IN ICR (campaign execution):**

- **`sia-type`** (recommend ADD) — see §5. Conditions target-age logic and round semantics.
- **`campaign-phase`** (recommend ADD) — `planning`, `preparation`, `pre-implementation`, `implementation`, `mop-up`, `post-evaluation`, from the planning tables (p.18–21) and chapter structure. Conditions which data are expected at each time-point.
- **Vaccine wastage / commodity accountability** (recommend ADD) — WMF and per-site/per-team vials received/opened/discarded/returned + VVM stage (p.24, 51, 88). Cross-cutting: supports ICRSupplyDelivery, ICRMedicationAdministration and ICRImmunizationEvent (vaccines, Vit A, mebendazole, ITN).
- **AEFI profile + `aefi-causal-type`** (recommend ADD) — AdverseEvent/Observation with onset-timing and serious-AEFI criteria (Ch.7, p.54–58). Reusable across all injectable/oral campaign types.
- **Supervision / QA** (recommend ADD, scoped) — Observation/MeasureReport profiles for the coded supervisory-checklist indicators (p.67, Annex I/II). High value for campaign managers.
- **`zero-dose` stratifier** (recommend ADD, small) — p.70.
- **Coverage-Measure age-band stratifiers + mop-up-decision code** (recommend ADD) — age-disaggregated coverage to catch age-misclassification (p.75) and a coded mop-up decision from the Table 6 matrix (p.76, admin-coverage × routine-coverage). Aligns with the IG's acknowledged "Measure definitions aligned to WHO reporting minimums" gap.

**Belongs IN ICR but lower priority / optional:**

- **`population-vulnerability` / special-population** value set (p.31) — equity axis as a Group characteristic. *Corroborates RED.*
- **Social-mobilization / demand / caregiver-awareness** Observation axis (p.59–67). *Corroborates 2016 & RED.*

**Belongs in a REFERENCED surveillance IG (NOT ICR):**

- **Measles case classification** (suspected / clinical / lab-confirmed / epi-linked), **case-based surveillance**, **lab specimen / confirmation**, **outbreak** entities, **confirmed-case age/vaccination-status distribution**, and **susceptibility-profile / inter-epidemic interval** modelling (p.8, 11, 14, 38). ICR should hold only a *reference* from the Campaign to the surveillance signal/outbreak that triggered or sized it, and to the case-age-distribution input used for the target age group — not the case data itself.

---

## 7. Use cases not yet identified in the IG

- **Outbreak-response SIA triggered by surveillance (out of full ICR scope — reference the trigger).** The strategy names "laboratory confirmation of cases and outbreaks" (p.8) but this preventive-SIA guide does **not** operationalize outbreak-response SIA mechanics (target-area drawn from the outbreak, compressed timeline). FHIR: an ICRCampaign (CarePlan) with `sia-type = outbreak-response`, `basedOn`/`supportingInfo` pointing at a **surveillance signal in a referenced surveillance IG** (DetectedIssue / Condition / a measles-outbreak resource). *In ICR scope: the campaign + the reference pointer. Out of scope: the case/lab data behind the trigger.*

- **Follow-up-SIA timing driven by susceptibility/interval modelling (reference, not model).** The TAG interval criteria (p.11) and WHO/UNICEF coverage estimates (p.11) decide *when* the next SIA runs. FHIR: ICRCampaignProtocol (PlanDefinition) can record the decision; the **inputs** (susceptibility profile, routine + prior-SIA coverage) are surveillance/coverage analytics ICR references. *Mostly out of scope; ICR references the result.*

- **Confirmed-case-age-distribution → target-age-group selection (reference input to ICRTargetPopulation).** "the age breakdown of confirmed measles cases and deaths should… be taken into consideration to determine the extent of measles follow-up SIAs" (p.14). FHIR: ICRTargetPopulation age bands set from a referenced surveillance analysis. *In scope: the resulting age-banded target. Out of scope: the case data.*

- **Post-campaign coverage survey + RCM as two distinct instruments (IN scope; partly modelled).** The independent cluster survey (ICRSurveyCoverage, `survey`, p.73) *validates* administrative coverage; RCM (`rcm`/`lqas`, p.70–72) is a pass/fail field-trigger, never aggregated to coverage. FHIR: two MeasureReport families with distinct `coverage-source` and explicit guidance that RCM carries pass/fail, not a rate. *In ICR scope.*

- **Mop-up round triggered by low coverage (IN scope).** The mop-up decision matrix (p.76) → a new per-area CarePlan (`partOf` the umbrella) with `sia-type = mop-up` / `campaign-phase = mop-up`, driven by an ICRAdministrativeCoverage + RCM read. *In ICR scope; needs `sia-type`/`campaign-phase`.*

- **AEFI during a measles SIA (IN scope as referenced profile).** Anaphylaxis / abscess / cluster detection during the campaign (Ch.7) → an AEFI profile (AdverseEvent/Observation) linked from the ICRImmunizationEvent and Campaign. *In ICR scope; needs the AEFI profile + causal value set.*

- **Zero-dose hand-off to routine immunization (IN scope, thin).** Areas/children identified as zero-dose or missed during the SIA are "targeted by the routine immunisation program through regular outreach services beyond the SIAs" (p.81, 70). FHIR: a `zero-dose` stratifier + a referral/hand-off (the `record-origin` firewall keeps the routine follow-up distinct). *In ICR scope.*

---

## 8. Bottom line

**The ICR IG is adequate for the measles-SIA half of this guide.** Every core mechanic — SIA macro/micro-planning, the three post types (fixed/temporary/mobile), bundled supply delivery, anonymous per-session tally (one Task per visit, persons on output), the campaign-vs-routine record-origin firewall, the strict separation of microplan-target / administrative-coverage / RCM-trigger / independent-cluster-survey lineages, denominator-with-provenance, operational-geography-over-admin mapping, and integration with Vitamin A / deworming / ITN / OPV / TT — maps onto the IG spine and *vindicates the IG's design invariants with direct page cites* (esp. p.24, 48, 64, 69, 71–74).

**In-scope vs reference:** the **execution** content is in ICR scope (and exposes the same surrounding-axis gaps the 2016 and RED analyses already flagged — SIA-type, campaign-phase, wastage, AEFI, supervision, social-mobilization, equity, zero-dose, mop-up). The **surveillance / case-based / lab-confirmation / outbreak / susceptibility-modelling** content (p.8, 11, 14, 38) is a **separate VPD-surveillance domain that ICR should reference, not model** — ICR holds the pointer from a Campaign to the surveillance signal/outbreak that triggered or sized it and to the confirmed-case age distribution that set the target age group, and nothing more. Notably, this preventive-SIA guide does not itself operationalize outbreak-response SIAs, so that workflow is under-specified in *both* documents.

**Top recommended IG changes (in priority order):**
1. Add a **`sia-type`** value set (`catch-up`, `follow-up`, `mop-up`, `outbreak-response`) and a **`campaign-phase`** axis — the two cleanest, most-corroborated gaps (p.10, 75, 18–21).
2. Add a **vaccine-wastage / vial-accountability** axis (WMF, vials received/opened/discarded/returned, VVM) spanning SupplyDelivery / Immunization / MedicationAdministration (p.24, 51, 88).
3. Add an **AEFI profile + `aefi-causal-type` 5-category value set** with onset-timing/severity (p.54–58).
4. Add **supervision/QA** Observation/MeasureReport profiles, a **`zero-dose`** stratifier, and **age-band-stratified coverage Measures** with a coded **mop-up-decision** (p.67, 70, 75–76); make explicit that an **RCM MeasureReport is pass/fail, not a coverage rate** (p.71–72).
5. Define a thin **reference mechanism** from ICRCampaign to an external surveillance IG (trigger signal / outbreak / confirmed-case age distribution) rather than absorbing surveillance into ICR (p.8, 14, 38).

*Uncertainties:* (a) several Annex figures (Annex III unsafe-practices, Annex VI session set-up, the triage card Fig.5, RCM/AEFI flowcharts) are images that pdftotext could not render, so a few coded reason-lists may exist in those annexes that I could not read — the RCM reason column (Annex V, p.89) is a blank table here, so the "unaware"/"post-too-far" `missed-reason` additions are inferred from body text (p.31, 67, 72), not a printed code list (unlike the 2016 guide's explicit p.191 list). (b) This is the **April 2010 revision** (cover says "Revised April 2010"; the supplied filename says "April 2011") — predating the 2016 generic guide; where the two differ, the 2016 guide is the more authoritative source for generic SIA structure, and this guide is authoritative for measles-specific surveillance linkage.
