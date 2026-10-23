# ICR dashboards

The ICR's dashboards at https://dashboards.healthcampaigns.org: four
[Observable Framework](https://observablehq.com/framework/) sites that run **DuckDB
(WebAssembly) in the browser** over parquet files and draw maps with **MapLibre** from
**PMTiles**. They build to plain static files, so nothing talks to a server while people
browse. Every input is made ahead of time from a warehouse.

They are built and deployed with **Observatory** (https://github.com/recodelabs/observatory,
npm `@recodelabs/observatory-cli`); its components package supplies the shared map and filters.

| Site | Path | Folder | Data |
|---|---|---|---|
| Campaign Dashboards (Nigeria demo, IG examples) | `/` | `sites/main/` | the main warehouse (R2 bucket root; local copy `data/`) |
| Uganda campaign dashboards | `/ug/` | `sites/uganda/` | the Uganda warehouse (R2 `uga/`; local copy `country/uganda/warehouse/`) |
| Sierra Leone DHIS2 dashboards | `/dhis2-sl/` | `sites/sldash/` | the local `data/` only |
| The same, redrawn | `/dhis2-sl-redux/` | `sites/sl-redux/` | the local `data/` only |

`observatory.config.js` lists the sites, their warehouses and where they go in R2.
`worker/` is the Cloudflare Worker that serves them and handles sign-in.

## Run

```bash
cd dashboards
npm install                       # Framework, the observatory CLI, components and gate, wrangler
npx observatory check             # the sites, their warehouses and bucket folders
npx observatory dev main          # preview, data from the cached R2 warehouse (pulled if none)
npx observatory dev main --local  # … from the local copy (data/) instead
npx observatory dev main --port 3030 --host 0.0.0.0   # other options go to Framework
```

The data loaders in each site's `src/data/` need `duckdb` on the PATH. They read the
warehouse folder in `DATA`, which observatory sets, and fall back to the local copy when
run on their own.

**DuckDB 2.0 in the browser.** Framework 1.13.4 comes with DuckDB-Wasm 1.29.0 (DuckDB
1.1.1). For pages that use DuckDB, observatory swaps in DuckDB-Wasm built for DuckDB 2.0.0
from the duckdb-wasm CI, which isn't on npm yet. It does so before every `dev`, `build` and
`deploy`, because `npm install` undoes it. Each site's `observablehq.config.js` sets the
`duckdb` extensions json and parquet to `null`, since 2.0 has both built in. The engine is
named `duckdb-base.<hash>.wasm`, after the start of its checksum: the Worker tells browsers
to keep it for a year, so a different build needs a different name.

## Deploy

The data comes from the warehouses in the `icr` R2 bucket, not from this machine: an update
is refresh the warehouse, then deploy. The full runbook is `tools/warehouse/README.md`.

```bash
tools/warehouse/refresh.sh --push            # (repo root) main server → data/ → r2:icr/
country/uganda/warehouse.sh --push           # (repo root) Uganda server → r2:icr/uga/
cd dashboards && npx observatory deploy main uganda
                                             # pull each warehouse → build → upload to
                                             # r2:icr/_site/campaignhq/… → D1 migrations → wrangler deploy worker/
```

For each site, `observatory deploy`:
1. Pulls the warehouse into `~/.cache/observatory/warehouses/`.
2. Clears Framework's cached loader outputs, which Framework would otherwise reuse while
   the loaders are unchanged.
3. Builds the site.
4. Adds brotli copies of the `.wasm` files.
5. Uploads the build to `_site/campaignhq/` plus the site's path.

Then it applies the gate's D1 migrations and deploys the Worker. `--dry-run` shows what would change; `--local` builds from the
local copies.

**Sites are uploaded separately.** Uploading `main` leaves `/ug/` and the Sierra Leone
folders alone. If R2 holds pages in a folder that no site owns, the upload stops rather
than delete them.

The Sierra Leone sites have no warehouse. Their loaders read the raw Location download in
the local `data/`, which is not pushed, so deploy them from a machine that has it.

**The Worker** (`worker/`) is Observatory's gate (`@recodelabs/observatory-gate`): it
serves the sites straight from the bucket and decides who sees what. Cloudflare Pages was
ruled out because it caps files at 25 MiB, and DuckDB-WASM's engine is larger.
- **Access:** each site's `access` in `observatory.config.js`. The main and Sierra Leone
  sites are public. `/ug/` is open to the Keycloak `uga` realm's group `/dashboards`, to
  verified ona.io addresses and to admins. Its data files follow its page: without a
  session they get 401.
- **Sign-in:** at `/_obs/login`, with Keycloak (the `uga` realm, client `observatory`) or by
  email and password. A verified ona.io address is active at once. Anyone else waits for an
  admin's approval; mberg@ona.io gets an email about each new account. Approval alone does
  not open `/ug/`: give someone outside Ona access by ticking uganda for them on Settings (or
  inviting them there), or by adding them to the Keycloak group `/dashboards`.
- **Uganda files cached before sign-in:** until the gate, `/ug/` was public, and its data
  files were sent with a one-year browser cache. A browser that opened `/ug/` then may still
  hold those files, though their pages now need sign-in. The file names change, and the old
  copies stop being used, once the Uganda data next changes.
- **Admins** (`auth.admins`): mberg@ona.io and the Keycloak group `/dashboards-admins`.
  They see every site and manage users at `/_obs/admin` ("Settings"). A signed-in user sees
  an account panel at the foot of each page's sidebar, with "Settings" for admins.
- **Invitations:** on Settings, an admin invites someone by email and ticks the sites they can
  see (or makes them admin). They sign in with an emailed link; no password is needed. Each
  user's row has the same ticks, to change later.
- **Users and sessions** are in the D1 database `observatory`. `observatory deploy` applies
  the gate's migrations before it deploys the Worker.
- **Secrets** (`npx wrangler secret put NAME`, in `worker/`): `BETTER_AUTH_SECRET`,
  `OIDC_UGA_SECRET` (the Keycloak client's secret) and `RESEND_API_KEY` (mail). Never
  commit or print them. For `wrangler dev`, put them in `worker/.dev.vars`, which git
  ignores.
- **Domain:** `wrangler.toml` declares `dashboards.healthcampaigns.org` as a custom-domain
  route, so wrangler creates its DNS record and certificate.
- **Old hosts:** `monitor.healthcampaigns.org` and `doorman.healthcampaigns.org` 301-redirect to
  the new host; old `/_door/` links go to `/_obs/`.
- **Brotli copies:** browsers that accept brotli get the precompressed copy of each
  `.wasm` file. Cloudflare's own compression is lighter: the DuckDB engine (27.4 MB) goes
  out as 4.7 MiB from the copy instead of 7.0 MiB.

## The main site

### What is on the page

- **Filters** — year, state, programme, status. Everything below reacts. The
  pulldowns are cascading: a choice with no rounds under the other filters is
  greyed out ("— none"), so you cannot land on an empty selection
  (`constrain` from `@recodelabs/observatory-components/filters`; the same helper drives the other pages).
- **KPIs** — LGA-level campaign rounds, LGAs covered, people targeted (sum of the
  campaigns' planning denominators), people reached with the administrative
  coverage over reported rounds (plus how many rounds have no report or are in
  progress).
- **Two synced maps** — LGA choropleths of campaign rounds and people targeted.
  Pan or zoom one and the other follows. Hover for the LGA's figures. Both ramps
  rescale to the selection (the rounds ramp runs 0 → busiest LGA in the current
  year / programme, so a single year still shows contrast). Boundaries come from `admin.pmtiles` (layers
  `states`, `lgas`; `promoteId: id` so feature-state is keyed by the registry
  Location id).
- **Timeline** — toggle between *By state* (one lane per state, one bar per state
  round coloured by programme; overlaps are two programmes in the same state at the
  same time) and *By LGA* (one lane per LGA, grouped into a collapsible section per
  state, all sharing one time axis). Red dotted line is today.
- **Table** — searchable, sortable LGA rounds with targeted, reached, administrative
  coverage, the LQAS verdict and the survey estimate with its confidence interval.

### Pages

- **Campaign calendar** (`/`) — filters, KPIs, two synced maps, timeline, table.
- **Campaign coverage** (`/coverage`) — people targeted and reached, by year, by
  state, and by LGA when a state is picked (drill down). Programme and year
  filters; KPIs for the year; synced maps of people targeted and administrative
  coverage per LGA (zoomed to the state when drilled); targeted-vs-reached bars
  per year; a coverage heat-map of state (or LGA) × year; and a state (or LGA) ×
  year table with rounds reported, targeted, reached, coverage, the post-campaign
  survey estimate and the LQAS pass count.
- **NTD endemicity** (`/ntd`) — per disease (LF, onchocerciasis, trachoma, schisto,
  STH): each LGA's classification as of the selected year (from the
  `IcrLocationStatus` assertions: endemic under MDA, post-MDA surveillance,
  non-endemic, unknown, with the baseline prevalence or stop-survey figure), the
  year's MDA rounds and their coverage in the endemic LGAs, gaps (endemic LGAs
  with no round), a coverage-by-LGA chart against the WHO target, and the
  transitions to post-MDA surveillance by year.
- **Microplan (NIPDs, Toro)** (`/microplan`) — one polio round (National Immunization
  Plus Days, round 2, Sep 7–11 2026) planned by health-facility catchment and monitored
  settlement by settlement, frozen at day 3: plan KPIs (settlements, under-5 target, teams)
  beside monitoring KPIs (visits completed, children vaccinated, coverage of completed
  settlements); a map of settlement visits coloured by status or coverage over the facility
  catchments (coloured by progress); visits by planned day; missed-children reasons; a
  facility table that drills into the settlement visits. Data: `IcrCampaignTask` +
  `IcrTargetPopulation` views (`src/data/microplan.parquet.sh`), generated by
  `tools/microplan-builder`.
- **DHIS2 indicators** (`/indicators`) — indicator values imported from a DHIS2
  instance with `fhir-pipes dhis2`, formerly `kiln dhis2` (see `project/dhis2-indicators.md`): pick an indicator,
  a map level (district / chiefdom for Sierra Leone) and a yearly or monthly period;
  KPIs for the country and the highest and lowest unit, a choropleth of the level,
  the trend of the country and every unit, and a table with DHIS2's numerator and
  denominator. Values are shown as DHIS2 computes them (annualised indicators can
  exceed 100% for months). The boundaries come from `indicator_units.geojson`
  (the admin units that have values, simplified), not the Nigeria tiles, so any
  country in the registry works. Reads `indicator_value` and `indicator`.
- **Georegistry** (`/georegistry`) — every layer exported from the location
  registry as PMTiles: country, states and LGAs (`admin.pmtiles`), health
  facilities (`facilities.pmtiles`), settlements (`settlements.pmtiles`, from
  zoom 8) and the catchment areas (`catchments.pmtiles`: facility catchments from
  zoom 6, settlement catchments from zoom 9 — Toro LGA, Bauchi so far, see
  `tools/catchments/`). The point archives are built with no dropping (`--drop-rate=1
  --no-feature-limit --no-tile-size-limit`) and streamed with HTTP range requests,
  so only the tiles in view are fetched. Layer toggles, state / LGA filters (the
  map zooms to the unit), and a click on any facility, settlement, catchment or LGA
  lists the feature's properties straight from the tile — a catchment shows
  `catchment_of`, the site it belongs to (`src/components/georegistry-map.js`).
- **About the data** (`/about`).

## Sierra Leone dashboards (`sldash/`)

`sldash/` is a separate Observable Framework site, with its own `package.json`, that
rebuilds the DHIS2 demo's Sierra Leone dashboards from the DHIS2 data in the registry.
It is not part of this site's build or deploy. See `sldash/README.md`.

`sl-redux/` is a second version of those dashboards with the same indicators, redrawn for
comparing districts (filters, rankings, heatmaps, scorecards). Also a separate site; see
`sl-redux/README.md`.

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
