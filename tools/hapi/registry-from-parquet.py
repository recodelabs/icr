# Rebuild FHIR NDJSON (Location + paired Organization) from the kiln GeoParquet on sdi.healthcampaigns.org.
# fhir_json is the full resource minus the boundary; the boundary is re-attached from `geometry`.
import base64, json, sys, duckdb
B = "https://sdi.healthcampaigns.org/parquet/locations"
PARTS = ["country=NGA/geom_type=polygon/type=admin-unit", "country=NGA/geom_type=point/type=facility",
         "country=NGA/geom_type=point/type=settlement"] + sys.argv[1:]   # e.g. the two catchment partitions
BOUNDARY = "https://icr.healthcampaigns.org/StructureDefinition/location-boundary-geojson"
c = duckdb.connect(); c.sql("INSTALL httpfs; LOAD httpfs; INSTALL spatial; LOAD spatial;")
def clean(r):
    m = r.get("meta", {}); m.pop("versionId", None); m.pop("lastUpdated", None)   # no ifMatch on a fresh server
    return r
for p in PARTS:
    name = p.split("type=")[-1]
    q = f"SELECT fhir_json, organization_json, geom_type, ST_AsGeoJSON(geometry) FROM read_parquet('{B}/{p}/part-0.parquet')"
    n = o = 0
    with open(f"{name}.ndjson", "w") as f:
        for fj, oj, gt, gj in c.sql(q).fetchall():
            r = clean(json.loads(fj))
            if gt == "polygon" and gj:
                r.setdefault("extension", []).append({"url": BOUNDARY, "valueAttachment": {
                    "contentType": "application/geo+json", "data": base64.b64encode(gj.encode()).decode()}})
            if oj:
                f.write(json.dumps(clean(json.loads(oj)), separators=(",", ":")) + "\n"); o += 1
            f.write(json.dumps(r, separators=(",", ":")) + "\n"); n += 1
    print(name, n, "locations", o, "organizations")
