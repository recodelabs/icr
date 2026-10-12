#!/usr/bin/env python3
"""Synthetic polio microplan + monitoring snapshot for Toro LGA, Bauchi.

    python3 build.py [--as-of 2026-09-09] [--seed 42] [--out DIR]

One National Immunization Plus Days (NIPDs, nOPV2) round, September 7–11 2026, frozen
part-way through, built on what the registry already holds for Toro: the health
facilities, their catchments (tools/catchments), the settlements assigned to each
catchment, and the WorldPop 2026 total per settlement catchment (kiln population).

What it writes (NDJSON for tools/hapi/load.py, in load order; every resource tagged
`nga-microplan-demo` so the set can be wiped in one call):

  01-groups.ndjson      ICRTargetPopulation: children 0–59 months per settlement catchment
                        (WorldPop total × Toro's under-5 share) and per facility catchment
                        (sum of its settlements) — the planning denominators
  02-careteams.ndjson   ICRCareTeam: one vaccination team per facility, with its workload target
  03-careplans.ndjson   ICRCampaign: the LGA round, plus one facility-level campaign per
                        facility catchment, partOf the LGA round
  04-tasks.ndjson       ICRCampaignTask: one house-to-house visit per settlement, basedOn its
                        facility's campaign; status and tally outputs as of --as-of
  report.md / tasks.csv the snapshot at a glance

Design (Matt, Sep 9 2026): each facility is a campaign; settlement visits are its Tasks;
no fixed-post facility tally; no coverage MeasureReport (coverage lives on the microplan
page); no failed visits (access is not a challenge in Toro); care teams generated.
Needs `duckdb` on the PATH (reads data/parquet); otherwise stdlib only.
"""
import argparse, csv, datetime as dt, json, math, os, random, subprocess, sys
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
DATA = os.path.join(REPO, "data", "parquet")

BASE = "https://icr.healthcampaigns.org"
SD = f"{BASE}/StructureDefinition"
CS = f"{BASE}/CodeSystem"
TAG = {"system": f"{CS}/icr-project-tag-cs", "code": "nga-microplan-demo",
       "display": "Nigeria microplan demo (Toro LGA NIPDs, September 2026)"}

LGA_ID, LGA_NAME = "nga-ba-5018", "Toro LGA"
LGA_U5_GROUP = "nga-demo-pop-under5-2026-ba-5018"      # campaign-builder's Toro 2026 under-5 denominator
U5_SHARE = 132_118 / 714_152                            # Toro 2026: under-5 ÷ total, NPC 2022 projection
PERSONS_PER_HOUSE = 6.0
PROTOCOL = f"{BASE}/PlanDefinition/nga-demo-proto-nopv2-sia"
ACTIVITY = f"{BASE}/ActivityDefinition/nga-demo-act-nopv2"
ROUND = 2
PERIOD_START, PERIOD_END = dt.date(2026, 9, 7), dt.date(2026, 9, 11)
DAYS = [(PERIOD_START + dt.timedelta(days=i)) for i in range(5)]
DAY_WEIGHTS = [0.22, 0.22, 0.22, 0.17, 0.17]           # share of each facility's settlements per day
FIELD_REGISTERED = 15                                   # unplanned settlements "found" during the round
ROUND_TITLE = "National Immunization Plus Days (NIPDs), round 2, September 2026"

FIRST = ["Aisha", "Fatima", "Hauwa", "Maryam", "Zainab", "Amina", "Hadiza", "Halima", "Safiya", "Rukayya",
         "Musa", "Ibrahim", "Abubakar", "Usman", "Yusuf", "Sani", "Bala", "Danjuma", "Isa", "Garba"]
LAST = ["Abdullahi", "Mohammed", "Adamu", "Umar", "Bello", "Sule", "Yakubu", "Haruna", "Idris", "Dauda",
        "Tanko", "Lawal", "Shehu", "Ahmed", "Aliyu", "Bature", "Maigari", "Sarki", "Wakili", "Gambo"]


