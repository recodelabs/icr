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


def fix_asset_hrefs(item: dict, item_dir: Path) -> None:
    # portolan-cli 0.8 writes a hive partition item's data href as "../part-0.parquet",
    # one directory above the item JSON; the file sits beside it.
    for asset in item.get("assets", {}).values():
        href = asset.get("href", "")
        if href.startswith(("http://", "https://", "s3://")):
            continue
        if not (item_dir / href).exists() and (item_dir / Path(href).name).exists():
            asset["href"] = f"./{Path(href).name}"


def retitle_items(coll: dict, coll_dir: Path) -> int:
    n = 0
    for link in coll.get("links", []):
        if link.get("rel") != "item":
            continue
        item_path = coll_dir / link["href"]
        item = json.loads(item_path.read_text())
        fix_asset_hrefs(item, item_path.parent)
        title = item_title(item["id"])
        if title:
            item["properties"]["title"] = title
            link["title"] = title
            n += 1
        item_path.write_text(json.dumps(item, indent=2) + "\n")
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
    coll["assets"] = {k: v for k, v in coll.get("assets", {}).items()
                      if not k.startswith("style-") and not k.endswith("-tiles")}

    for name, (title, layers, style, style_title) in TILES.items():
        archive = data / "tiles" / f"{name}.pmtiles"
        if not archive.exists():
            print(f"   skip {name}: {archive} missing", file=sys.stderr)
            continue
        href = f"../../tiles/{name}.pmtiles"
        coll["links"].append({
            "rel": "pmtiles", "href": href, "type": PMTILES_TYPE, "title": title, "pmtiles:layers": layers,
        })
        # The Portolan browser renders PMTiles from a `visual` asset, not from the link
        # (the spec lets the two coexist).
        coll["assets"][f"{name}-tiles"] = {
            "href": href, "type": PMTILES_TYPE, "title": f"{title} (PMTiles)", "roles": ["visual"],
            "file:size": archive.stat().st_size, "file:checksum": multihash(archive),
        }
        style_file = styles_dir / f"{style}.json"
        shutil.copyfile(src_styles / f"{style}.json", style_file)
        coll["assets"][f"style-{style}"] = {
            "href": f"./styles/{style}.json", "type": STYLE_TYPE, "title": style_title,
            "roles": ["style", "default"] if style == "default" else ["style"],
            "file:size": style_file.stat().st_size, "file:checksum": multihash(style_file),
        }

    # The thumbnail is rendered once with chiitiler over the default style (see the
    # portolan-thumbnails skill) and kept beside the styles; re-render when the tiles change.
    src_thumb = src_styles.parent / "thumbnail.png"
    coll["assets"].pop("thumbnail", None)
    if src_thumb.exists():
        thumb = coll_dir / "thumbnail.png"
        shutil.copyfile(src_thumb, thumb)
        coll["assets"]["thumbnail"] = {
            "href": "./thumbnail.png", "type": "image/png", "title": "Nigeria — administrative boundaries",
            "roles": ["thumbnail"], "file:size": thumb.stat().st_size, "file:checksum": multihash(thumb),
        }

    coll_path.write_text(json.dumps(coll, indent=2) + "\n")
    print(f"   {titled} items titled, {len([l for l in coll['links'] if l['rel'] == 'pmtiles'])} pmtiles links, "
          f"{len([k for k in coll['assets'] if k.startswith('style-')])} styles, "
          f"thumbnail={'yes' if src_thumb.exists() else 'no'} → {coll_path.relative_to(data)}")


if __name__ == "__main__":
    main(Path(sys.argv[1]).resolve())
