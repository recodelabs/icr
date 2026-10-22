#!/usr/bin/env bash
# Boundary tiles (layers country, states = regions, lgas = districts and cities: fhir-pipes
# names the levels the Nigerian way), built by refresh.sh.
set -euo pipefail
cat "$(dirname "$0")/../../warehouse/tiles/admin.pmtiles"
