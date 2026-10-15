#!/usr/bin/env python3
"""Builds the ICR solution-architecture diagrams.

Writes, next to this file:
  icr-architecture.svg            how the ICR fits into a country's campaign systems
  icr-architecture-animated.svg   the same, with the workflow played step by step
  icr-country-flows.svg           one country's NTD programme: what goes in and out of the ICR
  icr-country-flows-animated.svg  the same, animated
  index.html                      a page that plays both animations, with controls (claude.ai artifact)
  *.png                           2x PNGs of the static SVGs for slides (needs Google Chrome)

and copies them all to site/architecture/, with a full-page index.html, for
https://www.healthcampaigns.org/architecture/.

The animations are SMIL, so the animated SVGs also play on their own (in a browser,
an <img> tag or a slide tool that renders SVG). Everything moves on one loop of T
seconds, so each element's timing is a set of keyTimes on that loop.

  python3 diagram/build.py
"""
import html
import json
import math
import shutil
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent

FONTS = ("https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,400;12..96,600;12..96,700"
         "&family=Source+Serif+4:ital,opsz,wght@0,8..60,400;0,8..60,600;1,8..60,400"
         "&family=IBM+Plex+Mono:wght@400;500&display=swap")

# The look of www.healthcampaigns.org: its paper, ink and registry green, Bricolage
# Grotesque and IBM Plex Mono, with orange for the ICR and data going into it. Colours come from --d-* variables, with these values as
# the fallbacks used when an SVG file is opened on its own.
CSS = """
.bg{fill:var(--d-paper,#F7F8F5)}
.box{fill:var(--d-surface,#EEF1EB);stroke:var(--d-ink,#17211C);stroke-width:1.25}
.icr{fill:var(--d-paper,#F7F8F5);stroke:var(--d-accent,#F16427);stroke-width:1.75;stroke-dasharray:7 4}
.cell{fill:var(--d-surface,#EEF1EB);stroke:var(--d-ink,#17211C);stroke-width:1}
.group{fill:none;stroke:var(--d-ink2,#4A554F);stroke-width:1;stroke-dasharray:5 4}
.chip{fill:var(--d-paper,#F7F8F5);stroke:var(--d-hair,#C9CFC7);stroke-width:1}
.wire{fill:none;stroke:var(--d-ink2,#4A554F);stroke-width:1.25}
.rule{stroke:var(--d-hair,#C9CFC7);stroke-width:1}
.ah-in,.dot-in,.mk-on,.hlbar{fill:var(--d-accent,#F16427)}
.ah-out,.dot-out{fill:var(--d-ink,#17211C)}
.hl{fill:none;stroke:var(--d-accent,#F16427);stroke-width:2.5}
.tint{fill:var(--d-tint,rgba(241,100,39,.13))}
.mk-off{fill:var(--d-faint,#D5DAD3)}
.dg text{font-family:'Bricolage Grotesque',ui-sans-serif,system-ui,sans-serif;fill:var(--d-ink,#17211C)}
.dg .name{font-size:15.5px;font-weight:600}
.dg .sub{font-size:12px;fill:var(--d-ink2,#4A554F)}
.dg .body{font-size:11.5px}
.dg .mono,.dg .code{font-family:'IBM Plex Mono',ui-monospace,Menlo,monospace}
.dg .mono{font-size:9.5px;letter-spacing:.08em}
.dg .code{font-size:9px;fill:var(--d-muted,#6F7A74)}
.dg .muted{fill:var(--d-muted,#6F7A74)}
.dg .h-in{fill:var(--d-accent-ink,#A13A10);font-weight:500}
.dg .h-out{font-weight:500}
.dg .title{font-weight:700;letter-spacing:-.01em}
.dg .caption{font-size:15px;font-weight:600}
.dg .cellname{font-size:13.5px;font-weight:600}
"""


def esc(s):
    return html.escape(str(s), quote=True)


def fmt(v):
    return f"{v:.4f}".rstrip("0").rstrip(".")


def polyline_length(points):
    return sum(math.dist(a, b) for a, b in zip(points, points[1:]))


def d_of(points):
    return "M" + " L".join(f"{x:g},{y:g}" for x, y in points)


