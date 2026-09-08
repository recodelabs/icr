# ODK Locations

A single-page [Observable Framework](https://observablehq.com/framework/) site: filter
the ICR location registry (health facilities, settlements, LGA/state boundaries) with
**DuckDB (WebAssembly)** in the browser, then export an ODK entity CSV using
[`odk-locations`](https://github.com/recodelabs/odk-locations) compiled to WebAssembly.
Nothing is uploaded anywhere — filtering and conversion both happen client-side, in the
tab, so the site builds to plain static files.

```
data/parquet/locations/  ──▶ src/data/locations.parquet.sh   (duckdb at build time)
```

## Run

```bash
tools/warehouse/refresh.sh      # (repo root) regenerate data/ from the FHIR server
cd tools/odklocations
npm install
npm run dev                     # preview at http://127.0.0.1:3000
npm run build                   # static site in dist/
```

The loader in `src/data/` needs `duckdb` on the PATH; it runs at build (and preview)
time and its output is cached under `src/.observablehq/cache`.

## The wasm component

`src/components/odk-locations/odk_locations.js` + `odk_locations_bg.wasm` are a vendored
`wasm-pack --target web` build of [recodelabs/odk-locations](https://github.com/recodelabs/odk-locations)
(feature `wasm`) — the Rust source lives in that repo, not here. To update after a change
there:

```bash
git clone git@github.com:recodelabs/odk-locations.git
cd odk-locations
wasm-pack build --target web --no-default-features --features wasm
cp pkg/odk_locations.js pkg/odk_locations_bg.wasm \
  path/to/icr/tools/odklocations/src/components/odk-locations/
```

`src/components/filters.js` (the cascading-pulldown / checkbox-select helpers) is shared
verbatim with `campaignhq/src/components/filters.js` — keep the two in sync by hand if
either changes.

## Deploy — https://odklocations.healthcampaigns.org

Same pattern as `campaignhq/` (see its README for the full rationale): a Cloudflare
**Worker** (`worker/index.js`) serves the site straight from the **`icr` R2 bucket**
under the `_site/odklocations/` prefix.

```bash
npm run deploy     # observable build → rclone sync dist/ → r2 → wrangler deploy
```
