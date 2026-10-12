#!/usr/bin/env bash
# DHIS2 indicator values (IcrIndicatorValue, from `kiln dhis2 reports`) joined to the
# indicator catalogue (IcrIndicator) and the admin units, one row per indicator ×
# place × period. `value` is the figure as DHIS2 shows it (score × factor).
set -euo pipefail
DATA="$(cd "$(dirname "$0")/../../../data" && pwd)"
has() { [ -n "$(find "$1" -path '*/country=*' -name '*.parquet' 2>/dev/null | head -1)" ]; }
V="$DATA/parquet/indicator_value/country=*/**/*.parquet"
I="$DATA/parquet/indicator/country=*/**/*.parquet"
if ! has "$DATA/parquet/indicator_value" || ! has "$DATA/parquet/indicator"; then
  # No DHIS2 import on this server yet: an empty table with the same columns.
  duckdb -c "COPY (SELECT NULL::VARCHAR AS indicator_id, NULL::VARCHAR AS indicator, NULL::VARCHAR AS topic,
    NULL::DOUBLE AS factor, NULL::VARCHAR AS indicator_type, NULL::BOOLEAN AS annualized, NULL::VARCHAR AS source,
    NULL::VARCHAR AS location_id, NULL::VARCHAR AS location_name, NULL::INTEGER AS admin_level, NULL::VARCHAR AS admin1_name,
    NULL::VARCHAR AS country, NULL::VARCHAR AS period, NULL::VARCHAR AS period_type, NULL::DATE AS period_start,
    NULL::DATE AS period_end, NULL::BIGINT AS numerator, NULL::BIGINT AS denominator, NULL::BIGINT AS count,
    NULL::DOUBLE AS score, NULL::DOUBLE AS value, NULL::TIMESTAMPTZ AS reported WHERE FALSE) TO '/dev/stdout' (FORMAT PARQUET);"
  exit 0
fi
duckdb -c "
COPY (
  WITH v AS (SELECT * FROM read_parquet('$V', hive_partitioning=true, union_by_name=true)),
       i AS (SELECT * FROM read_parquet('$I', hive_partitioning=true, union_by_name=true)),
       l AS (SELECT id, name, admin_level, admin1_name
             FROM read_parquet('$DATA/parquet/locations/country=*/**/*.parquet', hive_partitioning=true, union_by_name=true)
             WHERE type = 'admin-unit')
  SELECT i.measure_id AS indicator_id, i.title AS indicator, i.topic, coalesce(i.factor, 1) AS factor,
         i.indicator_type, i.annualized, i.source,
         v.location_id, coalesce(l.name, v.location_name) AS location_name, l.admin_level, l.admin1_name, v.country,
         v.period,
         CASE WHEN regexp_matches(v.period, '^[0-9]{4}$') THEN 'Yearly'
              WHEN regexp_matches(v.period, '^[0-9]{6}$') THEN 'Monthly'
              WHEN regexp_matches(v.period, '^[0-9]{4}Q[1-4]$') THEN 'Quarterly'
              ELSE 'Other' END AS period_type,
         v.period_start, v.period_end, v.numerator, v.denominator, v.count, v.score,
         v.score * coalesce(i.factor, 1) AS value, v.reported
  FROM v JOIN i ON i.url = v.measure
  LEFT JOIN l ON l.id = v.location_id
  ORDER BY indicator, admin_level, location_name, period_start
) TO '/dev/stdout' (FORMAT PARQUET);"
