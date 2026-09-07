#!/usr/bin/env bash
# Admin boundaries → PMTiles for the dashboards' MapLibre maps.
#
#   data/parquet/locations (GeoParquet polygons) ──duckdb spatial──▶ GeoJSON ──tippecanoe──▶ data/tiles/admin.pmtiles
#
# One PMTiles archive, two layers: `states` (admin_level 1) and `lgas` (admin_level 2),
# each feature carrying id, name, admin_level, admin1_name (state) and path, so a
# dashboard can promoteId on `id` and set feature-state from the campaign tables.
#
# Usage: tools/warehouse/tiles.sh [COUNTRY=NGA]      Env: DATA (repo data/)
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
DATA="${DATA:-$REPO/data}"
COUNTRY="${1:-NGA}"
SRC="$DATA/parquet/locations/country=$COUNTRY/geom_type=polygon/type=admin-unit/*.parquet"
OUT="$DATA/tiles"
TMP="$(mktemp -d -t icr-tiles)"
mkdir -p "$OUT"

echo "== boundaries → GeoJSON ($COUNTRY)"
for lvl in 1 2; do
  name=$([ "$lvl" = 1 ] && echo states || echo lgas)
  duckdb -c "
    LOAD spatial; SET geometry_always_xy = true;
    COPY (
      SELECT id, name, admin_level, admin1_name, admin2_name, path, geometry
      FROM read_parquet('$SRC')
      WHERE admin_level = $lvl
    ) TO '$TMP/$name.geojson' WITH (FORMAT GDAL, DRIVER 'GeoJSON');"
  echo "   $name: $(grep -c '"type": *"Feature"' "$TMP/$name.geojson" | tr -d ' ') features"
done

echo "== tippecanoe → $OUT/admin.pmtiles"
tippecanoe --force -o "$OUT/admin.pmtiles" \
  --minimum-zoom=4 --maximum-zoom=11 \
  --coalesce-densest-as-needed --extend-zooms-if-still-dropping \
  --simplification=8 --no-tile-size-limit \
  --quiet -L "states:$TMP/states.geojson" -L "lgas:$TMP/lgas.geojson"
ls -la "$OUT/admin.pmtiles" | awk '{print "   " $5 " bytes"}'
rm -rf "$TMP"
