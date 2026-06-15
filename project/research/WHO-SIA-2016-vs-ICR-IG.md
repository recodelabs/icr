# WHO SIA Guide (2016) vs ICR FHIR IG — Alignment & Gap Analysis

This analyzes WHO's *Planning and Implementing High-Quality Supplementary Immunization Activities for Injectable Vaccines (Using an Example of Measles and Rubella Vaccines): Field Guide* (WHO, 2016, ISBN 978 92 4 151125 4; 212 pp.) — a planning/implementation/M&E field guide for injectable-vaccine SIAs — against the proposed **ICR (Integrated Campaign Registry) FHIR R4 IG** (IG v0.1.0 / explainer v0.7.0, canonical `https://fhir.icr.unicef.org`). Page numbers cite the WHO PDF.

---

## 1. Executive summary

The ICR IG's core architecture is strongly validated by this document. The SIA the guide describes is, in ICR terms, a **vaccination-sia** campaign run as a versioned plan (the "field guide" / macroplan / microplan) that is executed as orders (vaccination posts and house-to-house teams), produces per-child **delivery events** (vaccinations recorded on tally sheets and home-based records), and is measured by **two strictly separate coverage lineages** — administrative coverage from tally sheets (p.116, 118) and an independent coverage survey (p.131). The guide independently arrives at almost every ICR design invariant: delivery strategy as a first-class typology that "categorize[s] the population to be vaccinated" (p.28); a firewall between SIA and routine doses ("SIA doses are additional doses and should not be recorded or counted as routine doses", p.107); "no denominator without provenance" ("the source [should be] clearly specified", "if different population figures are available, the highest should be used", p.19, 50); a real-time-vs-reconciled split realized as **formal vs informal** reporting channels that "should be kept separate" (p.120); and geospatial identity via operational maps overlaid on the catchment/admin hierarchy with GPS (p.49, 127). The IG is a good fit for this domain.

The most important gaps are **not in the spine but in the surrounding axes the guide treats as first-class and the IG does not yet model**. The guide is built around an explicit **time-phased campaign lifecycle** (15–12 months / 12–9 / 9–6 / 6–2 / 8 weeks–1 day / implementation / 1–2 weeks after, with gated "readiness assessment" at 12/9/6/3/2 months and 8/4/2/1 weeks — p.91–93, 132). It elevates **SIA type** (catch-up / follow-up / speed-up / mop-up / rolling/phased, p.18, glossary p.VIII–IX) as a distinct concept from delivery strategy. It makes **AEFI surveillance** (5-way CIOMS/WHO causal classification, p.84) and **vaccine wastage/stock** (WMF, vials received/opened/discarded/returned, p.51, 118, 186) mandatory operational data with their own forms. And its **RCM** instrument carries a coded reasons-for-non-vaccination list and a coded refusal sub-list (p.191) that only partly matches the IG's `missed-reason` and `noncompliance-reason` CodeSystems.

Highest-value additions: (1) a **campaign-phase / readiness** axis; (2) an **SIA-type** value set distinct from delivery strategy; (3) reconciling `missed-reason`/`noncompliance-reason` codes with the WHO RCM lists, and adding **"already-vaccinated"** and **"plan-to-go-later"** as non-missed dispositions; (4) a **vaccine wastage / vial-accountability** axis; (5) an **AEFI** profile + causal-classification value set; (6) explicit modelling of the **independent-monitoring (RCM) pass/fail** instrument as something distinct from both administrative coverage and a probability coverage survey.

---

## 2. Where the document ALIGNS with the IG

**Architecture (Plan→Order lifecycle, umbrella + per-area CarePlans).** The guide is structured exactly as a reusable template (the field guide itself, "a reference for the preparation of regional/national SIA field guides", p.2) → a national **macroplan**/operational plan (p.35) → **district/health-centre microplans** aggregated "bottom-up… collated sequentially upward" (p.47–48) → daily execution. This maps cleanly to **ICRCampaignProtocol** (template), **ICRCampaign** umbrella CarePlan (`plan`) with per-district/per-area child CarePlans (`partOf`), transitioning to `order` at execution. The "macroplan distribution of strategies (% of target by strategy)" decided nationally and "modified during the microplanning stage" (p.28) is exactly a protocol→campaign refinement.

