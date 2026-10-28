---
title: Campaign delivery
sql:
  campaigns: data/campaigns.parquet
  tasks: data/tasks.parquet
  events: data/events.parquet
  tallies: data/tallies.parquet
---

# Campaign delivery

What the field teams recorded for one campaign: household registrations and visits (ICRCampaignTask), the outcome of each visit, the drugs and vaccines given to people (MedicationAdministration, Immunization) and the nets handed to households (ICRSupplyDistribution). A campaign with cycles shows all its rounds together, or one round.

```js
import {toRows, fmtInt, fmtDay, typeLabel} from "./components/digit.js";
```

```js
const campaignRows = toRows(await sql`SELECT * FROM campaigns`);
const taskRows = toRows(await sql`SELECT * FROM tasks`);
const eventRows = toRows(await sql`SELECT * FROM events`);
const tallyRows = toRows(await sql`SELECT * FROM tallies`);
const activity = d3.rollup([...taskRows.map((d) => [d.umbrella_id, d.tasks]), ...eventRows.map((d) => [d.umbrella_id, d.events])], (v) => d3.sum(v, (d) => d[1]), (d) => d[0]);
const umbrellas = campaignRows.filter((d) => d.is_umbrella)
  .map((d) => ({...d, records: activity.get(d.campaign_id) ?? 0}))
  .sort((a, b) => d3.descending(a.records, b.records) || d3.ascending(a.title, b.title));
```

```js
// Campaigns with the most records first.
const campaign = view(Inputs.select(umbrellas, {label: "Campaign", format: (d) => `${d.title} · ${typeLabel(d.campaign_type)}${d.records ? "" : " (no records yet)"}`, value: umbrellas[0], width: 420}));
```

```js
const roundsOf = campaignRows.filter((d) => d.umbrella_id === campaign.campaign_id && !d.is_umbrella).sort((a, b) => d3.ascending(a.round, b.round));
const round = view(Inputs.select([null, ...roundsOf], {label: "Round", format: (d) => d == null ? (roundsOf.length ? `All ${roundsOf.length} rounds` : "No rounds") : `${d.title} (${fmtDay(d.period_start)} → ${fmtDay(d.period_end)})`, disabled: !roundsOf.length}));
```

```js
// Records point at the umbrella or at a round; "all rounds" takes both.
const pick = (rows) => rows.filter((d) => d.umbrella_id === campaign.campaign_id && (round == null || d.campaign_id === round.campaign_id));
const tasks = pick(taskRows), events = pick(eventRows), tallies = pick(tallyRows);
const scope = round ?? campaign;
const registrations = tasks.filter((d) => d.kind === "registration");
const visits = tasks.filter((d) => d.kind === "visit");
const given = events.filter((d) => (d.source === "drug" || d.source === "vaccine") && d.status === "completed");
const nets = events.filter((d) => d.source === "net" && d.status === "completed");
```

<div class="grid" style="gap: 12px; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr))">
  <div class="card"><h2>Period</h2><span class="big" style="font-size: 16px">${fmtDay(scope.period_start)} to ${fmtDay(scope.period_end)}</span><div class="muted">${scope.status} · ${typeLabel(campaign.campaign_type)}</div></div>
  <div class="card"><h2>Target</h2><span class="big">${fmtInt(scope.target)}</span><div class="muted">${scope.target_unit === "household" ? "households" : "people"}${scope.location_name ? `, ${scope.location_name}` : ""}</div></div>
  <div class="card"><h2>Households registered</h2><span class="big">${fmtInt(d3.sum(registrations, (d) => d.tasks))}</span><div class="muted">registration tasks</div></div>
  <div class="card"><h2>Visits</h2><span class="big">${fmtInt(d3.sum(visits, (d) => d.tasks))}</span><div class="muted">${fmtInt(d3.sum(visits.filter((d) => d.status === "completed"), (d) => d.tasks))} completed</div></div>
  <div class="card"><h2>Doses given</h2><span class="big">${fmtInt(d3.sum(given, (d) => d.events))}</span><div class="muted">drugs and vaccines</div></div>
  <div class="card"><h2>Nets distributed</h2><span class="big">${fmtInt(d3.sum(nets, (d) => d.quantity))}</span><div class="muted">to ${fmtInt(d3.sum(nets, (d) => d.people))} households</div></div>
</div>

## Registrations and visits by day

```js
const daily = d3.flatRollup(tasks, (v) => d3.sum(v, (d) => d.tasks), (d) => +d.day, (d) => d.kind).map(([day, kind, n]) => ({day: new Date(day), kind: kind === "registration" ? "Household registrations" : "Visits", n}));
display(daily.length ? Plot.plot({
  width, height: 260,
  // At least two weeks wide, so a campaign with records on one day still reads as days.
  x: {type: "utc", label: null, domain: [d3.utcDay.offset(d3.min(daily, (d) => d.day), -7), d3.utcDay.offset(d3.max(daily, (d) => d.day), 8)]},
  y: {label: "Tasks per day", grid: true},
  color: {legend: true, domain: ["Household registrations", "Visits"], range: ["#94a3b8", "#0b57d0"]},
  marks: [Plot.rectY(daily, {x: "day", y: "n", fill: "kind", interval: "day", tip: true}), Plot.ruleY([0])]
}) : html`<p class="muted">No registrations or visits recorded for this campaign yet.</p>`);
```

## Visit outcomes