class Diagram:
    """Collects layered SVG parts; anim parts appear only in the animated version."""

    LAYERS = ("back", "wires", "dots", "nodes", "chips", "over", "strip")

    def __init__(self, key, w, h, T, label):
        self.key, self.w, self.h, self.T, self.label = key, w, h, T, label
        self.layers = {k: [] for k in self.LAYERS}
        self.stages = []
        self.streams = []

    def add(self, layer, svg, anim=False):
        self.layers[layer].append((svg, anim))

    # --- timing ------------------------------------------------------------

    def opacity(self, windows, fade=0.3):
        """An <animate> that shows an element during each (start, end) window."""
        T = self.T
        pts = [(0.0, 0.0)]
        for a, b in sorted(windows):
            pts += [(a, 0), (a + fade, 1), (b - fade, 1), (b, 0)]
        pts.append((T, 0))
        times = ";".join(fmt(t / T) for t, _ in pts)
        values = ";".join(str(v) for _, v in pts)
        return (f'<animate attributeName="opacity" dur="{T}s" repeatCount="indefinite" '
                f'calcMode="linear" keyTimes="{times}" values="{values}"/>')

    # --- drawing -----------------------------------------------------------

    def node(self, x, y, w, h, name, sub=None, code=None, hl=()):
        out = [f'<rect class="box" x="{x}" y="{y}" width="{w}" height="{h}" rx="3"/>']
        if sub or code:
            out.append(f'<text class="name" x="{x + 14}" y="{y + 27}">{esc(name)}</text>')
            if sub:
                out.append(f'<text class="sub" x="{x + 14}" y="{y + 46}">{esc(sub)}</text>')
            if code:
                out.append(f'<text class="code" x="{x + 14}" y="{y + h - 12}">{esc(code)}</text>')
        else:
            out.append(f'<text class="name" x="{x + 14}" y="{y + h / 2 + 5}">{esc(name)}</text>')
        self.add("nodes", "".join(out))
        if hl:
            self.add("over", f'<rect class="hl" x="{x}" y="{y}" width="{w}" height="{h}" rx="3" '
                             f'opacity="0">{self.opacity(hl)}</rect>', anim=True)

    def cell(self, x, y, w, h, lines, desc=(), code=None, hl=(), center=False):
        out = [f'<rect class="cell" x="{x}" y="{y}" width="{w}" height="{h}" rx="2"/>']
        if center:
            top = y + h / 2 - (len(lines) - 1) * 8 + 4
            for i, ln in enumerate(lines):
                out.append(f'<text class="cellname" x="{x + w / 2}" y="{top + i * 16}" '
                           f'text-anchor="middle">{esc(ln)}</text>')
        else:
            out.append(f'<text class="name" x="{x + 14}" y="{y + 26}">{esc(lines[0])}</text>')
            for i, ln in enumerate(desc):
                out.append(f'<text class="sub" x="{x + 14}" y="{y + 48 + i * 16}">{esc(ln)}</text>')
            if code:
                out.append(f'<text class="code" x="{x + 14}" y="{y + h - 13}">{esc(code)}</text>')
        self.add("nodes", "".join(out))
        if hl:
            self.add("over", f'<rect class="tint" x="{x}" y="{y}" width="{w}" height="{h}" rx="2" '
                             f'opacity="0">{self.opacity(hl)}</rect>'
                             f'<rect class="hl" x="{x}" y="{y}" width="{w}" height="{h}" rx="2" '
                             f'opacity="0">{self.opacity(hl)}</rect>', anim=True)

    def chip(self, cx, cy, w, sections):
        """A label sitting on a wire. sections: (direction, header, lines, highlight windows);
        direction "in" (into the ICR, orange) or "out" (ink)."""
        pad, hh, lh, gap = 9, 14, 15, 8
        h = pad * 2 + sum(hh + lh * len(s[2]) for s in sections) + gap * (len(sections) - 1)
        x, y = cx - w / 2, cy - h / 2
        self.add("chips", f'<rect class="chip" x="{x:g}" y="{y:g}" width="{w}" height="{h}" rx="2"/>')
        yy = y + pad
        for direction, header, lines, hl in sections:
            sh = hh + lh * len(lines)
            if hl:
                self.add("chips", f'<g opacity="0"><rect class="tint" x="{x + 1:g}" y="{yy - 5:g}" '
                                  f'width="{w - 2}" height="{sh + 8}"/><rect class="hlbar" x="{x + 1:g}" '
                                  f'y="{yy - 5:g}" width="2.5" height="{sh + 8}"/>{self.opacity(hl)}</g>',
                         anim=True)
            parts = [f'<text class="mono h-{direction}" x="{x + 12:g}" y="{yy + 8:g}">{esc(header)}</text>']
            for i, ln in enumerate(lines):
                parts.append(f'<text class="body" x="{x + 12:g}" y="{yy + hh + 9 + i * lh:g}">{esc(ln)}</text>')
            self.add("chips", "".join(parts))
            yy += sh + gap

    def wire(self, pid, points, start=None, end=None):
        """A connector drawn from points[0] to points[-1]; start/end name the arrowheads
        ("in" orange, "out" ink) at each end."""
        attrs = ""
        if start:
            attrs += f' marker-start="url(#{self.key}-{start})"'
        if end:
            attrs += f' marker-end="url(#{self.key}-{end})"'
        self.add("wires", f'<path id="{self.key}-{pid}" class="wire" d="{d_of(points)}"{attrs}/>')
        return points

    def stream(self, pid, points, at, forward, kind, n=3, speed=260, spacing=0.2):
        """Dots running along wire pid; forward follows the wire's drawing direction."""
        T = self.T
        # long routes run faster, so every dot arrives before its step stops
        dur = min(1.5, max(0.7, polyline_length(points) / speed))
        for i in range(n):
            s = at + i * spacing
            kp = "0;0;1;1" if forward else "1;1;0;0"
            kt = f"0;{fmt(s / T)};{fmt((s + dur) / T)};1"
            self.add("dots",
                     f'<circle class="dot-{kind}" r="4.5" opacity="0">'
                     f'<animateMotion dur="{T}s" repeatCount="indefinite" calcMode="linear" '
                     f'keyPoints="{kp}" keyTimes="{kt}"><mpath href="#{self.key}-{pid}" '
                     f'xlink:href="#{self.key}-{pid}"/></animateMotion>'
                     f'{self.opacity([(s, s + dur)], fade=0.08)}</circle>', anim=True)
        end = at + (n - 1) * spacing + dur
        self.streams.append((pid, at, end))
        return end

    def text(self, layer, x, y, s, cls, anchor=None, anim=False):
        a = f' text-anchor="{anchor}"' if anchor else ""
        self.add(layer, f'<text class="{cls}" x="{x:g}" y="{y:g}"{a}>{esc(s)}</text>', anim=anim)

    def legend(self, x, y):
        self.add("back",
                 f'<path class="wire" d="M{x},{y} h34" marker-end="url(#{self.key}-in)"/>'
                 f'<text class="sub" x="{x + 44}" y="{y + 4}">data going into the ICR</text>'
                 f'<path class="wire" d="M{x + 210},{y} h34" marker-end="url(#{self.key}-out)"/>'
                 f'<text class="sub" x="{x + 254}" y="{y + 4}">data going out of the ICR, or between tools</text>')

    def strip(self, y, stages):
        """Step markers and captions under the diagram (animated version only).
        stages: (start, end, label, caption lines)."""
        self.stages = [(a, label) for a, _, label, _ in stages]
        # a step played on its own stops 0.6 s before it ends (see the page script)
        for pid, at, end in self.streams:
            a, b = next((a, b) for a, b, _, _ in stages if a <= at < b)
            assert end <= b - 0.65, f"{self.key}: dots on {pid} arrive at {end:.2f}s, after the step stops at {b - 0.6:.2f}s"
        self.add("strip", f'<line class="rule" x1="40" y1="{y}" x2="{self.w - 40}" y2="{y}"/>', anim=True)
        step_w = (self.w - 80) / len(stages)
        for i, (a, b, label, caption) in enumerate(stages):
            x = 40 + i * step_w
            mk = f'<rect class="mk-off" x="{x:g}" y="{y + 20}" width="8" height="8"/>'
            mk += f'<rect class="mk-on" x="{x:g}" y="{y + 20}" width="8" height="8" opacity="0">{self.opacity([(a, b)], 0.15)}</rect>'
            lbl = f'{i + 1}  {label}'
            mk += f'<text class="mono muted" x="{x + 16:g}" y="{y + 28}">{esc(lbl)}</text>'
            mk += (f'<text class="mono" x="{x + 16:g}" y="{y + 28}" opacity="0">{esc(lbl)}'
                   f'{self.opacity([(a, b)], 0.15)}</text>')
            self.add("strip", mk, anim=True)
            lines = "".join(f'<text class="caption" x="40" y="{y + 62 + j * 22}">{esc(ln)}</text>'
                            for j, ln in enumerate(caption))
            self.add("strip", f'<g opacity="0">{lines}{self.opacity([(a, b)], 0.35)}</g>', anim=True)

    # --- output ------------------------------------------------------------

    def render(self, animated, standalone=True, height=None):
        h = height or self.h
        k = self.key
        head = (f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
                f'class="dg" viewBox="0 0 {self.w} {h}" width="{self.w}" height="{h}" '
                f'role="img" aria-label="{esc(self.label)}"')
        if animated:
            head += f' data-loop="{self.T}" data-stages="{esc(json.dumps(self.stages))}"'
        head += ">"
        out = [head, f"<title>{esc(self.label)}</title>"]
        if standalone:
            out.append(f"<style><![CDATA[@import url('{FONTS}');{CSS}]]></style>")
        out.append(
            "<defs>"
            f'<marker id="{k}-in" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" '
            f'orient="auto-start-reverse"><path class="ah-in" d="M0,1 L10,5 L0,9 z"/></marker>'
            f'<marker id="{k}-out" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" '
            f'orient="auto-start-reverse"><path class="ah-out" d="M0,1 L10,5 L0,9 z"/></marker>'
            "</defs>")
        out.append(f'<rect class="bg" width="{self.w}" height="{h}"/>')
        for layer in self.LAYERS:
            for svg, anim in self.layers[layer]:
                if animated or not anim:
                    out.append(svg)
        out.append("</svg>")
        return "\n".join(out)


