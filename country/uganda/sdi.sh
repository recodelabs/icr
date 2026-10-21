#!/usr/bin/env bash
# Refresh Uganda's SDI catalog (sdi/) from the Uganda ICR server, and with --push publish it
# at https://sdi.healthcampaigns.org/uga/ (the uga/ folder of the `icr` R2 bucket, served by
# tools/sdi). See README.md.
#
#   ./sdi.sh            refresh: locations → sdi/parquet, admin tiles, Portolan catalog
#   ./sdi.sh --push     and upload it
#
# The key comes from ~/.config/icr/uga-matt.env (or $KEY_FILE). Needs fhir-pipes, duckdb,
# tippecanoe, portolan and rclone with the r2 remote.
set -euo pipefail
cd "$(dirname "$0")"
set -a; . "${KEY_FILE:-$HOME/.config/icr/uga-matt.env}"; set +a
export FHIR_PIPES_CLIENT_ID="$FHIR_CLIENT_ID" FHIR_PIPES_CLIENT_SECRET="$FHIR_CLIENT_SECRET"
export DUCKDB_AGENT_MODE=0   # keep DuckDB 2.0's agent banner out of fhir-pipes' output

fhir-pipes refresh --config fhir-pipes.toml --only locations,tiles,hooks
# The catalog hook writes the collection's README; this is the root's, from sdi/.portolan/.
(cd sdi && portolan readme . --no-recursive >/dev/null)

if [ "${1:-}" = --push ]; then
  # fhir-pipes' own push syncs to the root of a bucket; this catalog lives in a folder of one.
  DEST=r2:icr/uga
  for d in parquet tiles; do
    rclone sync --checksum --exclude ".DS_Store" --exclude ".portolan/**" "sdi/$d" "$DEST/$d"
  done
  for f in catalog.json README.md AGENTS.md versions.json manifest.json; do
    rclone copyto --checksum "sdi/$f" "$DEST/$f"
  done
  echo "== https://sdi.healthcampaigns.org/uga/"
fi
