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
