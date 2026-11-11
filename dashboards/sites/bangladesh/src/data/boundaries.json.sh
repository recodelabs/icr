#!/usr/bin/env bash
# District, city corporation (admin level 2) and upazila-level (3) boundaries from the local
# warehouse's Location registry, as one GeoJSON FeatureCollection keyed by Location id, with
# id, name, admin_level and district. Simplified (~100 m) so the browser gets a few MB.
# The polygons come from the DGHS GIS dashboard and the CC ward shapefiles (see tools/bd-fhir).
set -euo pipefail
PARQUET="${DATA:-$(cd "$(dirname "$0")/../../../../../country/bangladesh/warehouse" && pwd)}/parquet"
duckdb -noheader -list -c "
INSTALL spatial; LOAD spatial;
WITH l AS (
  SELECT id, name, admin_level, coalesce(admin2_name, '') AS district,
         ST_SimplifyPreserveTopology(geometry, 0.001) AS g
  FROM read_parquet('$PARQUET/locations/**/*.parquet', hive_partitioning=true, union_by_name=true)
  WHERE admin_level IN (2, 3) AND geom_type IN ('polygon', 'multipolygon') AND type = 'admin-unit'
)
SELECT json_object('type', 'FeatureCollection', 'features', list(json_object(
  'type', 'Feature', 'id', id,
  'properties', json_object('id', id, 'name', name, 'admin_level', admin_level, 'district', district),
  'geometry', ST_AsGeoJSON(g)::JSON)))
FROM l WHERE g IS NOT NULL;"
