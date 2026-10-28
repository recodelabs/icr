# Shared by the data loaders in src/data/: where the warehouse is, and how to read a table.
# Sourced, not run. It sits outside src/ so Framework does not treat it as a page or a loader.
#
# The warehouse is a copy pulled from R2 digit/ by observatory (DATA), or country/digit/warehouse
# when a loader runs on its own. Its tables are not partitioned (see country/digit/fhir-pipes.toml).
DATA="${DATA:-$(cd "$(dirname "$0")/../../../../../country/digit/warehouse" && pwd)}"
W="$DATA/parquet"
export DUCKDB_AGENT_MODE=0

# IST_DAY <expr>: the calendar day of a timestamp in India Standard Time, the DIGIT demo server's
# time zone (a campaign that starts on 28 October has period.start 2026-10-27T18:30:00Z).
IST_DAY() { echo "CAST(timezone('Asia/Kolkata', CAST($1 AS TIMESTAMPTZ)) AS DATE)"; }

# T <table> <columns>: SQL that reads a view table, or, while the bulk load has not yet written
# any rows for it, an empty table with the given columns ("name TYPE, …"), so pages still build.
T() {
  if compgen -G "$W/$1/*.parquet" >/dev/null || compgen -G "$W/$1/**/*.parquet" >/dev/null; then
    echo "(SELECT * FROM read_parquet('$W/$1/**/*.parquet', union_by_name=true))"
  else
    local cols="" c
    IFS=',' read -ra parts <<< "$2"
    for c in "${parts[@]}"; do
      c="${c# }"
      cols+="${cols:+, }NULL::${c#* } AS ${c%% *}"
    done
    echo "(SELECT $cols WHERE false)"
  fi
}
