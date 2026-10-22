#!/usr/bin/env bash
# One row per campaign × activity × target Group: the ICHD targets as the campaigns hold them
# (CarePlan.activity.detail → planning-denominator, the IcrCampaignActivity view), with the
# campaign's place and the Group's count, name and age band. The target code is the middle of
# the Group id (ichd-2026-10-<code>-<location id>), as the view does not carry Group.code.
set -euo pipefail
W="$(cd "$(dirname "$0")/../../warehouse/parquet" && pwd)"
export DUCKDB_AGENT_MODE=0
P() { echo "read_parquet('$W/$1/**/*.parquet', hive_partitioning=true, union_by_name=true)"; }
duckdb -c "
COPY (
  SELECT a.campaign_id, c.status AS campaign_status, c.location_id, l.name AS location_name, l.admin_level,
         coalesce(l.admin1_name, l.name) AS region,
         regexp_extract(a.activity, '([^/]+)\$', 1) AS activity_key, a.activity_status,
         a.denominator_id AS group_id,
         regexp_extract(a.denominator_id, '^ichd-2026-10-(.+)-' || c.location_id || '\$', 1) AS target_code,
         regexp_replace(p.name, ', ' || l.name || ', .*\$', '') AS target_name,
         p.quantity, p.age_low, p.age_high, p.age_unit
  FROM $(P campaign_activity) a
  JOIN $(P campaign_calendar) c USING (campaign_id)
  LEFT JOIN $(P locations) l ON l.id = c.location_id
  LEFT JOIN $(P target_population) p ON p.group_id = a.denominator_id
  ORDER BY l.admin_level, region, location_name
) TO '/dev/stdout' (FORMAT PARQUET);"
