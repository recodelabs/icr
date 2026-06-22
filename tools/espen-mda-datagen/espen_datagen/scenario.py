"""Build one internally-consistent ESPEN oncho/LF IVM campaign (Ituri, DRC)."""
from __future__ import annotations

import random
from dataclasses import dataclass, field
from datetime import date, timedelta

from . import realism as R

# Real Ituri districts / HFs / villages drawn from the choices sheets.
ITURI_DISTRICTS = ["Bunia", "Mambasa"]
HEALTH_FACILITIES = ["Mudzipela Centre", "Nyakunde Centre", "Oicha Centre"]
VILLAGE_POOL = [
    "Kalelu", "Nyabibwe", "Misangi", "Mutoshi", "Sange", "Kimputu",
    "Soyo", "Tchomia", "Kasenyi", "Bogoro", "Marabo", "Gety",
    "Komanda", "Luna", "Mandima", "Biakato",
]
ITURI_CENTER = (1.56, 30.25)  # near Bunia


def _yn(b: bool) -> str:
    return "Yes" if b else "No"


@dataclass
class Config:
    seed: int = 20261101
    n_districts: int = 2
    n_hf: int = 3
    n_villages: int = 12
    campaign_days: int = 3
    province: str = "Ituri"
    diseases: tuple = ("ONCHO", "LF")
    medicine: str = "IVM+ALB"
    campaign_start: str = "2026-11-09"


@dataclass
class SubmissionRecord:
    form_key: str
    values: dict
    start: str
    end: str
    today: str


@dataclass
class Village:
    name: str
    location_id: str
    hf: str
    district: str
    recorder_id: str
    lat: float
    lon: float
    total_pop: int
    age_bands: dict
    eligible: int
    treated: int = 0
    not_treated: dict = field(default_factory=dict)
    treated_by_band_sex: dict = field(default_factory=dict)
    alb_distributed: int = 0
    treated_flag: bool = True


@dataclass
class Campaign:
    config: Config
    villages: list
    received: dict
    distributed: dict
    records: list


def _iso_dt(d: date, hour: int, minute: int) -> str:
    return f"{d.isoformat()}T{hour:02d}:{minute:02d}:00.000+02:00"


def build_campaign(cfg: Config = Config()) -> Campaign:
    rng = random.Random(cfg.seed)
    start_date = date.fromisoformat(cfg.campaign_start)

    villages: list[Village] = []
    for i in range(cfg.n_villages):
        name = VILLAGE_POOL[i % len(VILLAGE_POOL)]
        hf = HEALTH_FACILITIES[i % cfg.n_hf]
        district = ITURI_DISTRICTS[i % cfg.n_districts]
        total = rng.randint(*R.VILLAGE_POP_RANGE)
        bands = R.split_age_bands(total)
        eligible = int(round(total * R.ELIGIBLE_FRACTION))
        lat = round(ITURI_CENTER[0] + rng.uniform(-0.6, 0.6), 5)
        lon = round(ITURI_CENTER[1] + rng.uniform(-0.6, 0.6), 5)
        v = Village(
            name=name,
            location_id=str(101 + i),
            hf=hf,
            district=district,
            recorder_id=f"{(i % 12) + 1:02d}",
            lat=lat,
            lon=lon,
            total_pop=total,
            age_bands=bands,
            eligible=eligible,
        )
        # One village deliberately not treated (Insecurity) for realism.
        v.treated_flag = not (i == cfg.n_villages - 1)
        if v.treated_flag:
            cov = R.sample_coverage(rng)
            v.treated = int(round(eligible * cov))
            v.not_treated = R.split_not_treated(eligible - v.treated, rng)
            v.treated_by_band_sex = _split_treated(v.treated, rng)
            v.alb_distributed = v.treated * R.ALB_TABLETS_PER_PERSON
        else:
            v.treated = 0
            v.not_treated = {k: 0 for k in R.NOT_TREATED_WEIGHTS}
            v.treated_by_band_sex = _split_treated(0, rng)
            v.alb_distributed = 0
        villages.append(v)

    # IVM tablets used ~ height-banded; approximate 2 tablets/treated person.
    ivm_used = sum(v.treated for v in villages) * 2
    alb_used = sum(v.alb_distributed for v in villages)
    received = {"ivm": int(ivm_used * 1.15) + 50, "alb": int(alb_used * 1.15) + 50}
    distributed = {"ivm": ivm_used, "alb": alb_used}

    records: list[SubmissionRecord] = []
    records += _form1_records(villages, cfg, start_date)
    records += _form2_records(villages, cfg, received, start_date)
    records += _form3_records(villages, cfg, start_date)
    records += _form4_records(villages, cfg, distributed, start_date)
    records += _form5_records(villages, cfg, received, distributed, start_date)
    records += _form6_records(villages, cfg, start_date, rng)

    _assert_invariants(villages, received, distributed)
    return Campaign(cfg, villages, received, distributed, records)


