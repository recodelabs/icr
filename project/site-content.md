---
title: ICR site content
version: 0.1.0
last_modified: 2026-09-01T20:58:00Z
source_of: site/index.html
tags:
  - icr
  - valueprop
  - site
---

# ICR site content
`v0.1.0 · Last modified Sep 1, 2026 at 4:58 PM EDT`

> [!note] **How to use this file.** Every piece of visible text on `site/index.html` is here, in page order. Edit the text here and ask for the site to be updated from it. Headings marked `##` are page sections, `###` are blocks inside a section. Lines starting with `>` are notes about where the text goes and are not shown on the page. The argument itself lives in [[valueprop]]; this file is the page's wording.

* * *
## Top bar
- Brand: **Integrated Campaign Registry**
- Brand suffix: UNICEF
- Nav links: Why campaigns · Compounding · Benefits · Who it's for · Implementation guide ↗

* * *
## Hero
**Headline:** Campaign data *compounds* instead of being re‑collected.

> The word "compounds" is set in green.

**Subhead:** Every health campaign already maps the places, counts the people, trains the teams, and records the result. Today that work is used once and filed away. The ICR makes each round a contribution to a shared registry that the next campaign, the next programme, and the routine health system can all use.
### Map
- Corner label: Synthetic data · Illustrative country
- Panel heading (under the round label): What the registry knows
- Slider tick labels: 2022 · 2023 · 2024 · 2025 · 2026
- Button: Play the rounds (becomes "Pause" while playing)
- Caption: Drag the slider. Each campaign round adds places, denominators, households, teams, and coverage to the same registry. Hover a district to see what is known about it.

Panel counters (label → value is generated):

- Campaign rounds recorded
- Districts with history
- Settlements with stable IDs
- Denominator sources per district
- Households in register
- Teams with history
- Coverage data points

Campaign types (legend and tooltips):

- Measles‑rubella SIA
- Polio round
- NTD mass drug administration
- Bed‑net distribution
- Vitamin A

Legend lead item: Fill = how much the registry knows (rounds recorded)

Rounds on the slider, with the note shown for each:

| Round | Type | Note |
| --- | --- | --- |
| Q1 2022 | Polio | Historical load · Loaded from existing reports: district coverage and denominators only. |
| Q3 2022 | Measles | Historical load · Loaded from existing reports. |
| Q1 2023 | MDA | First ICR‑native round: settlements registered, CDD teams recorded. |
| Q3 2023 | Bed nets | Household register created for the net‑distribution wards. |
| Q1 2024 | Polio | Reused the 2023 settlement list; enumeration skipped in 25 districts. |
| Q3 2024 | Vitamin A | Same posts and teams as the polio round. |
| Q1 2025 | MDA | Second MDA round on the same registers: coverage trend now available. |
| Q3 2025 | Measles | Three denominator sources per district for planning. |
| Q1 2026 | Bed nets | Household revisit targeted from the 2023 register. |
| Q3 2026 | Polio | Every district now has a five‑year coverage history. |

Tooltip lines (per district, values generated):

- `{District} District`
- `Pop. est. {n} · {n} settlements mapped` or `settlements not yet mapped`
- One line per round: `{round} · {type} (loaded) · {coverage}%`
- If none: No campaign recorded yet

District names (invented): Kalu, Bemba, Oru, Sena, Mira, Tolo, Adi, Weke, Lomu, Kiri, Nako, Sabu, Ende, Yala, Bori, Tami, Gora, Central, Mosi, Rafa, Duma, Ibe, Kanu, Pela, Sori, Nuru, Wari, Ojo, Lira, Bala, Teso, Mbeya, Zila.

* * *
## Why campaigns first
**Eyebrow:** Why campaigns first

**Heading:** Public health has many data problems. We start with campaigns for four reasons.

**Lede:** Starting with campaigns is not a narrowing of ambition. It is the fastest way to build the map of places and people that every other programme needs, paid for by activities that are already happening.
### Cards
**Campaigns are funded** Measles and polio rounds, mass drug administration, bed‑net distribution, indoor residual spraying, and vitamin A each arrive with a budget and a deadline. No new funding line is needed to make the first contribution.

**Campaigns repeat** The same protocol runs again next year, in the same districts, often with the same teams. Repetition is what makes reuse valuable and what makes comparison possible.

**Campaigns go everywhere** A house‑to‑house team walks to the hamlet that no facility register has ever listed. Campaigns are the only health activity that visits every place, including the ones routine services do not reach.

**Campaigns find the missing** The zero‑dose child, the unlisted settlement, the household behind the river. Campaign teams find them every round. The question is whether that is captured and shared, or written on a tally sheet and lost.

* * *
## How value compounds
**Eyebrow:** How value compounds

