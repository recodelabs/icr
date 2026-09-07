#!/usr/bin/env bash
# Refresh data/ — the ICR analytics hub — from the FHIR server.
#
#   1. locations:  kiln run  (incremental extract → data/raw/<server>/locations,
#                             transform → data/parquet/locations)
#   2. views:      for every ViewDefinition in the IG build, export its base
#                  resource type (paged FHIR search → data/raw/<server>/<Type>.ndjson),
#                  run it in memory with octofhir-sof, partition the result by
#                  country (joined from the registry) into data/parquet/<view_name>/
#   3. manifest:   data/manifest.json with counts and provenance
#
# Usage: tools/warehouse/refresh.sh [--views] [--locations]     (default: both)
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

DO_LOC=1; DO_VIEWS=1
for a in "$@"; do
  case "$a" in
    --views) DO_LOC=0 ;;
    --locations) DO_VIEWS=0 ;;
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
    # Partition by country, taken from the registry (locations parquet) via location_id.
    duckdb -c "
      COPY (
        SELECT v.*, l.country
        FROM read_parquet('$tmp') v
        LEFT JOIN (SELECT id, country FROM read_parquet('$PARQUET/locations/**/*.parquet', hive_partitioning=true, union_by_name=true)) l
          ON l.id = v.location_id
      ) TO '$PARQUET/$table' (FORMAT PARQUET, PARTITION_BY (country), OVERWRITE_OR_IGNORE, FILENAME_PATTERN 'part-{i}');"
    rm -f "$tmp"
    rows=$(duckdb -noheader -csv -c "SELECT count(*) FROM read_parquet('$PARQUET/$table/**/*.parquet', hive_partitioning=true)")
    echo "   $name → parquet/$table ($rows rows)"
  done
fi

echo "== manifest"
python3 - "$DATA" "$FHIR_BASE" "$SERVER_NAME" <<'EOF'
import json, subprocess, sys, datetime, glob, os
data, base, server = sys.argv[1:]
def rows(table):
    q = f"SELECT count(*) FROM read_parquet('{data}/parquet/{table}/**/*.parquet', hive_partitioning=true, union_by_name=true)"
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
echo "done → $DATA"
