# Build the files for the online Bangladesh ICR server from the local server's snapshot
# (raw/bd-local in the offline warehouse): the country, divisions, districts and upazilas (and any other place
# that has values), with every indicator, the campaign and every value. Lower places (unions,
# wards, sub-blocks, schools, session sites) stay offline.
#
#   python3 -I export.py OFFLINE_WAREHOUSE [OUT]
#
# OFFLINE_WAREHOUSE is the offline warehouse folder (it holds raw/bd-local and parquet/); OUT is
# where the NDJSON files go (default: fhir/ beside this script). Prints the counts.
import json, os, subprocess, sys

if len(sys.argv) < 2: sys.exit(__doc__ or "usage: export.py OFFLINE_WAREHOUSE [OUT]")
HERE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(sys.argv[1], "raw", "bd-local")
PARQUET = os.path.join(sys.argv[1], "parquet")
OUT = sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, "fhir")
os.makedirs(OUT, exist_ok=True)

# Places to keep: admin levels 0-3 from the warehouse's locations table.
sql = f"""copy (select id from read_parquet('{PARQUET}/locations/**/*.parquet', union_by_name=true)
          where id like 'bgd-%' and admin_level between 0 and 3) to '/dev/stdout' (format csv, header false)"""
keep = set(subprocess.run([os.path.expanduser("~/.local/bin/duckdb"), "-no-agent", "-c", sql],
                          check=True, capture_output=True, text=True).stdout.split())

def strip(resource):
    """Drop the local server's version and timestamp; the new server sets its own."""
    meta = resource.get("meta", {})
    meta.pop("versionId", None); meta.pop("lastUpdated", None); meta.pop("source", None)
    return resource

# Values: all of them; note which places they are about.
subjects, reports = set(), 0
with open(os.path.join(RAW, "MeasureReport.ndjson")) as src, open(os.path.join(OUT, "MeasureReport.ndjson"), "w") as out:
    for line in src:
        r = strip(json.loads(line))
        subjects.add(r["subject"]["reference"].split("/")[-1])
        out.write(json.dumps(r, separators=(",", ":"), ensure_ascii=False) + "\n"); reports += 1
keep |= subjects

places, orgs_needed, dropped_parent = 0, set(), 0
with open(os.path.join(RAW, "locations", "locations.ndjson")) as src, open(os.path.join(OUT, "Location.ndjson"), "w") as out:
    for line in src:
        if '"id":"' not in line: continue
        r = json.loads(line)
        if r["id"] not in keep: continue
        r = strip(r)
        parent = r.get("partOf", {}).get("reference", "").split("/")[-1]
        if parent and parent not in keep:   # a place with values whose parent is not kept
            dropped_parent += 1; del r["partOf"]
        org = r.get("managingOrganization", {}).get("reference", "")
        if org: orgs_needed.add(org.split("/")[-1])
        out.write(json.dumps(r, separators=(",", ":"), ensure_ascii=False) + "\n"); places += 1

orgs = 0
with open(os.path.join(RAW, "locations", "organizations.ndjson")) as src, open(os.path.join(OUT, "Organization.ndjson"), "w") as out:
    for line in src:
        r = json.loads(line)
        if r["id"] in orgs_needed:
            out.write(json.dumps(strip(r), separators=(",", ":"), ensure_ascii=False) + "\n"); orgs += 1

small = {}
for name in ("Measure", "CarePlan", "Group"):
    with open(os.path.join(RAW, f"{name}.ndjson")) as src, open(os.path.join(OUT, f"{name}.ndjson"), "w") as out:
        n = 0
        for line in src:
            out.write(json.dumps(strip(json.loads(line)), separators=(",", ":"), ensure_ascii=False) + "\n"); n += 1
        small[name] = n

print(json.dumps({"Location": places, "places_with_values": len(subjects), "missing_places": len(subjects - keep),
                  "partOf_removed": dropped_parent, "Organization": orgs, "orgs_referenced": len(orgs_needed),
                  "MeasureReport": reports, **small}, indent=1))
