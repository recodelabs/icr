---
version: 0.2.0
last_modified: 2026-07-09T12:27:58Z
tags:
  - icr
  - who
  - alignment
  - terminology
public: false
---

# WHO IDHC Toolkit ↔ ICR IG — Alignment Review
<sub>`v0.2.0 · Last modified Jul 9, 2026 at 8:27 AM EDT`</sub>

> [!note] What this document is
> A comparison of the **WHO AFRO Integrated Digitization of Health Campaigns (IDHC) toolkit** (the PDFs and Excel annexes in `forms/who/`) against the **ICR FHIR IG** (`/ig`) and its companion design doc [[icr-ig]]. It answers three questions: (1) do we align or diverge, (2) what are the gaps in each direction, and (3) which WHO wording should we adopt so the ICR reads as native WHO vocabulary.

* * *

## 1. What we compared

**First, a naming correction:** the "IDHC" in the filenames stands for **Integrated *Digitization* of Health Campaigns** — not "Integrated District Health Campaigns." It is a WHO AFRO + Clinton Health Access Initiative toolkit, **co-branded with UNICEF**, © WHO 2026 (Brazzaville), developed as an extension of WHO's Digital Implementation Investment Guide (DIIG) and drawing on the OpenHIE framework. It was initiated by the Health Campaign Effectiveness Coalition's Campaign Digitization TWG, informed by MoH consultations in Benin, DRC, Kenya, Mozambique and Nigeria.

| In `forms/who/` | Document | What it is |
| --- | --- | --- |
| Toolkit-00 | Introduction | Series overview, rationale, structure |
| Toolkit-01 | Guidance on benefits, priorities, operationalizing | Use-case priorities, governance, **Annex B reference-architecture diagram** |
| Toolkit-02 | Solution selection framework | 4-stage selection process; Fig. 2 use-case taxonomy |
| Toolkit-03 | MLE framework approach | Logic model (IO1–6, PO1–3), indicator bank overview |
| Toolkit-04 | **Reference architecture** | The architecture the IG implements: shared data registries (7 master lists), core services, interoperability layer, guiding principles, **named standards (FHIR, GS1, ICD-11)** |
| Toolkit-05 | Business & functional requirements | Per-workflow inputs/outputs/functional requirements, enumerated-object taxonomy, georegistry rules |
| Toolkit-06 | Costing guidance | Incremental digitization costing; 5 categories × 20 cost drivers |
| Toolkit-07 | Device management guidance | Device lifecycle, quantification, BYOD, country cases |
| Annex 2.1 (xlsx) | Digital solution selection support tool | Weighted scoring matrix; §1 = WHO's canonical 10 campaign workflows |
| Annex 3.1 (xlsx) | MLE framework supplement | **48 indicators (A1–K4)** with definitions, disaggregation, counterfactuals |

> [!note] Still missing from our set
> Annex 2.2 (Digital tool selection guidebook, hosted by UNICEF) and Annex 6.1 (Campaign digitization costing tool). Document 4 was obtained and reviewed for v0.2.0 of this note (§2a below).

Compared against: the SUSHI IG source in `/ig` (17 profiles, 35 extensions, 26 CodeSystems, 8 questionnaires, 6 measures) and [[icr-ig]] v0.27.0.

* * *

## 2. Bottom line

**We align — strongly — but at different altitudes, which makes the two efforts complementary rather than competing.**

