from datetime import date

from campaign_builder.build import build
from campaign_builder.config import load_config


def _bundle():
    return build(load_config(), date(2026, 9, 7))


def test_results_are_deterministic_and_linked():
    a, b = _bundle(), _bundle()
    ra, rb = a["06-coverage-reports"], b["06-coverage-reports"]
    assert [r["id"] for r in ra] == [r["id"] for r in rb]
    assert [r["group"][0]["measureScore"]["value"] for r in ra] == [r["group"][0]["measureScore"]["value"] for r in rb]
    plan_ids = {cp["id"] for cp in a["05-care-plans"]}
    for r in ra:
        campaign = next(e for e in r["extension"] if e["url"].endswith("/campaign"))["valueReference"]["reference"].split("/")[1]
        assert campaign in plan_ids


def test_report_kinds_and_shapes():
    reports = _bundle()["06-coverage-reports"]
    by_source = {}
    for r in reports:
        src = next(e for e in r["extension"] if e["url"].endswith("/coverage-source"))["valueCode"]
        by_source.setdefault(src, []).append(r)
    assert set(by_source) == {"administrative", "survey", "lqas"}
    # every survey report carries a structured confidence interval or, for LQAS, a disposition
    for r in by_source["survey"]:
        assert any(e["url"].endswith("/confidence-interval") for e in r["extension"])
    for r in by_source["lqas"]:
        codes = [st["code"][0]["coding"][0]["code"] for st in r["group"][0]["stratifier"]]
        assert codes == ["sex", "age-band", "disposition"]  # exactly the survey Measure's stratifiers
        assert any("lot " in st["value"]["text"] for st in r["group"][0]["stratifier"][2]["stratum"])
    # planned rounds have no results; active rounds have realtime reports only
    lineages = {next(e for e in r["extension"] if e["url"].endswith("/realtime-vs-reconciled"))["valueCode"] for r in by_source["administrative"]}
    assert lineages == {"realtime", "reconciled"}


def test_admin_coverage_is_plausible():
    reports = _bundle()["06-coverage-reports"]
    admin = [r for r in reports if r["id"].startswith("nga-demo-cov-admin-")]
    scores = sorted(r["group"][0]["measureScore"]["value"] for r in admin)
    median = scores[len(scores) // 2]
    assert 0.80 <= median <= 1.00
    assert any(s > 1 for s in scores)             # denominator undercounts exist
    assert scores[0] < 0.6                         # and so do bad rounds
    assert all(s < 1.4 for s in scores)
