#!/usr/bin/env bash
# Build the IG website with the redesigned ig-fresh theme:
# SUSHI → IG Publisher (output/) → ig-fresh (output-fresh/).
# Prereqs: ./_updatePublisher.sh once; Java 17+ (brew install openjdk),
# Jekyll on a modern Ruby (brew install ruby && gem install jekyll),
# and ~/github/ig-fresh built (npm install && npm run build).
set -euo pipefail
cd "$(dirname "$0")"

IG_FRESH="${IG_FRESH:-$HOME/github/ig-fresh}"
export PATH="$(brew --prefix openjdk)/bin:$(brew --prefix ruby)/bin:$PATH"
GEM_BIN="$(gem environment 2>/dev/null | awk -F': ' '/EXECUTABLE DIRECTORY/{print $2}')"
[ -n "$GEM_BIN" ] && export PATH="$GEM_BIN:$PATH"

./_genonce.sh "$@"
node "$IG_FRESH/dist/cli.js" build -i output -o output-fresh
echo "Fresh site: open output-fresh/index.html (serve over HTTP for search: cd output-fresh && npx serve)"
