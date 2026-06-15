# WHO EYE Strategy / Yellow Fever PMVC vs ICR FHIR IG — Alignment & Gap Analysis

Sources: the WHO *EYE Strategy 2023 Highlights* brief (local PDF), two peer-reviewed PLOS papers on PMVC impact and YF outbreak potential, the WHO yellow-fever fact sheet, and the WHO/EYE coverage-monitoring and ICG-stockpile guidance found via search. Compared against the ICR FHIR R4 IG (ICR IG v0.1.0 / explainer v0.7.0; publisher UNICEF, built by Ona + Crosscut).

---

## 1. Executive summary

The ICR IG models the **mechanics** of a yellow-fever (YF) preventive mass vaccination campaign (PMVC) well. A YF PMVC is a single-dose, all-age (commonly 1–60 years) supplementary immunization activity, and the IG already names exactly this case: the `campaign-type` code `vaccination-sia` is defined as "delivering vaccines: measles–rubella, polio, HPV, **yellow fever PMVC**, OCV" (codesystems.fsh). The campaign→round spine (ICRCampaign / ICRCampaignProtocol / ICRCampaignActivity / ICRCampaignTask), the immunization delivery event with CVX coding (ICRImmunizationEvent), the configurable age-band denominator (ICRTargetPopulation, a `Group actual=false` whose `characteristic` is documented as "Age band, sex, eligibility rule, geography"), the denominator-provenance discipline, the firewall between administrative and survey coverage, and the geospatial location identity all map cleanly onto how EYE describes and reports PMVCs.

The gaps are the same **programme-semantics gaps** that prior sibling analyses (OCV/GTFCC, NTD-MDA, measles, WHO-SIA) already flagged, and YF corroborates every one of them strongly. (1) **Activity-type taxonomy.** EYE is built on an explicit four-activity-type model — routine infant immunization, preventive mass vaccination campaigns (PMVCs), preventive catch-up campaigns, and reactive outbreak campaigns — and the 2023 Highlights brief reports each separately (e.g. ">704,000 people protected via campaigns in Africa (preventive & reactive)", "~17.4m by reactive vaccination", ">184,000 children via routine immunization"; Sudan ran a "yellow fever catch-up campaign combined with measles"). The IG has **no activity-type / SIA-type axis**: `record-origin` only distinguishes campaign vs routine, and there is no way to label a campaign instance PMVC vs catch-up vs reactive. This is the single highest-value addition and is now confirmed across YF, OCV, measles and generic SIA.

(2) **Coverage targets as data.** EYE coverage benchmarks (interim 50% by 2022, 2026 target 60–80%, of the 1–60y population) are explicit, citable programme parameters used in modelling (PGPH 1003781). The IG stores only *achieved* coverage (ICRAdministrativeCoverage / ICRSurveyCoverage) — there is no **coverage-target** element to hold the planned denominator-relative goal. (3) **ICG stockpile + campaign-list reconciliation.** YF reactive campaigns draw from a 6-million-dose global emergency stockpile released by the International Coordinating Group (ICG); the 2023 brief logs "Four requests were approved … from the ICG", and the PLOS Medicine impact study had to *reconcile its campaign list against ICG records* to ensure completeness. The IG's ICRSupplyDelivery has no **stockpile-source / ICG-allocation / request-to-delivery** axis, and there is no first-class campaign-list reconciliation concept. (4) **Dosing regimen.** YF is single-dose-lifelong; the IG has no dosing-regimen element to distinguish that from multi-dose schedules (OCV, HPV). (5) **Risk-based geographic targeting.** EYE PMVCs are placed by sub-national risk ranking (RAWG outputs); the IG can record *where* a campaign runs but not the *risk-tier rationale* that selected it.

Bottom line: the IG is **structurally adequate but semantically thin** for YF. Nothing about a YF PMVC breaks the model; the missing pieces are coded axes that turn the campaign record into something that can be analysed and reconciled the way EYE actually works. Because every one of these gaps is now corroborated by multiple campaign types, they should be treated as cross-cutting IG priorities rather than YF-specific extras.

---

## 2. Where the document ALIGNS with the IG

