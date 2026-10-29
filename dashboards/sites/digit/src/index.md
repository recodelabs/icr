---
title: Overview
sql:
  campaigns: data/campaigns.parquet
  totals: data/totals.parquet
---

# DIGIT demo data in the ICR

This site shows the demo data of eGov's [DIGIT Health Campaign Management](https://docs.digit.org/health) (HCM) system after import into the ICR. The data is fake: DIGIT's demo campaigns, households, people, visits and stock, transformed to the ICR's FHIR profiles with the DIGIT mapping and loaded into the ICR server for DIGIT (`fhir-digit.healthcampaigns.org`). Every page is built from that server's warehouse, so it shows what the ICR holds, not what DIGIT's own dashboards show.

```js
import {toRows, fmtInt, fmtDay, typeLabel, countryInput, inCountry} from "./components/digit.js";
```

```js
const campaignRows = toRows(await sql`SELECT * FROM campaigns`);
const totalRows = toRows(await sql`SELECT * FROM totals`);
const all = totalRows.find((d) => d.umbrella_id == null) ?? {};
const byUmbrella = new Map(totalRows.filter((d) => d.umbrella_id != null).map((d) => [d.umbrella_id, d]));
const allUmbrellas = campaignRows.filter((d) => d.is_umbrella);
const rounds = d3.rollup(campaignRows.filter((d) => !d.is_umbrella), (v) => v.length, (d) => d.umbrella_id);
for (const u of allUmbrellas) Object.assign(u, {rounds: rounds.get(u.campaign_id) ?? 0, type: typeLabel(u.campaign_type)},
  byUmbrella.get(u.campaign_id) ?? {households: 0, people: 0, visits: 0, treated: 0, doses: 0, nets: 0});
```

A campaign's country is that of the DIGIT boundary hierarchy its target area belongs to (or, without a target area, the one its visits are in): NIGERIA and ADMIN are Nigeria, SIERRALEONE Sierra Leone, DEMOGABON Gabon and MICROPLAN Chad. Campaigns with neither are "Unknown".

```js
const country = view(countryInput(allUmbrellas));
```

```js
const umbrellas = allUmbrellas.filter(inCountry(country));
const sum = (k) => d3.sum(umbrellas, (d) => d[k]);
```

<div class="grid" style="gap: 12px; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr))">
  <div class="card"><h2>Campaigns</h2><span class="big">${fmtInt(umbrellas.length)}</span><div class="muted">with ${fmtInt(d3.sum(umbrellas, (d) => d.rounds))} cycle rounds${country === "All" ? "" : `, ${country}`}</div></div>
  <div class="card"><h2>Households registered</h2><span class="big">${fmtInt(sum("households"))}</span><div class="muted">in a campaign; ${fmtInt(all.households)} on the server, all countries</div></div>
  <div class="card"><h2>People</h2><span class="big">${fmtInt(sum("people"))}</span><div class="muted">in registered households; ${fmtInt(all.people)} on the server, all countries</div></div>
  <div class="card"><h2>Visits</h2><span class="big">${fmtInt(sum("visits"))}</span><div class="muted">delivery visits to households</div></div>
  <div class="card"><h2>People treated</h2><span class="big">${fmtInt(sum("treated"))}</span><div class="muted">given a drug or vaccine; ${fmtInt(sum("doses"))} doses</div></div>
  <div class="card"><h2>Nets distributed</h2><span class="big">${fmtInt(sum("nets"))}</span><div class="muted">to households</div></div>
</div>

<div class="note">A bulk load into the server was still running when this site was first built, so some campaigns have no registrations or visits yet. The figures change when the warehouse is refreshed and the site redeployed.</div>

## Totals by campaign type

```js
const byType = d3.rollups(umbrellas, (v) => ({
  type: v[0].type, campaigns: v.length, rounds: d3.sum(v, (d) => d.rounds),
  households: d3.sum(v, (d) => d.households), people: d3.sum(v, (d) => d.people), visits: d3.sum(v, (d) => d.visits),
  treated: d3.sum(v, (d) => d.treated), nets: d3.sum(v, (d) => d.nets)
}), (d) => d.type).map(([, v]) => v).sort((a, b) => b.campaigns - a.campaigns);
```

```js
Inputs.table(byType, {
  columns: ["type", "campaigns", "rounds", "households", "people", "visits", "treated", "nets"],
  header: {type: "Campaign type", campaigns: "Campaigns", rounds: "Rounds", households: "Households registered", people: "People", visits: "Visits", treated: "People treated", nets: "Nets distributed"},
  format: {campaigns: fmtInt, rounds: fmtInt, households: fmtInt, people: fmtInt, visits: fmtInt, treated: fmtInt, nets: fmtInt},
  width: {type: 240},
  select: false
})
```

## The campaigns

Each DIGIT campaign is an umbrella ICRCampaign. A campaign with cycles has one ICRCampaign round per cycle under it. The target is the umbrella's planning target, in people or households.

```js
const search = view(Inputs.search(umbrellas, {placeholder: "Search title, type or protocol…", columns: ["title", "type", "protocol", "location_name", "status", "country"]}));
```

```js
Inputs.table(search, {
  columns: ["title", "country", "type", "protocol", "status", "period_start", "period_end", "rounds", "location_name", "target", "households", "visits", "treated", "nets"],
  header: {title: "Campaign", country: "Country", type: "Type", protocol: "Protocol (DIGIT project type)", status: "Status", period_start: "Start", period_end: "End", rounds: "Rounds",
           location_name: "Where", target: "Target", households: "Households", visits: "Visits", treated: "Treated", nets: "Nets"},
  format: {period_start: fmtDay, period_end: fmtDay, target: (v, i, data) => v == null ? "—" : `${fmtInt(v)}${data[i].target_unit === "household" ? " hh" : ""}`,
           rounds: fmtInt, households: fmtInt, visits: fmtInt, treated: fmtInt, nets: fmtInt},
  width: {title: 220, country: 90, type: 170, protocol: 200, location_name: 140},
  sort: "period_start", reverse: true,
  rows: 25
})
```

<div class="muted" style="font-size: 12px">"hh" marks a target counted in households. Where is the campaign's first target area; DIGIT campaigns can cover several.</div>

<style>
.big { font-size: 28px; font-weight: 600; line-height: 1.1; font-variant-numeric: tabular-nums; }
.card h2 { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); margin: 0 0 4px; }
</style>
