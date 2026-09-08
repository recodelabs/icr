#!/usr/bin/env bash
# Health facility points (layer `facilities`), built by tools/warehouse/tiles.sh with no point dropping.
set -euo pipefail
DATA="$(cd "$(dirname "$0")/../../../data" && pwd)"
cat "$DATA/tiles/facilities.pmtiles"