| EYE / YF concept (source) | ICR IG artifact | Note |
|---|---|---|
| PMVC is a vaccine SIA targeting "all or most age groups in a specific area" (PLOS Med 1003523) | `campaign-type#vaccination-sia` — its definition literally names "yellow fever PMVC" (codesystems.fsh) | Direct, intentional alignment; no new top-level type needed for a *plain* PMVC. |
| Campaign with multiple rounds / multi-year delivery — e.g. Uganda "multi-year PMVC", DRC PMVC "combined with measles" (Highlights p.2–3) | ICRCampaign (CarePlan umbrella) + rounds `partOf`; ICRCampaignProtocol / ICRCampaignActivity | Round structure and umbrella/round nesting fit multi-year and integrated campaigns. |
| Per-person vaccine dose delivered, YF vaccine | ICRImmunizationEvent (Immunization, CVX) | CVX carries the YF vaccine code; one event per dose. |
| All-age targeting 1–60y; vaccinate ≥9 months, caution >60y (PGPH 1003781; WHO fact sheet) | ICRTargetPopulation (`Group actual=false`), `characteristic` = "Age band, sex, eligibility rule, geography" | Configurable age bands — see §3 (a) for the validation: bands are open, so 1–60y works; the only risk is an implicit under-5 default elsewhere. |
| Denominator = target population with a source; EYE coverage computed against it | ICRTargetPopulation `quantity` + `denominatorSource` (1..1) + `isPlanningDenominator`; `denominator-source` codes {census, census-projection, microcensus, worldpop, grid3, hmis, other} | Strong fit; provenance is mandatory (invariant 4). |
| EYE reports administrative coverage AND Post-Campaign Coverage Surveys (PCCS) separately; reactive-campaign coverage survey guidance (Highlights p.6; WHO 9789240090514) | ICRAdministrativeCoverage and ICRSurveyCoverage kept as distinct profiles; `coverage-source` {administrative, survey, lqas, rcm} | Aligns with EYE's own admin-vs-survey separation; `survey` + `lqas` cover the cluster-survey / LQAS methods in the coverage guidance. |
| Sub-national geographic placement of campaigns; cross-border risk (Highlights p.5,7) | ICRLocation (admin `partOf` + operational geography + GERS / P-code) | Geospatial identity supports district-level targeting and cross-border analysis. |
| Distinguishing campaign delivery from routine infant immunization (Highlights p.2: ">184,000 children via routine immunization" vs campaign totals) | `record-origin` {campaign, routine} + firewall invariant | Captures the campaign/routine split — but NOT the finer PMVC/catch-up/reactive split (§3). |
| Realtime field totals vs later reconciled figures ("best estimates … to be confirmed in late 2024", Highlights p.2) | `data-lineage` {realtime, reconciled} | Matches EYE's "best estimate now, confirmed later" reporting cadence. |

---

## 3. Gaps & divergences

### 3a. Things the document requires that the IG does NOT yet represent

1. **Activity-type / SIA-type taxonomy (routine / PMVC / catch-up / reactive)** — **REAL GAP (corroborates prior).** EYE is explicitly organised around four activity types and the 2023 brief tallies them separately: PMVC (Nigeria 18.7m, DRC 29.6m), reactive/RVC (Niger 221k, ~17.4m total Africa), preventive catch-up (Sudan "yellow fever catch-up campaign", LAC "multi-antigen regional catch-up campaigns"), and routine infant immunization (>184k children). PLOS papers separate the same buckets when computing coverage ("routine infant vaccination, reactive campaigns, PMVCs"; PLOS Med 1003523 / PGPH 1003781). The IG cannot label a campaign instance as PMVC vs catch-up vs reactive — `record-origin` only gives campaign-vs-routine. Prior OCV/measles/SIA analyses already flagged an `sia-type` axis; YF makes it a four-value taxonomy.

