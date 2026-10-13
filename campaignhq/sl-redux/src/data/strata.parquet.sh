#!/usr/bin/env bash
# Breakdowns of DHIS2 values (IcrIndicatorStrata): one row per item × place × period ×
# dimension option, e.g. Fixed / Outreach, or CHC / CHP / MCHP. `value` as DHIS2 shows it.
set -euo pipefail
DATA="${DATA:-$(cd "$(dirname "$0")/../../../../data" && pwd)}"
COUNTRY="${COUNTRY:-SLE}"
PREFIX="${PREFIX:-sle-}"
if [ -z "$(find "$DATA/parquet/indicator_strata" -name '*.parquet' 2>/dev/null | head -1)" ]; then
  duckdb -c "COPY (SELECT NULL::VARCHAR AS dx, NULL::VARCHAR AS location_id, NULL::VARCHAR AS period, NULL::VARCHAR AS dimension,
    NULL::VARCHAR AS dimension_name, NULL::VARCHAR AS option, NULL::VARCHAR AS option_name, NULL::BIGINT AS numerator,
    NULL::BIGINT AS denominator, NULL::DOUBLE AS value WHERE FALSE) TO '/dev/stdout' (FORMAT PARQUET);"
  exit 0
fi
duckdb -c "
COPY (
  WITH s AS (SELECT * FROM read_parquet('$DATA/parquet/indicator_strata/country=*/*.parquet', hive_partitioning=true, union_by_name=true)
             WHERE country = '$COUNTRY' OR (country IS NULL AND location_id LIKE '$PREFIX%')),
       i AS (SELECT * FROM read_parquet('$DATA/parquet/indicator/country=*/*.parquet', hive_partitioning=true, union_by_name=true))
  SELECT regexp_replace(i.measure_id, '^' || i.source || '-', '') AS dx, s.location_id, s.period,
         s.dimension, s.dimension_name, s.option, s.option_name, s.numerator, s.denominator,
         round(s.score * coalesce(i.factor, 1), 2) AS value
  FROM s JOIN i ON i.url = s.measure
) TO '/dev/stdout' (FORMAT PARQUET);"
