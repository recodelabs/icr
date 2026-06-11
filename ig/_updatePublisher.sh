#!/usr/bin/env bash
# Download the latest HL7 IG Publisher jar into input-cache/.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p input-cache
echo "Downloading latest IG Publisher…"
curl -L https://github.com/HL7/fhir-ig-publisher/releases/latest/download/publisher.jar -o input-cache/publisher.jar
echo "Done: input-cache/publisher.jar"
