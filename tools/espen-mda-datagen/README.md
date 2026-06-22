# ESPEN MDA sample-data generator

Generates one internally-consistent synthetic ESPEN MDA campaign (onchocerciasis/LF →
ivermectin, Ituri/DRC) and writes it as **ODK submission instance XML** — one file per
submission — for the six `forms/espen mda/` XLSForms. Built to be loaded into **Ona Data**
(OpenRosa) and later transformed to FHIR.

## Run

```bash
uv venv --python 3.13 .venv
uv pip install --python .venv -e "tools/espen-mda-datagen[dev]"
.venv/bin/python -m espen_datagen.generate --out tools/espen-mda-datagen/sample-data
```

Options: `--seed`, `--villages`, `--days`, `--out`, `--forms-dir`. Output is
deterministic per seed.

## Output

```
sample-data/
  1_location/<uuid>.xml ...        # one ODK submission per form, per record
  3_med_treatment/<uuid>.xml ...
  manifest.json                    # seed, footprint, counts, received/distributed, file list
```

Each XML's root `id` matches the compiled `form_id`, with a `uuid:` `meta/instanceID` —
so submissions match the published form on Ona Data.

## Loading into Ona Data (next step)

1. Publish the six XLSForms (or the compiled XForms) to an Ona Data project.
2. Submit each instance XML via the OpenRosa `/submission` endpoint.

## Design

See `docs/superpowers/specs/2026-06-22-espen-mda-sample-data-generator-design.md`.
