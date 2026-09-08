#!/usr/bin/env bash
# Refresh data/ — the ICR analytics hub — from the FHIR server.
#
#   1. locations:  kiln run  (incremental extract → data/raw/<server>/locations,
#                             transform → data/parquet/locations)
#   2. views:      for every ViewDefinition in the IG build, export its base
#                  resource type (paged FHIR search → data/raw/<server>/<Type>.ndjson),
#                  run it in memory with octofhir-sof, partition the result by
#                  country (joined from the registry) into data/parquet/<view_name>/
#   3. tiles:      admin boundaries → data/tiles/admin.pmtiles (tools/warehouse/tiles.sh)
#   4. manifest:   data/manifest.json with counts and provenance
#   5. push:       optional, --push: mirror data/ (minus raw/) to Cloudflare R2
#                  (tools/warehouse/push-r2.sh; bucket R2_BUCKET, default icr)
#
# Usage: tools/warehouse/refresh.sh [--views] [--locations] [--tiles] [--push]   (default: all, no push)
# Env:   FHIR_BASE (http://localhost:3447/fhir)  SERVER_NAME (hapi-local)
#        KILN (~/github/kiln/target/debug/kiln)  SOF (octofhir-sof)  DATA (repo data/)
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
DATA="${DATA:-$REPO/data}"
IG_RES="$REPO/ig/fsh-generated/resources"
FHIR_BASE="${FHIR_BASE:-http://localhost:3447/fhir}"
SERVER_NAME="${SERVER_NAME:-hapi-local}"
KILN="${KILN:-$HOME/github/kiln/target/debug/kiln}"
SOF="${SOF:-octofhir-sof}"
export PATH="$HOME/.local/bin:$PATH"

DO_LOC=1; DO_VIEWS=1; DO_TILES=1; DO_PUSH=0
for a in "$@"; do
  case "$a" in
    --views) DO_LOC=0; DO_TILES=0 ;;
    --locations) DO_VIEWS=0; DO_TILES=0 ;;
    --tiles) DO_LOC=0; DO_VIEWS=0 ;;
    --push) DO_PUSH=1 ;;
    *) echo "unknown option $a" >&2; exit 2 ;;
  esac
done

RAW="$DATA/raw/$SERVER_NAME"
PARQUET="$DATA/parquet"
VIEWS="$DATA/views"
mkdir -p "$RAW" "$PARQUET" "$VIEWS"

if [ "$DO_LOC" = 1 ]; then
  echo "== locations: kiln run ($FHIR_BASE → $RAW/locations → $PARQUET/locations)"
  "$KILN" run --server "$FHIR_BASE" --snapshot "$RAW/locations" --out "$PARQUET"
fi

if [ "$DO_VIEWS" = 1 ]; then
  echo "== views"
  ls "$IG_RES"/Binary-*.json >/dev/null 2>&1 || { echo "no IG build found in $IG_RES (run sushi build in ig/)" >&2; exit 1; }
  for f in "$IG_RES"/Binary-*.json; do
    # Only logical-model instances of the SoF ViewDefinition.
    python3 -c "import json,sys; v=json.load(open('$f')); sys.exit(0 if str(v.get('resourceType','')).endswith('/ViewDefinition') else 1)" || continue
    name=$(python3 -c "import json; print(json.load(open('$f'))['name'])")
    rtype=$(python3 -c "import json; print(json.load(open('$f'))['resource'])")
    table=$(python3 -c "import re,sys; n=sys.argv[1]; print(re.sub(r'(?<!^)(?=[A-Z])','_',n).lower().removeprefix('icr_'))" "$name")
    view_json="$VIEWS/$name.json"
    python3 -c "import json; v=json.load(open('$f')); v['resourceType']='ViewDefinition'; json.dump(v, open('$view_json','w'), indent=2)"
    "$SOF" validate "$view_json" >/dev/null

    ndjson="$RAW/$rtype.ndjson"
    if [ ! -s "$ndjson" ] || [ "${REFRESH_RAW:-1}" = 1 ]; then
      echo "   export $rtype → $ndjson"
      python3 - "$FHIR_BASE" "$rtype" "$ndjson" <<'EOF'
import json, sys, urllib.request
base, rtype, out = sys.argv[1:]
url = f"{base}/{rtype}?_count=500"
n = 0
with open(out, "w") as fh:
    while url:
        b = json.load(urllib.request.urlopen(url))
        for e in b.get("entry", []):
            fh.write(json.dumps(e["resource"]) + "\n"); n += 1
        url = next((l["url"] for l in b.get("link", []) if l["relation"] == "next"), None)
