#!/usr/bin/env bash
# The DHIS2 groups of every item (IcrIndicatorGroup): indicator groups, data element groups,
# and for data element group sets the set's uid, so items can be regrouped like DHIS2 does.
set -euo pipefail
DATA="${DATA:-$(cd "$(dirname "$0")/../../../../data" && pwd)}"
duckdb -c "
COPY (
  WITH g AS (SELECT * FROM read_parquet('$DATA/parquet/indicator_group/country=*/*.parquet', hive_partitioning=true, union_by_name=true)),
       i AS (SELECT * FROM read_parquet('$DATA/parquet/indicator/country=*/*.parquet', hive_partitioning=true, union_by_name=true))
  SELECT regexp_replace(i.measure_id, '^' || i.source || '-', '') AS dx, i.title AS name,
         regexp_extract(g.group_system, 'data-element-group-set/([A-Za-z0-9]+)\$', 1) AS group_set,
         g.group_code, g.group_name
  FROM g JOIN i ON i.url = g.measure_url
) TO '/dev/stdout' (FORMAT PARQUET);"
