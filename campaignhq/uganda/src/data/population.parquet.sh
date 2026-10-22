#!/usr/bin/env bash
# One row per place (country, regions, districts and cities): the Ministry of Health's total
# population 2026 and catch population 2025 (from the targets workbook) beside WorldPop's 2026
# total, read from the target-population Groups by their ids.
set -euo pipefail
W="$(cd "$(dirname "$0")/../../warehouse/parquet" && pwd)"
export DUCKDB_AGENT_MODE=0
P() { echo "read_parquet('$W/$1/**/*.parquet', hive_partitioning=true, union_by_name=true)"; }
duckdb -c "
COPY (
  WITH g AS (SELECT * FROM $(P target_population))
  SELECT l.id AS location_id, l.name AS location_name, l.admin_level, coalesce(l.admin1_name, l.name) AS region,
         max(CASE WHEN g.group_id = 'ichd-2026-10-population-2026-' || l.id THEN g.quantity END) AS moh_2026,
         max(CASE WHEN g.group_id = 'ichd-2026-10-catch-population-2025-' || l.id THEN g.quantity END) AS catch_2025,
         max(CASE WHEN g.group_id = 'pop-worldpop-2026-' || l.id THEN g.quantity END) AS worldpop_2026
  FROM $(P locations) l LEFT JOIN g ON g.location_id = l.id
  WHERE l.type = 'admin-unit'
  GROUP BY ALL ORDER BY l.admin_level, region, location_name
) TO '/dev/stdout' (FORMAT PARQUET);"
