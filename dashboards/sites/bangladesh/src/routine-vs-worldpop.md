---
title: How do routine targets compare with WorldPop?
sql:
  routine: data/routine.parquet
  worldpop: data/worldpop.parquet
---

# How do routine targets compare with WorldPop?

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

```js
import * as Plot from "npm:@observablehq/plot";
import * as d3 from "npm:d3";
import maplibregl from "npm:maplibre-gl@5";
import {item, pivot, fmt, rows} from "./components/dhis2.js";
import {thematic} from "./components/charts.js";
import {unitMap} from "./components/unit-map.js";

const YEARS = ["2024", "2025", "2026"];
const LOW = 80, HIGH = 125;
const short = (n) => (n ?? "").replace(/ (District|Upazila)$/, "");
const pct = (a, b) => a != null && b ? 100 * a / b : null;
const boundaries = await FileAttachment("data/boundaries.json").json();
const kpi = (label, v, sub = "") => html`<div style="text-align:center;padding:18px 0 10px"><div class="d2-kpi">${v == null ? "—" : typeof v === "string" ? v : fmt(v, 0)}</div>
  <div class="muted" style="font-size:12px;margin-top:6px">${label}</div>${sub ? html`<div class="muted" style="font-size:11px;margin-top:2px">${sub}</div>` : ""}</div>`;
// Red where the routine target is below WorldPop's estimate, blue where it is above.
const RATIO_BANDS = [
  {name: "Under 60%", start: 0, end: 60, color: "#d73027"}, {name: "60–80%", start: 60, end: LOW, color: "#fc8d59"},
  {name: "About the same", start: LOW, end: HIGH, color: "#ffffbf"},
  {name: "125–150%", start: HIGH, end: 150, color: "#91bfdb"}, {name: "Over 150%", start: 150, end: 1000, color: "#4575b4"}
];
const band = (v) => (RATIO_BANDS.find((b) => v < b.end) ?? RATIO_BANDS.at(-1)).name;
// The pale middle band needs an outline to show against the page.
const BAR_STROKE = "#94a3b8";
const sum = (list, f) => list.reduce((s, d) => s + (f(d) ?? 0), 0);
// Distance from 100% on a ratio scale (half and double are equally far).
const off = (v) => Math.abs(Math.log(v / 100));
```

```js
// Every routine target with a WorldPop figure for the same place and year: districts and city
// corporations (admin level 2) and upazilas (3).
const worldpop = new Map(rows(await sql`SELECT * FROM worldpop`).map((d) => [d.location_id, d]));
const all = rows(await sql`
  SELECT location_id, admin_level, period AS year, any_value(location_name) AS location_name,
         any_value(district) AS district, max(count) AS routine_target
  FROM routine
  WHERE key = 'target' AND period_type = 'Yearly' AND target_ok AND admin_level IN (2, 3)
  GROUP BY location_id, admin_level, period HAVING max(count) IS NOT NULL`)
  .map((r) => {
    const wp = worldpop.get(r.location_id)?.[`wp_under1_${r.year}`];
    return {...r, name: short(r.location_name), worldpop: wp, ratio: pct(r.routine_target, wp), difference: r.routine_target - wp};
  }).filter((d) => d.ratio != null && YEARS.includes(d.year));

const yearInput = Inputs.select(YEARS, {label: "Year", value: "2025"});
const year = Generators.input(yearInput);
const levelInput = Inputs.radio(new Map([["Upazilas", 3], ["Districts and city corporations", 2]]), {label: "Compare", value: 3});
const level = Generators.input(levelInput);
```

```js
const places = all.filter((d) => d.year === year && d.admin_level === level);
const unit = level === 3 ? "upazila" : "district";
const units = level === 3 ? "upazilas" : "districts and city corporations";
const count = (test) => places.filter(test).length;
const total = {routine: sum(places, (d) => d.routine_target), worldpop: sum(places, (d) => d.worldpop)};
const lower = places.filter((d) => d.ratio < LOW), higher = places.filter((d) => d.ratio > HIGH);
const districts = Array.from(new Set(places.map((d) => d.district))).filter(Boolean).sort();
const districtInput = Inputs.select(districts, {label: "Show a district", value: districts.includes("Netrakona") ? "Netrakona" : districts[0]});
const district = Generators.input(districtInput);
```

<div class="d2-item"><div class="d2-body" style="font-size:15px;line-height:1.5;max-width:900px">

Each year routine immunization sets a target for every place: the number of children aged 0–11 months it expects to vaccinate. WorldPop publishes its own estimate of children under 1 for the same places, modelled from census data and satellite imagery.

The two figures describe the same children. This page shows, place by place, how far the routine target is from the WorldPop estimate. A routine target well below WorldPop can make coverage look higher than it is; one well above can make it look lower.

