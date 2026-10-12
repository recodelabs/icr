---
title: DHIS2 indicators into the ICR as Measures and MeasureReports
version: 0.2.0
last_modified: 2026-10-12T04:20:00Z
status: built; 14 DHIS2 demo dashboards rebuilt in sldash; Sierra Leone demo loaded
tags:
  - icr
  - dhis2
  - kiln
  - measurereport
---

# DHIS2 indicators into the ICR as Measures and MeasureReports

<sub>`v0.2.0 · Last modified Oct 12, 2026 at 12:20 AM EDT`</sub>

Plan for the import half of workplan item 5.2 (the bidirectional DHIS2 connector): connect
to a DHIS2 instance, turn its indicators into FHIR `Measure` resources and its indicator
values into `MeasureReport` resources, load them into the ICR, and show them in
CampaignHQ the way the coverage pages show campaign results. The export direction (ICR
coverage reports into DHIS2 data values) is in [[dhis2]].

## Decisions

- **The tool is kiln.** New `kiln dhis2` subcommands. They reuse kiln's HTTP client, its
  API-key support, `kiln load`, and the Location snapshot that the org-unit mapping reads.
  `kiln population` already writes Groups the same way.
- **First instance: the Sierra Leone demo** (`play.im.dhis2.org`, DHIS2 2.41). It is open
  (`admin` / `district`) and has data for 2020–2026. Nigeria's national DHIS2
  (`dhis2nigeria.org.ng/dhis`) is online but needs credentials; whether it has usable data
  is unknown.
- **The Sierra Leone hierarchy comes from DHIS2 too.** Org units become ICR Locations
  (country, 13 districts, 152 chiefdoms, 1,166 facilities). The nine Sierra Leone IG
  example Locations (`example-country`, `example-district`, …) were deleted from the
  hosted HAPI on 2026-10-11 so the two hierarchies do not overlap. The other IG example
  resources that point at them were left in place.
- **DHIS2 identifiers go into the registry.** Each Location carries its DHIS2 org-unit UID
  as an identifier, so every later run maps org units to Locations through the registry.
- **Score convention:** `measureScore` is the DHIS2 value divided by the indicator type's
  factor, so 45.18 % is stored as 0.4518, the same as the ICR coverage reports. The factor
  is recorded on the Measure so dashboards can show a percent.

## How DHIS2 serves indicators

- An indicator is a formula: a numerator expression, a denominator expression (`#{de}` is
  a data element total, `#{de.coc}` one disaggregation), an indicator type with a factor
  (100 for percent, 1 for a plain number), and an `annualized` flag.
- Values are computed by `GET /api/analytics` over three dimensions: `dx` (indicators),
  `pe` (ISO periods such as `202501`, `2025Q1`, `2025`, or relative ones such as
  `LAST_12_MONTHS`) and `ou` (org units, or `LEVEL-n`).
- `includeNumDen=true` adds the numerator and denominator to each row:
  `dx, pe, ou, value, numerator, denominator, factor, multiplier, divisor`.
  `skipRounding=true` returns the value unrounded.
- DHIS2 adds up the numerator and denominator for each org unit and period, then divides.
  Indicator values must never be summed or averaged across places or periods; ask DHIS2
  for each one.
- Results reflect the last analytics table run: `lastAnalyticsTableSuccess` in
  `/api/system/info`.
- Authentication: personal access token (`Authorization: ApiToken d2pat_…`) or Basic.

Live example from the Sierra Leone demo, Penta 3 coverage nationally:

| period | value | numerator | denominator | factor | divisor |
|---|---|---|---|---|---|
| 2024 | 28.57 | 62,260 | 217,339 | 99.73 | 366 |
| 2025 | 27.98 | 62,045 | 221,781 | 100 | 365 |

## Mapping

### Org unit → Location (`kiln dhis2 locations`)

| DHIS2 | FHIR |
|---|---|
| org unit UID | `Location.identifier` (`use = official`, system per instance) and the id `sle-<uid>` |
| name, code | `name`, a second identifier for the code |
| parent | `partOf` |
| level 1–3 | `type = admin-unit`, admin level from the DHIS2 level |
| facility level (4) | a facility Location plus its Organization, as kiln already models facilities |
| geometry Polygon / MultiPolygon | boundary |
| geometry Point | `position` |

### Indicator → Measure (`kiln dhis2 measures`)

| DHIS2 | FHIR |
|---|---|
| indicator UID | `identifier`, and part of the canonical `url` and the id |
| name, description | `title`, `description` |
| indicator type percent | `scoring = proportion` |
| other factor (per 1,000 …) | `scoring = ratio` |
| number (denominator `1`) | `scoring = cohort`, a single population |
| numerator / denominator expression and description | `group.population[numerator / denominator].criteria` |
| factor, annualized, decimals | extensions on the Measure |
| indicator groups | `topic` |

### Indicator value → MeasureReport (`kiln dhis2 reports`)

