#!/usr/bin/env python3
"""Check the transform output: ids, tag, references, canonicals, cheap per-profile rules.

Usage: python3 check.py [OUT_DIR]   (default $DIGIT_WORK/out)
Every resource is checked (not a sample). Exit code 1 if any error.
"""
import collections
import json
import os
import re
import sys

OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.environ.get("DIGIT_WORK", "work"), "out")
BASE = "https://icr.healthcampaigns.org"
SD = BASE + "/StructureDefinition/"
TOC = BASE + "/CodeSystem/icr-task-output-type-cs"
ID_RE = re.compile(r"^[A-Za-z0-9\-\.]{1,64}$")
CANON_KEYS = {"instantiatesCanonical", "definitionCanonical", "valueCanonical"}

err = collections.Counter()
examples = {}


def bad(msg, res):
    err[msg] += 1
    examples.setdefault(msg, f"{res['resourceType']}/{res.get('id')}")


def files():
    for f in sorted(os.listdir(OUT)):
        if f.endswith(".ndjson"):
            yield f, os.path.join(OUT, f)


def resources():
    for f, p in files():
        with open(p) as fh:
            for line in fh:
                yield json.loads(line)


def exts(node, name):
    return [e for e in node.get("extension") or [] if e.get("url") == SD + name]


def has_code(ccpt, system_tail, code):
    return any(c.get("system", "").endswith(system_tail) and c.get("code") == code
               for c in (ccpt or {}).get("coding") or [])


def out_code(o):
    for c in (o.get("type") or {}).get("coding") or []:
        if c.get("system") == TOC:
            return c.get("code")
    return None


# pass 1: ids and canonical urls
ids, urls = set(), set()
counts = collections.Counter()
for r in resources():
    rt, rid = r["resourceType"], r.get("id", "")
    if not ID_RE.match(rid):
        bad("invalid id", r)
    key = f"{rt}/{rid}"
    if key in ids:
        bad("duplicate id", r)
    ids.add(key)
    if r.get("url"):
        urls.add(r["url"])
    prof = ((r.get("meta") or {}).get("profile") or ["(base)"])[0].rsplit("/", 1)[-1]
    counts[(rt, prof)] += 1

dangling = collections.Counter()
dangling_ex = {}


def walk(node, res, path):
    if isinstance(node, dict):
        for k, v in node.items():
            if k == "reference" and isinstance(v, str):
                if v not in ids:
                    key = (res["resourceType"], path, v.split("/")[0])
                    dangling[key] += 1
                    dangling_ex.setdefault(key, f"{res['resourceType']}/{res['id']} -> {v}")
            elif k in CANON_KEYS:
                for c in (v if isinstance(v, list) else [v]):
                    if isinstance(c, str) and c.startswith(BASE) and c not in urls:
                        key = (res["resourceType"], path + "." + k, "canonical")
                        dangling[key] += 1
                        dangling_ex.setdefault(key, f"{res['resourceType']}/{res['id']} -> {c}")
            else:
                walk(v, res, path + "." + k if k not in ("extension",) else path + ".ext")
    elif isinstance(node, list):
        for x in node:
            walk(x, res, path)


def check_event(r):
    if len(exts(r, "record-origin")) != 1:
        bad("event: record-origin must be 1..1", r)
    if not exts(r, "campaign"):
        bad("event: campaign missing", r)
    if not exts(r, "campaign-activity"):
        bad("event: campaign-activity missing", r)