**One Task per visit; per-person detail in delivery events.** The guide's atomic field unit is the **vaccination post / session** or a **house-to-house canvasser's area of responsibility** (p.99–101, 160), not the individual. Each post produces a **tally sheet per site per day** (p.117–118) — i.e. a visit-/session-level unit of work — while each child served is a tally mark / home-based-record line (a delivery event). This directly supports **ICRCampaignTask = one Task per visit** with persons hanging off `Task.output` as **ICRImmunizationEvent**s. The guide even reserves person-level chasing for the missed/zero-dose child (RCM finds unvaccinated children "so they can be targeted during mop-up", p.129; record name + house location of zero-dose children "so the child can be enrolled in routine immunization", p.189) — matching the IG's person-focused Task being reserved only for missed/zero-dose chasing.

**Campaign type & integration.** The guide explicitly anticipates **integrated / multi-intervention** campaigns: vitamin A, deworming (mebendazole), OPV bundled with MCV (p.33, 101, 117), and bednet (ITN) integration is cited in the bibliography (Goodson et al., *Improved equity… integrating insecticide-treated bednets in a vaccination campaign, Madagascar*, p.139). This validates ICR's `campaign-type` codes `vaccination-sia`, `vitamin-a`, and `integrated`, and the cross-intervention scope (MDA-style deworming sits alongside vaccination). Separate tally sheets per intervention with **consistent age-group cut-offs** (p.117) supports separate delivery-event profiles (Immunization vs MedicationAdministration vs SupplyDelivery) keyed to a shared denominator.

**Delivery strategy is first-class & coded.** §5.2.7 (p.28) instructs planners to "categorize the population to be vaccinated according to the appropriate SIA strategy": **fixed or mobile posts alone / fixed or mobile posts with house-to-house canvassing / house-to-house vaccination**, with site sub-types **fixed permanent post, fixed temporary post, mobile post, school/preschool** (glossary p.VIII–IX; Annex 5c). The microplan even targets "by vaccination site (e.g. permanent fixed (health facility), temporary fixed or mobile sites)" (p.151). This validates ICR `delivery-strategy` (`fixed-post`, `temporary-post`, `mobile`, `school`, `house-to-house`) and `location-type` (`facility`, `temporary-post`, `school`, `household`, `community-distribution-point`), and the Type A/B/C typology (Type A site-based = fixed/temporary/school; Type B house-to-house).

**Microplanning / denominators with provenance.** "Size of the targeted group should be taken from official sources (e.g. last census)… In case of multiple sources, the larger figure should be used and the source clearly specified" (p.19); denominators may come from census, BCG/DTPCV1 administrative counts, local head-counts/community registers, or line-listing of children by household (p.50). This validates ICR `denominator-source` (`census`, `census-projection`, `microcensus`, `hmis`, `other`) and the **denominator source + date** extension. The microplan targets "by age group… by geographic area… and by vaccination site" (p.151) validate **ICRTargetPopulation** (Group actual=false) stratified by age band, geography, and strategy.

**Administrative coverage vs survey coverage — kept strictly separate.** The guide gives an explicit **administrative coverage** formula (vaccinated ÷ microplan target × 100, p.118) and a separate **coverage survey** "to assess the coverage reached… and validat[e] it" (p.131), plus **RCM** as an explicitly *non*-coverage pass/fail tool ("RCM is a pass/fail assessment… not a coverage assessment… do not produce valid coverage estimates", p.114, 189). This is a near-perfect endorsement of ICR keeping **ICRAdministrativeCoverage** and **ICRSurveyCoverage** as separate MeasureReports, and of the `coverage-source` value set (`administrative`, `survey`, `lqas`, `rcm`).

