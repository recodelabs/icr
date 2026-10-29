#!/usr/bin/env bash
# One row per stock movement (DigitSupplyDelivery, ICRSupplyMovement profile), with its campaign,
# its sending and receiving places, and whether it is a dispatch still waiting for its receipt.
#
# How the DIGIT import writes stock (tools/digit/transform/transform.py, write_stock): each DIGIT
# stock row is a DISPATCHED or a RECEIVED transaction recorded by one side. The import pairs a
# dispatch with its receipt when both carry the same waybill number, product, quantity, sender and
# receiver, and writes one movement per pair (status completed) or per unpaired row: completed for
# a receipt, in-progress for a dispatch. In the demo data no pair matched, so every movement is
# one row (`stock_records` = 1): `record` is dispatch (in-progress) or receipt (completed).
#
# `pending`: a dispatch with no matching receipt. The match here is looser than the import's: a
# receipt with the same sender, receiver, product and quantity, ignoring the waybill. Dispatches
# and receipts with the same key are matched in date order, one to one; dispatches left over are
# pending. Every movement names its campaign (round or umbrella) in its campaign extension.
#
# Places: a sender is a facility (an Organization, placed by its facility Location), a field worker
# (Practitioner) or a party the import could not export (`not exported`). A receiver is a facility
# Location (`destination`) or a field worker (`receiver`). A facility has coordinates when its
# Location has a position (`*_lon`, `*_lat`), and an LGA (`*_lga`, the GRID3 id) when its DIGIT
# boundaries roll up through partOf to a DIGIT LGA or district matched to GRID3. A facility that
# sits directly under a state (a state store) has no LGA, only a state (`*_state`, the GRID3 id of
# the matched DIGIT state or province). `*_hierarchy` is the DIGIT hierarchy it sits in.
set -euo pipefail
. "$(dirname "$0")/../../loaders.sh"
duckdb -c "
COPY (
  WITH s AS (SELECT * FROM $(T digit_supply_delivery 'supply_id VARCHAR, profile VARCHAR, status VARCHAR, campaign_id VARCHAR, item VARCHAR, item_code VARCHAR, quantity DOUBLE, unit VARCHAR, supplier VARCHAR, supplier_display VARCHAR, receiver VARCHAR, destination_id VARCHAR, stock_records BIGINT, waybill VARCHAR, occurrence TIMESTAMPTZ, returned DOUBLE, not_usable DOUBLE')
             WHERE profile LIKE '%/ICRSupplyMovement'),
  dl AS (SELECT * FROM $(T digit_location 'location_id VARCHAR, name VARCHAR, type VARCHAR, type_text VARCHAR, part_of_id VARCHAR, organization_id VARCHAR, icr_location_id VARCHAR, lat DOUBLE, lon DOUBLE')),
  cal AS (SELECT DISTINCT campaign_id, coalesce(parent_campaign_id, campaign_id) AS umbrella_id
          FROM $(T campaign_calendar 'campaign_id VARCHAR, parent_campaign_id VARCHAR')),
  m AS (
    SELECT s.*,
      CASE WHEN s.status = 'completed' THEN 'receipt' ELSE 'dispatch' END AS record,
      -- The sending place: a facility Location (from its Organization), a field worker, or not exported.
      CASE WHEN s.supplier LIKE 'Organization/%' THEN coalesce(so.location_id, s.supplier)
           WHEN s.supplier LIKE 'Location/%' THEN split_part(s.supplier, '/', 2)
           ELSE s.supplier END AS sender_id,
      CASE WHEN s.supplier LIKE 'Organization/%' OR s.supplier LIKE 'Location/%' THEN 'facility'
           WHEN s.supplier LIKE 'Practitioner/%' THEN 'field worker'
           WHEN s.supplier_display IS NOT NULL THEN 'not exported' ELSE 'not recorded' END AS sender_kind,
      coalesce(s.destination_id, s.receiver) AS receiver_id,
      CASE WHEN s.destination_id IS NOT NULL THEN 'facility' WHEN s.receiver IS NOT NULL THEN 'field worker' ELSE 'not recorded' END AS receiver_kind
    FROM s LEFT JOIN dl so ON s.supplier LIKE 'Organization/%' AND so.organization_id = split_part(s.supplier, '/', 2)),
  -- Match dispatches to receipts with the same sender, receiver, product and quantity, in date order.
  ranked AS (SELECT *, row_number() OVER (PARTITION BY record, sender_id, receiver_id, item, quantity ORDER BY occurrence, supply_id) AS k,
                    count(*) FILTER (WHERE record = 'receipt') OVER (PARTITION BY sender_id, receiver_id, item, quantity) AS receipts
             FROM m),
  -- Every place in use, walked up its DIGIT boundaries to a matched GRID3 LGA.
  places AS (SELECT DISTINCT sender_id AS id FROM m WHERE sender_kind = 'facility' UNION SELECT DISTINCT receiver_id FROM m WHERE receiver_kind = 'facility'),
  walk AS (
    WITH RECURSIVE w(place_id, node_id, depth) AS (
      SELECT p.id, p.id, 0 FROM places p
      UNION ALL
      SELECT w.place_id, d.part_of_id, w.depth + 1 FROM w JOIN dl d ON d.location_id = w.node_id
      WHERE d.part_of_id IS NOT NULL AND w.depth < 12)
    SELECT * FROM w),
  lga AS (SELECT w.place_id,
                 min(d.icr_location_id) FILTER (WHERE regexp_matches(d.type_text, '^(LGA|DISTRICT) ')) AS lga_id,
                 min(d.icr_location_id) FILTER (WHERE regexp_matches(d.type_text, '^(STATE|PROVINCE) ')) AS state_id
          FROM walk w JOIN dl d ON d.location_id = w.node_id
          WHERE d.icr_location_id IS NOT NULL GROUP BY 1),
  hier AS (SELECT w.place_id, arg_min(regexp_extract(d.type_text, 'DIGIT (.+) hierarchy', 1), w.depth) AS hierarchy
           FROM walk w JOIN dl d ON d.location_id = w.node_id WHERE d.type_text LIKE '%DIGIT % hierarchy%' GROUP BY 1),
  place AS (SELECT p.id, d.name, d.lon, d.lat, l.lga_id, l.state_id, h.hierarchy
            FROM places p LEFT JOIN dl d ON d.location_id = p.id LEFT JOIN lga l ON l.place_id = p.id LEFT JOIN hier h ON h.place_id = p.id)
  SELECT r.supply_id, r.campaign_id, coalesce(c.umbrella_id, r.campaign_id) AS umbrella_id,
         $(IST_DAY r.occurrence) AS day, r.record, r.status,
         r.record = 'dispatch' AND r.k > r.receipts AS pending,
         coalesce(r.item, r.item_code) AS product, r.unit, r.quantity, r.returned, r.not_usable, r.waybill IS NOT NULL AS has_waybill,
         r.sender_id, r.sender_kind,
         CASE r.sender_kind WHEN 'facility' THEN coalesce(ps.name, r.sender_id) WHEN 'field worker' THEN 'Field worker ' || right(r.sender_id, 8)
              WHEN 'not exported' THEN r.supplier_display ELSE 'Sender not recorded' END AS sender,
         ps.lon AS sender_lon, ps.lat AS sender_lat, ps.lga_id AS sender_lga, ps.state_id AS sender_state, ps.hierarchy AS sender_hierarchy,
         r.receiver_id, r.receiver_kind,
         CASE r.receiver_kind WHEN 'facility' THEN coalesce(pr.name, r.receiver_id) WHEN 'field worker' THEN 'Field worker ' || right(r.receiver_id, 8)
              ELSE 'Receiver not recorded' END AS receiver,
         pr.lon AS receiver_lon, pr.lat AS receiver_lat, pr.lga_id AS receiver_lga, pr.state_id AS receiver_state, pr.hierarchy AS receiver_hierarchy
  FROM ranked r
  LEFT JOIN place ps ON r.sender_kind = 'facility' AND ps.id = r.sender_id
  LEFT JOIN place pr ON r.receiver_kind = 'facility' AND pr.id = r.receiver_id
  LEFT JOIN cal c USING (campaign_id)
  ORDER BY day, r.supply_id
) TO '/dev/stdout' (FORMAT PARQUET);"
