#!/usr/bin/env bash
# See locations-facility.parquet.sh for the per-layer rationale. LGA and
# state boundaries share one kiln partition (type=admin-unit); admin_level
# (2 = LGA, 1 = state) splits them the rest of the way.
set -euo pipefail
DATA="$(cd "$(dirname "$0")/../../../../data" && pwd)"
duckdb -c "
LOAD spatial;
COPY (
  SELECT id, name, type, status, admin_level,
         admin1_name AS state, admin2_name AS lga, admin3_name AS ward,
         CAST(NULL AS VARCHAR) AS facility_level,
         CAST(NULL AS VARCHAR) AS ownership, settlement_type,
         pcode, nhfr_code,
         CAST(NULL AS DOUBLE) AS lon, CAST(NULL AS DOUBLE) AS lat,
         ST_AsGeoJSON(geometry) AS geometry_geojson
  FROM read_parquet('$DATA/parquet/locations/country=NGA/geom_type=polygon/type=admin-unit/*.parquet')
  WHERE admin_level = 2
) TO '/dev/stdout' (FORMAT PARQUET);"
