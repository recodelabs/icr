"""Add what `fhir-pipes import location-boundaries` can't write yet to its Uganda Locations.

    python3 -I enrich.py build/districts.geojson overture/ug_division.parquet build/locations.ndjson build/locations-enriched.ndjson

- Identifiers: the P-code (official) for districts that have one, ISO 3166 codes for the country
  and regions (official), the Overture GERS id and the Wikidata id. A unit whose boundary came
  from a COD-AB unit of another level (Lira City: Lira Municipality) gets that P-code, not official. The import's single
  national-admin-code identifier is dropped: with no national code it only repeats the id.
- description: where the boundary came from.
Reads the GeoJSON's properties by unit, and the Overture divisions for the country and regions.
"""
import json, sys

import duckdb

GEOJSON, OVERTURE, IN, OUT = sys.argv[1:5]
ICR = "https://icr.healthcampaigns.org/identifiers"
PCODE, GERS = f"{ICR}/pcode", f"{ICR}/overture-gers"
WIKIDATA = "http://www.wikidata.org/entity"
ISO, ISO2 = "urn:iso:std:iso:3166", "urn:iso:std:iso:3166:-2"
RELEASE = "Overture Maps 2026-10-21.0 (OpenStreetMap contributors, ODbL)"

con = duckdb.connect()
con.sql("LOAD spatial")
with open(GEOJSON) as f:
    props = {feat["properties"]["district"]: feat["properties"] for feat in json.load(f)["features"]}
divs = {(s, n): (i, w, r) for i, s, n, w, r in con.sql(
    f"SELECT id, subtype, names.primary, wikidata, region FROM '{OVERTURE}' WHERE subtype IN ('country', 'region')").fetchall()}


def ident(system, value, official=False):
    return {"system": system, "value": value, **({"use": "official"} if official else {})}


n = 0
with open(IN) as f, open(OUT, "w") as out:
    for line in f:
        r = json.loads(line)
        ids = []
        level = r["id"].count("-")          # uga = 0, uga-n = 1, uga-n-abim = 2
        if level == 0:
            gers, wd, _ = divs[("country", r["name"])]
            ids = [ident(ISO, "UG", True), ident(GERS, gers), ident(WIKIDATA, wd)]
            r["description"] = f"Boundary: the union of its districts, from {RELEASE}."
        elif level == 1:
            gers, wd, iso = divs[("region", r["name"])]
            ids = [ident(ISO2, iso, True), ident(GERS, gers), ident(WIKIDATA, wd)]
            r["description"] = f"Boundary: the union of its districts, from {RELEASE}."
        else:
            p = props[r["name"]]
            if p.get("pcode"):
                ids.append(ident(PCODE, p["pcode"], True))
            if p.get("boundary_pcode"):
                ids.append(ident(PCODE, p["boundary_pcode"]))
            if p.get("gers"):
                ids.append(ident(GERS, p["gers"]))
            if p.get("wikidata"):
                ids.append(ident(WIKIDATA, p["wikidata"]))
            r["description"] = f"Boundary: {p['source']}."
        r["identifier"] = [i for i in ids if i["value"]]
        out.write(json.dumps(r, separators=(",", ":"), ensure_ascii=False) + "\n")
        n += 1
print(f"{n} Locations written to {OUT}")
