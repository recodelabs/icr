# Research → ICR IG — Cross-Document Synthesis & Prioritized Change-List

Rolls up **eight** source analyses in this folder into one decision-ready view: what the global-health field evidence **validates** in the ICR FHIR IG, and a **prioritized list of additions** it should consider. Compared against ICR IG v0.1.0 / explainer `ig-info.md` (v0.7.0–v0.8.0).

**Source analyses (read each for the page/URL-cited detail):**

*Injectable-vaccine SIA & routine microplanning*
- [WHO SIA Field Guide (2016), 212 pp](WHO-SIA-2016-vs-ICR-IG.md) — generic injectable-vaccine SIA planning/implementation/M&E.
- [WHO RED Microplanning (2009), 74 pp](RED-microplanning-vs-ICR-IG.md) — routine-RI microplanning methodology reused by campaigns.
- [WHO-AFRO Measles SIA Field Guide (2010/11), 95 pp](WHO-AFRO-Measles-Fieldguide-2011-vs-ICR-IG.md) — disease-specific measles SIA + surveillance linkage.

*Coverage measurement, other campaign types, geography*
- [WHO Coverage Cluster Surveys Reference Manual (2018), 234 pp](WHO-Cluster-Survey-Manual-2018-vs-ICR-IG.md) — survey methodology → `ICRSurveyCoverage` / `sample-design`.
- [GTFCC Cholera OCV Field Manual](GTFCC-OCV-FieldManual-vs-ICR-IG.md) — multi-dose vaccine campaign, ICG stockpile, cost.
- [NTD MDA / Preventive Chemotherapy (ESPEN + literature)](NTD-MDA-PreventiveChemotherapy-vs-ICR-IG.md) — the community-directed/drug half of the IG.
- [WHO EYE Strategy / Yellow Fever PMVC](WHO-EYE-YellowFever-vs-ICR-IG.md) — all-age PMVC, coverage targets, ICG reconciliation.
- [Geo-enabled Microplanning (ESPEN / AMP / WHO GIS)](Geo-enabled-Microplanning-vs-ICR-IG.md) — geography/denominator layer → `ICRLocation`.

---

## Bottom line

Eight documents — across routine RI, polio/measles/YF/OCV vaccine SIAs, NTD drug campaigns, survey methodology, and GIS microplanning — **converge hard on the same conclusions**. The convergence is the signal.

1. **The IG's spine is repeatedly validated** — plan→order lifecycle, one-Task-per-visit with per-person delivery events, the campaign-vs-routine `record-origin` firewall, no-denominator-without-provenance, the three never-merged coverage lineages, realtime-vs-reconciled, coded delivery strategy, and (the standout) operational geography overlaid on the admin hierarchy. No source contradicts the spine.

2. **The first three analyses surfaced the missing *operational axes* around the spine** (SIA-type, AEFI, wastage, supervision, social-mobilization, equity, defaulter). The five new analyses confirm those **and reveal a second, deeper theme: the IG's *coverage* and *programme-semantics* models are too thin.**

3. **The single highest-priority theme is now "programme semantics."** Four coded axes — **activity/SIA-type**, **coverage-target-as-data**, **stockpile-source**, **dosing-regimen** — are absent from the IG yet show up as first-class in *every* campaign type analysed (OCV, YF, NTD, measles, polio). They are cross-cutting deficits, not disease quirks.

4. **The coverage model needs the biggest rework.** Coverage in the IG is keyed only by *data-source* (`administrative`/`survey`/`lqas`/`rcm`). The evidence demands two more orthogonal axes: **denominator type** (total vs at-risk → NTD's programme-vs-epidemiological coverage), **unit** (people vs implementation-units → geographic coverage), plus a **structured survey design** (the IG's `sample-design` is one free-text string) and a **multi-dose "fully-immunized" measure**. Binding the coverage profiles to `Measure` definitions closes the IG's own acknowledged gap.

5. **Geography is the IG's strongest win** — every GIS/operational source validates `overlays-admin-unit` / `supervisory-area`. And the **GeoJSON-on-R4 "open question" is effectively already resolved**: the IG *ships* a `location-boundary-geojson` extension; `background.md` just hasn't been updated to say so.

