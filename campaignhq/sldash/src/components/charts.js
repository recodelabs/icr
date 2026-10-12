// DHIS2 visualisation types with Plot. Data rows are {category, series, value}:
// DHIS2's "rows" dimension is the category axis and its "columns" dimension the series.
import * as Plot from "npm:@observablehq/plot";
import {PALETTE, COVERAGE_LEGEND, MAP_CLASSES, fmt} from "./dhis2.js";

const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

/** DHIS2 period code as DHIS2 prints it: 202501 → January 2025, 2025Q1 → Jan–Mar 2025. */
export function periodName(p) {
  if (/^\d{6}$/.test(p)) return `${MONTHS[Number(p.slice(4)) - 1]} ${p.slice(0, 4)}`;
  const q = /^(\d{4})Q([1-4])$/.exec(p);
  if (q) return `${MONTHS[(q[2] - 1) * 3]}–${MONTHS[q[2] * 3 - 1]} ${q[1]}`;
  return p;
}

const order = (data, key, given) => given ?? Array.from(new Set(data.map((d) => d[key])));

/**
 * COLUMN / STACKED_COLUMN / BAR. `stacked` stacks the series in one bar per category;
 * otherwise each category gets a group of bars, one per series. `percent` stacks to 100%.
 */
export function columns(data, {width = 640, height = 320, stacked = false, percent = false, horizontal = false,
                                categoryOrder, seriesOrder, yLabel = null, colors = PALETTE, rotate} = {}) {
  const categories = order(data, "category", categoryOrder);
  const series = order(data, "series", seriesOrder);
  const color = {domain: series, range: colors, legend: series.length > 1};
  const tip = {title: (d) => `${d.category}\n${d.series}: ${fmt(d.value)}`};
  const longest = Math.max(...categories.map((c) => String(c).length));
  const tickRotate = rotate ?? (categories.length > 6 && longest > 4 ? -40 : 0);
  // Room for rotated labels: about 6 px per character, times the sine of the angle.
  const bottom = tickRotate ? Math.min(140, 16 + longest * 6 * Math.abs(Math.sin((tickRotate * Math.PI) / 180))) : 30;
  if (horizontal) {
    return Plot.plot({
      width, height: Math.max(height, 26 * categories.length * (stacked ? 1 : Math.max(1, series.length / 2)) + 60),
      marginLeft: 120, color,
      ...(stacked ? {y: {domain: categories, label: null}} : {fy: {domain: categories, label: null}, y: {domain: series, axis: null}}),
      x: {label: yLabel, grid: true},
      marks: [
        stacked
          ? Plot.barX(data, {y: "category", x: "value", fill: "series", tip: true, ...tip})
          : Plot.barX(data, {fy: "category", y: "series", x: "value", fill: "series", tip: true, ...tip}),
        Plot.ruleX([0])
      ]
    });
  }
  if (stacked) {
    return Plot.plot({
      width, height: height + bottom - 30, marginBottom: bottom, marginLeft: 55, color,
      x: {domain: categories, label: null, tickRotate},
      y: {label: yLabel ?? (percent ? "%" : null), grid: true, percent: false},
      marks: [
        Plot.barY(data, Plot.stackY({offset: percent ? "normalize" : null, x: "category", y: "value", fill: "series", order: series,
          tip: true, ...tip})),
        Plot.ruleY([0])
      ]
    });
  }
  return Plot.plot({
    width, height: height + bottom - 30, marginBottom: bottom, marginLeft: 55, color,
    fx: {domain: categories, label: null, tickRotate, padding: 0.15, axis: "bottom"},
    x: {domain: series, axis: null, padding: 0.05},
    y: {label: yLabel, grid: true},
    marks: [
      Plot.barY(data, {fx: "category", x: "series", y: "value", fill: "series", tip: true, ...tip}),
      Plot.ruleY([0])
    ]
  });
}

/** LINE: one line per series over ordered categories (periods). */
export function lines(data, {width = 640, height = 320, categoryOrder, seriesOrder, yLabel = null, colors = PALETTE, format = (c) => c} = {}) {
  const categories = order(data, "category", categoryOrder);
  const series = order(data, "series", seriesOrder);
  return Plot.plot({
    width, height, marginLeft: 55, marginBottom: categories.length > 6 ? 60 : 30,
    color: {domain: series, range: colors, legend: true},
    x: {domain: categories, label: null, tickFormat: format, type: "point", tickRotate: categories.length > 6 ? -40 : 0},
    y: {label: yLabel, grid: true},
    marks: [
      Plot.lineY(data, {x: "category", y: "value", stroke: "series", strokeWidth: 2, marker: "circle", tip: true,
        title: (d) => `${d.series}, ${format(d.category)}: ${fmt(d.value)}`}),
      Plot.ruleY([0])
    ]
  });
}

/** YEAR_OVER_YEAR_LINE: months Jan–Dec on x, one line per year. Rows are {year, month (1–12), value}. */
export function yearOverYear(data, {width = 640, height = 320, yLabel = null} = {}) {
  const years = Array.from(new Set(data.map((d) => d.year))).sort();
  return Plot.plot({
    width, height, marginLeft: 55,
    color: {domain: years.map(String), range: PALETTE, legend: true},
    x: {domain: MONTHS, label: null},
    y: {label: yLabel, grid: true},
    marks: [
      Plot.lineY(data, {x: (d) => MONTHS[d.month - 1], y: "value", stroke: (d) => String(d.year), strokeWidth: 2, marker: "circle",
        tip: true, title: (d) => `${MONTHS[d.month - 1]} ${d.year}: ${fmt(d.value)}`}),
      Plot.ruleY([0])
    ]
  });
}

/**
 * Colour a unit map like a DHIS2 Maps thematic layer: with a legend set when one is given,
 * otherwise five equal-interval classes between the lowest and highest value.
 */
export function thematic(map, data, {level, legend, label, points: facilities, outline}) {
  // `points`: facility rows {id, name, lon, lat} to colour by the values in `data` (level null).
  const values = new Map(data.map((d) => [d.location_id, d.value]));
  const byId = new Map(data.map((d) => [d.location_id, d]));
  let stops, colors, format;
  if (legend) {
    stops = legend.slice(1).map((l) => l.start);
    colors = legend.map((l) => l.color);
    format = (v) => String(v);
  } else {
    const vs = data.map((d) => d.value).filter((v) => v != null);
    const lo = Math.min(...vs), hi = Math.max(...vs);
    const step = (hi - lo) / MAP_CLASSES.length || 1;
    stops = [1, 2, 3, 4].map((k) => +(lo + k * step).toFixed(1));
    colors = MAP_CLASSES;
    format = (v) => fmt(v);
  }
  const tip = (d) => !d ? "no value" : `${fmt(d.value)}` + (d.denominator != null ? `<br>${fmt(d.numerator, 0)} ÷ ${fmt(d.denominator, 0)}` : "");
  const points = (facilities ?? []).map((f) => ({...f, value: byId.get(f.id)?.value, popup: tip(byId.get(f.id))}));
  map.update({
    level, values, stops, colors, points, outline,
    legend: [label, format],
    popup: (id) => {
      const d = byId.get(id);
      if (!d) return "no value";
      return `${fmt(d.value)}` + (d.denominator != null ? `<br>${fmt(d.numerator, 0)} ÷ ${fmt(d.denominator, 0)}` : "");
    }
  });
}

export {COVERAGE_LEGEND};
