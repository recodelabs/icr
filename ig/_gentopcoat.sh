#!/usr/bin/env bash
# Build the IG website with the IG Topcoat theme:
# SUSHI → IG Publisher (output/) → IG Topcoat (output-topcoat/).
# Prereqs: ./_updatePublisher.sh once; Java 17+ (brew install openjdk),
# Jekyll on a modern Ruby (brew install ruby && gem install jekyll),
# and ~/github/ig-topcoat built (npm install && npm run build).
set -euo pipefail
cd "$(dirname "$0")"

IG_TOPCOAT="${IG_TOPCOAT:-$HOME/github/ig-topcoat}"
export PATH="$(brew --prefix openjdk)/bin:$(brew --prefix ruby)/bin:$PATH"
GEM_BIN="$(gem environment 2>/dev/null | awk -F': ' '/EXECUTABLE DIRECTORY/{print $2}')"
[ -n "$GEM_BIN" ] && export PATH="$GEM_BIN:$PATH"

./_genonce.sh "$@"
node "$IG_TOPCOAT/dist/cli.js" build -i output -o output-topcoat
echo "Topcoat site: open output-topcoat/index.html (serve over HTTP for search: cd output-topcoat && npx serve)"
