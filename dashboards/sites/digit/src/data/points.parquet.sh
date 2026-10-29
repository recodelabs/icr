#!/usr/bin/env bash
# The Locations that have coordinates (DigitLocation): health facilities and household dwellings,
# with the name of the boundary each sits in. These are the only places with a position; the
# boundaries have none.
set -euo pipefail
. "$(dirname "$0")/../../loaders.sh"
duckdb -c "
COPY (
  WITH l AS (SELECT * FROM $(T digit_location 'location_id VARCHAR, name VARCHAR, type VARCHAR, type_text VARCHAR, part_of_id VARCHAR, lat DOUBLE, lon DOUBLE'))
  SELECT p.location_id, p.name,
         CASE WHEN p.type = 'facility' THEN 'facility' ELSE 'dwelling' END AS kind,
         p.type AS location_type, p.type_text,
         b.name AS boundary_name, regexp_extract(b.type_text, 'DIGIT (.+) hierarchy', 1) AS hierarchy,
         CAST(p.lon AS FLOAT) AS lon, CAST(p.lat AS FLOAT) AS lat
  FROM l p LEFT JOIN l b ON b.location_id = p.part_of_id
  WHERE p.lat IS NOT NULL AND p.lon IS NOT NULL AND p.lat BETWEEN -90 AND 90 AND p.lon BETWEEN -180 AND 180
    AND NOT (p.lat = 0 AND p.lon = 0)
  ORDER BY kind, p.location_id
) TO '/dev/stdout' (FORMAT PARQUET);"
