#!/usr/bin/env bash
# Run a Framework site's in-browser DuckDB on the DuckDB 2.0 engine.
#
# Framework 1.13.4 pins DuckDB-Wasm 1.29.0 (the DuckDB 1.1.1 engine) and loads its
# "mvp"/"eh" builds. DuckDB-Wasm for DuckDB 2.0 is not on npm yet, so this takes the
# package its CI built from the v2.0.0 release and puts it where Framework looks:
#
#   1. src/.observablehq/cache/_npm/@duckdb/duckdb-wasm@1.29.0/  the 2.0 module, worker
#      and engine, under the folder name Framework expects.
#   2. node_modules/@observablehq/framework/dist/client/stdlib/duckdb.js  ask for the
#      new "base" build (2.0 renamed mvp/eh to base/threads), and dist/libraries.js
#      so that `observable build` copies the base files instead of the mvp/eh ones.
#
# Each site's observablehq.config.js also sets duckdb.extensions json and parquet to
# null: 2.0 has both built in, and Framework would otherwise bundle the 1.1.1 ones.
#
# Framework puts a content hash in the worker's file name but not the engine's, and the
# Worker tells browsers to keep _npm/ files for a year. So the engine is copied in as
# duckdb-base.<first 8 hex of its sha256>.wasm: a different build gets a new name, and
# browsers fetch it instead of keeping the old one.
#
# npm install and `npm run clean` undo this, so deploy.sh runs it before each build.
# Safe to run again. Drop it once DuckDB-Wasm 2.0 is on npm and Framework can use it.
#
# Usage: ./duckdb-wasm2.sh SITE_DIR...      (e.g. . sldash sl-redux)
# Env:   DUCKDB_WASM2_DIR  where the package is kept (default ~/.cache/duckdb-wasm2)
set -euo pipefail

# duckdb/duckdb-wasm CI run on commit 5beed055bc, DuckDB submodule d54cbbe3df (v2.0.0).
RUN=39574007535
STORE="${DUCKDB_WASM2_DIR:-$HOME/.cache/duckdb-wasm2}/d54cbbe3df"
SUMS="be806078a159f7c196ff5065d787c2f558f07e3ad727b21c7aa2b7329e8c50d7  duckdb-base.wasm
8a8f73e2860daa0b1b7d4df0a2a017fef33e694249a6634636553478e630f9d5  duckdb-browser-base.worker.js
35f33368cb6018c1e6ede36273f5fec39e5c86e4976599decda845d5af2d19f5  duckdb-browser.mjs"
ENGINE="duckdb-base.$(echo "$SUMS" | awk '$2 == "duckdb-base.wasm" {print substr($1, 1, 8)}').wasm"

