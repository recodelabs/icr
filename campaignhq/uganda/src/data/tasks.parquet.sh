#!/usr/bin/env bash
# The campaign tasks (IcrCampaignTask view): one per district and activity for now, with the
# district's name and region.
set -euo pipefail
W="$(cd "$(dirname "$0")/../../warehouse/parquet" && pwd)"
export DUCKDB_AGENT_MODE=0
P() { echo "read_parquet('$W/$1/**/*.parquet', hive_partitioning=true, union_by_name=true)"; }
duckdb -c "
COPY (
  SELECT t.task_id, t.campaign_id, regexp_extract(t.activity, '([^/]+)\$', 1) AS activity_key,
         t.location_id, l.name AS location_name, l.admin1_name AS region,
         t.status, t.intent, t.strategy, t.origin, t.execution_start, t.execution_end
  FROM $(P campaign_task) t LEFT JOIN $(P locations) l ON l.id = t.location_id
  ORDER BY region, location_name, activity_key
) TO '/dev/stdout' (FORMAT PARQUET);"
