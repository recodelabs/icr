// Chart building blocks for sl-redux. Every chart is short (most 160–260 px) and compares
// places: districts ranked, districts against the country, this year against last.
import * as Plot from "npm:@observablehq/plot";
import * as d3 from "npm:d3";
import {html} from "npm:htl";
import {SERIES, FOCUS, NATIONAL, MUTED, FAINT, INK, ACCENT, ACCENT_FILL, ACCENT_TINT, TARGET, PREVIOUS,
        BETTER, WORSE, NEUTRAL, PERFORMANCE, colorOf, colorsFor, breaksFor, direction, ink,
        fmt, fmtShort, fmtValue, unitOf} from "./theme.js";
import {periodDate, periodName, COUNTRY} from "./data.js";

/** A left margin wide enough for the longest category label. */
const marginFor = (labels, min = 70, max = 240) => Math.max(min, Math.min(max, 12 + 6.2 * Math.max(0, ...labels.map((l) => String(l).length))));

const STYLE = {fontSize: "11px", fontFamily: "Inter, system-ui, sans-serif", color: INK, background: "transparent", overflow: "visible"};

/** A card: title, optional subtitle, content, optional note. */
export function panel(title, content, {subtitle, note, legend, className = ""} = {}) {
  return html`<section class="rx-panel ${className}">
    <header><h3>${title}</h3>${subtitle ? html`<p>${subtitle}</p>` : ""}</header>
    ${legend ? html`<div class="rx-legend">${legend}</div>` : ""}
    <div class="rx-body">${content}</div>
    ${note ? html`<footer>${note}</footer>` : ""}
  </section>`;
}

/** Swatches for a list of names and colours. */
export function swatches(names, colors = SERIES) {
  return html`${names.map((n, i) => html`<span class="rx-swatch"><i style="background:${colors[i % colors.length]}"></i>${n}</span>`)}`;
}

/** The colour classes of an item as a strip: "worse … better", or "fewer … more". */
export function scaleKey(item, values) {
  const b = breaksFor(item, values), c = colorsFor(item);
  const d = direction(item);
  const label = (i) => i === 0 ? `< ${fmt(b[0])}` : i === c.length - 1 ? `≥ ${fmt(b.at(-1))}` : `${fmt(b[i - 1])}–${fmt(b[i])}`;
  return html`<span class="rx-scale"><span class="rx-scale-end">${d ? "worse" : "fewer"}</span>${c.map((col, i) =>
    html`<i title=${label(i) + unitOf(item)} style="background:${col}"></i>`)}<span class="rx-scale-end">${d ? "better" : "more"}</span>
    <span class="rx-scale-breaks">${b.map((v) => fmt(v)).join(" · ")}${unitOf(item)}</span></span>`;
}

/** A headline figure with its change on the previous period and a sparkline. */
export function kpi({label, item, value, prev, prevLabel = "last year", spark = [], sub}) {
  const d = direction(item);
  const delta = value != null && prev != null ? value - prev : null;
  const good = delta == null || d == null || delta === 0 ? null : (delta > 0) === (d === "up");
  const unit = item?.factor === 100 ? " pts" : "";
  const chip = delta == null ? "" : html`<span class="rx-delta ${good === true ? "up" : good === false ? "down" : ""}">${delta > 0 ? "▲" : delta < 0 ? "▼" : "■"} ${(item?.factor ?? 1) === 1 ? fmtShort(Math.abs(delta)) : fmt(Math.abs(delta))}${unit}</span>`;
  const line = spark.length > 1 ? Plot.plot({
    width: 96, height: 32, margin: 2, axis: null, style: STYLE,
    y: {domain: d3.extent(spark, (s) => s.value), nice: false},
    marks: [
      Plot.areaY(spark, {x: "date", y1: () => d3.min(spark, (s) => s.value), y2: "value", fill: ACCENT_FILL, fillOpacity: 0.7, curve: "monotone-x"}),
      Plot.lineY(spark, {x: "date", y: "value", stroke: ACCENT, strokeWidth: 1.5, curve: "monotone-x"}),
      Plot.dot(spark.slice(-1), {x: "date", y: "value", fill: ACCENT, r: 2.5})
    ]
  }) : "";
  return html`<div class="rx-kpi">
    <div class="rx-kpi-label">${label ?? item?.name}</div>
    <div class="rx-kpi-row"><span class="rx-kpi-value">${fmtValue(item, value)}</span>${line}</div>
    <div class="rx-kpi-sub">${chip}${delta != null ? html` <span>vs ${prevLabel}</span>` : ""}${sub ? html` <span>${sub}</span>` : ""}</div>
  </div>`;
}

/**
 * Places ranked by value, best first: a dot per place coloured by the item's scale, a thin
 * line back to last period's value (a dumbbell), and the country as a dashed line.
 * rows: {name, value, prev?}.
 */
