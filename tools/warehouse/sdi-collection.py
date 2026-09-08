#!/usr/bin/env python3
"""Link the location PMTiles and their MapLibre styles into the Portolan collection.

    sdi-tiles.py DATA_DIR

The tiles live in DATA_DIR/tiles/ (built by tiles.sh) and are shared with the
dashboards, so the collection references them in place rather than copying:
a collection-level `rel: pmtiles` link per archive (STAC web-map-links 1.3.0)
and one style asset per archive in parquet/locations/styles/, copied from
.portolan/collections/locations/styles/ (kiln replaces parquet/locations/ on
every run). Idempotent: re-running replaces what it added before.
"""
from __future__ import annotations

import hashlib
import json
import shutil
import sys
from pathlib import Path

WEB_MAP_LINKS = "https://stac-extensions.github.io/web-map-links/v1.3.0/schema.json"
PMTILES_TYPE = "application/vnd.pmtiles"
STYLE_TYPE = "application/vnd.mapbox.style+json"

# The CLI names each partition item after its hive path ("country=NGA Geom Type=point
# Type=facility"); these give the items the titles people see in the browser.
COUNTRIES = {"NGA": "Nigeria", "NG": "Nigeria", "SL": "Sierra Leone", "SLE": "Sierra Leone"}
TYPES = {
    "admin-unit": "administrative boundaries",
    "facility": "health facilities",
    "settlement": "settlements",
    "school": "schools",
    "null": "locations without a type",
}

# archive → (title, default-visible layers, style file, style title)
TILES = {
    "admin": ("Administrative boundaries (country, states, LGAs)", ["lgas", "states", "country"], "default", "Administrative boundaries"),
    "facilities": ("Health facilities", ["facilities"], "facilities", "Health facilities by level"),
    "settlements": ("Settlements", ["settlements"], "settlements", "Settlements by type"),
}


def multihash(path: Path) -> str:
    return "1220" + hashlib.sha256(path.read_bytes()).hexdigest()


def item_title(item_id: str) -> str | None:
    keys = dict(part.split("=", 1) for part in item_id.split("_") if "=" in part)
    if "country" not in keys or "type" not in keys:
        return None
    country = COUNTRIES.get(keys["country"], keys["country"])
    what = TYPES.get(keys["type"], keys["type"].replace("-", " "))
    return f"{country} — {what}"


def retitle_items(coll: dict, coll_dir: Path) -> int:
    n = 0
    for link in coll.get("links", []):
        if link.get("rel") != "item":
            continue
        item_path = coll_dir / link["href"]
        item = json.loads(item_path.read_text())
        title = item_title(item["id"])
        if not title:
            continue
        item["properties"]["title"] = title
        link["title"] = title
        item_path.write_text(json.dumps(item, indent=2) + "\n")
        n += 1
    return n


def main(data: Path) -> None:
    coll_dir = data / "parquet" / "locations"
    coll_path = coll_dir / "collection.json"
    src_styles = data / ".portolan" / "collections" / "locations" / "styles"
    coll = json.loads(coll_path.read_text())

    titled = retitle_items(coll, coll_dir)

    styles_dir = coll_dir / "styles"
    styles_dir.mkdir(exist_ok=True)

    exts = coll.setdefault("stac_extensions", [])
    if WEB_MAP_LINKS not in exts:
        exts.append(WEB_MAP_LINKS)

    coll["links"] = [l for l in coll.get("links", []) if l.get("rel") != "pmtiles"]
    coll["assets"] = {k: v for k, v in coll.get("assets", {}).items() if not k.startswith("style-")}

    for name, (title, layers, style, style_title) in TILES.items():
        archive = data / "tiles" / f"{name}.pmtiles"
        if not archive.exists():
            print(f"   skip {name}: {archive} missing", file=sys.stderr)
            continue
        coll["links"].append({
            "rel": "pmtiles", "href": f"../../tiles/{name}.pmtiles", "type": PMTILES_TYPE,
            "title": title, "pmtiles:layers": layers,
        })
        style_file = styles_dir / f"{style}.json"
        shutil.copyfile(src_styles / f"{style}.json", style_file)
        coll["assets"][f"style-{style}"] = {
            "href": f"./styles/{style}.json", "type": STYLE_TYPE, "title": style_title,
            "roles": ["style", "default"] if style == "default" else ["style"],
            "file:size": style_file.stat().st_size, "file:checksum": multihash(style_file),
        }

    coll_path.write_text(json.dumps(coll, indent=2) + "\n")
    print(f"   {titled} items titled, {len([l for l in coll['links'] if l['rel'] == 'pmtiles'])} pmtiles links, "
          f"{len([k for k in coll['assets'] if k.startswith('style-')])} styles → {coll_path.relative_to(data)}")


if __name__ == "__main__":
    main(Path(sys.argv[1]).resolve())
