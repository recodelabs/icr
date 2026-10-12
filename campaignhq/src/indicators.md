---
title: DHIS2 indicators
sql:
  values: data/indicator_values.parquet
  catalog: data/indicator_catalog.parquet
---

<link rel="stylesheet" href="npm:maplibre-gl@5/dist/maplibre-gl.css">

# DHIS2 indicators

Indicator values imported from DHIS2, by place and period.

```js
import {unitMap} from "./components/unit-map.js";
import {DEFAULT_BASEMAP} from "./components/map.js";

const toRows = (table) => Array.from(table, (r) => {
  const o = typeof r.toJSON === "function" ? r.toJSON() : {...r};
  for (const k in o) if (typeof o[k] === "bigint") o[k] = Number(o[k]);
  return o;
});
const fmtInt = (n) => n == null ? "—" : Math.round(Number(n)).toLocaleString("en");
// Admin level names per country; other countries fall back to "Level n".
const LEVEL_NAMES = {SLE: ["Country", "District", "Chiefdom"], NGA: ["Country", "State", "LGA"]};
const levelName = (country, level) => LEVEL_NAMES[country]?.[level] ?? `Level ${level}`;
const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
const periodLabel = (p) => /^\d{6}$/.test(p) ? `${MONTHS[Number(p.slice(4)) - 1]} ${p.slice(0, 4)}` : p;
```

```js
const catalog = toRows(await sql`SELECT * FROM catalog`);
const countries = toRows(await sql`SELECT DISTINCT country FROM "values" WHERE country IS NOT NULL ORDER BY 1`).map((d) => d.country);
const withValues = new Set(toRows(await sql`SELECT DISTINCT indicator_id FROM "values"`).map((d) => d.indicator_id));
const indicators = catalog.filter((d) => withValues.has(d.indicator_id));
const geojson = await FileAttachment("data/indicator_units.geojson").json();
```

```js
if (indicators.length === 0) {
  display(html`<p class="muted">No DHIS2 indicator values on the server yet. Import some with
    <code>kiln dhis2 measures</code> and <code>kiln dhis2 reports</code>, load them, and run the warehouse refresh.</p>`);
}
```

<div class="grid grid-cols-4" style="gap: 12px; margin-bottom: 8px">
  <div>${indicatorInput}</div>
  <div>${levelInput}</div>
  <div>${periodTypeInput}</div>
  <div>${periodInput}</div>
</div>

```js
const indicatorInput = Inputs.select(indicators, {
  label: "Indicator",
  format: (d) => `${d.topic ? `${d.topic} · ` : ""}${d.indicator}`,
  value: indicators.find((d) => /penta 3/i.test(d.indicator)) ?? indicators[0]
});
const indicator = Generators.input(indicatorInput);
```

```js
// Levels and period types that this indicator has values for.
const id = indicator?.indicator_id ?? "";
const meta = toRows(await sql([`SELECT country, admin_level, period_type, period, count(*) AS n FROM "values"
  WHERE indicator_id = '${id.replace(/'/g, "''")}' GROUP BY ALL ORDER BY admin_level, period`]));
