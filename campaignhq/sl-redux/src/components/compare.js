// The page filter bar, and the district comparison block every page carries: pick one of
// the page's items, then see it mapped, ranked against last year, over time and as a table.
import * as Inputs from "npm:@observablehq/inputs";
import {html} from "npm:htl";
import {unitMap} from "./unit-map.js";
import {DISTRICTS, COUNTRY, periodName, periodDate} from "./data.js";
import {colorsFor, breaksFor, colorOf, direction, fmt, fmtInt, fmtValue, unitOf} from "./theme.js";
import {rank, strip, trend, scaleKey, kpi} from "./viz.js";

/**
 * Year, districts and (optionally) map level, as one form: its value is
 * {year, districts, level} with level 1 (districts) or 2 (chiefdoms).
 */
export function filterBar(years, {level = true, year} = {}) {
  const inputs = {
    year: Inputs.select(years.slice().reverse(), {label: "Year", value: year ?? years.at(-1)}),
    districts: Inputs.checkbox(DISTRICTS, {label: "Districts"}),
    ...(level ? {level: Inputs.radio(new Map([["Districts", 1], ["Chiefdoms", 2]]), {label: "Map by", value: 1})} : {})
  };
  return Inputs.form(inputs, {
    template: (i) => html`<div class="rx-filters">
      <div class="rx-filter-main">${i.year}${i.level ?? ""}<button type="button" class="rx-clear" onclick=${() => {
        for (const box of i.districts.querySelectorAll("input")) box.checked = false;
        i.districts.dispatchEvent(new Event("input", {bubbles: true}));
      }}>All districts</button></div>
      <div class="rx-filter-districts">${i.districts}</div>
    </div>`
  });
}

/** {dx, name, factor, kind} for an item, from its values. */
export function itemOf(all, dx, nameOf = (x) => x) {
  const d = all.find((r) => r.dx === dx);
  return {dx, name: nameOf(dx) ?? d?.name ?? dx, factor: d?.factor ?? 1, kind: d?.kind ?? "indicator"};
}

/**
 * The comparison block. `dxs` the page's items; `F` the filter values; `P` the periods for
 * the year; `state` an object kept across re-renders (remembers the chosen item).
 */
