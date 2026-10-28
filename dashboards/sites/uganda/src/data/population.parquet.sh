#!/usr/bin/env bash
# One row per place (country, regions, districts and cities): the Ministry of Health's total
# population 2026 and catch population 2025 beside WorldPop's 2026 total.
# The SQL lives in the Library analytics/UgandaPopulation.sql; the refresh writes its result to the warehouse
# as uganda_population (one file, not partitioned). This loader copies it, in the Library's order.
set -euo pipefail
# The Uganda warehouse: a copy pulled from R2 uga/ by observatory, or country/uganda/warehouse.
DATA="${DATA:-$(cd "$(dirname "$0")/../../../../../country/uganda/warehouse" && pwd)}"
W="$DATA/parquet"
export DUCKDB_AGENT_MODE=0
P() { echo "read_parquet('$W/$1/part-0.parquet')"; }
duckdb -c "
COPY (
  SELECT * FROM $(P uganda_population)
  ORDER BY admin_level, region, location_name
) TO '/dev/stdout' (FORMAT PARQUET);"
