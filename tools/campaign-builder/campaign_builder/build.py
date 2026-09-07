"""CLI: expand the schedule and write NDJSON + a report.

    python -m campaign_builder.build [--out DIR] [--as-of YYYY-MM-DD] [--config DIR]

Outputs (in --out, default tools/campaign-builder/out/):
    01-activity-definitions.ndjson
    02-eligibility-groups.ndjson
    03-plan-definitions.ndjson
    04-target-populations.ndjson
    05-care-plans.ndjson
    06-coverage-reports.ndjson   results: administrative / realtime / survey / LQAS MeasureReports
    calendar.csv       one row per LGA CarePlan (a quick preview of the calendar)
    report.md          counts by programme / year / state, plus overlaps
"""

from __future__ import annotations

import argparse
import csv
import json
from collections import Counter, defaultdict
from datetime import date
from pathlib import Path

from . import fhir
from .config import CONFIG_DIR, Config, load_config
from .population import band_population
from .results import build_results, load_results_config
from .schedule import Round, expand

DEFAULT_OUT = Path(__file__).resolve().parent.parent / "out"
DEFAULT_AS_OF = date(2026, 9, 7)


def _short(location_id: str) -> str:
    return location_id.removeprefix("nga-")


def build(cfg: Config, as_of: date) -> dict[str, list[dict]]:
    rounds = expand(cfg)
    activities = fhir.activity_definitions(cfg)
    eligibility = fhir.eligibility_groups(cfg)
    protocols = fhir.plan_definitions(cfg)

    populations: dict[str, dict] = {}
    care_plans: list[dict] = []

    def pop_group(unit, location_id: str, band_key: str, year: int) -> str:
        band = cfg.age_bands[band_key]
        gid = f"nga-demo-pop-{band_key.replace('_', '')}-{year}-{_short(location_id)}"
        if gid not in populations:
            populations[gid] = fhir.population_group(cfg, unit, location_id, band, year,
                                                     band_population(unit, year, band), gid)
        return gid

    for r in rounds:
        prog = cfg.programmes[r.programme]
        band_key = prog["age_band"]
        ctype = prog["campaign_type"]
        # Activity types for the integrated rounds (category carries every intervention type).
        extra_types = ["vaccination-sia"] if ctype == "integrated" else []
        if ctype == "integrated" and any(s.protocol.endswith("ntd-integrated") for s in r.states):
            extra_types.append("mda")

        national_id = None
        if r.multi_state:
            national_id = f"nga-demo-{r.id}"
            names = ", ".join(cfg.states[s.state_code].name for s in r.states)
            # National umbrella: its own denominator is the sum over the states in scope.
            gid = f"nga-demo-pop-{band_key.replace('_', '')}-{r.year}-{r.id}"
            band = cfg.age_bands[band_key]
            total = sum(band_population(cfg.states[s.state_code], r.year, band) for s in r.states)
            if gid not in populations:
                populations[gid] = fhir.population_group(cfg, _Scope(names), cfg.country_location, band, r.year, total, gid)
                populations[gid]["name"] = f"{band.label}, {names} ({r.year}, {r.title})"
            care_plans.append(fhir.care_plan(
                cfg, cid=national_id, title=f"{r.title} — {names}",
                description=f"{prog['label']}: {r.title}. Umbrella across {len(r.states)} states; "
                            f"each state and LGA has its own round CarePlan (partOf).",
                protocol=r.states[0].protocol, campaign_type=ctype, subject_group=gid,
                start=r.start, end=r.end, as_of=as_of, geography_id=cfg.country_location, geography_name="Nigeria",
                round_number=r.round_number, part_of=None, created_lead_days=75, activity_types=extra_types))

        for sr in r.states:
            state = cfg.states[sr.state_code]
            state_cid = f"nga-demo-{r.id}-{sr.state_code}"
            sgid = pop_group(state, state.id, band_key, r.year)
            care_plans.append(fhir.care_plan(
                cfg, cid=state_cid, title=f"{r.title} — {state.name} State",
                description=f"{prog['label']}: {r.title}, {state.name} State, {len(sr.windows)} LGAs "
                            f"({sr.start:%d %b} – {sr.end:%d %b %Y}).",
                protocol=sr.protocol, campaign_type=ctype, subject_group=sgid,
                start=sr.start, end=sr.end, as_of=as_of, geography_id=state.id, geography_name=f"{state.name} State",
                round_number=r.round_number, part_of=national_id, created_lead_days=60, activity_types=extra_types))
            for w in sr.windows:
                lgid = pop_group(w.lga, w.lga.id, band_key, r.year)
                care_plans.append(fhir.care_plan(
                    cfg, cid=f"nga-demo-{r.id}-{_short(w.lga.id)}",
                    title=f"{r.title} — {w.lga.name} LGA, {state.name}",
                    description=f"{prog['label']} ({prog['disease']}): {r.title}. {w.lga.name} LGA, "
                                f"{state.name} State, wave {w.batch + 1}.",
                    protocol=sr.protocol, campaign_type=ctype, subject_group=lgid,
                    start=w.start, end=w.end, as_of=as_of, geography_id=w.lga.id, geography_name=f"{w.lga.name} LGA",
                    round_number=r.round_number, part_of=state_cid, created_lead_days=45, activity_types=extra_types))

    reports, results_summary = build_results(cfg, load_results_config(cfg_dir(cfg)), rounds, populations, as_of, _short)

    return {
        "01-activity-definitions": activities,
        "02-eligibility-groups": eligibility,
        "03-plan-definitions": protocols,
        "04-target-populations": list(populations.values()),
        "05-care-plans": care_plans,
        "06-coverage-reports": reports,
        "_rounds": rounds,  # not written as NDJSON; used by the report
        "_results_summary": results_summary,
    }


