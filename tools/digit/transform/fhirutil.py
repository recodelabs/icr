"""Shared helpers: ids, identifiers, codings, time conversion, NDJSON writer."""
import hashlib
import json
import os
import re
from datetime import datetime, timezone

BASE = "https://icr.healthcampaigns.org"
SD = BASE + "/StructureDefinition/"
CS = BASE + "/CodeSystem/"
IDSYS = BASE + "/identifiers/digit-demo/"
PREFIX = "dgt-"

TAG = {"system": CS + "icr-project-tag-cs", "code": "digit-demo", "display": "DIGIT demo"}

_ID_OK = re.compile(r"^[A-Za-z0-9\-\.]{1,64}$")
_BAD = re.compile(r"[^A-Za-z0-9\-\.]")


def fid(raw, suffix=""):
    """Deterministic FHIR id: dgt-<raw><suffix>, invalid characters -> '-', hashed if too long."""
    s = _BAD.sub("-", str(raw))
    out = PREFIX + s + suffix
    if len(out) <= 64 and _ID_OK.match(out):
        return out
    h = hashlib.sha1((str(raw) + "|" + suffix).encode()).hexdigest()[:12]
    keep = 64 - len(PREFIX) - len(suffix) - 13
    return PREFIX + s[:keep] + "-" + h + suffix


def ident(entity, value, use=None):
    if value is None or value == "":
        return None
    d = {"system": IDSYS + entity, "value": str(value)}
    if use:
        d["use"] = use
    return d


def digit_ids(entity, rec):
    """DIGIT server id under <entity>, clientReferenceId under <entity>-client-ref."""
    out = []
    i = ident(entity, rec.get("id"))
    if i:
        out.append(i)
    c = ident(entity + "-client-ref", rec.get("clientReferenceId"))
    if c:
        out.append(c)
    return out


def meta(profile=None):
    m = {"tag": [dict(TAG)]}
    if profile:
        m["profile"] = [SD + profile]
    return m


def coding(cs, code, display=None):
    d = {"system": CS + cs, "code": code}
    if display:
        d["display"] = display
    return d


def cc(cs, code, display=None, text=None):
    d = {"coding": [coding(cs, code, display)]}
    if text:
        d["text"] = text
    return d


def ext(name, **value):
    (k, v), = value.items()
    return {"url": SD + name, k: v}


def ref(rtype, rid):
    return {"reference": f"{rtype}/{rid}"}


def ms_to_dt(ms):
    """Epoch ms (or seconds, if it looks like seconds) -> FHIR dateTime in UTC."""
    if ms is None:
        return None
    try:
        v = float(ms)
    except (TypeError, ValueError):
        return None
    if v <= 0:
        return None
    if v < 1e11:  # seconds
        v *= 1000
    return datetime.fromtimestamp(v / 1000, tz=timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def ms_to_date(ms):
    dt = ms_to_dt(ms)
    return dt[:10] if dt else None


def norm_ms(ms):
    try:
        v = float(ms)
    except (TypeError, ValueError):
        return None
    if v <= 0:
        return None
    if v < 1e11:
        v *= 1000
    return int(v)


def dmy_to_date(s):
    if not s:
        return None
    m = re.match(r"^(\d{1,2})/(\d{1,2})/(\d{4})$", s.strip())
    if not m:
        return None
    d, mo, y = int(m.group(1)), int(m.group(2)), int(m.group(3))
    try:
        datetime(y, mo, d)
    except ValueError:
        return None
    return f"{y:04d}-{mo:02d}-{d:02d}"


DAR = "http://hl7.org/fhir/StructureDefinition/data-absent-reason"


class Out:
    """One NDJSON file per resource type; refuses duplicate ids."""

    def __init__(self, outdir):
        self.dir = outdir
        os.makedirs(outdir, exist_ok=True)
        for f in os.listdir(outdir):
            if f.endswith(".ndjson"):
                os.remove(os.path.join(outdir, f))
        self.fh = {}
        self.ids = {}
        self.counts = {}
        self.dups = 0
        self.dup_by = {}

    def write(self, res):
        rt = res["resourceType"]
        s = self.ids.setdefault(rt, set())
        if res["id"] in s:
            self.dups += 1
            k = (rt, (res.get("meta") or {}).get("profile", ["(base)"])[0].rsplit("/", 1)[-1])
            self.dup_by[k] = self.dup_by.get(k, 0) + 1
            return False
        s.add(res["id"])
        if rt not in self.fh:
            self.fh[rt] = open(os.path.join(self.dir, rt + ".ndjson"), "w")
        self.fh[rt].write(json.dumps(res, separators=(",", ":"), ensure_ascii=False) + "\n")
        prof = (res.get("meta") or {}).get("profile", ["(base)"])[0].rsplit("/", 1)[-1]
        k = (rt, prof)
        self.counts[k] = self.counts.get(k, 0) + 1
        return True

    def close(self):
        for f in self.fh.values():
            f.close()


def rows(path):
    with open(path) as f:
        for line in f:
            if line.strip():
                yield json.loads(line)


def afields(rec):
    af = rec.get("additionalFields") or {}
    return {f.get("key"): f.get("value") for f in (af.get("fields") or []) if isinstance(f, dict)}
