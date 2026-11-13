#!/usr/bin/env bash
# Fill build/ (mounted at /config in the serve container) with what serve reads besides its
# warehouse: fhir-pipes.toml, the ICR profile, the ViewDefinitions and the Libraries as JSON.
# Run on a machine with this repo and fhir-pipes, before deploying (see README.md).
#
#   tools/hapi/gcp/data/bundle.sh
#
# The ViewDefinitions come from $VIEWS: by default the IG's (ig/fsh-generated/resources, after
# `sushi build .` in ig/), else data/views (the ones the main warehouse last ran).
set -euo pipefail
cd "$(dirname "$0")"
ROOT=../../../..
FHIR_PIPES=${FHIR_PIPES:-fhir-pipes}

rm -rf build && mkdir -p build/views
cp fhir-pipes.toml build/
cp "$ROOT/ig/fhir-pipes-profile.toml" build/

if [ -n "${VIEWS:-}" ]; then
  cp "$VIEWS"/*Icr*.json build/views/
elif [ -f "$ROOT/ig/fsh-generated/resources/Binary-IcrCampaignTaskOutput.json" ]; then
  cp "$ROOT"/ig/fsh-generated/resources/Binary-Icr*.json build/views/
else
  echo "note: the IG build has no IcrCampaignTaskOutput; using data/views" >&2
  cp "$ROOT"/data/views/Icr*.json build/views/
fi

"$FHIR_PIPES" libraries build libraries --out build/libraries

# Every Library's ViewDefinition must be there, or serve stops at startup.
for t in libraries/*.toml; do
  view=$(grep -o 'ViewDefinition/[A-Za-z]*' "$t" || true)
  [ -z "$view" ] && continue
  grep -lq "\"url\": *\"[^\"]*$view\"" build/views/*.json || { echo "no $view in build/views" >&2; exit 1; }
done
echo "== build/: $(ls build/views | wc -l | tr -d ' ') views, $(ls build/libraries | wc -l | tr -d ' ') libraries"
