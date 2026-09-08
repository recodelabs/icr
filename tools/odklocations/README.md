# ODK Locations

A single-purpose site over the ICR location registry: filter health
facilities, settlements, or LGA/state boundaries, and export an ODK entity
CSV — ready for ODK Central's or Ona Data's bulk entity upload.

Everything runs in the browser. DuckDB (WebAssembly) filters the registry
parquet; the conversion itself — geometry → ODK geopoint/geoshape, label and
property-name sanitizing — is done by
[`odk-locations`](https://github.com/recodelabs/odk-locations) (a Rust CLI,
here compiled to WebAssembly instead: see `src/components/odk-locations/`)
running in the same tab. Nothing is uploaded to a server; the export button
triggers a local file download.

Static site, same pattern as `../../campaignhq/`: Observable Framework, built
ahead of time, served from Cloudflare R2 by a small Worker.

## Data

`src/data/locations.parquet.sh` flattens the location registry (`data/parquet/locations/**`
in the repo's data hub) into one file, with geometry pre-converted to GeoJSON
text via DuckDB's spatial extension at build time — so the page's own
DuckDB-WASM instance never needs the spatial extension, it just filters plain
columns. Regenerate after `tools/warehouse/refresh.sh` with:

```bash
cd tools/odklocations && npm run build   # data loaders re-run on every build/preview
```

## Develop

```bash
npm install
npm run dev     # observable preview
npm run build   # → dist/
```

## Deploy — https://odklocations.healthcampaigns.org

Same as `campaignhq/`: a Cloudflare Worker (`worker/index.js`) serves the
built site straight from the `icr` R2 bucket, under `_site/odklocations/`.

```bash
./deploy.sh              # build → rclone sync dist/ → r2:icr/_site/odklocations → wrangler deploy
./deploy.sh --dry-run    # show what would change
```

Needs `rclone` with the `r2` remote configured and a `wrangler` login on this
account. `wrangler.toml`'s `custom_domain` route creates the DNS record and
certificate for `odklocations.healthcampaigns.org` on first deploy.

## The wasm module

`src/components/odk-locations/` is a vendored build of `odk-locations`'
`wasm` feature (branch `wasm-bindings`,
[PR #1](https://github.com/recodelabs/odk-locations/pull/1) — not yet
merged). See the README there for what it exposes and how to regenerate it
after a change to the Rust source.