export function rank(rows, {item, national, focus = [], width = 400, valueLabel = true, rowHeight = 17, scaleValues, target, prevLabel = "last year"} = {}) {
  const data = rows.filter((r) => r.value != null);
  const up = direction(item) !== "down";
  data.sort((a, b) => up ? b.value - a.value : a.value - b.value);
  const color = colorOf(item, scaleValues ?? data.map((r) => r.value));
  const focusSet = new Set(focus);
  const xs = data.flatMap((r) => [r.value, r.prev]).concat(national ?? []).filter((v) => v != null);
  return Plot.plot({
    width, height: 28 + data.length * rowHeight, marginLeft: marginFor(data.map((r) => r.name)), marginRight: valueLabel ? 46 : 12, marginTop: 6, marginBottom: 22, style: STYLE,
    x: {domain: [Math.min(0, d3.min(xs)), d3.max(xs) * 1.02], grid: true, label: null, tickFormat: (v) => fmtShort(v) + unitOf(item), ticks: 5},
    y: {domain: data.map((r) => r.name), label: null, tickSize: 0},
    marks: [
      Plot.barX(data.filter((r) => focusSet.has(r.name)), {x1: () => Math.min(0, d3.min(xs)), x2: () => d3.max(xs) * 1.02, y: "name", fill: ACCENT_TINT, insetTop: -1, insetBottom: -1}),
      target != null ? Plot.ruleX([target], {stroke: TARGET, strokeWidth: 1.5}) : null,
      national != null ? Plot.ruleX([national], {stroke: NATIONAL, strokeDasharray: "3,3", strokeWidth: 1}) : null,
      national != null ? Plot.text([national], {x: (v) => v, frameAnchor: "top", dy: -2, text: () => `${COUNTRY} ${fmtValue(item, national)}`, fill: MUTED, fontSize: 10, textAnchor: "start", dx: 3}) : null,
      Plot.link(data.filter((r) => r.prev != null), {x1: "prev", x2: "value", y1: "name", y2: "name", stroke: FAINT, strokeWidth: 2}),
      Plot.dot(data.filter((r) => r.prev != null), {x: "prev", y: "name", r: 3, stroke: "#9ca3af", fill: "#fff"}),
      Plot.dot(data, {x: "value", y: "name", r: 5.5, fill: (r) => color(r.value), stroke: (r) => focusSet.has(r.name) ? INK : "#fff", strokeWidth: (r) => focusSet.has(r.name) ? 1.5 : 1}),
      valueLabel ? Plot.text(data, {x: () => d3.max(xs) * 1.02, y: "name", text: (r) => fmtValue(item, r.value), textAnchor: "start", dx: 6, fill: MUTED}) : null,
      Plot.tip(data, Plot.pointerY({x: "value", y: "name", title: (r) => `${r.name}\n${fmtValue(item, r.value)}${r.prev != null ? `\n${prevLabel} ${fmtValue(item, r.prev)}` : ""}${r.numerator != null && r.denominator != null ? `\n${fmt(r.numerator, 0)} ÷ ${fmt(r.denominator, 0)}` : ""}`}))
    ]
  });
}

/**
 * Chiefdoms (or any sub-units) as dots in a row per district, coloured by value, with each
 * district's own value as a black tick and the country as a dashed line: the spread inside
 * each district at a glance. rows: {name, group, value}; groupValues: Map group → value.
 */
export function strip(rows, {item, groupValues = new Map(), national, groups, width = 400, scaleValues} = {}) {
  const data = rows.filter((r) => r.value != null);
  const order = groups ?? Array.from(new Set(data.map((r) => r.group))).sort((a, b) => (groupValues.get(b) ?? 0) - (groupValues.get(a) ?? 0));
  const color = colorOf(item, scaleValues ?? data.map((r) => r.value));
  const xs = data.map((r) => r.value).concat(national ?? []);
  const hi = d3.quantile(xs.slice().sort(d3.ascending), 0.99) * 1.05;
  return Plot.plot({
    width, height: 30 + order.length * 20, marginLeft: marginFor(order), marginRight: 14, marginTop: 8, marginBottom: 22, style: STYLE,
    x: {domain: [0, Math.max(hi, d3.max(Array.from(groupValues.values())) ?? 0)], grid: true, label: null, clamp: true, tickFormat: (v) => fmtShort(v) + unitOf(item)},
    y: {domain: order, label: null, tickSize: 0},
    marks: [
      national != null ? Plot.ruleX([national], {stroke: NATIONAL, strokeDasharray: "3,3"}) : null,
      Plot.dot(data, {x: "value", y: "group", r: 4, fill: (r) => color(r.value), stroke: "#fff", strokeWidth: 0.6, fillOpacity: 0.85}),
      Plot.tickX(order.filter((g) => groupValues.has(g)), {x: (g) => groupValues.get(g), y: (g) => g, stroke: INK, strokeWidth: 2}),
      Plot.tip(data, Plot.pointer({x: "value", y: "group", title: (r) => `${r.name} (${r.group})\n${fmtValue(item, r.value)}`}))
    ]
  });
}

/**
 * Lines over time: the range of all districts as a grey band, each picked district in its
 * own colour with its name at the end, and the country in black.
 * rows: {name, date, value, level} (level 0 country, 1 district).
 */
