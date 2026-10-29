#!/usr/bin/env bash
# One row per campaign (IcrCampaignCalendar) for the overview and coverage pages: level,
# programme, state and LGA names, people targeted and per-activity targets, and the results
# from IcrCoverage (administrative coverage, the latest realtime figure, LQAS and survey).
# The SQL lives in the Library analytics/MainCampaigns.sql; the refresh writes its result to the warehouse
# as main_campaigns (partitioned by country). This loader copies it, in the Library's order.
set -euo pipefail
DATA="${DATA:-$(cd "$(dirname "$0")/../../../../../data" && pwd)}"
P() { echo "read_parquet('$DATA/parquet/$1/**/*.parquet', hive_partitioning=true, union_by_name=true, hive_types_autocast=false)"; }
duckdb -c "
COPY (
  SELECT * FROM $(P main_campaigns)
  ORDER BY period_start, location_id, campaign_id
) TO '/dev/stdout' (FORMAT PARQUET);"
