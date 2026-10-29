#!/usr/bin/env bash
# Boundaries of the admin units that have DHIS2 indicator values, simplified for the
# indicator map (a GeoJSON source keyed by Location id, so no tile build is needed).
# Not a Library: it needs the locations table's geometry, and a Library can read only views,
# other Libraries and LocationHierarchy.
set -euo pipefail
DATA="${DATA:-$(cd "$(dirname "$0")/../../../../../data" && pwd)}"
has() { [ -n "$(find "$1" -path '*/country=*' -name '*.parquet' 2>/dev/null | head -1)" ]; }
V="$DATA/parquet/indicator_value/country=*/**/*.parquet"
if ! has "$DATA/parquet/indicator_value"; then
  echo '{"type":"FeatureCollection","features":[]}'
  exit 0
fi
duckdb -noheader -list -c "
LOAD spatial;
WITH ids AS (SELECT DISTINCT location_id FROM read_parquet('$V', hive_partitioning=true, union_by_name=true)),
     u AS (
  SELECT l.id, l.name, l.admin_level, l.admin1_name, l.country,
         ST_SimplifyPreserveTopology(l.geometry, 0.002) AS geometry
  FROM read_parquet('$DATA/parquet/locations/country=*/**/*.parquet', hive_partitioning=true, union_by_name=true) l
  JOIN ids ON ids.location_id = l.id
  WHERE l.type = 'admin-unit' AND l.geom_type = 'polygon'
)
SELECT json_object('type', 'FeatureCollection', 'features', coalesce(json_group_array(json_object(
  'type', 'Feature',
  'properties', json_object('id', id, 'name', name, 'admin_level', admin_level, 'admin1_name', admin1_name, 'country', country),
  'geometry', ST_AsGeoJSON(geometry)::JSON)), '[]'::JSON))
FROM u;"
