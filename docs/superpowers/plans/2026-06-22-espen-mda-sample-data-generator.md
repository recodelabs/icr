# ESPEN MDA Sample-Data Generator — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a reproducible Python tool that generates one internally-consistent synthetic ESPEN MDA campaign (oncho/LF → ivermectin, Ituri/DRC) and emits it as ODK submission instance XML for the six `forms/espen mda/` XLSForms, loadable into Ona Data.

**Architecture:** Three layers + a realism profile. `forms.py` compiles each XLSForm → XForm (pyxform) and extracts a fillable `FormSchema`. `realism.py` holds all sourced domain constants. `scenario.py` builds one coherent campaign (cross-form invariants asserted) as `SubmissionRecord`s. `render.py` fills each form's instance template and writes one XML file per submission + a manifest. `report.py` prints a face-validity indicator report. `generate.py` is the CLI.

**Tech Stack:** Python 3.13, pyxform 4.4.1, openpyxl 3.1.5, lxml (pulled in by pyxform), pytest. Run via the repo-local `.venv` managed with `uv`.

## Global Constraints

- **Output artifact:** ODK submission **instance XML only**, one file per submission. No CSV.
- **Geography:** existing DRC demo geography from the choices sheets; footprint anchored at province **Ituri → district Bunia** (+ one neighbouring district) → ~3 HFs → ~12 villages → 3-day campaign.
- **Disease/medicine:** oncho/LF → **IVM (+ALB for LF)**; apply real IVM eligibility (dose-pole `<90 cm` excluded; exclude pregnant, recently-breastfeeding).
- **Determinism:** every run is reproducible from a single integer `seed`.
- **Ona compatibility:** submission root `id` MUST equal the compiled `form_id`; `meta/instanceID` MUST be a unique `uuid:` URN.
- **No magic numbers:** every realism parameter lives in `realism.py`, named and commented with its source (ESPEN docs or WHO PC-NTD/Mectizan).
- **Tooling:** all code under `tools/espen-mda-datagen/`; tests are pytest; run from the worktree `.venv`.
- **Source spec:** `docs/superpowers/specs/2026-06-22-espen-mda-sample-data-generator-design.md`.

---

## File Structure

```
tools/espen-mda-datagen/
  pyproject.toml                 # deps + pytest config
  README.md                      # how to run, what it emits, Ona-load note
  espen_datagen/
    __init__.py
    forms.py                     # XLSForm -> XForm -> FormSchema; choices loader
    realism.py                   # sourced domain constants + pure helpers
    scenario.py                  # build one coherent campaign -> SubmissionRecords
    render.py                    # fill instance template -> ODK XML; write campaign
    report.py                    # face-validity aggregate indicators
    generate.py                  # CLI entry point
  tests/
    __init__.py
    conftest.py                  # FORMS_DIR fixture
    test_forms.py
    test_realism.py
    test_scenario.py
    test_render.py
    test_report.py
    test_generate.py
```

`FORMS_DIR` = repo path `forms/espen mda/` (the six `demo_mda_9999_*.xlsx`). The six form
keys used throughout: `1_location`, `2_part`, `3_med_treatment`, `4_case_mngnt`,
`5_supervision_hf`, `6_supervision_CDD`.

---

## Task 1: Scaffold + Form layer (`forms.py`)

Compile any of the six XLSForms with pyxform and extract a `FormSchema` the renderer can fill.

**Files:**
- Create: `tools/espen-mda-datagen/pyproject.toml`
- Create: `tools/espen-mda-datagen/espen_datagen/__init__.py` (empty)
- Create: `tools/espen-mda-datagen/espen_datagen/forms.py`
- Create: `tools/espen-mda-datagen/tests/__init__.py` (empty)
- Create: `tools/espen-mda-datagen/tests/conftest.py`
- Test: `tools/espen-mda-datagen/tests/test_forms.py`

**Interfaces:**
- Produces:
  - `@dataclass FormSchema` with fields: `key: str`, `form_id: str`, `version: str | None`,
    `title: str`, `template: lxml.etree._Element` (deep copy of the `<data>` instance node),
    `leaf_names: list[str]` (localnames of value-bearing leaf nodes, in document order,
    excluding the `meta` subtree), `calculate_names: set[str]`, `choices: dict[str, list[str]]`
    (list_name → valid option names), `src_path: str`.
  - `FORM_KEYS: list[str]` = the six keys above.
  - `def form_path(forms_dir: str, key: str) -> str` — resolves `demo_mda_9999_<key>.xlsx`
    (note file `3` is named `..._3_med_treatment.xlsx`).
  - `def load_form(xlsx_path: str) -> FormSchema`.
  - `def load_all(forms_dir: str) -> dict[str, FormSchema]`.

- [ ] **Step 1: Create `pyproject.toml`**

```toml
[project]
name = "espen-datagen"
version = "0.1.0"
description = "Synthetic ESPEN MDA sample-data generator (ODK XML for Ona Data)"
requires-python = ">=3.13"
dependencies = ["pyxform==4.4.1", "openpyxl==3.1.5", "lxml"]

[project.optional-dependencies]
dev = ["pytest>=8"]

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-q"

[tool.setuptools.packages.find]
where = ["."]
include = ["espen_datagen*"]
```

- [ ] **Step 2: Create the worktree venv and install (one-time setup)**

Run:
```bash
cd /Users/claudius/github/icr/.claude/worktrees/espen-datagen
uv venv --python 3.13 .venv
uv pip install --python .venv -e "tools/espen-mda-datagen[dev]"
printf '\n.venv/\n__pycache__/\n*.pyc\ntools/espen-mda-datagen/**/sample-data/\n' >> .gitignore
git add .gitignore && git commit -m "chore: datagen venv + ignores"
```
Expected: install succeeds; `git status` clean.

- [ ] **Step 3: Create `tests/conftest.py`**

```python
import os
import pytest

# Repo root is four levels up from this test file's worktree location.
REPO_ROOT = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "..")
)
FORMS_DIR_PATH = os.path.join(REPO_ROOT, "forms", "espen mda")


@pytest.fixture
def forms_dir():
    assert os.path.isdir(FORMS_DIR_PATH), f"missing {FORMS_DIR_PATH}"
    return FORMS_DIR_PATH
```

- [ ] **Step 4: Write the failing test `tests/test_forms.py`**

