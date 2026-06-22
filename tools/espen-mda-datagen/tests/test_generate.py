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
