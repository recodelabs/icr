---
title: "Georegistry change over time — how the ICR IG should handle administrative units that split, merge, move and get renamed"
project: ICR
status: draft
version: 0.1.0
last_modified: 2026-09-07T16:28:59Z
authors: [Ona]
audience: [Ona, Crosscut, UNICEF]
created: 2026-09-07
tags: [icr, fhir, ig, georegistry, location, history, provenance, working-doc]
---

# Georegistry change over time — proposal for the ICR IG

<sub>`v0.1.0 · Last modified Sep 7, 2026 at 12:28 PM EDT`</sub>

> [!note] Status
> Proposal only. Nothing in the IG has been changed. Written after reading IASO's data model and change-request API, the Common Geo-Registry specification, DHIS2's organisation-unit maintenance guidance, and OCHA's P-code guidance. Review inline with roughdraft.md comments; the FSH comes after the design is agreed.

## 1. The problem, split into its four parts

"Districts change over time" hides four different problems. They need different answers, and the systems we studied each solve only some of them.

1. **Identity.** When Gwale LGA is split in two, is the new Gwale the same thing as the old one? Coverage recorded against "Gwale" in 2023 has to know whether it is comparable to 2026.
2. **Hierarchy.** A ward moves from one LGA to another. Roll-ups for 2024 must use the 2024 tree, roll-ups for 2026 the 2026 tree. FHIR `Location.partOf` is a single pointer with no dates, so today the registry only knows the current tree.
3. **Attributes.** Names, codes, boundaries and coordinates change. Analysts need "what did this look like on the date of that round".
4. **Governance.** Who proposed the change, who approved it, from what evidence, and when it took effect.

On top of these sits a fifth requirement that only appears once you run analyses for more than a year: **reproducibility** — being able to say exactly which version of the registry a report was computed against.

## 2. What the precedents do

| | Per-unit validity dates | Succession (split / merge links) | Dated hierarchy | Change request with evidence | Audit log | Whole-registry snapshots |
|---|---|---|---|---|---|---|
| **Common Geo-Registry** (GeoPrism) | yes | partial | yes — hierarchies are dated | yes | yes | yes — master list versions |
| **IASO** (Bluesquare) | opening / closed date only | no (entity merge exists for persons, not org units) | no — only via snapshots | yes, strong: old and new value per field, partial approval, evidence as form submissions, per-type field configuration | yes — generic past-value / new-value log linked to the request | yes — "source versions", a full copy of the pyramid per version |
| **DHIS2** | opening / closed date | split and merge *operations* (2.37+) but no persistent links | no — hierarchy is edited in place | no (org unit maintenance is admin-side) | change log | no |
| **OCHA COD-AB / P-codes** | by dataset release | by changelog, informal | no | n/a | n/a | yes — dataset versions |
| **ICR IG today** | no | no | no (`partOf` only) | no | server `_history` only | kiln snapshot + parquet manifest (outside the IG) |

Two lessons stand out.

- **DHIS2 is the cautionary tale.** Its own documentation says that once the hierarchy is changed, "it is no longer possible to analyse aggregated numbers according to how they were before the change". Campaign coverage is inherently longitudinal; this is the failure mode the IG must design out.
- **IASO and CGR show that there are two kinds of history, and you want both.** IASO leans entirely on *release history* (snapshots of the whole pyramid) and has excellent governance around each change, but cannot answer comparability questions. CGR has *object history* (validity dates on units and hierarchies) and also publishes master-list versions. Neither has clean succession links; both would benefit from them.

## 3. The core design decision

The IG should specify **object history** (per-unit validity and succession, dated hierarchy) **and release history** (named, immutable snapshots). They are cheap together because a release is a labelled copy of the object state at a point in time, and each answers a question the other cannot:

- Object history answers *"is the Gwale in this 2023 coverage report the same place as the Gwale on today's map, and if not, what is it now?"*
- Release history answers *"what exactly did the analysts use in June 2024?"*

## 4. The model

### 4.1 Identity rule

A `Location` represents one administrative unit for its whole lifetime. **Attribute changes** — renames, boundary corrections, coordinate fixes, code revisions — edit the same resource. **Structural changes** — splits, merges, genuine territorial redrawing — create new resources and retire the old ones.

The IG states this rule explicitly, because it is what keeps identifiers stable, and stable identifiers are what every downstream join depends on. It is the P-code principle (a unit keeps its code across attribute changes and gets a new code only when it is a new unit) and it is already how kiln treats ids.

> [!note] Renames are not new units
> The old name goes to `Location.alias`. A country that insists a rename creates a new unit can use `superseded-by` (below), but the default protects identifier stability, which matters more than mirroring local administrative formalities.

### 4.2 Four additions to `ICRLocation`

1. **Validity period** — new extension `valid-period` (Period). `start` = when the unit came into administrative existence; `end` = when it stopped. `Location.status` goes `inactive` at the end, but the period is what queries use.
2. **Succession** — new extension `succession`, repeatable, complex: `relation` (code), `target` (Reference(ICRLocation)), `effective` (date). Relation codes: `split-into`, `merged-into`, `boundary-revised`, `superseded-by`, and their inverses recorded on the counterpart (`split-from`, `merged-from`, …). A retired unit points forward; its successors point back. This is the piece none of the precedents has cleanly, and it is what makes longitudinal coverage honest: a query can say "2023 Gwale = union of its two successors after March 2025", or flag that two figures are not comparable.
3. **Dated hierarchy membership** — new extension `hierarchy-membership`, repeatable, complex: `parent` (Reference(ICRLocation)), `period` (Period). `partOf` stays as *the current parent* so every existing search and client keeps working. When a ward moves, the old membership closes and a new one opens, and `partOf` is updated to match. Roll-ups pick the membership whose period contains the campaign date.
4. **Identifier periods** — FHIR already gives `Identifier.period`. A P-code or national code revision is recorded on the same resource with dates; no new resource.

