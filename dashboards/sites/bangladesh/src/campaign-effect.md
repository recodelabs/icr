---
title: Did routine immunization change during the campaign?
sql:
  routine: data/routine.parquet
---

# Did routine immunization change during the campaign?

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

```js
import * as Plot from "npm:@observablehq/plot";
import * as d3 from "npm:d3";
import maplibregl from "npm:maplibre-gl@5";
import {item, pivot, fmt, rows} from "./components/dhis2.js";
import {thematic} from "./components/charts.js";
import {unitMap} from "./components/unit-map.js";
import {CAMPAIGN} from "./components/mr.js";

const LOW = 80, HIGH = 125;
// February and March 2026 are the comparison months: the last full months before the campaign
// with normal reporting (December 2025 is nearly empty and January 2026 holds late entries).
const BEFORE = ["202602", "202603"], DURING = ["202604", "202605"], AFTER = ["202606", "202607"];
const MONTHS = [...BEFORE, ...DURING, ...AFTER, "202608", "202609"];
const monthName = (p) => new Date(Date.UTC(+p.slice(0, 4), +p.slice(4) - 1, 1)).toLocaleString("en", {month: "long", timeZone: "UTC"});
const VACCINES = [["mr1", "MR-1", "#d74554"], ["mr2", "MR-2", "#f59e9e"], ["bcg", "BCG", "#518cc3"], ["penta1", "Penta-1", "#7fb0d9"], ["penta3", "Penta-3", "#9aa5b1"]];
const short = (n) => (n ?? "").replace(/ (District|Upazila)$/, "");
const pct = (a, b) => a != null && b ? 100 * a / b : null;
const boundaries = await FileAttachment("data/boundaries.json").json();
const kpi = (label, v, sub = "") => html`<div style="text-align:center;padding:18px 0 10px"><div class="d2-kpi">${v == null ? "—" : typeof v === "string" ? v : fmt(v, 0)}</div>
  <div class="muted" style="font-size:12px;margin-top:6px">${label}</div>${sub ? html`<div class="muted" style="font-size:11px;margin-top:2px">${sub}</div>` : ""}</div>`;
// Red where doses fell during the campaign, blue where they rose.
const RATIO_BANDS = [
  {name: "Under 40%", start: 0, end: 40, color: "#d73027"}, {name: "40–80%", start: 40, end: LOW, color: "#fc8d59"},
  {name: "About the same", start: LOW, end: HIGH, color: "#ffffbf"},
  {name: "125–150%", start: HIGH, end: 150, color: "#91bfdb"}, {name: "Over 150%", start: 150, end: 1000, color: "#4575b4"}
];
const BAND_COLORS = {lower: "#d74554", same: "#a3b1c2", higher: "#518cc3"};
const band = (v) => v < LOW ? "lower" : v > HIGH ? "higher" : "same";
```

```js
const monthly = rows(await sql`
  SELECT location_id, any_value(location_name) AS location_name, any_value(district) AS district, any_value(admin_level) AS admin_level,
         replace(key, '-doses', '') AS vaccine, period, max(count) AS doses
  FROM routine
  WHERE key IN ('mr1-doses', 'mr2-doses', 'bcg-doses', 'penta1-doses', 'penta3-doses') AND period_type = 'Monthly'
    AND period BETWEEN '202602' AND '202609' AND admin_level IN (0, 3)
  GROUP BY location_id, key, period`);
const national = monthly.filter((d) => d.admin_level === 0);
const nationalDoses = (vaccine, periods) => national.filter((d) => d.vaccine === vaccine && periods.includes(d.period)).reduce((s, d) => s + (d.doses ?? 0), 0);
const perMonth = (vaccine, periods) => nationalDoses(vaccine, periods) / periods.length;
const change = (vaccine, periods) => pct(perMonth(vaccine, periods), perMonth(vaccine, BEFORE)) - 100;
const signed = (v) => `${v > 0 ? "+" : ""}${fmt(v, 0)}%`;
// Upazilas: doses per month before, during and after the campaign, for MR-1 and for BCG (a vaccine the campaign did not give).
const byPlace = d3.rollup(monthly.filter((d) => d.admin_level === 3), (list) => {
  const doses = (vaccine, periods) => list.filter((d) => d.vaccine === vaccine && periods.includes(d.period)).reduce((s, d) => s + (d.doses ?? 0), 0) / periods.length;
  const month = (vaccine, period) => list.find((d) => d.vaccine === vaccine && d.period === period)?.doses ?? 0;
  return {location_id: list[0].location_id, name: short(list[0].location_name), district: list[0].district, month,
    mr1_before: doses("mr1", BEFORE), mr1_during: doses("mr1", DURING), mr1_after: doses("mr1", AFTER),
    bcg_before: doses("bcg", BEFORE), bcg_during: doses("bcg", DURING)};
}, (d) => d.location_id);
// Upazilas with too few doses before the campaign are left out: their percentages jump around.
const MIN_DOSES = 50;
const upazilas = Array.from(byPlace.values()).filter((d) => d.mr1_before >= MIN_DOSES && d.bcg_before >= MIN_DOSES)
  .map((d) => ({...d, mr1_ratio: pct(d.mr1_during, d.mr1_before) ?? 0, bcg_ratio: pct(d.bcg_during, d.bcg_before) ?? 0, mr1_after_ratio: pct(d.mr1_after, d.mr1_before) ?? 0}));
const count = (test) => upazilas.filter(test).length;
```

