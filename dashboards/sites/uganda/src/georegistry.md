---
title: Georegistry
sql:
  registry: data/registry.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# Georegistry

The places Uganda's ICR server knows: the country, its 4 regions and 146 districts and cities, each a FHIR Location with its boundary and codes. Every target, campaign and task points at one of them. Health facilities, parishes and villages are not loaded yet.

```js
import {toRows, fmtInt} from "./components/ichd.js";
import {ugandaMap, UGANDA_BOUNDS} from "./components/uganda-map.js";
```

```js
const units = toRows(await sql`SELECT * FROM registry`);
const byId = new Map(units.map((d) => [d.id, d]));
const regionsList = units.filter((d) => d.admin_level === 1);
```

<div class="grid grid-cols-2" style="gap: 12px; margin-bottom: 8px">
  <div>${regionInput}</div>
  <div id="district-slot"></div>
</div>

```js
const regionInput = Inputs.select(["All", ...regionsList.map((d) => d.name)], {label: "Region", value: "All"});
const region = Generators.input(regionInput);
```

```js
const districtOptions = ["All", ...units.filter((d) => d.admin_level === 2 && (region === "All" || d.region === region)).map((d) => d.name).sort()];
const districtInput = Inputs.select(districtOptions, {label: "District / city", value: "All"});
document.getElementById("district-slot").replaceChildren(districtInput);
const district = Generators.input(districtInput);
```

```js
const districts = units.filter((d) => d.admin_level === 2 && (region === "All" || d.region === region));
const count = (k) => districts.filter((d) => d[k] != null && d[k] !== "").length;
const scopeName = region === "All" ? "Uganda" : region;
```

<div class="grid" style="gap: 12px; grid-template-columns: repeat(5, minmax(0, 1fr))">
  <div class="card"><h2>Regions</h2><span class="big">${region === "All" ? regionsList.length : 1}</span><div class="muted">${scopeName}</div></div>
  <div class="card"><h2>Districts and cities</h2><span class="big">${fmtInt(districts.length)}</span><div class="muted">admin level 2, with boundaries</div></div>
  <div class="card"><h2>With a P-code</h2><span class="big">${fmtInt(count("pcode"))}</span><div class="muted">OCHA COD-AB; new districts have none yet</div></div>
  <div class="card"><h2>With an Overture id</h2><span class="big">${fmtInt(count("gers_id"))}</span><div class="muted">GERS id, the boundary's source</div></div>
  <div class="card"><h2>With a Wikidata id</h2><span class="big">${fmtInt(count("wikidata"))}</span><div class="muted">for linking to other datasets</div></div>
</div>

<div class="grid" style="gap: 12px; margin-top: 12px; grid-template-columns: minmax(0, 2fr) minmax(0, 1fr)">
  <div class="card" style="padding: 0; overflow: hidden">${mapEl}</div>
  <div class="card">
    <h2>Selected place</h2>
    ${inspector}
  </div>
</div>

```js
const pmtiles = await FileAttachment("data/admin.pmtiles").arrayBuffer();
const mapEl = ugandaMap({pmtiles, labels: regionsList, height: 600, choropleth: false});
mapEl.setValues(new Map(), {describe: (id) => {
  const d = byId.get(id);
  return `${d?.pcode ?? "no P-code"}<br><span style="color:#64748b">click to inspect</span>`;
}});
const clicked = Generators.input(mapEl);
```

```js
{
  mapEl.setRegion(region === "All" ? null : region);
  const u = district !== "All" ? units.find((d) => d.admin_level === 2 && d.name === district) : region !== "All" ? regionsList.find((d) => d.name === region) : null;
  mapEl.fit(u ? [[u.xmin, u.ymin], [u.xmax, u.ymax]] : UGANDA_BOUNDS);
}
```

```js
const LABELS = [["id", "Location id"], ["name", "Name"], ["aliases", "Aliases"], ["admin_level", "Admin level"], ["region", "Region"], ["path", "Path"],
  ["pcode", "P-code"], ["iso", "ISO 3166-2"], ["gers_id", "Overture GERS id"], ["wikidata", "Wikidata"], ["description", "Boundary"], ["last_updated", "Last updated"]];
const picked = district !== "All" ? units.find((d) => d.admin_level === 2 && d.name === district) : clicked ? byId.get(clicked.id) : null;
const inspector = !picked
  ? html`<div class="muted">Click a district or city on the map, or choose one above. The fields are the Location's as stored on the server.</div>`
  : html`<div>
      <div style="font-weight: 600; font-size: 15px">${picked.name}</div>
      <div class="muted" style="margin-bottom: 8px">${picked.admin_level === 2 ? "District or city" : picked.admin_level === 1 ? "Region" : "Country"}</div>
      <table style="font-size: 12px; border-collapse: collapse; width: 100%">
        ${LABELS.filter(([k]) => picked[k] != null && picked[k] !== "").map(([k, label]) => html`<tr>
          <td style="color: var(--theme-foreground-muted); padding: 2px 8px 2px 0; vertical-align: top; white-space: nowrap">${label}</td>
          <td style="padding: 2px 0; word-break: break-word">${k === "wikidata" ? html`<a href="https://www.wikidata.org/wiki/${picked[k]}" target="_blank">${picked[k]}</a>` : String(picked[k])}</td></tr>`)}
      </table>
    </div>`;
```

## Districts and cities

```js
const search = view(Inputs.search(districts, {placeholder: "Search name, alias or code…", columns: ["name", "aliases", "pcode", "id", "region"]}));
```

```js
Inputs.table(search, {
  columns: ["name", "region", "id", "pcode", "gers_id", "wikidata", "aliases"],
  header: {name: "District / city", region: "Region", id: "Location id", pcode: "P-code", gers_id: "Overture GERS id", wikidata: "Wikidata", aliases: "Aliases"},
  format: {region: (d) => (d ?? "").replace(" Region", "")},
  width: {name: 130, region: 80, id: 170, pcode: 90, gers_id: 280, wikidata: 90},
  sort: "name",
  rows: 20
})
```

<footer class="muted" style="margin-top: 24px; padding-top: 12px; border-top: 1px solid var(--theme-foreground-faintest); font-size: 12px; line-height: 1.6">
  <p style="margin: 0 0 4px"><a href="https://sdi.healthcampaigns.org/uga/" target="_blank">Uganda SDI</a>: the same registry as a Portolan catalog, with GeoParquet downloads.</p>
  <p style="margin: 0">Boundaries from Overture Maps 2026-10-21.0 (OpenStreetMap contributors, ODbL); Lira City from the 2020 OCHA COD-AB. Entebbe City is merged into Wakiso to match the Ministry's list. The workbook's spellings are kept as aliases.</p>
</footer>

<style>
.big { font-size: 28px; font-weight: 600; line-height: 1.1; font-variant-numeric: tabular-nums; }
.card h2 { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); margin: 0 0 4px; }
.maplibregl-popup-content { padding: 6px 9px; }
</style>
