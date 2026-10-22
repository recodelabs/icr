// Colours and number formats. Values are coloured on a muted orange → slate blue scale
// (worse → better), which reads the same for the common forms of colour blindness; for items
// where lower is better (drop-out, malnutrition, deaths) the scale is reversed. Counts, where
// neither is better, use plain greys. The palette is kept low in saturation, as in a printed figure.

/** Series colours for categories that have no order (antigens, forms, facility types). */
export const SERIES = ["#4e79a7", "#f28e2b", "#59a14f", "#e15759", "#76b7b2", "#edc948", "#b07aa1", "#9c755f",
                       "#bab0ac", "#a0cbe8", "#ffbe7d", "#8cd17d", "#ff9d9a", "#86bcb6", "#f1ce63", "#d4a6c8", "#d7b5a6", "#79706e"];

/** Highlight colours for the districts picked in the filter. */
export const FOCUS = ["#4e79a7", "#e15759", "#59a14f", "#f28e2b", "#b07aa1", "#76b7b2", "#9c755f", "#edc948"];

export const INK = "#1f2937";
export const MUTED = "#6b7280";
export const FAINT = "#d1d5db";
export const NATIONAL = "#111827";

/** Single-colour marks (sparklines, small multiples) and their fills. */
export const ACCENT = "#4a6480";
export const ACCENT_FILL = "#dde3ea";
export const ACCENT_TINT = "#eef1f4";
/** Target lines, and last year's mark where one is drawn beside this year's. */
export const TARGET = "#5b8c5a";
export const PREVIOUS = "#8064a2";
/** Better / worse / neither, for changes. */
export const BETTER = "#4a6480";
export const WORSE = "#b4541f";
export const NEUTRAL = "#a3abb5";

/** Worse → better, six classes. */
export const PERFORMANCE = ["#b4541f", "#da8a5b", "#efc8a7", "#d2dae3", "#8fa3b7", "#4a6480"];
/** Counts, low → high. */
export const QUANTITY = ["#f3f3f2", "#dcdcda", "#bdbdba", "#969693", "#6e6e6b", "#474745"];

/** Items where a lower value is better (by DHIS2 uid). */
const LOWER_IS_BETTER = new Set([
  "ReUHfIn0pTQ", // ANC 1-3 Dropout Rate
  "EdN7qlmI5FS", // Dropout rate Penta 1 - 3
  "d9thHOJMROr", // Dropout rate Penta 1 - Measles
  "joIQbN4L1Ok", // Moderate malnutrition rate
  "vhzPbO1eEyr", // Severe malnutrition rate
  "vKWOc4itBo2", // Weight for height <70% rate
  "nfG18MJZX5o", // Weight for height 70-79% rate
  "tcs5YGnjiKo", // Maternal death rate
  "JIVMtpjVZqJ"  // Diarrhoea <5 y incidence rate
]);

/** "up", "down", or null for counts and plain ratios (factor 1), where neither is better. */
export function direction(item) {
  if (LOWER_IS_BETTER.has(item.dx)) return "down";
  if (item.kind === "data element" || (item.factor ?? 1) === 1) return null;
  return "up";
}

/** Coverage-style breaks for percentages around 0–100; quantile breaks for anything else. */
export function breaksFor(item, values) {
  const vs = values.filter((v) => v != null && Number.isFinite(v)).sort((a, b) => a - b);
  const median = vs[Math.floor(vs.length / 2)] ?? 0;
  if (item.factor === 100 && direction(item) === "up" && median > 25) return [40, 55, 70, 80, 90];
  if (vs.length < 6) return [0.2, 0.4, 0.6, 0.8, 1].map((k) => +(k * (vs.at(-1) ?? 1)).toPrecision(2));
  const q = (p) => vs[Math.min(vs.length - 1, Math.floor(p * vs.length))];
  const b = [q(1 / 6), q(2 / 6), q(3 / 6), q(4 / 6), q(5 / 6)].map((v) => +v.toPrecision(2));
  return b.map((v, i) => (i > 0 && v <= b[i - 1] ? +(b[i - 1] + Math.max(1e-6, Math.abs(b[i - 1]) * 0.01)).toPrecision(3) : v));
}

/** The six colours for an item: worse → better, or a single ramp for counts. */
export function colorsFor(item) {
  const d = direction(item);
  if (d === "up") return PERFORMANCE;
  if (d === "down") return PERFORMANCE.slice().reverse();
  return QUANTITY;
}

/** A Plot colour scale ({type: "threshold"}) for an item over a set of values. */
export function colorScale(item, values) {
  return {type: "threshold", domain: breaksFor(item, values), range: colorsFor(item)};
}

/** A function value → colour for an item over a set of values. */
export function colorOf(item, values) {
  const b = breaksFor(item, values), c = colorsFor(item);
  return (v) => {
    if (v == null) return "#e5e7eb";
    let k = 0;
    while (k < b.length && v >= b[k]) k++;
    return c[k];
  };
}

/** Black or white text on a background colour. */
export function ink(bg) {
  const m = /^#?([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i.exec(bg ?? "");
  if (!m) return INK;
  const [r, g, b] = m.slice(1).map((h) => parseInt(h, 16));
  return 0.299 * r + 0.587 * g + 0.114 * b > 150 ? INK : "#fff";
}

export const fmt = (v, digits = 1) => v == null || !Number.isFinite(+v) ? "–" : Number(v).toLocaleString("en", {maximumFractionDigits: digits});
export const fmtInt = (v) => fmt(v, 0);
/** Large counts as 12.3k / 1.2M. */
export const fmtShort = (v) => {
  if (v == null || !Number.isFinite(+v)) return "–";
  const a = Math.abs(v);
  if (a >= 1e6) return `${fmt(v / 1e6, 1)}M`;
  if (a >= 1e4) return `${fmt(v / 1e3, 0)}k`;
  if (a >= 1e3) return `${fmt(v / 1e3, 1)}k`;
  return fmt(v, a < 10 ? 1 : 0);
};
/** A value with its unit: 61.2% for percentages, 1,204 for counts. */
export function fmtValue(item, v) {
  if (v == null) return "–";
  if (item?.factor === 100) return `${fmt(v)}%`;
  if (item?.factor && item.factor !== 1) return `${fmt(v)} per ${fmtInt(item.factor)}`;
  return fmtShort(v);
}
export const unitOf = (item) => item?.factor === 100 ? "%" : "";
