#!/usr/bin/env bash
# Endemicity assertions (IcrLocationStatus) for the NTD page: every assertion with its LGA and
# state names, plus a flag for the current one per LGA x property (newest wins).
# The SQL lives in the Library analytics/MainEndemicity.sql; the refresh writes its result to the warehouse
# as main_endemicity (partitioned by country). This loader copies it, in the Library's order.
set -euo pipefail
DATA="${DATA:-$(cd "$(dirname "$0")/../../../../../data" && pwd)}"
P() { echo "read_parquet('$DATA/parquet/$1/**/*.parquet', hive_partitioning=true, union_by_name=true, hive_types_autocast=false)"; }
duckdb -c "
COPY (
  SELECT * FROM $(P main_endemicity)
  ORDER BY property, state, location_name, effective, observation_id
) TO '/dev/stdout' (FORMAT PARQUET);"
