# ICR FHIR Implementation Guide (draft)

FHIR R4 Implementation Guide for UNICEF's **Integrated Campaign Registry (ICR)**,
authored in [FHIR Shorthand (FSH)](https://build.fhir.org/ig/HL7/fhir-shorthand/) per
the [IG authoring guidance](https://build.fhir.org/ig/FHIR/ig-guidance/). The design
rationale lives in the working doc: [`../project/icr-v1.md`](../project/icr-v1.md).

## Layout

- `sushi-config.yaml` — IG metadata (canonical `https://fhir.icr.unicef.org`)
- `input/fsh/` — all FSH source:
  - `profiles-campaign.fsh` — ICRCampaignProtocol (PlanDefinition), ICRCampaign (CarePlan), ICRCampaignActivity (ActivityDefinition), ICRCampaignTask (Task)
  - `profiles-population.fsh` — ICRHousehold, ICRTargetPopulation (Group), ICRLocation
  - `profiles-delivery.fsh` — ICRImmunizationEvent, ICRMedicationAdministration, ICRSupplyDelivery
  - `profiles-coverage.fsh` — ICRAdministrativeCoverage, ICRSurveyCoverage (MeasureReport)
  - `extensions.fsh`, `codesystems.fsh`, `valuesets.fsh`, `aliases.fsh`, `examples.fsh`
- `input/pagecontent/` — IG narrative (index, background)

## Build

```bash
npm install -g fsh-sushi
sushi build .              # FSH → FHIR JSON in fsh-generated/ (do not edit that dir)

# Full IG website (needs Java 17+ and Jekyll):
./_updatePublisher.sh      # once, downloads publisher.jar
./_genonce.sh              # builds output/index.html
```

## Status / roadmap

v0.1 draft (Phase 1). Pending for later drafts: SQL-on-FHIR ViewDefinitions,
ConceptMap localization scaffolds, Consent guidance, Measure definitions aligned to
JAP / ICG / ESPEN / WHO EPI reporting minimums, data conformance testing against real
campaign datasets, and FHIR community review.
