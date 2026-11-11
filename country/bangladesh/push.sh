#!/usr/bin/env bash
# Publish Bangladesh's warehouse to the bgd/ folder of the `icr` R2 bucket, from the offline copy.
#
#   ./push.sh /path/to/offline/warehouse            upload parquet/, tiles/, views/ and the manifest
#   ./push.sh /path/to/offline/warehouse --dry-run  show what would be copied and deleted
#
# Bangladesh has no hosted ICR server. The campaign DHIS2 and the routine e-Tracker are imported
# into a FHIR server that is kept offline (tools/bd-fhir, branch bd/local-dhis2-import), and
# `fhir-pipes refresh` builds the warehouse beside it. This script only uploads that warehouse.
# The raw/ folder (the server's NDJSON snapshot) is not uploaded.
#
# The dashboards (dashboards/sites/bangladesh, observatory deploy) build from r2:icr/bgd/. Nothing
# in it is public: there is no SDI for Bangladesh, and the site needs sign-in.
#
# Needs rclone with the r2 remote.
set -euo pipefail
SRC=${1:-}; [ -d "$SRC/parquet" ] || { echo "usage: push.sh OFFLINE_WAREHOUSE [--dry-run]" >&2; exit 2; }
DRY=(); [ "${2:-}" = --dry-run ] && DRY=(--dry-run)
DEST=r2:icr/bgd
for d in parquet tiles views; do
  [ -d "$SRC/$d" ] && rclone sync --checksum --exclude ".DS_Store" ${DRY[@]+"${DRY[@]}"} "$SRC/$d" "$DEST/$d"
done
rclone copyto --checksum ${DRY[@]+"${DRY[@]}"} "$SRC/manifest.json" "$DEST/manifest.json"
echo "== $DEST/ (private)"