A visit is failed (Task status `failed`) when the household was closed. A visit that reached the household counts as refused, ineligible or missed when the task records a refusal (`noncompliance-reason`, or a missed reason of refusal), an exclusion (`exclusion-reason`) or another missed reason (`missed-reason`) for someone in it; otherwise it is completed.

```js
const outcomeOf = (d) => {
  if (d.status === "failed") return "Failed: household closed";
  if (d.status === "completed") {
    if (d.reason_type === "noncompliance-reason" || d.reason_code === "refusal") return "Refused";
    if (d.reason_type === "exclusion-reason") return "Ineligible";
    if (d.reason_type === "missed-reason" || d.reason_code) return "Missed";
    return "Completed";
  }
  if (["requested", "ready", "received", "accepted", "draft"].includes(d.status)) return "Not visited yet";
  return `Other (${d.status})`;
};
const outcomes = d3.rollups(visits, (v) => d3.sum(v, (d) => d.tasks), outcomeOf).map(([outcome, n]) => ({outcome, n})).sort((a, b) => b.n - a.n);
const reasons = d3.rollups(visits.filter((d) => d.reason), (v) => d3.sum(v, (d) => d.tasks), (d) => d.reason).map(([reason, n]) => ({reason, n})).sort((a, b) => b.n - a.n);
const notGiven = d3.rollups(events.filter((d) => d.status === "not-done"), (v) => d3.sum(v, (d) => d.events), (d) => d.reason ?? "no reason recorded").map(([reason, n]) => ({reason, n})).sort((a, b) => b.n - a.n);
```

<div class="grid grid-cols-2" style="gap: 12px">
  <div class="card"><h2>Visits by outcome</h2>${outcomes.length ? Plot.plot({width: 460, height: 30 + 28 * outcomes.length, marginLeft: 220, x: {label: "Visits", grid: true}, y: {label: null, domain: outcomes.map((d) => d.outcome)},
    marks: [Plot.barX(outcomes, {x: "n", y: "outcome", fill: (d) => d.outcome === "Completed" ? "#0b57d0" : d.outcome.startsWith("Failed") ? "#b91c1c" : "#f59e0b", tip: true}), Plot.text(outcomes, {x: "n", y: "outcome", text: (d) => fmtInt(d.n), dx: 4, textAnchor: "start"}), Plot.ruleX([0])]}) : html`<span class="muted">No visits yet.</span>`}</div>
  <div class="card"><h2>Reasons recorded on visits</h2>${reasons.length ? Inputs.table(reasons, {header: {reason: "Reason", n: "Visits"}, format: {n: fmtInt}, select: false, rows: 8}) : html`<span class="muted">None recorded.</span>`}
  <h2 style="margin-top: 12px">Doses not given, by reason</h2>${notGiven.length ? Inputs.table(notGiven, {header: {reason: "Reason", n: "People"}, format: {n: fmtInt}, select: false, rows: 8}) : html`<span class="muted">None recorded: every drug or vaccine event is completed.</span>`}</div>
</div>

## People treated by activity

```js
const byActivity = d3.rollups(given, (v) => ({activity_id: v[0].activity_id, activity: v[0].activity, product: v[0].product, source: v[0].source,
  events: d3.sum(v, (d) => d.events), people: d3.sum(v, (d) => d.people), quantity: d3.sum(v, (d) => d.quantity), unit: v[0].unit}), (d) => d.activity_id)
  .map(([, v]) => v).sort((a, b) => b.events - a.events);
const tallyByActivity = d3.rollups(tallies, (v) => ({activity_id: v[0].activity_id, activity: v[0].activity, tasks: d3.sum(v, (d) => d.tasks), treated: d3.sum(v, (d) => d.treated)}), (d) => d.activity_id).map(([, v]) => v);
```

Counted from the delivery events (MedicationAdministration and Immunization, status completed): people are counted once per activity and round. Where the tasks also carry a per-activity tally (`treated-count` outputs, the IcrCampaignTaskOutput view), its total is shown beside the events; the DIGIT import writes tallies only on some tasks, so the two differ.

```js
const tally = new Map(tallyByActivity.map((d) => [d.activity_id, d.treated]));
for (const d of byActivity) d.tallied = tally.get(d.activity_id) ?? null;
display(byActivity.length
  ? Inputs.table(byActivity, {columns: ["activity", "product", "source", "people", "events", "quantity", "unit", ...(tallyByActivity.length ? ["tallied"] : [])],
      header: {activity: "Activity", product: "Product", source: "Kind", people: "People treated", events: "Doses given", quantity: "Quantity", unit: "Unit", tallied: "Treated, task tallies"},
      format: {people: fmtInt, events: fmtInt, quantity: fmtInt, tallied: fmtInt}, width: {activity: 340, product: 160}, select: false})
  : html`<p class="muted">No drugs or vaccines given in this campaign yet.</p>`);
```

## Nets distributed

```js
const netRows = d3.rollups(nets, (v) => ({product: v[0].product, households: d3.sum(v, (d) => d.people), quantity: d3.sum(v, (d) => d.quantity), unit: v[0].unit}), (d) => d.product).map(([, v]) => v);
display(netRows.length
  ? Inputs.table(netRows, {header: {product: "Product", households: "Households", quantity: "Nets", unit: "Unit"}, format: {households: fmtInt, quantity: fmtInt}, select: false})
  : html`<p class="muted">No nets distributed in this campaign.</p>`);
```

<style>
.big { font-size: 28px; font-weight: 600; line-height: 1.1; font-variant-numeric: tabular-nums; }
.card h2 { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); margin: 0 0 4px; }
</style>
