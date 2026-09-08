#!/usr/bin/env bash
# One file per Export layer (facility/settlement/lga/state — see the other
# locations-*.parquet.sh loaders), read directly from kiln's own partition
# layout (data/parquet/locations/country=NGA/geom_type=.../type=...) rather
# than scanning+filtering the whole registry. index.md loads only the file
# for the currently selected layer, so picking "Health facilities" (the
# default) fetches ~3.5 MB instead of the ~27 MB every-layer-combined file
# this used to be.
#
# Points ship as bare lon/lat doubles, not precomputed GeoJSON text — the
# page builds the GeoJSON itself client-side (cheap) only for the rows
# actually exported.
set -euo pipefail
DATA="$(cd "$(dirname "$0")/../../../../data" && pwd)"
duckdb -c "
COPY (
  SELECT id, name, type, status, admin_level,
         admin1_name AS state, admin2_name AS lga, admin3_name AS ward,
         replace(facility_level_text, chr(160), ' ') AS facility_level,
         ownership_text AS ownership, settlement_type,
         pcode, nhfr_code,
         position_longitude AS lon, position_latitude AS lat,
         CAST(NULL AS VARCHAR) AS geometry_geojson
  FROM read_parquet('$DATA/parquet/locations/country=NGA/geom_type=point/type=facility/*.parquet')
) TO '/dev/stdout' (FORMAT PARQUET);"
