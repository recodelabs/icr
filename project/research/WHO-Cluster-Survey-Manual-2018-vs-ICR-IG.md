# WHO Vaccination Coverage Cluster Surveys Reference Manual (2018) vs ICR FHIR IG — Alignment & Gap Analysis

*Source: WHO, *Vaccination Coverage Cluster Surveys: Reference Manual*, Geneva 2018, WHO/IVB/18.09 (rev. 2021). Compared against the ICR FHIR R4 IG (ICR IG v0.1.0 / explainer v0.7.0). This is a **coverage-survey methodology manual**, so the comparison centres on the IG's coverage-measurement half — specifically the `ICRSurveyCoverage` MeasureReport profile, its `sample-design` extension, the `coverage-source` value set (survey / lqas / rcm), the admin-vs-survey separation invariant, and the denominator / age-band model.*

---

## 1. Executive summary

The ICR IG and this manual agree strongly on the **high-level architecture of coverage measurement**, and that agreement is not accidental: both treat a survey-based coverage estimate as a fundamentally different object from an administrative tally, computed by a different method, on a different denominator, and prone to diverging from it. The manual opens by stating that administrative estimates are "inaccurate due to errors in the denominator … errors in recording vaccinations … and errors in compiling the data" (p.2), and recommends surveys precisely "to monitor coverage while efforts to improve administrative reporting systems are ongoing" (p.2). The IG's design invariant 3 — administrative and independent-survey lineages "must never be merged" — is a direct, faithful encoding of that distinction, and `ICRSurveyCoverage` correctly binds only to the independent sources (survey / lqas / rcm) while `ICRAdministrativeCoverage` is pinned to `administrative`. At the level of *what kinds of quantities exist*, the IG is well-aligned.

The gap is at the level of *how a survey estimate is described*. The manual is, in essence, a 234-page specification for the metadata that makes a coverage estimate **credible, reproducible, and comparable**: a probability sample design (PSU/EA, systematic PPES, p.3, p.143), a design effect and ICC driving a calculated sample size (p.15–17), a precision target expressed as a confidence-interval half-width (p.16), a defined evidence hierarchy (card → register → recall, p.31), explicit valid-vs-crude dose logic with minimum ages and intervals (p.73–74), documented missing-data handling (p.75–76), and survey weights with a documented calculation (p.67). In the IG, **all of this collapses into a single free-text string**: the `sample-design` extension is a `0..1 valueString` whose own example reads `"WHO 30×10 cluster survey, district-representative; card + caregiver recall"`. None of the survey's load-bearing quantities — DEFF, ICC, sample size, CI, evidence source, valid-vs-crude flag, weighting status, missing-data convention — are individually representable or queryable. A consumer cannot machine-read whether a reported 76% is crude or valid coverage, whether it is card-confirmed or recall-based, whether the confidence interval is ±3% or ±15%, or whether respondents without documents were counted as unvaccinated or excluded. Each of those choices changes the number materially (the manual shows valid DTPCV3 of 55% sitting inside a plausible 55–82% band depending solely on the missing-data convention, p.69).

