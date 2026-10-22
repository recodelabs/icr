#!/usr/bin/env bash
# The Ministry of Health's October 2026 ICHD targets as ICRTargetPopulation Groups on the Uganda
# ICR server: one per target column for every district and city, with region and country totals.
# See README.md.
#
#   ./targets.sh            extract the server's Locations, build build/targets.ndjson
#   ./targets.sh --load     and load it (the two code systems first, then the Groups)
#
# Needs the workbook (not in git) next to this script, and Python with openpyxl.
set -euo pipefail
cd "$(dirname "$0")"
XLSX="Oct 2026_ICHDs_EPI Targets.xlsx"
set -a; . "${KEY_FILE:-$HOME/.config/icr/uga-matt.env}"; set +a
export FHIR_PIPES_CLIENT_ID="$FHIR_CLIENT_ID" FHIR_PIPES_CLIENT_SECRET="$FHIR_CLIENT_SECRET"
mkdir -p build

echo "== extract Locations from $FHIR_BASE"
fhir-pipes extract --server "$FHIR_BASE" --token-url "$FHIR_TOKEN_URL" --snapshot build/snapshot --full

echo "== targets"
python3 -I targets.py "$XLSX" build/snapshot/locations.ndjson build/targets.ndjson

if [ "${1:-}" = --load ]; then
  # The code systems first, so the Groups' codes validate against them.
  grep '"resourceType": "CodeSystem"' build/targets.ndjson > build/targets-codesystems.ndjson
  grep -v '"resourceType": "CodeSystem"' build/targets.ndjson > build/targets-groups.ndjson
  fhir-pipes load --server "$FHIR_BASE" --token-url "$FHIR_TOKEN_URL" --in build/targets-codesystems.ndjson
  fhir-pipes load --server "$FHIR_BASE" --token-url "$FHIR_TOKEN_URL" --in build/targets-groups.ndjson --batch-size 50
fi
