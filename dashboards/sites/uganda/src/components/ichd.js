// The October 2026 ICHD round: its six activities in the order of the protocol, with the labels
// the pages use, and the shared formatting helpers.

export const ACTIVITIES = [
  {key: "uga-ichd-catch-up", short: "Catch-up", label: "Catch-up vaccination, under 1"},
  {key: "uga-ichd-mr2", short: "MR2", label: "Measles-rubella, second dose (MR2)"},
  {key: "uga-ichd-deworming", short: "Deworming", label: "Deworming"},
  {key: "uga-ichd-vitamin-a", short: "Vitamin A", label: "Vitamin A supplementation"},
  {key: "uga-ichd-hpv", short: "HPV", label: "HPV vaccine"},
  {key: "uga-ichd-td", short: "Td2+", label: "Tetanus-diphtheria (Td2+)"}
];
export const ACTIVITY = new Map(ACTIVITIES.map((a) => [a.key, a]));

export const STRATEGIES = {"fixed-post": "Fixed post", "temporary-post": "Outreach post", "school": "School", "mobile": "Mobile team", "house-to-house": "House-to-house"};

export const toRows = (table) => Array.from(table, (r) => {
  const o = typeof r.toJSON === "function" ? r.toJSON() : {...r};
  for (const k in o) if (typeof o[k] === "bigint") o[k] = Number(o[k]);
  return o;
});
export const fmtInt = (n) => n == null ? "—" : Math.round(Number(n)).toLocaleString("en");
export const fmtPct = (x, digits = 0) => x == null ? "—" : `${(x * 100).toFixed(digits)}%`;
export const fmtCompact = (n) => n == null ? "—" : n >= 1e6 ? `${(n / 1e6).toFixed(n >= 1e7 ? 1 : 2)}M` : n >= 1e4 ? `${Math.round(n / 1e3)}k` : fmtInt(n);
// Dates in the warehouse can arrive as timestamps at UTC midnight; show the UTC calendar day.
export const fmtDay = (d) => d == null ? "" : new Date(d).toISOString().slice(0, 10);