export function trend(rows, {item, focus = [], width = 640, height = 200, xFormat, band = true, target} = {}) {
  const nat = rows.filter((r) => r.level === 0 && r.value != null).sort((a, b) => a.date - b.date);
  const units = rows.filter((r) => r.level !== 0 && r.value != null);
  const picked = units.filter((r) => focus.includes(r.name));
  const ext = d3.rollups(units, (v) => ({lo: d3.min(v, (r) => r.value), hi: d3.max(v, (r) => r.value)}), (r) => +r.date)
    .map(([t, e]) => ({date: new Date(t), ...e})).sort((a, b) => a.date - b.date);
  const colorOfFocus = (n) => FOCUS[focus.indexOf(n) % FOCUS.length];
  const last = d3.rollups(picked.concat(nat), (v) => v.sort((a, b) => b.date - a.date)[0], (r) => r.name).map(([, r]) => ({...r}));
  const [lo, hi] = d3.extent(units.concat(nat), (r) => r.value);
  const ys = spread(last.map((r) => r.value), ((hi - lo) || 1) / Math.max(6, (height - 30) / 12));
  last.forEach((r, i) => { r.labelY = ys[i]; });
  return Plot.plot({
    width, height, marginLeft: 40, marginRight: 90, marginTop: 8, marginBottom: 22, style: STYLE,
    x: {label: null, ticks: 6, tickFormat: xFormat},
    y: {label: null, grid: true, tickFormat: (v) => fmtShort(v) + unitOf(item), nice: true, zero: direction(item) == null},
    marks: [
      band && ext.length ? Plot.areaY(ext, {x: "date", y1: "lo", y2: "hi", fill: "#e5e7eb", fillOpacity: 0.7, curve: "monotone-x"}) : null,
      target != null ? Plot.ruleY([target], {stroke: TARGET, strokeDasharray: "4,3"}) : null,
      focus.length ? null : Plot.lineY(units, {x: "date", y: "value", z: "name", stroke: "#cbd5e1", strokeWidth: 0.8, curve: "monotone-x"}),
      Plot.lineY(picked, {x: "date", y: "value", z: "name", stroke: (r) => colorOfFocus(r.name), strokeWidth: 1.8, curve: "monotone-x"}),
      Plot.lineY(nat, {x: "date", y: "value", stroke: NATIONAL, strokeWidth: 2.2, curve: "monotone-x"}),
      Plot.text(last, {x: "date", y: "labelY", text: (r) => r.level === 0 ? COUNTRY : r.name, textAnchor: "start", dx: 5,
                       fill: (r) => r.level === 0 ? NATIONAL : colorOfFocus(r.name), fontWeight: 500}),
      Plot.tip(units.concat(nat), Plot.pointer({x: "date", y: "value", title: (r) => `${r.name}, ${periodName(r.period)}\n${fmtValue(item, r.value)}`}))
    ]
  });
}

/**
 * A grid of cells: rows × columns, coloured by value with the value written in.
 * rows: {x, y, value}; `item` sets the colours (or `colorFn`).
 */
export function heatmap(rows, {item, xOrder, yOrder, xFormat = (x) => x, width = 640, cell = 22, labels = true, marginLeft: ml, colorFn, title} = {}) {
  const xs = xOrder ?? Array.from(new Set(rows.map((r) => r.x)));
  const ys = yOrder ?? Array.from(new Set(rows.map((r) => r.y)));
  const marginLeft = ml ?? marginFor(ys);
  const color = colorFn ?? colorOf(item, rows.map((r) => r.value));
  const cw = (width - marginLeft - 8) / Math.max(1, xs.length);
  const showText = labels && cw >= 30;
  const maxChars = Math.max(3, Math.floor(cw / 6));
  const xTick = (x) => { const t = String(xFormat(x)); return t.length > maxChars ? t.slice(0, maxChars - 1) + "…" : t; };
  return Plot.plot({
    width, height: 26 + ys.length * cell, marginLeft, marginRight: 8, marginTop: 22, marginBottom: 4, style: STYLE, padding: 0.06,
    x: {domain: xs, axis: "top", label: null, tickSize: 0, tickFormat: xTick},
    y: {domain: ys, label: null, tickSize: 0},
    marks: [
      Plot.cell(rows, {x: "x", y: "y", fill: (r) => color(r.value), rx: 3}),
      showText ? Plot.text(rows, {x: "x", y: "y", text: (r) => fmtShort(r.value), fill: (r) => ink(color(r.value)), fontSize: 10}) : null,
      Plot.tip(rows, Plot.pointer({x: "x", y: "y", title: title ?? ((r) => `${r.y} · ${xFormat(r.x)}\n${fmtValue(item, r.value)}`)}))
    ]
  });
}

/**
 * Several items per place as coloured dots on one line, joined by a grey range: e.g. the
 * antigens of each district. rows: {category, series, value}.
 */