**Real-time vs reconciled (data lineage).** "Data communicated 'informally' (e.g. phone, SMS) should be kept separate from data shared 'formally' (e.g. paper, faxed, scanned… forms)… reported separately" to avoid double counting (p.120), and the summary form has a **"Source of report (F=Formal, I=Informal)"** and **"Final report (Y/N)"** field (Annex 9f, p.188). At end of SIA all tally sheets are "compiled for final tabulation (and verification)… compared… to check for discrepancies" (p.121). This is exactly ICR's `data-lineage` = `realtime` vs `reconciled` filtered through one structure.

**Record origin firewall.** "Note that SIA doses are additional doses and should not be recorded or counted as routine doses" (p.107); the zero-dose tally explicitly separates "M or MR vaccine during SIA" from "during RI services" (Annex 9e, p.187). Direct support for the mandatory `record-origin` = `campaign` vs `routine` flag on every delivery event.

**Geography (operational overlay + multi-system identity + GPS).** Catchment areas defined with "Google maps or other electronic mapping systems… to create precise operational maps of health facility catchment areas to clearly define the areas of responsibility" (p.49); canvasser areas defined by maps/diagrams with landmarks (Annex 5a, p.160); GPS used "to check vaccination team movements and which geographic areas have been covered" (p.127). This supports **ICRLocation** with admin hierarchy (`partOf`) + operational geography overlay + geospatial identity, and the `target-geography` / `operational-area` / `supervisory-area` location types.

**Missed / refusal reasons.** RCM records, per household, **reason(s) for being unvaccinated** and, if refusal, a **refusal sub-reason** (p.191) — exactly the two-level structure ICR models with `missed-reason` + `noncompliance-reason`. (Code-level reconciliation in §4–5.)

---

## 3. Gaps & divergences

### 3a. Things the document requires that the IG does NOT yet represent

- **Campaign phase / time-phased lifecycle & readiness gating (real gap).** The entire guide is organized by a countdown lifecycle (15–12 mo planning, 12–9, 9–6, 6–2 preparation, 8 wk–1 day pre-implementation, implementation, 1–2 wk post — p.14, 42, 46, 62, 94, 98, 128) with **SIA Readiness Assessment** at 12/9/6/3/2 months and district visits at 8/4/2/1 weeks producing a Yes/No dashboard with % of activities complete (p.91–93). The IG has CarePlan status (`draft`/`active`/`completed`) but no coded **campaign-phase** axis and no **readiness/preparedness** structure. Recommend a `campaign-phase` CodeSystem and a readiness-assessment profile (see §6, §7).

- **SIA type as a concept distinct from delivery strategy (real gap).** Catch-up, follow-up, speed-up, **mop-up**, and **rolling/phased (subnational)** SIAs (p.18; glossary p.VIII–IX; p.130) are first-class planning decisions ("Determining type of measles and rubella SIAs", §5.2.3). ICR `campaign-type` captures the *intervention* (`vaccination-sia`) but not the *SIA strategic type*. This is a genuinely missing axis (§5).

- **Vaccine wastage & vial accountability (real gap).** WMF = 100/(100−wastage), default 10% → 1.11 (p.51); every tally/summary form tracks vials **Received / Opened / Not usable / Returned (good condition)** (p.186, 188); cross-checks compare doses delivered to vials opened (p.122); wastage is a post-SIA indicator and a final-report field (p.128, 134). The IG has no wastage/stock-accountability axis. Recommend a wastage/commodity-accountability extension or profile (§6).

- **AEFI surveillance (real gap, partly acknowledged as "Consent/JAP-aligned Measures" scope but not AEFI specifically).** AEFI is a major operational stream: the 5-type CIOMS/WHO causal classification (vaccine-product-related, vaccine-quality-defect, immunization-error-related, immunization-anxiety-related, coincidental — p.84), serious-AEFI criteria, line-listing, clustering detection by location/time, a dedicated reporting form (Annex 7a) and reporting flow (Fig.10.1, p.86). No ICR profile or value set covers AEFI (§6, §7).

