#!/usr/bin/env bash
# Provenance of the data hub build (refresh time, server, counts).
set -euo pipefail
DATA="$(cd "$(dirname "$0")/../../../data" && pwd)"
cat "$DATA/manifest.json"
