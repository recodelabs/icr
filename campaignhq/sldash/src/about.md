---
title: About
---

# How DHIS2 data becomes FHIR

These dashboards show the Sierra Leone figures from the DHIS2 demo server (play.dhis2.org).
The figures do not come from DHIS2 directly. They were copied into a FHIR server, which
stores health data in a standard format called FHIR, and every chart here is drawn from
that FHIR copy. The point is to show that DHIS2's data, and dashboards
built on it, can be carried over into FHIR without losing anything.

This page explains how that works, starting with the parts of FHIR the dashboards rely on.

## The data passes through four steps

```mermaid
flowchart LR
  A["<b>DHIS2</b><br/>play.dhis2.org<br/>Sierra Leone demo"] -->|"kiln dhis2<br/>reads the DHIS2 API"| B["<b>FHIR server</b><br/>(HAPI FHIR)"]
  B -->|"fhir-warehouse<br/>turns records into tables"| C["<b>Data warehouse</b><br/>parquet files"]
  C -->|"any BI tool<br/>(here, DuckDB)"| D["<b>These dashboards</b>"]
  classDef box fill:#f8fafc,stroke:#94a3b8,color:#1f2937
  class A,B,C,D box
```

1. **kiln dhis2** asks DHIS2 for its places, its indicator definitions and its indicator
   values, and writes each as a FHIR record.
2. Those records are loaded into a **FHIR server**, where any FHIR tool can read them.
3. **fhir-warehouse** downloads them again and flattens them into tables, one row per value.
4. The **dashboards** are built from those tables. Here they use DuckDB to draw the same
   charts the DHIS2 dashboards draw.

## FHIR in brief

FHIR (Fast Healthcare Interoperability Resources) is a standard for exchanging health data.
It describes each kind of thing as a **resource**: a record with a fixed set of fields that
every FHIR system understands. There are resources for patients, vaccinations, health
facilities, and so on. These dashboards need only four:

