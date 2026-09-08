#!/usr/bin/env bash
# Endemicity assertions (from the IG ViewDefinition IcrLocationStatus) for the
# dashboard: every assertion with its LGA/state names, plus a flag for the
# current one per LGA × property (newest wins).
set -euo pipefail
DATA="$(cd "$(dirname "$0")/../../../data" && pwd)"
duckdb -c "
COPY (
  WITH s AS (SELECT * FROM read_parquet('$DATA/parquet/location_status/**/*.parquet', hive_partitioning=true, union_by_name=true)),
       loc AS (SELECT id, name, admin_level, admin1_name FROM read_parquet('$DATA/parquet/locations/country=*/**/*.parquet', hive_partitioning=true, union_by_name=true) WHERE type = 'admin-unit')
  SELECT s.observation_id, s.location_id, l.name AS location_name, l.admin1_name AS state, l.admin_level,
         s.property,
         regexp_replace(s.property, '-endemicity$', '') AS disease,
         s.status, s.effective, year(s.effective) AS effective_year,
         s.performer, s.method, s.evidence,
         s.figure_label, s.figure_value, s.figure_unit,
         s.country,
         row_number() OVER (PARTITION BY s.location_id, s.property ORDER BY s.effective DESC) = 1 AS is_current
  FROM s LEFT JOIN loc l ON l.id = s.location_id
  ORDER BY s.property, l.admin1_name, l.name, s.effective
) TO '/dev/stdout' (FORMAT PARQUET);"
