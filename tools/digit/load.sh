#!/usr/bin/env bash
# Load the DIGIT → ICR output into the digit hfs server through the gateway, referenced types first.
set -uo pipefail
export PATH="/opt/homebrew/opt/node@22/bin:$PATH"
set -a; . ~/.config/icr/digit-loader.env; set +a
export FHIR_PIPES_CLIENT_ID=$FHIR_CLIENT_ID FHIR_PIPES_CLIENT_SECRET=$FHIR_CLIENT_SECRET
cd "${DIGIT_WORK:-work}/out"
for t in ${TYPES:-Location Patient Group Task MedicationAdministration SupplyDelivery}; do
  echo "== $t $(wc -l < $t.ndjson) $(date +%H:%M:%S)"
  fhir-pipes load --server https://fhir-digit.healthcampaigns.org/fhir --token-url "$FHIR_TOKEN_URL" \
    --in $t.ndjson --batch-size 200 --concurrency 3 --retries 5 --timeout 300 2>&1 | tail -3
done
echo "== done $(date +%H:%M:%S)"
