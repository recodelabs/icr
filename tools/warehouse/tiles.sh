#!/usr/bin/env bash
# Location registry → PMTiles for the dashboards' MapLibre maps.
#
#   data/parquet/locations (GeoParquet) ──duckdb spatial──▶ GeoJSON ──tippecanoe──▶ data/tiles/*.pmtiles
#
#   admin.pmtiles        polygons: `country` (admin_level 0), `states` (1), `lgas` (2). Each feature
#                        carries id, name, admin_level, admin1_name, admin2_name, path, so a dashboard
#                        can promoteId on `id` and set feature-state from the campaign tables.
#   facilities.pmtiles   points: `facilities` — every health facility, no point dropped at any zoom.
#   settlements.pmtiles  points: `settlements` — every settlement, no point dropped at any zoom
#                        (z8+; ~300k points, so it is kept out of the low zooms and loaded on demand).
#
# Point layers are built with --drop-rate=1 --no-feature-limit --no-tile-size-limit so tippecanoe
# never thins them: what is in the registry is what is on the map.
#
# Usage: tools/warehouse/tiles.sh [COUNTRY=NGA]      Env: DATA (repo data/)
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
DATA="${DATA:-$REPO/data}"
COUNTRY="${1:-NGA}"
POLY="$DATA/parquet/locations/country=$COUNTRY/geom_type=polygon/type=admin-unit/*.parquet"
POINTS="$DATA/parquet/locations/country=$COUNTRY/geom_type=point/**/*.parquet"
OUT="$DATA/tiles"
TMP="$(mktemp -d -t icr-tiles)"
mkdir -p "$OUT"

count() { grep -c '"type": *"Feature"' "$1" | tr -d ' '; }

echo "== boundaries → GeoJSON ($COUNTRY)"
for lvl in 0 1 2; do
  case $lvl in 0) name=country ;; 1) name=states ;; 2) name=lgas ;; esac
  duckdb -c "
    LOAD spatial; SET geometry_always_xy = true;
    COPY (
      SELECT id, name, admin_level, admin1_name, admin2_name, path, pcode, geometry
      FROM read_parquet('$POLY')
      WHERE admin_level = $lvl
    ) TO '$TMP/$name.geojson' WITH (FORMAT GDAL, DRIVER 'GeoJSON');"
  echo "   $name: $(count "$TMP/$name.geojson") features"
done

echo "== tippecanoe → $OUT/admin.pmtiles"
tippecanoe --force -o "$OUT/admin.pmtiles" \
  --minimum-zoom=4 --maximum-zoom=11 \
  --coalesce-densest-as-needed --extend-zooms-if-still-dropping \
  --simplification=8 --no-tile-size-limit \
  --quiet -L "country:$TMP/country.geojson" -L "states:$TMP/states.geojson" -L "lgas:$TMP/lgas.geojson"
ls -la "$OUT/admin.pmtiles" | awk '{print "   " $5 " bytes"}'

# Point layers carry the full registry record, so a click on the map shows the item's properties
# straight from the tile. The archives are served with HTTP range requests (PMTiles), so only the
# tiles in view are ever fetched and the total size does not matter to the browser.
POINT_COLS="id, name, type, status, admin1_name, admin2_name, admin3_name, pcode, gers_id, nhfr_code, nhfr_uid,
            replace(facility_level_text, chr(160), ' ') AS facility_level, ownership_text AS ownership, settlement_type,
            managing_organization, part_of, last_updated,
            round(position_longitude, 5) AS lon, round(position_latitude, 5) AS lat"

echo "== facilities → GeoJSON"
duckdb -c "
  LOAD spatial; SET geometry_always_xy = true;
  COPY (
    SELECT $POINT_COLS, geometry
    FROM read_parquet('$POINTS', hive_partitioning=true, union_by_name=true)
    WHERE type = 'facility' AND geometry IS NOT NULL
  ) TO '$TMP/facilities.geojson' WITH (FORMAT GDAL, DRIVER 'GeoJSONSeq');"
echo "   facilities: $(count "$TMP/facilities.geojson") features"

echo "== tippecanoe → $OUT/facilities.pmtiles (no dropping)"
tippecanoe --force -o "$OUT/facilities.pmtiles" \
  --minimum-zoom=4 --maximum-zoom=12 --base-zoom=4 \
  --drop-rate=1 --no-feature-limit --no-tile-size-limit \
  --quiet -l facilities "$TMP/facilities.geojson"
ls -la "$OUT/facilities.pmtiles" | awk '{print "   " $5 " bytes"}'

echo "== settlements → GeoJSON"
duckdb -c "
  LOAD spatial; SET geometry_always_xy = true;
  COPY (
    SELECT $POINT_COLS, geometry
    FROM read_parquet('$POINTS', hive_partitioning=true, union_by_name=true)
    WHERE type = 'settlement' AND geometry IS NOT NULL
  ) TO '$TMP/settlements.geojson' WITH (FORMAT GDAL, DRIVER 'GeoJSONSeq');"
echo "   settlements: $(count "$TMP/settlements.geojson") features"

echo "== tippecanoe → $OUT/settlements.pmtiles (no dropping, z8+)"
tippecanoe --force -o "$OUT/settlements.pmtiles" \
  --minimum-zoom=8 --maximum-zoom=13 --base-zoom=8 \
  --drop-rate=1 --no-feature-limit --no-tile-size-limit \
  --quiet -l settlements "$TMP/settlements.geojson"
ls -la "$OUT/settlements.pmtiles" | awk '{print "   " $5 " bytes"}'

rm -rf "$TMP"