export function ladder(rows, {categoryOrder, seriesOrder, colors = SERIES, width = 640, unit = "%", target, rowHeight = 18} = {}) {
  const cats = categoryOrder ?? Array.from(new Set(rows.map((r) => r.category)));
  const series = seriesOrder ?? Array.from(new Set(rows.map((r) => r.series)));
  const data = rows.filter((r) => r.value != null && cats.includes(r.category));
  const range = d3.rollups(data, (v) => [d3.min(v, (r) => r.value), d3.max(v, (r) => r.value)], (r) => r.category).map(([c, [lo, hi]]) => ({c, lo, hi}));
  return Plot.plot({
    width, height: 30 + cats.length * rowHeight, marginLeft: marginFor(cats), marginRight: 14, marginTop: 6, marginBottom: 22, style: STYLE,
    x: {label: null, grid: true, nice: true, tickFormat: (v) => fmtShort(v) + unit},
    y: {domain: cats, label: null, tickSize: 0},
    color: {domain: series, range: colors},
    marks: [
      target != null ? Plot.ruleX([target], {stroke: TARGET, strokeDasharray: "4,3"}) : null,
      Plot.link(range, {x1: "lo", x2: "hi", y1: "c", y2: "c", stroke: FAINT, strokeWidth: 3}),
      Plot.dot(data, {x: "value", y: "category", fill: "series", r: 5, stroke: "#fff", strokeWidth: 0.8}),
      Plot.tip(data, Plot.pointer({x: "value", y: "category", title: (r) => `${r.category}\n${r.series}: ${fmt(r.value)}${unit}`}))
    ]
  });
}

/**
 * 100% bars: each category split into its series, with the share written on wide segments.
 * rows: {category, series, value}.
 */
export function shares(rows, {categoryOrder, seriesOrder, colors = SERIES, width = 640, rowHeight = 20} = {}) {
  const cats = categoryOrder ?? Array.from(new Set(rows.map((r) => r.category)));
  const series = seriesOrder ?? Array.from(new Set(rows.map((r) => r.series)));
  const data = rows.filter((r) => r.value != null && r.value > 0 && cats.includes(r.category));
  const totals = d3.rollup(data, (v) => d3.sum(v, (r) => r.value), (r) => r.category);
  const withShare = data.map((r) => ({...r, share: r.value / totals.get(r.category)}));
  return Plot.plot({
    width, height: 26 + cats.length * rowHeight, marginLeft: marginFor(cats), marginRight: 10, marginTop: 4, marginBottom: 20, style: STYLE,
    x: {label: null, percent: true, tickFormat: (v) => `${v}%`, ticks: 5},
    y: {domain: cats, label: null, tickSize: 0},
    color: {domain: series, range: colors},
    marks: [
      Plot.barX(withShare, Plot.stackX({x: "share", y: "category", fill: "series", order: series, insetTop: 2, insetBottom: 2})),
      Plot.text(withShare, Plot.stackX({x: "share", y: "category", z: "series", order: series,
        text: (r) => r.share >= 0.09 ? `${Math.round(r.share * 100)}%` : "", fill: "#fff", fontSize: 10})),
      Plot.tip(withShare, Plot.pointer(Plot.stackX({x: "share", y: "category", fill: "series", order: series,
        title: (r) => `${r.category} · ${r.series}\n${fmtShort(r.value)} (${Math.round(r.share * 100)}%)`})))
    ]
  });
}

/** Two series back to back from a centre line (e.g. fixed | outreach), left in the first colour. rows: {category, series, value}. */
export function backToBack(rows, {left, right, categoryOrder, colors = [SERIES[0], SERIES[2]], width = 640, rowHeight = 20} = {}) {
  const cats = categoryOrder ?? Array.from(new Set(rows.map((r) => r.category)));
  const data = rows.filter((r) => r.value != null && (r.series === left || r.series === right))
    .map((r) => ({...r, signed: r.series === left ? -r.value : r.value}));
  const m = d3.max(data, (r) => Math.abs(r.signed)) ?? 1;
  return Plot.plot({
    width, height: 26 + cats.length * rowHeight, marginLeft: marginFor(cats), marginRight: 14, marginTop: 6, marginBottom: 20, style: STYLE,
    x: {domain: [-m * 1.3, m * 1.3], label: null, tickFormat: (v) => fmtShort(Math.abs(v)), ticks: 6},
    y: {domain: cats, label: null, tickSize: 0},
    marks: [
      Plot.barX(data, {x: "signed", y: "category", fill: (r) => r.series === left ? colors[0] : colors[1], insetTop: 2, insetBottom: 2, rx: 2}),
      // textAnchor and dx are constants in Plot, so one text mark per side.
      Plot.text(data.filter((r) => r.signed < 0), {x: "signed", y: "category", text: (r) => fmtShort(r.value), textAnchor: "end", dx: -4, fill: MUTED, fontSize: 10}),
      Plot.text(data.filter((r) => r.signed >= 0), {x: "signed", y: "category", text: (r) => fmtShort(r.value), textAnchor: "start", dx: 4, fill: MUTED, fontSize: 10}),
      Plot.ruleX([0], {stroke: INK})
    ]
  });
}

