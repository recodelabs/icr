#!/usr/bin/env bash
# One row per campaign (IcrCampaignCalendar): umbrellas and their cycle rounds, with the umbrella
# id (`umbrella_id`, the campaign itself for an umbrella), the protocol's title (DigitProtocol),
# the first target geography's name (DigitLocation) and the planning target (IcrTargetPopulation).
# The period is DigitCampaignPeriod's, as calendar days in India Standard Time, DIGIT's time zone:
# IcrCampaignCalendar's dates are the UTC dates, a day early for DIGIT's start dates.
set -euo pipefail
. "$(dirname "$0")/../../loaders.sh"
duckdb -c "
COPY (
  WITH cal AS (
    SELECT * FROM $(T campaign_calendar 'campaign_id VARCHAR, title VARCHAR, status VARCHAR, intent VARCHAR, campaign_type VARCHAR, period_start DATE, period_end DATE, round INTEGER, parent_campaign_id VARCHAR, protocol VARCHAR, denominator_id VARCHAR, location_id VARCHAR')
    QUALIFY row_number() OVER (PARTITION BY campaign_id ORDER BY location_id NULLS LAST) = 1),
  per AS (SELECT campaign_id, $(IST_DAY period_start) AS period_start, $(IST_DAY period_end) AS period_end
          FROM $(T digit_campaign_period 'campaign_id VARCHAR, period_start TIMESTAMPTZ, period_end TIMESTAMPTZ')),
  geo AS (SELECT campaign_id, count(location_id) AS n_geographies
          FROM $(T campaign_calendar 'campaign_id VARCHAR, location_id VARCHAR') GROUP BY 1),
  pop AS (SELECT group_id, quantity, unit FROM $(T target_population 'group_id VARCHAR, quantity BIGINT, unit VARCHAR')),
  proto AS (SELECT url, title FROM $(T digit_protocol 'url VARCHAR, title VARCHAR')),
  loc AS (SELECT location_id, name FROM $(T digit_location 'location_id VARCHAR, name VARCHAR'))
  SELECT c.campaign_id, coalesce(c.parent_campaign_id, c.campaign_id) AS umbrella_id,
         c.parent_campaign_id IS NULL AS is_umbrella,
         c.title, c.status, c.campaign_type, CAST(c.round AS INTEGER) AS round,
         coalesce(per.period_start, c.period_start) AS period_start, coalesce(per.period_end, c.period_end) AS period_end,
         regexp_extract(c.protocol, '([^/]+)\$', 1) AS protocol_id, p.title AS protocol,
         c.location_id, l.name AS location_name, CAST(g.n_geographies AS INTEGER) AS n_geographies,
         t.quantity AS target, coalesce(t.unit, 'person') AS target_unit
  FROM cal c
  LEFT JOIN per USING (campaign_id)
  LEFT JOIN geo g USING (campaign_id)
  LEFT JOIN pop t ON t.group_id = c.denominator_id
  LEFT JOIN proto p ON p.url = c.protocol
  LEFT JOIN loc l ON l.location_id = c.location_id
  ORDER BY umbrella_id, is_umbrella DESC, c.round
) TO '/dev/stdout' (FORMAT PARQUET);"
