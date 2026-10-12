---
title: Microplanning + monitoring dashboard (Toro LGA)
status: built
created: 2026-09-08
last_modified: 2026-09-09T21:30:00Z
tags: [campaignhq, microplanning, polio, toro, synthetic-data]
---

# Microplanning dashboard — Toro LGA, Bauchi

<sub>`Built · Sep 9, 2026 · tools/microplan-builder + campaignhq/src/microplan.md`</sub>

> [!note] Where this stands (Sep 9, 2026)
> **Built, not deployed.** Matt's answers on Sep 9 settled the questions below and the
> design moved on from the Sep 8 survey because the registry gained real
> **facility and settlement catchments** for Toro that morning ([[toro-catchments]],
> `tools/catchments/`):
> - each facility is a campaign: one facility-level `ICRCampaign` per catchment, `partOf`
>   an LGA round (**National Immunization Plus Days (NIPDs), round 2, Sep 7–11 2026**);
>   pollution of the calendar accepted;
> - one house-to-house `ICRCampaignTask` per settlement, tally on `Task.output`; snapshot
>   at day 3, ~60 % completed; failed visits are **access** problems, never insecurity;
> - under-5 denominators are real: WorldPop 2026 per settlement catchment (kiln) × Toro's
>   under-5 share, persisted as `ICRTargetPopulation` Groups;
> - **no** fixed-post facility tally, **no** coverage MeasureReport (coverage lives on the
>   microplan page only); care teams generated, one per facility.
>
> Generator: `tools/microplan-builder/build.py` (README there). IG: `IcrCampaignTask`
> ViewDefinition + `nga-microplan-demo` project tag. Page: `/microplan`, titled
> "Microplan — National Immunization Plus Days (NIPDs), Toro LGA". Built with
> `npm run build`; deploy waits for a go-ahead. The survey and questions below are kept
> as the record of the decision.

## The ask (verbatim intent)

- LGA-level microplanning dashboard, Toro LGA only for now.
- Polio campaign that goes to **every settlement**; **tally-based, one Task per community**.
- Show population per settlement (make it up if needed), using the **settlement list
  and health facilities from the registry Locations**. Facilities = outreach points.
- List tasks per community, which are complete vs pending.
- Show coverage results: kids vaccinated vs estimated population per settlement,
  as a **table and a map**.
- Matt is unsure how to handle microplanning bleeding into monitoring; wants a view.

## Survey findings (Sep 8, 2026)

### campaignhq stack

- Observable Framework 1.13 static site, DuckDB-WASM over parquet, MapLibre GL 5 +
  PMTiles. No runtime FHIR calls; every page declares `sql:` frontmatter over
  `src/data/*.parquet`, built by shell loaders that run `duckdb` against the data hub
  at `data/parquet/**` and `data/tiles/*.pmtiles`.
- Routing is the explicit `pages` array in `campaignhq/observablehq.config.js`; a new
  page = `src/<name>.md` + a `pages` entry. No parameterized routes, so an LGA page is
  a fixed path with a selector.
- Existing pages: `/` calendar, `/coverage`, `/targeting`, `/ntd`, `/georegistry`.
- Map helpers: `src/components/map.js` (`campaignMap`, feature-state keyed on FHIR
  Location id via `promoteId`), `src/components/georegistry-map.js` (admin +
  facilities + settlements layers; settlements gated to z8+),
  `src/components/filters.js` (cascading selects).
- Tiles built by `tools/warehouse/tiles.sh` (tippecanoe). Warehouse refresh is
  `tools/warehouse/refresh.sh` (kiln for Locations, `octofhir-sof` for each IG
  ViewDefinition, partitioned by country). Adding a ViewDefinition to the IG makes a
  new `data/parquet/<name>/` folder appear automatically.
- Deploy is `campaignhq/deploy.sh` → Cloudflare R2/Worker at
  dashboards.healthcampaigns.org. Do **not** deploy after every edit; batch and wait
  for an explicit go-ahead (see memory note on deploy cadence).

### IG pieces that already fit (`ig/input/fsh/`)

- `ICRCampaign` (CarePlan) is the microplan: `instantiatesCanonical`, `subject` →
  `ICRTargetPopulation`, `period`, extensions `targetGeography`, `planningDenominator`,
  `campaignRound`. Doctrine: **one CarePlan per reporting scope; sub-units ride the
  Location hierarchy, not child CarePlans.** So settlement work hangs off Tasks, not
  child CarePlans.