/** A horizontal bullet: the value as a bar over the item's colour bands, last year as a tick. */
export function bullet({item, value, prev, max = 120, width = 320, label}) {
  const b = breaksFor(item, [value ?? 0]), c = colorsFor(item);
  const edges = [0, ...b.filter((v) => v < max), max];
  const bands = edges.slice(0, -1).map((x0, i) => ({x0, x1: edges[i + 1], fill: c[i]}));
  return html`<div class="rx-bullet">
    ${label ? html`<div class="rx-bullet-label">${label}</div>` : ""}
    <div class="rx-bullet-value">${fmtValue(item, value)}</div>
    ${Plot.plot({
      width, height: 46, marginLeft: 4, marginRight: 8, marginTop: 4, marginBottom: 18, style: STYLE,
      x: {domain: [0, max], label: null, ticks: 6, tickFormat: (v) => `${v}%`},
      marks: [
        Plot.rectX(bands, {x1: "x0", x2: "x1", y1: 0, y2: 1, fill: "fill", fillOpacity: 0.35}),
        value != null ? Plot.rectX([value], {x1: 0, x2: (v) => Math.min(v, max), y1: 0.32, y2: 0.68, fill: INK}) : null,
        prev != null ? Plot.ruleX([prev], {y1: 0.12, y2: 0.88, stroke: PREVIOUS, strokeWidth: 2}) : null
      ]
    })}
  </div>`;
}

/**
 * Districts placed by two items, each labelled; picked districts in their colours.
 * rows: {name, x, y}.
 */
export function scatter(rows, {xItem, yItem, focus = [], width = 400, height = 260, xLabel, yLabel, diagonal = false} = {}) {
  const data = rows.filter((r) => r.x != null && r.y != null);
  const colorOfFocus = (n) => focus.includes(n) ? FOCUS[focus.indexOf(n) % FOCUS.length] : "#64748b";
  const pad = (lo, hi) => { const d = (hi - lo) || 1; return [lo - d * 0.08, hi + d * 0.08]; };
  let xd = pad(d3.min(data, (r) => r.x), d3.max(data, (r) => r.x));
  let yd = pad(d3.min(data, (r) => r.y), d3.max(data, (r) => r.y));
  if (diagonal) { const lo = Math.min(xd[0], yd[0], 0), hi = Math.max(xd[1], yd[1]); xd = yd = [Math.max(0, lo), hi]; }
  // Label a point only where its name does not overlap one already placed: the country and
  // picked districts first, then the rest from the edges inwards.
  const [ml, mr, mt, mb] = [44, 16, 10, 34];
  const px = (v) => ml + (v - xd[0]) / (xd[1] - xd[0]) * (width - ml - mr);
  const py = (v) => mt + (1 - (v - yd[0]) / (yd[1] - yd[0])) * (height - mt - mb);
  const cx = d3.mean(data, (r) => r.x), cy = d3.mean(data, (r) => r.y);
  const order = data.slice().sort((a, b) => (b.level === 0) - (a.level === 0) || focus.includes(b.name) - focus.includes(a.name)
    || Math.hypot(b.x - cx, b.y - cy) - Math.hypot(a.x - cx, a.y - cy));
  const placed = [];
  const labelled = order.filter((r) => {
    const w = r.name.length * 5.6 + 4, x0 = px(r.x) - w / 2, y0 = py(r.y) - 19;
    const box = [x0, y0, x0 + w, y0 + 12];
    if (placed.some((p) => box[0] < p[2] && box[2] > p[0] && box[1] < p[3] && box[3] > p[1])) return false;
    placed.push(box);
    return true;
  });
  return Plot.plot({
    width, height, marginLeft: ml, marginRight: mr, marginTop: mt, marginBottom: mb, style: STYLE,
    x: {label: xLabel ?? xItem?.name, grid: true, domain: xd, tickFormat: (v) => fmtShort(v) + unitOf(xItem)},
    y: {label: yLabel ?? yItem?.name, grid: true, domain: yd, tickFormat: (v) => fmtShort(v) + unitOf(yItem)},
    marks: [
      diagonal ? Plot.line([[xd[0], xd[0]], [xd[1], xd[1]]], {stroke: FAINT, strokeDasharray: "4,3"}) : null,
      Plot.dot(data, {x: "x", y: "y", r: (r) => r.level === 0 ? 6 : 4.5, fill: (r) => r.level === 0 ? NATIONAL : colorOfFocus(r.name), fillOpacity: 0.9}),
      Plot.text(labelled, {x: "x", y: "y", text: "name", dy: -10, fontSize: 10, fill: (r) => r.level === 0 ? NATIONAL : colorOfFocus(r.name)}),
      Plot.tip(data, Plot.pointer({x: "x", y: "y", title: (r) => `${r.name}\n${xLabel ?? xItem?.name}: ${fmtValue(xItem, r.x)}\n${yLabel ?? yItem?.name}: ${fmtValue(yItem, r.y)}`}))
    ]
  });
}

/** Positions for labels at `values`, pushed apart to at least `gap` (same units). */
function spread(values, gap) {
  const order = values.map((v, i) => [v, i]).sort((a, b) => a[0] - b[0]);
  const out = new Array(values.length);
  let prev = -Infinity;
  for (const [v, i] of order) { prev = Math.max(v, prev + gap); out[i] = prev; }
  // Shift back down so the block stays centred on the data.
  const over = d3.max(order, ([v, i]) => out[i] - v) / 2;
  return out.map((y) => y - (over > 0 ? over : 0));
}

