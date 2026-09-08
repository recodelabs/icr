# campaign-builder — Nigeria demo campaign calendar

Generates a **realistic, synthetic campaign calendar** for five northern Nigerian
states — Bauchi, Kano, Jigawa, Gombe, Yobe — as ICR IG resources, 2022 through
2027, and writes it as NDJSON for the local HAPI (`tools/hapi`) or any FHIR
store. It exists to feed the campaign-calendar view (one ViewDefinition over
CarePlan, joined to the location registry parquet) with something that behaves
like real programme data: polio rounds that hit every LGA in the same week,
measles campaigns that roll through LGAs in waves, NTD MDAs that run in the dry
season and *stop* when LGAs pass their surveys.

Everything is driven by three YAML files, so the calendar can be re-cut without
touching code.

```
config/states.yaml       the 119 LGAs (registry ids), 2006 census + 2022 projection
config/endemicity.yaml   which LGAs each NTD programme treats, per year, with sources
config/schedule.yaml     the rounds and annual series: dates, durations, stagger rules
```

## Quick start

```bash
cd tools/campaign-builder
uv venv --python 3.13 .venv && uv pip install --python .venv -e ".[dev]"
.venv/bin/python -m pytest
.venv/bin/python -m campaign_builder.build            # writes out/
python3 ../hapi/load.py ndjson out/0*.ndjson           # load into local HAPI
```

`out/report.md` summarises rounds, counts and same-LGA collisions between
programmes; `out/calendar.csv` is one row per LGA round for a quick look.

Then flatten what the server holds with the IG's campaign-calendar
ViewDefinition (`ig/input/fsh/viewdefinitions.fsh`, built by sushi to
`ig/fsh-generated/resources/Binary-IcrCampaignCalendar.json`):

```bash
./export.sh            # FHIR search by tag → NDJSON → octofhir-sof → out/campaign-calendar.parquet
```

`export.sh` needs `octofhir-sof` on the PATH (the recodelabs/sof fork build,
for `--parquet-temporal native`) and, for the summary, `duckdb`. It is the
one-off, tag-filtered version; the repo's analytics hub (`data/`, refreshed by
`tools/warehouse/refresh.sh`) runs every IG ViewDefinition over everything on
the server and partitions the result by country next to the location registry
parquet — that is what dashboards should read.

Options: `--as-of YYYY-MM-DD` (default 2026-09-07) sets the line between
`completed`, `active` and `draft` (planned) CarePlans; `--out DIR`; `--config DIR`.

## What gets generated

| Resource | Profile | Count | Role |
|---|---|---|---|
| ActivityDefinition | ICRCampaignActivity | 8 | the product catalogue: nOPV2, MCV, MR, ivermectin ± albendazole, azithromycin, praziquantel + albendazole |
| Group (definitional) | — | 9 | protocol eligibility cohorts (age bands, no count) |
| PlanDefinition | ICRCampaignProtocol | 9 | protocols: nOPV2 SIA, measles catch-up, measles OBR, MR + nOPV2 (± NTD), LF/oncho MDA, oncho CDTI, trachoma MDA, schisto/STH school MDA |
| Group | ICRTargetPopulation | ~2,000 | planning denominators per LGA / state × age band × year |
| CarePlan | ICRCampaign | ~3,000 | national umbrella (multi-state rounds) → state umbrella → **one CarePlan per LGA** |
| MeasureReport | ICRAdministrativeCoverage / ICRSurveyCoverage | ~2,900 | results — see below |

The three CarePlan levels are linked by `partOf`. Every CarePlan carries
`target-geography` (the Location), `campaign-round`, `planning-denominator`,
`period`, and `status`/`intent` derived from the as-of date. LGA CarePlans are
`intent=order`; umbrellas of future rounds are `intent=plan`.

All generated resources carry `meta.tag` **`nga-demo`** (system
`https://icr.healthcampaigns.org/CodeSystem/icr-project-tag-cs`), so the demo
set can be selected or excluded in one query and the Sierra Leone IG examples
stay untouched:

```
CarePlan?_tag=https://icr.healthcampaigns.org/CodeSystem/icr-project-tag-cs|nga-demo
```

## What is real and what is modelled

- **Polio.** nOPV2 outbreak-response rounds and National Immunization Plus Days,
  four days, house-to-house, 0–59 months; two to four rounds a year, with the
  extra rounds in the high-risk north-west/north-east trio (Kano, Jigawa, Yobe),
  as in the 2022–2025 outbreak response. A few LGAs slip a day or two.
