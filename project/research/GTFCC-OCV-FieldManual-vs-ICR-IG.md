# GTFCC Cholera OCV Field Manual (§9) vs ICR FHIR IG — Alignment & Gap Analysis

This source is the GTFCC *Cholera Outbreak Response Field Manual*, **Section 9 — Oral Cholera Vaccine (OCV)** ([choleraoutbreak.org/book-page/section-9-oral-cholera-vaccine.html](https://www.choleraoutbreak.org/book-page/section-9-oral-cholera-vaccine.html)), which describes OCV as a **two-dose mass-campaign** intervention supplied from the **global OCV stockpile** managed by the **International Coordinating Group (ICG)**. It is compared against the **ICR FHIR R4 Implementation Guide** (publisher UNICEF; Ona + Crosscut), **IG v0.1.0 / explainer v0.7.0**. Because Section 9 is operationally thin on M&E, supply, and costing, supporting detail is drawn from the GTFCC *National Cholera Plan* monitoring page, WHO/ICG stockpile materials, Gavi, and the CholTool costing literature (all cited inline).

> **Sourcing note.** Section 9 on choleraoutbreak.org is a single page whose subsections are in-page anchors (`#useoforal`, `#massvacc`, `#prequalified`, `#useofocv`, `#monit`). Repeated fetches confirm that this page is **strategic/clinical**, not operational: it does **not** describe vaccination posts/teams, mop-up, the minimum data set, coverage-survey methodology, the admin-vs-survey gap, CholTool, or ICG request timelines. Those topics are therefore grounded in the supporting sources below. The Johns Hopkins *stop-cholera* GTFCC resources page ([publichealth.jhu.edu/stop-cholera/gtfcc-resources/vaccine](https://publichealth.jhu.edu/stop-cholera/gtfcc-resources/vaccine)) **could not be fetched** (hard HTTP 403 via WebFetch and via curl with a browser user-agent); its intended content (minimum data set, coverage methods, CholTool) was recovered from the equivalent GTFCC/WHO primary sources and peer-reviewed CholTool papers instead.

---

## 1. Executive summary

The ICR IG models the **skeleton** of an OCV campaign well. An OCV campaign is a mass public-health vaccination campaign with vaccination posts, teams, a target population/denominator, delivery events, and administrative + survey coverage — all of which the IG already has first-class profiles for (`ICRCampaign`/`ICRCampaignTask`/`ICRImmunizationEvent`, `ICRTargetPopulation`, `ICRDeliveryUnit`, `ICRAdministrativeCoverage`/`ICRSurveyCoverage`, plus the `delivery-strategy` and `record-origin` axes). An OCV campaign would today be coded `campaign-type = vaccination-sia`, and structurally that profile is adequate for the *posts-and-teams* shape of the intervention. The strong design choices — delivery strategy as first-class, the record-origin firewall, three never-merged coverage lineages, no denominator without provenance — all map cleanly onto how GTFCC frames an OCV campaign.

The **OCV-specific gaps are concentrated in three areas**, none of which the IG currently represents. First, **multi-dose / multi-round completion**: OCV is intrinsically two-dose, and GTFCC's own headline coverage indicator is "doses administered for **round 1 and round 2**" against persons targeted, with **95% target** ([GTFCC NCP monitoring](https://ncp.gtfcc.org/book-page/monitoring-and-reporting.html)). The IG can carry two rounds via `CarePlan` `partOf`, but it has **no derived "fully immunized (both doses)" coverage measure** and — under the one-Task-per-visit / aggregate-tally model — **no defined way to link an individual's round-1 dose to their round-2 dose**, which is the crux of OCV M&E. Second, **the ICG stockpile**: OCV supply is gated by an ICG request → allocation → delivery workflow with a famously variable request-to-delivery interval, yet `ICRSupplyDelivery` has **no stockpile-source / lot / ICG-allocation axis**. Third, **cost**: GTFCC explicitly recommends CholTool to report **cost per fully immunized person**, and the IG has **no campaign-cost axis at all**.

The **highest-value additions** are therefore: (a) a dose/round-completion coverage representation plus a derived "fully-immunized" `Measure`; (b) a supply-source axis (ICG / national / Gavi) and lot/allocation linkage on `ICRSupplyDelivery`; and (c) a campaign-cost representation (financial vs economic, by activity, cost-per-FIP). A smaller, cheaper win is an **OCV campaign sub-type** (reactive / preventive / humanitarian), since GTFCC, ICG, and Gavi all treat that trigger distinction as load-bearing.

Net: the IG is **adequate as a container** for an OCV campaign but **not yet sufficient** to satisfy GTFCC/ICG OCV reporting. Of the three core gaps, **multi-dose completion and cost are general** (they recur for any multi-round or any costed campaign), while **stockpile/ICG is more OCV-specific** (cholera supply is uniquely stockpile-gated, though the same axis would help any stockpile vaccine).

---

## 2. Where the document ALIGNS with the IG

- **Mass-campaign / posts-and-teams shape.** Section 9 frames OCV as **mass vaccination campaigns** (anchor `#massvacc`) delivered to a target population aged **"1 year or older"** ([§9](https://www.choleraoutbreak.org/book-page/section-9-oral-cholera-vaccine.html)). This is exactly the `vaccination-sia` shape the IG's spine is built for: `ICRCampaignProtocol` (PlanDefinition) → `ICRCampaignActivity` (ActivityDefinition) → `ICRCampaign` (CarePlan) → `ICRCampaignTask` (one Task per visit) → `ICRImmunizationEvent` (Immunization).
- **Delivery strategy as a first-class axis.** OCV is delivered through fixed/temporary posts plus outreach/mobile teams and mop-up. The IG's `delivery-strategy` value set (`fixed-post`, `temporary-post`, `mobile`, `school`, `house-to-house`, `community-directed`) already enumerates these posture options, satisfying GTFCC's distinction between site-based and outreach delivery.
- **Target population & denominator with provenance.** GTFCC coverage is expressed as doses-administered ÷ **persons targeted** ([GTFCC NCP, Indicator 9](https://ncp.gtfcc.org/book-page/monitoring-and-reporting.html)). The IG's `ICRTargetPopulation` (Group actual=false) plus `denominator-source` / denominator-date / `planning-denominator` extensions match this, and the "no denominator without provenance" invariant is exactly what a credible OCV coverage number needs.
- **Administrative vs survey coverage kept separate.** GTFCC reports **administrative coverage** as a routine indicator and treats **coverage surveys** as a separate quality/impact check ([§9 #monit](https://www.choleraoutbreak.org/book-page/section-9-oral-cholera-vaccine.html); [GTFCC NCP](https://ncp.gtfcc.org/book-page/monitoring-and-reporting.html)). This maps directly onto the IG's separate `ICRAdministrativeCoverage` and `ICRSurveyCoverage` MeasureReports and its invariant that the coverage lineages (`administrative`, `survey`, `lqas`, `rcm`) are never merged — directly relevant to OCV's well-known admin-vs-survey gap.
- **Campaign-vs-routine boundary.** GTFCC distinguishes OCV-as-campaign from routine immunization; the IG's `record-origin` firewall (`campaign` / `routine`) captures this.
- **Multi-round container exists.** The two-round structure of OCV (see §3a) can be hung off a single `ICRCampaign` umbrella with round CarePlans via `partOf` — the container is present even if the completion measure is not.
- **Geography multi-system.** OCV targets defined administrative units / hotspots; the IG's `ICRLocation` (admin `partOf` + operational geography + GERS/P-code) supports the hotspot-targeting model GTFCC uses.
- **AEFI is acknowledged.** Section 9 states "passive surveillance of adverse events following immunization should be conducted systematically following national policies" ([§9 #monit](https://www.choleraoutbreak.org/book-page/section-9-oral-cholera-vaccine.html)); the IG already lists AEFI as an acknowledged gap (sibling analyses), so this is a known, not new, item.

---

## 3. Gaps & divergences

### 3a. Things the document requires that the IG does NOT yet represent

1. **Per-round + derived "fully immunized (both doses)" coverage — REAL GAP (general, multi-dose).** OCV is recommended as a **"two-dose regimen, with the two doses given a minimum of 14 days apart"** ([§9 #useoforal](https://www.choleraoutbreak.org/book-page/section-9-oral-cholera-vaccine.html)). GTFCC's headline coverage indicator is "Total number of doses administered for **round 1 and 2**" ÷ "Total number of persons targeted … (round 1 and 2)", target **95%** ([GTFCC NCP, Indicator 9](https://ncp.gtfcc.org/book-page/monitoring-and-reporting.html)). The IG has delivery events and round CarePlans but **no coded "fully immunized" completion measure** and no per-round coverage `Measure` definitions. (The IG already acknowledges that WHO/ICG/ESPEN-aligned `Measure` definitions are missing — this names a concrete OCV instance of that gap.)

2. **Round-1 ↔ round-2 individual linkage under aggregate tallies — REAL GAP (modelling tension).** "Fully immunized" is, individually, *this person got dose 1 and dose 2*. Under the IG's **one-Task-per-visit** invariant and aggregate-tally model, there is **no defined mechanism to link the same person's two visits** (e.g., via finger-marking, a vaccination card ID, or a longitudinal patient/Group reference). Without that, "fully immunized" can only be estimated administratively (min of round totals or a survey), not derived per individual. This is the single most OCV-defining M&E requirement the IG does not yet address.

3. **ICG stockpile as a supply/lot/allocation source — REAL GAP (largely OCV-specific).** OCV is supplied from the **"global OCV stockpile … created in 2013"** ([§9](https://www.choleraoutbreak.org/book-page/section-9-oral-cholera-vaccine.html)), managed by the **ICG** (IFRC, MSF, UNICEF, WHO) ([Gavi](https://www.gavi.org/types-support/vaccine-support/oral-cholera); [WHO 2022](https://www.who.int/news/item/19-10-2022-shortage-of-cholera-vaccines-leads-to-temporary-suspension-of-two-dose-strategy--as-cases-rise-worldwide)). A country submits an **ICG request form** (recommended within **7 days of outbreak confirmation**); the ICG secretariat circulates it to member agencies, who typically **decide within ~2 working days**, after which vaccines are delivered ([WebSearch: Allocation of OCV in Africa / South Sudan first-use](https://journals.plos.org/plosmedicine/article?id=10.1371%2Fjournal.pmed.1001901)). `ICRSupplyDelivery` records a delivery but has **no stockpile-source axis, no ICG-allocation reference, and no lot identifier** tying delivered vaccine back to a stockpile allocation.

4. **Request-to-delivery interval — REAL GAP.** This interval is the operationally critical, famously variable OCV metric (decision in ~2 days, but total request-to-delivery often weeks; ~30 days in the South Sudan first use, longer elsewhere). The IG has no element to capture **request date → allocation date → delivery date** for stockpile reconciliation.

5. **Campaign cost / cost-per-fully-immunized-person — REAL GAP (general).** GTFCC recommends standardized costing via **CholTool**, an IVI/WHO/DOVE Excel tool that outputs **cost per fully immunized person** ([CholTool, PMC8641596](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8641596/)); published figures include ~US$5.64/FIP (Ethiopia) and US$7.14 financial / US$8.75 economic per fully vaccinated person (Malawi). The IG has **no campaign-cost axis at all** — no financial-vs-economic split, no cost-by-activity, no cost-per-FIP.

6. **OCV campaign sub-type (reactive / preventive / humanitarian) — REAL GAP (OCV-relevant, generalizable).** Section 9, Gavi, and the ICG all treat three campaign triggers as distinct: **outbreak/reactive response**, **preventive** vaccination in endemic hotspots, and **humanitarian-crisis** use ([§9](https://www.choleraoutbreak.org/book-page/section-9-oral-cholera-vaccine.html); [Gavi](https://www.gavi.org/types-support/vaccine-support/oral-cholera)). The split matters for supply (emergency vs non-emergency stockpile) and is itself a GTFCC indicator — "doses administered in the context of an outbreak" ÷ total ([GTFCC NCP, Indicator 11](https://ncp.gtfcc.org/book-page/monitoring-and-reporting.html)). The IG's `campaign-type` has no sub-type / trigger axis.

7. **Single-dose strategy — REAL GAP (OCV-specific).** In supply shortage the ICG **suspended the two-dose regimen in favour of a single dose** in 2022 ([WHO 2022](https://www.who.int/news/item/19-10-2022-shortage-of-cholera-vaccines-leads-to-temporary-suspension-of-two-dose-strategy--as-cases-rise-worldwide)); a single dose gives shorter protection ("at least 6 months" vs "at least 3 years" for two doses, [§9](https://www.choleraoutbreak.org/book-page/section-9-oral-cholera-vaccine.html)). The IG cannot express a **campaign-level dosing regimen (1-dose vs 2-dose)** as a planned attribute of the campaign/protocol, which changes the meaning of "fully immunized" for that campaign.

### 3b. Things the IG models that the document treats differently (or contradicts)

- **"Fully immunized" semantics — MODELLING CHOICE the IG must make explicit.** For OCV, "fully immunized" is **regimen-dependent**: two doses normally, but one dose during the 2022 single-dose period. The IG would need its fully-immunized measure to be **parameterised by the campaign's declared regimen**, not hard-coded to two doses — otherwise a single-dose campaign's coverage is mis-stated. This is a definitional contrast, not a contradiction.
- **No OCV/cholera campaign-type code — MODELLING CHOICE (assess).** The IG deliberately routes OCV through `vaccination-sia`. For the *delivery* shape this is adequate and arguably correct (avoids code proliferation). But it loses the trigger/regimen/stockpile distinctions above, which GTFCC reports on. Recommendation in §5: keep `vaccination-sia` but add orthogonal sub-type + regimen + supply-source axes rather than a new top-level `ocv` type.
- **AEFI timing.** GTFCC guidance is that AEFI analysis "should be completed **3 weeks after the second round**" ([WebSearch: GTFCC AEFI M&E guidance](https://www.gtfcc.org/resources/monitoring-and-evaluation-of-aefi-during-ocv-mass-vaccination-campaigns/)). This is consistent with the IG treating AEFI as an acknowledged gap — not a contradiction, but it confirms AEFI must be round-aware when added.

---

## 4. Terminology comparison

| OCV source term | ICR IG equivalent | Aligns / Varies / Missing | Note |
|---|---|---|---|
| Oral cholera vaccine (OCV) | `campaign-type = vaccination-sia` + Immunization vaccineCode | **Varies** | No `ocv`/`cholera` code; subsumed under generic SIA ([§9](https://www.choleraoutbreak.org/book-page/section-9-oral-cholera-vaccine.html)) |
| Round 1 / Round 2 | `ICRCampaign` rounds via `CarePlan.partOf` | **Aligns (container only)** | Container exists; per-round coverage `Measure` missing ([GTFCC NCP Ind.9](https://ncp.gtfcc.org/book-page/monitoring-and-reporting.html)) |
| Fully immunized (both doses) | — | **Missing** | No derived completion measure; no round1↔round2 linkage |
| Vaccination post (fixed / temporary) | `delivery-strategy = fixed-post` / `temporary-post`; `location-type = temporary-post` | **Aligns** | Posture covered |
| Vaccination team / mobile / house-to-house / mop-up | `delivery-strategy = mobile` / `house-to-house` / `community-directed` | **Aligns** | Mop-up = a further pass / strategy, representable; no explicit "mop-up" code |
| ICG / global OCV stockpile | `ICRSupplyDelivery` (delivery only) | **Missing** | No stockpile-source / ICG-allocation / lot axis ([Gavi](https://www.gavi.org/types-support/vaccine-support/oral-cholera)) |
| Reactive / preventive / humanitarian campaign | — | **Missing** | No campaign sub-type / trigger axis ([§9](https://www.choleraoutbreak.org/book-page/section-9-oral-cholera-vaccine.html)) |
| Single-dose vs two-dose strategy | — | **Missing** | No campaign-level regimen attribute ([WHO 2022](https://www.who.int/news/item/19-10-2022-shortage-of-cholera-vaccines-leads-to-temporary-suspension-of-two-dose-strategy--as-cases-rise-worldwide)) |
| Target population / persons targeted | `ICRTargetPopulation` + `denominator-source` | **Aligns** | Provenance enforced |
| Administrative coverage | `ICRAdministrativeCoverage` (`coverage-source = administrative`) | **Aligns** | Matches GTFCC Indicator 9 |
| Coverage survey | `ICRSurveyCoverage` (`coverage-source = survey` / `lqas`) | **Aligns** | Kept separate from admin |
| AEFI | — (acknowledged gap) | **Missing (acknowledged)** | Must be round-aware when added |
| Cost per fully immunized person (CholTool) | — | **Missing** | No cost axis at all ([CholTool](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8641596/)) |

---

## 5. Proposed terminology additions (flag for the IG)

1. **Keep `vaccination-sia`; do NOT add a top-level `ocv`/`cholera` campaign-type.** The delivery shape is the SIA shape; the OCV-specific facts are better carried as **orthogonal axes** (below) so they also serve future stockpile vaccines (measles, meningitis, YF). Document this decision explicitly in the IG (it is currently implicit). *Where:* `campaign-type` CodeSystem notes.

2. **Add a `dosing-regimen` axis + a derived `fully-immunized` coverage measure.** New extension on `ICRCampaignProtocol`/`ICRCampaign`, e.g. `dosing-regimen = {single-dose, two-dose}`, plus a `Measure` for **fully-immunized coverage** whose numerator is regimen-aware. *Where:* new extension on protocol/CarePlan + new `Measure` profile alongside `ICRAdministrativeCoverage`.

3. **Add a `supply-source` / stockpile axis on `ICRSupplyDelivery`.** New value set `supply-source = {icg-stockpile, national, gavi, other}` plus optional `stockpile-allocation` reference and lot identifier, so delivered OCV reconciles to an ICG allocation. *Where:* extensions on `ICRSupplyDelivery`.

4. **Add a `campaign-trigger` / sub-type axis.** `campaign-trigger = {reactive-outbreak, preventive, humanitarian}` — mirrors GTFCC's emergency-vs-preventive reporting and ICG emergency/non-emergency stockpile split. *Where:* extension on `ICRCampaign` / `ICRCampaignProtocol`.

5. **Add a `request-to-delivery` interval representation.** Capture `request-date`, `allocation-date`, `delivery-date` for stockpile reconciliation. *Where:* extension on `ICRSupplyDelivery` or a small stockpile-request profile (could reuse a `SupplyRequest`).

6. **Add a `dose-sequence` / round coding on delivery events.** Ensure `ICRImmunizationEvent` carries dose sequence (1 vs 2) and a round reference so per-round denominators are computable. *Where:* `ICRImmunizationEvent` (Immunization.protocolApplied.doseNumber + CarePlan/round reference).

---

## 6. Categories / value sets worth adding

- **Dose/round completion measure** (`single-dose`, `two-dose`; derived `fully-immunized`). **Belongs in the IG** — general to all multi-round campaigns (also MDA multi-round), not just OCV. High priority.
- **Supply / stockpile source** (`icg-stockpile`, `national`, `gavi`, `other`) with allocation + lot linkage. **Belongs in the IG** — cholera makes it salient, but it generalises to any stockpile vaccine. High priority.
- **Campaign cost** — a costing value set: cost basis (`financial`, `economic`), cost category (by activity), and headline `cost-per-fully-immunized-person`, aligned to **CholTool** outputs ([CholTool](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8641596/)). **Belongs in the IG** as a new optional analytics axis — general (every campaign has a cost), currently entirely absent.
- **Campaign trigger** (`reactive-outbreak`, `preventive`, `humanitarian`). **Belongs in the IG** — small, cheap, and directly mirrors a GTFCC indicator ([GTFCC NCP Ind.11](https://ncp.gtfcc.org/book-page/monitoring-and-reporting.html)).
- **Mop-up** as an explicit delivery-strategy/round qualifier. **Optional** — likely representable today as an extra pass; add a code only if reporting needs to distinguish mop-up doses.

---

## 7. Use cases not yet identified in the IG

1. **Two-round OCV campaign with per-round + fully-immunized coverage and round1↔round2 individual linkage.** *Resources:* `ICRCampaign` (umbrella) + two round `CarePlan`s via `partOf`; `ICRImmunizationEvent` with dose sequence; a new regimen-aware **fully-immunized `Measure`**; an individual linkage mechanism (vaccination-card/Group reference) under the one-Task-per-visit model. **Not currently expressible end-to-end.**
2. **ICG request → allocation → delivery reconciliation.** *Resources:* a stockpile-request profile (`SupplyRequest`) + `ICRSupplyDelivery` with `supply-source = icg-stockpile`, allocation reference, lot, and request/allocation/delivery dates. **Not currently expressible.**
3. **Cost-per-fully-immunized-person reporting.** *Resources:* a new cost analytics profile (MeasureReport-style) carrying financial vs economic cost, cost-by-activity, and cost-per-FIP, aligned to CholTool. **Not currently expressible.**
4. **Reactive, outbreak-triggered OCV.** *Resources:* `campaign-trigger = reactive-outbreak` on `ICRCampaign`, linked to the outbreak event and the 7-day ICG request recommendation. **Not currently expressible (trigger axis missing).**
5. **Single-dose strategy in a supply-constrained setting.** *Resources:* `dosing-regimen = single-dose` on the protocol, which redefines the fully-immunized numerator for that campaign. **Not currently expressible.**

---

## 8. Bottom line

**Is the IG adequate for an OCV campaign?** As a **data container, yes** — `vaccination-sia` plus the IG's delivery-strategy, denominator-provenance, record-origin, and dual admin/survey coverage machinery captures the posts-and-teams shape of an OCV campaign correctly. As a vehicle for **GTFCC/ICG OCV reporting, not yet** — the three things that make OCV *OCV* (two-dose completion, stockpile supply, cost) are all unrepresented.

**Top recommended IG changes:**
1. Add a **regimen-aware "fully immunized" coverage `Measure`** plus per-round dose-sequence coding, and define a round1↔round2 **individual-linkage** mechanism under the one-Task-per-visit model. *(Most important; OCV-defining.)*
2. Add a **supply-source / stockpile axis** on `ICRSupplyDelivery` (ICG / national / Gavi) with allocation + lot linkage and a **request→allocation→delivery** interval.
3. Add a **campaign-cost axis** (financial vs economic, by activity, **cost-per-FIP**, CholTool-aligned).
4. Add a **campaign-trigger sub-type** (reactive / preventive / humanitarian) and a **dosing-regimen** attribute (single- vs two-dose); document that `vaccination-sia` is retained rather than adding an `ocv` type.

**OCV-specific vs general:** the **stockpile/ICG** axis and **single-dose/two-dose regimen** are OCV-driven (though the stockpile axis generalises to other stockpile vaccines). **Multi-dose/round completion** and **campaign cost** are **general** IG gaps that OCV merely makes unavoidable — they will recur for any multi-round or any costed campaign, so fixing them serves the whole IG, not just cholera.
