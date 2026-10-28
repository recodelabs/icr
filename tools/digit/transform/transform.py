#!/usr/bin/env python3
"""DIGIT HCM demo-tenant export -> ICR FHIR R4 NDJSON.

Usage: python3 transform.py [--raw DIR] [--out DIR] [--window-hours 2]
Reads raw/<entity>.ndjson, writes out/<ResourceType>.ndjson and out/report.json.
Offline, standard library only, deterministic ids (re-runs overwrite the same output).
"""
import argparse
import collections
import json
import os
import re
import sys
import time
from datetime import date, datetime, timezone

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from fhirutil import (BASE, CS, DAR, IDSYS, Out, afields, cc, coding, digit_ids, dmy_to_date,
                      ext, fid, ident, meta, ms_to_date, ms_to_dt, norm_ms, ref, rows)
from products import Catalog

AS_OF_MS = int(datetime(2026, 10, 28, tzinfo=timezone.utc).timestamp() * 1000)  # export date
SKIP = collections.Counter()
NOTE = collections.Counter()
PHYS = "http://terminology.hl7.org/CodeSystem/location-physical-type"

CAMPAIGN_TYPE = {  # DIGIT project type code -> ICR campaign type (per-instance ConceptMap)
    "CO-DELIVERY": "integrated", "MR-DN": "smc", "POLIO": "vaccination-sia", "Oncho": "mda",
    "NTD": "mda", "IRS-mz": "irs", "DEFAULT": "mda",
}
CT_DISPLAY = {"smc": "Seasonal malaria chemoprevention", "integrated": "Integrated / multi-intervention campaign",
              "mda": "Mass drug administration (NTD preventive chemotherapy)",
              "vaccination-sia": "Vaccination campaign (SIA)", "irs": "Indoor residual spraying",
              "itn-distribution": "ITN mass distribution", "vitamin-a": "Vitamin A supplementation"}


def campaign_type(code):
    if code in CAMPAIGN_TYPE:
        return CAMPAIGN_TYPE[code]
    c = code.lower()
    if any(k in c for k in ("llin", "bednet", "itn", "sk")):
        return "itn-distribution"
    return "mda"


def ct_cc(code):
    t = campaign_type(code)
    return cc("icr-campaign-type-cs", t, CT_DISPLAY[t])


H2H = ext("delivery-strategy", valueCodeableConcept=cc("icr-delivery-strategy-cs", "house-to-house", "House-to-house"))
ORIGIN = ext("task-origin", valueCode="field-registered")
REC_ORIGIN = ext("record-origin", valueCode="campaign")


def out_type(code, display):
    return {"coding": [coding("icr-task-output-type-cs", code, display)]}


# ------------------------------------------------------------------ boundaries
def boundary_name(code):
    toks = [t for t in code.split("_") if t]
    j = None
    for i, t in enumerate(toks):
        if t.isdigit() and any(not x.isdigit() for x in toks[i + 1:]):
            j = i
    rest = toks[j + 1:] if j is not None else toks
    return " ".join(rest).title() or code


def load_boundaries(raw):
    B = {}  # code -> (hierarchy, type, depth, parent, node id)
    def walk(n, h, depth, parent):
        B[n["code"]] = (h, n.get("boundaryType"), depth, parent, n.get("id"))
        for c in n.get("children") or []:
            walk(c, h, depth + 1, n["code"])
    for t in rows(raw + "/boundary_tree.ndjson"):
        for b in t.get("boundary") or []:
            walk(b, t["hierarchyType"], 0, None)
    return B


def write_boundaries(out, B):
    seen = {}
    for code, (h, btype, depth, parent, nid) in B.items():
        lid = fid(code)
        if lid in seen and seen[lid] != code:
            raise SystemExit(f"boundary id collision {code} {seen[lid]}")
        seen[lid] = code
        loc = {"resourceType": "Location", "id": lid, "meta": meta("ICRLocation"),
               "identifier": [{"system": IDSYS + "boundary/" + h.lower(), "value": code}],
               "name": boundary_name(code), "status": "active",
               "physicalType": {"coding": [{"system": PHYS, "code": "jdn", "display": "Jurisdiction"}]},
               "type": [cc("icr-location-type-cs", "admin-unit", "Administrative unit"),
                        {"text": f"{btype} (DIGIT {h} hierarchy, level {depth})"}]}
        i = ident("boundary-id", nid)
        if i:
            loc["identifier"].append(i)
        if parent:
            loc["partOf"] = ref("Location", fid(parent))
        out.write(loc)


def position(a):
    try:
        lat, lon = float(a.get("latitude") or 0), float(a.get("longitude") or 0)
    except (TypeError, ValueError):
        return None
    if lat == 0 and lon == 0:
        return None
    if not (-90 <= lat <= 90 and -180 <= lon <= 180):
        return None
    return {"longitude": lon, "latitude": lat}


def locality(addr):
    return ((addr or {}).get("locality") or {}).get("code")


# ------------------------------------------------------------------ facilities
def write_facilities(out, raw, B):
    F = {}
    for f in rows(raw + "/facility.ndjson"):
        F[f["id"]] = f
        lid = fid(f["id"])
        a = f.get("address") or {}
        usage = f.get("usage") or "facility"
        if f.get("isPermanent") is False:
            t0 = cc("icr-location-type-cs", "temporary-post", "Temporary post")
        else:
            t0 = cc("icr-location-type-cs", "facility", "Health facility")
        ids = digit_ids("facility", f)
        loc = {"resourceType": "Location", "id": lid, "meta": meta("ICRLocation"), "identifier": ids,
               "name": f.get("name") or f["id"], "status": "inactive" if f.get("isDeleted") else "active",
               "physicalType": {"coding": [{"system": PHYS, "code": "si", "display": "Site"}]},
               "type": [t0, {"text": usage}],
               "managingOrganization": ref("Organization", lid)}
        loc_code = locality(a)
        if loc_code in B:
            loc["partOf"] = ref("Location", fid(loc_code))
        elif loc_code:
            NOTE["facility: locality boundary not exported (partOf left empty)"] += 1
        p = position(a)
        if p:
            loc["position"] = p
        org = {"resourceType": "Organization", "id": lid, "meta": meta("ICRFacilityOrganization"),
               "identifier": list(ids), "active": not f.get("isDeleted"), "name": f.get("name") or f["id"],
               "type": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/organization-type",
                                     "code": "prov", "display": "Healthcare Provider"}]}, {"text": usage}]}
        out.write(loc)
        out.write(org)
    return F


# ------------------------------------------------------------------ individuals
GENDER = {"MALE": "male", "FEMALE": "female", "OTHER": "other", "TRANSGENDER": "other"}


def human_name(n):
    n = n or {}
    hn = {}
    given = [x for x in [n.get("givenName"), n.get("otherNames")] if x]
    if given:
        hn["given"] = given
    if n.get("familyName"):
        hn["family"] = n["familyName"]
    return hn


def telecom(r):
    t = []
    for k, use in (("mobileNumber", "mobile"), ("altContactNumber", "home")):
        if r.get(k):
            t.append({"system": "phone", "value": str(r[k]), "use": use})
    if r.get("email"):
        t.append({"system": "email", "value": r["email"]})
    return t


