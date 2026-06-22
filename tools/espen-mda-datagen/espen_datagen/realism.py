"""Sourced realism parameters for the ESPEN oncho/LF IVM campaign.

Two source classes are tagged per constant:
  [ESPEN]  = mined from in-repo ESPEN Collect Training Package / Country Deck.
  [WHO]    = WHO PC-NTD / Mectizan dose-pole / APOC CDTI guidance (clinical numbers
             the ESPEN docs omit). Approximate, demo-calibrated; confirm with an NTD SME.
"""
from __future__ import annotations

# Form age bands [ESPEN: demo_mda_9999_3 treatment form uses 5-14 / 15+; 1-4 implicit].
AGE_BANDS = ["1_4", "5_14", "15_plus"]

# Sub-Saharan / DRC age pyramid [WHO/UN demographics, approx]; sums to 1.0.
AGE_PYRAMID = {"1_4": 0.13, "5_14": 0.29, "15_plus": 0.58}

# Eligible ≈ community minus structurally ineligible (<90cm/under-5 + pregnant) [WHO].
ELIGIBLE_FRACTION = 0.80

# Epidemiological coverage band [WHO: oncho elimination target >=80%; demo 70-85%].
COVERAGE_BAND = (0.70, 0.85)

# Mectizan dose-pole bands (min_cm, max_cm inclusive, tablets of 3 mg) [WHO].
DOSE_POLE_BANDS = [(90, 119, 1), (120, 140, 2), (141, 158, 3), (159, 999, 4)]

# Not-treated reason mix — absent dominates real registers [ESPEN taxonomy + field norm].
NOT_TREATED_WEIGHTS = {
    "absent": 0.55,
    "refusal": 0.15,
    "child": 0.15,        # child <90 cm (too short to dose)
    "pregnant": 0.10,
    "breastfeeding": 0.05,
}

# Adverse-event rates among treated [WHO: minor Mazzotti low; serious rare].
MINOR_AE_RATE = 0.03           # ~3% report minor reactions
SERIOUS_AE_RATE = 0.00008      # ~1 per 12,500 (Loa loa SAE risk exists in DRC)

# CDD staffing [WHO/APOC: ~1 distributor per few hundred people].
CDD_PER_POPULATION = 350

# Rural village total-population spread [ESPEN demo scale].
VILLAGE_POP_RANGE = (250, 2800)

# IVM dosing already height-based; ALB co-admin is one 400 mg tablet per eligible person.
ALB_TABLETS_PER_PERSON = 1

# Social-mobilisation channels [ESPEN supervision form choices].
COMM_CHANNELS = ["Radio", "Town.criers", "Community.leaders", "Schools", "Posters"]


def dose_pole_tablets(height_cm: float) -> int:
    h = int(height_cm)  # dose poles are read at integer-cm marks
    if h < 90:
        return 0
    for lo, hi, tabs in DOSE_POLE_BANDS:
        if lo <= h <= hi:
            return tabs
    return 0


def split_age_bands(total: int) -> dict[str, int]:
    out = {b: int(round(total * AGE_PYRAMID[b])) for b in AGE_BANDS}
    # fix rounding drift onto the largest band
    drift = total - sum(out.values())
    out["15_plus"] += drift
    return out


def sample_coverage(rng) -> float:
    lo, hi = COVERAGE_BAND
    return lo + (hi - lo) * rng.random()


def split_not_treated(n: int, rng) -> dict[str, int]:
    reasons = list(NOT_TREATED_WEIGHTS)
    if n <= 0:
        return {r: 0 for r in reasons}
    weights = [NOT_TREATED_WEIGHTS[r] for r in reasons]
    counts = {r: 0 for r in reasons}
    for _ in range(n):
        counts[rng.choices(reasons, weights=weights, k=1)[0]] += 1
    return counts


def cdd_count(population: int) -> int:
    return max(1, round(population / CDD_PER_POPULATION))
