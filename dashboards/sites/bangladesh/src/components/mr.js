// What every bd-mr page needs: the MR values, sums of counts over periods, and coverage
// worked out from summed counts (never by adding or averaging percentages).
import {rows} from "./dhis2.js";

/** DHIS2 uids of the MR dashboard items. */
export const DX = {
  target: "WaAXoj3iiRv", // Total Target (School + Community)
  vaccinated: "shuuDNWGVBo", // Total Vaccinated (School + Community)
  coverage: "wzJjkgmTUT3", // MR vaccination coverage
  targetCommunity: "Fx7pAfcLplg", // Target-Community (data element, by age and sex)
  vaccinatedCommunity: "IIu9d1VChct", // Vaccinated-Community
  targetSchool: "HW5CX4imcl7",
  vaccinatedSchool: "bnkGkYXRKmo"
};

/** The age bands the MR dashboards show, as [label, target uid, vaccinated uid]. */
export const AGES = [
  ["6 months", "BZfdU6I3kyS", "e5K53nJmgZI"], ["9 months", "rayGki8k3uS", "BNPmwD7A0KU"],
  ["1 year", "ZmfFR6ieSHg", "PLsyc7XfCYo"], ["2 yrs", "Kpare6r9iOo", "HI60r3MmQXp"],
  ["3 yrs", "hNfw30LP2Mo", "KzxNWLA3tiV"], ["4 yrs", "YWw2jx6x28W", "UuWCWnBJwHw"],
  ["5 yrs", "BAE0PUEssXO", "rU2M3Ugvpcc"], ["6 yrs", "yZvjzpXWWQM", "mTa8VC1wMpN"],
  ["7 yrs", "rm5ZM4PAyNb", "IlRTcwnOZaz"], ["8 yrs", "cPxiCgJcNo8", "Jg1nM22V2bM"],
  ["9 yrs", "LQzbomQ307t", "v99mSvDPiUx"], ["10 yrs", "WUVgynXu3dx", "A07uEL9U3Nu"],
  ["11 yrs", "O9ZfMazfbOZ", "NyMJBJiyepK"], ["12 yrs", "FK3YTjJZ6H4", "lww9Ifk9e9z"],
  ["13 yrs", "j68oDWwX3nk", "GF2w6mJiuG2"], ["14 yrs", "SWkQWpkkQjT", "U9RImiEvbDb"]
];

export const COUNTRY_ID = "bgd-I9x3B8oQvZH";
export const CAMPAIGN = {start: "2026-04-05", end: "2026-05-20", period: "2026-04-05/2026-05-20"};

const list = (xs) => xs.map((x) => `'${String(x).replace(/'/g, "''")}'`).join(",");

/** Every value of the given uids (needs `values: data/values.parquet` in the page's sql). */
export async function load(sql, uids) {
  return rows(await sql([`SELECT * FROM "values" WHERE dx IN (${list(uids)})`]));
}

/** The sex breakdown of the given uids (needs `strata: data/strata.parquet`). */
export async function loadStrata(sql, uids) {
  return rows(await sql([`SELECT * FROM strata WHERE dx IN (${list(uids)})`]));
}

/** A count: the value of a count item (DHIS2 "One" indicators and data elements). */
export const countOf = (d) => d?.count ?? d?.numerator ?? d?.value ?? null;

/** Sum of a count item over rows (periods or places), null when there are none. */
export function total(rs) {
  const xs = rs.map(countOf).filter((v) => v != null);
  return xs.length ? xs.reduce((a, b) => a + b, 0) : null;
}

/** Coverage in % from summed counts. */
export const coverage = (vaccinated, target) => (vaccinated != null && target ? (100 * vaccinated) / target : null);

/** The daily periods of the campaign that have values, in order, as {period, date, label}. */
export function campaignDays(all) {
  return Array.from(new Set(all.filter((d) => d.period_type === "Daily").map((d) => d.period))).sort()
    .map((p) => ({period: p, date: `${p.slice(0, 4)}-${p.slice(4, 6)}-${p.slice(6)}`, label: `${p.slice(0, 4)}-${p.slice(4, 6)}-${p.slice(6)}`}));
}

/** Index rows by dx, location id and period. */
export function index(all) {
  const m = new Map();
  for (const d of all) m.set(`${d.dx}|${d.location_id}|${d.period}`, d);
  return (dx, location_id, period) => m.get(`${dx}|${location_id}|${period}`);
}

/** ISO week code (2026W17) for a date string. */
export function isoWeek(date) {
  const d = new Date(`${date}T00:00:00Z`);
  const day = (d.getUTCDay() + 6) % 7;
  d.setUTCDate(d.getUTCDate() - day + 3);
  const first = new Date(Date.UTC(d.getUTCFullYear(), 0, 4));
  const week = 1 + Math.round(((d - first) / 86400000 - 3 + ((first.getUTCDay() + 6) % 7)) / 7);
  return `${d.getUTCFullYear()}W${week}`;
}

/** Index the sex breakdown by dx, location id, period and sex ("Female" / "Male"). */
export function indexStrata(strata) {
  const m = new Map();
  for (const d of strata) m.set(`${d.dx}|${d.location_id}|${d.period}|${d.sex}`, d);
  return (dx, location_id, period, sex) => m.get(`${dx}|${location_id}|${period}|${sex}`);
}

/** The places of one district at upazila level (upazilas, municipalities), sorted by name. */
export function placesIn(all, district) {
  return Array.from(new Map(all.filter((d) => d.level === 4 && d.district === district && d.place_kind !== "other")
    .map((d) => [d.location_id, d])).values()).sort((a, b) => a.location_name.localeCompare(b.location_name));
}

/** One place by exact name. */
export const placeNamed = (all, name) => all.find((d) => d.location_name === name);

/** Daily periods from `from` to `to` (YYYYMMDD) that have values. */
export const daysBetween = (all, from, to) => campaignDays(all).filter((d) => d.period >= from && d.period <= to);
