#!/usr/bin/env bash
# Feature counts per layer × state × LGA (× facility level) for the Georegistry page's
# KPIs and cascading filters.
set -euo pipefail
DATA="$(cd "$(dirname "$0")/../../../data" && pwd)"
duckdb -c "
LOAD spatial;
COPY (
  SELECT country, type AS layer, admin_level, admin1_name AS state, admin2_name AS lga,
         replace(facility_level_text, chr(160), ' ') AS facility_level, count(*) AS n   -- the registry label has a no-break space
  FROM read_parquet('$DATA/parquet/locations/**/*.parquet', hive_partitioning=true, union_by_name=true)
  GROUP BY ALL ORDER BY ALL
) TO '/dev/stdout' (FORMAT PARQUET);"
