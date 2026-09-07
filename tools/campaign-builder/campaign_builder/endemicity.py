"""Endemicity assertions: ICRLocationStatus Observations per LGA × disease.

What the NTD programme says about each LGA — endemic and under MDA, under
post-MDA surveillance after a passed TAS / impact survey, non-endemic, or
unknown — with the baseline prevalence figure the classification rests on
(as Observation components) and the survey that changed it. Statuses are
derived from the same year-maps that drive the campaign schedule
(config/endemicity.yaml, `assertions` block), so campaigns and assertions
never disagree. A new assertion is written only when the status changes.
"""

from __future__ import annotations

import hashlib
import random
from datetime import date, timedelta

from . import fhir
from .config import Config, Lga

LOCATION_STATUS = f"{fhir.CS}/icr-location-status-cs"
ENDEMICITY = f"{fhir.CS}/icr-endemicity-status-cs"
COMPONENT = f"{fhir.CS}/icr-endemicity-component-cs"  # local component codes (prevalence figures)

STATUS_DISPLAY = {
    "endemic-under-mda": "Endemic, under MDA",
    "post-mda-surveillance": "Under post-MDA surveillance",
    "non-endemic": "Non-endemic",
    "unknown": "Unknown (mapping required)",
    "endemic-mda-not-started": "Endemic, MDA not started",
}
PROPERTY_DISPLAY = {
    "lf-endemicity": "Lymphatic filariasis endemicity",
    "oncho-endemicity": "Onchocerciasis endemicity",
    "schisto-endemicity": "Schistosomiasis endemicity",
    "sth-endemicity": "Soil-transmitted helminthiasis endemicity",
    "trachoma-endemicity": "Trachoma endemicity",
}


def _rng(seed: int, *parts) -> random.Random:
    key = hashlib.sha256(("|".join(str(p) for p in (seed, *parts))).encode()).digest()
    return random.Random(int.from_bytes(key[:8], "big"))


def _years_under_mda(cfg: Config, programmes: list[str], state_code: str, lga: Lga, years: range) -> set[int]:
    out = set()
    for prog in programmes:
        for y in years:
            if any(l.id == lga.id for l in cfg.lgas_for(state_code, f"endemicity:{prog}", y)):
                out.add(y)
    return out


def _component(code: str, label: str, value: float, unit: str) -> dict:
    return {"code": {"coding": [{"system": COMPONENT, "code": code, "display": label}], "text": label},
            "valueQuantity": {"value": value, "unit": unit, "system": "http://unitsofmeasure.org", "code": "%" if unit == "%" else "1"}}


def _observation(cfg: Config, *, oid: str, prop: str, lga: Lga, state_name: str, status: str, effective: date,
                 performer: str, method: str, derived: str | None, components: list[dict]) -> dict:
    o = {
        "resourceType": "Observation", "id": oid, "meta": fhir.meta(cfg, "ICRLocationStatus"),
        "status": "final",
        "code": fhir.cc(LOCATION_STATUS, prop, PROPERTY_DISPLAY[prop]),
        "subject": {"reference": f"Location/{lga.id}", "display": f"{lga.name} LGA, {state_name} State"},
        "effectiveDateTime": effective.isoformat(),
        "valueCodeableConcept": fhir.cc(ENDEMICITY, status, STATUS_DISPLAY[status]),
        "performer": [{"display": performer}],
        "method": {"text": method},
    }
    if derived:
        o["derivedFrom"] = [{"display": derived}]
    if components:
        o["component"] = components
    return o


def build_endemicity(cfg: Config, endemicity_cfg: dict, as_of: date, short) -> tuple[list[dict], dict]:
    ac = endemicity_cfg["assertions"]
    seed = int(ac["seed"])
    baseline = date.fromisoformat(ac["baseline_date"])
    years = range(2022, 2028)
    out: list[dict] = []
    summary = {"baseline": 0, "transitions": 0, "by_status": {}}

    for dkey, d in ac["diseases"].items():
        prop = d["code"]
        prev = d["prevalence"]
        for code, state in cfg.states.items():
            also = {n for n in (d.get("also_endemic_in") or {}).get(code, [])}
            stopped = {n for n in ((ac.get("historically_stopped") or {}).get(dkey) or {}).get(code, [])}
            for lga in state.lgas.values():
                r = _rng(seed, dkey, lga.id)
                mda_years = _years_under_mda(cfg, d["programmes"], code, lga, years)
                ever_endemic = bool(mda_years) or lga.name in also or lga.name in stopped
                performer = ac["performer"].format(state=state.name, year=baseline.year)
                mapping_year = ac["mapping_year"][dkey]

                # --- baseline assertion (JRSM 2022) --------------------------------
                if not ever_endemic:
                    if r.random() < float(ac["unknown_share"]):
                        status, value = "unknown", None
                    else:
                        status, value = "non-endemic", round(r.uniform(*prev["non_endemic"]), 1)
                elif 2022 in mda_years or (lga.name in also and not mda_years):
                    status, value = "endemic-under-mda", round(r.uniform(*prev["endemic"]), 1)
                else:
                    # endemic historically, MDA already stopped before the window (e.g. Bade LF)
                    status, value = "post-mda-surveillance", round(r.uniform(*prev["endemic"]), 1)
                comps = [] if value is None else [_component("baseline-prevalence", f"{prev['label']} ({mapping_year})", value, prev["unit"])]
                if status == "post-mda-surveillance":
                    method = f"{d['mapping_method']} ({mapping_year}); {d.get('stop_method', 'stopping criteria met')} before {baseline.year}"
                elif value is not None:
                    method = f"{d['mapping_method']} ({mapping_year}); reconfirmed through annual JRSM reporting"
                else:
                    method = f"{d['mapping_method']}; not yet mapped"
                out.append(_observation(
                    cfg, oid=f"nga-demo-endem-{dkey}-{short(lga.id)}-{baseline.year}", prop=prop, lga=lga, state_name=state.name,
                    status=status, effective=baseline, performer=performer,
                    method=method,
                    derived=None if value is None else f"{d['mapping_method'].split(' (')[0]} report, {lga.name} LGA, {mapping_year}",
                    components=comps))
                summary["baseline"] += 1
                summary["by_status"][status] = summary["by_status"].get(status, 0) + 1

                # --- transitions: MDA stops after the last listed year -------------
                if mda_years and status == "endemic-under-mda" and d.get("stop_method"):
                    last = max(mda_years)
                    if last < max(years):
                        stop_year = last + 1
                        when = date(stop_year, 3, 1) + timedelta(days=r.randint(0, 120))
                        if when > as_of:
                            continue
                        comps = []
                        sr = d.get("stop_result")
                        if sr:
                            if "sample" in sr:
                                positives = r.randint(*sr["range"])
                                comps.append(_component("stop-survey-result", f"{sr['label']} (n = {sr['sample']}, critical cut-off {sr['cutoff']})", positives, sr["unit"]))
                            else:
                                comps.append(_component("stop-survey-result", sr["label"], round(r.uniform(*sr["range"]), 1), sr["unit"]))
                        out.append(_observation(
                            cfg, oid=f"nga-demo-endem-{dkey}-{short(lga.id)}-{stop_year}", prop=prop, lga=lga, state_name=state.name,
                            status="post-mda-surveillance", effective=when,
                            performer=ac["performer"].format(state=state.name, year=stop_year),
                            method=d["stop_method"], derived=f"{d['stop_method'].split(' —')[0]} report, {lga.name} LGA, {stop_year}",
                            components=comps))
                        summary["transitions"] += 1
    return out, summary
