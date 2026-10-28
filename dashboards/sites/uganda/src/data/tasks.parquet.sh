#!/usr/bin/env bash
# The campaign tasks: one per district and activity for now, with the district's name and region.
# The SQL lives in the Library analytics/UgandaTasks.sql; the refresh writes its result to the warehouse
# as uganda_tasks (one file, not partitioned). This loader copies it, in the Library's order.
set -euo pipefail
# The Uganda warehouse: a copy pulled from R2 uga/ by observatory, or country/uganda/warehouse.
DATA="${DATA:-$(cd "$(dirname "$0")/../../../../../country/uganda/warehouse" && pwd)}"
W="$DATA/parquet"
export DUCKDB_AGENT_MODE=0
P() { echo "read_parquet('$W/$1/part-0.parquet')"; }
duckdb -c "
COPY (
  SELECT * FROM $(P uganda_tasks)
  ORDER BY region, location_name, activity_key, task_id
) TO '/dev/stdout' (FORMAT PARQUET);"
