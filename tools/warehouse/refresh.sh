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
#                  built to Library JSON for each run first) over the view tables and
#                  location_hierarchy; each SQLQuery's result → data/parquet/<table>/
#                  (MainCampaigns → main_campaigns)
#   5. manifest:   data/manifest.json with counts and provenance
#   6. hooks:      tools/warehouse/catalog.sh, the Portolan catalog, after a locations refresh
#   7. push:       with --push, mirror data/ (minus raw/) to Cloudflare R2 (rclone)
#
# Usage: tools/warehouse/refresh.sh [--views] [--locations] [--tiles] [--libraries] [--push] [--full]
#        No step flag runs every step but push. --views and --locations also rerun the
#        Libraries, which read their tables; --libraries reruns only them, over the tables
#        already in the warehouse (so a new warehouse needs a views run first). --full downloads everything again
#        instead of only what changed; run it after resources were deleted on the server.
# Env:   FHIR_BASE (from the config, http://localhost:3447/fhir)  SERVER_NAME (hapi-local)
#        DATA (repo data/)  FHIR_PIPES (the fhir-pipes binary, default fhir-pipes on PATH,
#        ~/.local/bin first; it must be newer than 0.6.0, with the `libraries` command)
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

# Every command that reads fhir-pipes.toml needs a fhir-pipes newer than 0.6.0: 0.6.0 refuses the
# config's `libraries` key and has no `libraries` command.
"$FHIR_PIPES" libraries --help >/dev/null 2>&1 || {
  echo "$FHIR_PIPES has no libraries command (fhir-pipes 0.6.0 and earlier), and cannot read" >&2
  echo "fhir-pipes.toml. Set FHIR_PIPES to a newer build (see tools/warehouse/README.md)." >&2
  exit 1
}

# This run's copy of the config, beside the original so its relative paths still resolve, with
# `libraries` pointing at Library JSON built for this run alone. Two refreshes at once (of this
# warehouse or of another DATA) never share or delete each other's Library files, and a failed
# build stops here before anything else runs. Both are removed when the run ends.
LIBS="$HERE/../../dashboards/sites/main/analytics"
grep -q '^libraries = ' "$HERE/fhir-pipes.toml" || { echo "fhir-pipes.toml has no libraries line" >&2; exit 1; }
RUN="$(mktemp -d "$HERE/.run.XXXXXX")"
trap 'rm -rf "$RUN" "$RUN.toml"' EXIT
"$FHIR_PIPES" libraries build "$LIBS" --out "$RUN/libraries"
sed "s|^libraries = .*|libraries = [\"$RUN/libraries\"]|" "$HERE/fhir-pipes.toml" > "$RUN.toml"

args=(refresh --config "$RUN.toml")
[ -n "${FHIR_BASE:-}" ] && args+=(--server "$FHIR_BASE")
[ -n "${SERVER_NAME:-}" ] && args+=(--server-name "$SERVER_NAME")
[ -n "${DATA:-}" ] && args+=(--data "$DATA")
[ -n "${FHIR_TOKEN_URL:-}" ] && args+=(--token-url "$FHIR_TOKEN_URL")
if [ -n "${FHIR_CLIENT_ID:-}" ]; then
  : "${FHIR_CLIENT_SECRET:?set FHIR_CLIENT_SECRET with FHIR_CLIENT_ID}"
  export FHIR_PIPES_CLIENT_ID="$FHIR_CLIENT_ID" FHIR_PIPES_CLIENT_SECRET="$FHIR_CLIENT_SECRET"
fi

# fhir-pipes adds the libraries step itself whenever locations or views run, since the Libraries
# read their tables; it is listed here too, so the step list says what runs.
only=()
for a in "$@"; do
  case "$a" in
    --views) only+=(views libraries) ;;
    --locations) only+=(locations libraries hooks) ;;   # the catalog hook follows a locations refresh
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

"$FHIR_PIPES" "${args[@]}"
