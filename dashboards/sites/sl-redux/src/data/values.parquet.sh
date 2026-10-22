#!/usr/bin/env bash
# Every DHIS2 value for one country (default SLE): indicator and data element values
# (IcrIndicatorValue) with the item's DHIS2 uid, name and factor (IcrIndicator) and the
# place's name, level and district (locations). `value` is the figure as DHIS2 shows it.
set -euo pipefail
DATA="${DATA:-$(cd "$(dirname "$0")/../../../../../data" && pwd)}"
COUNTRY="${COUNTRY:-SLE}"
PREFIX="${PREFIX:-sle-}"
duckdb -c "
COPY (
  -- Facilities without coordinates are not in the GeoParquet dataset, so the refresh cannot
  -- give their values a country; pick those up by their Location id prefix.
  WITH v AS (SELECT * FROM read_parquet('$DATA/parquet/indicator_value/country=*/*.parquet', hive_partitioning=true, union_by_name=true)
             WHERE country = '$COUNTRY' OR (country IS NULL AND location_id LIKE '$PREFIX%')),
       i AS (SELECT * FROM read_parquet('$DATA/parquet/indicator/country=*/*.parquet', hive_partitioning=true, union_by_name=true)),
       l AS (SELECT id, name, admin_level, admin1_name, admin2_name
             FROM read_parquet('$DATA/parquet/locations/country=$COUNTRY/**/*.parquet', hive_partitioning=true, union_by_name=true)
             WHERE type = 'admin-unit')
  SELECT regexp_replace(i.measure_id, '^' || i.source || '-', '') AS dx,
         i.title AS name,
         CASE WHEN i.indicator_type LIKE 'Data element%' THEN 'data element'
              WHEN i.indicator_type LIKE 'Reporting rate%' THEN 'reporting rate' ELSE 'indicator' END AS kind,
         coalesce(i.factor, 1) AS factor,
         v.location_id, coalesce(l.name, v.location_name) AS location_name, l.admin_level,
         coalesce(l.admin1_name, l.name) AS district, l.admin2_name AS chiefdom,
         v.period,
         CASE WHEN regexp_matches(v.period, '^[0-9]{4}$') THEN 'Yearly'
              WHEN regexp_matches(v.period, '^[0-9]{6}$') THEN 'Monthly'
              WHEN regexp_matches(v.period, '^[0-9]{4}Q[1-4]$') THEN 'Quarterly'
              WHEN regexp_matches(v.period, '^[0-9]{4}S[12]$') THEN 'SixMonthly'
              ELSE 'Other' END AS period_type,
         v.period_start, v.period_end, v.numerator, v.denominator, v.count,
         round(v.score * coalesce(i.factor, 1), 2) AS value
  FROM v JOIN i ON i.url = v.measure
  LEFT JOIN l ON l.id = v.location_id
  ORDER BY dx, admin_level, location_name, period_start
) TO '/dev/stdout' (FORMAT PARQUET);"
