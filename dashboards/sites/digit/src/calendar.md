---
title: Campaign calendar
sql:
  campaigns: data/campaigns.parquet
  tasks: data/tasks.parquet
---

# Campaign calendar

When DIGIT's campaigns ran or are planned, as the ICR holds them (ICRCampaign, the IcrCampaignCalendar view): one row per campaign, with a grey bar for the campaign's whole period and a coloured bar for each cycle round. Campaigns without rounds show their own period in colour. Colours are campaign types; the red dotted line is today. Dates are calendar days in India Standard Time, DIGIT's time zone.

```js
import {toRows, fmtInt, fmtDay, typeLabel, countryInput, inCountry, CAMPAIGN_TYPES} from "./components/digit.js";
```

```js
const campaignRows = toRows(await sql`SELECT * FROM campaigns`);
const taskRows = toRows(await sql`SELECT campaign_id, kind, sum(tasks)::INT AS tasks, sum(households)::INT AS households FROM tasks GROUP BY ALL`);
// Visits and households registered per campaign row (round or umbrella).
const visitsOf = d3.rollup(taskRows.filter((d) => d.kind === "visit"), (v) => d3.sum(v, (d) => d.tasks), (d) => d.campaign_id);
const householdsOf = d3.rollup(taskRows.filter((d) => d.kind === "registration"), (v) => d3.sum(v, (d) => d.households), (d) => d.campaign_id);
for (const d of campaignRows) Object.assign(d, {type: typeLabel(d.campaign_type), visits: visitsOf.get(d.campaign_id) ?? 0, households: householdsOf.get(d.campaign_id) ?? 0});
const allUmbrellas = campaignRows.filter((d) => d.is_umbrella);
const roundsOf = d3.group(campaignRows.filter((d) => !d.is_umbrella), (d) => d.umbrella_id);
// An umbrella's records include its rounds'.
for (const u of allUmbrellas) {
  const rs = roundsOf.get(u.campaign_id) ?? [];
  u.all_visits = u.visits + d3.sum(rs, (r) => r.visits);
  u.all_households = u.households + d3.sum(rs, (r) => r.households);
}
const dated = (d) => d.period_start != null && d.period_end != null;
const today = new Date();
```

<div style="display: flex; flex-wrap: wrap; gap: 4px 24px">
  <div>${countryEl}</div>
  <div>${typeEl}</div>
</div>
<div style="display: flex; flex-wrap: wrap; gap: 4px 24px">
  <div>${fromEl}</div>
  <div>${toEl}</div>
</div>

```js
const countryEl = countryInput(allUmbrellas);
const country = Generators.input(countryEl);
const types = [...new Set(allUmbrellas.map((d) => d.type))].sort();
const typeEl = Inputs.select(["All types", ...types], {label: "Campaign type"});
const type = Generators.input(typeEl);
const span = [d3.min(campaignRows.filter(dated), (d) => new Date(d.period_start)), d3.max(campaignRows.filter(dated), (d) => new Date(d.period_end))];
const fromEl = Inputs.date({label: "From", value: span[0]});
const from = Generators.input(fromEl);
const toEl = Inputs.date({label: "To", value: span[1]});
const to = Generators.input(toEl);
```

```js
const chosen = allUmbrellas.filter(inCountry(country)).filter((d) => type === "All types" || d.type === type);
const undated = chosen.filter((d) => !dated(d));
const lo = from ?? span[0], hi = to ?? span[1];
const overlaps = (d) => dated(d) && new Date(d.period_end) >= lo && new Date(d.period_start) <= hi;
const shown = chosen.filter(overlaps).sort((a, b) => d3.ascending(a.type, b.type) || d3.ascending(new Date(a.period_start), new Date(b.period_start)) || d3.ascending(a.title, b.title));
const bars = shown.flatMap((u) => {
  const rs = (roundsOf.get(u.campaign_id) ?? []).filter(dated);
  return rs.length ? rs.map((r) => ({...r, lane: u.campaign_id, umbrella: u})) : [{...u, lane: u.campaign_id, umbrella: u}];
});
const nRounds = d3.sum(shown, (u) => (roundsOf.get(u.campaign_id) ?? []).length);
```

