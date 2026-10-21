#!/usr/bin/env bash
# WorldPop population estimates for Uganda's districts and cities, with region and country
# totals, as ICRTargetPopulation Groups on the Uganda ICR server. See README.md.
#
#   ./population.sh            extract the server's Locations, sum the raster under each district
#   ./population.sh --load     and load the Groups
#   YEAR=2025 ./population.sh  another year (WorldPop R2025A has 2015–2030)
#
# The raster is WorldPop's constrained 100 m grid (R2025A, about 60 MB), downloaded once into
# ~/.cache/worldpop. R2025A is LZW-compressed, which fhir-pipes 0.6.0 can't decode, so it is
# rewritten once with GDAL as DEFLATE (same pixels) and fhir-pipes reads that copy.
# The Groups are total-population estimates with denominator-source worldpop, not the
# planning denominator: the Ministry of Health's figures are what campaigns plan against.
set -euo pipefail
cd "$(dirname "$0")"
YEAR=${YEAR:-2026}
NAME="uga_pop_${YEAR}_CN_100m_R2025A_v1"
URL="https://data.worldpop.org/GIS/Population/Global_2015_2030/R2025A/$YEAR/UGA/v1/100m/constrained/$NAME.tif"
CACHE="${RASTER_CACHE:-$HOME/.cache/worldpop}"
PROFILE=../../ig/fhir-pipes-profile.toml
set -a; . "${KEY_FILE:-$HOME/.config/icr/uga-matt.env}"; set +a
export FHIR_PIPES_CLIENT_ID="$FHIR_CLIENT_ID" FHIR_PIPES_CLIENT_SECRET="$FHIR_CLIENT_SECRET"
mkdir -p build

echo "== extract Locations from $FHIR_BASE"
fhir-pipes extract --server "$FHIR_BASE" --token-url "$FHIR_TOKEN_URL" --snapshot build/snapshot --full

echo "== WorldPop $YEAR"
mkdir -p "$CACHE"
[ -s "$CACHE/$NAME.tif" ] || { curl -fsSL -o "$CACHE/$NAME.tif.tmp" "$URL" && mv "$CACHE/$NAME.tif.tmp" "$CACHE/$NAME.tif"; }
[ -s "$CACHE/$NAME.deflate.tif" ] || gdal_translate -q -co COMPRESS=DEFLATE -co TILED=YES "$CACHE/$NAME.tif" "$CACHE/$NAME.deflate.tif"
fhir-pipes population --profile "$PROFILE" --snapshot build/snapshot --raster "$CACHE/$NAME.deflate.tif" \
  --level 2 --year "$YEAR" \
  --out "build/worldpop-$YEAR.ndjson" --report "build/worldpop-$YEAR-report.json"

if [ "${1:-}" = --load ]; then
  fhir-pipes load --server "$FHIR_BASE" --token-url "$FHIR_TOKEN_URL" --in "build/worldpop-$YEAR.ndjson" --batch-size 50
fi
