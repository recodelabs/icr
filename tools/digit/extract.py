#!/usr/bin/env python3
# Download the DIGIT demo tenant's registries as NDJSON, one file per entity, 1,000 rows a
# page. Resumable: an entity whose file already holds its TotalCount rows is skipped, and a
# partial file continues from its line count. Logs in again on a 401.
#   python3 -I extract.py [entity…]
import json, os, sys, time, urllib.request, urllib.error

HOST = "https://health-demo.digit.org"
OUT = os.environ.get("DIGIT_RAW", os.path.join(os.environ.get("DIGIT_WORK", "work"), "raw"))
# Two DIGIT logins: a DISTRIBUTOR (reads the field registries: tasks, households, stock …) and an
# admin (campaigns, projects, boundaries, products, MDMS). Set them in the environment.
ACCOUNTS = {
    "field": (os.environ.get("DIGIT_FIELD_USER", ""), os.environ.get("DIGIT_FIELD_PASSWORD", "")),
    "admin": (os.environ.get("DIGIT_ADMIN_USER", ""), os.environ.get("DIGIT_ADMIN_PASSWORD", "")),
}
_tokens = {}

def login(acct):
    user, pw = ACCOUNTS[acct]
    data = f"username={user}&password={pw}&userType=EMPLOYEE&scope=read&grant_type=password&tenantId=demo".encode()
    req = urllib.request.Request(HOST + "/user/oauth/token", data,
                                 {"Authorization": "Basic ZWdvdi11c2VyLWNsaWVudDo="})
    _tokens[acct] = json.loads(urllib.request.urlopen(req, timeout=60).read())
    return _tokens[acct]

def call(acct, path, extra, retries=5):
    for attempt in range(retries):
        t = _tokens.get(acct) or login(acct)
        body = {"RequestInfo": {"apiId": "Rainmaker", "msgId": "1|en_IN",
                                "authToken": t["access_token"], "userInfo": t["UserRequest"]}}
        body.update(extra)
        req = urllib.request.Request(HOST + path, json.dumps(body).encode(), {"Content-Type": "application/json"})
        try:
            return json.loads(urllib.request.urlopen(req, timeout=180).read())
        except urllib.error.HTTPError as e:
            if e.code == 401 and attempt == 0:
                login(acct); continue
            if e.code in (500, 502, 503, 504):
                time.sleep(5 * (attempt + 1)); continue
            raise RuntimeError(f"{path}: HTTP {e.code} {e.read()[:200]!r}")
        except (urllib.error.URLError, TimeoutError):
            time.sleep(5 * (attempt + 1))
    raise RuntimeError(f"{path}: gave up after {retries} tries")

# entity: (account, search path, body, response key)
ENTITIES = {
    "household":           ("field", "/household/v1/_search", {"Household": {}}, "Households"),
    "household_member":    ("field", "/household/member/v1/_search", {"HouseholdMember": {}}, "HouseholdMembers"),
    "individual":          ("field", "/individual/v1/_search", {"Individual": {}}, "Individual"),
    "project_beneficiary": ("field", "/project/beneficiary/v1/_search", {"ProjectBeneficiary": {}}, "ProjectBeneficiaries"),
    "task":                ("field", "/project/task/v1/_search", {"Task": {"tenantId": "demo"}}, "Tasks"),
    "referral":            ("field", "/referralmanagement/v1/_search", {"Referral": {}}, "Referrals"),
    "facility":            ("field", "/facility/v1/_search", {"Facility": {}}, "Facilities"),
    "stock":               ("field", "/stock/v1/_search", {"Stock": {"tenantId": "demo"}}, "Stock"),
}

def total_of(d):
    return d.get("TotalCount", d.get("totalCount"))

def pull(name):
    acct, path, extra, key = ENTITIES[name]
    os.makedirs(OUT, exist_ok=True)
    fn = os.path.join(OUT, name + ".ndjson")
    have = sum(1 for _ in open(fn)) if os.path.exists(fn) else 0
    first = call(acct, f"{path}?tenantId=demo&limit=1&offset=0", extra)
    total = total_of(first) or 0
    if have >= total:
        print(f"{name}: complete ({have}/{total})", flush=True); return
    print(f"{name}: {have}/{total}, resuming", flush=True)
    with open(fn, "a") as f:
        off = have
        while off < total:
            d = call(acct, f"{path}?tenantId=demo&limit=1000&offset={off}", extra)
            rows = d.get(key, [])
            if not rows: break
            for r in rows: f.write(json.dumps(r) + "\n")
            off += len(rows); f.flush()
            if (off // 1000) % 20 == 0: print(f"  {name}: {off}/{total}", flush=True)
    print(f"{name}: done {off}/{total}", flush=True)

if __name__ == "__main__":
    for name in (sys.argv[1:] or list(ENTITIES)):
        pull(name)
