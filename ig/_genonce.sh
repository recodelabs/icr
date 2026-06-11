#!/usr/bin/env bash
# Build the IG website once: SUSHI (FSH → FHIR JSON) then the HL7 IG Publisher.
# Prereqs: node + `npm i -g fsh-sushi`, Java 17+, Jekyll. Run ./_updatePublisher.sh first.
set -euo pipefail
cd "$(dirname "$0")"
PUBLISHER_JAR=input-cache/publisher.jar
if [ ! -f "$PUBLISHER_JAR" ]; then
  echo "No $PUBLISHER_JAR — run ./_updatePublisher.sh first." >&2
  exit 1
fi
sushi build .
java -jar "$PUBLISHER_JAR" -ig . "$@"
echo "Built: open output/index.html"
