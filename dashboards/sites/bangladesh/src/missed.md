---
title: Where the campaign may have missed children
sql:
  routine: data/routine.parquet
  ages: data/campaign-ages.parquet
  worldpop: data/worldpop.parquet
---

# Where the MR campaign may have missed children

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

```js
import * as Plot from "npm:@observablehq/plot";
import * as d3 from "npm:d3";
import maplibregl from "npm:maplibre-gl@5";
import {item, pivot, fmt, rows} from "./components/dhis2.js";
import {thematic} from "./components/charts.js";
import {unitMap} from "./components/unit-map.js";

const YEAR = "2025";
const short = (n) => (n ?? "").replace(/ (District|Upazila)$/, "");
const pct = (a, b) => a != null && b ? 100 * a / b : null;
const boundaries = await FileAttachment("data/boundaries.json").json();
const kpi = (label, v, sub = "") => html`<div style="text-align:center;padding:18px 0 10px"><div class="d2-kpi">${v == null ? "—" : typeof v === "string" ? v : fmt(v, 0)}</div>
  <div class="muted" style="font-size:12px;margin-top:6px">${label}</div>${sub ? html`<div class="muted" style="font-size:11px;margin-top:2px">${sub}</div>` : ""}</div>`;
const w = (n) => Math.max(320, (width - 24) / n - 24);
// Red to blue (ColorBrewer RdYlBu): red where the campaign vaccinated far fewer children than
// routine planned for, blue where it vaccinated as many or more.
const COVERAGE_BANDS = [
  {name: "Under 60%", start: 0, end: 60, color: "#d73027"}, {name: "60–80%", start: 60, end: 80, color: "#fc8d59"},
  {name: "80–95%", start: 80, end: 95, color: "#fee090"}, {name: "95–110%", start: 95, end: 110, color: "#91bfdb"},
  {name: "110% or more", start: 110, end: 1000, color: "#4575b4"}
];
```

```js
const routine = rows(await sql`
  SELECT location_id, any_value(location_name) AS location_name, any_value(district) AS district, max(count) AS routine_target
  FROM routine
  WHERE key = 'target' AND period = ${YEAR} AND target_ok AND admin_level = 3
  GROUP BY location_id HAVING routine_target IS NOT NULL`);
const ages = new Map(rows(await sql`SELECT * FROM ages`).map((d) => [d.location_id, d]));
const worldpop = new Map(rows(await sql`SELECT * FROM worldpop`).map((d) => [d.location_id, d[`wp_under1_${YEAR}`]]));
const upazilas = routine.map((r) => {
  const a = ages.get(r.location_id) ?? {};
  const wp = worldpop.get(r.location_id);
  // "Agreed" figures count children only up to the lower of the routine target and WorldPop.
  const agreed = wp ? Math.min(r.routine_target, wp) : null;
  return {...r, name: short(r.location_name), campaign_target: a.target_1y, vaccinated: a.vaccinated_1y, worldpop: wp,
    own_coverage: pct(a.vaccinated_1y, a.target_1y), routine_coverage: pct(a.vaccinated_1y, r.routine_target),
    worldpop_coverage: pct(a.vaccinated_1y, wp),
    short_own: Math.max(0, a.target_1y - a.vaccinated_1y), short_routine: Math.max(0, r.routine_target - a.vaccinated_1y),
    short_agreed: agreed == null ? null : Math.max(0, agreed - a.vaccinated_1y)};
}).filter((d) => d.own_coverage != null && d.routine_coverage != null);
const sum = (f) => upazilas.reduce((s, d) => s + (f(d) ?? 0), 0);
const medianOf = (f) => { const v = upazilas.map(f).filter((x) => x != null).sort((a, b) => a - b); return v[Math.floor(v.length / 2)]; };
const districts = Array.from(new Set(upazilas.map((d) => d.district))).filter(Boolean).sort();
const districtInput = Inputs.select(districts, {label: "Show a district", value: districts.includes("Netrakona") ? "Netrakona" : districts[0]});
const district = Generators.input(districtInput);
```

<div class="d2-item"><div class="d2-body" style="font-size:15px;line-height:1.5;max-width:900px">

