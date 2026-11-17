# ICR data API

`https://data.healthcampaigns.org` serves the ICR's FHIR data as tables. Each table is the
result of a SQL on FHIR ViewDefinition, refreshed from the FHIR server once a day (02:30 UTC).
You ask for a table by name and get all of its rows as CSV or JSON.

This guide shows how to get a token with your API key, how to query a table, and how to get
NTD endemicity by location, the data behind https://dashboards.healthcampaigns.org/ntd.

The server holds a Nigerian location registry and campaign data generated for the demo. The
endemicity classifications and prevalence figures are not real records.

| | |
| --- | --- |
| Query URL | `https://data.healthcampaigns.org/fhir/$sql-run` |
| List of tables | `https://data.healthcampaigns.org/fhir/Library` |
| Token URL | `https://auth.healthcampaigns.org/realms/icr/protocol/openid-connect/token` |
| Token scope | `system/Library.rs` |
| Token lifetime | 1 hour |
| Formats | `csv`, `json`, `ndjson` |

The examples use `curl`, [`jq`](https://jqlang.org) and [DuckDB](https://duckdb.org).

## How access works

- Your **API key** is a client id (`key-<name>`) and a client secret. It does not expire. Keep
  the secret private, like a password.
- You trade the key for a **token** at the token URL. A token lasts 1 hour.
- You send the token with each query. The data API never sees your secret.
- When a token expires, queries return `401`. Get a new token the same way.

## 1. Save your key

Put the two values you were given in environment variables, so the commands below can use them:

```bash
export ICR_CLIENT_ID=key-yourname
export ICR_CLIENT_SECRET='the secret you were given'
```

## 2. Get a token

```bash
TOKEN=$(curl -s https://auth.healthcampaigns.org/realms/icr/protocol/openid-connect/token \
  -d grant_type=client_credentials \
  -d client_id="$ICR_CLIENT_ID" \
  --data-urlencode client_secret="$ICR_CLIENT_SECRET" \
  -d scope=system/Library.rs | jq -r .access_token)
```

`scope=system/Library.rs` is required. Keycloak also gives a token without it, but the data API
answers that token with `401`.

The full response looks like this; `access_token` is the token and `expires_in` is in seconds:

```json
{
  "access_token": "eyJhbGciOi…",
  "expires_in": 3600,
  "token_type": "Bearer",
  "scope": "system/Library.rs profile email"
}
```

If you get `{"error": "invalid_scope"}`, your key has not been granted access to the data API
yet. Ask the ICR team to grant it.

## 3. See which tables there are

```bash
curl -s -H "Authorization: Bearer $TOKEN" https://data.healthcampaigns.org/fhir/Library \
  | jq -r '.entry[].resource | [.url, .title] | @tsv'
```

Each table has an address of the form `https://icr.healthcampaigns.org/data/Library/<Name>`.
That address is what you pass to a query.

| Name | Rows are |
| --- | --- |
| `LocationHierarchy` | every location, with its name, level and the names of its parents |
| `IcrLocationStatus` | endemicity classifications per location and disease |
| `IcrLocationStatusLocation` | the admin units that have an endemicity classification, with the `LocationHierarchy` columns |
| `IcrCampaignCalendar`, `IcrCampaignActivity` | campaigns and their activities |
| `IcrCampaignTask`, `IcrCampaignTaskOutput` | campaign tasks and what they produced |
| `IcrTargetPopulation` | target populations (denominators) |
| `IcrPopulationByLocation` | census and WorldPop total population per admin unit, side by side |
| `IcrCoverage`, `IcrCoverageStrata` | coverage results, and their breakdowns |
| `IcrCoverageByLocation` | coverage results with their campaign, year, state and LGA |
| `IcrIndicator`, `IcrIndicatorGroup`, `IcrIndicatorStrata`, `IcrIndicatorValue` | indicators and their values |

## 4. Query a table

Pass the table's address as `subjectCanonical` and choose a format:

```bash
curl -H "Authorization: Bearer $TOKEN" -G 'https://data.healthcampaigns.org/fhir/$sql-run' \
  --data-urlencode subjectCanonical=https://icr.healthcampaigns.org/data/Library/IcrLocationStatus \
  --data-urlencode _format=csv > status.csv
```

Keep the single quotes around the URL, or the shell will try to expand `$sql`.

A query returns the whole table. The API takes three parameters and no others:

| Parameter | |
| --- | --- |
| `subjectCanonical` | required: the table's address |
| `_format` | `csv`, `json` or `ndjson` (the default) |
| `_limit` | the most rows to return, for example `_limit=5` to look at a table |

There are no filter parameters yet. A request with one, such as `year=2024`, is refused with
`400`:

```json
{"resourceType":"OperationOutcome","issue":[{"severity":"error","code":"invalid",
 "diagnostics":"unsupported parameter(s): year; this server takes subjectCanonical, _format and _limit"}]}
```

So you download a table and filter its rows yourself, as [section 6](#6-get-mda-coverage-and-filter-it-by-year-state-or-programme)
shows. The coverage table, for example, is 1.3 MB.

## 5. Get endemicity by location

Endemicity is in `IcrLocationStatus`. It refers to a location by id only, so you download
`IcrLocationStatusLocation` as well and join the two. That table has one row for each admin
unit that has an endemicity classification, with its name and the names of its parents.

### Download the two tables

```bash
Q() { curl -sS -H "Authorization: Bearer $TOKEN" -G 'https://data.healthcampaigns.org/fhir/$sql-run' \
        --data-urlencode "subjectCanonical=https://icr.healthcampaigns.org/data/Library/$1" \
        --data-urlencode _format=csv; }

Q IcrLocationStatus > status.csv                # about 670 rows
Q IcrLocationStatusLocation > locations.csv     # about 120 rows
```

### What the endemicity table holds

One row is one classification of one place for one disease, made on one date. In FHIR each row
is an `Observation` (profile ICRLocationStatus) whose subject is the `Location`.

| Column | Meaning | Example |
| --- | --- | --- |
| `observation_id` | id of the Observation | `nga-demo-endem-lf-ba-5001-2022` |
| `location_id` | id of the Location it is about | `nga-ba-5001` |
| `property` | the disease: `lf-endemicity`, `oncho-endemicity`, `schisto-endemicity`, `sth-endemicity`, `trachoma-endemicity` | `lf-endemicity` |
| `status` | the classification: `endemic-under-mda`, `endemic-mda-not-started`, `post-mda-surveillance`, `elimination-validated`, `non-endemic`, `unknown` | `endemic-under-mda` |
| `effective` | when it was assessed | `2022-01-15` |
| `performer` | who made the classification | Bauchi State Ministry of Health, NTD programme |
| `method` | how it was determined | LGA-level ICT mapping survey |
| `evidence` | the source document | ICT mapping survey report, Alkaleri LGA, 2012 |
| `figure_label` | what the supporting figure measures | LF antigenaemia prevalence at mapping (ICT), 15+ years (2012) |
| `figure_value` | the figure | `2.7` |
| `figure_unit` | its unit | `%` |
| `country` | ISO country code | `NGA` |

Three things to know when you read it:

- **A place can have several rows per disease**, one per assessment (for example 2022 and
  2025). The current classification is the row with the newest `effective`.
- **`figure_value` is not always a percentage.** For most rows it is the prevalence the
  classification rests on, with `figure_unit` = `%`. For lymphatic filariasis rows in
  `post-mda-surveillance` it is the number of positive children in the survey, with
  `figure_unit` = `children`. Check `figure_unit` before you treat the value as a rate.
- **A classification covers everything below the place it names.** Most rows name an LGA. A
  row that names a state applies to all of its LGAs unless an LGA has its own row.

### Join the tables

This gives the current classification of each place for each disease, with its state and LGA
names:

```bash
duckdb -c "
COPY (
  WITH current AS (
    SELECT * FROM read_csv('status.csv')
    QUALIFY row_number() OVER (PARTITION BY location_id, property ORDER BY effective DESC) = 1
  )
  SELECT l.admin0_name AS country,
         l.admin1_name AS state,
         l.name        AS location,
         l.admin_level,
         c.location_id,
         replace(c.property, '-endemicity', '') AS disease,
         c.status,
         CAST(c.effective AT TIME ZONE 'UTC' AS DATE) AS assessed,
         c.figure_value, c.figure_unit, c.figure_label,
         c.performer, c.method
  FROM current AS c
  JOIN read_csv('locations.csv') AS l ON l.id = c.location_id
  ORDER BY disease, state, location
) TO 'endemicity_by_location.csv' (HEADER);"
```

The first rows of the result:

| state | location | disease | status | assessed | figure_value | figure_unit |
| --- | --- | --- | --- | --- | --- | --- |
| Bauchi | Alkaleri | lf | post-mda-surveillance | 2025-03-21 | 3.0 | children |
| Bauchi | Bauchi | lf | post-mda-surveillance | 2024-04-05 | 0.0 | children |
| Bauchi | Bogoro | lf | post-mda-surveillance | 2024-05-15 | 3.0 | children |

Changes you can make to the query:

- To keep every assessment and not only the current one, remove the `QUALIFY` line.
- For baseline prevalence rates only, add `WHERE c.figure_unit = '%'` before `ORDER BY`.
- For Nigeria only, add `WHERE l.country = 'NGA'`. The server also holds the Implementation
  Guide's worked examples, so a few rows are about an example place (Kambia District, Sierra
  Leone).

### The location columns

`IcrLocationStatusLocation` has the same columns as `LocationHierarchy`. The ones used above:

| Column | Meaning |
| --- | --- |
| `id` | the Location id; matches `location_id` in the other tables |
| `name` | the location's name |
| `part_of` | id of its parent |
| `admin_level` | 0 country, 1 state, 2 LGA |
| `admin0_name` … `admin4_name` | names of the admin units it sits in, from the country down |
| `admin0_code` … `admin4_code` | their codes |
| `path` | ids from the country down, for example `/nga/nga-ba/nga-ba-5001` |

Other tables that carry a `location_id` join to `LocationHierarchy` the same way.
`LocationHierarchy` has every location (admin units, health facilities, settlements and other
places): about 350,000 rows and 62 MB, which takes about 10 seconds to download.

## 6. Get MDA coverage, and filter it by year, state or programme

`IcrCoverageByLocation` has one row per coverage report, with the campaign it belongs to and
the place it covers. It is the data behind https://dashboards.healthcampaigns.org/coverage. It
needs no join.

### Download the table

```bash
Q IcrCoverageByLocation > coverage.csv     # about 2,900 rows, 1.3 MB
```

(`Q` is the function from section 5.) This is every coverage report for every programme. The
filters below pick out what you want.

### The columns

| Column | Meaning | Example |
| --- | --- | --- |
| `report_id` | id of the MeasureReport | `nga-demo-cov-admin-lf-kn-2024-kn-20004` |
| `campaign_id`, `campaign_title` | the campaign | LF/onchocerciasis MDA (ivermectin + albendazole), 2024 round — Ajingi LGA, Kano |
| `campaign_type` | `mda`, `vaccination-sia`, `integrated`, … | `mda` |
| `protocol` | the campaign's protocol; this is what tells one programme or disease from another | `nga-demo-proto-lf-oncho-mda` |
| `round`, `campaign_status` | the campaign's round number and status | `1`, `completed` |
| `year` | the year the campaign started | `2024` |
| `country` | ISO country code | `NGA` |
| `location_id`, `location_name`, `admin_level` | the place the report covers | `nga-kn-20004`, Ajingi, `2` |
| `state`, `lga` | the names of its state and LGA | Kano, Ajingi |
| `measure` | what was measured | `icr-mda-treatment-coverage` |
| `source` | `administrative` (reported counts), `survey` or `lqas` | `administrative` |
| `lineage` | `reconciled` (final) or `realtime` (while the round runs) | `reconciled` |
| `denominator_type` | which population the denominator is | `at-risk` |
| `period_start`, `period_end`, `reported` | the period covered, and when it was reported | |
| `numerator` | people reached (treated) | `181036` |
| `denominator` | people targeted; for a survey, the sample size | `246227` |
| `score` | coverage, from 0 to 1 | `0.735` |
| `ci_low`, `ci_high`, `sample_design` | for surveys: the confidence interval and the design | |
| `reporter` | who reported it | |

### The protocols for MDA programmes

| `protocol` | Programme |
| --- | --- |
| `nga-demo-proto-lf-oncho-mda` | lymphatic filariasis and onchocerciasis MDA (ivermectin + albendazole) |
| `nga-demo-proto-oncho-cdti` | onchocerciasis, community-directed treatment with ivermectin |
| `nga-demo-proto-sch-sth-school-mda` | schistosomiasis and soil-transmitted helminths, school MDA |
| `nga-demo-proto-trachoma-mda` | trachoma MDA |

To see every protocol in the table: `duckdb -c "SELECT DISTINCT campaign_type, protocol FROM 'coverage.csv'"`.

### Filter by programme

All LF MDA coverage, as reported by the programme (administrative coverage, final figures):

```bash
duckdb -c "
COPY (
  SELECT year, state, lga, campaign_title, period_start, period_end,
         numerator AS treated, denominator AS at_risk, score AS coverage, reporter
  FROM 'coverage.csv'
  WHERE protocol = 'nga-demo-proto-lf-oncho-mda'
    AND source = 'administrative' AND lineage = 'reconciled'
  ORDER BY year, state, lga
) TO 'lf_mda_coverage.csv' (HEADER);"
```

This gives 341 rows, one per LGA and round, from 2022 to 2026. Leave out the `source` and
`lineage` line to keep the survey results too (59 more rows).

### Filter by year, by state, or both

Add conditions to the `WHERE` line:

```sql
  WHERE protocol = 'nga-demo-proto-lf-oncho-mda'
    AND source = 'administrative' AND lineage = 'reconciled'
    AND year = 2024              -- one year
    AND state = 'Kano'           -- one state
```

Other forms: `year BETWEEN 2023 AND 2025`, `state IN ('Kano', 'Jigawa')`.

### Totals by year or by state

Coverage for a group of LGAs is people treated over people at risk, summed. Do not average the
LGAs' `score` values.

```bash
duckdb -c "
SELECT year, count(*) AS lgas, sum(numerator) AS treated, sum(denominator) AS at_risk,
       round(sum(numerator) / sum(denominator), 3) AS coverage
FROM 'coverage.csv'
WHERE protocol = 'nga-demo-proto-lf-oncho-mda'
  AND source = 'administrative' AND lineage = 'reconciled'
GROUP BY year ORDER BY year;"
```

| year | lgas | treated | at_risk | coverage |
| --- | --- | --- | --- | --- |
| 2022 | 94 | 17,562,740 | 24,545,927 | 0.716 |
| 2023 | 91 | 17,222,994 | 24,403,015 | 0.706 |
| 2024 | 74 | 15,005,327 | 20,523,872 | 0.731 |
| 2025 | 48 | 10,342,663 | 13,893,008 | 0.744 |
| 2026 | 34 | 7,079,699 | 9,484,594 | 0.746 |

For states in one year, group by `state` and add `AND year = 2024`:

| state | lgas | coverage |
| --- | --- | --- |
| Bauchi | 7 | 0.714 |
| Gombe | 8 | 0.758 |
| Jigawa | 20 | 0.715 |
| Kano | 35 | 0.729 |
| Yobe | 4 | 0.825 |

## 7. Get census and WorldPop population by LGA

`IcrPopulationByLocation` has two estimates of how many people live in each admin unit, side by
side: the census projection the campaigns were planned against, and the WorldPop grid summed
over the unit's boundary. It is the data behind https://dashboards.healthcampaigns.org/targeting.
It needs no join.

### Download the table

```bash
Q IcrPopulationByLocation > population.csv     # about 810 rows, 60 KB
```

One row is one admin unit in one estimate year. The table has every admin unit with at least
one of the two estimates: for Nigeria in 2026, the country, 37 states and 774 LGAs. All of them
have a WorldPop figure. The census projection is there for 5 states (Bauchi, Gombe, Jigawa,
Kano, Yobe) and their 119 LGAs; elsewhere `census` and the difference columns are empty.

### The columns

| Column | Meaning | Example |
| --- | --- | --- |
| `country` | ISO country code | `NGA` |
| `location_id`, `location_name` | the admin unit | `nga-kn-20004`, Ajingi |
| `admin_level` | 0 country, 1 state, 2 LGA | `2` |
| `state`, `lga` | the names of its state and LGA | Kano, Ajingi |
| `year`, `estimate_date` | the year the estimates are for | `2026`, `2026-01-01` |
| `census` | total population, census projection | `321507` |
| `worldpop` | total population, WorldPop | `208063` |
| `worldpop_calculated` | true where the WorldPop figure is the sum of the units below it, as for states | `false` |
| `difference` | `worldpop` minus `census` | `-113444` |
| `difference_share` | the difference as a share of the census figure | `-0.3529` |

### Filter by level, state or year

LGAs that have both estimates, largest disagreement first:

```bash
duckdb -c "
COPY (
  SELECT state, lga, year, census, worldpop, difference, difference_share
  FROM 'population.csv'
  WHERE admin_level = 2 AND census IS NOT NULL
  ORDER BY abs(difference_share) DESC
) TO 'census_vs_worldpop_by_lga.csv' (HEADER);"
```

Add `AND state = 'Kano'` for one state, or `AND year = 2026` for one year. For states, use
`admin_level = 1`; for every LGA, with or without a census figure, leave out
`AND census IS NOT NULL`.

The first LGAs of Kano:

| state | lga | year | census | worldpop | difference | difference_share |
| --- | --- | --- | --- | --- | --- | --- |
| Kano | Ajingi | 2026 | 321,507 | 208,063 | -113,444 | -0.3529 |
| Kano | Albasu | 2026 | 349,473 | 296,282 | -53,191 | -0.1522 |
| Kano | Bagwai | 2026 | 300,901 | 289,941 | -10,960 | -0.0364 |

The five states:

| state | census | worldpop | difference_share |
| --- | --- | --- | --- |
| Bauchi | 9,604,794 | 7,938,273 | -0.1735 |
| Gombe | 4,504,775 | 3,653,283 | -0.1890 |
| Jigawa | 8,587,319 | 6,742,395 | -0.2148 |
| Kano | 17,510,245 | 15,845,286 | -0.0951 |
| Yobe | 4,086,830 | 4,398,047 | 0.0762 |

For other populations (at-risk, age groups, planning denominators, and places that are not
admin units), use `IcrTargetPopulation`. It has one row per estimate, with `source`,
`denominator_type`, `age_low`, `age_high` and `location_id`.

## Errors

| Response | Cause |
| --- | --- |
| `401` | no token, the token has expired, or it was asked for without `scope=system/Library.rs`. Get a new one. |
| `invalid_scope` from the token URL | the key has not been granted access to the data API |
| `unauthorized_client` from the token URL | wrong client id or secret |
| `404` | unknown table address |
| `400` | unsupported `_format` |
| `503` | the first refresh has not finished; try again later |

## For the ICR team: give someone access

On the `icr-hapi` VM, from `/opt/icr-hapi/gcp`:

```bash
k()  { sudo docker compose exec -T keycloak bash -s -- "$@" < gateway/api-key.sh; }
kd() { sudo docker compose exec -T keycloak bash -s -- "$@" < data/keycloak.sh; }
k create yourname     # prints the client id and secret to send them
kd grant yourname     # lets the key ask for system/Library.rs
```

More on running the service is in `tools/hapi/gcp/data/README.md`.
