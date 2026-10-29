#!/usr/bin/env python3
# DIGIT reference data: product variants and products, project types (MDMS), boundary
# hierarchies, campaigns (project-factory), and the projects that the field data points at.
#   python3 -I extract_ref.py [variants products mdms boundaries campaigns projects]
import json, os, sys, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from extract import call, OUT

def save(name, rows):
    with open(os.path.join(OUT, name + ".ndjson"), "w") as f:
        for r in rows: f.write(json.dumps(r) + "\n")
    print(f"{name}: {len(rows)}", flush=True)

def paged(acct, path, body, key, total_key=None):
    rows, off = [], 0
    while True:
        d = call(acct, f"{path}?tenantId=demo&limit=1000&offset={off}", body)
        got = d.get(key, [])
        rows += got; off += len(got)
        if len(got) < 1000: return rows

def variants():
    save("product_variant", paged("field", "/product/variant/v1/_search", {"ProductVariant": {"tenantId": "demo"}}, "ProductVariant"))

def products():
    for acct in ("field", "admin"):
        try:
            save("product", paged(acct, "/product/v1/_search", {"Product": {"tenantId": "demo"}}, "Product")); return
        except RuntimeError as e: print(f"product via {acct}: {str(e)[:100]}")

def mdms():
    for schema, name in (("HCM-PROJECT-TYPES.projectTypes", "mdms_project_type"),):
        rows, off = [], 0
        while True:
            d = call("admin", "/mdms-v2/v2/_search", {"MdmsCriteria": {"tenantId": "demo", "schemaCode": schema, "limit": 500, "offset": off}})
            got = d.get("mdms", []); rows += got; off += len(got)
            if len(got) < 500: break
        save(name, rows)

def boundaries():
    # every hierarchy type in use, with the full tree from the root
    d = call("admin", "/boundary-service/boundary-hierarchy-definition/_search", {"BoundaryTypeHierarchySearchCriteria": {"tenantId": "demo", "limit": 100, "offset": 0}})
    hier = d.get("BoundaryHierarchy", [])
    save("boundary_hierarchy", hier)
    trees = []
    for h in hier:
        ht = h.get("hierarchyType")
        try:
            t = call("admin", f"/boundary-service/boundary-relationships/_search?tenantId=demo&hierarchyType={ht}&includeChildren=true", {})
            trees += [{"hierarchyType": ht, **tb} for tb in t.get("TenantBoundary", [])]
        except RuntimeError as e: print(f"  boundary tree {ht}: {str(e)[:100]}")
    save("boundary_tree", trees)

def campaigns():
    rows, off = [], 0
    while True:
        d = call("admin", "/project-factory/v1/project-type/search", {"CampaignDetails": {"tenantId": "demo", "isActive": True, "pagination": {"limit": 100, "offset": off, "sortBy": "createdTime", "sortOrder": "desc"}}})
        got = d.get("CampaignDetails", []); rows += got; off += len(got)
        if len(got) < 100: break
    save("campaign", rows)

def projects():
    ids = collections.Counter()
    for fn in ("project_beneficiary", "task", "stock"):
        p = os.path.join(OUT, fn + ".ndjson")
        if not os.path.exists(p): continue
        for l in open(p):
            r = json.loads(l)
            for k in ("projectId", "referenceId"):
                v = r.get(k)
                if v and not v.startswith("{{"): ids[v] += 1
    rows = []
    idl = sorted(ids)
    for i in range(0, len(idl), 50):
        batch = idl[i:i + 50]
        d = call("admin", "/project/v1/_search?tenantId=demo&limit=100&offset=0&includeDescendants=false",
                 {"Projects": [{"tenantId": "demo", "id": x} for x in batch]})
        rows += d.get("Project", [])
    save("project", rows)
    print(f"  {len(ids)} project ids referenced, {len(rows)} found", flush=True)

if __name__ == "__main__":
    for step in (sys.argv[1:] or ["variants", "products", "mdms", "boundaries", "campaigns"]):
        globals()[step]()
