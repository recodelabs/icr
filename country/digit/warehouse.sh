#!/usr/bin/env bash
# Refresh the DIGIT demo warehouse (warehouse/) from the DIGIT ICR server, and with --push publish
# it to the digit/ folder of the `icr` R2 bucket. See README.md and tools/warehouse/README.md.
# DIGIT is a demo tenant (eGov's DIGIT HCM demo data, fake), not a country.
#
#   ./warehouse.sh            refresh: locations and the views (the IG's and views/Digit*.json)
#   ./warehouse.sh --push     and upload it
#   ./warehouse.sh --full     download everything again (after deletes or a reload on the server)
#
# The dashboards (dashboards/sites/digit, observatory deploy) build from r2:icr/digit/. Nothing in
# it is public: there is no SDI for DIGIT and no map tiles (the boundaries have no geometry).
#
# The views: the IG's ViewDefinitions (../../ig/fsh-generated/resources, or $IG_VIEWS), plus the
# DIGIT ones in views/.
#
# The key comes from ~/.config/icr/digit-loader.env (or $KEY_FILE). Needs fhir-pipes (0.6), duckdb
# and rclone with the r2 remote, and the IG built (sushi build . in ig/).
set -euo pipefail
cd "$(dirname "$0")"
set -a; . "${KEY_FILE:-$HOME/.config/icr/digit-loader.env}"; set +a
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

IG_VIEWS=${IG_VIEWS:-../../ig/fsh-generated/resources}
[ -f "$IG_VIEWS/Binary-IcrCampaignTask.json" ] || { echo "no IG views in $IG_VIEWS: run sushi build . in ig/" >&2; exit 1; }
echo "== IG views from $IG_VIEWS"
rm -rf build/views && mkdir -p build/views
cp "$IG_VIEWS"/Binary-Icr*.json build/views/
cp views/Digit*.json build/views/

fhir-pipes refresh --config fhir-pipes.toml --only locations,views ${FULL[@]+"${FULL[@]}"}

if [ "$PUSH" = 1 ]; then
  # fhir-pipes' own push syncs to the root of a bucket; this warehouse lives in a folder of one.
  DEST=r2:icr/digit
  for d in parquet views; do
    rclone sync --checksum --exclude ".DS_Store" "warehouse/$d" "$DEST/$d"
  done
  rclone copyto --checksum warehouse/manifest.json "$DEST/manifest.json"
  echo "== r2:icr/digit/ (private; dashboards: https://dashboards.healthcampaigns.org/digit/)"
fi