def write_individuals(out, raw, clients, creators, any_link=frozenset()):
    """Patient for every campaign-linked client; Practitioner for every EMPLOYEE user who created an
    imported record. A person can be both. Everyone else is skipped."""
    patients = {}   # crid -> birth date (date or None)
    users = {}      # userUuid -> Practitioner id
    for r in rows(raw + "/individual.ndjson"):
        key = r.get("clientReferenceId") or r["id"]
        is_client = key in clients
        is_worker = bool(r.get("userUuid")) and r.get("userUuid") in creators
        if is_worker and (r.get("userDetails") or {}).get("type") != "EMPLOYEE":
            SKIP["individual: creator of imported records but not an EMPLOYEE user"] += 1
            is_worker = False
        if not is_client and not is_worker:
            if r.get("isSystemUser"):
                SKIP["individual: login account that created no imported record"] += 1
            else:
                if key in any_link:
                    SKIP["individual: member / beneficiary only of records outside a resolved campaign"] += 1
                else:
                    SKIP["individual: no member or beneficiary link at all"] += 1
            continue
        rid = fid(key)
        ids = digit_ids("individual", r)
        hn = human_name(r.get("name"))
        if is_worker:
            for k, s in (("userUuid", "user-uuid"), ("userId", "user-id")):
                i = ident(s, r.get(k))
                if i:
                    ids.append(i)
            un = (r.get("userDetails") or {}).get("username")
            if un:
                ids.append(ident("username", un))
            pr = {"resourceType": "Practitioner", "id": rid, "meta": meta(), "identifier": ids,
                  "active": bool(r.get("isSystemUserActive")) and not r.get("isDeleted")}
            if hn:
                pr["name"] = [hn]
            tel = telecom(r)
            if tel:
                pr["telecom"] = tel
            g = GENDER.get(r.get("gender"))
            if g:
                pr["gender"] = g
            quals = []
            for s in r.get("skills") or []:
                if s.get("type") and not s.get("isDeleted") and s["type"] not in quals:
                    quals.append(s["type"])
            if quals:
                pr["qualification"] = [{"code": {"text": q}} for q in quals]
            out.write(pr)
            users[r["userUuid"]] = rid
            if not is_client:
                continue
            ids = digit_ids("individual", r)
        # beneficiary -> ICRPatient
        others, ubi = [], None
        for i in r.get("identifiers") or []:
            if i.get("isDeleted") or not i.get("identifierId"):
                continue
            t = (i.get("identifierType") or "OTHER")
            if t == "UNIQUE_BENEFICIARY_ID" and not ubi:
                ubi = i["identifierId"]
            else:
                others.append(ident("individual-identifier-" + re.sub(r"[^a-z0-9]+", "-", t.lower()),
                                    i["identifierId"]))
        if r.get("individualId"):
            ids.append({"system": BASE + "/identifiers/registry-id", "value": r["individualId"]})
        if ubi:
            ids.append(ident("beneficiary-id", ubi))
        ids.extend(others)
        pt = {"resourceType": "Patient", "id": rid, "meta": meta("ICRPatient"), "identifier": ids,
              "active": not r.get("isDeleted"),
              "name": [hn] if hn else [{"extension": [{"url": DAR, "valueCode": "unknown"}]}],
              "gender": GENDER.get(r.get("gender"), "unknown")}
        if r.get("gender") not in GENDER:
            NOTE["patient: gender missing -> unknown"] += 1
        bd = dmy_to_date(r.get("dateOfBirth"))
        if bd:
            pt["birthDate"] = bd
        else:
            pt["_birthDate"] = {"extension": [{"url": DAR, "valueCode": "unknown"}]}
            NOTE["patient: dateOfBirth missing/invalid -> data-absent-reason"] += 1
        tel = telecom(r)
        if tel:
            pt["telecom"] = tel
        addrs = []
        for a in r.get("address") or []:
            if a.get("isDeleted"):
                continue
            ad = {"use": "home"}
            lines = [x for x in (a.get("doorNo"), a.get("buildingName"), a.get("street"),
                                 a.get("addressLine1"), a.get("addressLine2"), a.get("landmark")) if x]
            if lines:
                ad["line"] = lines
            if a.get("city"):
                ad["city"] = a["city"]
            if a.get("pincode"):
                ad["postalCode"] = a["pincode"]
            if locality(a):
                ad["text"] = locality(a)
            if len(ad) > 1:
                addrs.append(ad)
        if addrs:
            pt["address"] = addrs
        out.write(pt)
        patients[key] = date.fromisoformat(bd) if bd else None
    return patients, users


# ------------------------------------------------------------------ households
# ------------------------------------------------------------------ campaign linkage
class Linkage:
    """Decides what is imported: only records that trace to a root project emitted as an ICRCampaign.

    clients  = individuals who are a beneficiary (project_beneficiary) in a resolved campaign, or a
               member of a household linked to one;
    creators = userUuids that created / performed an imported record (households, registrations,
               tasks, stock, referrals)."""

    PB_KEYS = ("id", "projectId", "beneficiaryClientReferenceId", "tag", "dateOfRegistration")

    def __init__(self, raw, prj, campaigns):
        def camp(pid):
            if pid not in prj.P:
                return None
            r = prj.root(pid)
            return r if r and fid(r) in campaigns else None
        self.camp = camp
        self.PB = {}
        pb_ok = []
        for b in rows(raw + "/project_beneficiary.ndjson"):
            slim = {k: b.get(k) for k in self.PB_KEYS}
            cad, ad = b.get("clientAuditDetails") or {}, b.get("auditDetails") or {}
            slim["clientAuditDetails"] = {"createdTime": cad.get("createdTime"), "createdBy": cad.get("createdBy")}
            slim["by"] = (cad.get("createdBy"), ad.get("createdBy"))
            slim["auditDetails"] = {"createdTime": ad.get("createdTime")}
            self.PB[b["clientReferenceId"]] = slim
            if camp(b.get("projectId")):
                pb_ok.append(slim)
        self.H = {}
        hh_proj = {}
        for h in rows(raw + "/household.ndjson"):
            a = h.get("address") or {}
            self.H[h["clientReferenceId"]] = {"id": h["id"], "loc": locality(a), "pos": position(a),
                                              "n": h.get("memberCount"), "del": h.get("isDeleted"),
                                              "type": h.get("householdType"), "rec": h,
                                              "by": ((h.get("clientAuditDetails") or {}).get("createdBy"),
                                                     (h.get("auditDetails") or {}).get("createdBy"))}
            hh_proj[h["clientReferenceId"]] = afields(h).get("projectId")
        self.members = collections.defaultdict(list)
        ind_hh = collections.defaultdict(list)
        member_by = collections.defaultdict(set)
        for m in rows(raw + "/household_member.ndjson"):
            hc = m.get("householdClientReferenceId")
            if hc not in self.H:
                SKIP["household_member: household not exported"] += 1
                continue
            t = norm_ms((m.get("clientAuditDetails") or {}).get("createdTime")) or \
                norm_ms((m.get("auditDetails") or {}).get("createdTime")) or 0
            self.members[hc].append((t, m["id"], m.get("individualClientReferenceId"),
                                     bool(m.get("isHeadOfHousehold")), bool(m.get("isDeleted"))))
            member_by[hc].update(((m.get("clientAuditDetails") or {}).get("createdBy"),
                                  (m.get("auditDetails") or {}).get("createdBy")))
            ind_hh[m.get("individualClientReferenceId")].append(hc)
        self.hh_linked, ben_ind = set(), set()
        for b in pb_ok:
            ben = b.get("beneficiaryClientReferenceId")
            if ben in self.H:
                self.hh_linked.add(ben)
            elif ben:
                ben_ind.add(ben)
        for crid, pid in hh_proj.items():
            if pid and camp(pid):
                self.hh_linked.add(crid)
        for ind in ben_ind:
            self.hh_linked.update(ind_hh.get(ind, ()))
        for crid in self.H:
            if crid not in self.hh_linked:
                SKIP["household: not linked to a resolved campaign"] += 1
                SKIP["household_member: household not linked to a resolved campaign"] += len(self.members.get(crid, ()))
        self.any_link = {b.get("beneficiaryClientReferenceId") for b in self.PB.values()} | set(ind_hh)
        self.clients = set(ben_ind)
        for crid in self.hh_linked:
            for m in self.members.get(crid, ()):
                if m[2]:
                    self.clients.add(m[2])
        cr = self.creators = set()
        # creators: the client-side and server-side createdBy of every imported record
        for crid in self.hh_linked:
            cr.update(self.H[crid]["by"])
            cr.update(member_by.get(crid, ()))
        for b in pb_ok:
            cr.update(b["by"])
        for tr in rows(raw + "/task.ndjson"):
            b = self.PB.get(tr.get("projectBeneficiaryClientReferenceId"))
            if b and camp(tr.get("projectId")):
                ben = b.get("beneficiaryClientReferenceId")
                if ben in self.hh_linked or ben in self.clients:
                    cr.add((tr.get("clientAuditDetails") or {}).get("createdBy"))
                    cr.add((tr.get("auditDetails") or {}).get("createdBy"))
        for st in rows(raw + "/stock.ndjson"):
            if st.get("referenceIdType") == "PROJECT" and camp(st.get("referenceId")):
                cr.add((st.get("clientAuditDetails") or {}).get("createdBy"))
                cr.add((st.get("auditDetails") or {}).get("createdBy"))
                for side in ("sender", "receiver"):
                    if st.get(side + "Type") == "STAFF":
                        cr.add(st.get(side + "Id"))
        for r in rows(raw + "/referral.ndjson"):
            b = self.PB.get(r.get("projectBeneficiaryClientReferenceId"))
            if b and camp(r.get("projectId") or b.get("projectId")) and b.get("beneficiaryClientReferenceId") in self.clients:
                cr.add(r.get("referrerId"))
                cr.add((r.get("clientAuditDetails") or {}).get("createdBy"))
                cr.add((r.get("auditDetails") or {}).get("createdBy"))
                if r.get("recipientType") == "STAFF":
                    cr.add(r.get("recipientId"))
        cr.discard(None)
        cr.discard("")