### 4.3 Governance as resources, not as a product

The IG defines a **contract** for change, so any front end — IASO, a DHIS2 export, a GRID3 reload, a spreadsheet run through kiln — feeds the registry the same way. It does not define an application.

- **A change request is a Task** (new profile, e.g. `ICRLocationChangeRequest`): `focus` = the Location (or, for creations, the proposed Location in `validation-status = new` — IASO's pattern), `input` = old and new value per field, `input` = evidence as Reference(QuestionnaireResponse | DocumentReference | Attachment), `output` on completion = the list of fields actually approved and a rejection comment. Partial approval is a normal outcome, not a rejection plus a second request. Task status carries the workflow (`requested → accepted/rejected → completed`); multi-step approval chains are an implementation choice, not an IG concern.
- **Every accepted change produces a Provenance** on the new Location version: `target` (versioned reference), `agent` (who), `activity` from a small `location-change-type` code system (create, rename, reparent, boundary-revise, relocate, split, merge, retire, reconcile), `reason`, `entity` = the Task and the evidence, plus an extension carrying the **before-and-after diff** (IASO's past-value / new-value pair). FHIR `_history` gives version retrieval; Provenance gives the *why* in a portable form that survives moving between servers.
- The IG already has the SDC questionnaires, so a GPS-capture form becomes the provenance of a coordinate at no extra cost — exactly IASO's "reference instance".

### 4.4 Releases

A **registry release** is a `List` of versioned Location references with a name and a date, mirrored by the parquet build and its manifest in the data hub (`data/manifest.json` already records the kiln watermark and counts). Campaign records and coverage reports cite the release they were computed against. This is CGR's master-list version and IASO's source version, expressed in FHIR.

## 5. Rules that make it work in practice

- **Nothing that happened is ever rewritten.** A campaign points at the Location that existed on its dates. A merge does not touch the campaign; it adds succession links that let a query aggregate.
- **Reconciliation is a diff that yields Tasks.** Two sources disagreeing produce change requests with evidence, never silent overwrites. kiln's `diff` is already the engine; IASO's source-version synchronisation is the same idea.
- **Analysis is always "as of" a date.** The location parquet gains `valid_from`, `valid_to`, the dated parent list, `predecessor_ids` and `successor_ids`. The calendar and coverage views join on the parent *as of the round's start*, not the current parent.
- **Revisable state stays beside the Location, not in it.** Endemicity and similar assertions remain `ICRLocationStatus` observations; programmatic groupings (IASO's "groups") are not added to the Location.

## 6. What this deliberately does not do

- Depend on server version history alone. `_history` is not portable across FHIR servers and says nothing about why a change was made.
- Model the hierarchy purely by snapshot, as IASO does. Snapshots cannot answer comparability questions; DHIS2 shows where that leads.
- Build a validation-workflow engine into the IG. Task status plus a small change-type vocabulary is the contract; approval chains, payments to field workers (IASO has these), and UI are implementation choices.
- Adopt IHE mCSD as a dependency. mCSD aligns facility/organisation hierarchies but does not solve the temporal problem either; alignment can come later without changing this design.

## 7. Sequencing

**Phase A (pure additions, no cost for data that never changes):** validity period, succession, identifier periods, the Task and Provenance contract, the release List, the `location-change-type` code system.

**Phase B (with the first real boundary change we can test against):** dated hierarchy membership and the as-of joins in the views and parquet.

**First worked example:** the 2,441 Nigerian facilities currently parented at state level because of LGA name spelling mismatches between the GRID3 facility CSV and the boundary GeoJSON. Resolving them as Tasks with evidence, each producing a Provenance, is exactly this contract in use and would give the IG its example set.

## 8. Open questions

1. Whether a rename ever creates a new unit — default no (§4.1); confirm with UNICEF and the first pilot country.
2. Whether `hierarchy-membership` should also carry the *kind* of hierarchy (administrative vs health-reporting), given `Organization.partOf` already carries the reporting hierarchy for facilities.
3. Release granularity: per refresh (cheap, noisy) or per curated publication (rarer, meaningful). Recommendation: tag every refresh, name only the curated ones.
4. Whether the succession `effective` date should be allowed to differ from the retired unit's `valid-period.end` (it should not; the invariant is worth writing).

## Sources

- IASO — models (`iaso/models/org_unit.py`, `data_source.py`, `hat/audit/models.py`) and change-request API docs: https://github.com/BLSQ/iaso
- Common Geo-Registry specification and GeoPrism Registry: https://github.com/terraframe/common-geo-registry-specification · https://github.com/terraframe/geoprism-registry
- Health GeoLab, master lists and the CGR: https://healthgeolab.net/resource_framework/master-lists-common-geo-registry/
- DHIS2 organisation-unit maintenance (the "no longer possible to analyse" caveat) and 2.37 split/merge APIs: https://docs.dhis2.org/en/implement/maintenance-and-use/organisation-unit-maintenance.html
- OCHA P-codes and COD-AB: https://knowledge.base.unocha.org/wiki/spaces/imtoolbox/pages/222265609

Related: [[icr-v1]] §7.7 / §9 (georegistry rule), `ig/input/fsh/profiles-population.fsh` (`ICRLocation`, `ICRLocationStatus`), [[nigeria-registry-load-2026-09-06]] (the LGA-mismatch backlog).
