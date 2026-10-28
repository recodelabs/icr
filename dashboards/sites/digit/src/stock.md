---
title: Stock
sql:
  stock: data/stock.parquet
---

# Stock movements

Stock moved between warehouses, facilities and field teams (ICRSupplyMovement). DIGIT records each transfer twice, once by the sender (dispatched) and once by the receiver (received); the import pairs the two into one movement. A movement both sides recorded is complete (status `completed`); one the receiver has not recorded is in progress (`in-progress`). Distributions to households are on the [campaign delivery](./delivery) page.

```js
import {toRows, fmtInt, fmtDay} from "./components/digit.js";
```

```js
const rows = toRows(await sql`SELECT * FROM stock`);
const received = (d) => d.status === "completed";
const products = [...new Set(rows.map((d) => d.product))].sort();
```

```js
if (!rows.length) display(html`<div class="card"><b>No stock movements on the server yet.</b> <span class="muted">The bulk load writes them after the households and visits. Refresh the warehouse and redeploy once it has finished.</span></div>`);
```

<div class="grid" style="gap: 12px; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr))">
  <div class="card"><h2>Movements</h2><span class="big">${fmtInt(d3.sum(rows, (d) => d.movements))}</span><div class="muted">${products.length} products</div></div>
  <div class="card"><h2>Dispatched</h2><span class="big">${fmtInt(d3.sum(rows, (d) => d.quantity))}</span><div class="muted">units sent</div></div>
  <div class="card"><h2>Received</h2><span class="big">${fmtInt(d3.sum(rows.filter(received), (d) => d.quantity))}</span><div class="muted">units recorded by the receiver</div></div>
  <div class="card"><h2>Not yet received</h2><span class="big">${fmtInt(d3.sum(rows.filter((d) => !received(d)), (d) => d.quantity))}</span><div class="muted">in movements still in progress</div></div>
</div>

```js
const product = view(Inputs.select(["All products", ...products], {label: "Product"}));
```

```js
const sel = rows.filter((d) => product === "All products" || d.product === product);
```

## Received and dispatched by product

```js
const byProduct = d3.rollups(sel, (v) => ({product: v[0].product, unit: v[0].unit, movements: d3.sum(v, (d) => d.movements),
  dispatched: d3.sum(v, (d) => d.quantity), received: d3.sum(v.filter(received), (d) => d.quantity),
  returned: d3.sum(v, (d) => d.returned), not_usable: d3.sum(v, (d) => d.not_usable)}), (d) => d.product).map(([, v]) => v).sort((a, b) => b.dispatched - a.dispatched);
const long = byProduct.flatMap((d) => [{product: d.product, measure: "Dispatched", q: d.dispatched}, {product: d.product, measure: "Received", q: d.received}]);
display(byProduct.length ? Plot.plot({
  width, height: 50 + 44 * byProduct.length, marginLeft: 220,
  x: {label: "Quantity", grid: true}, y: {axis: null, domain: ["Dispatched", "Received"]},
  fy: {label: null, domain: byProduct.map((d) => d.product), axis: "left"},
  color: {legend: true, domain: ["Dispatched", "Received"], range: ["#94a3b8", "#0b57d0"]},
  marks: [Plot.barX(long, {x: "q", y: "measure", fy: "product", fill: "measure", tip: true}), Plot.ruleX([0])]
}) : html`<p class="muted">No movements.</p>`);
```

```js
display(byProduct.length ? Inputs.table(byProduct, {
  columns: ["product", "unit", "movements", "dispatched", "received", "returned", "not_usable"],
  header: {product: "Product", unit: "Unit", movements: "Movements", dispatched: "Dispatched", received: "Received", returned: "Returned", not_usable: "Not usable"},
  format: {movements: fmtInt, dispatched: fmtInt, received: fmtInt, returned: fmtInt, not_usable: fmtInt}, select: false
}) : html`<p class="muted">No movements.</p>`);
```

## By facility

Each place's stock in and out: what it received from others and what it dispatched to others, for the product chosen above.

```js
const ledger = new Map();
const row = (name) => { if (!ledger.has(name)) ledger.set(name, {place: name, received_in: 0, dispatched_out: 0, awaiting: 0}); return ledger.get(name); };
for (const d of sel) {
  if (d.sender) row(d.sender).dispatched_out += d.quantity ?? 0;
  if (d.receiver) { if (received(d)) row(d.receiver).received_in += d.quantity ?? 0; else row(d.receiver).awaiting += d.quantity ?? 0; }
}
const places = [...ledger.values()].sort((a, b) => (b.received_in + b.dispatched_out) - (a.received_in + a.dispatched_out));
const placeSearch = view(Inputs.search(places, {placeholder: "Search a facility or team…"}));
```

```js
display(places.length ? Inputs.table(placeSearch, {
  columns: ["place", "received_in", "dispatched_out", "awaiting"],
  header: {place: "Facility or team", received_in: "Received", dispatched_out: "Dispatched", awaiting: "Dispatched to it, not yet received"},
  format: {received_in: fmtInt, dispatched_out: fmtInt, awaiting: fmtInt}, width: {place: 320}, select: false, rows: 20
}) : html`<p class="muted">No movements.</p>`);
```

## Movements by day

```js
const byDay = d3.flatRollup(sel, (v) => d3.sum(v, (d) => d.quantity), (d) => +d.day, (d) => received(d) ? "Received" : "Dispatched, not yet received")
  .map(([day, status, q]) => ({day: new Date(day), status, q}));
display(byDay.length ? Plot.plot({
  width, height: 240, x: {type: "utc", label: null, domain: [d3.utcDay.offset(d3.min(byDay, (d) => d.day), -7), d3.utcDay.offset(d3.max(byDay, (d) => d.day), 8)]}, y: {label: "Quantity", grid: true},
  color: {legend: true, domain: ["Received", "Dispatched, not yet received"], range: ["#0b57d0", "#f59e0b"]},
  marks: [Plot.rectY(byDay, {x: "day", y: "q", fill: "status", interval: "day", tip: true}), Plot.ruleY([0])]
}) : html`<p class="muted">No movements.</p>`);
```

<style>
.big { font-size: 28px; font-weight: 600; line-height: 1.1; font-variant-numeric: tabular-nums; }
.card h2 { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); margin: 0 0 4px; }
</style>