<div class="d2-item"><div class="d2-body" style="font-size:15px;line-height:1.5;max-width:900px">

The MR campaign ran from ${CAMPAIGN.start} to ${CAMPAIGN.end}. Routine immunization gives the same vaccine: the first measles-rubella dose (MR-1) at 9 months and the second (MR-2) at 15 months. This page looks at the doses routine recorded each month around the campaign.

BCG and Penta are the comparison. The campaign did not give them, so if routine sessions had simply stopped, they would have fallen as well.

</div></div>

<div class="grid grid-cols-4" style="gap: 16px; margin-top: 16px">
${item("Routine MR-1 before the campaign", kpi("doses a month, February–March 2026", perMonth("mr1", BEFORE)))}
${item("Routine MR-1 in May", kpi("doses recorded, the campaign's last month", nationalDoses("mr1", ["202605"]), `${signed(change("mr1", ["202605"]))} against February–March`))}
${item("Routine BCG in May", kpi("doses recorded, a vaccine the campaign did not give", nationalDoses("bcg", ["202605"]), `${signed(change("bcg", ["202605"]))} against February–March`))}
${item("Routine MR-1 in June", kpi("doses recorded, the month after the campaign", nationalDoses("mr1", ["202606"]), `${signed(change("mr1", ["202606"]))} against February–March`))}
</div>

```js
const mid = (p) => new Date(Date.UTC(+p.slice(0, 4), +p.slice(4) - 1, 15));
const series = national.map((d) => ({...d, date: mid(d.period), label: VACCINES.find((v) => v[0] === d.vaccine)[1]}));
const nationalChart = Plot.plot({
  width: Math.max(320, width - 48), height: 380, marginLeft: 60, marginBottom: 40, marginRight: 70,
  x: {type: "utc", label: null, ticks: MONTHS.map(mid), tickFormat: (d) => d.toLocaleString("en", {month: "short", timeZone: "UTC"})},
  y: {label: "Routine doses recorded in the month, Bangladesh", grid: true, tickFormat: "s"},
  color: {domain: VACCINES.map((v) => v[1]), range: VACCINES.map((v) => v[2]), legend: true},
  marks: [
    Plot.rectY([{x1: new Date(CAMPAIGN.start), x2: new Date(CAMPAIGN.end)}], {x1: "x1", x2: "x2", fill: "#fde68a", fillOpacity: 0.45}),
    Plot.text([{x: new Date(CAMPAIGN.start)}], {x: "x", frameAnchor: "top", dy: 6, dx: 6, textAnchor: "start", text: () => "MR campaign", fill: "#92400e", fontSize: 11}),
    Plot.ruleY([0]),
    Plot.lineY(series, {x: "date", y: "doses", stroke: "label", strokeWidth: (d) => d.vaccine.startsWith("mr") ? 2.5 : 1.5, z: "label"}),
    Plot.dot(series, {x: "date", y: "doses", fill: "label", r: 3, tip: true, title: (d) => `${d.label}, ${monthName(d.period)} 2026\n${fmt(d.doses, 0)} doses`}),
    Plot.text(series.filter((d) => d.period === "202609"), {x: "date", y: "doses", text: "label", dx: 8, textAnchor: "start", fontSize: 11, fill: "#334155"})
  ]
});
```

<div style="margin-top: 16px">
${item("Routine doses recorded each month in 2026", nationalChart,
  {note: "Red lines: the two routine measles-rubella doses. Blue and grey lines: vaccines the campaign did not give. The shaded band is the campaign."})}
