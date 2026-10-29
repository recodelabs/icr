#!/usr/bin/env bash
# One row per campaign (IcrCampaignCalendar): umbrellas and their cycle rounds, with the umbrella
# id (`umbrella_id`, the campaign itself for an umbrella), the protocol's title (DigitProtocol),
# the first target geography's name (DigitLocation) and the planning target (IcrTargetPopulation).
# The period is DigitCampaignPeriod's, as calendar days in India Standard Time, DIGIT's time zone:
# IcrCampaignCalendar's dates are the UTC dates, a day early for DIGIT's start dates.
#
# `country` is the same for an umbrella and its rounds, and both pages filter by it. It comes from
# the DIGIT hierarchy (`hierarchy`) of the campaign's target geography: the umbrella's, else its
# rounds' most common; for a campaign with no target geography, the most common hierarchy of the
# boundaries its tasks' dwellings sit in (`country_from` says which). Each hierarchy has one root
# country unit: NIGERIA and ADMIN are Nigeria, SIERRALEONE Sierra Leone, DEMOGABON Gabon, and
# MICROPLAN (root "Microplan Tc", code MICROPLAN_TC) is Chad, whose provinces it holds (Lac,
# N'Djamena, Ouaddaï). No hierarchy at all gives "Unknown".
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
  dl AS (SELECT location_id, name, part_of_id, regexp_extract(type_text, 'DIGIT (.+) hierarchy', 1) AS hierarchy
         FROM $(T digit_location 'location_id VARCHAR, name VARCHAR, part_of_id VARCHAR, type_text VARCHAR')),
  -- The hierarchy of every target geography, per umbrella.
  geo_h AS (SELECT coalesce(c.parent_campaign_id, c.campaign_id) AS umbrella_id, c.parent_campaign_id IS NULL AS own, d.hierarchy
            FROM $(T campaign_calendar 'campaign_id VARCHAR, parent_campaign_id VARCHAR, location_id VARCHAR') c
            JOIN dl d ON d.location_id = c.location_id WHERE d.hierarchy <> ''),
  from_geo AS (SELECT umbrella_id, arg_max(hierarchy, n) AS hierarchy
               FROM (SELECT umbrella_id, hierarchy, count(*) + 1000000 * bool_or(own)::INT AS n FROM geo_h GROUP BY 1, 2) GROUP BY 1),
  -- Else the hierarchy of the boundaries its tasks' dwellings sit in.
  task_h AS (SELECT coalesce(c.parent_campaign_id, t.campaign_id) AS umbrella_id, b.hierarchy
             FROM $(T campaign_task 'campaign_id VARCHAR, location_id VARCHAR') t
             JOIN dl d ON d.location_id = t.location_id JOIN dl b ON b.location_id = d.part_of_id
             LEFT JOIN (SELECT DISTINCT campaign_id, parent_campaign_id FROM $(T campaign_calendar 'campaign_id VARCHAR, parent_campaign_id VARCHAR')) c
               ON c.campaign_id = t.campaign_id
             WHERE b.hierarchy <> ''),
  from_tasks AS (SELECT umbrella_id, arg_max(hierarchy, n) AS hierarchy FROM (SELECT umbrella_id, hierarchy, count(*) AS n FROM task_h GROUP BY 1, 2) GROUP BY 1),
  ctry AS (SELECT u.umbrella_id, coalesce(g.hierarchy, t.hierarchy) AS hierarchy,
                  CASE WHEN g.hierarchy IS NOT NULL THEN 'target geography' WHEN t.hierarchy IS NOT NULL THEN 'tasks' END AS country_from
           FROM (SELECT DISTINCT coalesce(parent_campaign_id, campaign_id) AS umbrella_id FROM cal) u
           LEFT JOIN from_geo g USING (umbrella_id) LEFT JOIN from_tasks t USING (umbrella_id))
  SELECT c.campaign_id, coalesce(c.parent_campaign_id, c.campaign_id) AS umbrella_id,
         c.parent_campaign_id IS NULL AS is_umbrella,
         c.title, c.status, c.campaign_type, CAST(c.round AS INTEGER) AS round,
         coalesce(per.period_start, c.period_start) AS period_start, coalesce(per.period_end, c.period_end) AS period_end,
         regexp_extract(c.protocol, '([^/]+)\$', 1) AS protocol_id, p.title AS protocol,
         c.location_id, l.name AS location_name, CAST(g.n_geographies AS INTEGER) AS n_geographies,
         t.quantity AS target, coalesce(t.unit, 'person') AS target_unit,
         k.hierarchy,
         CASE k.hierarchy WHEN 'NIGERIA' THEN 'Nigeria' WHEN 'ADMIN' THEN 'Nigeria' WHEN 'SIERRALEONE' THEN 'Sierra Leone'
                          WHEN 'DEMOGABON' THEN 'Gabon' WHEN 'MICROPLAN' THEN 'Chad'
                          ELSE coalesce(k.hierarchy, 'Unknown') END AS country,
         k.country_from
  FROM cal c
  LEFT JOIN per USING (campaign_id)
  LEFT JOIN geo g USING (campaign_id)
  LEFT JOIN pop t ON t.group_id = c.denominator_id
  LEFT JOIN proto p ON p.url = c.protocol
  LEFT JOIN dl l ON l.location_id = c.location_id
  LEFT JOIN ctry k ON k.umbrella_id = coalesce(c.parent_campaign_id, c.campaign_id)
  ORDER BY umbrella_id, is_umbrella DESC, c.round
) TO '/dev/stdout' (FORMAT PARQUET);"
