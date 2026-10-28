#!/usr/bin/env bash
# One row per campaign x activity x target Group: the ICHD targets as the campaigns hold them, with
# the campaign's place and the Group's count, name and age band.
# The SQL lives in the Library analytics/UgandaTargets.sql; the refresh writes its result to the warehouse
# as uganda_targets (flat or partitioned by country). This loader copies it, in the Library's order.
set -euo pipefail
# The Uganda warehouse: a copy pulled from R2 uga/ by observatory, or country/uganda/warehouse.
DATA="${DATA:-$(cd "$(dirname "$0")/../../../../../country/uganda/warehouse" && pwd)}"
W="$DATA/parquet"
export DUCKDB_AGENT_MODE=0
P() { echo "read_parquet('$W/$1/**/*.parquet', hive_partitioning=true, union_by_name=true, hive_types_autocast=false)"; }
duckdb -c "
COPY (
  SELECT * FROM $(P uganda_targets)
  ORDER BY admin_level, region, location_name, activity_key, group_id
) TO '/dev/stdout' (FORMAT PARQUET);"
