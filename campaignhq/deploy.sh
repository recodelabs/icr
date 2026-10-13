#!/usr/bin/env bash
# Build Campaign Dashboards and publish it to https://dashboards.healthcampaigns.org.
#
#   observable build ──▶ dist/ ──rclone sync──▶ r2:icr/_site/campaignhq/ ──▶ wrangler deploy (Worker)
#
# The Worker (worker/index.js) serves the site straight from R2; the data it
# was built from is the local data/ hub (run tools/warehouse/refresh.sh first).
#
# Two more Framework sites are served under it, each from its own folder and built
# from its own directory here:
#   sldash/    → /dhis2-sl/         the DHIS2 demo's Sierra Leone dashboards
#   sl-redux/  → /dhis2-sl-redux/   the same, redrawn for comparing districts
# The main site's sync leaves those folders alone.
#
# Usage: ./deploy.sh [--skip-build] [--dry-run] [SITE...]
#        SITE: main (the default), sldash, sl-redux, or all
# Env:   R2_BUCKET (icr)  R2_REMOTE (r2)
set -euo pipefail
cd "$(dirname "$0")"
BUCKET="${R2_BUCKET:-icr}"
REMOTE="${R2_REMOTE:-r2}"
SUBSITES=("sldash:dhis2-sl" "sl-redux:dhis2-sl-redux")
BUILD=1; DRY=""; SITES=()
for a in "$@"; do
  case "$a" in
    --skip-build) BUILD=0 ;;
    --dry-run) DRY="--dry-run" ;;
    main|sldash|sl-redux) SITES+=("$a") ;;
    all) SITES+=(main sldash sl-redux) ;;
    *) echo "unknown option $a" >&2; exit 2 ;;
  esac
done
[ ${#SITES[@]} -gt 0 ] || SITES=(main)

rclone lsd "$REMOTE:" 2>/dev/null | awk '{print $NF}' | grep -qx "$BUCKET" || {
  echo "bucket '$BUCKET' not found on rclone remote '$REMOTE'. Create it:  npx wrangler r2 bucket create $BUCKET" >&2; exit 1; }

# sync DIR PREFIX [rclone options…]: mirror DIR/dist to the site folder PREFIX.
sync() {
  local dir="$1" prefix="$2"; shift 2
  if [ "$BUILD" = 1 ]; then
    echo "== build $dir"
    (cd "$dir" && npm run build)
  fi
  echo "== sync $dir/dist → $REMOTE:$BUCKET/_site/campaignhq/$prefix ${DRY:+(dry run)}"
  rclone sync $DRY --checksum --fast-list --transfers 16 --exclude ".DS_Store" "$@" \
    "$dir/dist" "$REMOTE:$BUCKET/_site/campaignhq/$prefix" --stats-one-line -v 2>&1 | grep -v "^$" | tail -3
}

for site in "${SITES[@]}"; do
  if [ "$site" = main ]; then
    excludes=()
    for s in "${SUBSITES[@]}"; do excludes+=(--exclude "/${s#*:}/**"); done
    sync . "" "${excludes[@]}"
    if [ -z "$DRY" ]; then
      echo "== deploy worker"
      npx wrangler deploy
    fi
    echo "== https://dashboards.healthcampaigns.org"
  else
    for s in "${SUBSITES[@]}"; do
      [ "${s%%:*}" = "$site" ] || continue
      sync "$site" "${s#*:}"
      echo "== https://dashboards.healthcampaigns.org/${s#*:}/"
    done
  fi
done
