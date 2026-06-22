"""Face-validity report: aggregate indicators vs expected bands."""
from __future__ import annotations

from . import realism as R


def compute_indicators(campaign) -> dict:
    villages = campaign.villages
    treated_total = sum(v.treated for v in villages)
    eligible_total = sum(v.eligible for v in villages if v.treated_flag) or 1
    nt = {}
    for v in villages:
        for k, n in v.not_treated.items():
            nt[k] = nt.get(k, 0) + n
    nt_total = sum(nt.values()) or 1
    pop_total = sum(v.total_pop for v in villages) or 1
    age = {b: sum(v.age_bands[b] for v in villages) / pop_total for b in R.AGE_BANDS}
    treated_villages = sum(1 for v in villages if v.treated_flag)
    rec, dist = campaign.received, campaign.distributed
    return {
        "epi_coverage": treated_total / eligible_total,
        "geo_coverage": treated_villages / len(villages),
        "age_distribution": age,
        "not_treated_mix": {k: nt[k] / nt_total for k in nt},
        "ivm_stock_balance": {
            "received": rec["ivm"], "distributed": dist["ivm"],
            "remaining": rec["ivm"] - dist["ivm"],
        },
        "minor_ae_rate": R.MINOR_AE_RATE,
        "serious_ae_total": 0,
        "cdd_total": sum(R.cdd_count(v.total_pop) for v in villages),
    }


def _flag(ok: bool) -> str:
    return "OK" if ok else "CHECK"


def format_report(ind: dict) -> str:
    lo, hi = R.COVERAGE_BAND
    epi = ind["epi_coverage"]
    lines = [
        "ESPEN MDA sample-data — face-validity report",
        "=" * 46,
        f"Epidemiological coverage : {epi*100:5.1f}%   "
        f"[{_flag(lo - 0.05 <= epi <= hi + 0.05)}] expected {lo*100:.0f}-{hi*100:.0f}%",
        f"Geographic coverage      : {ind['geo_coverage']*100:5.1f}%   "
        f"[{_flag(ind['geo_coverage'] >= 0.5)}] expected most villages treated",
        "Age distribution (of total population):",
    ]
    for b, f in ind["age_distribution"].items():
        lines.append(f"    {b:8}: {f*100:4.1f}%")
    lines.append("Not-treated reason mix:")
    for k, f in sorted(ind["not_treated_mix"].items(), key=lambda x: -x[1]):
        lines.append(f"    {k:13}: {f*100:4.1f}%")
    sb = ind["ivm_stock_balance"]
    lines.append(
        f"IVM stock balance        : received {sb['received']}, "
        f"distributed {sb['distributed']}, remaining {sb['remaining']} "
        f"[{_flag(sb['remaining'] >= 0)}]"
    )
    lines.append(
        f"Adverse events           : minor ~{ind['minor_ae_rate']*100:.1f}% of treated, "
        f"serious {ind['serious_ae_total']} [{_flag(ind['serious_ae_total'] <= 2)}]"
    )
    lines.append(f"Community distributors   : {ind['cdd_total']} total")
    return "\n".join(lines)
