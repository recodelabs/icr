#!/usr/bin/env bash
# The boundaries of the DIGIT admin units that have one: the Nigerian states and LGAs of the ADMIN
# (STATE → LGA) and NIGERIA (PROVINCE → DISTRICT) hierarchies matched to GRID3 in the ICR's
# location registry, 168 units. DIGIT itself holds no geometry. The polygons are fhir-pipes'
# location table (geom_type=polygon), lightly simplified; names, levels and codes come from
# DigitLocation.
#
# Each feature also carries counts over all campaigns for the places under the unit in DIGIT's
# hierarchy (by partOf, not by geometry): household dwellings, households registered (distinct
# households of the "Register household" tasks) and visits (the other tasks), each task placed by
# its dwelling (Task.location).
set -euo pipefail
. "$(dirname "$0")/../../loaders.sh"
POLY="$W/locations/*/geom_type=polygon/type=admin-unit/*.parquet"
if [ -z "$(find "$W/locations" -path '*geom_type=polygon*' -name '*.parquet' -print -quit 2>/dev/null)" ]; then
  echo '{"type":"FeatureCollection","features":[]}'; exit 0
fi
duckdb -list -noheader -c "
LOAD spatial;
WITH poly AS (SELECT id, geometry FROM read_parquet('$POLY', hive_partitioning=true)),
  dl AS (SELECT * FROM $(T digit_location 'location_id VARCHAR, name VARCHAR, type_text VARCHAR, part_of_id VARCHAR, pcode VARCHAR, icr_location_id VARCHAR, alias VARCHAR')),
  -- Every place with a position (dwellings, facilities) and its ancestors, from fhir-pipes' table.
  anc AS (SELECT id AS place_id, type, unnest(ancestor_ids) AS unit_id
          FROM read_parquet('$W/locations/*/geom_type=point/*/*.parquet', hive_partitioning=true)),
  t AS (SELECT location_id, code, for_group_id FROM $(T campaign_task 'location_id VARCHAR, code VARCHAR, for_group_id VARCHAR')),
  stats AS (
    SELECT a.unit_id,
           count(DISTINCT a.place_id) FILTER (WHERE a.type = 'household') AS dwellings,
           count(DISTINCT t.for_group_id) FILTER (WHERE t.code = 'Register household') AS households,
           count(t.location_id) FILTER (WHERE t.code IS DISTINCT FROM 'Register household') AS visits
    FROM anc a LEFT JOIN t ON t.location_id = a.place_id
    WHERE a.unit_id IN (SELECT id FROM poly) GROUP BY 1),
  f AS (
    SELECT json_object('type', 'Feature', 'id', row_number() OVER (ORDER BY p.id),
      'properties', json_object(
        'id', p.id, 'name', d.name,
        'kind', CASE WHEN regexp_matches(d.type_text, '^(STATE|PROVINCE)') THEN 'state' ELSE 'lga' END,
        'level_name', trim(regexp_extract(d.type_text, '^([^(]+)', 1)),
        'hierarchy', regexp_extract(d.type_text, 'DIGIT (.+) hierarchy', 1),
        'parent', pd.name, 'pcode', d.pcode, 'icr_location_id', d.icr_location_id, 'alias', d.alias,
        'dwellings', coalesce(s.dwellings, 0), 'households', coalesce(s.households, 0), 'visits', coalesce(s.visits, 0)),
      'geometry', ST_AsGeoJSON(ST_SimplifyPreserveTopology(p.geometry, 0.002))::JSON) AS feature
    FROM poly p LEFT JOIN dl d ON d.location_id = p.id LEFT JOIN dl pd ON pd.location_id = d.part_of_id
    LEFT JOIN stats s ON s.unit_id = p.id)
SELECT '{\"type\":\"FeatureCollection\",\"features\":[' || coalesce(string_agg(feature::VARCHAR, ','), '') || ']}' FROM f;"
