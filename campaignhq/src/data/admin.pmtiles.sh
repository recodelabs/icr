#!/usr/bin/env bash
# Admin boundary tiles (states + lgas layers), built by the tiles step of tools/warehouse/refresh.sh.
set -euo pipefail
DATA="$(cd "$(dirname "$0")/../../../data" && pwd)"
cat "$DATA/tiles/admin.pmtiles"
