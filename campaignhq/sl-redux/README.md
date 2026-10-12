# sl-redux — Sierra Leone dashboards, redrawn

The 14 Sierra Leone dashboards of the DHIS2 demo server, with the same indicators as
[`../sldash`](../sldash/README.md) but drawn for comparing districts rather than copying
the DHIS2 layout. Same data, same stack: [Observable Framework](https://observablehq.com/framework/),
DuckDB-WASM over parquet, MapLibre, built to static files.

## Run

```bash
tools/warehouse/refresh.sh      # (repo root) regenerate data/ from the FHIR server
cd campaignhq/sl-redux
npm install
npm run dev                     # preview at http://127.0.0.1:3000
npm run build                   # static site in dist/
```

The loaders in `src/data/` are copies of sldash's and read the repo's `data/` by default;
set `DATA=/path/to/hub` to read another copy, and `COUNTRY` (default `SLE`) for another
country's partition.

## How the pages work

Every page has the same parts:

- **Filter bar** (sticky): the year, the districts, and whether maps show districts or
  chiefdoms. Picking districts filters every chart on the page to them; picking exactly one
  switches the headline figures and the single-place charts to that district.
- **Headline figures**: the dashboard's main indicators for the year, the change on the year
  before, and a sparkline of the last 12 months (or 10 years).
- **Compare districts**: one block per page (`src/components/compare.js`). Choose any of the
  page's indicators to get a map, a ranking of districts against last year with the country
  as a dashed line (or, for chiefdoms, every chiefdom as a dot in its district's row), the
  trend with the picked districts in colour, and a table with DHIS2's numerator and denominator.
- **The dashboard's own items**, redrawn: heatmaps (district × month, district × year),
  dot ladders (several indicators per district), 100% bars (facility type, fixed/outreach),
  scatter plots (two indicators per district), slope charts, small multiples and scorecards.

Charts are kept short and use one colour scale throughout: orange is worse and blue is
better, reversed for indicators where lower is better (drop-out, malnutrition, maternal
deaths, diarrhoea incidence). Counts use a single indigo ramp. Coverage-type percentages
share fixed breaks (40, 55, 70, 80, 90); other values use quantile breaks.

| File | What it holds |
|---|---|
| `src/components/data.js` | loading, periods (stopping at the last complete month), filtering by district |
| `src/components/theme.js` | colours, which indicators are "lower is better", number formats |
| `src/components/viz.js` | the chart types (Plot) |
| `src/components/compare.js` | the filter bar, the headline figures and the comparison block |
| `src/components/unit-map.js` | the MapLibre choropleth (zooms to the picked districts) |

## Pages

| Page | Items redrawn as |
|---|---|
| Overview | a card per dashboard with its headline indicator and the districts on one line; a scorecard of the 14 headline indicators |
| Antenatal Care | coverage heatmaps by quarter and month, year-on-year bars, running totals, facility type and fixed/outreach shares |
| Delivery | three delivery rates per district, ANC → delivery heatmap, skilled attendance scatter, place of birth shares, facility births heatmap |
| Disease Surveillance | cases by diagnosis (stacked), new cases by diagnosis × district, reporting against incidence |
| Immunization | vaccine ladder with the 80% target, Penta 1 vs Penta 3, ten-year heatmap, slope and small multiples, doses by facility type and fixed/outreach |
| Immunization data | coverage by vaccine × month, year-on-year, doses scorecard, doses by facility type |
| Key Indicators | scorecard of every key indicator by district, ladders by programme, weight-for-height shares |
| Malnutrition | trends, severe malnutrition by month, scorecard, ten-year small multiples |
| Measles | coverage against drop-out, cases by district and chiefdom, facility type |
| Mother and Child Health | coverage ladder, drop-out ranking with the 25% target, monthly trends, facility type and outreach |
| Nutrition | weight-for-height shares, reports against malnutrition, monthly heatmap |
| Reporting Rates | form × district × month heatmap with a form picker, trends, scorecard |
| Reporting Reproductive Health | forms by month, last month against the year, scorecard |
| Staffing | staff by cadre over two half-years, district × cadre scorecard, workload map |
| Visits ANC | bullets against last year in place of gauges, district ladder |

Every value is DHIS2's own figure for its place and period. Values are added up only where
DHIS2 adds them too: counts across visit numbers, facility types, fixed/outreach, diagnosis
groups, or staff cadres for the total.
