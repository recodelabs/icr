---
title: ICR Value Proposition
version: 0.2.0
last_modified: 2026-09-01T20:02:44Z
status: working draft for review
tags:
  - icr
  - valueprop
  - comms
---

# ICR — Value Proposition
<sub>`v0.2.0 · Last modified Sep 1, 2026 at 4:02 PM EDT`</sub>

{>>v0.2.0 rewrite pass: replaced "deposit" with "contribution" throughout (c1), rewrote the opening of §5 in plain words (c2), and did a full plain-language pass over the doc. Technical terms are kept only in §6 and §7.5, where the reader expects them, and each is explained the first time it appears.<<}{id="c3" by="claude" at="2026-09-01T20:02:44.000Z"}

> [!note] **Purpose.** This is the source document for how we explain the value of the Integrated Campaign Registry (ICR) to different stakeholders. It is written to be cut into a website, a deck, or a one-pager later. The framing is fixed here; each audience section chooses what to emphasize. Technical detail lives in [[ig-summary-v2]] and the published standard at [icr.healthcampaigns.org](https://icr.healthcampaigns.org). Slide-ready bullets from an earlier pass are in [[preso]].

* * *
## 1. In one sentence
**Campaign data compounds instead of being re-collected.**

Every health campaign already does the expensive work. It maps the places, counts the people, trains the teams, delivers the vaccine or drug or net, and records the result. Today that work is used once and then filed away. With the ICR, every round contributes to a shared record of places, people, and results that the next campaign, the next programme, and the everyday health system can all use. The value of the data grows with every round instead of starting again from zero.

* * *
## 2. Why campaigns first
Public health has many data problems. We start with campaigns for four reasons.

- **Campaigns are funded.** Measles and polio rounds, mass drug administration, bed-net distribution, indoor spraying, and vitamin A supplementation each arrive with a budget and a deadline. No new funding line is needed to make the first contribution.
- **Campaigns repeat.** The same kind of campaign runs again next year, in the same districts, often with the same teams. Repetition is what makes reuse valuable and what makes comparison possible.
- **Campaigns go everywhere.** A house-to-house team walks to the hamlet that no clinic register has ever listed. Campaigns are the only health activity that visits every place, including the ones everyday services do not reach.
- **Campaigns find the missing.** The child who has never been vaccinated, the settlement that is on no list, the household behind the river. Campaign teams find them every round. The finding already happens. The question is whether it is captured and shared, or written on a tally sheet and lost at the end of the round.

Starting with campaigns is not a narrowing of ambition. It is the fastest way to build the map of places and people that every other programme needs, paid for by work that is already happening.

* * *
## 3. How value compounds
{>>Resolved c1: "deposit" is gone. Each round now "contributes to a shared record" of the country's places, people, and campaign results. That answers the "contribution to what" question in the same sentence.<<}{id="c4" by="claude" at="2026-09-01T20:02:44.000Z"}

Each campaign round contributes to a shared record of the country's places, people, teams, and results. The record holds five kinds of information, and each one gets richer with every round.

| What builds up | After round 1 | After round 5 |
| --- | --- | --- |
| **Places** | A district list and some GPS points | A verified map of every settlement, each with a permanent ID and a boundary, plus the vaccination posts and buildings used in each round |
| **Population figures** | One estimate from the census projection | Census, satellite-based estimates, last round's headcount, and government figures side by side, with the source of each one recorded |
| **People and households** | A register from this round | Households and school classes known across rounds, so follow-up visits can be targeted |
| **Teams** | A list of names | Community drug distributors, vaccinators, and supervisors with a history of which areas they covered and how they performed |
| **Results** | One coverage figure | A trend over time for each place and each kind of campaign, with reported coverage and surveyed coverage kept apart |

Three things make this work in practice.

**Any level of detail is a valid contribution.** The record can hold a single vaccination given to a named child in a named household. It can also hold a district's reported coverage figure. A current round can contribute village and household detail. A past round can contribute the coverage and population figures it reported by district. Both are useful, and the record shows which is which.

**Past campaigns can be loaded now.** The record does not have to start empty. Results from rounds already run can be loaded from existing reports, so a country has a multi-year picture of what happened where before it runs a single campaign on the new system. Loaded data keeps whatever quality it had, and the record says where each figure came from. That is a feature: it makes the "before" measurable.

**Detail improves over time.** Old rounds are totals only. Current rounds are village-level. Future rounds are household-level. The same record holds all three, and the picture sharpens with each round.

> [!note] **On the "benefit is in the next round" objection.** The benefit of reuse lands in the next round, but the contribution is made in this round with this round's budget. Two of the benefits below, shared places and comparable population figures, pay off during the current round as well. And where a country runs several campaigns a year, the next round is months away, not years.

* * *
## 4. What compounding unlocks
Seven benefits. Each audience section in §7 picks the ones that matter to it.

| Benefit | The claim | What makes it true |
| --- | --- | --- |
| **Shared places** | One list of places feeds every tool, ready to use | Every settlement, facility, and post has a permanent ID and a boundary that any data-collection, mapping, or reporting tool can load without cleaning it first |
| **Population figures you can defend** | Census, satellite estimates, government figures, and last round's headcount side by side, each with its source | Every population figure records where it came from; the figure chosen for planning is a recorded decision, not an accident |
| **Skip the pre-census** | Reuse last round's registers, posts, and teams; target instead of counting everyone again | Households, communities, schools, and teams persist from one round to the next |
| **Campaign visibility** | An official record of what is planned where, viewable as a map and a calendar | Every campaign is a record with geography, dates, and status, from the first plan through completion |
| **Totals you can check** | The district figure can be traced to the individual visits beneath it | Individual vaccinations and treatments add up to the coverage report; reported coverage and surveyed coverage are never mixed |
| **Effectiveness over time** | Coverage trend, cost per person reached, and data-quality trend for each place and each kind of campaign | Rounds of the same kind of campaign are directly comparable, within a country and, where countries share the standard, across them |
| **Campaign to everyday care** | Same facilities, same places, same population figures; one marker separates campaign doses from routine doses | Campaign and routine records live in one system without distorting each other's statistics, following the WHO guideline for routine immunization data |

Two further consequences follow from these and deserve a mention in most versions of the pitch.

- **Combining campaigns.** Once the record shows what is planned where, it can flag two campaigns hitting the same wards within weeks of each other. That is the integrated-campaign argument in its most concrete form.
- **Reaching the unreached.** Coverage history for each place is the input for finding settlements that have never been reached and children who have never been vaccinated. Same records, different question.

* * *
## 5. Beyond campaigns
{>>Resolved c2: dropped "the location is the pivot" and rewrote the section opening in plain words. The point is that a place, once recorded, is the same place for every programme.<<}{id="c5" by="claude" at="2026-09-01T20:02:44.000Z"}

The registry is not only for campaigns. The reason is simple: **a place, once recorded, is the same place for every health programme.**

When a village, a clinic, a school, or a household is recorded once with a permanent ID, that record can be used by routine immunization, nutrition, HIV, disease surveillance, supply chain, and birth registration. Campaigns are the first programme to record those places, because campaigns are the only programme that visits all of them. Every programme that comes after inherits the map.

This is the order of the argument. Campaigns first, because they are funded and go everywhere. Compounding across campaigns, because they repeat. Then extension beyond campaigns, because the places, people, and facilities are already recorded in a form every other health system can read.

The immunization case makes it concrete. A country that runs a measles campaign and then wants to strengthen routine immunization in the same districts already has, in the registry, the clinics that will give routine doses, the population figures for each community, and the households with children. Moving from campaign mode to everyday mode is a change of marker on the record, not a change of system.

* * *
## 6. Why it is safe to adopt
This section names the technical choices. Each is explained the first time it appears.

- **Open standard, not a product.** The ICR is defined as a specification on top of FHIR, the international standard for exchanging health data. It is published by UNICEF under an open licence (Apache 2.0). Any system that speaks FHIR can read ICR data, whether or not it knows about the ICR.
- **Aligned with WHO.** The ICR is built as the campaign companion to WHO's digital guideline for routine immunization, using the same tools and the same vocabulary where the two overlap.
- **Country-owned.** The database is the country's. Tools connect to it; none of them owns it. Data can be copied into whatever systems the country already runs.
- **Reference solution, not a platform.** The ICR describes how interchangeable open-source parts fit together: data collection, data conversion, the central database, data quality checks, mapping and planning, analysis, and reporting. Any part can be swapped. What holds them together is the shared data model in the middle, not a vendor.
- **Feeds DHIS2, does not replace it.** National reporting continues in DHIS2. The registry supplies checked, place-linked figures to it rather than competing for the reporting role.
- **A better path to analysis.** Building an analysis database from one FHIR database is a single, standard step. The alternative, mapping every collection tool into an analysis database separately, is the work countries are already struggling with.
- **Individual-level data is optional and governed.** The model works with totals and with community registers, without recording individuals. Where individuals are recorded, consent is part of the record and the rules for use are explicit.

* * *
## 7. By audience
Every audience gets the one sentence, then the benefits that matter to it, then one story. The stories should eventually point at the same demo (§9).
### 7.1 Donors and global partners
*Gavi, the polio eradication initiative, the END Fund, foundations, WHO and UNICEF headquarters.*

**They care about:** cost per round, comparability across countries, reaching the unreached, and not paying for the same headcount five times.

**Lead with:** skip the pre-census, effectiveness over time, reaching the unreached, totals you can check.

**Story:** the same two thousand villages received measles, polio, and lymphatic filariasis interventions within eighteen months and were counted three times. With the registry, the first campaign's headcount is the second campaign's starting point, and the third campaign's coverage can be compared with the first.

**Tone:** money, equity, and standards alignment. Avoid technical detail. Present cross-country comparison as something the standard makes possible and the country decides to use.
### 7.2 National programmes and ministries
*Immunization programme managers, neglected tropical disease programme managers, health information leads, planning directorates.*

**They care about:** ownership, population figures they can defend, and knowing what is happening in their own country.

**Lead with:** campaign visibility, population figures you can defend, campaign to everyday care, shared places.

**Story:** the national campaign calendar as a live map built from the registry, rather than a spreadsheet one person maintains. Two programmes discover they are planning the same districts a month apart and combine.

**Tone:** ownership and visibility. The database is theirs. Say plainly that it is not another reporting system on top of DHIS2.
### 7.3 District planners
*District health teams, campaign coordinators, planning workshops.*

**They care about:** time. Weeks spent cleaning location lists, counting households again, and re-assigning teams.

**Lead with:** shared places, skip the pre-census, visibility of what is coming to their district.

**Story:** the next round starts from the last one. The settlement list, the posts used, the teams and their areas, and last round's coverage for each settlement are the first page of the new plan instead of the output of a three-week exercise. The hamlet found last time is already on the list.

**Tone:** shortest and most concrete section. Show a before-and-after planning timeline.
### 7.4 Implementers and field partners
*NGOs, campaign contractors, ESPEN and similar programmes.*

**They care about:** not rebuilding forms, location lists, and data pipelines for every client and every country.

**Lead with:** shared places, shared data model, totals you can check.

**Story:** one set of forms and one data pipeline that works in the next country because the target is the same. The location list arrives from the registry instead of being built from scratch.

**Tone:** practical. Point at the reference architecture and the example forms already published with the standard.
### 7.5 Technology partners and vendors
*Builders of data collection, mapping, analysis, and reporting tools.*

**They care about:** a clear interface to build against and not being locked out.

**Lead with:** shared data model, shared places, reference solution not platform.

**Story:** implement the ICR profiles once and work with every other tool in the ecosystem. The published specification is the contract.

**Tone:** link straight to the published specification. This audience reads the technical detail.

* * *
## 8. Objections, answered
| Objection | Answer |
| --- | --- |
| "DHIS2 already does this." | DHIS2 does national reporting and case tracking. It does not hold a reusable record of places, teams, population figures, and campaign designs that carries across programmes. The registry feeds DHIS2. |
| "Another standard nobody will adopt." | It is built on FHIR, the most widely used health data standard, and aligned with WHO's digital guidelines. Any FHIR system can read the data as-is. Adoption starts with reading the data, not rewriting systems. |
| "This locks us into one vendor." | Open licence, published by UNICEF, country-owned database, interchangeable parts. The consortium builds the reference; it does not own the result. |
| "Individual data in campaigns is a privacy risk." | The model works with totals and community registers without recording individuals. Where individuals are recorded, consent is part of the record and the rules for use are explicit. |
| "Our location data is a mess." | That is the first thing the registry fixes, and campaigns are the activity that visits every place to fix it. |
| "The benefit is all in the next round." | Shared places and comparable population figures pay off in this round. Loading past campaigns gives a multi-year picture before the first round on the new system. Where several campaigns run a year, the next round is months away. |
| "We cannot compare across countries; contexts differ." | The standard makes comparison possible; whether to use it is the country's decision. Comparing rounds within a country is the primary use. |

* * *
## 9. Proof
A value proposition for a standard is hard to feel. Every version of this pitch should end by pointing at something the audience can see. Candidates, in order of preference:

1. **The campaign map.** A country view of what is planned and what has happened, by place, across kinds of campaign, built from registry data. A minister, a donor, and a district officer can all read it without explanation. Loading past campaigns makes this achievable early.
2. **One village, five campaigns.** A single named place followed through a measles campaign, a polio round, a mass drug administration, a bed-net distribution, and vitamin A. Show what was collected again each time and what the registry carries forward. Works as a scrolling web story and as five slides.
3. **The plan in minutes.** A district plan generated from the previous round's registry records.

Framing devices to reuse across formats:

- **This round and the next.** A timeline of weeks spent on headcounts, location cleanup, and team assignment, before and after.
- **The layer cake.** Places, people, campaigns, deliveries, coverage. Each audience lives in one layer; highlight theirs.
- **The contribution.** Each round adds to the shared record. Use it wherever the compounding idea needs a picture.

* * *
## 10. Open items
- [ ] Two or three real numbers: headcount cost per round, planning days, campaigns per year in a typical country. Placeholders until we have them.
- [ ] Decide the primary demo (§9) and align every audience story to it.
- [ ] Pick the first output format: audience-switching web page on healthcampaigns.org, with decks exported from it.