**Heading:** Each round contributes to a shared registry. Five kinds of record get richer every time.
### Table
Column heads: Record · After round 1 · After round 5

| Record | After round 1 | After round 5 |
| --- | --- | --- |
| Places | A district list and some GPS points | A verified settlement map with stable IDs and boundaries, plus the posts and structures used in each round |
| Denominators | One estimate from the census projection | Census, WorldPop, previous‑round enumeration, and administrative figures side by side, each with its source recorded |
| People and households | A register from this round | Households and school cohorts known across rounds, so follow‑up and revisits can be targeted |
| Teams | A list of names | Community drug distributors, vaccinators, and supervisors with a history of which areas they covered and how they performed |
| Outcomes | One coverage figure | A trend line per place per campaign type, with administrative and survey coverage kept as separate lineages |
### Three properties
**Any resolution is a valid contribution** The registry stores household‑level delivery events and district‑level outcome reports in the same model. A current round contributes village and household detail. A past round contributes its reported coverage and denominator by district. The model records which is which.

**Historical data can be loaded now** The registry does not have to start empty. Outcome‑level records from rounds already run can be loaded from existing reports, so a country has a multi‑year picture before it runs a single ICR‑native round. Retrofitted data carries its original quality, and the provenance fields say so.

**Resolution improves over time** Old rounds are aggregate‑only. Current rounds are village‑level. Future rounds are household‑level. The same registry holds all three, and the picture sharpens with each round.
### Callout
**The benefit is not all in the next round.** The contribution is made in this round with this round's budget, and two of the benefits below, common places and denominator triangulation, pay off during the current round. Where a country runs several campaigns a year, the next round is months away, not years.

* * *
## What compounding unlocks
**Eyebrow:** What compounding unlocks

**Heading:** Seven benefits.

**Lede:** Each audience below picks the ones that matter to it.
### Table
Column heads: Benefit · The claim · What makes it true

| Benefit | The claim | What makes it true |
| --- | --- | --- |
| Common places | One georegistry seeds every tool, turnkey. | Stable place IDs and boundaries in FHIR, exportable to ODK, DHIS2, Crosscut, and any other tool without re‑cleaning. |
| Denominators you can defend | Census, WorldPop, administrative, and last‑round figures side by side, each with its source. | Target populations carry provenance; the planning denominator is a recorded choice, not an accident. |
| Skip the pre‑census | Reuse last round's registers, posts, and teams; target instead of re‑enumerate. | Households, delivery units, and care teams persist across rounds. |
| Campaign visibility | An official registry of what is planned where, viewable as a map and a calendar. | Every campaign is a record with geography, dates, and status, from microplan through completion. |
| Validated aggregates | The district figure can be traced to the events beneath it. | Delivery events roll up to coverage reports; administrative and survey coverage are never merged. |
| Effectiveness over time | Coverage trend, cost per person reached, and data‑quality trend per place and per campaign type. | Rounds of the same protocol are directly comparable within a country and, where countries share the standard, across them. |
| Campaign‑to‑routine bridge | Same facilities, same places, same denominators; one flag separates campaign doses from routine doses. | Aligned with the WHO SMART Immunizations guideline; campaign and routine records coexist in one store without contaminating each other's statistics. |
### Two consequences
**Co‑delivery and integration** Once the registry knows what is planned where, it can surface two campaigns hitting the same wards within weeks of each other. That is the integrated‑campaign argument in its most concrete form.

**Equity targeting** Historic per‑place coverage is the input for finding never‑reached settlements and zero‑dose children. Same records, different question. The IG already defines a zero‑dose coverage measure.

* * *
## Beyond campaigns
**Eyebrow:** Beyond campaigns

**Heading:** A place recorded by a campaign is the same place for every other programme.

**Lede:** The registry is built on HL7 FHIR, and FHIR Location, Organization, Patient, and Group resources are not campaign‑specific.

Once a village, a facility, a school, or a household exists as a FHIR resource with a stable identifier, it is the same resource that routine immunization, nutrition, HIV, surveillance, supply chain, and civil registration systems can reference. Campaigns are the first programme to create those resources, because campaigns are the only programme that visits every place. Every programme that follows starts from the same location and population records.

The immunization case makes it concrete. A country that runs a measles campaign and then wants to strengthen routine immunization in the same districts already has, in the registry, the facilities that will deliver routine doses, the community denominators, and the households with children. The transition from campaign mode to routine mode is a change of flag, not a change of system.

* * *
## Why it is safe to adopt
**Eyebrow:** Why it is safe to adopt

**Heading:** An open standard and a reference solution, not a product.
### List
**Open standard** The core is a FHIR R4 Implementation Guide, published by UNICEF under Apache 2.0. Every ICR profile is valid plain FHIR, so any FHIR system can read the data as its base type.

