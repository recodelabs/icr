# microplan-builder — Toro LGA NIPDs microplan + monitoring snapshot

Generates a **synthetic polio microplan frozen part-way through a round** for Toro LGA,
Bauchi State, on top of what the registry really holds: the health facilities, their
catchments (`tools/catchments`), the settlements assigned to each catchment, and the
WorldPop 2026 total per settlement catchment (`kiln population`). It feeds the Campaign
Dashboards **Microplan** page (`campaignhq/src/microplan.md`).

The round: **National Immunization Plus Days (NIPDs), round 2, September 7–11 2026**,
nOPV2, house-to-house to every settlement, snapshot at the end of day 3 (Sep 9): about
60 % of visits completed.

## What it writes (`out/`, git-ignored; load order)

| File | Profile | Count | What |
| --- | --- | --- | --- |
| `01-groups.ndjson` | ICRTargetPopulation | 2,237 | children 0–59 months per settlement catchment (`u5-worldpop-2026-<settlement id>`: WorldPop 2026 catchment total × 0.185, Toro's under-5 share from the NPC 2022 projection) and per facility catchment (`u5-worldpop-2026-catchment-<facility id>`, the sum); age-band 0–59 mo, `at-risk`, planning denominator, calculated |
| `02-careteams.ndjson` | ICRCareTeam | 159 | one vaccination team per facility (2 vaccinators, a recorder, a supervisor; managing Organization = the facility's), oversees-area and workload-target = its catchment |
| `03-careplans.ndjson` | ICRCampaign | 160 | the LGA round (`nga-microplan-polio-2026-r2-ba-5018`, target geography Toro, subject the existing Toro under-5 denominator) and one facility-level campaign per catchment (`mp-polio-2026-r2-<facility id>`, `partOf` the round, target geography the catchment) |
| `04-tasks.ndjson` | ICRCampaignTask | 2,102 | one house-to-house visit per settlement (`mp-task-2026-r2-<settlement id>`): `basedOn` the facility campaign, `for` / `location` the settlement, `owner` the team, planned day, status as of the snapshot, tally outputs on completed visits |
| `tasks.csv`, `report.md` | | | the snapshot at a glance |

Everything carries `meta.tag` `nga-microplan-demo` (ICRProjectTagCS), so the set can be
listed or deleted in one query.

### Snapshot rules

- Each facility's settlements are ordered by distance and split over the five days
  (22 / 22 / 22 / 17 / 17 %). Days before the snapshot: completed. Snapshot day: 75 %
  completed, 22 % in progress, 3 % pending. Later days: pending. No failed visits: access is
  not a challenge in Toro (Matt).
- Completed tallies: children present ≈ target × N(0.93, 0.11), absent 2–10 % of present, a
  few refusals / sick / asleep, treated = present − those; houses ≈ WorldPop ÷ 6. Coverage
  lands mostly 80–100 % with a tail below 80 % (revisit candidates).
- 15 of the 260 Toro settlements that have no catchment are registered **in the field**
  (`task-origin = field-registered`, completed, no target) — the microplan-completeness story.
- No fixed-post facility tally and no coverage MeasureReport: coverage lives on the
  microplan page only (Matt, Sep 9 2026).

## Run

```bash
python3 tools/microplan-builder/build.py            # --as-of 2026-09-09 --seed 42 --out tools/microplan-builder/out
for f in 01-groups 02-careteams 03-careplans 04-tasks; do python3 tools/hapi/load.py ndjson tools/microplan-builder/out/$f.ndjson; done
tools/warehouse/refresh.sh --views                  # → data/parquet/campaign_task (IcrCampaignTask view) + target_population
cd campaignhq && npm run build                      # src/data/microplan.parquet.sh joins tasks × settlements × facilities × denominators
```

Needs `duckdb` on the PATH (it reads `data/parquet`, so run the warehouse refresh after
loading catchments and WorldPop Groups first). Re-running is idempotent (PUT by id).

Wipe: `curl -X DELETE 'localhost:3447/fhir/Task?_tag=nga-microplan-demo'` and likewise for
`CarePlan`, `CareTeam`, `Group` (HAPI has multiple-delete enabled).