def check(r):
    prof = ((r.get("meta") or {}).get("profile") or [""])[0].rsplit("/", 1)[-1]
    tags = (r.get("meta") or {}).get("tag") or []
    if not any(t.get("code") == "digit-demo" and t.get("system") == BASE + "/CodeSystem/icr-project-tag-cs" for t in tags):
        bad("digit-demo tag missing", r)
    if not r.get("identifier") and r["resourceType"] not in ("Group",) and prof != "":
        bad("no identifier", r)
    if prof == "ICRLocation":
        if any(has_code(t, "icr-location-type-cs", "admin-unit") for t in r.get("type") or []) and not r.get("identifier"):
            bad("icr-loc-admin-id", r)
        if not r.get("name"):
            bad("location: no name", r)
    elif prof == "ICRFacilityOrganization":
        if not r.get("name") or not r.get("type"):
            bad("org: name/type 1..", r)
    elif prof == "ICRPatient":
        if not r.get("identifier") or not r.get("name") or not r.get("gender"):
            bad("patient: identifier/name/gender required", r)
        if not r.get("birthDate") and not r.get("_birthDate"):
            bad("patient: birthDate 1..1", r)
        if len([i for i in r.get("identifier") or [] if i.get("system") == BASE + "/identifiers/registry-id"]) > 1:
            bad("patient: registryId 0..1", r)
    elif prof == "ICRDeliveryUnit":
        if r.get("type") != "person" or r.get("actual") is not True or not r.get("code"):
            bad("du: type/actual/code fixed", r)
        if len(exts(r, "group-location")) != 1:
            bad("du: group-location 1..1", r)
        heads = sum(1 for m in r.get("member") or [] for e in exts(m, "relationship-to-head")
                    if has_code(e.get("valueCodeableConcept"), "icr-household-relationship-cs", "head") and not m.get("inactive"))
        if heads > 1:
            bad("icr-du-one-head", r)
        if r.get("member") and heads == 0:
            err["(warning) icr-du-head: household with members but no head"] += 1
    elif prof == "ICRTargetPopulation":
        if r.get("actual") is not False or r.get("type") != "person" or not isinstance(r.get("quantity"), int):
            bad("tp: actual/type/quantity", r)
        if len(exts(r, "denominator-source")) != 1:
            bad("tp: denominator-source 1..1", r)
    elif prof == "ICRCampaign":
        if len(r.get("instantiatesCanonical") or []) != 1 or not r.get("category") or not r.get("period") \
                or not r.get("subject") or not r.get("intent") or not r.get("status"):
            bad("campaign: required element missing", r)
        for a in r.get("activity") or []:
            d = a.get("detail")
            if d and (len(d.get("instantiatesCanonical") or []) != 1 or not d.get("status")):
                bad("campaign: activity.detail instantiatesCanonical/status", r)
        if any(has_code(c, "icr-campaign-type-cs", "integrated") for c in r.get("category") or []):
            for a in r.get("activity") or []:
                if not exts(a.get("detail") or {}, "planning-denominator"):
                    err["(warning) icr-campaign-activity-targets"] += 1
    elif prof == "ICRCampaignProtocol":
        if not r.get("type") or not exts(r, "delivery-strategy"):
            bad("protocol: type / delivery-strategy", r)
    elif prof == "ICRCampaignActivity":
        if r.get("kind") != "Task" or not r.get("code"):
            bad("activity: kind/code", r)
    elif prof == "ICRCampaignTask":
        if not r.get("code") or len(r.get("basedOn") or []) != 1 or not r.get("for") or not r.get("location") \
                or not r.get("intent") or not r.get("status"):
            bad("task: required element missing", r)
        if len(exts(r, "delivery-strategy")) != 1 or len(exts(r, "task-origin")) != 1:
            bad("task: delivery-strategy / task-origin 1..1", r)
        oc = collections.Counter(out_code(o) for o in r.get("output") or [])
        for one in ("houses-visited", "eligible-present", "eligible-absent", "children-already-marked",
                    "revisit-outcome", "referred-count", "registered-count", "voucher", "entitlement"):
            if oc[one] > 1:
                bad(f"task: output[{one}] 0..1", r)
        tc = [o for o in r.get("output") or [] if out_code(o) == "treated-count"]
        if len(tc) > 1:
            acts = [exts(o, "campaign-activity") for o in tc]
            if not all(acts):
                bad("icr-task-treated-per-activity: entries must name their activity", r)
            vals = [a[0]["valueCanonical"] for a in acts if a]
            if len(set(vals)) != len(vals):
                bad("icr-task-treated-per-activity: activity repeated", r)
        if r.get("instantiatesCanonical") and any(exts(o, "campaign-activity") for o in tc):
            bad("icr-task-treated-per-activity: qualified entry on a Task with instantiatesCanonical", r)
        for o in r.get("output") or []:
            if not any(k.startswith("value") for k in o):
                bad("task: output without value", r)
    elif prof == "ICRImmunizationEvent":
        check_event(r)
        if not r.get("patient") or not r.get("vaccineCode") or not r.get("occurrenceDateTime"):
            bad("immunization: patient/vaccineCode/occurrence", r)
        if r.get("status") == "not-done" and not r.get("statusReason"):
            bad("immunization: not-done without statusReason", r)
    elif prof == "ICRMedicationAdministration":
        check_event(r)
        if not r.get("subject") or not r.get("medicationCodeableConcept") or not r.get("effectiveDateTime"):
            bad("ma: subject/medication/effective", r)
        if r.get("status") == "not-done" and not r.get("statusReason"):
            bad("ma: not-done without statusReason", r)
    elif prof == "ICRSupplyDistribution":
        check_event(r)
        if not (r.get("suppliedItem") or {}).get("quantity") or not exts(r, "distribution-recipient"):
            bad("distribution: suppliedItem.quantity / recipient", r)
    elif prof == "ICRSupplyMovement":
        if len(exts(r, "record-origin")) != 1 or not r.get("suppliedItem"):
            bad("movement: record-origin / suppliedItem", r)
    elif prof == "ICRReferral":
        if r.get("intent") != "order" or not r.get("subject") or len(r.get("basedOn") or []) != 1 \
                or not r.get("authoredOn") or not r.get("reasonCode") \
                or not any(has_code(c, "icr-referral-category-cs", "campaign-referral") for c in r.get("category") or []):
            bad("referral: required/fixed element", r)


for r in resources():
    walk(r, r, r["resourceType"])
    check(r)

print("Resources by type and profile:")
for (rt, prof), n in sorted(counts.items()):
    print(f"  {rt:26} {prof:30} {n:>9,}")
print(f"  {'total':57} {sum(counts.values()):>9,}")
print("\nDangling references / canonicals:", sum(dangling.values()))
for k, n in dangling.most_common():
    print(f"  {n:>8}  {k}  e.g. {dangling_ex[k]}")
hard = {k: v for k, v in err.items() if not k.startswith("(warning)")}
print("\nErrors:", sum(hard.values()))
for k, n in sorted(err.items()):
    print(f"  {n:>8}  {k}" + (f"  e.g. {examples[k]}" if k in examples else ""))
sys.exit(1 if hard or dangling else 0)