- The toolkit is **programme guidance and architecture**: what to digitize, how to select tools, how to govern, cost, and evaluate. It deliberately stops short of a data standard — it names **FHIR** as the data-exchange standard, **FHIR Questionnaire** and **FHIR mADX** as content standards, **GS1** and **ICD-11** as terminology standards (Doc 4 §3.2; Annex 2.1 §4.2), and calls for a **terminology service** and **standardized master lists** — but defines no profiles, no code systems, no record-level data elements.
- The ICR IG is exactly the artifact the toolkit's architecture presupposes but doesn't provide: **the FHIR content standard for the campaign data layer**. Every WHO "master list" and most "digitized campaign activity components" have a direct ICR counterpart (§3).
- The core thesis is the same in both: campaigns re-collect data on **the same populations, households and geographies** every round; a **shared georegistry / registry layer** lets each campaign validate and reuse the last one's data. WHO Annex 3.1 even scores this as indicators (B3 campaign integration, C5 "reuse of digital solution… in multiple campaigns").
- Divergences are mostly **vocabulary** (§4) and **scope edges** (§5): WHO treats Training, Payments and SBC as first-class campaign use cases (ICR doesn't model them); ICR models AEFI/pharmacovigilance, per-event delivery records, coverage lineage and consent (the toolkit never mentions adverse events at all).

> [!tip] Strategic framing
> The toolkit is UNICEF-co-branded — i.e., our client's own reference framework. Positioning the ICR IG as "the FHIR implementation of the IDHC reference architecture's data layer" (and self-scoring the reference platform against Annex 2.1, where it would do well: open source, DPG-track, FHIR-native, APIs) is a cheap, high-value alignment move for Phase 1.

* * *

## 2a. Document 4 (Reference architecture) — the load-bearing findings

Reviewed for v0.2.0 (WHO:AFRO/ARD:2025-10, 18 pp; audience: MoH ICT staff, technology providers, implementing organizations). This is the document the ICR IG most directly implements, and it makes the alignment explicit rather than inferred:

- **Standards are named, and they're ours.** §3.2.1 Content: "**FHIR questionnaire** which defines the structure and content of data collection forms and **FHIR mADX** which standardizes aggregate reports and programmatic monitoring indicators… ensure alignment with existing standards like FHIR." §3.2.2 Data exchange: **FHIR** (and Direct). §3.2.4 Terminology: **GS1** product codes for campaign commodities, **ICD-11** for diagnoses. The ICR already ships SDC Questionnaires, GS1/GTIN commodity coding, and MeasureReport-based aggregate reporting — action: verify our MeasureReports are consumable in the mADX aggregate-exchange pattern, and consider ICD-11 mappings for the NTD disease codes.
- **The architecture "establishes a common vocabulary for campaign digitization"** (§2.2) and requires every master list to carry a **data dictionary** ("structure, definitions, relationships and attributes of data elements"). That common-vocabulary + data-dictionary slot is precisely what the IG's terminology layer and artifact pages fill (and it matches the WHO SMART L2 data-dictionary plan already in [[icr-ig]] §13.3).
- **Master list definitions (verbatim highlights):** Beneficiary list — "basic information about individuals benefiting from campaign interventions… ensures that no beneficiary is overlooked during the intervention." Household list — "must be updated before any campaign… ensures that no household is overlooked." Terminology list(s) — "standardized terms and codes for campaign items such as bednets, insecticides, vaccines and drugs… names, codes, descriptions, and classifications of campaign deliverables." Registry rule restated: "**Programmatic data should not be included within a data registry**, but programmatic datasets should reference master list data where possible" — our Location/registry design verbatim.
- **Core services layer:** audit trail, authentication, **demography service**, health facility service, health worker service, payment service, **terminology service** — modular, API-exposed. The ICR terminology + Location + Practitioner layers are the FHIR-native realization of the demography/facility/worker/terminology services.
- **Interoperability layer** = "a locally managed health information exchange, utilizing event-based microservices… quality checks such as **data deduplication** are enforced before inserting or updating core registries; and data transformation is completed before transmission." This is the OpenFn/Airbyte + dedup slot in the ICR reference platform, and it locates WHO's answer to record-linkage at the interoperability layer (relevant to the IG's open record-linkage question).
- **Guiding principles** (§3.1) map to existing ICR commitments: **unique identification** ("leverage national IDs… support an effective unique ID system to capture individual-level data", ID4D, OpenHIE) = our sliced nationalId/registryId; **reusability of data** ("data dictionaries and comprehensive metadata… machine readable formats") = provenance-on-everything; offline capability, localization (our FR designations), scalability ("national level datasets across multiple **rounds** of campaigns").
- One vocabulary nuance: Doc 4 is the only toolkit document that says "patient" — once, in "standards for… **patient and beneficiary registries**" (§3.1.4) — supporting our keep-Patient-resource / say-beneficiary split.

* * *

## 3. Where we align (structure)

WHO's reference architecture (Doc 4 §2.3.1, diagrammed in Doc 1 Annex B) names seven **master lists**, each of which is an ICR/FHIR resource:

