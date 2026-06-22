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