- `ICRCampaignTask` (Task, `profiles-campaign.fsh` ~L87): required `code`, `basedOn`
  → ICRCampaign, `for 1..1` → ICRDeliveryUnit | ICRLocation | Patient, `location 1..1`,
  extensions `deliveryStrategy 1..1`, `taskOrigin 1..1` (pre-planned |
  field-registered), optional `dataLineage`. **Tallies are `Task.output` slices**:
  `treatedCount`, `housesVisited`, `eligiblePresent`, `eligibleAbsent`,
  `childrenAlreadyMarked` (unsignedInt) plus `missedReason`, `noncomplianceReason`,
  `exclusionReason`, `revisitOutcome` (CodeableConcept). Status uses base FHIR Task
  codes (requested → in-progress → completed | failed).
- `ICRTargetPopulation` (Group): `quantity`, `characteristic[geography]` → Location,
  `denominatorSource 1..1` (includes `worldpop`, `grid3`), `isPlanningDenominator`.
- `ICRLocation`: types `admin-unit | settlement | facility | school |
  community-distribution-point | temporary-post | household | supervisory-area |
  operational-area`. Delivery strategies: `fixed-post, temporary-post, mobile, school,
  house-to-house, community-directed, outreach`.
- `ICRAdministrativeCoverage` (MeasureReport) for roll-ups; the `/coverage` page reads
  the `IcrCoverage` view.
- Task examples in `examples.fsh`: `example-site-session-task`, `example-mopup-task`,
  `example-mda-community-task`, `example-followup-task` (good templates).
- **Gap:** no Task ViewDefinition exists (`viewdefinitions.fsh` has calendar,
  target population, coverage, coverage strata, location status only). Needs a new
  `IcrCampaignTask` view.

### Data on the local HAPI (`http://localhost:3447/fhir`, see `tools/hapi/README.md`)

| Item | Value |
|---|---|
| Toro LGA Location | `nga-ba-5018` (national-admin-code `5018`), partOf `Location/nga-ba`, boundary polygon in the GeoJSON extension, no `position` |
| Direct children | 2,510 |
| Settlements | **2,347**, all with `position`, all with quadkey-18 `spatial-index`; `settlementType` null on all |
| Health facilities | **163**, all with `position`; 102 have an NHFR code on the paired Organization (`org-<globalid>`) |
| Wards | **0** — the registry hierarchy is country → state → LGA; settlements and facilities attach directly to the LGA |
| Toro campaign rounds already in the calendar | 26 CarePlans with `location_id = nga-ba-5018` (synthetic, from `tools/campaign-builder`, tag `nga-demo`) |
| Tasks on server | 6 (IG examples only). Immunization 1, MedicationAdministration 1 |

Sample settlements: `3bf6ac13-5fc1-43f5-ab7c-06292741e777` "Wundi East",
`e61ceba2-c198-4b8f-ac93-8bad7b20c2f2` "Rugar Alhaji Jimo". Sample facilities:
`b26a2529-5070-4277-81de-686ebe50f44b` "Toro General Hospital" (secondary/public),
`878f91e1-8bc4-4042-8df5-41fde2c9ae7d` "Lau Primary Health Clinic" (primary/public).

**Settlement-level population does not exist anywhere locally.** Every
`ICRTargetPopulation` is at admin-unit level. Toro 2026 LGA totals: census-projection
714,152; WorldPop 553,764; children 0–59 months 132,118; school-age 5–14 214,246.
Any settlement denominator must be newly derived. Related: [[kiln-population-plan]]
(WorldPop → Groups in kiln, pixel-centroid rule) could be extended with Voronoi
polygons per settlement point if we want real numbers later.

Location type coding: `type[0].coding.system =
https://icr.healthcampaigns.org/CodeSystem/icr-location-type`, codes `admin-unit` /
`settlement` / `facility`; facilities also carry `icr-facility-type-cs`
(primary/secondary/tertiary) and `icr-ownership-cs`. HAPI 8 has no `:above`/`:below`.

## Open questions (with recommended answers)

Matt has not answered these yet. Where he doesn't, take the recommendation.

1. **Scale and grouping.** 2,347 settlements is a lot of rows and Tasks. Real Nigerian
   microplans group by ward; registry has none. *Recommend:* assign each settlement to
   its nearest facility → "outreach catchment" (could be an `operational-area`
   Location), table is facility-level with expand-to-settlements. Alternative: flat
   settlement table with search/filters.