The campaign reports close to 100% of its own target almost everywhere. Its target is close to the number of children its teams found, so that figure cannot show children who were never found.

Routine immunization planned for the same children a year earlier, as infants in 2025. Measuring the campaign against that routine target shows where it may have missed children. The figures are for the campaign's 1-year age group, the children routine planned for in 2025.

</div></div>

<div class="grid grid-cols-4" style="gap: 16px; margin-top: 16px">
${item("Coverage the campaign reports", kpi("median upazila, vaccinated ÷ the campaign's own target", `${fmt(medianOf((d) => d.own_coverage), 0)}%`,
  `${upazilas.filter((d) => d.own_coverage >= 95).length} of ${upazilas.length} upazilas report 95% or more`))}
${item("Coverage against the routine target", kpi("median upazila, the same children ÷ routine target", `${fmt(medianOf((d) => d.routine_coverage), 0)}%`,
  `${upazilas.filter((d) => d.routine_coverage >= 95).length} of ${upazilas.length} upazilas reach 95% or more`))}
${item("Children short of the routine target", kpi("1-year-olds, where the campaign vaccinated fewer than routine planned for", sum((d) => d.short_routine),
  `the campaign's own figures show ${fmt(sum((d) => d.short_own), 0)}`))}
${item("Short of both routine and WorldPop", kpi("1-year-olds, counted only where WorldPop also says more children live there", sum((d) => d.short_agreed),
  "the more cautious estimate"))}
</div>