</div>

<div class="grid grid-cols-4" style="gap: 16px; margin-top: 16px">
${item("Upazilas compared", kpi(`with at least ${MIN_DOSES} MR-1 and BCG doses a month before the campaign`, upazilas.length))}
${item("MR-1 fell during the campaign", kpi("upazilas where MR-1 doses a month in April–May were under 80% of February–March", count((d) => d.mr1_ratio < LOW)))}
${item("BCG fell during the campaign", kpi("upazilas where BCG doses a month in April–May were under 80% of February–March", count((d) => d.bcg_ratio < LOW)))}
${item("MR-1 back up afterwards", kpi("upazilas where MR-1 doses a month in June–July were at least 80% of February–March", count((d) => d.mr1_after_ratio >= LOW)))}
</div>

```js
const clampX = (v) => Math.max(0, Math.min(v, 200));
const MARGIN = {top: 20, right: 20, bottom: 40, left: 50};
// Two histograms of the same upazilas, one above the other, with one selection across both:
// drag to pick a range. The value is [low, high] or null (everything).
const SERIES = [
  {name: "MR-1: doses a month during the campaign ÷ before", field: "mr1_ratio"},
  {name: "BCG: doses a month during the campaign ÷ before", field: "bcg_ratio"}
];
const histogram = (() => {
  const W = Math.max(320, width - 48), H = 480;
  const stacked = SERIES.flatMap(({name, field}) => upazilas.map((d) => ({series: name, value: clampX(d[field]), band: band(d[field])})));
  const svg = Plot.plot({
    width: W, height: H, marginTop: MARGIN.top, marginRight: MARGIN.right, marginBottom: MARGIN.bottom, marginLeft: MARGIN.left,
    x: {label: "Doses a month in April–May as % of February–March →", domain: [0, 200]},
    y: {label: "Number of upazilas", grid: true},
    fy: {domain: SERIES.map((s) => s.name), axis: null, padding: 0.12},
    color: {domain: Object.keys(BAND_COLORS), range: Object.values(BAND_COLORS)},
    marks: [
      Plot.rectY(stacked, Plot.binX({y: "count"}, {x: "value", fy: "series", fill: "band", thresholds: Array.from({length: 41}, (_, i) => i * 5), insetLeft: 0.5, insetRight: 0.5})),
      Plot.text(SERIES, {fy: "name", text: "name", frameAnchor: "top-right", dx: -8, dy: 4, fontSize: 12, fontWeight: 600, fill: "#334155"}),
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
})();
const range = Generators.input(histogram);
const map = unitMap({geojson: boundaries, height: 560});
// Click an upazila for a pinned box with its name and monthly doses (hovering shows the ratio only).
const byId = new Map(upazilas.map((d) => [d.location_id, d]));
// closeOnClick is off because it would also close the box on the click that opens the next one.
const pinned = new maplibregl.Popup({closeButton: true, closeOnClick: false, maxWidth: "340px", offset: 8});
map.map.on("click", (event) => { if (!map.map.queryRenderedFeatures(event.point, {layers: ["unit-fill"]}).length) pinned.remove(); });
map.map.on("click", "unit-fill", (event) => {
  const d = byId.get(event.features?.[0]?.id);
  if (!d) return;
  const cell = (v) => `<td style="text-align:right;padding:1px 0 1px 14px;font-variant-numeric:tabular-nums">${v}</td>`;
  const shown = MONTHS.slice(0, 6);
  pinned.setLngLat(event.lngLat).setHTML(`<div style="font:12px system-ui;line-height:1.4">
    <div style="font-weight:600;font-size:13px;margin-bottom:4px">${d.name}, ${d.district}</div>
    <table style="border-collapse:collapse;margin:0">
      <tr><td style="color:#475569">Routine doses, 2026</td>${cell("<b>MR-1</b>")}${cell("<b>BCG</b>")}</tr>
      ${shown.map((p) => `<tr><td style="color:#475569">${monthName(p)}${DURING.includes(p) ? " (campaign)" : ""}</td>${cell(fmt(d.month("mr1", p), 0))}${cell(fmt(d.month("bcg", p), 0))}</tr>`).join("")}
      <tr><td style="color:#475569;padding-top:4px">April–May ÷ February–March</td>${cell(`<b>${fmt(d.mr1_ratio, 0)}%</b>`)}${cell(`${fmt(d.bcg_ratio, 0)}%`)}</tr>
    </table></div>`).addTo(map.map);
});
```

