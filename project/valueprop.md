---
title: ICR Value Proposition
version: 0.3.0
last_modified: 2026-09-01T20:06:49Z
status: working draft for review
tags:
  - icr
  - valueprop
  - comms
---

# ICR — Value Proposition
`v0.3.0 · Last modified Sep 1, 2026 at 4:06 PM EDT`

⁠

> [!note] **Purpose.** This is the source document for how we explain the value of the Integrated Campaign Registry (ICR) to different stakeholders. It is written to be cut into a website, a deck, or a one-pager later. The framing is fixed here; each audience section chooses what to emphasize. Technical detail lives in [[ig-summary-v2]] and the published IG at [icr.healthcampaigns.org](https://icr.healthcampaigns.org). Slide-ready bullets from an earlier pass are in [[preso]].

* * *
## 1. Summary
**Campaign data compounds instead of being re-collected.**

Every health campaign already does the expensive work: it maps the places, counts the people, trains the teams, delivers the intervention, and records the result. Today that work is spent once and archived. With the ICR, every round contributes to a shared, standards-based registry that the next campaign, the next programme, and the routine health system can all draw on. The value of the data grows with every round instead of resetting to zero.

* * *
## 2. Why campaigns first
Public health has many data problems. We start with campaigns for four reasons.

- **Campaigns are funded.** Measles and polio rounds, mass drug administration (MDA), bed-net distribution, indoor residual spraying, and vitamin A supplementation each arrive with a budget and a deadline. There is no need to create a new funding line to make the first contribution.
- **Campaigns repeat.** The same protocol runs again next year, in the same districts, often with the same teams. Repetition is what makes reuse valuable and what makes comparison possible.
- **Campaigns go everywhere.** A house-to-house team walks to the hamlet that no facility register has ever listed. Campaigns are the only health activity that visits every place, including the ones routine services do not reach.
- **Campaigns find the missing.** The zero-dose child, the unlisted settlement, the household behind the river are found by campaign teams every round. The finding already happens. The question is whether it is captured and shared, or written on a tally sheet and lost at the end of the round.

Starting with campaigns is not a narrowing of ambition. It is the fastest way to build the map of places and people that every other programme needs, paid for by activities that are already happening.

* * *
## 3. How value compounds
{>>Resolved c1: "deposit" replaced with "contribution" throughout. Each round contributes to the shared registry of places, denominators, people, teams, and outcomes; that is the "contribution to what".<<}{id="c4" by="claude" at="2026-09-01T20:06:49.000Z"}

Each campaign round contributes to a shared registry of the country's places, denominators, people, teams, and outcomes. The registry holds five kinds of record, and each one gets richer with every round.

| What accumulates | Round 1 | Round 5 |
| --- | --- | --- |
| **Places** | A district list and some GPS points | A verified settlement map with stable IDs, boundaries, and the posts and structures used in each round |
| **Denominators** | One estimate from the census projection | Census, WorldPop, previous-round enumeration, and administrative figures side by side, each with its source recorded |
| **People and households** | A register from this round | Households and school cohorts known across rounds, so follow-up and revisits can be targeted |
| **Teams** | A list of names | Community drug distributors, vaccinators, and supervisors with a history of which areas they covered and how they performed |
| **Outcomes** | One coverage figure | A trend line per place per campaign type, with administrative and survey coverage kept as separate lineages |

Three properties make this compounding work in practice.

**Any resolution is a valid contribution.** The registry stores household-level delivery events and district-level outcome reports in the same model. A current round can contribute village and household detail. A past round can contribute its reported coverage and denominator by district. Both are useful, and the model records which is which.

**Historical data can be loaded now.** The registry does not have to start empty. Outcome-level records from rounds already run can be loaded from existing reports, so a country has a multi-year picture of what happened where before it runs a single ICR-native round. Retrofitted data carries its original quality, and the provenance fields say so. That is a feature: it makes the "before" measurable.

**Resolution improves over time.** Old rounds are aggregate-only. Current rounds are village-level. Future rounds are household-level. The same registry holds all three, and the picture sharpens with each round.

> [!note] **On the round N+1 objection.** The benefit of reuse lands in the next round, but the contribution is made in this round with this round's budget. Two of the pillars below, common places and denominator triangulation, pay off during the current round as well. And where a country runs several campaigns a year, the next round is months away, not years.

* * *
## 4. What compounding unlocks
Seven pillars. Each audience section in §7 picks the ones that matter to it.

| Pillar | The claim | What makes it true |
| --- | --- | --- |
| **Common places** | One georegistry seeds every tool, turnkey | Stable place IDs and boundaries in FHIR, exportable to ODK, DHIS2, Crosscut, and any other tool without re-cleaning |
| **Denominators you can defend** | Census, WorldPop, administrative, and last-round figures side by side, each with its source | Target populations carry provenance; the planning denominator is a recorded choice, not an accident |
| **Skip the pre-census** | Reuse last round's registers, posts, and teams; target instead of re-enumerate | Households, delivery units, and care teams persist across rounds |
| **Campaign visibility** | An official registry of what is planned where, viewable as a map and a calendar | Every campaign is a record with geography, dates, and status, from microplan through completion |
| **Validated aggregates** | The district figure can be traced to the events beneath it | Delivery events roll up to coverage reports; administrative and survey coverage are never merged |
| **Effectiveness over time** | Coverage trend, cost per person reached, and data-quality trend per place and per campaign type | Rounds of the same protocol are directly comparable records, within a country and, where countries share the standard, across them |
| **Campaign-to-routine bridge** | Same facilities, same places, same denominators; one flag separates campaign doses from routine doses | Aligned with the WHO SMART Immunizations guideline; campaign and routine records coexist in one store without contaminating each other's statistics |

Two further consequences fall out of these and deserve a mention in most versions of the pitch.

- **Co-delivery and integration.** Once the registry knows what is planned where, it can surface two campaigns hitting the same wards within weeks of each other. That is the integrated-campaign argument in its most concrete form.
- **Equity targeting.** Historic per-place coverage is the input for finding never-reached settlements and zero-dose children. Same records, different question. The IG already defines a zero-dose coverage measure.

* * *
## 5. Beyond campaigns
{>>Resolved c2: rewrote the opening to say the concrete thing instead of "the location is the pivot".<<}{id="c5" by="claude" at="2026-09-01T20:06:49.000Z"}

The registry is built on HL7 FHIR, and FHIR Location, Organization, Patient, and Group resources are not campaign-specific. Once a village, a facility, a school, or a household exists as a FHIR resource with a stable identifier, it is the same resource that routine immunization, nutrition, HIV, surveillance, supply chain, and civil registration systems can reference. Campaigns are the first programme to create those resources, because campaigns are the only programme that visits every place. Every programme that follows starts from the same location and population records.

This is the order of the argument. Campaigns first, because they are funded and go everywhere. Compounding across campaigns, because they repeat. Then extension beyond campaigns, because the places, people, and facilities are already there in a form every other health system can read.

The immunization case makes it concrete. A country that runs a measles campaign and then wants to strengthen routine immunization in the same districts already has, in the registry, the facilities that will deliver routine doses, the community denominators, and the households with children. The transition from campaign mode to routine mode is a change of flag, not a change of system.

* * *
## 6. Why it is safe to adopt
- **Open standard, not a product.** The core is a FHIR R4 Implementation Guide, published under Apache 2.0 with UNICEF as publisher. Every ICR profile is valid plain FHIR, so any FHIR system can read the data as its base type.
- **Aligned with WHO.** The IG is designed as the campaign complement to the WHO SMART Immunizations guideline, using the same toolchain and the same routine-immunization vocabulary where it overlaps.
- **Country-owned.** The FHIR store is the country's. Tools connect to it; none of them owns it. Data can be replicated into whatever platforms the country already runs.
- **Reference solution, not a platform.** The ICR describes how interchangeable open-source components fit together: data collection, transformation, FHIR store, data quality, geospatial planning, warehouse, reporting. Any component can be swapped. What holds them together is the common data model in the middle, not a vendor.
- **Feeds DHIS2, does not replace it.** National reporting continues in DHIS2. The registry supplies validated, place-linked figures rather than competing for the reporting role.
- **A better path to analytics.** Building a warehouse from a FHIR store is a single, standard transformation. The alternative, mapping every collection tool into a warehouse separately, is the work countries are already struggling with.
- **Person-level data is optional and governed.** The model works at aggregate, register, and individual level. Where individuals are recorded, a consent profile governs their use.

* * *
## 7. By audience
Every audience gets the one sentence, then the pillars that matter to it, then one story. The stories should eventually point at the same demo (§9).
### 7.1 Donors and global partners
*Gavi, GPEI, the END Fund, foundations, WHO and UNICEF headquarters.*

**They care about:** cost per round, comparability across countries, equity outcomes, and not funding the same enumeration five times.

**Lead with:** skip the pre-census, effectiveness over time, equity targeting, validated aggregates.

**Story:** the same two thousand villages received measles, polio, and lymphatic filariasis interventions within eighteen months and were enumerated three times. With the registry, the first campaign's enumeration is the second campaign's starting point, and the third campaign's coverage can be compared with the first.

**Tone:** money, equity, and standards alignment. Avoid FHIR detail. Present cross-country comparison as something the standard makes possible and the country decides to use.
### 7.2 National programmes and ministries
*EPI managers, NTD programme managers, health information system leads, planning directorates.*

**They care about:** ownership, denominators they can defend, and knowing what is happening in their own country.

**Lead with:** campaign visibility, denominators you can defend, campaign-to-routine bridge, common places.

**Story:** the national campaign calendar as a live map built from the registry, rather than a spreadsheet one person maintains. Two programmes discover they are planning the same districts a month apart and combine.

**Tone:** sovereignty and visibility. The store is theirs. Say plainly that it is not another reporting system on top of DHIS2.
### 7.3 District planners and microplanners
*District health teams, campaign coordinators, microplanning workshops.*

**They care about:** time. Weeks spent cleaning location lists, re-enumerating, and re-assigning teams.

**Lead with:** common places, skip the pre-census, visibility of what is coming to their district.

**Story:** round N+1 starts from round N. The settlement list, the posts used, the teams and their areas, and last round's per-settlement coverage are the first page of the new microplan instead of the output of a three-week exercise. The hamlet found last time is already on the list.

**Tone:** shortest and most concrete section. Show a before-and-after microplan timeline.
### 7.4 Implementers and field partners
*NGOs, campaign contractors, ESPEN and similar programmes.*

**They care about:** not rebuilding forms, location lists, and pipelines for every client and every country.

**Lead with:** common places, common model, validated aggregates.

**Story:** one form set and one integration pipeline that works in the next country because the target model is the same. The location list arrives from the registry instead of being built from scratch.

**Tone:** practical. Point at the reference architecture and the example instruments already in the IG.
### 7.5 Technology partners and vendors
*Data collection, GIS, warehouse, and reporting tool builders.*

**They care about:** integration surface and not being locked out.

**Lead with:** common model, common places, reference solution not platform.

**Story:** implement one profile set and interoperate with every other component in the reference solution. The IG defines the interface.

**Tone:** link straight to the IG. This audience reads the profiles.

* * *
## 8. Objections, answered
| Objection | Answer |
| --- | --- |
| "DHIS2 already does this." | DHIS2 does aggregate reporting and case tracking. It does not hold a reusable campaign model with places, teams, denominators, and protocols that carry across programmes. The registry feeds DHIS2. |
| "Another standard nobody will adopt." | It is FHIR R4, the most widely deployed health data standard, aligned with WHO SMART Guidelines, and every profile is valid plain FHIR. Adoption starts with reading the data, not rewriting systems. |
| "This locks us into one vendor." | Apache 2.0 licence, UNICEF-published, country-owned store, interchangeable components. The consortium builds the reference; it does not own the result. |
| "Person-level data in campaigns is a privacy risk." | The model works at aggregate and register level without individuals. Where individuals are recorded, consent is modelled and governance is explicit. |
| "Our location data is a mess." | That is the first thing the registry fixes, and campaigns are the activity that visits every place to fix it. |
| "The benefit is all in the next round." | Common places and denominator triangulation pay off in this round. Historical loading gives a multi-year picture before the first ICR-native round. Where several campaigns run a year, the next round is months away. |
| "We cannot compare across countries; contexts differ." | The standard makes comparison possible; whether to use it is the country's decision. Within-country comparison across rounds is the primary use. |

* * *
## 9. Proof
A value proposition for a standards framework is hard to feel. Every version of this pitch should end by pointing at something the audience can see. Candidates, in order of preference:

1. **The campaign map.** A country view of what is planned and what has happened, by place, across campaign types, built from registry data. A minister, a donor, and a district officer can all read it without explanation. Historical loading makes this achievable early.
2. **One village, five campaigns.** A single named place followed through a measles campaign, a polio round, an MDA, a bed-net distribution, and vitamin A. Show what was re-collected each time and what the registry carries forward. Works as a scrolling web story and as five slides.
3. **The microplan in minutes.** A district microplan generated from the previous round's registry records.

Framing devices to reuse across formats:

- **Round N and round N+1.** A timeline of weeks spent on enumeration, location cleanup, and team assignment, before and after.
- **The layer cake.** Places, people, campaigns, delivery, coverage. Each audience lives in one layer; highlight theirs.
- **The contribution.** Each round adds to the registry. Use it wherever the compounding idea needs a picture.

* * *
## 10. Open items
- [ ] 
  
  Two or three real numbers: enumeration cost per round, microplanning days, campaigns per year in a typical country. Placeholders until we have them.
- [ ] 
  
  Decide the primary demo (§9) and align every audience story to it.
- [ ] 
  
  Pick the first output format: audience-switching web page on healthcampaigns.org, with decks exported from it.
