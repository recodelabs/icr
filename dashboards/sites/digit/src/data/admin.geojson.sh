#!/usr/bin/env bash
# Nigeria's states (37) and LGAs (774) from GRID3, as the ICR's location registry holds them
# (grid3_nga, copied into the DIGIT warehouse by country/digit/warehouse.sh), each flagged with
# whether DIGIT has a matching unit. DIGIT itself holds no geometry; 168 of its units in the ADMIN
# (STATE → LGA) and NIGERIA (PROVINCE → DISTRICT) hierarchies carry the `icr-location` identifier
# of their GRID3 unit (DigitLocation.icr_location_id), which is the match. Both hierarchies can
# match the same GRID3 unit; its DIGIT names and hierarchies are then listed together.
#
# A matched unit also carries counts over all campaigns for the places under its DIGIT units in
# DIGIT's hierarchy (by partOf, not by geometry): household dwellings, households registered
# (distinct households of the "Register household" tasks) and visits (the other tasks), each task
# placed by its dwelling (Task.location).
#
# Geometry is simplified (0.003°, about 300 m) and rounded to 4 decimals to keep the file small.
# Without grid3_nga, only the DIGIT units' own boundaries (fhir-pipes' locations table) are drawn.
set -euo pipefail
. "$(dirname "$0")/../../loaders.sh"
has() { [ -n "$(find "$W/$1" -path "*$2*" -name '*.parquet' -print -quit 2>/dev/null)" ]; }
if has grid3_nga ""; then
  BASE="SELECT id, name, CASE admin_level WHEN 1 THEN 'state' ELSE 'lga' END AS kind, admin1_name AS state, pcode, geometry
        FROM read_parquet('$W/grid3_nga/*.parquet')"
elif has locations geom_type=polygon; then
  BASE="SELECT d.icr_location_id AS id, d.name, CASE WHEN regexp_matches(d.type_text, '^(STATE|PROVINCE)') THEN 'state' ELSE 'lga' END AS kind,
               NULL AS state, d.pcode, p.geometry
        FROM read_parquet('$W/locations/*/geom_type=polygon/*/*.parquet', hive_partitioning=true) p
        JOIN $(T digit_location 'location_id VARCHAR, name VARCHAR, type_text VARCHAR, pcode VARCHAR, icr_location_id VARCHAR') d ON d.location_id = p.id"
else
  echo '{"type":"FeatureCollection","features":[]}'; exit 0
fi
duckdb -list -noheader -c "
LOAD spatial;
WITH base AS ($BASE),
  dl AS (SELECT * FROM $(T digit_location 'location_id VARCHAR, name VARCHAR, type_text VARCHAR, icr_location_id VARCHAR')),
  -- The DIGIT units matched to a GRID3 unit.
  du AS (SELECT location_id, name, icr_location_id, regexp_extract(type_text, 'DIGIT (.+) hierarchy', 1) AS hierarchy
         FROM dl WHERE icr_location_id IS NOT NULL),
  -- Every place with a position (dwellings, facilities) and its ancestors, from fhir-pipes' table.
  anc AS (SELECT id AS place_id, type, unnest(ancestor_ids) AS unit_id
          FROM read_parquet('$W/locations/*/geom_type=point/*/*.parquet', hive_partitioning=true)),
  t AS (SELECT location_id, code, for_group_id FROM $(T campaign_task 'location_id VARCHAR, code VARCHAR, for_group_id VARCHAR')),
  stats AS (
    SELECT du.icr_location_id,
           count(DISTINCT a.place_id) FILTER (WHERE a.type = 'household') AS dwellings,
           count(DISTINCT t.for_group_id) FILTER (WHERE t.code = 'Register household') AS households,
           count(t.location_id) FILTER (WHERE t.code IS DISTINCT FROM 'Register household') AS visits
    FROM du JOIN anc a ON a.unit_id = du.location_id LEFT JOIN t ON t.location_id = a.place_id
    GROUP BY 1),
  m AS (SELECT icr_location_id, string_agg(DISTINCT hierarchy, ', ' ORDER BY hierarchy) AS digit_hierarchies,
               string_agg(DISTINCT name, ' / ' ORDER BY name) AS digit_names, string_agg(location_id, ' ' ORDER BY location_id) AS digit_ids
        FROM du GROUP BY 1),
  f AS (
    SELECT json_object('type', 'Feature', 'id', row_number() OVER (ORDER BY b.kind DESC, b.id),
      'properties', json_object(
        'id', b.id, 'name', b.name, 'kind', b.kind, 'state', b.state, 'pcode', b.pcode,
        'in_digit', m.icr_location_id IS NOT NULL, 'digit_hierarchies', m.digit_hierarchies,
        'digit_names', m.digit_names, 'digit_ids', m.digit_ids,
        'dwellings', s.dwellings, 'households', s.households, 'visits', s.visits),
      'geometry', ST_AsGeoJSON(ST_ReducePrecision(ST_SimplifyPreserveTopology(b.geometry, 0.003), 0.0001))::JSON) AS feature
    FROM base b LEFT JOIN m ON m.icr_location_id = b.id LEFT JOIN stats s ON s.icr_location_id = b.id)
SELECT '{\"type\":\"FeatureCollection\",\"features\":[' || coalesce(string_agg(feature::VARCHAR, ','), '') || ']}' FROM f;"
