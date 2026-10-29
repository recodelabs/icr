// Labels and formatting shared by the DIGIT demo pages.
import * as d3 from "npm:d3";
import * as Inputs from "npm:@observablehq/inputs";

export const CAMPAIGN_TYPES = {
  "smc": "Seasonal malaria chemoprevention",
  "itn-distribution": "Bednet (ITN) distribution",
  "vaccination-sia": "Vaccination campaign",
  "mda": "Mass drug administration",
  "integrated": "Integrated (co-delivery)",
  "irs": "Indoor residual spraying"
};
export const typeLabel = (t) => CAMPAIGN_TYPES[t] ?? t ?? "other";

// The country selector shared by the overview and the delivery page. `country` is on every
// campaign row (data/campaigns.parquet.sh derives it from the campaign's DIGIT hierarchy).
export function countryInput(umbrellas, {value = "All"} = {}) {
  const counts = d3.rollup(umbrellas, (v) => v.length, (d) => d.country ?? "Unknown");
  const countries = [...counts.keys()].sort((a, b) => (a === "Unknown") - (b === "Unknown") || d3.descending(counts.get(a), counts.get(b)));
  return Inputs.select(["All", ...countries], {label: "Country", value,
    format: (c) => c === "All" ? `All countries (${umbrellas.length})` : `${c} (${counts.get(c)})`});
}
export const inCountry = (country) => (d) => country === "All" || (d.country ?? "Unknown") === country;

export const toRows =(table) => Array.from(table, (r) => {
  const o = typeof r.toJSON === "function" ? r.toJSON() : {...r};
  for (const k in o) if (typeof o[k] === "bigint") o[k] = Number(o[k]);
  return o;
});
export const fmtInt = (n) => n == null ? "—" : Math.round(Number(n)).toLocaleString("en");
export const fmtPct = (x, digits = 0) => x == null || !isFinite(x) ? "—" : `${(x * 100).toFixed(digits)}%`;
// DIGIT's demo server keeps time in India Standard Time: a campaign that starts on 28 October has
// period.start 2026-10-27T18:30:00Z. Show calendar days in that zone. (A date-only value written as
// UTC midnight stays on its own day there too.)
const dayFormat = new Intl.DateTimeFormat("en-CA", {timeZone: "Asia/Kolkata", year: "numeric", month: "2-digit", day: "2-digit"});
export const fmtDay = (d) => d == null ? "" : dayFormat.format(new Date(d));
