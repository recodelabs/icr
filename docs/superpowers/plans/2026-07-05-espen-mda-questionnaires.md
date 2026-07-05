# ESPEN MDA Questionnaires Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the six ESPEN MDA XLSForms in `forms/espen mda/` into FHIR R4 Questionnaires with SDC template-based extraction into ICR-profiled resources, shipped as example artifacts in the ICR IG.

**Architecture:** Six `Instance ... InstanceOf: Questionnaire, Usage: #example` in a new `ig/input/fsh/questionnaires-espen.fsh`. Extraction templates are contained (`Usage: #inline`) base-typed resources carrying `sdc-questionnaire-templateExtractValue`/`templateExtractContext` FHIRPath extensions, wired from the Questionnaire via `sdc-questionnaire-templateExtract`. Two new CodeSystem/ValueSet pairs carry the NTD disease and MDA medicine-package vocabulary. Existing canonical checklists (`icr-mda-supervision-checklist`, `icr-campaign-readiness-checklist`) are untouched.

**Tech Stack:** FSH/SUSHI → IG Publisher → IG Topcoat. SDC dependency `hl7.fhir.uv.sdc#4.0.0` (verified: FHIR 4.0.1, latest on packages.fhir.org, contains all templateExtract artifacts).

**Spec:** `docs/superpowers/specs/2026-07-05-espen-mda-questionnaires-design.md`
**Source-of-truth data:** `docs/superpowers/plans/2026-07-05-espen-forms-reference.md` — a complete dump (survey + choices + settings) of all six XLSForms. Already generated; committed in Task 1. Every linkId, label, formula, and choice list cited below appears verbatim there. **When a task says "roster in reference §N", that section is the complete, authoritative item list — transcribe it row-by-row using the Conversion Rules.**

## Global Constraints

- IG canonical: `https://fhir.icr.unicef.org/`. Questionnaire URLs: `https://fhir.icr.unicef.org/Questionnaire/<id>`.
- All new FSH marked with `(espen-forms)` comments, matching the repo's `(forms-v1)` convention.
- Every task ends with `sushi build` **0 errors** from `/Users/claudius/github/icr/ig` and a git commit. Run builds with: `cd /Users/claudius/github/icr/ig && sushi build . 2>&1 | tail -4`.
- Never edit `ig/fsh-generated/` (SUSHI owns it) or `ig/output*/`.
- Git commits end with the trailer: `Claude-Session: https://claude.ai/code/session_01SWsnPpXg2hudGRrXq5h3GE`.
- Do NOT touch `ig/input/fsh/questionnaires.fsh` (the canonical checklists coexist with these).

## Conversion Rules (apply to every questionnaire task)

| XLSForm | FHIR item |
|---|---|
| `begin group` / `begin_group` … `end group` | `type = #group`, `linkId` = group name, `text` = group label |
| `integer` / `int` | `#integer` |
| `text` | `#text` |
| `string` | `#string` |
| `date` | `#date` |
| `select_one yes_no` | `#boolean` |
| `select_one X` (domain list) | `#choice` + `answerValueSet` (ICR-bound lists) or inline `answerOption` (local lists) |
| `select_multiple X` | `#choice` + `repeats = true`, same answer source rules |
| `calculate` | `#integer` (these forms only calculate sums) + `$SDCCalculatedExpression` + `$QHidden = true` + `readOnly = true` |
| `geopoint` | `#group` with two `#decimal` children `<name>_lat` / `<name>_lng` (documented deviation — FHIR has no geopoint item type; extraction needs the parts) |
| `required` = yes | `required = true` |
| `label::English` | `text` |
| `hint::English` (rare) | child `#display` item, `linkId` = `<name>-hint` |

**linkId rule:** the XLSForm `name` column verbatim (including its inconsistent casing, e.g. `I_total_popn_1_4`, `P_hydrocele_LF` — fidelity beats tidiness).

**Registry-cascade rule:** `select_one state|district|health_facility|location|location_id|recorder_id|supervisor` items whose choices are deployment/entity data (the DRC demo place lists, recorder numbers 01–99) become **`#string`** items. FSH comment above each: `// registry cascade: choices are deployment entity data (bind::db_*) — in ICR these resolve against the Location hierarchy / CareTeam registry at capture time`. Exception: form 5's `select_one supervisor` (National/Regional/District/Partner/Health facility — a stable domain list) → `#choice` with inline `answerOption.valueString` options.

**Dropped-with-comment rule** (one `//` comment where each occurs): `start`/`end` device-timestamp rows; `bind::db_*` columns (superseded by the extraction templates); `choice_filter` cascades; the giant medicine-vs-disease combination `constraint` on `p_medicine`/`s_medicine` (`// combination-validity constraint enforced at the capture layer; not carried over`); `appearance` values.

**Source-bug rule:** the `*_women_treated` calculations in form 3 read `${X_5_14_female_treated} + ${X_15_male_treated}` — a source typo (male ≠ female). Convert as the female counterpart (`…15_female_treated`) with comment `// source form has a copy-paste bug (sums 15_male into women); corrected here`.

**FHIRPath answer-fetch convention** (used in calculatedExpressions and templates): 
`%resource.repeat(item).where(linkId='X').answer.value.first()` — and for sums where an answer may be absent:
`iif(%resource.repeat(item).where(linkId='X').answer.exists(), %resource.repeat(item).where(linkId='X').answer.value.first(), 0)`.
Abbreviated below as `V('X')` and `V0('X')` — **expand these in the actual FSH; never write `V(` in output**.

