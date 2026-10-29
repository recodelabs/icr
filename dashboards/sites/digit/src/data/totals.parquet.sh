#!/usr/bin/env bash
# Headline figures per umbrella campaign, with its rounds rolled up:
#   households    households registered (distinct Task.for of the "Register household" tasks)
#   people        members of those households (DigitHousehold.quantity)
#   visits        delivery visits (the other tasks)
#   treated       distinct people given a drug or vaccine (completed events)
#   doses         completed drug administrations and vaccinations
#   nets          nets handed to households (LLIN distributions, summed quantity)
# The one row with umbrella_id NULL is the whole server: every household and person, registered in
# a campaign or not.
set -euo pipefail
. "$(dirname "$0")/../../loaders.sh"
duckdb -c "
COPY (
  WITH cal AS (SELECT DISTINCT campaign_id, coalesce(parent_campaign_id, campaign_id) AS umbrella_id
               FROM $(T campaign_calendar 'campaign_id VARCHAR, parent_campaign_id VARCHAR')),
  t AS (SELECT t.*, coalesce(c.umbrella_id, t.campaign_id) AS umbrella_id
        FROM $(T campaign_task 'task_id VARCHAR, code VARCHAR, campaign_id VARCHAR, for_group_id VARCHAR') t LEFT JOIN cal c USING (campaign_id)),
  hh AS (SELECT group_id, quantity FROM $(T digit_household 'group_id VARCHAR, quantity BIGINT')),
  reg AS (SELECT umbrella_id, count(DISTINCT for_group_id) AS households, sum(h.quantity) AS people
          FROM (SELECT DISTINCT umbrella_id, for_group_id FROM t WHERE code = 'Register household') r
          LEFT JOIN hh h ON h.group_id = r.for_group_id GROUP BY 1),
  vis AS (SELECT umbrella_id, count(*) AS visits FROM t WHERE code IS DISTINCT FROM 'Register household' GROUP BY 1),
  given AS (
    SELECT campaign_id, subject AS person FROM (
      SELECT campaign_id, patient_id AS subject, status FROM $(T digit_medication_administration 'campaign_id VARCHAR, patient_id VARCHAR, status VARCHAR')
      UNION ALL
      SELECT campaign_id, patient_id, status FROM $(T digit_immunization 'campaign_id VARCHAR, patient_id VARCHAR, status VARCHAR'))
    WHERE status = 'completed'),
  trt AS (SELECT coalesce(c.umbrella_id, g.campaign_id) AS umbrella_id, count(DISTINCT person) AS treated, count(*) AS doses
          FROM given g LEFT JOIN cal c USING (campaign_id) GROUP BY 1),
  nets AS (SELECT coalesce(c.umbrella_id, s.campaign_id) AS umbrella_id, sum(quantity) AS nets
           FROM $(T digit_supply_delivery 'profile VARCHAR, campaign_id VARCHAR, status VARCHAR, item_class VARCHAR, quantity DOUBLE') s
           LEFT JOIN cal c USING (campaign_id)
           WHERE s.profile LIKE '%/ICRSupplyDistribution' AND s.item_class = 'llin' AND s.status = 'completed' GROUP BY 1),
  ids AS (SELECT umbrella_id FROM reg UNION SELECT umbrella_id FROM vis UNION SELECT umbrella_id FROM trt UNION SELECT umbrella_id FROM nets
          UNION SELECT DISTINCT umbrella_id FROM cal)
  SELECT i.umbrella_id, coalesce(reg.households, 0) AS households, coalesce(reg.people, 0) AS people,
         coalesce(vis.visits, 0) AS visits, coalesce(trt.treated, 0) AS treated, coalesce(trt.doses, 0) AS doses,
         coalesce(nets.nets, 0) AS nets
  FROM ids i LEFT JOIN reg USING (umbrella_id) LEFT JOIN vis USING (umbrella_id) LEFT JOIN trt USING (umbrella_id) LEFT JOIN nets USING (umbrella_id)
  WHERE i.umbrella_id IS NOT NULL
  UNION ALL
  SELECT NULL, (SELECT count(*) FROM hh), (SELECT count(*) FROM $(T digit_patient 'patient_id VARCHAR')),
         NULL, NULL, NULL, NULL
) TO '/dev/stdout' (FORMAT PARQUET);"