# ==========================================================================
# 1. Solution architecture
# ==========================================================================

def architecture():
    D = Diagram("a", 1280, 810, 26, "The ICR in a country's campaign systems: campaign tools plan and "
                "collect, the ICR keeps the registry and the record, DHIS2 and the warehouse report.")
    D.text("back", 40, 44, "THE ICR IN A COUNTRY'S CAMPAIGN SYSTEMS", "mono muted")

    # stage windows
    S1, S2, S3, S4, S5 = (0.3, 5), (5, 10), (10, 16), (16, 21.5), (21.5, 26)

    # row labels
    for y, label, lines in [(116, "PLAN AND COLLECT", ["Countries keep the", "tools they use"]),
                            (412, "RECORD", ["One registry and", "system of record"]),
                            (687, "REPORT AND ANALYSE", ["National reporting", "and analysis"])]:
        D.text("back", 40, y, label, "mono")
        for i, ln in enumerate(lines):
            D.text("back", 40, y + 20 + i * 16, ln, "sub")

    # campaign tools
    tools = [("crosscut", "Crosscut", "Microplanning"),
             ("commcare", "CommCare", "Delivery, supervision"),
             ("digit", "DIGIT", "Malaria campaigns"),
             ("icf", "ICF", None),
             ("other", "Other tools", "ODK, DHIS2 Tracker"),
             ("cdash", "Dashboards", "Campaign monitoring")]
    tw, tg, tx0, ty, th = 162, 12, 210, 90, 70
    bus_y, trunk_x, icr_top = 210, 545, 330
    collectors = ("commcare", "digit", "icf", "other")
    paths = {}
    for i, (tid, name, sub) in enumerate(tools):
        x = tx0 + i * (tw + tg)
        cx = x + tw / 2
        hl = {"crosscut": [(5.1, S2[1] - 0.2)],
              "cdash": [(17.6, S4[1] - 0.2)]}.get(tid, [(10.1, S3[1] - 0.2)] if tid in collectors else [])
        D.node(x, ty, tw, th, name, sub, hl=hl)
        pts = [(cx, ty + th), (cx, bus_y), (trunk_x, bus_y), (trunk_x, icr_top)]
        if tid == "cdash":
            paths[tid] = D.wire(tid, pts, start="out")
        else:
            paths[tid] = D.wire(tid, pts, start="out", end="in")

    # what moves between the tools and the ICR
    D.chip(trunk_x - 14 - 115, 270, 230, [
        ("out", "ICR ↔ TOOLS", ["locations and catchments", "target populations",
                                "campaign plans and targets", "shared codes"],
         [(5.1, 9.8), (10.1, 12.7), (16.1, 21.3)])])
    D.chip(trunk_x + 14 + 115, 270, 230, [
        ("in", "TOOLS → ICR", ["doses and treatments given", "coverage",
                               "supervision findings", "stock"],
         [(12.8, 15.8), (16.1, 21.3)])])

    # the ICR
    ix, iy, iw, ih = 210, icr_top, 670, 200
    D.add("nodes", f'<rect class="icr" x="{ix}" y="{iy}" width="{iw}" height="{ih}" rx="4"/>')
    D.add("nodes", f'<text class="title" x="{ix + 20}" y="{iy + 34}" font-size="24">ICR</text>'
                   f'<text class="sub" x="{ix + 70}" y="{iy + 33}">Integrated Campaign Registry</text>'
                   f'<text class="mono h-in" x="{ix + iw - 20}" y="{iy + 32}" text-anchor="end">'
                   f'SYSTEM OF RECORD · HL7 FHIR R4</text>')
    cw, cy0, chh = 202, iy + 54, 130
    cells = [(["Location registry"], ["Admin areas, health facilities,", "catchments, settlements"],
              "Location · Organization", [(1.6, S1[1] - 0.2), (8.0, S2[1] - 0.2), (21.7, 25.8)]),
             (["Campaign data"], ["Campaigns, rounds, targets,", "doses given, coverage"],
              "CarePlan · Group · MeasureReport", [(1.6, S1[1] - 0.2), (13.6, S3[1] - 0.2), (21.7, 25.8)]),
             (["Terminology"], ["Shared codes, and how each", "tool's own codes map to them"],
              "CodeSystem · ValueSet · ConceptMap", [(10.1, 12.7), (21.7, 25.8)])]
    for i, (name, desc, code, hl) in enumerate(cells):
        D.cell(ix + 20 + i * (cw + 12), cy0, cw, chh, name, desc, code, hl=hl)

    # warehouse and dashboards
    D.node(990, 380, 250, 100, "Data warehouse", "Parquet files, SQL queries", "SQL-on-FHIR",
           hl=[(16.8, S4[1] - 0.2)])
    wh = D.wire("wh", [(ix + iw, 430), (990, 430)], end="out")
    D.text("wires", 935, 421, "PARQUET EXPORT", "mono muted", anchor="middle")
    D.node(990, 660, 250, 70, "Dashboards and BI", "DuckDB, Superset, Metabase, Power BI",
           hl=[(18.0, S4[1] - 0.2)])
    bi = D.wire("bi", [(1115, 480), (1115, 660)], end="out")

    # DHIS2
    D.node(210, 660, 230, 70, "DHIS2", "National HMIS", hl=[(0.4, 2.6), (12.9, S3[1] - 0.2), (17.2, S4[1] - 0.2)])
    dh = D.wire("dhis2", [(325, 660), (325, iy + ih)], start="out", end="in")
    # DHIS2 loads the registry once; after that only changes come in, with campaign data
    D.chip(458, 595, 216, [("in", "DHIS2 → ICR · FIRST LOAD", ["org units, facilities, history"],
                            [(0.5, S1[1] - 0.2)]),
                           ("in", "DHIS2 → ICR · AFTER THAT", ["changes, e.g. a new facility",
                                                               "campaign data entered in DHIS2"],
                            [(12.9, S3[1] - 0.2)])])
    D.chip(686, 595, 210, [("out", "ICR → DHIS2", ["campaign results", "as aggregate data"],
                            [(16.1, S4[1] - 0.2)])])

    D.legend(210, 772)

    # the workflow
    D.stream("dhis2", dh, 0.7, True, "in")
    D.stream("crosscut", paths["crosscut"], 5.3, False, "out")
    D.stream("crosscut", paths["crosscut"], 7.3, True, "in")
    for t in collectors:
        D.stream(t, paths[t], 10.3, False, "out")
        D.stream(t, paths[t], 13.0, True, "in")
    D.stream("dhis2", dh, 13.0, True, "in")
    D.stream("dhis2", dh, 16.4, False, "out")
    D.stream("cdash", paths["cdash"], 16.4, False, "out")
    D.stream("wh", wh, 16.4, True, "out")
    D.stream("bi", bi, 17.3, True, "out")

    D.strip(820, [
        (*S1, "LOAD", ["DHIS2 org units and historical campaign data load the ICR's location registry and campaign data."]),
        (*S2, "PLAN", ["Crosscut reads locations and target populations from the ICR to make microplans,",
                       "and sends catchment areas back to the location registry."]),
        (*S3, "DELIVER", ["Collection tools get the campaign plan, targets and shared codes from the ICR,",
                          "run the campaign with their own forms, and send results back. DHIS2 sends its campaign data and any changes, such as a new facility."]),
        (*S4, "REPORT", ["The ICR sends aggregate results to DHIS2 and exports Parquet files to the warehouse,",
                         "which dashboards and BI tools read."]),
        (*S5, "NEXT ROUND", ["The next round starts from the registry: locations, populations and past results",
                             "don't have to be collected again."]),
    ])
    return D