**Aligned with WHO** Designed as the campaign complement to the WHO SMART Immunizations guideline, using the same toolchain and the same routine‑immunization vocabulary where it overlaps.

**Country‑owned** The FHIR store is the country's. Tools connect to it; none of them owns it. Data can be replicated into whatever platforms the country already runs.

**Reference solution, not a platform** Interchangeable open‑source components for collection, transformation, storage, data quality, geospatial planning, warehouse, and reporting. Any component can be swapped. The common data model in the middle holds them together, not a vendor.

**Feeds DHIS2, does not replace it** National reporting continues in DHIS2. The registry supplies validated, place‑linked figures rather than competing for the reporting role.

**A better path to analytics** Building a warehouse from a FHIR store is a single, standard transformation. Mapping every collection tool into a warehouse separately is the work countries are already struggling with.

**Person‑level data is optional and governed** The model works at aggregate, register, and individual level. Where individuals are recorded, a consent profile governs their use.

* * *
## Who it is for
**Eyebrow:** Who it is for

**Heading:** Same registry, different reasons to care.

**Lede:** Pick your seat.

**Tabs:** Donors and global partners · National programmes · District planners · Implementers · Technology partners
### Donors and global partners
- Who: Gavi, GPEI, the END Fund, foundations, WHO and UNICEF headquarters.
- They care about: Cost per round, comparability across countries, equity outcomes, and not funding the same enumeration five times.
- Lead with: Skip the pre‑census · Effectiveness over time · Equity targeting · Validated aggregates
- The story: The same two thousand villages received measles, polio, and lymphatic filariasis interventions within eighteen months and were enumerated three times. With the registry, the first campaign's enumeration is the second campaign's starting point, and the third campaign's coverage can be compared with the first.
### National programmes
- Who: EPI managers, NTD programme managers, health information system leads, planning directorates.
- They care about: Ownership, denominators they can defend, and knowing what is happening in their own country.
- Lead with: Campaign visibility · Denominators you can defend · Campaign‑to‑routine bridge · Common places
- The story: The national campaign calendar as a live map built from the registry, rather than a spreadsheet one person maintains. Two programmes discover they are planning the same districts a month apart, and combine.
### District planners
- Who: District health teams, campaign coordinators, microplanning workshops.
- They care about: Time. Weeks spent cleaning location lists, re‑enumerating, and re‑assigning teams.
- Lead with: Common places · Skip the pre‑census · Visibility of what is coming to the district
- The story: The next round starts from the last one. The settlement list, the posts used, the teams and their areas, and last round's per‑settlement coverage are the first page of the new microplan instead of the output of a three‑week exercise. The hamlet found last time is already on the list.
### Implementers
- Who: NGOs, campaign contractors, ESPEN and similar programmes.
- They care about: Not rebuilding forms, location lists, and pipelines for every client and every country.
- Lead with: Common places · Common model · Validated aggregates
- The story: One form set and one integration pipeline that works in the next country because the target model is the same. The location list arrives from the registry instead of being built from scratch.
### Technology partners
- Who: Data collection, GIS, warehouse, and reporting tool builders.
- They care about: Integration surface and not being locked out.
- Lead with: Common model · Common places · Reference solution, not platform
- The story: Implement one profile set and interoperate with every other component in the reference solution. The IG defines the interface. Read the implementation guide ↗

* * *
## Objections
**Eyebrow:** Objections

**Heading:** The questions we get asked, answered.

| Objection | Answer |
| --- | --- |
| "DHIS2 already does this." | DHIS2 does aggregate reporting and case tracking. It does not hold a reusable campaign model with places, teams, denominators, and protocols that carry across programmes. The registry feeds DHIS2. |
| "Another standard nobody will adopt." | It is FHIR R4, the most widely deployed health data standard, aligned with WHO SMART Guidelines, and every profile is valid plain FHIR. Adoption starts with reading the data, not rewriting systems. |
| "This locks us into one vendor." | Apache 2.0 licence, UNICEF‑published, country‑owned store, interchangeable components. The consortium builds the reference; it does not own the result. |
| "Person‑level data in campaigns is a privacy risk." | The model works at aggregate and register level without individuals. Where individuals are recorded, consent is modelled and governance is explicit. |
| "Our location data is a mess." | That is the first thing the registry fixes, and campaigns are the activity that visits every place to fix it. |
| "The benefit is all in the next round." | Common places and denominator triangulation pay off in this round. Historical loading gives a multi‑year picture before the first ICR‑native round. Where several campaigns run a year, the next round is months away. |
| "We cannot compare across countries; contexts differ." | The standard makes comparison possible; whether to use it is the country's decision. Within‑country comparison across rounds is the primary use. |

* * *
## Footer
- Left: Integrated Campaign Registry · UNICEF with Ona and Crosscut · FHIR R4 · Apache 2.0
- Right: Implementation guide · Contact