| FHIR resource (DHIS2 term) | What it holds | Example |
|---|---|---|
| `Location` (organisation unit) | A place: the country, a district, a chiefdom or a health facility | Bo district |
| `Organization` (the facility's organisation unit) | The organisation that runs a health facility, as distinct from the building and where it is | the provider at a clinic |
| `Measure` (indicator, data element or reporting rate) | The definition of an indicator: what is counted and how the figure is worked out | Penta 3 coverage under one year |
| `MeasureReport` (analytics value) | One result of that indicator, for one location and one period | Penta 3 coverage in Bo in 2025: 31.5 % |

Resources point to each other by reference. A MeasureReport names the Measure it is a
result of and the Location it is about, much as a row in a spreadsheet might name a column
heading and a district.

## Measures and MeasureReports

A **Measure** (DHIS2: indicator) is the definition of an indicator. A **MeasureReport**
(DHIS2: analytics value) is the value of that indicator for one location (DHIS2:
organisation unit) and one period. The Measure holds no numbers; each MeasureReport
holds the numbers for one location and period, and names the Measure it reports on.

In this case DHIS2 calculated every value, and each MeasureReport is a copy of one DHIS2
result. In other settings the MeasureReports are generated from individual records, such
as vaccinations, by software that applies the Measure's definition.

The examples below build up from the simplest case. All of them are real records from the
import.

### Example 1: a count

The simplest Measure counts one thing. "Penta3 doses given" is the number of third doses of
pentavalent vaccine given; in DHIS2 it is a **data element**. Its Measure has a single
**population**, the thing counted, and no division. Its MeasureReport for Bo district in 2025 holds one number.

```mermaid
flowchart LR
  M["<b>Measure</b> (data element)<br/>Penta3 doses given<br/><br/>counts: Penta 3 doses given"]
  R["<b>MeasureReport</b> (analytics value)<br/>location: Bo<br/>period: 2025<br/><br/>count: 6,656"]
  R -->|reports on| M
  classDef def fill:#eef2f7,stroke:#64748b,color:#1f2937
  classDef res fill:#ffffff,stroke:#94a3b8,color:#1f2937
  class M def
  class R res
```

FHIR calls a Measure like this a **cohort** Measure (DHIS2: data element).

### Example 2: a rate, with a numerator and a denominator

Most indicators divide one count by another, as a DHIS2 indicator's formula does. "Penta 3 coverage under one year" is the
number of children under one who received their third dose (the **numerator**) divided by
the number of children under one (the **denominator**). The Measure defines both counts
and says the result is shown as a percentage.

The MeasureReport holds both counts and the result of the division, the **score**
(DHIS2: the indicator value).

```mermaid
flowchart LR
  M["<b>Measure</b> (indicator)<br/>Penta 3 coverage &lt;1y<br/><br/>numerator: Penta 3 doses given &lt;1y<br/>denominator: population &lt;1y<br/>shown as a percentage"]
  R["<b>MeasureReport</b> (analytics value)<br/>location: Bo<br/>period: 2025<br/><br/>numerator: 6,589<br/>denominator: 20,924<br/>score: 6,589 ÷ 20,924 = 31.5 %"]
  R -->|reports on| M
  classDef def fill:#eef2f7,stroke:#64748b,color:#1f2937
  classDef res fill:#ffffff,stroke:#94a3b8,color:#1f2937
  class M def
  class R res
```

The numerator here (6,589) is smaller than the count in example 1 (6,656) because it
includes only doses given to children under one. FHIR calls a Measure like this a
**proportion** Measure (DHIS2: indicator of type per cent).

### Example 3: a value broken down

A MeasureReport can also break its value into parts. DHIS2 records whether each dose was
given at a fixed health facility or at an outreach session, so the 6,656 doses from
example 1 split into two parts. FHIR calls the breakdown a **stratifier** (DHIS2: category,
or organisation unit group set) and each part a **stratum** (DHIS2: category option, or
organisation unit group).

```mermaid
flowchart LR
  R["<b>MeasureReport</b> (analytics value)<br/>Penta3 doses given<br/>Bo · 2025<br/><br/>count: 6,656"]
  R --> S["<b>stratifier</b> (category)<br/>Fixed / Outreach"]
  S --> F["<b>stratum</b> (category option)<br/>Fixed<br/>count: 5,421"]
  S --> O["<b>stratum</b> (category option)<br/>Outreach<br/>count: 1,235"]
  classDef res fill:#ffffff,stroke:#94a3b8,color:#1f2937
  classDef part fill:#f8fafc,stroke:#cbd5e1,color:#1f2937
  class R res
  class S,F,O part
```

A rate can be broken down the same way, with each stratum holding its own numerator,
denominator and score. The dashboards use breakdowns by Fixed/Outreach and by facility type
(hospital, health centre, clinic and so on).

### Example 4: one Measure, many MeasureReports

There is one MeasureReport for each location and period that DHIS2 has a value for. These are
four of the Penta 3 coverage MeasureReports:

| Location | Period | Numerator | Denominator | Score |
|---|---|---:|---:|---:|
| Bo | 2025 | 6,589 | 20,924 | 31.5 % |
| Bo | 2024 | 6,804 | 20,505 | 33.2 % |
| Kenema | 2025 | 6,051 | 22,978 | 26.3 % |
| Sierra Leone | 2025 | 62,045 | 221,781 | 28.0 % |

A chart on these dashboards is a selection of rows like these: one Measure, the locations
being compared and the periods shown.

## How the DHIS2 model maps to FHIR

DHIS2 and FHIR describe the same things in different words. The mapping is close to
one-to-one.

```mermaid
flowchart LR
  OU["<b>DHIS2 organisation unit</b><br/><i>country, district, chiefdom</i>"] --> LOC["<b>FHIR Location</b>"]
  FAC["<b>DHIS2 organisation unit</b><br/><i>health facility</i>"] --> FLOC["<b>FHIR Location</b><br/><i>the place</i>"]
  FAC --> ORG["<b>FHIR Organization</b><br/><i>the provider running it</i>"]
  IND["<b>DHIS2 indicator</b><br/><i>numerator ÷ denominator formula</i>"] --> MP["<b>FHIR Measure</b><br/><i>scoring: proportion</i>"]
  DS["<b>DHIS2 data set reporting rate</b><br/><i>actual ÷ expected reports</i>"] --> MP2["<b>FHIR Measure</b><br/><i>scoring: proportion</i>"]
  DE["<b>DHIS2 data element</b><br/><i>a count, e.g. doses given</i>"] --> MC["<b>FHIR Measure</b><br/><i>scoring: cohort</i>"]
  GRP["<b>DHIS2 indicator or data element group</b>"] --> TOP["<b>FHIR Measure topic</b>"]
  VAL["<b>DHIS2 analytics value</b><br/><i>item × period × org unit</i>"] --> MR["<b>FHIR MeasureReport</b>"]
  CAT["<b>DHIS2 category or group set</b><br/><i>e.g. Facility Type, Fixed/Outreach</i>"] --> STR["<b>FHIR MeasureReport stratifier</b>"]
  classDef dhis fill:#eef2f7,stroke:#64748b,color:#1f2937
  classDef fhir fill:#ffffff,stroke:#94a3b8,color:#1f2937
  class OU,FAC,IND,DS,DE,GRP,VAL,CAT dhis
  class LOC,FLOC,ORG,MP,MP2,MC,TOP,MR,STR fhir
```

### Organisation units become Locations, and facilities also become Organizations

Every DHIS2 organisation unit becomes a FHIR `Location`: the country, 13 districts, 152
chiefdoms and 1,166 facilities. DHIS2's parent-child hierarchy becomes the Location's
`partOf` field, which points to the place one level up. Boundaries and facility
coordinates come across too, which is what the maps on these dashboards use.

DHIS2 uses one organisation unit for a health facility. FHIR splits it in two: a
`Location` for the place (its name, coordinates and position in the hierarchy) and an
`Organization` for the health provider that runs it. Each of the 1,166 facilities gets
both, with the same DHIS2 identifier, and the Location points to its Organization through
its `managingOrganization` field. Districts and chiefdoms are only places, so they get a
Location alone.

```mermaid
flowchart BT
  SL["Location: Sierra Leone<br/><i>DHIS2 org unit ImspTQPwCqd</i>"]
  BO["Location: Bo<br/><i>DHIS2 org unit O6uvpzGd5pu</i>"]
  KE["Location: Kenema"]
  CH["Location: Badjia<br/><i>a chiefdom in Bo</i>"]
  FA["Location: a health facility<br/><i>with its coordinates</i>"]
  ORG["Organization: the facility's provider<br/><i>same DHIS2 org unit ID</i>"]
  BO -->|partOf| SL
  KE -->|partOf| SL
  CH -->|partOf| BO
  FA -->|partOf| CH
  FA -->|managingOrganization| ORG
  classDef box fill:#ffffff,stroke:#94a3b8,color:#1f2937
  classDef org fill:#eef2f7,stroke:#64748b,color:#1f2937
  class SL,BO,KE,CH,FA box
  class ORG org
```

Each Location and Organization keeps its DHIS2 identifier, so any FHIR record can be
traced back to the DHIS2 organisation unit it came from, and later imports find the same
place again.

### Indicators, data elements and reporting rates become Measures

| DHIS2 | FHIR Measure |
|---|---|
| Indicator ID and code | `identifier` |
| Name and description | `title`, `description` |
| Numerator and denominator formulas | `group.population`: a numerator and a denominator, each with its DHIS2 formula |
| Indicator type (per cent, per 1,000, number) | `scoring`, and the factor (100 for a percentage) |
| Data element (a plain count) | a `cohort` Measure with one population |
| Data set reporting rate | a `proportion` Measure: actual reports ÷ expected reports |
| Indicator group, data element group | `topic` (Immunization, ANC, Delivery …) |

The Sierra Leone import holds 199 Measures: 39 indicators, 154 data elements and 6
reporting rates, covering every item on the 14 dashboards.

### Indicator values become MeasureReports

DHIS2 serves each value through its analytics API as a row with three coordinates: which
item (`dx`), which period (`pe`) and which organisation unit (`ou`). Each row becomes one
MeasureReport.

| DHIS2 analytics row | FHIR MeasureReport |
|---|---|
| `dx` (the indicator) | `measure`: the Measure above |
| `ou` (the org unit) | `subject`: the Location with that DHIS2 identifier |
| `pe` (e.g. `2025`, `2025Q1`, `202511`) | `period`: start and end dates |
| numerator, denominator | `group.population` counts |
| value | `group.measureScore` |
| breakdown by a category or group set | `group.stratifier` |

Here is the same figure in both systems:

<div class="grid grid-cols-2">
<div class="card">

**DHIS2 analytics row**

```text
dx          tUIlpyeeX9N   Penta 3 Coverage <1y
pe          2025
ou          O6uvpzGd5pu   Bo
numerator   6589
denominator 20924
value       31.49
```

</div>
<div class="card">

**FHIR MeasureReport** (shortened)

```json
{
  "resourceType": "MeasureReport",
  "status": "complete",
  "type": "summary",
  "measure": "…/Measure/sl-demo-tUIlpyeeX9N",
  "subject": {"reference": "Location/sle-O6uvpzGd5pu",
              "display": "Bo"},
  "period": {"start": "2025-01-01", "end": "2025-12-31"},
  "group": [{
    "population": [
      {"code": "numerator",   "count": 6589},
      {"code": "denominator", "count": 20924}],
    "measureScore": {"value": 0.3149}
  }]
}
```

</div>
</div>

FHIR stores the score as a fraction (0.3149) rather than a percentage. The Measure records
DHIS2's factor (100), and the dashboards multiply by it to show 31.5 %.

The import holds 161,216 MeasureReports: the country, districts and chiefdoms for every
year from 2016 to 2026, quarters and months for 2025 and 2026, and facilities for 2025
and 2026.

## From FHIR records to charts

Charts need tables, not individual records. fhir-warehouse reads every Measure and
MeasureReport and flattens them with **ViewDefinitions**, FHIR's standard way of saying
"make a table with these columns from these fields". One MeasureReport becomes one row:

| measure | location | period | numerator | denominator | score |
|---|---|---|---|---|---|
| Penta 3 Coverage <1y | Bo | 2025 | 6,589 | 20,924 | 0.3149 |

The tables are saved as parquet files, a common format for data tables. Once the data is
in parquet, a wide range of BI and analysis tools can read it and build dashboards on it.
These dashboards use DuckDB.

## Things to know

- **The values are DHIS2's own.** DHIS2 works out each indicator for each place and period
  itself, and the import copies the result. The dashboards never add up or average
  indicator values across places or periods, because that would give a different answer
  from DHIS2's.
- **A missing value means no record.** Where DHIS2 has no value, there is no MeasureReport,
  and the charts show a gap rather than a zero.
- **The data is DHIS2's training data.** The Sierra Leone demo is generated for training;
  the figures are not real Sierra Leone statistics.
- **Facility-level values cover 2025 and 2026 only.** Earlier years were imported for the
  country, districts and chiefdoms.
- **The same Measures work beyond DHIS2.** Figures from other sources, such as campaign
  results or surveys, can be stored as the same Measure and MeasureReport resources, so
  DHIS2 routine data and other data can sit side by side and be read by the same tools.