[ $# -gt 0 ] || { echo "usage: $0 SITE_DIR..." >&2; exit 2; }

if ! (cd "$STORE" 2>/dev/null && echo "$SUMS" | shasum -a 256 -c --status); then
  echo "== downloading DuckDB-Wasm 2.0 (CI run $RUN) to $STORE"
  tmp=$(mktemp -d)
  gh run download "$RUN" -R duckdb/duckdb-wasm -n duckdb-wasm-packages -D "$tmp"
  unzip -q "$tmp/duckdb-wasm-packages.zip" 'packages/duckdb-wasm/dist/duckdb-browser.mjs' \
    'packages/duckdb-wasm/dist/duckdb-base.wasm' 'packages/duckdb-wasm/dist/duckdb-browser-base.worker.js' -d "$tmp"
  mkdir -p "$STORE"
  cp "$tmp"/packages/duckdb-wasm/dist/* "$STORE"/
  rm -rf "$tmp"
  (cd "$STORE" && echo "$SUMS" | shasum -a 256 -c --quiet) || { echo "checksum mismatch in $STORE" >&2; exit 1; }
fi

for site in "$@"; do
  npm="$site/src/.observablehq/cache/_npm"
  cache="$npm/@duckdb/duckdb-wasm@1.29.0"
  client="$site/node_modules/@observablehq/framework/dist/client/stdlib/duckdb.js"
  libraries="$site/node_modules/@observablehq/framework/dist/libraries.js"
  [ -f "$client" ] || { echo "$site: no Framework in node_modules; run npm install" >&2; exit 1; }
  # Framework fills its npm cache the first time a page needs DuckDB.
  arrow=$(cd "$npm" 2>/dev/null && ls -d apache-arrow@* 2>/dev/null | sort -V | tail -1 || true)
  if [ ! -d "$cache" ] || [ -z "$arrow" ]; then
    echo "$site: Framework has not cached DuckDB-Wasm yet; open a page that uses sql in 'npm run dev' (or run 'npm run build') once, then run this again" >&2
    exit 1
  fi

  rm -f "$cache"/dist/duckdb-mvp.wasm "$cache"/dist/duckdb-eh.wasm "$cache"/dist/duckdb-base*.wasm \
    "$cache"/dist/duckdb-browser-mvp.worker.js "$cache"/dist/duckdb-browser-eh.worker.js
  mkdir -p "$cache/dist"
  cp "$STORE/duckdb-base.wasm" "$cache/dist/$ENGINE"
  cp "$STORE/duckdb-browser-base.worker.js" "$cache/dist/"
  { echo "/* DuckDB-Wasm for DuckDB 2.0.0 (d54cbbe3df), duckdb/duckdb-wasm CI run $RUN; see campaignhq/duckdb-wasm2.sh */"
    sed -e "s#from\"apache-arrow\"#from\"../../$arrow/_esm.js\"#g" -e '/^\/\/# sourceMappingURL/d' "$STORE/duckdb-browser.mjs"
  } > "$cache/_esm.js"

  python3 -I - "$client" "$libraries" "$ENGINE" <<'EOF'
import re, sys
client, libraries, engine = sys.argv[1:]
s = open(client).read()
start, end = s.index("const bundles = {"), s.index("const bundle = duckdb.selectBundle(bundles);")
s = s[:start] + '''const bundles = {
  base: {
    mainModule: import.meta.resolve("npm:@duckdb/duckdb-wasm/dist/''' + engine + '''"),
    mainWorker: import.meta.resolve("npm:@duckdb/duckdb-wasm/dist/duckdb-browser-base.worker.js")
  }
};
''' + s[end:]
open(client, "w").write(s)
s = open(libraries).read()
old = re.compile(r'(\s*)implicits\.add\("npm:@duckdb/duckdb-wasm/dist/duckdb-mvp\.wasm"\);\s*'
                 r'implicits\.add\("npm:@duckdb/duckdb-wasm/dist/duckdb-browser-mvp\.worker\.js"\);\s*'
                 r'implicits\.add\("npm:@duckdb/duckdb-wasm/dist/duckdb-eh\.wasm"\);\s*'
                 r'implicits\.add\("npm:@duckdb/duckdb-wasm/dist/duckdb-browser-eh\.worker\.js"\);')
base = re.compile(r'npm:@duckdb/duckdb-wasm/dist/duckdb-base(\.[0-9a-f]{8})?\.wasm')
if old.search(s):
    s = old.sub(lambda m: m.group(1) + f'implicits.add("npm:@duckdb/duckdb-wasm/dist/{engine}");'
                + m.group(1) + 'implicits.add("npm:@duckdb/duckdb-wasm/dist/duckdb-browser-base.worker.js");', s, count=1)
elif base.search(s):
    s = base.sub(f"npm:@duckdb/duckdb-wasm/dist/{engine}", s, count=1)
else:
    sys.exit(f"{libraries}: DuckDB file list not found; Framework changed?")
open(libraries, "w").write(s)
EOF
  echo "== $site: DuckDB-Wasm 2.0, $ENGINE (arrow from $arrow)"
done
