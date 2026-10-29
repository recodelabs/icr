# DIGIT demo dashboards

Served at https://dashboards.healthcampaigns.org/digit/ (sign-in: a verified ona.io address
or an admin). The data is eGov's DIGIT Health Campaign Management demo data, which is fake,
transformed to the ICR profiles by the DIGIT mapping (`project/digit.md`) and loaded into the
DIGIT ICR server (https://fhir-digit.healthcampaigns.org/fhir). DIGIT is a demo tenant, not a
country.

- **Overview** (`/`): what the site is; the campaigns (type, protocol, period, status,
  target, rounds); households registered, people, visits, people treated and nets
  distributed, in total and by campaign type.
- **Georegistry** (`/georegistry`): DIGIT's boundary hierarchies with their boundaries by
  level, a searchable table of boundaries that shows each one's parents and children, its
  P-code and whether it has a GRID3 boundary, and a map. DIGIT holds no geometry; only the
  168 Nigerian states and LGAs matched to GRID3 in the ICR's location registry (ADMIN:
  STATE → LGA, NIGERIA: PROVINCE → DISTRICT) carry a boundary, with the P-code, the ICR
  Location id and GRID3's spelling as an alias. The map draws those boundaries for one
  hierarchy at a time, can shade the LGAs by dwellings, households registered or visits
  (all campaigns, counted through DIGIT's `partOf` hierarchy), and puts the facilities and
  dwellings on top.
- **Campaign delivery** (`/delivery`): for one campaign, with its rounds together or one
  round: registrations and visits by day, visit outcomes and their reasons, doses not
  given by reason, people treated by activity and nets distributed.
- **Stock** (`/stock`): stock movements by product and by facility or team, dispatched
  against received, and by day.

## Data

The loaders in `src/data/` read the DIGIT warehouse with DuckDB. They share `loaders.sh`,
which finds the warehouse and gives an empty table for a view that has no rows yet, so the
site builds while the server is still being loaded.

The warehouse tables are fhir-pipes runs of ViewDefinitions (`country/digit/fhir-pipes.toml`):

- the IG's views: `campaign_calendar`, `campaign_activity`, `campaign_task`,
  `campaign_task_output` (from PR #224, see below), `target_population` and the coverage
  and indicator views, which are empty for DIGIT;
- the DIGIT views in `country/digit/views/` (written by `make.py` there), for what the IG
  has no views for yet: `digit_location` (every Location, including the boundaries that
  fhir-pipes' `locations` table leaves out because they have no geometry;
  with `pcode`, `icr_location_id`, `alias` and `has_boundary`), `digit_household`, `digit_patient`, `digit_medication_administration`,
  `digit_immunization`, `digit_supply_delivery`, `digit_task_output`, `digit_campaign_period`, `digit_activity` and
  `digit_protocol`.

The boundary polygons (`src/data/admin.geojson.sh`) come from fhir-pipes' `locations`
table, which holds the 168 GRID3 polygons (`geom_type=polygon`) beside the dwellings and
facilities. The pages use only these tables, not SQL on FHIR Libraries.

## Refresh and build

```bash
country/digit/warehouse.sh --push              # (repo root) DIGIT server → r2:icr/digit/
cd dashboards && npx observatory deploy digit  # R2 warehouse → build → /digit/
```

For a preview, `npx observatory dev digit` (data from the cached R2 warehouse), or with
`--local` from `country/digit/warehouse/` (run `warehouse.sh` first).

`warehouse.sh` takes the IG's views from `$IG_VIEWS`. Until PR #224 (`ig/digit-additions`,
which adds `IcrCampaignTaskOutput`) is merged, it uses that branch's build in its worktree
(`.claude/worktrees/agent-ae0f8141a1de285a3/ig/fsh-generated/resources`) when it exists;
after the merge, rebuild the IG on `main` and it falls back to `ig/fsh-generated/resources`.
The delivery page counts people treated from the delivery events, because the DIGIT import
records each dose as an event; it writes per-activity tallies (`treated-count`) on only some
tasks, and the page shows their totals beside the events.

DIGIT's demo server keeps time in India Standard Time (a campaign starting on 28 October has
`period.start` 2026-10-27T18:30:00Z), so the pages and loaders show days in that zone.
