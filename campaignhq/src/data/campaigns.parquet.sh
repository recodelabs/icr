#!/usr/bin/env bash
# Campaign calendar rows (from the IG ViewDefinition IcrCampaignCalendar) enriched
# for the dashboard: level, programme label, state/LGA names, people targeted,
# and the results from the IcrCoverage view — people reached and administrative
# coverage (reconciled), the latest realtime figure for active rounds, the LQAS
# verdict and the survey estimate with its confidence interval where they exist.
set -euo pipefail
DATA="$(cd "$(dirname "$0")/../../../data" && pwd)"
duckdb -c "
COPY (
  WITH cal AS (SELECT * FROM read_parquet('$DATA/parquet/campaign_calendar/**/*.parquet', hive_partitioning=true, union_by_name=true)),
       pop AS (SELECT group_id, quantity FROM read_parquet('$DATA/parquet/target_population/**/*.parquet', hive_partitioning=true, union_by_name=true)),
       loc AS (SELECT id, name, admin_level, admin1_name FROM read_parquet('$DATA/parquet/locations/**/*.parquet', hive_partitioning=true, union_by_name=true) WHERE type = 'admin-unit'),
       cov AS (SELECT * FROM read_parquet('$DATA/parquet/coverage/**/*.parquet', hive_partitioning=true, union_by_name=true)),
       admin AS (SELECT campaign_id, numerator AS reached, denominator AS admin_denominator, score AS admin_coverage, reported AS admin_reported
                 FROM cov WHERE source = 'administrative' AND lineage = 'reconciled' QUALIFY row_number() OVER (PARTITION BY campaign_id ORDER BY reported DESC) = 1),
       rt AS (SELECT campaign_id, numerator AS realtime_reached, score AS realtime_coverage, period_end AS realtime_through
              FROM cov WHERE source = 'administrative' AND lineage = 'realtime' QUALIFY row_number() OVER (PARTITION BY campaign_id ORDER BY period_end DESC) = 1),
       lqas AS (SELECT campaign_id, score AS lqas_score, regexp_extract(sample_design, 'result: (\\w+)', 1) AS lqas_result
                FROM cov WHERE source = 'lqas' QUALIFY row_number() OVER (PARTITION BY campaign_id ORDER BY reported DESC) = 1),
       survey AS (SELECT campaign_id, score AS survey_coverage, ci_low AS survey_ci_low, ci_high AS survey_ci_high, denominator AS survey_n, sample_design AS survey_design
                  FROM cov WHERE source = 'survey' QUALIFY row_number() OVER (PARTITION BY campaign_id ORDER BY reported DESC) = 1)
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
    c.denominator_id,
    -- results
    coalesce(a.reached, rt.realtime_reached) AS reached,
    a.admin_coverage,
    a.admin_reported,
    rt.realtime_reached, rt.realtime_coverage, rt.realtime_through,
    lq.lqas_score, lq.lqas_result,
    s.survey_coverage, s.survey_ci_low, s.survey_ci_high, s.survey_n, s.survey_design,
    CASE WHEN a.campaign_id IS NOT NULL THEN 'reported'
         WHEN rt.campaign_id IS NOT NULL THEN 'in progress'
         WHEN c.status = 'draft' THEN 'planned'
         ELSE 'no report' END AS result_status
  FROM cal c
  LEFT JOIN loc l ON l.id = c.location_id
  LEFT JOIN pop p ON p.group_id = c.denominator_id
  LEFT JOIN admin a ON a.campaign_id = c.campaign_id
  LEFT JOIN rt ON rt.campaign_id = c.campaign_id
  LEFT JOIN lqas lq ON lq.campaign_id = c.campaign_id
  LEFT JOIN survey s ON s.campaign_id = c.campaign_id
  ORDER BY c.period_start, c.location_id
) TO '/dev/stdout' (FORMAT PARQUET);"
