"""CLI: generate one coherent ESPEN MDA campaign as ODK submission XML."""
from __future__ import annotations

import argparse
import os
import sys

from .forms import load_all
from .scenario import build_campaign, Config
from .render import write_campaign
from .report import compute_indicators, format_report

_DEFAULT_FORMS = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "..", "forms", "espen mda")
)
_DEFAULT_OUT = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "sample-data")
)


def run(forms_dir: str, out: str, cfg: Config) -> dict:
    schemas = load_all(forms_dir)
    campaign = build_campaign(cfg)
    manifest = write_campaign(campaign, schemas, out)
    manifest["_report"] = compute_indicators(campaign)
    return manifest


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description="ESPEN MDA sample-data generator")
    p.add_argument("--seed", type=int, default=Config.seed)
    p.add_argument("--villages", type=int, default=Config.n_villages)
    p.add_argument("--days", type=int, default=Config.campaign_days)
    p.add_argument("--out", default=_DEFAULT_OUT)
    p.add_argument("--forms-dir", default=_DEFAULT_FORMS)
    a = p.parse_args(argv)
    cfg = Config(seed=a.seed, n_villages=a.villages, campaign_days=a.days)
    schemas = load_all(a.forms_dir)
    campaign = build_campaign(cfg)
    manifest = write_campaign(campaign, schemas, a.out)
    print(f"Wrote {manifest['total_submissions']} submissions to {a.out}")
    print(format_report(compute_indicators(campaign)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
