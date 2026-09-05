# ICR FHIR Implementation Guide (draft)

FHIR R4 Implementation Guide for UNICEF's **Integrated Campaign Registry (ICR)**,
authored in [FHIR Shorthand (FSH)](https://build.fhir.org/ig/HL7/fhir-shorthand/) per
the [IG authoring guidance](https://build.fhir.org/ig/FHIR/ig-guidance/). The design
rationale lives in the working doc: [`../project/icr-v1.md`](../project/icr-v1.md).

## Layout

- `sushi-config.yaml` — IG metadata (canonical `https://fhir.icr.unicef.org`)
- `input/fsh/` — all FSH source:
  - `profiles-campaign.fsh` — ICRCampaignProtocol (PlanDefinition), ICRCampaign (CarePlan), ICRCampaignActivity (ActivityDefinition), ICRCampaignTask (Task)
  - `profiles-population.fsh` — ICRDeliveryUnit (household/community Group), ICRTargetPopulation (Group), ICRLocation
  - `profiles-delivery.fsh` — ICRImmunizationEvent, ICRMedicationAdministration, ICRSupplyDelivery
  - `profiles-coverage.fsh` — ICRAdministrativeCoverage, ICRSurveyCoverage (MeasureReport)
  - `profiles-cost.fsh` — ICRCampaignCost (Observation — budget/expenditure line item), ICRCostReport (MeasureReport — total & cost per person)
  - `extensions.fsh`, `codesystems.fsh`, `valuesets.fsh`, `aliases.fsh`, `examples.fsh`
- `input/pagecontent/` — IG narrative (index, background)

## Build

```bash
npm install -g fsh-sushi
sushi build .              # FSH → FHIR JSON in fsh-generated/ (do not edit that dir)

# Full IG website (needs Java 17+ and Jekyll):
./_updatePublisher.sh      # once, downloads publisher.jar
./_genonce.sh              # builds output/index.html

# Redesigned site (modern theme, ⌘K + full-text search) via IG Topcoat
# (https://github.com/recodelabs/ig-topcoat, expected at ~/github/ig-topcoat):
./_gentopcoat.sh           # builds output/ then output-topcoat/index.html
```

`output-topcoat/` is the same IG re-rendered by **IG Topcoat**: identical page filenames and
canonical URLs, publisher validation/QA untouched, but with a modern shell — command
palette (⌘K), Pagefind full-text search, interactive element trees, filterable
terminology tables, dark mode. Serve it over HTTP for search: `cd output-topcoat && npx serve`.

## Published sites

`.github/workflows/publish-ig.yml` builds the IG once and publishes both renderings:

| Rendering | Source dir | URL |
| --- | --- | --- |
| Stock HL7 IG Publisher | `output/` | https://icr-ig-standard.pages.dev |
| IG Topcoat (modern shell) | `output-topcoat/` → `_site` | https://icr-ig.pages.dev |

Both are also uploaded as run artifacts (`icr-ig-standard`, `icr-ig-site`).

Topcoat rewrites the HTML **in place** — same filenames, same canonical URLs — so the stock
rendering cannot be recovered from the Topcoat site. That is why the two live in separate
Pages projects rather than under one site at different paths. The machine-readable artifacts
(`package.tgz`, `full-ig.zip`, `definitions.*.zip`, `validator.pack`, per-resource JSON/XML)
are byte-identical in both, at the root of either site.

Use the stock site when someone expects the standard HL7 layout — FHIR community review,
HL7 balloting, or cross-checking how the publisher actually rendered a profile.

## Status / roadmap

v0.1 draft (Phase 1). Pending for later drafts: SQL-on-FHIR ViewDefinitions,
ConceptMap localization scaffolds, Consent guidance, Measure definitions aligned to
JAP / ICG / ESPEN / WHO EPI reporting minimums, data conformance testing against real
campaign datasets, and FHIR community review.
