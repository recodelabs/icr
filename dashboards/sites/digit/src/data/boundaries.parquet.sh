#!/usr/bin/env bash
# Every boundary (admin-unit Location, DigitLocation view), with its DIGIT hierarchy, level and
# level name, read from the type text the importer writes ("PHU (DIGIT SIERRALEONE hierarchy,
# level 7)"), its parent's name, and how many boundaries, facilities and dwellings sit directly
# under it. DIGIT's boundaries have no geometry. The Nigerian states and LGAs matched to GRID3
# (168 units) carry a boundary from the ICR's registry: `has_boundary`, with their P-code, the ICR
# Location id and GRID3's spelling where it differs (`alias`). The polygons are in admin.geojson.
set -euo pipefail
. "$(dirname "$0")/../../loaders.sh"
duckdb -c "
COPY (
  WITH l AS (SELECT * FROM $(T digit_location 'location_id VARCHAR, name VARCHAR, type VARCHAR, type_text VARCHAR, part_of_id VARCHAR, boundary_code VARCHAR, code VARCHAR, pcode VARCHAR, icr_location_id VARCHAR, alias VARCHAR, has_boundary BOOLEAN')),
  kids AS (SELECT part_of_id AS location_id,
                  count(*) FILTER (WHERE type = 'admin-unit') AS child_boundaries,
                  count(*) FILTER (WHERE type = 'facility') AS facilities,
                  count(*) FILTER (WHERE type IS DISTINCT FROM 'admin-unit' AND type IS DISTINCT FROM 'facility') AS other_places
           FROM l WHERE part_of_id IS NOT NULL GROUP BY 1)
  SELECT b.location_id, b.name,
         regexp_extract(b.type_text, 'DIGIT (.+) hierarchy', 1) AS hierarchy,
         TRY_CAST(regexp_extract(b.type_text, 'level (\\d+)', 1) AS INTEGER) AS level,
         trim(regexp_extract(b.type_text, '^([^(]+)', 1)) AS level_name,
         b.part_of_id, p.name AS parent_name, coalesce(b.boundary_code, b.code) AS code,
         coalesce(k.child_boundaries, 0) AS child_boundaries, coalesce(k.facilities, 0) AS facilities,
         coalesce(k.other_places, 0) AS other_places,
         coalesce(b.has_boundary, false) AS has_boundary, b.pcode, b.icr_location_id, b.alias
  FROM l b LEFT JOIN l p ON p.location_id = b.part_of_id LEFT JOIN kids k ON k.location_id = b.location_id
  WHERE b.type = 'admin-unit'
  ORDER BY hierarchy, level, name
) TO '/dev/stdout' (FORMAT PARQUET);"
