#!/usr/bin/env bash
# Settlement points (layer `settlements`, z8+), built by tools/warehouse/tiles.sh with no point dropping.
set -euo pipefail
DATA="$(cd "$(dirname "$0")/../../../data" && pwd)"
cat "$DATA/tiles/settlements.pmtiles"
