# Updating the warehouse and the dashboards

This is the runbook for getting data from the ICR's FHIR servers into the warehouse and
from the warehouse onto the dashboards. Updates are run by hand for now, because the data
changes rarely. Run them after anything on a FHIR server changes, such as a reload of
targets, campaigns or results.

## How the data flows

```
FHIR servers ──fhir-pipes refresh──▶ warehouse on this machine ──push──▶ warehouse in R2 (private)
                                                                           │
                                       dashboards ◀──observatory deploy pulls it, builds, uploads──┤
                                       SDI (public: locations and tiles only) ◀───────────┤
                                       DuckDB users (catalog.sql) ◀───────────────────────┘
```

The warehouse in R2 is the one source that the dashboards, the SDI and anyone querying
with DuckDB share. An update always goes through it in two steps:

1. **Refresh and push a warehouse.** fhir-pipes reads a FHIR server, runs the IG's
   ViewDefinitions into parquet tables and builds map tiles, then the push copies the
   result to R2.
2. **Redeploy the dashboards.** `observatory deploy`, run in `dashboards/`, pulls the
   warehouse from R2, builds each site from it, and uploads the build. Observatory
   (recodelabs/observatory, on npm as `@recodelabs/observatory-cli`) is the dashboards'
   build and deploy tool.

The dashboards do not query the warehouse while people browse. At build time, Observable
Framework runs each site's data loaders (`src/data/*.sh`) over the warehouse and puts
small files shaped for the pages into the build. New data therefore shows only after a
redeploy.

Most of the main and Uganda dashboards' SQL is not in the loaders. It is in SQL on FHIR
Libraries in each site's `analytics/` folder (`<name>.sql` with a `<name>.toml` beside it):
SQLViews, which other Libraries read, and SQLQueries, whose results the refresh writes to
the warehouse as tables (`MainCampaigns` becomes `parquet/main_campaigns/`). The loaders
that use them only copy those tables. A change to a Library's SQL therefore needs a
refresh (`--libraries` is enough) before the redeploy. The main site shares the generic
`Icr…ByArea` SQLViews with Uganda's: `dashboards/sites/main/analytics/` links to the files
in `dashboards/sites/uganda/analytics/`.

## The pieces

| Piece | Source | Local copy | In R2 (`icr` bucket) | Public address |
|---|---|---|---|---|
| Main warehouse (Nigeria demo, Sierra Leone demo, IG examples) | `hapi.healthcampaigns.org` | `data/` | the bucket root (`parquet/`, `tiles/`, `catalog.sql` …) | none |
| Uganda warehouse | `fhir-uga.healthcampaigns.org` | `country/uganda/warehouse/` | `uga/` | none |
| DIGIT demo warehouse | `fhir-digit.healthcampaigns.org` | `country/digit/warehouse/` | `digit/` | none |
| Main dashboards | main warehouse | `dashboards/sites/main/` | `_site/campaignhq/` | https://dashboards.healthcampaigns.org |
| Uganda dashboards | Uganda warehouse | `dashboards/sites/uganda/` | `_site/campaignhq/ug/` | https://dashboards.healthcampaigns.org/ug/ |
| DIGIT demo dashboards | DIGIT demo warehouse | `dashboards/sites/digit/` | `_site/campaignhq/digit/` | https://dashboards.healthcampaigns.org/digit/ |
| Sierra Leone dashboards | local `data/` only | `dashboards/sites/sldash/`, `dashboards/sites/sl-redux/` | `_site/campaignhq/dhis2-sl*/` | `/dhis2-sl/`, `/dhis2-sl-redux/` |
| SDI | both warehouses | | the same folders | https://sdi.healthcampaigns.org (main), `/uga/` |

The SDI Worker (`tools/sdi`) serves only the location collections, tiles and catalog files.
The campaign tables in the same folders return 404 and stay private.

## Update the main warehouse

```bash
FHIR_BASE=https://hapi.healthcampaigns.org/fhir SERVER_NAME=hapi-gcp \
  tools/warehouse/refresh.sh --push
```

