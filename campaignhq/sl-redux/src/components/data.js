// Loading and slicing the DHIS2 values: the same tables and indicators as sldash, read
// through DuckDB-WASM, plus the periods and places the filters work on.

/** Arrow table or array → plain objects with numbers (not BigInt). */
export function rows(table) {
  return Array.from(table, (r) => {
    const o = typeof r.toJSON === "function" ? r.toJSON() : {...r};
    for (const k in o) if (typeof o[k] === "bigint") o[k] = Number(o[k]);
    return o;
  });
}

const list = (uids) => uids.map((u) => `'${String(u).replace(/'/g, "''")}'`).join(",");

/** Every value of the given DHIS2 uids (the page's sql needs `values: data/values.parquet`). */
export async function load(sql, uids) {
  return rows(await sql([`SELECT * FROM "values" WHERE dx IN (${list(uids)})`]));
}

/** Breakdowns of the given uids by one dimension (needs `strata: data/strata.parquet`). */
export async function loadStrata(sql, uids, dimension) {
  return rows(await sql([`SELECT * FROM strata WHERE dx IN (${list(uids)}) AND dimension = '${dimension}'`]));
}

/** The DHIS2 breakdown dimensions. */
export const DIM = {fixedOutreach: "fMZEcRHuamy", facilityType: "J5jldMd8OHv"};
export const COUNTRY_ID = "sle-ImspTQPwCqd";
export const COUNTRY = "Sierra Leone";

/** The 13 districts. */
export const DISTRICTS = ["Bo", "Bombali", "Bonthe", "Kailahun", "Kambia", "Kenema", "Koinadugu", "Kono", "Moyamba",
                          "Port Loko", "Pujehun", "Tonkolili", "Western Area"];

const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

/** 202603 → Mar 2026, 2026Q1 → Q1 2026, 2026S1 → Jan–Jun 2026. */
export function periodName(p, {short = false} = {}) {
  if (p == null) return "";
  if (/^\d{6}$/.test(p)) return short ? MONTHS[Number(p.slice(4)) - 1] : `${MONTHS[Number(p.slice(4)) - 1]} ${p.slice(0, 4)}`;
  const q = /^(\d{4})Q([1-4])$/.exec(p);
  if (q) return `Q${q[2]} ${q[1]}`;
  const s = /^(\d{4})S([12])$/.exec(p);
  if (s) return `${s[2] === "1" ? "Jan–Jun" : "Jul–Dec"} ${s[1]}`;
  return p;
}

/** The first day of a period, as a Date (for time axes). */
export function periodDate(p) {
  if (/^\d{6}$/.test(p)) return new Date(Date.UTC(+p.slice(0, 4), +p.slice(4) - 1, 1));
  const q = /^(\d{4})Q([1-4])$/.exec(p);
  if (q) return new Date(Date.UTC(+q[1], (q[2] - 1) * 3, 1));
  const s = /^(\d{4})S([12])$/.exec(p);
  if (s) return new Date(Date.UTC(+s[1], s[2] === "1" ? 0 : 6, 1));
  return new Date(Date.UTC(+p, 0, 1));
}

/**
 * The periods a page works with, for a chosen year. The demo holds values for months that
 * have not happened yet, so month and quarter lists stop at the last complete one.
 */
export function periods(all, year, today = new Date()) {
  const have = (type) => Array.from(new Set(all.filter((d) => d.period_type === type).map((d) => d.period))).sort();
  const y = String(year);
  const m = today.getMonth();
  const lastMonth = m === 0 ? `${today.getFullYear() - 1}12` : `${today.getFullYear()}${String(m).padStart(2, "0")}`;
  const q = Math.floor(m / 3);
  const lastQuarter = q === 0 ? `${today.getFullYear() - 1}Q4` : `${today.getFullYear()}Q${q}`;
  const months = have("Monthly").filter((p) => p.slice(0, 4) <= y && p <= lastMonth);
  const quarters = have("Quarterly").filter((p) => p.slice(0, 4) <= y && p <= lastQuarter);
  const halves = have("SixMonthly").filter((p) => p.slice(0, 4) <= y && p <= (m >= 6 ? `${today.getFullYear()}S1` : `${today.getFullYear() - 1}S2`));
  return {
    year: y,
    prevYear: String(year - 1),
    years: have("Yearly").filter((p) => p <= y),
    months,
    last12Months: months.slice(-12),
    monthsThisYear: months.filter((p) => p.startsWith(y)),
    monthsLastYear: have("Monthly").filter((p) => p.startsWith(String(year - 1))),
    lastMonth: months.at(-1),
    last4Quarters: quarters.slice(-4),
    lastQuarter: quarters.at(-1),
    lastHalf: halves.at(-1),
    last2Halves: halves.slice(-2)
  };
}

/** Years with values, newest last. */
export function yearsOf(all) {
  return Array.from(new Set(all.filter((d) => d.period_type === "Yearly").map((d) => d.period))).sort();
}

/**
 * Values of one or more items. `level` 0 country, 1 district, 2 chiefdom, "facility" for
 * facilities; `periods` period codes; `districts` keeps districts (and chiefdoms and
 * facilities) in those districts — an empty list keeps all.
 */
export function pick(all, {dx, level, periods: ps, districts}) {
  const dxs = new Set([].concat(dx));
  const pset = ps ? new Set([].concat(ps)) : null;
  const dset = districts?.length ? new Set(districts) : null;
  return all.filter((d) => dxs.has(d.dx)
    && (level == null || (level === "facility" ? d.admin_level == null : d.admin_level === level))
    && (!pset || pset.has(d.period))
    && (!dset || d.admin_level === 0 || dset.has(d.district)));
}

/** One value: the item at one place (by name or id) and period. */
export function valueAt(all, dx, period, place = COUNTRY) {
  return all.find((d) => d.dx === dx && d.period === period && (d.location_name === place || d.location_id === place))?.value;
}

/** Breakdown rows for one place and period (or periods). */
export function pickStrata(strata, {dx, location_id, periods: ps}) {
  const dxs = new Set([].concat(dx));
  const pset = ps ? new Set([].concat(ps)) : null;
  return strata.filter((d) => dxs.has(d.dx) && (!location_id || d.location_id === location_id) && (!pset || pset.has(d.period)));
}

/** Location id → district name, for the country and the 13 districts. */
export function districtIds(all) {
  const m = new Map();
  for (const d of all) if (d.admin_level === 1 || d.admin_level === 0) m.set(d.location_id, d.location_name);
  return m;
}

/** An item's display name, from its values (or a fallback map). */
export function namer(all, fallback = {}) {
  const names = new Map();
  for (const d of all) if (!names.has(d.dx)) names.set(d.dx, d.name);
  return (dx) => fallback[dx] ?? names.get(dx) ?? dx;
}

/** Month by month, an item at a place this year and the same month last year: {month, now, before}. */
export function monthPairs(all, dx, P, place = COUNTRY) {
  return P.monthsThisYear.filter((p) => P.months.includes(p)).map((p) => {
    const lastP = `${+p.slice(0, 4) - 1}${p.slice(4)}`;
    const at = (q) => all.find((d) => d.dx === dx && d.period === q && d.location_name === place)?.value;
    return {month: periodName(p, {short: true}), now: at(p), before: at(lastP)};
  });
}

/** The place the page's single-place charts show: the one picked district, else the country. */
export const placeOf = (F) => F.districts?.length === 1 ? F.districts[0] : COUNTRY;