</div></div>

<div class="d2-filter" style="margin-top:16px">${yearInput}${levelInput}</div>

<div class="grid grid-cols-3" style="gap: 16px">
${item(`Routine target, ${year}`, kpi(`children 0–11 months, in the ${places.length} ${units} compared`, total.routine))}
${item(`WorldPop estimate, ${year}`, kpi("children under 1, in the same places", total.worldpop))}
${item("Routine target as a share of WorldPop", kpi("all compared places together", `${fmt(pct(total.routine, total.worldpop), 0)}%`))}
</div>

<p class="muted" style="max-width:900px;margin:12px 0 0">Added up, the two figures are close. Place by place they are often far apart.</p>

<div class="grid grid-cols-3" style="gap: 16px; margin-top: 16px">
${item("About the same", kpi(`${units} where the routine target is 80% to 125% of WorldPop`, count((d) => d.ratio >= LOW && d.ratio <= HIGH), `of ${places.length} compared`))}
${item("Routine target lower", kpi(`${units} where the routine target is under 80% of WorldPop`, lower.length,
  `${fmt(sum(lower, (d) => -d.difference), 0)} fewer children than WorldPop in those places`))}
${item("Routine target higher", kpi(`${units} where the routine target is over 125% of WorldPop`, higher.length,
  `${fmt(sum(higher, (d) => d.difference), 0)} more children than WorldPop in those places`))}
</div>

```js
function scatter() {
  const lo = Math.max(10, d3.min(places, (d) => Math.min(d.routine_target, d.worldpop)) * 0.8);
  const hi = d3.max(places, (d) => Math.max(d.routine_target, d.worldpop)) * 1.2;
  const line = (k) => [{x: lo, y: lo * k}, {x: hi, y: hi * k}];
  return Plot.plot({
    width: Math.max(320, width - 48), height: 460, marginLeft: 70, marginBottom: 44,
    x: {type: "log", label: "WorldPop children under 1 →", domain: [lo, hi], tickFormat: "~s", grid: true},
    y: {type: "log", label: "↑ Routine target, children 0–11 months", domain: [lo, hi], tickFormat: "~s", grid: true},
    color: {domain: RATIO_BANDS.map((b) => b.name), range: RATIO_BANDS.map((b) => b.color)},
    marks: [
      Plot.line(line(1), {x: "x", y: "y", stroke: "#0f172a", strokeWidth: 2, clip: true}),
      Plot.line(line(LOW / 100), {x: "x", y: "y", stroke: "#334155", strokeDasharray: "4,3", clip: true}),
      Plot.line(line(HIGH / 100), {x: "x", y: "y", stroke: "#334155", strokeDasharray: "4,3", clip: true}),
      Plot.dot(places, {x: "worldpop", y: "routine_target", fill: (d) => band(d.ratio), stroke: BAR_STROKE, strokeWidth: 0.5, r: 4,
        channels: {Place: (d) => level === 3 ? `${d.name}, ${d.district}` : d.name, "Routine ÷ WorldPop": (d) => `${fmt(d.ratio, 0)}%`},
        tip: {format: {fill: false, x: (v) => fmt(v, 0), y: (v) => fmt(v, 0)}}})
    ]
  });
}
```

<div style="margin-top: 16px">
${item(`Routine target against WorldPop, one dot per ${unit}, ${year}`, html`${scatter()}${bandKey()}`,
  {note: "Dots on the solid line have a routine target equal to WorldPop. Dots between the dashed lines are within 80% to 125%. Dots below the lines have a lower routine target; dots above have a higher one. Both axes are logarithmic."})}
</div>

