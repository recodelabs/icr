#!/usr/bin/env bash
# MR campaign 2026 coverage for the whole campaign (2026-04-05/2026-05-20) per place, from the
# local warehouse: vaccinated ÷ target as DHIS2 computes it (item wzJjkgmTUT3). Small, for the
# routine-vs-campaign page.
set -euo pipefail
PARQUET="${DATA:-$(cd "$(dirname "$0")/../../../../../country/bangladesh/warehouse" && pwd)}/parquet"
duckdb -c "
COPY (
  SELECT location_id, numerator AS vaccinated, denominator AS target, round(score * 100, 2) AS value
  FROM read_parquet('$PARQUET/indicator_value/**/*.parquet', hive_partitioning=true, union_by_name=true)
  WHERE measure LIKE '%/Measure/bd-epi-wzJjkgmTUT3' AND period = '2026-04-05/2026-05-20'
) TO '/dev/stdout' (FORMAT PARQUET);"
