# CampaignHQ

The ICR campaign calendar dashboard: an [Observable Framework](https://observablehq.com/framework/)
site that runs **DuckDB (WebAssembly) in the browser** over parquet files and draws the
map with **MapLibre** from a **PMTiles** archive. It builds to plain static files —
nothing talks to a server at runtime — because every input is generated ahead of time
from the FHIR registry into the repo's analytics hub, `data/`.

```
data/parquet/campaign_calendar/   ─┐
data/parquet/target_population/    ├─ src/data/campaigns.parquet.sh   (duckdb join at build time)
data/parquet/locations/           ─┘   src/data/admin_units.parquet.sh
data/tiles/admin.pmtiles          ──▶ src/data/admin.pmtiles.sh
data/manifest.json                ──▶ src/data/manifest.json.sh
```

## Run

```bash
tools/warehouse/refresh.sh      # (repo root) regenerate data/ from the FHIR server, incl. tiles
cd campaignhq
npm install
npm run dev                     # preview at http://127.0.0.1:3000
npm run build                   # static site in dist/
```

The data loaders in `src/data/` need `duckdb` on the PATH; they run at build (and
preview) time and their output is cached under `src/.observablehq/cache`.

## What is on the page

- **Filters** — year, state, programme, status. Everything below reacts.
- **KPIs** — LGA-level campaign rounds, LGAs covered, people targeted (sum of the
  campaigns' planning denominators), people reached (blank until delivery events are
  loaded).
- **Two synced maps** — LGA choropleths of campaign rounds (left) and people
  targeted (right) in the selection; pan or zoom one and the other follows. Hover
  for the LGA's count and people targeted. The targeted ramp rescales to the
  selection. Boundaries come from `admin.pmtiles` (layers `states`, `lgas`;
  `promoteId: id` so feature-state is keyed by the registry Location id).
- **Timeline** — toggle between *By state* (one lane per state, one bar per state
  round coloured by programme; overlaps are two programmes in the same state at the
  same time) and *By LGA* (one lane per LGA, grouped into a collapsible section per
  state, all sharing one time axis). Red dotted line is today.
- **Table** — searchable, sortable LGA rounds.

## Basemap

`BASEMAP` at the top of `src/index.md` is the one setting. It accepts a raster XYZ
layer (`{tiles: [...], attribution}`), a MapLibre style URL, or `false` for
boundaries only. The default is OpenStreetMap as a placeholder.

## Adding data

New columns: extend the ViewDefinitions in the IG (`ig/input/fsh/viewdefinitions.fsh`),
run the refresh, then add the join in `src/data/campaigns.parquet.sh`. New tables
(e.g. delivery events for "people reached"): a new ViewDefinition becomes a new
folder under `data/parquet/` automatically; add a loader here and query it with
`sql`.
