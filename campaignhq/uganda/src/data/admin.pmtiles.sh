#!/usr/bin/env bash
# Boundary tiles (layers country, states = regions, lgas = districts and cities: fhir-pipes
# names the levels the Nigerian way), from the Uganda warehouse.
set -euo pipefail
DATA="${DATA:-$(cd "$(dirname "$0")/../../../../country/uganda/warehouse" && pwd)}"
cat "$DATA/tiles/admin.pmtiles"
