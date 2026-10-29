#!/usr/bin/env bash
# Campaign tasks (IcrCampaignTask, with DigitTaskOutput for the reasons) counted per campaign, day
# (in India Standard Time, DIGIT's zone), kind, status and reason.
#   kind         registration (a "Register household" task, from DIGIT's project beneficiaries) or
#                visit (a DIGIT task: a household visit, a drug administration or a distribution)
#   code         the task's code text ("Household visit", "Administer", "Distribute", …)
#   reason_type  the first reason output on the task: missed-reason, noncompliance-reason or
#                exclusion-reason
#   reason_code  its code (absent, refusal, other …), else the task's missed reason
#   reason       its text, else the code, else the task's status reason
#   households   distinct households (Task.for)
set -euo pipefail
. "$(dirname "$0")/../../loaders.sh"
duckdb -c "
COPY (
  WITH t AS (SELECT * FROM $(T campaign_task 'task_id VARCHAR, status VARCHAR, code VARCHAR, campaign_id VARCHAR, for_group_id VARCHAR, execution_start TIMESTAMPTZ, missed_reason VARCHAR, status_reason VARCHAR')),
  o AS (SELECT task_id,
               first(output_type ORDER BY output_type DESC) AS reason_type,
               first(value_code ORDER BY output_type DESC) AS reason_code,
               first(coalesce(value_text, value_code) ORDER BY output_type DESC) AS reason
        FROM $(T digit_task_output 'task_id VARCHAR, output_type VARCHAR, value_code VARCHAR, value_text VARCHAR')
        WHERE output_type IN ('missed-reason', 'noncompliance-reason', 'exclusion-reason') GROUP BY 1),
  cal AS (SELECT DISTINCT campaign_id, coalesce(parent_campaign_id, campaign_id) AS umbrella_id
          FROM $(T campaign_calendar 'campaign_id VARCHAR, parent_campaign_id VARCHAR'))
  SELECT t.campaign_id, coalesce(c.umbrella_id, t.campaign_id) AS umbrella_id,
         $(IST_DAY t.execution_start) AS day,
         CASE WHEN t.code = 'Register household' THEN 'registration' ELSE 'visit' END AS kind,
         t.code, t.status, o.reason_type,
         coalesce(o.reason_code, t.missed_reason) AS reason_code,
         coalesce(o.reason, t.missed_reason, t.status_reason) AS reason,
         count(*) AS tasks, count(DISTINCT t.for_group_id) AS households
  FROM t LEFT JOIN o USING (task_id) LEFT JOIN cal c USING (campaign_id)
  GROUP BY ALL
  ORDER BY umbrella_id, day
) TO '/dev/stdout' (FORMAT PARQUET);"
