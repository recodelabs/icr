#!/usr/bin/env bash
# Every MR value in the local warehouse (IcrIndicatorValue) with the item's DHIS2 uid, name and
# factor (IcrIndicator) and the place (places.parquet.sh). `value` is the figure as DHIS2 shows it.
# period_type: Daily, Weekly, Monthly, or Campaign (the whole-campaign range).
set -euo pipefail
PARQUET="${DATA:-$(cd "$(dirname "$0")/../../../../../country/bangladesh/warehouse" && pwd)}/parquet"
HERE="$(cd "$(dirname "$0")" && pwd)"
PLACES="$(mktemp -t places).parquet"; trap 'rm -f "$PLACES"' EXIT
bash "$HERE/places.parquet.sh" > "$PLACES"
duckdb -c "
COPY (
  WITH v AS (SELECT * FROM read_parquet('$PARQUET/indicator_value/**/*.parquet', hive_partitioning=true, union_by_name=true)),
       i AS (SELECT * FROM read_parquet('$PARQUET/indicator/**/*.parquet', hive_partitioning=true, union_by_name=true)),
       p AS (SELECT * FROM read_parquet('$PLACES'))
  SELECT regexp_replace(i.measure_id, '^' || i.source || '-', '') AS dx, i.title AS name,
         CASE WHEN i.indicator_type LIKE 'Data element%' THEN 'data element'
              WHEN i.indicator_type LIKE 'Reporting rate%' THEN 'reporting rate' ELSE 'indicator' END AS kind,
         coalesce(i.factor, 1) AS factor,
         v.location_id, coalesce(p.name, v.location_name) AS location_name, p.level, p.kind AS place_kind, p.division, p.district,
         v.period,
         CASE WHEN regexp_matches(v.period, '^[0-9]{4}-[0-9]{2}-[0-9]{2}/[0-9]{4}-[0-9]{2}-[0-9]{2}$') THEN 'Campaign'
              WHEN regexp_matches(v.period, '^[0-9]{8}$') THEN 'Daily'
              WHEN regexp_matches(v.period, '^[0-9]{4}W[0-9]+$') THEN 'Weekly'
              WHEN regexp_matches(v.period, '^[0-9]{6}$') THEN 'Monthly' ELSE 'Other' END AS period_type,
         v.period_start, v.period_end, v.numerator, v.denominator, v.count,
         round(v.score * coalesce(i.factor, 1), 2) AS value
  FROM v JOIN i ON i.url = v.measure LEFT JOIN p ON p.id = v.location_id
  ORDER BY dx, p.level, location_name, v.period_start
) TO '/dev/stdout' (FORMAT PARQUET);"