```js
// Just inside the top of the axis, so values beyond it land in the last bar and not outside it.
const clampX = (v) => Math.max(20, Math.min(v, 200 - 1e-6));
const MARGIN = {top: 20, right: 20, bottom: 40, left: 50};
// A histogram of the ratio that is also a filter: drag to pick a range. Its value is
// [low, high] or null (everything).
function brushHistogram() {
  const W = Math.max(320, width - 48), H = 320;
  const svg = Plot.plot({
    width: W, height: H, marginTop: MARGIN.top, marginRight: MARGIN.right, marginBottom: MARGIN.bottom, marginLeft: MARGIN.left,
    x: {label: "Routine target as % of WorldPop children under 1 →", domain: [20, 200]},
    y: {label: `Number of ${units}`, grid: true},
    color: {domain: RATIO_BANDS.map((b) => b.name), range: RATIO_BANDS.map((b) => b.color)},
    marks: [
      Plot.rectY(places, Plot.binX({y: "count"}, {x: (d) => clampX(d.ratio), fill: (d) => band(d.ratio),
        thresholds: Array.from({length: 37}, (_, i) => 20 + i * 5), insetLeft: 0.5, insetRight: 0.5, stroke: BAR_STROKE, strokeWidth: 0.5})),
      Plot.ruleX([100], {stroke: "#0f172a", strokeWidth: 4}),
      Plot.text([100], {x: (d) => d, frameAnchor: "top", dy: -14, text: () => "100%", fill: "#0f172a", fontWeight: 600, fontSize: 11}),
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
      d3.select(this).attr("opacity", inside ? 1 : 0.3).attr("stroke", selection && inside ? "#334155" : BAR_STROKE).attr("stroke-width", selection && inside ? 0.75 : 0.5);
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
const histogram = brushHistogram();
const range = Generators.input(histogram);
const bandKey = () => html`<div style="display:flex;flex-wrap:wrap;gap:12px;font:11px system-ui;color:#475569;margin-top:6px">
  ${RATIO_BANDS.map((b) =>
    html`<span><span style="display:inline-block;width:11px;height:11px;background:${b.color};border:0.5px solid ${BAR_STROKE};margin-right:4px;vertical-align:-1px"></span>${b.name === "About the same" ? "About the same (80–125%)" : b.name}</span>`)}</div>`;
const HOW = "Each bar counts the places in a 5-point band; 100% means the routine target equals WorldPop. Drag across the chart to pick a range, drag the selection to move it or its handles to resize it, and click outside it to clear. Values under 20% or over 200% are drawn at the ends.";
```

```js
// The map is in its own cell so that changing the year or resizing the window does not make a
// new one. `shown` holds the places the popups read; the cell below fills it.
const shown = {byId: new Map(), year: null};
const map = unitMap({geojson: boundaries, height: 520});
// closeOnClick is off because it would also close the box on the click that opens the next one.
const pinned = new maplibregl.Popup({closeButton: true, closeOnClick: false, maxWidth: "340px", offset: 8});
map.map.on("click", (event) => { if (!map.map.queryRenderedFeatures(event.point, {layers: ["unit-fill"]}).length) pinned.remove(); });
map.map.on("click", "unit-fill", (event) => {
  const d = shown.byId.get(event.features?.[0]?.id);
  if (!d) return;
  const line = (label, value) => `<tr><td style="padding:1px 12px 1px 0;color:#475569">${label}</td><td style="text-align:right;font-variant-numeric:tabular-nums">${value}</td></tr>`;
  pinned.setLngLat(event.lngLat).setHTML(`<div style="font:12px system-ui;line-height:1.4">
    <div style="font-weight:600;font-size:13px;margin-bottom:4px">${d.name}${d.admin_level === 3 ? `, ${d.district}` : ""}</div>
    <table style="border-collapse:collapse;margin:0">
      ${line(`Routine target (0–11 months, ${d.year})`, fmt(d.routine_target, 0))}
      ${line(`WorldPop under 1 (${d.year})`, fmt(d.worldpop, 0))}
      ${line("Routine target ÷ WorldPop", `<b>${fmt(d.ratio, 0)}%</b>`)}
      ${line("Difference (routine − WorldPop)", `${d.difference > 0 ? "+" : ""}${fmt(d.difference, 0)}`)}
    </table></div>`).addTo(map.map);
});
invalidation.then(() => map.map.remove());
```

```js
// The ends of the chart hold everything beyond them, so a range touching an end is open on that side.
const within = (v) => !range || ((range[0] <= 20 || v >= range[0]) && (range[1] >= 200 || v <= range[1]));
const selected = places.filter((d) => within(d.ratio));
shown.byId = new Map(places.map((d) => [d.location_id, d]));
pinned.remove();
thematic(map, selected.map((d) => ({location_id: d.location_id, value: +d.ratio.toFixed(0)})),
  {level, legend: RATIO_BANDS, label: "Routine target ÷ WorldPop under 1 (%)"});
```

## Where the routine target differs from WorldPop

<div style="margin-top: 16px">
${item(`Routine target as a share of WorldPop children under 1, by ${unit}, ${year}`, html`${histogram}${bandKey()}`, {note: HOW})}
</div>

<div class="d2-filter" style="margin-top:16px"><span>${range ? html`<b>${selected.length} of ${places.length} ${units}</b> have a routine target that is ${range[0]}% to ${range[1]}% of WorldPop.` : html`<b>Showing all ${places.length} ${units}.</b> Drag across the chart above to filter this map.`}</span>
<span class="muted">In these places: routine target ${fmt(sum(selected, (d) => d.routine_target), 0)}, WorldPop ${fmt(sum(selected, (d) => d.worldpop), 0)}.</span></div>

