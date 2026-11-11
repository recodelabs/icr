#!/usr/bin/env bash
# Bangladesh places down to upazila level from the warehouse's Location registry: id (the FHIR
# Location id, bgd-<DHIS2 uid>), name, level (1 country … 4 upazila, the campaign DHIS2's org unit
# levels), division, district, and kind: division, district, city corporation, camp, upazila,
# municipality, zone, other. Places only the routine e-Tracker has (bgd-et-…) are left out.
set -euo pipefail
PARQUET="${DATA:-$(cd "$(dirname "$0")/../../../../../country/bangladesh/warehouse" && pwd)}/parquet"
duckdb -c "
COPY (
  WITH u AS (
    SELECT id, name, depth + 1 AS level, part_of AS parent
    FROM read_parquet('$PARQUET/locations/**/*.parquet', hive_partitioning=true, union_by_name=true)
    WHERE id LIKE 'bgd-%' AND id NOT LIKE 'bgd-et-%' AND depth <= 3
  ),
  l2 AS (SELECT * FROM u WHERE level = 2), l3 AS (SELECT * FROM u WHERE level = 3)
  SELECT u.id, u.name, u.level,
         regexp_replace(coalesce(CASE u.level WHEN 2 THEN u.name WHEN 3 THEN p2.name WHEN 4 THEN g2.name END, ''), ' Division$', '') AS division,
         regexp_replace(coalesce(CASE u.level WHEN 3 THEN u.name WHEN 4 THEN p3.name END, ''), ' District$', '') AS district,
         CASE WHEN u.level = 1 THEN 'country' WHEN u.level = 2 THEN 'division'
              WHEN u.level = 3 AND u.name LIKE '% District' THEN 'district'
              WHEN u.level = 3 AND u.name LIKE '% CC' THEN 'city corporation'
              WHEN u.level = 3 AND u.name ILIKE '%camp%' THEN 'camp'
              WHEN u.level = 4 AND u.name ILIKE '%upazila%' THEN 'upazila'
              WHEN u.level = 4 AND u.name ILIKE '%municipality%' THEN 'municipality'
              WHEN u.level = 4 AND u.name ILIKE '%zone%' THEN 'zone'
              WHEN u.level = 4 AND p3.name LIKE '% District' AND u.name NOT ILIKE '%site%' AND u.name NOT LIKE 'HF\_%' ESCAPE '\' THEN 'upazila'
              ELSE 'other' END AS kind
  FROM u
  LEFT JOIN l2 p2 ON u.level = 3 AND p2.id = u.parent
  LEFT JOIN l3 p3 ON u.level = 4 AND p3.id = u.parent
  LEFT JOIN l2 g2 ON u.level = 4 AND g2.id = p3.parent
  ORDER BY u.level, division, district, u.name
) TO '/dev/stdout' (FORMAT PARQUET);"
