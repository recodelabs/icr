---
title: Campaign plan
sql:
  targets: data/targets.parquet
  tasks: data/tasks.parquet
---

# Campaign plan, ICHDs October 2026

The October 2026 round as the ICR holds it: one protocol with six activities, a national campaign with one campaign under it for each district and city, and one task for each district and activity. Each campaign names its own target for every activity. Everything is a draft until the Ministry of Health confirms the plan; later the district tasks can be split into facility, parish or session tasks.

```js
import {ACTIVITIES, ACTIVITY, STRATEGIES, toRows, fmtInt, fmtDay} from "./components/ichd.js";
```

```js
const targetRows = toRows(await sql`SELECT * FROM targets`);
const taskRows = toRows(await sql`SELECT * FROM tasks`);
const campaigns = d3.group(targetRows, (d) => d.campaign_id);
const national = targetRows.filter((d) => d.admin_level === 0);
const target = d3.rollup(targetRows, (v) => d3.sum(v, (d) => d.quantity), (d) => d.campaign_id, (d) => d.activity_key);
const parts = d3.rollup(national, (v) => v.map((d) => d.target_name), (d) => d.activity_key);
const statusOf = d3.rollup(targetRows, (v) => [...new Set(v.map((d) => d.activity_status))].join(", "), (d) => d.activity_key);
for (const t of taskRows) {
  t.activity = ACTIVITY.get(t.activity_key)?.short ?? t.activity_key;
  t.strategy_label = STRATEGIES[t.strategy] ?? t.strategy;
  t.target = target.get(t.campaign_id)?.get(t.activity_key) ?? null;
  t.region = (t.region ?? "").replace(" Region", "");
  t.dates = `${fmtDay(t.execution_start)} → ${fmtDay(t.execution_end)}`;
}
const start = d3.min(taskRows, (d) => fmtDay(d.execution_start)), end = d3.max(taskRows, (d) => fmtDay(d.execution_end));
const nationalCampaign = national[0]?.campaign_id;
```

<div class="grid grid-cols-4" style="gap: 12px">
  <div class="card"><h2>Activities</h2><span class="big">${ACTIVITIES.length}</span><div class="muted">in the protocol, Uganda ICHDs</div></div>
  <div class="card"><h2>Campaigns</h2><span class="big">${fmtInt(campaigns.size)}</span><div class="muted">1 national + ${fmtInt(campaigns.size - 1)} districts and cities, all draft</div></div>
  <div class="card"><h2>Tasks</h2><span class="big">${fmtInt(taskRows.length)}</span><div class="muted">one per district and activity, ${[...new Set(taskRows.map((d) => d.status))].join(", ")}</div></div>
  <div class="card"><h2>Round</h2><span class="big" style="font-size: 22px">${start} → ${end}</span><div class="muted">the whole month for now</div></div>
</div>

<div class="card" style="margin-top: 12px">
  <h2>The six activities</h2>
  ${activityTable}
</div>

```js
const activityTable = html`<div style="overflow-x: auto"><table class="plain">
  <thead><tr><th>Activity</th><th class="num">Target, Uganda</th><th>Target groups</th><th>Delivery</th><th class="num">Tasks</th><th>Status in the campaigns</th></tr></thead>
  <tbody>${ACTIVITIES.map((a) => html`<tr>
    <td>${a.label}</td>
    <td class="num">${fmtInt(target.get(nationalCampaign)?.get(a.key))}</td>
    <td>${(parts.get(a.key) ?? []).join(" + ")}</td>
    <td>${[...new Set(taskRows.filter((t) => t.activity_key === a.key).map((t) => t.strategy_label))].join(", ")}</td>
    <td class="num">${fmtInt(taskRows.filter((t) => t.activity_key === a.key).length)}</td>
    <td>${statusOf.get(a.key) ?? ""}</td></tr>`)}</tbody>
</table></div>`;
```

<div class="card" style="margin-top: 12px">
  <h2>Tasks by activity and delivery strategy</h2>
  ${matrix}
  <div class="muted" style="margin-top: 4px">HPV is delivered in schools and the other activities at fixed posts, as drafted. The delivery strategy of each activity is still to be confirmed with the Ministry.</div>
</div>

```js
const cells = d3.flatRollup(taskRows, (v) => v.length, (d) => ACTIVITY.get(d.activity_key)?.label ?? d.activity_key, (d) => d.strategy_label)
  .map(([activity, strategy, n]) => ({activity, strategy, n}));
const strategies = [...new Set(cells.map((d) => d.strategy))];
const matrix = Plot.plot({
  width: Math.min(width, 640),
  height: 40 + 30 * ACTIVITIES.length,
  marginLeft: 230, marginTop: 30,
  x: {label: null, domain: strategies, axis: "top", tickSize: 0},
  y: {label: null, domain: ACTIVITIES.map((a) => a.label), tickSize: 0},
  marks: [
    Plot.cell(cells, {x: "strategy", y: "activity", fill: "#3182bd", inset: 2, rx: 3}),
    Plot.text(cells, {x: "strategy", y: "activity", text: (d) => `${d.n} tasks`, fill: "white", fontSize: 11, fontWeight: 500})
  ]
});
```

## Tasks

```js
const search = view(Inputs.search(taskRows, {placeholder: "Search district, region or activity…", columns: ["location_name", "region", "activity", "strategy_label"]}));
```

```js
Inputs.table(search, {
  columns: ["location_name", "region", "activity", "target", "strategy_label", "status", "dates", "task_id"],
  header: {location_name: "District / city", region: "Region", activity: "Activity", target: "Target", strategy_label: "Delivery", status: "Status", dates: "Dates", task_id: "Task id"},
  format: {target: fmtInt},
  width: {location_name: 130, region: 80, activity: 90, target: 90, strategy_label: 90, status: 60, dates: 190},
  sort: "location_name",
  rows: 18
})
```

<div class="card" style="margin-top: 16px; max-width: 900px">
  <h2>To confirm with the Ministry of Health</h2>
  <ul style="margin: 4px 0 0; padding-left: 1.2rem; line-height: 1.6">
    <li>The ages for deworming, vitamin A, HPV and Td2+, so those targets and the protocol's activities can carry age bands.</li>
    <li>Whether the April 2025 column is an MR2 target (children 18 months old in October); the workbook also counts it in the under-1 total.</li>
    <li>What "Catch Population 2025" is; it is taken to be the health facility catchment population.</li>
    <li>The products (which HPV vaccine, which deworming drug) and how each activity is delivered.</li>
    <li>The round's dates in each district, if they differ from 1–31 October.</li>
  </ul>
</div>

<style>
.big { font-size: 28px; font-weight: 600; line-height: 1.1; font-variant-numeric: tabular-nums; }
.card h2 { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); margin: 0 0 4px; }
table.plain { border-collapse: collapse; width: 100%; font-size: 13px; max-width: none; }
table.plain th, table.plain td { text-align: left; padding: 5px 10px 5px 0; border-bottom: 1px solid var(--theme-foreground-faintest); vertical-align: top; }
table.plain th { font-weight: 600; }
table.plain .num { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap; }
</style>
