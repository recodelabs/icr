// The DHIS2 dashboard look, rebuilt with Plot and d3: the series palette, the
// "Immunization Coverage" legend set, and the item types Plot has no mark for
// (gauge, pie, pivot table with legend colours).
import * as d3 from "npm:d3";
import {html, svg} from "npm:htl";

/** DHIS2's default chart series colours, in order. */
export const PALETTE = ["#a8bf24", "#518cc3", "#d74554", "#ff9e21", "#968f8f", "#ba3ba1", "#ffda54", "#45e7a6",
                        "#b98037", "#76a6cc", "#c95c8d", "#9ccc65", "#6a5acd", "#f08080"];

/** The demo's "Immunization Coverage" legend set (used on its coverage tables and maps). */
export const COVERAGE_LEGEND = [
  {name: "Low", start: 0, end: 40, color: "#FF0000"},
  {name: "Low Plus", start: 40, end: 55, color: "#FF6600"},
  {name: "Medium", start: 55, end: 70, color: "#FF9900"},
  {name: "Medium Plus", start: 70, end: 80, color: "#FFFF00"},
  {name: "Good", start: 80, end: 90, color: "#99CC00"},
  {name: "High", start: 90, end: 120, color: "#00FF00"},
  {name: "Invalid", start: 120, end: 1000, color: "#CCCCCC"}
];

/** DHIS2 Maps' default thematic scale (five classes, yellow to brown). */
export const MAP_CLASSES = ["#ffffd4", "#fed98e", "#fe9929", "#d95f0e", "#993404"];

export function legendColor(v, legend = COVERAGE_LEGEND) {
  if (v == null) return null;
  return (legend.find((l) => v >= l.start && v < l.end) ?? legend.at(-1)).color;
}

/** Black or white text for a background colour. */
function ink(bg) {
  const c = d3.color(bg);
  if (!c) return "#111";
  const {r, g, b} = c.rgb();
  return 0.299 * r + 0.587 * g + 0.114 * b > 150 ? "#111" : "#fff";
}

export const fmt = (v, digits = 1) => v == null ? "" : Number(v).toLocaleString("en", {maximumFractionDigits: digits});

/** Arrow table or array → plain objects with numbers (not BigInt). */
export function rows(table) {
  return Array.from(table, (r) => {
    const o = typeof r.toJSON === "function" ? r.toJSON() : {...r};
    for (const k in o) if (typeof o[k] === "bigint") o[k] = Number(o[k]);
    return o;
  });
}

/** A dashboard item: title bar over its content, like a DHIS2 dashboard card. */
export function item(title, content, {note} = {}) {
  return html`<div class="d2-item">
    <div class="d2-title">${title}</div>
    <div class="d2-body">${content}</div>
    ${note ? html`<div class="d2-note">${note}</div>` : ""}
  </div>`;
}

/** Semicircle gauge, 0 → max, with the value in the middle (DHIS2 GAUGE). */
export function gauge(value, {max = 100, label = "", width = 300, legend = COVERAGE_LEGEND} = {}) {
  const h = width * 0.62, r = width * 0.42, cx = width / 2, cy = h - 20;
  const arc = d3.arc().innerRadius(r * 0.62).outerRadius(r);
  const angle = d3.scaleLinear([0, max], [-Math.PI / 2, Math.PI / 2]).clamp(true);
  const fill = legendColor(value, legend) ?? "#a8bf24";
  const dial = svg`<svg width=${width} height=${h} viewBox="0 0 ${width} ${h}" style="max-width:100%">
    <g transform="translate(${cx},${cy})">
      <path d=${arc({startAngle: -Math.PI / 2, endAngle: Math.PI / 2})} fill="#eef0f3"></path>
      ${value == null ? "" : svg`<path d=${arc({startAngle: -Math.PI / 2, endAngle: angle(value)})} fill=${fill}></path>`}
      <text text-anchor="middle" y="-6" style="font:600 26px system-ui">${value == null ? "—" : `${fmt(value)}`}</text>
      <text text-anchor="middle" x=${-r * 0.81} y="16" style="font:11px system-ui;fill:#64748b">0</text>
      <text text-anchor="middle" x=${r * 0.81} y="16" style="font:11px system-ui;fill:#64748b">${max}</text>
    </g>
  </svg>`;
  return html`<div style="display:inline-flex;flex-direction:column;align-items:center;max-width:${width}px">${dial}
    <div style="font:12px/1.3 system-ui;color:#475569;text-align:center;margin-top:-6px">${label}</div></div>`;
}

/** Pie with a legend of name, value and share (DHIS2 PIE). */
export function pie(data, {width = 320, colors = PALETTE} = {}) {
  const items = data.filter((d) => d.value > 0);
  const total = d3.sum(items, (d) => d.value);
  const size = Math.min(width, 260), r = size / 2 - 4;
  const arcs = d3.pie().sort(null).value((d) => d.value)(items);
  const arc = d3.arc().innerRadius(0).outerRadius(r);
  return html`<div style="display:flex;flex-wrap:wrap;gap:16px;align-items:center">
    ${svg`<svg width=${size} height=${size} viewBox="${-size / 2} ${-size / 2} ${size} ${size}">
      ${arcs.map((a, i) => svg`<path d=${arc(a)} fill=${colors[i % colors.length]} stroke="#fff"><title>${a.data.name}: ${fmt(a.data.value, 0)} (${fmt((100 * a.data.value) / total)}%)</title></path>`)}
    </svg>`}
    <div style="font:12px system-ui;line-height:1.7">
      ${arcs.map((a, i) => html`<div><span style="display:inline-block;width:11px;height:11px;background:${colors[i % colors.length]};margin-right:6px;vertical-align:-1px"></span>${a.data.name}: <b>${fmt(a.data.value, 0)}</b> <span style="color:#64748b">(${fmt((100 * a.data.value) / total)}%)</span></div>`)}
    </div>
  </div>`;
}

/**
 * Pivot table: one row per `row(d)`, one column per `col(d)`, cells coloured by the
 * legend set when `legend` is given (DHIS2 PIVOT_TABLE with "use legend colours").
 */
export function pivot(data, {row, col, value = (d) => d.value, rowOrder, colOrder, legend, digits = 1, rowLabel = ""}) {
  const rowsKeys = rowOrder ?? Array.from(new Set(data.map(row)));
  const cols = colOrder ?? Array.from(new Set(data.map(col)));
  const cell = new Map(data.map((d) => [`${row(d)}\u0000${col(d)}`, value(d)]));
  return html`<div class="d2-pivot"><table>
    <thead><tr><th>${rowLabel}</th>${cols.map((c) => html`<th>${c}</th>`)}</tr></thead>
    <tbody>${rowsKeys.map((r) => html`<tr><th>${r}</th>${cols.map((c) => {
      const v = cell.get(`${r}\u0000${c}`);
      const bg = legend ? legendColor(v, legend) : null;
      return html`<td style=${bg ? `background:${bg};color:${ink(bg)}` : ""}>${fmt(v, digits)}</td>`;
    })}</tr>`)}</tbody>
  </table></div>`;
}

/** Legend set as a row of swatches. */
export function legendKey(legend = COVERAGE_LEGEND) {
  return html`<div style="display:flex;flex-wrap:wrap;gap:10px;font:11px system-ui;color:#475569;margin-top:6px">
    ${legend.map((l) => html`<span><span style="display:inline-block;width:11px;height:11px;background:${l.color};border:1px solid #cbd5e1;margin-right:4px;vertical-align:-1px"></span>${l.name} ${l.start}–${l.end === 1000 ? "" : l.end}</span>`)}
  </div>`;
}