- **Supervision / monitoring / quality-assurance data (real gap).** Supervisory checklists (Annexes 9b/9c), "% of vaccination posts assessed by supervisors", "% sites with no shortfalls", "% sites where used syringes immediately placed in safety boxes", VVM stage observations, etc. (p.133) are structured monitoring observations with targets. The IG has no supervision/QA profile (an Observation or MeasureReport family) (§6).

- **Independent monitoring (RCM) as a distinct pass/fail instrument (partly modelled).** ICR has `coverage-source = rcm` and `sample-design`, but RCM here is explicitly **not** a coverage estimate — it is a 15-household pass/fail trigger tool with specific triggers (<14/15 HHs fully vaccinated; <90% in-house; <90% out-of-house — p.115) and "skip-house" walk rules (p.190). The IG should be explicit that an RCM MeasureReport carries pass/fail + triggers, not a coverage rate, and that it is not a probability survey (§7).

- **Zero-dose identification as RI-strengthening output (partly modelled).** The optional zero-dose tally (Total RI subtracted from Total SIA for 12–23 mo: "Zero dose children = A2 − B", p.187) and the named/located zero-dose child handed to RI services (p.189) are explicit workflows. ICR's person-focused missed-child Task is the natural home, but the **zero-dose computation and hand-off to routine** is a use case not yet shown (§7).

- **Social mobilization / communication & demand (real gap).** Advocacy, social mobilization, community engagement, IPC, KABP surveys, caregiver-awareness monitoring ("% of caregivers who can identify the target disease, campaign dates, venues and target age groups", target 95%, p.132–133) are a whole subcommittee's worth of structured activity and a pre-SIA indicator. The IG has no demand/social-mobilization axis (§6).

- **Security-compromised / access-strategy axis (real gap).** Annex 4 (p.157–159) defines coded access approaches (community-acceptance/trust, opportunistic vaccination, protected campaigns, negotiated access) and operational strategies (remote management, permanent teams, shortened immunization days, fire-walling/transit points, health camps, discrete activities). These imply location types and strategies (transit-point, health-camp, IDP-camp) not in ICR (§5, §6).

### 3b. Things the IG models that the document treats differently (or contradicts)

- **Delivery strategy vs site type granularity.** ICR collapses "fixed permanent" and "fixed temporary" into `fixed-post` + `temporary-post`, but the guide and microplan distinguish **permanent fixed (health facility)** vs **temporary fixed (school/church/mosque/admin office)** vs **mobile** at the *site* level (p.151, glossary). ICR's `location-type` (`facility` vs `temporary-post`) covers this — but note the guide treats "house-to-house canvassing" as an **add-on to a fixed/mobile post**, not a standalone strategy: "fixed or mobile posts **with** house-to-house canvassing" is distinct from "house-to-house **vaccination**" (p.28). ICR's single `house-to-house` code conflates *canvassing* (Type A demand-generation, vaccination still at post) with *house-to-house vaccination* (Type B, dose given at the door). This is a **modelling choice to revisit** — canvassing should arguably be a strategy modifier/extension, not folded into `house-to-house`.

- **`community-directed` strategy.** ICR includes `community-directed` (for MDA/Type C). The injectable-SIA guide does **not** use community-directed delivery (injections require trained HCWs, p.56), so this code is simply out of scope here — not a contradiction, but a reminder that this document cannot validate the MDA half of the IG.

- **Coverage denominator caution.** The guide repeatedly warns administrative coverage is unreliable because of denominator error ("inaccurate microplanning estimates… denominator problem", p.123) and even >100% coverage from population underestimates; it recommends analysing **proportion reached by strategy or age group** rather than vs total population (p.124). ICR models the denominator with provenance but should ensure ICRAdministrativeCoverage can be **stratified by strategy and age band** and can carry a data-quality/caveat flag — a refinement, not a contradiction.

---

## 4. Terminology comparison

