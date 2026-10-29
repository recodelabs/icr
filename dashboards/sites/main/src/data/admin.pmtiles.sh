#!/usr/bin/env bash
# Admin boundary tiles (layers admin0 the country, admin1 the states, admin2 the LGAs), built by
# the tiles step of tools/warehouse/refresh.sh.
set -euo pipefail
DATA="${DATA:-$(cd "$(dirname "$0")/../../../../../data" && pwd)}"
cat "$DATA/tiles/admin.pmtiles"