2. **Settlement denominators.** *Recommend:* apportion the LGA under-5 total across
   settlements with a skewed (log-normal) random distribution now, but persist as
   one `ICRTargetPopulation` Group per settlement (`denominatorSource=worldpop`,
   `isPlanningDenominator=true`) so numbers can be swapped for real WorldPop zonal
   stats later without touching the dashboard.
3. **Which campaign.** *Recommend:* attach to one existing 2026 nOPV2 Toro round
   CarePlan from the calendar so `/` and `/coverage` link through; Tasks `basedOn`
   that LGA-level CarePlan (IG doctrine). Alternative: fresh dedicated round.
4. **Snapshot moment.** *Recommend:* 4-day round frozen at end of day 3: ~70%
   completed, some in-progress, rest requested, a few `failed` (inaccessible /
   security, realistic for Bauchi). Alternative: finished round + mop-up tasks with
   coverage as the headline.
5. **Task granularity.** *Recommend:* one Task per settlement per round (single
   tally), `executionPeriod` = scheduled day; generate revisit tasks for settlements
   under 80%; add a handful of `field-registered` Tasks for settlements "found" that
   aren't in the registry (the microplan-completeness story the IG was designed for).
   Alternative: one Task per settlement per day.
6. **Outreach point semantics.** *Recommend both:* each facility gets one `fixed-post`
   Task with its own tally; each settlement Task is `house-to-house` with the facility
   as the responsible site. Optionally generate CareTeams (vaccination teams +
   supervisor per facility) as `Task.owner` so the plan shows team counts/workload.
7. **Coverage numerator.** *Recommend both:* tallies live on Task outputs; also emit
   one `ICRAdministrativeCoverage` MeasureReport at LGA level so the coverage page
   picks it up.
8. **Microplan vs monitoring.** *Recommend one page, not two.* They are the same Task
   list at two points in time. KPI strip: planning on the left (settlements, planned,
   unplanned, target under-5, teams) and monitoring on the right (completed, pending,
   vaccinated, coverage). Map metric toggle: plan status / task status / coverage.
   Table carries both column sets. Add missed-reason breakdown (absent, refusal,
   inaccessible). Alternative: separate Plan and Progress tabs.
9. **Plumbing.** *Recommend:* new `tools/microplan-builder` beside campaign-builder;
   load to HAPI with its own tag (e.g. `nga-microplan-demo`) so it's deletable; new
   `IcrCampaignTask` ViewDefinition in `ig/input/fsh/viewdefinitions.fsh`; parquet via
   `tools/warehouse/refresh.sh`; page at `campaignhq/src/microplan.md` route
   `/microplan` with an LGA selector locked to Toro.

## Build plan (once questions are settled)

1. **Generator** (`tools/microplan-builder`): pull Toro settlements + facilities from
   HAPI; nearest-facility assignment; synthetic under-5 per settlement → Groups;
   Tasks per settlement (+ per facility) with strategy/origin/status/outputs
   distributed per the snapshot; optional CareTeams; LGA MeasureReport. Emit a
   transaction Bundle, load with `tools/hapi/load.py`, tag everything.
2. **IG**: add `IcrCampaignTask` ViewDefinition (columns: task id, status, code,
   strategy, origin, based_on campaign id, for location id, location id, owner,
   execution start/end, each tally output, missed reason). Rebuild IG if examples
   change.
3. **Warehouse**: run `refresh.sh`, confirm `data/parquet/campaign_task/` appears;
   settlement/facility geometry already exists in `locations` parquet and the
   settlements/facilities PMTiles.
4. **Dashboard**: `campaignhq/src/data/microplan.parquet.sh` joining tasks × groups ×
   locations for Toro; `src/microplan.md` with KPI strip, map (settlement circles
   coloured by metric, facility markers, LGA boundary from admin tiles), table.
   Follow the dataviz skill for palette consistency (YlGnBu is the coverage ramp
   used elsewhere).
5. Add to `pages` in `observablehq.config.js`, preview with `npm run dev`, batch
   deploy only on go-ahead.

## Related

- [[icr-v1]] — design doc
- [[icr-ig]] — IG notes
- Memory notes: nigeria registry load (Sep 6), campaign calendar (Sep 7), targeting
  dashboard (Sep 8), kiln population plan (Sep 8)
- `tools/campaign-builder/README.md` — pattern to copy for the generator
- `tools/hapi/README.md` — server, load recipes, working search URLs
