#!/usr/bin/env python3
"""Seed the local HAPI FHIR server.

    python3 load.py ig                      # every resource the IG compiles (ig/fsh-generated/resources)
    python3 load.py kiln-demo [--snapshot DIR]   # a kiln snapshot: organizations.ndjson then locations.ndjson
    python3 load.py ndjson FILE [FILE …]    # any NDJSON of FHIR resources

Resources are PUT by their own id inside transaction bundles (--batch per bundle),
so a re-run is idempotent: unchanged resources get 200, new ones 201. Stdlib only.
"""
import argparse, glob, json, os, sys, time, urllib.request, urllib.error

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
IG_RESOURCES = os.path.join(REPO, "ig", "fsh-generated", "resources")
KILN_SNAPSHOT = os.path.abspath(os.path.join(REPO, "..", "kiln", "data", "icr-demo", "snapshot"))
SKIP_TYPES = {"ImplementationGuide"}


def wait_for(base, timeout):
    deadline = time.time() + timeout
    while True:
        try:
            with urllib.request.urlopen(base + "/metadata", timeout=10) as r:
                if r.status == 200:
                    return
        except Exception as e:  # noqa: BLE001
            err = e
        if time.time() > deadline:
            sys.exit(f"server at {base} not ready after {timeout}s: {err}")
        time.sleep(3)


def post_bundle(base, resources):
    entries = []
    for res in resources:
        res = dict(res)
        meta = dict(res.get("meta") or {})
        meta.pop("versionId", None)   # server-owned; a stale one would trip version checks
        meta.pop("lastUpdated", None)
        if meta:
            res["meta"] = meta
        else:
            res.pop("meta", None)
        entries.append({
            "resource": res,
            "request": {"method": "PUT", "url": f"{res['resourceType']}/{res['id']}"},
        })
    body = json.dumps({"resourceType": "Bundle", "type": "transaction", "entry": entries}).encode()
    req = urllib.request.Request(base, data=body, method="POST",
                                 headers={"Content-Type": "application/fhir+json",
                                          "Accept": "application/fhir+json"})
    try:
        with urllib.request.urlopen(req, timeout=600) as r:
            out = json.load(r)
    except urllib.error.HTTPError as e:
        detail = e.read().decode(errors="replace")
        try:
            oo = json.loads(detail)
            detail = "; ".join(i.get("diagnostics", "") for i in oo.get("issue", []))
        except Exception:  # noqa: BLE001
            pass
        return None, f"HTTP {e.code}: {detail[:800]}"
    statuses = {}
    for e in out.get("entry", []):
        st = (e.get("response") or {}).get("status", "?").split(" ")[0]
        statuses[st] = statuses.get(st, 0) + 1
    return statuses, None


def load(base, resources, batch, label):
    total, agg, failures = 0, {}, 0
    for i in range(0, len(resources), batch):
        chunk = resources[i:i + batch]
        statuses, err = post_bundle(base, chunk)
        if err:
            failures += len(chunk)
            print(f"  {label} batch {i // batch + 1}: FAILED — {err}")
            continue
        total += len(chunk)
        for k, v in statuses.items():
            agg[k] = agg.get(k, 0) + v
        print(f"  {label} batch {i // batch + 1}: {len(chunk)} sent {statuses}")
    print(f"{label}: {total} loaded {agg}" + (f", {failures} FAILED" if failures else ""))
    return failures


def read_ig():
    files = sorted(glob.glob(os.path.join(IG_RESOURCES, "*.json")))
    if not files:
        sys.exit(f"no resources in {IG_RESOURCES} — run `sushi build .` in ig/ first")
    out = []
    for f in files:
        with open(f) as fh:
            r = json.load(fh)
        if r.get("resourceType") in SKIP_TYPES or "id" not in r:
            continue
        out.append(r)
    # Conformance first, then everything else — HAPI likes CodeSystems before ValueSets.
    # SearchParameters go in their own leading bundle (see load_ig) so the custom
    # parameters exist before the resources they index arrive.
    order = {"SearchParameter": -1, "CodeSystem": 0, "ValueSet": 1, "StructureDefinition": 2,
             "ConceptMap": 3, "Questionnaire": 4, "Measure": 5}
    out.sort(key=lambda r: (order.get(r["resourceType"], 9), r["resourceType"], r["id"]))
    return out


def reindex(base, resource_types):
    """Ask HAPI to re-index the given types so custom SearchParameters apply to
    resources that were already stored (HAPI only indexes new params going forward)."""
    params = {"resourceType": "Parameters",
              "parameter": [{"name": "url", "valueString": f"{t}?"} for t in sorted(resource_types)]}
    req = urllib.request.Request(f"{base}/$reindex", data=json.dumps(params).encode(),
                                 headers={"Content-Type": "application/fhir+json",
                                          "Accept": "application/fhir+json", "Prefer": "respond-async"},
                                 method="POST")
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            body = json.loads(r.read())
        msg = "; ".join(i.get("diagnostics", "") for i in body.get("issue", []) if i.get("severity") == "information")
        print(f"  $reindex {', '.join(sorted(resource_types))}: {msg or 'accepted'}")
    except urllib.error.HTTPError as e:
        print(f"  $reindex failed: HTTP {e.code} {e.read().decode()[:300]}")
        return 1
    return 0


def load_ig(base, batch):
    """SearchParameters first in their own bundle, then everything else, then a
    $reindex of the SearchParameters' base types so already-loaded data is searchable."""
    resources = read_ig()
    sps = [r for r in resources if r["resourceType"] == "SearchParameter"]
    rest = [r for r in resources if r["resourceType"] != "SearchParameter"]
    failures = 0
    if sps:
        failures += load(base, sps, batch, "ig:searchparameters")
    failures += load(base, rest, batch, "ig")
    if sps:
        bases = {b for sp in sps for b in sp.get("base", [])}
        failures += reindex(base, bases)
    return failures


def read_ndjson(path):
    out = []
    with open(path) as fh:
        for line in fh:
            line = line.strip()
            if line:
                out.append(json.loads(line))
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("source", choices=["ig", "kiln-demo", "ndjson"])
    ap.add_argument("files", nargs="*", help="NDJSON files (source = ndjson)")
    ap.add_argument("--base", default=os.environ.get("FHIR_BASE", "http://localhost:3447/fhir"))
    ap.add_argument("--snapshot", default=KILN_SNAPSHOT, help="kiln snapshot dir (source = kiln-demo)")
    ap.add_argument("--batch", type=int, default=200)
    ap.add_argument("--wait", type=int, default=300, help="seconds to wait for the server")
    a = ap.parse_args()

    print(f"waiting for {a.base} …")
    wait_for(a.base, a.wait)
    failures = 0
    if a.source == "ig":
        failures += load_ig(a.base, a.batch)
    elif a.source == "kiln-demo":
        for name in ("organizations.ndjson", "locations.ndjson"):
            p = os.path.join(a.snapshot, name)
            if not os.path.exists(p):
                print(f"  (no {name} in {a.snapshot}, skipping)")
                continue
            failures += load(a.base, read_ndjson(p), a.batch, name)
    else:
        if not a.files:
            sys.exit("ndjson: give at least one file")
        for f in a.files:
            failures += load(a.base, read_ndjson(f), a.batch, os.path.basename(f))
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
