---
title: ICR → DHIS2 — mapping Measures & MeasureReports to DHIS2 indicators
status: reference note (from IG review discussion, Aug 19 2026)
last_modified: 2026-08-19T20:30:00Z
tags:
  - icr
  - dhis2
  - fhir
  - coverage
  - integration
---

# ICR → DHIS2: mapping Measures & MeasureReports to DHIS2 indicators

`Reference note · captured from IG review discussion · Aug 19, 2026`

How the ICR's coverage machinery ([[ig-summary-v2|IG §7]]: six canonical Measures, `ICRAdministrativeCoverage` / `ICRSurveyCoverage` MeasureReports) maps onto DHIS2's aggregate model. Context: Phase 4 (reporting alignment); DHIS2 integration is Crosscut's lane in the consortium — the ICR side's job is to make the export mechanical.

## The Rosetta stone

DHIS2's aggregate model and FHIR's Measure/MeasureReport model are near-mirror images:

| FHIR (ICR) | DHIS2 | Notes |
| --- | --- | --- |
| `Measure` (definition) | **Indicator** (numerator formula ÷ denominator formula, type "percent") | Both are the *recipe* |
| `MeasureReport.group.population` counts | **Data values** on **data elements** (e.g. "Doses administered", "Target population") | The *raw counts* — DHIS2 stores these, not the rate |
| `measureScore` | Computed by the DHIS2 indicator at display time | Don't import the 99% — DHIS2 recalculates it |
| `group.stratifier` (sex × age-band) | **Category combination** → each stratum = a **categoryOptionCombo** | Sex(F/M) × AgeBand(9–59m/5–14y) = 4 COCs |
| `period` | DHIS2 **period** (monthly/custom) | Friction point — see below |
| geography (reporter's Location) | **orgUnit** | `ICRLocation` already carries the join: `example-ward`'s identifier *is* a DHIS2 orgUnit UID under an MoH system URI |
| `campaign` extension → the round | **attributeOptionCombo** | The standard DHIS2 trick for campaign data: "Campaign/Round" as an attribute category, so SIA round 1 vs round 2 vs routine stay separable |
| `coverageSource` admin vs survey | **Separate data elements** | DHIS2 convention: "MR coverage (admin)" and "MR coverage (survey)" are different DEs — the ICR never-merge rule, expressed DHIS2-style |
| `dataLineage` realtime vs reconciled | Separate datasets, or another attribute option | No native DHIS2 concept; must be modeled |

## The six Measures as DHIS2 indicators

| ICR Measure | DHIS2 numerator DE | DHIS2 denominator DE | Disaggregation (categoryCombo) |
| --- | --- | --- | --- |
| `icr-admin-coverage` | Doses/treatments administered (campaign) | Target population (planning denominator) | Sex × Age band; strategy & geography via COC/orgUnit |
| `icr-survey-coverage` | Survey: found covered | Survey: sample size | Sex × Age band |
| `icr-mda-treatment-coverage` | Persons treated, **per drug** (drug as category or per-drug DEs) | At-risk population | Sex × Age band × Disposition |
| `icr-geographic-coverage` | Villages/units treated | Villages/units targeted | Disposition (reason not treated) |
| `icr-zero-dose-coverage` | Zero-dose children reached | Target population | Dose-history |
| `icr-campaign-readiness` | Readiness checks passed | Checks assessed | Readiness domain |

Note the structural rhyme: the ICR's **standard stratifier axes** (`ICRCoverageStratifierVS`) are precisely a DHIS2 **category** list, and a `stratum` value maps 1:1 to a categoryOptionCombo. Not an accident — both descend from the same aggregate-cube tradition (the formal bridge standard, **ADX**, uses exactly this correspondence).

## Worked example: `example-admin-coverage` → a DHIS2 dataValueSet

The Kambia report (numerator 47,766 / denominator 48,250, June round) lands as:

```json
POST /api/dataValueSets
{
  "orgUnit": "<Kambia District UID — from ICRLocation.identifier (MoH DHIS2 system)>",
  "period": "202606",
  "attributeOptionCombo": "<MR SIA 2026, Round 1>",   // ← the campaign extension
  "dataValues": [
    { "dataElement": "<MR doses administered>", "value": 47766,
      "categoryOptionCombo": "<default, or per sex×age stratum from the stratifiers>" },
    { "dataElement": "<MR target population>",  "value": 48250 }
  ]
}
```

DHIS2's indicator "MR SIA admin coverage (%)" then computes 99% itself; the survey report posts to *different* data elements and its 76% shows up beside it — divergence preserved, same as in FHIR.

## Three friction points

1. **Periods.** DHIS2 periods are calendar-shaped; a campaign round (Jun 15–26) isn't. Standard practice: post to the containing month(s) and carry the round identity in the attributeOptionCombo — the `campaign` extension on the coverage profiles is exactly the field that feeds it. Without that link the exporter would be reverse-engineering "which round" from dates.
2. **The mapping table is metadata, not code.** Someone must pair (measure, population, stratum) → (dataElement UID, COC UID), and ICRLocation → orgUnit UID, per country instance. The orgUnit half is already designed for (identifiers on ICRLocation); the data-element half is a small mapping config — conceptually a ConceptMap, practically a lookup the OpenFn job owns.
3. **Direction and ownership.** After the campaign-link (PR #45) and stratifier work, a MeasureReport contains every field the dataValueSet needs — the export is mechanical.

## Possible next artifacts

- A short "DHIS2 export mapping" note/section in [[ig-summary-v2]].
- A prototype OpenFn job: MeasureReport → `POST /api/dataValueSets` against a demo DHIS2 instance.
