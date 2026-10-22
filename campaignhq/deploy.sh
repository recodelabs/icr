#!/usr/bin/env bash
# Build Campaign Dashboards and publish it to https://dashboards.healthcampaigns.org.
#
#   warehouse in R2 ──rclone──▶ cache ──▶ observable build ──▶ dist/ ──rclone sync──▶ r2:icr/_site/campaignhq/
#   ──▶ wrangler deploy (Worker)
#
# Each site is built from a warehouse in the same R2 bucket, the one source the dashboards, the
# SDI and DuckDB users share: the main site from the bucket root (tools/warehouse/refresh.sh
# --push writes it), /ug/ from uga/ (country/uganda/warehouse.sh --push). Its parquet/, tiles/
# and manifest are pulled into WAREHOUSE_CACHE and the data loaders read them there ($DATA), so
# a deploy shows what the warehouse holds, from any machine with the r2 remote. --local-data
# builds from the local copies instead (data/, country/uganda/warehouse/). The two Sierra Leone
# sites always build from the local data/: they read the raw Location download, which is not
# pushed (the GeoParquet leaves out facilities without coordinates).
#
# The Worker (worker/index.js) serves the site straight from R2.
#
# Two more Framework sites are served under it, each from its own folder and built
# from its own directory here:
#   sldash/    → /dhis2-sl/         the DHIS2 demo's Sierra Leone dashboards
#   sl-redux/  → /dhis2-sl-redux/   the same, redrawn for comparing districts
#   uganda/    → /ug/               Uganda's planning data, from the Uganda ICR server
#                                   (run uganda/refresh.sh first)
# The main site's sync leaves those folders alone.
#
# Usage: ./deploy.sh [--skip-build] [--dry-run] [--local-data] [SITE...]
#        SITE: main (the default), sldash, sl-redux, uganda, or all
# Env:   R2_BUCKET (icr)  R2_REMOTE (r2)  BR_CACHE (~/.cache/campaignhq-br)
#        WAREHOUSE_CACHE (~/.cache/campaignhq-warehouse)
set -euo pipefail
cd "$(dirname "$0")"
BUCKET="${R2_BUCKET:-icr}"
REMOTE="${R2_REMOTE:-r2}"
SUBSITES=("sldash:dhis2-sl" "sl-redux:dhis2-sl-redux" "uganda:ug")
BR_CACHE="${BR_CACHE:-$HOME/.cache/campaignhq-br}"
WAREHOUSE_CACHE="${WAREHOUSE_CACHE:-$HOME/.cache/campaignhq-warehouse}"
# site:folder of its warehouse in the bucket ("" = the root). Sites not listed build from local data.
WAREHOUSES=("main:" "uganda:uga/")
BUILD=1; DRY=""; LOCAL_DATA=0; SITES=()
for a in "$@"; do
  case "$a" in
    --skip-build) BUILD=0 ;;
    --dry-run) DRY="--dry-run" ;;
    --local-data) LOCAL_DATA=1 ;;
    main|sldash|sl-redux|uganda) SITES+=("$a") ;;
    all) SITES+=(main sldash sl-redux uganda) ;;
    *) echo "unknown option $a" >&2; exit 2 ;;
  esac
