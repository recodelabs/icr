"""Load and validate the three YAML inputs (states, endemicity, schedule)."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date
from pathlib import Path

import yaml

CONFIG_DIR = Path(__file__).resolve().parent.parent / "config"


@dataclass(frozen=True)
class Lga:
    id: str
    name: str
    state: str  # short code: ba, kn, ...
    census_2006: int
    projection_2022: int


@dataclass(frozen=True)
class State:
    code: str
    id: str
    name: str
    census_2006: int
    projection_2022: int
    lgas: dict[str, Lga] = field(default_factory=dict)  # by LGA id

    def by_name(self, name: str) -> Lga:
        for lga in self.lgas.values():
            if lga.name == name:
                return lga
        raise KeyError(f"{self.name}: no LGA named {name!r} in config/states.yaml")


@dataclass(frozen=True)
class AgeBand:
    key: str
    label: str
    low: int
    low_unit: str
    high: int | None
    high_unit: str
    fraction: float


@dataclass
class Config:
    country_location: str
    canonical_base: str
    dataset_tag: dict  # {system, code, display}
    age_bands: dict[str, AgeBand]
    states: dict[str, State]
    endemicity: dict
    programmes: dict
    rounds: list[dict]
    series: list[dict]
    config_dir: Path = CONFIG_DIR

    def lgas_for(self, state_code: str, selector, year: int) -> list[Lga]:
        """Resolve an LGA selector for one state and round year.

        `selector` is `all`, `endemicity:<programme>`, or a list of names.
        """
        state = self.states[state_code]
        if selector is None or selector == "all":
            return list(state.lgas.values())
        if isinstance(selector, str) and selector.startswith("endemicity:"):
            prog = selector.split(":", 1)[1]
            return self._endemic_lgas(prog, state, year)
        if isinstance(selector, list):
            return [state.by_name(n) for n in selector]
        raise ValueError(f"bad LGA selector {selector!r}")

    def _endemic_lgas(self, programme: str, state: State, year: int) -> list[Lga]:
        block = self.endemicity.get(programme, {}).get(state.code)
        if block is None:
            return []
        by_year = block.get("by_year", {})
        entry = by_year.get(year, by_year.get("default", []))
        exclude = set(block.get("exclude_always", []))
        for name in exclude:
            state.by_name(name)  # fail fast on typos
        if entry == "all":
            names = [l.name for l in state.lgas.values() if l.name not in exclude]
        else:
            names = [n for n in (entry or []) if n not in exclude]
        return [state.by_name(n) for n in names]


def _load_yaml(path: Path):
    with path.open() as fh:
        return yaml.safe_load(fh)


def load_config(config_dir: Path = CONFIG_DIR) -> Config:
    states_raw = _load_yaml(config_dir / "states.yaml")
    endemicity = _load_yaml(config_dir / "endemicity.yaml")
    schedule = _load_yaml(config_dir / "schedule.yaml")

    age_bands = {
        key: AgeBand(key=key, **spec) for key, spec in states_raw["age_bands"].items()
    }

    states: dict[str, State] = {}
    for code, s in states_raw["states"].items():
        lgas = {
            lid: Lga(id=lid, name=spec["name"], state=code,
                     census_2006=int(spec["census_2006"]),
                     projection_2022=int(spec["projection_2022"]))
            for lid, spec in s["lgas"].items()
        }
        states[code] = State(code=code, id=s["id"], name=s["name"],
                             census_2006=int(s["census_2006"]),
                             projection_2022=int(s["projection_2022"]), lgas=lgas)

    cfg = Config(
        country_location=states_raw["country_location"],
        canonical_base=states_raw["canonical_base"].rstrip("/"),
        dataset_tag=dict(states_raw["dataset_tag"]),
        age_bands=age_bands,
        states=states,
        endemicity=endemicity,
        programmes=schedule["programmes"],
        rounds=schedule.get("rounds", []),
        series=schedule.get("series", []),
        config_dir=config_dir,
    )
    _validate(cfg)
    return cfg


def _validate(cfg: Config) -> None:
    # Every endemicity name must exist; every programme/age band referenced must exist.
    for prog, by_state in cfg.endemicity.items():
        if prog == "assertions":  # the endemicity-assertion model, not a programme's LGA lists
            continue
        for code, block in by_state.items():
            state = cfg.states[code]
            for year, entry in block.get("by_year", {}).items():
                if entry != "all":
                    for name in entry or []:
                        state.by_name(name)
    for r in cfg.rounds:
        if r["programme"] not in cfg.programmes:
            raise ValueError(f"round {r['id']}: unknown programme {r['programme']}")
        if not isinstance(r["start"], date):
            raise ValueError(f"round {r['id']}: start must be a date")
    for s in cfg.series:
        if s["programme"] not in cfg.programmes:
            raise ValueError(f"series {s['id']}: unknown programme {s['programme']}")
    for p in cfg.programmes.values():
        if p["age_band"] not in cfg.age_bands:
            raise ValueError(f"unknown age band {p['age_band']}")
