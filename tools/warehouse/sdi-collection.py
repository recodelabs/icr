#!/usr/bin/env python3
"""Link the location PMTiles and their MapLibre styles into the Portolan collection.

    sdi-tiles.py DATA_DIR

The tiles live in DATA_DIR/tiles/ (built by the tiles step of refresh.sh) and are shared with the
dashboards, so the collection references them in place rather than copying:
a collection-level `rel: pmtiles` link per archive (STAC web-map-links 1.3.0)
and one style asset per archive in parquet/locations/styles/, copied from
.portolan/collections/locations/styles/ (kiln replaces parquet/locations/ on
every run). Idempotent: re-running replaces what it added before.

It also catalogues the files of Locations that have no geometry (kiln transform
--keep-without-geometry writes them under geom_type=null/). portolan-cli 0.8 treats a
GeoParquet file whose geometries are all null as plain tabular data: it makes no item
for it and adds a loose collection asset named after the file alone ("part-0",
"./part-0.parquet"), so two such files collide and the asset points at nothing. Here
each of those files gets an item like the others, with a null geometry and no bbox,
and the broken loose asset is removed. An item's footprint is the extent of its
country's other items (the rows have none of their own): stac-geoparquet, which builds
items.parquet, cannot take an item with a null geometry, and a footprint keeps the files
findable by area.
"""
from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

WEB_MAP_LINKS = "https://stac-extensions.github.io/web-map-links/v1.3.0/schema.json"
PMTILES_TYPE = "application/vnd.pmtiles"
STYLE_TYPE = "application/vnd.mapbox.style+json"

# The CLI names each partition item after its hive path ("country=NGA Geom Type=point
# Type=facility"); these give the items the titles people see in the browser.
COUNTRIES = {"NGA": "Nigeria", "NG": "Nigeria", "SL": "Sierra Leone", "SLE": "Sierra Leone",
             "UGA": "Uganda", "UG": "Uganda"}
TYPES = {
    "admin-unit": "administrative boundaries",
    "facility": "health facilities",
    "settlement": "settlements",
    "school": "schools",
    "null": "locations without a type",
}

# archive → (title, default-visible layers, style file, style title). A catalog can rename the
# titles in .portolan/collections/locations/tiles.json ({"admin": {"title": …, "style_title": …},
# "thumbnail_title": …}), e.g. Uganda's regions and districts where Nigeria has states and LGAs.
TILES = {
    "admin": ("Administrative boundaries (country, states, LGAs)", ["lgas", "states", "country"], "default", "Administrative boundaries"),
    "facilities": ("Health facilities", ["facilities"], "facilities", "Health facilities by level"),
    "settlements": ("Settlements", ["settlements"], "settlements", "Settlements by type"),
}


def multihash(path: Path) -> str:
    return "1220" + hashlib.sha256(path.read_bytes()).hexdigest()


def hive_keys(item_id: str) -> dict[str, str]:
    # "country=NGA_geom_type=null_type=facility": keys may contain "_" themselves.
    return dict(re.findall(r"([a-z]+(?:_[a-z]+)*)=([^_]*)", item_id))


def item_title(item_id: str) -> str | None:
    keys = hive_keys(item_id)
    if "country" not in keys or "type" not in keys:
        return None
    country = COUNTRIES.get(keys["country"], keys["country"])
    what = TYPES.get(keys["type"], keys["type"].replace("-", " "))
    if keys.get("geom_type") == "null":
        what += " without coordinates"
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


def row_count(path: Path) -> int | None:
    try:
        out = subprocess.check_output(
            ["duckdb", "-noheader", "-csv", "-c", f"SELECT count(*) FROM read_parquet('{path}')"])
        return int(out.decode().strip())
    except (OSError, subprocess.CalledProcessError, ValueError):
        return None


