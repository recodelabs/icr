from espen_datagen.scenario import build_campaign, Config


def test_determinism():
    a = build_campaign(Config(seed=123))
    b = build_campaign(Config(seed=123))
    av = [(r.form_key, r.values) for r in a.records]
    bv = [(r.form_key, r.values) for r in b.records]
    assert av == bv


def test_record_counts_by_form():
    c = build_campaign(Config(n_villages=12, campaign_days=3))
    by = {}
    for r in c.records:
        by[r.form_key] = by.get(r.form_key, 0) + 1
    assert by["1_location"] == 12                  # one per village
    assert by["3_med_treatment"] == 12 * 3         # village x day
    assert by["2_part"] == 3                        # one per HF
    assert by["4_case_mngnt"] == 3
    assert by["5_supervision_hf"] >= 1
    assert by["6_supervision_CDD"] >= 1


def test_invariant_treated_plus_not_treated_within_eligible():
    c = build_campaign()
    for v in c.villages:
        if not v.treated_flag:
            continue
        assert v.treated + sum(v.not_treated.values()) <= v.eligible


def test_invariant_distributed_le_received():
    c = build_campaign()
    # ALB distributed across all villages cannot exceed ALB received across HFs
    assert c.distributed["alb"] <= c.received["alb"]
    assert c.distributed["ivm"] <= c.received["ivm"]


def test_invariant_age_bands_sum_to_total():
    c = build_campaign()
    for v in c.villages:
        assert sum(v.age_bands.values()) == v.total_pop


def test_geo_anchored_in_ituri():
    c = build_campaign()
    assert c.config.province == "Ituri"
    # Ituri bounding box (approx): lat 0.5..3.5 N, lon 28..31 E
    for v in c.villages:
        assert 0.5 <= v.lat <= 3.5 and 28.0 <= v.lon <= 31.0


def test_form2_received_totals_reconcile():
    c = build_campaign()
    ivm = sum(int(r.values["p_total_ivm"]) for r in c.records if r.form_key == "2_part")
    alb = sum(int(r.values["p_total_alb"]) for r in c.records if r.form_key == "2_part")
    assert ivm == c.received["ivm"]
    assert alb == c.received["alb"]
