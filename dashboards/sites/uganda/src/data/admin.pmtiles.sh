#!/usr/bin/env bash
# Boundary tiles (layers country, regions, districts: the Uganda profile's names), from the
# Uganda warehouse.
set -euo pipefail
DATA="${DATA:-$(cd "$(dirname "$0")/../../../../../country/uganda/warehouse" && pwd)}"
cat "$DATA/tiles/admin.pmtiles"
