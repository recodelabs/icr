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
#   4. manifest:   data/manifest.json with counts and provenance
#   5. hooks:      tools/warehouse/catalog.sh, the Portolan catalog, after a locations refresh
#   6. push:       with --push, mirror data/ (minus raw/) to Cloudflare R2 (rclone)
#
# Usage: tools/warehouse/refresh.sh [--views] [--locations] [--tiles] [--push] [--full]
#        No step flag runs every step but push. --full downloads everything again instead of
#        only what changed; run it after resources were deleted on the server.
# Env:   FHIR_BASE (from the config, http://localhost:3447/fhir)  SERVER_NAME (hapi-local)
#        DATA (repo data/)  FHIR_PIPES (the fhir-pipes binary, default fhir-pipes on PATH)
#        FHIR_CLIENT_ID, FHIR_CLIENT_SECRET: an API key for a server behind the FHIR Info
#        Gateway (tools/hapi/gcp/README.md); FHIR_TOKEN_URL overrides the ICR Keycloak in the
#        config. Without them requests carry no token, as the local HAPI needs.
#        fhir-pipes' own FHIR_PIPES_* variables work too.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
FHIR_PIPES="${FHIR_PIPES:-fhir-pipes}"
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

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
    --views) only+=(views) ;;
    --locations) only+=(locations hooks) ;;   # the catalog hook follows a locations refresh
    --tiles) only+=(tiles) ;;
    --push) args+=(--push) ;;
    --full) args+=(--full) ;;
    *) echo "unknown option $a" >&2; exit 2 ;;
  esac
done
if [ ${#only[@]} -gt 0 ]; then
  args+=(--only "$(IFS=,; echo "${only[*]}")")
fi

exec "$FHIR_PIPES" "${args[@]}"