# ==========================================================================
# 2. One country: what goes in and out of the ICR
# ==========================================================================

def country():
    D = Diagram("c", 1280, 840, 27, "Example of one country's NTD programme: what each system sends to "
                "the ICR and what it gets back.")
    D.text("back", 40, 44, "EXAMPLE · DATA IN AND OUT OF THE ICR IN ONE COUNTRY'S NTD PROGRAMME", "mono muted")
    S1, S2, S3, S4, S5 = (0.3, 5.5), (5.5, 11), (11, 15), (15, 21.5), (21.5, 27)

    # The NTD programme's own systems
    D.add("back", '<rect class="group" x="560" y="64" width="676" height="216" rx="6"/>')
    D.text("back", 580, 90, "NTD PROGRAMME", "mono")
    D.text("back", 580, 108, "Systems of the NGO that runs it", "sub")
    D.node(980, 80, 230, 60, "Metabase", "Programme dashboards", hl=[(0.4, 2.8), (15.6, S4[1] - 0.2)])
    D.node(600, 180, 240, 60, "Crosscut", "Planning", hl=[(5.6, S2[1] - 0.2), (15.6, S4[1] - 0.2)])
    D.node(980, 180, 230, 60, "CommCare", "Collection", hl=[(15.1, S4[1] - 0.2)])
    cc_cs = D.wire("cc-cs", [(980, 210), (840, 210)], end="out")
    D.text("wires", 910, 202, "delivery data", "body", anchor="middle")
    cc_mb = D.wire("cc-mb", [(1095, 180), (1095, 140)], end="out")
    D.text("wires", 1105, 164, "reports", "body")

    # other programmes' tools
    D.node(40, 90, 230, 60, "ICF", None, hl=[(11.1, S3[1] - 0.2), (16.3, S4[1] - 0.2)])
    D.node(40, 720, 230, 60, "DIGIT", "Malaria", hl=[(11.1, S3[1] - 0.2), (16.3, S4[1] - 0.2)])
    D.node(1000, 720, 230, 60, "DHIS2", "National HMIS", hl=[(0.4, 2.8)])

    # the ICR
    ix, iy, iw, ih = 470, 450, 340, 150
    D.add("nodes", f'<rect class="icr" x="{ix}" y="{iy}" width="{iw}" height="{ih}" rx="4"/>')
    D.add("nodes", f'<text class="title" x="{ix + 16}" y="{iy + 32}" font-size="24">ICR</text>'
                   f'<text class="sub" x="{ix + 66}" y="{iy + 31}">registry and system of record</text>')
    cw = (iw - 32 - 16) / 3
    for i, (lines, hl) in enumerate([
            (["Location", "registry"], [(1.6, S1[1] - 0.2), (9.0, S2[1] - 0.2), (22, 26.8)]),
            (["Campaign", "data"], [(1.9, S1[1] - 0.2), (17.6, S4[1] - 0.2), (22, 26.8)]),
            (["Terminology"], [(22, 26.8)])]):
        D.cell(ix + 16 + i * (cw + 8), iy + 56, cw, 78, lines, hl=hl, center=True)

    # connectors, drawn from the other system towards the ICR
    icf = D.wire("icf", [(270, 135), (470, 480)], start="out", end="in")
    D.chip(370, 307, 236, [
        ("out", "ICR → ICF", ["locations · populations", "indicators · Crosscut catchments"], [(11.2, S3[1] - 0.2)]),
        ("in", "ICF → ICR", ["campaign data"], [(16.4, S4[1] - 0.2)])])
    digit = D.wire("digit", [(270, 735), (470, 585)], start="out", end="in")
    D.chip(362, 662, 216, [
        ("out", "ICR → DIGIT", ["locations · populations", "indicators"], [(11.2, S3[1] - 0.2)]),
        ("in", "DIGIT → ICR", ["campaign data"], [(16.4, S4[1] - 0.2)])])
    cs = D.wire("cs", [(720, 240), (720, iy)], start="out", end="in")
    D.chip(720, 345, 252, [
        ("out", "ICR → CROSSCUT", ["locations · populations · indicators"], [(5.6, 8.2)]),
        ("in", "CROSSCUT → ICR", ["catchment areas, added to", "the location registry",
                                  "hard-to-reach communities"], [(8.3, S2[1] - 0.2)])])
    cc = D.wire("cc", [(1120, 240), (ix + iw, 525)], end="in")
    D.chip(996, 354, 210, [("in", "COMMCARE → ICR", ["campaign data", "supervision coverage"],
                            [(16.4, S4[1] - 0.2)])])
    mb = D.wire("mb", [(1210, 110), (1252, 110), (1252, 565), (ix + iw, 565)], end="in")
    D.chip(1030, 565, 160, [("in", "METABASE → ICR", ["historical data"], [(0.6, S1[1] - 0.2)])])
    dh = D.wire("dhis2", [(1000, 750), (760, iy + ih)], end="in")
    D.chip(880, 675, 196, [("in", "DHIS2 → ICR", ["org units · routine data"], [(0.5, S1[1] - 0.2)])])

    D.legend(470, 812)

    # the workflow
    D.stream("dhis2", dh, 0.7, True, "in")
    D.stream("mb", mb, 1.0, True, "in")
    D.stream("cs", cs, 5.8, False, "out")
    D.stream("cs", cs, 8.4, True, "in")
    D.stream("icf", icf, 11.3, False, "out")
    D.stream("digit", digit, 11.3, False, "out")
    D.stream("cc-cs", cc_cs, 15.3, True, "out")
    D.stream("cc-mb", cc_mb, 15.3, True, "out")
    D.stream("cc", cc, 16.5, True, "in")
    D.stream("icf", icf, 16.5, True, "in")
    D.stream("digit", digit, 16.5, True, "in")

    D.strip(850, [
        (*S1, "EXISTING DATA", ["DHIS2 sends org units and routine data. The NTD programme's Metabase sends",
                                "data from past campaigns."]),
        (*S2, "PLAN", ["Crosscut takes locations, populations and indicators from the ICR. Its catchment areas",
                       "and hard-to-reach communities go back into the location registry."]),
        (*S3, "SHARE", ["Other programmes' tools, ICF and DIGIT for malaria, get the same locations, populations",
                        "and indicators. ICF also gets Crosscut's catchments."]),
        (*S4, "RUN CAMPAIGNS", ["CommCare sends delivery data to Crosscut and Metabase, and campaign data and",
                                   "supervision coverage to the ICR. ICF and DIGIT send their campaign data too."]),
        (*S5, "NEXT ROUND", ["The next round starts from what the ICR holds: locations, catchments, populations",
                             "and past results are already there."]),
    ])
    return D


