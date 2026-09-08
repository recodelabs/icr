#!/usr/bin/env bash
# See locations-facility.parquet.sh for the per-layer rationale.
set -euo pipefail
DATA="$(cd "$(dirname "$0")/../../../../data" && pwd)"
duckdb -c "
COPY (
  SELECT id, name, type, status, admin_level,
         admin1_name AS state, admin2_name AS lga, admin3_name AS ward,
         replace(facility_level_text, chr(160), ' ') AS facility_level,
         ownership_text AS ownership, settlement_type,
         pcode, nhfr_code,
         position_longitude AS lon, position_latitude AS lat,
         CAST(NULL AS VARCHAR) AS geometry_geojson
  FROM read_parquet('$DATA/parquet/locations/country=NGA/geom_type=point/type=settlement/*.parquet')
) TO '/dev/stdout' (FORMAT PARQUET);"