def cfg_dir(cfg: Config) -> Path:
    return getattr(cfg, "config_dir", CONFIG_DIR)


class _Scope:
    """Minimal stand-in so population_group can name a multi-state scope."""
    def __init__(self, name: str):
        self.name = name


def write_outputs(cfg: Config, bundle: dict, out: Path, as_of: date) -> None:
    out.mkdir(parents=True, exist_ok=True)
    for key, resources in bundle.items():
        if key.startswith("_"):
            continue
        with (out / f"{key}.ndjson").open("w") as fh:
            for res in resources:
                fh.write(json.dumps(res, ensure_ascii=False) + "\n")

    rounds: list[Round] = bundle["_rounds"]

    with (out / "calendar.csv").open("w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["campaign_id", "programme", "round_id", "state", "lga_id", "lga", "start", "end", "status", "intent", "protocol"])
        for r in rounds:
            for sr in r.states:
                state = cfg.states[sr.state_code]
                for win in sr.windows:
                    cid = f"nga-demo-{r.id}-{_short(win.lga.id)}"
                    status, intent = fhir._status(win.start, win.end, as_of)
                    w.writerow([cid, r.programme, r.id, state.name, win.lga.id, win.lga.name,
                                win.start.isoformat(), win.end.isoformat(), status, intent, sr.protocol])

    (out / "report.md").write_text(_report(cfg, bundle, as_of))



def _report(cfg: Config, bundle: dict, as_of: date) -> str:
    rounds: list[Round] = bundle["_rounds"]
    plans = bundle["05-care-plans"]
    lines = [f"# Nigeria demo calendar — build report", "",
             f"As-of date: {as_of.isoformat()}  ·  rounds: {len(rounds)}  ·  CarePlans: {len(plans)}  ·  "
             f"target-population Groups: {len(bundle['04-target-populations'])}", ""]

    by_status = Counter(cp["status"] for cp in plans)
    lines += ["## CarePlans by status", "", "| status | count |", "|---|---|"]
    lines += [f"| {k} | {v} |" for k, v in sorted(by_status.items())]

    rs = bundle.get("_results_summary", {})
    reports = bundle.get("06-coverage-reports", [])
    lines += ["", "## Results (coverage MeasureReports)", "",
              f"{len(reports)} reports: {rs.get('admin', 0)} reconciled administrative, {rs.get('realtime', 0)} realtime (active round), "
              f"{rs.get('survey_state', 0)} state-level post-campaign surveys, {rs.get('lqas', 0)} LQAS lots, {rs.get('ces', 0)} NTD coverage evaluation surveys. "
              f"{rs.get('missing', 0)} LGA rounds have no administrative report (never submitted or not yet received); "
              f"{rs.get('incidents', 0)} rounds were hit by an incident (stock-out, security, late start); {rs.get('over100', 0)} LGA rounds report administrative coverage above 100%."]
    admin = [r for r in reports if r["extension"][1]["valueCode"] == "administrative" and r["extension"][2]["valueCode"] == "reconciled"]
    if admin:
        scores = sorted(r["group"][0]["measureScore"]["value"] for r in admin)
        q = lambda p: scores[min(len(scores) - 1, int(p * len(scores)))]
        lines += ["", "| admin coverage | p10 | p25 | median | p75 | p90 |", "|---|---|---|---|---|---|",
                  f"| all programmes | {q(.1):.0%} | {q(.25):.0%} | {q(.5):.0%} | {q(.75):.0%} | {q(.9):.0%} |"]

    lines += ["", "## LGA rounds by programme and year", ""]
    years = sorted({r.year for r in rounds})
    progs = list(cfg.programmes)
    table: dict[str, Counter] = defaultdict(Counter)
    for r in rounds:
        table[r.programme][r.year] += sum(len(s.windows) for s in r.states)
    lines.append("| programme | " + " | ".join(str(y) for y in years) + " |")
    lines.append("|---|" + "---|" * len(years))
    for p in progs:
        lines.append(f"| {cfg.programmes[p]['label']} | " + " | ".join(str(table[p].get(y, 0) or "") for y in years) + " |")

    lines += ["", "## Rounds", "", "| start | end | round | states | LGAs | status |", "|---|---|---|---|---|---|"]
    for r in rounds:
        n = sum(len(s.windows) for s in r.states)
        status, _ = fhir._status(r.start, r.end, as_of)
        lines.append(f"| {r.start} | {r.end} | {r.title} | {', '.join(s.state_code for s in r.states)} | {n} | {status} |")

    # Overlaps: same LGA, two different programmes, windows intersecting.
    lines += ["", "## Same-LGA overlaps between programmes (calendar collisions)", ""]
    windows = []
    for r in rounds:
        for sr in r.states:
            for w in sr.windows:
                windows.append((w.lga, r, w.start, w.end))
    by_lga = defaultdict(list)
    for lga, r, s, e in windows:
        by_lga[lga.id].append((r, s, e))
    overlaps = []
    for lid, items in by_lga.items():
        items.sort(key=lambda t: t[1])
        for i in range(len(items)):
            for j in range(i + 1, len(items)):
                r1, s1, e1 = items[i]
                r2, s2, e2 = items[j]
                if s2 > e1:
                    break
                if r1.programme != r2.programme:
                    overlaps.append((lid, r1, r2, max(s1, s2), min(e1, e2)))
    lines.append(f"{len(overlaps)} overlapping LGA-windows across programmes.")
    lines.append("")
    for lid, r1, r2, s, e in overlaps[:25]:
        lines.append(f"- {lid}: {r1.title} × {r2.title} ({s} – {e})")
    if len(overlaps) > 25:
        lines.append(f"- … and {len(overlaps) - 25} more")
    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    ap.add_argument("--as-of", type=date.fromisoformat, default=DEFAULT_AS_OF,
                    help="date that separates completed / active / planned (default %(default)s)")
    ap.add_argument("--config", type=Path, default=CONFIG_DIR)
    a = ap.parse_args(argv)

    cfg = load_config(a.config)
    bundle = build(cfg, a.as_of)
    write_outputs(cfg, bundle, a.out, a.as_of)
    plans = bundle["05-care-plans"]
    print(f"Wrote {len(plans)} CarePlans, {len(bundle['04-target-populations'])} target-population Groups, "
          f"{len(bundle['03-plan-definitions'])} PlanDefinitions, {len(bundle['06-coverage-reports'])} coverage MeasureReports to {a.out}")
    print(f"Status split: {dict(Counter(cp['status'] for cp in plans))}")
    print(f"See {a.out / 'report.md'} and {a.out / 'calendar.csv'}")


if __name__ == "__main__":
    main()