# ==========================================================================
# Page
# ==========================================================================

PAGE = """<title>ICR solution architecture</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="__FONTS__">
<style>
/* Layout and type follow www.healthcampaigns.org: one 1120px column, light paper only. */
:root {
  --paper: #F7F8F5; --paper-2: #EEF1EB; --ink: #17211C; --ink-2: #4A554F; --ink-3: #8A948E; --rule: #D5DAD3;
  --reg: #2F6B4F; --reg-2: #DDE9E0;
  --display: "Bricolage Grotesque", ui-sans-serif, system-ui, sans-serif;
  --body: "Source Serif 4", Georgia, serif;
  --mono: "IBM Plex Mono", ui-monospace, Menlo, monospace;
  --d-paper: var(--paper); --d-surface: var(--paper-2); --d-ink: var(--ink); --d-ink2: var(--ink-2);
  --d-muted: #6F7A74; --d-faint: var(--rule); --d-hair: #C9CFC7;
  --d-accent: #F16427; --d-accent-ink: #A13A10; --d-tint: rgba(241,100,39,.13);
}
__CSS__
* { box-sizing: border-box; }
body { margin: 0; background: var(--paper); color: var(--ink); font-family: var(--body); font-size: 18px; line-height: 1.55; -webkit-font-smoothing: antialiased; }
a { color: var(--reg); }
h1, h2, h3 { font-family: var(--display); line-height: 1.05; letter-spacing: -0.01em; margin: 0; text-wrap: balance; }
h1 { font-size: clamp(28px, 3.6vw, 42px); font-weight: 700; letter-spacing: -0.025em; }
h2 { font-size: clamp(26px, 3vw, 36px); font-weight: 600; max-width: 28ch; }
h3 { font-size: 19px; font-weight: 600; }
p { margin: 0; max-width: 62ch; color: var(--ink-2); }
.wrap { width: min(1120px, calc(100% - 48px)); margin: 0 auto; }
.eyebrow { font-family: var(--mono); font-size: 12px; letter-spacing: .08em; text-transform: uppercase; color: var(--ink-3); }
.topbar { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 8px 22px; padding: 20px 0; font-family: var(--display); font-size: 15px; }
.topbar .brand { font-weight: 700; letter-spacing: -0.01em; color: var(--ink); text-decoration: none; }
.topbar .brand span { color: var(--ink-3); font-weight: 400; margin-left: 10px; }
.topbar nav { display: flex; flex-wrap: wrap; gap: 4px 22px; }
.topbar nav a { color: var(--ink-2); text-decoration: none; }
.topbar nav a:hover { color: var(--ink); }
.hero { padding-block: 40px 56px; display: grid; gap: 14px; }
.hero .kicker { font-family: var(--display); font-weight: 600; font-size: clamp(18px, 2vw, 22px); color: var(--ink-2); letter-spacing: -0.01em; }
section { padding-block: 64px; border-top: 1px solid var(--rule); display: grid; gap: 16px; }
.cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 28px; }
.card { border-top: 2px solid var(--ink); padding-top: 14px; display: grid; gap: 6px; align-content: start; }
.card.reg { border-top-color: var(--d-accent); }
.card ul { margin: 0; padding-left: 20px; color: var(--ink-2); font-size: 16.5px; display: grid; gap: 4px; }
figure { margin: 8px 0 0; display: grid; gap: 12px; }
.frame { overflow-x: auto; border: 1px solid var(--rule); border-radius: 6px; background: var(--paper); }
.frame svg { display: block; width: 100%; height: auto; min-width: 820px; }
.controls { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; }
.controls button { font-family: var(--display); font-size: 15px; font-weight: 600; background: transparent; border: 1px solid var(--rule);
  color: var(--ink-2); padding: 8px 14px; border-radius: 999px; cursor: pointer; }
.controls button:hover { border-color: var(--ink-3); color: var(--ink); }
.controls button:focus-visible { outline: 2px solid var(--d-accent); outline-offset: 2px; }
.controls button[aria-current="step"] { background: var(--ink); color: #fff; border-color: var(--ink); }
.controls .play { background: var(--d-accent); color: #fff; border-color: var(--d-accent); min-width: 84px; }
.controls .play:hover { color: #fff; border-color: var(--d-accent-ink); }
.progress { flex: 1 1 120px; height: 2px; background: var(--rule); position: relative; }
.progress i { position: absolute; inset: 0 auto 0 0; width: 0; background: var(--d-accent); }
figcaption { font-size: 15px; color: var(--ink-3); max-width: 80ch; }
.files { font-size: 15px; color: var(--ink-2); }
footer { border-top: 1px solid var(--rule); padding: 40px 0 60px; font-size: 14px; color: var(--ink-3); display: flex; justify-content: space-between; flex-wrap: wrap; gap: 12px; }
footer a { color: var(--ink-2); }
footer code { font-family: var(--mono); font-size: 13px; }
footer .support { flex-basis: 100%; font-size: 13px; margin-top: 6px; }
</style>

<div class="wrap">
__BAR__
<header class="hero">
  <div class="kicker">Integrated Campaign Registry</div>
  <h1>ICR solution architecture</h1>
</header>

<main>
  <section aria-label="What the ICR does and does not do">
    <div class="cards">
      <div class="card reg">
        <h3>The ICR holds</h3>
        <ul>
          <li>The location registry: admin areas, facilities, catchments, settlements</li>
          <li>Campaigns and rounds, targets and results</li>
          <li>Shared codes, and how each tool's codes map to them</li>
        </ul>
      </div>
      <div class="card">
        <h3>Other systems keep doing</h3>
        <ul>
          <li>Data collection in CommCare, DIGIT, ODK and DHIS2 Tracker</li>
          <li>Microplanning in Crosscut</li>
          <li>Routine reporting in DHIS2, the national HMIS</li>
        </ul>
      </div>
    </div>
  </section>

  <section>
    <div class="eyebrow">Diagram 1</div>
    <h2>Where the ICR sits between campaign tools and national reporting</h2>
    <figure data-player>
      <div class="frame">__ARCH__</div>
      <div class="controls"></div>
      <figcaption>Click a step to play it, or Play to run through them all. Orange arrowheads mark data going into the ICR.</figcaption>
    </figure>
  </section>

  <section>
    <div class="eyebrow">Diagram 2</div>
    <h2>Example: what goes in and out of the ICR in one country's NTD programme</h2>
    <p>The NGO running the NTD programme uses Crosscut for planning, CommCare for collection and Metabase for its dashboards. Other programmes in the same country use ICF and DIGIT. The ICR gives all of them the same locations and populations, and collects their results in one place.</p>
    <figure data-player>
      <div class="frame">__COUNTRY__</div>
      <div class="controls"></div>
    </figure>
    __FILES__
  </section>
</main>

<footer>__FOOTER__</footer>
</div>

<script>
// The diagrams carry SMIL timings so the SVG files animate on their own. On this page
// the script reads those timings, removes the SMIL elements and plays them itself, so
// play, pause and the step buttons behave the same in every browser.
(() => {
  const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;

  const nums = s => s.split(';').map(Number);
  function interp(times, values, p) {
    for (let i = 0; i < times.length - 1; i++) {
      if (p <= times[i + 1]) {
        const span = times[i + 1] - times[i];
        return span <= 0 ? values[i + 1] : values[i] + (values[i + 1] - values[i]) * (p - times[i]) / span;
      }
    }
    return values[values.length - 1];
  }

  function compile(svg) {
    const tracks = [];
    svg.querySelectorAll('animate, animateMotion').forEach(a => {
      const el = a.parentElement;
      const times = nums(a.getAttribute('keyTimes'));
      if (a.localName === 'animate') {
        const values = nums(a.getAttribute('values'));
        tracks.push(p => { el.style.opacity = interp(times, values, p); });
      } else {
        const points = nums(a.getAttribute('keyPoints'));
        const path = svg.querySelector(a.querySelector('mpath').getAttribute('href'));
        const len = path.getTotalLength();
        tracks.push(p => {
          const pt = path.getPointAtLength(interp(times, points, p) * len);
          el.setAttribute('transform', `translate(${pt.x} ${pt.y})`);
        });
      }
      a.remove();
    });
    return p => tracks.forEach(f => f(p));
  }

  document.querySelectorAll('[data-player]').forEach(fig => {
    const svg = fig.querySelector('svg');
    const T = +svg.dataset.loop;
    const stages = JSON.parse(svg.dataset.stages);
    const draw = compile(svg);
    const bar = fig.querySelector('.controls');

    // stopAt: when a step is played from pause, where to stop again
    let t = 0, paused = false, stopAt = null, last = performance.now();

    const play = document.createElement('button');
    play.type = 'button';
    play.className = 'play';
    bar.append(play);
    const setPaused = p => { paused = p; play.textContent = p ? 'Play' : 'Pause'; };
    play.addEventListener('click', () => { stopAt = null; setPaused(!paused); });

    // A step button plays just that step and stops on its last frame, before the step
    // fades out, so a demo can go through the steps one click at a time. Play loops.
    const playStep = i => {
      stopAt = (i + 1 < stages.length ? stages[i + 1][0] : T) - 0.6;
      t = stages[i][0] + 0.05;
      setPaused(false);
    };
    const current = () => stages.reduce((n, [at], i) => (t >= at ? i : n), 0);
    const steps = stages.map(([, label], i) => {
      const b = document.createElement('button');
      b.type = 'button';
      b.textContent = `${i + 1} ${label}`;
      b.addEventListener('click', () => playStep(i));
      bar.append(b);
      return b;
    });
    const next = document.createElement('button');
    next.type = 'button';
    next.textContent = 'Next step →';
    next.addEventListener('click', () => playStep((current() + 1) % stages.length));
    bar.append(next);
    const progress = document.createElement('div');
    progress.className = 'progress';
    progress.innerHTML = '<i></i>';
    bar.append(progress);
    const fill = progress.firstChild;

    function frame(now) {
      if (!paused) {
        t = (t + Math.min(0.1, (now - last) / 1000)) % T;
        if (stopAt !== null && t >= stopAt) { t = stopAt; stopAt = null; setPaused(true); }
      }
      last = now;
      draw(t / T);
      fill.style.width = `${(t / T) * 100}%`;
      const cur = current();
      steps.forEach((b, i) => b.setAttribute('aria-current', i === cur ? 'step' : 'false'));
      requestAnimationFrame(frame);
    }

    if (reduced) { t = stages[stages.length - 1][0] + 0.6; setPaused(true); }
    else setPaused(false);
    requestAnimationFrame(frame);
  });
})();
</script>
"""


