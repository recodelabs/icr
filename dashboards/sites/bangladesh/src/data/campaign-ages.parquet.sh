#!/usr/bin/env bash
# MR campaign 2026 targets and children vaccinated per place, for the whole campaign
# (2026-04-05/2026-05-20), for all ages and for the 1-year age group (community). The 1-year
# group is the birth cohort closest to the routine 0–11-month target, so the
# routine-vs-campaign page compares the two.
set -euo pipefail
PARQUET="${DATA:-$(cd "$(dirname "$0")/../../../../../country/bangladesh/warehouse" && pwd)}/parquet"
duckdb -c "
COPY (
  WITH v AS (SELECT location_id, regexp_extract(measure, '[^/]+$') AS m, count
             FROM read_parquet('$PARQUET/indicator_value/**/*.parquet', hive_partitioning=true, union_by_name=true)
             WHERE period = '2026-04-05/2026-05-20')
  SELECT location_id,
         max(count) FILTER (WHERE m = 'bd-epi-ZmfFR6ieSHg') AS target_1y,
         max(count) FILTER (WHERE m = 'bd-epi-PLsyc7XfCYo') AS vaccinated_1y,
         max(count) FILTER (WHERE m = 'bd-epi-WaAXoj3iiRv') AS target_all,
         max(count) FILTER (WHERE m = 'bd-epi-IIu9d1VChct') AS vaccinated_all
  FROM v GROUP BY 1
) TO '/dev/stdout' (FORMAT PARQUET);"
