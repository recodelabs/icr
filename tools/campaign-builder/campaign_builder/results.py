"""Synthetic but realistic campaign results as ICR coverage MeasureReports.

Administrative coverage per LGA round (tallies ÷ planning denominator, can exceed
100% where the projection undercounts), daily realtime reports for rounds that
are active at the as-of date, state-level post-campaign cluster surveys for the
vaccination campaigns, LGA-level LQAS lots for polio, and NTD coverage
evaluation surveys in a sample of MDA LGAs. See config/results.yaml for the
model and its knobs. Deterministic from the seed.
"""

from __future__ import annotations

import hashlib
import math
import random
from dataclasses import dataclass, replace
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

import yaml

from . import fhir
from .config import CONFIG_DIR, Config, Lga
from .population import band_population
from .schedule import Round

SD = fhir.SD
CS = fhir.CS
MEASURE_POP = "http://terminology.hl7.org/CodeSystem/measure-population"
STRAT = f"{CS}/icr-coverage-stratifier-cs"
MEASURE_BASE = "https://icr.healthcampaigns.org/Measure"


def load_results_config(config_dir: Path = CONFIG_DIR) -> dict:
    with (config_dir / "results.yaml").open() as fh:
        return yaml.safe_load(fh)


def _rng(seed: int, *parts) -> random.Random:
    key = hashlib.sha256(("|".join(str(p) for p in (seed, *parts))).encode()).digest()
    return random.Random(int.from_bytes(key[:8], "big"))


def _uniform(r: random.Random, lo_hi) -> float:
    lo, hi = lo_hi
    return r.uniform(lo, hi)


def _pct(x: float) -> float:
    """Proportion-scored Measures carry a unit-less fraction 0..1 (validator rule); 3 decimals."""
    return round(x, 3)


@dataclass
class LgaOutcome:
    lga: Lga
    state_code: str
    round: Round
    protocol: str
    start: date
    end: date
    denominator: int
    true_population: int
    reach: float          # fraction of the true eligible population reached
    reached: int          # people reached (numerator)
    incident: str | None
    reported: bool        # administrative report submitted


# ----------------------------------------------------------------- model ----

class ResultsModel:
    def __init__(self, cfg: Config, rc: dict, as_of: date):
        self.cfg, self.rc, self.as_of = cfg, rc, as_of
        self.seed = int(rc["seed"])

    # persistent per-LGA factors
    def denominator_error(self, lga: Lga) -> float:
        named = self.rc["lga_factors"]["denominator_error"].get(lga.name)
        if named is not None:
            return float(named)
        return _uniform(_rng(self.seed, "denom", lga.id), self.rc["lga_factors"]["denominator_error_default"])

    def quality(self, lga: Lga, programme: str) -> float:
        prog = self.rc["programmes"][programme]
        base = _uniform(_rng(self.seed, "quality", lga.id, programme), prog["quality"])
        base += float(self.rc["lga_factors"]["quality_adjust"].get(lga.name, 0.0))
        if "community-directed" in prog["strategies"] and lga.name in self.rc["lga_factors"]["metro_lgas"]:
            base += float(self.rc["lga_factors"]["metro_mda_penalty"])
        return base

    def outcome(self, r: Round, state_code: str, protocol: str, w, denominator: int) -> LgaOutcome:
        prog = self.rc["programmes"][r.programme]
        rr = _rng(self.seed, "round", r.id, w.lga.id)
        reach = self.quality(w.lga, r.programme) + rr.gauss(0, float(prog["round_sd"]))
        incident = None
        if rr.random() < float(self.rc["incident_rate"]):
            reach *= float(self.rc["incident_reach_multiplier"])
            incident = rr.choice(["vaccine/drug stock-out on day 2", "security incident suspended teams for a day",
                                  "late start: supplies arrived a day late", "team payment dispute reduced turnout"])
        reach = max(0.25, min(1.06, reach))
        true_pop = round(denominator * self.denominator_error(w.lga))
        reached = round(true_pop * reach)
        reported = rr.random() >= float(self.rc["missing_report_rate"])
        return LgaOutcome(w.lga, state_code, r, protocol, w.start, w.end, denominator, true_pop, reach, reached, incident, reported)


# ------------------------------------------------------------ resources ----

