#!/usr/bin/env bash
# Every facility of the country with its chiefdom, district, DHIS2 facility type and position
# (null when DHIS2 has none). Read from the Location snapshot the warehouse refresh keeps in
# data/raw/, because the GeoParquet dataset leaves out facilities without coordinates.
set -euo pipefail
DATA="${DATA:-$(cd "$(dirname "$0")/../../../../../data" && pwd)}"
COUNTRY="${COUNTRY:-SLE}"
PREFIX="${PREFIX:-sle-}"
duckdb -c "
COPY (
  WITH f AS (
    SELECT json->>'id' AS id, json->>'name' AS name,
           regexp_replace(json->'partOf'->>'reference', '^Location/', '') AS parent,
           (json->'position'->>'longitude')::DOUBLE AS lon, (json->'position'->>'latitude')::DOUBLE AS lat,
           list_filter(json_extract(json, '\$.type')::JSON[], lambda t: json_extract_string(t, '\$.coding[0].system') LIKE '%/dimension/J5jldMd8OHv')[1]->>'text' AS facility_type
    FROM read_ndjson_objects('$DATA/raw/*/locations/locations.ndjson')
    WHERE json->>'id' LIKE '$PREFIX%'
      AND json_extract_string(json, '\$.type[0].coding[0].code') = 'facility'),
  c AS (SELECT id, name, admin1_name FROM read_parquet('$DATA/parquet/locations/country=$COUNTRY/**/*.parquet', hive_partitioning=true, union_by_name=true)
        WHERE type = 'admin-unit')
  SELECT f.id, f.name, c.name AS chiefdom, c.admin1_name AS district, f.facility_type, f.lon, f.lat
  FROM f LEFT JOIN c ON c.id = f.parent
  ORDER BY district, chiefdom, f.name
) TO '/dev/stdout' (FORMAT PARQUET);"
