#!/usr/bin/env bash
# Delivery events per campaign, activity and outcome: drug administrations
# (DigitMedicationAdministration), vaccinations (DigitImmunization) and distributions to households
# (DigitSupplyDelivery, ICRSupplyDistribution profile). `events` counts records, `people` distinct
# people (patients; for distributions, households), `quantity` the doses or items given. The
# activity's title and product come from DigitActivity.
set -euo pipefail
. "$(dirname "$0")/../../loaders.sh"
duckdb -c "
COPY (
  WITH ev AS (
    SELECT 'drug' AS source, campaign_id, activity, status, coalesce(status_reason_text, status_reason) AS reason,
           patient_id AS person, dose_value AS quantity, dose_unit AS unit, medication AS product
    FROM $(T digit_medication_administration 'campaign_id VARCHAR, activity VARCHAR, status VARCHAR, status_reason VARCHAR, status_reason_text VARCHAR, patient_id VARCHAR, dose_value DOUBLE, dose_unit VARCHAR, medication VARCHAR')
    UNION ALL BY NAME
    SELECT 'vaccine' AS source, campaign_id, activity, status, status_reason AS reason,
           patient_id AS person, coalesce(dose_value, 1) AS quantity, 'doses' AS unit, coalesce(vaccine, vaccine_code) AS product
    FROM $(T digit_immunization 'campaign_id VARCHAR, activity VARCHAR, status VARCHAR, status_reason VARCHAR, patient_id VARCHAR, dose_value DOUBLE, vaccine VARCHAR, vaccine_code VARCHAR')
    UNION ALL BY NAME
    SELECT CASE WHEN item_class = 'llin' THEN 'net' ELSE 'item' END AS source, campaign_id, activity, status, NULL AS reason,
           recipient_group_id AS person, quantity, unit, item AS product
    FROM $(T digit_supply_delivery 'profile VARCHAR, campaign_id VARCHAR, activity VARCHAR, status VARCHAR, item_class VARCHAR, recipient_group_id VARCHAR, quantity DOUBLE, unit VARCHAR, item VARCHAR')
    WHERE profile LIKE '%/ICRSupplyDistribution'),
  act AS (SELECT url, title FROM $(T digit_activity 'url VARCHAR, title VARCHAR')),
  cal AS (SELECT DISTINCT campaign_id, coalesce(parent_campaign_id, campaign_id) AS umbrella_id
          FROM $(T campaign_calendar 'campaign_id VARCHAR, parent_campaign_id VARCHAR'))
  SELECT ev.campaign_id, coalesce(c.umbrella_id, ev.campaign_id) AS umbrella_id, ev.source,
         regexp_extract(ev.activity, '([^/]+)\$', 1) AS activity_id, coalesce(a.title, ev.product) AS activity,
         ev.product, ev.status, ev.reason, ev.unit,
         count(*) AS events, count(DISTINCT ev.person) AS people, sum(ev.quantity) AS quantity
  FROM ev LEFT JOIN act a ON a.url = ev.activity LEFT JOIN cal c USING (campaign_id)
  GROUP BY ALL
  ORDER BY umbrella_id, activity
) TO '/dev/stdout' (FORMAT PARQUET);"
