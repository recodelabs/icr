// What every sldash page needs: its DHIS2 items' values, a pick() over them, and the
// relative periods DHIS2 dashboards use (this year, last 10 years, last 12 months, …),
// anchored on a chosen year instead of today.
import {rows} from "./dhis2.js";

const list = (uids) => uids.map((u) => `'${String(u).replace(/'/g, "''")}'`).join(",");

/** Every value of the given DHIS2 uids (needs `values: data/values.parquet` in the page's sql). */
export async function load(sql, uids) {
  return rows(await sql([`SELECT * FROM "values" WHERE dx IN (${list(uids)})`]));
}

/**
 * Every breakdown of the given DHIS2 uids by one dimension (needs `strata: data/strata.parquet`):
 * rows {dx, location_id, period, dimension, option, option_name, numerator, denominator, value}.
 */
export async function loadStrata(sql, uids, dimension) {
  return rows(await sql([`SELECT * FROM strata WHERE dx IN (${list(uids)}) AND dimension = '${dimension}'`]));
}

/** Breakdown rows for one place and period (or periods). */
export function pickStrata(strata, {dx, location_id, periods}) {
  const dxs = new Set([].concat(dx));
  const ps = periods ? new Set(periods) : null;
  return strata.filter((d) => dxs.has(d.dx) && (!location_id || d.location_id === location_id) && (!ps || ps.has(d.period)));
}

/** The DHIS2 breakdown dimensions the dashboards use. */
export const DIM = {fixedOutreach: "fMZEcRHuamy", facilityType: "J5jldMd8OHv"};
/** Location ids of the country and the districts by name. */
export const COUNTRY_ID = "sle-ImspTQPwCqd";

/**
 * Values of one or more items: `level` 0 country, 1 district, 2 chiefdom; `periods` a list of
 * period codes; `places` a list of names (districts, or for chiefdoms their district names
 * via `inDistricts`).
 */
export function pick(all, {dx, level, periods, places, inDistricts}) {
  const dxs = new Set([].concat(dx));
  const ps = periods ? new Set(periods) : null;
  const pl = places ? new Set(places) : null;
  const ds = inDistricts ? new Set(inDistricts) : null;
  return all.filter((d) => dxs.has(d.dx) && (level == null || d.admin_level === level) && (!ps || ps.has(d.period))
    && (!pl || pl.has(d.location_name)) && (!ds || ds.has(d.district)));
}

/** DHIS2's relative periods, relative to `year` (DHIS2's "this year"). */
export function relative(all, year, today = new Date()) {
  const have = (type) => Array.from(new Set(all.filter((d) => d.period_type === type).map((d) => d.period))).sort();
  const y = String(year);
  // DHIS2 counts "last 12 months" and "last 4 quarters" back from today and leaves out the
  // month and quarter in progress; the demo also holds values for future months.
  const m = today.getMonth(); // 0-based: the current month is in progress
  const lastMonth = m === 0 ? `${today.getFullYear() - 1}12` : `${today.getFullYear()}${String(m).padStart(2, "0")}`;
  const q = Math.floor(m / 3); // quarters complete this year
  const lastQuarter = q === 0 ? `${today.getFullYear() - 1}Q4` : `${today.getFullYear()}Q${q}`;
  const months = have("Monthly").filter((p) => p.slice(0, 4) <= y && p <= lastMonth);
  const quarters = have("Quarterly").filter((p) => p.slice(0, 4) <= y && p <= lastQuarter);
  return {
    thisYear: y,
    lastYear: String(year - 1),
    last10Years: Array.from({length: 10}, (_, i) => String(year - 10 + i)),
    monthsThisYear: have("Monthly").filter((p) => p.startsWith(y)),
    monthsLastYear: have("Monthly").filter((p) => p.startsWith(String(year - 1))),
    last12Months: months.slice(-12),
    lastMonth: months.at(-1),
    // The month in progress, when this year is the current year (DHIS2's "this month").
    thisMonth: y === String(today.getFullYear()) ? `${y}${String(m + 1).padStart(2, "0")}` : months.at(-1),
    last4Quarters: quarters.slice(-4),
    lastQuarter: quarters.at(-1),
    thisQuarter: y === String(today.getFullYear()) ? `${y}Q${q + 1}` : quarters.at(-1),
    quartersThisYear: have("Quarterly").filter((p) => p.startsWith(y)),
    // Half-years: S1 Jan–Jun, S2 Jul–Dec. "Last six-month" is the last complete one.
    lastSixMonth: have("SixMonthly").filter((p) => p.slice(0, 4) <= y && p <= (m >= 6 ? `${today.getFullYear()}S1` : `${today.getFullYear() - 1}S2`)).at(-1),
    last2SixMonths: have("SixMonthly").filter((p) => p.slice(0, 4) <= y && p <= (m >= 6 ? `${today.getFullYear()}S1` : `${today.getFullYear() - 1}S2`)).slice(-2)
  };
}

/** The 13 districts in DHIS2's order. */
export const DISTRICTS = ["Bo", "Bombali", "Bonthe", "Kailahun", "Kambia", "Kenema", "Koinadugu", "Kono", "Moyamba",
                          "Port Loko", "Pujehun", "Tonkolili", "Western Area"];
