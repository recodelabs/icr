#!/usr/bin/env bash
# The full location registry — points and polygons together, one row per
# location — flattened for the browser. Geometry is pre-converted to GeoJSON
# text here (DuckDB's spatial extension, at build time) so the page's
# DuckDB-WASM instance never needs the spatial extension itself; it just
# filters plain columns and hands the geometry_geojson string straight to
# the odk-locations wasm module.
set -euo pipefail
DATA="$(cd "$(dirname "$0")/../../../../data" && pwd)"
duckdb -c "
LOAD spatial;
COPY (
  SELECT id, name, type, status, country, admin_level,
         admin1_name AS state, admin2_name AS lga, admin3_name AS ward,
         replace(facility_level_text, chr(160), ' ') AS facility_level,
         ownership_text AS ownership, settlement_type,
         pcode, gers_id, nhfr_code, nhfr_uid,
         managing_organization, part_of, last_updated,
         geom_type,
         ST_AsGeoJSON(geometry) AS geometry_geojson
  FROM read_parquet('$DATA/parquet/locations/**/*.parquet', hive_partitioning=true, union_by_name=true)
  WHERE country = 'NGA' AND geometry IS NOT NULL
) TO '/dev/stdout' (FORMAT PARQUET);"