export function explore({all, dxs, nameOf, geojson, F, P, state = {}, width = 900, title = "Compare districts"}) {
  const items = dxs.map((dx) => itemOf(all, dx, nameOf)).filter((it) => all.some((d) => d.dx === it.dx));
  const level = F.level ?? 1;
  const picked = F.districts ?? [];
  const select = Inputs.select(items, {label: "Indicator", format: (it) => it.name,
    value: items.find((it) => it.dx === state.dx) ?? items[0]});
  const stats = html`<div class="rx-stats"></div>`;
  const map = unitMap({geojson, height: 330});
  const right = html`<div></div>`;
  const below = html`<div></div>`;
  const table = html`<div></div>`;
  const half = width >= 760 ? Math.floor((width - 16) / 2) - 2 : width;

  function render() {
    const item = select.value;
    state.dx = item.dx;
    const rowsOf = (period, lvl) => all.filter((d) => d.dx === item.dx && d.period === period && d.admin_level === lvl
      && (!picked.length || lvl === 0 || picked.includes(d.district)));
    const now = rowsOf(P.year, level);
    const prev = new Map(rowsOf(P.prevYear, level).map((d) => [d.location_id, d.value]));
    const nat = all.find((d) => d.dx === item.dx && d.period === P.year && d.admin_level === 0)?.value;
    const natPrev = all.find((d) => d.dx === item.dx && d.period === P.prevYear && d.admin_level === 0)?.value;
    // Colour classes from every unit at this level, so filtering does not change the colours.
    const scaleValues = all.filter((d) => d.dx === item.dx && d.period === P.year && d.admin_level === level).map((d) => d.value);
    const sorted = now.filter((d) => d.value != null).sort((a, b) => direction(item) === "down" ? a.value - b.value : b.value - a.value);
    const best = sorted[0], worst = sorted.at(-1);
    const unitWord = level === 1 ? "district" : "chiefdom";
    const ranked = direction(item) != null;
    const deltaClass = (dlt) => !ranked ? "" : (dlt >= 0) === (direction(item) !== "down") ? "up" : "down";
    const delta = nat != null && natPrev != null ? nat - natPrev : null;
    stats.replaceChildren(
      html`<div><span>${COUNTRY} ${P.year}</span><b>${fmtValue(item, nat)}</b>${delta != null ? html`<em class=${deltaClass(delta)}>${delta >= 0 ? "▲" : "▼"} ${fmt(Math.abs(delta))}${item.factor === 100 ? " pts" : ""} on ${P.prevYear}</em>` : html`<em></em>`}</div>`,
      html`<div><span>${ranked ? "Best" : "Highest"} ${unitWord}</span><b>${fmtValue(item, best?.value)}</b><em>${best?.location_name ?? ""}</em></div>`,
      html`<div><span>${ranked ? "Worst" : "Lowest"} ${unitWord}</span><b>${fmtValue(item, worst?.value)}</b><em>${worst?.location_name ?? ""}</em></div>`,
      html`<div><span>${ranked ? "Gap, best to worst" : "Range"}</span><b>${best && worst ? fmtValue(item, Math.abs(best.value - worst.value)) : "–"}</b><em>${sorted.length} ${unitWord}s${picked.length ? " in the picked districts" : ""}</em></div>`,
      html`<div class="rx-stats-key">${scaleKey(item, scaleValues)}</div>`);

    const byId = new Map(now.map((d) => [d.location_id, d]));
    map.update({
      level, values: new Map(now.map((d) => [d.location_id, d.value])),
      stops: breaksFor(item, scaleValues), colors: colorsFor(item),
      legend: [`${item.name}, ${P.year}`, (v) => `${fmt(v)}${unitOf(item)}`],
      popup: (id) => {
        const d = byId.get(id);
        if (!d) return picked.length ? "not in the picked districts" : "no value";
        const p = prev.get(id);
        return `${fmtValue(item, d.value)}${p != null ? ` <span style="color:#6b7280">(last year ${fmtValue(item, p)})</span>` : ""}` +
          (d.denominator != null ? `<br>${fmtInt(d.numerator)} ÷ ${fmtInt(d.denominator)}` : "");
      },
      points: [], outline: 1,
      // Zoom to the picked districts.
      fitIds: picked.length ? all.filter((d) => d.admin_level === 1 && picked.includes(d.location_name)).map((d) => d.location_id) : null
    });

    if (level === 1) {
      right.replaceChildren(html`<div class="rx-sub">Ranked, ${P.year} (dot) against ${P.prevYear} (ring); dashed line is ${COUNTRY}</div>`,
        rank(now.map((d) => ({name: d.location_name, value: d.value, prev: prev.get(d.location_id), numerator: d.numerator, denominator: d.denominator})),
          {item, national: nat, focus: picked, width: half, scaleValues}));
    } else {
      const districtValues = new Map(all.filter((d) => d.dx === item.dx && d.period === P.year && d.admin_level === 1).map((d) => [d.location_name, d.value]));
      right.replaceChildren(html`<div class="rx-sub">Each chiefdom as a dot in its district's row; the black tick is the district, dashed line ${COUNTRY}</div>`,
        strip(now.map((d) => ({name: d.location_name, group: d.district, value: d.value})),
          {item, groupValues: districtValues, national: nat, width: half, scaleValues}));
    }

    // Over time: months when the item has them, else years. Districts only (chiefdoms are too many).
    const months = P.months.filter((p) => all.some((d) => d.dx === item.dx && d.period === p));
    const span = months.length >= 6 ? months : P.years;
    const series = all.filter((d) => d.dx === item.dx && span.includes(d.period) && (d.admin_level === 0 || d.admin_level === 1)
      && (!picked.length || d.admin_level === 0 || picked.includes(d.location_name)))
      .map((d) => ({name: d.location_name, level: d.admin_level, period: d.period, date: periodDate(d.period), value: d.value}));
    below.replaceChildren(html`<div class="rx-sub">${span === months ? "Monthly" : "Yearly"}: ${COUNTRY} in black, ${picked.length ? "the picked districts in colour" : "the range across districts in grey"}${item.factor === 100 && span === months ? "; monthly values of annualised indicators are scaled to a year" : ""}</div>`,
      trend(series, {item, focus: picked, width, height: 190, xFormat: span === months ? (d) => d.toLocaleString("en", {month: "short", year: "2-digit", timeZone: "UTC"}) : (d) => String(d.getUTCFullYear())}));

    const tableRows = now.map((d) => ({place: d.location_name, district: d.district, value: d.value, prev: prev.get(d.location_id),
      change: d.value != null && prev.get(d.location_id) != null ? d.value - prev.get(d.location_id) : null, numerator: d.numerator, denominator: d.denominator}))
      .sort((a, b) => (b.value ?? -Infinity) - (a.value ?? -Infinity));
    const color = colorOf(item, scaleValues);
    table.replaceChildren(Inputs.table(tableRows, {
      columns: ["place", ...(level === 2 ? ["district"] : []), "value", "prev", "change", "numerator", "denominator"],
      header: {place: level === 1 ? "District" : "Chiefdom", district: "District", value: P.year, prev: P.prevYear, change: "Change", numerator: "Numerator", denominator: "Denominator"},
      format: {
        value: (v) => html`<span class="rx-cell" style="background:${color(v)}"></span>${fmtValue(item, v)}`,
        prev: (v) => fmtValue(item, v), change: (v) => v == null ? "–" : `${v > 0 ? "+" : ""}${fmt(v)}`,
        numerator: fmtInt, denominator: fmtInt
      },
      rows: 12, width: {place: 160}
    }));
  }

  select.addEventListener("input", render);
  render();
  return html`<section class="rx-panel rx-explore">
    <header class="rx-explore-head"><h3>${title}</h3>${select}</header>
    ${stats}
    <div class="rx-two"><div class="rx-map">${map}</div><div>${right}</div></div>
    <div>${below}</div>
    <details class="rx-table"><summary>Table: every ${level === 1 ? "district" : "chiefdom"}, ${P.year} and ${P.prevYear}</summary>${table}</details>
  </section>`;
}

