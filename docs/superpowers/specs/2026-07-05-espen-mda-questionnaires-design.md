# ESPEN MDA forms → FHIR Questionnaires with template-based extraction

**Date:** 2026-07-05 · **Status:** Approved by Matt · **Round tag:** `espen-forms`
**Amended:** 2026-07-07 (`espen-remap` round, approved by Matt) — see
*Adapted mapping* below; the Form 3/4 rows in the extraction table are superseded.

## Goal

Convert the six ESPEN MDA XLSForms in `forms/espen mda/` into FHIR R4 Questionnaires,
carrying SDC **template-based extraction** (`templateExtract`) so a filled
QuestionnaireResponse extracts into the proper ICR-profiled resources. Ship them in the
IG's **examples section**, where the Topcoat renderer now previews questionnaires.
Matt confirmed templateExtract is the mechanism their code supports.

## Decisions (made with Matt)

1. **Coexist, don't replace.** The canonical condensed `icr-mda-supervision-checklist`
   and `icr-campaign-readiness-checklist` stay untouched as the IG's normative
   instruments. The six ESPEN conversions ship alongside as complete, source-faithful
   example instruments (`espen-mda-*`), demonstrating the "countries extend" story.
2. **Faithful structure, ICR codes.** Item structure, groups, skip logic
   (`relevant` → `enableWhen`), and constraints follow the XLSForm 1:1. Answer lists
   bind to existing ICR terminology where it overlaps; only genuinely reusable new
   vocabulary is minted (see Terminology).
3. **templateExtract confirmed** — supported by project code; no fallback to
   definition-based extraction.

## Artifacts

New file `ig/input/fsh/questionnaires-espen.fsh` with six `Instance ... InstanceOf:
Questionnaire`, `Usage: #example` (places them in the examples section / preview),
canonical `url` under `https://fhir.icr.unicef.org/Questionnaire/`:

| Instance id | Source XLSForm | Content |
|---|---|---|
| `espen-mda-location-registration` | `demo_mda_9999_1_location.xlsx` | Admin cascade, village population by age band (total / 1–4 / 5–14 / 15+), eligible-pop calculate, GPS |
| `espen-mda-drug-receipt` | `demo_mda_9999_2_part.xlsx` | Disease + medicine package selects; per-medicine received totals (PZQ, ALB, MEB, IVM, DEC, AZM susp/tab, TETRA) |
| `espen-mda-treatment` | `demo_mda_9999_3_med_treatment.xlsx` | Core treatment tally: census group + 8 per-drug blocks (treated by sex × age band, calculates, reasons-not-treated counts), drug blocks gated by the medicine-package answer |
| `espen-mda-case-management` | `demo_mda_9999_4_case_mngnt.xlsx` | Distributed totals per drug, minor/serious side-effect counts, other-NTD case counts (guinea worm, leish, Buruli, LF lymphoedema/hydrocele) |
| `espen-mda-supervision-hf` | `demo_mda_9999_5_supervision_hf.xlsx` | Full ESPEN Form 5: geographic coverage, per-drug stock triplets (remain / expired / concordance), training, social mobilization, supervision area, pharmacovigilance, free-text challenges |
| `espen-mda-supervision-cdd` | `demo_mda_9999_6_supervision_CDD.xlsx` | Full ESPEN Form 6: CDD observation supervision |

### Conversion rules (XLSForm → Questionnaire)

- `begin group`/`end group` → `item.type = #group`; group labels preserved.
- `select_one` / `select_multiple` → `choice` items (+ `repeats` via
  `sdc`-standard handling: select_multiple → `answerConstraint`-free R4 idiom =
  `type #choice` + `extension[questionnaire-itemControl]` where needed; multiplicity
  via `repeats = true`).
- `select_one yes_no` → `#boolean`.
- `relevant` → `enableWhen` (translate the XPath conditions; where a condition is not
  representable as enableWhen, use `sdc-questionnaire-enableWhenExpression`).
- `calculate` → `sdc-questionnaire-calculatedExpression` (FHIRPath), item hidden.
- `constraint`/`constraint_message` → `sdc-questionnaire-constraint` extension when
  simple; drop with a code comment when device-specific.
