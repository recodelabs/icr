#!/usr/bin/env bash
# DHIS2 indicator values (IcrIndicatorValue) joined to the indicator catalogue (IcrIndicator) and
# the admin units, one row per indicator x place x period. `value` is the figure as DHIS2 shows
# it (score x factor).
# The SQL lives in the Library analytics/MainIndicatorValues.sql; the refresh writes its result to the warehouse
# as main_indicator_values (partitioned by country). This loader copies it, in the Library's order.
set -euo pipefail
DATA="${DATA:-$(cd "$(dirname "$0")/../../../../../data" && pwd)}"
P() { echo "read_parquet('$DATA/parquet/$1/**/*.parquet', hive_partitioning=true, union_by_name=true, hive_types_autocast=false)"; }
duckdb -c "
COPY (
  SELECT * FROM $(P main_indicator_values)
  ORDER BY indicator, admin_level, location_name, period_start, location_id, period
) TO '/dev/stdout' (FORMAT PARQUET);"