```python
from espen_datagen.forms import load_form, form_path, load_all, FORM_KEYS, FormSchema


def test_load_location_form_schema(forms_dir):
    schema = load_form(form_path(forms_dir, "1_location"))
    assert isinstance(schema, FormSchema)
    assert schema.form_id == "demo_mda_9999_1_location_v3"
    # value-bearing leaves present, meta excluded
    assert "l_total_pop" in schema.leaf_names
    assert "l_eligible_pop" in schema.leaf_names
    assert "instanceID" not in schema.leaf_names
    # calculate node detected
    assert "l_eligible_pop" in schema.calculate_names
    # choices loaded: DRC geography + recorder ids
    assert "Ituri" in schema.choices["state"]
    assert any(c.isdigit() for c in schema.choices["recorder_id"][0])


def test_treatment_form_has_grouped_leaves(forms_dir):
    schema = load_form(form_path(forms_dir, "3_med_treatment"))
    assert schema.form_id == "demo_mda_9999_3_med_treatement_v3"
    # leaves inside groups are reachable by localname
    for n in ["census_men", "ivm_5_14_male_treated", "cd_trained"]:
        assert n in schema.leaf_names


def test_load_all_six(forms_dir):
    schemas = load_all(forms_dir)
    assert set(schemas) == set(FORM_KEYS)
    assert len(FORM_KEYS) == 6
```

- [ ] **Step 5: Run test to verify it fails**

Run: `cd /Users/claudius/github/icr/.claude/worktrees/espen-datagen && .venv/bin/pytest tools/espen-mda-datagen/tests/test_forms.py -v`
Expected: FAIL — `ModuleNotFoundError: espen_datagen.forms` / `cannot import name 'load_form'`.

- [ ] **Step 6: Implement `espen_datagen/forms.py`**

```python
"""Compile ESPEN XLSForms to XForms (pyxform) and extract fillable schemas."""
from __future__ import annotations

import copy
import os
from dataclasses import dataclass, field

from lxml import etree
import openpyxl
from pyxform.xls2xform import convert

XF = "http://www.w3.org/2002/xforms"
NS = {"h": "http://www.w3.org/1999/xhtml", "x": XF}

FORM_KEYS = [
    "1_location",
    "2_part",
    "3_med_treatment",
    "4_case_mngnt",
    "5_supervision_hf",
    "6_supervision_CDD",
]


@dataclass
class FormSchema:
    key: str
    form_id: str
    version: str | None
    title: str
    template: etree._Element  # deep copy of the <data> instance node
    leaf_names: list[str]
    calculate_names: set[str]
    choices: dict[str, list[str]]
    src_path: str = ""
    meta_present: bool = False
    xform_xml: str = ""  # compiled XForm, persisted for Ona Data publishing


def form_path(forms_dir: str, key: str) -> str:
    return os.path.join(forms_dir, f"demo_mda_9999_{key}.xlsx")


def _localname(el) -> str:
    tag = el.tag
    return tag.split("}")[-1] if isinstance(tag, str) else tag


def _collect_leaves(data_el) -> tuple[list[str], bool]:
    """Localnames of value-bearing leaves, in doc order, excluding the meta subtree."""
    names: list[str] = []
    meta_present = False
    for child in data_el.iter():
        if child is data_el:
            continue
        if _localname(child) == "meta":
            meta_present = True
    for child in data_el.iter():
        if child is data_el:
            continue
        ln = _localname(child)
        # skip anything under meta
        parent = child.getparent()
        in_meta = False
        while parent is not None and parent is not data_el:
            if _localname(parent) == "meta":
                in_meta = True
                break
            parent = parent.getparent()
        if in_meta or ln == "meta":
            continue
        if len(child) == 0:  # leaf
            names.append(ln)
    return names, meta_present


def _calculate_names(root) -> set[str]:
    out = set()
    for b in root.findall(".//x:bind", NS):
        if b.get("calculate"):
            ref = b.get("nodeset", "")
            out.add(ref.rsplit("/", 1)[-1])
    return out


def _load_choices(xlsx_path: str) -> dict[str, list[str]]:
    wb = openpyxl.load_workbook(xlsx_path, read_only=True, data_only=True)
    if "choices" not in wb.sheetnames:
        return {}
    ws = wb["choices"]
    rows = list(ws.iter_rows(values_only=True))
    if not rows:
        return {}
    header = [str(h) if h is not None else "" for h in rows[0]]
    li = header.index("list_name") if "list_name" in header else 0
    ni = header.index("name") if "name" in header else 1
    out: dict[str, list[str]] = {}
    for r in rows[1:]:
        if not r or li >= len(r) or r[li] is None:
            continue
        name = r[ni] if ni < len(r) and r[ni] is not None else None
        if name is None:
            continue
        out.setdefault(str(r[li]).strip(), []).append(str(name).strip())
    return out


def load_form(xlsx_path: str) -> FormSchema:
    result = convert(xlsx_path)
    root = etree.fromstring(result.xform.encode("utf-8"))
    instance = root.find(".//x:model/x:instance", NS)
    data_el = list(instance)[0]
    form_id = data_el.get("id")
    version = data_el.get("version")
    title_el = root.find(".//h:head/h:title", NS)
    title = title_el.text if title_el is not None else form_id
    leaves, meta_present = _collect_leaves(data_el)
    key = "_".join(os.path.basename(xlsx_path).replace(".xlsx", "").split("_")[2:])
    return FormSchema(
        key=key,
        form_id=form_id,
        version=version,
        title=title,
        template=copy.deepcopy(data_el),
        leaf_names=leaves,
        calculate_names=_calculate_names(root),
        choices=_load_choices(xlsx_path),
        src_path=xlsx_path,
        meta_present=meta_present,
        xform_xml=result.xform,
    )


def load_all(forms_dir: str) -> dict[str, FormSchema]:
    return {k: load_form(form_path(forms_dir, k)) for k in FORM_KEYS}
```

- [ ] **Step 7: Run tests to verify they pass**

Run: `.venv/bin/pytest tools/espen-mda-datagen/tests/test_forms.py -v`
Expected: PASS (3 tests). If `test_load_location_form_schema` fails on `calculate_names`,
print `schema.calculate_names` to confirm the bind localname; adjust only the test's
expectation if pyxform names the calc differently, never weaken the implementation.

- [ ] **Step 8: Commit**

```bash
git add tools/espen-mda-datagen/pyproject.toml tools/espen-mda-datagen/espen_datagen/__init__.py tools/espen-mda-datagen/espen_datagen/forms.py tools/espen-mda-datagen/tests/__init__.py tools/espen-mda-datagen/tests/conftest.py tools/espen-mda-datagen/tests/test_forms.py
git commit -m "feat(datagen): form layer — XLSForm->XForm->FormSchema"
```

---

## Task 2: Realism profile (`realism.py`)

All sourced domain constants + pure deterministic helpers. No I/O, no form knowledge.

**Files:**
- Create: `tools/espen-mda-datagen/espen_datagen/realism.py`
- Test: `tools/espen-mda-datagen/tests/test_realism.py`