- `required` → `required = true`.
- XLSForm plumbing (`start`, `end`, device `recorder_id` lists, `bind::db_*`
  Ona-entity columns) → dropped or converted to hidden items; the `bind::db_*`
  entity semantics are *replaced by* the FHIR extraction templates (that's the point).
- Labels/hints: `label::English` → `text`, `hint::English` →
  `entryFormat`/`item.item display` per SDC idiom (hint → `questionnaire-displayCategory`
  or simply appended; keep simple: hints become item `text` sub-display items only when
  they carry real instruction).

## Terminology

- **Reuse:** `ICRCommunicationChannelVS` (Form 5 `channel_com` list — map labels to the
  existing 18 codes, extensible for stragglers). Reasons-not-treated in Forms 3/5 are
  **integer count items**, not selects — their ICR alignment happens at extraction
  (they populate the `disposition` stratifier), not via ValueSet binding.
- **Mint (in `codesystems.fsh`/`valuesets.fsh`, marked `(espen-forms)`):**
  - `ICRNTDDiseaseCS` / VS — `lf`, `oncho`, `schisto`, `sth`, `trachoma`.
  - `ICRMDAMedicinePackageCS` / VS — `ivm`, `ivm-alb`, `ivm-alb-dec`, `alb`, `tetra`,
    `azm-tab`, `azm-susp`, `meb`, `pzq`, `pzq-alb`, `pzq-meb`.
  Both are genuine ICR campaign metadata (disease scope, medicine package), not
  form-local trivia.

## Template-based extraction design

Add dependency `hl7.fhir.uv.sdc` to `sushi-config.yaml` — the version that carries
`templateExtract` (4.0.0-ballot; verify exact package id/version pullable by IG
Publisher at implementation). Aliases for the SDC extension URLs go in `aliases.fsh`.

Mechanism per SDC template-based extraction: the Questionnaire (root or item) carries
`sdc-questionnaire-templateExtract` referencing a **contained** template resource;
template elements carry `sdc-questionnaire-templateExtractValue` FHIRPath expressions
over the QuestionnaireResponse (`%resource`), with allocate-id for new resource ids.

Extraction targets follow the IG's aggregate-vs-individual rule (working doc §6.5:
*individual record when you have a person; aggregate on Task.output when you don't;
MeasureReport for derived or stratified coverage*):

| Form | Template(s) | Notes |
|---|---|---|
| 1 location | `ICRLocation` + `ICRTargetPopulation` Groups | Location: `name`, `position` from geopoint, `partOf` up the cascade; Groups: `quantity` from the population integers — one total-population Group, one eligible-population Group, age-band Groups with the age-band characteristic |
| 2 receipt | `ICRSupplyDelivery` per drug | Item-level templates so only answered drug totals extract; `suppliedItem.itemCodeableConcept` = drug code, `quantity` = answer |
| 3 treatment | `ICRAdministrativeCoverage` MeasureReport **+ (espen-remap) one `ICRDeliveryUnit` community Group and one Group-subject `ICRMedicationAdministration` per answered drug** | `measure → icr-mda-treatment-coverage`; per-drug `group` with `sex` / `age-band` / `disposition` stratifiers — same shape as `example-mda-treatment-tally` (§7.3). Disposition mapping: under-height/pregnant/breastfeeding counts → `excluded`, absent → `absent` (missed), refusal → `refused` |
| 4 case mgmt | ~~`ICRSupplyDelivery` per drug (distributed)~~ **(espen-remap) None** | Distributed totals stay on the QR; stock reconciliation onto the Form 2 receipt happens in the transform layer. Side-effect and other-NTD counts remain in the QR, documented: person-level `ICRAdverseEvent` cannot be minted from aggregate counts |
| 5 & 6 supervision | **None — by design** | Per §4.6 the QuestionnaireResponse *is* the record (`ICRSupervisionReport`); each Questionnaire carries a description note saying so |

## Adapted mapping — `espen-remap` round (2026-07-07)

