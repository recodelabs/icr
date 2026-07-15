---
version: 0.1.0
last_modified: 2026-07-15T19:08:00Z
tags:
  - icr
  - fhir
  - ig
  - forms
  - crosscut
  - gap-analysis
public: true
---

# Crosscut Forms — ICR gap analysis
<sub>`v0.1.0 · Last modified Jul 15, 2026 at 3:08 PM EDT`</sub>

> [!note] What this document is
> A systematic comparison of **33 real campaign data-collection forms** contributed by **Crosscut** (`forms/crosscut/`) against the draft **ICR FHIR Implementation Guide** (`project/icr-ig.md`). For each form it records: what the instrument collects, how it **fits** the ICR model (which profiles / extensions / codes it maps onto), the **gaps** it exposes (data with no ICR home), and **terminology / valueset additions** it suggests (new codes, or the same concept in different / local / multilingual wording). Forms are grouped by campaign category — **Immunization**, **Malaria (ITN/LLIN & IRS)**, and **NTD (MDA)**. Where a gap is already on the IG roadmap (§13 of the IG), that is noted — a recurring field pattern *strengthens* an existing proposal rather than being a brand-new finding.

**Method.** Each `.xls/.xlsx/.xlsm` was parsed to its sheet/header/label structure; the one PDF (AMP ITN microplanning toolkit) was read directly. Every form was compared against a distilled reference of the IG's 20 profiles, 35 extensions, and 25 CodeSystems (with their full code lists). "Fit" citations name the exact ICR artifact (e.g. `ICRTargetPopulation`, `ICRDeliveryStrategyCS`, `stockAccountability`); quoted column headers are **verbatim** from the forms (language noted for FR/PT). This is an input to IG design decisions, not a change to the IG itself.

