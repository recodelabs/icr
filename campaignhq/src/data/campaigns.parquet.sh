#!/usr/bin/env bash
# Campaign calendar rows (from the IG ViewDefinition IcrCampaignCalendar) enriched
# for the dashboard: level, programme label, state/LGA names, people targeted.
set -euo pipefail
DATA="$(cd "$(dirname "$0")/../../../data" && pwd)"
duckdb -c "
COPY (
  WITH cal AS (SELECT * FROM read_parquet('$DATA/parquet/campaign_calendar/**/*.parquet', hive_partitioning=true, union_by_name=true)),
       pop AS (SELECT group_id, quantity FROM read_parquet('$DATA/parquet/target_population/**/*.parquet', hive_partitioning=true, union_by_name=true)),
       loc AS (SELECT id, name, admin_level, admin1_name FROM read_parquet('$DATA/parquet/locations/**/*.parquet', hive_partitioning=true, union_by_name=true) WHERE type = 'admin-unit')
  SELECT
    c.campaign_id, c.title, c.status, c.intent, c.campaign_type, c.country,
    c.period_start, c.period_end,
    year(c.period_start) AS year,
    c.round, c.parent_campaign_id, c.protocol,
    regexp_replace(regexp_replace(c.protocol, '.*/', ''), '^nga-demo-proto-', '') AS protocol_key,
    CASE regexp_replace(regexp_replace(c.protocol, '.*/', ''), '^nga-demo-proto-', '')
      WHEN 'nopv2-sia' THEN 'Polio (nOPV2)'
      WHEN 'measles-catchup' THEN 'Measles catch-up'
      WHEN 'measles-obr' THEN 'Measles outbreak response'
      WHEN 'mr-nopv2-integrated' THEN 'MR + nOPV2 integrated'
      WHEN 'mr-nopv2-ntd-integrated' THEN 'MR + nOPV2 + NTD integrated'
      WHEN 'lf-oncho-mda' THEN 'LF / onchocerciasis MDA'
      WHEN 'oncho-cdti' THEN 'Onchocerciasis CDTI'
      WHEN 'trachoma-mda' THEN 'Trachoma MDA'
      WHEN 'sch-sth-school-mda' THEN 'Schisto / STH school MDA'
      ELSE coalesce(c.campaign_type, 'other') END AS programme,
    c.location_id,
    CASE l.admin_level WHEN 0 THEN 'national' WHEN 1 THEN 'state' WHEN 2 THEN 'lga' ELSE coalesce(l.admin_level::varchar, 'other') END AS level,
    l.name AS location_name,
    l.admin1_name AS state,
    p.quantity AS targeted,
    c.denominator_id
  FROM cal c
  LEFT JOIN loc l ON l.id = c.location_id
  LEFT JOIN pop p ON p.group_id = c.denominator_id
  ORDER BY c.period_start, c.location_id
) TO '/dev/stdout' (FORMAT PARQUET);"
