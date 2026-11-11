#!/usr/bin/env bash
# Routine immunization (EPI e-Tracker, via the DGHS GIS dashboard) from the local warehouse:
# every bd-ri-* value with its vaccine and metric, the place (admin level, division, district)
# and the period (a year, or a month). `value` is a percent for coverage and dropout, a count
# otherwise. Metrics: target, doses, coverage (uncapped), coverage-dashboard (as the dashboard
# shows it, capped at 100), unvaccinated, dropout.
# target_ok: false when a place's target for the year is more than 3 times, or under a third of,
# the median of its targets over the three years. The dashboard's targets for a few place-years
# are off by up to 80,000 times (Bangladesh 2024: 621 million; Boalmari 2026: 189,749); for
# those, the figures that divide by the target (coverage, zero-dose) are left out (null).
set -euo pipefail
PARQUET="${DATA:-$(cd "$(dirname "$0")/../../../../../country/bangladesh/warehouse" && pwd)}/parquet"
duckdb -c "
COPY (
  WITH v AS (SELECT * FROM read_parquet('$PARQUET/indicator_value/**/*.parquet', hive_partitioning=true, union_by_name=true)
             WHERE measure LIKE '%/Measure/bd-ri-%'),
       l AS (SELECT id, name, admin_level, admin1_name, admin2_name FROM read_parquet('$PARQUET/locations/**/*.parquet', hive_partitioning=true, union_by_name=true)),
       k AS (SELECT *, regexp_extract(measure, 'bd-ri-(.*)$', 1) AS key FROM v),
       t AS (SELECT location_id, left(period, 4) AS year, max(count) AS target FROM k WHERE key = 'target' GROUP BY ALL),
       m AS (SELECT location_id, median(target) AS mid FROM t GROUP BY 1),
       ok AS (SELECT t.location_id, t.year, coalesce(t.target BETWEEN m.mid / 3.0 AND m.mid * 3.0, true) AS target_ok
              FROM t JOIN m USING (location_id))
  SELECT k.key,
         CASE WHEN key = 'target' THEN 'all' WHEN key LIKE 'dropout-%' THEN regexp_extract(key, 'dropout-(.*)$', 1)
              ELSE regexp_extract(key, '^([a-z0-9]+)-', 1) END AS vaccine,
         CASE WHEN key = 'target' THEN 'target' WHEN key LIKE 'dropout-%' THEN 'dropout'
              ELSE regexp_extract(key, '^[a-z0-9]+-(.*)$', 1) END AS metric,
         k.location_id, coalesce(l.name, k.location_name) AS location_name, l.admin_level,
         regexp_replace(coalesce(l.admin1_name, ''), ' Division$', '') AS division,
         regexp_replace(coalesce(l.admin2_name, ''), ' District$', '') AS district,
         k.period, CASE WHEN length(k.period) = 4 THEN 'Yearly' ELSE 'Monthly' END AS period_type,
         k.period_start, k.numerator, k.denominator, k.count,
         coalesce(ok.target_ok, true) AS target_ok,
         CASE WHEN NOT coalesce(ok.target_ok, true) AND (key LIKE '%coverage%' OR key LIKE '%unvaccinated') THEN NULL
              WHEN key LIKE '%coverage%' OR key LIKE 'dropout-%' THEN round(k.score * 100, 2) ELSE k.score END AS value
  FROM k LEFT JOIN l ON l.id = k.location_id LEFT JOIN ok ON ok.location_id = k.location_id AND ok.year = left(k.period, 4)
  ORDER BY key, l.admin_level, location_name, k.period_start
) TO '/dev/stdout' (FORMAT PARQUET);"
