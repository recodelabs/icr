#!/usr/bin/env bash
# District and city corporation (admin level 2) and upazila-level (3) boundaries from the
# warehouse's Location registry, as vector tiles: one tile layer per level, `admin2` and
# `admin3`, each feature with id (the Location id), name and district. Read by every page with
# a map (components/unit-map.js). The warehouse's own tiles/admin.pmtiles holds districts only.
# The polygons come from the DGHS GIS dashboard and the CC ward shapefiles (see tools/bd-fhir).
# Needs tippecanoe (brew install tippecanoe).
set -euo pipefail
PARQUET="${DATA:-$(cd "$(dirname "$0")/../../../../../country/bangladesh/warehouse" && pwd)}/parquet"
command -v tippecanoe >/dev/null || { echo "boundaries.pmtiles.sh needs tippecanoe" >&2; exit 1; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
for level in 2 3; do
  DUCKDB_AGENT_MODE=0 duckdb -noheader -list -c "
  INSTALL spatial; LOAD spatial;
  SELECT json_object('type', 'Feature',
    'properties', json_object('id', id, 'name', name, 'district', coalesce(admin2_name, '')),
    'geometry', ST_AsGeoJSON(geometry)::JSON)
  FROM read_parquet('$PARQUET/locations/**/*.parquet', hive_partitioning=true, union_by_name=true)
  WHERE admin_level = $level AND geom_type IN ('polygon', 'multipolygon') AND type = 'admin-unit' AND geometry IS NOT NULL
  ORDER BY id;" > "$TMP/admin$level.geojsonl"
done
# Zooms 3 to 9 (the map overzooms past 9, and shows nothing below 3), simplified to about 80 m at zoom 9: 1.1 MB. No feature
# is dropped to keep a tile small. tippecanoe records its file names in the tiles, so it runs
# inside the temporary folder with fixed names: the same boundaries then give the same file.
(cd "$TMP" && tippecanoe -q -f -o boundaries.pmtiles -n boundaries -Z3 -z9 --simplification=4 \
  --no-tiny-polygon-reduction --no-tile-size-limit --no-feature-limit \
  -L admin2:admin2.geojsonl -L admin3:admin3.geojsonl >&2)
cat "$TMP/boundaries.pmtiles"