print(f"      {n} {rtype}")
EOF
    fi

    tmp="$(mktemp -t "$table.XXXX").parquet"
    "$SOF" run "$view_json" --input "$ndjson" --output parquet --parquet-temporal native --out "$tmp"
    rm -rf "$PARQUET/$table"; mkdir -p "$PARQUET/$table"
    # Partition by country: from the registry via location_id when the view has one,
    # else via campaign_id through the campaign calendar table, else unpartitioned.
    cols=$(duckdb -noheader -csv -c "SELECT string_agg(column_name, ',') FROM (DESCRIBE SELECT * FROM read_parquet('$tmp'))" | tr -d '"')
    if [[ ",$cols," == *",location_id,"* ]]; then
      country_join="LEFT JOIN (SELECT id AS _k, country FROM read_parquet('$PARQUET/locations/country=*/**/*.parquet', hive_partitioning=true, union_by_name=true)) l ON l._k = v.location_id"
    elif [[ ",$cols," == *",campaign_id,"* ]] && [ -d "$PARQUET/campaign_calendar" ]; then
      country_join="LEFT JOIN (SELECT campaign_id AS _k, any_value(country) AS country FROM read_parquet('$PARQUET/campaign_calendar/**/*.parquet', hive_partitioning=true, union_by_name=true) GROUP BY 1) l ON l._k = v.campaign_id"
    else
      country_join="LEFT JOIN (SELECT NULL AS _k, NULL::VARCHAR AS country) l ON FALSE"
    fi
    duckdb -c "
      COPY (
        SELECT v.*, l.country FROM read_parquet('$tmp') v $country_join
      ) TO '$PARQUET/$table' (FORMAT PARQUET, PARTITION_BY (country), WRITE_PARTITION_COLUMNS TRUE, OVERWRITE_OR_IGNORE, FILENAME_PATTERN 'part-{i}');"
    rm -f "$tmp"
    rows=$(duckdb -noheader -csv -c "SELECT count(*) FROM read_parquet('$PARQUET/$table/country=*/**/*.parquet', hive_partitioning=true)")
    echo "   $name → parquet/$table ($rows rows)"
  done
fi

if [ "$DO_TILES" = 1 ]; then
  DATA="$DATA" "$HERE/tiles.sh"
fi

echo "== manifest"
python3 - "$DATA" "$FHIR_BASE" "$SERVER_NAME" <<'EOF'
import json, subprocess, sys, datetime, glob, os
data, base, server = sys.argv[1:]
def rows(table):
    # country=*/ keeps the Portolan metadata beside the data (items.parquet) out of the table
    q = f"SELECT count(*) FROM read_parquet('{data}/parquet/{table}/country=*/**/*.parquet', hive_partitioning=true, union_by_name=true)"
    return int(subprocess.check_output(["duckdb", "-noheader", "-csv", "-c", q]).decode().strip())
tables = sorted(d for d in os.listdir(f"{data}/parquet") if os.path.isdir(f"{data}/parquet/{d}"))
views = {}
for f in glob.glob(f"{data}/views/*.json"):
    v = json.load(open(f)); views[v["name"]] = {"url": v.get("url"), "resource": v.get("resource"), "status": v.get("status")}
state = {}
try: state = json.load(open(f"{data}/raw/{server}/locations/state.json"))
except FileNotFoundError: pass
m = {"refreshed_at": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
     "server": base, "server_name": server,
     "tables": {t: {"rows": rows(t)} for t in tables},
     "views": views,
     "kiln": {k: state.get(k) for k in ("kiln_version", "watermark", "count", "organization_count", "completed_at")}}
json.dump(m, open(f"{data}/manifest.json", "w"), indent=2)
print(json.dumps(m["tables"]))
EOF

# Portolan catalog (data/ is the catalog root, published at https://sdi.healthcampaigns.org
# by tools/sdi/). `add` writes the STAC metadata beside the parquet — collection.json, one
# item per hive partition, items.parquet, README/AGENTS.md — and leaves kiln's files alone.
# The snapshot time is the collection's datetime. The SDI is the location registry only —
# the view tables are ICR-internal and stay out of the catalog (see data/README.md).
if [ "$DO_LOC" = 1 ] && command -v portolan >/dev/null; then
  echo "== portolan catalog"
  refreshed=$(python3 -c "import json; print(json.load(open('$DATA/manifest.json'))['refreshed_at'])")
  # kiln swaps in a fresh locations/ directory on every run, so the collection's
  # human-written metadata is kept under .portolan/collections/ and copied in first.
  mkdir -p "$PARQUET/locations/.portolan"
  cp "$DATA/.portolan/collections/locations/metadata.yaml" "$PARQUET/locations/.portolan/metadata.yaml"
  # Always build from a clean slate: re-adding over existing items loses their `collection` field
  # (portolan-cli 0.8), and a --locations run without a kiln change would otherwise hit that path.
  find "$PARQUET/locations" -type f \( -name '*.json' -o -name '*.md' -o -name 'items.parquet' \) -delete
  rm -rf "$PARQUET/locations/styles"
  (cd "$DATA" && portolan add parquet/locations/ --no-thumbnails --datetime "$refreshed" \
    && python3 "$HERE/sdi-collection.py" "$DATA" \
    && portolan stac-geoparquet -c parquet/locations >/dev/null \
    && portolan readme parquet/locations --no-recursive >/dev/null \
    && portolan check --fix --data-scope local) || echo "   portolan: catalog not conformant (see above)" >&2
fi
echo "done → $DATA"

if [ "$DO_PUSH" = 1 ]; then
  DATA="$DATA" "$HERE/push-r2.sh"
fi
