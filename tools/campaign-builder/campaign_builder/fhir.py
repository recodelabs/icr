"""FHIR resource builders for the ICR IG profiles.

Everything generated carries the dataset tag from config/states.yaml
(`dataset_tag`) as meta.tag, so it can be selected or excluded in one search:
`?_tag=<system>|<code>`.
"""

from __future__ import annotations

from datetime import date, timedelta

from .config import AgeBand, Config, Lga, State

CS = "https://icr.healthcampaigns.org/CodeSystem"
SD = "https://icr.healthcampaigns.org/StructureDefinition"
CAMPAIGN_TYPE = f"{CS}/icr-campaign-type-cs"
DELIVERY = f"{CS}/icr-delivery-strategy-cs"
GROUP_CHAR = f"{CS}/icr-group-characteristic-cs"
DENOM_SOURCE = f"{CS}/icr-denominator-source-cs"
CVX = "http://hl7.org/fhir/sid/cvx"
ATC = "http://www.whocc.no/atc"

CAMPAIGN_TYPE_DISPLAY = {
    "vaccination-sia": "Vaccination campaign (SIA)",
    "mda": "Mass drug administration (NTD preventive chemotherapy)",
    "integrated": "Integrated / multi-intervention campaign",
}
DELIVERY_DISPLAY = {
    "fixed-post": "Fixed post",
    "temporary-post": "Temporary / outreach post",
    "mobile": "Mobile team",
    "school": "School-based",
    "house-to-house": "House-to-house",
    "community-directed": "Community-directed distribution",
    "outreach": "Outreach / special-strategy site",
}


def meta(cfg: Config, profile: str | None) -> dict:
    m = {"tag": [dict(cfg.dataset_tag)]}
    if profile:
        m["profile"] = [f"{SD}/{profile}"]
    return m


def cc(system: str, code: str, display: str | None = None, text: str | None = None) -> dict:
    coding = {"system": system, "code": code}
    if display:
        coding["display"] = display
    out = {"coding": [coding]}
    if text:
        out["text"] = text
    return out


def delivery_ext(codes: list[str]) -> list[dict]:
    return [
        {"url": f"{SD}/delivery-strategy",
         "valueCodeableConcept": cc(DELIVERY, c, DELIVERY_DISPLAY[c])}
        for c in codes
    ]


def age_range(band: AgeBand) -> dict:
    unit_name = {"mo": "months", "a": "years"}
    rng = {"low": {"value": band.low, "unit": unit_name[band.low_unit],
                   "system": "http://unitsofmeasure.org", "code": band.low_unit}}
    if band.high is not None:
        rng["high"] = {"value": band.high, "unit": unit_name[band.high_unit],
                       "system": "http://unitsofmeasure.org", "code": band.high_unit}
    return rng


# ---------------------------------------------------------------- catalog ----