| WHO document term (p.X) | ICR IG equivalent | Aligns / Varies / Missing | Note |
|---|---|---|---|
| Supplementary immunization activity (SIA) / mass-immunization campaign (p.1, VIII) | `campaign-type = vaccination-sia` | Aligns | Core synonym. |
| Catch-up SIA (p.18, VIII) | — | Missing | New SIA-type axis. |
| Follow-up SIA (p.18, IX) | — | Missing | New SIA-type axis. |
| Speed-up SIA (rubella) (p.18, IX) | — | Missing | New SIA-type axis. |
| Mop-up activities / mop-up SIA (p.130, VIII) | — | Missing | New SIA-type / phase; revaccination round. |
| Rolling / phased / subnational SIA (p.18) | per-area CarePlans (`partOf`) | Varies | Geography modelled; "rolling" rounds not a coded type. |
| Fixed (permanent) vaccination post (p.VIII, 151) | `delivery-strategy = fixed-post`; `location-type = facility` | Aligns | "Permanent = health facility". |
| Fixed temporary vaccination post (p.VIII, 151) | `delivery-strategy = temporary-post`; `location-type = temporary-post` | Aligns | School/church/mosque/admin office. |
| Mobile vaccination post (p.IX) | `delivery-strategy = mobile` | Aligns | |
| Fixed/mobile post **with** house-to-house **canvassing** (p.28, 160) | `delivery-strategy = house-to-house` (conflated) | Varies | Canvassing ≠ door vaccination; should be a modifier. |
| House-to-house **vaccination** (p.28, 163) | `delivery-strategy = house-to-house` | Aligns | Type B; dose given at door. |
| Vaccination at schools/preschools/day care (Annex 5c) | `delivery-strategy = school`; `location-type = school` | Aligns | |
| Transit points / border crossings / IDP camps / health camps (p.20, 158) | — | Missing | New location types / access strategy. |
| Microplanning / microplan (p.47) | ICRCampaign (`plan`) + ICRTargetPopulation | Aligns | Bottom-up aggregation. |
| Macroplanning / operational plan (p.35) | ICRCampaignProtocol / umbrella CarePlan | Aligns | |
| Target population / target age group (p.19, 50) | ICRTargetPopulation (Group actual=false) | Aligns | Stratified by age band. |
| Denominator: last census (p.19) | `denominator-source = census` | Aligns | |
| Denominator: BCG / DTPCV1 admin counts (p.50) | `denominator-source = hmis` | Aligns | Closest fit. |
| Denominator: community head-count / register / line-listing (p.50) | `denominator-source = microcensus` | Aligns | |
| "Source… clearly specified… larger figure used" (p.19) | denominator source+date extension | Aligns | Provenance invariant confirmed. |
| Administrative coverage (p.118) | `coverage-source = administrative`; ICRAdministrativeCoverage | Aligns | Formula matches. |
| Coverage survey (post-SIA) (p.131) | `coverage-source = survey`; ICRSurveyCoverage | Aligns | |
| Rapid convenience monitoring (RCM) (p.114, VIII) | `coverage-source = rcm` | Aligns (but) | RCM is pass/fail, not coverage — flag in profile. |
| LQAS | `coverage-source = lqas` | Missing in doc | Not used in this guide (uses RCM). |
| Independent monitoring / independent monitors (p.129) | `coverage-source = rcm` (post-SIA) | Aligns | Same RCM method, post-SIA, by independent monitors. |
| Formal vs informal reporting (p.120, 188) | `data-lineage = reconciled` vs `realtime` | Aligns | Strong match. |
| SIA doses "additional… not routine" (p.107) | `record-origin = campaign` vs `routine` | Aligns | Firewall confirmed. |
| Zero-dose children (p.118, 187) | person-focused missed-child Task | Aligns (partial) | Computation/hand-off use case missing. |
| RCM reason: absent/away from home (p.191) | `missed-reason = absent` | Aligns | |
| RCM reason: unaware of campaign/post location (p.191) | — | Missing | New `missed-reason` (≈ awareness/social-mob gap). |
| RCM reason: post too far away (p.191) | `missed-reason = inaccessible`? | Varies | Distance/access, not strictly "inaccessible". |
| RCM reason: post had no vaccine (p.191) | — | Missing | New `missed-reason = stockout/post-no-vaccine`. |
| RCM reason: plan to go later today/tomorrow (p.191) | — | Missing | A *non-missed* pending disposition. |
| RCM reason: child already vaccinated (p.191) | n/a (not missed) | Missing | Disposition = already-vaccinated, not "missed". |
| RCM reason: refusal (p.191) | `missed-reason` → `noncompliance-reason` | Aligns | Two-level structure matches. |
| RCM reason: sick (as missed reason in main glossary; p.191 puts "sick" under refusal-reason 1) | `missed-reason = sick` | Varies | WHO files "child was sick" under *refusal* sub-reasons. |
| Refusal sub-reason: religious beliefs (p.191) | `noncompliance-reason = religious-objection` | Aligns | |
| Refusal sub-reason: fear of vaccine (p.191) | `noncompliance-reason = safety-concern` | Aligns (≈) | "Fear" ⊇ safety-concern + misinformation. |
| Refusal sub-reason: respondent doesn't make that decision (p.191) | — | Missing | New `noncompliance-reason = not-decision-maker`. |
| Refusal sub-reason: other / don't know-declined (p.191) | `noncompliance-reason = other` | Aligns | Add explicit `unknown/declined`. |
| Missed reason: sleeping / not-visited (IG) | — | Not in doc | IG-only codes; not contradicted. |
| AEFI (p.84) | — | Missing | New profile + causal value set. |
| Wastage / WMF / vials received-opened-discarded-returned (p.51, 186) | — | Missing | New wastage/accountability axis. |
| SIA Readiness Assessment / dashboard (p.91) | — | Missing | New readiness profile + phase axis. |
| Supervisory checklist / supervision visit (p.113, 133) | — | Missing | New supervision/QA profile. |
| Daily cumulative administrative coverage (p.123) | ICRAdministrativeCoverage (time series) | Aligns | Daily + cumulative reporting. |
| GPS / electronic operational maps (p.49, 127) | ICRLocation operational geography | Aligns | |
| Special / hard-to-reach / underserved populations (p.22) | Group / target-geography overlays | Varies | No coded "population-vulnerability" axis. |
| Disease surveillance (case-based, by location/time/age/vaccination status) (p.135) | out of scope | Missing | Separate VPD surveillance domain. |