**Trigger.** Matt's review of the deployed pipeline: a "distributed" `SupplyDelivery`
misstates what happened. SupplyDelivery means a custody transfer of stock (to a clinic,
a distribution point, a household receiving nets). Tablets swallowed by community
members are treatment, not a transfer — and the IG already sanctions the shape for it:
`ICRMedicationAdministration.subject` allows an `ICRDeliveryUnit` Group precisely for
register-level (tally-sheet) capture where individuals are not enumerated.

**The rule, restated.** Tablet counts are supply chain; people counts are treatment.
The two are different numbers (dose poles put 1–4 tablets in each person) and live on
different axes.

### Changes

1. **Form 3 (treatment)** — extraction additionally mints, per submission:
   - one **`ICRDeliveryUnit` community Group** (`code = community`, `quantity` =
     census men + women, `group-location` → the village by identifier), allocated an id
     so sibling templates can reference it;
   - one **Group-subject `ICRMedicationAdministration` per answered drug block**
     (ATC-coded, `subject` → the allocated community Group, `effective` from
     `authored`, `record-origin = campaign`). This is the treatment *event* the
     MeasureReport's numbers describe, and gives `ICRAdverseEvent.suspectEntity`
     something to reference for MDA pharmacovigilance.
   - The stratified MeasureReport is unchanged — a MedicationAdministration has no
     slot for counts; the cube stays on the report.
2. **Form 4 (case management)** — the eight per-drug "distributed" `ICRSupplyDelivery`
   templates (`EspenSDUsed*`) are **removed**. Distributed totals stay on the
   QuestionnaireResponse. Folding them into the **stock-accountability extension on the
   Form 2 receipt** `SupplyDelivery` is a cross-form merge, which template-based
   extraction cannot express — it happens in the **transform layer** (the fhir-icr
   OpenFn adaptor's `reconcileStockUsed` operation: read the receipt by business
   identifier, merge `used` (+ derived `remaining`), conditional PUT).
3. **Campaign anchor (adaptor only)** — the pipeline additionally upserts a minimal
   campaign layer so extracted resources no longer float free of any campaign:
   - one `ICRCampaignProtocol` (PlanDefinition, `type = mda`,
     `delivery-strategy = community-directed`) per state × year;
   - one `ICRCampaign` (CarePlan, `intent = order`, `instantiatesCanonical` → the
     protocol, `subject` → the village's eligible `ICRTargetPopulation` by logical
     identifier reference) per village × year;
   - one completed `ICRCampaignTask` per Form 3 submission (`for` → the community
     Group, `location` → the village, `focus` → the CarePlan,
     `delivery-strategy = community-directed`, `task-origin = pre-planned`,
     `output` → the per-drug MedicationAdministrations and MeasureReports).
   The IG extraction templates do **not** mint the campaign layer — shared,
   cross-submission resources are a transform-layer concern (same boundary rationale
   as the surveillance scope decision, working doc §13.2).

### Not changed

Form 2 receipt SupplyDeliveries (a true stock drop at the health facility); Forms 5/6
no-extraction rule; the canonical checklists; all terminology.

## IG & working-doc wiring

- `sushi-config.yaml`: SDC dependency.
- `aliases.fsh`: SDC extension aliases.
- `codesystems.fsh` / `valuesets.fsh`: the two new CS/VS pairs.
- `project/icr-ig.md`: new content documenting the ESPEN instrument set + extraction
  design (new subsection near §4.6–4.8 territory + §1.5/§13.2 count updates), version
  bump **0.21.x → 0.22.0** (content rewrite = minor bump), visible stamp + frontmatter
  `last_modified` synced, committed per the versioning convention.

## Verification

1. `sushi` clean compile; `_gentopcoat.sh` full build green.
2. QA report: no new errors on the six instances (warnings triaged).
3. Topcoat preview of at least `espen-mda-treatment` renders in the browser
   (questionnaire preview feature) — eyeball the group/skip-logic structure.
4. Extraction templates validate: contained resources conform to their ICR profiles
   where extraction fills all mandatory elements (where a mandatory element can only
   come from context — e.g. Location partOf refs — the template documents the
   launchContext assumption).

## Out of scope

- Example QuestionnaireResponses for the six instruments (can be a follow-up round).
- Executable end-to-end extraction testing (Matt's code supports templateExtract;
  the IG ships the templates).
- Reworking the canonical checklists or `ICRSupervisionReport`.
