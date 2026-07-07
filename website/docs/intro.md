---
slug: /
sidebar_position: 1
title: Introduction
---

# Integrated Campaign Registry

This is the implementation guide for UNICEF's **Integrated Campaign Registry (ICR)** — a
practical, tool-by-tool walkthrough for standing up the ICR reference solution and
integrating its components.

It is the companion to the **FHIR Implementation Guide** at
[icr.healthcampaigns.org](https://icr.healthcampaigns.org), which is the authoritative data
model (the "DNA"). This site covers the *how to build and run it* side.

## The reference stack

Data flows through interchangeable open-source components:

1. **Data collection** — ODK, DHIS2 Tracker, CommCare, OpenSRP
2. **Ingestion / transformation** — OpenFn, Airbyte
3. **FHIR store** — HAPI FHIR, Google Healthcare API
4. **Data quality & browsing** — Cinder
5. **Geospatial / microplanning** — Crosscut
6. **Warehouse** — SQL-on-FHIR
7. **Reporting** — DHIS2, JAP

Start with [Getting started](./getting-started.md), or jump to a specific
[component](./components/odk.md).

:::note
This guide is under active development. Pages marked _stub_ are placeholders.
:::