const country = meta[0]?.country ?? countries[0];
const levels = Array.from(new Set(meta.filter((d) => d.admin_level != null && d.admin_level > 0).map((d) => d.admin_level))).sort();
const periodTypes = Array.from(new Set(meta.map((d) => d.period_type)));
```

```js
const levelInput = Inputs.select(levels, {label: "Map level", format: (l) => levelName(country, l), value: levels[0]});
const level = Generators.input(levelInput);
const periodTypeInput = Inputs.select(periodTypes, {label: "Period type", value: periodTypes.includes("Yearly") ? "Yearly" : periodTypes[0]});
const periodType = Generators.input(periodTypeInput);
```

```js
const periods = Array.from(new Set(meta.filter((d) => d.period_type === periodType).map((d) => d.period))).sort();
// Default to the last complete year rather than the year in progress.
const thisYear = String(new Date().getFullYear());
const defaultPeriod = periodType === "Yearly" ? periods.filter((p) => p < thisYear).at(-1) ?? periods.at(-1) : periods.at(-1);
const periodInput = Inputs.select(periods, {label: "Period", format: periodLabel, value: defaultPeriod});
const period = Generators.input(periodInput);
```

```js
const q = (s) => `'${String(s).replace(/'/g, "''")}'`;
// Every value of the indicator for the chosen period type: map, trend and table read from it.
const series = toRows(await sql([`SELECT * FROM "values" WHERE indicator_id = ${q(id)} AND period_type = ${q(periodType)}`]));
const atPeriod = series.filter((d) => d.period === period);
const unitRows = atPeriod.filter((d) => d.admin_level === level).sort((a, b) => b.value - a.value);
const national = atPeriod.find((d) => d.admin_level === 0);
const percent = indicator?.factor === 100;
const unit = percent ? "%" : indicator?.factor === 1 ? "" : ` per ${fmtInt(indicator?.factor)}`;
const fmtValue = (v) => v == null ? "—" : `${Number(v).toLocaleString("en", {maximumFractionDigits: 1})}${unit}`;
const reported = series[0]?.reported ? new Date(series[0].reported) : null;
```

```js
const best = unitRows[0], worst = unitRows.at(-1);
const unitWord = levelName(country, level).toLowerCase();
```

<div class="grid grid-cols-4" style="gap: 12px">
  <div class="card"><h2>${levelName(country, 0)}, ${periodLabel(period ?? "")}</h2><span class="big">${fmtValue(national?.value)}</span><div class="muted">${national ? (national.denominator != null ? `${fmtInt(national.numerator)} ÷ ${fmtInt(national.denominator)}` : `count ${fmtInt(national.count ?? national.numerator)}`) : "no national value"}</div></div>
  <div class="card"><h2>Highest ${unitWord}</h2><span class="big">${fmtValue(best?.value)}</span><div class="muted">${best?.location_name ?? "—"}</div></div>
  <div class="card"><h2>Lowest ${unitWord}</h2><span class="big">${fmtValue(worst?.value)}</span><div class="muted">${worst?.location_name ?? "—"}</div></div>
  <div class="card"><h2>${levelName(country, level)}s with a value</h2><span class="big">${fmtInt(unitRows.length)}</span><div class="muted">${reported ? `DHIS2 analytics as of ${reported.toLocaleDateString("en", {day: "numeric", month: "short", year: "numeric"})}` : ""}</div></div>
</div>

<div class="grid grid-cols-2" style="gap: 12px; margin-top: 12px">
  <div class="card" style="padding: 0; overflow: hidden">
    <div class="map-title">${indicator?.indicator} by ${unitWord}, ${periodLabel(period ?? "")}</div>
    ${map}
  </div>
  <div class="card">
    <h2>${indicator?.indicator} over time</h2>
    <div class="muted" style="margin-bottom: 6px">${levelName(country, 0)} in black, each ${unitWord} in grey${level > 1 ? " (hover for its name)" : ""}.</div>
    ${trend}
  </div>
</div>

```js
const map = unitMap({geojson, height: 460, basemap: DEFAULT_BASEMAP});
```

```js
{
  const values = new Map(unitRows.map((d) => [d.location_id, d.value]));
  const byId = new Map(unitRows.map((d) => [d.location_id, d]));
  const max = Math.max(1, ...unitRows.map((d) => d.value));
  const nice = (x) => { const p = 10 ** Math.floor(Math.log10(x)); const m = x / p; return (m <= 1 ? 1 : m <= 2 ? 2 : m <= 5 ? 5 : 10) * p; };
  const stops = percent ? [20, 40, 60, 80, 100] : [0.2, 0.4, 0.6, 0.8, 1].map((k) => +(nice(max) * k).toPrecision(2));
  const colors = ["#fde0dd", "#fcc5c0", "#fa9fb5", "#c7e9c0", "#74c476", "#238b45"];
  map.update({
    level, values, stops,
    colors: percent || indicator?.factor !== 1 ? colors : ["#ffffcc", "#c7e9b4", "#7fcdbb", "#41b6c4", "#2c7fb8", "#253494"],
    legend: [`${indicator?.indicator}${unit && unit !== "%" ? ` (${unit.trim()})` : ""}`, (v) => percent ? `${v}%` : v.toLocaleString("en")],
    popup: (lid) => {
      const d = byId.get(lid);
      if (!d) return "no value for this period";
      return `${fmtValue(d.value)}` + (d.denominator != null ? `<br>${fmtInt(d.numerator)} ÷ ${fmtInt(d.denominator)}` : "");
    }
  });
}
```

```js
const nationalSeries = series.filter((d) => d.admin_level === 0);
const unitSeries = series.filter((d) => d.admin_level === level);
const trend = Plot.plot({
  width: Math.max(320, width / 2 - 40),
  height: 420,
  marginLeft: 50,
  x: {label: null, type: "utc"},
  y: {label: unit === "%" ? "%" : null, grid: true, zero: true},
  marks: [
    Plot.line(unitSeries, {x: (d) => new Date(d.period_start), y: "value", z: "location_id", stroke: "#cbd5e1", strokeWidth: 1}),
    Plot.line(nationalSeries, {x: (d) => new Date(d.period_start), y: "value", stroke: "#111", strokeWidth: 2.5, marker: "circle"}),
    Plot.ruleX([new Date(atPeriod[0]?.period_start ?? 0)], {stroke: "#238b45", strokeDasharray: "3,3"}),
    Plot.tip(unitSeries.concat(nationalSeries), Plot.pointer({x: (d) => new Date(d.period_start), y: "value",
      title: (d) => `${d.location_name}, ${periodLabel(d.period)}\n${fmtValue(d.value)}${d.denominator != null ? `\n${fmtInt(d.numerator)} ÷ ${fmtInt(d.denominator)}` : ""}`}))
  ]
});
```

## ${levelName(country, level)}s, ${periodLabel(period ?? "")}

```js
const search = view(Inputs.search(unitRows, {placeholder: `Search ${unitWord}…`, columns: ["location_name", "admin1_name"]}));
```

```js
Inputs.table(search, {
  columns: ["location_name", ...(level > 1 ? ["admin1_name"] : []), "value", "numerator", "denominator"],
  header: {location_name: levelName(country, level), admin1_name: levelName(country, 1), value: indicator?.indicator, numerator: "Numerator", denominator: "Denominator"},
  format: {value: fmtValue, numerator: fmtInt, denominator: fmtInt},
  rows: 20
})
```

<div class="card" style="margin-top: 12px">
  <h2>About this indicator</h2>
  <div>${indicator?.description ?? ""}</div>
  <div class="muted" style="margin-top: 6px">
    ${indicator?.numerator_description ? html`Numerator: ${indicator.numerator_description}<br>` : ""}
    ${indicator?.denominator_description ? html`Denominator: ${indicator.denominator_description}<br>` : ""}
    ${indicator?.indicator_type ?? ""}${indicator?.annualized ? ", annualised (values for periods shorter than a year are scaled to a year, so they can exceed 100%)" : ""} · from ${indicator?.publisher ?? indicator?.source ?? "DHIS2"}
  </div>
</div>

<footer class="muted" style="margin-top: 24px; padding-top: 12px; border-top: 1px solid var(--theme-foreground-faintest); font-size: 12px; line-height: 1.6">
  <p style="margin: 0">
    DHIS2 computes each value for its own place and period: it adds up the numerator and
    the denominator, then divides. The values are imported unchanged (<code>kiln dhis2 reports</code>,
    one <code>MeasureReport</code> per indicator, place and period; <code>IcrIndicatorValue</code> view),
    and are never summed across places or periods here.
  </p>
</footer>

<style>
.big { font-size: 28px; font-weight: 600; line-height: 1.1; }
.map-title { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); padding: 10px 14px 6px; }
.card h2 { font-size: 13px; font-weight: 500; color: var(--theme-foreground-muted); margin: 0 0 4px; }
.maplibregl-popup-content { padding: 6px 9px; }
</style>