<div style="margin-top: 16px">
${item("Routine target ÷ WorldPop children under 1", map, {note: "Red and orange: the routine target is lower than WorldPop. Pale yellow: about the same. Blue: the routine target is higher. Grey: outside the selected range, or no figure. Click a place for its figures."})}
</div>

## The places

```js
const table = (list) => pivot(list.flatMap((d) => [
    ["Routine target", d.routine_target], ["WorldPop under 1", d.worldpop],
    ["Routine ÷ WorldPop (%)", d.ratio], ["Difference", d.difference]
  ].map(([col, value]) => ({row: d.label ?? d.name, col, value}))), {row: (d) => d.row, col: (d) => d.col, rowLabel: level === 3 ? "Upazila" : "District", digits: 0});
const ranked = selected.slice().sort((a, b) => off(b.ratio) - off(a.ratio));
// With a range selected, or at district level, the table lists every place; otherwise the 25 furthest from WorldPop.
const listed = (range || level === 2 ? ranked : ranked.slice(0, 25)).map((d) => ({...d, label: level === 3 ? `${d.name}, ${d.district}` : d.name}));
const inDistrict = selected.filter((d) => d.district === district).sort((a, b) => a.name.localeCompare(b.name));
```

<div style="margin-top: 16px">
${item(range ? `All ${listed.length} ${units} in the selected range, furthest from WorldPop first` : level === 2 ? `All ${listed.length} ${units}, furthest from WorldPop first` : `The ${listed.length} upazilas where the routine target is furthest from WorldPop`,
  listed.length ? table(listed) : html`<span class="muted">No places are in the selected range.</span>`,
  {note: "Difference is the routine target minus the WorldPop estimate. With a range selected on the chart, the table lists the places in it."})}
</div>

```js
const districtTable = level === 3 ? html`<div class="d2-filter" style="margin-top:16px">${districtInput}</div>
<div style="margin-top: 16px">${item(`${district}: routine target and WorldPop by upazila, ${year}`, inDistrict.length ? table(inDistrict) : html`<span class="muted">No upazilas in ${district} are in the selection.</span>`)}</div>` : html``;
```

${districtTable}

## The three years

```js
const levelRows = all.filter((d) => d.admin_level === level);
const byYear = YEARS.map((y) => ({year: y, list: levelRows.filter((d) => d.year === y)}));
const yearTable = pivot(byYear.flatMap(({year: y, list}) => [
    ["Places compared", list.length], ["Routine target", sum(list, (d) => d.routine_target)], ["WorldPop under 1", sum(list, (d) => d.worldpop)],
    ["Routine ÷ WorldPop (%)", pct(sum(list, (d) => d.routine_target), sum(list, (d) => d.worldpop))],
    ["Under 80%", list.filter((d) => d.ratio < LOW).length], ["80–125%", list.filter((d) => d.ratio >= LOW && d.ratio <= HIGH).length],
    ["Over 125%", list.filter((d) => d.ratio > HIGH).length]
  ].map(([col, value]) => ({row: y, col, value}))), {row: (d) => d.row, col: (d) => d.col, rowLabel: "Year", digits: 0});
// Places on the same side of WorldPop in every year they have a target for (at least two years).
const perPlace = d3.rollups(levelRows, (v) => v.map((d) => d.ratio), (d) => d.location_id).map(([, r]) => r).filter((r) => r.length > 1);
const alwaysLow = perPlace.filter((r) => r.every((v) => v < LOW)).length;
const alwaysHigh = perPlace.filter((r) => r.every((v) => v > HIGH)).length;
```

<div style="margin-top: 16px">
${item(`Routine target and WorldPop by year, ${units}`, yearTable,
  {note: `The last three columns count places by their routine target as a share of WorldPop. ${alwaysLow} places are under 80% in every year they have a target for, and ${alwaysHigh} are over 125% in every year, so most of the large differences are not one-year errors.`})}
</div>

<div class="d2-footer muted">

**How to read this.** WorldPop is a model, not a count, so a difference does not show which figure is wrong. A routine target far from WorldPop in every year is worth checking against local knowledge: the catchment may be drawn differently from the boundary used here, families may use services in a neighbouring place, or the target may be carried over from an old census. Some sadar upazilas show a very high share (Satkhira Sadar, Mymensingh Sadar). Their municipality or city corporation is a separate place here, so the boundary WorldPop is summed over may cover less ground than the routine target does.

**Sources.** Routine: EPI e-Tracker yearly target of children aged 0–11 months, from the DGHS GIS dashboard. WorldPop Global2 R2025A v1, children under 1, summed over each place's boundary (CC BY 4.0, DOI 10.5258/SOTON/WP00841). Places without a plausible routine target for the year, and Chattogram, Rajbari and Shariatpur districts (no routine figures), are left out.

</div>
