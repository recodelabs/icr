#!/usr/bin/env bash
# Visits and household registrations per campaign (or round) and Nigerian LGA, for the delivery
# page's map. A task is placed by its dwelling (Task.location) and attributed to an LGA the same way
# as the georegistry shading: through DIGIT's partOf hierarchy (the dwelling's ancestors in
# fhir-pipes' locations table) to the DIGIT LGA or district that is matched to a GRID3 LGA
# (DigitLocation.icr_location_id). `lga_id` is that GRID3 id (as in admin.geojson), or NULL for
# tasks that do not roll up to a matched LGA (no dwelling, a dwelling without coordinates, or one
# in a hierarchy without boundaries); `hierarchy` is then the DIGIT hierarchy of the dwelling's
# boundary, where there is one.
#   visits      tasks other than "Register household"
#   households  distinct households registered ("Register household" tasks)
set -euo pipefail
. "$(dirname "$0")/../../loaders.sh"
POINTS="$W/locations/*/geom_type=point/*/*.parquet"
if [ -z "$(find "$W/locations" -path '*geom_type=point*' -name '*.parquet' -print -quit 2>/dev/null)" ]; then
  ANC="SELECT NULL::VARCHAR AS place_id, NULL::VARCHAR AS unit_id WHERE false"
else
  ANC="SELECT id AS place_id, unnest(ancestor_ids) AS unit_id FROM read_parquet('$POINTS', hive_partitioning=true)"
fi
duckdb -c "
COPY (
  WITH dl AS (SELECT * FROM $(T digit_location 'location_id VARCHAR, type_text VARCHAR, part_of_id VARCHAR, icr_location_id VARCHAR')),
  -- DIGIT LGAs and districts matched to GRID3.
  lga AS (SELECT location_id, icr_location_id FROM dl
          WHERE icr_location_id IS NOT NULL AND regexp_matches(type_text, '^(LGA|DISTRICT) ')),
  place_lga AS (SELECT a.place_id, min(l.icr_location_id) AS lga_id FROM ($ANC) a JOIN lga l ON l.location_id = a.unit_id GROUP BY 1),
  t AS (SELECT * FROM $(T campaign_task 'task_id VARCHAR, campaign_id VARCHAR, code VARCHAR, for_group_id VARCHAR, location_id VARCHAR')),
  cal AS (SELECT DISTINCT campaign_id, coalesce(parent_campaign_id, campaign_id) AS umbrella_id
          FROM $(T campaign_calendar 'campaign_id VARCHAR, parent_campaign_id VARCHAR'))
  SELECT t.campaign_id, coalesce(c.umbrella_id, t.campaign_id) AS umbrella_id, p.lga_id,
         CASE WHEN p.lga_id IS NULL THEN regexp_extract(b.type_text, 'DIGIT (.+) hierarchy', 1) END AS hierarchy,
         count(*) FILTER (WHERE t.code IS DISTINCT FROM 'Register household') AS visits,
         count(DISTINCT t.for_group_id) FILTER (WHERE t.code = 'Register household') AS households
  FROM t
  LEFT JOIN place_lga p ON p.place_id = t.location_id
  LEFT JOIN dl d ON d.location_id = t.location_id
  LEFT JOIN dl b ON b.location_id = d.part_of_id
  LEFT JOIN cal c USING (campaign_id)
  GROUP BY ALL
  ORDER BY umbrella_id, campaign_id, lga_id
) TO '/dev/stdout' (FORMAT PARQUET);"
