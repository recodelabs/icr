#!/usr/bin/env bash
# Push the analytics hub (data/) to Cloudflare R2 so dashboards and other
# consumers read the same parquet, tiles and manifest from the cloud.
#
#   data/parquet/  data/tiles/  data/views/  data/manifest.json  data/catalog.sql
#     ──rclone sync──▶  r2:<bucket>/  (same paths)
#
# raw/ (NDJSON snapshots, server-specific, hundreds of MB) is NOT pushed.
#
# Uses the `r2` rclone remote (S3 API on this Cloudflare account). Sync is
# checksum-based and deletes objects that no longer exist locally, so the
# bucket mirrors data/ exactly — treat it as derived, like data/ itself.
#
# Usage: tools/warehouse/push-r2.sh [--dry-run]
# Env:   R2_BUCKET (icr)  R2_REMOTE (r2)  DATA (repo data/)
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
DATA="${DATA:-$REPO/data}"
BUCKET="${R2_BUCKET:-icr}"
REMOTE="${R2_REMOTE:-r2}"
DRY=""
for a in "$@"; do
  case "$a" in
    --dry-run) DRY="--dry-run" ;;
    *) echo "unknown option $a" >&2; exit 2 ;;
  esac
done

command -v rclone >/dev/null || { echo "rclone not installed (brew install rclone) or the '$REMOTE' remote is not configured" >&2; exit 1; }
rclone lsd "$REMOTE:" 2>/dev/null | awk '{print $NF}' | grep -qx "$BUCKET" || {
  echo "bucket '$BUCKET' not found on remote '$REMOTE'. Create it with:  wrangler r2 bucket create $BUCKET" >&2; exit 1; }

echo "== push data/ → $REMOTE:$BUCKET ${DRY:+(dry run)}"
for d in parquet tiles views; do
  [ -d "$DATA/$d" ] || continue
  rclone sync $DRY --checksum --fast-list --transfers 8 --exclude ".DS_Store" \
    "$DATA/$d" "$REMOTE:$BUCKET/$d" --stats-one-line -v 2>&1 | grep -v "^$" | tail -3
done
for f in manifest.json catalog.sql; do
  [ -f "$DATA/$f" ] && rclone copyto $DRY "$DATA/$f" "$REMOTE:$BUCKET/$f"
done
echo "== done"
[ -n "$DRY" ] || rclone size "$REMOTE:$BUCKET" | sed 's/^/   /'
