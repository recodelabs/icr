#!/usr/bin/env python3
# Copy a server's FHIR resources from the source HAPI to the hfs server, conformance first so
# profiles and custom SearchParameters register, then data. Idempotent: FHIR batch bundles,
# PUT by id. Stdlib only. Run inside a container attached to both compose networks, e.g.:
#
#   cid=$(sudo docker run -d --network icr-uga_default -v $PWD/migrate.py:/mig.py:ro python:3-alpine sleep 900)
#   sudo docker network connect icr-ugahfs_default $cid
#   sudo docker exec $cid python3 /mig.py
#   sudo docker rm -f $cid
#
# SRC/DST default to the Uganda HAPI and the hfs server on those networks; override with env.
import json, os, urllib.request, urllib.error

SRC = os.environ.get("SRC", "http://country-hapi:3447/fhir")   # source HAPI (its /fhir base)
DST = os.environ.get("DST", "http://hfs:8080")                  # hfs (root base; gateway adds /fhir)
TYPES = ["StructureDefinition", "SearchParameter", "CodeSystem", "ValueSet",
         "PlanDefinition", "ActivityDefinition", "Measure",
         "Location", "Organization", "Group", "CarePlan", "Task", "Patient",
         "MeasureReport", "Condition"]

def get(url):
    req = urllib.request.Request(url, headers={"Accept": "application/fhir+json"})
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read())

def fetch_all(rtype):
    out, url = [], f"{SRC}/{rtype}?_count=200"
    while url:
        b = get(url)
        for e in b.get("entry", []):
            res = e.get("resource")
            if res and res.get("resourceType") == rtype:
                out.append(res)
        url = next((l["url"] for l in b.get("link", []) if l.get("relation") == "next"), None)
    return out

def post_batch(resources):
    created = updated = failed = 0
    for i in range(0, len(resources), 100):
        chunk = resources[i:i + 100]
        bundle = {"resourceType": "Bundle", "type": "batch", "entry": [
            {"resource": r, "request": {"method": "PUT", "url": f"{r['resourceType']}/{r['id']}"}}
            for r in chunk]}
        req = urllib.request.Request(DST + "/", data=json.dumps(bundle).encode(),
              headers={"Content-Type": "application/fhir+json", "Accept": "application/fhir+json"},
              method="POST")
        try:
            with urllib.request.urlopen(req, timeout=300) as r:
                rb = json.loads(r.read())
            for e in rb.get("entry", []):
                st = str(e.get("response", {}).get("status", ""))
                if st.startswith("201"): created += 1
                elif st.startswith("200"): updated += 1
                else: failed += 1
        except urllib.error.HTTPError as ex:
            failed += len(chunk); print(f"    HTTP {ex.code}: {ex.read()[:200]}")
    return created, updated, failed

total_c = total_u = total_f = 0
for t in TYPES:
    res = fetch_all(t)
    if not res:
        print(f"{t:20} (none)"); continue
    c, u, f = post_batch(res)
    total_c += c; total_u += u; total_f += f
    print(f"{t:20} fetched={len(res):5}  created={c:5} updated={u:5} failed={f:5}")
print(f"\nTOTAL created={total_c} updated={total_u} failed={total_f}")