def _split_treated(treated: int, rng) -> dict:
    """Split treated count across age-band x sex cells used by form 3 (IVM/ALB)."""
    # IVM excludes <90cm (~under-5), so treated are 5-14 and 15+ only.
    share_5_14 = 0.32
    n_5_14 = int(round(treated * share_5_14))
    n_15 = treated - n_5_14
    f5 = n_5_14 // 2
    f15 = n_15 // 2
    return {
        "5_14_female": f5,
        "5_14_male": n_5_14 - f5,
        "15_female": f15,
        "15_male": n_15 - f15,
    }


# ---- per-form record builders -------------------------------------------------

def _form1_records(villages, cfg, start_date):
    recs = []
    s = _iso_dt(start_date, 8, 0)
    e = _iso_dt(start_date, 8, 30)
    for v in villages:
        recs.append(SubmissionRecord("1_location", {
            "l_recorder_id": v.recorder_id,
            "l_state": cfg.province,
            "l_district": v.district,
            "l_health_facility": v.hf,
            "l_location": v.name,
            "l_location_id": v.location_id,
            "l_total_pop": str(v.total_pop),
            "I_total_popn_1_4": str(v.age_bands["1_4"]),
            "I_total_popn_5_14": str(v.age_bands["5_14"]),
            "I_total_popn_15_More": str(v.age_bands["15_plus"]),
            "l_eligible_pop": str(v.eligible),
            "l_gps": f"{v.lat} {v.lon} 0 5",
            "l_submitting_report": f"Recorder {v.recorder_id}",
            "l_additional_note": "",
        }, s, e, start_date.isoformat()))
    return recs


def _form2_records(villages, cfg, received, start_date):
    recs = []
    hfs = sorted({v.hf for v in villages})
    n = len(hfs)
    base_ivm, rem_ivm = divmod(received["ivm"], n)
    base_alb, rem_alb = divmod(received["alb"], n)
    s = _iso_dt(start_date - timedelta(days=1), 9, 0)
    e = _iso_dt(start_date - timedelta(days=1), 9, 20)
    for idx, hf in enumerate(hfs):
        ivm_hf = base_ivm + (rem_ivm if idx == 0 else 0)
        alb_hf = base_alb + (rem_alb if idx == 0 else 0)
        recs.append(SubmissionRecord("2_part", {
            "p_recorder_id": "01",
            "p_state": cfg.province,
            "p_district": villages[0].district,
            "p_health_facility": hf,
            "p_disease": " ".join(cfg.diseases),
            "p_medicine": cfg.medicine,
            "p_total_ivm": str(ivm_hf),
            "p_total_alb": str(alb_hf),
            "p_total_pzq": "0", "p_total_meb": "0", "p_total_dec": "0",
            "p_total_az_sus": "0", "p_total_az_tab": "0", "p_total_tetra": "0",
            "p_add_note": "",
        }, s, e, (start_date - timedelta(days=1)).isoformat()))
    return recs


