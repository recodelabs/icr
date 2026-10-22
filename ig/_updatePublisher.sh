#!/usr/bin/env bash
# Download the HL7 IG Publisher jar into input-cache/.
#
# Pinned to 2.3.4, the last release that builds this IG: 3.0.0 and 3.0.1 stop on the ESPEN
# drug-receipt Questionnaire, whose contained SupplyDelivery extraction templates they can't
# convert ("The resource SupplyDelivery cannot be converted from R4 to RN"). Override with
# PUBLISHER_VERSION=latest (or another release tag) to try a newer one.
set -euo pipefail
cd "$(dirname "$0")"
VERSION="${PUBLISHER_VERSION:-2.3.4}"
mkdir -p input-cache
if [ "$VERSION" = latest ]; then
  url=https://github.com/HL7/fhir-ig-publisher/releases/latest/download/publisher.jar
else
  url="https://github.com/HL7/fhir-ig-publisher/releases/download/$VERSION/publisher.jar"
fi
echo "Downloading IG Publisher $VERSION…"
curl -fL "$url" -o input-cache/publisher.jar
echo "Done: input-cache/publisher.jar"