- **Measles.** A November 2022 north-east catch-up (9–59 months) in waves; small
  outbreak responses in 2023–2025; the real **6 October 2025 integrated MR +
  nOPV2 campaign** (9 months–14 years, eight days per LGA in three waves, NTD
  co-delivery in Kano and Yobe); a planned October 2027 follow-up.
- **NTDs.** LF/onchocerciasis MDA (ivermectin + albendazole, CDTI) in the dry
  season, LGAs in batches, stopping as LGAs pass TAS (Bauchi 2025 state report,
  Yobe iTAS); onchocerciasis-only CDTI continuing where LF stopped; trachoma
  azithromycin MDA in the published Kano (12 LGAs), Jigawa (Taura, Garki + 10)
  and Yobe (5 LGAs) sets, stopping after impact surveys; schisto/STH school MDA
  in May–June. `config/endemicity.yaml` says, per block, what is published and
  what is our assumption.
- **Population.** 2006 census and 2022 NPC projection per LGA
  (citypopulation.de), interpolated geometrically to the round year, times a
  northern-Nigeria age-band share. Written as `denominator-source =
  census-projection`, `is-calculated = true`. **WorldPop aggregation to LGA
  boundaries is the planned replacement**; only `population.py` changes.

## Results

`06-coverage-reports.ndjson` holds the outcomes as ICR coverage MeasureReports
(`config/results.yaml` is the model):

| Kind | Profile | Per | Count |
|---|---|---|---|
| Administrative coverage, reconciled | ICRAdministrativeCoverage | LGA round (completed) | ~2,170 |
| Administrative coverage, realtime (daily) | ICRAdministrativeCoverage | LGA round (active) | ~120 |
| Post-campaign cluster survey | ICRSurveyCoverage (`survey`) | state round, MR and measles catch-up | 8 |
| LQAS lot | ICRSurveyCoverage (`lqas`) | ~⅓ of polio / MR LGA rounds | ~500 |
| NTD coverage evaluation survey | ICRSurveyCoverage (`survey`) | ~15 % of MDA LGA rounds | ~90 |

The generator does not draw a coverage percentage. Each LGA has a persistent
*denominator error* (how far the census projection is from reality; urban
growth LGAs run high) and a persistent *programme quality*; each round adds
noise and a 5 % chance of an incident. People reached = true population ×
reach, so administrative coverage exceeds 100 % exactly where projections
undercount. Surveys measure reach with recall loss and sampling error and carry
a structured 95 % confidence interval. About 7 % of LGA rounds have no report;
active rounds have daily realtime reports instead of a reconciled one. Scores
are proportions 0–1 (proportion-scored Measures are unit-less). Reports carry
exactly the stratifiers their Measure declares (sex, age band, delivery
strategy, geography, disposition), which the validator checks.

## Endemicity

`07-location-status.ndjson` holds the NTD programme's classification of every
LGA for each of the five PC-NTDs as `ICRLocationStatus` Observations (the
`assertions` block of `config/endemicity.yaml`): one baseline assertion per LGA ×
disease dated to the JRSM 2022 submission — *endemic, under MDA* / *under
post-MDA surveillance* / *non-endemic* / *unknown (mapping required)* for a few
unmapped LGAs — carrying the baseline prevalence figure it rests on as a
component (LF antigenaemia at mapping, onchocerciasis mf prevalence, trachoma TF
in 1–9 year olds, schisto and STH prevalence in school-age children, in the
published ranges for northern Nigeria), the method, and the evidence document.
When an LGA leaves a programme's MDA list a second assertion records the
transition to post-MDA surveillance with the stop-survey result (TAS positives
against the critical cut-off; TF at the impact survey). Statuses derive from the
same year-maps as the campaign schedule, so campaigns and endemicity never
disagree.

## Not yet generated

Tasks and delivery events (Immunization / MedicationAdministration), teams,
supply. The aggregate results exist first — that is how campaign data arrives —
and the individual events can later be reconciled against them.

## Tweaking

- Add or move a round: edit `schedule.yaml` (`rounds` for one-offs, `series` for
  annual programmes). Stagger rules: `none`, `jitter`, `batches`.
- Change which LGAs a programme treats in a year: `endemicity.yaml` `by_year`.
  An empty list stops the programme for that year in that state.
- Change denominators: `states.yaml` populations or `age_bands` fractions.
- Change the "today" line: `--as-of`.

Output is deterministic: same config, same NDJSON.
