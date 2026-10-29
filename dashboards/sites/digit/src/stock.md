---
title: Stock
sql:
  stock: data/stock.parquet
  campaigns: data/campaigns.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Stock movements

Stock moved between warehouses, facilities and field workers (ICRSupplyMovement). DIGIT records a transfer twice: the sender records it as dispatched, the receiver as received. The DIGIT import joins the two records into one movement when they carry the same waybill number, product, quantity, sender and receiver; in this demo data none do, so each movement here is one record, a dispatch (status `in-progress`) or a receipt (`completed`). Distributions to households are on the [campaign delivery](./delivery) page.

**Dispatched, not yet received** is worked out on this page: a dispatch counts as received when there is a receipt with the same sender, receiver, product and quantity, ignoring the waybill. Dispatches and receipts with the same sender, receiver, product and quantity are matched in date order, one to one; the dispatches left over are the ones not yet received.

```js
import {toRows, fmtInt, fmtPct, fmtDay, typeLabel, countryInput, inCountry} from "./components/digit.js";
import {stockMap, STATES} from "./components/stock-map.js";
```

```js
const allRows = toRows(await sql`SELECT * FROM stock`);
const campaignRows = toRows(await sql`SELECT * FROM campaigns`);
const admin = await FileAttachment("data/admin.geojson").json();
const umbrellaOf = new Map(campaignRows.filter((d) => d.is_umbrella).map((d) => [d.campaign_id, d]));
for (const r of allRows) r.country = umbrellaOf.get(r.umbrella_id)?.country ?? "Unknown";
const moves = d3.rollup(allRows, (v) => v.length, (d) => d.umbrella_id);
const allUmbrellas = [...umbrellaOf.values()].map((d) => ({...d, movements: moves.get(d.campaign_id) ?? 0}));
const attributed = allRows.filter((d) => umbrellaOf.has(d.umbrella_id)).length;
```

```js
if (!allRows.length) display(html`<div class="card"><b>No stock movements on the server yet.</b> <span class="muted">Refresh the warehouse and redeploy once the load has finished.</span></div>`);
```

```js
const country = view(countryInput(allUmbrellas));
```

```js
const withStock = allUmbrellas.filter(inCountry(country)).filter((d) => d.movements > 0).sort((a, b) => d3.descending(a.movements, b.movements));
const campaign = view(Inputs.select([null, ...withStock], {label: "Campaign", width: 420,
  format: (d) => d == null ? `All campaigns with stock (${withStock.length})` : `${d.title} · ${typeLabel(d.campaign_type)} (${fmtInt(d.movements)} movements)`}));
```

```js
const scoped = allRows.filter(inCountry(country)).filter((d) => campaign == null || d.umbrella_id === campaign.campaign_id);
const products = [...new Set(scoped.map((d) => d.product))].sort();
const product = view(Inputs.select(["All products", ...products], {label: "Product"}));
```

```js
const rows = scoped.filter((d) => product === "All products" || d.product === product);
const dispatches = rows.filter((d) => d.record === "dispatch");
const receipts = rows.filter((d) => d.record === "receipt");
const pending = dispatches.filter((d) => d.pending);
const qty = (v) => d3.sum(v, (d) => d.quantity);
const unitNote = (v) => product === "All products" ? `${products.length} products, mixed units` : `${fmtInt(qty(v))} ${v[0]?.unit ?? rows[0]?.unit ?? ""}`;
```

<p class="muted">Every movement names its campaign (round or umbrella) in its campaign extension: ${fmtInt(attributed)} of ${fmtInt(allRows.length)} (${fmtPct(attributed / allRows.length)}) are attributed to a campaign.</p>

<div class="grid" style="gap: 12px; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr))">
  <div class="card"><h2>Movements</h2><span class="big">${fmtInt(rows.length)}</span><div class="muted">${unitNote(rows)}</div></div>
  <div class="card"><h2>Dispatched</h2><span class="big">${fmtInt(dispatches.length)}</span><div class="muted">dispatch records · ${unitNote(dispatches)}</div></div>
  <div class="card"><h2>Received</h2><span class="big">${fmtInt(receipts.length)}</span><div class="muted">receipt records · ${unitNote(receipts)}</div></div>
  <div class="card"><h2>Dispatched, not yet received</h2><span class="big">${fmtInt(pending.length)}</span><div class="muted">${fmtPct(pending.length / (dispatches.length || 1))} of dispatches · ${unitNote(pending)}</div></div>
</div>

## Where stock was dispatched and received

Each LGA has up to three circles: stock dispatched from its facilities, received in them, and dispatched from them but not yet received. A circle's area is the number of movements. DIGIT holds no geometry and only one facility in the stock records has coordinates, so a facility is placed in its LGA through DIGIT's hierarchy (`partOf`): its DIGIT LGA or district, matched to the GRID3 LGA. A store that sits directly under a state is drawn at the state. Only Nigeria's states and LGAs are matched, so stock elsewhere, and stock with field workers, is counted below the map, not drawn.

