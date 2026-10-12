#!/usr/bin/env bash
# The indicator catalogue (IcrIndicator): one row per Measure that has DHIS2 values.
set -euo pipefail
DATA="$(cd "$(dirname "$0")/../../../data" && pwd)"
has() { [ -n "$(find "$1" -path '*/country=*' -name '*.parquet' 2>/dev/null | head -1)" ]; }
I="$DATA/parquet/indicator/country=*/**/*.parquet"
if ! has "$DATA/parquet/indicator"; then
  duckdb -c "COPY (SELECT NULL::VARCHAR AS indicator_id, NULL::VARCHAR AS indicator, NULL::VARCHAR AS topic, NULL::VARCHAR AS scoring,
    NULL::DOUBLE AS factor, NULL::VARCHAR AS indicator_type, NULL::BOOLEAN AS annualized, NULL::VARCHAR AS source,
    NULL::VARCHAR AS publisher, NULL::VARCHAR AS description, NULL::VARCHAR AS numerator_description,
    NULL::VARCHAR AS denominator_description WHERE FALSE) TO '/dev/stdout' (FORMAT PARQUET);"
  exit 0
fi
duckdb -c "
COPY (
  SELECT measure_id AS indicator_id, title AS indicator, topic, scoring, coalesce(factor, 1) AS factor,
         indicator_type, annualized, source, publisher, description, numerator_description, denominator_description
  FROM read_parquet('$I', hive_partitioning=true, union_by_name=true)
  WHERE factor IS NOT NULL
  ORDER BY topic, title
) TO '/dev/stdout' (FORMAT PARQUET);"