```js
const clampX = (v) => Math.max(20, Math.min(v, 160));
const THRESHOLDS = Array.from({length: 57}, (_, i) => 20 + i * 2.5);
const SERIES = [
  {name: "As the campaign reports it: vaccinated ÷ the campaign's own target", field: "own_coverage", color: "#518cc3"},
  {name: "The same children against the routine target: vaccinated ÷ routine target", field: "routine_coverage", color: "#d74554"}
];
const MARGIN = {top: 20, right: 20, bottom: 40, left: 50};
// Two histograms of the same upazilas, one above the other on the same axes, with one selection
// across both: drag to pick a range of coverage. The value is [low, high] or null (everything).
const coverageHistogram = (() => {
  const W = Math.max(320, width - 48), H = 480;
  const stacked = SERIES.flatMap(({name, field}) => upazilas.map((d) => ({series: name, value: clampX(d[field])})));
  const svg = Plot.plot({
    width: W, height: H, marginTop: MARGIN.top, marginRight: MARGIN.right, marginBottom: MARGIN.bottom, marginLeft: MARGIN.left,
    x: {label: "1-year-olds vaccinated, as % of the target →", domain: [20, 160]},
    y: {label: "Number of upazilas", grid: true},
    fy: {domain: SERIES.map((s) => s.name), axis: null, padding: 0.12},
    color: {domain: SERIES.map((s) => s.name), range: SERIES.map((s) => s.color)},
    marks: [
      Plot.rectY(stacked, Plot.binX({y: "count"}, {x: "value", fy: "series", fill: "series", fillOpacity: 0.75, thresholds: THRESHOLDS, insetLeft: 0.5, insetRight: 0.5})),
      Plot.text(SERIES, {fy: "name", text: "name", frameAnchor: "top-left", dx: 8, dy: 4, fontSize: 12, fontWeight: 600, fill: "#334155"}),
      Plot.ruleX([100], {stroke: "#334155"}),
      Plot.ruleY([0])
    ]
  });
  const x = svg.scale("x");
  const bars = d3.select(svg).selectAll('g[aria-label="rect"] rect');
  const GRIP = {width: 8, height: 44};
  svg.value = null;
  // Bars in the selected range get a thin outline, the rest are faded; grips mark the two edges.
  function show(selection) {
    bars.each(function () {
      const mid = +this.getAttribute("x") + +this.getAttribute("width") / 2;
      const inside = !selection || (mid >= selection[0] && mid <= selection[1]);
      d3.select(this).attr("opacity", inside ? 1 : 0.3).attr("stroke", selection && inside ? "#334155" : null).attr("stroke-width", selection && inside ? 0.75 : null);
    });
    grip.attr("display", selection ? null : "none");
    if (selection) grip.attr("x", (i) => selection[i] - GRIP.width / 2);
  }
  const brush = d3.brushX().extent([[MARGIN.left, MARGIN.top], [W - MARGIN.right, H - MARGIN.bottom]])
    .on("brush", (event) => show(event.selection))
    .on("end", (event) => {
      show(event.selection);
      svg.value = event.selection ? event.selection.map((px) => Math.round(x.invert(px))) : null;
      svg.dispatchEvent(new Event("input", {bubbles: true}));
    });
  const g = d3.select(svg).append("g").attr("class", "brush").call(brush);
  g.select(".selection").attr("fill", "#334155").attr("fill-opacity", 0.06).attr("stroke", "#334155").attr("stroke-opacity", 0.5).attr("stroke-dasharray", "3,2");
  const grip = g.selectAll(".grip").data([0, 1]).join("rect").attr("class", "grip")
    .attr("width", GRIP.width).attr("height", GRIP.height).attr("rx", 4)
    .attr("y", (MARGIN.top + H - MARGIN.bottom - GRIP.height) / 2)
    .attr("fill", "white").attr("stroke", "#334155").attr("stroke-width", 1.2)
    .attr("pointer-events", "none").attr("display", "none");
  return svg;
})();
const range = Generators.input(coverageHistogram);
const map = unitMap({geojson: boundaries, height: 560});
// Click an upazila for a pinned box with its name and figures (hovering shows the coverage only).
const byId = new Map(upazilas.map((d) => [d.location_id, d]));
// closeOnClick is off because it would also close the box on the click that opens the next one.
const pinned = new maplibregl.Popup({closeButton: true, closeOnClick: false, maxWidth: "340px", offset: 8});
map.map.on("click", (event) => { if (!map.map.queryRenderedFeatures(event.point, {layers: ["unit-fill"]}).length) pinned.remove(); });
map.map.on("click", "unit-fill", (event) => {
  const d = byId.get(event.features?.[0]?.id);
  if (!d) return;
  const line = (label, value) => `<tr><td style="padding:1px 12px 1px 0;color:#475569">${label}</td><td style="text-align:right;font-variant-numeric:tabular-nums">${value}</td></tr>`;
  pinned.setLngLat(event.lngLat).setHTML(`<div style="font:12px system-ui;line-height:1.4">
    <div style="font-weight:600;font-size:13px;margin-bottom:4px">${d.name}, ${d.district}</div>
    <table style="border-collapse:collapse;margin:0">
      ${line("Campaign vaccinated (1 year)", fmt(d.vaccinated, 0))}
      ${line("Campaign target (1 year)", fmt(d.campaign_target, 0))}
      ${line("Coverage the campaign reports", `${fmt(d.own_coverage, 0)}%`)}
      ${line("Routine target (0–11 months, 2025)", fmt(d.routine_target, 0))}
      ${line("Coverage against the routine target", `<b>${fmt(d.routine_coverage, 0)}%</b>`)}
      ${line("WorldPop under 1 (2025)", d.worldpop == null ? "—" : fmt(d.worldpop, 0))}
      ${line("Coverage against WorldPop", d.worldpop_coverage == null ? "—" : `${fmt(d.worldpop_coverage, 0)}%`)}
      ${line("Children short of the routine target", fmt(d.short_routine, 0))}
      ${line("Short where WorldPop agrees", d.short_agreed == null ? "—" : fmt(d.short_agreed, 0))}
    </table></div>`).addTo(map.map);
});
```

```js
// The ends of the chart hold everything beyond them, so a range touching an end is open on that side.
const within = (v) => !range || ((range[0] <= 20 || v >= range[0]) && (range[1] >= 160 || v <= range[1]));
const selected = upazilas.filter((d) => within(d.routine_coverage));
const ownInRange = upazilas.filter((d) => within(d.own_coverage));
thematic(map, selected.map((d) => ({location_id: d.location_id, value: +d.routine_coverage.toFixed(0)})),
  {level: 3, legend: COVERAGE_BANDS, label: "Campaign vaccinated ÷ routine target (%)"});
const sumSelected = (f) => selected.reduce((s, d) => s + (f(d) ?? 0), 0);
```

