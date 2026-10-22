"""The October 2026 ICHDs as a draft campaign: protocol, activities and campaigns.

    python3 -I campaign.py build/targets.ndjson build/snapshot/locations.ndjson build/campaign.ndjson

Writes, all with status draft:

- one ICRCampaignActivity (ActivityDefinition) per intervention;
- the ICRCampaignProtocol (PlanDefinition) "Uganda ICHDs" listing them;
- the national ICRCampaign (CarePlan) for the round, and one per district and city with the
  national one as partOf: the district is the reporting scope;
- one ICRCampaignTask per district and activity (for and location = the district), the unit
  that later splits into facility, parish or session tasks.

Each campaign's subject is its place's total population for 2026 from the targets workbook. The
campaign lists its six activities in CarePlan.activity.detail, each with its own target Groups
for that place as planning-denominator (MR2 has two). A district task is at the campaign's own
scope, so it carries no target: it finds it through its campaign and activity. A task below the
district would name its own share in Task.input (target-population).
"""
import html, json, sys

TARGETS, LOCATIONS, OUT = sys.argv[1:4]
SERVER = "https://fhir-uga.healthcampaigns.org/fhir"
ICR = "https://icr.healthcampaigns.org"
SD = f"{ICR}/StructureDefinition"
CAMPAIGN_TYPE, DELIVERY = f"{ICR}/CodeSystem/icr-campaign-type-cs", f"{ICR}/CodeSystem/icr-delivery-strategy-cs"
CVX, ATC = "http://hl7.org/fhir/sid/cvx", "http://www.whocc.no/atc"
ROUND_CS = f"{SERVER}/CodeSystem/uga-campaign-round"
ROUND, ROUND_NAME, START, END = "ichd-2026-10", "ICHDs October 2026", "2026-10-01", "2026-10-31"
PROTOCOL = "uga-ichd"
TAG = {"system": ROUND_CS, "code": ROUND, "display": ROUND_NAME}
TYPES = {"integrated": "Integrated / multi-intervention campaign", "vaccination-sia": "Vaccination campaign (SIA)",
         "mda": "Mass drug administration (NTD preventive chemotherapy)", "vitamin-a": "Vitamin A supplementation"}
STRATEGIES = {"fixed-post": "Fixed post", "temporary-post": "Temporary / outreach post", "school": "School-based"}


def cc(system, code, display, text=None):
    return {"coding": [{"system": system, "code": code, "display": display}], **({"text": text} if text else {})}


def narrative(*paras):
    return {"status": "generated", "div": '<div xmlns="http://www.w3.org/1999/xhtml">'
            + "".join(f"<p>{html.escape(p)}</p>" for p in paras) + "</div>"}


# Activity id → (title, code, campaign type, product, dosage, target codes from uga-ichd-target,
# delivery strategy of its district tasks). Products are as specific as the workbook allows; the
# brands, ages and strategies are the Ministry's to confirm.
ACTIVITIES = {
    "uga-ichd-catch-up": (
        "Vaccinate unimmunized and under-immunized children under 1 year (catch-up of missed routine doses)",
        "Vaccinate", "vaccination-sia", {"text": "Routine childhood vaccines, the doses each child has missed"},
        "Per the national immunization schedule", ["under-1-unimmunized", "under-1-under-immunized"], "fixed-post"),
    "uga-ichd-mr2": (
        "Administer measles-rubella vaccine, second dose (MR2)", "Vaccinate", "vaccination-sia",
        cc(CVX, "04", "measles and rubella virus vaccine"), "0.5 mL subcutaneous, single dose",
        ["born-2025-04", "mr2-born-2024-04"], "fixed-post"),
    "uga-ichd-deworming": (
        "Deworming", "Treat", "mda",
        cc(ATC, "P02CA", "Benzimidazole derivatives", text="Albendazole or mebendazole, single dose"),
        "Single dose", ["deworming-vitamin-a"], "fixed-post"),
    "uga-ichd-vitamin-a": (
        "Vitamin A supplementation", "Supplement", "vitamin-a", cc(ATC, "A11CA01", "retinol (vit A)"),
        "Single high-dose capsule, by age", ["deworming-vitamin-a"], "fixed-post"),
    "uga-ichd-hpv": (
        "Administer HPV vaccine", "Vaccinate", "vaccination-sia",
        cc(CVX, "137", "HPV, unspecified formulation"), "0.5 mL intramuscular", ["hpv"], "school"),
    "uga-ichd-td": (
        "Administer tetanus-diphtheria vaccine (Td2+)", "Vaccinate", "vaccination-sia",
        cc(CVX, "139", "Td(adult) unspecified formulation"), "0.5 mL intramuscular", ["td2-plus"], "fixed-post"),
}


def canonical(rt, id):
    return f"{SERVER}/{rt}/{id}"


def activity(aid):
    title, code, topic, product, dosage, _, _ = ACTIVITIES[aid]
    return {
        "resourceType": "ActivityDefinition", "id": aid,
        "meta": {"profile": [f"{SD}/ICRCampaignActivity"], "tag": [TAG]},
        "text": narrative(title),
        "url": canonical("ActivityDefinition", aid), "version": "2026-10",
        "name": "".join(w.capitalize() for w in aid.split("-")), "title": title,
        "status": "draft", "experimental": False, "kind": "Task",
        "code": {"text": code}, "topic": [cc(CAMPAIGN_TYPE, topic, TYPES[topic])],
        "productCodeableConcept": product, "dosage": [{"text": dosage}],
    }


