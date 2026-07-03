# ig-fresh — modern static site generator for FHIR IG Publisher output

**Date:** 2026-07-03 · **Status:** approved · **Working example:** the ICR IG in `ig/`

## Problem

FHIR Implementation Guides are published as static HTML by the HL7 IG Publisher. The
content is authoritative but the presentation is dated and hard to use: no real search,
dense framed tables, weak navigation, not responsive, no dark mode. We want a fresh,
modern reading experience without forking the official toolchain.

## Approach (decided)

**Post-process the publisher output.** The standard build (`sushi` → IG Publisher) stays
untouched and remains the source of truth for validation, snapshot computation, QA, and
terminology expansion. `ig-fresh` is a standalone, IG-agnostic CLI living in its own repo
(`~/github/ig-fresh`) that reads a built `output/` directory and generates a redesigned
static site.

Rejected alternatives: a custom Jekyll template package (stays in-mechanism but is a
re-skin at best, and the template system is arcane); a from-scratch renderer of the FHIR
package (would reimplement snapshot generation, expansion, and core-spec linking — too
large, too risky).

## Fidelity contract ("still true to an IG")

- **Same page filenames** as the publisher output (`StructureDefinition-x.html`,
  `CodeSystem-y.html`, `artifacts.html`, …) so all internal and inbound links keep working.
- Same page tree and menu (from the `ImplementationGuide` resource + publisher config).
- Same artifact set; canonical URLs, version, status, publisher, dependencies displayed.
- Draft/ci-build status banner and a publish/provenance box, restyled.
- Links out to the core FHIR spec (hl7.org) and other IGs preserved as-is.
- Publisher files we don't re-render (e.g. `qa.html`, `.json`/`.xml`/`.ttl` renditions,
  `package.tgz`) are copied through and linked.

## CLI

```
ig-fresh build -i <publisher-output-dir> -o <site-dir> [--verbose]
```

Node ≥ 20, TypeScript. Distributed as a repo-cloneable CLI (npm publish later if wanted).

## Pipeline

1. **Load** — parse `ImplementationGuide-*.json` (metadata, dependencies, page tree,
   artifact/`definition.resource` list), every `<Type>-<id>.json` artifact (publisher
   emits StructureDefinitions **with computed snapshots**), and `expansions.json`
   (ValueSet expansions). Extract the main content region of publisher-generated
   narrative pages (index, background, any authored pages) with cheerio and restyle it
   inside the new shell.
2. **Model** — normalize into typed structures: `IgMeta`, `PageNode` tree,
   `Artifact` (grouped by kind: profiles, extensions, code systems, value sets,
   concept maps, examples, questionnaires, measures, capability statements, other),
   `ElementTree` built from snapshot + differential (slicing-aware).
3. **Render** — build-time JSX (Preact + `preact-render-to-string`; **no client-side
   React runtime**) → static HTML pages:
   - **Profile / Extension pages:** header card (canonical, version, status, base
     definition, derivation), a "key elements" summary (required + must-support),
     interactive element tree — collapsible rows, differential/snapshot tabs,
     cardinality, type links, binding links, flag badges with tooltips, must-support
     highlighted — plus a syntax-highlighted JSON tab (shiki at build time) and
     copy-canonical button.
   - **CodeSystem / ValueSet pages:** metadata card; concept table with instant
     client-side text filter; expansion contents when present in `expansions.json`,
     otherwise the compose rules.
   - **Examples & other instances:** metadata + collapsible JSON tree viewer, link to
     the profile(s) they claim conformance to.
   - **Artifacts index:** filterable table/card grid (by kind + text).
   - **Narrative pages:** extracted publisher content, publisher CSS classes mapped to
     the new design.
   - **Fallbacks:** unknown resource types get a generic metadata + JSON page. One bad
     artifact never fails the build — log a warning, emit the fallback.
4. **Search** — two layers, both fully static:
   - **⌘K command palette:** fuzzy quick-switcher over all artifacts + pages
     (fuse.js over a small generated JSON index), grouped by kind.
   - **Full-text:** Pagefind indexes the generated site; results page in the shell.
5. **UI shell** — Tailwind v4 with shadcn-style design tokens (CSS variables, light +
   dark), fixed sidebar (page tree + artifact groups), topbar with search trigger and
   theme toggle, breadcrumbs from the page tree, responsive/mobile layout. Interactivity
   (tabs, tree collapse, dialog, filter, theme) is small hand-written vanilla JS —
   honest static HTML, no framework runtime, no server (htmx unnecessary).

## Repo layout (ig-fresh)

```
src/
  cli.ts          # arg parsing, orchestration
  load/           # readers: ig resource, artifacts, expansions, narrative extraction
  model/          # normalized types + builders (element tree, artifact grouping)
  render/         # JSX page templates + components
  ui/             # client JS islands + Tailwind entry CSS
test/
  fixtures/       # small trimmed artifact JSONs
  golden/         # rendered-HTML golden files
```

## Integration in the icr repo

`ig/_genfresh.sh`: run `sushi build` + `_genonce.sh`, then
`ig-fresh build -i output -o output-fresh`. `output-fresh/` gitignored like `output/`.

## Testing

- **Unit (vitest):** element-tree builder (slicing, choice types, cardinality),
  artifact grouping, narrative extraction.
- **Golden files:** rendered HTML for representative artifacts (one profile, one
  extension, one CodeSystem, one ValueSet, one example).
- **End-to-end:** full build of the ICR IG; script asserts every internal `href`
  resolves to a file; browser screenshots (light + dark, desktop + mobile) reviewed
  for visual quality.

## Prerequisites

Local machine needs Java (JDK via brew) and Jekyll (gem) once, to run the IG Publisher
and produce `ig/output/` — the input fixture for development.

## Out of scope (v1)

Multi-version IG switcher; re-rendering QA reports (link `qa.html`); XML/Turtle
renditions (link the publisher's files); htmx/server features; Questionnaire form
preview beyond an item tree. Stretch goal if time allows: profile-dependency graph on
the artifacts page.
