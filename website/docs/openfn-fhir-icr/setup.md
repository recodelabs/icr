---
sidebar_position: 2
title: Setup & running
---

# Setup & running

## 1. Install the OpenFn CLI

```bash
npm install -g @openfn/cli
openfn test   # smoke test
```

## 2. Get the adaptor

The adaptor lives at [`recodelabs/fhir-icr`](https://github.com/recodelabs/fhir-icr)
(package name `@openfn/language-fhir-icr`, CLI short-name `fhir-icr`):

```bash
git clone https://github.com/recodelabs/fhir-icr.git
cd fhir-icr && npm install
```

Use it from the CLI by pointing `-a` at the local path:

```bash
openfn job.js -a fhir-icr=/abs/path/to/fhir-icr -s state.json -o out.json
```

## 3. Create the FHIR store (Google Healthcare)

```bash
gcloud healthcare fhir-stores create icr-demo \
  --dataset=ICR --location=us-west1 \
  --version=R4 --enable-update-create
```

- **`--version=R4`** matches the ICR IG.
- **`--enable-update-create`** lets the adaptor upsert by business identifier with
  idempotent conditional PUTs. Without it, re-running the pipeline errors.

## 4. Create a service account

```bash
gcloud iam service-accounts create icr-openfn --display-name="ICR OpenFn pipeline"

gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:icr-openfn@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/healthcare.fhirResourceEditor"

gcloud iam service-accounts keys create icr-openfn-sa.json \
  --iam-account=icr-openfn@PROJECT_ID.iam.gserviceaccount.com
```

`healthcare.fhirResourceEditor` grants read + create + update on FHIR resources.

## 5. The credential

The adaptor's credential (`configuration`) is:

```json
{
  "baseUrl": "https://healthcare.googleapis.com/v1/projects/PROJECT/locations/LOCATION/datasets/DATASET/fhirStores/STORE/fhir",
  "service_account": { "type": "service_account", "project_id": "…", "private_key": "…", "client_email": "…" }
}
```

Pass the whole service-account JSON object as `service_account`. (You can pass a static
`access_token` instead for quick tests, but a `service_account` self-refreshes.)

## 6. Run locally

A minimal job for form 1:

```js title="form1.js"
// state.data.value = ODK Central OData submissions for the location form
fn(state => {
  state.entries = state.data.value.flatMap(b.fromLocationForm);
  return state;
});
upsertBundle($.entries);
```

Put the credential in `state.configuration` and the ODK submissions in `state.data`, then:

```bash
openfn form1.js -a fhir-icr=/abs/path/to/fhir-icr -s state.json -o out.json
```

`upsertBundle` dedupes shared admin-hierarchy Locations and posts one FHIR transaction.
`out.json` contains the transaction response — every entry should be `200 OK` or `201 Created`.

## 7. The full workflow (ODK → FHIR)

In production the fetch is a first step using the [`odk`](https://docs.openfn.org/adaptors/packages/odk-docs)
adaptor, with an incremental cursor so each run only pulls new submissions:

```json title="workflow.json"
{
  "options": { "start": "fetch-locations" },
  "workflow": {
    "name": "espen-location-to-fhir",
    "steps": [
      { "id": "fetch-locations", "adaptor": "odk",
        "expression": "fetch-locations.js",
        "configuration": "tmp/odk-creds.json",
        "next": { "load-fhir": { "condition": "!state.errors" } } },
      { "id": "load-fhir", "adaptor": "fhir-icr",
        "expression": "load-fhir.js",
        "configuration": "tmp/fhir-icr-creds.json" }
    ]
  }
}
```

```js title="fetch-locations.js  (odk adaptor)"
cursor($.cursor, { defaultValue: '2020-01-01T00:00:00.000Z' });
getSubmissions(2, 'demo_mda_9999_1_location_v3', {
  $filter: `$root/Submissions/__system/submissionDate gt ${state.cursor}`,
});
cursor('now');
```

```js title="load-fhir.js  (fhir-icr adaptor)"
fn(state => { state.entries = state.data.value.flatMap(b.fromLocationForm); return state; });
upsertBundle($.entries);
```

## 8. Deploy to OpenFn Lightning

Define the project and deploy:

```bash
export OPENFN_ENDPOINT=https://openfn.healthcampaigns.org
export OPENFN_API_KEY=…   # personal access token from the Lightning UI
openfn deploy
```

Create the **credentials in the Lightning UI** (they are never uploaded from disk) — one for
`odk` (baseUrl + email + password) and one for `fhir-icr` (baseUrl + service_account) — and
attach a **cron trigger** to run the sync on a schedule. Because the upsert is idempotent,
overlapping or repeated runs are safe.

:::note
Publishing `@openfn/language-fhir-icr` to the public OpenFn adaptors catalog is a separate
step (a PR into `OpenFn/adaptors`). Until then, reference it by local path or a private
package as above.
:::
