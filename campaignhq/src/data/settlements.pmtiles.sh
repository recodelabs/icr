#!/usr/bin/env bash
# Settlement points (layer `settlements`, z8+), built by the tiles step of tools/warehouse/refresh.sh with no point dropping.
set -euo pipefail
DATA="$(cd "$(dirname "$0")/../../../data" && pwd)"
cat "$DATA/tiles/settlements.pmtiles"
