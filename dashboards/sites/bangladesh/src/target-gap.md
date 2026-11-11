---
title: Do routine and the campaign plan for the same children?
sql:
  routine: data/routine.parquet
  ages: data/campaign-ages.parquet
  worldpop: data/worldpop.parquet
---

# Do routine and the campaign plan for the same number of children?

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

```js
import * as Plot from "npm:@observablehq/plot";
import * as d3 from "npm:d3";
import maplibregl from "npm:maplibre-gl@5";
import {item, pivot, fmt, rows} from "./components/dhis2.js";
import {thematic} from "./components/charts.js";
import {unitMap} from "./components/unit-map.js";

const YEAR = "2025";
const LOW = 80, HIGH = 125;
const short = (n) => (n ?? "").replace(/ (District|Upazila)$/, "");
const pct = (a, b) => a != null && b ? 100 * a / b : null;
const boundaries = await FileAttachment("data/boundaries.json").json();
const kpi = (label, v, sub = "") => html`<div style="text-align:center;padding:18px 0 10px"><div class="d2-kpi">${v == null ? "—" : typeof v === "string" ? v : fmt(v, 0)}</div>
  <div class="muted" style="font-size:12px;margin-top:6px">${label}</div>${sub ? html`<div class="muted" style="font-size:11px;margin-top:2px">${sub}</div>` : ""}</div>`;
// Red where the campaign planned for fewer children than routine, blue where it planned for more.
const RATIO_BANDS = [
  {name: "Under 60%", start: 0, end: 60, color: "#d73027"}, {name: "60–80%", start: 60, end: LOW, color: "#fc8d59"},
  {name: "About the same", start: LOW, end: HIGH, color: "#ffffbf"},
  {name: "125–150%", start: HIGH, end: 150, color: "#91bfdb"}, {name: "Over 150%", start: 150, end: 1000, color: "#4575b4"}
];
const BAND_COLORS = {lower: "#d74554", same: "#a3b1c2", higher: "#518cc3"};
const band = (v) => v < LOW ? "lower" : v > HIGH ? "higher" : "same";
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
  return {...r, name: short(r.location_name), campaign_target: a.target_1y, worldpop: wp,
    ratio: pct(a.target_1y, r.routine_target), difference: a.target_1y - r.routine_target,
    routine_wp: pct(r.routine_target, wp), campaign_wp: pct(a.target_1y, wp)};
}).filter((d) => d.ratio != null);
// National figures for the same children. WorldPop: R2025A children under 1 in Bangladesh, 2025
// (api.worldpop.org/v3/countries/BGD?include=groups).
const WORLDPOP_NATIONAL = 3413267;
const [nationalRoutine] = rows(await sql`
  SELECT location_id, max(count) AS routine_target FROM routine
  WHERE key = 'target' AND period = ${YEAR} AND target_ok AND admin_level = 0 GROUP BY location_id`);
const national = {routine_target: nationalRoutine?.routine_target, campaign_target: ages.get(nationalRoutine?.location_id)?.target_1y};
const sum = (list, f) => list.reduce((s, d) => s + (f(d) ?? 0), 0);
const medianOf = (f) => { const v = upazilas.map(f).filter((x) => x != null).sort((a, b) => a - b); return v[Math.floor(v.length / 2)]; };
const count = (test) => upazilas.filter(test).length;
// Which target is nearer to WorldPop, on a ratio scale (half and double are equally far).
const off = (v) => Math.abs(Math.log(v / 100));
const districts = Array.from(new Set(upazilas.map((d) => d.district))).filter(Boolean).sort();
const districtInput = Inputs.select(districts, {label: "Show a district", value: districts.includes("Netrakona") ? "Netrakona" : districts[0]});
const district = Generators.input(districtInput);
```

<div class="d2-item"><div class="d2-body" style="font-size:15px;line-height:1.5;max-width:900px">

Routine immunization and the MR campaign each set a target for the same children: those born from about May 2024 to May 2025. Routine counted them as its 2025 target of children aged 0–11 months. The campaign counted them a year later as its target for 1-year-olds.

If both systems used the same population figures, the two targets would match in every upazila. This page shows how far apart they are, and where. WorldPop's estimate of children under 1 in 2025 is a third figure to check both against.

</div></div>

