-- Two total-population denominators per administrative unit and estimate year, side by side:
-- the WorldPop grid summed over the unit's boundary (source worldpop) and the census
-- projection (source census-projection), both from IcrTargetPopulation, with the unit's name,
-- level, state and country. One row per unit and year that has at least one of the two; the
-- delta columns are null where only one side exists. Read by the targeting page through
-- src/data/denominators.parquet.sh.
-- Only administrative units are kept: LocationHierarchy gives an admin_level to them alone.
-- admin_level is cast to INTEGER, the type the page had from the locations table.
WITH tp AS (
  SELECT location_id, location_name, CAST(admin_level AS INTEGER) AS admin_level, admin1_name, country,
         source, quantity, estimate_date, is_calculated
  FROM target_population
  WHERE denominator_type = 'total-population' AND admin_level IS NOT NULL
),
w AS (SELECT location_id, estimate_date, quantity AS worldpop, is_calculated AS worldpop_calculated FROM tp WHERE source = 'worldpop'),
c AS (SELECT location_id, estimate_date, quantity AS census FROM tp WHERE source = 'census-projection'),
keys AS (
  SELECT DISTINCT location_id, location_name, admin_level, admin1_name, country, estimate_date
  FROM tp WHERE source IN ('worldpop', 'census-projection')
)
SELECT
  k.location_id,
  k.location_name,
  k.admin_level,
  CASE k.admin_level WHEN 0 THEN 'national' WHEN 1 THEN 'state' WHEN 2 THEN 'lga' ELSE 'other' END AS level,
  CASE WHEN k.admin_level = 1 THEN k.location_name ELSE k.admin1_name END AS state,
  k.country,
  k.estimate_date,
  year(k.estimate_date) AS year,
  w.worldpop,
  w.worldpop_calculated,
  c.census,
  w.worldpop - c.census AS delta,
  (w.worldpop - c.census) / CAST(c.census AS DOUBLE) AS delta_share
FROM keys AS k
LEFT JOIN w ON w.location_id = k.location_id AND w.estimate_date = k.estimate_date
LEFT JOIN c ON c.location_id = k.location_id AND c.estimate_date = k.estimate_date
ORDER BY k.estimate_date, k.admin_level, k.admin1_name, k.location_name