def write_households(out, B, patients, link):
    H, members = link.H, link.members
    emitted = {}   # hh crid -> {"group": id, "dwelling": loc id or None, "loc": locality loc id or None}
    member_hh = {}
    for crid, h in H.items():
        if crid not in link.hh_linked:
            continue
        gid = fid(crid)
        dwelling = None
        loc_id = fid(h["loc"]) if h["loc"] in B else None
        if h["pos"]:
            dwelling = gid
            d = {"resourceType": "Location", "id": gid, "meta": meta("ICRLocation"),
                 "identifier": [ident("household", h["id"])], "name": f"Dwelling of household {h['id']}",
                 "status": "inactive" if h["del"] else "active",
                 "physicalType": {"coding": [{"system": PHYS, "code": "ho", "display": "House"}]},
                 "type": [cc("icr-location-type-cs", "household", "Household dwelling")],
                 "position": h["pos"]}
            if loc_id:
                d["partOf"] = ref("Location", loc_id)
            elif h["loc"]:
                NOTE["dwelling: household locality boundary not exported (no partOf)"] += 1
            out.write(d)
        home = dwelling or loc_id
        if not home:
            SKIP["household: no coordinates and locality not exported (group-location 1..1)"] += 1
            continue
        g = {"resourceType": "Group", "id": gid, "meta": meta("ICRDeliveryUnit"),
             "identifier": digit_ids("household", h["rec"]),
             "extension": [ext("group-location", valueReference=ref("Location", home))],
             "active": not h["del"], "type": "person", "actual": True,
             "code": cc("icr-group-kind-cs", "community", "Community") if h["type"] == "COMMUNITY"
             else cc("icr-group-kind-cs", "household", "Household")}
        if isinstance(h["n"], int) and h["n"] >= 0:
            g["quantity"] = h["n"]
        elif h["n"] is not None:
            NOTE["household: negative memberCount dropped"] += 1
        mem, heads = [], 0
        for t, mid, icrid, is_head, mdel in sorted(members.get(crid, [])):
            if icrid not in patients:
                SKIP["household_member: individual not in the export"] += 1
                continue
            e = {"entity": ref("Patient", fid(icrid))}
            if is_head:
                code = "head" if heads == 0 else "co-head"
                heads += 1
                e["extension"] = [ext("relationship-to-head", valueCodeableConcept=cc(
                    "icr-household-relationship-cs", code, "Head (reference person)" if code == "head" else "Co-head"))]
            if mdel:
                e["inactive"] = True
            mem.append(e)
            member_hh.setdefault(icrid, crid)
        if mem:
            g["member"] = mem
        out.write(g)
        emitted[crid] = {"group": gid, "dwelling": dwelling, "loc": loc_id}
    return H, emitted, member_hh


# ------------------------------------------------------------------ projects, protocols, activities
class Projects:
    def __init__(self, raw, B):
        self.B = B
        self.P = {p["id"]: p for p in rows(raw + "/project.ndjson")}
        self._root = {}
        roots = {pid for pid, p in self.P.items() if not p.get("parent")}
        camp_nums = {self.P[r].get("referenceID") for r in roots}
        self.camp = {}
        for c in rows(raw + "/campaign.ndjson"):
            if c.get("campaignNumber") in camp_nums:
                c.pop("boundaries", None)
                c.pop("deliveryRules", None)
                self.camp.setdefault(c["campaignNumber"], []).append(c)
        self.roots = sorted(roots)

    def root(self, pid):
        if pid in self._root:
            return self._root[pid]
        p = self.P.get(pid)
        r = None
        if p:
            q, seen = p, set()
            while q and q["id"] not in seen:
                seen.add(q["id"])
                if not q.get("parent"):
                    r = q["id"]
                    break
                q = self.P.get(q["parent"])
            if r is None:
                for x in (p.get("projectHierarchy") or "").split("."):
                    if x in self.P and not self.P[x].get("parent"):
                        r = x
                        break
        self._root[pid] = r
        return r

    def campaign_record(self, rid):
        recs = self.camp.get(self.P[rid].get("referenceID")) or []
        if not recs:
            return None
        recs.sort(key=lambda c: (c.get("projectId") == rid, c.get("status") == "created",
                                 (c.get("auditDetails") or {}).get("lastModifiedTime") or 0), reverse=True)
        return recs[0]

    def ptype(self, rid):
        return (self.P[rid].get("additionalDetails") or {}).get("projectType") or {}

    def cycles(self, rid):
        out = []
        for c in self.ptype(rid).get("cycles") or []:
            try:
                out.append((int(c.get("id")), norm_ms(c.get("startDate")), norm_ms(c.get("endDate")), c))
            except (TypeError, ValueError):
                pass
        return sorted(out, key=lambda x: x[0])

    def rounds(self, rid):
        cy = self.cycles(rid)
        return cy if len(cy) > 1 else []

    def round_id(self, rid, cycle_index=None, t=None):
        rs = self.rounds(rid)
        if not rs:
            return fid(rid)
        try:
            ci = int(cycle_index)
        except (TypeError, ValueError):
            ci = None
        for n, s, e, _ in rs:
            if ci == n:
                return fid(rid, f"-c{n}")
        if t:
            for n, s, e, _ in rs:
                if s and e and s <= t <= e:
                    return fid(rid, f"-c{n}")
        return fid(rid)

    def boundary(self, pid):
        return ((self.P[pid].get("address") or {}).get("boundary"))


def age_ok(cond, months):
    if months is None or not cond:
        return True
    c = cond.replace("&&", "and").replace(" ", "")
    for part in re.split(r"and", c):
        m = re.fullmatch(r"(\d+)(<=|<)age(<=|<)(\d+)", part)
        if m:
            lo, op1, op2, hi = int(m.group(1)), m.group(2), m.group(3), int(m.group(4))
            if not ((months >= lo if op1 == "<=" else months > lo) and (months <= hi if op2 == "<=" else months < hi)):
                return False
            continue
        m = re.fullmatch(r"(\d+)(<=|<)age", part)
        if m:
            lo = int(m.group(1))
            if not (months >= lo if m.group(2) == "<=" else months > lo):
                return False
            continue
        m = re.fullmatch(r"age(>=|>|<=|<|==)(\d+)", part)
        if m:
            v = int(m.group(2))
            if not {">=": months >= v, ">": months > v, "<=": months <= v, "<": months < v, "==": months == v}[m.group(1)]:
                return False
    return True


