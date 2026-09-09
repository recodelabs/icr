#!/usr/bin/env python3
"""Build catchment-area Locations (and their accessibility denominators) for the ICR
registry from Crosscut exports.

    python3 build.py [--hf GEOJSON] [--hf-csv CSV] [--settlements GEOJSON] [--settlements-csv CSV]
                     [--out NDJSON] [--groups-out NDJSON]

Input (defaults: the Toro LGA, Bauchi files in data/imports/):
  --hf / --settlements     one polygon per health facility / settlement, keyed by the
                           registry Location id (property `location_id`).
  --hf-csv / --settlements-csv
                           the matching Google Sheets exports (two header rows): the
                           population / building / accessibility columns, and — for
                           settlements — the parent facility (`organization_id` =
                           `org-<facility id>`), which the GeoJSON does not carry. The
                           CSVs' own uuid columns are unusable (Sheets coerced them to
                           numbers): facilities join on `organization_id`, settlements on
                           `grid3_settlement_id`.

Output, ready for tools/hapi/load.py (Locations first, then Groups):

  --out         ICRLocation per polygon:
                  Location/catchment-<facility id>    type facility-catchment,   partOf the LGA
                  Location/catchment-<settlement id>  type settlement-catchment, partOf the facility catchment
                each with catchment-of → its site, and one building-count extension per
                footprint dataset in the CSV (OSM, Overture, Google Open Buildings at 60/70/80 %).
  --groups-out  ICRTargetPopulation Groups: the WorldPop 2026 population of each catchment
                by walking-time band to the facility (within 1 h, 1–4 h, over 4 h) — the
                CSV's "People … of walking" columns — as travel-time-stratified estimates
                scoped to the catchment Location (Group id acc-<band>-<year>-<site id>).

The catchments' own all-of-the-area WorldPop totals are NOT built here: those come from
`kiln population --type facility-catchment` / `--type settlement-catchment`, the same
raster extraction as the admin units (see README). Stdlib only.
"""
import argparse, base64, csv, json, os, re, sys
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
IMPORTS = os.path.join(REPO, "data", "imports")
DEFAULT_HF = os.path.join(IMPORTS, "Nigeria - ICR HFs, Bauchi_ Toro, Ward Bounded, Filtered_2026-09-09T14_50_48Z.geojson")
DEFAULT_HF_CSV = os.path.join(IMPORTS, "Nigeria - ICR HFs, Bauchi_ Toro, Ward Bounded, Filtered.csv")
DEFAULT_ST = os.path.join(IMPORTS, "Nigeria - ICR Settlements, Bound by HF catchments, Filtered_2026-09-09T15_49_21Z.geojson")
DEFAULT_ST_CSV = os.path.join(IMPORTS, "Nigeria - ICR Settlements, Bound by HF catchments, Filtered.csv")
DEFAULT_OUT = os.path.join(HERE, "out", "nga-ba-toro-catchments.ndjson")
DEFAULT_GROUPS_OUT = os.path.join(HERE, "out", "nga-ba-toro-access-groups.ndjson")

BASE = "https://icr.healthcampaigns.org"
LOCATION_PROFILE = f"{BASE}/StructureDefinition/ICRLocation"
GROUP_PROFILE = f"{BASE}/StructureDefinition/ICRTargetPopulation"
BOUNDARY_EXT = f"{BASE}/StructureDefinition/location-boundary-geojson"
CATCHMENT_OF_EXT = f"{BASE}/StructureDefinition/catchment-of"
BUILDING_COUNT_EXT = f"{BASE}/StructureDefinition/building-count"
LOCATION_TYPE_CS = f"{BASE}/CodeSystem/icr-location-type-cs"
BUILDING_SOURCE_CS = f"{BASE}/CodeSystem/icr-building-source-cs"
GROUP_CHARACTERISTIC_CS = f"{BASE}/CodeSystem/icr-group-characteristic-cs"
TRAVEL_TIME_CS = f"{BASE}/CodeSystem/icr-travel-time-band-cs"
DENOMINATOR_SOURCE_CS = f"{BASE}/CodeSystem/icr-denominator-source-cs"
PHYSICAL_TYPE_CS = "http://terminology.hl7.org/CodeSystem/location-physical-type"

# CSV column → building-count entry. The dataset date is read from the header's "(YYYY-MM[-DD])".
BUILDING_COLUMNS = [
    ("OpenStreetMap Buildings", "osm", "OpenStreetMap", None),
    ("Overture Buildings", "overture", "Overture Maps", None),
    ("Google Buildings 60+% Confidence", "google-open-buildings", "Google Open Buildings", 0.6),
    ("Google Buildings 70+% Confidence", "google-open-buildings", "Google Open Buildings", 0.7),
    ("Google Buildings 80+% Confidence", "google-open-buildings", "Google Open Buildings", 0.8),
]
# CSV column → travel-time band. The accessibility block is "Total population - WorldPop (2026)".
WALKING_COLUMNS = [
    ("People within 1hr of walking", "walk-lt-1h", "Within 1 hour walking", "within 1 hour walking"),
    ("People between 1hr - 4hr of walking", "walk-1h-4h", "1 to 4 hours walking", "1 to 4 hours walking"),
    ("People further than 4hr of walking", "walk-gt-4h", "Over 4 hours walking", "over 4 hours walking"),
]
ACCESS_YEAR = 2026
ACCESS_ESTIMATE_DATE = "2026-01-01"   # the WorldPop raster's reference year, as kiln population does
ACCESS_SOURCE_TEXT = ("WorldPop 2026 population inside the catchment by walking time to the health facility "
                      "(Crosscut accessibility model; export 2026-09-09)")