<div style="margin-top: 16px">
${item("Campaign coverage of 1-year-olds in each upazila, measured against two targets", coverageHistogram,
  {note: `Both charts count the same ${upazilas.length} upazilas. Drag across the chart to pick a range of coverage; it applies to both. Drag the selection to move it, or its handles to widen or narrow it; click outside it to clear. Values under 20% or over 160% are drawn at the ends.`})}
</div>

<div class="d2-filter" style="margin-top:16px"><span>${range ? html`<b>Coverage from ${range[0]}% to ${range[1]}%:</b> ${ownInRange.length} upazilas as the campaign reports it, <b>${selected.length} upazilas against the routine target</b>. The map and tables show those ${selected.length}.` : html`<b>Showing all ${upazilas.length} upazilas.</b> Drag across the chart above to filter.`}</span>
<span class="muted">Children short of the routine target: ${fmt(sumSelected((d) => d.short_routine), 0)}. Where WorldPop agrees: ${fmt(sumSelected((d) => d.short_agreed), 0)}.</span></div>

<div style="margin-top: 16px">
${item("Campaign coverage of 1-year-olds against the routine target", map,
  {note: "Red: the campaign vaccinated far fewer 1-year-olds than routine planned for. Yellow: 80–95%. Blue: about as many or more. Grey: outside the selected range, or no figure. Click an upazila for its figures."})}
</div>

```js
const table = (list, label = "Upazila") => pivot(list.flatMap((d) => [
    ["Campaign vaccinated", d.vaccinated], ["Coverage reported (%)", d.own_coverage], ["Routine target", d.routine_target],
    ["Coverage, routine target (%)", d.routine_coverage], ["WorldPop under 1", d.worldpop], ["Children short", d.short_agreed]
  ].map(([col, value]) => ({row: d.name, col, value}))), {row: (d) => d.row, col: (d) => d.col, rowLabel: label, digits: 0});
const inDistrict = selected.filter((d) => d.district === district).sort((a, b) => a.name.localeCompare(b.name));
// With a range selected the table lists every upazila in it; without one, the 25 with the most children short.
const ranked = selected.slice().sort((a, b) => (b.short_agreed ?? 0) - (a.short_agreed ?? 0) || a.routine_coverage - b.routine_coverage);
const largest = (range ? ranked : ranked.filter((d) => d.short_agreed > 0).slice(0, 25)).map((d) => ({...d, name: `${d.name}, ${d.district}`}));
```

<div style="margin-top: 16px">
${item(range ? `All ${largest.length} upazilas with coverage against the routine target from ${range[0]}% to ${range[1]}%, most children short first` : `The ${largest.length} upazilas with the most children short, where routine and WorldPop agree`, table(largest),
  {note: "The last column counts children up to the lower of the routine target and WorldPop, so an inflated routine target alone does not put an upazila here."})}
</div>

<div class="d2-filter" style="margin-top:16px">${districtInput}</div>

<div style="margin-top: 16px">
${item(`${district}: campaign coverage of 1-year-olds against each target`, inDistrict.length ? table(inDistrict) : html`<span class="muted">No upazilas in ${district} are in the selected range.</span>`)}
</div>

<div class="d2-footer muted">

**How to read this.** A shortfall means either children the campaign did not reach or a target that is too high. Where the routine target and WorldPop both say more children live in an upazila than the campaign vaccinated, missed children are the more likely reading; a household survey would confirm it. The figures cover 1-year-olds only, in the ${upazilas.length} upazilas with figures from both systems, so they are not a national total. Sadar upazilas that share a city corporation can look low because the campaign reports the city separately.

**Sources.** Routine: EPI e-Tracker 2025 targets, from the DGHS GIS dashboard. Campaign: EPI campaign DHIS2, 1-year age group at community sessions, 2026-04-05 to 2026-05-20. WorldPop Global2 R2025A v1, children under 1 (CC BY 4.0, DOI 10.5258/SOTON/WP00841).

</div>
