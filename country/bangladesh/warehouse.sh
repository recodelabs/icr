#!/usr/bin/env bash
# Refresh Bangladesh's warehouse (warehouse/) from the Bangladesh ICR server, and with --push
# publish it to the bgd/ folder of the `icr` R2 bucket. See README.md and tools/warehouse/README.md.
#
#   ./warehouse.sh            refresh: locations and the IG's views (indicators, values, campaign)
#   ./warehouse.sh --push     and upload it
#   ./warehouse.sh --full     download everything again (after deletes or a reload on the server)
#
# The dashboards (dashboards/sites/bangladesh, observatory deploy) build from r2:icr/bgd/. Nothing
# in it is public: there is no SDI for Bangladesh and no map tiles.
#
# fhir-pipes 0.6 `refresh` leaves out Locations without geometry, and some divisions, camps and
# city zones have none. So: refresh the locations, run the transform again with
# --keep-without-geometry into parquet/locations, then build the views against that table so
# every location_id resolves.
#
# The key comes from ~/.config/icr/bgd-loader.env (or $KEY_FILE). Needs fhir-pipes (0.6), duckdb
# and rclone with the r2 remote, and the IG built (sushi build . in ig/).
set -euo pipefail
cd "$(dirname "$0")"
set -a; . "${KEY_FILE:-$HOME/.config/icr/bgd-loader.env}"; set +a
export FHIR_PIPES_CLIENT_ID="$FHIR_CLIENT_ID" FHIR_PIPES_CLIENT_SECRET="$FHIR_CLIENT_SECRET"
export DUCKDB_AGENT_MODE=0   # keep DuckDB 2.0's agent banner out of fhir-pipes' output

PUSH=0 FULL=()
for a in "$@"; do
  case "$a" in
    --push) PUSH=1 ;;
    --full) FULL=(--full) ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

PROFILE=../../ig/fhir-pipes-profile.toml
[ -f ../../ig/fsh-generated/resources/Binary-IcrIndicatorValue.json ] || { echo "no IG views: run sushi build . in ig/" >&2; exit 1; }

fhir-pipes refresh --config fhir-pipes.toml --only locations ${FULL[@]+"${FULL[@]}"}
rm -rf build/locations
fhir-pipes transform locations --snapshot warehouse/raw/bgd/locations --out build/locations \
  --keep-without-geometry --profile "$PROFILE" | sed -n '/Issues found/,$p'
rm -rf warehouse/parquet/locations
mv build/locations/locations warehouse/parquet/locations
cp build/locations/_report.json warehouse/parquet/_report.json
rm -rf build/locations
fhir-pipes refresh --config fhir-pipes.toml --only views,manifest ${FULL[@]+"${FULL[@]}"}

if [ "$PUSH" = 1 ]; then
  # fhir-pipes' own push syncs to the root of a bucket; this warehouse lives in a folder of one.
  DEST=r2:icr/bgd
  for d in parquet views; do
    rclone sync --checksum --exclude ".DS_Store" "warehouse/$d" "$DEST/$d"
  done
  rclone copyto --checksum warehouse/manifest.json "$DEST/manifest.json"
  echo "== r2:icr/bgd/ (private)"
fi
