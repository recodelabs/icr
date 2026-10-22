#!/usr/bin/env bash
# Refresh warehouse/ (the Uganda dashboards' data) from the Uganda ICR server with fhir-pipes:
# its locations, the IG's views (campaign calendar and activities, targets, tasks) and the
# boundary tiles for the maps.
#
#   ./refresh.sh          only what changed since the last run
#   ./refresh.sh --full   download everything again (after records were deleted on the server)
#
# The key comes from ~/.config/icr/uga-matt.env (or $KEY_FILE). Build the IG first
# (sushi build . in ig/), since the views are read from ig/fsh-generated/resources.
set -euo pipefail
cd "$(dirname "$0")"
set -a; . "${KEY_FILE:-$HOME/.config/icr/uga-matt.env}"; set +a
export FHIR_PIPES_CLIENT_ID="$FHIR_CLIENT_ID" FHIR_PIPES_CLIENT_SECRET="$FHIR_CLIENT_SECRET"
export DUCKDB_AGENT_MODE=0   # keep DuckDB 2.0's agent banner out of fhir-pipes' output
exec "${FHIR_PIPES:-fhir-pipes}" refresh --config fhir-pipes.toml --only locations,views,tiles "$@"
