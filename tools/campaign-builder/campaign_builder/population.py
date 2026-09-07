"""Population estimates: geometric interpolation between the 2006 census and the
2022 NPC projection, then an age-band fraction.

Deliberately simple. The `denominator-source` written on every Group is
`census-projection` and `is-calculated` is true, so a WorldPop-derived
replacement can be dropped in later without changing the CarePlans.
"""

from __future__ import annotations

from .config import AgeBand, Lga, State


def total_population(unit: Lga | State, year: int) -> int:
    """Population of an LGA or state in `year`, from its 2006 and 2022 anchors."""
    p06, p22 = unit.census_2006, unit.projection_2022
    if p06 <= 0 or p22 <= 0:
        raise ValueError(f"{unit.name}: non-positive population anchors")
    annual_growth = (p22 / p06) ** (1 / 16)
    return round(p22 * annual_growth ** (year - 2022))


def band_population(unit: Lga | State, year: int, band: AgeBand) -> int:
    return round(total_population(unit, year) * band.fraction)
