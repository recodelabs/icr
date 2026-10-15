#!/usr/bin/env bash
# Rebuild the Portolan catalog of the location registry: data/ is the catalog root,
# published at https://sdi.healthcampaigns.org by tools/sdi/. `add` writes the STAC metadata
# beside the parquet (collection.json, one item per hive partition, items.parquet,
# README/AGENTS.md) and leaves fhir-pipes' files alone. The SDI is the location registry only;
# the view tables are ICR-internal and stay out of the catalog (see data/README.md).
#
# Run by fhir-pipes refresh as the `catalog` hook after a locations refresh, with DATA and
# REFRESHED_AT (the manifest's refreshed_at, the collection's datetime) set.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DATA="${DATA:-$(cd "$HERE/../.." && pwd)/data}"
PARQUET="$DATA/parquet"
REFRESHED_AT="${REFRESHED_AT:-$(python3 -c "import json; print(json.load(open('$DATA/manifest.json'))['refreshed_at'])")}"

if ! command -v portolan >/dev/null; then
  echo "   portolan not installed: catalog not rebuilt" >&2
  exit 0
fi

# fhir-pipes swaps in a fresh locations/ directory on every run, so the collection's
# human-written metadata is kept under .portolan/collections/ and copied in first.
mkdir -p "$PARQUET/locations/.portolan"
cp "$DATA/.portolan/collections/locations/metadata.yaml" "$PARQUET/locations/.portolan/metadata.yaml"
# `check --metadata` validates the catalog only: without it `--fix` also converts every loose
# GeoJSON/CSV under data/ (imports/, exports/) into parquet + thumbnails beside the originals.
# Always build from a clean slate: re-adding over existing items loses their `collection` field
# (portolan-cli 0.8), and a --locations run without a location change would otherwise hit that path.
find "$PARQUET/locations" -type f \( -name '*.json' -o -name '*.md' -o -name 'items.parquet' \) -delete
rm -rf "$PARQUET/locations/styles"
(cd "$DATA" && portolan add parquet/locations/ --no-thumbnails --datetime "$REFRESHED_AT" \
  && python3 "$HERE/sdi-collection.py" "$DATA" \
  && portolan stac-geoparquet -c parquet/locations >/dev/null \
  && portolan readme parquet/locations --no-recursive >/dev/null \
  && portolan check --fix --metadata --data-scope local) || echo "   portolan: catalog not conformant (see above)" >&2