6. **Surveillance is a separate domain to reference, not model** (measles). ICR holds a pointer to the outbreak/case-age signal that triggered/sized a campaign; case/lab data live in a VPD-surveillance IG.

---

## Convergence matrix (recommendation × document)

✓ = the document independently flags it (own cites); ~ = touched/implied; blank = out of that document's scope.
**S**=SIA-2016, **R**=RED, **M**=Measles, **CS**=ClusterSurvey, **O**=OCV, **N**=NTD-MDA, **Y**=YellowFever, **G**=Geo.

| Recommended IG addition | S | R | M | CS | O | N | Y | G | Priority |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|---|
| **Activity/SIA-type axis** (routine/PMVC/catch-up/reactive/follow-up/mop-up) | ✓ | ~ | ✓ |  | ~ | ~ | ✓ |  | **P1** |
| **Coverage-target as data** (≥95% / ≥65% / 50-60-80%) |  |  | ~ | ~ | ✓ | ✓ | ✓ |  | **P1** |
| **Coverage model: add denominator-type + unit axes** (programme/epidemiological/geographic; at-risk denominator) |  |  |  | ~ | ~ | ✓ | ~ |  | **P1** |
| **Structured `sample-design` + bind coverage to a `Measure`** | ~ |  | ~ | ✓ | ~ | ~ |  |  | **P1** |
| **Multi-dose "fully-immunized" measure + round linkage** |  |  |  | ~ | ✓ |  | ~ |  | **P1** |
| **RCM = pass/fail + triggers, not a coverage rate** | ✓ | ✓ | ✓ | ✓ |  |  |  |  | **P1** |
| **AEFI** profile + 5-category causal value set | ✓ | ✓ | ✓ |  |  |  | ~ |  | **P1** |
| **Wastage / vial-accountability** axis | ✓ | ✓ | ✓ |  | ~ |  |  |  | **P1** |
| **Reconcile `missed-reason`/`noncompliance-reason`** with WHO field lists | ✓ | ✓ | ~ |  |  | ~ |  |  | **P1** |
| **Stockpile-source axis** (ICG / national / Gavi) on supply |  |  |  |  | ✓ |  | ✓ |  | **P2** |
| **Dosing-regimen** (single / multi-dose / fractional) |  |  |  |  | ✓ |  | ✓ |  | **P2** |
| **Campaign-trigger** (reactive / preventive / outbreak) |  |  | ~ |  | ✓ |  | ✓ |  | **P2** |
| **Campaign-cost** axis (cost per fully immunized/treated person) | ~ | ~ |  |  | ✓ |  |  |  | **P2** |
| **Campaign-phase / readiness** lifecycle (+ readiness MeasureReport) | ✓ | ~ | ✓ |  |  |  |  |  | **P2** |
| **Defaulter / dropout / zero-dose** disposition + dropout Measure | ~ | ✓ | ✓ |  |  | ~ |  |  | **P2** |
| **Supervision / QA** profile | ✓ | ✓ | ✓ |  |  | ~ |  |  | **P2** |
| **Social-mobilization / demand** axis | ✓ | ✓ | ✓ |  |  |  |  |  | **P2** |
| **Population-vulnerability / equity** taxonomy | ✓ | ✓ | ✓ |  |  | ~ |  | ✓ | **P2** |
| **`outreach` delivery-strategy** (distinct from mobile/temporary-post) |  | ✓ |  |  |  | ~ |  | ~ | **P2** |
| **CDD / community-distributor performer role** |  |  |  |  |  | ✓ |  |  | **P2** |
| **Team / CareTeam + microplan-resource** profile |  | ~ |  |  |  | ~ |  | ✓ | **P2** |
| **Survey evidence-source + crude-vs-valid coverage** (card/recall/register) |  |  |  | ✓ |  |  |  |  | **P2** |
| **Population-estimation method + source-raster version/date** | ~ | ~ |  |  |  | ~ |  | ✓ | **P3** |
| **Catchment-polygon geometry — adopt the shipped GeoJSON ext, close the open question** |  |  |  |  |  |  |  | ✓ | **P3 (cheap)** |
| **`structure`/footprint location-type + accessibility/travel-time** |  | ~ |  |  |  |  |  | ✓ | **P3** |
| **Cold-chain / logistics / stock-readiness** axis | ~ | ✓ | ✓ |  | ~ |  |  |  | **P3** |
| **Endemicity status + TAS/impact-survey gate** (NTD) |  |  |  |  |  | ✓ |  |  | **P3** |
| **Eligibility-exclusion reasons + dose-pole/height dosing** (NTD) |  |  |  |  |  | ✓ |  |  | **P3** |
| **Access-vs-utilization** problem-category typology |  | ✓ |  |  |  |  |  |  | **P3** |
| **Location-type / denominator-source code additions** (transit-point, health-camp, head-count, campaign-results…) | ✓ | ✓ | ~ |  |  | ~ |  | ~ | **P3** |
| **Surveillance / outbreak / lab — *reference, don't model*** |  | ~ | ✓ |  | ~ | ~ | ~ |  | **Scope** |

