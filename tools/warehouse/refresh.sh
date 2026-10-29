#!/usr/bin/env bash
# Refresh data/ — the ICR analytics hub — from the FHIR server with fhir-pipes
# (https://github.com/ohs-foundation/fhir-pipes-rs). The steps, tables, partitioning, tiles,
# catalog hook and push are set in tools/warehouse/fhir-pipes.toml:
#
#   1. locations:  extract the Location registry incrementally → data/raw/<server>/locations,
#                  transform it → data/parquet/locations
#   2. views:      download what changed of each resource type the IG's ViewDefinitions read
#                  → data/raw/<server>/<Type>.ndjson, run the views, partition each table by
#                  country → data/parquet/<table>/
#   3. tiles:      the registry → data/tiles/*.pmtiles (duckdb + tippecanoe)
#   4. libraries:  the main dashboards' SQL on FHIR Libraries (dashboards/sites/main/analytics/,
#                  built to Library JSON here first) over the view tables and
#                  location_hierarchy; each SQLQuery's result → data/parquet/<table>/
#                  (MainCampaigns → main_campaigns)
#   5. manifest:   data/manifest.json with counts and provenance
#   6. hooks:      tools/warehouse/catalog.sh, the Portolan catalog, after a locations refresh
#   7. push:       with --push, mirror data/ (minus raw/) to Cloudflare R2 (rclone)
#
# Usage: tools/warehouse/refresh.sh [--views] [--locations] [--tiles] [--libraries] [--push] [--full]
#        No step flag runs every step but push. --views also reruns the Libraries, which read
#        the view tables; --libraries reruns only them. --full downloads everything again
#        instead of only what changed; run it after resources were deleted on the server.
# Env:   FHIR_BASE (from the config, http://localhost:3447/fhir)  SERVER_NAME (hapi-local)
#        DATA (repo data/)  FHIR_PIPES (the fhir-pipes binary, default fhir-pipes on PATH;
#        the libraries step needs a build with the `libraries` command, which 0.6.0 lacks)
#        FHIR_CLIENT_ID, FHIR_CLIENT_SECRET: an API key for a server behind the FHIR Info
#        Gateway (tools/hapi/gcp/README.md); FHIR_TOKEN_URL overrides the ICR Keycloak in the
#        config. Without them requests carry no token, as the local HAPI needs.
#        fhir-pipes' own FHIR_PIPES_* variables work too.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
FHIR_PIPES="${FHIR_PIPES:-fhir-pipes}"
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export DUCKDB_AGENT_MODE=0   # DuckDB 2.0 prints an agent banner when AI_AGENT is set; keep it out

command -v "$FHIR_PIPES" >/dev/null || {
  echo "fhir-pipes not found; install it with:" >&2
  echo "  cargo install --git https://github.com/ohs-foundation/fhir-pipes-rs --locked fhir-pipes" >&2
  exit 1
}

args=(refresh --config "$HERE/fhir-pipes.toml")
[ -n "${FHIR_BASE:-}" ] && args+=(--server "$FHIR_BASE")
[ -n "${SERVER_NAME:-}" ] && args+=(--server-name "$SERVER_NAME")
[ -n "${DATA:-}" ] && args+=(--data "$DATA")
[ -n "${FHIR_TOKEN_URL:-}" ] && args+=(--token-url "$FHIR_TOKEN_URL")
if [ -n "${FHIR_CLIENT_ID:-}" ]; then
  : "${FHIR_CLIENT_SECRET:?set FHIR_CLIENT_SECRET with FHIR_CLIENT_ID}"
  export FHIR_PIPES_CLIENT_ID="$FHIR_CLIENT_ID" FHIR_PIPES_CLIENT_SECRET="$FHIR_CLIENT_SECRET"
fi

only=()
for a in "$@"; do
  case "$a" in
    --views) only+=(views libraries) ;;     # the Libraries read the view tables
    --locations) only+=(locations hooks) ;;   # the catalog hook follows a locations refresh
    --tiles) only+=(tiles) ;;
    --libraries) only+=(libraries) ;;
    --push) args+=(--push) ;;
    --full) args+=(--full) ;;
    *) echo "unknown option $a" >&2; exit 2 ;;
  esac
done
if [ ${#only[@]} -gt 0 ]; then
  args+=(--only "$(IFS=,; echo "${only[*]}")")
fi

# The main dashboards' Libraries (SQL in dashboards/sites/main/analytics/) as Library JSON, which
# the libraries step loads from the config's `libraries`. build/ is emptied first, so a Library
# that was renamed or deleted stops running.
if [ ${#only[@]} -eq 0 ] || [[ " ${only[*]} " == *" libraries "* ]]; then
  "$FHIR_PIPES" libraries --help >/dev/null 2>&1 || {
    echo "$FHIR_PIPES has no libraries command (fhir-pipes 0.6.0 and earlier). Set FHIR_PIPES to a newer" >&2
    echo "build, such as one from main of ohs-foundation/fhir-pipes-rs (see tools/warehouse/README.md)." >&2
    exit 1
  }
  LIBS="$HERE/../../dashboards/sites/main/analytics"
  rm -rf "$LIBS/build"
  "$FHIR_PIPES" libraries build "$LIBS" --out "$LIBS/build"
fi

exec "$FHIR_PIPES" "${args[@]}"