class Protocols:
    def __init__(self, raw, cat):
        self.cat = cat
        self.recs = []
        self.by_id, self.by_code = {}, {}
        used = set()
        for m in rows(raw + "/mdms_project_type.ndjson"):
            d = m["data"]
            code = d["code"]
            pid = fid(code)
            if pid.lower() in used:
                pid = fid(code, "-" + re.sub(r"[^A-Za-z0-9]", "", str(d.get("id")))[:8])
            used.add(pid.lower())
            rec = {"pid": pid, "code": code, "data": d, "active": m.get("isActive"), "mdms": m}
            self.recs.append(rec)
            self.by_id.setdefault(d.get("id"), rec)
            self.by_code.setdefault(code, rec)
        self.acts = collections.OrderedDict()   # (pid, delivery, pvid) -> info
        for rec in self.recs:
            self.add_config(rec, rec["data"])

    def for_project(self, p):
        rec = self.by_id.get(p.get("projectTypeId")) or self.by_code.get(p.get("projectType"))
        if rec is None:
            NOTE["project type not in MDMS export"] += 1
        return rec

    def add_config(self, rec, ptype):
        """Register activities for every (delivery, product variant) in a project-type config."""
        for cyc in ptype.get("cycles") or []:
            for dl in cyc.get("deliveries") or []:
                for crit in dl.get("doseCriteria") or []:
                    for pv in crit.get("ProductVariants") or []:
                        self.activity(rec, dl.get("id") or 1, pv.get("productVariantId"),
                                      strategy=dl.get("deliveryStrategy"), cond=crit.get("condition"),
                                      qty=pv.get("quantity"), wait=dl.get("mandatoryWaitSinceLastDeliveryInDays"))

    def activity(self, rec, delivery, pvid, strategy=None, cond=None, qty=None, wait=None):
        try:
            delivery = int(delivery)
        except (TypeError, ValueError):
            delivery = 1
        k = (rec["pid"], delivery, pvid)
        a = self.acts.get(k)
        if a is None:
            aid = fid(f"{rec['code']}-d{delivery}-{pvid}")
            a = {"id": aid, "url": BASE + "/ActivityDefinition/" + aid, "rec": rec, "delivery": delivery,
                 "pvid": pvid, "strategy": strategy, "conds": [], "qty": qty, "wait": wait}
            self.acts[k] = a
        if cond and cond not in a["conds"]:
            a["conds"].append(cond)
        if strategy and not a["strategy"]:
            a["strategy"] = strategy
        return a

    def expected(self, ptype, cycle_index, months):
        """Product variants a person should have received at delivery 1 of a cycle (for not-done events)."""
        cycles = ptype.get("cycles") or []
        cyc = None
        for c in cycles:
            if str(c.get("id")) == str(cycle_index):
                cyc = c
        cyc = cyc or (cycles[0] if cycles else None)
        if not cyc or not cyc.get("deliveries"):
            return [], None
        dl = cyc["deliveries"][0]
        crits = dl.get("doseCriteria") or []
        if not crits:
            return [], dl
        pick = None
        for c in crits:
            if age_ok(c.get("condition"), months):
                pick = c
                break
        if pick is None:
            NOTE["not-done: no dose criterion matched the age; first criterion used"] += 1
            pick = crits[0]
        return [pv.get("productVariantId") for pv in pick.get("ProductVariants") or []], dl

    def write(self, out):
        verbs = {"vaccine": "Vaccinate", "drug": "Treat", "commodity": "Distribute", None: "Deliver"}
        by_pid = collections.defaultdict(list)
        for a in self.acts.values():
            by_pid[a["rec"]["pid"]].append(a)
            rec, cat = a["rec"], self.cat
            kind = cat.kind(a["pvid"])
            ad = {"resourceType": "ActivityDefinition", "id": a["id"], "meta": meta("ICRCampaignActivity"),
                  "url": a["url"], "identifier": [ident("product-variant", a["pvid"])],
                  "name": re.sub(r"[^A-Za-z0-9_]", "", "DigitDemo_" + a["id"].replace("-", "_"))[:254],
                  "title": f"{verbs[kind]}: {cat.label(a['pvid'])}, delivery {a['delivery']} ({rec['code']})",
                  "status": "active" if rec["active"] else "retired", "kind": "Task",
                  "code": {"text": verbs[kind]}, "topic": [ct_cc(rec["code"])],
                  "productCodeableConcept": cat.code(a["pvid"])}
            tp = rec["data"].get("taskProcedure")
            if tp:
                ad["description"] = " ".join(tp)
            if a["qty"] is not None:
                ad["quantity"] = dict({"value": a["qty"]}, **cat.unit(a["pvid"]))
            dtext = []
            if a["strategy"]:
                dtext.append(f"DIGIT delivery strategy {a['strategy']}"
                             + (" (directly observed)" if a["strategy"] == "DIRECT" else ""))
            if a["conds"]:
                dtext.append("dose criteria: " + "; ".join(a["conds"]))
            if dtext:
                ad["dosage"] = [{"text": ", ".join(dtext)}]
            out.write(ad)
        for rec in self.recs:
            d = rec["data"]
            pd = {"resourceType": "PlanDefinition", "id": rec["pid"], "meta": meta("ICRCampaignProtocol"),
                  "url": BASE + "/PlanDefinition/" + rec["pid"],
                  "identifier": [i for i in (ident("project-type", d.get("id")), ident("project-type-code", rec["code"])) if i],
                  "extension": [H2H],
                  "name": re.sub(r"[^A-Za-z0-9_]", "", "DigitDemo_" + rec["code"].replace("-", "_")),
                  "title": f"{d.get('name') or rec['code']} ({rec['code']})",
                  "status": "active" if rec["active"] else "retired", "type": ct_cc(rec["code"])}
            desc = []
            if d.get("beneficiaryType"):
                desc.append(f"Beneficiary type: {d['beneficiaryType']}.")
            if d.get("observationStrategy"):
                desc.append(f"Observation strategy: {d['observationStrategy']}.")
            if d.get("eligibilityCriteria"):
                desc.append("Eligibility: " + " ".join(d["eligibilityCriteria"]))
            if desc:
                pd["description"] = " ".join(desc)
            if d.get("validMinAge") is not None or d.get("validMaxAge") is not None:
                gid = fid(rec["pid"][4:], "-eligible")
                rng = {}
                if d.get("validMinAge") is not None:
                    rng["low"] = {"value": d["validMinAge"], "unit": "months", "system": "http://unitsofmeasure.org", "code": "mo"}
                if d.get("validMaxAge") is not None:
                    rng["high"] = {"value": d["validMaxAge"], "unit": "months", "system": "http://unitsofmeasure.org", "code": "mo"}
                out.write({"resourceType": "Group", "id": gid, "meta": meta(), "type": "person", "actual": False,
                           "name": f"Eligible population, {rec['code']} (DIGIT validMinAge/validMaxAge)",
                           "characteristic": [{"code": {"coding": [coding("icr-group-characteristic-cs", "age-band", "Age band")]},
                                               "valueRange": rng, "exclude": False}]})
                pd["subjectReference"] = ref("Group", gid)
            actions, first_of = [], {}
            for a in sorted(by_pid.get(rec["pid"], []), key=lambda a: (a["delivery"], a["pvid"] or "")):
                aid = f"d{a['delivery']}-{len(actions) + 1}"
                act = {"id": aid, "title": f"Delivery {a['delivery']}: {self.cat.label(a['pvid'])}",
                       "definitionCanonical": a["url"]}
                if a["conds"]:
                    act["condition"] = [{"kind": "applicability", "expression": {
                        "language": "text/x-digit-condition", "expression": " or ".join(f"({c})" for c in a["conds"]),
                        "description": "DIGIT dose-criterion expression, carried as text (not computable)"}}]
                prev = first_of.get(a["delivery"] - 1)
                if prev and a["wait"]:
                    act["relatedAction"] = [{"actionId": prev, "relationship": "after-end",
                                             "offsetDuration": {"value": a["wait"], "unit": "days",
                                                                "system": "http://unitsofmeasure.org", "code": "d"}}]
                first_of.setdefault(a["delivery"], aid)
                actions.append(act)
            if actions:
                pd["action"] = actions
            out.write(pd)


