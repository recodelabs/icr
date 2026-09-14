# Campaign Dashboards

The ICR campaign calendar dashboard: an [Observable Framework](https://observablehq.com/framework/)
site that runs **DuckDB (WebAssembly) in the browser** over parquet files and draws the
map with **MapLibre** from a **PMTiles** archive. It builds to plain static files —
nothing talks to a server at runtime — because every input is generated ahead of time
from the FHIR registry into the repo's analytics hub, `data/`.

```
data/parquet/campaign_calendar/   ─┐
data/parquet/target_population/    │
data/parquet/coverage/             ├─ src/data/campaigns.parquet.sh   (duckdb join at build time)
data/parquet/locations/           ─┘   src/data/admin_units.parquet.sh
data/tiles/admin.pmtiles          ──▶ src/data/admin.pmtiles.sh
data/tiles/facilities.pmtiles     ──▶ src/data/facilities.pmtiles.sh
data/tiles/settlements.pmtiles    ──▶ src/data/settlements.pmtiles.sh
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

- **Filters** — year, state, programme, status. Everything below reacts. The
  pulldowns are cascading: a choice with no rounds under the other filters is
  greyed out ("— none"), so you cannot land on an empty selection
  (`src/components/filters.js`; the same helper drives the other pages).
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

## Deploy — https://dashboards.healthcampaigns.org

The site is served by a small Cloudflare **Worker** (`worker/index.js`) straight
from the **`icr` R2 bucket**, under the `_site/campaignhq/` prefix, next to the
data hub it was built from. Cloudflare Pages was ruled out: it caps files at
25 MiB and DuckDB-WASM's engine builds are ~35–40 MiB each. R2 has no such
limit, and one bucket holds both site and data.

```bash
tools/warehouse/refresh.sh --push   # (repo root) regenerate data/ and mirror it to r2:icr/
cd campaignhq && ./deploy.sh        # build → rclone sync dist/ → r2:icr/_site/campaignhq → wrangler deploy
```

`wrangler.toml` binds the bucket and declares `dashboards.healthcampaigns.org` as a
custom-domain route, so wrangler creates the DNS record and certificate on the
first deploy. Needs `rclone` with the `r2` remote configured and a wrangler
login on this account. `./deploy.sh --dry-run` shows what would change.

## Login (doorman)

Access control is [doorman](https://github.com/recodelabs/doorman), a Cloudflare Worker
that serves the same `_site/campaignhq/` prefix from R2 behind a login (Better Auth,
sessions in D1). This repo only holds the deployment: `doorman/` has `doorman.config.js`
(site name, brand, `auth.allowedDomains`, mail addresses, page rules: `/about` is
public, everything else needs an active account), `wrangler.jsonc` (account, D1 and R2
bindings, `BASE_URL`, routes) and `worker.js`, which builds the Worker from that config.
doorman itself is installed from git, pinned by tag in `doorman/package.json`.

```bash
cd campaignhq/doorman && npm install
npx wrangler d1 migrations apply doorman --remote   # picks up new migrations after an upgrade
npx wrangler deploy                                  # or `npm run deploy` = doorman-deploy, which also syncs dist/ with rclone
```

The site build is unchanged: `./deploy.sh` still syncs `dist/` to R2. doorman reads it
from there. Secrets on the Worker (set once with `npx wrangler secret put`):
`BETTER_AUTH_SECRET` and `RESEND_API_KEY` (mail from `doorman@healthcampaigns.org`, so
healthcampaigns.org must be verified in Resend). The D1 database `doorman` already
exists; its id is in `wrangler.jsonc`. To upgrade doorman, bump the tag in
`doorman/package.json`, `npm install`, migrate, deploy.

Staging is https://doorman.healthcampaigns.org. Sign in at `/_door/login`; the first
account ever created is the admin, later sign-ups wait on `/_door/admin` unless their
domain is in `allowedDomains`. Remaining cutover steps, in order:

1. **Move the hostnames.** In `doorman/wrangler.jsonc` set `vars.BASE_URL` to
   `https://dashboards.healthcampaigns.org` and list both hostnames in `routes`
   (`dashboards.healthcampaigns.org` and `monitor.healthcampaigns.org`, both
   `custom_domain: true`). Drop both routes from `wrangler.toml` and redeploy the old
   Worker so it releases them (a custom domain can only point at one Worker; move them
   one at a time if downtime matters). Deploy doorman. `monitor.*` then 301s to
   `dashboards.*` as before, because doorman redirects every non-`BASE_URL` host.
2. **Retire the old Worker.** Delete `worker/` and `wrangler.toml`, drop the
   `wrangler deploy` step from `deploy.sh` (keep build and rclone sync), and update the
   Deploy section above.

## Pages

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
- **Georegistry** (`/georegistry`) — every layer exported from the location
  registry as PMTiles: country, states and LGAs (`admin.pmtiles`), health
  facilities (`facilities.pmtiles`) and settlements (`settlements.pmtiles`, from
  zoom 8). The point archives are built with no dropping (`--drop-rate=1
  --no-feature-limit --no-tile-size-limit`) and streamed with HTTP range requests,
  so only the tiles in view are fetched. Layer toggles, state / LGA filters (the
  map zooms to the unit), and a click on any facility, settlement or LGA lists the
  feature's properties straight from the tile (`src/components/georegistry-map.js`).
- **About the data** (`/about`).

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