---

## Prioritized recommendations

### P1 — strongly convergent / load-bearing (do first)

**A. Programme-semantics quartet** — four small coded axes the IG lacks but every campaign type treats as first-class:
1. **`activity-type` (a.k.a. `sia-type`)** — `routine`, `pmvc`, `catch-up`, `follow-up`, `mop-up`, `reactive`/`outbreak-response`, `rolling-phased`. Orthogonal to `campaign-type` (intervention) and `record-origin` (campaign-vs-routine). On Protocol/Campaign. (S, M, Y; EYE's canonical 4-type taxonomy.)
2. **`coverage-target`** element — store the *programme-defined threshold* (≥95% SIA; ≥65% LF epidemiological; EYE 50/60/80%), not just achieved coverage. (Y, N, O.)
3. **`stockpile-source`** axis on ICRSupplyDelivery — ICG / national / Gavi, with allocation/lot + request-to-delivery interval. One value set serves OCV and YF (same ICG mechanism). (O, Y.)
4. **`dosing-regimen`** — single-dose-lifelong / multi-dose / fractional-dose; needed to define "fully immunized." (O, Y.)

**B. Coverage-model overhaul** — the biggest analytic theme:
5. **Separate the three coverage axes.** Today coverage is keyed only by *data-source*. Add **denominator-type** (total-population vs at-risk/eligible → NTD programme-vs-epidemiological coverage; requires an **at-risk denominator** on ICRTargetPopulation) and **unit** (people vs implementation-units → a **geographic-coverage** Measure). (N decisive; O/Y/M corroborate the target/independent split.)
6. **Structure `sample-design`** (currently a single free-text string) into sub-elements — method, PSU/EA, #clusters, design-effect/ICC, sample size, weighting, evidence-source (card/recall/register), crude-vs-valid, CI/precision — and **bind `ICRSurveyCoverage` (and `ICRAdministrativeCoverage`) to `Measure` definitions** aligned to VCQI/Annex L. This closes the IG's own acknowledged "Measure definitions" gap. (CS.)
7. **Multi-dose "fully-immunized" measure + round1↔round2 linkage** for OCV/multi-round campaigns. (O, Y.)
8. **Make RCM semantics explicit** — pass/fail + trigger thresholds, *not* a coverage rate, *not* a probability survey; LQAS needs its decision-rule. (S, M, CS, R.)

**C. Vaccine-cross-cutting operational data** (all three vaccine guides):
9. **AEFI** profile + `aefi-causal-type` value set (5 WHO/CIOMS categories + serious criteria).
10. **Wastage / vial-accountability** axis (WMF; received/opened/not-usable/returned; VVM) — reusable for vaccines, drugs, ITNs.
11. **Reconcile `missed-reason`/`noncompliance-reason`** with the WHO RCM field lists (add `unaware-campaign`, `post-distance`, `post-stockout`, `not-decision-maker`, `unknown-declined`; split out non-missed dispositions `already-vaccinated`/`plan-to-go-later`; decide one home for `sick`).

### P2 — convergent, more design work
12. **Stockpile-source, dosing-regimen, campaign-trigger, campaign-cost** (cost-per-FIP, CholTool-aligned). 13. **Campaign-phase/readiness** axis + readiness MeasureReport. 14. **Defaulter/dropout/zero-dose** disposition + dropout Measure + zero-dose hand-off-to-routine. 15. **Supervision/QA**, **social-mobilization/demand**, **population-vulnerability/equity** profiles/characteristic. 16. **`outreach` delivery-strategy**; **CDD performer role**; a **Team/CareTeam + microplan-resource** profile (every geo/microplanning source models team-areas + workload; the IG has none).

### P3 — narrower or partly routine-only
17. **Geography refinements:** **adopt the already-shipped `location-boundary-geojson` extension as canonical and remove GeoJSON from "open question" status**; add a **population-estimation-method + source-raster version/date** on ICRTargetPopulation (two `worldpop` estimates are currently indistinguishable); add a **`structure`/footprint** location-type + **accessibility/travel-time** attribute; a **georegistry-match-status** value set extending the GERS-enrichment lifecycle. 18. **Cold-chain/logistics/stock-readiness** beyond SupplyDelivery. 19. **NTD specifics:** endemicity status + TAS/impact-survey gate on ICRLocation; eligibility-exclusion reasons + dose-pole/height dosing. 20. **Access-vs-utilization** problem typology; **location-type / denominator-source** code additions (transit-point, health-camp, idp-camp; head-count, campaign-results, line-list-household).

---

## Scope decision: surveillance & outbreak response — *reference, don't model*
Case-based surveillance, lab specimen/confirmation, susceptibility/inter-epidemic modelling and confirmed-case age-distribution (measles guide; YF outbreak-risk) are the **trigger and evaluation context** for a campaign, not its execution data. ICR holds a thin reference (the signal/outbreak that justified the SIA + the case-age distribution that set the target age) and links out to a VPD-surveillance IG. Keep case/lab data out of the ICR campaign IG.

## Modelling choices to revisit (refinements, not new axes)
- **House-to-house *canvassing* vs *vaccination*** — the IG's single `house-to-house` code conflates Type A demand-generation (dose at post) with Type B door-delivery; canvassing is arguably a modifier. (S.)
- **Administrative coverage stratification** — all sources warn it is denominator-fragile; ensure ICRAdministrativeCoverage stratifies by strategy + age band and can carry a data-quality caveat. (S, M, R.)
- **OCV/YF campaign-type** — keep `vaccination-sia` (it already names YF PMVC) rather than adding `ocv`/`yf` codes; document as a deliberate choice. (O, Y.)

## Validated — do not change
Plan→order lifecycle; one-Task-per-visit with per-person delivery events; `record-origin` campaign/routine firewall; denominator-with-provenance; three never-merged coverage lineages; realtime-vs-reconciled; coded delivery strategy; **operational-geography-overlays-admin** (strongest win — validated by every GIS/operational source); GERS-preferred multi-system identity; configurable age bands (all-age PMVC works); `campaign-type=mda` + `community-directed` + `ICRMedicationAdministration`(ATC, subject=DeliveryUnit, directlyObserved) for NTD MDA; integrated multi-intervention on a shared denominator. The field evidence strongly endorses the IG's spine.

## Caveats on the evidence
- The **RED** doc is the **2009** edition (not the 2017 revision).
- Some web sources 403'd or were thin (**GTFCC §9**, **JHU stop-cholera**, the **WHO geo handbook** landing page); those analyses leaned on substituted primary sources (GTFCC monitoring page, WHO single-dose guidance, Gavi, CholTool papers; GRID3 white papers; AMP case study) — flagged inline in each file. A few **measles-guide annexes** are scanned images; two of its `missed-reason` proposals are inferred from body text.
- Downloaded source PDFs live in `docs/research/` (left untracked). Each analysis checked the IG against the committed FSH; confirm exact CodeSystem URLs against `ig/input/fsh/` before drafting changes.