---

## 5. Proposed terminology additions (flag for the IG)

**To `missed-reason` CodeSystem** (justified by the RCM in-house reasons list, p.191):
- `unaware-campaign` — "Unaware of the campaign/location of post" (p.191). Distinct from absent; signals a social-mobilization gap.
- `post-distance` / `post-too-far` — "Vaccine post too far away" (p.191). The IG's `inaccessible` is broader (terrain/security); distance-to-post is a distinct, actionable reason.
- `post-stockout` — "Vaccine post did not have vaccine" (p.191). A supply-side miss, not a person-side one.
- Consider splitting the IG's current single concept so that **pending dispositions** are *not* coded as "missed":
  - `plan-to-go-later` — "Plan to go later today/tomorrow" (p.191) — pending, not missed.
  - `already-vaccinated` — "Child is already vaccinated" (p.191) — a non-event disposition, not a miss.
- Note WHO files **"child was sick"** under *refusal* sub-reasons (p.191), whereas ICR lists `sick` as a `missed-reason`. Decide a single home and document the mapping.

**To `noncompliance-reason` (refusal) CodeSystem** (RCM refusal sub-list, p.191):
- `not-decision-maker` — "Respondent does not make that decision" (p.191). Common, actionable; absent from ICR.
- `fear-of-vaccine` — "Fear of vaccine" (p.191). ICR has `safety-concern` and `misinformation`; "fear" may warrant its own code or an explicit map.
- `unknown-declined` — "Do not know/declined to respond" (p.191). ICR has only `other`.

**To `delivery-strategy` / strategy modelling:**
- Add a **canvassing** modifier (extension or boolean) so "fixed/mobile post WITH house-to-house canvassing" (Type A demand-generation) is distinguishable from "house-to-house vaccination" (Type B). Today both collapse to `house-to-house` (p.28).