def catchment_id(site_id):
    return f"catchment-{site_id}"


def is_uuid(s):
    return isinstance(s, str) and len(s) == 36 and s.count("-") == 4


def has_geometry(geometry):
    """False for a missing geometry or one with no coordinates at all — Crosscut
    exports an empty ring (`[[]]`) for a settlement it could not draw."""
    if not geometry or not geometry.get("coordinates"):
        return False
    def any_point(c):
        return any(any_point(x) for x in c) if isinstance(c, list) and c and isinstance(c[0], list) else bool(c)
    return any_point(geometry["coordinates"])


def as_int(s):
    try:
        return int(round(float(str(s).replace(",", ""))))
    except (TypeError, ValueError):
        return None


def header_date(header):
    m = re.search(r"\((\d{4}-\d{2}(?:-\d{2})?)\)", header)
    return m.group(1) if m else None


def building_counts(row, header):
    """building-count extensions for one CSV row, one per dataset column with a number."""
    out = []
    for prefix, code, display, min_conf in BUILDING_COLUMNS:
        col = next((h for h in header if h.startswith(prefix)), None)
        if col is None:
            continue
        n = as_int(row.get(col))
        if n is None or n < 0:
            continue
        ext = [
            {"url": "source", "valueCodeableConcept": {"coding": [{"system": BUILDING_SOURCE_CS, "code": code, "display": display}]}},
            {"url": "count", "valueUnsignedInt": n},
        ]
        date = header_date(col)
        if date:
            ext.append({"url": "date", "valueDate": date})
        if min_conf is not None:
            ext.append({"url": "minConfidence", "valueDecimal": min_conf})
        out.append({"url": BUILDING_COUNT_EXT, "extension": ext})
    return out


def location(site_id, name, type_code, type_display, part_of, geometry, buildings):
    """One catchment-area ICRLocation. The boundary is the bare GeoJSON geometry,
    base64 in an application/geo+json attachment — the same shape kiln writes for
    admin units, so the warehouse picks it up as a polygon row."""
    data = base64.b64encode(json.dumps(geometry, separators=(",", ":")).encode()).decode()
    return {
        "resourceType": "Location",
        "id": catchment_id(site_id),
        "meta": {"profile": [LOCATION_PROFILE]},
        "extension": [
            {"url": BOUNDARY_EXT,
             "valueAttachment": {"contentType": "application/geo+json", "data": data}},
            {"url": CATCHMENT_OF_EXT, "valueReference": {"reference": f"Location/{site_id}"}},
            *buildings,
        ],
        "status": "active",
        "name": f"{name} catchment",
        "type": [{"coding": [{"system": LOCATION_TYPE_CS, "code": type_code, "display": type_display}]}],
        "physicalType": {"coding": [{"system": PHYSICAL_TYPE_CS, "code": "area", "display": "Area"}]},
        "partOf": {"reference": f"Location/{part_of}"},
    }


def access_groups(site_id, catchment_name, row):
    """Three ICRTargetPopulation Groups (one per walking-time band) for one catchment."""
    out = []
    for col, code, display, phrase in WALKING_COLUMNS:
        n = as_int(row.get(col))
        if n is None or n < 0:
            continue
        out.append({
            "resourceType": "Group",
            "id": f"acc-{code}-{ACCESS_YEAR}-{site_id}",
            "meta": {"profile": [GROUP_PROFILE]},
            "extension": [
                {"url": f"{BASE}/StructureDefinition/denominator-source",
                 "valueCodeableConcept": {"coding": [{"system": DENOMINATOR_SOURCE_CS, "code": "worldpop", "display": "WorldPop modelled estimate"}],
                                          "text": ACCESS_SOURCE_TEXT}},
                {"url": f"{BASE}/StructureDefinition/denominator-type", "valueCode": "total-population"},
                {"url": f"{BASE}/StructureDefinition/estimate-date", "valueDate": ACCESS_ESTIMATE_DATE},
                {"url": f"{BASE}/StructureDefinition/is-calculated", "valueBoolean": False},
                {"url": f"{BASE}/StructureDefinition/is-planning-denominator", "valueBoolean": False},
            ],
            "type": "person",
            "actual": False,
            "name": f"Population {phrase} of the health facility, {catchment_name}, {ACCESS_YEAR} (WorldPop)",
            "quantity": n,
            "characteristic": [
                {"code": {"coding": [{"system": GROUP_CHARACTERISTIC_CS, "code": "geography", "display": "Geographic scope"}]},
                 "valueReference": {"reference": f"Location/{catchment_id(site_id)}", "display": catchment_name},
                 "exclude": False},
                {"code": {"coding": [{"system": GROUP_CHARACTERISTIC_CS, "code": "travel-time", "display": "Travel time to service point"}]},
                 "valueCodeableConcept": {"coding": [{"system": TRAVEL_TIME_CS, "code": code, "display": display}]},
                 "exclude": False},
            ],
        })
    return out