**Interfaces:**
- Produces:
  - Constants: `AGE_BANDS` (`["1_4","5_14","15_plus"]`), `AGE_PYRAMID` (dict band→fraction,
    sums to 1.0), `ELIGIBLE_FRACTION` (float), `COVERAGE_BAND` (`(lo, hi)`), `DOSE_POLE_BANDS`
    (`list[(min_cm, max_cm, tablets)]`), `NOT_TREATED_WEIGHTS` (dict reason→weight),
    `MINOR_AE_RATE`, `SERIOUS_AE_RATE`, `CDD_PER_POPULATION`, `VILLAGE_POP_RANGE`,
    `ALB_TABLETS_PER_PERSON`, `COMM_CHANNELS`.
  - `def dose_pole_tablets(height_cm: float) -> int` (0 if `< 90`).
  - `def split_age_bands(total: int) -> dict[str, int]` (sums to `total`).
  - `def sample_coverage(rng) -> float` (within `COVERAGE_BAND`).
  - `def split_not_treated(n: int, rng) -> dict[str, int]` (keys = `NOT_TREATED_WEIGHTS`
    keys: `child`, `pregnant`, `breastfeeding`, `absent`, `refusal`; sums to `n`).
  - `def cdd_count(population: int) -> int` (>=1).

- [ ] **Step 1: Write failing test `tests/test_realism.py`**

```python
import random
from espen_datagen import realism as R


def test_age_pyramid_sums_to_one():
    assert abs(sum(R.AGE_PYRAMID.values()) - 1.0) < 1e-9
    assert set(R.AGE_PYRAMID) == set(R.AGE_BANDS)


def test_dose_pole_bands():
    assert R.dose_pole_tablets(80) == 0      # too short -> excluded
    assert R.dose_pole_tablets(90) == 1
    assert R.dose_pole_tablets(119) == 1
    assert R.dose_pole_tablets(120) == 2
    assert R.dose_pole_tablets(150) == 3
    assert R.dose_pole_tablets(170) == 4


def test_split_age_bands_conserves_total():
    d = R.split_age_bands(1000)
    assert sum(d.values()) == 1000
    assert set(d) == set(R.AGE_BANDS)
    assert d["15_plus"] > d["1_4"]  # pyramid shape


def test_sample_coverage_in_band_and_deterministic():
    lo, hi = R.COVERAGE_BAND
    rng = random.Random(42)
    vals = [R.sample_coverage(rng) for _ in range(50)]
    assert all(lo <= v <= hi for v in vals)
    assert R.sample_coverage(random.Random(7)) == R.sample_coverage(random.Random(7))


def test_split_not_treated_conserves_and_absent_dominates():
    rng = random.Random(1)
    d = R.split_not_treated(100, rng)
    assert sum(d.values()) == 100
    assert set(d) == {"child", "pregnant", "breastfeeding", "absent", "refusal"}
    assert d["absent"] == max(d.values())


def test_cdd_count_at_least_one():
    assert R.cdd_count(50) >= 1
    assert R.cdd_count(2000) >= R.cdd_count(200)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `.venv/bin/pytest tools/espen-mda-datagen/tests/test_realism.py -v`
Expected: FAIL — `ModuleNotFoundError` / missing attributes.

- [ ] **Step 3: Implement `espen_datagen/realism.py`**

```python
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
    if height_cm < 90:
        return 0
    for lo, hi, tabs in DOSE_POLE_BANDS:
        if lo <= height_cm <= hi:
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `.venv/bin/pytest tools/espen-mda-datagen/tests/test_realism.py -v`
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
git add tools/espen-mda-datagen/espen_datagen/realism.py tools/espen-mda-datagen/tests/test_realism.py
git commit -m "feat(datagen): realism profile — sourced constants + helpers"
```

---

## Task 3: Scenario layer (`scenario.py`)

Build one coherent campaign and assert the cross-form invariants. This is the heart.

**Files:**
- Create: `tools/espen-mda-datagen/espen_datagen/scenario.py`
- Test: `tools/espen-mda-datagen/tests/test_scenario.py`

**Interfaces:**
- Consumes: `realism` (Task 2). Does **not** need `FormSchema` — it emits values keyed by
  the exact form node localnames; `render` (Task 4) marries values to templates.
- Produces:
  - `@dataclass Config`: `seed: int = 20261101`, `n_districts: int = 2`, `n_hf: int = 3`,
    `n_villages: int = 12`, `campaign_days: int = 3`, `province: str = "Ituri"`,
    `diseases: tuple[str,...] = ("ONCHO","LF")`, `medicine: str = "IVM+ALB"`,
    `campaign_start: str = "2026-11-09"`.
  - `@dataclass SubmissionRecord`: `form_key: str`, `values: dict[str, str]`,
    `start: str`, `end: str`, `today: str`.
  - `@dataclass Village`: `name`, `location_id`, `hf`, `district`, `recorder_id`,
    `lat`, `lon`, `total_pop`, `age_bands: dict[str,int]`, `eligible: int`,
    `treated: int`, `not_treated: dict[str,int]`, `treated_by_band_sex: dict[str,int]`,
    `alb_distributed: int`, `treated_flag: bool`.
  - `@dataclass Campaign`: `config: Config`, `villages: list[Village]`,
    `received: dict[str,int]`, `distributed: dict[str,int]`, `records: list[SubmissionRecord]`.
  - `def build_campaign(cfg: Config = Config()) -> Campaign`.

- [ ] **Step 1: Write failing test `tests/test_scenario.py`**

```python
from espen_datagen.scenario import build_campaign, Config


def test_determinism():
    a = build_campaign(Config(seed=123))
    b = build_campaign(Config(seed=123))
    av = [(r.form_key, r.values) for r in a.records]
    bv = [(r.form_key, r.values) for r in b.records]
    assert av == bv


def test_record_counts_by_form():
    c = build_campaign(Config(n_villages=12, campaign_days=3))
    by = {}
    for r in c.records:
        by[r.form_key] = by.get(r.form_key, 0) + 1
    assert by["1_location"] == 12                  # one per village
    assert by["3_med_treatment"] == 12 * 3         # village x day
    assert by["2_part"] == 3                        # one per HF
    assert by["4_case_mngnt"] == 3
    assert by["5_supervision_hf"] >= 1
    assert by["6_supervision_CDD"] >= 1


def test_invariant_treated_plus_not_treated_within_eligible():
    c = build_campaign()
    for v in c.villages:
        if not v.treated_flag:
            continue
        assert v.treated + sum(v.not_treated.values()) <= v.eligible


def test_invariant_distributed_le_received():
    c = build_campaign()
    # ALB distributed across all villages cannot exceed ALB received across HFs
    assert c.distributed["alb"] <= c.received["alb"]
    assert c.distributed["ivm"] <= c.received["ivm"]