done
[ ${#SITES[@]} -gt 0 ] || SITES=(main)

rclone lsd "$REMOTE:" 2>/dev/null | awk '{print $NF}' | grep -qx "$BUCKET" || {
  echo "bucket '$BUCKET' not found on rclone remote '$REMOTE'. Create it:  npx wrangler r2 bucket create $BUCKET" >&2; exit 1; }

# precompress DIR: put a brotli copy (quality 11) next to each .wasm in DIR/dist, which the
# Worker sends to browsers that accept brotli. Cloudflare's own compression is lighter: the
# DuckDB engine goes over the wire as 7.0 MB that way, 4.7 MB from the copy. Copies are kept
# in BR_CACHE by checksum, so an unchanged file is compressed once (it takes about a minute).
precompress() {
  find "$1/dist" -name '*.wasm.br' -delete
  command -v brotli >/dev/null || { echo "brotli not installed; .wasm goes up without a brotli copy" >&2; return 0; }
  mkdir -p "$BR_CACHE"
  local f br
  while IFS= read -r -d '' f; do
    br="$BR_CACHE/$(shasum -a 256 "$f" | cut -c1-64).br"
    if [ ! -s "$br" ]; then
      echo "== brotli ${f#"$1"/dist/}"
      brotli -q 11 -c "$f" > "$br.tmp" && mv "$br.tmp" "$br"
    fi
    cp "$br" "$f.br"
  done < <(find "$1/dist" -name '*.wasm' -print0)
}

# pull SITE: copy SITE's warehouse from R2 into the cache and print its path; nothing for a
# site without one (it builds from local data).
pull() {
  local entry folder dest
  for entry in "${WAREHOUSES[@]}"; do
    [ "${entry%%:*}" = "$1" ] || continue
    folder="${entry#*:}"; dest="$WAREHOUSE_CACHE/${folder:-root/}"
    echo "== pull r2:$BUCKET/${folder} warehouse → $dest" >&2
    for d in parquet tiles; do
      rclone sync --checksum --fast-list --transfers 16 --exclude ".DS_Store" --exclude ".portolan/**" \
        "$REMOTE:$BUCKET/${folder}$d" "$dest/$d" >&2
    done
    rclone copyto --checksum "$REMOTE:$BUCKET/${folder}manifest.json" "$dest/manifest.json" >&2
    echo "${dest%/}"
  done
}

# sync SITE DIR PREFIX [rclone options…]: build SITE (in DIR) and mirror DIR/dist to the site folder PREFIX.
sync() {
  local site="$1" dir="$2" prefix="$3"; shift 3
  if [ "$BUILD" = 1 ]; then
    local data=""
    [ "$LOCAL_DATA" = 1 ] || data="$(pull "$site")"
    echo "== build $dir${data:+ from $data}"
    ./duckdb-wasm2.sh "$dir"
    # Framework reuses a loader's cached output until the loader itself changes, so new data in the
    # warehouse would not show; drop the cached outputs (not the npm cache duckdb-wasm2.sh fills).
    rm -rf "$dir/src/.observablehq/cache/data"
    (cd "$dir" && export DUCKDB_AGENT_MODE=0 ${data:+DATA="$data"} && npm run build)
  fi
  precompress "$dir"
  echo "== sync $dir/dist → $REMOTE:$BUCKET/_site/campaignhq/$prefix ${DRY:+(dry run)}"
  rclone sync $DRY --checksum --fast-list --transfers 16 --exclude ".DS_Store" "$@" \
    "$dir/dist" "$REMOTE:$BUCKET/_site/campaignhq/$prefix" --stats-one-line -v 2>&1 | grep -v "^$" | tail -3
}

WORKER=0
for site in "${SITES[@]}"; do
  if [ "$site" = main ]; then
    excludes=()
    for s in "${SUBSITES[@]}"; do excludes+=(--exclude "/${s#*:}/**"); done
    sync main . "" "${excludes[@]}"
    WORKER=1
    echo "== https://dashboards.healthcampaigns.org"
  else
    for s in "${SUBSITES[@]}"; do
      [ "${s%%:*}" = "$site" ] || continue
      sync "$site" "$site" "${s#*:}"
      echo "== https://dashboards.healthcampaigns.org/${s#*:}/"
    done
  fi
done

# The Worker goes last, so a wrangler failure never leaves a site unsynced.
# Wrangler needs Node 22 or later; if the default node is older, use Homebrew's.
if [ "$WORKER" = 1 ] && [ -z "$DRY" ]; then
  echo "== deploy worker"
  major() { "$1" -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0; }
  if [ "$(major node)" -lt 22 ]; then
    for n in "$(brew --prefix 2>/dev/null)/opt/node/bin/node" "$(brew --prefix 2>/dev/null)"/opt/node@2*/bin/node; do
      if [ -x "$n" ] && [ "$(major "$n")" -ge 22 ]; then PATH="$(dirname "$n"):$PATH"; break; fi
    done
  fi
  [ "$(major node)" -ge 22 ] || { echo "wrangler needs Node 22 or later (node is $(node -v)); the sites are synced, the Worker is not" >&2; exit 1; }
  npx wrangler deploy
fi
