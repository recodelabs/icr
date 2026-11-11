#!/usr/bin/env bash
# WorldPop children under 1 per place (2024–2026): worldpop-under1.csv here, made by
# country/bangladesh/worldpop/zonal.py, which sums the WorldPop R2025A 100 m age and sex rasters
# (f_00 + m_00) over each place's boundary. Licence CC BY 4.0; DOI 10.5258/SOTON/WP00841.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
duckdb -c "
COPY (SELECT location_id, wp_under1_2024, wp_under1_2025, wp_under1_2026 FROM read_csv('$HERE/worldpop-under1.csv'))
TO '/dev/stdout' (FORMAT PARQUET);"
