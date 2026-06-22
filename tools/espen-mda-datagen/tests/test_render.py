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
