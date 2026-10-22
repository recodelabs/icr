#!/usr/bin/env bash
# The campaign tasks (IcrCampaignTask view): one per district and activity for now, with the
# district's name and region.
set -euo pipefail
# The Uganda warehouse: a copy pulled from R2 uga/ by deploy.sh, or country/uganda/warehouse.
DATA="${DATA:-$(cd "$(dirname "$0")/../../../../country/uganda/warehouse" && pwd)}"
W="$DATA/parquet"
export DUCKDB_AGENT_MODE=0
# Globs start at country=*/ so the Portolan metadata beside the data (items.parquet) is not read.
P() { echo "read_parquet('$W/$1/country=*/**/*.parquet', hive_partitioning=true, union_by_name=true)"; }
duckdb -c "
COPY (
  SELECT t.task_id, t.campaign_id, regexp_extract(t.activity, '([^/]+)\$', 1) AS activity_key,
         t.location_id, l.name AS location_name, l.admin1_name AS region,
         t.status, t.intent, t.strategy, t.origin, t.execution_start, t.execution_end
  FROM $(P campaign_task) t LEFT JOIN $(P locations) l ON l.id = t.location_id
  ORDER BY region, location_name, activity_key
) TO '/dev/stdout' (FORMAT PARQUET);"
