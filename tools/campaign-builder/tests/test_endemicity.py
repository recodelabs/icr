from datetime import date

from campaign_builder.build import build
from campaign_builder.config import load_config


def test_endemicity_assertions_match_the_programme_lists():
    cfg = load_config()
    b = build(cfg, date(2026, 9, 7))
    obs = b["07-location-status"]
    # 119 LGAs × 5 diseases baseline assertions, plus transitions
    baseline = [o for o in obs if o["id"].endswith("-2022")]
    assert len(baseline) == 119 * 5
    by = {}
    for o in obs:
        by.setdefault((o["subject"]["reference"], o["code"]["coding"][0]["code"]), []).append(o)
    # Bade (Yobe) passed LF TAS in 2017: post-MDA surveillance at baseline, never under MDA in the window
    bade = by[("Location/nga-yo-701", "lf-endemicity")]
    assert bade[0]["valueCodeableConcept"]["coding"][0]["code"] == "post-mda-surveillance"
    # Yobe trachoma LGAs: endemic under MDA in 2022, then a transition after the 2023 round
    nguru = sorted(by[("Location/nga-yo-713", "trachoma-endemicity")], key=lambda o: o["effectiveDateTime"])
    assert [o["valueCodeableConcept"]["coding"][0]["code"] for o in nguru] == ["endemic-under-mda", "post-mda-surveillance"]
    assert nguru[1]["effectiveDateTime"].startswith("2024")
    # Kano Municipal: LF non-endemic (urban), with a baseline prevalence component below 1%
    km = by[("Location/nga-kn-20043", "lf-endemicity")][0]
    assert km["valueCodeableConcept"]["coding"][0]["code"] in ("non-endemic", "unknown")
    # every endemic assertion carries a baseline prevalence figure
    for o in baseline:
        if o["valueCodeableConcept"]["coding"][0]["code"] == "endemic-under-mda":
            assert o["component"][0]["valueQuantity"]["value"] > 0
