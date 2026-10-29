#!/usr/bin/env python3
# Give DIGIT's Nigerian admin units the GRID3 boundaries the ICR already holds. DIGIT's boundary
# service has no geometry, but its ADMIN (STATE → LGA) and NIGERIA (PROVINCE → DISTRICT)
# hierarchies are Nigeria's states and LGAs, which the ICR's location registry has from GRID3
# with polygons and P-codes. Units are matched by name: states first, then LGAs within the
# matched state (exact, then a known alias, then a GRID3 compound name, then a close spelling).
# A matched Location keeps its DIGIT id and codes and gains the GRID3 boundary
# (location-boundary-geojson), the P-code, an identifier for the ICR Location, and GRID3's
# spelling as an alias.
#
#   python3 enrich_grid3.py --grid3 GRID3_ADMIN_PARQUET_GLOB [--out DIR]
#
# Reads DIR/../raw/boundary_tree.ndjson and DIR/Location.ndjson; rewrites the matched Locations
# in DIR/Location.ndjson and also writes them alone, with a crosswalk, to DIR/../grid3/
# (Location-grid3.ndjson, to load just those; grid3-crosswalk.csv). Run it after every transform. Needs the duckdb CLI on PATH.
import argparse, base64, csv, difflib, json, os, re, subprocess, sys

BASE = "https://icr.healthcampaigns.org"
GEO_EXT = f"{BASE}/StructureDefinition/location-boundary-geojson"
PCODE = f"{BASE}/identifiers/pcode"
ICR_LOC = f"{BASE}/identifiers/icr-location"
PAIRS = (("ADMIN", "STATE", "LGA"), ("NIGERIA", "PROVINCE", "DISTRICT"))
ALIASES = {"dankowasagu": "wasagudanko"}  # DIGIT name → GRID3 name, where the words are reversed

norm = lambda s: re.sub(r"[^a-z0-9]", "", s.lower())

def label(code):
    # the part of a DIGIT code after its last run of numeric segments: ADMIN_NI_02_04_LAFIA → LAFIA
    segs = code.split("_")
    i = max([k for k, s in enumerate(segs) if s.isdigit()] or [1])
    return " ".join(segs[i + 1:]).strip()

def find(n, cand):
    if n in cand: return cand[n], "exact"
    if ALIASES.get(n) in cand: return cand[ALIASES[n]], "alias"
    for k in cand:  # GRID3 compound names: Arewa Dandi, Birnin Magaji-Kiyaw
        if len(n) >= 4 and k.startswith(n): return cand[k], "prefix"
    c = difflib.get_close_matches(n, cand, 1, 0.8)
    return (cand[c[0]], "fuzzy") if c else (None, "none")

def grid3_units(glob):
    # the warehouse keeps the boundary in `geometry` (its fhir_json leaves it out)
    q = (f"LOAD spatial; SELECT id, name, admin_level, admin1_name, pcode, ST_AsGeoJSON(geometry) AS geojson "
         f"FROM read_parquet('{glob}') WHERE admin_level IN (1, 2)")
    out = subprocess.run(["duckdb", "-no-agent", "-json", "-c", q], capture_output=True, text=True, check=True).stdout
    return json.loads(out or "[]")

def digit_units(raw):
    rows = []
    def walk(n, ht, parent):
        rows.append((ht, n.get("boundaryType"), n["code"], parent))
        for c in n.get("children") or []: walk(c, ht, n["code"])
    for l in open(os.path.join(raw, "boundary_tree.ndjson")):
        t = json.loads(l)
        if t["hierarchyType"] in {p[0] for p in PAIRS}:
            for b in t.get("boundary") or []: walk(b, t["hierarchyType"], None)
    return rows

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--grid3", required=True, help="parquet glob of the ICR's GRID3 admin units (country=NGA, type=admin-unit)")
    ap.add_argument("--out", default=os.path.join(os.environ.get("DIGIT_WORK", "work"), "out"))
    a = ap.parse_args()
    raw = os.path.join(os.path.dirname(os.path.abspath(a.out)), "raw")

    g = grid3_units(a.grid3)
    states = {norm(r["name"]): r for r in g if r["admin_level"] == 1}
    lgas = {}
    for r in g:
        if r["admin_level"] == 2: lgas.setdefault(norm(r["admin1_name"]), {})[norm(r["name"])] = r

    units = digit_units(raw)
    match = {}  # DIGIT code → (GRID3 row, how)
    for ht, lv1, lv2 in PAIRS:
        for _, bt, code, _p in units:
            if _ == ht and bt == lv1:
                hit, how = find(norm(label(code)), states)
                if hit: match[code] = (hit, how)
        for _, bt, code, parent in units:
            if _ == ht and bt == lv2 and parent in match:
                hit, how = find(norm(label(code)), lgas.get(norm(match[parent][0]["name"]), {}))
                if hit: match[code] = (hit, how)

    def did(code):  # DIGIT boundary ids as the transform writes them
        return "dgt-" + code.replace("_", "-")
    by_id = {did(c): v for c, v in match.items()}

    path = os.path.join(a.out, "Location.ndjson"); tmp = path + ".tmp"
    side = os.path.join(os.path.dirname(os.path.abspath(a.out)), "grid3"); os.makedirs(side, exist_ok=True)
    delta = open(os.path.join(side, "Location-grid3.ndjson"), "w")
    done = 0
    with open(path) as src, open(tmp, "w") as dst:
        for line in src:
            r = json.loads(line)
            if r["id"] in by_id:
                hit, how = by_id[r["id"]]
                geo = [{"url": GEO_EXT, "valueAttachment": {"contentType": "application/geo+json",
                        "data": base64.b64encode((hit["geojson"] if isinstance(hit["geojson"], str) else json.dumps(hit["geojson"], separators=(",", ":"))).encode()).decode()}}] if hit.get("geojson") else []
                r["extension"] = [e for e in r.get("extension", []) if e.get("url") != GEO_EXT] + geo
                ids = [i for i in r.get("identifier", []) if i.get("system") not in (PCODE, ICR_LOC)]
                if hit.get("pcode"): ids.append({"system": PCODE, "value": hit["pcode"]})
                ids.append({"system": ICR_LOC, "value": hit["id"]})
                r["identifier"] = ids
                if norm(hit["name"]) != norm(r.get("name", "")):
                    r["alias"] = sorted(set(r.get("alias", [])) | {hit["name"]})
                line = json.dumps(r) + "\n"; delta.write(line); done += 1
            dst.write(line)
    delta.close(); os.replace(tmp, path)

    with open(os.path.join(side, "grid3-crosswalk.csv"), "w", newline="") as f:
        w = csv.writer(f); w.writerow(["digit_code", "digit_location", "grid3_location", "grid3_name", "pcode", "match"])
        for code, (hit, how) in sorted(match.items()):
            w.writerow([code, did(code), hit["id"], hit["name"], hit.get("pcode") or "", how])
    print(f"matched {len(match)} DIGIT units to GRID3; enriched {done} Locations", file=sys.stderr)

if __name__ == "__main__":
    main()