<div class="grid" style="gap: 12px; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr))">
  <div class="card"><h2>Campaigns shown</h2><span class="big">${fmtInt(shown.length)}</span><div class="muted">of ${fmtInt(chosen.length)} chosen, overlapping the dates</div></div>
  <div class="card"><h2>Cycle rounds</h2><span class="big">${fmtInt(nRounds)}</span><div class="muted">in the campaigns shown</div></div>
  <div class="card"><h2>Running today</h2><span class="big">${fmtInt(chosen.filter((d) => dated(d) && new Date(d.period_start) <= today && new Date(d.period_end) >= today).length)}</span><div class="muted">${fmtDay(today)}</div></div>
  <div class="card"><h2>Dates</h2><span class="big" style="font-size: 16px">${fmtDay(span[0])} to ${fmtDay(span[1])}</span><div class="muted">earliest start and latest end, all campaigns</div></div>
</div>

```js
const typeDomain = types;
const label = (u) => `${u.title}${u.country && u.country !== "Unknown" ? ` · ${u.country}` : ""}`;
const laneLabel = new Map(shown.map((u) => [u.campaign_id, label(u)]));
const barTitle = (d) => {
  const u = d.umbrella ?? d;
  return `${d.title}\n${fmtDay(d.period_start)} → ${fmtDay(d.period_end)} · ${d.status}\n${u.type} · ${u.country}`
    + (u.location_name ? `\ntarget area: ${u.location_name}${u.n_geographies > 1 ? ` and ${u.n_geographies - 1} more` : ""}` : "")
    + (d.target != null ? `\ntarget: ${fmtInt(d.target)} ${d.target_unit === "household" ? "households" : "people"}` : "")
    + `\n${fmtInt(d === u ? u.all_visits : d.visits)} visits · ${fmtInt(d === u ? u.all_households : d.households)} households registered`;
};
// The main dashboard's timeline (sites/main/src/index.md) is inline Plot code, not a shared
// component, so this follows it: Plot.barX lanes on a shared UTC axis with today as a red rule.
display(shown.length ? Plot.plot({
  width,
  height: 50 + 18 * shown.length,
  marginLeft: Math.min(320, 7 + 6.2 * d3.max(shown, (u) => laneLabel.get(u.campaign_id).length)),
  marginRight: 20,
  x: {type: "utc", label: null, grid: true, domain: [lo, hi], axis: "top"},
  y: {label: null, domain: shown.map((u) => u.campaign_id), tickFormat: (id) => laneLabel.get(id), tickSize: 0},
  color: {legend: true, domain: typeDomain},
  marks: [
    Plot.barX(shown, {x1: (d) => new Date(d.period_start), x2: (d) => new Date(d.period_end), y: "campaign_id", fill: "#e2e8f0", insetTop: 2, insetBottom: 2, rx: 2,
      tip: true, title: barTitle}),
    Plot.barX(bars, {x1: (d) => new Date(d.period_start), x2: (d) => d3.utcDay.offset(new Date(d.period_end), 1), y: "lane", fill: (d) => d.umbrella.type,
      fillOpacity: 0.85, insetTop: 4, insetBottom: 4, rx: 2, stroke: "white", strokeWidth: 0.5, tip: true, title: barTitle}),
    Plot.ruleX([today], {stroke: "#ef4444", strokeDasharray: "3,3"})
  ]
}) : html`<p class="muted">No campaigns in these dates.</p>`);
```

```js
display(undated.length
  ? html`<div class="note">No dates for ${undated.length} campaign${undated.length === 1 ? "" : "s"}: ${undated.map((d) => d.title).join(", ")}.</div>`
  : html`<p class="muted">Every campaign chosen has a start and an end date.</p>`);
```

## The campaigns and their rounds

```js
const tableRows = shown.flatMap((u) => [u, ...(roundsOf.get(u.campaign_id) ?? []).sort((a, b) => d3.ascending(a.round, b.round))])
  .map((d) => ({...d, level: d.is_umbrella ? "campaign" : `round ${d.round ?? ""}`, country: d.country, visits_shown: d.is_umbrella ? d.all_visits : d.visits}));
display(Inputs.table(tableRows, {
  columns: ["title", "level", "type", "country", "status", "period_start", "period_end", "location_name", "visits_shown"],
  header: {title: "Campaign or round", level: "Level", type: "Type", country: "Country", status: "Status", period_start: "Start", period_end: "End", location_name: "Target area", visits_shown: "Visits"},
  format: {period_start: fmtDay, period_end: fmtDay, visits_shown: fmtInt},
  width: {title: 260, level: 70, type: 180},
  select: false, rows: 20
}));
```

<style>
.big { font-size: 28px; font-weight: 600; line-height: 1.1; font-variant-numeric: tabular-nums; }
.card h2 { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); margin: 0 0 4px; }
</style>