| WHO master list | ICR / FHIR counterpart |
| --- | --- |
| Administrative boundary list | `ICRLocation` (admin-unit hierarchy, GeoJSON boundary ext, GERS/P-code IDs) |
| Health facility list | `ICRLocation` (type `facility`) |
| Health worker list | Practitioner / PractitionerRole (via `ICRCareTeam`) |
| Household list | `ICRDeliveryUnit` (Group, kind `household`) + dwelling Location |
| Beneficiary list | `ICRPatient` |
| School list | `ICRLocation` (type `school`) |
| Terminology list(s) / Terminology service | The IG's 26 CodeSystems / 28 ValueSets — the ICR *is* this component |

WHO's canonical 10 campaign workflows (Annex 2.1 §1) vs ICR coverage:

| WHO workflow | ICR status |
| --- | --- |
| 1.1 Enumeration | **Partial** — denominator provenance (`microcensus`, `worldpop`, `grid3`), ESPEN Form 1 village registration, `field-registered` task origin; no general enumeration instrument |
| 1.2 Georegistry | **Strong** — the most-customized ICR resource (`ICRLocation`); WHO's rule that a georegistry holds only *identify/classify/locate/contact* data (Doc 5) matches our Location design exactly |
| 1.3 Planning (macro/micro) | **Strong** — `ICRCampaignProtocol` / `ICRCampaign` (intent=plan microplan), workload targets, planning denominators |
| 1.4 Supply chain & logistics | **Partial** — `ICRSupplyDelivery` + stock-accountability ext (received/used/remaining/not-usable/returned ≈ WHO reverse logistics); no forecasting/procurement (deliberately — that's eLMIS territory) |
| 1.5 Delivery | **Strong** — Tasks (site-session / house-to-house / community), delivery events, mop-up, revisit |
| 1.6 Training | **Absent** |
| 1.7 Payments | **Absent** |
| 1.8 Social & behaviour change communication | **Partial** — `socialMobilization` ext (populationInformed + 18 channels) |
| 1.9 Supervision | **Strong** — `ICRSupervisionReport`, supervision checklists (ESPEN Forms 5/6), oversees-area/workload |
| 1.10 Monitoring & response | **Strong** — MeasureReports with admin/survey lineage split, realtime-vs-reconciled, data-to-action-style measures |

Other structural matches worth citing in the IG:

- **Three-phase model.** WHO's *Campaign planning → Campaign readiness and execution → Campaign monitoring and response* maps cleanly onto the ICR lifecycle (protocol/microplan → readiness validation + delivery → coverage/supervision reporting). Our **readiness** checklist even matches WHO's "campaign readiness" phrase.
- **Mop-up.** Both use *mop-up* identically — coverage-target-triggered corrective delivery (WHO's "data-to-action framework… minimum coverage targets that, if not met, would trigger targeted mop-up campaign activities").
- **Task model.** WHO Doc 5 assigns work as *operational-unit allocations to teams on a daily/weekly cadence* ("daily work plan") — exactly `ICRCampaignTask` + `ICRCareTeam` + workload-target.
- **Denominators.** WHO D1/D2 indicators compare microplan denominators against census/projections, enumeration, **GRID3** — our `ICRDenominatorSourceCS` codes (`census`, `census-projection`, `microcensus`, `worldpop`, `grid3`, `hmis`) cover WHO's exact source list. WHO indicator **D2 ("% variance in population or households found during campaign vs the microplan")** is directly computable from ICR `field-registered` task counts vs the planning denominator — the IG already documents this use.
- **Hard-to-reach.** WHO: "hard-to-reach populations (defined for each country)… IDPs, migratory workers, zero-dose children." ICR: `ICRSettlementTypeCS` (refugee-idp, nomad-pastoralist, hard-to-reach, cross-border…) + zero-dose measure.
- **Multicycle campaigns.** WHO Doc 5 names SMC "cycles"/"rounds" and the exact pain points (implementer churn within a round, per-cycle treatment status) our round/partOf + CareTeam model addresses.

* * *

## 4. Terminology crosswalk — WHO wording vs ours

This is the section to act on. Legend: ✅ aligned · 🟡 adopt WHO term in prose/labels · 🔴 real divergence to decide.

| Concept | WHO IDHC says | ICR says | Verdict |
| --- | --- | --- | --- |
| Person receiving intervention | **beneficiary**, **campaign recipient**, **individual**, "households/individuals", "eligible individuals"; **never "patient"** (Doc 4's lone "patient" is in "patient and beneficiary registries") | FHIR `Patient`, now titled "ICR Patient (**Beneficiary** / Registered Individual)" | ✅ **Adopted (Jul 9, 2026)** — resource stays `Patient`; profile retitled; descriptions and IG narrative say beneficiary/individual; rule stated in the profile: human-facing text never says "patient". |
| Umbrella worker term | **campaign workers** / **campaign staff**; disaggregate **by user cadre** | "team", role codes (vaccinator, CDD, supervisor, recorder, social-mobilizer) | 🟡 Use **campaign worker** as the umbrella prose term and **cadre** for the role axis. Role codes themselves align (WHO uses CDD, supervisor verbatim). |
| Front-line data collector | **registrar** (Doc 3 annexes), **field enumerator** (Doc 5), "data collectors" | **enumerator** (was: recorder) | ✅ **Adopted (Jul 9, 2026)** — `recorder` renamed **`enumerator`** in `ICRTeamRoleCS`, covering both the enumeration and data-capture duties; description notes the ESPEN/registrar synonyms. ESPEN questionnaire item texts ("recorder ID") stay source-faithful to the original forms. |
| Counting/target unit | **household** — "a family unit that typically resides together"; **head of household**; **physical household** (geolocated point/polygon) | household Group + **dwelling** Location | ✅ Aligned. Note the synonym: WHO "physical household" = ICR "dwelling". WHO's Building/Room enumerated objects have no ICR analog (fine for v1). |
| Registry layer | **georegistry**, **shared data registries**, **master list**, "source of truth", "hierarchy" | **georegistry**, **master list** (adopted) | ✅ **Adopted (Jul 9, 2026)** — `ICRLocation` described as the ICR's georegistry layer (with the IDHC no-programmatic-data rule cited); index and background pages use georegistry + master list throughout. |
| Admin units | "administrative, operational and referral **units**"; **operational unit** (settlement, ward, village); **admin unit** (the standard disaggregation axis) | administrative unit, **operational area**, supervisory area, **implementation units** (ESPEN) | ✅ Mostly aligned. Document the synonym set: WHO "operational unit" ≈ ICR "operational area" ≈ ESPEN "implementation unit". |
| Campaign lifecycle | **Campaign planning → Campaign readiness and execution → Campaign monitoring and response** | IDHC three-phase framing (adopted in narrative) | ✅ **Adopted (Jul 9, 2026)** — index and background pages present the CarePlan lifecycle under WHO's three phase names. |
| Repeat execution | **round** and **cycle** (multicycle, e.g. SMC); "subsequent rounds of the same intervention" | **round** (`campaign-round` ext), umbrella via `partOf` | ✅ Aligned; add "cycle" as a synonym in the round extension's description for SMC readers. |
| Delivery event | **delivery** — "distribution, administration and other provisioning"; "health products **administered or given** to individuals/households"; **service delivery** | **delivery event** (umbrella); dose / treatment / distribution / spray | ✅ Aligned. WHO's aggregate framing vs our per-event records is an altitude difference, not a conflict (our Group-subject MDA administration covers the aggregate case). |
| Delivery modes | **fixed point** vs **door-to-door / house-to-house**; **service delivery posts**, vaccination sites, distribution centre | fixed-post, temporary-post, mobile, school, house-to-house, community-directed, outreach | ✅ Ours is a superset. Note "door-to-door" as synonym for house-to-house. |
| Refusal | **intervention refusals**, "reasons for intervention refusals" | **refusal reason** (retitled from noncompliance) | ✅ **Adopted (Jul 9, 2026)** — CodeSystem/ValueSet/extension retitled "Refusal Reason"; ids, FSH names and code values unchanged for stability; descriptions note the ESPEN "noncompliance" provenance. |
| Demand side | **social and behaviour change (SBC/SBCC)**, "generate demand", "conduct messaging", **IEC messaging** | **social mobilization** + "(SBC)" (adopted) | ✅ **Adopted (Jul 9, 2026)** — "social and behaviour change (SBC)" added alongside social mobilization in the role/extension descriptions. Our channel list already covers IEC. |
| Supply | **commodities**, **health products**, **batch code/number**, **buffer stock**, **reverse logistics**, stockouts, eLMIS, master product list | commodity, stock accountability (received/used/remaining/not-usable/**returned**), lotNumber, wastage, medication shortage | ✅/🟡 Aligned in substance. Document synonyms: WHO "batch number" = FHIR `lotNumber`; our `returned` = WHO "reverse logistics". "Buffer stock" not modeled (planning-side; fine). |
| Enumeration | **enumeration** — "systematic process of counting and recording objects of interest"; **enumerated object**; "registration" may co-occur with enumeration | enumeration/microcensus (denominator source), **field-registered** (task origin), "registration" (ESPEN Form 1) | 🟡 Use **enumeration** as the workflow noun consistently; keep "registration" for the person-level act (matches WHO's own distinction). |
| Monitoring | **data-to-action framework / indicators**, dashboards, **course correction**, supportive supervision, mop-up | measures, stratifiers, realtime vs reconciled, supervision, mop-up | 🟡 "Data-to-action" and "course correction" are good WHO phrases to use when describing the realtime lineage + mop-up loop. |
| Coverage | **administrative coverage**, **intervention coverage rate**, **coverage survey / coverage evaluation survey / coverage verification survey**, "monitor coverage" | administrative vs survey coverage, LQAS, RCM, geographic coverage, treatment coverage | ✅ Strongly aligned — including WHO Doc 5 flagging admin-coverage >100% pathology, which our lineage split exists to expose. |
| Disaggregation | **by admin unit, age, sex, user cadre, hard-to-reach populations, operational unit** | stratifiers: sex, age-band, geography, delivery-strategy, disposition, dose-history | 🟡 Near-complete. Gap: WHO's "general vs **hard-to-reach** populations" axis (G1/G2) — consider a settlement-type stratifier on the coverage measures. "User cadre" disaggregation applies to training/payment indicators we don't model. |
| Adverse events | **absent from the entire toolkit** (closest: "grievance redressal") | AEFI, pharmacovigilance, seriousness/severity/causality | ✅ ICR extends WHO here, aligned instead to WHO/CIOMS + WHO SMART IMMZ. No change needed; worth stating in the IG that the toolkit is silent on safety. |

* * *

## 5. Gaps

### 5.1 WHO has it, ICR doesn't

| Gap | WHO source | Recommendation |
| --- | --- | --- |
| **Training** (worker registration, assignment, tracking, pre/post tests; indicators C2, D7–D8, J5) | Doc 5 §7, Annex 3.1 | Keep out of IG v1 (HRIS territory) but say so explicitly in `background.md`, pointing at the toolkit. A future Practitioner-linked training profile is plausible if pilots demand it. |
| **Payments** (calculate/make/track; time logs, payment lists, audit trail; D9–D10) | Doc 5 §9, Annex 3.1 | Same treatment: explicit out-of-scope with rationale (mobile-money/HR systems). Payments is the use case UNICEF stakeholders ask about most — don't leave the silence unexplained. |
| **Grievance redressal** | Docs 1/2/5 | Out of scope; note it. (Distinct from AEFI — WHO's grievance is worker/beneficiary complaints.) |
| **Enumeration as a first-class workflow** (enumerated-object CRUD, dedup, import of shapefile/CSV/JSON, GPS accuracy config) | Doc 5 §3 | Partial today. The reference *platform* covers this (Crosscut/ODK); the IG could add a short "enumeration" narrative mapping WHO's enumerated objects → ICR resources. WHO's Building/Room objects have no ICR analog — acceptable v1 gap. |
| **Buffer stock / forecasting / procurement** | Docs 5–7 | eLMIS territory; out of scope, say so. |
| **Device management & costing** | Docs 6–7 | Purely operational; no IG action. Relevant to reference-platform deployment docs later (device specs, MDM, BYOD). |
| **"Hiring"** (appears in Annex 3.1 A3's workflow list) | Annex 3.1 | Ignore; not in the canonical 10. |
| **Hard-to-reach coverage disaggregation** | G1/G2 | Actionable: add settlement-type/hard-to-reach stratifier to `icr-admin-coverage` and `icr-survey-coverage`. |

### 5.2 ICR has it, the toolkit doesn't

Not misalignments — the toolkit simply doesn't operate at record level — but worth stating as our value-add: **AEFI/pharmacovigilance**, per-event delivery records with lot traceability, the **administrative-vs-survey coverage firewall**, **record-origin** (campaign vs routine) separation, dose history / **zero-dose**, DOC and dose-pole MDA mechanics, finger-marking/revisit micro-workflow, **consent & data governance** (the toolkit only gestures at data privacy SOPs), and formal **round/umbrella semantics** (the toolkit uses "round" informally).

### 5.3 Indicator crosswalk (Annex 3.1 → ICR)

The MLE indicators that touch campaign *data* (vs programme management) are all computable from ICR resources — a strong validation of the model:

- **D1/D2** (microplan denominator completeness/variance) ← `ICRTargetPopulation` (source, estimate date, confidence) + field-registered vs pre-planned task counts
- **D3** (microplans updated during campaign) ← CarePlan versioning
- **D5/D6** (stockouts resolved, adequate stock incl. reverse logistics) ← stock-accountability ext, `medication-shortage` missed reason
- **D11** (recipients reporting IEC messaging) ← socialMobilization ext + survey lineage
- **E1–E5** (data completeness, timeliness, concordance) ← QuestionnaireResponse/MeasureReport metadata, realtime-vs-reconciled lineage
- **G1/G2** (individuals reached, intervention coverage rate) ← the coverage measures; WHO's insistence on survey validation of admin figures *is* our never-merge rule
- **B3/B4, C5** (cross-campaign integration, reuse) ← the ICR thesis itself; B4's "integrated with routine health system (e.g., DHIS2)" is our Phase 4 reporting alignment

* * *

## 6. Recommended changes (prioritized)

**Done (Jul 9, 2026 — IG source updated, SUSHI-clean):**

- ✅ WHO terminology adopted in the IG: beneficiary/individual language (Patient resource kept, profile retitled), `recorder` → **`enumerator`** role, "Refusal Reason" retitling, georegistry/master-list framing, SBC alongside social mobilization, "door-to-door" synonym, IDHC three-phase lifecycle in the narrative.
- ✅ `background.md` now has a "Relationship to the WHO IDHC toolkit" section that names the out-of-scope use cases (training, payments, grievance redressal, device management, costing) with the toolkit as the reference.
- ✅ Document 4 obtained and reviewed (§2a).

**Open:**

1. **Matching terminology pass on [[icr-ig]]** (content rewrite → v0.28.0): beneficiary/individual, enumerator, refusal, georegistry, three-phase framing — so the design doc reads consistently with the IG source it documents.
2. **Obtain Annexes 2.2 and 6.1** (tool selection guidebook, costing tool).
3. **mADX + ICD-11 follow-ups from Doc 4:** verify ICR MeasureReports are consumable in the FHIR mADX aggregate-exchange pattern (Doc 4 names mADX as *the* aggregate-reporting content standard); consider ICD-11 mappings for `ICRNTDDiseaseCS`.
4. **Remaining small terminology items:** "cycle" synonym in the campaign-round extension (SMC vocabulary); hard-to-reach/settlement-type stratifier on the two coverage measures (WHO G1/G2 disaggregation); possibly a generic `distributor` role.
5. **Add an "IDHC alignment" page to the IG** (a condensed version of §2a–§5 of this note): master lists → resources, 10 workflows → coverage status, Annex 3.1 indicators → measures. Positions the ICR as the FHIR data layer of WHO's own architecture — powerful for both UNICEF and country audiences.
6. **Self-score the reference platform against Annex 2.1** before Phase 2 country engagement — it is very likely the instrument countries will be told to use for solution selection, and the ICR platform scores well on its highest-signal criteria (4.2 FHIR, 5.1 open source, 5.2 DPG, 4.4–4.6 APIs/integration).

* * *

> [!note] Sources
> WHO AFRO IDHC toolkit Documents 0–7 (WHO:AFRO/ARD:2025-03/-04/-08/-09/-10/-11, WHO:AFRO/HSS:2026-01, WHO/AFRO:2026-13258…), Annex 2.1 (solution selection support tool), Annex 3.1 (MLE framework supplement, indicators A1–K4); ICR IG source `/ig` (v0.1.0 draft, `unicef.fhir.icr`); [[icr-ig]] v0.27.0.