def _quantity_pct(value: float) -> dict:
    # Proportion-scored Measures: a unit-less measureScore between 0 and 1.
    return {"value": value}


def _population(code: str, count: int) -> dict:
    return {"code": {"coding": [{"system": MEASURE_POP, "code": code, "display": code.capitalize()}]}, "count": int(count)}


def _stratifier(code: str, display: str, strata: list[tuple[str, int | None, int | None, float | None]]) -> dict:
    out = {"code": [{"coding": [{"system": STRAT, "code": code, "display": display}]}], "stratum": []}
    for text, num, den, score in strata:
        st = {"value": {"text": text}, "population": []}
        if num is not None:
            st["population"].append(_population("numerator", num))
        if den is not None:
            st["population"].append(_population("denominator", den))
        if not st["population"]:
            del st["population"]
        if score is not None:
            st["measureScore"] = _quantity_pct(score)
        out["stratum"].append(st)
    return out


def _report(cfg: Config, *, rid: str, profile: str, measure: str, campaign_id: str, location_id: str,
            period: tuple[date, date], reported_on: date, reporter: str, numerator: int, denominator: int,
            score: float, source: str, lineage: str, status: str = "complete", denominator_type: str | None = None,
            denominator_source: str | None = None, sample_design: str | None = None, ci: tuple[float, float] | None = None,
            stratifiers: list[dict] | None = None, coverage_unit: str | None = None) -> dict:
    ext = [
        {"url": f"{SD}/campaign", "valueReference": {"reference": f"CarePlan/{campaign_id}"}},
        {"url": f"{SD}/coverage-source", "valueCode": source},
        {"url": f"{SD}/realtime-vs-reconciled", "valueCode": lineage},
    ]
    if denominator_type:
        ext.append({"url": f"{SD}/denominator-type", "valueCode": denominator_type})
    if denominator_source:
        ext.append({"url": f"{SD}/denominator-source",
                    "valueCodeableConcept": fhir.cc(fhir.DENOM_SOURCE, denominator_source, "Census projection")})
    if coverage_unit:
        ext.append({"url": f"{SD}/coverage-unit", "valueCode": coverage_unit})
    if sample_design:
        ext.append({"url": f"{SD}/sample-design", "valueString": sample_design})
    if ci:
        ext.append({"url": f"{SD}/confidence-interval", "extension": [
            {"url": "low", "valueDecimal": ci[0]}, {"url": "high", "valueDecimal": ci[1]}, {"url": "level", "valueDecimal": 95}]})  # CI in the score's unit (fraction)
    group = {"population": [_population("numerator", numerator), _population("denominator", denominator)],
             "measureScore": _quantity_pct(score)}
    if stratifiers:
        group["stratifier"] = stratifiers
    return {
        "resourceType": "MeasureReport", "id": rid, "meta": fhir.meta(cfg, profile),
        "extension": ext, "status": status, "type": "summary",
        "measure": f"{MEASURE_BASE}/{measure}",
        "subject": {"reference": f"Location/{location_id}"},
        "date": datetime.combine(reported_on, datetime.min.time(), tzinfo=timezone.utc).isoformat(),
        "reporter": {"display": reporter},
        "period": {"start": period[0].isoformat(), "end": period[1].isoformat()},
        "group": [group],
    }


# Stratifiers each ICR Measure declares (the validator checks reports against them).
MEASURE_STRATIFIERS = {
    "icr-admin-coverage": ["sex", "age-band", "delivery-strategy", "geography"],
    "icr-mda-treatment-coverage": ["sex", "age-band", "disposition"],
    "icr-survey-coverage": ["sex", "age-band", "disposition"],
}


