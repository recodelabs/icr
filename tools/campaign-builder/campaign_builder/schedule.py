"""Expand the schedule (rounds + series) into concrete per-LGA windows."""

from __future__ import annotations

import hashlib
from dataclasses import dataclass
from datetime import date, timedelta

from .config import Config, Lga


@dataclass(frozen=True)
class LgaWindow:
    lga: Lga
    start: date
    end: date
    batch: int  # 0-based batch/wave index (0 for jitter/none)


@dataclass(frozen=True)
class StateRound:
    state_code: str
    protocol: str
    windows: list[LgaWindow]

    @property
    def start(self) -> date:
        return min(w.start for w in self.windows)

    @property
    def end(self) -> date:
        return max(w.end for w in self.windows)


@dataclass(frozen=True)
class Round:
    id: str
    programme: str
    title: str
    round_number: int
    year: int
    nominal_start: date
    duration_days: int
    states: list[StateRound]

    @property
    def start(self) -> date:
        return min(s.start for s in self.states)

    @property
    def end(self) -> date:
        return max(s.end for s in self.states)

    @property
    def multi_state(self) -> bool:
        return len(self.states) > 1


def _stable_int(*parts: str, mod: int) -> int:
    """Deterministic pseudo-random integer in [0, mod) from a string key."""
    h = hashlib.sha256("|".join(parts).encode()).digest()
    return int.from_bytes(h[:4], "big") % mod


def _stable_order(round_id: str, lgas: list[Lga]) -> list[Lga]:
    """A deterministic shuffle so batch membership looks operational, not
    alphabetical, and differs between rounds."""
    return sorted(lgas, key=lambda l: _stable_int(round_id, l.id, mod=1_000_000))


def _windows(round_id: str, lgas: list[Lga], start: date, duration: int, stagger: dict) -> list[LgaWindow]:
    kind = (stagger or {}).get("kind", "none")
    out: list[LgaWindow] = []
    if kind == "none":
        for l in lgas:
            out.append(LgaWindow(l, start, start + timedelta(days=duration - 1), 0))
    elif kind == "jitter":
        max_days = int(stagger.get("max_days", 0))
        for l in lgas:
            # Most LGAs start on time; a minority slip. Weight the draw so that
            # ~60% land on day 0 when max_days == 2.
            draw = _stable_int(round_id, l.id, "jitter", mod=10)
            slip = 0 if draw < 6 else min(max_days, 1 + (draw - 6) * max_days // 4)
            s = start + timedelta(days=slip)
            out.append(LgaWindow(l, s, s + timedelta(days=duration - 1), 0))
    elif kind == "batches":
        count = max(1, int(stagger.get("count", 1)))
        gap = int(stagger.get("gap_days", 0))
        ordered = _stable_order(round_id, lgas)
        for i, l in enumerate(ordered):
            batch = i % count
            s = start + timedelta(days=batch * gap)
            out.append(LgaWindow(l, s, s + timedelta(days=duration - 1), batch))
    else:
        raise ValueError(f"{round_id}: unknown stagger kind {kind!r}")
    return sorted(out, key=lambda w: (w.start, w.lga.name))


def _expand_round(cfg: Config, spec: dict, year: int, start: date, title: str, round_number: int) -> Round | None:
    prog = cfg.programmes[spec["programme"]]
    protocol_by_state = spec.get("protocol_by_state", {}) or {}
    lga_sel = spec.get("lgas")
    states: list[StateRound] = []
    for code in spec["states"]:
        selector = lga_sel.get(code) if isinstance(lga_sel, dict) else lga_sel
        lgas = cfg.lgas_for(code, selector, year)
        if not lgas:
            continue  # programme has stopped in this state this year
        windows = _windows(f"{spec['id']}-{year}", lgas, start, int(spec["duration_days"]), spec.get("stagger"))
        states.append(StateRound(code, protocol_by_state.get(code, prog["protocol"]), windows))
    if not states:
        return None
    return Round(id=spec["id"] if "years" not in spec else f"{spec['id']}-{year}",
                 programme=spec["programme"], title=title, round_number=round_number,
                 year=year, nominal_start=start, duration_days=int(spec["duration_days"]), states=states)


def expand(cfg: Config) -> list[Round]:
    rounds: list[Round] = []
    for spec in cfg.rounds:
        start: date = spec["start"]
        r = _expand_round(cfg, spec, start.year, start, spec["title"], int(spec.get("round", 1)))
        if r:
            rounds.append(r)
    for spec in cfg.series:
        md = spec["start_md"]
        month, day = (int(x) for x in md.split("-"))
        shift_max = int(spec.get("start_shift_days", 0))
        for n, year in enumerate(spec["years"], start=1):
            base = date(year, month, day)
            # Real programmes never start on the same calendar day two years running.
            shift = _stable_int(spec["id"], str(year), "shift", mod=shift_max + 1) if shift_max else 0
            start = base + timedelta(days=shift)
            title = spec["title"].format(year=year)
            r = _expand_round(cfg, spec, year, start, title, n)
            if r:
                rounds.append(r)
    rounds.sort(key=lambda r: (r.start, r.id))
    return rounds
