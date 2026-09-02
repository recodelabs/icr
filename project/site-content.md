---
title: ICR site content
version: 0.7.1
last_modified: 2026-09-02T22:20:00Z
source_of: site/index.html
tags:
  - icr
  - valueprop
  - site
---

# ICR site content
<sub>`v0.7.1 · Last modified Sep 2, 2026 at 6:20 PM EDT`</sub>

> [!note] **How to use this file.** Every piece of visible text on `site/index.html` is here, in page order. Edit the text here and ask for the site to be updated from it. Headings marked `##` are page sections, `###` are blocks inside a section. Lines starting with `>` are notes about where the text goes and are not shown on the page. The argument itself lives in [[valueprop]]; this file is the page's wording.

* * *
## Top bar
- Brand: **Integrated Campaign Registry**
- Brand suffix: UNICEF
- Nav links: Why campaigns · Compounding · Benefits · Who it's for · Implementation guide ↗

* * *
## Hero
**Kicker (small line above the headline):** Integrated Campaign Registry

**Headline:** Ensuring every campaign *builds on the last.*

> The phrase "builds on the last" is set in green.

**Browser tab title:** Integrated Campaign Registry — Ensuring every campaign builds on the last

**Subhead:** Health campaigns are expensive but essential to reaching the hard-to-reach. The ICR makes sure their data is reused and validated, so the investment compounds and every round that follows is cheaper and more effective.
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

**Heading:** Whether health services come through routine delivery or a campaign, the aim is the same: reach everyone, equitably.

**Lede:** The hard part is everything that makes that possible: knowing where people are, how many there are, whether they were reached, and who is still missing. Campaigns are the activity best placed to find out.
### Cards
**Campaigns are funded** Campaigns represent a significant investment by governments and donors to ensure services reach those who need them. That funding also carries smaller programmes along: an MDA round can share the teams and logistics of a polio round. The cost of mapping the places and delivering the services is already paid; capturing what was learned costs almost nothing more, and losing it is a waste.

**Campaigns repeat** The same protocol runs again next year, in the same districts, often with the same teams. Repetition is what makes reuse valuable and what makes comparison possible.

**Campaigns have broad reach** Campaigns reach places routine services do not cover. Every village, hamlet, or household visited is a chance to find people who may have been missed.

**Campaigns count** Once to set the target, once to see whether it was met, with monitoring in between to check the count. No other health activity attempts to produce a denominator and a validated result for so many places in so short a time.

* * *
## How value compounds
**Eyebrow:** How value compounds

**Heading:** Every round contributes to shared registries.
### Table
Column heads: Record · Start of round 1 · Start of round 2 · Start of round 5

| Record | Start of round 1 | Start of round 2 | Start of round 5 |
| --- | --- | --- | --- |
| Places | A list of settlement names, some with GPS points, some without | Every settlement visited last round, each with a GPS point and verified name. | A verified settlement map with stable IDs and boundaries, plus points of interest eg. the schools and churches that served as vaccination posts, etc. |
| Denominators | One estimate from the census projection | The census projection and last round's headcount, side by side | Census, WorldPop, previous‑round enumeration, and administrative figures side by side, each with its source recorded |
| People and households | No register yet | Last round's household register, ready for revisits | Household members including number of children and women of reproductive age known enabling further targeting and linkages to routine service delivery. |
| Teams | A list of names | Last round's teams and the areas each one covered | Community drug distributors, vaccinators, and supervisors with a history of which areas they covered and how they performed |
| Coverage | No baseline for these places | One coverage figure per place, from last round | A trend line per place per campaign type, with administrative and survey coverage kept separate |
### Key properties
**Block heading (shown on page):** Key properties

**Resolution‑agnostic** Household, village, or district: the ICR data model is designed to store however the data is captured.

**Backfillable** The ICR is designed to take in past campaign data, so it can serve as the system of record for every round a country has run, not just the ones ahead.

**Sourced** Every population figure and coverage result says where it came from, so a census projection is never mistaken for a field headcount.

**Persistent** Places, households, and teams keep the same identifier from one round to the next.

* * *
## What compounding unlocks
**Eyebrow:** What compounding unlocks

**Heading:** Key ICR benefits.
### Table
Column heads: Benefit · Description (claim and what makes it true, merged)

| Benefit | Description |
| --- | --- |
| Common places | One common source of locations across tools. Stable place IDs and administrative boundaries, linked to health data in FHIR, load straight into field data collection tools such as ODK and DHIS2, so that what each round collects adds to a living map. |
| Better denominators | The ICR makes it easy to compare census, WorldPop, administrative, and last‑round figures side by side, so campaign teams choose their planning denominator with the alternatives in view. |
| Campaign visibility | Every campaign is a record with geography, dates, and status, from microplan to completion. The ICR gives a centralized view of what is planned where that any programme can consult. |
| Skip the pre‑census | Households, delivery units, and teams persist from one round to the next, so a campaign can target from last round's registers instead of enumerating everyone again. |
| Effectiveness over time | The ICR stores campaign records in a standard, comparable form, so coverage trends, cost per person reached, and data quality can be tracked per place and per campaign type, within a country and across countries that share the standard. |
| Campaign‑to‑routine bridge | Campaign and routine records share the same facilities, places, and denominators in one store, with a single flag separating campaign doses from routine ones. The ICR is built on the same HL7 FHIR data model used to represent routine care. |

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
