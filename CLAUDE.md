# ICR — Integrated Campaign Registry

This repository is the **research and writing workspace** for the Integrated Campaign
Registry (ICR) project. It is where we plan, research, synthesize, and draft — markdown
notes, technical design docs, FHIR modeling explorations, meeting synthesis, and project
management artifacts. **Application/IG code lives in separate repos** (created as the work
matures); this repo holds the thinking and the written output, primarily on the Ona side.

## What the ICR is

UNICEF's Integrated Campaign Registry: a standards framework and open-source reference
implementation that lets public health campaigns (immunization, polio, NTD mass drug
administration, malaria, vitamin A) **share, exchange, and reuse** campaign data and
metadata instead of re-collecting it every round. Built on **HL7 FHIR R4**.

- **Architectural core:** an HL7 FHIR Implementation Guide (IG) is the "DNA" of the system.
  Campaigns are modeled on **CarePlan** (with PlanDefinition as the reusable protocol,
  ActivityDefinition, Task, Group for households, Location for admin hierarchy/geospatial,
  Immunization/MedicationAdministration/SupplyDelivery for delivery events).
- **Reference solution (not a platform):** interchangeable open-source components — data
  collection (ODK, DHIS2 Tracker, CommCare, OpenSRP) → transformation/ingestion (OpenFn,
  Airbyte) → FHIR store (HAPI FHIR / Google Healthcare API) → browsing & data quality
  (Cinder) → geospatial/microplanning (Crosscut) → SQL-on-FHIR warehouse → DHIS2 & JAP
  reporting.
- **Consortium:** **Ona** (prime — IG, reference platform, integration, training, PM) +
  **Crosscut** (geospatial microplanning, DHIS2 integration, NTD campaign experience).
  Client: **UNICEF**. Project lead: **Matt Berg** (Ona).
- **Timeline:** 17 months, 6 phases (May 2026 – Sep 2027). Phase 1 = FHIR IG (M1–2),
  Phase 2 = platform dev + 2-country pilot (M3–6), Phase 3 = capacity building (M7–12),
  Phases 4–6 = reporting alignment / systems integration / sustainability (M13–17).

Authoritative source: `docs/contract/ICR Technical Propoal Ona Final.pdf` (and the ToR
alongside it). Treat the proposal's scope, deliverables, and exclusions as the spec.

## Working conventions

- **Notes & synthesis use Obsidian Flavored Markdown.** This repo is treated as an Obsidian
  vault. Use `[[wikilinks]]` to connect notes, `> [!note]`/`> [!warning]` callouts,
  YAML frontmatter for metadata, and `#tags` where useful. Prefer linking notes over deep
  folder nesting.
- Markdown for everything — research, design decisions, meeting notes, drafts.
- Keep the authoritative reference material (contract, ToR, country decks, integration
  reports) in `docs/`. Generated synthesis and our own writing live in topical folders.

## Working-doc review & versioning convention

Design/working docs (e.g. `project/icr-v1.md`) are reviewed inline using
**roughdraft.md** CriticMarkup-style syntax (https://www.roughdraft.md):

- Highlight a span: `{==text==}`
- Attach a comment: `{>>comment<<}{id="cN" by="user" at="<ISO8601>"}`
- Reply to a comment: another comment block carrying `re="<parent-id>"`, placed
  immediately after the comment it answers, e.g.
  `{>>reply<<}{id="c22" by="claude" at="<ISO8601>" re="c8"}`. Use a fresh, unique `id`
  and `by="claude"` for our replies.

**Replying to comments and rewriting content are two separate passes.** When asked to
reply, add the reply annotations only — do **not** apply the requested content edits.
The rewrite is a distinct, explicitly-triggered step.

Each working doc carries `version` and `last_modified` in its YAML frontmatter **and**
a visible stamp directly under the H1 title (frontmatter is hidden in rendered/Obsidian
preview), e.g. ``` `v0.1.1` · _last modified 2026-06-10 04:07 UTC_ ```. Keep the visible
stamp and the frontmatter in sync on every version change.

- **Comment-reply pass** → bump the patch digit (`+0.0.1`), e.g. `0.1.0 → 0.1.1`; a run
  of reply passes steps `0.1.1 → 0.1.2 → …`.
- **Content rewrite** → bump the minor digit (`+0.1`), e.g. `0.1.x → 0.2.0`.
- On every version change, update `last_modified` and **commit**, so each version is a
  point in git history.

## Project management — Linear + Amadeus

This project is managed in **Linear**, and uses **Amadeus** (the autonomous background
coding agent) for dispatching implementation work, adapted for ICR.

- Amadeus fires when a Linear issue gets the `Amadeus` label **and** moves to `Planning`.
  It communicates only through issue comments and signals state via issue status. Watch for
  `Feedback Needed` (it's paused, waiting on a reply) and `Review` (PR open, ready to merge).
- The full dispatch/monitor/scaling playbook lives in the Amadeus workflow note
  (`~/github/chappy/chap/context/amadeus.md`) — read it before dispatching agents.
- **Linear project:** [ICR](https://linear.app/recodelabs/project/icr-b68b387609d5/overview)
  (workspace: `recodelabs`).
- **ICR-specific Linear details (team, label/status IDs) are still TBD** — Matt to share.
  Note the ICR project lives in the Recode Labs workspace, but do not assume the ChapChap
  (REC) team/IDs from the source workflow note. Confirm the ICR team before dispatching.

## Repo layout

- `docs/contract/` — proposal, ToR, signed contract. The spec.
- `docs/ESPEN/` — ESPEN training/integration reference material.
- `docs/` — country reference (Uganda health campaign calendar, Sierra Leone & Uganda
  integration reports).
- (research/design notes — added as the work grows)