def read_sheet(path, key):
    """Rows of a Google Sheets export (group-heading row, then column names) as dicts
    keyed by the first column named `key`. Repeated column names (the settlement CSV
    repeats the site block for the parent facility) keep their FIRST occurrence, which
    is the site's own value."""
    with open(path, encoding="utf-8-sig", newline="") as fh:
        rows = list(csv.reader(fh))
    header = rows[1]
    first = {}
    for i, h in enumerate(header):
        first.setdefault(h, i)
    out = {}
    for r in rows[2:]:
        if len(r) < len(header):
            r = r + [""] * (len(header) - len(r))
        d = {h: r[i] for h, i in first.items()}
        # settlements: the only organization_id column is in the parent-site block
        # (facilities: it is the site's own — unused for them)
        org_cols = [i for i, h in enumerate(header) if h == "organization_id"]
        d["_parent_org"] = r[org_cols[-1]].strip() if org_cols else ""
        k = d.get(key, "").strip()
        if k:
            out[k] = d
    return header, out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--hf", default=DEFAULT_HF)
    ap.add_argument("--hf-csv", default=DEFAULT_HF_CSV)
    ap.add_argument("--settlements", default=DEFAULT_ST)
    ap.add_argument("--settlements-csv", default=DEFAULT_ST_CSV)
    ap.add_argument("--out", default=DEFAULT_OUT)
    ap.add_argument("--groups-out", default=DEFAULT_GROUPS_OUT)
    a = ap.parse_args()

    with open(a.hf) as fh:
        hf = json.load(fh)["features"]
    with open(a.settlements) as fh:
        st = json.load(fh)["features"]
    hf_header, hf_rows = read_sheet(a.hf_csv, "organization_id")          # org-<facility id> → row
    st_header, st_rows = read_sheet(a.settlements_csv, "grid3_settlement_id")

    locations, groups, problems = [], [], Counter()
    facility_ids = set()
    for ft in hf:
        p = ft["properties"]
        fid, lga = p.get("location_id"), p.get("lga_location_id")
        if not is_uuid(fid) or not lga:
            problems["facility: missing id/lga"] += 1
            continue
        if not has_geometry(ft.get("geometry")):
            problems["facility: empty geometry"] += 1
            continue
        row = hf_rows.get(f"org-{fid}")
        if row is None:
            problems["facility: no CSV row (no building counts / access bands)"] += 1
        facility_ids.add(fid)
        loc = location(fid, p["Name"], "facility-catchment", "Facility catchment", lga, ft["geometry"],
                       building_counts(row, hf_header) if row else [])
        locations.append(loc)
        if row:
            groups.extend(access_groups(fid, loc["name"], row))

    for ft in st:
        p = ft["properties"]
        sid, gid = p.get("location_id"), str(p.get("grid3_settlement_id", ""))
        row = st_rows.get(gid)
        parent = row["_parent_org"][len("org-"):] if row and row["_parent_org"].startswith("org-") else None
        if not is_uuid(sid):
            problems["settlement: missing id"] += 1
            continue
        if not has_geometry(ft.get("geometry")):
            problems["settlement: empty geometry"] += 1
            print(f"  skip {sid} ({p.get('Name')}): empty geometry", file=sys.stderr)
            continue
        if parent is None:
            problems["settlement: no parent facility in the CSV"] += 1
            continue
        if parent not in facility_ids:
            problems["settlement: parent facility has no catchment polygon"] += 1
            continue
        loc = location(sid, p["Name"], "settlement-catchment", "Settlement catchment",
                       catchment_id(parent), ft["geometry"], building_counts(row, st_header))
        locations.append(loc)
        groups.extend(access_groups(sid, loc["name"], row))

    for path, items in ((a.out, locations), (a.groups_out, groups)):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as fh:
            for r in items:
                fh.write(json.dumps(r, separators=(",", ":")) + "\n")
    kinds = Counter(r["type"][0]["coding"][0]["code"] for r in locations)
    with_b = sum(1 for r in locations if any(e["url"] == BUILDING_COUNT_EXT for e in r["extension"]))
    print(f"{len(locations)} Locations → {a.out}  {dict(kinds)}  ({with_b} with building counts)")
    bands = Counter(g["characteristic"][1]["valueCodeableConcept"]["coding"][0]["code"] for g in groups)
    print(f"{len(groups)} Groups → {a.groups_out}  {dict(bands)}")
    for k, v in problems.items():
        print(f"  skipped {v}: {k}", file=sys.stderr)
    sys.exit(0 if locations else 1)


if __name__ == "__main__":
    main()