def _strata_for(o: LgaOutcome, rc: dict, r: random.Random, measure: str, state_name: str) -> list[dict]:
    prog = rc["programmes"][o.round.programme]
    wanted = MEASURE_STRATIFIERS[measure]
    out = []
    # sex
    f = _uniform(r, rc["female_share"])
    nf = round(o.reached * f)
    df = round(o.denominator * 0.505)
    out.append(_stratifier("sex", "Sex", [
        ("female", nf, df, _pct(nf / df)), ("male", o.reached - nf, o.denominator - df, _pct((o.reached - nf) / (o.denominator - df)))]))
    # age bands
    bands = []
    rem_n, rem_d = o.reached, o.denominator
    items = list(prog["age_bands"].items())
    for i, (label, share) in enumerate(items):
        if i == len(items) - 1:
            n, d = rem_n, rem_d
        else:
            d = round(o.denominator * share)
            n = round(o.reached * share * r.uniform(0.94, 1.06))
            rem_n, rem_d = rem_n - n, rem_d - d
        bands.append((label, max(n, 0), max(d, 1), _pct(max(n, 0) / max(d, 1))))
    out.append(_stratifier("age-band", "Age band", bands))
    if "delivery-strategy" in wanted:
        strat = []
        rem = o.reached
        items = list(prog["strategies"].items())
        for i, (code, share) in enumerate(items):
            n = rem if i == len(items) - 1 else round(o.reached * share * r.uniform(0.9, 1.1))
            rem -= n
            strat.append((fhir.DELIVERY_DISPLAY.get(code, code), max(n, 0), None, None))
        out.append(_stratifier("delivery-strategy", "Delivery strategy", strat))
    if "geography" in wanted:
        out.append(_stratifier("geography", "Geography", [(f"{o.lga.name} LGA, {state_name} State", o.reached, o.denominator, _pct(o.reached / o.denominator))]))
    if "disposition" in wanted:
        # Treated vs not-treated reasons over the eligible population actually present
        # (the denominator as the programme saw it: min(denominator, true population)).
        present = max(o.reached, min(o.denominator, o.true_population))
        gap = max(0, present - o.reached)
        absent = round(gap * r.uniform(0.45, 0.6))
        refused = round((gap - absent) * r.uniform(0.5, 0.7))
        excluded = gap - absent - refused
        out.append(_stratifier("disposition", "Disposition", [
            ("treated", o.reached, None, None), ("not treated: absent", absent, None, None),
            ("not treated: refused", refused, None, None), ("not treated: excluded (pregnant / ill / under age)", excluded, None, None)]))
    return out


def _lag(r: random.Random, lo_hi) -> int:
    lo, hi = lo_hi
    return r.randint(int(lo), int(hi))


def _admin_reporter(rc: dict, programme: str, state: str, lga: str) -> str:
    key = "admin_mda" if rc["programmes"][programme]["measure"] == "icr-mda-treatment-coverage" else "admin_vaccination"
    return rc["reporters"][key].format(state=state, lga=lga)


def _clamp(x: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, x))


# ------------------------------------------------------------ generation ----