The highest-value additions are therefore not new resources but **structuring the survey metadata that already conceptually belongs to `ICRSurveyCoverage`**: (1) decompose `sample-design` into structured sub-elements (survey method, PSU/cluster counts, respondents-per-cluster, design effect, ICC, weighting status); (2) add a `coverage-definition` axis (crude / valid / fully-vaccinated) and an `evidence-source` axis (card / register / recall / biomarker) so each `MeasureReport.group` is self-describing; (3) represent precision (95% CI, and the manual's one-sided LCB/UCB used for classification, p.84–86, p.192–193); and (4) record the missing-data convention. The IG already acknowledges that Measure definitions need to be aligned to WHO reporting minimums — Annex L (p.190) and the VCQI indicator catalogue are exactly the definitions that work should target.

Bottom line up front: `ICRSurveyCoverage` is an adequate *container* but not yet an adequate *description* of a WHO cluster coverage survey. It can hold the headline number; it cannot yet faithfully represent the survey that produced it.

---

## 2. Where the document ALIGNS with the IG

- **Administrative-vs-survey separation (invariant 3).** The manual frames administrative and survey coverage as distinct measurement modes — administrative being "available at all levels … with very little delays" but error-prone (p.2), surveys giving credible estimates "designed appropriately and implemented with high quality" (p.3). It even treats *agreement between them* as a survey question: "Are survey results consistent with the administrative coverage estimate (for example, within ± 5 percentage points …)?" (p.11). The IG's separate `ICRAdministrativeCoverage` (fixed `source=administrative`) and `ICRSurveyCoverage` (independent sources only), which "must never be collapsed," map this exactly. **Strong alignment.**

- **`coverage-source` survey / lqas as distinct methods.** The manual explicitly discusses cluster survey vs LQAS as different classification approaches, and notes that "In the past, the method that has been used to classify coverage is lot quality assurance sampling (LQAS)" with specific disadvantages (p.3). The IG's `coverage-source` CodeSystem (`survey`, `lqas`, `rcm`) recognises these as separate independent sources. **Aligns** at the enumeration level (with a gap on what distinguishes them — see §3a).

- **Denominator with provenance (invariant 4).** The manual repeatedly grounds coverage in a defined target population — "the proportion of a given population that has been vaccinated" (p.2) — and stresses census-based sampling frames and finite-population corrections (p.16), with weights "scaled so they sum to the target population" (p.67). The IG's `denominator-source` CodeSystem (census, census-projection, microcensus, worldpop, grid3, hmis, other) with source+date provenance is consonant with the manual's insistence on documented, census-derived denominators. **Aligns** in spirit.

- **Configurable age bands as annual birth cohorts.** The manual defines target populations in 12-month groups: "children aged 12–23 months … children aged 24–35 months … women who gave birth in the last 12 months … girls aged 15 years" for HPV, and stratified SIA bands "<5, 5–9, 10–14" (p.12). The IG's `ICRTargetPopulation` carrying configurable age bands matches the manual's age-cohort model. **Aligns.**

- **SIA-dose handling / campaign coverage as a first-class survey purpose.** The manual treats post-SIA coverage surveys as a primary use case throughout (e.g. "What proportion of the target population was vaccinated during an SIA," p.11; whole sections on post-SIA fieldwork timing, p.25, p.187), and discusses including SIA doses and distinguishing them from routine (p.5). The IG's campaign-first model with `vaccination-sia` campaign type and `ICRSurveyCoverage` for post-campaign evaluation is well-matched. **Aligns.**

- **Geography / cluster → location.** The manual's clusters are census enumeration areas (EAs) / primary sampling units mapped with boundaries and GPS (p.3, p.17, p.31), aggregated up an administrative hierarchy (district → province → national, p.10, p.26). The IG's `ICRLocation` (admin `partOf` hierarchy + operational geography + GERS/P-code) and `ICRTargetPopulation`'s geography characteristic referencing `ICRLocation` align with the manual's stratum/cluster geography. **Aligns** (with the cluster/PSU object itself unmodelled — see §3a).

- **Realtime vs reconciled (invariant 6).** The manual distinguishes preliminary in-field results from final analysed estimates, e.g. unweighted "alarmingly few vaccinated" reports that can run "even before the survey weights are available" to give "immediate actionable information" (p.66) vs the final weighted report. The IG's `data-lineage` (realtime / reconciled), required on `ICRSurveyCoverage`, captures this. **Aligns.**

---

## 3. Gaps & divergences

### 3a. Things the document requires that the IG does NOT yet represent

All of the following are **real gaps** unless marked otherwise. The unifying problem is that `sample-design` is a single `valueString` (confirmed: extension `sample-design` is `0..1`, `value[x]` type `string`, example `"WHO 30×10 cluster survey, district-representative; card + caregiver recall"`), so none of these survey quantities are individually structured or queryable.

- **Probability sample design (PSU/EA, single- vs two-stage, PPES).** The manual's single most important methodological requirement is a probability sample: "WHO now recommends using probability-based sampling methods at each stage" (p.5), with PSUs sampled by "systematic probability proportional to estimated size (systematic PPES)" (p.143/§3.6.5), single- or two-stage cluster designs (p.3). The IG cannot record sampling stage count, PPES vs equal-probability selection, or even the number of PSUs. **Real gap.** A faithful `ICRSurveyCoverage` should carry: survey method (cluster/LQAS/other), number of stages, PSU selection method, number of clusters/PSUs, target respondents per cluster.

- **Design effect (DEFF) and intracluster correlation coefficient (ICC).** Central to both sample-size planning and interpretation: sample size = A×B×C×D×E where C is DEFF (p.15); ICC "drives the design effect" (p.25); reports must "summarize the observed design effect and intracluster correlation coefficient as an aid for those who will plan the next survey" (Box 6, p.90). The IG has no field for either the planned or observed DEFF/ICC. **Real gap** — and a high-value one, because DEFF/ICC are exactly the metadata the manual says each survey must hand to the next.

- **Sample size and effective sample size.** The manual computes a target total sample, number of clusters, and households-to-visit (p.17–18), and reports effective sample size (e.g. 263/2.5 = 105, p.82). The IG cannot record planned or achieved sample size, completed-interview counts, or response/non-response rates (the manual's parameter E, p.16, and the Table 3 sample-quality counts, p.62). **Real gap.**

- **Precision / confidence intervals, and one-sided confidence bounds.** Precision is the survey's stated inferential goal: a 95% CI half-width (e.g. "± 5% if coverage is 70% or higher," p.16). For classification the manual uses **one-sided** 95% LCB and UCB, distinct from the two-sided CI endpoints (p.84–86, p.192–193), to label strata pass / fail / indeterminate against a programmatic threshold (e.g. measles 95%, p.87). FHIR `MeasureReport.group.measureScore` carries a point value but the IG defines no place for CI bounds, LCB/UCB, or the threshold being classified against. **Real gap.** Without this, an `ICRSurveyCoverage` reporting "76%" cannot convey whether that is ±3% or ±15%, nor whether the survey was even powered to estimate vs only to classify.

- **Evidence-of-vaccination source (card / register / recall / biomarker).** The manual prescribes a strict evidence hierarchy — home-based record (card) → health-centre register → caretaker recall (p.31) — and every standard table is broken out *by source* (Table 4: "from home-based card," "card OR register," "verbal history," p.73; the derived variables `got_*_by_card / _by_register / _by_history / _by_any_source`, p.59). Coverage by source is not a nicety; recall over-reports and card-only under-reports, so the source materially changes the number. The IG has no coded axis for evidence source. **Real gap.** (Serology/biomarker is discussed and explicitly set aside in this manual, p.2 — but a coded evidence axis should still include it for cross-document consistency.)

- **Valid vs crude dose distinction, with minimum-age/interval rules.** The manual rigorously separates **crude coverage** ("includes all doses, whether valid or not … the most liberal (highest) estimate," p.73) from **valid coverage** (only doses given at correct age and after the minimum interval, often 28 days; invalid early doses are dropped and later valid doses shifted down, p.73–74). These are different indicators on different denominators and the IG has no flag to distinguish them. **Real gap** — arguably the single most consequential coding gap, since a consumer cannot tell whether a survey's number is crude or valid.

- **Survey weights / weighting status.** The manual insists on weighted analysis for any population-level estimate (design weight → nonresponse adjustment → post-stratification, p.67; "it is essential to conduct a weighted analysis," p.5), and reports both weighted and unweighted N (Table 4, p.73). The IG has no flag for whether a reported figure is weighted, nor a place to reference the weighting annex the manual requires. **Real gap.** (FHIR offers `MeasureReport.group.population` and weighted/unweighted denominators could be modelled there.)

- **Missing-data / indeterminate handling convention.** The manual gives explicit, *consequential* options: count no-document respondents as unvaccinated (lower bound) vs exclude them (p.75); count missing/DNK as not vaccinated (recommended) vs expand to a three-category outcome — vaccinated / not vaccinated / missing-DNK (p.76). The same survey yields materially different coverage depending on the convention (the 55%–82% band, p.69). The IG has no field to record which convention a report used. **Real gap.**

- **Hierarchical / multi-level estimation and aggregation.** The manual designs for multiple levels of hierarchy — classify at district, aggregate to province with ±5%, aggregate to national with ±3% (p.26) — and aggregates stratum data to higher levels (p.14, p.87). The IG can reference an `ICRLocation` per report but has no explicit model for the parent-of-children aggregation relationship between a province-level estimate and its district-level surveys, nor for which level was *powered* for estimation vs classification. **Real gap** (modelling choice: could be expressed via report-to-report relationships or a level/inferential-goal coded field). The manual does not require Bayesian/hierarchical *model-based* estimation here (it uses design-based Wilson/Korn–Graubard intervals, p.70), so model-based small-area estimation is out of scope for this document.

- **Equity / inequality stratification.** The manual repeatedly requires coverage by subgroup — sex, maternal education, urban/rural, wealth, indigenous status (p.11, p.81) — with domain analysis and Rao-Scott chi-squared tests, and stresses reporting the *magnitude* of differences for "gender inequity" action (p.83). The IG's `ICRTargetPopulation` has a geography characteristic but no general equity-stratifier axis (sex / education / wealth / residence). **Real gap.**

- **Fieldwork / data-quality indicators.** The manual makes survey quality auditable: card-availability rate, participation/response rate, revisit counts, cluster inaccessibility/replacement, zero-dose clusters (p.62, p.66), and concordance between card/register/recall (p.81). None of these quality indicators have a home in the IG. **Real gap** (lower priority than the estimate-defining gaps, but the manual treats documented quality as what separates a credible survey from a non-probability one).

- **Inferential goal (estimation vs classification vs comparison).** The manual's three primary-question types — estimation (CI), classification (misclassification probability), comparison (statistical power) — drive the entire design and determine what the result *means* (p.11–13). The IG cannot record which a given survey was designed for, yet a classification-only survey "may not yield a precise quantitative estimate" (p.14). **Real gap.**

### 3b. Things the IG models that the document treats differently (or contradicts)

- **`rcm` as a coverage source.** The IG's `coverage-source` lists `rcm` (rapid convenience monitoring / RCM) alongside `survey` and `lqas` as independent coverage sources bound to `ICRSurveyCoverage`. This manual is about **probability** coverage surveys and is, if anything, *hostile* to non-probability quota methods — it spends pages criticising the old EPI "non-probability sample" quota method for selection bias (p.4) and stresses that only probability samples permit generalisation and valid CIs (p.3). RCM (and finger-mark checks, p.32) are convenience methods that this manual would not accept as coverage *estimates*. This **corroborates the prior sibling finding** that "RCM is pass/fail, not a coverage estimate." **Modelling tension, not a contradiction:** the IG is right to keep RCM out of `ICRAdministrativeCoverage`, but lumping RCM with probability surveys under one profile risks implying comparable rigour. The manual's view argues for a `survey-method` / rigour axis that distinguishes probability-survey from convenience monitoring (see §5).

- **LQAS as decision-rule classification.** The IG treats `lqas` as a coverage source but carries no place for the a-priori decision rules LQAS depends on (sample size n, decision threshold d). The manual notes LQAS "uses a priori defined decision rules to classify coverage" and recommends instead cluster-survey confidence bounds (p.3). If the IG keeps `lqas`, it needs to be able to represent that it is a classification (pass/fail) output, not an estimate with a CI. **Modelling gap** consistent with the IG's general lack of an estimation-vs-classification axis.

- **Single free-text `sample-design`.** As above, the IG *does* model sample design — but as opaque prose. This is a **modelling choice the manual effectively contradicts**: the manual's entire premise is that survey credibility comes from *structured, auditable, reproducible* design parameters that the next survey-planner and any external reviewer can read and reuse (Box 6 appendices, p.90). A free-text blob defeats comparability — the very property the manual says distinguishes a good survey from the old EPI method (p.4).

---

## 4. Terminology comparison

| Manual term (p.X) | ICR IG equivalent | Aligns / Varies / Missing | Note |
|---|---|---|---|
| Cluster survey (p.87 glossary; p.3) | `ICRSurveyCoverage` + `coverage-source = survey` | Aligns | IG has the source code but not the design structure |
| Primary sampling unit (PSU) / enumeration area (EA) (p.3, p.17, p.87) | — (clusters not modelled; `ICRLocation` for geography) | Missing | No PSU/cluster object or count |
| PPES / PPS — probability proportional to estimated size (p.143) | — | Missing | No selection-method field |
| Design effect (DEFF) (p.15, p.90) | — (free-text in `sample-design`) | Missing | Required in report appendix per manual |
| Intracluster correlation coefficient (ICC) (p.16, p.25) | — | Missing | Drives DEFF; manual requires observed value be reported |
| Sample size / effective sample size (p.17, p.82) | — | Missing | No planned or achieved N |
| Confidence interval (95% CI), half-width (p.16, p.70) | — (`measureScore` point value only) | Missing | No CI bounds field |
| 1-sided LCB / UCB for classification (p.84–86, p.192) | — | Missing | Distinct from 2-sided CI; needed for pass/fail |
| Card (home-based record) vs register vs recall (verbal history) (p.31, p.73) | — | Missing | No evidence-source axis |
| Serology / biomarker (p.2) | — | Missing (out of scope in this manual) | Include in evidence axis for cross-doc use |
| Crude coverage (p.73) | — | Missing | No crude/valid flag |
| Valid (dose) coverage (p.73–74) | — | Missing | Minimum age/interval logic; different denominator |
| Fully vaccinated (p.11, p.73) | — | Missing | Country-defined composite indicator |
| Dropout (p.69) | — | Missing | Derived multi-dose indicator |
| Indeterminate (classification) (p.86, p.87 glossary) | — | Missing | Third classification outcome (yellow) |
| Weighting / survey weights (p.67) | `data-lineage` (realtime/reconciled, unrelated) | Missing | No weighted/unweighted flag |
| LQAS (p.3) | `coverage-source = lqas` | Varies | IG has the code; no decision-rule / pass-fail semantics |
| RCM (p.32, finger-marking) | `coverage-source = rcm` | Varies | Manual treats as convenience, not an estimate |
| coverage-source (administrative / survey / lqas / rcm) | `coverage-source` CodeSystem | Aligns | Core IG axis matches the manual's method split |
| Denominator / target population (p.2, p.12, p.67) | `ICRTargetPopulation` + `denominator-source` | Aligns | Manual's census-frame emphasis matches provenance model |
| Equity stratifier — sex / education / wealth / urban-rural (p.11, p.81) | `ICRTargetPopulation` geography only | Missing | No general equity-stratifier axis |
| Design effect / ICC reported for next survey (Box 6, p.90) | — | Missing | Reuse metadata explicitly required |

---

## 5. Proposed terminology additions (flag for the IG)

Each justified by a manual page. Recommended home noted.

1. **Decompose `sample-design` into structured sub-extensions** on `ICRSurveyCoverage` (justified p.5, p.15–18, p.90 Box 6 appendix requirements):
   - `survey-method` (cluster / lqas / rcm / other) — coded.
   - `sampling-stages` (1 / 2 / 3+) and `psu-selection-method` (systematic-ppes / equal-probability / other) (p.3, p.143).
   - `number-of-clusters` (PSUs) and `respondents-per-cluster` (the manual's `m`, p.16).
   - `design-effect` and `icc` — planned and/or observed (p.15, p.25, p.90).
   - `effective-sample-size` and `achieved-sample-size` (p.17, p.82).
   - `weighted` (boolean) (p.67).

2. **`coverage-definition` value set** — `crude` / `valid` / `fully-vaccinated` / `dropout` (p.73–74, p.69). Apply per `MeasureReport.group` so each reported number is self-describing as crude vs valid. *(Highest single value.)*

3. **`survey-evidence-source` value set** — `card` (home-based record) / `register` (health-centre) / `recall` (verbal history) / `card-or-register` / `any-source` / `biomarker` (p.31, p.59, p.73). Apply per group or per stratifier so coverage-by-source is representable.

4. **`precision` representation** on coverage groups — `ci-low` / `ci-high` (two-sided 95% CI), plus `lcb` / `ucb` (one-sided 95% bounds) and `ci-method` (e.g. Wilson / Korn–Graubard, p.70). Needed for both estimation and classification (p.16, p.84–86, p.192).

5. **`inferential-goal` code** — `estimation` / `classification` / `comparison` (p.11–13) on `ICRSurveyCoverage`, with `classification-threshold` and `classification-result` (`above` / `below` / `indeterminate`) when goal = classification (p.86, p.87).

6. **`missing-data-convention` code** — `count-as-unvaccinated` / `exclude-no-document` / `three-category` / `imputed` (p.75–76), recorded on the report so the denominator semantics are explicit.

7. **Equity-stratifier axis** on `ICRTargetPopulation` / coverage groups — `sex` / `maternal-education` / `wealth-quintile` / `urban-rural` / `other` (p.11, p.81), to carry the manual's subgroup/domain analyses.

---

## 6. Categories / value sets worth adding

New coded axes implied by the manual, with a recommendation on whether each belongs in the IG:

- **Evidence-of-vaccination source** (card / register / recall / biomarker) — **Yes, add.** This is foundational to the manual (p.31, p.73) and materially changes the number; it is also reusable across other survey/serosurvey documents.
- **Coverage definition** (crude / valid / fully-vaccinated / dropout) — **Yes, add (highest priority).** Without it, a survey number is ambiguous (p.73–74).
- **Survey method / rigour** (probability-cluster / LQAS / RCM-convenience) — **Yes, add.** Lets the IG distinguish a probability estimate from convenience monitoring, which the manual sharply separates (p.3–4). This also resolves the `rcm` tension in §3b.
- **Sampling-stage / PSU-selection** (single/two-stage; systematic-PPES) — **Yes, add** as structured `sample-design` sub-elements (p.3, p.143).
- **Precision / CI representation** (2-sided CI + 1-sided LCB/UCB + method) — **Yes, add.** Core to interpreting and classifying (p.16, p.70, p.84).
- **Equity stratifier** (sex / education / wealth / residence) — **Yes, add**, reusable beyond surveys (p.11, p.81).
- **Inferential goal + classification outcome** (estimation/classification/comparison; above/below/indeterminate) — **Yes, add** (p.11–13, p.86).

**Should `ICRSurveyCoverage` reference a `Measure`?** **Yes — strongly recommended.** The manual's Annex L (p.190) explicitly anchors standard indicator definitions in the WHO VCQI catalogue (e.g. `RI_COVG_01: Crude coverage`, with documented weighted denominator, numerator, and missing/DNK handling, p.190). FHIR `MeasureReport.measure` should point to a `Measure` resource that encodes each indicator's denominator/numerator/weighting/missing-data rules. This is the cleanest way to carry the crude/valid/missing-data semantics above without overloading extensions, and it directly serves the IG's already-acknowledged gap "Measure definitions aligned to WHO reporting minimums." VCQI / Annex L is the concrete catalogue to align to.

---

## 7. Use cases not yet identified in the IG

1. **Design a post-SIA coverage survey from expected coverage + design effect + precision.** The manual's A×B×C×D×E sample-size workflow (p.15–18) — pick precision (CI half-width), anticipated coverage `p`, ICC→DEFF, households-per-eligible, non-response inflation — produces clusters and respondents-per-cluster. The IG has no artifact to capture this *survey-design intent* (analogous to how `ICRCampaignProtocol` captures campaign intent). **FHIR home:** a survey-design profile, or structured `sample-design` sub-elements on `ICRSurveyCoverage` populated at planning time, optionally referencing a `Measure`.

2. **Admin-vs-survey external-consistency check.** The manual frames "Are survey results consistent with the administrative coverage estimate (within ±5 pp)?" as a real survey question (p.11). The IG keeps the two reports separate (correctly) but provides no modelled way to *relate* an `ICRSurveyCoverage` to the `ICRAdministrativeCoverage` it validates for the same period/place. **FHIR home:** a `MeasureReport.relatedDocument` / report-link or a comparison observation; this is a reconciliation use case the IG should name.

3. **Card + recall + register coverage with valid-dose rules.** Reporting crude (any source) and valid (documented, correct age/interval) coverage side by side, broken out by evidence source, with the missing-data convention stated (Tables 4–5, p.73–74; missing-data §6.3.3, p.75). **FHIR home:** multiple `MeasureReport.group`s on one `ICRSurveyCoverage`, each tagged with `coverage-definition` + `survey-evidence-source` (per §5).

4. **Equity / inequality analysis.** Coverage by sex / maternal education / wealth / urban-rural with magnitude-of-difference reporting and domain analysis (p.81, p.83). **FHIR home:** `MeasureReport.group.stratifier` populated from an equity-stratifier value set; `ICRTargetPopulation` extended with the stratifier characteristic.

5. **SIA-dose inclusion and RI-on-SIA bundling.** A post-SIA survey that also collects routine-immunization coverage (p.25, §2.11), where the SIA needs only district classification but RI needs province estimation — different sample sizes, different DEFF. **FHIR home:** distinct `ICRSurveyCoverage` reports (SIA vs RI) sharing fieldwork, each with its own `inferential-goal`, level, and design — which the IG cannot currently distinguish.

6. **Classification at district, aggregation to province/national.** Classify each district pass/fail/indeterminate against a threshold (e.g. measles 95%), then aggregate to a precise province estimate (p.26, p.87). **FHIR home:** report-to-report aggregation relationships + an `inferential-goal`/level field on each `ICRSurveyCoverage`.

---

## 8. Bottom line

**Is `ICRSurveyCoverage` adequate to represent a WHO cluster coverage survey?** As a *container for the headline estimate and its source* — yes. As a *faithful, reproducible, machine-readable description of the survey* the manual specifies — **not yet.** The IG correctly captures the architectural distinction (admin vs survey, never merged) and the source enumeration, but the survey's load-bearing metadata — the parameters that determine what the number *means* and whether it is *credible* — currently live (if at all) in one opaque free-text `sample-design` string. The manual's entire thesis is that those parameters must be structured and auditable.

**Top 5 recommended IG changes:**

1. **Add a `coverage-definition` axis (crude / valid / fully-vaccinated / dropout)** per `MeasureReport.group` — without it, a survey number is ambiguous (p.73–74). *(Highest value, lowest cost.)*
2. **Add a `survey-evidence-source` axis (card / register / recall / biomarker)** — coverage-by-source is the manual's standard output and materially changes the estimate (p.31, p.73).
3. **Decompose `sample-design` into structured sub-elements** — survey method, PSU/cluster counts, respondents-per-cluster, **design effect, ICC**, effective/achieved sample size, weighted flag (p.15–18, p.90).
4. **Represent precision** — two-sided 95% CI bounds plus one-sided LCB/UCB and CI method, and an `inferential-goal` (estimation/classification/comparison) with a classification result (above/below/indeterminate) (p.16, p.70, p.84–86).
5. **Bind `ICRSurveyCoverage` to a `Measure`** encoding each indicator's denominator/numerator/weighting/missing-data rules, aligned to WHO Annex L / VCQI definitions (p.190) — closing the IG's already-acknowledged "Measure definitions aligned to WHO reporting minimums" gap and carrying the missing-data convention (p.75–76).

Items 1–2 are inexpensive coded axes that immediately make survey reports self-describing; items 3–5 raise `ICRSurveyCoverage` from "holds a number" to "represents a WHO cluster survey." Equity stratifiers and fieldwork-quality indicators (§3a) are valuable second-tier additions.