/** Last year → this year per district, as a slope chart. rows: {name, from, to}. */
export function slope(rows, {item, fromLabel, toLabel, focus = [], width = 320, height = 260} = {}) {
  const data = rows.filter((r) => r.from != null && r.to != null);
  const d = direction(item);
  const lo = d3.min(data, (r) => Math.min(r.from, r.to)), hi = d3.max(data, (r) => Math.max(r.from, r.to));
  const gap = (hi - lo) / Math.max(8, (height - 30) / 12);
  const yFrom = spread(data.map((r) => r.from), gap), yTo = spread(data.map((r) => r.to), gap);
  const labelled = data.map((r, i) => ({...r, yFrom: yFrom[i], yTo: yTo[i]}));
  const strokeOf = (r) => focus.length && !focus.includes(r.name) ? "#e5e7eb" : (r.to >= r.from) === (d !== "down") ? BETTER : WORSE;
  return Plot.plot({
    width, height, marginLeft: 96, marginRight: 96, marginTop: 18, marginBottom: 8, style: STYLE,
    x: {domain: [fromLabel, toLabel], axis: "top", label: null, tickSize: 0, inset: 10},
    y: {axis: null, domain: [Math.min(lo, d3.min(yFrom), d3.min(yTo)), Math.max(hi, d3.max(yFrom), d3.max(yTo))]},
    marks: [
      Plot.link(labelled, {x1: () => fromLabel, x2: () => toLabel, y1: "from", y2: "to", stroke: strokeOf, strokeWidth: 1.6}),
      Plot.dot(labelled, {x: () => fromLabel, y: "from", r: 2.5, fill: MUTED}),
      Plot.dot(labelled, {x: () => toLabel, y: "to", r: 2.5, fill: MUTED}),
      Plot.text(labelled, {x: () => fromLabel, y: "yFrom", text: (r) => `${r.name} ${fmt(r.from)}`, textAnchor: "end", dx: -7, fontSize: 9.5, fill: MUTED}),
      Plot.text(labelled, {x: () => toLabel, y: "yTo", text: (r) => `${fmt(r.to)} ${r.name}`, textAnchor: "start", dx: 7, fontSize: 9.5,
                           fill: (r) => strokeOf(r) === "#e5e7eb" ? "#9ca3af" : INK})
    ]
  });
}

/** Stacked areas over time. rows: {date, series, value}. */
export function stackedArea(rows, {seriesOrder, colors = SERIES, width = 640, height = 200, xFormat, unit = ""} = {}) {
  const series = seriesOrder ?? Array.from(new Set(rows.map((r) => r.series)));
  return Plot.plot({
    width, height, marginLeft: 44, marginTop: 8, marginBottom: 22, style: STYLE,
    x: {label: null, tickFormat: xFormat},
    y: {label: null, grid: true, tickFormat: (v) => fmtShort(v) + unit},
    color: {domain: series, range: colors},
    marks: [
      Plot.areaY(rows, Plot.stackY({x: "date", y: "value", fill: "series", order: series, fillOpacity: 0.85})),
      Plot.ruleY([0]),
      Plot.tip(rows, Plot.pointer(Plot.stackY({x: "date", y: "value", fill: "series", order: series, title: (r) => `${r.series}, ${xFormat ? xFormat(r.date) : r.date.getUTCFullYear()}\n${fmtShort(r.value)}`})))
    ]
  });
}

/** Horizontal bars, longest first, value written at the end. rows: {name, value}. */
export function bars(rows, {item, color = SERIES[0], colorFn, width = 400, rowHeight = 18, sort = true, marginLeft: ml} = {}) {
  const data = rows.filter((r) => r.value != null);
  const marginLeft = ml ?? marginFor(data.map((r) => r.name));
  if (sort) data.sort((a, b) => b.value - a.value);
  return Plot.plot({
    width, height: 24 + data.length * rowHeight, marginLeft, marginRight: 50, marginTop: 4, marginBottom: 18, style: STYLE,
    x: {label: null, grid: true, tickFormat: (v) => fmtShort(v) + unitOf(item), ticks: 4},
    y: {domain: data.map((r) => r.name), label: null, tickSize: 0},
    marks: [
      Plot.barX(data, {x: "value", y: "name", fill: colorFn ?? (() => color), insetTop: 3, insetBottom: 3, rx: 2}),
      Plot.text(data, {x: "value", y: "name", text: (r) => fmtValue(item, r.value), textAnchor: "start", dx: 4, fill: MUTED}),
      Plot.ruleX([0])
    ]
  });
}

/**
 * A district small-multiple grid: one short area chart per district on a shared scale, with
 * the country as a dashed line. rows: {name, date, value, level}.
 */