# ICRCampaignActivity allows one delivery-strategy per activity (the primary
# mode); the full mix lives on the protocol (PlanDefinition).
ACTIVITIES: dict[str, dict] = {
    "nga-demo-act-nopv2": dict(
        title="Administer nOPV2, 0–59 months", code="Vaccinate", topic="vaccination-sia",
        product=cc(CVX, "02", "poliovirus vaccine, live, oral", text="nOPV2 (novel oral polio vaccine type 2)"),
        dosage="2 drops orally, single dose", delivery=["house-to-house"]),
    "nga-demo-act-mcv": dict(
        title="Administer measles-containing vaccine", code="Vaccinate", topic="vaccination-sia",
        product=cc(CVX, "05", "measles virus vaccine"), dosage="0.5 mL subcutaneous, single dose",
        delivery=["fixed-post"]),
    "nga-demo-act-mr": dict(
        title="Administer measles-rubella vaccine, 9 months–14 years", code="Vaccinate", topic="vaccination-sia",
        product=cc(CVX, "04", "measles and rubella virus vaccine"), dosage="0.5 mL subcutaneous, single dose",
        delivery=["fixed-post"]),
    "nga-demo-act-ivm-alb": dict(
        title="Administer ivermectin + albendazole (LF/onchocerciasis), height-pole dosing", code="Treat",
        topic="mda", product=cc(ATC, "P02CF01", "ivermectin", text="ivermectin 3 mg (height-pole) + albendazole 400 mg"),
        dosage="Ivermectin by height pole (1–4 tablets) + albendazole 400 mg, single dose, directly observed",
        delivery=["community-directed"]),
    "nga-demo-act-ivm": dict(
        title="Administer ivermectin (onchocerciasis CDTI), height-pole dosing", code="Treat", topic="mda",
        product=cc(ATC, "P02CF01", "ivermectin"),
        dosage="Ivermectin by height pole (1–4 tablets), single dose, directly observed",
        delivery=["community-directed"]),
    "nga-demo-act-azm": dict(
        title="Administer azithromycin (trachoma), height-based dosing", code="Treat", topic="mda",
        product=cc(ATC, "J01FA10", "azithromycin"),
        dosage="20 mg/kg by height (tablets or oral suspension), single dose, directly observed; TEO for <6 months",
        delivery=["community-directed"]),
    "nga-demo-act-pzq-alb": dict(
        title="Administer praziquantel + albendazole, school-age children", code="Treat", topic="mda",
        product=cc(ATC, "P02BA01", "praziquantel", text="praziquantel 600 mg (height-pole) + albendazole 400 mg"),
        dosage="Praziquantel 40 mg/kg by height pole + albendazole 400 mg, single dose, directly observed",
        delivery=["school"]),
    "nga-demo-act-alb": dict(
        title="Administer albendazole (STH deworming), 1–14 years", code="Treat", topic="mda",
        product=cc(ATC, "P02CA03", "albendazole"), dosage="Albendazole 400 mg single dose",
        delivery=["fixed-post"]),
}

PROTOCOLS: dict[str, dict] = {
    "nga-demo-proto-nopv2-sia": dict(
        title="nOPV2 supplementary immunization activity, 0–59 months, house-to-house",
        type="vaccination-sia", band="under5", delivery=["house-to-house", "outreach"],
        goal="≥95% of children 0–59 months vaccinated in every LGA (independent monitoring / LQAS pass)",
        actions=[("Vaccinate all children 0–59 months with nOPV2 regardless of prior dose history", "nga-demo-act-nopv2")]),
    "nga-demo-proto-measles-catchup": dict(
        title="Measles catch-up campaign, 9–59 months, fixed and temporary posts",
        type="vaccination-sia", band="m9_59", delivery=["fixed-post", "temporary-post"],
        goal="≥95% administrative coverage in every LGA, verified by post-campaign coverage survey",
        actions=[("Vaccinate all children 9–59 months with MCV regardless of prior vaccination status", "nga-demo-act-mcv")]),
    "nga-demo-proto-measles-obr": dict(
        title="Measles outbreak response immunization, 6–59 months",
        type="vaccination-sia", band="m6_59", delivery=["fixed-post", "temporary-post", "house-to-house"],
        goal="≥95% coverage of 6–59 months in the outbreak LGAs within 10 days of confirmation",
        actions=[("Vaccinate all children 6–59 months with MCV in affected LGAs", "nga-demo-act-mcv")]),
    "nga-demo-proto-mr-nopv2-integrated": dict(
        title="Integrated measles-rubella (9 months–14 years) + nOPV2 (0–59 months) campaign",
        type="integrated", band="m9_y14", delivery=["fixed-post", "temporary-post", "house-to-house"],
        goal="≥95% MR coverage 9 months–14 years and ≥95% nOPV2 coverage 0–59 months, by post-campaign survey",
        actions=[("Vaccinate all children 9 months–14 years with MR", "nga-demo-act-mr"),
                 ("Vaccinate all children 0–59 months with nOPV2", "nga-demo-act-nopv2")]),
    "nga-demo-proto-mr-nopv2-ntd-integrated": dict(
        title="Integrated measles-rubella + nOPV2 + NTD (albendazole) campaign",
        type="integrated", band="m9_y14", delivery=["fixed-post", "temporary-post", "house-to-house"],
        goal="≥95% MR and nOPV2 coverage; ≥75% albendazole coverage 1–14 years",
        actions=[("Vaccinate all children 9 months–14 years with MR", "nga-demo-act-mr"),
                 ("Vaccinate all children 0–59 months with nOPV2", "nga-demo-act-nopv2"),
                 ("Deworm all children 1–14 years with albendazole", "nga-demo-act-alb")]),
    "nga-demo-proto-lf-oncho-mda": dict(
        title="Lymphatic filariasis / onchocerciasis MDA (ivermectin + albendazole), community-directed",
        type="mda", band="y5_plus", delivery=["community-directed"],
        goal="≥65% epidemiological coverage (of total population) in every endemic LGA",
        actions=[("Treat everyone 5 years and older (excluding pregnant women and the severely ill) with ivermectin + albendazole", "nga-demo-act-ivm-alb")]),
    "nga-demo-proto-oncho-cdti": dict(
        title="Onchocerciasis community-directed treatment with ivermectin (CDTI)",
        type="mda", band="y5_plus", delivery=["community-directed"],
        goal="≥80% therapeutic coverage of the eligible population in every endemic community",
        actions=[("Treat everyone 5 years and older with ivermectin", "nga-demo-act-ivm")]),
    "nga-demo-proto-trachoma-mda": dict(
        title="Trachoma MDA (azithromycin, tetracycline eye ointment for infants), directly observed",
        type="mda", band="m6_plus", delivery=["community-directed", "house-to-house"],
        goal="≥80% coverage of the total population in every endemic LGA",
        actions=[("Treat everyone 6 months and older with azithromycin; TEO for infants under 6 months", "nga-demo-act-azm")]),
    "nga-demo-proto-sch-sth-school-mda": dict(
        title="Schistosomiasis / STH school-based MDA (praziquantel + albendazole), 5–14 years",
        type="mda", band="y5_14", delivery=["school", "community-directed"],
        goal="≥75% coverage of school-age children (enrolled and non-enrolled) in every endemic LGA",
        actions=[("Treat all school-age children 5–14 years with praziquantel + albendazole", "nga-demo-act-pzq-alb")]),
}


