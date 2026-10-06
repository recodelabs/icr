#!/usr/bin/env bash
# One row per settlement visit Task of the Toro NIPDs microplan (tools/microplan-builder):
# the task (status, origin, day, tallies) joined to its settlement point, its facility
# (campaign_id = mp-polio-2026-r2-<facility id>) and catchment, and the settlement's
# under-5 planning denominator and WorldPop total.
set -euo pipefail
DATA="$(cd "$(dirname "$0")/../../../data" && pwd)"
duckdb -c "
LOAD spatial;
COPY (
  WITH t AS (
    SELECT *, campaign_id[18:] AS facility_id FROM read_parquet('$DATA/parquet/campaign_task/country=*/**/*.parquet', hive_partitioning=true, union_by_name=true)
    WHERE campaign_id LIKE 'mp-polio-2026-r2-%'
  ),
  s AS (SELECT id, name, lon, lat FROM read_parquet('$DATA/parquet/locations/country=NGA/geom_type=point/type=settlement/*.parquet') WHERE admin2_name = 'Toro'),
  f AS (SELECT id, name, replace(facility_level_text, chr(160), ' ') AS level, lon, lat FROM read_parquet('$DATA/parquet/locations/country=NGA/geom_type=point/type=facility/*.parquet') WHERE admin2_name = 'Toro'),
  pop AS (SELECT * FROM read_parquet('$DATA/parquet/target_population/country=NGA/*.parquet')),
  u5 AS (SELECT location_id[11:] AS settlement_id, quantity AS u5 FROM pop WHERE group_id LIKE 'u5-worldpop-2026-%' AND location_id LIKE 'catchment-%' AND location_id NOT LIKE 'catchment-catchment-%'),
  wp AS (SELECT location_id[11:] AS settlement_id, quantity AS worldpop FROM pop WHERE source = 'worldpop' AND travel_time IS NULL AND denominator_type = 'total-population' AND location_id LIKE 'catchment-%')
  SELECT t.task_id, t.status, t.origin, strftime(t.execution_start AT TIME ZONE 'UTC', '%Y-%m-%d') AS day, t.missed_reason, t.status_reason,
         t.for_location_id AS settlement_id, s.name AS settlement, s.lon, s.lat,
         t.facility_id, f.name AS facility, f.level AS facility_level, f.lon AS facility_lon, f.lat AS facility_lat,
         'catchment-' || t.facility_id AS catchment_id,
         u5.u5, wp.worldpop,
         2 * 6371 * asin(sqrt(pow(sin((radians(s.lat) - radians(f.lat)) / 2), 2) + cos(radians(s.lat)) * cos(radians(f.lat)) * pow(sin((radians(s.lon) - radians(f.lon)) / 2), 2))) AS distance_km,
         t.treated_count AS treated, t.houses_visited AS houses, t.eligible_present AS present, t.eligible_absent AS absent, t.children_already_marked AS marked
  FROM t
  LEFT JOIN s ON s.id = t.for_location_id
  LEFT JOIN f ON f.id = t.facility_id
  LEFT JOIN u5 ON u5.settlement_id = t.for_location_id
  LEFT JOIN wp ON wp.settlement_id = t.for_location_id
  ORDER BY f.name, day, s.name
) TO '/dev/stdout' (FORMAT PARQUET);"