| DHIS2 analytics row | FHIR |
|---|---|
| dx | `measure` (canonical of the Measure above) |
| ou | `subject` = the Location carrying that UID |
| pe | `period.start` / `period.end`, computed from the ISO period |
| numerator, denominator | `group.population` counts |
| value ÷ factor | `group.measureScore` |
| `lastAnalyticsTableSuccess` | `date` |
| (fixed) | `status = complete`, `type = summary` |
| instance | `reporter` (the DHIS2 instance's organization), `meta.tag` |

Report ids are deterministic, `<prefix>-<indicator>-<orgunit>-<period>`, so a re-run
updates the same reports (`kiln load` PUTs by id). Breakdowns by category are a later
step: DHIS2 can only break an indicator down by a category that every part of its
formula has.

## DHIS2 behaviour the tool has to handle

- **Annualized indicators:** value ≠ numerator ÷ denominator × factor. The DHIS2 value is
  the score; the numerator and denominator are kept as returned.
- **Fractional counts:** FHIR `population.count` is an integer, DHIS2 returns `"7589.0"`
  and some numerators are fractional. Round, and report every rounded value.
- **Missing values return no row.** No row means no report, not a zero.
- **Row limit:** queries over ~50,000 rows fail (E7128). Split by indicator, org-unit
  level and period.
- **Caching:** analytics responses are cacheable for up to two weeks; send
  `Cache-Control: no-cache`.
- **Late data:** each run re-pulls the trailing periods.
- **Denominators from longer periods:** the yearly population is used unchanged as the
  denominator of monthly and quarterly values.

## Steps

1. **Done.** `kiln dhis2 locations`: org units → Locations (+ facility Organizations)
   with DHIS2 identifiers. An admin unit without geometry (the Sierra Leone national
   unit) gets the union of its children's boundaries.
2. **Done.** `kiln dhis2 measures`: indicator groups or single indicators → Measures.
3. **Done.** `kiln dhis2 reports`: analytics → MeasureReports, mapped through the
   Locations, with the Location name as `subject.display`.
4. **Done.** IG: extensions `dhis2-indicator` and `dhis2-period`; ViewDefinitions
   `IcrIndicator` (every Measure) and `IcrIndicatorValue` (the DHIS2 values), which
   the warehouse refresh writes to `data/parquet/indicator/` and
   `data/parquet/indicator_value/`.
5. **Done.** CampaignHQ page `/indicators`: indicator, map level and period
   pickers; country, highest and lowest unit; choropleth; trend of the country and
   every unit; table with numerator and denominator. Boundaries come from a GeoJSON
   loader, not the Nigeria tiles, so any country works.
6. **Done.** `kiln dhis2 measures/reports --data-element-group/--data-element`: aggregate
   data elements (doses given, live births, …) as count (`cohort`) Measures, valued at
   their total over all disaggregations.
7. **Done.** `campaignhq/sldash/`: a second Observable Framework site, "Sierra Leone dashboards",
   rebuilding 14 of the DHIS2 demo's 22 dashboards item by item (129 items: columns,
   stacked and 100% stacked, pies, gauges, year-over-year, pivots with DHIS2 legend sets,
   district, chiefdom and facility maps). The other eight are built on tracker or event
   data, imagery or video. See `campaignhq/sldash/README.md`.
8. **Done.** Reporting rates (`--data-set`: actual ÷ expected reports), data element group
   sets (`--data-element-group-set`, with group-set-coded `Measure.topic`), breakdowns
   (`--breakdown`: categories and org unit group sets as `group.stratifier`), and org unit
   group sets on Locations (`--group-set`, e.g. Facility Type). IG views
   `IcrIndicatorStrata` and `IcrIndicatorGroup`. kiln PR: recodelabs/kiln#23.
9. Later: `kiln dhis2 match` for countries whose Locations already exist (Nigeria),
   by hierarchy and name, then geometry; breakdowns as stratifiers; program
   indicators; incremental runs that only send changed values.

## What is on the hosted server

Loaded on 2026-10-12 from the Sierra Leone demo (DHIS2 2.41.10, tag `sl-demo`). The
demo's data is generated by DHIS2 for training, not real Sierra Leone figures.

| Resource | Count | Command |
|---|---|---|
| Location | 1,332 (country, 13 districts, 152 chiefdoms, 1,166 facilities) | `kiln dhis2 locations --instance sl-demo --id-prefix sle --country-code SLE` |
| Organization | 1,166 (one per facility) | (same) |
| Measure | 199 now (first loads: 58: indicator groups Immunization, ANC, Deliveries; data element groups Immunization, ANC, Delivery; two live-birth indicators | `kiln dhis2 measures --indicator-group srxUNt2w5jn --indicator-group oehv9EO3vP7 --indicator-group LWvy9lMdSlH --data-element-group h9cuJOkOwY2 --data-element-group qfxEYY9xAl6 --data-element-group t5W0AAqvK5b` (+ `--indicator RdkKj1rVp8R --indicator Rigf2d2Zbjp`)); then every indicator, data element and reporting rate the 14 dashboards use, and the Diagnosis group set |
| MeasureReport | 161,216 now, some with Fixed/Outreach and Facility Type strata, facility-level values for 2025–2026 (first loads: about 100,700: country and districts × 2016–2026, quarters and months of this year and last; chiefdoms × 2016–2026 (and the last 12 months for the first 22 indicators) | `kiln dhis2 reports … --level 1 --level 2 --period 2016 … --period 2026 --period LAST_4_QUARTERS --period QUARTERS_THIS_YEAR --period MONTHS_THIS_YEAR --period MONTHS_LAST_YEAR`, then `--level 3` with the years) |

Each export takes under a minute. Loading into the hosted HAPI runs at about 1,000
MeasureReports a minute (250 per transaction).

## Sources

- DHIS2 analytics API: https://docs.dhis2.org/en/develop/using-the-api/dhis-core-version-241/analytics.html
- DHIS2 metadata API: https://docs.dhis2.org/en/develop/using-the-api/dhis-core-version-241/metadata.html
- IHE mADX (aggregate MeasureReports): https://profiles.ihe.net/QRPH/mADX/
- WHO SMART immunization Measures: https://github.com/WorldHealthOrganization/smart-immunizations
- DHIS2 FHIR IG (Location identifier types): https://github.com/dhis2/dhis2-fhir-ig