/**
 * Headline figures for the page's main items: the year's value, the change on last year and
 * the last 12 months as a sparkline. For the country, or for the one district picked.
 */
export function headline({all, dxs, nameOf, F, P}) {
  const place = F.districts?.length === 1 ? F.districts[0] : COUNTRY;
  const level = place === COUNTRY ? 0 : 1;
  const cards = dxs.map((dx) => {
    const item = itemOf(all, dx, nameOf);
    const mine = all.filter((d) => d.dx === dx && d.admin_level === level && d.location_name === place);
    const at = (p) => mine.find((d) => d.period === p)?.value;
    const months = P.last12Months.filter((p) => mine.some((d) => d.period === p));
    const span = months.length >= 4 ? months : P.years.slice(-10);
    const spark = span.map((p) => ({date: periodDate(p), value: at(p)})).filter((s) => s.value != null);
    return kpi({item, value: at(P.year), prev: at(P.prevYear), prevLabel: P.prevYear, spark,
                sub: span === months ? "· 12 months" : "· 10 years"});
  });
  return html`<div class="rx-kpis">${cards}</div>
    <div class="rx-sub" style="margin-top:4px">${place}, ${P.year}${place === COUNTRY && F.districts?.length > 1 ? " (pick one district to see its figures here)" : ""}</div>`;
}