# ------------------------------------------------------------------ targets and campaigns
def write_targets(out, prj, B, protos):
    """Each project's targets[] -> ICRTargetPopulation Groups. Returns root id -> {btype: group id}."""
    root_targets = collections.defaultdict(dict)
    seen_tp = set()
    for pid, p in prj.P.items():
        r = prj.root(pid)
        if r is None:
            continue
        bcode = prj.boundary(pid)
        is_root = pid == r
        if bcode not in B and not is_root:
            for t in p.get("targets") or []:
                SKIP["project target: boundary not exported (child project)"] += 1
            continue
        for t in p.get("targets") or []:
            if t.get("isDeleted"):
                continue
            bt = t.get("beneficiaryType") or "INDIVIDUAL"
            unit = "household" if bt == "HOUSEHOLD" else "person"
            place = boundary_name(bcode) if bcode else "unknown area"
            for field, dtype, suffix, label in (("targetNo", "at-risk", "-target", "targeted"),
                                                ("totalNo", "total-population", "-baseline", "in total")):
                n = t.get(field)
                if not isinstance(n, (int, float)) or n <= 0:
                    continue
                gid = fid(t["id"], suffix)
                if gid in seen_tp:   # the same DIGIT target id is copied onto several projects
                    gid = fid(f"{t['id']}-{pid}", suffix)
                    NOTE["project target id shared by several projects: id includes the project id"] += 1
                seen_tp.add(gid)
                g = {"resourceType": "Group", "id": gid, "meta": meta("ICRTargetPopulation"),
                     "identifier": [ident("project-target", t["id"]), ident("project", pid)],
                     "type": "person", "actual": False,
                     "extension": [ext("denominator-source", valueCodeableConcept=cc("icr-denominator-source-cs", "unknown", "Unknown")),
                                   ext("denominator-type", valueCode=dtype)],
                     "name": f"{p.get('name')}: {unit}s {label}, {place}", "quantity": int(n)}
                if dtype == "at-risk":
                    g["extension"].append(ext("is-planning-denominator", valueBoolean=True))
                if unit == "household":
                    g["modifierExtension"] = [ext("unit-of-count", valueCode="household")]
                if bcode in B:
                    g["characteristic"] = [{"code": {"coding": [coding("icr-group-characteristic-cs", "geography", "Geographic scope")]},
                                            "exclude": False, "valueReference": ref("Location", fid(bcode))}]
                else:
                    NOTE["root project target: boundary not exported (Group without geography)"] += 1
                out.write(g)
                if is_root and dtype == "at-risk":
                    root_targets[r].setdefault(bt, g["id"])
    return root_targets


def campaign_status(prj, rid):
    rec = prj.campaign_record(rid)
    if rec and rec.get("status") in ("drafted", "creating"):
        return "draft"
    p = prj.P[rid]
    end = norm_ms(p.get("endDate")) or norm_ms((rec or {}).get("endDate"))
    if end and end < AS_OF_MS:
        return "completed"
    return "active"


DETAIL_STATUS = {"draft": "not-started", "active": "in-progress", "completed": "completed"}


def write_campaigns(out, prj, B, protos, root_targets, used_roots):
    written = set()
    for rid in prj.roots:
        p = prj.P[rid]
        rec = protos.for_project(p)
        if rec is None:
            SKIP["root project: project type not exported"] += 1
            continue
        crec = prj.campaign_record(rid)
        status = campaign_status(prj, rid)
        start = norm_ms(p.get("startDate")) or norm_ms((crec or {}).get("startDate"))
        end = norm_ms(p.get("endDate")) or norm_ms((crec or {}).get("endDate"))
        if not start:
            SKIP["root project: no start date (CarePlan.period 1..1)"] += 1
            continue
        tg = root_targets.get(rid, {})
        bt = prj.ptype(rid).get("beneficiaryType") or rec["data"].get("beneficiaryType") or "INDIVIDUAL"
        subj = tg.get(bt) or next(iter(tg.values()), None)
        if subj is None:
            SKIP["root project: no target to use as CarePlan.subject (1..1)"] += 1
            continue
        ids = [ident("project", rid), ident("project-number", p.get("projectNumber"))]
        if crec:
            ids += [ident("campaign-number", crec.get("campaignNumber")), ident("campaign", crec.get("id"))]
        elif p.get("referenceID"):
            ids.append(ident("campaign-number", p["referenceID"]))
        ids = [i for i in ids if i]
        # activities this campaign delivers, from the project's own copy of its project type
        acts = collections.OrderedDict()
        for n, s, e, cyc in prj.cycles(rid):
            for dl in cyc.get("deliveries") or []:
                for crit in dl.get("doseCriteria") or []:
                    for pv in crit.get("ProductVariants") or []:
                        a = protos.activity(rec, dl.get("id") or 1, pv.get("productVariantId"),
                                            strategy=dl.get("deliveryStrategy"), cond=crit.get("condition"),
                                            qty=pv.get("quantity"))
                        acts.setdefault(a["url"], set()).add(n)
        title = (crec or {}).get("campaignName") or p.get("name") or rid
        exts = []
        if prj.boundary(rid) in B:
            exts.append(ext("target-geography", valueReference=ref("Location", fid(prj.boundary(rid)))))
        exts.append(ext("planning-denominator", valueReference=ref("Group", subj)))

        def careplan(cid, title, period, round_n=None, acts_for=None):
            cp = {"resourceType": "CarePlan", "id": cid, "meta": meta("ICRCampaign"), "identifier": ids,
                  "extension": list(exts), "instantiatesCanonical": [BASE + "/PlanDefinition/" + rec["pid"]],
                  "status": status, "intent": "plan" if status == "draft" else "order", "title": title,
                  "category": [ct_cc(rec["code"])], "subject": ref("Group", subj), "period": period}
            if p.get("description"):
                cp["description"] = p["description"]
            if round_n:
                cp["extension"].insert(0, ext("campaign-round", valuePositiveInt=round_n))
                cp["partOf"] = [ref("CarePlan", fid(rid))]
            details = []
            for url, cycles in acts.items():
                if acts_for is not None and acts_for not in cycles:
                    continue
                details.append({"detail": {"extension": [ext("planning-denominator", valueReference=ref("Group", subj))],
                                           "instantiatesCanonical": [url], "status": DETAIL_STATUS[status]}})
            if details:
                cp["activity"] = details
            out.write(cp)
            written.add(cid)

        period = {"start": ms_to_dt(start)}
        if end:
            period["end"] = ms_to_dt(end)
        careplan(fid(rid), title, period)
        for n, s, e, cyc in prj.rounds(rid):
            per = {"start": ms_to_dt(s or start)}
            if e or end:
                per["end"] = ms_to_dt(e or end)
            careplan(fid(rid, f"-c{n}"), f"{title}, cycle {n}", per, round_n=n, acts_for=n)
    return written


# ------------------------------------------------------------------ tasks
SUCCESS = {"ADMINISTRATION_SUCCESS", "DELIVERED"}
MISSED = {"ADMINISTRATION_FAILED", "NOT_ADMINISTERED", "BENEFICIARY_ABSENT", "BENEFICIARY_MIGRATED"}


def reason_for(status, af):
    """-> (task output slice, CodeableConcept) for a not-given outcome."""
    if status == "BENEFICIARY_ABSENT" or status == "CLOSED_HOUSEHOLD":
        return "missed-reason", cc("icr-missed-reason-cs", "absent", "Absent")
    if status == "BENEFICIARY_MIGRATED":
        return "missed-reason", cc("icr-missed-reason-cs", "other", "Other", text="Moved away (DIGIT BENEFICIARY_MIGRATED)")
    if status == "ADMINISTRATION_FAILED":
        r = (af.get("reason") or "").upper()
        if r in ("ABSENCE", "ABSENT"):
            return "missed-reason", cc("icr-missed-reason-cs", "absent", "Absent", text="Administration failed: absent")
        if r in ("REFUSED", "REFUSAL"):
            return "missed-reason", cc("icr-missed-reason-cs", "refusal", "Refusal", text="Administration failed: refused")
        return "missed-reason", cc("icr-missed-reason-cs", "other", "Other", text="Administration failed (DIGIT ADMINISTRATION_FAILED)")
    if status == "NOT_ADMINISTERED":
        return "missed-reason", cc("icr-missed-reason-cs", "other", "Other", text="Not administered (DIGIT NOT_ADMINISTERED)")
    if status == "BENEFICIARY_REFUSED":
        return "noncompliance-reason", cc("icr-noncompliance-reason-cs", "other", "Other",
                                          text="Refused, reason not recorded (DIGIT BENEFICIARY_REFUSED)")
    if status == "INELIGIBLE":
        return "exclusion-reason", cc("icr-exclusion-reason-cs", "other", "Other contraindication",
                                      text="Ineligible at the DIGIT eligibility checklist (INELIGIBLE)")
    if status == "BENEFICIARY_DIED":
        return "exclusion-reason", cc("icr-exclusion-reason-cs", "other", "Other contraindication",
                                      text="Beneficiary died (DIGIT BENEFICIARY_DIED)")
    return None, None


OUT_DISPLAY = {"missed-reason": "Missed reason", "noncompliance-reason": "Refusal reason",
               "exclusion-reason": "Exclusion reason"}


def months_between(bd, t_ms):
    if not bd or not t_ms:
        return None
    d = datetime.fromtimestamp(t_ms / 1000, tz=timezone.utc).date()
    m = (d.year - bd.year) * 12 + (d.month - bd.month) - (1 if d.day < bd.day else 0)
    return m if m >= 0 else None