def build_results(cfg: Config, rc: dict, rounds: list[Round], populations: dict[str, dict], as_of: date, short) -> tuple[list[dict], dict]:
    """Return (MeasureReports, summary). `populations` are the Groups keyed by id (for denominators);
    `short` is the id-shortening helper used for CarePlan ids."""
    model = ResultsModel(cfg, rc, as_of)
    reports: list[dict] = []
    outcomes: dict[str, list[LgaOutcome]] = {}  # round.id -> outcomes
    summary = {"admin": 0, "realtime": 0, "survey_state": 0, "lqas": 0, "ces": 0, "missing": 0, "incidents": 0, "over100": 0}

    for r in rounds:
        prog_cfg = cfg.programmes[r.programme]
        band_key = prog_cfg["age_band"]
        prog = rc["programmes"][r.programme]
        outs: list[LgaOutcome] = []
        for sr in r.states:
            state = cfg.states[sr.state_code]
            for w in sr.windows:
                gid = f"nga-demo-pop-{band_key.replace('_', '')}-{r.year}-{short(w.lga.id)}"
                denominator = int(populations[gid]["quantity"])
                o = model.outcome(r, sr.state_code, sr.protocol, w, denominator)
                outs.append(o)
                campaign_id = f"nga-demo-{r.id}-{short(w.lga.id)}"
                rr = _rng(model.seed, "report", r.id, w.lga.id)
                score = o.reached / o.denominator * 100
                if score > 100:
                    summary["over100"] += 1
                if o.incident:
                    summary["incidents"] += 1

                status, intent = fhir._status(w.start, w.end, as_of)
                if status == "draft":
                    continue  # planned: no results yet
                if status == "active":
                    # daily realtime reports up to the as-of date
                    days = (w.end - w.start).days + 1
                    shares = rc["realtime_daily_shares"]
                    for d in range(days):
                        day = w.start + timedelta(days=d)
                        if day > as_of:
                            break
                        share = shares[min(d, len(shares) - 1)] if d < days - 1 else 1.0
                        cum = round(o.reached * share)
                        partial = replace(o, reached=cum)
                        reports.append(_report(
                            cfg, rid=f"nga-demo-cov-rt{d + 1}-{r.id}-{short(w.lga.id)}", profile="ICRAdministrativeCoverage",
                            measure=prog["measure"], campaign_id=campaign_id, location_id=w.lga.id,
                            period=(w.start, day), reported_on=day, reporter=_admin_reporter(rc, r.programme, state.name, w.lga.name),
                            numerator=cum, denominator=o.denominator, score=_pct(cum / o.denominator),
                            source="administrative", lineage="realtime", status="pending", denominator_type=prog["denominator_type"],
                            denominator_source="census-projection", stratifiers=_strata_for(partial, rc, _rng(model.seed, "rt", r.id, w.lga.id, d), prog["measure"], state.name)))
                        summary["realtime"] += 1
                    continue

                if not o.reported:
                    summary["missing"] += 1
                    continue
                reported_on = w.end + timedelta(days=_lag(rr, rc["admin_report_lag_days"]))
                if reported_on > as_of:
                    summary["missing"] += 1  # not yet received
                    continue
                stratifiers = _strata_for(o, rc, rr, prog["measure"], state.name)
                rep = _report(
                    cfg, rid=f"nga-demo-cov-admin-{r.id}-{short(w.lga.id)}", profile="ICRAdministrativeCoverage",
                    measure=prog["measure"], campaign_id=campaign_id, location_id=w.lga.id,
                    period=(w.start, w.end), reported_on=reported_on,
                    reporter=_admin_reporter(rc, r.programme, state.name, w.lga.name),
                    numerator=o.reached, denominator=o.denominator, score=_pct(o.reached / o.denominator),
                    source="administrative", lineage="reconciled", denominator_type=prog["denominator_type"],
                    denominator_source="census-projection", stratifiers=stratifiers)
                reports.append(rep)
                summary["admin"] += 1

                # LQAS lot (polio, MR) for a share of LGAs
                lq = prog.get("lqas")
                if lq and rr.random() < float(lq["share_of_lgas"]):
                    n = int(lq["sample"])
                    p = _clamp(o.reach, 0.3, 0.995)
                    missed = sum(1 for _ in range(n) if rr.random() > p)
                    verdict = "pass" if missed <= lq["pass_max_missed"] else "intermediate" if missed <= lq["intermediate_max_missed"] else "fail"
                    when = w.end + timedelta(days=_lag(rr, lq["lag_days"]))
                    if when <= as_of:
                        reports.append(_report(
                            cfg, rid=f"nga-demo-cov-lqas-{r.id}-{short(w.lga.id)}", profile="ICRSurveyCoverage",
                            measure="icr-survey-coverage", campaign_id=campaign_id, location_id=w.lga.id,
                            period=(when, when + timedelta(days=1)), reported_on=when + timedelta(days=2),
                            reporter=rc["reporters"]["lqas"].format(state=state.name),
                            numerator=n - missed, denominator=n, score=_pct((n - missed) / n), source="lqas", lineage="reconciled",
                            sample_design=f"LQAS: 1 lot (LGA), {n} children sampled house-to-house; "
                                          f"≤{lq['pass_max_missed']} missed = pass, ≤{lq['intermediate_max_missed']} = intermediate, else fail — result: {verdict}",
                            stratifiers=_survey_strata(rr, (n - missed) / n, n, list(prog["age_bands"].keys()),
                                                        disposition=[(f"lot {verdict} ({missed} of {n} missed)", missed, n, None)])))
                        summary["lqas"] += 1

                # NTD coverage evaluation survey in a sample of LGAs
                ces = prog.get("ces")
                if ces and rr.random() < float(ces["share_of_lgas"]):
                    when = w.end + timedelta(days=_lag(rr, ces["lag_days"]))
                    if when <= as_of:
                        est, lo, hi, n = _survey_estimate(rr, o.reach, ces)
                        reports.append(_report(
                            cfg, rid=f"nga-demo-cov-ces-{r.id}-{short(w.lga.id)}", profile="ICRSurveyCoverage",
                            measure="icr-survey-coverage", campaign_id=campaign_id, location_id=w.lga.id,
                            period=(when, when + timedelta(days=4)), reported_on=when + timedelta(days=12),
                            reporter=rc["reporters"]["ces"].format(state=state.name),
                            numerator=round(est * n), denominator=n, score=_pct(est), source="survey", lineage="reconciled",
                            sample_design=f"Coverage evaluation survey, LGA-representative: 30 clusters × {n // 30} persons (n = {n}), "
                                          f"segment sampling; evidence: household register + recall",
                            ci=(_pct(lo), _pct(hi)),
                            stratifiers=_survey_strata(rr, est, n, list(prog["age_bands"].keys()))))
                        summary["ces"] += 1
        outcomes[r.id] = outs

        # State-level post-campaign cluster survey
        sv = prog.get("survey")
        if sv and sv.get("level") == "state":
            for sr in r.states:
                state = cfg.states[sr.state_code]
                so = [o for o in outs if o.state_code == sr.state_code]
                if not so or fhir._status(sr.start, sr.end, as_of)[0] != "completed":
                    continue
                rr = _rng(model.seed, "survey", r.id, sr.state_code)
                true_reach = sum(o.reached for o in so) / max(1, sum(o.true_population for o in so))
                when = sr.end + timedelta(days=_lag(rr, sv["lag_days"]))
                if when > as_of:
                    continue
                est, lo, hi, n = _survey_estimate(rr, true_reach, sv)
                campaign_id = f"nga-demo-{r.id}-{sr.state_code}"
                bands = list(rc["programmes"][r.programme]["age_bands"].keys())
                reports.append(_report(
                    cfg, rid=f"nga-demo-cov-pccs-{r.id}-{sr.state_code}", profile="ICRSurveyCoverage",
                    measure="icr-survey-coverage", campaign_id=campaign_id, location_id=state.id,
                    period=(when, when + timedelta(days=6)), reported_on=when + timedelta(days=21),
                    reporter=rc["reporters"]["survey_state"].format(state=state.name),
                    numerator=round(est * n), denominator=n, score=_pct(est), source="survey", lineage="reconciled",
                    sample_design=f"WHO {sv['clusters']}×{sv['per_cluster']} cluster survey (n = {n:,}), state-representative; "
                                  f"evidence: vaccination card + caregiver recall; design effect {sv['design_effect']}",
                    ci=(_pct(lo), _pct(hi)),
                    stratifiers=_survey_strata(rr, est, n, bands)))
                summary["survey_state"] += 1

    return reports, summary


