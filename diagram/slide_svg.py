"""Make a slide-ready copy of a static diagram SVG.

The static SVGs from build.py style their shapes with CSS classes and load their fonts
from Google Fonts. PowerPoint, Keynote and Google Slides ignore most of that. This copy
writes the colours and line styles onto each shape, turns the text into outlines (so it
looks the same without the fonts installed), and draws the arrowheads as plain triangles
instead of SVG markers.

  uv run --with fonttools --with uharfbuzz python3 diagram/slide_svg.py [diagram/icr-architecture.svg]

writes diagram/icr-architecture-slide.svg (and the copy in site/architecture/).
"""
import math
import pathlib
import re
import shutil
import sys
import urllib.request
import xml.etree.ElementTree as ET

import uharfbuzz as hb
from fontTools.pens.svgPathPen import SVGPathPen

HERE = pathlib.Path(__file__).resolve().parent
SITE = HERE.parent / "site" / "architecture"
FONTS = pathlib.Path.home() / ".cache" / "icr-diagram-fonts"
FONT_URLS = {
    "bricolage": "https://github.com/google/fonts/raw/main/ofl/bricolagegrotesque/BricolageGrotesque%5Bopsz,wdth,wght%5D.ttf",
    "plex-400": "https://github.com/google/fonts/raw/main/ofl/ibmplexmono/IBMPlexMono-Regular.ttf",
    "plex-500": "https://github.com/google/fonts/raw/main/ofl/ibmplexmono/IBMPlexMono-Medium.ttf",
}
NS = "http://www.w3.org/2000/svg"

# The palette and the CSS rules of build.py, written out per class.
INK, INK2, MUTED, HAIR = "#17211C", "#4A554F", "#6F7A74", "#C9CFC7"
PAPER, SURFACE, ACCENT, ACCENT_INK = "#F7F8F5", "#EEF1EB", "#F16427", "#A13A10"
SHAPES = {
    "bg": {"fill": PAPER},
    "box": {"fill": SURFACE, "stroke": INK, "stroke-width": "1.25"},
    "icr": {"fill": PAPER, "stroke": ACCENT, "stroke-width": "1.75", "stroke-dasharray": "7 4"},
    "cell": {"fill": SURFACE, "stroke": INK, "stroke-width": "1"},
    "group": {"fill": "none", "stroke": INK2, "stroke-width": "1", "stroke-dasharray": "5 4"},
    "chip": {"fill": PAPER, "stroke": HAIR, "stroke-width": "1"},
    "wire": {"fill": "none", "stroke": INK2, "stroke-width": "1.25"},
    "rule": {"stroke": HAIR, "stroke-width": "1"},
}
# font, size, weight, letter-spacing (em), fill; later classes override earlier ones
TEXT = {
    "name": {"size": 15.5, "weight": 600},
    "sub": {"size": 12, "fill": INK2},
    "body": {"size": 11.5},
    "mono": {"font": "plex", "size": 9.5, "ls": 0.08},
    "code": {"font": "plex", "size": 9, "fill": MUTED},
    "muted": {"fill": MUTED},
    "h-in": {"fill": ACCENT_INK, "weight": 500},
    "h-out": {"weight": 500},
    "title": {"weight": 700, "ls": -0.01},
    "caption": {"size": 15, "weight": 600},
    "cellname": {"size": 13.5, "weight": 600},
}


def font_file(key):
    path = FONTS / FONT_URLS[key].rsplit("/", 1)[1].replace("%5B", "[").replace("%5D", "]")
    if not path.exists():
        FONTS.mkdir(parents=True, exist_ok=True)
        urllib.request.urlretrieve(FONT_URLS[key], path)
    return path


_fonts = {}


def hb_font(family, weight, size):
    """A HarfBuzz font at the instance a browser would pick (optical size follows px size)."""
    if family == "plex":
        key = ("plex", 500 if weight >= 500 else 400)
        if key not in _fonts:
            _fonts[key] = hb.Font(hb.Face(font_file(f"plex-{key[1]}").read_bytes()))
        return _fonts[key]
    key = ("bricolage", weight, size)
    if key not in _fonts:
        f = hb.Font(hb.Face(font_file("bricolage").read_bytes()))
        f.set_variations({"wght": weight, "opsz": min(max(size, 12), 96), "wdth": 100})
        _fonts[key] = f
    return _fonts[key]


