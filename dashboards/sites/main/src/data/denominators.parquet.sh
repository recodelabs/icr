#!/usr/bin/env bash
# Two total-population denominators per admin unit and estimate year, side by side: WorldPop
# and the census projection (IcrTargetPopulation), with the unit's name, level and state.
# The SQL lives in the Library analytics/MainDenominators.sql; the refresh writes its result to the warehouse
# as main_denominators (partitioned by country). This loader copies it, in the Library's order.
set -euo pipefail
DATA="${DATA:-$(cd "$(dirname "$0")/../../../../../data" && pwd)}"
P() { echo "read_parquet('$DATA/parquet/$1/**/*.parquet', hive_partitioning=true, union_by_name=true, hive_types_autocast=false)"; }
duckdb -c "
COPY (
  SELECT * FROM $(P main_denominators)
  ORDER BY estimate_date, admin_level, state, location_name, location_id
) TO '/dev/stdout' (FORMAT PARQUET);"
