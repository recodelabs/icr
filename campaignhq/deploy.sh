#!/usr/bin/env bash
# Build Campaign Dashboards and publish it to https://monitor.healthcampaigns.org.
#
#   observable build ──▶ dist/ ──rclone sync──▶ r2:icr/_site/campaignhq/ ──▶ wrangler deploy (Worker)
#
# The Worker (worker/index.js) serves the site straight from R2; the data it
# was built from is the local data/ hub (run tools/warehouse/refresh.sh first).
#
# Usage: ./deploy.sh [--skip-build] [--dry-run]
# Env:   R2_BUCKET (icr)  R2_REMOTE (r2)
set -euo pipefail
cd "$(dirname "$0")"
BUCKET="${R2_BUCKET:-icr}"
REMOTE="${R2_REMOTE:-r2}"
BUILD=1; DRY=""
for a in "$@"; do
  case "$a" in
    --skip-build) BUILD=0 ;;
    --dry-run) DRY="--dry-run" ;;
    *) echo "unknown option $a" >&2; exit 2 ;;
  esac
done

rclone lsd "$REMOTE:" 2>/dev/null | awk '{print $NF}' | grep -qx "$BUCKET" || {
  echo "bucket '$BUCKET' not found on rclone remote '$REMOTE'. Create it:  npx wrangler r2 bucket create $BUCKET" >&2; exit 1; }

if [ "$BUILD" = 1 ]; then
  echo "== build"
  npm run build
fi

echo "== sync dist/ → $REMOTE:$BUCKET/_site/campaignhq ${DRY:+(dry run)}"
rclone sync $DRY --checksum --fast-list --transfers 16 --exclude ".DS_Store" \
  dist "$REMOTE:$BUCKET/_site/campaignhq" --stats-one-line -v 2>&1 | grep -v "^$" | tail -3

if [ -z "$DRY" ]; then
  echo "== deploy worker"
  npx wrangler deploy
  echo "== https://monitor.healthcampaigns.org"
fi