def test_invariant_age_bands_sum_to_total():
    c = build_campaign()
    for v in c.villages:
        assert sum(v.age_bands.values()) == v.total_pop


def test_geo_anchored_in_ituri():
    c = build_campaign()
    assert c.config.province == "Ituri"
    # Ituri bounding box (approx): lat 0.5..3.5 N, lon 28..31 E
    for v in c.villages:
        assert 0.5 <= v.lat <= 3.5 and 28.0 <= v.lon <= 31.0
```

- [ ] **Step 2: Run test to verify it fails**

Run: `.venv/bin/pytest tools/espen-mda-datagen/tests/test_scenario.py -v`
Expected: FAIL — `ModuleNotFoundError`.

- [ ] **Step 3: Implement `espen_datagen/scenario.py`**

```python
"""Build one internally-consistent ESPEN oncho/LF IVM campaign (Ituri, DRC)."""
from __future__ import annotations

import random
from dataclasses import dataclass, field
from datetime import date, timedelta

from . import realism as R

# Real Ituri districts / HFs / villages drawn from the choices sheets.
ITURI_DISTRICTS = ["Bunia", "Mambasa"]
HEALTH_FACILITIES = ["Mudzipela Centre", "Nyakunde Centre", "Oicha Centre"]
VILLAGE_POOL = [
    "Kalelu", "Nyabibwe", "Misangi", "Mutoshi", "Sange", "Kimputu",
    "Soyo", "Tchomia", "Kasenyi", "Bogoro", "Marabo", "Gety",
    "Komanda", "Luna", "Mandima", "Biakato",
]
ITURI_CENTER = (1.56, 30.25)  # near Bunia


def _yn(b: bool) -> str:
    return "Yes" if b else "No"


@dataclass
class Config:
    seed: int = 20261101
    n_districts: int = 2
    n_hf: int = 3
    n_villages: int = 12
    campaign_days: int = 3
    province: str = "Ituri"
    diseases: tuple = ("ONCHO", "LF")
    medicine: str = "IVM+ALB"
    campaign_start: str = "2026-11-09"


@dataclass
class SubmissionRecord:
    form_key: str
    values: dict
    start: str
    end: str
    today: str


@dataclass
class Village:
    name: str
    location_id: str
    hf: str
    district: str
    recorder_id: str
    lat: float
    lon: float
    total_pop: int
    age_bands: dict
    eligible: int
    treated: int = 0
    not_treated: dict = field(default_factory=dict)
    treated_by_band_sex: dict = field(default_factory=dict)
    alb_distributed: int = 0
    treated_flag: bool = True


@dataclass
class Campaign:
    config: Config
    villages: list
    received: dict
    distributed: dict
    records: list


def _iso_dt(d: date, hour: int, minute: int) -> str:
    return f"{d.isoformat()}T{hour:02d}:{minute:02d}:00.000+02:00"


def build_campaign(cfg: Config = Config()) -> Campaign:
    rng = random.Random(cfg.seed)
    start_date = date.fromisoformat(cfg.campaign_start)

    villages: list[Village] = []
    for i in range(cfg.n_villages):
        name = VILLAGE_POOL[i % len(VILLAGE_POOL)]
        hf = HEALTH_FACILITIES[i % cfg.n_hf]
        district = ITURI_DISTRICTS[i % cfg.n_districts]
        total = rng.randint(*R.VILLAGE_POP_RANGE)
        bands = R.split_age_bands(total)
        eligible = int(round(total * R.ELIGIBLE_FRACTION))
        lat = round(ITURI_CENTER[0] + rng.uniform(-0.6, 0.6), 5)
        lon = round(ITURI_CENTER[1] + rng.uniform(-0.6, 0.6), 5)
        v = Village(
            name=name,
            location_id=str(101 + i),
            hf=hf,
            district=district,
            recorder_id=f"{(i % 12) + 1:02d}",
            lat=lat,
            lon=lon,
            total_pop=total,
            age_bands=bands,
            eligible=eligible,
        )
        # One village deliberately not treated (Insecurity) for realism.
        v.treated_flag = not (i == cfg.n_villages - 1)
        if v.treated_flag:
            cov = R.sample_coverage(rng)
            v.treated = int(round(eligible * cov))
            v.not_treated = R.split_not_treated(eligible - v.treated, rng)
            v.treated_by_band_sex = _split_treated(v.treated, rng)
            v.alb_distributed = v.treated * R.ALB_TABLETS_PER_PERSON
        else:
            v.treated = 0
            v.not_treated = {k: 0 for k in R.NOT_TREATED_WEIGHTS}
            v.treated_by_band_sex = _split_treated(0, rng)
            v.alb_distributed = 0
        villages.append(v)

    # IVM tablets used ~ height-banded; approximate 2 tablets/treated person.
    ivm_used = sum(v.treated for v in villages) * 2
    alb_used = sum(v.alb_distributed for v in villages)
    received = {"ivm": int(ivm_used * 1.15) + 50, "alb": int(alb_used * 1.15) + 50}
    distributed = {"ivm": ivm_used, "alb": alb_used}

    records: list[SubmissionRecord] = []
    records += _form1_records(villages, cfg, start_date)
    records += _form2_records(villages, cfg, received, start_date)
    records += _form3_records(villages, cfg, start_date)
    records += _form4_records(villages, cfg, distributed, start_date)
    records += _form5_records(villages, cfg, received, distributed, start_date)
    records += _form6_records(villages, cfg, start_date, rng)

    _assert_invariants(villages, received, distributed)
    return Campaign(cfg, villages, received, distributed, records)


def _split_treated(treated: int, rng) -> dict:
    """Split treated count across age-band x sex cells used by form 3 (IVM/ALB)."""
    # IVM excludes <90cm (~under-5), so treated are 5-14 and 15+ only.
    share_5_14 = 0.32
    n_5_14 = int(round(treated * share_5_14))
    n_15 = treated - n_5_14
    f5 = n_5_14 // 2
    f15 = n_15 // 2
    return {
        "5_14_female": f5,
        "5_14_male": n_5_14 - f5,
        "15_female": f15,
        "15_male": n_15 - f15,
    }


# ---- per-form record builders -------------------------------------------------

