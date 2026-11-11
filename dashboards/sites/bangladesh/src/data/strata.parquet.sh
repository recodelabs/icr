#!/usr/bin/env bash
# The sex breakdown of every MR value (IcrIndicatorStrata): dx, location_id, period, sex,
# numerator, denominator, count, value (as DHIS2 shows it).
set -euo pipefail
PARQUET="${DATA:-$(cd "$(dirname "$0")/../../../../../country/bangladesh/warehouse" && pwd)}/parquet"
duckdb -c "
COPY (
  WITH s AS (SELECT * FROM read_parquet('$PARQUET/indicator_strata/**/*.parquet', hive_partitioning=true, union_by_name=true)),
       i AS (SELECT * FROM read_parquet('$PARQUET/indicator/**/*.parquet', hive_partitioning=true, union_by_name=true))
  SELECT regexp_replace(i.measure_id, '^' || i.source || '-', '') AS dx, s.location_id, s.period, s.option_name AS sex,
         s.numerator, s.denominator, s.count, round(s.score * coalesce(i.factor, 1), 2) AS value
  FROM s JOIN i ON i.url = s.measure
  WHERE s.dimension = 'ASLMEOYnDKi'
  ORDER BY dx, s.location_id, s.period, sex
) TO '/dev/stdout' (FORMAT PARQUET);"
