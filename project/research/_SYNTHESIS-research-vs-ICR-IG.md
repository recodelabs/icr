# Research → ICR IG — Cross-Document Synthesis & Prioritized Change-List

Rolls up the three document analyses in this folder into one decision-ready view: what the WHO field evidence **validates** in the ICR FHIR IG, and a **prioritized list of additions** the IG should consider. Compared against ICR IG v0.1.0 / explainer `ig-info.md` v0.7.0.

**Source analyses (read each for the page-cited detail):**
- [WHO SIA Field Guide (2016), 212 pp](WHO-SIA-2016-vs-ICR-IG.md) — generic injectable-vaccine SIA planning/implementation/M&E.
- [WHO RED Microplanning (WHO/IVB/09.11, 2009), 74 pp](RED-microplanning-vs-ICR-IG.md) — routine-immunization microplanning methodology reused by campaigns.
- [WHO-AFRO Measles SIA Field Guide (2010/11), 95 pp](WHO-AFRO-Measles-Fieldguide-2011-vs-ICR-IG.md) — disease-specific measles SIA + surveillance linkage.

---

## Bottom line

The three documents — written independently, across two decades, for routine RI, generic SIAs, and measles specifically — **converge hard on the same conclusions**. That convergence is the signal:

1. **The IG's spine is validated.** All three re-derive, from field practice, the IG's core design invariants: plan→order lifecycle (macroplan/microplan → execution), **one Task per visit/session** (the atomic field unit is the post/session/canvasser-area, never the individual), the **campaign-vs-routine `record-origin` firewall**, **no denominator without provenance**, **three never-merged coverage lineages** (planned / administrative / independent), realtime-vs-reconciled (formal-vs-informal) data, coded delivery strategies, and operational geography overlaid on the admin hierarchy. No document contradicts the spine.

2. **The gaps are not in the spine — they're in the operational axes around it**, and the same axes recur in all three. These are the high-confidence additions below.

3. **Surveillance is a separate domain to reference, not absorb** (measles guide). ICR should hold a pointer from a Campaign to the surveillance/outbreak signal and the confirmed-case age distribution that triggered/sized it — not model case-based surveillance or lab confirmation itself.

---

## Convergence matrix (recommendation × document)

✓ = the document independently flags it, with its own page cites. (S = SIA-2016, R = RED-2009, M = Measles-2011.)

| Recommended IG addition | S | R | M | Strength |
|---|:--:|:--:|:--:|---|
| **SIA-type** axis (catch-up / follow-up / mop-up / outbreak-response) distinct from `campaign-type` | ✓ | ✓ | ✓ | **P1** |
| **AEFI** profile + 5-category causal value set (CIOMS/WHO) | ✓ | ✓ | ✓ | **P1** |
| **Vaccine wastage / vial-accountability** axis (WMF; received/opened/not-usable/returned; VVM) | ✓ | ✓ | ✓ | **P1** |
| **RCM = pass/fail + triggers**, explicitly *not* a coverage rate (and ≠ probability survey) | ✓ | ✓ | ✓ | **P1** |
| Reconcile **`missed-reason` / `noncompliance-reason`** with WHO RCM field lists | ✓ | ✓ | ~ | **P1** |
| **Campaign-phase / readiness** lifecycle axis (+ readiness MeasureReport) | ✓ | ~ | ✓ | **P2** |
| **Defaulter / dropout / zero-dose** disposition + dropout Measure | ~ | ✓ | ✓ | **P2** |
| **Supervision / QA** profile (checklist observations, coded indicators) | ✓ | ✓ | ✓ | **P2** |
| **Social-mobilization / demand** axis (caregiver-awareness indicator) | ✓ | ✓ | ✓ | **P2** |
| **Population-vulnerability / equity** taxonomy (hard-to-reach categories) | ✓ | ✓ | ✓ | **P2** |
| **Outreach** as a first-class `delivery-strategy` (distinct from mobile/temporary-post) | – | ✓ | ~ | **P2** |
| **Cold-chain / logistics / stock** beyond the SupplyDelivery event | ~ | ✓ | ✓ | **P3** |
| **Access-vs-utilization** problem-category typology (RED Table 2) | – | ✓ | – | **P3** |
| **Surveillance / outbreak / lab** — *reference only*, do not model | – | ~ | ✓ | **Scope decision** |

