#!/usr/bin/env bash
# The indicator catalogue (IcrIndicator): one row per Measure that has DHIS2 values.
# The SQL lives in the Library analytics/MainIndicatorCatalog.sql; the refresh writes its result to the warehouse
# as main_indicator_catalog (one file, not partitioned). This loader copies it, in the Library's order.
set -euo pipefail
DATA="${DATA:-$(cd "$(dirname "$0")/../../../../../data" && pwd)}"
P() { echo "read_parquet('$DATA/parquet/$1/**/*.parquet', hive_partitioning=true, union_by_name=true, hive_types_autocast=false)"; }
duckdb -c "
COPY (
  SELECT * FROM $(P main_indicator_catalog)
  ORDER BY topic, indicator, indicator_id
) TO '/dev/stdout' (FORMAT PARQUET);"
