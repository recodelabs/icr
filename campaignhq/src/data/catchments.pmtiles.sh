#!/usr/bin/env bash
# Catchment areas (layers `facility_catchments`, `settlement_catchments`, z6–14), built by
# the tiles step of tools/warehouse/refresh.sh from the *-catchment Location partitions.
set -euo pipefail
DATA="${DATA:-$(cd "$(dirname "$0")/../../../data" && pwd)}"
cat "$DATA/tiles/catchments.pmtiles"