<div class="grid grid-cols-3" style="gap: 16px; margin-top: 16px">
${item("Routine target, Bangladesh", kpi("children 0–11 months, 2025", national.routine_target))}
${item("Campaign target, Bangladesh", kpi("1-year age group, 2026 campaign", national.campaign_target, `${fmt(pct(national.campaign_target, national.routine_target), 0)}% of the routine target`))}
${item("WorldPop estimate, Bangladesh", kpi("children under 1, 2025", WORLDPOP_NATIONAL))}
</div>

<p class="muted" style="max-width:900px;margin:12px 0 0">Across the country the three figures are within about 15% of each other. The differences are much larger in individual upazilas, shown below for the ${upazilas.length} upazilas that have both targets.</p>

<div class="grid grid-cols-4" style="gap: 16px; margin-top: 16px">
${item("Targets about the same", kpi("upazilas where the two targets are within 20% of each other", count((d) => d.ratio >= LOW && d.ratio <= HIGH),
  `of ${upazilas.length} upazilas with both targets`))}
${item("Campaign target lower", kpi("upazilas where the campaign target is under 80% of the routine target", count((d) => d.ratio < LOW),
  `${fmt(sum(upazilas.filter((d) => d.ratio < LOW), (d) => -d.difference), 0)} fewer children in those upazilas`))}
${item("Campaign target higher", kpi("upazilas where the campaign target is over 125% of the routine target", count((d) => d.ratio > HIGH),
  `${fmt(sum(upazilas.filter((d) => d.ratio > HIGH), (d) => d.difference), 0)} more children in those upazilas`))}
${item("Closer to WorldPop", kpi("upazilas where the routine target is the closer of the two", count((d) => d.worldpop && off(d.routine_wp) < off(d.campaign_wp)),
  `the campaign target is closer in ${count((d) => d.worldpop && off(d.campaign_wp) < off(d.routine_wp))}`))}
</div>

```js
// Just inside the top of the axis, so values beyond it land in the last bar and not outside it.
const clampX = (v) => Math.max(20, Math.min(v, 200 - 1e-6));
const MARGIN = {top: 20, right: 20, bottom: 40, left: 50};
// A histogram of one ratio that is also a filter: drag to pick a range. Its value is
// [low, high] or null (everything).
function brushHistogram(field, label) {
  const W = Math.max(320, width - 48), H = 320;
  const svg = Plot.plot({
    width: W, height: H, marginTop: MARGIN.top, marginRight: MARGIN.right, marginBottom: MARGIN.bottom, marginLeft: MARGIN.left,
    x: {label, domain: [20, 200]},
    y: {label: "Number of upazilas", grid: true},
    color: {domain: Object.keys(BAND_COLORS), range: Object.values(BAND_COLORS)},
    marks: [
      Plot.rectY(upazilas.filter((d) => d[field] != null), Plot.binX({y: "count"}, {x: (d) => clampX(d[field]), fill: (d) => band(d[field]),
        thresholds: Array.from({length: 37}, (_, i) => 20 + i * 5), insetLeft: 0.5, insetRight: 0.5})),
      Plot.ruleX([100], {stroke: "#334155"}),
      Plot.ruleX([LOW, HIGH], {stroke: "#334155", strokeDasharray: "4,3"}),
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
}
const routineHistogram = brushHistogram("ratio", "Campaign target as % of the routine target →");
const routineRange = Generators.input(routineHistogram);
const worldpopHistogram = brushHistogram("campaign_wp", "Campaign target as % of WorldPop children under 1 →");
const worldpopRange = Generators.input(worldpopHistogram);
const bandKey = () => html`<div style="display:flex;flex-wrap:wrap;gap:12px;font:11px system-ui;color:#475569;margin-top:6px">
  ${[["lower", "campaign target lower (under 80%)"], ["same", "about the same (80–125%)"], ["higher", "campaign target higher (over 125%)"]].map(([k, t]) =>
    html`<span><span style="display:inline-block;width:11px;height:11px;background:${BAND_COLORS[k]};margin-right:4px;vertical-align:-1px"></span>${t}</span>`)}</div>`;
const HOW = "Each bar counts the upazilas in a 5-point band; 100% means the two figures are equal. Drag across the chart to pick a range, drag the selection to move it or its handles to resize it, and click outside it to clear. Values under 20% or over 200% are drawn at the ends.";
```