```js
const stateInput = Inputs.checkbox(STATES.map(([s]) => s), {label: "Show", value: STATES.map(([s]) => s), format: (s) => STATES.find((x) => x[0] === s)[1]});
const states = Generators.input(stateInput);
const mapEl = stockMap(admin, {height: 540});
const mapClicked = Generators.input(mapEl);
```

```js
// Dispatches are placed at the sender, receipts at the receiver; pending dispatches at the sender.
const placed = [
  ...dispatches.map((d) => ({state: "dispatched", d, kind: d.sender_kind, lga: d.sender_lga ?? d.sender_state, hierarchy: d.sender_hierarchy})),
  ...receipts.map((d) => ({state: "received", d, kind: d.receiver_kind, lga: d.receiver_lga ?? d.receiver_state, hierarchy: d.receiver_hierarchy})),
  ...pending.map((d) => ({state: "pending", d, kind: d.sender_kind, lga: d.sender_lga ?? d.sender_state, hierarchy: d.sender_hierarchy}))
];
const mapRows = d3.flatRollup(placed.filter((p) => p.lga), (v) => ({
  movements: v.length, quantity: d3.sum(v, (p) => p.d.quantity),
  products: d3.rollups(v, (w) => ({product: w[0].d.product, unit: w[0].d.unit, quantity: d3.sum(w, (p) => p.d.quantity)}), (p) => p.d.product).map(([, x]) => x).sort((a, b) => b.quantity - a.quantity)
}), (p) => p.lga, (p) => p.state).map(([unit_id, state, x]) => ({unit_id, state, ...x}));
mapEl.setData(mapRows);
// Why the rest is not on the map, per state.
const reason = (p) => p.kind === "field worker" ? "a field worker (no place)" : p.kind === "not exported" ? "a party the import could not export" : p.kind === "not recorded" ? "no party recorded"
  : p.hierarchy && !["NIGERIA", "ADMIN"].includes(p.hierarchy) ? `a facility in the ${p.hierarchy} hierarchy (no boundaries)` : "a Nigerian facility above state level (no matched state or LGA)";
const unmapped = d3.rollups(placed.filter((p) => !p.lga), (v) => v.length, (p) => p.state, reason);
```

<div>${stateInput}</div>

```js
mapEl.setStates(states);
```

```js
display(html`<div class="grid" style="gap: 12px; grid-template-columns: minmax(0, 3fr) minmax(0, 1fr)">
  <div class="card" style="padding: 0; overflow: hidden">${mapEl}</div>
  <div class="card"><h2>Selected LGA</h2>${!mapClicked ? html`<div class="muted">Click an LGA or a circle.</div>` : html`<div>
    <div style="font-weight: 600">${mapClicked.name ?? mapClicked.id}</div>
    <div class="muted">${mapClicked.kind === "state" ? "State (state stores)" : `LGA, ${mapClicked.state ?? ""}`} · P-code ${mapClicked.pcode ?? "—"}</div>
    ${STATES.map(([s, label, c]) => html`<div style="margin-top: 6px"><span style="color: ${c}">●</span> ${label}: ${fmtInt(mapClicked[s]?.movements ?? 0)} movements
      ${(mapClicked[s]?.products ?? []).map((q) => html`<div class="muted" style="font-size: 12px; margin-left: 14px">${fmtInt(q.quantity)} ${q.unit ?? ""} ${q.product}</div>`)}</div>`)}
    <div class="muted" style="font-size: 12px; margin-top: 6px">For the country, campaign and product chosen when the LGA was clicked.</div></div>`}</div>
</div>`);
```

```js
display(html`<p>${STATES.map(([s, label]) => {
  const all = placed.filter((p) => p.state === s).length, off = d3.sum((unmapped.find(([st]) => st === s)?.[1] ?? []), ([, n]) => n);
  return `${label}: ${fmtInt(all - off)} of ${fmtInt(all)} on the map.`;
}).join(" ")}</p>
${unmapped.length ? html`<div class="note">Not on the map: ${unmapped.map(([s, rs]) => html`<div><b>${STATES.find((x) => x[0] === s)[1]}</b>: ${rs.sort((a, b) => b[1] - a[1]).map(([r, n]) => `${fmtInt(n)} at ${r}`).join("; ")}.</div>`)}</div>` : ""}`);
```

## By product