2. **Coverage-target as stored data** — **REAL GAP (corroborates prior).** EYE targets are explicit, citable numbers: "50% — interim 2022 target (set in 2018) as a minimum/worst-case", "60% — lower bound of 2026 target", "80% — upper bound … WHO recommendation: coverages >80% with a 60–80% security threshold necessary to interrupt transmission" (PGPH 1003781). These are *planning inputs*, distinct from achieved coverage. The IG has no coverage-target element — only ICRAdministrativeCoverage / ICRSurveyCoverage (achieved). Corroborates the OCV/measles coverage-target gap.

3. **ICG stockpile-source / allocation / request-to-delivery axis** — **REAL GAP (corroborates prior).** Reactive YF campaigns draw from the 6-million-dose Gavi-funded global emergency stockpile released by the ICG; access requires an application to the ICG Secretariat (WHO Geneva) or a member agency (IFRC/MSF/UNICEF). The 2023 brief: "Four requests were approved … from the ICG: CAR (two requests, eight districts), Guinea (one district), Niger (one district)"; "~1.2 million doses shipped to outbreaks in 2023." ICRSupplyDelivery has no field to record stockpile source, the ICG request/approval, or the request-to-delivery turnaround. Corroborates the OCV stockpile-source flag.

4. **Campaign-list reconciliation** — **REAL GAP (NEW, YF-sharpened).** The PLOS Medicine study had to reconcile its assembled PMVC list against ICG records: "the resulting list of vaccination campaigns was compared with data from the WHO ICG … and discrepancies were resolved" — which "virtually ensured completeness." This is a *cross-source dataset reconciliation* concern (which campaigns happened, where, when), distinct from per-record `data-lineage`. The IG has no construct for reconciling a campaign *roster* against an authoritative external list. Sharper here than in any prior sibling.

