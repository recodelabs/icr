from datetime import date

from campaign_builder.build import build
from campaign_builder.config import load_config
from campaign_builder.population import total_population
from campaign_builder.schedule import expand


def test_config_loads_and_lga_names_resolve():
    cfg = load_config()
    assert len(cfg.states) == 5
    assert sum(len(s.lgas) for s in cfg.states.values()) == 119


def test_population_anchors_are_honoured():
    cfg = load_config()
    kano = cfg.states["kn"]
    assert total_population(kano, 2022) == kano.projection_2022
    assert total_population(kano, 2006) == kano.census_2006
    assert total_population(kano, 2027) > kano.projection_2022


def test_expansion_is_deterministic_and_staggered():
    cfg = load_config()
    a, b = expand(cfg), expand(cfg)
    assert [(r.id, r.start, r.end) for r in a] == [(r.id, r.start, r.end) for r in b]
    mr = next(r for r in a if r.id == "mr-2025")
    starts = {w.start for s in mr.states for w in s.windows}
    assert len(starts) == 3  # three waves
    assert mr.start == date(2025, 10, 6)


def test_programmes_stop_when_endemicity_says_so():
    cfg = load_config()
    ids = {r.id for r in expand(cfg)}
    assert "trachoma-yo-2023" in ids and "trachoma-yo-2024" not in ids
    assert "lf-yo-2025" in ids and "lf-yo-2026" not in ids


def test_status_split_around_as_of():
    cfg = load_config()
    bundle = build(cfg, date(2026, 9, 7))
    plans = bundle["05-care-plans"]
    statuses = {cp["status"] for cp in plans}
    assert statuses == {"completed", "active", "draft"}
    active = [cp for cp in plans if cp["status"] == "active"]
    assert all("September 2026" in cp["title"] for cp in active)
    # Every LGA plan points at a state plan that exists, and every state plan of a
    # multi-state round points at a national plan that exists.
    ids = {cp["id"] for cp in plans}
    for cp in plans:
        for p in cp.get("partOf", []):
            assert p["reference"].split("/")[1] in ids
    # Every subject Group exists.
    gids = {g["id"] for g in bundle["04-target-populations"]}
    assert all(cp["subject"]["reference"].split("/")[1] in gids for cp in plans)
