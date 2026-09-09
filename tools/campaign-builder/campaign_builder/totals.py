"""Total-population denominators from the census anchors, one Group per state
and LGA for a year — the census-projection counterpart to the WorldPop Groups
`kiln population` writes.

    python -m campaign_builder.totals [--year 2026] [--out FILE]

The age-band Groups `build` emits are what the campaigns plan against; they
carry a band fraction, so none of them is an all-ages figure. These Groups are:
`denominator-type = total-population`, no age band, `denominator-source =
census-projection`, `is-calculated = true` (interpolated, and states are the
sum of their LGAs), `is-planning-denominator = false` (WorldPop is the planning
denominator; these exist for the comparison). Ids follow kiln's scheme —
`pop-census-projection-<year>-<locationId>` — so the same Location's two
estimates sit side by side in the `target_population` view and in HAPI.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from .config import CONFIG_DIR, Config, Lga, State, load_config
from .fhir import DENOM_SOURCE, GROUP_CHAR, SD, cc, meta
from .population import total_population

DENOM_TYPE_URL = f"{SD}/denominator-type"
DEFAULT_OUT = Path(__file__).resolve().parent.parent / "out" / "08-total-populations.ndjson"


def group_id(year: int, location_id: str) -> str:
    return f"pop-census-projection-{year}-{location_id}"


def total_group(cfg: Config, unit: Lga | State, year: int, quantity: int) -> dict:
    scope = f"{unit.name} LGA" if isinstance(unit, Lga) else f"{unit.name} State"
    return {
        "resourceType": "Group", "id": group_id(year, unit.id), "meta": meta(cfg, "ICRTargetPopulation"),
        "type": "person", "actual": False,
        "name": f"Total population, {scope}, {year} (census projection)",
        "quantity": quantity,
        "characteristic": [
            {"code": cc(GROUP_CHAR, "geography", "Geographic scope"),
             "valueReference": {"reference": f"Location/{unit.id}", "display": scope}, "exclude": False},
        ],
        "extension": [
            {"url": f"{SD}/denominator-source",
             "valueCodeableConcept": cc(DENOM_SOURCE, "census-projection", "Census projection",
                                        text=f"NPC 2006 census and 2022 projection, geometric interpolation to {year}"
                                             + ("; state = sum of its LGAs" if isinstance(unit, State) else ""))},
            # A bare code in the IG (value[x] only code), unlike denominator-source.
            {"url": DENOM_TYPE_URL, "valueCode": "total-population"},
            {"url": f"{SD}/estimate-date", "valueDate": f"{year}-01-01"},
            {"url": f"{SD}/is-planning-denominator", "valueBoolean": False},
            {"url": f"{SD}/is-calculated", "valueBoolean": True},
        ],
    }


def total_groups(cfg: Config, year: int) -> list[dict]:
    """One Group per LGA (interpolated) and per state (sum of its LGAs, so the
    two levels are exactly additive, as kiln's rollup is)."""
    out: list[dict] = []
    for state in cfg.states.values():
        lga_totals = {lga.id: total_population(lga, year) for lga in state.lgas.values()}
        out.extend(total_group(cfg, lga, year, lga_totals[lga.id]) for lga in state.lgas.values())
        out.append(total_group(cfg, state, year, sum(lga_totals.values())))
    return out


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--year", type=int, default=2026)
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    ap.add_argument("--config", type=Path, default=CONFIG_DIR)
    args = ap.parse_args()
    cfg = load_config(args.config)
    groups = total_groups(cfg, args.year)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w") as fh:
        for g in groups:
            fh.write(json.dumps(g) + "\n")
    n_states = sum(1 for g in groups if g["name"].split(", ")[1].endswith("State"))
    print(f"Wrote {len(groups)} Groups ({len(groups) - n_states} LGAs, {n_states} states) for {args.year} to {args.out}")


if __name__ == "__main__":
    main()
