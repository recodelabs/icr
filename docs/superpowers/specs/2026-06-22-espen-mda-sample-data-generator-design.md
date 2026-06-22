---
title: ESPEN MDA sample-data generator
date: 2026-06-22
status: design — approved
tags:
  - icr
  - espen
  - mda
  - xlsform
  - odk
  - ona-data
  - sample-data
related:
  - "[[espen-v4]]"
  - "[[ig-info]]"
---

# ESPEN MDA sample-data generator — design

## 1. Purpose & context

Generate a **coherent synthetic ESPEN MDA campaign dataset** that fills out the six
ESPEN NTD-MDA XLSForms in `forms/espen mda/`, emitted as **ODK submission instance
XML** (one file per submission). This is **step 1** of an end-to-end demonstration:

```
XLSForms ──pyxform──▶ XForms ──[this tool]──▶ ODK submission XML
   │                                              │
   └─ (publish to Ona Data) ◀────────────────────┘  load submissions (OpenRosa)
                                                  │
                                          OpenFn ─▶ FHIR bundles ─▶ Healthcare API   (later steps)
```

The dataset will be **loaded into Ona Data** (an OpenRosa/ODK-compatible aggregate
backend) and later transformed to FHIR per the mapping in [[espen-v4]]. The whole point
is to flesh out integration issues step by step before jumping to FHIR.

### Decisions locked in (from brainstorming)

| Decision | Choice |
|---|---|
| Primary artifact | **ODK submission instance XML only** (one file per submission). No CSV export. |
| Geography | **Existing DRC demo geography** baked into the forms' choices sheets. Footprint anchored at province **Ituri → district Bunia** (+ one neighbouring district) → ~3 health facilities → ~12 villages. |
| Scale | **Small & coherent**: ~1 province, 2 districts, ~3 HFs, ~12 villages, 3-day campaign. |
| Form→XForm | **pyxform** compile; fill the compiled instance template (no hand-authored XML). |
| Backend target | **Ona Data** — submission XML must be valid OpenRosa instances whose root `id` (+ version) match the published form. |
| Out of scope (now) | live ODK Central/Ona push, real Overture geography, CSV, web UI, multi-scenario stress generation, the FHIR/OpenFn conversion itself. |

## 2. The six forms (one campaign, six angles)

| # | Form (`demo_mda_9999_*`) | Compiled form id | Grain | Core content |
|---|---|---|---|---|
| 1 | `1_location` | `demo_mda_9999_1_location_v3` | one / village | total + age-band population (1–4, 5–14, 15+), eligible pop (calculate), GPS |
| 2 | `2_part` | `demo_mda_9999_2_part_v3` | one / HF | drugs received (PZQ/ALB/MEB/IVM/DEC/AZM susp+tab/TETRA) |
| 3 | `3_med_treatment` | `demo_mda_9999_3_med_treatement_v3` | one / village / campaign-day | **disaggregated cube**: per-drug × age-band × sex treated; reasons-not-treated (child<90cm, pregnant, breastfeeding, absent, refusal); census; CDD counts |
| 4 | `4_case_mngnt` | `demo_mda_9999_4_case_mngnt_v3` | one / HF | drugs distributed; minor/serious side-effects; other-NTD case rumours |
| 5 | `5_supervision_hf` | `demo_mda_9999_5_supervision_hf_v3` | one / supervision visit | village coverage; per-drug stock (remain/expired/concordance); training; social-mob; pharmacovigilance |
| 6 | `6_supervision_CDD` | `demo_mda_9999_6_supervision_CDD_v3` | one / observed CDD | full observation checklist; training topics |

All six compile cleanly via pyxform (verified). The choices sheets already carry DRC
geography (provinces, districts, HFs, villages, location_ids), diseases
(LF/ONCHO/SCHISTO/STH/TRACHOMA), medicine packages, recorder IDs, and code lists.

## 3. Architecture — three layers

### 3.1 Form layer — `forms.py`
- pyxform-compile each XLSForm → XForm (cache the XML).
- Extract per form: `form_id`, the **instance template** tree (exact node nesting incl.
  groups), the ordered list of leaf node paths, the set of `calculate` nodes, and the
  `meta/instanceID` slot.
- Parse the **choices** sheets into lookup tables (valid codes per `list_name`).
- Write the compiled XForms to `xform/<form>.xml` — these are the exact artifacts to
  publish to Ona Data so submission ids match.
- Output: a per-form `FormSchema` object the renderer fills.

### 3.2 Scenario layer — `scenario.py` (the consistency engine)
Builds **one campaign** as plain Python objects, **deterministic from a fixed seed**:

