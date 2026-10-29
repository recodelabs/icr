#!/usr/bin/env bash
# Feature counts per layer × state × LGA (× facility level) for the Georegistry page's
# KPIs and cascading filters.
# Not a Library: it counts every Location by type and facility level, columns of the locations
# table that LocationHierarchy, the only Location input a Library has, does not carry.
set -euo pipefail
DATA="${DATA:-$(cd "$(dirname "$0")/../../../../../data" && pwd)}"
duckdb -c "
LOAD spatial;
COPY (
  SELECT country, type AS layer, admin_level, admin1_name AS state, admin2_name AS lga,
         replace(facility_level_text, chr(160), ' ') AS facility_level, count(*) AS n   -- the registry label has a no-break space
  FROM read_parquet('$DATA/parquet/locations/country=*/**/*.parquet', hive_partitioning=true, union_by_name=true)
  GROUP BY ALL ORDER BY ALL
) TO '/dev/stdout' (FORMAT PARQUET);"
