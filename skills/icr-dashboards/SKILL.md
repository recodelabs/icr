---
name: icr-dashboards
description: Where the ICR's data, tables and saved SQL queries are, and how to go from a question answered with the ICR data connector (MCP) to a dashboard page built on the same tables. Use this whenever the work involves ICR campaign data (coverage, campaigns, target populations, endemicity, indicators, locations): analysing it, answering a question from it, or adding or changing a page in `dashboards/`. Use it together with the Observatory `dashboards` skill, which covers how pages are written.
---

# ICR data and dashboards

Use this with the Observatory plugin's `dashboards` skill. That skill says how to write a
page. This one says what the ICR's data is and where its definitions are.

## The same tables in three places

The ICR's FHIR data is turned into tables by the SQL on FHIR ViewDefinitions in the
implementation guide. Every place below holds those same tables.

| Place | What it is | Use it for |
|---|---|---|
| The **ICR data** connector (MCP) | The saved queries at `data.healthcampaigns.org`: `list_queries`, `get_query`, `run_query`, `aggregate`. Refreshed daily from the main FHIR server | Answering a question in the chat; finding out what the data holds before building |
| The **warehouse** | Parquet tables in the R2 bucket `icr`, one warehouse per site. `observatory pull main` caches the main one at `~/.cache/observatory/warehouses/r2/icr/@root`; some machines also have a local copy in `data/`. Refreshed by hand; `manifest.json` in the folder has `refreshed_at` | What the dashboards are built from. Query it with the `duckdb` CLI |
| A site's **`analytics/`** | SQL Libraries the warehouse refresh runs, such as `MainCampaigns` | The joins and rules the dashboards share |

The connector's server and the warehouse are refreshed separately, so a figure can differ by
a recent load. If two numbers disagree, compare each one's refresh time before looking for
a bug. The main data is a Nigerian location registry with campaign data generated for the
demo: the coverage and endemicity figures are not real records.

## Names

A saved query, a ViewDefinition and a warehouse table are the same thing under three names:

| Saved query (connector) | ViewDefinition | Warehouse table |
|---|---|---|
| `ViewIcrCampaignCalendar` | `IcrCampaignCalendar` | `campaign_calendar` |
| `ViewIcrCampaignActivity` | `IcrCampaignActivity` | `campaign_activity` |
| `ViewIcrCampaignTask`, `ViewIcrCampaignTaskOutput` | `IcrCampaignTask`, `…Output` | `campaign_task`, `campaign_task_output` |
| `ViewIcrCoverage`, `ViewIcrCoverageStrata` | `IcrCoverage`, `…Strata` | `coverage`, `coverage_strata` |
| `ViewIcrTargetPopulation` | `IcrTargetPopulation` | `target_population` |
| `ViewIcrLocationStatus` | `IcrLocationStatus` | `location_status` |
| `ViewIcrIndicator`, `…Group`, `…Value`, `…Strata` | `IcrIndicator…` | `indicator`, `indicator_group`, `indicator_value`, `indicator_strata` |
| `ViewLocationHierarchy` | `LocationHierarchy` | `location_hierarchy` |

Three saved queries are joins that exist only on the data server: `IcrCoverageByLocation`,
`IcrPopulationByLocation` and `IcrLocationStatusLocation`. Their SQL is in
`tools/hapi/gcp/data/libraries/`. The dashboards' own joins are the Libraries in
`dashboards/sites/main/analytics/` (`MainCampaigns`, `MainEndemicity`, `MainDenominators`,
`MainIndicatorValues`, `MainIndicatorCatalog`), written to the warehouse as `main_campaigns`
and so on.

## Where the definitions are

- **What a column means:** `ig/input/fsh/viewdefinitions.fsh` (each column has a
  description), and the profiles beside it for the FHIR resources behind the tables.
- **A saved query's SQL and parameters:** `get_query` on the connector, or
  `tools/hapi/gcp/data/libraries/<Name>.sql` and `.toml`. `datapi.md` is the guide for people
  calling the data API directly.
- **A dashboard table's rules** (which report counts, how programmes are labelled):
  the header comment and SQL of `dashboards/sites/<site>/analytics/<Name>.sql`.
- **Which rows must not be added together:** `tools/hapi/gcp/data/mcp/queries.toml`. The
  connector's `aggregate` enforces it. A loader or page has no such check, so apply the same
  rule yourself.
