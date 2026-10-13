# sldash — Sierra Leone dashboards

Health dashboards for Sierra Leone modelled on the dashboards of the DHIS2 demo server
(play.dhis2.org, "Sierra Leone"), drawn from the DHIS2 data held in the ICR registry. Each
page follows one DHIS2 dashboard item by item, with the item's DHIS2 title, so the two can be
compared side by side. Lives in `campaignhq/sldash/` as its own site, with the same stack as Campaign Dashboards: [Observable Framework](https://observablehq.com/framework/),
DuckDB-WASM over parquet, MapLibre, built to static files.

```
DHIS2 (play.dhis2.org) ──kiln dhis2 locations/measures/reports──▶ NDJSON ──kiln load──▶ HAPI
HAPI ──tools/warehouse/refresh.sh──▶ data/parquet/{locations, indicator, indicator_value}
data/parquet ──src/data/values.parquet.sh, units.geojson.sh──▶ this site
```

## Run

```bash
tools/warehouse/refresh.sh      # (repo root) regenerate data/ from the FHIR server
cd campaignhq/sldash
npm install
npm run dev                     # preview at http://127.0.0.1:3000
npm run build                   # static site in dist/
```

The loaders read the repo's `data/` (`../../data`) by default; set `DATA=/path/to/hub` to point them at another
copy, and `COUNTRY` (default `SLE`) for another country's partition.

## Pages

One page per DHIS2 dashboard, under its DHIS2 name, rebuilding 129 of the 14 dashboards'
data items. The Overview has one card and one national figure per dashboard.

| Page | Items | Not shown, and why |
|---|---|---|
| Antenatal Care | 11 of 11 | — |
| Delivery | 11 of 11 | — |
| Disease Surveillance | 3 of 4 | messages box |
| Immunization | 17 of 17 | (no catchment radius on the facility-type map, no 80% target line) |
| Immunization data | 10 of 10 | "BCG doses given at facility <1 Fixed" shows Fixed doses of all ages; "Indicators MCHP in Bo" is empty because DHIS2 has no values for those facilities |
| Key Indicators | 6 of 6 | — |
| Malnutrition | 5 of 7 | messages and resources boxes |
| Measles | 6 of 6 | — |
| Mother and Child Health | 14 of 17 | messages, reports and one empty item |
| Nutrition | 5 of 6 | messages box |
| Reporting Rates | 8 of 8 | — |
| Reporting Reproductive Health | 10 of 11 | messages box |
| Staffing | 2 of 2 | — |
| Visits ANC | 3 of 3 | — |

A "This year" picker at the top of each page anchors DHIS2's relative periods (this year,
last 10 years, last 4 quarters, last 12 months, last six-month). As in DHIS2, "last" periods
leave out the month, quarter or half-year in progress. Where DHIS2 combines this month and
last month (or quarter) into one value, the page shows the latest complete one and says so.

Left out on purpose: the dashboards built on tracker and event data (Cases Malaria, the four
Inpatient dashboards, Top Contacts), the Earth Engine imagery maps (EE maps) and Info Videos.

Facility maps show the 601 of 1,166 facilities that have coordinates in DHIS2. Facility-level
values were imported for 2025 and 2026 (live births for the last 4 quarters), so facility
items for earlier years are empty.

## Data tables

| Loader | From | One row per |
|---|---|---|
| `values.parquet` | `IcrIndicatorValue` + `IcrIndicator` + locations | item × place × period, with `value` as DHIS2 shows it |
| `strata.parquet` | `IcrIndicatorStrata` | breakdown option (Fixed/Outreach, Facility Type) of a value |
| `groups.parquet` | `IcrIndicatorGroup` | item × DHIS2 group (incl. the Diagnosis and Morbidity/Mortality group sets) |
| `facilities.parquet` | the Location snapshot in `data/raw/` | facility, with chiefdom, district, Facility Type and position |
| `units.geojson` | locations | country, district and chiefdom boundaries |

## What the data is

The demo DHIS2's data is generated for training; it is not real Sierra Leone data. It was
read with `kiln dhis2` (instance `sl-demo`, tag `sl-demo` on every resource) and loaded into
the hosted HAPI: the org unit tree as Locations (facilities with their Facility Type), 199
Measures (indicators, data elements, the morbidity data elements and six data set reporting
rates) and 161,216 MeasureReports, some with Fixed/Outreach and Facility Type breakdowns. `project/dhis2-indicators.md` has the
commands. DHIS2 computes each indicator value for its own place and period; the pages never
sum indicator values across places or periods (data element counts, such as doses given,
are summed only in the cumulative line, as DHIS2 does).

## Layout

- `src/components/dhis2.js` — the colours, the legend sets, dashboard item card, gauge,
  pie and pivot table. The colours are muted rather than DHIS2's: one series palette, and
  one softened red (poor) to yellow to green (good) ramp that every legend set uses, in
  place of the demo's bright red-to-green, yellow-to-red and blue legends.
- `src/components/charts.js` — column, stacked column, line and year-over-year charts, and the
  thematic map colouring (legend set, or DHIS2's five equal-interval classes).
- `src/components/page.js` — loading a page's DHIS2 items, `pick()`, and the relative periods.
- `src/components/unit-map.js` — the MapLibre choropleth over `units.geojson`.
