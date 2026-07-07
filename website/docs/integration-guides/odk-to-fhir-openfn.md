---
sidebar_position: 1
title: ODK → FHIR via OpenFn
---

# ODK → FHIR via OpenFn

This recipe wires **ODK Central** submissions into the **FHIR store** using an OpenFn
workflow and the ICR FHIR adaptor.

```
ODK Central  ──OData──▶  OpenFn (fhir-icr adaptor)  ──FHIR transaction──▶  FHIR store
```

The workflow has two steps:

1. **Fetch** — the [`odk`](https://docs.openfn.org/adaptors/packages/odk-docs) adaptor pulls
   new submissions from ODK Central via OData, incrementally (a `cursor` on
   `__system/submissionDate` so each run only fetches what's new).
2. **Transform + load** — the [`@openfn/language-fhir-icr`](../openfn-fhir-icr/) adaptor turns
   each submission into ICR-profiled FHIR and upserts it into the store in one idempotent
   transaction.

The transform, credential, form-by-form mapping, worked `workflow.json`, and Lightning
deployment are documented in the dedicated adaptor section:

- **[FHIR-ICR adaptor — Overview](../openfn-fhir-icr/)** — how it works + the ESPEN MDA
  form → FHIR mapping table.
- **[Setup & running](../openfn-fhir-icr/setup)** — install, credential (GCP service
  account), local run, and the full ODK → FHIR `workflow.json` + Lightning deploy.
- **[Extending & adapting](../openfn-fhir-icr/extending)** — add a form transform or target
  a different store/IG.
