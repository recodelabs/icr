# docs.healthcampaigns.org — ICR Implementation Guide site

**Status:** approved design · **Date:** 2026-07-06 · **Owner:** Matt Berg (Ona)

## Purpose

A Docusaurus documentation site published at **docs.healthcampaigns.org** that serves as
the **implementation guide** for the ICR — how to stand up the Integrated Campaign Registry
and every tool in its reference stack. It is the practical "how to build and run it"
companion to the FHIR Implementation Guide (the spec/DNA), which lives separately at
`icr.healthcampaigns.org`.

Audience: implementers and developers deploying or integrating the ICR reference solution
(ministries, integrators, Ona/Crosscut delivery teams).

Non-goals: it is not the FHIR IG (that stays authoritative for the data model), not a
donor/marketing landing page, and not a research knowledge base.

## Repository location

- **Docusaurus app** lives in **`website/`** at the repo root.
- **Doc content** (markdown) lives in **`website/docs/`** — Docusaurus's native convention.
- The existing top-level **`docs/`** folder (contract, ESPEN, research PDFs — reference
  material, not site content) stays exactly as-is. No collision.

## Site structure

Docusaurus **classic preset, TypeScript config, blog removed, docs-only mode**
(`routeBasePath: '/'` — the Introduction page is the landing; no separate marketing
homepage to maintain).

Sidebar (mostly stub pages in this first cut, real structure in place):

1. **Introduction** — what the ICR reference solution is; relationship to the FHIR IG
   (link to `icr.healthcampaigns.org`); the reference-stack diagram.
2. **Architecture** — end-to-end data flow, component roles, deployment topology.
3. **Getting started** — prerequisites; a "minimum viable stack" quickstart.
4. **Components** — one page per tool:
   - Data collection: ODK, DHIS2 Tracker, CommCare, OpenSRP
   - Ingestion/transformation: OpenFn, Airbyte
   - FHIR store: HAPI FHIR, Google Healthcare API
   - Data quality: Cinder
   - Geospatial/microplanning: Crosscut
   - Warehouse: SQL-on-FHIR
   - Reporting: DHIS2, JAP
5. **Integration guides** — recipes (e.g. "ODK → FHIR via OpenFn", "FHIR → DHIS2 aggregate").
6. **Operations** — hosting, domains, backups, upgrades.
7. **Reference** — glossary; links (IG, OpenFn instance, ODK Central, source repos).

### Docusaurus config essentials

- `url: 'https://docs.healthcampaigns.org'`, `baseUrl: '/'`.
- `title: 'ICR Implementation Guide'`, tagline referencing UNICEF's Integrated Campaign
  Registry.
- `organizationName`/`projectName` pointing at the GitHub repo; `editUrl` so pages have
  "Edit this page" links into the repo.
- Node 20 (matches the IG workflow).

## Deploy pipeline

Mirror the existing IG pipeline (`.github/workflows/publish-ig.yml`):

- New workflow **`.github/workflows/publish-docs.yml`**.
- Trigger: push to `main` touching `website/**` (and the workflow file); plus
  `workflow_dispatch`.
- Steps: checkout → setup-node 20 → `npm ci` in `website/` → `npm run build` →
  deploy `website/build` to a **new Cloudflare Pages project `icr-docs`** via
  `cloudflare/wrangler-action@v3`, reusing the existing repo secrets
  `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`.
- Same graceful-degrade pattern as the IG workflow: if the CF token is absent, upload the
  built site as a run artifact and skip the deploy step.
- `concurrency` group `publish-docs`, cancel-in-progress.

## Domain

- **docs.healthcampaigns.org** → CNAME `icr-docs.pages.dev`, **proxied (orange)**.
- Two steps require the Cloudflare dashboard because the current wrangler OAuth token
  lacks `dns_records:edit` (see the `healthcampaigns-domains` memory):
  1. Add the custom domain `docs.healthcampaigns.org` to the `icr-docs` Pages project.
  2. Add the CNAME record in the Cloudflare dashboard (proxied).
- The design will surface the exact values for the user to apply; automation stops at the
  Pages project + workflow.

## Delivery

All work ships as a **single PR** off the `docs-site` branch (per the `icr-ship-via-prs`
convention), developed in a git worktree to avoid the branch-checkout daemon on the main
working copy.

## Out of scope (later, incremental)

- Real prose for the component/integration/operations pages (stubs now).
- Search (Algolia/local), versioning, i18n, custom landing design.
- Cross-linking IG anchors, embedded diagrams beyond the architecture overview.
