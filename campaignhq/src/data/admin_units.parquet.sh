#!/usr/bin/env bash
# Admin units (states + LGAs) with centroids, for labels, filters and map fitting.
set -euo pipefail
DATA="$(cd "$(dirname "$0")/../../../data" && pwd)"
duckdb -c "
LOAD spatial;
COPY (
  SELECT id, name, admin_level, admin1_name, path, country,
         ST_X(ST_Centroid(geometry)) AS lon, ST_Y(ST_Centroid(geometry)) AS lat,
         ST_XMin(geometry) AS xmin, ST_YMin(geometry) AS ymin, ST_XMax(geometry) AS xmax, ST_YMax(geometry) AS ymax
  FROM read_parquet('$DATA/parquet/locations/**/*.parquet', hive_partitioning=true, union_by_name=true)
  WHERE type = 'admin-unit' AND geom_type = 'polygon' AND admin_level IN (1, 2)
  ORDER BY admin_level, name
) TO '/dev/stdout' (FORMAT PARQUET);"