def activity_definitions(cfg: Config) -> list[dict]:
    out = []
    for aid, a in ACTIVITIES.items():
        out.append({
            "resourceType": "ActivityDefinition", "id": aid, "meta": meta(cfg, "ICRCampaignActivity"),
            "url": f"{cfg.canonical_base}/ActivityDefinition/{aid}", "version": "1.0.0",
            "name": aid.replace("-", "_"), "title": a["title"], "status": "active", "kind": "Task",
            "code": {"text": a["code"]},
            "topic": [cc(CAMPAIGN_TYPE, a["topic"], CAMPAIGN_TYPE_DISPLAY[a["topic"]])],
            "productCodeableConcept": a["product"], "dosage": [{"text": a["dosage"]}],
            "extension": delivery_ext(a["delivery"]),
        })
    return out


def eligibility_group_id(protocol_id: str) -> str:
    return protocol_id.replace("-proto-", "-eligible-")


def eligibility_groups(cfg: Config) -> list[dict]:
    """Definitional cohorts (actual=false, no count) that protocols point at."""
    out = []
    for pid, p in PROTOCOLS.items():
        band = cfg.age_bands[p["band"]]
        out.append({
            "resourceType": "Group", "id": eligibility_group_id(pid), "meta": meta(cfg, None),
            "type": "person", "actual": False,
            "name": f"{band.label} (eligibility, {p['title']})",
            "characteristic": [{
                "code": cc(GROUP_CHAR, "age-band", "Age band"),
                "valueRange": age_range(band), "exclude": False}],
        })
    return out