def build_visits(raw, prj, B, protos, cat, patients, users, hh_emitted, member_hh, H, window_ms, campaigns, PB):
    groups = collections.defaultdict(list)

    def resolve_project(pid, what):
        if pid not in prj.P:
            SKIP[f"{what}: projectId is a template placeholder" if str(pid).startswith("{{") else f"{what}: project not exported"] += 1
            return None
        r = prj.root(pid)
        if r is None:
            SKIP[f"{what}: project's root project not exported"] += 1
            return None
        if fid(r) not in campaigns:
            SKIP[f"{what}: root project not emitted as a campaign"] += 1
            return None
        return r

    def resolve_ben(ben, what):
        if ben in hh_emitted:
            return ben, None
        if ben in patients:
            hh = member_hh.get(ben)
            return (hh if hh in hh_emitted else None), ben
        if ben in H:
            SKIP[f"{what}: beneficiary household not emitted"] += 1
        else:
            SKIP[f"{what}: beneficiary (household or individual) not exported"] += 1
        return None, None

    # registrations
    for crid, b in PB.items():
        r = resolve_project(b.get("projectId"), "project_beneficiary")
        if not r:
            continue
        hh, person = resolve_ben(b.get("beneficiaryClientReferenceId"), "project_beneficiary")
        if not hh and not person:
            continue
        t = norm_ms(b.get("dateOfRegistration")) or norm_ms((b.get("clientAuditDetails") or {}).get("createdTime")) \
            or norm_ms((b.get("auditDetails") or {}).get("createdTime")) or 0
        worker = (b.get("clientAuditDetails") or {}).get("createdBy") or ""
        rnd = prj.round_id(r, None, t)
        key = (rnd, hh or ("p:" + person), worker)
        groups[key].append({"kind": "reg", "t": t, "crid": crid, "id": b["id"], "root": r, "hh": hh,
                            "person": person, "tag": b.get("tag"),
                            "ben_is_hh": person is None})
    # tasks
    for tr in rows(raw + "/task.ndjson"):
        r = resolve_project(tr.get("projectId"), "task")
        if not r:
            continue
        b = PB.get(tr.get("projectBeneficiaryClientReferenceId"))
        if b is None:
            SKIP["task: project beneficiary not exported"] += 1
            continue
        hh, person = resolve_ben(b.get("beneficiaryClientReferenceId"), "task")
        if not hh and not person:
            continue
        af = afields(tr)
        cad = tr.get("clientAuditDetails") or {}
        t = norm_ms(cad.get("createdTime")) or norm_ms(tr.get("actualStartDate")) or \
            norm_ms((tr.get("auditDetails") or {}).get("createdTime")) or 0
        worker = cad.get("createdBy") or ""
        rnd = prj.round_id(r, af.get("cycleIndex"), t)
        a = tr.get("address") or {}
        key = (rnd, hh or ("p:" + person), worker)
        groups[key].append({"kind": "task", "t": t, "crid": tr.get("clientReferenceId") or tr["id"], "id": tr["id"],
                            "root": r, "hh": hh, "person": person, "status": tr.get("status"), "af": af,
                            "res": [x for x in (tr.get("resources") or []) if not x.get("isDeleted")],
                            "loc": locality(a), "end": norm_ms(tr.get("actualEndDate"))})
    visits = []
    for key, rs in groups.items():
        rs.sort(key=lambda x: (x["t"], x["crid"]))
        cur, last = [], None
        for x in rs:
            if cur and x["t"] - last > window_ms:
                visits.append((key, cur))
                cur = []
            cur.append(x)
            last = x["t"]
        if cur:
            visits.append((key, cur))
    return visits