def duck(sql):
    out = subprocess.run(["duckdb", "-json", "-c", sql], capture_output=True, text=True, check=True).stdout
    return json.loads(out) if out.strip() else []


def read_registry():
    """Toro facilities with a catchment; every Toro settlement with its facility (by catchment
    assignment, else by point-in-polygon) and its WorldPop 2026 catchment total."""
    sql = f"""
    LOAD spatial;
    CREATE TABLE fc AS SELECT id AS catchment_id, json_extract_string(fhir_json, '$.extension[*].valueReference.reference')[1][10:] AS facility_id, geometry
      FROM read_parquet('{DATA}/locations/country=NGA/geom_type=polygon/type=facility-catchment/*.parquet');
    CREATE TABLE sc AS SELECT id AS catchment_id, json_extract_string(fhir_json, '$.extension[*].valueReference.reference')[1][10:] AS settlement_id, part_of AS facility_catchment
      FROM read_parquet('{DATA}/locations/country=NGA/geom_type=polygon/type=settlement-catchment/*.parquet');
    CREATE TABLE f AS SELECT id, name, replace(facility_level_text, chr(160), ' ') AS level, lon, lat
      FROM read_parquet('{DATA}/locations/country=NGA/geom_type=point/type=facility/*.parquet') WHERE admin2_name = 'Toro' AND admin1_name = 'Bauchi';
    CREATE TABLE s AS SELECT id, name, lon, lat, geometry
      FROM read_parquet('{DATA}/locations/country=NGA/geom_type=point/type=settlement/*.parquet') WHERE admin2_name = 'Toro' AND admin1_name = 'Bauchi';
    CREATE TABLE pop AS SELECT location_id[11:] AS settlement_id, quantity AS worldpop
      FROM read_parquet('{DATA}/target_population/country=NGA/*.parquet')
      WHERE source = 'worldpop' AND travel_time IS NULL AND denominator_type = 'total-population' AND location_id LIKE 'catchment-%';
    SELECT 'facility' AS kind, f.id, f.name, f.level, f.lon, f.lat, fc.catchment_id, NULL AS facility_id, NULL AS planned, NULL AS worldpop
      FROM f JOIN fc ON fc.facility_id = f.id
    UNION ALL
    SELECT 'settlement', s.id, s.name, NULL, s.lon, s.lat, sc.catchment_id,
           coalesce(fc1.facility_id, fc2.facility_id), sc.catchment_id IS NOT NULL, pop.worldpop
      FROM s LEFT JOIN sc ON sc.settlement_id = s.id
             LEFT JOIN fc fc1 ON fc1.catchment_id = sc.facility_catchment
             LEFT JOIN fc fc2 ON sc.catchment_id IS NULL AND ST_Contains(fc2.geometry, s.geometry)
             LEFT JOIN pop ON pop.settlement_id = s.id
    ORDER BY 1, 3;
    """
    rows = duck(sql)
    facilities = {r["id"]: r for r in rows if r["kind"] == "facility"}
    settlements = [r for r in rows if r["kind"] == "settlement" and r["facility_id"] in facilities]
    return facilities, settlements


def km(a, b):
    """Great-circle distance, km."""
    la1, lo1, la2, lo2 = map(math.radians, (a["lat"], a["lon"], b["lat"], b["lon"]))
    h = math.sin((la2 - la1) / 2) ** 2 + math.cos(la1) * math.cos(la2) * math.sin((lo2 - lo1) / 2) ** 2
    return 2 * 6371 * math.asin(math.sqrt(h))


def meta(profile):
    return {"profile": [f"{SD}/{profile}"], "tag": [TAG]}


def ext_ref(url, ref, display=None):
    v = {"reference": ref}
    if display:
        v["display"] = display
    return {"url": f"{SD}/{url}", "valueReference": v}


