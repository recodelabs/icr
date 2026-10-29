-- One row per campaign (IcrCampaignCalendar) for the main dashboard: level, programme label,
-- the administrative unit's name and state, people targeted, and the results from IcrCoverage:
-- people reached and administrative coverage (reconciled), the latest realtime figure for
-- active rounds, the LQAS verdict and the survey estimate with its confidence interval where
-- they exist. An integrated campaign has a target per activity (IcrCampaignActivity):
-- activity_targets lists them, and the coverage figures name the activity they cover.
-- Read by the overview and coverage pages through src/data/campaigns.parquet.sh.
--
-- Names, level and state come from LocationHierarchy for administrative units only, so a
-- campaign at a catchment or settlement has level 'other' and no name. country is the
-- calendar table's own (its partition column). The SQL is DuckDB's (QUALIFY, list of structs).
WITH pop AS (SELECT group_id, quantity FROM target_population),
     adm AS (SELECT id, name, admin_level, admin1_name FROM hierarchy WHERE is_admin),
     -- One result per report for campaign coverage: a household report has distribution and
     -- registration groups (group_code); keep distribution and single-group rows.
     cov AS (SELECT * FROM coverage WHERE group_code IS NULL OR group_code = 'distribution'),
     -- Short names for the activities; anything not listed shows its id.
     label AS (SELECT * FROM (VALUES ('nga-demo-act-mr', 'MR'), ('nga-demo-act-nopv2', 'Polio (nOPV2)'), ('nga-demo-act-alb', 'Albendazole'),
                                     ('nga-demo-act-mcv', 'Measles'), ('nga-demo-act-ivm-alb', 'Ivermectin + albendazole'),
                                     ('nga-demo-act-ivm', 'Ivermectin'), ('nga-demo-act-azm', 'Azithromycin'),
                                     ('nga-demo-act-pzq-alb', 'Praziquantel + albendazole')) t(activity_key, activity_label)),
     act AS (SELECT a.campaign_id, regexp_replace(a.activity, '.*/', '') AS activity_key, sum(p.quantity) AS targeted
             FROM activity AS a
             LEFT JOIN pop AS p ON p.group_id = a.denominator_id
             GROUP BY 1, 2),
     acts AS (SELECT campaign_id,
                     list({activity: coalesce(l.activity_label, act.activity_key), targeted: act.targeted} ORDER BY act.targeted DESC) AS activity_targets,
                     max(act.targeted) AS max_activity_targeted
              FROM act LEFT JOIN label AS l USING (activity_key) GROUP BY 1),
     admin AS (SELECT campaign_id, numerator AS reached, denominator AS admin_denominator, score AS admin_coverage, reported AS admin_reported,
                      regexp_replace(activity, '.*/', '') AS admin_activity_key
               FROM cov WHERE source = 'administrative' AND lineage = 'reconciled' QUALIFY row_number() OVER (PARTITION BY campaign_id ORDER BY reported DESC) = 1),
     rt AS (SELECT campaign_id, numerator AS realtime_reached, score AS realtime_coverage, period_end AS realtime_through
            FROM cov WHERE source = 'administrative' AND lineage = 'realtime' QUALIFY row_number() OVER (PARTITION BY campaign_id ORDER BY period_end DESC) = 1),
     lqas AS (SELECT campaign_id, score AS lqas_score, regexp_extract(sample_design, 'result: (\w+)', 1) AS lqas_result
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
  CASE l.admin_level WHEN 0 THEN 'national' WHEN 1 THEN 'state' WHEN 2 THEN 'lga' ELSE coalesce(CAST(l.admin_level AS VARCHAR), 'other') END AS level,
  l.name AS location_name,
  l.admin1_name AS state,
  -- The campaign's planning denominator; a campaign with only per-activity targets
  -- counts its largest one.
  coalesce(p.quantity, ac.max_activity_targeted) AS targeted,
  c.denominator_id,
  ac.activity_targets,
  al.activity_label AS coverage_activity,
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
FROM calendar AS c
LEFT JOIN adm AS l ON l.id = c.location_id
LEFT JOIN pop AS p ON p.group_id = c.denominator_id
LEFT JOIN acts AS ac ON ac.campaign_id = c.campaign_id
LEFT JOIN admin AS a ON a.campaign_id = c.campaign_id
LEFT JOIN label AS al ON al.activity_key = a.admin_activity_key
LEFT JOIN rt ON rt.campaign_id = c.campaign_id
LEFT JOIN lqas AS lq ON lq.campaign_id = c.campaign_id
LEFT JOIN survey AS s ON s.campaign_id = c.campaign_id
ORDER BY c.period_start, c.location_id