```js
// The map is in its own cell so that resizing the window (which redraws the histogram) does not
// make new ones; when this cell is replaced, the old maps are removed.
// A map whose upazilas open a pinned box with their name and figures when clicked.
const byId = new Map(upazilas.map((d) => [d.location_id, d]));
function clickableMap() {
  const map = unitMap({geojson: boundaries, height: 520});
  // closeOnClick is off because it would also close the box on the click that opens the next one.
  const pinned = new maplibregl.Popup({closeButton: true, closeOnClick: false, maxWidth: "340px", offset: 8});
  map.map.on("click", (event) => { if (!map.map.queryRenderedFeatures(event.point, {layers: ["unit-fill"]}).length) pinned.remove(); });
  map.map.on("click", "unit-fill", (event) => {
    const d = byId.get(event.features?.[0]?.id);
    if (!d) return;
    const line = (label, value) => `<tr><td style="padding:1px 12px 1px 0;color:#475569">${label}</td><td style="text-align:right;font-variant-numeric:tabular-nums">${value}</td></tr>`;
    const share = (v) => v == null ? "—" : `${fmt(v, 0)}%`;
    pinned.setLngLat(event.lngLat).setHTML(`<div style="font:12px system-ui;line-height:1.4">
      <div style="font-weight:600;font-size:13px;margin-bottom:4px">${d.name}, ${d.district}</div>
      <table style="border-collapse:collapse;margin:0">
        ${line("Routine target (0–11 months, 2025)", fmt(d.routine_target, 0))}
        ${line("Campaign target (1 year)", fmt(d.campaign_target, 0))}
        ${line("WorldPop under 1 (2025)", d.worldpop == null ? "—" : fmt(d.worldpop, 0))}
        ${line("Campaign ÷ routine target", `<b>${share(d.ratio)}</b>`)}
        ${line("Campaign target ÷ WorldPop", `<b>${share(d.campaign_wp)}</b>`)}
        ${line("Routine target ÷ WorldPop", share(d.routine_wp))}
        ${line("Difference (campaign − routine)", `${d.difference > 0 ? "+" : ""}${fmt(d.difference, 0)}`)}
      </table></div>`).addTo(map.map);
  });
  return map;
}
const routineMap = clickableMap();
const worldpopMap = clickableMap();
invalidation.then(() => { routineMap.map.remove(); worldpopMap.map.remove(); });
```

```js
// The ends of a chart hold everything beyond them, so a range touching an end is open on that side.
const within = (range, v) => !range || (v != null && (range[0] <= 20 || v >= range[0]) && (range[1] >= 200 || v <= range[1]));
const byRoutine = upazilas.filter((d) => within(routineRange, d.ratio));
const byWorldpop = upazilas.filter((d) => d.campaign_wp != null && within(worldpopRange, d.campaign_wp));
// The tables list the upazilas inside every range that is set.
const selected = byRoutine.filter((d) => within(worldpopRange, d.campaign_wp));
const range = routineRange || worldpopRange;
thematic(routineMap, byRoutine.map((d) => ({location_id: d.location_id, value: +d.ratio.toFixed(0)})),
  {level: 3, legend: RATIO_BANDS, label: "Campaign target ÷ routine target (%)"});
thematic(worldpopMap, byWorldpop.map((d) => ({location_id: d.location_id, value: +d.campaign_wp.toFixed(0)})),
  {level: 3, legend: RATIO_BANDS, label: "Campaign target ÷ WorldPop under 1 (%)"});
const totals = (list) => `routine target ${fmt(sum(list, (d) => d.routine_target), 0)}, campaign target ${fmt(sum(list, (d) => d.campaign_target), 0)}, WorldPop ${fmt(sum(list, (d) => d.worldpop), 0)}`;
const MAP_NOTE = "Red and orange: the campaign target is lower. Pale yellow: about the same. Blue: the campaign target is higher. Grey: outside the selected range, or no figure. Click an upazila for its figures.";
```

## The campaign target against the routine target

<div style="margin-top: 16px">
${item("Campaign target as a share of the routine target, by upazila", html`${routineHistogram}${bandKey()}`, {note: HOW})}
</div>