**To `location-type` CodeSystem** (p.20, 158, 161):
- `transit-point` (border crossings, bus/train stations — used both for delivery and for out-of-house RCM, p.20, 191), `health-camp` (Annex 4, p.158), `idp-camp`/`displacement-site` (p.20). Consider `marketplace`, `workplace` for adolescent/adult SIAs (p.27).

**To `denominator-source`:** add `bcg-dtp1-administrative` (admin proxy from BCG/DTPCV1, p.50) as a named alternative to the generic `hmis`; and `line-list-household` (community line-listing by household, p.50) alongside `microcensus`.

**To `coverage-source` documentation:** clarify that `rcm` carries **pass/fail + trigger** semantics (triggers: <14/15 HHs, <90% in/out-of-house, p.115), and that intra-SIA vs post-SIA-independent are the same method at different times (p.114, 129) — possibly an extension `rcm-timing = intra | post-independent`.

---

## 6. Categories / value sets worth adding

- **Campaign phase / lifecycle (recommend ADD).** A `campaign-phase` CodeSystem: `planning`, `preparation`, `pre-implementation`, `implementation`, `mop-up`, `post-evaluation` — directly from the guide's section structure (p.14–138). Belongs in the IG: it conditions which data elements are expected.
- **Readiness / preparedness assessment (recommend ADD).** A profile (MeasureReport or Observation set) capturing the SIA Readiness Assessment Tool — Yes/No critical-activity completion, % complete, by level and time-point (12/9/6/3/2 mo; 8/4/2/1 wk) (p.91–93). High value for campaign managers; aligns with the IG's acknowledged "Measures aligned to WHO reporting minimums" gap.
- **SIA strategic type (recommend ADD).** `sia-type`: `catch-up`, `follow-up`, `speed-up`, `mop-up`, `outbreak-response`, `rolling-phased` (p.18, 130). Distinct from `campaign-type`.
- **Vaccine wastage / commodity accountability (recommend ADD).** WMF, and per-team/per-site **vials received / opened / not-usable / returned-good** with VVM stage (p.51, 186, 188). Belongs in the IG (cross-cutting for vaccines, drugs, and ITN commodities — supports SupplyDelivery and MedicationAdministration too).
- **AEFI (recommend ADD).** Profile + `aefi-causal-type` value set (vaccine-product-related, vaccine-quality-defect, immunization-error-related, immunization-anxiety-related, coincidental — p.84) + serious-AEFI criteria. Likely AdverseEvent/Observation. High value and broadly reusable across campaign types.
- **Supervision / quality assurance (recommend ADD, scoped).** Supervisory-checklist observations and the during-SIA quality indicators (post assessed, no shortfalls, syringe-in-safety-box, AEFI-procedure-known — p.133). Could be Observation/MeasureReport profiles.
- **Social mobilization / demand (recommend, optional).** Caregiver-awareness indicator (≥95% can identify disease/dates/venues/age, p.132–133), KABP. Lower priority but a genuine pre-SIA data stream.
- **Population vulnerability / access (recommend, optional).** Coded "special population" categories (urban poor, migrant, nomadic, IDP/refugee, conflict-affected, resistant/anti-vaccine, p.22) used to flag groups and pick strategies; plus the Annex 4 access approaches (p.158). Useful as a Group characteristic axis.

---

## 7. Use cases not yet identified in the IG