protocol = {
    "resourceType": "PlanDefinition", "id": PROTOCOL,
    "meta": {"profile": [f"{SD}/ICRCampaignProtocol"], "tag": [TAG]},
    "text": narrative("Uganda Integrated Child Health Days (ICHDs)",
                      "Interventions: " + "; ".join(a[0] for a in ACTIVITIES.values()) + "."),
    "url": canonical("PlanDefinition", PROTOCOL), "version": "2026-10", "name": "UgaIchd",
    "title": "Uganda Integrated Child Health Days (ICHDs)", "status": "draft", "experimental": False,
    "type": cc(CAMPAIGN_TYPE, "integrated", TYPES["integrated"]),
    "description": "Draft. Twice-yearly integrated child health days: catch-up vaccination, MR2, deworming, "
                   "vitamin A, HPV and Td. The eligible ages and delivery strategies are to be confirmed "
                   "with the Ministry of Health.",
    "action": [{"title": ACTIVITIES[a][0], "definitionCanonical": canonical("ActivityDefinition", a)}
               for a in ACTIVITIES],
    "extension": [{"url": f"{SD}/delivery-strategy", "valueCodeableConcept": cc(DELIVERY, c, d)}
                  for c, d in STRATEGIES.items()],
}

locs = {}
with open(LOCATIONS) as f:
    for line in f:
        r = json.loads(line)
        locs[r["id"]] = r
targets = {}                                  # (target code, location id) → Group
with open(TARGETS) as f:
    for line in f:
        r = json.loads(line)
        if r["resourceType"] == "Group":
            targets[(r["code"]["coding"][0]["code"], r["characteristic"][0]["valueReference"]["reference"][9:])] = r
districts = sorted({lid for (_, lid) in targets
                    if locs[lid].get("partOf") and locs[locs[lid]["partOf"]["reference"][9:]].get("partOf")})
assert len(districts) == 146, len(districts)


def target_groups(aid, lid):
    return [targets[(c, lid)] for c in ACTIVITIES[aid][5]]


def target_text(aid, lid):
    return " + ".join(f"{g['code']['text']} {g['quantity']:,}" for g in target_groups(aid, lid))


def campaign(lid, part_of=None):
    loc = locs[lid]
    scope = "Uganda" if lid == "uga" else loc["name"]
    title = f"{ROUND_NAME}, {scope}"
    population = targets[("population-2026", lid)]
    cp = {
        "resourceType": "CarePlan", "id": f"{ROUND}-{lid}",
        "meta": {"profile": [f"{SD}/ICRCampaign"], "tag": [TAG]},
        "text": narrative(title, f"Draft, {START} to {END}. Targets: "
                          + "; ".join(f"{a[0]}: {target_text(aid, lid)}" for aid, a in ACTIVITIES.items()) + "."),
        "instantiatesCanonical": [canonical("PlanDefinition", PROTOCOL)],
        "status": "draft", "intent": "plan",
        "category": [cc(CAMPAIGN_TYPE, t, d) for t, d in TYPES.items()],
        "title": title,
        "description": ("Integrated Child Health Days, October 2026 (the whole month for now). Targets from the "
                        "Ministry of Health's targets workbook." + (" National round." if lid == "uga" else "")),
        "subject": {"reference": f"Group/{population['id']}", "display": population["name"]},
        "period": {"start": START, "end": END},
        "activity": [{"detail": {
            "instantiatesCanonical": [canonical("ActivityDefinition", aid)],
            "status": "not-started",
            "description": f"{ACTIVITIES[aid][0]}. Target: {target_text(aid, lid)}.",
            "extension": [{"url": f"{SD}/planning-denominator",
                           "valueReference": {"reference": f"Group/{g['id']}", "display": g["name"]}}
                          for g in target_groups(aid, lid)],
        }} for aid in ACTIVITIES],
        "extension": [
            {"url": f"{SD}/target-geography", "valueReference": {"reference": f"Location/{lid}", "display": scope}},
        ],
    }
    if part_of:
        cp["partOf"] = [{"reference": f"CarePlan/{part_of}"}]
    return cp


def task(aid, lid):
    title, code, *_rest, strategy = ACTIVITIES[aid]
    where = {"reference": f"Location/{lid}", "display": locs[lid]["name"]}
    return {
        "resourceType": "Task", "id": f"{ROUND}-{aid.removeprefix('uga-ichd-')}-{lid}",
        "meta": {"profile": [f"{SD}/ICRCampaignTask"], "tag": [TAG]},
        "text": narrative(f"{title}, {locs[lid]['name']}, {ROUND_NAME}", f"Target: {target_text(aid, lid)}."),
        "instantiatesCanonical": canonical("ActivityDefinition", aid),
        "status": "draft", "intent": "plan",
        "code": {"text": title},
        "description": f"{title}. Target: {target_text(aid, lid)}.",
        "basedOn": [{"reference": f"CarePlan/{ROUND}-{lid}"}],
        "for": where, "location": where,
        "executionPeriod": {"start": START, "end": END},
        "extension": [
            {"url": f"{SD}/delivery-strategy", "valueCodeableConcept": cc(DELIVERY, strategy, STRATEGIES[strategy])},
            {"url": f"{SD}/task-origin", "valueCode": "pre-planned"},
        ],
    }


out_rows = [activity(a) for a in ACTIVITIES] + [protocol, campaign("uga")]
out_rows += [campaign(lid, f"{ROUND}-uga") for lid in districts]
out_rows += [task(aid, lid) for lid in districts for aid in ACTIVITIES]
with open(OUT, "w") as out:
    for r in out_rows:
        out.write(json.dumps(r) + "\n")
print(f"{len(ACTIVITIES)} ActivityDefinitions, 1 PlanDefinition, {1 + len(districts)} CarePlans, "
      f"{len(districts) * len(ACTIVITIES)} Tasks → {OUT}")