(~ = touched/implied; – = out of that document's scope.)

---

## Prioritized recommendations

### P1 — strongly convergent (all/most three; cheap, high-value)
1. **`sia-type` CodeSystem + ValueSet** — `catch-up`, `follow-up`, `mop-up`, `outbreak-response`, `rolling-phased`. A coded attribute of ICRCampaignProtocol / ICRCampaign, orthogonal to `campaign-type` (which is the intervention). Drives target-age logic and round structure. (S p.18; M p.10, 75; R p.69 SIA-as-denominator.)
2. **AEFI profile + `aefi-causal-type` ValueSet** — the 5 WHO/CIOMS categories (vaccine-product-related, vaccine-quality-defect, immunization-error-related, immunization-anxiety-related, coincidental) + serious-AEFI criteria + onset timing. Likely `AdverseEvent`/`Observation` linked to the ICRImmunizationEvent + site Task. Broadly reusable across campaign types. (S p.84–88; M p.54–58; R p.38.)
3. **Wastage / commodity-accountability axis** — WMF and per-site/per-team vials received / opened / not-usable / returned + VVM stage; reusable for vaccines, MDA drugs, and ITN commodities (extends SupplyDelivery / MedicationAdministration and feeds ICRAdministrativeCoverage cross-checks). (S p.51, 186; M p.24, 88; R p.34–38.)
4. **Make RCM semantics explicit** — document that an RCM/independent-monitoring MeasureReport carries **pass/fail + trigger thresholds** (e.g. <14/15 HHs; ≥2/20), is *not* an administrative coverage rate, and is *not* a probability `survey`. Possibly an `rcm-timing` (intra vs post-independent) flag. (S p.114–115; M p.71–72; R Annex 1 convenience sample, p.39.)
5. **Reconcile missed/refusal codes with the WHO RCM lists** — add to `missed-reason`: `unaware-campaign`, `post-distance` (post too far ≠ `inaccessible`), `post-stockout`; split out *non-missed* dispositions `already-vaccinated` and `plan-to-go-later`. Add to `noncompliance-reason`: `not-decision-maker`, `unknown-declined`, and decide whether "fear" warrants its own code vs mapping to `safety-concern`/`misinformation`. Decide a single home for **`sick`** (WHO files it under refusal sub-reasons; IG lists it as a missed-reason). (S p.191; R p.32 defaulter.)

### P2 — convergent, larger or more design work
6. **Campaign-phase / readiness** — a `campaign-phase` CodeSystem (`planning`, `preparation`, `pre-implementation`, `implementation`, `mop-up`, `post-evaluation`) plus a **readiness-assessment MeasureReport** (Yes/No critical-activity completion, % complete, by level + time-point). Conditions which data elements are expected. (S p.91–93; M p.18–21.)
7. **Defaulter / dropout / zero-dose** — add a `defaulter`/`overdue`/`partially-immunized` disposition and a **dropout-rate Measure**; multi-dose SIAs and multi-round MDA have the identical "started but didn't complete" problem. Pair with the zero-dose computation + hand-off-to-routine use case. (R Step 8, p.32–33, DO%; M p.70; S p.187.)
8. **Supervision / QA**, **social-mobilization / demand**, and **population-vulnerability / equity** axes — three related operational-data families all three guides treat as first-class (supervisory checklists; ≥95% caregiver-awareness indicator; rural-remote / nomadic / urban-poor / minority / conflict-affected typology). Model as Observation/MeasureReport profiles + a Group `vulnerability` characteristic. (S p.22, 132–133; R p.5, 13, 16, 47–49; M p.31, 59–67.)
9. **`outreach` delivery-strategy** — RED treats outreach (a periodic fixed-location visit reachable in a day) as distinct from `mobile` and from `temporary-post`; add the code + an `outreach-site` location-type. (R p.14–15.)

### P3 — useful, narrower or partly routine-only
10. **Cold-chain / logistics / stock-readiness** axis (stock balance, temperature/VVM, doses-opened) beyond the SupplyDelivery delivery event. (R p.34–38, 61–62; M p.24.)
11. **Access-vs-utilization problem-category** typology (RED Table 2: coverage×dropout → 4 categories) as a coded operational-area diagnosis driving corrective action. (R p.13.)
12. **Location-type additions:** `transit-point`, `health-camp`, `idp-camp`/displacement-site, and consider `marketplace`/`workplace` for adolescent/adult SIAs. **Denominator-source additions:** `head-count`/`enumeration`/`line-list-household`, and `campaign-results` (prior SIA tallies as a denominator source). (S p.20, 158; R p.45, 48, 69; M p.24.)

---

## Scope decision: surveillance & outbreak response — *reference, don't model*
The measles guide's case-based surveillance, lab specimen/confirmation, susceptibility/inter-epidemic modelling, and confirmed-case age-distribution are the **trigger and evaluation context** for a campaign, not its execution data. **Recommendation:** ICR holds a thin reference — the surveillance signal / outbreak that justified the SIA, and the case-age distribution used to set the target age band — and links out to a VPD-surveillance IG (e.g. a measles/rubella case-surveillance profile family). Keep case/lab data out of the ICR campaign IG. (M p.8, 11, 14, 38.)

---

## Modelling choices to revisit (not new axes — refinements)
- **House-to-house *canvassing* vs *vaccination*.** The SIA guide distinguishes "fixed/mobile post **with** house-to-house canvassing" (Type A demand-generation, dose still at the post) from "house-to-house **vaccination**" (Type B, dose at the door). The IG's single `house-to-house` code conflates them; canvassing is arguably a strategy *modifier*, not a strategy. (S p.28.)
- **Administrative coverage stratification.** All three warn administrative coverage is denominator-fragile; ensure ICRAdministrativeCoverage can be stratified by **strategy** and **age band** and can carry a data-quality caveat. (S p.123–124; M p.69; R p.64.)

## Validated — do not change
Plan→order lifecycle; one-Task-per-visit with per-person delivery events; `record-origin` campaign/routine firewall; denominator-with-provenance; the three never-merged coverage lineages; realtime-vs-reconciled; coded delivery strategy; operational-geography-overlays-admin; integrated multi-intervention on a shared denominator. The field evidence strongly endorses the IG's spine.

---

## Caveats on the evidence
- The **RED** document on file is the **2009** edition (WHO/IVB/09.11), not the 2017 revision — flag if the newer edition was intended.
- A few **measles-guide annexes are scanned images** that text-extraction could not render (RCM/AEFI flowcharts, triage card); two of its proposed `missed-reason` codes are inferred from body text rather than a printed code list — weaker evidence than the 2016 guide's explicit RCM list.
- This synthesis compares against the IG as described in `ig-info.md` v0.7.0 + the committed FSH; exact CodeSystem URLs should be confirmed against `ig/input/fsh/` before drafting changes.