def plan_definitions(cfg: Config) -> list[dict]:
    out = []
    for pid, p in PROTOCOLS.items():
        out.append({
            "resourceType": "PlanDefinition", "id": pid, "meta": meta(cfg, "ICRCampaignProtocol"),
            "url": f"{cfg.canonical_base}/PlanDefinition/{pid}", "version": "1.0.0",
            "name": pid.replace("-", "_"), "title": p["title"], "status": "active",
            "type": cc(CAMPAIGN_TYPE, p["type"], CAMPAIGN_TYPE_DISPLAY[p["type"]]),
            "subjectReference": {"reference": f"Group/{eligibility_group_id(pid)}"},
            "goal": [{"description": {"text": p["goal"]}}],
            "action": [{"title": title, "definitionCanonical": f"{cfg.canonical_base}/ActivityDefinition/{aid}"}
                       for title, aid in p["actions"]],
            "extension": delivery_ext(p["delivery"]),
        })
    return out


# ------------------------------------------------------------ populations ----

def population_group(cfg: Config, unit: Lga | State, location_id: str, band: AgeBand, year: int, quantity: int, gid: str) -> dict:
    scope = f"{unit.name} LGA" if isinstance(unit, Lga) else f"{unit.name} State"
    return {
        "resourceType": "Group", "id": gid, "meta": meta(cfg, "ICRTargetPopulation"),
        "type": "person", "actual": False,
        "name": f"{band.label}, {scope}, {year} (planning denominator)",
        "quantity": quantity,
        "characteristic": [
            {"code": cc(GROUP_CHAR, "geography", "Geographic scope"),
             "valueReference": {"reference": f"Location/{location_id}", "display": scope}, "exclude": False},
            {"code": cc(GROUP_CHAR, "age-band", "Age band"), "valueRange": age_range(band), "exclude": False},
        ],
        "extension": [
            {"url": f"{SD}/denominator-source",
             "valueCodeableConcept": cc(DENOM_SOURCE, "census-projection", "Census projection",
                                        text=f"NPC 2006 census and 2022 projection, geometric interpolation to {year}, × {band.fraction:.3f} age-band share")},
            {"url": f"{SD}/estimate-date", "valueDate": f"{year}-01-01"},
            {"url": f"{SD}/is-planning-denominator", "valueBoolean": True},
            {"url": f"{SD}/is-calculated", "valueBoolean": True},
        ],
    }


# -------------------------------------------------------------- campaigns ----

def _status(start: date, end: date, as_of: date) -> tuple[str, str]:
    """(status, intent): completed/order, active/order, or draft/plan."""
    if end < as_of:
        return "completed", "order"
    if start <= as_of:
        return "active", "order"
    return "draft", "plan"


def care_plan(cfg: Config, *, cid: str, title: str, description: str, protocol: str, campaign_type: str,
              subject_group: str, start: date, end: date, as_of: date, geography_id: str, geography_name: str,
              round_number: int, part_of: str | None, created_lead_days: int, activity_types: list[str] | None = None) -> dict:
    status, intent = _status(start, end, as_of)
    categories = [cc(CAMPAIGN_TYPE, campaign_type, CAMPAIGN_TYPE_DISPLAY[campaign_type])]
    for t in activity_types or []:
        if t != campaign_type:
            categories.append(cc(CAMPAIGN_TYPE, t, CAMPAIGN_TYPE_DISPLAY[t]))
    ext = [
        {"url": f"{SD}/campaign-round", "valuePositiveInt": round_number},
        {"url": f"{SD}/target-geography", "valueReference": {"reference": f"Location/{geography_id}", "display": geography_name}},
        {"url": f"{SD}/planning-denominator", "valueReference": {"reference": f"Group/{subject_group}"}},
    ]
    cp = {
        "resourceType": "CarePlan", "id": cid, "meta": meta(cfg, "ICRCampaign"),
        "instantiatesCanonical": [f"{cfg.canonical_base}/PlanDefinition/{protocol}"],
        "status": status, "intent": intent, "category": categories,
        "title": title, "description": description,
        "subject": {"reference": f"Group/{subject_group}"},
        "period": {"start": start.isoformat(), "end": end.isoformat()},
        "created": (start - timedelta(days=created_lead_days)).isoformat(),
        "extension": ext,
    }
    if part_of:
        cp["partOf"] = [{"reference": f"CarePlan/{part_of}"}]
    return cp