def emit_visits(out, visits, prj, B, protos, cat, patients, users, hh_emitted):
    stats = collections.Counter()
    for (rnd, unit, worker), rs in visits:
        first = rs[0]
        root = first["root"]
        vid = fid("visit-" + first["crid"])
        hh = first["hh"]
        prec = protos.for_project(prj.P[root])
        ptype = prj.ptype(root) or prec["data"]
        wref = ref("Practitioner", users[worker]) if worker in users else None
        if not wref:
            NOTE["visit: worker not exported as a Practitioner (no requester/performer)"] += 1
        # where the visit happened
        loc_id = None
        if hh and hh_emitted[hh]["dwelling"]:
            loc_id = hh_emitted[hh]["dwelling"]
        if not loc_id:
            for x in rs:
                if x.get("loc") in B:
                    loc_id = fid(x["loc"])
                    break
        if not loc_id and hh:
            loc_id = hh_emitted[hh]["loc"]
        if not loc_id and prj.boundary(root) in B:
            loc_id = fid(prj.boundary(root))
        if not loc_id:
            SKIP["visit: no resolvable location (Task.location 1..1)"] += len(rs)
            continue
        events, treated, acts_used = [], collections.defaultdict(set), set()
        reasons = []   # (slice, cc)
        referred = 0
        statuses = []
        ident_list = []
        reg_people, reg_hh, vouchers = set(), False, []
        kinds = set()
        for x in rs:
            if x["kind"] == "reg":
                ident_list += [ident("project-beneficiary", x["id"]), ident("project-beneficiary-client-ref", x["crid"])]
                if x["ben_is_hh"]:
                    reg_hh = True
                elif x["person"]:
                    reg_people.add(x["person"])
                if x.get("tag"):
                    vouchers.append(x["tag"])
                continue
            ident_list += [ident("task", x["id"]), ident("task-client-ref", x["crid"])]
            st = x["status"]
            statuses.append(st)
            af = x["af"]
            when = ms_to_dt(x["t"])
            person = x["person"]
            subj = ("Patient", fid(person)) if person else ("Group", hh_emitted[hh]["group"])
            dose = af.get("doseIndex")
            try:
                dose = int(dose)
                if dose < 1:
                    dose = 1
            except (TypeError, ValueError):
                dose = 1
            strategy = af.get("deliveryStrategy")

            def event(pvid, status, n, reason=None, qty=None, rid=None):
                kind = cat.kind(pvid)
                if kind is None:
                    SKIP["delivery event: product variant not exported"] += 1
                    return
                a = protos.activity(prec, dose if status == "completed" else 1, pvid)
                strat = strategy or a["strategy"]
                common_ext = [REC_ORIGIN, ext("campaign", valueReference=ref("CarePlan", rnd)),
                              ext("campaign-activity", valueCanonical=a["url"])]
                ids = [ident("task", x["id"]), ident("task-client-ref", x["crid"])]
                if rid:
                    ids += [i for i in (ident("task-resource", rid[0]), ident("task-resource-client-ref", rid[1])) if i]
                base_id = (rid[1] or rid[0]) if rid else None
                unit = cat.unit(pvid)
                if kind == "commodity":
                    if status != "completed":
                        return
                    sd = {"resourceType": "SupplyDelivery", "id": fid(base_id or x["crid"], "" if base_id else f"-e{n}"),
                          "meta": meta("ICRSupplyDistribution"), "identifier": ids,
                          "extension": common_ext + [ext("distribution-recipient", valueReference=ref(
                              "Group", hh_emitted[hh]["group"]) if hh else ref("Patient", fid(person)))],
                          "status": "completed",
                          "suppliedItem": {"quantity": dict({"value": qty if qty is not None else 1}, **unit),
                                           "itemCodeableConcept": cat.code(pvid)},
                          "occurrenceDateTime": when, "destination": ref("Location", loc_id)}
                    if person:
                        sd["patient"] = ref("Patient", fid(person))
                    if wref:
                        sd["supplier"] = wref
                    events.append(sd)
                    acts_used.add(a["url"])
                    kinds.add(kind)
                    return
                if kind == "vaccine":
                    if not person:
                        SKIP["delivery event: vaccine for a household beneficiary (Immunization.patient)"] += 1
                        return
                    im = {"resourceType": "Immunization", "id": fid(base_id or x["crid"], "" if base_id else f"-e{n}"),
                          "meta": meta("ICRImmunizationEvent"), "identifier": ids, "extension": common_ext,
                          "status": status, "vaccineCode": cat.code(pvid), "patient": ref("Patient", fid(person)),
                          "occurrenceDateTime": when, "location": ref("Location", loc_id)}
                    if reason:
                        im["statusReason"] = reason
                    if status == "completed":
                        if qty is not None:
                            im["doseQuantity"] = dict({"value": qty}, **unit)
                        im["protocolApplied"] = [{"doseNumberPositiveInt": dose}]
                    if wref:
                        im["performer"] = [{"actor": wref}]
                    events.append(im)
                    if status == "completed":
                        treated[a["url"]].add(person)
                    acts_used.add(a["url"])
                    kinds.add(kind)
                    return
                for suffix, code in cat.components(pvid):
                    ma = {"resourceType": "MedicationAdministration",
                          "id": fid(base_id or x["crid"], suffix if base_id else f"-e{n}{suffix}"),
                          "meta": meta("ICRMedicationAdministration"), "identifier": ids,
                          "extension": list(common_ext), "status": status, "medicationCodeableConcept": code,
                          "subject": ref(*subj), "effectiveDateTime": when}
                    if strat in ("DIRECT", "INDIRECT"):
                        ma["extension"].append(ext("directly-observed-consumption", valueBoolean=strat == "DIRECT"))
                    if reason:
                        ma["statusReason"] = [reason]
                    if wref:
                        ma["performer"] = [{"actor": wref}]
                    if status == "completed" and qty is not None and not suffix:
                        ma["dosage"] = {"dose": dict({"value": qty}, **unit)}
                    events.append(ma)
                if status == "completed" and person:
                    treated[a["url"]].add(person)
                acts_used.add(a["url"])
                kinds.add(kind)

            if st in SUCCESS or st == "BENEFICIARY_REFERRED":
                if st == "BENEFICIARY_REFERRED":
                    referred += 1
                if not x["res"]:
                    NOTE[f"task {st} with no resources (no event)"] += 1
                for i, rsrc in enumerate(x["res"]):
                    event(rsrc.get("productVariantId"), "completed", i, qty=rsrc.get("quantity"),
                          rid=(rsrc.get("id"), rsrc.get("clientReferenceId")))
                    if not rsrc.get("isDelivered"):
                        NOTE["resource isDelivered=false on a success status (status decides: completed)"] += 1
            elif st in MISSED or st in ("BENEFICIARY_REFUSED", "INELIGIBLE"):
                sl, rcc = reason_for(st, af)
                reasons.append((sl, rcc))
                pvids = [rsrc.get("productVariantId") for rsrc in x["res"]]
                if not pvids:
                    months = months_between(patients.get(person), x["t"]) if person else None
                    pvids, _ = protos.expected(ptype, af.get("cycleIndex"), months)
                if not pvids:
                    NOTE["not-done: no product could be determined (no event)"] += 1
                for i, pv in enumerate(pvids):
                    if cat.kind(pv) == "commodity":
                        NOTE["not-done commodity: no event, reason on the Task"] += 1
                        continue
                    event(pv, "not-done", i, reason=rcc)
            elif st == "BENEFICIARY_DIED":
                reasons.append(reason_for(st, af))
            elif st == "CLOSED_HOUSEHOLD":
                reasons.append(reason_for(st, af))
            elif st == "VISITED":
                if x["res"]:
                    NOTE["VISITED task resources ignored (reached, no outcome)"] += len(x["res"])
            else:
                NOTE[f"unmapped task status {st}"] += 1
        task_rows = [x for x in rs if x["kind"] == "task"]
        if not task_rows:
            status, code = "completed", "Register household"
        elif all(s == "CLOSED_HOUSEHOLD" for s in statuses):
            status, code = "failed", "Household visit (household closed)"
        else:
            status = "completed"
            code = "Distribute" if kinds == {"commodity"} else ("Administer" if kinds else "Household visit")
        for_ref = ref("Group", hh_emitted[hh]["group"]) if hh else ref("Patient", fid(first["person"]))
        if not hh:
            NOTE["visit for an individual with no household: Task.for = Patient"] += 1
        tend = max(x["t"] for x in rs)
        task = {"resourceType": "Task", "id": vid, "meta": meta("ICRCampaignTask"),
                "identifier": [i for i in ident_list if i], "extension": [H2H, ORIGIN],
                "status": status, "intent": "order", "code": {"text": code},
                "basedOn": [ref("CarePlan", rnd)], "for": for_ref, "location": ref("Location", loc_id),
                "executionPeriod": {"start": ms_to_dt(first["t"]), "end": ms_to_dt(tend)},
                "authoredOn": ms_to_dt(first["t"])}
        if wref:
            task["requester"] = wref
        if len(acts_used) == 1:
            task["instantiatesCanonical"] = next(iter(acts_used))
        outputs = []
        if treated:
            if len(acts_used) == 1:
                outputs.append({"type": out_type("treated-count", "Persons treated / vaccinated (scalar tally)"),
                                "valueUnsignedInt": len(next(iter(treated.values())))})
            else:
                for url in sorted(treated):
                    outputs.append({"extension": [ext("campaign-activity", valueCanonical=url)],
                                    "type": out_type("treated-count", "Persons treated / vaccinated (scalar tally)"),
                                    "valueUnsignedInt": len(treated[url])})
        seen_r = set()
        for sl, rcc in reasons:
            k = (sl, json.dumps(rcc, sort_keys=True))
            if k in seen_r:
                continue
            seen_r.add(k)
            outputs.append({"type": out_type(sl, OUT_DISPLAY[sl]), "valueCodeableConcept": rcc})
        if referred:
            outputs.append({"type": out_type("referred-count", "Persons referred"), "valueUnsignedInt": referred})
        if reg_people:
            outputs.append({"type": out_type("registered-count", "Persons registered"), "valueUnsignedInt": len(reg_people)})
        if reg_hh and hh:
            outputs.append({"type": out_type("registered-household", "Household registered"),
                            "valueReference": ref("Group", hh_emitted[hh]["group"])})
        if vouchers:
            outputs.append({"type": out_type("voucher", "Voucher issued"),
                            "valueIdentifier": {"system": IDSYS + "voucher/" + fid(root), "value": vouchers[0]}})
            if len(vouchers) > 1:
                NOTE["visit with several vouchers: first kept (voucher 0..1)"] += 1
        written_events = []
        for e in events:
            if out.write(e):
                written_events.append(e)
            else:
                SKIP["delivery event: duplicate id"] += 1
        for e in written_events:
            outputs.append({"type": out_type("delivery-event", "Delivery event reference"),
                            "valueReference": ref(e["resourceType"], e["id"])})
        if outputs:
            task["output"] = outputs
        out.write(task)
        stats["visits"] += 1
        stats["visit rows"] += len(rs)
        stats[f"visit rows={min(len(rs), 10)}"] += 1
    return stats


# ------------------------------------------------------------------ referrals
REFERRAL_REASON = {"FEVER": ("fever", "Fever"), "SUSPECTED_MALARIA": ("suspected-malaria", "Suspected malaria"),
                   "MALNUTRITION": ("acute-malnutrition", "Acute malnutrition"), "OTHER": ("other", "Other")}