- **Footprint** — Ituri → {Bunia, +1 district} → ~3 HFs → ~12 villages; each village gets
  a stable `location_id`, `recorder_id`, and a GPS jittered around a centroid.
- **Population** (Form 1) — per village total pop (rural sizes ~300–2,500) split into age
  bands 1–4 / 5–14 / 15+; `eligible_pop` computed by the form's own calculate rule.
- **Disease → medicine package** — one coherent package for the footprint
  (e.g. SCHISTO+STH → PZQ+ALB), drawn from the valid `disease`/`medicine` lists.
- **Drugs received** (Form 2, per HF) — sized to eligible pop × tablets/person × buffer.
- **Treatment cube** (Form 3, per village per day) — treated by drug × age-band × sex at
  realistic coverage (~70–90%); residue split across not-treated reasons; CDD counts;
  spread across the 3 campaign days; `calculate` fields (men/women treated) computed.
- **Distribution & case mgmt** (Form 4, per HF) — tablets distributed ≈ treated ×
  tablets/person, ≤ received; small minor/serious side-effect counts; a few other-NTD
  rumours.
- **Supervision HF** (Form 5) — village coverage = the actual footprint counts; per-drug
  stock remain/expired/concordance consistent with received − distributed; training;
  social-mob channels; pharmacovigilance flags = Form 4 side-effects.
- **Supervision CDD** (Form 6) — a few observed CDDs in sampled villages; checklist mostly
  "Yes" with a couple "No"; training topics.

**Cross-form invariants enforced in code (then `assert`-checked):**
1. `treated_total + Σ not-treated reasons ≤ eligible_pop` per village/drug.
2. `Σ tablets distributed (F4) ≈ Σ people treated (F3) × tablets/person`, and `≤ received (F2)`.
3. `stock remaining (F5) ≈ received (F2) − distributed (F4)` per drug.
4. `F5 villages total/treated/not-treated = footprint counts`.
5. `F5/F4 pharmacovigilance flags` consistent with side-effect counts.
6. age-band sums and `calculate` nodes reconcile to their inputs.

Output: a list of `SubmissionRecord{form_id, values: {node_path: value}}`.

### 3.3 Render layer — `render.py`
- For each record: clone the form's instance template; set each leaf by node path
  (groups handled by path; `select_multiple` rendered space-separated per ODK);
  fill `meta/instanceID` with a fresh UUID (`uuid:...`) and `start`/`end`/`today`
  timestamps inside the campaign window; preserve the root `id` (+ version) attributes.
- Write `sample-data/<form>/<uuid>.xml`.
- Write `sample-data/manifest.json` — run map (seed, footprint summary, per-form counts,
  file list). Not a data export; an index for the later OpenFn/Ona load step.

## 4. Entry point & layout

- **Entry point:** `generate.py` — config = `seed`, footprint sizes, output dir; defaults
  to the small/coherent footprint; prints a summary table of what was generated.
- **Layout:** self-contained `tools/espen-mda-datagen/`:
  ```
  tools/espen-mda-datagen/
    pyproject.toml | requirements.txt   # pinned: pyxform, openpyxl
    README.md                           # how to run, what it emits, Ona-load note
    forms.py  scenario.py  render.py  generate.py
    sample-data/                        # generated output (xform/, per-form dirs, manifest.json)
  ```
  Run from the existing repo `.venv` (uv, python 3.13). Demo/research harness for this
  workspace — not IG/app code (those live in separate repos per CLAUDE.md).

## 5. Verification

1. **Structural** — re-parse every emitted XML; assert each required leaf is present and
   the file round-trips through the parser.
2. **Schema fidelity** — every emitted node path exists in the form's compiled instance
   template (no stray/misspelled nodes); every `calculate` node carries its computed value.
3. **Invariants** — the scenario-layer `assert`s (§3.2) all pass.
4. **Ona compatibility** — root `id` equals the compiled `form_id`; `meta/instanceID` is a
   unique `uuid:` URN; submission validates as OpenRosa instance shape.
5. *(Optional, not required)* ODK Validate (Java) on the compiled XForms.

## 6. Out of scope / YAGNI

Live push to Ona Data or ODK Central; real Overture geography; CSV/flat export; web UI;
multiple or randomized stress scenarios; the OpenFn→FHIR→Healthcare-API conversion (the
next step, designed separately). One reproducible coherent campaign, XML out, nothing more.

## 7. What this sets up next

- Publish the compiled XForms + load the submission XML into **Ona Data** (OpenRosa).
- An **OpenFn** job mapping ODK submissions → FHIR bundles per [[espen-v4]].
- Load into the **Healthcare API** FHIR store — the true end-to-end validation.
