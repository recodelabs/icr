#!/usr/bin/env bash
# Refresh Uganda's warehouse (warehouse/) from the Uganda ICR server, and with --push publish it to
# the uga/ folder of the `icr` R2 bucket. See README.md.
#
#   ./warehouse.sh            refresh: locations, the IG's views (campaigns, targets, tasks…),
#                             the dashboards' Libraries (uganda_tasks…), admin tiles, Portolan catalog of the locations
#   ./warehouse.sh --push     and upload it
#
# In R2, uga/ holds the whole warehouse; the SDI (https://sdi.healthcampaigns.org/uga/) serves only
# its location collection and tiles, and the dashboards (dashboards/, observatory deploy) build from the rest.
#
# The key comes from ~/.config/icr/uga-matt.env (or $KEY_FILE). Needs fhir-pipes, duckdb,
# tippecanoe, portolan and rclone with the r2 remote, and the IG built (sushi build . in ig/).
set -euo pipefail
cd "$(dirname "$0")"
set -a; . "${KEY_FILE:-$HOME/.config/icr/uga-matt.env}"; set +a
export FHIR_PIPES_CLIENT_ID="$FHIR_CLIENT_ID" FHIR_PIPES_CLIENT_SECRET="$FHIR_CLIENT_SECRET"
export DUCKDB_AGENT_MODE=0   # keep DuckDB 2.0's agent banner out of fhir-pipes' output

# The dashboards' Libraries (SQL in dashboards/sites/uganda/analytics/) as Library JSON, which the
# libraries step runs over the view tables and location_hierarchy.
fhir-pipes libraries build ../../dashboards/sites/uganda/analytics --out ../../dashboards/sites/uganda/analytics/build
fhir-pipes refresh --config fhir-pipes.toml --only locations,views,libraries,tiles,hooks
# The catalog hook writes the collection's README; this is the root's, from warehouse/.portolan/.
(cd warehouse && portolan readme . --no-recursive >/dev/null)

if [ "${1:-}" = --push ]; then
  # fhir-pipes' own push syncs to the root of a bucket; this warehouse lives in a folder of one.
  DEST=r2:icr/uga
  for d in parquet tiles views; do
    rclone sync --checksum --exclude ".DS_Store" --exclude ".portolan/**" "warehouse/$d" "$DEST/$d"
  done
  for f in catalog.json README.md AGENTS.md versions.json manifest.json; do
    rclone copyto --checksum "warehouse/$f" "$DEST/$f"
  done
  echo "== r2:icr/uga/ (SDI: https://sdi.healthcampaigns.org/uga/)"
fi