# The healthcampaigns.org copy lives at /architecture/, next to the files it links to.
SITE = HERE.parent / "site" / "architecture"
SITE_BAR = ('<div class="topbar"><a class="brand" href="/">Integrated Campaign Registry <span>UNICEF</span></a>'
            '<nav><a href="/#why">Why campaigns</a><a href="/#what">What it is</a><a href="/#unlock">Benefits</a>'
            '<a href="/#audience">Who benefits</a><a href="/architecture/">Architecture</a>'
            '<a href="https://icr.healthcampaigns.org">Implementation guide ↗</a>'
            '</nav></div>')
SITE_FILES = ('<p class="files">For slides: diagram 1 as <a href="icr-architecture.png">PNG</a> or '
              '<a href="icr-architecture.svg">SVG</a>, diagram 2 as <a href="icr-country-flows.png">PNG</a> or '
              '<a href="icr-country-flows.svg">SVG</a>. Animated SVGs: '
              '<a href="icr-architecture-animated.svg">diagram 1</a>, '
              '<a href="icr-country-flows-animated.svg">diagram 2</a>.</p>')
SITE_FOOTER = ('<div>Integrated Campaign Registry</div>'
               '<div><a href="https://icr.healthcampaigns.org">FHIR Implementation Guide</a> · '
               '<a href="https://dashboards.healthcampaigns.org/">Dashboards</a> · '
               '<a href="/architecture/">Solution architecture</a></div>'
               '<div class="support">With support from the Gates Foundation.</div>')
