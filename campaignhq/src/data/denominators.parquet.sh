#!/usr/bin/env bash
# Two total-population denominators per admin unit and estimate year, side by side:
# the WorldPop grid summed over the unit's boundary (kiln population, source
# `worldpop`) and the census projection (campaign-builder totals, source
# `census-projection`), both from the IG's IcrTargetPopulation view, joined to
# the location registry for names, level and state. One row per unit × year
# that has at least one of the two; the delta columns are null where only one
# side exists.
set -euo pipefail
DATA="$(cd "$(dirname "$0")/../../../data" && pwd)"
duckdb -c "
COPY (
  WITH tp AS (
    SELECT location_id, source, quantity, estimate_date, is_calculated
    FROM read_parquet('$DATA/parquet/target_population/country=*/**/*.parquet', hive_partitioning=true, union_by_name=true)
    WHERE denominator_type = 'total-population' AND location_id IS NOT NULL
  ),
  w AS (SELECT location_id, estimate_date, quantity AS worldpop, is_calculated AS worldpop_calculated FROM tp WHERE source = 'worldpop'),
  c AS (SELECT location_id, estimate_date, quantity AS census FROM tp WHERE source = 'census-projection'),
  keys AS (SELECT location_id, estimate_date FROM w UNION SELECT location_id, estimate_date FROM c),
  loc AS (
    SELECT id, name, admin_level, admin1_name, country
    FROM read_parquet('$DATA/parquet/locations/country=*/**/*.parquet', hive_partitioning=true, union_by_name=true)
    WHERE type = 'admin-unit'
  )
  SELECT
    k.location_id,
    l.name AS location_name,
    l.admin_level,
    CASE l.admin_level WHEN 0 THEN 'national' WHEN 1 THEN 'state' WHEN 2 THEN 'lga' ELSE 'other' END AS level,
    CASE WHEN l.admin_level = 1 THEN l.name ELSE l.admin1_name END AS state,
    l.country,
    k.estimate_date,
    year(k.estimate_date) AS year,
    w.worldpop,
    w.worldpop_calculated,
    c.census,
    w.worldpop - c.census AS delta,
    (w.worldpop - c.census) / c.census::DOUBLE AS delta_share
  FROM keys k
  JOIN loc l ON l.id = k.location_id
  LEFT JOIN w ON w.location_id = k.location_id AND w.estimate_date = k.estimate_date
  LEFT JOIN c ON c.location_id = k.location_id AND c.estimate_date = k.estimate_date
  ORDER BY k.estimate_date, l.admin_level, l.admin1_name, l.name
) TO '/dev/stdout' (FORMAT PARQUET);"
