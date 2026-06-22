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