export function multiples(rows, {item, names, columns = 5, width = 900, panelHeight = 64, focus = []} = {}) {
  const nat = rows.filter((r) => r.level === 0 && r.value != null);
  const units = rows.filter((r) => r.level !== 0 && r.value != null);
  const list = names ?? Array.from(new Set(units.map((r) => r.name))).sort();
  const pos = new Map(list.map((n, i) => [n, {fx: i % columns, fy: Math.floor(i / columns)}]));
  const unitsPos = units.filter((r) => pos.has(r.name)).map((r) => ({...r, ...pos.get(r.name)}));
  const natPos = list.flatMap((n) => nat.map((r) => ({...r, ...pos.get(n)})));
  const labels = list.map((n) => ({name: n, ...pos.get(n)}));
  const ext = d3.extent(units.concat(nat), (r) => r.value);
  const rowsN = Math.ceil(list.length / columns);
  return Plot.plot({
    width, height: rowsN * (panelHeight + 18) + 10, marginLeft: 36, marginTop: 16, marginBottom: 6, marginRight: 8, style: STYLE,
    fx: {axis: null, padding: 0.12}, fy: {axis: null, padding: 0.28},
    x: {axis: null},
    y: {label: null, ticks: 2, grid: true, domain: [Math.min(0, ext[0]), ext[1]], tickFormat: (v) => fmtShort(v)},
    marks: [
      Plot.areaY(unitsPos, {x: "date", y: "value", fx: "fx", fy: "fy", fill: (r) => focus.includes(r.name) ? ACCENT_FILL : ACCENT_TINT, curve: "monotone-x"}),
      Plot.lineY(unitsPos, {x: "date", y: "value", fx: "fx", fy: "fy", stroke: (r) => focus.includes(r.name) ? FOCUS[focus.indexOf(r.name) % FOCUS.length] : ACCENT, strokeWidth: 1.4, curve: "monotone-x"}),
      Plot.lineY(natPos, {x: "date", y: "value", fx: "fx", fy: "fy", z: null, stroke: NATIONAL, strokeDasharray: "3,2", strokeWidth: 1}),
      Plot.text(labels, {fx: "fx", fy: "fy", frameAnchor: "top-left", dy: -13, text: "name", fontWeight: 600, fill: INK}),
      Plot.tip(unitsPos, Plot.pointerX({x: "date", y: "value", fx: "fx", fy: "fy", title: (r) => `${r.name}, ${periodName(r.period)}\n${fmtValue(item, r.value)}`}))
    ]
  });
}

/**
 * A table of places × items, each cell coloured on its item's own scale, the country first.
 * items: [{dx, name, factor, kind}]; values: rows with dx, location_name, value.
 */
export function scorecard(values, {items, places, focus = [], shortName = (it) => it.name, prevValues = []} = {}) {
  const at = new Map(values.map((d) => [`${d.dx}\u0000${d.location_name}`, d.value]));
  const prevAt = new Map(prevValues.map((d) => [`${d.dx}\u0000${d.location_name}`, d.value]));
  const colors = new Map(items.map((it) => [it.dx, colorOf(it, values.filter((d) => d.dx === it.dx && d.admin_level !== 0).map((d) => d.value))]));
  return html`<div class="rx-scorecard"><table>
    <thead><tr><th></th>${items.map((it) => html`<th title=${it.name}>${shortName(it)}</th>`)}</tr></thead>
    <tbody>${places.map((p) => html`<tr class=${p === COUNTRY ? "rx-country" : focus.includes(p) ? "rx-focus" : ""}><th>${p}</th>${items.map((it) => {
      const v = at.get(`${it.dx}\u0000${p}`);
      const pv = prevAt.get(`${it.dx}\u0000${p}`);
      const bg = colors.get(it.dx)(v);
      const arrow = v != null && pv != null && Math.abs(v - pv) >= 0.5 ? (v > pv ? "↑" : "↓") : "";
      return html`<td style="background:${v == null ? "transparent" : bg};color:${ink(bg)}" title=${`${it.name}: ${fmtValue(it, v)}${pv != null ? ` (last year ${fmtValue(it, pv)})` : ""}`}>${v == null ? "–" : fmtShort(v)}<small>${arrow}</small></td>`;
    })}</tr>`)}</tbody>
  </table></div>`;
}

/** Month dates for a list of period codes. */
export const dated = (rows) => rows.map((r) => ({...r, date: periodDate(r.period)}));

/** Several items over time for one place, one line each, named at the end. rows: {date, series, value, period}. */
export function lines(rows, {seriesOrder, colors = SERIES, width = 640, height = 200, xFormat, unit = "", target} = {}) {
  const series = seriesOrder ?? Array.from(new Set(rows.map((r) => r.series)));
  const data = rows.filter((r) => r.value != null);
  const last = d3.rollups(data, (v) => v.sort((a, b) => b.date - a.date)[0], (r) => r.series).map(([, r]) => r);
  const [lo, hi] = d3.extent(data, (r) => r.value);
  const ys = spread(last.map((r) => r.value), ((hi - lo) || 1) / Math.max(6, (height - 30) / 12));
  last.forEach((r, i) => { r.labelY = ys[i]; });
  return Plot.plot({
    width, height, marginLeft: 40, marginRight: 120, marginTop: 8, marginBottom: 22, style: STYLE,
    x: {label: null, ticks: 6, tickFormat: xFormat},
    y: {label: null, grid: true, nice: true, tickFormat: (v) => fmtShort(v) + unit},
    color: {domain: series, range: colors},
    marks: [
      target != null ? Plot.ruleY([target], {stroke: TARGET, strokeDasharray: "4,3"}) : null,
      Plot.lineY(data, {x: "date", y: "value", stroke: "series", strokeWidth: 1.8, curve: "monotone-x"}),
      Plot.dot(last, {x: "date", y: "value", fill: "series", r: 2.5}),
      Plot.text(last, {x: "date", y: "labelY", text: (r) => r.series.length > 22 ? r.series.slice(0, 21) + "…" : r.series, fill: "series", textAnchor: "start", dx: 6, fontWeight: 500}),
      Plot.tip(data, Plot.pointer({x: "date", y: "value", stroke: "series", title: (r) => `${r.series}, ${periodName(r.period)}\n${fmt(r.value)}${unit}`}))
    ]
  });
}

