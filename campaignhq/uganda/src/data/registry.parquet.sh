#!/usr/bin/env bash
# The location registry: every admin unit with its codes (P-code, ISO, Overture GERS id,
# Wikidata), aliases and boundary source, with a centroid and bounding box for labels and zoom.
set -euo pipefail
# The Uganda warehouse: a copy pulled from R2 uga/ by deploy.sh, or country/uganda/warehouse.
DATA="${DATA:-$(cd "$(dirname "$0")/../../../../country/uganda/warehouse" && pwd)}"
W="$DATA/parquet"
export DUCKDB_AGENT_MODE=0
# Globs start at country=*/ so the Portolan metadata beside the data (items.parquet) is not read.
P() { echo "read_parquet('$W/$1/country=*/**/*.parquet', hive_partitioning=true, union_by_name=true)"; }
duckdb -c "
LOAD spatial;
COPY (
  SELECT id, name, admin_level, part_of, admin1_name AS region, path, pcode, gers_id,
         list_extract(list_transform(list_filter(identifier, lambda x: x.system = 'http://www.wikidata.org/entity'), lambda x: x.value), 1) AS wikidata,
         list_extract(list_transform(list_filter(identifier, lambda x: x.system LIKE 'urn:iso:std:iso:3166%'), lambda x: x.value), 1) AS iso,
         array_to_string(alias, '; ') AS aliases, description, last_updated,
         ST_X(ST_Centroid(geometry)) AS lon, ST_Y(ST_Centroid(geometry)) AS lat,
         ST_XMin(geometry) AS xmin, ST_YMin(geometry) AS ymin, ST_XMax(geometry) AS xmax, ST_YMax(geometry) AS ymax
  FROM $(P locations)
  WHERE type = 'admin-unit'
  ORDER BY admin_level, region, name
) TO '/dev/stdout' (FORMAT PARQUET);"