```js
// The right end of the chart holds everything beyond it, so a range touching it is open on that side.
const within = (v) => !range || (v >= range[0] && (range[1] >= 200 || v <= range[1]));
const selected = upazilas.filter((d) => within(d.mr1_ratio));
const bcgInRange = upazilas.filter((d) => within(d.bcg_ratio));
thematic(map, selected.map((d) => ({location_id: d.location_id, value: +d.mr1_ratio.toFixed(0)})),
  {level: 3, legend: RATIO_BANDS, label: "Routine MR-1 doses a month, April–May ÷ February–March (%)"});
```

<div style="margin-top: 16px">
${item("Routine doses during the campaign against before it, by upazila", html`${histogram}
  <div style="display:flex;flex-wrap:wrap;gap:12px;font:11px system-ui;color:#475569;margin-top:6px">
  ${[["lower", "fewer doses during the campaign (under 80%)"], ["same", "about the same (80–125%)"], ["higher", "more doses (over 125%)"]].map(([k, t]) =>
    html`<span><span style="display:inline-block;width:11px;height:11px;background:${BAND_COLORS[k]};margin-right:4px;vertical-align:-1px"></span>${t}</span>`)}</div>`,
  {note: `Both charts count the same ${upazilas.length} upazilas in 5-point bands. 100% means as many doses a month in April–May as in February–March. Drag across the chart to pick a range; it is drawn on both, and the map and table below show the upazilas in that range by the top chart (MR-1). Drag the selection to move it, or its handles to resize it; click outside it to clear. Values over 200% are drawn at the right end.`})}
</div>

<div class="d2-filter" style="margin-top:16px"><span>${range ? html`<b>MR-1 doses at ${range[0]}% to ${range[1]}% of the months before: ${selected.length} of ${upazilas.length} upazilas.</b> For BCG, ${bcgInRange.length} upazilas are in that range.` : html`<b>Showing all ${upazilas.length} upazilas.</b> Drag across the chart above to filter.`}</span></div>

<div style="margin-top: 16px">
${item("Routine MR-1 doses during the campaign against before it", map,
  {note: "Red and orange: fewer MR-1 doses a month during the campaign. Pale yellow: about the same. Blue: more. Grey: outside the selected range, too few doses to compare, or no figure. Click an upazila for its monthly doses."})}
</div>

```js
// With a range selected the table lists every upazila in it; without one, the 25 with the largest fall.
const ranked = selected.slice().sort((a, b) => a.mr1_ratio - b.mr1_ratio || b.mr1_before - a.mr1_before);
const listed = (range ? ranked : ranked.slice(0, 25)).map((d) => ({...d, name: `${d.name}, ${d.district}`}));
const table = (list) => pivot(list.flatMap((d) => [
    ["MR-1 a month, Feb–Mar", d.mr1_before], ["MR-1, April", d.month("mr1", "202604")], ["MR-1, May", d.month("mr1", "202605")], ["MR-1, June", d.month("mr1", "202606")],
    ["MR-1 during ÷ before (%)", d.mr1_ratio], ["BCG during ÷ before (%)", d.bcg_ratio]
  ].map(([col, value]) => ({row: d.name, col, value}))), {row: (d) => d.row, col: (d) => d.col, rowLabel: "Upazila", digits: 0});
```

<div style="margin-top: 16px">
${item(range ? `All ${listed.length} upazilas in the selected range, largest fall in MR-1 first` : `The ${listed.length} upazilas with the largest fall in routine MR-1 during the campaign`, listed.length ? table(listed) : html`<span class="muted">No upazilas are in the selected range.</span>`)}
</div>

<div class="d2-footer muted">

**How to read this.** A fall in routine MR doses with steady BCG and Penta means routine sessions went on but gave less MR: either routine MR was paused during the campaign, or children got their dose in the campaign and it was not also recorded as a routine dose. The data cannot tell these apart. Children vaccinated in the campaign at 9–11 months may then have no routine MR-1 on record. The rise in June and after fits catching up on doses not given in April and May.

**Reporting.** The figures are doses recorded in the EPI e-Tracker, from the DGHS GIS dashboard, so a fall can also be missing reports. That is unlikely here: about as many upazilas reported in April and May as in the months around them, and BCG and Penta held steady. February and March are the comparison months because December 2025 is nearly empty and January 2026 holds late entries; October 2026 is a partial month and is left out. Upazilas with under ${MIN_DOSES} MR-1 or BCG doses a month before the campaign are left out.

</div>