- `refresh.sh` first builds the main dashboards' Libraries
  (`dashboards/sites/main/analytics/*.sql`) into Library JSON in a directory of its own
  (`tools/warehouse/.run.*`), and writes a copy of `tools/warehouse/fhir-pipes.toml` whose
  `libraries` points there. It then runs `fhir-pipes refresh` with that copy, in this order:
  locations, views, tiles, libraries (each SQLQuery's result as a table `main_…`),
  manifest, the catalog hook, then the push. Both are removed when the run ends, so two runs
  at once never share Library files, and a Library that fails to build stops the run before
  anything is downloaded.
- **The fhir-pipes build:** every command that uses `tools/warehouse/fhir-pipes.toml` needs
  a fhir-pipes newer than 0.6.0. 0.6.0 refuses the config's `libraries` key and has no
  `libraries` command. `~/.local/bin/fhir-pipes` is such a build (the old 0.6.0 is kept as
  `~/.local/bin/fhir-pipes-0.6.0-old`, for rolling back only). refresh.sh uses `FHIR_PIPES`,
  else `fhir-pipes` on the `PATH` with `~/.local/bin` first, and stops with a message when
  that binary has no `libraries` command.
- Set `FHIR_BASE` and `SERVER_NAME` as above. The config's default server is a local HAPI
  (`localhost:3447`).
- **Incremental by default:** only what changed is downloaded. Add `--full` after records
  were deleted on the server. A full run takes about 30 minutes, nearly all of it spent
  extracting the 350,000 locations, and prints no progress while it does.
- **Narrower runs:** `--views` (seconds) and `--locations` refresh that part and rerun the
  Libraries, since fhir-pipes runs them whenever their input tables change. `--libraries`
  reruns only the Libraries, after a change to their SQL, over the tables already in the
  warehouse: a new warehouse needs a run with views first, or the step stops on the
  missing view tables. `--tiles` rebuilds only the tiles.
- **Push only, without refreshing:**
  `"${FHIR_PIPES:-$HOME/.local/bin/fhir-pipes}" refresh --config tools/warehouse/fhir-pipes.toml --data data --server https://hapi.healthcampaigns.org/fhir --server-name hapi-gcp --only push`.
  Add `--dry-run` to see what it would copy and delete. Push only from a warehouse whose
  tables and catalog files you mean to publish: the push mirrors it to R2, which the
  dashboards and the SDI read.
- **Running fhir-pipes by hand** with `tools/warehouse/fhir-pipes.toml` and a step that
  loads the Libraries reads them from `dashboards/sites/main/analytics/build/`. Build it
  first: `"$FHIR_PIPES" libraries build dashboards/sites/main/analytics --out dashboards/sites/main/analytics/build`.

## Update the Uganda warehouse

```bash
country/uganda/warehouse.sh --push
```

- **What it does:** runs `fhir-pipes refresh` with `country/uganda/fhir-pipes.toml`
  (locations, views, tiles and the catalog hook), then uploads `warehouse/` to `r2:icr/uga/`
  with rclone. It takes about 30 seconds.
- **Why rclone:** fhir-pipes can only push to the root of a bucket.
- **API key:** read from `~/.config/icr/uga-matt.env`, or another file given in `KEY_FILE`.

## Update the DIGIT warehouse

```bash
country/digit/warehouse.sh --push
```

- **What it does:** copies the IG's ViewDefinitions and the DIGIT ones in
  `country/digit/views/` into `country/digit/build/views/`, runs `fhir-pipes refresh` with
  `country/digit/fhir-pipes.toml` (locations and views; no tiles and no catalog: DIGIT holds
  no geometry, and only 168 Nigerian states and LGAs carry a GRID3 boundary from the ICR's
  registry, which the site draws from the `locations` table), then uploads `warehouse/` to `r2:icr/digit/` with
  rclone. `digit/` is private: there is no SDI for it.
- **The data:** DIGIT HCM demo data (fake), imported into the ICR through the DIGIT mapping.
  DIGIT is a demo tenant, not a country, so the tables are not partitioned by country.
- **Incremental by default**, like the others; add `--full` after a reload or deletes on
  the server. The first run downloads about 220,000 Locations twice (once for the
  `locations` table, once for the `digit_location` view) and takes several minutes.
- **The IG's views** come from `$IG_VIEWS`. Until PR #224 (`ig/digit-additions`, which adds
  `IcrCampaignTaskOutput`) is merged, the script uses that branch's build in its worktree
  when it exists; after the merge it uses `ig/fsh-generated/resources` (build the IG first).
- **API key:** read from `~/.config/icr/digit-loader.env`, or another file given in
  `KEY_FILE`.

## Redeploy the dashboards

```bash
cd dashboards && npm install      # once, and after package.json changes
npx observatory deploy main uganda digit
```

- **The sites and where they go** are in `dashboards/observatory.config.js`.
  `npx observatory check` lists each site, its warehouse and its bucket folder.
- **What it does, for each site:**
  1. Pulls the site's warehouse from R2 into `~/.cache/observatory/warehouses/`.
  2. Sets `DATA` for the loaders, and `DUCKDB_AGENT_MODE=0`.
  3. Clears Framework's cached loader outputs.
  4. Swaps in DuckDB 2.0 for pages that use DuckDB.
  5. Builds, then uploads the build to R2.

  Then the gate (`dashboards/worker/`, the `campaignhq` Worker) is redeployed, after its D1
  migrations are applied.
- **Options:**
  - `--dry-run` builds and shows what would change, without uploading.
  - `--local` builds from the local copies (`data/`, `country/uganda/warehouse/`) instead
    of R2.
  - `--skip-build` uploads the last build; `--no-worker` leaves the Worker alone.
- **Sites are uploaded one at a time.** A site's upload leaves the folders of the sites
  under its path alone, so `main` can be deployed on its own. If R2 holds pages in a
  folder that no site in the config owns, the upload stops rather than delete them
  (`--prune` deletes them).
- **The Sierra Leone sites** (`npx observatory deploy sldash sl-redux`) are static. They
  have no warehouse: their loaders read the raw Location download in the local `data/`,
  which isn't pushed. Redeploy them only when they change.

## Check the result

