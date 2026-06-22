# ESPEN MDA sample-data generator

Generates **one internally-consistent synthetic ESPEN MDA campaign** — onchocerciasis/LF
treated with ivermectin (+albendazole) via community-directed treatment (CDTI) in
**Ituri, DRC** — and writes it as **ODK submission instance XML**, one file per submission,
for the six `forms/espen mda/` XLSForms.

It exists to demonstrate the ICR pipeline end to end:

```
XLSForms ──pyxform──▶ XForms ──[this tool]──▶ ODK submission XML
                                                    │
                                            load into Ona Data (OpenRosa)
                                                    │
                                            OpenFn ─▶ FHIR ─▶ Healthcare API   (later steps)
```

The point of the tool is **coherence**: the six forms describe one campaign from different
angles, so the generated numbers reconcile across forms (treated + not-treated ≤ eligible;
tablets distributed ≤ received; stock remaining = received − distributed; the supervision
village counts equal the actual footprint; `calculate` fields equal their form formulas).
Random per-form data would be obviously fake to anyone who has seen ESPEN registers — this
isn't.

## Quick start

From the repo root:

```bash
# one-time setup
uv venv --python 3.13 .venv
uv pip install --python .venv -e "tools/espen-mda-datagen[dev]"

# generate (writes to tools/espen-mda-datagen/sample-data/ by default)
.venv/bin/python -m espen_datagen.generate
```

You'll see `Wrote 57 submissions to …` followed by a face-validity report. To write
elsewhere, pass `--out`:

```bash
.venv/bin/python -m espen_datagen.generate --out /tmp/espen-run
```

## CLI options

| Flag | Default | Meaning |
|------|---------|---------|
| `--seed` | `20261101` | RNG seed. **Same seed → identical data** (instance-IDs excepted; see Determinism). |
| `--villages` | `12` | Number of villages in the footprint (one `1_location` submission each). |
| `--days` | `3` | Campaign length in days (treatment cube is spread across days). Tuned for 3; other values fall back to a uniform daily split. |
| `--out` | `tools/espen-mda-datagen/sample-data` | Output directory (created if missing). |
| `--forms-dir` | `<repo>/forms/espen mda` | Where the six source XLSForms live. |

Example — a larger, differently-seeded run:

```bash
.venv/bin/python -m espen_datagen.generate --seed 7 --villages 20 --days 5 --out /tmp/espen-big
```

## What it produces

```
sample-data/
  xform/
    1_location.xml  2_part.xml  3_med_treatment.xml
    4_case_mngnt.xml  5_supervision_hf.xml  6_supervision_CDD.xml   # compiled form DEFINITIONS
  1_location/<uuid>.xml …          # filled-out submission INSTANCES, split by form
  2_part/<uuid>.xml …
  3_med_treatment/<uuid>.xml …
  4_case_mngnt/<uuid>.xml …
  5_supervision_hf/<uuid>.xml …
  6_supervision_CDD/<uuid>.xml …
  manifest.json                    # run map: seed, footprint, counts, received/distributed, file list
```

Two kinds of artifact:

- **`xform/*.xml` — form definitions.** The XLSForms compiled to XForms by pyxform. These
  are what you publish to Ona Data once. Identical for the same source forms.
- **`<form>/<uuid>.xml` — submission instances.** The actual filled-out data. Each file's
  root element `id` equals the compiled `form_id` and `meta/instanceID` is a unique `uuid:`
  URN, so a submission attaches to its published form automatically (OpenRosa).

The six forms / submission counts at the default footprint:

| Form | Grain | Count |
|------|-------|-------|
| `1_location` | one per village | 12 |
| `2_part` (medicine receipt) | one per health facility | 3 |
| `3_med_treatment` (the disaggregated cube) | one per village × day | 36 |
| `4_case_mngnt` (distribution, side-effects) | one per health facility | 3 |
| `5_supervision_hf` | one supervision visit | 1 |
| `6_supervision_CDD` | one observed distributor | 2 |
| **total** | | **57** |

## Determinism & regeneration

- Data is **reproducible per `--seed`**: same seed and footprint → identical field values.
- **Instance IDs / filenames are intentionally NOT seeded** — `meta/instanceID` must be
  globally unique, so every run produces fresh UUIDs (and therefore fresh filenames).
- `write_campaign` does **not** clear the output directory; re-running accumulates files.
  Point `--out` at a fresh directory (or delete the old one) for a clean run.
- The committed `sample-data/` snapshot is a fixed example; the directory is gitignored,
  so your own runs won't create git churn (the snapshot was force-added on purpose).

## Loading into Ona Data (next step)

1. Publish the six forms to an Ona Data project — upload the XLSForms from
   `forms/espen mda/`, or the compiled `sample-data/xform/*.xml`.
2. POST each submission instance to the OpenRosa `/submission` endpoint. Because each
   instance's root `id` matches a published form's `form_id`, it attaches to the right form.

## How realism is calibrated

All domain parameters live in `realism.py` as **named, sourced constants** (no magic
numbers), tagged by origin:

- **`[ESPEN]`** — mined from the in-repo ESPEN Collect Training Package and Country Deck:
  the real Ituri integrated-campaign context, geography, reporting cadence, the not-treated
  taxonomy, a ~2% data-entry baseline.
- **`[WHO]`** — WHO PC-NTD / Mectizan / APOC CDTI guidance for the clinical numbers the
  ESPEN docs omit: dose-pole height bands (`<90 cm` excluded → 1–4 tablets), IVM
  eligibility/exclusions, coverage band (~70–85%), low minor / near-zero serious AE rates,
  CDD-per-population ratio, the age pyramid.

Every run prints a **face-validity report** — the indicators an ESPEN reviewer eyeballs
(epidemiological & geographic coverage, age distribution, not-treated mix, IVM stock
balance, AE rates, CDD total) flagged `OK`/`CHECK` against expected bands — so "does this
look real?" is a five-second check. The WHO-sourced clinical numbers are the ones worth a
sanity-check from an NTD subject-matter expert.

## Module map

| File | Responsibility |
|------|----------------|
| `forms.py` | Compile each XLSForm → XForm (pyxform); extract a fillable `FormSchema` (instance template, leaf names, calculate nodes, choices). |
| `realism.py` | Sourced domain constants + pure helpers (dose-pole, age split, coverage, not-treated mix, CDD count). No I/O. |
| `scenario.py` | Build one coherent campaign → `SubmissionRecord`s; enforce the cross-form invariants. |
| `render.py` | Fill each form's instance template → submission XML; write files + `manifest.json` + the `xform/` definitions. |
| `report.py` | Compute & format the face-validity indicators from the campaign. |
| `generate.py` | CLI (`run()` for programmatic use, `main()` for the command line). |

## Tests

```bash
.venv/bin/pytest tools/espen-mda-datagen -q
```

26 tests covering form extraction, the realism helpers, the cross-form invariants,
XML rendering/Ona-compatibility, the report, and an end-to-end pipeline run.

## Design docs

- Spec: `docs/superpowers/specs/2026-06-22-espen-mda-sample-data-generator-design.md`
- Plan: `docs/superpowers/plans/2026-06-22-espen-mda-sample-data-generator.md`
- Form ↔ IG mapping: `project/espen-v4.md`

**Out of scope (next steps):** live Ona push, and the OpenFn → FHIR → Healthcare API transform.
