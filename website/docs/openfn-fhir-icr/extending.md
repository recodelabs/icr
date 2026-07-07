---
sidebar_position: 3
title: Extending & adapting
---

# Extending & adapting

The adaptor is small and deliberately hand-authored, so extending it is straightforward.
Everything lives in three files:

- **`src/utils.js`** — FHIR datatype helpers, the idempotent-upsert plumbing (`cond`, `urn`,
  `upsertEntry`, `dedupeEntries`), and GCP auth (`gcpAccessToken`).
- **`src/builders.js`** — ICR resource builders + the ESPEN form transforms, and the ICR
  code-system / identifier / extension constants (`SYS`, `CS`, `EXT`).
- **`src/Adaptor.js`** — the operations (`execute`, `upsertBundle`) and re-exported FHIR ops.

## The builder pattern

Every builder returns `{ ref, entry }` and is registered for idempotent upsert via
`upsertEntry(resourceType, system, value, resource)`:

- `system` + `value` are the **business identifier** — the adaptor embeds it in the resource
  *and* builds the conditional-PUT URL from it, so re-running upserts in place.
- `ref` is a deterministic `urn:uuid` you use to **reference this resource from siblings** in
  the same transaction (e.g. a Group's `geography` → its village Location).

```js
import { coding, concept, upsertEntry } from './utils.js';

export function myResource({ value, name, locationRef }) {
  return upsertEntry('Observation', SYS.myThing, value, {
    status: 'final',
    code: concept(CS.someCode, 'my-code', 'My code'),
    subject: { reference: locationRef },   // a urn:uuid ref from another builder
    valueString: name,
  });
}
```

:::tip Two things that will bite you
- **Put the identifier in the resource body**, not just the conditional URL — `upsertEntry`
  does this for you. A resource with no `identifier` duplicates on every run.
- **`QuestionnaireResponse.identifier` is `0..1`** (a single object), while most resources
  are `0..*` (an array). `upsertEntry` special-cases this.
:::

## Add a new form transform

A form transform takes one ODK OData submission and returns an array of transaction entries.
Reuse `adminLocations` to build (and reference) the admin hierarchy consistently with the
other forms:

```js
export function fromMyForm(sub) {
  const date = (sub.__system?.submissionDate || '2026-01-01').slice(0, 10);
  const { entries, hfRef, villageRef } = adminLocations({
    state: sub.p_state, district: sub.p_district, hf: sub.p_health_facility,
    village: sub.p_location, villageId: sub.p_location_id,
  });
  const out = [...entries];
  out.push(myResource({ value: `${sub.p_location_id}:thing`, name: sub.some_field, locationRef: villageRef }).entry);
  return out;
}
```

Then a job just does:

```js
fn(state => { state.entries = state.data.value.flatMap(b.fromMyForm); return state; });
upsertBundle($.entries);
```

Because `adminLocations` uses the same deterministic identifiers everywhere, references line
up across forms — a SupplyDelivery from the receipt form points at the *same* Location the
registration form created.

## Target a different FHIR store

Nothing about the builders is Google-specific. To point at HAPI or another R4 store, drop the
`service_account` from the credential and use `baseUrl` (+ `access_token`/basic auth if the
store needs it). The adaptor only mints a GCP token when a `service_account` is present.

## Adapt for a different IG or country profile

The ICR conformance detail is centralized in the `SYS`, `CS`, and `EXT` constants at the top
of `builders.js` (canonical base, code systems, identifier systems, extension URLs) and in
the individual builders. To retarget another jurisdiction's profiles:

1. Point the constants at the new canonical base / code systems.
2. Adjust the builders' element structure to the new profiles.
3. Keep `upsertEntry` / `adminLocations` / the GCP auth as-is.

For a large, stable IG it's worth generating builders from the StructureDefinitions (the
approach OpenFn's `fhir-ndr-et` adaptor takes with `@openfn/generate-fhir`) instead of
hand-authoring — a planned evolution for `fhir-icr`.

## Contributing to the OpenFn catalog

To publish `@openfn/language-fhir-icr` to [docs.openfn.org](https://docs.openfn.org/adaptors/):
add the OpenFn build tooling (`build.config.js` + `@openfn/buildtools`), two logo assets
(`assets/rectangle.png`, `assets/square.png`), and a changeset, then open a PR into
[`OpenFn/adaptors`](https://github.com/OpenFn/adaptors) as `packages/fhir-icr`. CI publishes
to npm and the catalog on merge.