- **How data gets from the FHIR server to the dashboards, and the refresh commands:**
  `tools/warehouse/README.md`. Read it before refreshing a warehouse or deploying.
- **The sites, their pages and how to run them:** `dashboards/README.md`.

## The main site's campaign table

`main_campaigns` (Library `MainCampaigns`, loaded as `data/campaigns.parquet`) has one row
per campaign round and place, with its target and results. Most coverage pages need nothing
else. Check the values with a `GROUP BY` before relying on this list:

- `level`: `lga`, `state`, `national` or `other`. A round can have a state row (target only)
  beside its LGA rows, so use `level = 'lga'` for totals, as the coverage page does.
- `programme`: a label per protocol, such as "LF / onchocerciasis MDA", "Onchocerciasis CDTI"
  and "MR + nOPV2 + NTD integrated". These are separate programmes. When a request names a
  disease that several of them cover, say in the page's notes which ones are included.
- `targeted`: the round's planning denominator.
- `admin_coverage`: not NULL when the round has a reconciled administrative report.
- `reached`: the reconciled figure, or the latest realtime one for a round in progress. Sum
  it only over rows where `admin_coverage IS NOT NULL`, or reconciled and realtime figures mix.
- `result_status`: `reported`, `in progress`, `planned` or `no report`.
- `survey_coverage`, `survey_ci_low`, `survey_ci_high`, `lqas_result`: the independent checks.

## Rules for ICR figures

- **Coverage has kinds.** A row of `coverage` is one report: `source` is administrative,
  survey or lqas; `lineage` is realtime or reconciled; a place can have a state-level and an
  LGA-level report; an integrated campaign reports per activity. Choose one of each before a
  total. The dashboards use the reconciled administrative report for "reached" and show
  surveys beside it.
- **Coverage is a sum over a sum**, not the average of `score`: `sum(numerator) /
  sum(denominator)` on `coverage`, and `sum(reached) / sum(targeted)` over the reported rounds
  on `main_campaigns`, which is what the dashboards show.
- **One admin level per total.** A state's row holds its LGAs' people, in the population
  tables and in the campaign tables.
- **Programmes are not added into one rate.** A rate over LF treatment and a polio campaign
  together means nothing. Counts of rounds across programmes are fine.
- **A target summed across campaigns or years counts people more than once.** Say so where
  it is shown, or leave the "All" choice out of the filter.
- **Place names come from `location_hierarchy`**, joined on the Location id. Filter
  `is_admin` for administrative units; `admin_level` 1 is a state, 2 an LGA in Nigeria.
- **The demo data is not real.** A page on the main site says in its notes that the campaign
  data was generated for the demo.
- **Programme targets.** The site's coverage classes use 80% and 95%. A programme can have
  its own target (WHO's for LF treatment is 65% of the total population). Ask which to show
  when it matters, and name the target on the chart.

## From a question in the chat to a page

1. **Answer it with the connector first.** `list_queries` to find the query, `get_query` to
   read its SQL, then `aggregate` with the kind of row fixed (programme, admin level, source).
   Keep the figures and the choices that produced them.
2. **Find the same data in the warehouse**, using the names table above, and reproduce the
   figure with the `duckdb` CLI on the site's warehouse. If it differs, find out why before
   building (a different refresh, or a different kind of row).
3. **Check whether a dashboard table already has it.** `main_campaigns` already joins
   campaigns, targets and results; most coverage pages need nothing else.
4. **Build the page** following the Observatory `dashboards` skill: add a column to a
   Library or a loader if needed, then the page.
5. **Compare the page's headline figures with step 1.** Say in the page's notes which kind of
   row the figures use, for example "the reconciled administrative report, at LGA level".

Without the connector, do steps 2 to 5 and check the figures against the warehouse alone.

A question the connector cannot answer because no saved query covers it is a reason to
propose a new Library in `tools/hapi/gcp/data/libraries/`, not to work around the connector.
The saved queries are the approved ways into the data.

## Sites that are not the main one

Uganda, DIGIT and Bangladesh each have their own warehouse and site (`dashboards/README.md`
lists them). The connector covers the main server only. Bangladesh's data is sensitive and
its site needs sign-in: do not send its data to any outside service, and do not copy its
figures into chat answers or pull requests.