REPO_FOOTER = ("<div>Static and animated SVG versions of both diagrams are in the ICR repository under "
               "<code>diagram/</code>, built by <code>diagram/build.py</code>.</div>")
CHROME = Path("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")


def png(svg, out, w, h):
    """Renders an SVG to a 2x PNG with headless Chrome, so the web fonts are drawn in."""
    subprocess.run([str(CHROME), "--headless=new", "--disable-gpu", "--hide-scrollbars",
                    "--force-device-scale-factor=2", f"--window-size={w},{h}", "--virtual-time-budget=3000",
                    f"--screenshot={out}", svg.as_uri()], check=True, capture_output=True)


def main():
    arch, ctry = architecture(), country()
    for D, name in [(arch, "icr-architecture"), (ctry, "icr-country-flows")]:
        (HERE / f"{name}.svg").write_text(D.render(False))
        (HERE / f"{name}-animated.svg").write_text(D.render(True, height=D.h + 120))
        if CHROME.exists():
            png(HERE / f"{name}.svg", HERE / f"{name}.png", D.w, D.h)
    page = (PAGE.replace("__FONTS__", FONTS).replace("__CSS__", CSS)
            .replace("__ARCH__", arch.render(True, standalone=False, height=arch.h + 120))
            .replace("__COUNTRY__", ctry.render(True, standalone=False, height=ctry.h + 120)))
    # index.html is published as a claude.ai artifact, which supplies the <head>
    (HERE / "index.html").write_text(page.replace("__BAR__\n", "").replace("__FILES__\n", "")
                                     .replace("__FOOTER__", REPO_FOOTER))

    head, body = page.split('<div class="wrap">', 1)
    body = body.replace("__BAR__", SITE_BAR).replace("__FILES__", SITE_FILES).replace("__FOOTER__", SITE_FOOTER)
    SITE.mkdir(parents=True, exist_ok=True)
    (SITE / "index.html").write_text(
        '<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n'
        '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
        + head + "</head>\n<body>\n<div class=\"wrap\">" + body + "\n</body>\n</html>\n")
    for f in HERE.glob("icr-*"):
        shutil.copy(f, SITE / f.name)
    print("wrote", ", ".join(p.name for p in sorted(HERE.glob("icr-*"))), "and index.html, and copied them to", SITE)


if __name__ == "__main__":
    main()
