#!/usr/bin/env bash
# Export the tagged campaign set from a FHIR server and flatten it with the
# ICR campaign-calendar ViewDefinition into a typed parquet file.
#
#   FHIR server ──(search by tag, paged)──▶ NDJSON ──(octofhir-sof, in memory)──▶ parquet
#
# Nothing here is server-specific: the search is standard FHIR; a bulk $export
# would do the same job on a server that supports it. The runner is
# octofhir-sof (https://github.com/recodelabs/sof fork, `--parquet-temporal
# native` writes real dates). DuckDB then joins the parquet to the location
# registry parquet from kiln.
#
# Usage:  ./export.sh [OUT_DIR]        (env: FHIR_BASE, TAG, VIEW, SOF)
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${1:-$HERE/out}"
FHIR_BASE="${FHIR_BASE:-http://localhost:3447/fhir}"
TAG="${TAG:-https://icr.healthcampaigns.org/CodeSystem/icr-project-tag-cs|nga-demo}"
VIEW="${VIEW:-$HERE/../../ig/fsh-generated/resources/Binary-IcrCampaignCalendar.json}"
SOF="${SOF:-octofhir-sof}"

mkdir -p "$OUT"
NDJSON="$OUT/export-careplans.ndjson"
PARQUET="$OUT/campaign-calendar.parquet"

echo "1/3 export CarePlan?_tag=$TAG from $FHIR_BASE"
python3 - "$FHIR_BASE" "$TAG" "$NDJSON" <<'EOF'
import json, sys, urllib.parse, urllib.request
base, tag, out = sys.argv[1:]
url = f"{base}/CarePlan?_tag={urllib.parse.quote(tag, safe='|:/')}&_count=500"
n = 0
with open(out, "w") as fh:
    while url:
        bundle = json.load(urllib.request.urlopen(url))
        for e in bundle.get("entry", []):
            fh.write(json.dumps(e["resource"]) + "\n"); n += 1
        url = next((l["url"] for l in bundle.get("link", []) if l["relation"] == "next"), None)
print(f"    {n} CarePlans -> {out}")
EOF

echo "2/3 run ViewDefinition $(basename "$VIEW") with $SOF"
# sushi/IG-publisher write logical-model instances with the model's canonical as
# resourceType; runners expect the plain "ViewDefinition". Normalise into OUT.
VIEW_JSON="$OUT/$(basename "${VIEW%.json}" | sed 's/^Binary-//').view.json"
python3 - "$VIEW" "$VIEW_JSON" <<'EOF2'
import json, sys
v = json.load(open(sys.argv[1])); v["resourceType"] = "ViewDefinition"
json.dump(v, open(sys.argv[2], "w"), indent=2)
EOF2
"$SOF" validate "$VIEW_JSON" >/dev/null
"$SOF" run "$VIEW_JSON" --input "$NDJSON" --output parquet --parquet-temporal native --out "$PARQUET"
echo "    -> $PARQUET"

echo "3/3 summary (duckdb)"
if command -v duckdb >/dev/null; then
  duckdb -c "
    SELECT status, count(*) AS campaigns, min(period_start) AS first_start, max(period_end) AS last_end
    FROM '$PARQUET' GROUP BY 1 ORDER BY 1;
    DESCRIBE SELECT period_start, period_end, round FROM '$PARQUET';"
else
  echo "    duckdb not installed; skipped"
fi