**Corpus.** 3 immunization (Ethiopia, Tanzania, Mali) · 9 malaria (Côte d'Ivoire, Ghana, Malawi ×2, Nigeria, Zambia ×2, plus generic PMI IRS template + AMP toolkit) · 21 NTD (Nigeria, Benin, Senegal, Madagascar, Burundi, Liberia ×3, Guinea-Bissau ×2, Guinea, plus live CommCare/ODK supervision exports). Languages: English, French, Portuguese.

* * *

## Executive synthesis — the recurring signal across all 33 forms

The strongest finding is **convergence**: the same handful of gaps recur across immunization, malaria, and NTD, in three languages, which is exactly the "campaigns re-collect the same data" thesis the ICR exists to solve. Ranked by weight of evidence:

**1. Forward supply-chain quantification has no home — the single biggest gap family.** Almost every microplan (ITN, IRS, MDA, SIA) runs the same forecast math and ICR models none of it: `estimated need = target × commodity-per-capita − carryover stock + safety buffer`, then **rounded to a pack/packaging unit** (bales of 40/50 nets, boxes of 500 tablets, insecticide units of 130/60). `ICRSupplyDelivery.stockAccountability` is **after-the-fact only** (received/used/remaining) — there is no **requisition / forecast** artifact, no **quantification-coefficient** field (persons-per-net 1.8, structures-per-insecticide-unit, tablets-per-person, avg household size), no **buffer-rate** field, and no **pack-size / packaging-tier** on `quantity`. *Recommendation:* a quantification/requisition model (extension or lightweight profile) carrying commodity-per-capita ratio, buffer %, carryover, and packaging unit — serves ITN, IRS, MDA, and vaccine campaigns alike. Strengthens & extends the roadmap GS1/GTIN + doses-per-vial items.

**2. IRS is a "treat-a-place" event and the field data hand the IG its schema.** Four malaria workbooks plan and report IRS against **structures, not people** — verbatim `Total # of Structures 2023 | Total Eligible Structures 2023 | Planned Structures 2023 | Found Structures 2023 | Sprayed Structures 2023 | Spray Coverage | Mop Up Structures`, with structures-per-operator-day and wall-surface-area coefficients. This is decisive evidence for the roadmap **`ICRStructureTreatment`** event + `structure` Location type, and additionally demands a **`eligible-structures` denominator type**, a **structure-disposition value set** (`found` / `sprayed` / `mop-up` / `eligible` / `not-eligible` / `refused` / `locked`), and an **`irs-spray-coverage` Measure** (sprayed ÷ found). Prior-round structure counts used to plan the next round argue for longitudinal structure history.

**3. `ICRTeamRoleCS` is far too narrow — the biggest terminology gap.** The current 5 codes (vaccinator/cdd/supervisor/social-mobilizer/recorder) miss most of the real campaign workforce named verbatim across the forms: ITN — `registration-assistant`, `distribution-point-attendant`, `hsa`, `cbv`/volunteer, `enumerator/recenseur`, `stock-manager`, `data-entry-officer`; IRS — `spray-operator`, `team-leader`, `site-manager`, `washer`, `security-guard`, `pump-technician`, `store-keeper`; MDA/EPI — `town-crier`, `village-chief`, `teacher/school-distributor`, `driver`, `ward-focal-person`, `lga-ntd-coordinator`, and a **partner-organization** axis (TCC/UNICEF/etc.). Also recurring: workforce **sex composition** (Male/Female CDDs), **PWD-inclusion** flags, and **incentive/turnover** (received-motivation, replaced/recycled).

**4. NTD needs an eligible-target ("UTG") denominator and stored coverage thresholds.** Every NTD form derives the treatment target as `total population × eligibility-fraction` (82.36% ivermectin, 28.83% SAC schisto) and reports **therapeutic coverage** against that **Ultimate Treatment Goal (UTG)**, not total population — then flags villages by programmatic **65% / 80%** thresholds. `ICRDenominatorTypeCS` (`total-population | at-risk`) has no clean `eligible-for-treatment`/`ultimate-treatment-goal` value and no slot to store the eligibility % or the programme threshold. Strengthens the roadmap `coverage-target` quartet item; adds an explicit UTG denominator.

**5. Multilingual terminology is a first-class ConceptMap requirement, not an afterthought.** The identical concept appears in EN/FR/PT and must map to one ICR code: strategies (`Stratégie Avancée`=outreach, `CF/SA/EM`), diseases (`GEO/géohelminthiase`=sth, `BIL/bilharziose/SCHISTO`=schisto, `GeoH`=sth), coverage (`Cobertura Terapêutica`/`Couv. Thérapeutique`=therapeutic coverage), missed/exclusion reasons (`Ausente/Recusa/Doente/Gravida/Aleitando` PT; `Absents/Refus/Malades grabataires` FR), admin units (`Fokontany`, `Colline`, `Tabanca`, `Arrondissement`, `Clan`), and drugs (`Mectizan`/`IVERECTINA`=ivermectin). Even single-language forms show spelling drift (`Health Distrcit`, `Statis of CDTI`). This is concrete demand for the roadmap **ConceptMap-for-local-codes** mechanism, and a starter glossary is embedded per-form below.

**6. Supervision needs three things `ICRSupervisionReport` / `icr-mda-supervision-checklist` lacks.** The live CommCare (Sightsavers, ~130 columns each) and ODK (TCC) instruments — the exact tools Crosscut ingests — reveal that the canonical 4-section checklist (supplies/CDD-observation/stock/social-mob) is missing: **(a)** a **records / data-quality** section (treatment-register & tally-sheet availability + correctness, missed-persons recording); **(b)** a structured **finding → severity → corrective-action** escalation layer (`maj_iss_*` flags + dated `major_action_*`) — supervision without action-tracking loses its purpose; and **(c)** **per-CDD roster** performance/workload (`ICRCareTeam.workloadTarget` is per-team, not per-participant). Plus a coded **side-effects** answer list and CDD **incentive/turnover** fields.

**7. Delivery-site & settlement typology is richer than `ICRLocationTypeCS` / `ICRSettlementTypeCS`.** MDA is delivered at **village / church (religious-site) / school / market** (an explicit coverage-disaggregation axis) — `ICRLocationTypeCS` has `school` but no `religious-site`/`market`. Recurring location types missing: `health-facility-catchment` (FLHF / Aire de Santé / Área Sanitária — the smallest MDA reporting unit, in all three languages), `clan`, `hamlet`, `distribution-site` vs `distribution-point`, `prepositioning-site`/`warehouse`, `irs-base`/`soak-pit`/`wash-area`. Terrain and security-accessibility are **orthogonal axes** the forms keep separate but ICR folds into `settlement-type`. And TCC's **migrant/mobile-population module** (occupation, origin, duration, movement frequency, treated-at-origin) is a genuinely new data domain with no ICR home.

**8. Smaller but concrete additions.** Stock dispositions need **`lost/missing`** and **`expired`** buckets (`perdidos`/`espirado`/`Perdus`/`Tabs missing`) beyond notUsable/returned. `ICRExclusionReasonCS` `under-height-age` should **split into `under-age` (<5 yrs) and `under-height` (<90 cm)** — the CommCare `not_eligible_ivm` lists carry both distinctly — and add `bedridden`/`severely-ill` and a breastfeeding **<7-day** qualifier. Disease scope is a **co-endemic combination** (a *set* of `ICRNTDDiseaseCS` codes), not a single disease. Cold-chain deserves a supervision-time check (ice-pack condition) and an equipment/energy-source vocabulary.

**9. Out-of-scope co-bundling is real and must be handled in the transform.** Surveillance / morbidity / MMDP data (oncho skin-snip MF, CMFL, Ov16 serology, black-fly PCR; LF hydrocele/lymphedema/elephantiasis; schisto transmission ponds) recurs prominently, physically co-bundled onto the same sheet as treatment tallies. This confirms the IG's "reference, don't model" boundary — but the **ingestion pipeline must reliably split** epi/morbidity data to a surveillance store while keeping program-round metadata (rounds delivered, treatment strategy) referenceable in ICR. **Budget/costing** is likewise pervasive and out of scope — recommend an explicit boundary statement.

* * *

## How to read the per-form sections

Each form has four labelled parts — **What it collects**, **Fit**, **Gaps**, **Terminology / valueset additions** — followed by a **Cross-cutting findings** roll-up per category. Verbatim form headers are quoted; ICR artifacts are named exactly. "Strengthens the roadmap X item" means the IG already proposed X (§13) and this form is field evidence for it; "genuinely new" means no current or proposed home.

* * *

## Immunization

This form family covers **microplanning, budgeting, and logistics estimation** for immunization service delivery at woreda/council/district level. Two of the three are **routine immunization (RED/REC)** annual microplans (Ethiopia, Tanzania) and one is a genuine **SIA campaign** microplan canvas (Mali, MenAfiVac/COVID-19). They share a common planning core — session sites by delivery strategy, target-population denominators, teams, cold chain, integrated services, hard-to-reach access — but expose several axes ICR does not yet model: **cold-chain equipment inventory, staff-training tracking, transport/access modes, and RED access-vs-utilization analytics**.

### Woreda MP format (01)-FEB 2019_blank.xls — Woreda/Kebele EPI routine-immunization microplanning workbook (Ethiopia)
**What it collects:** A 16-sheet annual **routine immunization (RED)** microplanning workbook at Sub-Kebele → Kebele/HC-cluster → Woreda tiers: site inventory, session planning, doses/coverage/drop-out data analysis with problem categorization, root-cause (fishbone) analysis, annual workplan, vaccine/syringe/budget resourcing, and an activity monitoring calendar. This is routine EPI, not a campaign (`Form K4 "Annual RI workplan"`).

**Fit:**
- Admin hierarchy Region/Zone/Woreda/Kebele/Sub-Kebele → `ICRLocation` with `partOf` chain and `type`→ICRLocationTypeCS (`admin-unit`, `facility`); facility subtypes `Hos/HC/HP` (Hospital/Health Centre/Health Post) map to `facility`.
- Target-population columns (`Live birth`, `Surviving infant`, `12-23 months`, `12-59 months`, `HPV target`, `Preg. Women`, `Non-Preg. Women`) → `ICRTargetPopulation` (Group actual=false) with `characteristic` age-band/sex and `quantity`; `denominatorSource`→ICRDenominatorSourceCS (`census-projection`; the `Surviving Infants = CBR − IMR` formula in `wplanning` r30 is exactly a `census-projection`).
- Session sites `Name of the site (fixed, outreach mobile)` and `Session type (F, OR & M)` → `ICRLocation.deliveryStrategy` / `ICRCampaignTask.deliveryStrategy` → ICRDeliveryStrategyCS (`fixed-post`, `outreach`, `mobile`). Scheduled vs held dates (`HF Workplan`) → Task microplan (`intent=plan`) vs execution.
- Doses administered by antigen (`Penta1/Penta3/MCV1/MCV2/HPV/TT2+`) and coverage % → `ICRImmunizationEvent` (**`record-origin=routine`**) aggregated to `ICRAdministrativeCoverage` MeasureReport with `dose-history`/`age-band` stratifiers; `Unimmunized (No.)` and zero-dose logic touch `icr-zero-dose-coverage`.
- `Name of hard to reach area` → `ICRLocation.settlementType`→ICRSettlementTypeCS (`hard-to-reach`); `Type: Rural/Urban` → `rural`/`urban`.
- Vaccine/syringe/safety-box requirements and wastage factors (`wMPresource`, r26 wastage table) → `ICRSupplyDelivery` (suppliedItem) + `ICRCampaignActivity.product[x]`; strengthens the roadmap **wastage Measure + doses-per-vial** item.
- Root-cause/problem sheets partially → `ICRSupervisionReport` (QuestionnaireResponse) pattern, though these are planning-time not supervision-time.

**Gaps:**
- **Cold-chain equipment inventory** — `# Functional Cold chain Equipment: Refrig | Cold box | V. Carrier`. ICR has only the readiness checklist + SupplyDelivery; there is no equipment-type inventory. Strengthens the roadmap "cold-chain/logistics axis beyond readiness checklist & SupplyDelivery" — this is concrete evidence to build it.
- **Staff-training tracking** — `# staff trained: MLM | IIP | IRT | Cold Chain | Vaccine Management | Injection Safety`. Genuinely NEW; no home in IG (readiness checklist is binary campaign-level, not per-course staff counts).
- **Transportation access** — `Transportation Access? (yes=1, No=0): Car | Motor Bike | Animal`. NEW; no structured home. Distinct from settlementType — it is an access-*mode* inventory per site.
- **Access-vs-Utilization / RED categorization analytics** — `Drop-out rates (%) P1-P3, MCV1-MCV2`; `Access | Utilization`; `Category 1,2,3,4` (r19-22: 1=No problem; 2=Utilization problem [drop-out high, coverage high]; 3=Access problem [drop-out low, coverage low]; 4=Both) + `Priority/rank`. This is a rich diagnostic taxonomy with NO home — richer than any current coverage MeasureReport. NEW and high-value.
- **Root-cause / problem taxonomy** — `ClusterProblem`/`Wproblemana` system components + `Root Causes (Fishbone analysis)`, `SOLUTIONS with available/extra resources`, `Possible time line`. NEW.
- **`# injections per year` productivity norms** (r18-19: static 40/day, outreach/mobile 30/day; with VAS integration 35/25). Planning parameter with no slot (could inform `ICRCareTeam.workloadTarget`).
- **`Distance or time to vaccination post (km or minutes)`** — quantitative access metric, no structured home.
- **Budget/costing** (`wMPresource`: Allowance for OR/Mobile, Supervision, Review Meeting, Training, Transport, Kerosene, Socmob/IEC, Source of budget) — ICR has no financial model. Recurrent across all three forms; likely out-of-scope but should be explicitly noted as a boundary.
- **Integrated services** — `Other key MNCH activities for integration (e.g. Vit, de-worming, screening)` and `Vit.A tin` budget line. See terminology.

**Terminology / valueset additions:**
- Propose **ICRColdChainEquipmentCS**: `refrigerator`, `cold-box`, `vaccine-carrier` (verbatim `Refrig / Cold box / V. Carrier`); extend with `freezer`, `ice-pack` from the other forms.
- Propose **ICRTrainingCourseCS**: `mlm` (Mid-Level Management), `iip` (Immunization in Practice), `irt`, `cold-chain`, `vaccine-management`, `injection-safety` (verbatim column headers).
- Propose **ICRTransportModeCS**: `car`, `motorbike`, `draught-animal` (verbatim `Car / Motor Bike / Animal`).
- Propose **ICRProblemCategoryCS** (RED): `no-problem`, `utilization-problem`, `access-problem`, `access-and-utilization-problem` + a priority rank stratifier — a campaign/routine analytics vocabulary.
- Propose **ICRREDComponentCS** (root-cause system components, verbatim): `reaching-target-population`, `supportive-supervision`, `engaging-communities`, `monitoring-and-data-use`, `resource-planning-management`, `cold-chain-vaccine-management`, `service-integration`, `surveillance`.
- Propose **ICRIntegratedServiceCS**: `vitamin-a`, `deworming`, `screening`, `growth-monitoring` (verbatim `Vit, de-worming, screening`).
- **EPI age-band value set** for `ICRGroupCharacteristicCS`/`age-band`: enumerate `live-birth`, `surviving-infant`, `12-23-months`, `12-59-months`, `hpv-target`, `pregnant-women`, `non-pregnant-women` — the reference lists only `geography`/`age-band` axes but not the values; these headers are a concrete EPI denominator set.
- **ICRTeamRoleCS** additions: `health-extension-worker` / `health-worker` (verbatim `HEW/HW`).

### IVD_REC Microplanning Tool_Tanzania_2016_blank.xlsx — IVD/REC budget & logistics estimation tool (Tanzania)
**What it collects:** A council-level **routine immunization (REACHING EVERY COMMUNITY / REC)** planning tool (`REC PLANNING TOOL FOR ESTIMATING BUDGET AND LOGISTICS`) that compiles health-facility outreach/mobile session plans, computes vaccine/syringe/cold-chain requirements, and produces facility- and council-level budget summaries. Routine, not campaign.

**Fit:**
- Session-type list `Outreach Session | Mobile Clinic | Health Facility` → ICRDeliveryStrategyCS (`outreach` / `mobile` / `fixed-post`).
- Village outreach plan (`CHMTCmTm`): `Annual Beneficiaries (Pregnant Women | Surviving infants | 12-24 month children)` → `ICRTargetPopulation`; `Weekday`/`Week number for organizing outreach`, `Location/address of outreach session` → `ICRCampaignTask` microplan + `ICRLocation` (`temporary-post`/`community-distribution-point`).
- Teams: `Team members from health facility (F1/F2)`, `Team members from community (C1/C2)`, `Name of village leader`, supervisors `from Health Facility / CHMT` (`SupPl`) → `ICRCareTeam` participants + `overseesArea`.
- Vaccine schedule (`Var` r46-64): `Doses per vial`, `Doses required`, `Mode of administration (Injectable/Oral)`, `Wastage Rate (%)`, `Syringe used`, `Reconstitution (Yes/No)` for BCG/OPV/PCV13/Rota/Penta/MR/TT/IPV/HPV → `ICRCampaignActivity` (CVX product) + `ICRSupplyDelivery`; `25% buffer stock`, doses-per-vial and wastage directly strengthen the roadmap **wastage Measure / doses-per-vial** item.
- `Doses per vial` + wastage + syringe requirements → supports the proposed **dosing-regimen** semantics.

**Gaps:**
- **Cold-chain maintenance detail** (`CoChMn`): `Number of LP Gas Cylinders required every month`, `Whether electricity used for cold chain maintenance (YES/NO)`, `Approximate cost of electricity for cold chain per month`, refill-vs-purchase-new cylinders. NO home — strongly strengthens the cold-chain axis roadmap item with an *energy-source* dimension (gas vs electricity) absent from ICR.
- **Vaccine delivery / route planning** (`VacDelHQ`): `Route Number | Vehicle Number | Number of facilities covered | Names of health facilities (in order of transporting) | Total distance covered in Km (incl. return) | Overnight stay`. NEW — a last-mile distribution-route model ICR lacks (SupplyDelivery has destination but no route/leg concept).
- **`Distance of village from facility (Km)`** + **`Fare for transporting vaccines to outreach`** + **`Overnight stay (YES/NO)`** — per-session access/logistics attributes with no structured home.
- **Budget line taxonomy** (`SumCncl` r38-51): extra-duty allowance (HF staff / community members / transport officer / driver), overnight per diem, fuel, fare, cold-chain refill/purchase/electricity — same financial gap as Ethiopia; ICR has no cost model.
- **`Mode of administration` (Injectable/Oral)** and **`Reconstitution (Yes/No)`** — vaccine-handling attributes not currently on `ICRImmunizationEvent`/`ICRCampaignActivity`.

**Terminology / valueset additions:**
- Extend **ICRColdChainEquipmentCS** with an *energy source* axis: `lp-gas-cylinder`, `electric` / `gas` / `solar` cold-chain (verbatim `LP Gas Cylinders`, `electricity used for cold chain`).
- **ICRTeamRoleCS** additions confirmed and extended: `community-member` (verbatim `Team members from community C1/C2`), `driver` (verbatim `driver of vaccine van`), `facility-staff` (verbatim `Facility staff F1/F2`).
- Propose vaccine-handling attributes on `ICRCampaignActivity`: `modeOfAdministration` (`injectable`/`oral`), `reconstitution` (bool), `dosesPerVial`, `wastageRate` — feeds the wastage Measure.
- `RCH1 Cards` / `RCH1 Cards` and `Safety boxes` → `ICRSuppliedItemCS` additions (client-held card, safety box).

### Canevas Microplan Campagne de Vaccination-Mali_blank.xlsx — SIA campaign microplan canvas (Mali, French)
**What it collects:** A **genuine SIA campaign** microplan (MenAfiVac and COVID-19 references) with a base-parameters sheet, a per-aire-de-santé canvas (targets, doses, injection material, teams, volunteers, waste/injection supplies, training, costs), five district copies, a social-mobilization sheet, and a cold-chain costing sheet. This one maps directly onto `ICRCampaign`.

**Fit:**
- `ICRCampaign` (CarePlan, `intent=plan` microplan) with `ICRCampaignProtocol`; the MenAfiVac/COVID-19 subject → `ICRCampaignTypeCS` = `vaccination-sia`. `Durée de la campagne` (10 days) → campaign period.
- Strategy columns `CF | SA | EM/EMS` = *Centre Fixe / Stratégie Avancée / Équipe Mobile* → ICRDeliveryStrategyCS `fixed-post` / **`outreach`** / `mobile`. **`Stratégie avancée` is the Francophone equivalent of "outreach"** — a prime **ConceptMap-for-local-codes** case (strengthens that roadmap item).
- `Aires de santé`, `Nombre villages`, `POP TOTAL 2022`, `% à Couvrir par stratégies`, `Population Cibles à vacciner par stratégies` → `ICRLocation` + `ICRTargetPopulation` (with `isPlanningDenominator`, `at-risk`) and `ICRCampaign.planningDenominator`.
- Teams/agents/volunteers per strategy (`Nombre équipes`, `Nombres d'agents`, `Nombres de volontaires`, `chauffeurs`) + supervisor ratios (`Nombre d'équipes par superviseur`) → `ICRCareTeam.participant` + `workloadTarget`.
- `Nombre doses de Vaccin/MenAfiVac`, `Seringues Autobloquantes (SAB)`, `Seringues de dilution`, `Boites de sécurité` → `ICRSupplyDelivery` + `ICRCampaignActivity`; `Facteur de perte` (wastage 1.05) → wastage Measure.
- `Cartes de vaccination`, `Fiches de pointage` (tally sheets), `Fiche synthèse journalière` → `ICRCampaignTask.output` aggregate tally pattern.
- `MOBILISATION SOCIALE` sheet (`Radios`, `Mobilisateurs de proximité`, `Journées d'information`, `Lancement`) → `ICRCampaign.socialMobilization` (`channel`→ICRCommunicationChannelCS `radio`, `social-mobilizer`, `volunteer-chw`).
- `Forfait gestion MAPI` (MAPI = *Manifestation Adverse Post-Immunisation* = AEFI) → provisioning for `ICRAdverseEvent`.

**Gaps:**
- **Cold-chain costing/inventory** (`Chaine du froid` sheet): `Congélateurs` (freezers) rental, `Carburant Groupe (district sans électricité)` (generator fuel where no grid). Same cold-chain axis gap; adds `freezer` and `generator/no-electricity` dimensions.
- **Ice-pack / vaccine-carrier logistics** (`Paramètres`): `Nombre d'accu/porte vaccins` (ice-accumulators per vaccine carrier), `Nbre d'accus 0,6 litres par glacière`, `Nbre portes vaccins par équipe`, `Volume par accumulateur` — micro-logistics of the passive cold chain, no home.
- **Waste management** — `Boites de sécurité`, `Aménagement Fosse` (burial pit construction), `Frais d'incinération déchets`, `Besoins en sachets poubelles`, `Fiche de réception/déstruction déchets`, `Fiches synthèse élimination déchets`. ICR's `stockAccountability` covers received/used/remaining but NOT disposal/incineration/burial-pit accountability. NEW.
- **Injection-safety consumables** — `Besoins en coton` (cotton), `Nombre de Gants`/`boites de Gants` (gloves). Minor `ICRSuppliedItemCS` additions.
- **Transport-mode / terrain access** (`Paramètres` r37-41): vehicle, `moto`, **`chameaux`** (camels), **`pinasses`** (motorized river boats), **`pirogues`** (canoes) rental — riverine/desert access modes ICR cannot express. Strengthens the transport-mode gap with terrain-specific values.
- **Training provisioning** — `Formations vaccinateurs volontaires` and `Formation opérateurs` (DISTRICT sheets) — training as a budgeted campaign activity, no home.
- **Budget/costing** — pervasive per-diem/fuel/coordination/incineration line items; same financial-model boundary note.

**Terminology / valueset additions:**
- **ConceptMap (local→ICR):** `CF`→`fixed-post`, `SA` (`Stratégie Avancée`)→`outreach`, `EM/EMS` (`Équipe Mobile`)→`mobile`. Canonical Francophone campaign vocabulary — high-value for a French-language ICR deployment.
- Extend **ICRTransportModeCS** with terrain modes: `camel`, `motorized-boat` (pinasse), `canoe` (pirogue), `motorbike`, `vehicle` (verbatim `chameaux / pinasses / pirogues / motos`).
- Extend **ICRColdChainEquipmentCS** with `freezer` (`congélateurs`), `ice-pack`/`accumulator` (`accus`), `vaccine-carrier` (`porte vaccins`), `cold-box` (`glacière`); add cold-chain energy value `generator`/`no-grid` (`district sans électricité`).
- Propose **ICRWasteDisposalCS** (or a `wasteAccountability` extension on `ICRSupplyDelivery`): `safety-box`, `incineration`, `burial-pit` (`aménagement fosse`), `waste-destruction-record`.
- **ICRTeamRoleCS**: `volunteer` (`volontaire`), `driver` (`chauffeur`), `social-mobilizer`/`proximity-mobilizer` (`mobilisateur de proximité`) — confirms the additions above.
- **ICRSuppliedItemCS** additions: `cotton`, `gloves`, `waste-bag` (`sachets poubelles`), `vaccination-card`, `tally-sheet` (`fiche de pointage`).
- **ICRCommunicationChannelCS**: `information-day` (`journées d'information`), `campaign-launch` (`lancement`), `traditional-performance` (`animation traditionnelle`, Mob soc sheet header) — additions to the existing `radio`/`town-criers` set.

### Cross-cutting findings — Immunization

- **Routine-vs-campaign boundary is the headline finding.** Two of three forms (Ethiopia Woreda, Tanzania IVD) are **routine immunization RED/REC** microplans — annual sessions, drop-out between routine doses, `record-origin=routine`. Their delivery events belong to the WHO SMART Guidelines routine immunization (IMMZ) domain, NOT ICR. Only the **Mali Canevas is a true SIA campaign** (`vaccination-sia`) that maps onto `ICRCampaign` directly. **However**, the *microplanning primitives* — session sites by delivery strategy (fixed/outreach/mobile), target-population denominators, teams and supervisor ratios, cold-chain, hard-to-reach access, integrated services — are **shared** between routine and campaign microplanning. ICR should ensure its microplan vocabulary (ICRDeliveryStrategyCS, ICRTargetPopulation, ICRCareTeam) is deliberately alignable with routine EPI microplans so the same site/team/denominator data is reusable across both, which is exactly ICR's "share/reuse instead of re-collect" mission.
- **Cold-chain/logistics is the single biggest recurring gap, confirmed across all three forms** and three distinct sub-axes: (1) *equipment inventory* by type (Refrig/Cold box/V. Carrier/Freezer/Ice-pack), (2) *energy source* (electricity vs LP gas vs generator/no-grid), (3) *passive-chain micro-logistics* (accumulators per carrier, cylinders per month). This decisively strengthens the existing roadmap item "cold-chain/logistics axis beyond readiness checklist & SupplyDelivery" — recommend a dedicated **ICRColdChainEquipment** profile + CodeSystem.
- **Three genuinely NEW terminology clusters** not on the roadmap: **staff-training tracking** (MLM/IIP/IRT/Cold-Chain/Vaccine-Mgmt/Injection-Safety course types), **transport/terrain access modes** (car/motorbike/animal/camel/boat/canoe), and **waste-disposal accountability** (safety-box/incineration/burial-pit) — none has any current home.
- **RED access-vs-utilization analytics** (drop-out rates + coverage → problem Category 1-4 + priority rank, plus the fishbone root-cause component taxonomy) is a high-value analytic vocabulary with no ICR equivalent; the campaign-side analogue today is LQAS/RCM, but the routine RED categorization is a distinct, mature diagnostic the IG could adopt as an optional MeasureReport stratifier + CodeSystem.
- **Delivery-strategy vocabulary is validated** by all three (fixed/outreach/mobile in EN, CF/SA/EM in FR), and the French forms are a compelling case for the **ConceptMap-for-local-codes** roadmap item — Stratégie Avancée→outreach, MAPI→AEFI, etc.
- **Team-role vocabulary needs enrichment**: forms consistently require `driver`, `volunteer`, `community-member`, and `health-extension-worker/facility-staff` roles beyond the current vaccinator/cdd/supervisor/social-mobilizer/recorder set.
- **Financial/budget modeling** (per-diems, allowances, fuel, transport, coordination, incineration, training costs) is pervasive in every form but almost certainly out of ICR scope — recommend an explicit boundary statement that costing lives in the planning workbook / PM layer, not the FHIR registry, while the *quantities* that drive cost (sessions, teams, doses, distances) ARE in scope.
- **Integrated service delivery** (Vit A, deworming, screening bundled into EPI sessions; adjusted injection-per-day norms when VAS is added) recurs in Ethiopia and the Mali `integrated` framing — supports an **ICRIntegratedServiceCS** and confirms the value of the existing `integrated` campaign type.

* * *

## Malaria (ITN/LLIN & IRS)

Eight malaria microplanning workbooks (five ITN/LLIN mass-distribution, one pure IRS quantification, two combined ITN+IRS) plus the AMP ITN microplanning methodology chapter. These are the strongest field evidence in the whole form corpus for the IG's two acknowledged malaria gaps: (1) IRS as a "treat-a-place" event (the proposed but unbuilt `ICRStructureTreatment`), whose denominator is **structures**, not people; and (2) commodity identity for physical goods (nets, insecticide) with no GS1/GTIN binding. They also expose a recurring **net-quantification model** (population ÷ persons-per-net → nets → bales + buffer) and a **distribution-point/pre-positioning hierarchy** that the IG models only loosely, plus a large body of campaign-logistics data (team cadres, transport, PPE, waste/returns) that currently has no structured home.

### AGNEBY TIASSA_ DDS SIKENSI_ MICRO PLAN_CAMPAGNE MILDA 2024_validé_Groupe2_blank.xls — LLIN (MILDA) mass-distribution microplan (Côte d'Ivoire, French)
**What it collects:** A district (DDS) MILDA campaign microplan with a two-phase model — `dénombrement` (household enumeration/registration) then `distribution` — carrying per-health-area (Aire de Santé) population, net needs, distribution-site counts, team/volunteer/supervisor allotments, logistics (containers, transport modes, fuel), and a full budget.
**Fit:**
- Campaign → `ICRCampaign` (CarePlan, `intent=plan`), `type` = `itn-distribution` (ICRCampaignTypeCS). The `dénombrement`/`distribution` split maps to two `ICRCampaignActivity` (ActivityDefinition) instances sequenced in an `ICRCampaignProtocol`.
- "Population totale AdS", "Ménage cible = pop totale / 5" → `ICRTargetPopulation.quantity` with `characteristic` geography; health-area/village hierarchy → `ICRLocation.partOf`.
- "Nombre de sites de distribution", "Population minimum pour créer un site de distribution = 4000" → `ICRLocation` type `community-distribution-point` (ICRLocationTypeCS).
- "Stratégie de distribution des MILDA dans le village" with the legend `Communautaire / Porte a Porte / Fixe / Fixe Mobile` → `deliveryStrategy` extension: community-directed, house-to-house, fixed-post, mobile (all present in ICRDeliveryStrategyCS).
- Nets to distribute → `ICRSupplyDelivery.suppliedItem` (nets) + `quantity`; team roster (volontaires/mobilisateurs/superviseurs) → `ICRCareTeam` with `workloadTarget`.
- Household enumeration registers ("Nombre de ménages par registre = 225") → `ICRDeliveryUnit` (household) with register-level `quantity` fallback.
**Gaps:**
- **Net-quantification denominator**: `Stratégie Universelle pour la quantification des MILDA (nombre de personne pour une MILDA) = 1.8` and `Ménage cible (personnes) = 5.6`. The people-per-net ratio and the mean-household-size that drive net need have no field on `ICRTargetPopulation` or `ICRCampaignActivity`. This is a genuinely new modeling need (a quantification-ratio / commodity-per-capita coefficient).
- **Bale packaging unit**: "Nombre de balles", "Capacité de charge d'un 10 Tonnes … (balle)", `Volume par MILDA (m3) = 0.14`. The bale (and net volume) is a logistics packaging tier below the shipment; `ICRSupplyDelivery.quantity` has no packaging-unit concept.
- **Container/warehouse pre-positioning** (Outil 2): container references, storage-capacity gap ("Gap en espace de stockage en MILDA"), unloading port (SAN PEDRO/ABIDJAN), distance from port. No cold-chain/warehouse-storage axis exists beyond the readiness checklist — strengthens the roadmap "logistics axis beyond readiness & SupplyDelivery."
- **Team-day / equipe rotation logistics** (Outil 5): "Nbre cumule de jours de distribution", "Nbre reel d'equipe travaillant sur 7 jours", per-day team progression (J1–J7). Task/CareTeam have no day-by-day routing/progression structure.
- **Whole cost/budget model** (per-diems, fuel consumption L/100km, vehicle rental rates) — out of IG scope, correctly (route to finance system).
**Terminology / valueset additions:**
- ICRTeamRoleCS: add `volontaire`/`distributor`, `mobilisateur` (social-mobilizer exists), `recenseur` (enumerator/registration-agent), `superviseur-proximité`, `point-focal-communication`, `gestionnaire-stock` (stock manager). Enumerator/registration-agent is a distinct new role.
- ICRLocationTypeCS: `prepositioning-site` / `storage-container` for the MILDA container depots (distinct from a distribution point).
- "Type d'acces / Mode de transport" legend (`Route Bitumée/Route en terre/Piste/Voie navigable`; `Camion/Pick Up/Tricycle/Moto/Barque Motorisée/Pirogue`) — a road-access & transport-mode vocabulary the IG has nowhere to put.

### Annex_3_BIAKOYE_District_Microplanning_Template_Ghana_blank.xlsx — Point Mass LLIN Distribution (PMD) district microplan (Ghana)
**What it collects:** A district Point Mass Distribution microplan built on a Sub-district → Pre-positioning Site (PPS) → Distribution Point (DP) → catchment-village hierarchy, with per-village population, households, LLIN allocation, bales, and registration/distribution personnel, plus a linked budget and community-social-mobilization/transport-plan sheets.
**Fit:**
- `ICRCampaign` type `itn-distribution`; two activities: "Household Registration & Issuance of Code cards" and "LLIN Distribution at DPs".
- "Name of Distribution Point", "No. Distribution Points (DPs)" → `ICRLocation` `community-distribution-point`; sub-district/village hierarchy → `partOf`.
- "2018 Population (microplanning)", "Number of Households (average HH size of 4.1)", "Number of LLIN Allocated / (Pop/1.8)" → `ICRTargetPopulation`.
- Personnel: "No. of Registration Assistants", "No. of DP Members", "No. of HH Reg. Supervisors", "No. of DP Supervisors" → `ICRCareTeam` participants + `workloadTarget` (the sheet even encodes ratios "1 Sup:6 RAs", "3 persons/DP").
- SBCC sheet (priority channels pre/during/post PMD) → `ICRCampaign.extension[socialMobilization].channel` (ICRCommunicationChannelCS).
**Gaps:**
- **Pre-positioning Site (PPS) as a distinct node**: "Name of Pre-positioning Site (health facility or other PPS type)", plus two transport-plan tabs ("Transport Plan - Dist to PPSs", "Transport Plan - PPS to DP"). The IG has `community-distribution-point` and `temporary-post` but no intermediate **prepositioning/storage-hub** location type, and no structured multi-leg transport/supply-chain routing (District store → PPS → DP). Strengthens the "logistics axis" roadmap item.
- **Coupon/code-card issuance**: "Issuance of Code cards" — the household-registration→voucher→redemption model (register HH, issue coupon, redeem for nets at DP) is a distinct workflow the IG's Task model doesn't capture (no voucher/entitlement artifact).
- **Reverse logistics / leftover returns**: "Reverse logistics from health facilities/PPSs to District Stores … assuming 2% of all LLIN would be left over". `stockAccountability` has `returned` — this fits, but the 2% leftover assumption and reverse-transport are unmodeled logistics.
- **Net-per-net-quantifier constants**: "Number of persons per net 1.8", "Number of nets per bale 50", "Average HH size 4", "Average number of HH to be registered per RA 350", "Average Number of HH per DP 750" — same quantification-coefficient gap as CIV, plus workload norms.
**Terminology / valueset additions:**
- ICRLocationTypeCS: `prepositioning-site` (health facility or other), `district-store` / `warehouse`.
- ICRTeamRoleCS: `registration-assistant` (RA), `distribution-point-attendant` (DPA / DP member). Acronyms sheet gives verbatim: `DPA = Distribution Point Attendant`, `RA = Registration Assistant`.
- Distinguish `LLIN` vs `ITN` (Acronyms sheet lists both) — reinforce free-text/GS1 commodity gap on `ICRSupplyDelivery`.

### Balaka LLINS Microplanning Template Revised August 2024 FINAL_blank.xlsx — LLIN mass-campaign microplan (Malawi)
**What it collects:** A Malawi district LLIN microplan with a Health Facility → Distribution Site (DS) → Distribution Point (DP=HSA) → catchment-village hierarchy, net quantification by village/DP/DS in bales and "loose nets", transport plan, staff list, and phase-specific budget/training sheets.
**Fit:**
- Same ITN structure as Ghana. "Name of HSA (distribution point) (DP)" → HSA (Health Surveillance Assistant) as the DP-level worker → `ICRCareTeam` participant; DS/DP → `ICRLocation`.
- "2024 Population (by head count)", "Number of households (average HH size of 4.4)" → `ICRTargetPopulation` (note: **head-count** enumeration denominator).
- "Number of LLIN required", "Number of bales of 50" → `ICRSupplyDelivery`.
**Gaps:**
- **Three-tier distribution geography**: Distribution **Site** (DS) vs Distribution **Point** (DP), each DS = ~4 DPs, each DS serves ~4,000 persons ("total population ÷ 4,000"). The IG's single `community-distribution-point` type can't express the DS↔DP nesting; needs `partOf` with two distinct location subtypes or a settlement/operational split.
- **Bales vs loose nets accounting**: "Bale/Distribution Point", "LOOSE NETS/Distribution Point", "Bale/Distribution Site", "LOOSE NETS/Distribution Site" — explicit whole-bale vs loose-piece split for transport tonnage. Reinforces the packaging-unit gap on `ICRSupplyDelivery.quantity`.
- **Volunteer pairing rule**: "1 HSA will work with 1 volunteer" — team composition norm; `ICRCareTeam` has no team-template/composition-rule slot.
- Transport plan: "Tonnage", "Condition of the road from cluster warehouse to distribution site", "Maximum distance (km) between the cluster warehouse and the distribution site", "The Type and number of transport to use", "Route" → unmodeled supply-chain routing (again a "cluster warehouse" → DS leg).
**Terminology / valueset additions:**
- ICRTeamRoleCS: `hsa` (Health Surveillance Assistant), `community-volunteer`, `data-manager`, `digital-support-supervisor`.
- ICRLocationTypeCS: `distribution-site` (DS, an aggregation of distribution points) and `cluster-warehouse` / `prepositioning-warehouse (PPW)`.
- Road-condition & transport-mode vocabulary ("Condition of the road", Truck/Boat/Other) — same access vocabulary as CIV.

### GOMBE STATE SIMPLIFIED P- 3B_blank.xls — Simplified ITN mass-campaign microplan (Nigeria, Gombe)
**What it collects:** A "2021 ITN Mass Campaign - Single phase door-to-door" microplan, "Microplanning based on population of settlement/catchment areas", per-ward/community with population, households, ITN need, distribution holding-points (DH), MDTs (mobile distribution teams), bales, and hard-to-reach flags.
**Fit:**
- `ICRCampaign` type `itn-distribution`; single-phase **door-to-door** → `deliveryStrategy` = `house-to-house`.
- LGA → Ward → "List of contiguous communities/settlements" → `ICRLocation.partOf`; "Population / (2021)", "Number of HHs", "Number of ITNs needed by population" → `ICRTargetPopulation`.
- "Name of DH" (Distribution Holding point), "No of MDTs per DH", "Number of cluster supervisors (DH)" → `ICRLocation` (DH) + `ICRCareTeam` (MDT).
**Gaps:**
- **Settlement-level denominator with per-net divisor exposed in the header row**: constants `5.0 | 1.8 | 4800 | 50 | 800 | 3` (avg HH size 5, persons-per-net 1.8, ITNs/… , 50 nets/bale, 800 = HH/personnel norm, 3 = MDT multiple). Same quantification-coefficient gap.
- **Hard-to-reach classification with terrain reasons**: "Is the community a hard-to-reach area? (yes/no)", "Reasons for hard to reach (riverrine/Hilly/Mountainous/sandy/desert)", "Suggested means of transport", "Need for satellite DH (Yes/No)". `ICRSettlementTypeCS` has `hard-to-reach` but not the **terrain reason** sub-vocabulary; and "satellite DH" is a dynamically-added distribution node (maps to `taskOrigin=field-registered` but for a Location).
- **"Number of MDT by catchment adjusted to multiple of 3"** — a team-rounding/allocation rule with no home.
**Terminology / valueset additions:**
- Terrain/access-barrier CodeSystem (new): `riverine`, `hilly`, `mountainous`, `sandy`, `desert` — quoted verbatim as hard-to-reach reasons. Complements `ICRSettlementTypeCS`.
- ICRLocationTypeCS: `distribution-holding-point` (DH), `satellite-distribution-point`.
- ICRTeamRoleCS: `mdt` / `mobile-distribution-team-member`, `cluster-supervisor`.

### VL Malawi Quantification and Material Needs Assessment for IRS 2023_blank.xls — IRS quantification & material-needs assessment (Malawi)
**What it collects:** A pure **IRS** (indoor residual spraying) planning workbook: per-operations-site targeted **structures** and population, spray-operator/team/washer/guard HR quantification, insecticide quantification by burn-rate and coverage-target scenarios, and exhaustive procurement lists (insecticide, sprayers & spare parts, PPE, spill/wash materials, IT, printed forms, IEC).
**Fit (partial):**
- Campaign → `ICRCampaign` type `irs` (ICRCampaignTypeCS exists). Operations sites → `ICRLocation`.
- Insecticide, sprayers, PPE procurement → `ICRSupplyDelivery.suppliedItem` (free text) + `quantity`; buffer/stock-balance → `stockAccountability` (received/used/remaining).
- HR cadres → `ICRCareTeam` participants; training counts → readiness checklist.
**Gaps (this form is the core "treat-a-place" evidence):**
- **Structure as the unit of work and the denominator**: "Targeted Structures", "Number of Structures Sprayed Per Spray Operator Per Day = 9", "Number of Structures Sprayed Per Unit of Insecticide = 1.8", "Average Size of Structure (Sqm) = 138.9", "Wall Surface Area Covered Per Unit of Insecticide (Sqm) = 250". The IG has **no structure-treatment event and no structure denominator** — IRS today lives only on `Task.output` aggregate counts. This directly validates the proposed `ICRStructureTreatment` profile and a `structure`/`at-risk-structures` denominator type. Strongest single piece of evidence for that roadmap item.
- **Insecticide quantification model**: two methods — "For Areas Where the Insecticide Usage Rate is Known" (burn-rate: structures ÷ structures-per-unit) and "For New Spray Areas" (wall-surface-area ÷ area-per-unit). Neither the surface-area method nor the burn-rate coefficient has any IG home. Buffer "Buffer Size 0.2" recurs (see cross-cutting).
- **Product-formulation identity**: "Total Fludora Fusion (66%) … Total SumiShield (34%) … per PMI policy", "UNITS of 130 Fludora Fusion", "UNITS of 60 Sumishield". Named insecticide products + concentrations + pack-sizes — strengthens GS1/GTIN commodity-binding gap.
- **Serialization / track-and-trace**: "Stickers (Larger)/(Coupon) - for insecticide bottle labeling … serialized stickers (6 digits long from 000001 to 100000)", "Scanners for Insecticide serialization", "Insecticide Distribution Tracker Form", "Insecticide stock booklets", empty-bottle return & recycling transport. Per-bottle serialized commodity tracking is well beyond `stockAccountability`; strongly reinforces GS1/lot-serialization gap.
- **Spray-environment infrastructure**: "Number of Fixed Soak Pits", "Mobile Soak Pits I/II", "Washing Areas", "Number of Stores". These are IRS-specific site features (soak pit, wash area, store) — new `ICRLocation` types.
- **PPE / pharmacovigilance for operators**: atropine, pregnancy test kits, "Spill Response Form", "Material Safety Data Sheet", "Emergency Response Procedure Form", cholinesterase-adjacent safety — occupational-safety data with no home (adverse-event model is patient-facing, not operator-facing).
**Terminology / valueset additions:**
- New `ICRStructureTreatment` (or Task.output) needs a **structure-status** vocabulary. Related Zambia IRS Calendar gives the verbs: `found`, `sprayed`, `not-sprayed`, `mop-up`, plus `eligible` / `not-eligible` / `locked` / `refused` (implied). Add a **structure-disposition** CodeSystem.
- ICRTeamRoleCS (IRS cadres, verbatim): `spray-operator` (SOP), `team-leader`, `site-manager`, `spray-supervisor`, `washer` / `wash-person`, `security-guard`, `pump-technician` / `sprayer-technician`, `store-keeper`, `iec-assistant`, `mobilizer`, `chag` (community health action group), `m&e-assistant`, `mhealth-coordinator`, `data-entry-clerk`.
- ICRLocationTypeCS: `operations-site`, `soak-pit` (fixed/mobile), `wash-area`, `insecticide-store`, `central-warehouse`.
- Commodity CodeSystem for insecticides (ATC/WHOPES class or GS1): `fludora-fusion`, `sumishield`, plus formulation % and pack-unit — feeds the GS1-binding decision.
- A **denominatorType** addition: `total-structures` / `eligible-structures` alongside `total-population`/`at-risk`.

### PMI_Districts_Microplan_ITN_IRS_2023_Zambia_blank.xlsx — Combined ITN + IRS district microplan (Zambia, PMI)
**What it collects:** A single Zambia NMEC workbook covering **both** ITN mass distribution (village-level D2D registration & distribution) **and** IRS (district structure counts), with a pivot-style district summary that segments every metric by `Intervention` = "ITN Distribution" or "IRS".
**Fit:**
- Two interventions in one campaign → either one `ICRCampaign` type `integrated` (ICRCampaignTypeCS has `integrated`) or two linked campaigns via `partOf`. The explicit "Intervention" column is exactly the `ICRCampaignActivity.code` / campaign-type discriminator.
- ITN village data → `ICRTargetPopulation` + `ICRSupplyDelivery`; D2D teams/CBVs → `ICRCareTeam`.
- "Total population (CSO)" vs "Total population (Head count)" → two `ICRTargetPopulation` with different `denominatorSource` (census-projection vs enumeration).
**Gaps:**
- **IRS structure denominators, verbatim**: "Found Structures 2022 IRS", "Total Structures Sprayed 2022", "Total number of Structures 2023 in the district", "Total number of IRS Eligible Structures 2023", "IRS Planned Structures 2023", "Reveal Population". Same structure-denominator gap as the Malawi IRS form — and note **prior-round** structure counts (2022 found/sprayed) used to plan the 2023 round: a longitudinal structure-history the IG can't hold.
- **"Reveal Population" / "Reveal Pop"**: an external denominator source from the Reveal geospatial microplanning platform — a new `ICRDenominatorSourceCS` code (`reveal`), analogous to `worldpop`/`grid3`.
- **Dual head-count vs projected population as a first-class pair**: the IG allows one `subject` denominator per campaign; here both CSO-projection and head-count enumeration coexist and are reconciled. Strengthens "population-estimation-method" roadmap item.
- **Bales-per-team-per-day distribution rate**: "# of bales to be distributed per team / day", "Number of trips needed per day", "Capacity (# of bales) per transport mode" → per-team throughput & transport-capacity, unmodeled.
- **5% revisit built into the plan**: "5% revisit HHs", "CBVs of 5% revisited HHs" → planned revisit workload; `revisitOutcome` exists as an event extension but not as a planning parameter.
**Terminology / valueset additions:**
- ICRDenominatorSourceCS: add `reveal`, `head-count` / `enumeration` (registration-derived), `hmis-cso`.
- ICRLocationTypeCS: `structure` (the sprayable building — already on roadmap; this is direct evidence), `zone` (Zambia uses Province→District→HF→Zone→Village).
- ICRTeamRoleCS: `cbv` (community-based volunteer), `chw`, `data-entry-officer`.

### S3-Quantification by Site-Template_blank.xlsx — Generic PMI IRS quantification-by-site template
**What it collects:** The canonical PMI IRS quantification tool (up to 3 sites side-by-side): assumptions/performance-standards, HR by cadre, insecticide by two methods, and a fully-itemized equipment/PPE/stores/stationery list.
**Fit:** Same as the Malawi IRS form — `ICRCampaign` type `irs`, `ICRSupplyDelivery`, `ICRCareTeam`.
**Gaps:** Identical structure-treatment / insecticide-quantification / commodity-identity gaps as the Malawi IRS workbook, in a cleaner canonical form:
- "Number of Structures", "Number of Structures Sprayed Per Spray Operator Per Day", "Number of Structures Sprayed Per Unit of Insecticide", "Total Wall Surface Area of Spray Area", "Wall Surface Area Covered Per Unit of Insecticide (sq. m) 250" — structure + surface-area quantification.
- Named equipment models as commodities: "Hudson X-Pert Sprayer", "Spare Parts Kit", "Nozzle Tip", full PPE list (Face shield, Apron, Gum boots, Haversack, Helmet, Overalls, Rubber Gloves short/long, Dust Mask). "Spill Kit" defined inline. Reinforces GS1/commodity gap.
- "Number of Stores Per Supply Truck (minimum 5 ton)", "Number of Spray Teams Per Transport Vehicle" — transport-capacity ratios, unmodeled.
**Terminology / valueset additions:**
- Same IRS cadre and location-type additions as the Malawi IRS form.
- An **IRS commodity/equipment CodeSystem** (spray pump, nozzle tip, soak-pit consumables, PPE items) if the IG chooses to structure IRS logistics rather than leaving free text.

### Zambia_LLIN_IRS District Microplan Template_ 2023-Final_blank.xls — Combined LLIN + IRS district microplan with IRS operations calendar (Zambia)
**What it collects:** The richest combined workbook — everything in the PMI ITN+IRS form **plus** a dedicated `IRS_location_data` sheet, an `IRS Calendar` spray-scheduling sheet, and a real `District Metadata` village gazetteer (Province/District/HF/Zone/Village + population + households, with actual data rows).
**Fit:**
- `District Metadata` rows (Central | Chibombo | Chamakubi Health Post | Chamakubi | Chikana | 412 | 68.7) → clean `ICRLocation` hierarchy + `ICRTargetPopulation` per village — this is exactly the microplan denominator the IG's `planningDenominator` is designed for.
- `IRS_location_data` columns → per-location IRS records.
**Gaps (definitive IRS structure-treatment + spray-scheduling evidence):**
- **`IRS_location_data` header, verbatim**: "Operation Site | Catchment Area | Location | Distance from IRS Base (KM) | Headcount Population | Intervention 2023 | Found 2022 (IRS) | Sprayed 2022 (IRS) | Total # of Structures 2023 | Total Eligible Structures 2023 (IRS) | Planned Structures 2023 (IRS)". Per-location structure denominators + prior-round outcomes — no IG home.
- **`IRS Calendar` = the spray event/coverage model, verbatim**: "Number of Structures [A] | Number of Days [B]=(A/224) | # SOPS Per Location [C]=A/14 | # Mobilizers Per Location [D]=(C/5)2 | Planned Dates of Spray | Found Structures 2023* | Sprayed Structures 2023* | Spray Coverage* | Mop Up Structures*". This is precisely a `Task`/event pairing planned-vs-actual for a **place**: planned structures + planned spray dates vs found/sprayed/coverage/mop-up. It is the concrete schema the proposed `ICRStructureTreatment` (or structured `Task.output` for IRS) would need — including a **spray-coverage** measure (sprayed ÷ found) distinct from population coverage, and **mop-up** as a disposition.
- **Spray-operator productivity constants embedded in formulae**: 224 structures/spray-period, 14 structures/SOP, mobilizer ratio — same quantification-coefficient gap, now for IRS.
- **Structure denominator distinctions**: "Total # of Structures" (all) vs "Eligible Structures" vs "Planned Structures" vs "Found" vs "Sprayed" — a four-to-five-stage structure funnel (census → eligible → planned → found → sprayed) with no IG denominator/coverage vocabulary.
**Terminology / valueset additions:**
- **structure-disposition** CodeSystem (verbatim from the calendar): `found`, `sprayed`, `mop-up`; plus `eligible`, `not-eligible`, `planned`, `locked`/`closed`, `refused` (the standard IRS not-sprayed reasons).
- New coverage measure `irs-spray-coverage` (sprayed structures ÷ found structures) and denominator `eligible-structures` — parallel to the existing person-based coverage Measures.
- ICRLocationTypeCS: `irs-base` (spray operations base), `operation-site`, `structure`.

### Cross-cutting findings — Malaria

- **IRS is the sharpest gap, and the field data give the IG its schema.** Across VL-Malawi IRS, S3, and both Zambia workbooks, IRS is planned and reported against **structures**, not people: found/eligible/planned/sprayed structure counts, structures-per-operator-day, structures-per-insecticide-unit, wall-surface-area, and a "Spray Coverage" = sprayed ÷ found. This directly validates the roadmap's proposed **`ICRStructureTreatment`** event and the **`structure` Location type**, and additionally demands (a) a `structure`/`eligible-structures` **denominatorType**, (b) a **structure-disposition** value set (`found`, `sprayed`, `mop-up`, `eligible`, `not-eligible`, `refused`, `locked`), and (c) an **`irs-spray-coverage` Measure** distinct from population coverage. Prior-round structure history (Found/Sprayed 2022 used to plan 2023) also argues for longitudinal structure records. This is the single strongest recommendation in the malaria set.

- **A shared net-quantification model has no home.** Every ITN form encodes population ÷ **persons-per-net (universally 1.8, "1 net per 2 people, round down")** → nets → **bales (40 or 50 nets/bale)** → **+ buffer/contingency (10% ITN, 20% insecticide/PPE)**, driven by an **average household size** (4.0–5.6) and workload norms (HH/registrar/day, HH/DP). The IG's `ICRTargetPopulation`/`ICRCampaignActivity`/`ICRSupplyDelivery` hold the inputs and outputs but not the **quantification coefficients** (persons-per-net, structures-per-unit, HH-size, buffer %). Recommend a small "quantification-parameter" extension (commodity-per-capita ratio + buffer + packaging-unit) — this also serves NTD and vitamin-A quantification.

- **GS1 / commodity-identity gap is decisively confirmed.** Nets appear only as free-text ("LLIN"/"ITN", "50 nets/bale"); insecticide appears as **named branded products with concentrations and pack-sizes** ("Fludora Fusion (66%)", "SumiShield (34%)", "UNITS of 130/60"), spray pumps as **manufacturer part numbers** ("IK VC Super 7.50; Goizper 8.18.75", "Hudson X-Pert"), and IRS insecticide is **individually serialized** (6-digit stickers, scanners, distribution-tracker, empty-bottle recycling). `ICRSupplyDelivery` has no GTIN binding and no per-item serialization/lot-return chain. Strengthens the roadmap GS1-binding item and adds a **serialization/track-and-trace** dimension not yet on the roadmap.

- **Bale/packaging unit + multi-leg supply chain.** "Bales vs loose nets", tonnage, "District store → PPS/cluster-warehouse → DS → DP" routing, road condition, transport mode, and **reverse logistics/returns** (2% leftover, empty-bottle recycling) recur in every workbook. `ICRSupplyDelivery.quantity` needs a **packaging tier** (bale/carton), and the IG needs a **supply-chain routing/location-hierarchy** for pre-positioning sites, warehouses, and stores — reinforcing the roadmap "logistics axis beyond readiness & SupplyDelivery."

- **Distribution-node hierarchy is under-specified.** Forms use a 2–3 tier node model — **Distribution Site (DS) → Distribution Point (DP)**, plus **satellite/holding points (DH)**, **pre-positioning sites (PPS)**, and DP-type = **fixed / outreach / mobile** (AMP: "verify whether distribution points are fixed, outreach or mobile"). `ICRLocationTypeCS` has a single `community-distribution-point`; recommend subtypes (`distribution-site`, `distribution-point`, `prepositioning-site`, `holding-point`) and confirm `deliveryStrategy` (`fixed-post`/`outreach`/`mobile`) is stored on the DP Location, not just the Task.

- **Team-role vocabulary is far too narrow.** `ICRTeamRoleCS` (vaccinator/cdd/supervisor/social-mobilizer/recorder) misses the entire ITN and IRS workforce: ITN — `registration-assistant`, `distribution-point-attendant`, `hsa`, `cbv`/volunteer, `data-entry-officer`; IRS — `spray-operator`, `team-leader`, `site-manager`, `spray-supervisor`, `washer`, `security-guard`, `pump/sprayer-technician`, `store-keeper`, `iec-assistant`, `mobilizer`, `chag`, `m&e-assistant`, `mhealth-coordinator`. All quoted verbatim from the HR-summary sheets.

- **Two-phase campaign (registration → distribution) and de-facto vs de-jure population.** ITN campaigns are explicitly two-phase (`dénombrement`/HHR then distribution; coupon issuance in Ghana). The IG's single-intent CarePlan handles the phase transition (plan→order) but not two distinct activity phases with separate personnel/tools each. Forms also carry **both** projected (CSO/census) **and** head-count/enumeration population ("Total population (CSO)" vs "Total population (Head count)"), plus external sources **WorldPop-like "Reveal Population"** — argues for `denominatorSource` codes `reveal`, `head-count`/`enumeration`, and the roadmap "population-estimation-method."

- **AMP methodology alignment (reuse mission).** The AMP chapter frames the whole ICR reuse thesis in malaria terms: macroplanning (national, census/projection, ±10% contingency) vs microplanning (implementation-level, head-count-updated), "Can microplans from the **previous campaign** be used?" and "Can microplans from **EPI** be used?" — i.e. explicit cross-round and cross-programme reuse of the same denominator/geography/DP artifacts the IG models. It confirms `intent=plan` (microplan) → `intent=order` (execution), the >10% macro-vs-micro discrepancy flag (a reconciliation/data-lineage concern), and DP-type fixed/outreach/mobile. Terminology to harvest verbatim: `macroplanning`/`microplanning`, `HHR (household registration)`, `DP/catchment area`, `pre-positioning site`, `micro-positioning plan (MPP)`, `contingency/buffer stock`.

* * *

## NTD (MDA — LF / Oncho / Schistosomiasis / STH)

Twenty-one preventive-chemotherapy NTD mass-drug-administration forms spanning **microplanning & drug/tools quantification** (Benin, Nigeria, Senegal, Madagascar, Burundi), **geographic-coordinate / geographic-coverage surveys** (Liberia ×3), **treatment-result & coverage summaries** (Nigeria, Guinea-Bissau, Guinea), and **live digital supervision instruments** (Sightsavers CommCare ×3, TCC ODK) — in English, French, and Portuguese. This is the largest and most linguistically diverse set, and the one that most directly exercises the ESPEN-forms round already in the IG (§4.8): these forms mostly **fit** the MDA model (`ICRMedicationAdministration`, `icr-mda-treatment-coverage`, dose-pole band, community-directed strategy, `ICRNTDDiseaseCS`/`ICRMDAMedicinePackageCS`) while exposing a consistent frontier — forward drug quantification, the eligible-target (UTG) denominator, multilingual terminology, delivery-site typology, and the supervision-model gaps the live CommCare/ODK tools make unavoidable.

### A conserver_Microplan TDM Oncho_V_08_01_2025_blank.xlsm — Oncho CDTI mass-treatment (TDM) microplan + costing macro-workbook (Benin, French)
**What it collects:** A full national ivermectin (Ivermectine 3mg) community-directed mass-treatment microplan for Benin — planning assumptions (`HYPOTHESE`), the 5-level admin hierarchy rolled up at each level (`MASTER ARR/COM/ZS/DEP`), a rich village-level operational register (`Villages`), and an embedded cost/budget engine. It computes teams, distributors, criers, transport, drugs and money from population.
**Fit:**
- Admin hierarchy `Département > Zone Sanitaire > Commune > Arrondissement > Village` (+ `Aire de Supervision (AS)`) → nested `ICRLocation.partOf`; `ID PARENT`/`ID` slots map to `ICRLocation.identifier`.
- `Population (Instad 2024)` + `Population Cible Instad 2024 (PT*82,36%)` → `ICRTargetPopulation.quantity` with `denominatorSource` = census-projection (INStaD) and `estimateDate`; the ×82.36% is an eligibility-fraction derivation (see gaps).
- `Nombre de ménages`, `Nombre de Grappe` (clusters) → `ICRDeliveryUnit` (household) counts / register-level `quantity`.
- Workforce (`Nombre RC Santé Com de distribution`, `crieurs publics`, `chefs de villages`, `ASCQ`, `ICP`, `superviseurs …`) → `ICRCareTeam` participants (`ICRTeamRoleCS`: cdd, social-mobilizer, supervisor) with `workloadTarget`.
- Strategy is community-directed (CDTI/TDC) → `ICRDeliveryStrategyCS: community-directed`; campaign type `mda`; disease `oncho` (`ICRNTDDiseaseCS`); product `ivm` (`ICRMDAMedicinePackageCS`).
- Prior-round therapeutic-coverage history (`Couverture thérapeutique du TDM` 2022/2024) → `ICRAdministrativeCoverage` / `icr-mda-treatment-coverage` for past rounds linked via `partOf`.
- Non-treatment causes `Refus` / `Absence` → `ICRMissedReasonCS: refusal, absent`.
- `Village frontalier avec le Togo ou le Nigéria` → `ICRSettlementTypeCS: cross-border`; `Difficulté d'accès`/`Population dispersée`/`Problèmes de sécurité` → hard-to-reach / (dispersed → new) / security-compromised.
**Gaps:**
- **Drug quantification/forecasting math has no ICR home.** `Nombre de comprimés requis TDM OV 2025` | `Nombre de comprimés restants TDM OV 2024` (carryover stock) | `Nombre de comprimés Total TDM OV 2025`, plus `HYPOTHESE` params `Ratio Personnes/Ivermectine = 2.5` and `Taux de stock de sécurité d'ivermectine = 0.01` (buffer stock). ICR `ICRSupplyDelivery.stockAccountability` records received/used/remaining *after* the fact but there is **no requisition/quantification artifact** (need = target ÷ tablets-per-person − carryover + buffer). Genuinely new (roadmap has doses-per-vial/wastage but not forward forecasting).
- **Eligibility-fraction denominator.** `Taux moyen d'éligibilité = 0.8236` derives treatment target from total pop. `ICRDenominatorTypeCS` only has `total-population | at-risk`; no `eligible-for-treatment` and no slot to store the eligibility % as a derivation parameter. Recurring across every NTD form.
- **Embedded activity-based costing** (per-diems, fuel by vehicle type, room hire, vehicle rental, banner/vest/chalk unit costs across ~118 `HYPOTHESE` rows). Budget/costing is out of ICR scope but is inseparably co-bundled with the microplan here — a transform/routing note.
- **Countable campaign tools & IEC commodities** (`banderoles` per admin level, `gilets`/vests, `Bâtons craie`/chalk, training manuals) — no ICR commodity vocabulary (see cross-cutting terminology).
- Transport/logistics microplan fields (`Mode de transport TDM OV`, `Dates de transport`, `Aire(s) de santé à déservir`) — no per-Location transport-mode/route attribute.
**Terminology / valueset additions:**
- Add `dispersed-population` to **ICRSettlementTypeCS** (`Population dispersée`, FR), distinct from existing `hard-to-reach`.
- Add `town-crier` (`crieur public`, FR) and `village-chief` (`chef de village`) and `ASCQ`/community-QA-agent to **ICRTeamRoleCS** — recurring MDA field roles absent from vaccinator/cdd/supervisor/social-mobilizer/recorder.
- `Aire de Supervision (AS)` confirms **ICRLocationTypeCS: supervisory-area**; `Type d'AS (Urbain/Rurale)` → settlement urban/rural (present).
- Multilingual: `TDM` (traitement de masse) = MDA; `TDC/TIDC` = CDTI/community-directed; `RC` (relais communautaire) = CDD.

### Kogi 2025 Micro planning Template (headers only)_blank.xlsx — integrated Oncho+STH+SCH community microplan (Nigeria, English)
**What it collects:** LGA/ward/community-level microplan for an **integrated** three-disease MDA (Oncho, STH, SCH), with per-disease targets, settlement characterization, CDD/teacher workforce sizing, and per-drug quantity requirements.
**Fit:**
- `LGA > Name of ward > FLHF > Name of Community` → `ICRLocation.partOf`; community → `ICRDeliveryUnit` (community kind).
- `Total pop of Community`, `SAC` (school-age children), `Adult`, and three `Target for 2025` columns under `Oncho | STH | SCH` → per-disease `ICRTargetPopulation` (age-band characteristics), one campaign of `ICRCampaignTypeCS: integrated`.
- `No of Drugs IVM required | No of Drugs MEB required | No of Drugs PZQ required` → per-`ICRCampaignActivity.product` (ivm/meb/pzq) quantification.
- Workforce `No of CDDs Required | Number of CDDs Approved | Number of Health workers | No of Teachers Required` → `ICRCareTeam` + `workloadTarget`.
- `Settlement Type` → `ICRSettlementTypeCS`; `Name/Phone of in-charge` → `ICRCareTeam.participant` telecom.
- Tools count (`Treatment registers in Community`, `Ward summary form`, `LGA Summary form`, `No of Training Manuals`, `Posters need in community`) → supply/readiness.
**Gaps:**
- **Per-disease endemicity of the implementation unit** — the Oncho/STH/SCH column groups encode *which diseases this community is targeted for*. ICR has no per-disease endemicity/co-endemicity classification on `ICRLocation`/`ICRTargetPopulation`. Genuinely new NTD-specific gap; strong case with the integrated campaign model.
- **`Settlement Security Accessibility` and `Settlement Terrain` are separate axes from `Settlement Type`.** ICR collapses everything into `ICRSettlementTypeCS`; terrain (riverine/hilly) and security-accessibility are orthogonal. New.
- **`Number of PWDs as CDDs`** (persons with disabilities recruited as distributors) — an equity/inclusion workforce attribute with no ICR home on CareTeam.
- Drug/tool quantification (same forecasting gap as form 1) and countable IEC commodities (posters, registers, summary forms, manuals).
**Terminology / valueset additions:**
- Add `settlement-terrain` and `security-accessibility` as **separate** coded axes (or extensions on `ICRLocation`) rather than folding into `ICRSettlementTypeCS`; seed terrain values e.g. `riverine`, `hilly`, `island`, `plain`.
- Add `teacher` / `school-based-distributor` to **ICRTeamRoleCS** (`No of Teachers Required`).
- Add a `pwd-distributor` / disability-inclusion flag for CareTeam participants (`Number of PWDs as CDDs`, EN).
- Confirms `ICRLocationTypeCS` needs **`health-facility-catchment`** for `FLHF` (Front-Line Health Facility) — the smallest MDA reporting unit (see cross-cutting).

### MAQUETTE MICROPLAN DISTRICT TEMPLATE_blank.xlsx — SCH+STH (GEO) school/community DMM district microplan (Senegal, French)
**What it collects:** Senegal `PNLMTN` district-level mass-drug-distribution (DMM) microplan for schistosomiasis + soil-transmitted helminths (GEO), organized by health post (PPS): demographics, PPS→village cartography, and a needs-estimation sheet for drugs, human resources, dose-poles, management tools and communication supports.
**Fit:**
- `Région Médicale > District > Poste/Centre de santé (PPS) > Village/Quartier` → `ICRLocation.partOf`; PPS is a facility-anchored catchment.
- `Population` / `Population cible` derived at `28,83%` (SAC proportion) → `ICRTargetPopulation` (age-band SAC), `estimateDate`.
- `Medicaments: Albendazole | Praziquantel` → `ICRCampaignActivity.product` (`alb`, `pzq`).
- HR (`Nombre d'equipe`, `nbre de distributeurs`, `nbre d'enseignant`, `nbre de superviseurs`) → `ICRCareTeam`; delivery strategy school + community.
- `Distance Village/PSS`, `Distance du PPS/CS` → could inform `ICRLocation` logistics (no home today).
**Gaps:**
- **Schisto environmental transmission-risk fields co-bundled in the microplan:** `Existence de mare temporaire oui/non` (temporary pond = transmission site) and `Nombre d'école élémentaire avec source d'eau` (schools with water source). These are targeting/WASH-risk variables ICR treats as surveillance/reference — flag co-bundling.
- **`Toises` (dose-poles) tracked as a countable commodity** with `Disponibles | Besoins | Total` — ICR has `dosePoleBand` on MedicationAdministration but no dose-pole as a `ICRSuppliedItem`. New.
- **Management tools & promo commodities**: `Outils de Gestion SCHISTO/GEO` (`Fiches pointage`/tally, `Fiches synthese Equipe/Poste`), `SUPPORTS PROMOTIONNELS` (`Tee-shirt`, `Polo`, `Casquettes`), `Affiches Schisto`, `Affiches complications`. No commodity vocabulary (cross-cutting gap; per-disease tool variants).
- Drug quantification/forecasting math (same as form 1).
**Terminology / valueset additions:**
- Add `koranic-school` / `daara` to **ICRLocationTypeCS** (or a school subtype) — `Nombre de Daara`, FR (Senegal Quranic schools are a distinct distribution venue alongside `école élémentaire`/`collège`).
- Add `dose-pole` (`toise`, FR) to **ICRSuppliedItemVS**.
- Multilingual disease codes for **ICRNTDDiseaseCS** ConceptMap: `GEO`/`géohelminthiase` = `sth`; `SCHISTO`/`bilharziose` = `schisto`; `DMM` (Distribution de Masse de Médicaments) = MDA.

### MICROPLAN 2025 BIL_GEO 29 janv2026_blank.xlsx — SCH (BIL) + STH (GEO) fokontany microplan (Madagascar, French)
**What it collects:** Madagascar bilharzia (BIL) + geohelminth (GEO) MDA microplan at CSB (health-center) and fokontany (village) level: contacts, distances/transport, age-split population, and PZQ need.
**Fit:**
- `REGION > DISTRICTS > COMMUNE > NOM CSB > NOM DU FOKONTANY` → `ICRLocation.partOf`; `NOMBRE DE HAMEAU` (hamlets) → sub-settlement `ICRDeliveryUnit`/count.
- `POPULATION 5-14 ANS` / `POPULATION 15 ANS ET +` → `ICRTargetPopulation` age-band characteristics; `BESOIN EN PZQ` → product `pzq` quantity.
- `NOM CHEF CSB` / `CONTACT CHEF CSB` → CareTeam contact; `PLAN DE TRAITEMENT` → treatment plan/`ICRCampaignProtocol` reference.
**Gaps:**
- `DISTANCE SDSP/CSB`, `DISTANCE CSB-FOKONTANY`, `MOYEN DE LOCOMOTION` (transport mode, given twice — district→CSB and CSB→village) — no ICR travel-distance/transport-mode microplanning attribute on Location. Recurring logistics gap.
- `NOMBRE DE HAMEAU` — hamlet as a sub-village settlement unit; ICR `ICRDeliveryUnit` handles the count but there is no settlement-typology code for hamlet vs village.
- PZQ forecasting (same quantification gap).
**Terminology / valueset additions:**
- Add admin-level labels to a Madagascar ConceptMap: `Fokontany` = lowest admin unit / settlement; `Hameau` = hamlet (sub-settlement); `CSB` (Centre de Santé de Base) = facility.
- `BIL`/`bilharziose` = `schisto`, `GEO` = `sth` (reinforces the FR ConceptMap need).
- Consider `hamlet` in **ICRSettlementTypeCS** (recurs as `Hameau` FR / `hamlet` EN).

### Planification_ APPROVISIONNEMENT_EN_MEDICAMENTS_ET_OUTILS_ Campagne 2023_blank.xls — CDTI drug + tools supply-quantification & distribution ledger (Burundi, French)
**What it collects:** Burundi `PNIMTNC` / `PROJET TIDC` ivermectin(Mectizan)+albendazole quantification down to `Colline` (hill = lowest unit), then per-health-center supply-distribution ledgers ("received" quantities of drugs and tools). This is the **explicit drug-and-tools supply-chain form** the microplans imply.
**Fit:**
- `Province Sanitaire > District sanitaire > Commune > Centre de Santé > Colline` → `ICRLocation.partOf`.
- Per-CDS delivery ledger (`Mectizan Réçu`, `Albendazole réçu`, tools received) → `ICRSupplyDelivery` (suppliedItem, quantity, destination=CDS Location); products `ivm`, `alb`.
- `Population totale attendue 2023` / `OAT 2023` (objectif à traiter) → `ICRTargetPopulation` (denominator + treatment target).
**Gaps:**
- **The core quantification chain is unmodeled:** `Besoins éstimés en Mectizan` (estimated need) → `Mectizan en stock 2022` (opening stock) → `Besoins Réels en Mectizan 2023` (net need) → `Besoins Réels conditionnés en 500` / `…par boites de 500 avec arrondissement` (packaged & rounded to 500-tablet boxes) → `Mectizan approvisionnés` (procured). ICR has no requisition/forecast object and no **pack-size/`conditioned-in-500`** concept (relates to the roadmap GS1/GTIN gap — strengthens it).
- **Tools/`OUTILS` inventory as commodities:** `Registre de recensement et de traitement familial` (family census+treatment register), `Fiche de pointage Albendazole` (tally), `Fiche de Rapport DC` (distributor report), `Fiche rapport mectizan/Albendazole CDS`, `Toises` (dose-poles). No ICR commodity vocabulary for campaign tools/registers/reporting forms.
**Terminology / valueset additions:**
- Add commodity codes to **ICRSuppliedItemVS** (or a new `ICRCampaignMaterialCS`): `treatment-register`, `tally-sheet`, `distributor-report-form`, `summary-report-form`, `dose-pole`, `training-manual`, `poster`, `banner`, `vest`, `chalk`. Recurs verbatim across forms 1/3/5 in FR + Kogi in EN.
- Note pack-size / `conditioned` unit (`boîte de 500`, FR) — supports a packaging/GTIN slot on SupplyDelivery.
- `OAT` (Objectif à Traiter, FR) = treatment target denominator; `Mectizan` = ivermectin (Mectizan Donation Program brand — donation-program provenance is metadata worth a note).

### Geographical Coordinate Survey Data NOrth West 2012_blank.xls — GPS village-listing by health-facility catchment (Liberia, English)
**What it collects:** A minimal community geo-registry: one row per community with catchment, clan, population, household count and GPS.
**Fit:**
- `No | County | District | FLHF | Clan | Community | Population | NO. of Households | Latitude | Longitude | Altitude` → `ICRLocation` (community) with `position` (lat/long/**altitude**), `partOf` chain, and `ICRDeliveryUnit`/`ICRTargetPopulation` for population & households. This is essentially the geo-seed for the ICR Location registry.
**Gaps:**
- `Altitude` — ICR `Location.position` (FHIR) supports altitude, but note it should be carried (elevation used for some vector NTDs). Minor.
- `Clan` — a social/settlement grouping between district and community (see terminology).
- `FLHF` catchment as the operational parent — see cross-cutting `health-facility-catchment` gap.
**Terminology / valueset additions:**
- Add `clan` (EN, Liberia — also a recurring West-African social unit) as an **ICRLocationTypeCS** / settlement grouping value.
- Reinforces **`health-facility-catchment`** in ICRLocationTypeCS (`FLHF` / `Health Facility Catchment`).

### Geographical Coordinate Survey Data South West 2013_blank.xls — Oncho community geo + treatment-history / geographic-coverage survey (Liberia, English)
**What it collects:** Form `GC03`: for each town/village, whether it is on the official `MOH/APOC list`, last year of treatment, tablet size/color observed, years CDTI running, a **year-by-year treated matrix (2006–2012)**, CDD counts by sex, and GPS. An `analysis` sheet computes geographic coverage (communities on-list vs treated per year, CDD gender %).
**Fit:**
- Community geo + catchment/clan hierarchy → `ICRLocation` (as form 6).
- `Male CDD | Female CDD | Total CDD` → `ICRCareTeam` composition.
- Per-year treated matrix + `analysis` (`Community treated 20XX` / `Community not-treated`, `% of Communities treated`) → `ICRSurveyCoverage` / `icr-geographic-coverage` Measure (coverageUnit = implementation-units).
- `Town or village in MOH/APOC list (Yes=1,No=2)` → the pre-planned vs field-registered distinction (`ICRTaskOriginCS`), i.e. community-registry completeness.
**Gaps:**
- **Community-registry validation / "listed vs found vs treated" data quality** — the survey's purpose is to reconcile the official community register against ground truth. ICR has `field-registered` on Task but no first-class **registry-completeness / community-listing-status** concept on Location, nor a coverage stratifier for on-list vs off-list. Genuinely new (data-quality/geographic-coverage flavor beyond the admin/survey coverage split).
- **CDD gender disaggregation** (`Male/Female CDD`) — no CareTeam composition-by-sex home.
- `Size and Color of the Drugs (big and small white=1…)` / `How long treatment has been ongoing (years)` — field verification of drug identity & program tenure; program-tenure ("number of rounds/years") has no planning slot.
- Multi-round treatment history embedded (2006–2012) as a planning/monitoring input — ICR models rounds via `partOf` but not a compact prior-round coverage series on the community.
**Terminology / valueset additions:**
- Add `on-official-list` / `registry-listed` vs `unlisted` status (Location extension or `ICRCoverageStratifierCS` value) — supports the geographic-coverage completeness story.
- Add a `sex` composition axis for `ICRCareTeam` (or reuse coverage stratifier `sex` for workforce) — `Male/Female CDD` recurs (also Liberia SE, Benin implicitly).
- `APOC`/`MOH list` = the national/programmatic community register.

### Geographical Coverage Survey Data South East 2013_blank.xls — Oncho geographic-coverage survey (Liberia, English)
**What it collects:** Identical `GC03` instrument to the South-West form (community on-list Yes/No, last year treated, tablet size/color, years running, 2006–2012 treated matrix, CDD by sex, GPS) for the South-East counties.
**Fit:** Same mapping as the South-West form — `ICRLocation` geo-registry, `ICRSurveyCoverage`/`icr-geographic-coverage`, `ICRCareTeam`, `ICRTaskOrigin` (on-list vs found).
**Gaps:** Same as South-West (community-registry completeness as a first-class concept; CDD gender composition; program-tenure/years-running; embedded multi-round treated matrix). No new gaps beyond form 7 — the pair is evidence these geographic-coverage/community-listing surveys are a **standard recurring NTD instrument**, strengthening the case for a Location listing-status + geographic-coverage-completeness model.
**Terminology / valueset additions:** As form 7 (`registry-listed`/`unlisted`, CDD `sex` composition, `health-facility-catchment`, `clan`). Header spelling variants confirm ConceptMap need even within one language (`Health Distrcit`, `Statis of CDTI`, `Health Facility catchement`).

### Données_evaluations_oncho_blank.xls — Onchocerciasis epidemiological/entomological impact-assessment (English, francophone origin)
**What it collects:** A pure **surveillance / impact-evaluation** instrument: per survey site, diagnostic results across MF skin-snip (examined/positive/%, CMFL), serology (Ov16), PCR in black flies (vector poolscreen), and crab infestation, plus a programmatic decision.
**Fit:**
- Only the *program-metadata* columns fit ICR: `Survey type`, admin `level 1/2`, `community`, `Latitude/Longitude` → `ICRLocation`; `Date of the first PC round (year)`, `Treatment strategy`, `Number of rounds of PC delivered prior to survey` → campaign/round provenance (`ICRCampaign` history, `partOf`).
- `Survey sites` + `Programmatic decision` → could reference an `ICRSurveyCoverage`-adjacent decision, but the coverage model does not carry epi endpoints.
**Gaps (mostly deliberately out-of-scope):**
- **Entire epidemiological/entomological payload is out of ICR scope** ("surveillance/morbidity = reference, don't model"): `MF skin snip`, `Serology`, `% positive`, `CMFL` (community microfilarial load), `PCR in black flies` / `Species of the vector` / `% poolscreen positive`, `Crab infestation`. This form is the clearest example of surveillance data that must be **routed to a surveillance store**, not the ICR FHIR store.
- **Co-bundling flag:** it mixes those out-of-scope results with genuinely program-relevant fields — `Treatment strategy`, `Number of rounds of PC delivered`, `Pre-control prevalence (%)`, `Programmatic decision`. The transform must split: keep program metadata (rounds/strategy) referenceable in ICR, ship epi/ento results elsewhere. Also touches the open "vector control / entomological surveillance — scope decision" roadmap item.
**Terminology / valueset additions:**
- None for ICR core (surveillance vocabulary belongs to the surveillance store). Worth recording `PC` (preventive chemotherapy) = MDA and `pre-control prevalence` / `number of PC rounds` as program-provenance fields ICR may want to *reference* (candidate for the proposed programme-semantics quartet: number-of-rounds delivered).

### GESTAO DADO BAFATA_24.05.2024_blank.xls — LF+Oncho integrated MDA treatment register & coverage data-management workbook (Guinea-Bissau, Portuguese)
**What it collects:** A Portuguese-language data-management workbook for integrated **Filariose Linfática + Oncocercose** MDA: a village (`tabanca`) treatment register (`xitole`) with age×sex census/treated counts, drugs used, untreated reasons, adverse reactions and GPS; a results roll-up (`RESUL_BAFATA`) with geographic (`CG%`) and therapeutic (`CT%`) coverage; and an `IVM-ALB` supply sheet.
**Fit:**
- `Area Sanitaria > Tabanca/Bairro` → `ICRLocation.partOf`; `tabanca` (village) → `ICRDeliveryUnit`; GPS `Latitude/Longitude`/`Coordenados geograficas` → `Location.position`.
- Census vs treated by age (`5-14 anos`/`15 anos e mais`) × sex (`Hom/Mulher/Total`), `Recenseada/Tratada` → `ICRTargetPopulation` (denominator) + `ICRMedicationAdministration` counts / `icr-mda-treatment-coverage` stratified by age-band & sex.
- Drugs `IVERECTINA | ALBENDAZOLE | MEBENDAZOLE`, `N° CP distribuidos` / `Comprimidos usados` → products `ivm/alb/meb` + `ICRSupplyDelivery` usage.
- Untreated reasons `Ausente | Recusa | Doente` → `ICRMissedReasonCS: absent, refusal, sick`; exclusions `Gravida` (pregnant) / `Aleitando <7 dias` (breastfeeding) → `ICRExclusionReasonCS: pregnant, breastfeeding`; `Crianças (0-59 meses)` under-age → `under-height-age`.
- Adverse reactions `Reacção ligeira | Reacção severa | Casos referidos para o centro de saúde` → `ICRAdverseEvent` (seriousness non-serious/serious, referral).
- Coverage thresholds `N° tabanca tratada com CT ≥ 65%` / `CT > 79,999%` → programmatic coverage-target thresholds → `icr-mda-treatment-coverage`; `CG%`/`CT%` → geographic/therapeutic coverage.
**Gaps:**
- **LF morbidity fields co-bundled with treatment data:** `Linfodema/Elefantiase`, `Hidrocelo` (hydrocele), `Elefantiase da mama` (breast elephantiasis) counts — chronic-morbidity/surveillance data ICR treats as out-of-scope; flag the co-bundling (route to surveillance/morbidity store).
- **Coverage-target threshold as stored programme semantics** — `CT ≥ 65%` and `CT > 79,999%` are the WHO effective-coverage thresholds counted per village. Reinforces the roadmap "coverage-target (store the programme threshold)" quartet item.
- **Integrated LF+Oncho single-register** (one ivermectin+albendazole distribution covering two diseases) — validates modeling `integrated` campaigns with multiple `ICRNTDDiseaseCS` targets on one delivery event.
**Terminology / valueset additions:**
- Portuguese ConceptMap (Guinea-Bissau) for **ICRMissedReasonCS / ICRExclusionReasonCS**: `Ausente`=absent, `Recusa`=refusal, `Doente`=sick, `Gravida`=pregnant, `Aleitando <7 dias`=breastfeeding, `Crianças (0-59 meses)`=under-height-age.
- Portuguese coverage terms: `Cobertura Geográfica (CG)` = geographic coverage, `Cobertura Terapêutica (CT)` = therapeutic/treatment coverage — align to `icr-geographic-coverage` / `icr-mda-treatment-coverage`.
- Admin/settlement PT: `Tabanca` = village (Guinea-Bissau; add to settlement/Location ConceptMap), `Bairro` = neighborhood/quarter, `Area Sanitária` = health area/catchment (again supports `health-facility-catchment`).
- Drug PT spellings for ConceptMap: `IVERECTINA`=ivermectin (`ivm`), `ALBENDAZOLE`=`alb`, `MEBENDAZOLE`=`meb`.

### EDO SECOND ROUND DRUG DISTRIBUTION 2024 MDA_Corrected_blank.xlsx — LGA/village drug-distribution & treatment tally (Nigeria, Edo State, English)

**What it collects:** One row per settlement, per-LGA sheet (AKOKO EDO, ESAN CENTRAL, …), tallying ivermectin (and in OVIA SOUTH WEST, albendazole) distributed against a population target. Columns: `LGA | WARD | PHC | VILLAGES | POPULATION | UTG | TOTAL IVM | IVM IN CUP` (OVIA SOUTH WEST adds `ALB | ALB IN CUP`).

**Fit:**
- Admin hierarchy `LGA | WARD | PHC | VILLAGES` → `ICRLocation` `partOf` chain; `PHC` (primary health centre) is a `facility`, `VILLAGES` a `settlement`. Maps cleanly.
- Per-village treated counts (`TOTAL IVM`) → `ICRAdministrativeCoverage` numerator per implementation unit (register-level MDA), or a Group-subject `ICRMedicationAdministration` per village per drug (§6.2).
- `POPULATION` → `ICRTargetPopulation.quantity` (denominator).

**Gaps:**
- **`UTG` (Ultimate Treatment Goal)** is a distinct NTD denominator — the eligible-for-treatment target after removing ineligibles — sitting *alongside* raw `POPULATION`. ICR's `ICRDenominatorTypeCS` offers only `total-population | at-risk`; UTG is neither exactly. Genuinely worth a `ultimate-treatment-goal` (or `eligible-target`) denominator-type code, since NTD "therapeutic/programmatic coverage" is computed against UTG, not total population. Strengthens the roadmap `coverage-target` item.
- **`IVM IN CUP`** — a physical drug-counting method (tablets pre-counted into cups) distinct from `TOTAL IVM` (tablets consumed). No ICR home; minor, but it is a distribution-accounting artifact.

**Terminology / valueset additions:**
- Add `ultimate-treatment-goal` to `ICRDenominatorTypeCS` (or document that UTG maps to `at-risk`). NTD denominators (`POPULATION` census vs `UTG` eligible) recur across every form in this set.

---

### RESUMO TRATAMENTO 2024 (headers only)_blank.xlsx — LF/oncho treatment & morbidity summary (Guinea-Bissau, Portuguese/French)

**What it collects:** Per-region worksheets (bafata, bijagos, cacheu, …) summarizing lymphatic-filariasis (`Tab2: Filariose linfatica`) and onchocerciasis treatment by health area (`Area Sanitaria`) and village (`Bairro/Tabanca`), plus supervisor/CDD training tallies (`formaçao`), a national drug-inventory sheet (`IVM_ALB`), and morbidity/case-management counts (`Disease Manag`).

**Fit:**
- `Regioes / Area Sanitaria / Bairro/Tabanca` → `ICRLocation` hierarchy (`tabanca` = hamlet/settlement).
- Treated by age×sex — `5-14 anos Tratadas` / `15 anos e mais tratadas` split into `Hom | Mulher | Total` → `ICRAdministrativeCoverage` sex × age-band stratifiers (the `icr-mda-treatment-coverage` cube).
- `formaçao` supervisor/CDD training counts (`Supervisors formados`, `ASC/DC formado`, `Masculino/Feminino`, `Novo/Antigo`, `objetivo anual`, `%Atangido`) → pre-campaign readiness/training; partially `icr-campaign-readiness-checklist`, but the *quantified* trained-vs-target-by-sex-and-new/returning breakdown has no structured home (see gap).
- `IVM_ALB` inventory (`Stock Inicio | Abasticimento Regioes | perdidos | espirado | usado | Stock físico/restante`) → `ICRSupplyDelivery` `stockAccountability`.
- `Latitude | Longitude` per tabanca → `ICRLocation.position`.

**Gaps:**
- **Three distinct NTD coverage measures side by side:** `Coubertura geografica (%)` (geographic — villages treated), `Coubertura Terapeotica (%)` (therapeutic — treated ÷ eligible), and a threshold pass/fail split `≥ 65%` / `≥ 80%` (`N° tabanca tratada com Coubertura Terapeutica`). ICR's coverage model (`coverageUnit people|implementation-units`) captures geographic vs dose coverage, but NTD **therapeutic coverage against the UTG denominator** and the **programmatic threshold flags (65%/80%)** are not first-class — reinforces the roadmap `coverage-target` (store the programme threshold) item and the UTG denominator gap above.
- **`perdidos` (lost) and `espirado` (expired)** as distinct stock dispositions. `ICRSupplyDelivery.stockAccountability` has received/used/remaining/notUsable/returned — **no `lost/missing` and no `expired` bucket** (`espirado` ≠ `notUsable`/damaged). Recurs as `Perdus` (French forms) and `Tabs missing` (VILLAGE/SCHOOL SUMMARY). New, concrete gap.
- **Denominator provenance `Recenseada` (enumerated/census) vs `Recenseada (INASA)`** (national statistics institute projection) — two named denominator sources. `INASA` is a national-stats-office projection → maps to `ICRDenominatorSourceCS` but that CS lacks a `national-statistics-office`/`census-projection`-by-NSO code (it has `census`, `census-projection`, `hmis`, `worldpop`, `grid3`). Minor: `census-projection` likely covers INASA.
- **Morbidity management (`Gestao morbididade`): `LINFOdema/Elefantiase`, `Hidrocelo`, `Elefantiase da mama`, `Trichiasis`, `Casos referidos para o centro de saúde`, and the `Disease Manag` surgery counts (`% receiving surgery for hydrocele`, `% receiving care of those with lymphedema`).** This is MMDP / morbidity surveillance — **ICR out-of-scope** ("reference, don't model"; route to surveillance store). Confirmed out-of-scope; flag only that these MMDP counts are prominent and recur (French/Portuguese forms all carry `Complications MTN-CTP`), so the transform must reliably shunt them.
- `Nombre d'ESG` (school-age-children group?) — ambiguous, no reliable mapping.

**Terminology / valueset additions:**
- Add `lost` (a.k.a. `missing`) and `expired` codes to the stock-accountability disposition vocabulary (currently the extension's received/used/remaining/notUsable/returned set) — verbatim source terms `perdidos`/`espirado` (pt), `Perdus`/`espiré` (fr), `missing`/`wasted` (en).
- Multilingual therapeutic-coverage terms to gloss: `Coubertura Terapeotica` (pt) = `Couv. Epidémiologique/Therapeutique` (fr) = therapeutic coverage; `Coubertura geografica` = geographic coverage.

---

### VILLAGE_CHURCH_SCHOOL_TREATMENT_SUMMARY_EDO 2020_blank.xlsx — treatment register w/ delivery-site typology, full drug ledger & AE (Nigeria, Edo State, English)

**What it collects:** The richest treatment register in the set. One row per settlement with CDDs trained (M/F), census counts, and per-disease treated counts (river blindness/oncho, LF, SCH, STH) disaggregated by sex and age band, plus a full four-drug accountability ledger and adverse-event counts. The sheet name and `List` sheet key on **village / church / school** as delivery-site types.

**Fit:**
- `State Name | LGA Name | Ward Name | FLHF Name | Settlement/village/community name` → `ICRLocation` hierarchy (`FLHF` = front-line health facility).
- `CDDs trained M | CDDs trained F | Total` → `ICRCareTeam` participants / readiness training counts (sex-disaggregated).
- Census block `Census # H/Hs | Census M | Census F | Total Census | 0-4 yrs | 4-14yrs | 15 yrs +` → `ICRTargetPopulation` with age-band + sex characteristics.
- Per-disease treated: `RB RX M/F/Total`, `RB RX 5-14 YRS M/F/Total`, `Oncho Tx Total`, `LF RX …`, `SCH RX 5-14 yrs M/F`, `STH RX 5-14 yrs M/F` → `ICRAdministrativeCoverage` cubes per disease (`ICRNTDDiseaseCS` rb/oncho=`oncho`, LF=`lf`, SCH=`schisto`, STH=`sth`).
- Drug ledger `IVM GIVEN | ALB GIVEN | PZQ GIVEN | MEB GIVEN`, `… USED`, `… REMAINING` and per-drug `IVM/ALB/PZQ/MBD USED` → `ICRSupplyDelivery` stockAccountability + `ICRMedicationAdministration` (ATC → `ICRMDAMedicationVS`; MEB=mebendazole, PZQ=praziquantel).
- Exclusion/absence tally `ABSENT | REFUSED | PREGNANT | UNDERAGE (< 5yrs) | BREAST FEEDING | SICK | TOTAL` → maps precisely to `ICRMissedReasonCS` (`absent`), `ICRNoncomplianceReasonCS` (`refusal`), `ICRExclusionReasonCS` (`pregnant`, `breastfeeding`, `under-height-age`≈UNDERAGE, `acute-illness`≈SICK). Good fit — validates the exclusion CS.
- `ADVERSE EVENTS NO. MILD | ADVERSE EVENTS NO. SEVERE` → `ICRAdverseEvent` (seriousness `non-serious`/`serious`), but as aggregate counts (§4.8 rule: counts stay on the QR/tally, not minted per-person).
- `SUMMARY` sheet per-drug `Tab Recd | Tabs Distd | Tabs missing | Tabs Remaining` → stockAccountability; `Minor Cases | Cases refd to H/C` → morbidity (out-of-scope).

**Gaps:**
- **Delivery-site typology village / church / school** (sheet name `VILLAGE_CHURCH_SCHOOL_TREATMENT`) — the register is explicitly disaggregated by delivery-site *type*. `ICRLocationTypeCS` has `school`, `community-distribution-point`, `settlement` — but **no `church`/`religious-site`** and no `mosque`. This is a real coverage-disaggregation axis (treated-at-village vs treated-at-church vs treated-at-school), not just a place. New terminology (see below).
- **`Tabs missing`** — the lost/missing stock bucket (as in RESUMO). Confirms the stock-disposition gap.
- Per-disease **`Oncho COV | LF COV | SCH COV | STH COV`** computed inline — fine, these are MeasureReport scores; noted only that a single register row yields *four* disease-specific coverage measures (multi-disease integrated round).

**Terminology / valueset additions:**
- **Add `religious-site` (and/or `church`, `mosque`) and `market` to `ICRLocationTypeCS`** as delivery-site types — recurs in TCC ODK (`religsitename`) and EDO distribution (church/school delivery). Verbatim: `church`, `school`, `village`.
- Confirm `ICRExclusionReasonCS` covers `UNDERAGE (< 5yrs)` — note that here under-age means age <5, whereas the CS code is `under-height-age` (dose-pole height). MDA uses **both** an age floor (<5 yrs) *and* a height floor (dose pole); consider distinguishing `under-age` from `under-height`.

---

### VVFF REGION DE N'Zérékoré RESULTAT CAMPAGNE MTN 19-07-2024 (headers only)_blank.xlsx — TSDC/CDTI data-entry mask with 4-level roll-up (Guinea, French)

**What it collects:** A community-directed treatment (`TSDC` = Traitement Sous Directives Communautaires) data-entry workbook for NTDs (`MTN-CTP`), with a village-level capture sheet (`Saisie des données`) and auto-computed synthesis sheets that roll village → health-centre → district → region (`Synthèse Village/CS/District/Région`). `PARAMETRES` holds the treatment-type and year pick-lists; `INSTRUCTIONS` documents the data-flow and validation workflow.

**Fit:**
- Section 1 admin `IRSHP | DPS | CS | Nom Communauté/Village` → `ICRLocation` hierarchy (`DPS` = health district, `CS` = health centre).
- Section 2 `DENOMBREMENT`: `Nbre de ménages | <5ans | 5-14 ans | 15 et + | Nbre d'Hommes | Nbre de Femmes | Pop. Totale` → `ICRTargetPopulation` (households + age band + sex).
- Section 3 `PERSONNES TRAITEES` by sex×age (`Hommes/Femmes × 5-14 ans / 15 ans et +`) + `COUVERTURE %` → `ICRAdministrativeCoverage` cube.
- Section 3 `PERSONNES NON TRAITEES`: `Enfants de moins de 5 ans | Femmes allaitantes < 7 jours | Femmes enceintes | Malades grabataires | Absents | Refus` → exclusion/missed/noncompliance CS (see terminology — `Malades grabataires`, lactating<7days).
- Section 5 drug ledgers per MECTIZAN/ALBENDAZOLE/PRAZIQUANTEL: `Reçus | Utilisés | Perdus | Restants | Conso. moyenne | Rendus au CS/DPS` → `ICRSupplyDelivery` stockAccountability.
- The four `Synthèse` roll-up sheets are exactly the admin→operational geographic-coverage aggregation ICR models via `ICRLocation.partOf` + `icr-geographic-coverage` (`Total Villages Traités`, `Couv. Géographique`).
- `PARAMETRES` `Type de Traitement` list → campaign disease-scope (`ICRNTDDiseaseCS`).

**Gaps:**
- **`Couv. Epidémiologique ONCHO/SCH` vs `Couv. Programmatique GEO` vs `Couv. Géographique`** — three coverage denominators in one form (epidemiological/total-pop, programmatic/eligible-target, geographic/IU). Same UTG/therapeutic-coverage denominator gap as RESUMO — the eligible-target (programmatic) denominator is not first-class in `ICRDenominatorTypeCS`.
- **`Perdus` (lost) and `Rendus au CS/DPS` (returned up a level)** — `Rendus` = returned-to-supplier maps to stockAccountability `returned`, but `Perdus` (lost/missing) again has no bucket. Also `Conso. moyenne` (average consumption = tablets per person treated) is a derived wastage/dosing metric — relates to roadmap `doses-per-vial`/wastage Measure.
- **`Type de Traitement` co-endemic combinations** — `Oncho | Oncho+FL+SCH+GeoH | Oncho+FL+SCH | Oncho+SCH+GeoH | Oncho+SCH | SCH+GeoH | Oncho+GeoH | Oncho+FL` (`GeoH` = geohelminths/STH). A campaign's disease scope is a *combination*, not a single disease. `ICRNTDDiseaseCS` has single codes — this is representable as multiple codes, but the form shows co-endemic treatment **packages** are the real unit; worth documenting the pattern (and `GeoH` as an alias for `sth`).
- `Complications MTN-CTP: Hydrocèle | Elephantiasis | Trichiasis (TT)` — morbidity, out-of-scope.
- **In-built data-quality/validation workflow** (INSTRUCTIONS: DPS data manager validates by village and CS, feedback loop to CS during distribution). This concordance/QA-during-campaign is an operational process ICR doesn't model beyond `ICRSupervisionReport` — reference only.

**Terminology / valueset additions:**
- `Malades grabataires` (bedridden/gravely-ill persons) — an exclusion reason distinct from `acute-illness`. Add `bedridden`/`severely-ill` to `ICRExclusionReasonCS` (recurs as `personnes_gravement_malades` in Liberia CommCare).
- `Femmes allaitantes < 7 jours` (lactating, baby <7 days) — a **more specific** breastfeeding exclusion than ICR's generic `breastfeeding`; note the <7-day qualifier (ivermectin contraindication). Recurs verbatim across the CommCare forms.
- French gloss for `ICRMissedReasonCS`/`ICRNoncomplianceReasonCS`: `Absents`=absent, `Refus`=refusal.
- Document `GeoH`/`geohelminths` ↔ `sth`; multilingual medicine names MECTIZAN=ivermectin, ALBENDAZOLE, PRAZIQUANTEL.

---

### MDA Supervision 2023_2024_blank.xlsx — integrated MDA+polio supervision responses (Nigeria, "riverblindnessnigeria", English)

**What it collects:** A single flat response table (`riverblindnessnigeria-responses`, 64 columns) — a digital supervision instrument capturing supervisor observations at a site: CDD details, drug sufficiency/refusals/SAEs, GPS of both site and supervision point, five "key questions", and — notably — **polio integration** fields.

**Fit:**
- `GroupName | GroupLevel | selectonelga:Region | selectonelga:LGA | healthfac | VillageName` → `ICRLocation` + supervisory hierarchy; `GroupLevel` = supervisor tier.
- `location:Latitude/Longitude/Altitude/Accuracy` and `supervisionlocation:*` → two `ICRLocation.position` points (site vs where supervisor stood).
- Supervision items → `ICRSupervisionReport` (`icr-mda-supervision-checklist`): `mdamedsenough`, `mdarefusalyn`, `mdasaeyn`, `correctfinger` (finger-marking check → `fingerMarked`), `cddtrainyn`, `teampresent`, `supervisiontraincdti` (CDTI training), `numcdds`, `mdahhs/mdahhsremaining/mdahhtreated` (household spot-check).
- `supervisor | supervisoragency | supervisorrole2 | sitesupervisor | supervisorhhnum` → `ICRCareTeam` roles.
- Stock: `medsoffered`, drug counts → SupplyDelivery/MedicationAdministration.

**Gaps:**
- **`poliovaxstage` and `icepackcondition`** — this "river blindness" MDA supervision form *also* checks polio vaccination stage and **cold-chain ice-pack condition**. Evidence of a genuinely **integrated NTD+polio+EPI** supervision visit. ICR treats cold-chain via the readiness checklist and SupplyDelivery only; a *supervision-time* cold-chain check (`icepackcondition`) is not in `icr-mda-supervision-checklist`. Reinforces roadmap "cold-chain/logistics axis beyond readiness checklist."
- **`supervisorkeyq1…supervisorkeyq5`** — five generic "key question" slots, plus `dipuse` — an escalation/scoring pattern (see CommCare `maj_iss_*` below); the supervision checklist has no scored key-question or major-issue-flag layer.
- **`villagetype2 | villagetypespecial`** — settlement-type classification embedded in supervision → `ICRSettlementTypeCS` (extensible); `villagetypespecial` (special populations) likely adds codes beyond the 11 present.
- `mdahhs | mdahhtreated | mdahhsremaining` + `supervisorhhnum` — the **supervisor's household spot-audit** (checked N households, X treated). Not full administrative coverage and not RCM — a supervision-embedded coverage verification with no clean ICR home (see CommCare/TCC below; recurring pattern).

**Terminology / valueset additions:**
- `ICRTeamRoleCS` additions for NTD supervision hierarchy (see CommCare/TCC): the CS has `supervisor` only — needs supervisor *level/agency* distinction.
- Add a supervision-time `cold-chain`/`ice-pack-condition` checklist item and a `polio-vaccination-stage` item if integrated-campaign supervision is in scope (or document as out-of-scope integrated-programme reference).

---

### Kogi MDA Supervision Data with GPS_blank.xlsx — CommCare supervisory-site export w/ GPS (Nigeria, Kogi State)

**What it collects:** A CommCare case export: a display sheet (`Kogi MDA Supervision`) and `Raw Data`. Each record is a supervisory **site** case with GPS and the admin cascade (state/LGA/ward/HF/community), case metadata (owner, opened/closed, case_type).

**Fit:**
- `community_name | Health Facility_code/name | LGA_name | State_name | Ward_name` → `ICRLocation` hierarchy with `identifier` (HF code).
- `Latitude | Longitude | Altitude | Accuracy` / `community_location_gps` → `ICRLocation.position`.
- `Case_type | data_type | caseid` → the CommCare case-management scaffolding; `caseid` → `ICRLocation.identifier` (registry ID) for the supervisory site. This is the parent "site" case that the Sightsavers checklist children attach to.

**Gaps:**
- Almost entirely CommCare case-plumbing (`owner_id`, `closed_by_username`, `server_last_modified_date`, `external_id`) — infrastructural, no ICR modeling need. Confirms the **site-case / checklist-case parent-child pattern** that ICR must flatten: a `supervisory_site` case (this file) is `for`/`overseesArea` of one or more supervision `QuestionnaireResponse`s (the Sightsavers checklist files). Worth noting the transform must join child checklist cases to their parent site case (`indices.parent.case_id`).

**Terminology / valueset additions:**
- None new. `Health Facility_code` reinforces the need for facility `identifier` slicing (national/pcode) already in `ICRLocation`.

---

### Liberia - Supervision sites_2024_blank.xlsx — supervision-site master list w/ GPS (Liberia)

**What it collects:** A flat site list: `site_name | gps_lat | gps_long | gps_alt | gps_acc | subdistrict_name | district_name | region_name | supervisor ID | date supervision visit`.

**Fit:**
- Admin `region/district/subdistrict/site` → `ICRLocation.partOf`; GPS → `position`.
- `supervisor ID` → `ICRCareTeam` participant reference; `date supervision visit` → `ICRSupervisionReport.authored`.

**Gaps:**
- Thin; a site register, not an instrument. Confirms the **subdistrict** tier (Liberia clan/subdistrict) sits between district and settlement — `ICRLocation.partOf` handles it. No new gap.

**Terminology / valueset additions:**
- None.

---

### Sightsavers Guinea-Bissau CommCare Supervision_anonymized.xlsx — live digital MDA supervision checklist (Guinea-Bissau, Portuguese)

**What it collects:** A REAL CommCare instrument (2,632 site cases, 1,404 checklist cases; `domain: dmdi-guinea-bissau`). Parent `supervisory_site` cases (admin cascade + GPS + `currently_at_site`) with child `supervisory_checklist` cases carrying ~130 supervision items: drug accountability, dose-pole checks, training, register/tally QA, missed-persons handling, side-effects, population census, and a **major-issue flag + major-action** escalation layer. This is exactly the tool Crosscut ingests via CommCare→ODK→FHIR.

**Fit (to `ICRSupervisionReport` / `icr-mda-supervision-checklist`):**
- **Dose pole:** `does_pole_properly_calibrated`, `dose_poles`, `dd_know_how_to_use_dose_poles` → checklist "height chart used correctly" (partial — calibration is new).
- **DOC/eligibility:** `everyone_receiving_the_drug`, `give_drugs_to_missed_persons`, `without_skipping_houses`, `not_eligible_ivm` (multi-select, see terminology).
- **Stock (inline, supervision-time):** `ivm_received | ivm_distributed | ivm_wasted`, `alb_received | alb_distributed | alb_wasted`, `ivm_sufficient`, `drug_remaining_ivm/alb`, `drugs_being_stored_in_a_safe_place`, `location_drug_storage`, `expiry_date` → `ICRSupplyDelivery` stockAccountability, but captured *within* the supervision QR.
- **Social-mob/rumors:** `any_negative_rumors` → checklist social-mobilization section.
- **Team/training:** `dd_trained`, `number_drug_distributors`, `last_training_date`, `supervisor_designation`, `supervision_number`, `supervision_date`.
- **Safe water:** `safe_water_available` (needed to swallow tablets).
- **Census:** `census_updated`, `premda_census_population_updated`, `period_update_population`, `last_premda_census_date`.

**Gaps (items with NO clean `icr-mda-supervision-checklist` home — the checklist ships only supplies/CDD-observation/stock/social-mob sections):**
- **Register & tally-sheet data-quality items:** `treatment_tally_sheet_available`, `treatment_tally_sheet_correct`, `register_correctly_filled`, `inventories_correctly_filled`, `recording_missed_persons_cases`, `why_not_recording`, `daily_movement_map`, `daily_time_sheet`. A whole **records/data-quality** section is missing from the canonical checklist.
- **Major-issue escalation layer:** `maj_iss_drug_distrib`, `maj_iss_drug_rcvd`, `maj_iss_drug_suffic`, `maj_iss_grp_missed`, `maj_iss_tally_sheet_available`, `maj_iss_sae_rprtd`, `add_a_major_action_2..5`, `major_action_1..5`, `date_ma`, `action_to_resolve_drug_distribution_on_track`, `details_retrain_replace`. This is a structured **finding→severity→corrective-action** model (each checklist domain can be flagged a "major issue" and generate a dated action). ICR's `ICRSupervisionReport` is a flat answer set with **no action/finding-severity model**. Genuinely new and important — supervision without action-tracking loses the point of supervision.
- **Side-effects sub-module:** `complain_side_effects`, `side_effects_type` (coded), `other_side_effects_type`, `solution_to_help_address_side_effects`, `drug_reactions_reported` — aggregate AE observed during supervision; per §4.8 these stay on the QR (can't mint per-person `ICRAdverseEvent`), but the **coded `side_effects_type` answer list** has no ICR vocabulary.
- **`group_being_missed_absent_refused` + `_specify` + `everyone_not_received_the_drugs`** (free-text reason) — reason-for-missing captured as a checklist observation (distinct from Task-level missed-reason).

**Terminology / valueset additions:**
- **`not_eligible_ivm` answer list (verbatim, pt):** `mulheres_gravidas` (pregnant), `mulheres_que_amamentam_com_bebês_menos_de_7_dias` (lactating, baby <7 days), `criancas_com_menos_de_90_cm_de_altura` (children <90 cm height). → binds to `ICRExclusionReasonCS` (`pregnant`, `breastfeeding`, `under-height-age`); confirms the **<90 cm** height floor and **<7-day** lactation qualifier as concrete extensible codes.
- **`side_effects_type`** coded list (values `1`..`15`; free-text examples `diarreia`) — propose an MDA adverse-reaction symptom valueset (or bind to an external AE terminology); currently unmodeled.
- **A supervision finding-severity code** (`major-issue` / `minor` / `ok`) and an **action/corrective-action** structure — new, for the escalation layer.
- **Drug-storage / collection location** coded lists (`location_drug_storage`, `location_drug_collection` integers) — storage-point typology.

---

### Sightsavers Liberia CommCare Supervision_anonymized.xlsx — live digital MDA supervision checklist (Liberia, French/English)

**What it collects:** Same CommCare architecture (`domain: mda-supervision`, 1,238 sites / 1,188 checklists, `case_type: supervisory_site_lr`), tuned for Liberia. Adds explicit **eligibility-by-drug**, **motivation/incentive**, and **refusal-reason** structure the GB form lacks.

**Fit:** As Guinea-Bissau — dose-pole (`dose_pole`, `dose_pole_calibrated`, `dose_pole_usage`), stock (`ivm_received/distributed/wasted`, `alb_cmp_received/distributed/wasted`), training (`num_cdd_trained`, `num_distributors`, `last_training_date`), records QA (`drug_sheets_correct_completed`, `entrees_correctes`, `registre_comm_existant_ov_lf`), census (`premda_census`, `total_population`, `know_total_population`, `update_pop_data`), safe water (`safe_water_available`), SAE (`severe_adverse_events_reported`, `drug_reactions_reported`, `num_drug_reactions_reported`) → `ICRSupervisionReport` + SupplyDelivery.

**Gaps (beyond those shared with GB):**
- **Eligibility & treated-population *by drug*:** `pop_treated_ivm` (`5_ans_et_plus` = 5 yrs+), `pop_treated_alb` (`5_14_ans` = 5–14 yrs), `not_eligible_ivm` (French coded list). The **age-eligibility band differs per medicine** (ivermectin 5+, albendazole 5–14) — ICR captures age bands on `ICRTargetPopulation`/coverage stratifiers but not a **per-medicine eligibility rule** (which population a given drug targets). Relates to roadmap `dosing-regimen`; the *eligible-age-band-per-product* is a modeling gap on `ICRCampaignActivity`/`ICRCampaignProtocol`.
- **Motivation/incentive:** `received_motivation`, `motivation_type`, `dc_remp_recycl` (distributor replaced/recycled), `details_retrain_replace` — CDD **incentive and turnover** tracking. No ICR home (`ICRCareTeam` has no incentive/attrition fields). New.
- **Refusal reasons coded:** `reasons_for_refusal` (coded, values e.g. `4`), `others_reasons_for_refusal` (free text, e.g. "the medication is not good"), `persons_refused`, `why_not_recording`. → `ICRNoncomplianceReasonCS` (extensible) — but the form's coded list may extend it; capture the codes.
- **`difficulties_encountered` + `_details`** (e.g. "Hard to reach, bad road condition"), `details_return_hh` ("CDDs visited more than one time") — access-difficulty and revisit observations; access maps loosely to `ICRMissedReasonCS` `difficult-access`/`inaccessible`.
- Major-issue escalation layer present here too (`maj_iss_ivm_*`, `maj_iss_alb_*`, `maj_iss_grp_missed`, `maj_iss_reg_com_exst_ov_lf`) — same finding-severity gap as GB.

**Terminology / valueset additions:**
- **`not_eligible_ivm` (verbatim, fr):** `femmes_enceintes` (pregnant), `femmes_allaitantes_bb_moins_7_jrs` (lactating <7 days), `personnes_gravement_malades` (severely ill/bedridden), `enfants_de_moins_de_5_ans` (children <5 yrs), `enfants_qui_une_taille_infreure_90_cm` (children <90 cm). → `ICRExclusionReasonCS`: confirms **both** `under-age` (<5 yrs) **and** `under-height` (<90 cm) as *distinct* codes, plus `severely-ill`/`bedridden` (= `Malades grabataires` fr). Strong multilingual evidence to split `under-height-age` into two codes.
- **`pop_treated_ivm`/`pop_treated_alb` eligibility bands** (`5_ans_et_plus`, `5_14_ans`) — a per-product age-eligibility vocabulary.
- **`motivation_type`** and a **distributor-turnover** (`replaced`/`recycled`/`retrained`) vocabulary — new for `ICRCareTeam`.
- `reasons_for_refusal` coded list → extend/confirm `ICRNoncomplianceReasonCS`.

---

### Sightsavers Nigeria CommCare Supervision_anonymized.xlsx — live digital MDA supervision checklist, largest dataset (Nigeria, English)

**What it collects:** Same CommCare architecture (`domain: nigeria-1`, 9,728 site / 9,327 checklist records, `case_type: supervisory_site_nga`), the biggest instrument. Site case adds `site_type` (`community`) and a two-value `data_type`. Checklist mirrors Liberia plus a distributor-action code and richer endemicity.

**Fit:** As Liberia/GB. Notable: `endemicity` has **14 distinct values** (co-endemic combinations — cf. VVFF `Type de Traitement`), `treatment_register_available`, `correct_entries`, `source_drinking_water`, `collect_drug_location` (coded, up to `9`), `storage_drug_location`, `ivm_remain` (explicit remaining), `trained_this_year`. Maps to `ICRSupervisionReport` + SupplyDelivery + `ICRNTDDiseaseCS`.

**Gaps (beyond shared CommCare gaps):**
- **`endemicity` = co-endemic combinations (14 distinct)** — confirms the disease-scope-as-combination pattern; each supervision record's endemicity is a *set* of `ICRNTDDiseaseCS` codes. ICR should document endemicity as a multi-code axis (on `ICRCampaign`/`ICRLocation`).
- **`cdd_action` (coded)** and `others_reasons_for_refusal` (e.g. "Belief or traditionalist"), `reasons_for_refusal` — the distributor-corrective-action + refusal-reason vocabularies (as Liberia). "Belief or traditionalist" → `ICRNoncomplianceReasonCS` `religious-objection`.
- **`other_location_drug_collect`: "WARD FOCAL PERSON"** — a drug-collection-point/role type (ward focal person) — relates to `ICRTeamRoleCS` gap.
- **`collect_drug_location` / `storage_drug_location` coded (1–9)** — a drug-logistics location typology (health facility / ward store / distribution point / focal-person) with no ICR vocabulary.
- Major-issue escalation layer again (`maj_iss_ivm_*`, `maj_iss_treatment_register_available`, `maj_iss_sae_rprtd`) + `comments_actions_*` free-text per domain — same finding/action gap.

**Terminology / valueset additions:**
- `ICRTeamRoleCS` — add NTD roles seen across forms: `lga-ntd-coordinator` (`supervisor_designation: "LGA NTDs Coordinator"`), `ward-focal-person`, `health-facility-focal-person`. Current CS has only generic `supervisor`.
- `endemicity` co-endemic combination handling (multi-`ICRNTDDiseaseCS`).
- `cdd_action` / distributor corrective-action coded list.
- Confirm `others_reasons_for_refusal: "Belief or traditionalist"` → `ICRNoncomplianceReasonCS` `religious-objection`/`misinformation`.

---

### TCC Nigeria ODK Supervision_anonymized.xlsx — live ODK Central supervision instrument w/ migrant module & per-CDD roster (Nigeria, The Carter Center, English)

**What it collects:** A REAL ODK Central form (4,533 submissions, `formVersion 202605140816`), structured into nested groups: `Supervisor`, `Site_Supervision`, `sitelocation` (GeoJSON Point), `Community_Info`, `Alternate_MDA_Location`, `MDA_Info` (incl. a full **migrant-population** sub-module), and a repeating `CDD_Info.CDD[]` roster with per-distributor performance. The richest supervisor/agency and delivery-site modeling in the set.

**Fit:**
- `Supervisor.supervisor/contactinfo`, `Site_Supervision.sitesupervisor`, `supervisoragency` (`The_Carter_Center`, `UNICEF`; 11 distinct), `supervisorrole` (`Partner-TCC`; 11 distinct), `healthprogsupervise` (`Onchocerciasis_river_blindness`; 13 distinct) → `ICRCareTeam` participants + roles + `overseesArea`.
- `sitelocation` + `Community_Info.healthfacilitylocation` as **GeoJSON `Point`** → `ICRLocation.position` / boundary extension (native GeoJSON, matches ICR's GeoJSON boundary approach).
- `State | LGA | Community_Info.VillageName | healthfac` → `ICRLocation` hierarchy.
- `MDA_Info.medsoffered` (IVM…), `mdaround` (`Round_1`/`Round_2`) → `ICRCampaign.campaignRound`; `mdastart/mdaend` → period.
- `CDD_Info.CDD[]` roster: `cddname`, `cddphonenum`, `mdahhs`, `mdahhsremaining`, `cddtrainyn`, `mdamedsenough`, `mdarefusalyn`, `mdasaeyn`, `supportgivenmdayn`, `cddreportsubmit` → `ICRCareTeam.participant` per CDD.
- `supervisorhhnum`, `mdahhtreated`, `mdahhmemtreated`, `mdahhmemtotal` → household spot-audit.

**Gaps:**
- **Migrant-population sub-module** — `MigrantPop` (present y/n), `MigrantOcc` (occupation — `Farming`, `Timber`…), `MigrantFromState`/`MigrantNotFromState` (origin), `MigrantDur` (`Less_than_6_months`…), `MigrantFreq` (frequency of movement), `MigrantComp` (counted in census?), `MigrantTreat` (treated?), `MigrantTreatOrigin` (treated at origin?). This is a **whole mobile/migrant-population tracking module with NO ICR home.** `ICRSettlementTypeCS` has `nomad-pastoralist`, `immigrant`, `cross-border` as *place* types, but the migrant **data** (occupation, origin, duration, movement frequency, treated-at-origin) is unmodeled. Epidemiologically critical for oncho (mobile farmers near rivers) and cross-border coverage. Genuinely new — the single biggest new modeling area these forms expose.
- **Per-CDD performance & workload in a roster:** `CDD_Info.CDD[]` carries per-distributor households-assigned (`mdahhs`) / remaining (`mdahhsremaining`) and per-CDD flags (trained, meds-enough, refusals, SAE, support-given, report-submitted). ICR's `ICRCareTeam.workloadTarget` is **per-team, not per-participant**; there is no place for **per-member household assignment or per-member performance**. New gap (recurs as `numcdds`+per-CDD in the MDA 2023 form).
- **Delivery-site typology:** `Alternate_MDA_Location.schoolname` + `religsitename` — the MDA happened at a **school or religious site** (not the village). Confirms the `ICRLocationTypeCS` `religious-site`/`school` delivery-site gap (see VILLAGE_CHURCH_SCHOOL). `Community_Info.villagetype` (`Rural`/`Urban`, 3 distinct) → `ICRSettlementTypeCS`; `villagetypespecial` (**19 distinct** + `villagetypespecialoth`) → very likely **extends `ICRSettlementTypeCS` beyond its 11 codes** (special-population typology).
- **`mdacomplaintdetail` coded** (`Many_absentees`; free-text `Itching`) — complaint/issue typology, unmodeled.
- **Household spot-audit** `supervisorhhnum` / `mdahhtreated` / `mdahhmemtreated` / `mdahhmemtotal` — a supervision-embedded coverage-verification sample (checked 40 HHs; 12 of 33 members treated). Not administrative coverage, not a formal survey/LQAS/RCM MeasureReport — no clean ICR home. Recurs in MDA 2023 & CommCare forms; worth a decision (supervision-time verification vs RCM).

**Terminology / valueset additions:**
- **New migrant/mobile-population axis** — codes for occupation (`Farming`, `Timber`, …), duration (`Less_than_6_months`, …), movement frequency, and status flags (`counted-in-census`, `treated`, `treated-at-origin`). No existing ICR CS covers this; either a new `ICRMigrantPopulation`* module or route to settlement-type + a mobility extension.
- **`ICRSettlementTypeCS` expansion** — `villagetypespecial` has 19 distinct values (only `NA`/`Not hard` visible in the sample); harvest the full list to extend the 11-code CS (HTRA/special-population targeting axis).
- **`ICRLocationTypeCS`** — add `religious-site`/`church`, `school` delivery-site (confirmed by `religsitename`/`schoolname`).
- **`ICRTeamRoleCS` / supervisor-agency** — `supervisoragency` (11 distinct: `The_Carter_Center`, `UNICEF`, …) and `supervisorrole` (11: `Partner-TCC`, …) argue for a partner-organization identifier on `ICRCareTeam` and NTD supervisor-role codes (partner-supervisor, LGA/ward/facility levels).
- `mdaround` (`Round_1`/`Round_2`) — confirms `ICRCampaign.campaignRound`.

### Cross-cutting findings — NTD

- **Forward drug quantification/forecasting is the top NTD gap, confirmed on every microplan.** Benin (`Besoins requis − restants + Ratio Personnes/Ivermectine 2.5 + Taux de stock de sécurité 0.01`), Burundi (`Besoins éstimés → en stock → Besoins Réels → conditionnés en boîtes de 500 → approvisionnés`), Senegal/Madagascar/Kogi all run the same `need = target ÷ tablets-per-person − carryover + buffer → round to pack-size` chain. ICR has no requisition/forecast object and no pack-size (`boîte de 500`) unit — this is the NTD instance of Synthesis gap #1 and strengthens the roadmap GS1/pack-size item.

- **The eligible-target (UTG) denominator and NTD coverage thresholds are not first-class.** `UTG` (Nigeria/Edo), `Population cible ×82.36%`/`×28.83%` (Benin/Senegal), `OAT` (Burundi), and the recurring **65% / 80%** therapeutic-coverage thresholds (`CT ≥ 65%`, Guinea-Bissau/Guinea) show NTD reports coverage against an eligible target with a stored programme threshold — neither is expressible in `ICRDenominatorTypeCS` (`total-population | at-risk`) or the coverage profiles today. Add an `ultimate-treatment-goal`/`eligible-target` denominator type + eligibility-fraction slot; strengthens the roadmap `coverage-target` quartet item.

- **Multilingual terminology is unavoidable in NTD** (EN/FR/PT in one corpus). A ConceptMap must cover: diseases (`GEO`/`géohelminthiase`/`GeoH`=sth; `BIL`/`bilharziose`/`SCHISTO`=schisto; `RB`/river-blindness=oncho); coverage (`Cobertura Terapêutica`/`Couv. Thérapeutique`; `Cobertura Geográfica`/`Couv. Géographique`); missed/exclusion reasons (`Ausente/Recusa/Doente/Gravida/Aleitando<7dias/Crianças0-59m` PT; `Absents/Refus/Malades grabataires/Femmes allaitantes<7jrs/enfants<5ans/<90cm` FR); admin/settlement units (`Fokontany`, `Colline`, `Tabanca`, `Bairro`, `Arrondissement`, `Clan`, `Daara`, `Aire de Santé`/`Área Sanitária`); drugs (`Mectizan`/`IVERECTINA`=ivermectin, `ALBENDAZOLE`, `PRAZIQUANTEL`, `MEBENDAZOLE`). Concrete demand for the roadmap ConceptMap mechanism.

- **The live CommCare/ODK supervision instruments define the supervision-model gap.** Across the three Sightsavers CommCare forms and TCC's ODK form, `icr-mda-supervision-checklist` is missing (a) a **records/data-quality** section (`treatment_tally_sheet_correct`, `register_correctly_filled`, `recording_missed_persons_cases`), (b) a **finding→severity→corrective-action** escalation layer (`maj_iss_*` + dated `major_action_1..5`), and (c) **per-CDD roster** performance/workload (`CDD_Info.CDD[]`; `ICRCareTeam.workloadTarget` is per-team only). Plus a coded **side-effects** answer list, **CDD incentive/turnover** (`received_motivation`, `dc_remp_recycl`), and a **supervision-embedded household spot-audit** (`supervisorhhnum`/`mdahhtreated`) that is neither administrative coverage nor formal RCM/LQAS — worth an explicit modeling decision.

- **Delivery-site & location typology needs NTD-specific additions.** Add `religious-site`/`church` and `market` to `ICRLocationTypeCS` (the VILLAGE/CHURCH/SCHOOL register and TCC `religsitename`/`schoolname` make delivery-site a coverage-disaggregation axis); add `health-facility-catchment` (FLHF / Aire de Santé / Área Sanitária — the smallest MDA reporting unit, all three languages), `clan`, `hamlet`/`Hameau`, and `daara` (Quranic school). Terrain and security-accessibility recur as **separate** axes from settlement-type (Kogi `Settlement Terrain` + `Settlement Security Accessibility`).

- **TCC's migrant/mobile-population module is the single biggest genuinely-new NTD data domain** — occupation, origin state, duration, movement frequency, counted-in-census, treated, treated-at-origin — epidemiologically critical for oncho and cross-border coverage, with no ICR home (settlement-type codes cover the *place*, not the mobility *data*).

- **Stock dispositions, exclusion reasons, and disease-scope need refinement.** Add `lost/missing` and `expired` to stock accountability (`perdidos`/`espirado`/`Perdus`/`Tabs missing`). Split `ICRExclusionReasonCS` `under-height-age` into `under-age` (<5 yrs) and `under-height` (<90 cm) and add `bedridden`/`severely-ill` — the `not_eligible_ivm` coded lists (PT + FR) carry all of these distinctly, with a breastfeeding **<7-day** ivermectin qualifier. Disease scope is a **co-endemic combination** (VVFF `Type de Traitement` 8 combos; Nigeria CommCare `endemicity` 14 values) — document endemicity as a multi-`ICRNTDDiseaseCS` axis on `ICRCampaign`/`ICRLocation`.

- **Community-registry completeness is a recurring NTD instrument.** The Liberia GC03 geographic-coverage surveys reconcile the official `MOH/APOC list` against ground truth (on-list vs found vs treated, with a 2006–2012 treated matrix) — a data-quality/geographic-coverage flavor with no first-class Location listing-status concept and no on-list/off-list coverage stratifier. CDD **sex composition** (Male/Female CDD) recurs here and elsewhere.

- **Out-of-scope co-bundling is prominent and confirmed.** `Données_evaluations_oncho` (pure entomology/serology/CMFL), Guinea-Bissau/RESUMO (LF morbidity: hydrocele, lymphedema, elephantiasis, trichiasis surgery), and Senegal (schisto transmission ponds) all co-bundle surveillance/MMDP onto treatment sheets. ICR correctly treats these as "reference, don't model" — but the transform must reliably route them to a surveillance/morbidity store while preserving program-round metadata (number of PC rounds, treatment strategy) as referenceable ICR context. Also relates to the open "vector control / entomological surveillance" scope decision.

* * *

*This is a working analysis document following the ICR working-doc convention (versioned, timestamped). It records findings for IG design consideration; the IG source (`ig/input/fsh/`) and `project/icr-ig.md` remain authoritative. Form-header quotations are verbatim from the contributed templates in `forms/crosscut/`.*