def u5_group(gid, geography_id, geography_name, quantity, text, calculated):
    return {
        "resourceType": "Group", "id": gid, "meta": meta("ICRTargetPopulation"),
        "extension": [
            {"url": f"{SD}/denominator-source", "valueCodeableConcept": {
                "coding": [{"system": f"{CS}/icr-denominator-source-cs", "code": "worldpop", "display": "WorldPop modelled estimate"}], "text": text}},
            {"url": f"{SD}/denominator-type", "valueCode": "at-risk"},
            {"url": f"{SD}/estimate-date", "valueDate": "2026-01-01"},
            {"url": f"{SD}/is-calculated", "valueBoolean": calculated},
            {"url": f"{SD}/is-planning-denominator", "valueBoolean": True},
        ],
        "type": "person", "actual": False,
        "name": f"Children 0–59 months, {geography_name}, 2026 (planning denominator)",
        "quantity": quantity,
        "characteristic": [
            {"code": {"coding": [{"system": f"{CS}/icr-group-characteristic-cs", "code": "geography", "display": "Geographic scope"}]},
             "valueReference": {"reference": f"Location/{geography_id}", "display": geography_name}, "exclude": False},
            {"code": {"coding": [{"system": f"{CS}/icr-group-characteristic-cs", "code": "age-band", "display": "Age band"}]},
             "valueRange": {"low": {"value": 0, "unit": "months", "system": "http://unitsofmeasure.org", "code": "mo"},
                            "high": {"value": 59, "unit": "months", "system": "http://unitsofmeasure.org", "code": "mo"}},
             "exclude": False},
        ],
    }


def person(rng, role):
    return f"{rng.choice(FIRST)} {rng.choice(LAST)} ({role})"


def careteam(rng, fac, tid, u5, houses, group_id):
    role = lambda code, display: {"coding": [{"system": f"{CS}/icr-team-role-cs", "code": code, "display": display}]}
    return {
        "resourceType": "CareTeam", "id": tid, "meta": meta("ICRCareTeam"),
        "extension": [
            ext_ref("oversees-area", f"Location/{fac['catchment_id']}", f"{fac['name']} catchment"),
            {"url": f"{SD}/workload-target", "extension": [
                {"url": "targetArea", "valueReference": {"reference": f"Location/{fac['catchment_id']}", "display": f"{fac['name']} catchment"}},
                {"url": "targetPopulation", "valueUnsignedInt": u5},
                {"url": "targetHouseholds", "valueUnsignedInt": houses},
                {"url": "targetDays", "valueUnsignedInt": len(DAYS)},
            ]},
        ],
        "status": "active",
        "name": f"{fac['name']} vaccination team",
        "subject": {"reference": f"Group/{group_id}"},
        "participant": [
            {"role": role("vaccinator", "Vaccinator"), "member": {"display": person(rng, "vaccinator")}},
            {"role": role("vaccinator", "Vaccinator"), "member": {"display": person(rng, "vaccinator")}},
            {"role": role("enumerator", "Enumerator"), "member": {"display": person(rng, "recorder")}},
            {"role": role("supervisor", "Supervisor"), "member": {"display": person(rng, "supervisor")}},
        ],
        "managingOrganization": [{"reference": f"Organization/org-{fac['id']}", "display": fac["name"]}],
    }


def careplan(cid, title, description, geography_id, geography_name, group_id, teams, part_of, status, created):
    cp = {
        "resourceType": "CarePlan", "id": cid, "meta": meta("ICRCampaign"),
        "extension": [
            {"url": f"{SD}/campaign-round", "valuePositiveInt": ROUND},
            ext_ref("target-geography", f"Location/{geography_id}", geography_name),
            ext_ref("planning-denominator", f"Group/{group_id}"),
        ],
        "instantiatesCanonical": [PROTOCOL],
        "status": status, "intent": "order",
        "category": [{"coding": [{"system": f"{CS}/icr-campaign-type-cs", "code": "vaccination-sia", "display": "Vaccination campaign (SIA)"}]}],
        "title": title, "description": description,
        "subject": {"reference": f"Group/{group_id}"},
        "period": {"start": PERIOD_START.isoformat(), "end": PERIOD_END.isoformat()},
        "created": created,
        "careTeam": [{"reference": f"CareTeam/{t}"} for t in teams],
    }
    if part_of:
        cp["partOf"] = [{"reference": f"CarePlan/{part_of}"}]
    return cp


