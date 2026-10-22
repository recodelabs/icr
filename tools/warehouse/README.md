# Updating the warehouse and the dashboards

This is the runbook for getting data from the ICR's FHIR servers into the warehouse and
from the warehouse onto the dashboards. Updates are run by hand for now, because the data
changes rarely. Run them after anything on a FHIR server changes, such as a reload of
targets, campaigns or results.

## How the data flows

```
FHIR servers ──fhir-pipes refresh──▶ warehouse on this machine ──push──▶ warehouse in R2 (private)
                                                                           │
                                       dashboards ◀──deploy.sh pulls it, builds, uploads──┤
                                       SDI (public: locations and tiles only) ◀───────────┤
                                       DuckDB users (catalog.sql) ◀───────────────────────┘
```

The warehouse in R2 is the one source that the dashboards, the SDI and anyone querying
with DuckDB share. An update always goes through it in two steps:

1. **Refresh and push a warehouse.** fhir-pipes reads a FHIR server, runs the IG's
   ViewDefinitions into parquet tables and builds map tiles, then the push copies the
   result to R2.
2. **Redeploy the dashboards.** `campaignhq/deploy.sh` pulls the warehouse from R2,
   builds each site from it, and uploads the build.

The dashboards do not query the warehouse while people browse. At build time, Observable
Framework runs each site's data loaders (`src/data/*.sh`) over the warehouse and puts
small files shaped for the pages into the build. New data therefore shows only after a
redeploy.

## The pieces

| Piece | Source | Local copy | In R2 (`icr` bucket) | Public address |
|---|---|---|---|---|
| Main warehouse (Nigeria demo, Sierra Leone demo, IG examples) | `hapi.healthcampaigns.org` | `data/` | the bucket root (`parquet/`, `tiles/`, `catalog.sql` …) | none |
| Uganda warehouse | `fhir-uga.healthcampaigns.org` | `country/uganda/warehouse/` | `uga/` | none |
| Main dashboards | main warehouse | `campaignhq/` | `_site/campaignhq/` | https://dashboards.healthcampaigns.org |
| Uganda dashboards | Uganda warehouse | `campaignhq/uganda/` | `_site/campaignhq/ug/` | https://dashboards.healthcampaigns.org/ug/ |
| Sierra Leone dashboards | local `data/` only | `campaignhq/sldash/`, `campaignhq/sl-redux/` | `_site/campaignhq/dhis2-sl*/` | `/dhis2-sl/`, `/dhis2-sl-redux/` |
| SDI | both warehouses | | the same folders | https://sdi.healthcampaigns.org (main), `/uga/` |

The SDI Worker (`tools/sdi`) serves only the location collections, tiles and catalog files.
The campaign tables in the same folders return 404 and stay private.

## Update the main warehouse

```bash
FHIR_BASE=https://hapi.healthcampaigns.org/fhir SERVER_NAME=hapi-gcp \
  tools/warehouse/refresh.sh --push
```

- `refresh.sh` runs `fhir-pipes refresh` with `tools/warehouse/fhir-pipes.toml`, in this
  order: locations, views, tiles, manifest, the catalog hook, then the push.
- Set `FHIR_BASE` and `SERVER_NAME` as above. The config's default server is a local HAPI
  (`localhost:3447`).
- **Incremental by default:** only what changed is downloaded. Add `--full` after records
  were deleted on the server. A full run takes about 30 minutes, nearly all of it spent
  extracting the 350,000 locations, and prints no progress while it does.
- **Narrower runs:** `--views` (seconds) and `--tiles` refresh only that part.
- **Push only, without refreshing:**
  `fhir-pipes refresh --config tools/warehouse/fhir-pipes.toml --data data --server https://hapi.healthcampaigns.org/fhir --server-name hapi-gcp --only push`.
  Add `--dry-run` to see what it would copy and delete.

## Update the Uganda warehouse

```bash
country/uganda/warehouse.sh --push
```

- **What it does:** runs `fhir-pipes refresh` with `country/uganda/fhir-pipes.toml`
  (locations, views, tiles and the catalog hook), then uploads `warehouse/` to `r2:icr/uga/`
  with rclone. It takes about 30 seconds.
- **Why rclone:** fhir-pipes can only push to the root of a bucket.
- **API key:** read from `~/.config/icr/uga-matt.env`, or another file given in `KEY_FILE`.

## Redeploy the dashboards

```bash
cd campaignhq && ./deploy.sh main uganda
```

- **What it does, for each site:**
  1. Pulls the site's warehouse from R2 into `~/.cache/campaignhq-warehouse/`.
  2. Sets `DATA` for the loaders.
  3. Clears Framework's cached loader outputs.
  4. Builds, then uploads the build to R2.

  The Worker is redeployed last.