def add_items_without_geometry(coll: dict, coll_dir: Path) -> int:
    """One item per partition file that portolan left without one (see the module docstring)."""
    # The loose assets portolan adds for those files point at the collection directory,
    # where kiln writes no data files.
    coll["assets"] = {k: v for k, v in coll.get("assets", {}).items()
                      if not (v.get("href", "").endswith(".parquet") and "*" not in v["href"]
                              and k != "geoparquet-items" and not (coll_dir / v["href"]).exists())}

    linked = {(coll_dir / l["href"]).resolve() for l in coll.get("links", []) if l.get("rel") == "item"}
    items = [coll_dir / l["href"] for l in coll.get("links", []) if l.get("rel") == "item"]
    template = json.loads(items[0].read_text()) if items else {}
    datetime = template.get("properties", {}).get("datetime")
    collection_id = template.get("collection", coll.get("id"))
    # Country → bbox over the items that have one.
    extents: dict[str, list[float]] = {}
    for path in items:
        item = json.loads(path.read_text())
        country = hive_keys(item["id"]).get("country")
        if country and item.get("bbox"):
            b = item["bbox"]
            e = extents.setdefault(country, list(b))
            extents[country] = [min(e[0], b[0]), min(e[1], b[1]), max(e[2], b[2]), max(e[3], b[3])]
    fallback = (coll.get("extent", {}).get("spatial", {}).get("bbox") or [[-180, -90, 180, 90]])[0]
    root = coll_dir.parent.parent / "catalog.json"

    n = 0
    for data_file in sorted(coll_dir.glob("*=*/**/*.parquet")):
        item_dir = data_file.parent
        hive = [part for part in item_dir.relative_to(coll_dir).parts if "=" in part]
        item_id = "_".join(hive)
        item_path = item_dir / f"{item_id}.json"
        if item_path.resolve() in linked or any(p.parent == item_dir for p in linked):
            continue
        rows = row_count(data_file)
        country = dict(part.split("=", 1) for part in hive).get("country")
        x0, y0, x1, y1 = extents.get(country, fallback)
        item = {
            "type": "Feature",
            "stac_version": "1.1.0",
            "stac_extensions": [],
            "id": item_id,
            "geometry": {"type": "Polygon",
                         "coordinates": [[[x0, y0], [x1, y0], [x1, y1], [x0, y1], [x0, y0]]]},
            "bbox": [x0, y0, x1, y1],
            "properties": {
                **({"geoparquet:feature_count": rows} if rows is not None else {}),
                "description": ("Locations with no point and no boundary yet: the geometry column is null "
                                "in every row. The item's footprint is the extent of the country's other "
                                "locations, not of these rows."),
                "datetime": datetime,
            },
            "links": [
                {"rel": "root", "href": os.path.relpath(root, item_dir), "type": "application/json"},
                {"rel": "collection", "href": os.path.relpath(coll_dir / "collection.json", item_dir),
                 "type": "application/json", "title": coll.get("title")},
                {"rel": "parent", "href": os.path.relpath(coll_dir / "collection.json", item_dir),
                 "type": "application/json", "title": coll.get("title")},
            ],
            "assets": {
                "data": {
                    "href": f"./{data_file.name}", "type": "application/vnd.apache.parquet",
                    "file:size": data_file.stat().st_size, "file:checksum": multihash(data_file),
                    "roles": ["data"],
                },
            },
            "collection": collection_id,
        }
        item_path.write_text(json.dumps(item, indent=2) + "\n")
        coll["links"].append({"rel": "item", "href": f"./{item_path.relative_to(coll_dir)}",
                              "type": "application/geo+json"})
        linked.add(item_path.resolve())
        n += 1
    return n


def main(data: Path) -> None:
    coll_dir = data / "parquet" / "locations"
    coll_path = coll_dir / "collection.json"
    src_styles = data / ".portolan" / "collections" / "locations" / "styles"
    coll = json.loads(coll_path.read_text())
    titles_file = src_styles.parent / "tiles.json"
    titles = json.loads(titles_file.read_text()) if titles_file.exists() else {}

    without_geometry = add_items_without_geometry(coll, coll_dir)
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
        title = titles.get(name, {}).get("title", title)
        style_title = titles.get(name, {}).get("style_title", style_title)
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
            "href": "./thumbnail.png", "type": "image/png",
            "title": titles.get("thumbnail_title", "Nigeria — administrative boundaries"),
            "roles": ["thumbnail"], "file:size": thumb.stat().st_size, "file:checksum": multihash(thumb),
        }

    coll_path.write_text(json.dumps(coll, indent=2) + "\n")
    print(f"   {without_geometry} items without geometry added, {titled} items titled, {len([l for l in coll['links'] if l['rel'] == 'pmtiles'])} pmtiles links, "
          f"{len([k for k in coll['assets'] if k.startswith('style-')])} styles, "
          f"thumbnail={'yes' if src_thumb.exists() else 'no'} → {coll_path.relative_to(data)}")


if __name__ == "__main__":
    main(Path(sys.argv[1]).resolve())
