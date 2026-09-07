---
title: About the data
---

# About the data

CampaignHQ is a static site. Everything it shows was generated from the FHIR
registry ahead of time and shipped as parquet and PMTiles; the browser runs
DuckDB (WebAssembly) over those files. Nothing here talks to a server at
runtime.

```js
const manifest = await FileAttachment("data/manifest.json").json();
```

<div class="grid grid-cols-3">
  <div class="card"><h2>Last refresh</h2><span class="big">${new Date(manifest.refreshed_at).toLocaleString("en", {dateStyle: "medium", timeStyle: "short"})}</span><div class="muted">${manifest.server}</div></div>
  <div class="card"><h2>Location registry</h2><span class="big">${manifest.tables.locations?.rows.toLocaleString("en")}</span><div class="muted">locations (kiln ${manifest.kiln?.kiln_version})</div></div>
  <div class="card"><h2>Campaign rows</h2><span class="big">${manifest.tables.campaign_calendar?.rows.toLocaleString("en")}</span><div class="muted">from ${Object.keys(manifest.views).length} ViewDefinition${Object.keys(manifest.views).length === 1 ? "" : "s"}</div></div>
</div>

## How the data gets here

1. **The registry is FHIR.** Campaigns are `CarePlan`s (one umbrella per round, one
   per state, one per LGA, linked by `partOf`), protocols are `PlanDefinition`s,
   planning denominators are `Group`s, and places are `Location`s with GRID3
   boundaries and settlements.
2. **SQL-on-FHIR ViewDefinitions** in the ICR Implementation Guide say how those
   resources flatten to tables. `IcrCampaignCalendar` gives one row per campaign per
   geography; `IcrTargetPopulation` gives the denominators. Any conformant runner
   produces the same tables.
3. **`tools/warehouse/refresh.sh`** exports the resources from the server, runs the
   views (octofhir-sof), writes hive-partitioned parquet under `data/parquet/`, runs
   kiln for the location GeoParquet, and builds the admin-boundary PMTiles.
4. **This site's data loaders** (`src/data/*.sh`) join those tables with DuckDB at
   build time into the two parquet files the pages query, plus the tiles.

```js
Inputs.table(Object.entries(manifest.views).map(([name, v]) => ({name, resource: v.resource, status: v.status, url: v.url})), {header: {name: "ViewDefinition", resource: "Base resource", status: "Status", url: "Canonical"}})
```

## What is demo data

The Nigeria calendar (Bauchi, Kano, Jigawa, Gombe, Yobe; 2022–2027) is synthetic
but realistic: polio rounds, measles campaigns and NTD MDAs shaped on published
schedules and endemicity, with populations projected from the 2006 census. It is
tagged `nga-demo` in the registry. The four Sierra Leone campaigns are the IG's
worked examples. See `tools/campaign-builder/README.md` for what is sourced and
what is assumed.

**People reached** is blank on purpose: delivery events (immunizations, drug
administrations) are not loaded yet. When they are, a third ViewDefinition adds
them and the column fills in without changing anything else here.

<style>
.big { font-size: 24px; font-weight: 600; line-height: 1.1; }
.card h2 { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); margin: 0 0 4px; }
</style>