def tallies(rng, u5, worldpop):
    """A completed house-to-house visit's outputs. Coverage lands mostly 80–100 % of the
    planning denominator, with a tail below 80 % (revisit candidates) and a few above."""
    present = max(0, round((u5 or 20) * min(1.25, max(0.55, rng.gauss(0.93, 0.11)))))
    absent = round(present * rng.uniform(0.02, 0.10))
    refused = rng.choice([0, 0, 0, 0, 0, 1, 1, 2, 3]) if present > 10 else 0
    sick = rng.choice([0, 0, 0, 0, 1, 1, 2]) if present > 10 else 0
    sleeping = rng.choice([0, 0, 0, 1, 1, 2, 3]) if present > 10 else 0
    treated = max(0, present - refused - sick - sleeping)
    marked = round(treated * rng.uniform(0.0, 0.05))
    houses = max(1, round(((worldpop or 120) / PERSONS_PER_HOUSE) * rng.uniform(0.85, 1.05)))
    out = [("treated-count", "Persons treated / vaccinated (scalar tally)", treated),
           ("houses-visited", "Houses visited", houses),
           ("eligible-present", "Eligible persons present", present),
           ("eligible-absent", "Eligible persons absent", absent),
           ("children-already-marked", "Children already finger-marked", marked)]
    outputs = [{"type": {"coding": [{"system": f"{CS}/icr-task-output-type-cs", "code": c, "display": d}]}, "valueUnsignedInt": v} for c, d, v in out]
    reasons = [("absent", "Absent", absent), ("refusal", "Refusal", refused), ("sick", "Sick", sick), ("sleeping", "Sleeping", sleeping)]
    for code, display, n in reasons:
        if n > 0:
            outputs.append({"type": {"coding": [{"system": f"{CS}/icr-task-output-type-cs", "code": "missed-reason", "display": "Missed reason"}]},
                            "valueCodeableConcept": {"coding": [{"system": f"{CS}/icr-missed-reason-cs", "code": code, "display": display}]}})
    if refused:
        outputs.append({"type": {"coding": [{"system": f"{CS}/icr-task-output-type-cs", "code": "noncompliance-reason", "display": "Refusal reason"}]},
                        "valueCodeableConcept": {"coding": [{"system": f"{CS}/icr-noncompliance-reason-cs", "code": "no-felt-need", "display": "No felt need"}]}})
    return outputs, dict(treated=treated, houses=houses, present=present, absent=absent, refused=refused, sick=sick, sleeping=sleeping, marked=marked)