def _survey_strata(r: random.Random, est: float, n: int, bands: list[str], disposition=None) -> list[dict]:
    """sex, age-band and disposition strata for a survey/LQAS report (sample counts)."""
    nf = round(n * r.uniform(0.48, 0.52))
    ef = _clamp(est + r.uniform(0.0, 0.04), 0, 1)
    em = _clamp(est - r.uniform(0.0, 0.04), 0, 1)
    sex = _stratifier("sex", "Sex", [("female", round(nf * ef), nf, _pct(ef)), ("male", round((n - nf) * em), n - nf, _pct(em))])
    age, rem = [], n
    for i, b in enumerate(bands):
        d = rem if i == len(bands) - 1 else round(n / len(bands))
        rem -= d
        eb = _clamp(est + r.uniform(-0.05, 0.05), 0, 1)
        age.append((b, round(d * eb), d, _pct(eb)))
    covered = round(n * est)
    disp = disposition or [("covered", covered, n, None), ("not covered", n - covered, n, None)]
    return [sex, _stratifier("age-band", "Age band", age), _stratifier("disposition", "Disposition", disp)]


def _survey_estimate(r: random.Random, true_reach: float, design: dict) -> tuple[float, float, float, int]:
    """Survey-measured coverage: true reach × recall loss + sampling error; returns (estimate, lo, hi, n)."""
    n = int(design.get("sample") or design["clusters"] * design["per_cluster"])
    recall = _uniform(r, design["recall"])
    p = _clamp(true_reach * recall, 0.05, 0.99)
    se = math.sqrt(p * (1 - p) / n) * math.sqrt(float(design["design_effect"]))
    est = _clamp(r.gauss(p, se), 0.05, 0.99)
    return est, _clamp(est - 1.96 * se, 0, 1), _clamp(est + 1.96 * se, 0, 1), n