- **Mop-up round triggered by RCM/coverage (p.129–130).** RCM/independent monitoring fails an area → schedule a revaccination round → record which area, reason, doses in SIA vs mop-up. FHIR: a child **ICRCampaign** CarePlan (`partOf`, status reopened) + Tasks tagged as mop-up, with the triggering RCM MeasureReport referenced. Needs an example.
- **Catch-up vs follow-up vs speed-up SIA (p.18).** Different target-age logic (follow-up = 9–59 mo cohort born since last SIA; speed-up = adolescents/adults). FHIR: ICRCampaignProtocol variants + ICRTargetPopulation age bands; needs `sia-type`.
- **Intra-SIA RCM with corrective action (p.114–116).** 15-HH pass/fail with triggers, then move/split a post or send canvassers. FHIR: ICRSurveyCoverage/RCM MeasureReport (pass/fail + triggers) → Task adjustments. Needs a non-coverage RCM example.
- **Post-SIA independent monitoring + zero-dose hand-off to RI (p.129, 187, 189).** Compute zero-dose (A2−B), name/locate child, enrol in routine. FHIR: person-focused missed-child Task + an Immunization recommendation / referral to routine; demonstrates the `record-origin` firewall end-to-end.
- **AEFI surveillance during a campaign (p.84–88).** Detect, line-list, cluster by location/time, report up the flow. FHIR: AEFI profile linked to the ICRImmunizationEvent and the Task/site; clustering as a MeasureReport/Observation.
- **Vaccine wastage / vial reconciliation (p.51, 122).** Cross-check doses delivered vs vials opened; compute wastage; feed final report. FHIR: wastage extension on the site Task/SupplyDelivery + ICRAdministrativeCoverage cross-check.
- **Readiness gating across the lifecycle (p.91–93).** Dashboard of Yes/No critical activities at each time-point, aggregated up the admin hierarchy. FHIR: readiness MeasureReport per Location per phase.
- **Integrated SIA with separate per-intervention tallies on a shared denominator (p.117).** MCV + vitamin A + deworming + OPV, consistent age cut-offs. FHIR: ICRImmunizationEvent + ICRMedicationAdministration + ICRSupplyDelivery off one visit Task, shared ICRTargetPopulation. A multi-intervention example would exercise the `integrated` type.
- **Coverage survey design distinct from RCM (p.131).** Probability survey with sample design, validating administrative coverage. FHIR: ICRSurveyCoverage with `sample-design`; contrast with RCM pass/fail.
- **Operating in security-compromised areas (Annex 4, p.157).** Access approach, transit-point/health-camp delivery, remote management, periodically revised microplans on population displacement. FHIR: access-strategy/location-type codes + frequent CarePlan revisions.
- **Adolescent/adult & special-setting vaccination (p.27).** Line-list of schools/colleges/workplaces/markets to visit. FHIR: ICRDeliveryUnit as `school-cohort`/institution Group + site Tasks; supports wider age bands.

---

## 8. Bottom line

The IG's model is **adequate and well-aligned** for the core of this document: the plan→order lifecycle, one-Task-per-visit with per-child delivery events, the SIA-vs-routine firewall, denominator provenance, the three-lineage coverage separation (administrative / survey / RCM), formal-vs-informal (realtime-vs-reconciled) data, coded delivery strategies and location types, and operational geography. The guide essentially re-derives the IG's design invariants from field practice.

What's missing is the **operational scaffolding around the spine** that this guide treats as first-class. Top recommended IG changes:

1. **Add a campaign-phase / readiness axis** (`campaign-phase` CodeSystem + a readiness-assessment MeasureReport) — the guide's central organizing concept (p.14–138, 91–93).
2. **Add an `sia-type` value set** (catch-up / follow-up / speed-up / mop-up / outbreak-response / rolling) distinct from `campaign-type` (p.18, 130).
3. **Reconcile `missed-reason` / `noncompliance-reason` with the WHO RCM lists** — add `unaware-campaign`, `post-distance`, `post-stockout`, `not-decision-maker`, `unknown-declined`; and split out non-missed dispositions (`already-vaccinated`, `plan-to-go-later`) (p.191).
4. **Add a vaccine-wastage / vial-accountability axis** (received/opened/not-usable/returned + VVM + WMF) usable across vaccines, drugs, and commodities (p.51, 186).
5. **Add an AEFI profile + causal-classification value set** (5 CIOMS/WHO types, serious-AEFI criteria, clustering) (p.84–88).

Secondary but worthwhile: a supervision/QA profile, a social-mobilization/awareness indicator, population-vulnerability and access-strategy/location codes, and an explicit statement that RCM MeasureReports carry pass/fail+triggers (not coverage). One modelling choice to revisit: distinguish house-to-house **canvassing** (Type A) from house-to-house **vaccination** (Type B), which the IG currently conflates (p.28).