- **Options:**
  - `--dry-run` builds and shows what would change, without uploading.
  - `--local-data` builds from the local copies instead of R2.
- **Deploy `main` and `uganda` together**, from a branch whose `deploy.sh` lists `uganda`
  in `SUBSITES`. The main site's upload deletes every folder under `_site/campaignhq/`
  that isn't listed there, so deploying `main` from an older branch would delete `/ug/`.
- **The Sierra Leone sites** (`./deploy.sh sldash sl-redux`) are static. They always build
  from the local `data/`, because they read the raw Location download, which isn't pushed.
  Redeploy them only when they change.

## Check the result

```bash
rclone cat r2:icr/manifest.json | python3 -c "import json,sys; print(json.load(sys.stdin)['refreshed_at'])"
rclone cat r2:icr/uga/manifest.json | python3 -c "import json,sys; print(json.load(sys.stdin)['refreshed_at'])"
for p in "" coverage ug/ ug/plan dhis2-sl/; do curl -s -o /dev/null -w "%{http_code} /$p\n" https://dashboards.healthcampaigns.org/$p; done
curl -s -o /dev/null -w "%{http_code}\n" https://sdi.healthcampaigns.org/uga/parquet/campaign_activity/country=UGA/part-0.parquet  # must be 404
```

Then open the pages in a browser and check that the figures changed as expected. A page
can respond with 200 and still fail in its DuckDB queries.

## What the tools need

- **fhir-pipes** 0.6 or later (ohs-foundation/fhir-pipes-rs), at `~/.local/bin/fhir-pipes`.
- **duckdb** (2.0, with the spatial extension), **tippecanoe**, and **portolan** for the
  catalog hook.
- **rclone** with the `r2` remote for the `icr` bucket.
- **wrangler** with a login on the Cloudflare account, and Node 22 or later. `deploy.sh`
  falls back to Homebrew's node if the default is older.
- **The IG built:** run `sushi build .` in `ig/`. The views are read from
  `ig/fsh-generated/resources`.
- **API keys:** the Uganda key in `~/.config/icr/uga-matt.env`. The main server is read
  through its open address for now.
- **The Uganda dashboards' npm packages:** run `npm install` in `campaignhq/uganda/`; the
  main site and the Sierra Leone sites each have their own.

## Pitfalls

- **DuckDB 2.0's agent mode.** When `AI_AGENT` is set (as in an AI coding session), DuckDB
  prints an "agent mode" banner on stdout. That corrupts the parquet that data loaders
  write to stdout. `deploy.sh`, `refresh.sh` and `warehouse.sh` set `DUCKDB_AGENT_MODE=0`.
  Set it yourself for `npm run dev`, or anything else that runs the loaders.
- **Stale dashboard data.** Framework keeps a loader's output until the loader file
  changes. `deploy.sh` clears that cache. A dev server (`npm run dev`) doesn't, so delete
  `src/.observablehq/cache/data` to see new data.
- **The DuckDB engine in a dev server.** `duckdb-wasm2.sh` swaps in DuckDB 2.0, and
  `npm install` or `npm run clean` undo it. If a dev server can't fetch
  `duckdb-base.wasm`, run `./duckdb-wasm2.sh <site>` and restart the server.
- **Portolan metadata beside the data.** Warehouse folders hold Portolan files
  (`items.parquet`, `collection.json`) next to the tables. Read tables with globs that
  start at `country=*/`, as `data/catalog.sql` and the loaders do.
- **Lock file.** `.refresh.lock` in a warehouse folder is fhir-pipes' run lock: a run holds
  an operating-system lock on it, so two refreshes of one warehouse take turns, and the lock
  ends with the process. The empty file stays by design and never blocks a later run.
  `.gitignore` keeps it out of git.
- **What is public.** The dashboards are public, including the Ministry of Health's ICHD
  targets on `/ug/`; a login is planned. The SDI is public by design. The warehouses in R2
  are private: the bucket has no public URL. The main FHIR server's open address
  (`hapi.healthcampaigns.org`) is unprotected for now.
- **Secrets.** Never print or commit the API keys, the rclone config or the Cloudflare
  credentials.

## Known issues to raise with fhir-pipes

- Tile layers are named `states` and `lgas` for every country, so Uganda's regions and
  districts get those names (`src/warehouse/tiles.rs`).
- Date-only values such as `executionPeriod.start` are written as UTC-midnight timestamps,
  so they show the previous day west of UTC.
- A full location extract shows no progress.
- The location GeoParquet leaves out locations without coordinates. This is why the Sierra
  Leone sites read `raw/`.
- The push can only target the root of a bucket.
