from espen_datagen.scenario import build_campaign
from espen_datagen.report import compute_indicators, format_report
from espen_datagen import realism as R


def test_indicators_within_expected_bands():
    ind = compute_indicators(build_campaign())
    lo, hi = R.COVERAGE_BAND
    assert lo - 0.1 <= ind["epi_coverage"] <= hi + 0.1
    assert 0 < ind["geo_coverage"] <= 1.0
    assert abs(sum(ind["age_distribution"].values()) - 1.0) < 1e-6
    assert ind["ivm_stock_balance"]["remaining"] >= 0
    assert ind["serious_ae_total"] <= 2
    assert 0.0 <= ind["minor_ae_rate"] <= 0.10
    assert ind["epi_coverage"] <= 1.0 + 1e-9


def test_ae_totals_derived_from_form4():
    camp = build_campaign()
    expected_serious = sum(int(r.values["p_serious_side_effect"])
                           for r in camp.records if r.form_key == "4_case_mngnt")
    ind = compute_indicators(camp)
    assert ind["serious_ae_total"] == expected_serious


def test_format_report_mentions_coverage():
    ind = compute_indicators(build_campaign())
    text = format_report(ind)
    assert "coverage" in text.lower()
    assert "%" in text
