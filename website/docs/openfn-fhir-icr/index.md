---
sidebar_position: 1
title: Overview
---

# The FHIR-ICR OpenFn adaptor

[`@openfn/language-fhir-icr`](https://github.com/recodelabs/fhir-icr) is an OpenFn language
adaptor that turns **ODK Central submissions into ICR-profiled FHIR R4** and loads them into
a FHIR store — in the reference stack, a **Google Cloud Healthcare** FHIR store.

It is the transform-and-load half of the ICR ingestion path:

```
ODK Central  ──OData──▶  OpenFn (fhir-icr adaptor)  ──FHIR transaction──▶  FHIR store
  submissions              transform + idempotent upsert                   (Google Healthcare)
```

It is a thin layer over [`@openfn/language-fhir`](https://www.npmjs.com/package/@openfn/language-fhir)
(which provides the FHIR HTTP client) and adds three things the reference solution needs.

## What it adds

### 1. Google Healthcare authentication

Generic FHIR adaptors take a static `access_token`, which expires in an hour — useless for a
scheduled pipeline. `fhir-icr` accepts a **GCP service-account key** in the credential and
mints a short-lived OAuth token on every run:

```js
// configuration.service_account -> the adaptor mints an access_token per run
```

Grant the service account `roles/healthcare.fhirResourceEditor`. See [Setup](./setup).

### 2. ICR-profiled resource builders

Builders emit FHIR that conforms to the [ICR Implementation Guide](https://icr.healthcampaigns.org)
profiles — `ICRLocation`, `ICRTargetPopulation`, `ICRSupplyDelivery`,
`ICRAdministrativeCoverage`, `QuestionnaireResponse` — with the correct ICR code systems,
identifiers, and extensions baked in. Job authors call one function per form; the ICR
conformance detail lives in the adaptor.

### 3. Idempotent upsert

`upsertBundle` posts a **FHIR transaction of conditional PUTs**, keyed by business
identifier, with deterministic `urn:uuid` references between resources created in the same
bundle. Re-running the pipeline **updates resources in place instead of duplicating them** —
essential for a cron/incremental sync. (Google resolves `urn:uuid` references within a
transaction; it does *not* resolve conditional references to sibling entries, which is why
the adaptor uses `urn:uuid` for intra-bundle links.)

## The ESPEN MDA form → FHIR mapping

The six ESPEN Mass Drug Administration forms map to FHIR per the ICR IG's extraction design
(aggregate-vs-individual rule: individual record when you have a person, aggregate on a
report when you don't):

| Form | Transform | FHIR output |
|---|---|---|
| **1. Location registration** | `fromLocationForm` | `ICRLocation` cascade (admin hierarchy → village, GPS position, `partOf`) + `ICRTargetPopulation` Groups (total, MDA-eligible, 1–4 / 5–14 / 15+ age bands) |
| **2. Drug receipt** | `fromDrugReceiptForm` | `ICRSupplyDelivery` per drug **received** at the health facility |
| **3. Treatment tally** | `fromTreatmentForm` | `ICRAdministrativeCoverage` (MeasureReport) per drug — numerator/denominator + `sex` × `age-band` × `disposition` stratifiers |
| **4. Case management** | `fromCaseMgmtForm` | `ICRSupplyDelivery` per drug **distributed** + a `QuestionnaireResponse` for the aggregate side-effect / other-NTD counts (which can't become person-level resources) |
| **5 & 6. Supervision (HF / CDD)** | `fromSupervisionForm` | `QuestionnaireResponse` — per the IG, the supervision record *is* the QuestionnaireResponse |

**Proven end-to-end:** 57 synthetic ESPEN submissions across all six forms →
**132 FHIR resources** (21 Location, 60 Group, 12 SupplyDelivery, 33 MeasureReport,
6 QuestionnaireResponse) in a Google Healthcare store, fully idempotent.

## Next

- **[Setup](./setup)** — install the adaptor, configure the credential, run it locally, and
  deploy the workflow to OpenFn Lightning.
- **[Extending it](./extending)** — add a new form transform or builder, or target a
  different FHIR store or IG.