def write_referrals(out, raw, prj, patients, users, F, campaigns, PB):
    for r in rows(raw + "/referral.ndjson"):
        b = PB.get(r.get("projectBeneficiaryClientReferenceId"))
        if not b:
            SKIP["referral: project beneficiary not exported"] += 1
            continue
        pid, ben = r.get("projectId") or b.get("projectId"), b.get("beneficiaryClientReferenceId")
        if ben not in patients:
            SKIP["referral: beneficiary is not an exported individual"] += 1
            continue
        root = prj.root(pid) if pid in prj.P else None
        if not root or fid(root) not in campaigns:
            SKIP["referral: project not exported"] += 1
            continue
        t = norm_ms((r.get("clientAuditDetails") or {}).get("createdTime")) or norm_ms((r.get("auditDetails") or {}).get("createdTime"))
        reasons = []
        for x in r.get("reasons") or []:
            code, disp = REFERRAL_REASON.get(str(x).upper(), ("other", "Other"))
            reasons.append(cc("icr-referral-reason-cs", code, disp, text=None if code != "other" or str(x).upper() == "OTHER" else str(x)))
            if str(x).upper() not in REFERRAL_REASON:
                NOTE[f"referral reason {x} -> other"] += 1
        if not reasons:
            reasons = [cc("icr-referral-reason-cs", "other", "Other")]
        sr = {"resourceType": "ServiceRequest", "id": fid(r.get("clientReferenceId") or r["id"]), "meta": meta("ICRReferral"),
              "identifier": digit_ids("referral", r), "status": "active", "intent": "order",
              "category": [cc("icr-referral-category-cs", "campaign-referral", "Campaign referral")],
              "priority": "routine", "subject": ref("Patient", fid(ben)), "basedOn": [ref("CarePlan", prj.round_id(root, None, t))],
              "authoredOn": ms_to_dt(t), "reasonCode": reasons}
        if r.get("referrerId") in users:
            sr["requester"] = ref("Practitioner", users[r["referrerId"]])
        elif r.get("referrerId"):
            sr["requester"] = {"identifier": ident("user-uuid", r["referrerId"]), "display": "DIGIT user (not exported)"}
        rid = r.get("recipientId")
        if r.get("recipientType") == "FACILITY":
            if rid in F:
                sr["performer"] = [ref("Organization", fid(rid))]
                sr["locationReference"] = [ref("Location", fid(rid))]
            elif rid:
                sr["performer"] = [{"identifier": ident("facility", rid), "display": "DIGIT facility (not exported)"}]
        elif rid in users:
            sr["performer"] = [ref("Practitioner", users[rid])]
        elif rid:
            sr["performer"] = [{"identifier": ident("user-uuid", rid), "display": "DIGIT staff member (not exported)"}]
        if r.get("sideEffect"):
            NOTE["referral sideEffect not mapped (no side effects exported)"] += 1
        out.write(sr)


# ------------------------------------------------------------------ stock
def write_stock(out, raw, prj, cat, users, F, campaigns):
    S = list(rows(raw + "/stock.ndjson"))
    pairs = collections.defaultdict(list)
    for s in S:
        if s.get("wayBillNumber"):
            pairs[(s["wayBillNumber"], s.get("productVariantId"), s.get("quantity"), s.get("senderId"), s.get("receiverId"))].append(s)
    partner = {}
    for k, v in pairs.items():
        d = [s for s in v if s.get("transactionType") == "DISPATCHED"]
        r = [s for s in v if s.get("transactionType") == "RECEIVED"]
        if len(d) == 1 and len(r) == 1:
            partner[d[0]["id"]] = r[0]
            partner[r[0]["id"]] = d[0]
    done = set()

    def party(pid, ptype, as_location=False):
        if ptype == "WAREHOUSE" or pid in F:
            if pid in F:
                return ref("Location" if as_location else "Organization", fid(pid))
            return {"identifier": ident("facility", pid), "display": "DIGIT facility (not exported)"} if pid and not as_location else None
        if pid in users:
            return ref("Practitioner", users[pid])
        return {"identifier": ident("user-uuid", pid), "display": "DIGIT staff member (not exported)"} if pid and not as_location else None

    for s in S:
        if s["id"] in done:
            continue
        other = partner.get(s["id"])
        recs = [s] + ([other] if other else [])
        for x in recs:
            done.add(x["id"])
        pid = s.get("referenceId") if s.get("referenceIdType") == "PROJECT" else None
        root = prj.root(pid) if pid in prj.P else None
        if not root or fid(root) not in campaigns:
            SKIP["stock: referenced project not exported"] += 1
            continue
        recv = next((x for x in recs if x.get("transactionType") == "RECEIVED"), None)
        main = recv or s
        t = norm_ms(main.get("dateOfEntry")) or norm_ms((main.get("clientAuditDetails") or {}).get("createdTime"))
        unit = cat.unit(s.get("productVariantId"))
        qty = dict({"value": s.get("quantity")}, **unit)
        ids = []
        for x in recs:
            ids += digit_ids("stock", x)
        if s.get("wayBillNumber"):
            ids.append(ident("waybill", s["wayBillNumber"]))
        sd = {"resourceType": "SupplyDelivery", "id": fid(main.get("clientReferenceId") or main["id"]),
              "meta": meta("ICRSupplyMovement"), "identifier": ids,
              "extension": [REC_ORIGIN, ext("campaign", valueReference=ref("CarePlan", prj.round_id(root, None, t)))],
              "status": "completed" if recv else "in-progress",
              "suppliedItem": {"quantity": qty, "itemCodeableConcept": cat.code(s.get("productVariantId"))}}
        if t:
            sd["occurrenceDateTime"] = ms_to_dt(t)
        sup = party(s.get("senderId"), s.get("senderType"))
        if sup:
            sd["supplier"] = sup
        if s.get("receiverType") == "STAFF" or (s.get("receiverId") in users):
            rv = party(s.get("receiverId"), "STAFF")
            if rv:
                sd["receiver"] = [rv]
        else:
            dst = party(s.get("receiverId"), s.get("receiverType"), as_location=True)
            if dst:
                sd["destination"] = dst
            elif s.get("receiverId"):
                NOTE["stock: receiving facility not exported (destination empty)"] += 1
        reason = (main.get("transactionReason") or "").upper()
        acct = None
        if reason == "RETURNED":
            acct = "returned"
        elif reason.startswith("LOST") or reason.startswith("DAMAGED"):
            acct = "notUsable"
        if acct:
            sd["extension"].append({"url": BASE + "/StructureDefinition/stock-accountability",
                                    "extension": [{"url": acct, "valueQuantity": qty}]})
        if not other:
            NOTE[f"stock: unpaired {s.get('transactionType')} row (one movement)"] += 1
        else:
            NOTE["stock: DISPATCHED+RECEIVED pair merged"] += 1
        out.write(sd)


# ------------------------------------------------------------------ main
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw", default=os.path.join(os.environ.get("DIGIT_WORK", "work"), "raw"))
    ap.add_argument("--out", default=os.path.join(os.environ.get("DIGIT_WORK", "work"), "out"))
    ap.add_argument("--window-hours", type=float, default=2.0)
    args = ap.parse_args()
    raw = os.path.abspath(args.raw)
    t0 = time.time()

    def step(msg):
        print(f"[{time.time() - t0:7.1f}s] {msg}", flush=True)

    out = Out(os.path.abspath(args.out))
    step("boundaries")
    B = load_boundaries(raw)
    write_boundaries(out, B)
    step("facilities")
    F = write_facilities(out, raw, B)
    cat = Catalog({p["id"]: p for p in rows(raw + "/product.ndjson")},
                  {v["id"]: v for v in rows(raw + "/product_variant.ndjson")})
    step("projects")
    prj = Projects(raw, B)
    protos = Protocols(raw, cat)
    for rid in prj.roots:
        rec = protos.for_project(prj.P[rid])
        if rec:
            protos.add_config(rec, prj.ptype(rid))
    root_targets = write_targets(out, prj, B, protos)
    campaigns = write_campaigns(out, prj, B, protos, root_targets, None)
    step("campaign linkage")
    link = Linkage(raw, prj, campaigns)
    step(f"individuals ({len(link.clients)} linked clients, {len(link.creators)} creator ids)")
    patients, users = write_individuals(out, raw, link.clients, link.creators, link.any_link)
    step("households")
    H, hh_emitted, member_hh = write_households(out, B, patients, link)
    step("grouping tasks into visits")
    visits = build_visits(raw, prj, B, protos, cat, patients, users, hh_emitted, member_hh, H,
                          int(args.window_hours * 3600 * 1000), campaigns, link.PB)
    step(f"emitting {len(visits)} visits")
    vstats = emit_visits(out, visits, prj, B, protos, cat, patients, users, hh_emitted)
    del visits
    step("referrals, stock")
    write_referrals(out, raw, prj, patients, users, F, campaigns, link.PB)
    write_stock(out, raw, prj, cat, users, F, campaigns)
    step("protocols and activities")
    protos.write(out)
    out.close()
    step("done writing")
    report = {"counts": {f"{k[0]} ({k[1]})": v for k, v in sorted(out.counts.items())},
              "skipped": dict(SKIP.most_common()), "notes": dict(NOTE.most_common()),
              "visits": dict(vstats), "duplicate_ids_refused": out.dups,
              "duplicate_ids_by_type": {f"{k[0]} ({k[1]})": v for k, v in out.dup_by.items()},
              "seconds": round(time.time() - t0, 1)}
    with open(os.path.join(os.path.abspath(args.out), "report.json"), "w") as f:
        json.dump(report, f, indent=1)
    print(json.dumps(report, indent=1))


if __name__ == "__main__":
    main()