```js
const byProduct = d3.rollups(rows, (v) => {
  const dsp = v.filter((d) => d.record === "dispatch"), rcv = v.filter((d) => d.record === "receipt");
  return {product: v[0].product, unit: v[0].unit, dispatched: qty(dsp), received: qty(rcv), pending: qty(dsp.filter((d) => d.pending)),
    dispatches: dsp.length, receipts: rcv.length, pending_n: dsp.filter((d) => d.pending).length,
    returned: d3.sum(v, (d) => d.returned), not_usable: d3.sum(v, (d) => d.not_usable)};
}, (d) => d.product).map(([, v]) => v).sort((a, b) => b.dispatched + b.received - a.dispatched - a.received);
const LABELS = Object.fromEntries(STATES.map(([s, l]) => [s, l]));
const long = byProduct.flatMap((d) => [["dispatched", d.dispatched], ["received", d.received], ["pending", d.pending]].map(([s, q]) => ({product: d.product, state: LABELS[s], q})));
display(byProduct.length ? Plot.plot({
  width, height: 50 + 54 * byProduct.length, marginLeft: 220,
  x: {label: "Quantity", grid: true}, y: {axis: null, domain: STATES.map(([, l]) => l)},
  fy: {label: null, domain: byProduct.map((d) => d.product), axis: "left"},
  color: {legend: true, domain: STATES.map(([, l]) => l), range: STATES.map(([, , c]) => c)},
  marks: [Plot.barX(long, {x: "q", y: "state", fy: "product", fill: "state", tip: true}), Plot.ruleX([0])]
}) : html`<p class="muted">No movements.</p>`);
```

```js
display(byProduct.length ? Inputs.table(byProduct, {
  columns: ["product", "unit", "dispatches", "dispatched", "receipts", "received", "pending_n", "pending", "returned", "not_usable"],
  header: {product: "Product", unit: "Unit", dispatches: "Dispatches", dispatched: "Quantity dispatched", receipts: "Receipts", received: "Quantity received",
           pending_n: "Not yet received", pending: "Quantity not yet received", returned: "Returned", not_usable: "Not usable"},
  format: {dispatches: fmtInt, dispatched: fmtInt, receipts: fmtInt, received: fmtInt, pending_n: fmtInt, pending: fmtInt, returned: fmtInt, not_usable: fmtInt},
  width: {product: 200}, select: false
}) : html`<p class="muted">No movements.</p>`);
```

## By facility or field worker

What each place dispatched, received, and dispatched without a matching receipt yet.

```js
const ledger = new Map();
const entry = (name, kind) => { if (!ledger.has(name)) ledger.set(name, {place: name, kind, dispatched: 0, received: 0, pending: 0}); return ledger.get(name); };
for (const d of dispatches) { const e = entry(d.sender, d.sender_kind); e.dispatched += d.quantity ?? 0; if (d.pending) e.pending += d.quantity ?? 0; }
for (const d of receipts) entry(d.receiver, d.receiver_kind).received += d.quantity ?? 0;
const places = [...ledger.values()].sort((a, b) => (b.received + b.dispatched) - (a.received + a.dispatched));
const placeSearch = view(Inputs.search(places, {placeholder: "Search a facility or field worker…"}));
```

```js
display(places.length ? Inputs.table(placeSearch, {
  columns: ["place", "kind", "dispatched", "received", "pending"],
  header: {place: "Facility or field worker", kind: "Kind", dispatched: "Dispatched", received: "Received", pending: "Dispatched, not yet received"},
  format: {dispatched: fmtInt, received: fmtInt, pending: fmtInt}, width: {place: 320}, select: false, rows: 20
}) : html`<p class="muted">No movements.</p>`);
```

## Movements by day

```js
// Every dispatch counts as dispatched, as on the map and the cards; the ones not yet received are
// a part of them, so each state gets its own row rather than a stack.
const byDay = [
  ...d3.flatRollup(dispatches, (v) => v.length, (d) => +d.day).map(([day, n]) => ({day: new Date(day), state: LABELS.dispatched, n})),
  ...d3.flatRollup(receipts, (v) => v.length, (d) => +d.day).map(([day, n]) => ({day: new Date(day), state: LABELS.received, n})),
  ...d3.flatRollup(pending, (v) => v.length, (d) => +d.day).map(([day, n]) => ({day: new Date(day), state: LABELS.pending, n}))
];
display(byDay.length ? Plot.plot({
  width, height: 330, marginLeft: 50, marginRight: 190,
  x: {type: "utc", label: null, domain: [d3.utcDay.offset(d3.min(byDay, (d) => d.day), -7), d3.utcDay.offset(d3.max(byDay, (d) => d.day), 8)]},
  y: {label: "Movements", grid: true},
  fy: {label: null, domain: STATES.map(([, l]) => l)},
  color: {legend: true, domain: STATES.map(([, l]) => l), range: STATES.map(([, , c]) => c)},
  marks: [Plot.rectY(byDay, {x: "day", y: "n", fy: "state", fill: "state", interval: "day", tip: true}), Plot.ruleY([0])]
}) : html`<p class="muted">No movements.</p>`);
```

<style>
.big { font-size: 28px; font-weight: 600; line-height: 1.1; font-variant-numeric: tabular-nums; }
.card h2 { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); margin: 0 0 4px; }
.maplibregl-popup-content { padding: 6px 9px; }
</style>