5. **Dosing regimen (single-dose lifelong)** — **REAL GAP (corroborates prior).** WHO fact sheet: "A single dose provides lifelong immunity and no booster is needed." The IG has no dosing-regimen element to encode single-dose-lifelong vs multi-dose (relevant when YF sits in an `integrated` campaign alongside multi-dose antigens, or vs OCV's two-dose schedule). Corroborates OCV dosing-regimen flag.

6. **Risk-based geographic targeting rationale** — **REAL GAP (NEW).** EYE places PMVCs by sub-national risk ranking from the Risk Analysis Working Group (RAWG): "top-ranking countries for risk: Nigeria, Cameroon, DRC, Ghana, Uganda…"; PLOS defines PMVC areas as "high-risk based on disease circulation … or risk assessment" (PLOS Med 1003523); outbreak potential keyed to effective reproduction number R>1 (PGPH 1003781). The IG records *where* a campaign runs but not the *risk tier / outbreak-potential rationale* that selected the geography — i.e. a `campaign-trigger` / risk-targeting axis. Partly overlaps the prior "campaign-trigger (reactive vs preventive)" flag.

### 3b. Things the IG models that the document treats differently (or contradicts)

- **`record-origin` campaign/routine vs EYE's four-way split** — **MODELLING CHOICE, now under-powered.** The IG's binary firewall is correct as far as it goes, but EYE's reporting requires a richer axis. Recommend adding an orthogonal activity-type rather than overloading `record-origin`.
- **Coverage kept as three never-merged lineages** — **ALIGNS, not a contradiction.** EYE independently keeps administrative totals separate from PCCS results, so the IG's firewall matches practice. The divergence is only that EYE *also* needs the planned *target* alongside the achieved figures (§3a-2).
- **`integrated` campaign-type vs disease attribution** — **MODELLING CHOICE / minor gap.** EYE routinely co-delivers YF with measles or meningitis (Sudan YF+measles, DRC YF+measles, Guinea RVC+meningitis). The IG's `integrated` type captures the bundling but not *which antigen/disease* each dose served; per-dose attribution lives in the CVX of ICRImmunizationEvent, so this is mostly resolved at the delivery-event level — flag only that campaign-level disease/antigen attribution is implicit.

---

## 4. Terminology comparison

| EYE / YF term (source) | ICR IG equivalent | Aligns / Varies / Missing | Note |
|---|---|---|---|
| Preventive mass vaccination campaign (PMVC) | `campaign-type#vaccination-sia` (definition names "YF PMVC") | Aligns (as a type) / Missing (as an activity-type label) | Adequate as a vaccine-SIA; cannot be *labelled* PMVC vs other SIA. |
| Preventive catch-up campaign (Highlights: Sudan catch-up; LAC catch-up) | — | Missing | No activity-type code for catch-up of a specific cohort. |
| Reactive (outbreak) vaccination campaign / RVC | — (only `record-origin#campaign`) | Missing | No reactive vs preventive distinction. |
| Routine infant immunization | `record-origin#routine` | Aligns | Captured by the firewall. |
| All-age / target age range 1–60y (≥9mo, caution >60y) | ICRTargetPopulation `characteristic` (age band) | Aligns | Configurable bands; see §5 note on default assumption. |
| Coverage target (50% / 60% / 80%) (PGPH 1003781) | — | Missing | Only achieved coverage stored. |
| ICG / global emergency vaccine stockpile (6M doses) | — (ICRSupplyDelivery lacks source axis) | Missing | No stockpile-source / ICG-allocation field. |
| ICG campaign-list reconciliation (PLOS Med 1003523) | — | Missing | No roster-reconciliation construct. |
| Single-dose, lifelong (no booster) | — | Missing | No dosing-regimen element. |
| Outbreak risk / outbreak potential (R>1) / risk ranking | ICRLocation (geography only) | Varies / Missing | Geography recorded; risk-tier rationale not. |
| Administrative coverage | `coverage-source#administrative` | Aligns | — |
| Survey coverage / PCCS (cluster, LQAS) | `coverage-source#{survey, lqas}` | Aligns | Matches WHO coverage-survey methods (9789240090514). |
| AEFI / adverse events | — | Missing | Not in IG; corroborates prior AEFI flag (not surfaced in these YF sources beyond risk-benefit caution >60y). |
| Serology / immunity gap analysis (Highlights p.6–7) | — | Missing | EYE drives catch-up from immunity-gap analyses; IG has no immunity/serology context. NEW, low priority. |

---

## 5. Proposed terminology additions (flag for the IG)

1. **`activity-type` (a.k.a. `sia-type`) CodeSystem + element on ICRCampaign/ICRCampaignProtocol** — values `{routine, pmvc, catch-up, reactive}`. WHERE: new CodeSystem + ValueSet; bound on the campaign profile (orthogonal to `record-origin`). Justification: EYE's defining four-activity-type model (Highlights p.2; WHO fact sheet "mass vaccination campaigns … routine children's immunization and catch-up interventions … outbreak containment"). **CORROBORATES** the `sia-type`/activity-type axis flagged in the prior OCV, measles and WHO-SIA analyses — YF supplies the canonical four-value enumeration, raising priority to highest.

2. **`coverage-target` element on ICRTargetPopulation or ICRCampaignProtocol** — a planned percentage (with denominator reference, target date, and a `target-basis` qualifier e.g. interim/long-term). WHERE: extension on ICRTargetPopulation or a field on the protocol. Justification: explicit EYE 50/60/80% targets tied to 2022/2026 horizons (PGPH 1003781). **CORROBORATES** the coverage-target gap flagged by OCV/measles siblings.

3. **`stockpile-source` axis on ICRSupplyDelivery** — `{icg-emergency-stockpile, gavi-routine, country-procured, donated, other}` plus optional ICG request/approval identifiers and request-date/delivery-date. WHERE: ICRSupplyDelivery extension(s). Justification: ICG-released stockpile doses central to reactive YF response (Highlights p.6–7; WHO ICG stockpile guide). **CORROBORATES** the OCV stockpile-source flag.

4. **`dosing-regimen` element** — `{single-dose, single-dose-lifelong, multi-dose, fractional-dose}` on ICRCampaignActivity or the immunization event. WHERE: ActivityDefinition extension. Justification: YF single-dose-lifelong (WHO fact sheet); fractional-dose is a real YF emergency variant (excluded in PLOS Med 1003523), so the value set should include it. **CORROBORATES** the OCV dosing-regimen flag; YF adds the `fractional-dose` value.

5. **`campaign-trigger` / risk-targeting axis** — `{preventive-risk-based, reactive-outbreak}` plus an optional risk-tier reference. WHERE: campaign profile extension; can be derived from / paired with `activity-type`. Justification: EYE distinguishes risk-based PMVC placement from outbreak-driven RVC (PLOS Med 1003523; RAWG risk rankings Highlights p.5). **CORROBORATES** the prior campaign-trigger flag; consider merging with `activity-type` to avoid redundancy.

6. **Optional `campaign-subtype` / disease tag** — a YF (or per-disease) marker for analytics, even when `campaign-type=vaccination-sia` or `integrated`. WHERE: a low-cardinality coded extension. Justification: lets analytics filter YF activity out of mixed `integrated` campaigns without parsing CVX codes. **NEW** (mild) — only if per-disease campaign-level rollups are a reporting requirement; otherwise CVX at the event level suffices.

---

## 6. Categories / value sets worth adding

- **activity-type {routine, pmvc, catch-up, reactive}** — belongs in the IG; highest priority; overlaps directly with OCV/measles/SIA recommendations (define once, reuse).
- **coverage-target (numeric + basis qualifier)** — belongs in the IG; overlaps OCV/measles coverage-target asks.
- **stockpile-source {icg-emergency-stockpile, gavi-routine, country-procured, donated, other}** — belongs in the IG; overlaps the OCV ICG-stockpile recommendation (YF and OCV share the *same* ICG mechanism, so one value set serves both).
- **dosing-regimen {single-dose, single-dose-lifelong, multi-dose, fractional-dose}** — belongs in the IG; overlaps OCV; YF contributes `fractional-dose` (also a YF dose-sparing tactic).
- **campaign-trigger {preventive-risk-based, reactive-outbreak}** — useful but candidate to fold into activity-type; avoid a redundant axis.
- **risk-tier / outbreak-potential** — optional coded axis on ICRLocation or the campaign; lower priority; YF-led but generalisable.
- **reconciliation-status / external-list-source** — optional; supports campaign-roster reconciliation against ICG; NEW, lower priority, but novel vs siblings.

---

## 7. Use cases not yet identified in the IG

1. **All-age PMVC (1–60y) with a coverage target** — configure ICRTargetPopulation with a 1–60y age band AND attach a `coverage-target` (e.g. 80% by 2026); ICRCampaign labelled `activity-type=pmvc`. *Gap:* coverage-target element and activity-type label missing. Resources: ICRTargetPopulation, ICRCampaign, ICRCampaignProtocol.

2. **Reactive outbreak campaign from the ICG stockpile with list reconciliation** — a reactive YF campaign (ICRCampaign `activity-type=reactive`, `campaign-trigger=reactive-outbreak`) whose doses come from the ICG emergency stockpile (ICRSupplyDelivery `stockpile-source=icg-emergency-stockpile`, with ICG request/approval IDs and request-to-delivery dates), later reconciled against the authoritative ICG campaign list. *Gap:* activity-type, stockpile-source, and reconciliation constructs all missing. Resources: ICRCampaign, ICRCampaignTask, ICRSupplyDelivery.

3. **Preventive catch-up of a specific cohort** — e.g. Sudan's YF catch-up combined with measles, or LAC multi-antigen catch-up: ICRCampaign `activity-type=catch-up`, `campaign-type=integrated`, ICRTargetPopulation scoped to the catch-up cohort. *Gap:* catch-up activity-type label; per-disease attribution within `integrated`. Resources: ICRCampaign, ICRTargetPopulation, ICRImmunizationEvent (CVX per antigen).

4. **Risk-based geographic targeting of PMVCs** — selecting PMVC districts from sub-national RAWG risk rankings / outbreak-potential (R>1), recording the risk tier as the targeting rationale on ICRLocation or the campaign. *Gap:* no risk-tier axis. Resources: ICRLocation, ICRCampaignProtocol.

5. **Immunity-gap-driven planning** — EYE sizes catch-up from immunity-gap/serology analyses ("estimated 7.2 million unvaccinated children"; Highlights p.6–7). *Gap:* no immunity/serology context in the IG. Resources: would need a new immunity-estimate construct (low priority; NEW).

---

## 8. Bottom line

For a **plain YF PMVC**, the IG is **adequate today** — `vaccination-sia` already names the YF PMVC, configurable age bands carry 1–60y all-age targeting, the campaign/round spine and CVX immunization events capture delivery, and the admin-vs-survey coverage firewall matches EYE's own reporting. What the IG cannot yet do is represent YF as a *programme*: label the activity type, store the coverage target, trace stockpile/ICG provenance, encode single-dose-lifelong, or reconcile a campaign roster.

Top recommended IG changes, in priority order:

1. **Add an `activity-type` axis `{routine, pmvc, catch-up, reactive}`** — the highest-value change, now **confirmed across YF, OCV, measles and generic SIA**. Multi-campaign corroboration makes this the clear #1.
2. **Add a `coverage-target` element** (planned %, denominator ref, target date/basis) — corroborated by OCV and measles; YF supplies concrete 50/60/80% values.
3. **Add a `stockpile-source` axis on ICRSupplyDelivery** (with ICG request/approval + request-to-delivery dates) — corroborated by OCV; YF and OCV share the same ICG mechanism, so one value set serves both.
4. **Add a `dosing-regimen` element** `{single-dose-lifelong, multi-dose, fractional-dose}` — corroborated by OCV; YF adds single-dose-lifelong and fractional-dose.
5. **Add a `campaign-trigger` / risk-targeting concept** (ideally folded into activity-type) plus an optional campaign-roster reconciliation marker — partly corroborated (campaign-trigger); reconciliation is YF-NEW.

The pattern across siblings is decisive: the same four programme-semantics gaps (activity-type, coverage-target, stockpile-source, dosing-regimen) recur for every campaign type analysed, so they are cross-cutting IG deficits, not disease-specific edge cases — and should be prioritised as such. YF's only genuinely new contributions are the four-value activity-type enumeration, the ICG campaign-list **reconciliation** concern, and immunity-gap/serology context.

---

### Sources

- WHO, *EYE Strategy 2023 Highlights* (local PDF) — pp.1–7. Activity types, dose/coverage totals, ICG requests, RAWG risk rankings, PCCS, supply figures.
- WHO, *Eliminate Yellow Fever Epidemics (EYE) 2017–2026: A Global Strategy* — https://iris.who.int/bitstream/handle/10665/272408/9789241513661-eng.pdf
- Garske et al. / Hamlet et al., "Assessing the impact of preventive mass vaccination campaigns on yellow fever outbreaks in Africa," *PLOS Medicine* 10.1371/journal.pmed.1003523 — https://journals.plos.org/plosmedicine/article?id=10.1371%2Fjournal.pmed.1003523 (PMVC impact, ICG list reconciliation, "all or most age groups").
- "Assessing yellow fever outbreak potential and implications for vaccine strategy," *PLOS Global Public Health* 10.1371/journal.pgph.0003781 — https://journals.plos.org/globalpublichealth/article?id=10.1371%2Fjournal.pgph.0003781 (50/60/80% targets, 1–60y, R-based outbreak potential).
- WHO yellow fever fact sheet — https://www.who.int/news-room/fact-sheets/detail/yellow-fever (single-dose lifelong; ≥9 months; >60y caution; EYE three objectives incl. catch-up).
- WHO, *Estimating and monitoring yellow fever reactive campaign vaccination coverage: overview of survey and monitoring methods* (9789240090514) — https://www.who.int/publications-detail-redirect/9789240090514 (admin + cluster/LQAS survey methods).
- WHO, *Guide on access to the yellow fever ICG stockpile* — https://www.who.int/docs/default-source/documents/emergencies/guide-on-access-to-the-yellow-fever-icg-stockpile.pdf (6M-dose stockpile; ICG request process; IFRC/MSF/UNICEF/WHO).
- ICR FHIR IG source: `ig/input/fsh/codesystems.fsh` (`vaccination-sia` naming "yellow fever PMVC"; `record-origin`; `coverage-source`; `denominator-source`), `ig/input/fsh/profiles-population.fsh` (ICRTargetPopulation age-band characteristic + denominator provenance).