**Placeholder-value pattern** (from SDC's own `extract-complex-template` example): a mandatory primitive in a contained template gets a static placeholder value *plus* a `templateExtractValue` extension; extraction replaces the placeholder.

**Template FSH idioms** (established in Task 3, reused everywhere):

```fsh
// Wire a root-level template:
* contained[+] = SomeTemplate
* extension[+].url = $SDCTemplateExtract
* extension[=].extension[+].url = "template"
* extension[=].extension[=].valueReference.reference = "#<contained-id>"
// Item-level template (extracts only when the item exists in the QR): same two
// lines but on `* item[=].extension[...]`.
// Allocate an id another template can reference:
* extension[+].url = $SDCExtractAllocateId
* extension[=].valueString = "newLocationId"
// ...then in the template extension block, after "template":
* extension[=].extension[+].url = "fullUrl"
* extension[=].extension[=].valueString = "%newLocationId"
// Extract into a primitive element (creates _element in JSON):
* someElement.extension[+].url = $SDCTemplateExtractValue
* someElement.extension[=].valueString = "<fhirpath>"
```

Contained templates are `InstanceOf` the **base** resource type (`Location`, `Group`, `SupplyDelivery`, `MeasureReport`) with `Usage: #inline`, an explicit `* id = "<kebab-id>"`, and `* meta.profile = "https://fhir.icr.unicef.org/StructureDefinition/<ICRProfileId>"` — base-typed because templates are structurally partial; `meta.profile` declares intent. Use **numeric indices** (not slice names) for paths inside templates.

**ICR extension URLs used inside templates** (base-typed instances can't use slice names):

| Extension | URL |
|---|---|
| record-origin (code) | `https://fhir.icr.unicef.org/StructureDefinition/record-origin` |
| denominator-source (CodeableConcept) | `https://fhir.icr.unicef.org/StructureDefinition/denominator-source` |
| estimate-date (date) | `https://fhir.icr.unicef.org/StructureDefinition/estimate-date` |
| coverage-source (code) | `https://fhir.icr.unicef.org/StructureDefinition/coverage-source` |
| realtime-vs-reconciled (code) | `https://fhir.icr.unicef.org/StructureDefinition/realtime-vs-reconciled` |
| stock-accountability (complex: received/used/remaining/notUsable/concordant) | `https://fhir.icr.unicef.org/StructureDefinition/stock-accountability` |

**The drug table** (used by Tasks 4, 5, 6):

| Block prefix | Drug | ATC | Display | UCUM unit | Form-2 receipt linkId | Form-4 distributed linkId |
|---|---|---|---|---|---|---|
| `pzq` | Praziquantel | `P02BA01` | "praziquantel" | `{tbl}` | `p_total_pzq` | `p_total_pzq_dist` |
| `alb` | Albendazole | `P02CA03` | "albendazole" | `{tbl}` | `p_total_alb` | `p_total_alb_dist` |
| `meb` | Mebendazole | `P02CA01` | "mebendazole" | `{tbl}` | `p_total_meb` | `p_total_meb_dist` |
| `ivm` | Ivermectin | `P02CF01` | "ivermectin" | `{tbl}` | `p_total_ivm` | `p_total_ivm_dist` |
| `dec` | Diethylcarbamazine | `P02CB02` | "diethylcarbamazine" | `{tbl}` | `p_total_dec` | `p_total_dec_dist` |
| `azm_susp` | Azithromycin suspension | `J01FA10` | "azithromycin (suspension)" | `L` | `p_total_az_sus` | `p_total_az_sus_dist` |
| `azm_tb` | Azithromycin tablets | `J01FA10` | "azithromycin (tablets)" | `{tbl}` | `p_total_az_tab` | `p_total_az_tab_dist` |
| `tetra` | Tetracycline eye ointment | `S01AA09` | "tetracycline (eye ointment)" | `{tube}` | `p_total_tetra` | `p_total_tetra_dist` |

(`$ATC = http://www.whocc.no/atc` already exists in `aliases.fsh:4`.)

---

### Task 1: SDC dependency, aliases, and the reference dump

**Files:**
- Modify: `ig/sushi-config.yaml` (add `dependencies`)
- Modify: `ig/input/fsh/aliases.fsh` (append SDC aliases)
- Commit (already generated): `docs/superpowers/plans/2026-07-05-espen-forms-reference.md`

**Interfaces:**
- Produces: aliases `$SDCTemplateExtract`, `$SDCTemplateExtractContext`, `$SDCTemplateExtractValue`, `$SDCExtractAllocateId`, `$SDCCalculatedExpression`, `$SDCLaunchContext`, `$QHidden` — used by Tasks 3–7.

- [ ] **Step 1: Add the SDC dependency**

In `ig/sushi-config.yaml`, after the `jurisdiction:` line and before `publisher:`, add:

```yaml
dependencies:
  hl7.fhir.uv.sdc: 4.0.0
```

- [ ] **Step 2: Append SDC aliases to `ig/input/fsh/aliases.fsh`**

```fsh
// --- SDC (Structured Data Capture 4.0.0) — template-based extraction (espen-forms) ---
Alias: $SDCTemplateExtract = http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-templateExtract
Alias: $SDCTemplateExtractContext = http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-templateExtractContext
Alias: $SDCTemplateExtractValue = http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-templateExtractValue
Alias: $SDCExtractAllocateId = http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-extractAllocateId
Alias: $SDCCalculatedExpression = http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-calculatedExpression
Alias: $SDCLaunchContext = http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-launchContext
Alias: $QHidden = http://hl7.org/fhir/StructureDefinition/questionnaire-hidden
```

- [ ] **Step 3: Build — expect SDC package fetch + 0 errors**

Run: `cd /Users/claudius/github/icr/ig && sushi build . 2>&1 | tail -6`
Expected: a line downloading/resolving `hl7.fhir.uv.sdc#4.0.0`, then the summary box with `0 Errors`. (Warnings pre-exist; only new errors block.)

- [ ] **Step 4: Commit**

```bash
cd /Users/claudius/github/icr
git add ig/sushi-config.yaml ig/input/fsh/aliases.fsh docs/superpowers/plans/2026-07-05-espen-forms-reference.md docs/superpowers/plans/2026-07-05-espen-mda-questionnaires.md
git commit -m "ig: add SDC 4.0.0 dependency + aliases; ESPEN forms reference dump (espen-forms)"
```

---

### Task 2: NTD disease & MDA medicine-package terminology

**Files:**
- Modify: `ig/input/fsh/codesystems.fsh` (append)
- Modify: `ig/input/fsh/valuesets.fsh` (append)
- Modify: `ig/input/fsh/aliases.fsh` (append 2 aliases)

**Interfaces:**
- Produces: `ICRNTDDiseaseCS`/`ICRNTDDiseaseVS`, `ICRMDAMedicinePackageCS`/`ICRMDAMedicinePackageVS`, aliases `$NTDDisease`, `$MedicinePackage`. Tasks 3–7 bind `answerValueSet = Canonical(ICRNTDDiseaseVS)` etc. and write `enableWhen.answerCoding = ICRMDAMedicinePackageCS#ivm`.

- [ ] **Step 1: Append to `codesystems.fsh`** (follow the file's existing style — `^caseSensitive`, `^experimental`):

```fsh
// --- espen-forms: NTD-MDA vocabulary from the ESPEN demo instruments -----------

CodeSystem: ICRNTDDiseaseCS
Id: icr-ntd-disease-cs
Title: "ICR NTD Disease"
Description: "The preventive-chemotherapy NTDs an MDA campaign addresses — the disease-scope axis of the ESPEN MDA instruments (espen-forms)."
* ^caseSensitive = true
* ^experimental = false
* #lf "Lymphatic filariasis (LF)"
* #oncho "Onchocerciasis"
* #schisto "Schistosomiasis"
* #sth "Soil-transmitted helminthiasis (STH)"
* #trachoma "Trachoma"

CodeSystem: ICRMDAMedicinePackageCS
Id: icr-mda-medicine-package-cs
Title: "ICR MDA Medicine Package"
Description: "The medicine package distributed in an MDA round — single drugs and the standard co-administration combinations (ESPEN medicine list, espen-forms)."
* ^caseSensitive = true
* ^experimental = false
* #ivm "IVM (ivermectin)"
* #ivm-alb "IVM + ALB"
* #ivm-alb-dec "IVM + ALB + DEC"
* #alb "ALB (albendazole)"
* #meb "MEB (mebendazole)"
* #pzq "PZQ (praziquantel)"
* #pzq-alb "PZQ + ALB"
* #pzq-meb "PZQ + MEB"
* #azm-tab "AZM tablets (azithromycin)"
* #azm-susp "AZM suspension (azithromycin)"
* #tetra "TETRA (tetracycline eye ointment)"
```

- [ ] **Step 2: Append to `valuesets.fsh`** (matching existing VS style):

```fsh
// --- espen-forms ----------------------------------------------------------------

ValueSet: ICRNTDDiseaseVS
Id: icr-ntd-disease-vs
Title: "ICR NTD Disease"
Description: "Diseases covered by an MDA campaign (espen-forms)."
* ^experimental = false
* include codes from system ICRNTDDiseaseCS

ValueSet: ICRMDAMedicinePackageVS
Id: icr-mda-medicine-package-vs
Title: "ICR MDA Medicine Package"
Description: "MDA medicine packages, single and combined (espen-forms)."
* ^experimental = false
* include codes from system ICRMDAMedicinePackageCS
```

- [ ] **Step 3: Append aliases to `aliases.fsh`:**

```fsh
Alias: $NTDDisease = https://fhir.icr.unicef.org/CodeSystem/icr-ntd-disease-cs
Alias: $MedicinePackage = https://fhir.icr.unicef.org/CodeSystem/icr-mda-medicine-package-cs
```

- [ ] **Step 4: Build**

Run: `cd /Users/claudius/github/icr/ig && sushi build . 2>&1 | tail -4`
Expected: `0 Errors`, and 4 new resources in the count.

- [ ] **Step 5: Commit**

```bash
cd /Users/claudius/github/icr && git add ig/input/fsh && git commit -m "ig: ICRNTDDiseaseCS/VS + ICRMDAMedicinePackageCS/VS (espen-forms)"
```

---

### Task 3: `espen-mda-location-registration` — questionnaire + Location/Group extraction

The pattern-setting task: first full questionnaire, first extraction templates, first allocate-id cross-reference. Roster: reference **§demo_mda_9999_1_location.xlsx** (16 rows, all shown in this task).

**Files:**
- Create: `ig/input/fsh/questionnaires-espen.fsh`

**Interfaces:**
- Produces: the file header comment block; the questionnaire/template FSH idioms every later task copies; instance `espen-mda-location-registration`.
- Consumes: Task 1 aliases; Task 2 nothing (this form has no disease/medicine items).

- [ ] **Step 1: Create `questionnaires-espen.fsh` with header + the full instance**

```fsh
// ESPEN MDA demo instruments (espen-forms) — the six ESPEN MDA XLSForms
// (forms/espen mda/) converted to FHIR Questionnaires with SDC template-based
// extraction into ICR-profiled resources. These are complete, source-faithful
// EXAMPLE instruments (Usage: #example) demonstrating how a country programme's
// forms plug into the ICR: the canonical condensed checklists in
// questionnaires.fsh remain the IG's normative instruments.
// Source-of-truth dump: docs/superpowers/plans/2026-07-05-espen-forms-reference.md
// Conversion conventions: linkId = XLSForm name verbatim; registry cascades
// (state/district/facility/village) → string items resolved against the Location
// hierarchy at capture time; select_one yes_no → boolean; calculates → hidden
// items with SDC calculatedExpression; device metadata (start/end) dropped.

// --- Form 1: MDA Location (village registration & census) ----------------------
// Extraction: ICRLocation (the village) + ICRTargetPopulation Groups (total,
// eligible, and age-band denominators), cross-linked via extractAllocateId.

Instance: espen-mda-location-registration
InstanceOf: Questionnaire
Title: "ESPEN MDA — 1. Location Registration Form"
Usage: #example
* url = "https://fhir.icr.unicef.org/Questionnaire/espen-mda-location-registration"
* name = "EspenMDALocationRegistration"
* status = #active
* experimental = false
* description = "ESPEN MDA demo Form 1 (village/location registration and census): admin cascade, population by age band, GPS. Template-based extraction: one ICRLocation for the village and ICRTargetPopulation Groups for the total, eligible, and age-band denominators (espen-forms)."
* subjectType = #Location
// allocate the extracted Location's id so the Group templates can reference it
* extension[+].url = $SDCExtractAllocateId
* extension[=].valueString = "newLocationId"
* extension[+].url = $SDCTemplateExtract
* extension[=].extension[+].url = "template"
* extension[=].extension[=].valueReference.reference = "#loc-template"
* extension[=].extension[+].url = "fullUrl"
* extension[=].extension[=].valueString = "%newLocationId"
* extension[+].url = $SDCTemplateExtract
* extension[=].extension[+].url = "template"
* extension[=].extension[=].valueReference.reference = "#pop-total-template"
* extension[+].url = $SDCTemplateExtract
* extension[=].extension[+].url = "template"
* extension[=].extension[=].valueReference.reference = "#pop-eligible-template"
* extension[+].url = $SDCTemplateExtract
* extension[=].extension[+].url = "template"
* extension[=].extension[=].valueReference.reference = "#pop-1-4-template"
* extension[+].url = $SDCTemplateExtract
* extension[=].extension[+].url = "template"
* extension[=].extension[=].valueReference.reference = "#pop-5-14-template"
* extension[+].url = $SDCTemplateExtract
* extension[=].extension[+].url = "template"
* extension[=].extension[=].valueReference.reference = "#pop-15-plus-template"
// registry cascade: choices are deployment entity data (bind::db_*) — in ICR these
// resolve against the Location hierarchy / CareTeam registry at capture time
* item[+].linkId = "l_recorder_id"
* item[=].text = "Select the recorder ID"
* item[=].type = #string
* item[+].linkId = "l_state"
* item[=].text = "Select State / Region / Province"
* item[=].type = #string
* item[=].required = true
* item[+].linkId = "l_district"
* item[=].text = "Select District / LGA / County"
* item[=].type = #string
* item[=].required = true
* item[+].linkId = "l_health_facility"
* item[=].text = "Enter the Health facility / Sub district"
* item[=].type = #string
* item[=].required = true
* item[+].linkId = "l_location"
* item[=].text = "Enter the village / location / site"
* item[=].type = #string
* item[=].required = true
* item[+].linkId = "l_location_id"
* item[=].text = "Enter the ID of village / location / site"
* item[=].type = #string
* item[=].required = true
* item[+].linkId = "l_total_pop"
* item[=].text = "Enter the total population of the village"
* item[=].type = #integer
* item[=].required = true
* item[+].linkId = "I_total_popn_1_4"
* item[=].text = "Total number of people aged 1-4 years of the village"
* item[=].type = #integer
* item[=].required = true
* item[+].linkId = "I_total_popn_5_14"
* item[=].text = "Total number of people aged 5-14 years of the Village"
* item[=].type = #integer
* item[=].required = true
* item[+].linkId = "I_total_popn_15_More"
* item[=].text = "Total number of people aged 15 years and above in the village"
* item[=].type = #integer
* item[=].required = true
* item[+].linkId = "l_eligible_pop"
* item[=].text = "Total eligible population of the village"
* item[=].type = #integer
* item[=].readOnly = true
* item[=].extension[+].url = $QHidden
* item[=].extension[=].valueBoolean = true
* item[=].extension[+].url = $SDCCalculatedExpression
* item[=].extension[=].valueExpression.language = #text/fhirpath
* item[=].extension[=].valueExpression.expression = "iif(%resource.repeat(item).where(linkId='I_total_popn_1_4').answer.exists(), %resource.repeat(item).where(linkId='I_total_popn_1_4').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='I_total_popn_5_14').answer.exists(), %resource.repeat(item).where(linkId='I_total_popn_5_14').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='I_total_popn_15_More').answer.exists(), %resource.repeat(item).where(linkId='I_total_popn_15_More').answer.value.first(), 0)"
// geopoint → lat/lng decimal pair (FHIR has no geopoint item type; extraction
// needs the parts)
* item[+].linkId = "l_gps"
* item[=].text = "GPS of the village"
* item[=].type = #group
* item[=].item[+].linkId = "l_gps_lat"
* item[=].item[=].text = "Latitude"
* item[=].item[=].type = #decimal
* item[=].item[+].linkId = "l_gps_lng"
* item[=].item[=].text = "Longitude"
* item[=].item[=].type = #decimal
* item[+].linkId = "l_submitting_report"
* item[=].text = "Enter name of person submitting report"
* item[=].type = #string
* item[=].required = true
* item[+].linkId = "l_additional_note"
* item[=].text = "Any other information"
* item[=].type = #text
// dropped: l_start / l_end (device timestamps)
* contained[+] = EspenLocTemplate
* contained[+] = EspenPopTotalTemplate
* contained[+] = EspenPopEligibleTemplate
* contained[+] = EspenPop14Template
* contained[+] = EspenPop514Template
* contained[+] = EspenPop15PlusTemplate
```

- [ ] **Step 2: Append the contained templates (same file)**

```fsh
// -- extraction templates for Form 1 --

Instance: EspenLocTemplate
InstanceOf: Location
Usage: #inline
* id = "loc-template"
* meta.profile = "https://fhir.icr.unicef.org/StructureDefinition/ICRLocation"
* status = #active
* name.extension[+].url = $SDCTemplateExtractValue
* name.extension[=].valueString = "%resource.repeat(item).where(linkId='l_location').answer.value.first()"
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#area "Area"
* position.latitude.extension[+].url = $SDCTemplateExtractValue
* position.latitude.extension[=].valueString = "%resource.repeat(item).where(linkId='l_gps_lat').answer.value.first()"
* position.longitude.extension[+].url = $SDCTemplateExtractValue
* position.longitude.extension[=].valueString = "%resource.repeat(item).where(linkId='l_gps_lng').answer.value.first()"
* identifier[0].system = "https://fhir.icr.unicef.org/identifier/espen-location-id"
* identifier[0].value.extension[+].url = $SDCTemplateExtractValue
* identifier[0].value.extension[=].valueString = "%resource.repeat(item).where(linkId='l_location_id').answer.value.first()"

Instance: EspenPopTotalTemplate
InstanceOf: Group
Usage: #inline
* id = "pop-total-template"
* meta.profile = "https://fhir.icr.unicef.org/StructureDefinition/ICRTargetPopulation"
* type = #person
* actual = false
* name = "Total population (village census, ESPEN Form 1)"
* extension[0].url = "https://fhir.icr.unicef.org/StructureDefinition/denominator-source"
* extension[0].valueCodeableConcept = $DenominatorSource#microcensus "Microcensus / enumeration"
* extension[1].url = "https://fhir.icr.unicef.org/StructureDefinition/estimate-date"
* extension[1].valueDate = "2026-01-01"
* extension[1].valueDate.extension[+].url = $SDCTemplateExtractValue
* extension[1].valueDate.extension[=].valueString = "%resource.authored.toString().substring(0,10)"
* quantity = 0
* quantity.extension[+].url = $SDCTemplateExtractValue
* quantity.extension[=].valueString = "%resource.repeat(item).where(linkId='l_total_pop').answer.value.first()"
* characteristic[0].code = $GroupCharacteristic#geography "Geography"
* characteristic[0].valueReference.reference.extension[+].url = $SDCTemplateExtractValue
* characteristic[0].valueReference.reference.extension[=].valueString = "%newLocationId"
* characteristic[0].exclude = false
```

`EspenPopEligibleTemplate` (`id = "pop-eligible-template"`, name `"Eligible population (village census, ESPEN Form 1)"`) is identical except `quantity` extracts `l_eligible_pop`.

The three age-band templates (`EspenPop14Template`/`pop-1-4-template`, `EspenPop514Template`/`pop-5-14-template`, `EspenPop15PlusTemplate`/`pop-15-plus-template`) are identical to `EspenPopTotalTemplate` except: `name` = `"Population aged 1-4 / 5-14 / 15+ (village census, ESPEN Form 1)"`, `quantity` extracts `I_total_popn_1_4` / `I_total_popn_5_14` / `I_total_popn_15_More`, and each **adds a second characteristic** (age band, `exclude = false`):

```fsh
* characteristic[1].code = $GroupCharacteristic#age-band "Age band"
* characteristic[1].valueCodeableConcept.text = "1-4 years"   // or "5-14 years" / "15+ years"
* characteristic[1].exclude = false
```

- [ ] **Step 3: Build and inspect**

Run: `cd /Users/claudius/github/icr/ig && sushi build . 2>&1 | tail -4`
Expected: `0 Errors`.

Run: `python3 -c "import json; d=json.load(open('/Users/claudius/github/icr/ig/fsh-generated/resources/Questionnaire-espen-mda-location-registration.json')); print(len(d['contained']), 'contained;', len(d['item']), 'items;', sum(1 for e in d['extension'] if e['url'].endswith('templateExtract')), 'templateExtract exts')"`
Expected: `6 contained; 14 items; 6 templateExtract exts`

- [ ] **Step 4: Commit**

```bash
cd /Users/claudius/github/icr && git add ig/input/fsh/questionnaires-espen.fsh && git commit -m "ig: espen-mda-location-registration questionnaire + Location/TargetPopulation extraction (espen-forms)"
```

---

### Task 4: `espen-mda-drug-receipt` — questionnaire + SupplyDelivery extraction

Roster: reference **§demo_mda_9999_2_part.xlsx** (17 rows). Structure: recorder/state/district/facility strings (cascade rule) → `p_disease` choice (repeats, `ICRNTDDiseaseVS`) → `p_medicine` choice (repeats, `ICRMDAMedicinePackageVS`, combination constraint dropped-with-comment) → 8 per-drug integer items each `relevant`-gated on `p_medicine` → `p_add_note` text.

**Files:**
- Modify: `ig/input/fsh/questionnaires-espen.fsh` (append)

**Interfaces:**
- Consumes: Task 2 ValueSets; Task 3 idioms.
- Produces: instance `espen-mda-drug-receipt`; the per-drug SupplyDelivery template pattern Task 6 copies.

- [ ] **Step 1: Append the questionnaire**

Header block: `url = "https://fhir.icr.unicef.org/Questionnaire/espen-mda-drug-receipt"`, `name = "EspenMDADrugReceipt"`, Title `"ESPEN MDA — 2. Medicine Receipt Form"`, `subjectType = #Location`, description: `"ESPEN MDA demo Form 2 (medicine receipt at health facility): disease and medicine-package scope, per-medicine received totals. Template-based extraction: one ICRSupplyDelivery per answered medicine total (espen-forms)."`

Disease/medicine items:

```fsh
* item[+].linkId = "p_disease"
* item[=].text = "Disease covered by the MDA"
* item[=].type = #choice
* item[=].repeats = true
* item[=].required = true
* item[=].answerValueSet = Canonical(ICRNTDDiseaseVS)
* item[+].linkId = "p_medicine"
* item[=].text = "Select the medicine package"
* item[=].type = #choice
* item[=].repeats = true
* item[=].required = true
* item[=].answerValueSet = Canonical(ICRMDAMedicinePackageVS)
// combination-validity constraint enforced at the capture layer; not carried over
```

Per-drug integer item pattern — PZQ shown; repeat for all 8 rows of the drug table. The XLSForm `relevant` for each is in the dump; translate `selected(${p_medicine},'X') or selected(...)` into one `enableWhen` per package code + `enableBehavior = #any` (single condition ⇒ omit `enableBehavior`). **Item-level templateExtract** goes on each drug item:

```fsh
* item[+].linkId = "p_total_pzq"
* item[=].text = "Total Praziquantel received"
* item[=].type = #integer
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#pzq
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#pzq-alb
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#pzq-meb
* item[=].enableBehavior = #any
* item[=].extension[+].url = $SDCTemplateExtract
* item[=].extension[=].extension[+].url = "template"
* item[=].extension[=].extension[=].valueReference.reference = "#sd-receipt-pzq"
```

enableWhen package codes per drug (from the dump's `relevant` column): pzq → pzq, pzq-alb, pzq-meb · alb → alb, ivm-alb, ivm-alb-dec, pzq-alb · meb → meb, pzq-meb · ivm → ivm, ivm-alb, ivm-alb-dec · dec → ivm-alb-dec · az_sus → azm-susp · az_tab → azm-tab · tetra → tetra.

Close with `p_add_note` (`#text`), dropped-comment for `p_start`/`p_end`, and `* contained[+] = ...` for all 8 templates.

- [ ] **Step 2: Append the 8 SupplyDelivery templates**

PZQ shown in full; the other 7 substitute id (`sd-receipt-<block>` with hyphens, e.g. `sd-receipt-azm-susp`), ATC coding, unit, and source linkId from the drug table:

```fsh
Instance: EspenSDReceiptPzq
InstanceOf: SupplyDelivery
Usage: #inline
* id = "sd-receipt-pzq"
* meta.profile = "https://fhir.icr.unicef.org/StructureDefinition/ICRSupplyDelivery"
* status = #completed
* extension[0].url = "https://fhir.icr.unicef.org/StructureDefinition/record-origin"
* extension[0].valueCode = #campaign
* suppliedItem.itemCodeableConcept = $ATC#P02BA01 "praziquantel"
* suppliedItem.quantity.system = "http://unitsofmeasure.org"
* suppliedItem.quantity.code = #{tbl}
* suppliedItem.quantity.unit = "tablets"
* suppliedItem.quantity.value.extension[+].url = $SDCTemplateExtractValue
* suppliedItem.quantity.value.extension[=].valueString = "%resource.repeat(item).where(linkId='p_total_pzq').answer.value.first()"
// destination: the receiving facility is a registry cascade string in the source
// form; deployments bind it via launchContext against the Location hierarchy
```

- [ ] **Step 3: Build and inspect**

Run: `cd /Users/claudius/github/icr/ig && sushi build . 2>&1 | tail -4` → `0 Errors`.
Run: `python3 -c "import json; d=json.load(open('/Users/claudius/github/icr/ig/fsh-generated/resources/Questionnaire-espen-mda-drug-receipt.json')); items={i['linkId']:i for i in d['item']}; print(len(d['contained']),'contained;', sum(1 for i in d['item'] for e in i.get('extension',[]) if e['url'].endswith('templateExtract')),'item-level templateExtract')"`
Expected: `8 contained; 8 item-level templateExtract`

- [ ] **Step 4: Commit**

```bash
cd /Users/claudius/github/icr && git add ig/input/fsh/questionnaires-espen.fsh && git commit -m "ig: espen-mda-drug-receipt questionnaire + per-drug SupplyDelivery extraction (espen-forms)"
```

---

### Task 5: `espen-mda-treatment` — questionnaire + stratified MeasureReport extraction

The core tally form. Roster: reference **§demo_mda_9999_3_med_treatement.xlsx** (~130 rows): header items (cascade strings, `p_campaign_day` choice from the `campaign_day` list as inline `answerOption.valueString` Day 1…Day 10, `p_disease`/`p_medicine` as in Task 4), a `census` group (`census_method` choice with two `valueString` options from the dump, `census_house_hold`/`census_men`/`census_women` integers), then **8 per-drug block pairs** (`<blk>_by_sex` + `<blk>_reason_not_treated` groups, both `relevant`-gated on `p_medicine` exactly as the dump shows — same enableWhen mapping as Task 4), a `cd_who_distributed` group (4 integers), `p_add_note`.

**Files:**
- Modify: `ig/input/fsh/questionnaires-espen.fsh` (append)

**Interfaces:**
- Consumes: Tasks 1–4 patterns.
- Produces: instance `espen-mda-treatment` + 8 contained MeasureReport templates `mr-<blk>`.

**Block shapes** (linkIds verbatim from the dump):
- Standard blocks `dec, alb, meb, ivm, pzq`: by_sex = `<blk>_5_14_female_treated`, `<blk>_5_14_male_treated`, `<blk>_15_female_treated`, `<blk>_15_male_treated` + calculates `<blk>_men_treated`, `<blk>_women_treated` (apply **source-bug rule**); reasons = `<blk>_child`, `<blk>_pregnant`, `<blk>_breastfeeding`, `<blk>_absent`, `<blk>_refusal`.
- `azm_susp`: by_sex = `azm_susp_less7_boy_treated`, `azm_susp_less7_girl_treated`; reasons = `azm_susp_child`, `azm_susp_absent`, `azm_susp_refusal`.
- `azm_tb`: by_sex = `azm_tb_more7_boy_treated`, `azm_tb_more7_girl_treated`, `azm_tb_child`; reasons = `azm_tb_pregnant`, `azm_tb_breastfeeding`, `azm_tb_absent`, `azm_tb_refusal`.
- `tetra`: by_sex = `tetra_baby_boy`, `tetra_baby_girl`, `tetra_pregnant_women`; reasons = `tetra_child`, `tetra_pregnant`, `tetra_breastfeeding`, `tetra_absent`, `tetra_refusal`.

- [ ] **Step 1: Append the questionnaire** — header: Title `"ESPEN MDA — 3. Medicine Treatment Form (tally)"`, `name = "EspenMDATreatment"`, `subjectType = #Location`, description: `"ESPEN MDA demo Form 3 (the treatment tally): village census plus per-drug treated counts by sex and age band with reasons-not-treated. Template-based extraction: one ICRAdministrativeCoverage MeasureReport per answered drug block — measure icr-mda-treatment-coverage, stratified by sex, age-band, and disposition, the same cube as example-mda-treatment-tally (espen-forms)."` The templateExtract for each drug rides **on that drug's `<blk>_by_sex` group item** (so unanswered blocks extract nothing).

- [ ] **Step 2: Append the 8 MeasureReport templates** — `EspenMRDec`/`mr-dec` shown in full; the 7 others substitute per the block shapes (group.code coding from the drug table; strata linkIds per block shape; azm/tetra blocks: sex strata use their boy/girl items, age-band stratum labels use their band — "6mo-<7y" for azm_susp, "7+y" for azm_tb, "<6mo"+"pregnant-women" for tetra; disposition strata only for reason items the block has):

```fsh
Instance: EspenMRDec
InstanceOf: MeasureReport
Usage: #inline
* id = "mr-dec"
* meta.profile = "https://fhir.icr.unicef.org/StructureDefinition/ICRAdministrativeCoverage"
* status = #complete
* type = #summary
* measure = "https://fhir.icr.unicef.org/Measure/icr-mda-treatment-coverage"
* extension[0].url = "https://fhir.icr.unicef.org/StructureDefinition/coverage-source"
* extension[0].valueCode = #administrative
* extension[1].url = "https://fhir.icr.unicef.org/StructureDefinition/realtime-vs-reconciled"
* extension[1].valueCode = #realtime
* period.start = "2026-01-01"
* period.start.extension[+].url = $SDCTemplateExtractValue
* period.start.extension[=].valueString = "%resource.authored"
* period.end = "2026-01-01"
* period.end.extension[+].url = $SDCTemplateExtractValue
* period.end.extension[=].valueString = "%resource.authored"
* reporter.display = "recorder"
* reporter.display.extension[+].url = $SDCTemplateExtractValue
* reporter.display.extension[=].valueString = "%resource.repeat(item).where(linkId='p_recorder_id').answer.value.first()"
* group[0].code = $ATC#P02CB02 "diethylcarbamazine"
* group[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].population[0].count = 0
* group[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='dec_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='dec_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='dec_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_15_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='dec_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_15_male_treated').answer.value.first(), 0)"
* group[0].population[1].code = $MeasurePopulation#denominator "Denominator"
* group[0].population[1].count = 0
* group[0].population[1].count.extension[+].url = $SDCTemplateExtractValue
* group[0].population[1].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='census_men').answer.exists(), %resource.repeat(item).where(linkId='census_men').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='census_women').answer.exists(), %resource.repeat(item).where(linkId='census_women').answer.value.first(), 0)"
// sex stratifier
* group[0].stratifier[0].code = $CoverageStratifier#sex "Sex"
* group[0].stratifier[0].stratum[0].value.text = "female"
* group[0].stratifier[0].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[0].stratum[0].population[0].count = 0
* group[0].stratifier[0].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[0].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='dec_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='dec_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_15_female_treated').answer.value.first(), 0)"
* group[0].stratifier[0].stratum[1].value.text = "male"
* group[0].stratifier[0].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[0].stratum[1].population[0].count = 0
* group[0].stratifier[0].stratum[1].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[0].stratum[1].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='dec_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='dec_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_15_male_treated').answer.value.first(), 0)"
// age-band stratifier
* group[0].stratifier[1].code = $CoverageStratifier#age-band "Age band"
* group[0].stratifier[1].stratum[0].value.text = "5-14 years"
* group[0].stratifier[1].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[1].stratum[0].population[0].count = 0
* group[0].stratifier[1].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[1].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='dec_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='dec_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_5_14_male_treated').answer.value.first(), 0)"
* group[0].stratifier[1].stratum[1].value.text = "15+ years"
* group[0].stratifier[1].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[1].stratum[1].population[0].count = 0
* group[0].stratifier[1].stratum[1].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[1].stratum[1].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='dec_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_15_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='dec_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_15_male_treated').answer.value.first(), 0)"
// disposition stratifier — one stratum per reason item + treated
* group[0].stratifier[2].code = $CoverageStratifier#disposition "Disposition"
* group[0].stratifier[2].stratum[0].value.text = "treated"
* group[0].stratifier[2].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[0].population[0].count = 0
* group[0].stratifier[2].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='dec_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='dec_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='dec_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_15_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='dec_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_15_male_treated').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[1].value.text = "excluded - under height/age"
* group[0].stratifier[2].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[1].population[0].count = 0
* group[0].stratifier[2].stratum[1].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[1].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='dec_child').answer.exists(), %resource.repeat(item).where(linkId='dec_child').answer.value.first(), 0)"
```

…continue the disposition strata for `dec` with the same single-item shape: stratum[2] `"excluded - pregnant"` ← `dec_pregnant`, stratum[3] `"excluded - breastfeeding"` ← `dec_breastfeeding`, stratum[4] `"absent"` ← `dec_absent`, stratum[5] `"refused"` ← `dec_refusal`.

- [ ] **Step 3: Build and inspect**

Run: `cd /Users/claudius/github/icr/ig && sushi build . 2>&1 | tail -4` → `0 Errors`.
Run: `python3 -c "import json; d=json.load(open('/Users/claudius/github/icr/ig/fsh-generated/resources/Questionnaire-espen-mda-treatment.json')); print(len(d['contained']),'contained MRs')"`
Expected: `8 contained MRs`

- [ ] **Step 4: Commit**

```bash
cd /Users/claudius/github/icr && git add ig/input/fsh/questionnaires-espen.fsh && git commit -m "ig: espen-mda-treatment questionnaire + per-drug stratified MeasureReport extraction (espen-forms)"
```

---

### Task 6: `espen-mda-case-management` — questionnaire + SupplyDelivery(used) extraction

Roster: reference **§demo_mda_9999_4_case_mngnt.xlsx** (25 rows): cascade strings, `p_disease`/`p_medicine` (Task 4 pattern), `med_distr` group (8 per-drug `*_dist` integers with the same enableWhen gating + `p_minor_side_effect`/`p_serious_side_effect` integers), `other_ntd_rep` group (5 integers: `p_guinea_worm_rumor`, `p_leish_suspect`, `p_buruli_ulcer_suspect`, `p_Lymphoedema_LF`, `P_hydrocele_LF`), `p_add_note`.

**Files:**
- Modify: `ig/input/fsh/questionnaires-espen.fsh` (append)

**Interfaces:**
- Consumes: Task 4's SupplyDelivery template pattern; drug table (distributed linkIds).
- Produces: instance `espen-mda-case-management`.

- [ ] **Step 1: Append the questionnaire** — Title `"ESPEN MDA — 4. Medicine Use & Case Management Form"`, `name = "EspenMDACaseManagement"`, `subjectType = #Location`, description: `"ESPEN MDA demo Form 4 (medicine use and case management): per-drug distributed totals, side-effect counts, other-NTD case counts. Template-based extraction: one ICRSupplyDelivery per answered distributed total, carrying the count as stock-accountability 'used'. Side-effect and other-NTD counts remain on the QuestionnaireResponse: person-level ICRAdverseEvent records cannot be minted from aggregate counts (espen-forms)."` templateExtract on each `*_dist` item.

- [ ] **Step 2: Append 8 templates** — copy Task 4's pattern with these differences (PZQ shown; other 7 substitute from drug table):

```fsh
Instance: EspenSDUsedPzq
InstanceOf: SupplyDelivery
Usage: #inline
* id = "sd-used-pzq"
* meta.profile = "https://fhir.icr.unicef.org/StructureDefinition/ICRSupplyDelivery"
* status = #completed
* extension[0].url = "https://fhir.icr.unicef.org/StructureDefinition/record-origin"
* extension[0].valueCode = #campaign
* extension[1].url = "https://fhir.icr.unicef.org/StructureDefinition/stock-accountability"
* extension[1].extension[0].url = "used"
* extension[1].extension[0].valueQuantity.system = "http://unitsofmeasure.org"
* extension[1].extension[0].valueQuantity.code = #{tbl}
* extension[1].extension[0].valueQuantity.unit = "tablets"
* extension[1].extension[0].valueQuantity.value.extension[+].url = $SDCTemplateExtractValue
* extension[1].extension[0].valueQuantity.value.extension[=].valueString = "%resource.repeat(item).where(linkId='p_total_pzq_dist').answer.value.first()"
* suppliedItem.itemCodeableConcept = $ATC#P02BA01 "praziquantel"
* suppliedItem.quantity.system = "http://unitsofmeasure.org"
* suppliedItem.quantity.code = #{tbl}
* suppliedItem.quantity.unit = "tablets"
* suppliedItem.quantity.value.extension[+].url = $SDCTemplateExtractValue
* suppliedItem.quantity.value.extension[=].valueString = "%resource.repeat(item).where(linkId='p_total_pzq_dist').answer.value.first()"
```

- [ ] **Step 3: Build + inspect** — same check as Task 4 against `Questionnaire-espen-mda-case-management.json`; expected `8 contained; 8 item-level templateExtract`.

- [ ] **Step 4: Commit**

```bash
cd /Users/claudius/github/icr && git add ig/input/fsh/questionnaires-espen.fsh && git commit -m "ig: espen-mda-case-management questionnaire + SupplyDelivery(used) extraction (espen-forms)"
```

---

### Task 7: `espen-mda-supervision-hf` + `espen-mda-supervision-cdd` — no extraction, by design

Rosters: reference **§demo_mda_9999_5_supervision_hf.xlsx** (~78 rows) and **§demo_mda_9999_6_supervision_CDD.xlsx** (~44 rows). No contained templates: each description ends with `"No extraction templates: per ICRSupervisionReport (working doc §4.6) the QuestionnaireResponse itself is the supervision record."`

**Files:**
- Modify: `ig/input/fsh/questionnaires-espen.fsh` (append)

**Interfaces:**
- Consumes: Tasks 1–4 patterns; Task 2 ValueSets.
- Produces: instances `espen-mda-supervision-hf`, `espen-mda-supervision-cdd`.

**Coded-list mappings (exact):**
- `s_reason_non_treatment` (`#choice`, repeats): `answerOption.valueCoding` from `ICRMissedReasonCS` (system `https://fhir.icr.unicef.org/CodeSystem/icr-missed-reason-cs`): `Absence of DC` → `#not-visited "Absence of DC"` (display override), `Population refusal` → `#refusal "Population refusal"`, `Medication shortage` → `#medication-shortage`, `Insecurity` → `#insecurity`, `Difficult access` → `#difficult-access`, `Not Required` → `#not-required`.
- `s_chanel_utilises` (`#choice`, repeats): `answerOption.valueCoding` from `ICRCommunicationChannelCS` (system `https://fhir.icr.unicef.org/CodeSystem/icr-communication-channel-cs`): Radio → `#radio`, Town criers → `#town-criers`, Community leaders → `#community-leaders`, Schools → `#schools`, Posters → `#posters`.
- Form 5 `s_supervisor_Level` / form 6 `s_supervisor`: `#choice`, `answerOption.valueString` = National / Regional / District / Partner / Health facility.
- Form 6 `s_training_topic` (`#choice`, repeats): `answerOption.valueString` = the 9 options in the dump (Using the measuring stick … Other).
- All `select_one yes_no` → `#boolean` (≈40 items across both forms).
- `s_disease`/`s_medicine` → Task 4's disease/medicine pattern (constraint dropped-with-comment).
- Form 5 per-drug stock groups (`logistic_<blk>`, 8 groups × 3 booleans) have **no `relevant` in the source** — convert without enableWhen, faithful.
- Form 6: `s_total_dist` calculate → hidden integer + calculatedExpression summing `s_total_dist_trained_male`/`s_total_dist_trained_female` (Task 3 idiom); `attitude_CDD` group's hint → child display item per Conversion Rules.
- Headers: Form 5 Title `"ESPEN MDA — 5. Supervision: Health Facility"`, `name = "EspenMDASupervisionHF"`; Form 6 Title `"ESPEN MDA — 6. Supervision: CDD Observation"`, `name = "EspenMDASupervisionCDD"`; both `subjectType = #Location`, urls per the id pattern.

- [ ] **Step 1: Append both questionnaires** (transcribe rosters row-by-row per rules above)
- [ ] **Step 2: Build + inspect**

Run: `cd /Users/claudius/github/icr/ig && sushi build . 2>&1 | tail -4` → `0 Errors`.
Run: `ls /Users/claudius/github/icr/ig/fsh-generated/resources/Questionnaire-espen-* | wc -l`
Expected: `6`

- [ ] **Step 3: Commit**

```bash
cd /Users/claudius/github/icr && git add ig/input/fsh/questionnaires-espen.fsh && git commit -m "ig: espen-mda-supervision-hf + -cdd questionnaires — QR is the record, no extraction (espen-forms)"
```

---

### Task 8: Full IG build + Topcoat preview verification

**Files:** none created (build outputs only).

- [ ] **Step 1: Full publisher + Topcoat build**

Run: `cd /Users/claudius/github/icr/ig && ./_gentopcoat.sh 2>&1 | tail -15` (takes several minutes).
Expected: publisher completes; Topcoat build finishes with its output line. 

- [ ] **Step 2: QA check**

Run: `python3 -c "import json; d=json.load(open('/Users/claudius/github/icr/ig/output/qa.json')); errs=[m for m in d.get('messages',[]) if m.get('level')=='ERROR' and 'espen' in m.get('file','').lower()]; print(len(errs), 'espen errors'); [print(m['file'], m['message'][:160]) for m in errs[:10]]"`
Expected: `0 espen errors`. If errors appear, fix the FSH (common: invalid enableWhen answerCoding, bad canonical) and rebuild; do not suppress.

- [ ] **Step 3: Preview verification in the browser**

Serve: `cd /Users/claudius/github/icr/ig/output-topcoat && npx serve -l 7777 &` then open `http://localhost:7777/Questionnaire-espen-mda-treatment.html` with the browser tool (playwright/chrome-devtools MCP). Verify: the questionnaire preview renders; groups and per-drug sections visible; take a screenshot and send it to the user with SendUserFile. Repeat for `Questionnaire-espen-mda-location-registration.html`. Kill the server after.

- [ ] **Step 4: Commit** (only if any FSH fixes were made in Step 2; build outputs are gitignored)

---

### Task 9: Working-doc update (`project/icr-ig.md` → v0.22.0)

**Files:**
- Modify: `project/icr-ig.md`

Per the repo's versioning convention (CLAUDE.md): content rewrite ⇒ **minor bump** to `0.22.0`, update frontmatter `version` + `last_modified` (ISO 8601 UTC) **and** the visible `<sub>` stamp under the H1 (friendly EDT format), then commit.

- [ ] **Step 1: Add the espen-forms content**
  - New subsection **§4.8 "The ESPEN MDA instrument set (espen-forms)"** after §4.7: what the six instruments are, the coexist-with-canonical-checklists decision, the template-based-extraction design (per-form target table from the spec), the no-extraction-by-design rule for the supervision pair, and the SDC 4.0.0 dependency. ~300–400 words, matching the doc's voice; cite `docs/superpowers/specs/2026-07-05-espen-mda-questionnaires-design.md`.
  - §1.5 artifact tables: Questionnaire count 2 → 8 (note the six `espen-mda-*` example instruments); add `questionnaires-espen.fsh` to the file map; CodeSystems 23 → 25 and add the two new CS to the §9 table with an *(espen-forms)* marker; ValueSets count +2.
  - §13.2: add an **espen-forms (built)** entry mirroring the forms-v1 entry style.
- [ ] **Step 2: Bump version + stamp** — frontmatter `version: 0.22.0`, `last_modified` = now (UTC ISO); visible stamp `` <sub>`v0.22.0 · Last modified <friendly EDT>`</sub> ``.
- [ ] **Step 3: Commit**

```bash
cd /Users/claudius/github/icr && git add project/icr-ig.md && git commit -m "icr-ig.md v0.22.0: ESPEN MDA instrument set + template-based extraction (espen-forms)"
```
