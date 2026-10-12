#!/usr/bin/env bash
# Country, district and chiefdom boundaries (levels 0–2), simplified, keyed by Location id.
set -euo pipefail
DATA="${DATA:-$(cd "$(dirname "$0")/../../../../data" && pwd)}"
COUNTRY="${COUNTRY:-SLE}"
duckdb -noheader -list -c "
LOAD spatial;
WITH u AS (
  SELECT id, name, admin_level, admin1_name, ST_SimplifyPreserveTopology(geometry, 0.002) AS geometry
  FROM read_parquet('$DATA/parquet/locations/country=$COUNTRY/**/*.parquet', hive_partitioning=true, union_by_name=true)
  WHERE type = 'admin-unit' AND geom_type = 'polygon' AND admin_level <= 2
)
SELECT json_object('type', 'FeatureCollection', 'features', coalesce(json_group_array(json_object(
  'type', 'Feature',
  'properties', json_object('id', id, 'name', name, 'admin_level', admin_level, 'admin1_name', admin1_name),
  'geometry', ST_AsGeoJSON(geometry)::JSON)), '[]'::JSON))
FROM u;"