def task(s, fac, cid, team_id, day, status, origin, outputs, as_of):
    t = {
        "resourceType": "Task", "id": f"mp-task-2026-r2-{s['id']}", "meta": meta("ICRCampaignTask"),
        "extension": [
            {"url": f"{SD}/delivery-strategy", "valueCodeableConcept": {"coding": [{"system": f"{CS}/icr-delivery-strategy-cs", "code": "house-to-house", "display": "House-to-house"}]}},
            {"url": f"{SD}/task-origin", "valueCode": origin},
            {"url": f"{SD}/data-lineage", "valueCode": "realtime"},
        ],
        "instantiatesCanonical": ACTIVITY,
        "basedOn": [{"reference": f"CarePlan/{cid}"}],
        "status": status, "intent": "order",
        "code": {"text": "House-to-house nOPV2 vaccination visit, children 0–59 months"},
        "description": f"Visit every household in {s['name']} and vaccinate all children 0–59 months with nOPV2; finger-mark and tally.",
        "reasonCode": {"text": "Poliomyelitis (cVDPV2)"},
        "for": {"reference": f"Location/{s['id']}", "display": s["name"]},
        "location": {"reference": f"Location/{s['id']}", "display": s["name"]},
        "owner": {"reference": f"CareTeam/{team_id}", "display": f"{fac['name']} vaccination team"},
        "authoredOn": "2026-08-24",
        "lastModified": (day if status == "completed" else min(day, as_of)).isoformat() + "T17:30:00+01:00",
        "executionPeriod": {"start": day.isoformat()} if status == "requested" else {"start": day.isoformat(), "end": day.isoformat()},
    }
    if status == "in-progress":
        t["executionPeriod"] = {"start": day.isoformat()}
    if outputs:
        t["output"] = outputs
    return t


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--as-of", default="2026-09-09", help="snapshot date (end of that day)")
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--out", default=os.path.join(HERE, "out"))
    a = ap.parse_args()
    as_of = dt.date.fromisoformat(a.as_of)
    rng = random.Random(a.seed)

    facilities, settlements = read_registry()
    by_fac = defaultdict(list)
    for s in settlements:
        by_fac[s["facility_id"]].append(s)

    groups, teams, plans, tasks, rows = [], [], [], [], []
    lga_teams = []
    lga_plan_id = f"nga-microplan-polio-2026-r{ROUND}-ba-5018"

    # Field-registered: unplanned settlements "found" on days 1–3, spread over facilities.
    unplanned = [s for s in settlements if not s["planned"]]
    rng.shuffle(unplanned)
    found = {s["id"] for s in unplanned[:FIELD_REGISTERED]}

    for fid, fac in sorted(facilities.items(), key=lambda kv: kv[1]["name"]):
        planned = sorted((s for s in by_fac[fid] if s["planned"]), key=lambda s: km(s, fac))
        # under-5 per settlement catchment
        u5_total, houses_total = 0, 0
        for s in planned:
            s["u5"] = round(s["worldpop"] * U5_SHARE) if s.get("worldpop") is not None else None
            if s["u5"] is not None:
                u5_total += s["u5"]
                houses_total += round(s["worldpop"] / PERSONS_PER_HOUSE)
                groups.append(u5_group(f"u5-worldpop-2026-{s['id']}", s["catchment_id"], f"{s['name']} catchment", s["u5"],
                                       f"WorldPop 2026 catchment total × {U5_SHARE:.3f} (Toro under-5 share, NPC 2022 projection)", True))
        fac_group = f"u5-worldpop-2026-{fac['catchment_id']}"
        groups.append(u5_group(fac_group, fac["catchment_id"], f"{fac['name']} catchment", u5_total,
                               f"Sum of the settlement-catchment estimates (WorldPop 2026 × {U5_SHARE:.3f})", True))
        team_id = f"mp-team-2026-r{ROUND}-{fid}"
        teams.append(careteam(rng, fac, team_id, u5_total, houses_total, fac_group))
        lga_teams.append(team_id)
        cid = f"mp-polio-2026-r{ROUND}-{fid}"
        plans.append(careplan(cid, f"NIPDs round {ROUND}, September 2026 — {fac['name']} catchment",
                              f"Facility-level microplan for the {ROUND_TITLE} round: house-to-house nOPV2 visits to the "
                              f"{len(planned)} settlements of the {fac['name']} catchment, {LGA_NAME}, Bauchi State.",
                              fac["catchment_id"], f"{fac['name']} catchment", fac_group, [team_id], lga_plan_id, "active", "2026-08-24"))

        # Day plan: nearest settlements first, split by DAY_WEIGHTS.
        n = len(planned)
        bounds, acc = [], 0
        for w in DAY_WEIGHTS:
            acc += w
            bounds.append(round(acc * n))
        day_of = {}
        start = 0
        for d, end in zip(DAYS, bounds):
            for s in planned[start:end]:
                day_of[s["id"]] = d
            start = end
        # Snapshot status
        for s in planned:
            d = day_of[s["id"]]
            if d < as_of:
                status = "completed"
            elif d == as_of:
                r = rng.random()
                status = "completed" if r < 0.75 else "in-progress" if r < 0.97 else "requested"
            else:
                status = "requested"
            outputs, tally = (tallies(rng, s["u5"], s["worldpop"]) if status == "completed" else ([], {}))
            tasks.append(task(s, fac, cid, team_id, d, status, "pre-planned", outputs, as_of))
            rows.append(dict(facility=fac["name"], settlement=s["name"], settlement_id=s["id"], day=d.isoformat(), status=status,
                             origin="pre-planned", u5=s["u5"], worldpop=s["worldpop"], **tally))
        # Field-registered finds in this catchment: completed on a day ≤ as-of, no denominator.
        for s in by_fac[fid]:
            if s["id"] in found:
                d = rng.choice([x for x in DAYS if x <= as_of])
                s["u5"] = None
                outputs, tally = tallies(rng, None, s.get("worldpop"))
                tasks.append(task(s, fac, cid, team_id, d, "completed", "field-registered", outputs, as_of))
                rows.append(dict(facility=fac["name"], settlement=s["name"], settlement_id=s["id"], day=d.isoformat(), status="completed",
                                 origin="field-registered", u5=None, worldpop=s.get("worldpop"), **tally))

    plans.insert(0, careplan(lga_plan_id, f"{ROUND_TITLE} — {LGA_NAME}, Bauchi",
                             f"Polio (nOPV2) {ROUND_TITLE}, {LGA_NAME}, Bauchi State: house-to-house visits to every settlement, "
                             f"organised by health-facility catchment ({len(facilities)} facility-level microplans, partOf this round).",
                             LGA_ID, LGA_NAME, LGA_U5_GROUP, lga_teams, None, "active", "2026-08-20"))

    os.makedirs(a.out, exist_ok=True)
    for name, items in (("01-groups", groups), ("02-careteams", teams), ("03-careplans", plans), ("04-tasks", tasks)):
        with open(os.path.join(a.out, f"{name}.ndjson"), "w") as fh:
            for r in items:
                fh.write(json.dumps(r, ensure_ascii=False) + "\n")
    with open(os.path.join(a.out, "tasks.csv"), "w", newline="") as fh:
        cols = ["facility", "settlement", "settlement_id", "day", "status", "origin", "u5", "worldpop", "treated", "houses", "present", "absent", "refused", "sick", "sleeping", "marked"]
        w = csv.DictWriter(fh, fieldnames=cols); w.writeheader()
        for r in rows:
            w.writerow({k: r.get(k) for k in cols})

    from collections import Counter
    st = Counter(r["status"] for r in rows)
    pre = [r for r in rows if r["origin"] == "pre-planned"]
    done = [r for r in pre if r["status"] == "completed" and r["u5"]]
    cov = sum(r["treated"] for r in done) / max(1, sum(r["u5"] for r in done))
    lines = [
        f"# Toro microplan snapshot — {ROUND_TITLE}, as of {as_of}", "",
        f"- Facilities / facility campaigns: {len(facilities)}", f"- Settlement Tasks: {len(tasks)} ({len(pre)} pre-planned, {len(rows) - len(pre)} field-registered)",
        f"- Status: " + ", ".join(f"{k} {v} ({100 * v / len(rows):.0f}%)" for k, v in st.most_common()),
        f"- Planning denominator (settlements with WorldPop): {sum(r['u5'] for r in pre if r['u5']):,} children 0–59 months in {sum(1 for r in pre if r['u5'])} settlements",
        f"- Vaccinated so far (completed, pre-planned): {sum(r['treated'] for r in done):,} = {100 * cov:.1f}% of their denominators",
        f"- Settlements below 80% coverage among completed: {sum(1 for r in done if r['treated'] < 0.8 * r['u5'])}",
        f"- Unplanned Toro settlements (no catchment, outside the plan): {len(unplanned)}; of which registered in the field: {len(found)}",
    ]
    with open(os.path.join(a.out, "report.md"), "w") as fh:
        fh.write("\n".join(lines) + "\n")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