def _form1_records(villages, cfg, start_date):
    recs = []
    s = _iso_dt(start_date, 8, 0)
    e = _iso_dt(start_date, 8, 30)
    for v in villages:
        recs.append(SubmissionRecord("1_location", {
            "l_recorder_id": v.recorder_id,
            "l_state": cfg.province,
            "l_district": v.district,
            "l_health_facility": v.hf,
            "l_location": v.name,
            "l_location_id": v.location_id,
            "l_total_pop": str(v.total_pop),
            "I_total_popn_1_4": str(v.age_bands["1_4"]),
            "I_total_popn_5_14": str(v.age_bands["5_14"]),
            "I_total_popn_15_More": str(v.age_bands["15_plus"]),
            "l_eligible_pop": str(v.eligible),
            "l_gps": f"{v.lat} {v.lon} 0 5",
            "l_submitting_report": f"Recorder {v.recorder_id}",
            "l_additional_note": "",
        }, s, e, start_date.isoformat()))
    return recs


def _form2_records(villages, cfg, received, start_date):
    recs = []
    hfs = sorted({v.hf for v in villages})
    per = max(1, received["ivm"] // max(1, len(hfs)))
    per_alb = max(1, received["alb"] // max(1, len(hfs)))
    s = _iso_dt(start_date - timedelta(days=1), 9, 0)
    e = _iso_dt(start_date - timedelta(days=1), 9, 20)
    for hf in hfs:
        recs.append(SubmissionRecord("2_part", {
            "p_recorder_id": "01",
            "p_state": cfg.province,
            "p_district": villages[0].district,
            "p_health_facility": hf,
            "p_disease": " ".join(cfg.diseases),
            "p_medicine": cfg.medicine,
            "p_total_ivm": str(per),
            "p_total_alb": str(per_alb),
            "p_total_pzq": "0", "p_total_meb": "0", "p_total_dec": "0",
            "p_total_az_sus": "0", "p_total_az_tab": "0", "p_total_tetra": "0",
            "p_add_note": "",
        }, s, e, (start_date - timedelta(days=1)).isoformat()))
    return recs


def _form3_records(villages, cfg, start_date):
    recs = []
    for v in villages:
        for day in range(cfg.campaign_days):
            d = start_date + timedelta(days=day)
            frac = [0.45, 0.35, 0.20][day] if cfg.campaign_days == 3 else 1.0 / cfg.campaign_days
            ts = v.treated_by_band_sex
            day_men = int(round((ts["15_male"]) * frac))
            day_women = int(round((ts["15_female"]) * frac))
            vals = {
                "p_recorder_id": v.recorder_id,
                "p_state": cfg.province, "p_district": v.district,
                "p_health_facility": v.hf, "p_location": v.name,
                "p_location_id": v.location_id,
                "p_campaign_day": f"Day {day + 1}",
                "p_disease": " ".join(cfg.diseases),
                "p_medicine": cfg.medicine,
                "census_method": "Aggregate Reporting ",
                "census_house_hold": str(max(1, v.total_pop // 6)),
                "census_men": str(v.age_bands["15_plus"] // 2),
                "census_women": str(v.age_bands["15_plus"] - v.age_bands["15_plus"] // 2),
                # IVM cube
                "ivm_5_14_female_treated": str(int(round(ts["5_14_female"] * frac))),
                "ivm_5_14_male_treated": str(int(round(ts["5_14_male"] * frac))),
                "ivm_15_female_treated": str(day_women),
                "ivm_15_male_treated": str(day_men),
                "ivm_men_treated": str(day_men),
                "ivm_women_treated": str(day_women),
                # reasons not treated only logged day 1
                "ivm_child": str(v.not_treated["child"] if day == 0 else 0),
                "ivm_pregnant": str(v.not_treated["pregnant"] if day == 0 else 0),
                "ivm_breastfeeding": str(v.not_treated["breastfeeding"] if day == 0 else 0),
                "ivm_absent": str(v.not_treated["absent"] if day == 0 else 0),
                "ivm_refusal": str(v.not_treated["refusal"] if day == 0 else 0),
                "cd_who_distributed_man": str(R.cdd_count(v.total_pop)),
                "cd_who_distributed_woman": str(R.cdd_count(v.total_pop)),
                "cd_trained": str(max(1, R.cdd_count(v.total_pop) // 2)),
                "cd_recycled": str(R.cdd_count(v.total_pop) // 2),
                "p_add_note": "",
            }
            recs.append(SubmissionRecord("3_med_treatment", vals,
                                         _iso_dt(d, 9, 0), _iso_dt(d, 16, 0), d.isoformat()))
    return recs


def _form4_records(villages, cfg, distributed, start_date):
    recs = []
    hfs = sorted({v.hf for v in villages})
    end_date = start_date + timedelta(days=cfg.campaign_days)
    n = len(hfs)
    for idx, hf in enumerate(hfs):
        hf_villages = [v for v in villages if v.hf == hf]
        treated = sum(v.treated for v in hf_villages)
        minor = int(round(treated * R.MINOR_AE_RATE))
        serious = 1 if (idx == 0 and treated * R.SERIOUS_AE_RATE >= 0) and treated > 5000 else 0
        recs.append(SubmissionRecord("4_case_mngnt", {
            "p_state": cfg.province, "p_district": hf_villages[0].district,
            "p_health_facility": hf,
            "p_disease": " ".join(cfg.diseases), "p_medicine": cfg.medicine,
            "p_total_ivm_dist": str(treated * 2),
            "p_total_alb_dist": str(sum(v.alb_distributed for v in hf_villages)),
            "p_total_pzq_dist": "0", "p_total_meb_dist": "0", "p_total_dec_dist": "0",
            "p_total_az_sus_dist": "0", "p_total_az_tab_dist": "0", "p_total_tetra_dist": "0",
            "p_minor_side_effect": str(minor),
            "p_serious_side_effect": str(serious),
            "p_guinea_worm_rumor": "0", "p_leish_suspect": "0",
            "p_buruli_ulcer_suspect": "0", "p_Lymphoedema_LF": str(idx),
            "P_hydrocele_LF": "0", "p_add_note": "",
        }, _iso_dt(end_date, 10, 0), _iso_dt(end_date, 10, 30), end_date.isoformat()))
    return recs


def _form5_records(villages, cfg, received, distributed, start_date):
    total = len(villages)
    treated_v = sum(1 for v in villages if v.treated_flag)
    end_date = start_date + timedelta(days=cfg.campaign_days)
    remain_ivm = received["ivm"] - distributed["ivm"]
    vals = {
        "s_recorder_id": "01", "s_state": cfg.province,
        "s_district": villages[0].district, "s_health_facility": villages[0].hf,
        "s_location": villages[0].name, "s_supervisor_Level": "District",
        "s_date_start": cfg.campaign_start, "s_date_end": end_date.isoformat(),
        "s_disease": " ".join(cfg.diseases), "s_medicine": cfg.medicine,
        "s_nb_villages_total": str(total),
        "s_nb_villages_treated": str(treated_v),
        "s_nb_villages_non_treated": str(total - treated_v),
        "s_reason_non_treatment": "Insecurity",
        "s_stock_remain_ivm": _yn(remain_ivm > 0),
        "s_stock_expired_ivm": "No", "s_stock_concordance_ivm": "Yes",
        "s_stock_remain_alb": "Yes", "s_stock_expired_alb": "No",
        "s_stock_concordance_alb": "Yes",
        "s_dc_trained_h": "8", "s_dc_trained_f": "6", "s_manual_used": "Yes",
        "s_population_informed": "Yes",
        "s_chanel_utilises": "Radio Community.leaders Town.criers",
        "s_dc_supervised": "12", "s_villages_supervised": str(treated_v),
        "s_side_effect": "Yes", "s_sever_side_effect": "No",
        "s_difficultes": "Difficult access to one village (insecurity).",
        "s_solutions": "Reschedule with security escort.",
        "s_recommandations": "Pre-position stock earlier.",
    }
    # zero out the unused-drug stock fields the form carries
    for drug in ("meb", "dec", "pzq", "az_sus", "az_tab", "tetra"):
        vals[f"s_stock_remain_{drug}"] = "No"
        vals[f"s_stock_expired_{drug}"] = "No"
        vals[f"s_stock_concordance_{drug}"] = "Yes"
    return [SubmissionRecord("5_supervision_hf", vals,
                             _iso_dt(end_date, 11, 0), _iso_dt(end_date, 12, 0),
                             end_date.isoformat())]


def _form6_records(villages, cfg, start_date, rng):
    recs = []
    observed = [v for v in villages if v.treated_flag][:2]
    for v in observed:
        d = start_date + timedelta(days=1)
        yn = lambda p: "Yes" if rng.random() < p else "No"
        recs.append(SubmissionRecord("6_supervision_CDD", {
            "s_supervisor": "District", "s_state": cfg.province, "s_district": v.district,
            "s_health_facility": v.hf, "s_location": v.name,
            "s_date_start": cfg.campaign_start,
            "s_date_end": (start_date + timedelta(days=cfg.campaign_days)).isoformat(),
            "s_disease": " ".join(cfg.diseases), "s_medicine": cfg.medicine,
            "s_medicine_sufficient": "Yes",
            "s_total_dist_trained_male": "2", "s_total_dist_trained_female": "2",
            "s_total_dist": "4",
            "s_hieght_chart": "Yes", "s_register": "Yes",
            "s_records_checklist": "Yes", "s_med_bag": "Yes",
            "s_wear_vest": yn(0.8), "s_usual_greetings": "Yes",
            "s_introduced_patient": "Yes", "s_used_height_chart_correctly": yn(0.9),
            "s_gave_write_dosage": "Yes", "s_medicine_took_in_front_of_dc": "Yes",
            "s_filled_form": "Yes", "s_investigated_cases": yn(0.7),
            "s_identified_ineligible": "Yes", "s_follow_side_effect_procedure": yn(0.8),
            "s_date_training": (start_date - timedelta(days=3)).isoformat(),
            "s_traning_duration": "2",
            "s_training_topic": "Using.the.measuring.stick Completing.the.checklists Marking.concessions",
            "s_took_med_in_training": "Yes", "s_complete_form": "Yes",
            "s_case_mngt": "Yes", "s_has_inegidible": "Yes", "s_follow_side_effect": "Yes",
            "s_difficultes": "", "s_solutions": "", "s_recommandations": "",
        }, _iso_dt(d, 13, 0), _iso_dt(d, 13, 40), d.isoformat()))
    return recs


def _assert_invariants(villages, received, distributed):
    for v in villages:
        assert sum(v.age_bands.values()) == v.total_pop, f"age bands {v.name}"
        if v.treated_flag:
            assert v.treated + sum(v.not_treated.values()) <= v.eligible, f"coverage {v.name}"
            cube = sum(v.treated_by_band_sex.values())
            assert abs(cube - v.treated) <= 2, f"cube vs treated {v.name}"
    assert distributed["ivm"] <= received["ivm"], "ivm distributed>received"
    assert distributed["alb"] <= received["alb"], "alb distributed>received"
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `.venv/bin/pytest tools/espen-mda-datagen/tests/test_scenario.py -v`
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
git add tools/espen-mda-datagen/espen_datagen/scenario.py tools/espen-mda-datagen/tests/test_scenario.py
git commit -m "feat(datagen): scenario layer — coherent campaign + invariants"
```

---

## Task 4: Render layer (`render.py`)

Fill each form's instance template from a `SubmissionRecord` and write ODK submission XML + manifest.

**Files:**
- Create: `tools/espen-mda-datagen/espen_datagen/render.py`
- Test: `tools/espen-mda-datagen/tests/test_render.py`

**Interfaces:**
- Consumes: `FormSchema` (Task 1), `SubmissionRecord` (Task 3).
- Produces:
  - `def render_submission(schema: FormSchema, rec: SubmissionRecord, *, instance_id: str)
    -> bytes` — returns serialized XML; sets each leaf by localname, fills `meta/instanceID`,
    `start`/`end`/`today` if present, preserves root `id`. Unknown record keys raise
    `KeyError` (catches typos); record keys absent from the template are an error.
  - `def write_campaign(campaign, schemas: dict[str,FormSchema], outdir: str) -> dict`
    — writes `outdir/<form_key>/<uuid>.xml` for each record and `outdir/manifest.json`;
    returns the manifest dict.

- [ ] **Step 1: Write failing test `tests/test_render.py`**

```python
import uuid
from lxml import etree
from espen_datagen.forms import load_all
from espen_datagen.scenario import build_campaign, SubmissionRecord
from espen_datagen.render import render_submission, write_campaign

XF = "{http://www.w3.org/2002/xforms}"


def _first(records, key):
    return next(r for r in records if r.form_key == key)


def test_render_sets_values_and_meta(forms_dir):
    schemas = load_all(forms_dir)
    camp = build_campaign()
    rec = _first(camp.records, "1_location")
    iid = f"uuid:{uuid.uuid4()}"
    xml = render_submission(schemas["1_location"], rec, instance_id=iid)
    root = etree.fromstring(xml)
    assert root.get("id") == "demo_mda_9999_1_location_v3"
    # value landed
    tp = root.find(f"{XF}l_total_pop")
    assert tp is not None and tp.text == rec.values["l_total_pop"]
    # instanceID set
    meta = root.find(f"{XF}meta")
    assert meta is not None
    assert meta.find(f"{XF}instanceID").text == iid


def test_render_grouped_node(forms_dir):
    schemas = load_all(forms_dir)
    camp = build_campaign()
    rec = _first(camp.records, "3_med_treatment")
    xml = render_submission(schemas["3_med_treatment"], rec, instance_id="uuid:x")
    root = etree.fromstring(xml)
    node = root.find(f".//{XF}census/{XF}census_men")
    assert node is not None and node.text == rec.values["census_men"]


def test_render_rejects_unknown_key(forms_dir):
    schemas = load_all(forms_dir)
    bad = SubmissionRecord("1_location", {"nonexistent_field": "x"}, "s", "e", "t")
    try:
        render_submission(schemas["1_location"], bad, instance_id="uuid:x")
        assert False, "expected KeyError"
    except KeyError:
        pass


def test_write_campaign_emits_files_and_manifest(forms_dir, tmp_path):
    schemas = load_all(forms_dir)
    camp = build_campaign()
    out = tmp_path / "sample-data"
    manifest = write_campaign(camp, schemas, str(out))
    # one xml per record
    n_files = sum(len(list((out / k).glob("*.xml"))) for k in {r.form_key for r in camp.records})
    assert n_files == len(camp.records)
    assert (out / "manifest.json").exists()
    assert manifest["total_submissions"] == len(camp.records)
    # every emitted file parses and has a uuid instanceID
    for k in {r.form_key for r in camp.records}:
        for f in (out / k).glob("*.xml"):
            root = etree.fromstring(f.read_bytes())
            iid = root.find(f".//{XF}instanceID").text
            assert iid.startswith("uuid:")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `.venv/bin/pytest tools/espen-mda-datagen/tests/test_render.py -v`
Expected: FAIL — `ModuleNotFoundError`.

- [ ] **Step 3: Implement `espen_datagen/render.py`**

```python
"""Fill form instance templates from scenario records -> ODK submission XML."""
from __future__ import annotations

import copy
import json
import os
import uuid as uuidlib

from lxml import etree

XF = "http://www.w3.org/2002/xforms"
XFB = "{%s}" % XF


def _localname(el) -> str:
    return el.tag.split("}")[-1] if isinstance(el.tag, str) else el.tag


def _index_by_localname(root) -> dict:
    idx = {}
    for el in root.iter():
        if el is root:
            continue
        idx.setdefault(_localname(el), el)
    return idx


def render_submission(schema, rec, *, instance_id: str) -> bytes:
    data = copy.deepcopy(schema.template)
    idx = _index_by_localname(data)
    for key, value in rec.values.items():
        if key not in idx:
            raise KeyError(f"{schema.key}: node '{key}' not in form template")
        idx[key].text = "" if value is None else str(value)
    # timestamps if the form carries them
    for tkey, tval in (("start", rec.start), ("end", rec.end), ("today", rec.today)):
        if tkey in idx:
            idx[tkey].text = tval
    # meta/instanceID
    meta = data.find(f"{XFB}meta")
    if meta is None:
        meta = etree.SubElement(data, f"{XFB}meta")
    iid = meta.find(f"{XFB}instanceID")
    if iid is None:
        iid = etree.SubElement(meta, f"{XFB}instanceID")
    iid.text = instance_id
    return etree.tostring(data, xml_declaration=True, encoding="UTF-8")


def write_campaign(campaign, schemas: dict, outdir: str) -> dict:
    os.makedirs(outdir, exist_ok=True)
    # persist compiled XForms (what you publish to Ona Data)
    xform_dir = os.path.join(outdir, "xform")
    os.makedirs(xform_dir, exist_ok=True)
    for key, schema in schemas.items():
        with open(os.path.join(xform_dir, f"{key}.xml"), "w", encoding="utf-8") as fh:
            fh.write(schema.xform_xml)
    files = []
    for rec in campaign.records:
        schema = schemas[rec.form_key]
        iid = f"uuid:{uuidlib.uuid4()}"
        xml = render_submission(schema, rec, instance_id=iid)
        sub = os.path.join(outdir, rec.form_key)
        os.makedirs(sub, exist_ok=True)
        fname = f"{iid.split(':', 1)[1]}.xml"
        path = os.path.join(sub, fname)
        with open(path, "wb") as fh:
            fh.write(xml)
        files.append({"form_key": rec.form_key, "form_id": schema.form_id,
                      "instance_id": iid, "path": os.path.relpath(path, outdir)})
    counts = {}
    for rec in campaign.records:
        counts[rec.form_key] = counts.get(rec.form_key, 0) + 1
    manifest = {
        "seed": campaign.config.seed,
        "province": campaign.config.province,
        "diseases": list(campaign.config.diseases),
        "medicine": campaign.config.medicine,
        "footprint": {
            "districts": campaign.config.n_districts,
            "health_facilities": campaign.config.n_hf,
            "villages": campaign.config.n_villages,
            "campaign_days": campaign.config.campaign_days,
        },
        "received": campaign.received,
        "distributed": campaign.distributed,
        "counts_by_form": counts,
        "total_submissions": len(campaign.records),
        "xforms": sorted(schemas),
        "files": files,
    }
    with open(os.path.join(outdir, "manifest.json"), "w") as fh:
        json.dump(manifest, fh, indent=2)
    return manifest
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `.venv/bin/pytest tools/espen-mda-datagen/tests/test_render.py -v`
Expected: PASS (4 tests). If `test_render_sets_values_and_meta` fails because a value
node localname differs from the scenario key, that is a real mismatch bug — fix the
scenario key to match the form's actual node name (confirm with
`print(schemas['1_location'].leaf_names)`), not the renderer.

- [ ] **Step 5: Commit**

```bash
git add tools/espen-mda-datagen/espen_datagen/render.py tools/espen-mda-datagen/tests/test_render.py
git commit -m "feat(datagen): render layer — instance XML + manifest"
```

---

## Task 5: Face-validity report (`report.py`)

Compute the aggregate indicators an ESPEN reviewer eyeballs, and format them with expected bands.

**Files:**
- Create: `tools/espen-mda-datagen/espen_datagen/report.py`
- Test: `tools/espen-mda-datagen/tests/test_report.py`

**Interfaces:**
- Consumes: `Campaign` (Task 3), `realism` (Task 2).
- Produces:
  - `def compute_indicators(campaign) -> dict` with keys: `epi_coverage`,
    `geo_coverage`, `age_distribution` (dict band→fraction), `not_treated_mix`
    (dict reason→fraction), `ivm_stock_balance` (received/distributed/remaining),
    `minor_ae_rate`, `serious_ae_total`, `cdd_total`.
  - `def format_report(ind: dict) -> str` — human-readable, flags each indicator
    `OK`/`CHECK` against its expected band from `realism`.

- [ ] **Step 1: Write failing test `tests/test_report.py`**

```python
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


def test_format_report_mentions_coverage():
    ind = compute_indicators(build_campaign())
    text = format_report(ind)
    assert "coverage" in text.lower()
    assert "%" in text
```

- [ ] **Step 2: Run test to verify it fails**

Run: `.venv/bin/pytest tools/espen-mda-datagen/tests/test_report.py -v`
Expected: FAIL — `ModuleNotFoundError`.

- [ ] **Step 3: Implement `espen_datagen/report.py`**

```python
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `.venv/bin/pytest tools/espen-mda-datagen/tests/test_report.py -v`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add tools/espen-mda-datagen/espen_datagen/report.py tools/espen-mda-datagen/tests/test_report.py
git commit -m "feat(datagen): face-validity report"
```

---

## Task 6: CLI (`generate.py`) + end-to-end + README

Wire the layers into a CLI and verify the whole pipeline produces valid output.

**Files:**
- Create: `tools/espen-mda-datagen/espen_datagen/generate.py`
- Create: `tools/espen-mda-datagen/README.md`
- Test: `tools/espen-mda-datagen/tests/test_generate.py`

**Interfaces:**
- Consumes: all prior modules.
- Produces:
  - `def main(argv: list[str] | None = None) -> int` — args: `--seed`, `--villages`,
    `--days`, `--out` (default `tools/espen-mda-datagen/sample-data`), `--forms-dir`
    (default the repo `forms/espen mda`). Builds campaign, writes XML + manifest, prints
    the face-validity report. Returns 0 on success.
  - `def run(forms_dir, out, cfg) -> dict` — programmatic entry returning the manifest.

- [ ] **Step 1: Write failing test `tests/test_generate.py`**

```python
import json
from lxml import etree
from espen_datagen.generate import run
from espen_datagen.scenario import Config

XF = "{http://www.w3.org/2002/xforms}"


def test_end_to_end_pipeline(forms_dir, tmp_path):
    out = tmp_path / "sample-data"
    manifest = run(forms_dir, str(out), Config(seed=999, n_villages=12, campaign_days=3))
    # manifest counts
    assert manifest["counts_by_form"]["1_location"] == 12
    assert manifest["counts_by_form"]["3_med_treatment"] == 36
    assert manifest["total_submissions"] == sum(manifest["counts_by_form"].values())
    # compiled XForms persisted for Ona publishing
    assert (out / "xform" / "1_location.xml").exists()
    assert len(list((out / "xform").glob("*.xml"))) == 6
    # every file is valid XML with matching form id + uuid instanceID
    for entry in manifest["files"]:
        root = etree.fromstring((out / entry["path"]).read_bytes())
        assert root.get("id") == entry["form_id"]
        assert root.find(f".//{XF}instanceID").text == entry["instance_id"]
    # manifest is valid json on disk
    json.loads((out / "manifest.json").read_text())


def test_run_is_deterministic(forms_dir, tmp_path):
    m1 = run(forms_dir, str(tmp_path / "a"), Config(seed=5))
    m2 = run(forms_dir, str(tmp_path / "b"), Config(seed=5))
    assert m1["counts_by_form"] == m2["counts_by_form"]
    assert m1["received"] == m2["received"]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `.venv/bin/pytest tools/espen-mda-datagen/tests/test_generate.py -v`
Expected: FAIL — `ModuleNotFoundError`.

- [ ] **Step 3: Implement `espen_datagen/generate.py`**

```python
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `.venv/bin/pytest tools/espen-mda-datagen/tests/test_generate.py -v`
Expected: PASS (2 tests).

- [ ] **Step 5: Run the full suite + the CLI for real**

Run:
```bash
.venv/bin/pytest tools/espen-mda-datagen -q
.venv/bin/python -m espen_datagen.generate --out /tmp/espen-out
```
Expected: all tests pass; CLI prints "Wrote N submissions" + the face-validity report;
`/tmp/espen-out` holds six form folders + `manifest.json`. Eyeball the report — coverage
~70-85%, absent dominates non-treatment, stock remaining >= 0.

- [ ] **Step 6: Write `README.md`**

````markdown
# ESPEN MDA sample-data generator

Generates one internally-consistent synthetic ESPEN MDA campaign (onchocerciasis/LF →
ivermectin, Ituri/DRC) and writes it as **ODK submission instance XML** — one file per
submission — for the six `forms/espen mda/` XLSForms. Built to be loaded into **Ona Data**
(OpenRosa) and later transformed to FHIR.

## Run

```bash
uv venv --python 3.13 .venv
uv pip install --python .venv -e "tools/espen-mda-datagen[dev]"
.venv/bin/python -m espen_datagen.generate --out tools/espen-mda-datagen/sample-data
```

Options: `--seed`, `--villages`, `--days`, `--out`, `--forms-dir`. Output is
deterministic per seed.

## Output

```
sample-data/
  1_location/<uuid>.xml ...        # one ODK submission per form, per record
  3_med_treatment/<uuid>.xml ...
  manifest.json                    # seed, footprint, counts, received/distributed, file list
```

Each XML's root `id` matches the compiled `form_id`, with a `uuid:` `meta/instanceID` —
so submissions match the published form on Ona Data.

## Loading into Ona Data (next step)

1. Publish the six XLSForms (or the compiled XForms) to an Ona Data project.
2. Submit each instance XML via the OpenRosa `/submission` endpoint.

## Design

See `docs/superpowers/specs/2026-06-22-espen-mda-sample-data-generator-design.md`.
````

- [ ] **Step 7: Commit**

```bash
git add tools/espen-mda-datagen/espen_datagen/generate.py tools/espen-mda-datagen/README.md tools/espen-mda-datagen/tests/test_generate.py
git commit -m "feat(datagen): CLI + end-to-end + README"
```

---

## Self-Review notes (for the executor)

- **Node-name fidelity is the main risk.** The scenario keys (Task 3) must exactly match
  each form's node localnames. Tasks 4 & 6 assert this (unknown key → `KeyError`; render
  round-trip). If a `KeyError` fires, the fix is in `scenario.py` (correct the key), never
  loosen the renderer. Quick reference dump: `.venv/bin/python -c "from espen_datagen.forms
  import load_all; s=load_all(FORMS_DIR); print(s['3_med_treatment'].leaf_names)"`.
- **`select_multiple` values** (disease, medicine package, channels, training topics) are
  space-joined strings — already handled in the scenario builders.
- **Calculate nodes** (`l_eligible_pop`, `*_men_treated`, `*_women_treated`, `s_total_dist`)
  are filled with the computed value, since a static submission has no calc engine.
- **Determinism**: one `random.Random(seed)` threaded through the scenario; UUIDs are
  per-file and intentionally NOT seeded (instance IDs should be globally unique).
- **Out of scope** (per spec): live Ona/ODK push, real Overture geography, CSV, the
  OpenFn→FHIR step.