```bash
rclone cat r2:icr/manifest.json | python3 -c "import json,sys; print(json.load(sys.stdin)['refreshed_at'])"
rclone cat r2:icr/uga/manifest.json | python3 -c "import json,sys; print(json.load(sys.stdin)['refreshed_at'])"
for p in "" coverage ug/ ug/plan digit/ dhis2-sl/; do curl -s -o /dev/null -w "%{http_code} /$p\n" https://dashboards.healthcampaigns.org/$p; done
curl -s -o /dev/null -w "%{http_code}\n" https://sdi.healthcampaigns.org/uga/parquet/campaign_activity/country=UGA/part-0.parquet  # must be 404
```

Then open the pages in a browser and check that the figures changed as expected. A page
can respond with 200 and still fail in its DuckDB queries.

## What the tools need

- **fhir-pipes** (ohs-foundation/fhir-pipes-rs), a build newer than 0.6.0 with the
  `libraries` command, at `~/.local/bin/fhir-pipes` (a `cargo build --release` of main).
  All three warehouses use it. The main and Uganda configs have Libraries, which 0.6.0
  refuses, and the admin tile layer names the sites draw (`admin0`…) are the newer build's.
- **duckdb** (2.0, with the spatial extension), **tippecanoe**, and **portolan** for the
  catalog hook.
- **rclone** with the `r2` remote for the `icr` bucket.
- **wrangler** with a login on the Cloudflare account, and Node 22 or later. If the
  default node is older, put Homebrew's first:
  `PATH="$(brew --prefix)/opt/node/bin:$PATH"`.
- **gh**, signed in: Observatory downloads the DuckDB-Wasm 2.0 build from the
  duckdb/duckdb-wasm CI the first time.
- **The IG built:** run `sushi build .` in `ig/`. The views are read from
  `ig/fsh-generated/resources`.
- **API keys:** the Uganda key in `~/.config/icr/uga-matt.env`, the DIGIT key in
  `~/.config/icr/digit-loader.env`. The main server is read
  through its open address for now.
- **The dashboards' npm packages:** run `npm install` in `dashboards/`. All four sites
  share them.

## Pitfalls

- **DuckDB 2.0's agent mode.** When `AI_AGENT` is set (as in an AI coding session), DuckDB
  prints an "agent mode" banner on stdout. That corrupts the parquet that data loaders
  write to stdout. `observatory`, `refresh.sh` and `warehouse.sh` set
  `DUCKDB_AGENT_MODE=0`. Set it yourself for anything else that runs the loaders.
- **Stale dashboard data.** Framework keeps a loader's output until the loader file
  changes. `observatory build` and `deploy` clear it. A dev server
  (`npx observatory dev <site>`) doesn't, so delete the outputs under
  `src/.observablehq/cache/` to see new data.
- **The DuckDB engine.** `npm install` undoes Observatory's DuckDB 2.0 swap in
  `node_modules`. `observatory dev`, `build` and `deploy` redo it each time, so always
  run the sites through `observatory`, not `observable` directly.
- **Portolan metadata beside the data.** Warehouse folders hold Portolan files
  (`items.parquet`, `collection.json`) next to the tables. Read tables with globs that
  start at `country=*/`, as `data/catalog.sql` and the loaders do. The Library results
  (`main_…`, `uganda_…`) have no Portolan files, so their loaders read
  `<table>/**/*.parquet`, which also finds an unpartitioned result's `part-0.parquet`.
- **Map tile layer names.** fhir-pipes after 0.6.0 names the layers of `admin.pmtiles`
  by admin level: `admin0`, `admin1`, `admin2`. 0.6.0 named them `country`, `states` and
  `lgas`. The sites' maps use the new names (`ADMIN_LAYERS` in
  `dashboards/sites/main/src/components/map.js`, `UGANDA_LAYERS` in the Uganda site). The
  profile could rename the layers (`[location] admin_layers`); it does not, because the
  maps and the SDI styles use the level names, which fit every country.
- **Lock file.** `.refresh.lock` in a warehouse folder is fhir-pipes' run lock: a run holds
  an operating-system lock on it, so two refreshes of one warehouse take turns, and the lock
  ends with the process. The empty file stays by design and never blocks a later run.
  `.gitignore` keeps it out of git.
- **What is public.** The main and Sierra Leone dashboards are public. `/ug/`, with the
  Ministry of Health's ICHD targets, needs sign-in: Keycloak `uga` group `/dashboards`, a
  verified ona.io address, or an admin (`dashboards/README.md`). The SDI is public by design. The warehouses in R2
  are private: the bucket has no public URL. The main FHIR server's open address
  (`hapi.healthcampaigns.org`) is unprotected for now.
- **Secrets.** Never print or commit the API keys, the rclone config or the Cloudflare
  credentials.

## Known issues to raise with fhir-pipes

- Date-only values such as `executionPeriod.start` are written as UTC-midnight timestamps,
  so they show the previous day west of UTC.
- A full location extract shows no progress.
- The location GeoParquet leaves out locations without coordinates. This is why the Sierra
  Leone sites read `raw/`.
- The push can only target the root of a bucket.
