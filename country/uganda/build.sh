#!/usr/bin/env bash
# Build Uganda's admin units (country, regions, districts and cities) as FHIR Locations, and
# with --load send them to the Uganda ICR server. See README.md.
#
#   ./build.sh            fetch Overture, build, check; writes build/locations-enriched.ndjson
#   ./build.sh --load     also load it, with the key in ~/.config/icr/uga-matt.env (or $KEY_FILE)
#
# Needs duckdb (2.0), fhir-pipes (0.6.0), uv, and the COD-AB zip in this folder.
set -euo pipefail
cd "$(dirname "$0")"
RELEASE=2026-10-21.0
FHIR_PIPES=${FHIR_PIPES:-fhir-pipes}
PROFILE=../../ig/fhir-pipes-profile.toml   # the ICR profile, kept with the IG
mkdir -p build overture cod

# 1. Overture divisions for Uganda (about 10 seconds; kept until the release changes).
if [ ! -f "overture/$RELEASE" ]; then
  echo "== Overture $RELEASE"
  duckdb -no-agent -c "
    INSTALL httpfs; LOAD httpfs; SET s3_region = 'us-west-2';
    COPY (SELECT * FROM read_parquet('s3://overturemaps-us-west-2/release/$RELEASE/theme=divisions/type=division/*.parquet', hive_partitioning = false)
          WHERE country = 'UG') TO 'overture/ug_division.parquet';
    COPY (SELECT * FROM read_parquet('s3://overturemaps-us-west-2/release/$RELEASE/theme=divisions/type=division_area/*.parquet', hive_partitioning = false)
          WHERE country = 'UG') TO 'overture/ug_division_area.parquet';"
  rm -f overture/20*; touch "overture/$RELEASE"
fi

# 2. COD-AB districts and counties (2020), for P-codes and Lira Municipality.
[ -f cod/uga_admin3.geojson ] || unzip -q -o uga_admin_boundaries.geojson.zip uga_admin2.geojson uga_admin3.geojson -d cod

# 3. The ministry's district names, from the targets workbook.
uv run -q --no-project --with openpyxl python3 -I - "Oct 2026_ICHDs_EPI Targets.xlsx" targets-names.csv <<'EOF'
import csv, sys, openpyxl
ws = openpyxl.load_workbook(sys.argv[1], data_only=True)["Target_refined"]
with open(sys.argv[2], "w", newline="") as f:
    w = csv.writer(f); w.writerow(["sheet_name"])
    for r in ws.iter_rows(min_row=3, values_only=True):
        if r[0] and not str(r[0]).strip().startswith("National"): w.writerow([r[0]])
EOF

# 4. One GeoJSON feature per district or city, with the checks printed.
echo "== districts.sql"
rm -f build/districts.geojson
duckdb -no-agent -csv -c ".read districts.sql" | tee build/districts-checks.txt

# 5. fhir-pipes builds the Locations; enrich.py adds identifiers and sources.
"$FHIR_PIPES" import location-boundaries --profile "$PROFILE" --in build/districts.geojson \
  --country Uganda=UGA --level region=region:region_code --level district=district \
  --alias district=district_aliases --dissolve-parents --out build/locations.ndjson --report build/import-report.json
uv run -q --no-project --with duckdb python3 -I enrich.py build/districts.geojson overture/ug_division.parquet \
  build/locations.ndjson build/locations-enriched.ndjson

# 6. Load.
if [ "${1:-}" = --load ]; then
  set -a; . "${KEY_FILE:-$HOME/.config/icr/uga-matt.env}"; set +a
  "$FHIR_PIPES" load --server "$FHIR_BASE" --client-id "$FHIR_CLIENT_ID" --client-secret "$FHIR_CLIENT_SECRET" \
    --token-url "$FHIR_TOKEN_URL" --in build/locations-enriched.ndjson --batch-size 25
fi
