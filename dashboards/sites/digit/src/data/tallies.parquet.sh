#!/usr/bin/env bash
# People treated per campaign and activity as the tasks report them (IcrCampaignTaskOutput, added
# by PR #224: one row per task and activity tally). The DIGIT import records each dose as an event
# and writes treated-count outputs on only some tasks, so the delivery page counts the events and
# shows these totals beside them.
set -euo pipefail
. "$(dirname "$0")/../../loaders.sh"
duckdb -c "
COPY (
  WITH o AS (SELECT * FROM $(T campaign_task_output 'task_id VARCHAR, campaign_id VARCHAR, activity VARCHAR, treated_count BIGINT')),
  act AS (SELECT url, title FROM $(T digit_activity 'url VARCHAR, title VARCHAR')),
  cal AS (SELECT DISTINCT campaign_id, coalesce(parent_campaign_id, campaign_id) AS umbrella_id
          FROM $(T campaign_calendar 'campaign_id VARCHAR, parent_campaign_id VARCHAR'))
  SELECT o.campaign_id, coalesce(c.umbrella_id, o.campaign_id) AS umbrella_id,
         regexp_extract(o.activity, '([^/]+)\$', 1) AS activity_id, coalesce(a.title, o.activity) AS activity,
         count(DISTINCT o.task_id) AS tasks, sum(o.treated_count) AS treated
  FROM o LEFT JOIN act a ON a.url = o.activity LEFT JOIN cal c USING (campaign_id)
  WHERE o.treated_count IS NOT NULL
  GROUP BY ALL
) TO '/dev/stdout' (FORMAT PARQUET);"
