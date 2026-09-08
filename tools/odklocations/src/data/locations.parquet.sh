#!/usr/bin/env bash
# The registry rows this page filters and exports: facilities, settlements, and
# LGA/state boundaries for Nigeria, flattened to the column names the page's SQL
# and the LAYERS map expect (state/lga/ward instead of admin1_name/2/3).
set -euo pipefail
DATA="$(cd "$(dirname "$0")/../../../../data" && pwd)"
duckdb -c "
LOAD spatial;
COPY (
  SELECT id, name, type, admin_level,
         admin1_name AS state, admin2_name AS lga, admin3_name AS ward,
         pcode, nhfr_code, status, settlement_type,
         replace(facility_level_text, chr(160), ' ') AS facility_level,
         ownership_text AS ownership,
         ST_AsGeoJSON(geometry) AS geometry_geojson
  FROM read_parquet('$DATA/parquet/locations/**/*.parquet', hive_partitioning=true, union_by_name=true)
  WHERE country = 'NGA'
    AND (type IN ('facility', 'settlement') OR (type = 'admin-unit' AND admin_level IN (1, 2)))
) TO '/dev/stdout' (FORMAT PARQUET);"