def outline(text, x, y, anchor, style):
    font = hb_font(style["font"], style["weight"], style["size"])
    upem = font.face.upem
    scale = style["size"] / upem
    buf = hb.Buffer()
    buf.add_str(text)
    buf.guess_segment_properties()
    hb.shape(font, buf, {"kern": True, "liga": style["ls"] == 0})
    spacing = style["ls"] * style["size"]
    width = sum(p.x_advance * scale + spacing for p in buf.glyph_positions)
    pen_x = x - {"start": 0, "middle": width / 2, "end": width}[anchor]
    parts = []
    for info, pos in zip(buf.glyph_infos, buf.glyph_positions):
        pen = SVGPathPen(None, lambda v: f"{v:.2f}".rstrip("0").rstrip("."))
        font.draw_glyph_with_pen(info.codepoint, pen)
        d = pen.getCommands()
        if d:
            gx, gy = pen_x + pos.x_offset * scale, y - pos.y_offset * scale
            parts.append(f'<path transform="translate({gx:.2f} {gy:.2f}) scale({scale:.5f} {-scale:.5f})" d="{d}"/>')
        pen_x += pos.x_advance * scale + spacing
    return parts


def arrowhead(tip, before, fill):
    """The build.py marker (M0,1 L10,5 L0,9 z, refX 9) drawn at `tip`, pointing away from `before`."""
    a = math.atan2(tip[1] - before[1], tip[0] - before[0])
    c, s = math.cos(a), math.sin(a)
    pts = [(tip[0] + px * c - py * s, tip[1] + px * s + py * c) for px, py in ((-9, -4), (1, 0), (-9, 4))]
    return f'<path fill="{fill}" d="M{pts[0][0]:.2f},{pts[0][1]:.2f} L{pts[1][0]:.2f},{pts[1][1]:.2f} L{pts[2][0]:.2f},{pts[2][1]:.2f} z"/>'


def points(d):
    """Points of a path made of M, L and h/v commands."""
    pts, cur = [], (0.0, 0.0)
    for cmd, args in re.findall(r"([MLhvHV])\s*([-\d.,\s]+)", d):
        nums = [float(n) for n in re.split(r"[\s,]+", args.strip()) if n]
        if cmd in "ML":
            cur = (nums[0], nums[1])
        elif cmd == "h":
            cur = (cur[0] + nums[0], cur[1])
        elif cmd == "v":
            cur = (cur[0], cur[1] + nums[0])
        elif cmd == "H":
            cur = (nums[0], cur[1])
        elif cmd == "V":
            cur = (cur[0], nums[0])
        pts.append(cur)
    return pts


def attrs(el, skip=("class", "id", "marker-start", "marker-end")):
    return "".join(f' {k}="{v}"' for k, v in el.attrib.items() if k not in skip)


def convert(src):
    root = ET.parse(src).getroot()
    w, h = root.get("width"), root.get("height")
    label = root.get("aria-label", "")
    heads = {"a-in": ACCENT, "a-out": INK}
    out = [f'<svg xmlns="{NS}" viewBox="0 0 {w} {h}" width="{w}" height="{h}" role="img" aria-label="{label}">',
           f"<title>{label}</title>"]

    def walk(el):
        tag = el.tag.split("}")[1]
        if tag in ("title", "style", "defs", "marker"):
            return
        if tag in ("svg", "g"):
            for child in el:
                walk(child)
            return
        classes = el.get("class", "").split()
        if tag == "text":
            style = {"font": "bricolage", "size": 12, "weight": 400, "ls": 0, "fill": INK}
            for c in classes:
                style.update(TEXT.get(c, {}))
            if el.get("font-size"):
                style["size"] = float(el.get("font-size"))
            text = " ".join("".join(el.itertext()).split())
            glyphs = outline(text, float(el.get("x")), float(el.get("y")), el.get("text-anchor", "start"), style)
            out.append(f'<g fill="{style["fill"]}" aria-label="{text}">' + "".join(glyphs) + "</g>")
            return
        style = {}
        for c in classes:
            style.update(SHAPES.get(c, {}))
        out.append(f"<{tag}{attrs(el)}" + "".join(f' {k}="{v}"' for k, v in style.items()) + "/>")
        if tag == "path" and ("marker-start" in el.attrib or "marker-end" in el.attrib):
            pts = points(el.get("d"))
            for which, tip, before in (("marker-start", pts[0], pts[1]), ("marker-end", pts[-1], pts[-2])):
                ref = el.get(which)
                if ref:
                    out.append(arrowhead(tip, before, heads[ref[5:-1]]))

    walk(root)
    out.append("</svg>")
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    src = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else HERE / "icr-architecture.svg")
    dst = src.with_name(src.stem + "-slide.svg")
    dst.write_text(convert(src))
    if SITE.exists():
        shutil.copy(dst, SITE / dst.name)
    print(f"wrote {dst.name}")
