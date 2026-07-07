---
version: 0.1.0
last_modified: 2026-07-07T17:30:00Z
tags:
  - icr
  - preso
---

# ICR — Integrated Campaign Registry (slide bullets)
<sub>`v0.1.0 · Last modified Jul 7, 2026 at 1:30 PM EDT`</sub>

Distilled from [[icr-ig]] (v0.24.0) — 8 slides' worth of bullets.

---

## 1. The problem ICR solves

- Health campaigns — measles SIAs, polio rounds, NTD mass drug administration, bed-net distribution, vitamin A — repeatedly collect the **same data**: who lives where, who is eligible, who was reached, what coverage was achieved.
- That data is then archived or locked in one-off spreadsheets; the **next campaign starts from scratch**.
- The **Integrated Campaign Registry (ICR)** gives campaigns a shared, reusable data model so each campaign's data **compounds instead of being re-collected**.
- A UNICEF standards framework + open-source reference implementation, built on **HL7 FHIR R4**.

---

## 2. What ICR is (and isn't)

- The architectural core is a **FHIR Implementation Guide** — the "DNA" of the system: profiles, extensions, and terminology that make campaign data comparable by construction, across countries and implementers.
- It models the half of delivery work that routine health systems **don't**: campaign architecture, population & geography, delivery events, and coverage.
- Deliberately a **complement to WHO's SMART Immunizations IG** (which is routine-only) — ICR positions itself as *"the campaign SMART-Guidelines IG."*
- Covers all major delivery models through one typology: **Type A** (fixed/temporary posts), **Type B** (house-to-house), **Type C** (community-directed / MDA).

---

## 3. The campaign architecture

- FHIR has no native "Campaign" resource — ICR builds campaigns on **CarePlan**, surrounded by ~17 profiles.
- **Protocol** (PlanDefinition) — the reusable, versioned template: define "measles–rubella SIA, 9m–14y" once; every country and round instantiates the same recipe and stays comparable.
- **Campaign** (CarePlan) — one execution or round; **starts as a microplan and evolves into the execution record** (same resource, plan → order). National umbrellas and district rounds link via `partOf`.
- **Activity** (ActivityDefinition) defines the intervention once; **Task** is the assignable unit of work — one per site session or household/community visit — producing the delivery events.
- **CareTeam** makes accountability queryable: who worked this area and who reported this figure are joins, not string comparisons.

---

## 4. People, places, and denominators

- *Who* and *where* are kept strictly separate, so each keeps a stable identity when the other changes.
- **DeliveryUnit** (Group) — the actual household, community, or school cohort a task acts on, enumerating registered individuals (**Patient**) with stable cross-campaign IDs.
- **TargetPopulation** (Group) — the denominator, with **source and date provenance**; competing estimates (census vs WorldPop vs enumeration) coexist side by side, one flagged as *the* planning denominator.
- **Location** — the richest ICR profile: nested admin hierarchy, operational geography that *overlays* (not replaces) the admin tree, GeoJSON boundaries, and multi-system geospatial identity with **Overture GERS IDs preferred** as the cross-campaign join key.

---

## 5. Design principles that protect the data

- **Campaign vs routine is a firewall** — a mandatory `record-origin` flag on every delivery event means campaign doses never contaminate routine analytics (and vice versa), yet both live in one store.
- **Three views of coverage, never merged**: planned (denominator), administrative (the campaign's own tallies), and independently surveyed — because they routinely disagree (e.g. 99% admin vs 76% survey on the same round).
- **Delivery strategy is first-class and coded** — it determines which data elements even make sense (house-to-house tallies are meaningless at a fixed post).
- **Denominator provenance travels with every estimate** — no more mystery denominators.

---

## 6. Standards reuse, not reinvention

- ICR mints code systems **only for genuinely new campaign semantics** (25 CodeSystems: delivery strategy, missed/refusal/exclusion reasons, settlement type, …).
- Everything with an existing standard is reused: vaccines → **CVX**, drugs → **ATC**, commodities → **GS1**, geography → **ISO 3166 / P-codes / GERS**.
- 35 extensions carry the campaign semantics FHIR lacks — field tallies, social mobilization, stock accountability, zero-dose status.
- Structural discriminators are required bindings (analytics can branch on them); field-reality vocabularies are extensible (countries add local codes and map back).

---

## 7. Grounded in field evidence

- Ships a complete worked scenario — a Sierra Leone measles–rubella SIA plus a community-directed MDA thread — with **41 example instances** exercising every profile end-to-end, from protocol down to a single child's dose and its AEFI.
- Validated against **eight global-health source analyses** (WHO SIA/RED/measles guidance, cluster-survey manual, GTFCC, NTD-MDA, EYE): **no source contradicts the core design**.
- Iteratively hardened against real instruments: ten UNICEF polio-SIA forms (zero-dose tracking, readiness checklists) and the six **ESPEN MDA forms**, converted to FHIR Questionnaires with automatic extraction to ICR resources.
- Demonstrates the "countries extend the IG" story: a filled national form becomes ICR-profiled data.

---

## 8. Where it goes next

- **WHO alignment**: adopt the SMART-Guidelines IG structure, derive ICR's coverage Measures from WHO's 45 indicators where they overlap, and offer the campaign layer back as ICR's distinctive contribution.
- **Analytics layer**: executable CQL for the shipped Measures, SQL-on-FHIR views, and ConceptMap scaffolds for country/local code localization.
- **Validation**: conformance testing against real campaign datasets, FHIR community review, and 2-country pilots — open questions are published in the IG itself for transparency.
- **17-month roadmap** (May 2026 – Sep 2027): IG first, then platform + pilots, capacity building, and reporting/systems integration — Ona (prime) + Crosscut, for UNICEF.