def _form3_records(villages, cfg, start_date):
    recs = []
    for v in villages:
        for day in range(cfg.campaign_days):
            d = start_date + timedelta(days=day)
            frac = [0.45, 0.35, 0.20][day] if cfg.campaign_days == 3 else 1.0 / cfg.campaign_days
            ts = v.treated_by_band_sex
            day_men = int(round((ts["15_male"]) * frac))
            day_women = int(round((ts["15_female"]) * frac))
            vals = {
                "p_recorder_id": v.recorder_id,
                "p_state": cfg.province, "p_district": v.district,
                "p_health_facility": v.hf, "p_location": v.name,
                "p_location_id": v.location_id,
                "p_campaign_day": f"Day {day + 1}",
                "p_disease": " ".join(cfg.diseases),
                "p_medicine": cfg.medicine,
                "census_method": "Aggregate Reporting ",
                "census_house_hold": str(max(1, v.total_pop // 6)),
                "census_men": str(v.age_bands["15_plus"] // 2),
                "census_women": str(v.age_bands["15_plus"] - v.age_bands["15_plus"] // 2),
                # IVM cube
                "ivm_5_14_female_treated": str(int(round(ts["5_14_female"] * frac))),
                "ivm_5_14_male_treated": str(int(round(ts["5_14_male"] * frac))),
                "ivm_15_female_treated": str(day_women),
                "ivm_15_male_treated": str(day_men),
                "ivm_men_treated": str(day_men),
                "ivm_women_treated": str(day_women),
                # reasons not treated only logged day 1
                "ivm_child": str(v.not_treated["child"] if day == 0 else 0),
                "ivm_pregnant": str(v.not_treated["pregnant"] if day == 0 else 0),
                "ivm_breastfeeding": str(v.not_treated["breastfeeding"] if day == 0 else 0),
                "ivm_absent": str(v.not_treated["absent"] if day == 0 else 0),
                "ivm_refusal": str(v.not_treated["refusal"] if day == 0 else 0),
                "cd_who_distributed_man": str(R.cdd_count(v.total_pop)),
                "cd_who_distributed_woman": str(R.cdd_count(v.total_pop)),
                "cd_trained": str(max(1, R.cdd_count(v.total_pop) // 2)),
                "cd_recycled": str(R.cdd_count(v.total_pop) // 2),
                "p_add_note": "",
            }
            recs.append(SubmissionRecord("3_med_treatment", vals,
                                         _iso_dt(d, 9, 0), _iso_dt(d, 16, 0), d.isoformat()))
    return recs


def _form4_records(villages, cfg, distributed, start_date):
    recs = []
    hfs = sorted({v.hf for v in villages})
    end_date = start_date + timedelta(days=cfg.campaign_days)
    for idx, hf in enumerate(hfs):
        hf_villages = [v for v in villages if v.hf == hf]
        treated = sum(v.treated for v in hf_villages)
        minor = int(round(treated * R.MINOR_AE_RATE))
        serious = round(treated * R.SERIOUS_AE_RATE)
        recs.append(SubmissionRecord("4_case_mngnt", {
            "p_state": cfg.province, "p_district": hf_villages[0].district,
            "p_health_facility": hf,
            "p_disease": " ".join(cfg.diseases), "p_medicine": cfg.medicine,
            "p_total_ivm_dist": str(treated * 2),
            "p_total_alb_dist": str(sum(v.alb_distributed for v in hf_villages)),
            "p_total_pzq_dist": "0", "p_total_meb_dist": "0", "p_total_dec_dist": "0",
            "p_total_az_sus_dist": "0", "p_total_az_tab_dist": "0", "p_total_tetra_dist": "0",
            "p_minor_side_effect": str(minor),
            "p_serious_side_effect": str(serious),
            "p_guinea_worm_rumor": "0", "p_leish_suspect": "0",
            "p_buruli_ulcer_suspect": "0", "p_Lymphoedema_LF": str(idx),
            "P_hydrocele_LF": "0", "p_add_note": "",
        }, _iso_dt(end_date, 10, 0), _iso_dt(end_date, 10, 30), end_date.isoformat()))
    return recs


def _form5_records(villages, cfg, received, distributed, start_date):
    total = len(villages)
    treated_v = sum(1 for v in villages if v.treated_flag)
    end_date = start_date + timedelta(days=cfg.campaign_days)
    remain_ivm = received["ivm"] - distributed["ivm"]
    vals = {
        "s_recorder_id": "01", "s_state": cfg.province,
        "s_district": villages[0].district, "s_health_facility": villages[0].hf,
        "s_location": villages[0].name, "s_supervisor_Level": "District",
        "s_date_start": cfg.campaign_start, "s_date_end": end_date.isoformat(),
        "s_disease": " ".join(cfg.diseases), "s_medicine": cfg.medicine,
        "s_nb_villages_total": str(total),
        "s_nb_villages_treated": str(treated_v),
        "s_nb_villages_non_treated": str(total - treated_v),
        "s_reason_non_treatment": "Insecurity",
        "s_stock_remain_ivm": _yn(remain_ivm > 0),
        "s_stock_expired_ivm": "No", "s_stock_concordance_ivm": "Yes",
        "s_stock_remain_alb": "Yes", "s_stock_expired_alb": "No",
        "s_stock_concordance_alb": "Yes",
        "s_dc_trained_h": "8", "s_dc_trained_f": "6", "s_manual_used": "Yes",
        "s_population_informed": "Yes",
        "s_chanel_utilises": "Radio Community.leaders Town.criers",
        "s_dc_supervised": "12", "s_villages_supervised": str(treated_v),
        "s_side_effect": "Yes", "s_sever_side_effect": "No",
        "s_difficultes": "Difficult access to one village (insecurity).",
        "s_solutions": "Reschedule with security escort.",
        "s_recommandations": "Pre-position stock earlier.",
    }
    # zero out the unused-drug stock fields the form carries
    for drug in ("meb", "dec", "pzq", "az_sus", "az_tab", "tetra"):
        vals[f"s_stock_remain_{drug}"] = "No"
        vals[f"s_stock_expired_{drug}"] = "No"
        vals[f"s_stock_concordance_{drug}"] = "Yes"
    return [SubmissionRecord("5_supervision_hf", vals,
                             _iso_dt(end_date, 11, 0), _iso_dt(end_date, 12, 0),
                             end_date.isoformat())]


def _form6_records(villages, cfg, start_date, rng):
    recs = []
    observed = [v for v in villages if v.treated_flag][:2]
    yn = lambda p: "Yes" if rng.random() < p else "No"
    for v in observed:
        d = start_date + timedelta(days=1)
        recs.append(SubmissionRecord("6_supervision_CDD", {
            "s_supervisor": "District", "s_state": cfg.province, "s_district": v.district,
            "s_health_facility": v.hf, "s_location": v.name,
            "s_date_start": cfg.campaign_start,
            "s_date_end": (start_date + timedelta(days=cfg.campaign_days)).isoformat(),
            "s_disease": " ".join(cfg.diseases), "s_medicine": cfg.medicine,
            "s_medicine_sufficient": "Yes",
            "s_total_dist_trained_male": "2", "s_total_dist_trained_female": "2",
            "s_total_dist": "4",
            "s_hieght_chart": "Yes", "s_register": "Yes",
            "s_records_checklist": "Yes", "s_med_bag": "Yes",
            "s_wear_vest": yn(0.8), "s_usual_greetings": "Yes",
            "s_introduced_patient": "Yes", "s_used_height_chart_correctly": yn(0.9),
            "s_gave_write_dosage": "Yes", "s_medicine_took_in_front_of_dc": "Yes",
            "s_filled_form": "Yes", "s_investigated_cases": yn(0.7),
            "s_identified_ineligible": "Yes", "s_follow_side_effect_procedure": yn(0.8),
            "s_date_training": (start_date - timedelta(days=3)).isoformat(),
            "s_traning_duration": "2",
            "s_training_topic": "Using.the.measuring.stick Completing.the.checklists Marking.concessions",
            "s_took_med_in_training": "Yes", "s_complete_form": "Yes",
            "s_case_mngt": "Yes", "s_has_inegidible": "Yes", "s_follow_side_effect": "Yes",
            "s_difficultes": "", "s_solutions": "", "s_recommandations": "",
        }, _iso_dt(d, 13, 0), _iso_dt(d, 13, 40), d.isoformat()))
    return recs


def _assert_invariants(villages, received, distributed):
    for v in villages:
        assert sum(v.age_bands.values()) == v.total_pop, f"age bands {v.name}"
        if v.treated_flag:
            assert v.treated + sum(v.not_treated.values()) <= v.eligible, f"coverage {v.name}"
            cube = sum(v.treated_by_band_sex.values())
            assert abs(cube - v.treated) <= 2, f"cube vs treated {v.name}"
    assert distributed["ivm"] <= received["ivm"], "ivm distributed>received"
    assert distributed["alb"] <= received["alb"], "alb distributed>received"
