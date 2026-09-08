#!/usr/bin/env bash
# Deploy the SDI Worker that serves the Portolan catalog from the `icr` R2
# bucket at https://sdi.healthcampaigns.org.
#
# The catalog content itself (catalog.json, collections, parquet, tiles) is
# data/ pushed by tools/warehouse/push-r2.sh — this only (re)deploys the Worker,
# so it is needed once, and again only when worker/index.js changes.
#
# Usage: ./deploy.sh [--dry-run]
set -euo pipefail
cd "$(dirname "$0")"
case "${1:-}" in
  "") ;;
  --dry-run) npx wrangler deploy --dry-run; exit 0 ;;
  *) echo "unknown option $1" >&2; exit 2 ;;
esac
npx wrangler deploy
echo "== https://sdi.healthcampaigns.org  (catalog: https://sdi.healthcampaigns.org/catalog.json)"