<div class="d2-filter" style="margin-top:16px"><span>${routineRange ? html`<b>${byRoutine.length} of ${upazilas.length} upazilas</b> have a campaign target that is ${routineRange[0]}% to ${routineRange[1]}% of the routine target.` : html`<b>Showing all ${upazilas.length} upazilas.</b> Drag across the chart above to filter this map.`}</span>
<span class="muted">In these upazilas: ${totals(byRoutine)}.</span></div>

<div style="margin-top: 16px">
${item("Campaign target ÷ routine target", routineMap, {note: MAP_NOTE})}
</div>

## The campaign target against WorldPop

<div style="margin-top: 16px">
${item("Campaign target as a share of WorldPop children under 1, by upazila", html`${worldpopHistogram}${bandKey()}`, {note: HOW})}
</div>

<div class="d2-filter" style="margin-top:16px"><span>${worldpopRange ? html`<b>${byWorldpop.length} of ${upazilas.length} upazilas</b> have a campaign target that is ${worldpopRange[0]}% to ${worldpopRange[1]}% of WorldPop.` : html`<b>Showing all ${upazilas.length} upazilas.</b> Drag across the chart above to filter this map.`}</span>
<span class="muted">In these upazilas: ${totals(byWorldpop)}.</span></div>

<div style="margin-top: 16px">
${item("Campaign target ÷ WorldPop children under 1", worldpopMap, {note: MAP_NOTE})}
</div>

## The upazilas

```js
const table = (list) => pivot(list.flatMap((d) => [
    ["Routine", d.routine_target], ["Campaign", d.campaign_target], ["Campaign ÷ routine (%)", d.ratio],
    ["WorldPop", d.worldpop], ["Campaign ÷ WorldPop (%)", d.campaign_wp], ["Routine ÷ WorldPop (%)", d.routine_wp]
  ].map(([col, value]) => ({row: d.name, col, value}))), {row: (d) => d.row, col: (d) => d.col, rowLabel: "Upazila", digits: 0});
const inDistrict = selected.filter((d) => d.district === district).sort((a, b) => a.name.localeCompare(b.name));
// With a range selected the table lists every upazila in it; without one, the 25 furthest apart.
const ranked = selected.slice().sort((a, b) => off(b.ratio) - off(a.ratio));
const listed = (range ? ranked : ranked.slice(0, 25)).map((d) => ({...d, name: `${d.name}, ${d.district}`}));
```

<div style="margin-top: 16px">
${item(range ? `All ${listed.length} upazilas in the ${routineRange && worldpopRange ? "two selected ranges" : "selected range"}, targets furthest apart first` : `The ${listed.length} upazilas where the two targets are furthest apart`, listed.length ? table(listed) : html`<span class="muted">No upazilas are in both selected ranges.</span>`,
  {note: "With a range selected on one chart, the tables list the upazilas in it; with ranges on both charts, the upazilas in both. Routine and Campaign are the two targets; WorldPop is its estimate of children under 1. A WorldPop share near 100% means that target is close to WorldPop's estimate."})}
</div>

<div class="d2-filter" style="margin-top:16px">${districtInput}</div>

<div style="margin-top: 16px">
${item(`${district}: the two targets by upazila`, inDistrict.length ? table(inDistrict) : html`<span class="muted">No upazilas in ${district} are in the selection.</span>`)}
</div>

<div class="d2-footer muted">

**How to read this.** The two targets cover nearly the same children, a year apart, so small differences are expected: some infants die or move, and the two age groups do not line up to the month. A large difference means the two systems are working from different population figures for that upazila. WorldPop is a model built from census data and satellite imagery, not a count, so it can suggest which target is nearer the truth but cannot settle it. Sadar upazilas that share a city corporation can look low on the campaign side because the campaign reports the city separately.

**Sources.** Routine: EPI e-Tracker 2025 target of children aged 0–11 months, from the DGHS GIS dashboard. Campaign: EPI campaign DHIS2 target for the 1-year age group at community sessions, 2026 MR campaign. WorldPop Global2 R2025A v1, children under 1 (CC BY 4.0, DOI 10.5258/SOTON/WP00841). Upazilas without a plausible routine target for 2025, and Chattogram, Rajbari and Shariatpur districts (no routine figures), are left out.

</div>
