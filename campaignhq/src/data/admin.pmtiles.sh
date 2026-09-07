#!/usr/bin/env bash
# Admin boundary tiles (states + lgas layers), built by tools/warehouse/tiles.sh.
set -euo pipefail
DATA="$(cd "$(dirname "$0")/../../../data" && pwd)"
cat "$DATA/tiles/admin.pmtiles"