/** Counts stacked along a bar per category, longest first. rows: {category, series, value}. */
export function stackBars(rows, {categoryOrder, seriesOrder, colors = SERIES, width = 640, rowHeight = 19} = {}) {
  const series = seriesOrder ?? Array.from(new Set(rows.map((r) => r.series)));
  const data = rows.filter((r) => r.value != null && r.value > 0);
  const totals = d3.rollup(data, (v) => d3.sum(v, (r) => r.value), (r) => r.category);
  const cats = categoryOrder ?? Array.from(totals.keys()).sort((a, b) => totals.get(b) - totals.get(a));
  return Plot.plot({
    width, height: 24 + cats.length * rowHeight, marginLeft: marginFor(cats), marginRight: 44, marginTop: 4, marginBottom: 20, style: STYLE,
    x: {label: null, grid: true, tickFormat: fmtShort, ticks: 5},
    y: {domain: cats, label: null, tickSize: 0},
    color: {domain: series, range: colors},
    marks: [
      Plot.barX(data, Plot.stackX({x: "value", y: "category", fill: "series", order: series, insetTop: 2, insetBottom: 2})),
      Plot.text(cats.map((c) => ({c, t: totals.get(c)})), {x: "t", y: "c", text: (d) => fmtShort(d.t), textAnchor: "start", dx: 4, fill: MUTED}),
      Plot.tip(data, Plot.pointer(Plot.stackX({x: "value", y: "category", fill: "series", order: series, title: (r) => `${r.category} · ${r.series}\n${fmt(r.value, 0)}`})))
    ]
  });
}

/**
 * This year against last year, month by month, as bars of the difference (blue where the
 * change is for the better). rows: {month, now, before}.
 */
export function yearOnYear(rows, {item, width = 640, height = 200} = {}) {
  const d = direction(item);
  const data = rows.map((r) => ({...r, diff: r.now != null && r.before != null ? r.now - r.before : null}));
  const unit = item?.factor === 100 ? " pts" : "";
  return Plot.plot({
    width, height, marginLeft: 48, marginTop: 10, marginBottom: 22, style: STYLE,
    x: {domain: data.map((r) => r.month), label: null, tickSize: 0},
    y: {label: null, grid: true, tickFormat: (v) => `${v > 0 ? "+" : ""}${fmtShort(v)}${unit}`},
    marks: [
      Plot.barY(data, {x: "month", y: "diff", fill: (r) => d == null ? NEUTRAL : (r.diff >= 0) === (d === "up") ? PERFORMANCE[4] : PERFORMANCE[1], rx: 2}),
      Plot.ruleY([0]),
      Plot.tip(data, Plot.pointerX({x: "month", y: "diff", title: (r) => `${r.month}\nthis year ${fmtValue(item, r.now)}\nlast year ${fmtValue(item, r.before)}`}))
    ]
  });
}

/** The districts as dots on one line, coloured by value, with the country as a black tick. rows: {name, value}. */
export function dotStrip(rows, {item, national, width = 240, focus = []} = {}) {
  const data = rows.filter((r) => r.value != null);
  const color = colorOf(item, data.map((r) => r.value));
  const xs = data.map((r) => r.value).concat(national ?? []);
  return Plot.plot({
    width, height: 38, marginLeft: 6, marginRight: 6, marginTop: 6, marginBottom: 16, style: {...STYLE, fontSize: "10px"},
    x: {domain: d3.extent(xs), nice: true, ticks: 3, tickFormat: (v) => fmtShort(v) + unitOf(item), tickSize: 0, label: null},
    y: {axis: null},
    marks: [
      Plot.ruleY([0], {stroke: "#e5e7eb"}),
      Plot.dot(data, {x: "value", y: 0, r: 4.5, fill: (r) => color(r.value), stroke: (r) => focus.includes(r.name) ? INK : "#fff", strokeWidth: 0.8}),
      national != null ? Plot.tickX([national], {x: (v) => v, y: 0, stroke: NATIONAL, strokeWidth: 2, insetTop: -2, insetBottom: -2}) : null,
      Plot.tip(data, Plot.pointerX({x: "value", y: 0, title: (r) => `${r.name}\n${fmtValue(item, r.value)}`}))
    ]
  });
}
