# DIGIT demo dashboards

Served at https://dashboards.healthcampaigns.org/digit/ (sign-in: a verified ona.io address
or an admin). The data is eGov's DIGIT Health Campaign Management demo data, which is fake,
transformed to the ICR profiles by the DIGIT mapping (`project/digit.md`) and loaded into the
DIGIT ICR server (https://fhir-digit.healthcampaigns.org/fhir). DIGIT is a demo tenant, not a
country.

- **Overview** (`/`): what the site is; the campaigns (country, type, protocol, period,
  status, target, rounds); households registered, people, visits, people treated and nets
  distributed, in total and by campaign type. A country selector filters all of it.
- **Georegistry** (`/georegistry`): DIGIT's boundary hierarchies with their boundaries by
  level, a searchable table of boundaries that shows each one's parents and children, its
  P-code and whether it has a GRID3 boundary, and a map. DIGIT holds no geometry; only the
  168 Nigerian states and LGAs matched to GRID3 in the ICR's location registry (ADMIN:
  STATE → LGA, NIGERIA: PROVINCE → DISTRICT) carry a boundary, with the P-code, the ICR
  Location id and GRID3's spelling as an alias. The map draws all of Nigeria's GRID3 states
  (37) and LGAs (774) with a light outline and highlights the 138 GRID3 units that DIGIT has
  (both hierarchies can match the same unit) with a grey fill and a darker border. Only
  those can be shaded by dwellings, households registered or visits (all campaigns,
  counted through DIGIT's `partOf` hierarchy). The facilities and dwellings are on top.
- **Campaign calendar** (`/calendar`): one row per campaign with its period in grey and its
  cycle rounds as bars coloured by campaign type, today marked, for a country, a campaign
  type and a date range; hover shows dates, status, type, country, target area, target,
  visits and households registered. It follows the main dashboard's timeline
  (`sites/main/src/index.md`), which is inline Plot code rather than a shared component.
- **Campaign delivery** (`/delivery`): a country, then one campaign of that country, with
  its rounds together or one round: registrations and visits by day; a map of visits (or
  households registered) per Nigerian LGA, with how many are mapped and how many are not;
  visit outcomes and their reasons, doses not given by reason, people treated by activity
  and nets distributed. Campaigns outside Nigeria get a note instead of the map: DIGIT
  holds no geometry, and only Nigeria's units are matched to GRID3.

A campaign's country (`country` in `campaigns.parquet`, used by both pages) comes from the
DIGIT hierarchy of its target area, or of its visits when it has none: NIGERIA and ADMIN
are Nigeria, SIERRALEONE Sierra Leone, DEMOGABON Gabon, and MICROPLAN Chad (its provinces
are Lac, N'Djamena and Ouaddaï). Campaigns with neither are "Unknown".
- **Stock** (`/stock`): stock movements for a country and campaign (every movement names
  its campaign): dispatched, received, and dispatched but not yet received, by product, by
  facility or field worker, by day, and on a map of Nigeria's LGAs (circles per LGA, or per
  state for state stores; facilities placed through DIGIT's `partOf` hierarchy, since almost
  none has coordinates). In the demo data the import paired no dispatch with its receipt
  (no matching waybill), so each movement is one DIGIT record; "not yet received" is a
  dispatch with no receipt of the same sender, receiver, product and quantity, matched one
  to one in date order (`src/data/stock.parquet.sh`). Stock outside Nigeria or with field
  workers is counted below the map.

## Data

The loaders in `src/data/` read the DIGIT warehouse with DuckDB. They share `loaders.sh`,
which finds the warehouse and gives an empty table for a view that has no rows yet, so the
site builds while the server is still being loaded.

The warehouse tables are fhir-pipes runs of ViewDefinitions (`country/digit/fhir-pipes.toml`):

- the IG's views: `campaign_calendar`, `campaign_activity`, `campaign_task`,
  `campaign_task_output`, `target_population` and the coverage
  and indicator views, which are empty for DIGIT;
- the DIGIT views in `country/digit/views/` (written by `make.py` there), for what the IG
  has no views for yet: `digit_location` (every Location, including the boundaries that
  fhir-pipes' `locations` table leaves out because they have no geometry;
  with `pcode`, `icr_location_id`, `alias` and `has_boundary`), `digit_household`, `digit_patient`, `digit_medication_administration`,
  `digit_immunization`, `digit_supply_delivery`, `digit_task_output`, `digit_campaign_period`, `digit_activity` and
  `digit_protocol`.

The boundary polygons (`src/data/admin.geojson.sh`, about 1.1 MB, 0.3 MB compressed) are
the warehouse's `grid3_nga` table: the main warehouse's GRID3 states and LGAs for Nigeria,
which `warehouse.sh` copies in from `r2:icr/parquet/locations/country=NGA/...` after each
refresh. A unit is in DIGIT when a DIGIT Location carries its `icr-location` identifier
(`digit_location.icr_location_id`). The pages use only these tables, not SQL on FHIR Libraries.

## Refresh and build

```bash
country/digit/warehouse.sh --push              # (repo root) DIGIT server → r2:icr/digit/
cd dashboards && npx observatory deploy digit  # R2 warehouse → build → /digit/
```

For a preview, `npx observatory dev digit` (data from the cached R2 warehouse), or with
`--local` from `country/digit/warehouse/` (run `warehouse.sh` first).

`warehouse.sh` takes the IG's views from `ig/fsh-generated/resources` (run `sushi build .` in
`ig/` first), or from `$IG_VIEWS`.
The delivery page counts people treated from the delivery events, because the DIGIT import
records each dose as an event; it writes per-activity tallies (`treated-count`) on only some
tasks, and the page shows their totals beside the events.

DIGIT's demo server keeps time in India Standard Time (a campaign starting on 28 October has
`period.start` 2026-10-27T18:30:00Z), so the pages and loaders show days in that zone.
