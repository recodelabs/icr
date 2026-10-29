#!/usr/bin/env bash
# Stock movements (DigitSupplyDelivery, ICRSupplyMovement profile) per day, product, sender and
# receiver, by status: completed is a movement both sides recorded (dispatched and received),
# in-progress one dispatched and not yet recorded as received. Names come from DigitLocation for
# places and from the facility Organizations' Locations where the sender is an Organization.
set -euo pipefail
. "$(dirname "$0")/../../loaders.sh"
duckdb -c "
COPY (
  WITH s AS (SELECT * FROM $(T digit_supply_delivery 'profile VARCHAR, status VARCHAR, campaign_id VARCHAR, item VARCHAR, item_code VARCHAR, quantity DOUBLE, unit VARCHAR, supplier VARCHAR, destination_id VARCHAR, issued_to_team_id VARCHAR, occurrence TIMESTAMPTZ, returned DOUBLE, not_usable DOUBLE')
             WHERE profile LIKE '%/ICRSupplyMovement'),
  l AS (SELECT location_id, name, organization_id FROM $(T digit_location 'location_id VARCHAR, name VARCHAR, organization_id VARCHAR')),
  -- A sender is a Location, or an Organization whose facility Location names it.
  sender AS (SELECT DISTINCT supplier,
                    regexp_extract(supplier, '^([A-Za-z]+)/', 1) AS supplier_type,
                    regexp_extract(supplier, '/([^/]+)\$', 1) AS supplier_id
             FROM s WHERE supplier IS NOT NULL),
  cal AS (SELECT DISTINCT campaign_id, coalesce(parent_campaign_id, campaign_id) AS umbrella_id
          FROM $(T campaign_calendar 'campaign_id VARCHAR, parent_campaign_id VARCHAR'))
  SELECT $(IST_DAY s.occurrence) AS day, s.status,
         coalesce(c.umbrella_id, s.campaign_id) AS umbrella_id,
         coalesce(s.item, s.item_code) AS product, s.unit,
         sd.supplier_type,
         coalesce(ls.name, lo.name, sd.supplier_id) AS sender,
         s.destination_id IS NOT NULL AS to_place, s.issued_to_team_id IS NOT NULL AS to_team,
         coalesce(ld.name, CASE WHEN s.issued_to_team_id IS NOT NULL THEN 'Team ' || s.issued_to_team_id END) AS receiver,
         count(*) AS movements, sum(s.quantity) AS quantity,
         sum(s.returned) AS returned, sum(s.not_usable) AS not_usable
  FROM s
  LEFT JOIN sender sd USING (supplier)
  LEFT JOIN l ls ON sd.supplier_type = 'Location' AND ls.location_id = sd.supplier_id
  LEFT JOIN l lo ON sd.supplier_type = 'Organization' AND lo.organization_id = sd.supplier_id
  LEFT JOIN l ld ON ld.location_id = s.destination_id
  LEFT JOIN cal c USING (campaign_id)
  GROUP BY ALL
  ORDER BY day
) TO '/dev/stdout' (FORMAT PARQUET);"
