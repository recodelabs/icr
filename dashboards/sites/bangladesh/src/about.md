---
title: About the data
---

# About the data

<div style="max-width: 860px">

These dashboards put two Bangladesh immunization systems side by side: the MR campaign's reporting system and the routine immunization records. The two are run separately and use different software, places and targets. Here both were loaded into the Integrated Campaign Registry (ICR), one FHIR server kept offline, matched to the same list of places, and compared.

<figure style="margin: 20px 0; max-width: 860px">
<svg viewBox="0 0 860 380" width="100%" role="img" aria-label="The campaign DHIS2, the routine e-Tracker and WorldPop are loaded into the ICR, one FHIR server with a shared list of places, which feeds the dashboards" style="font-family: system-ui, sans-serif">
<defs>
<marker id="about-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#64748b"/></marker>
</defs>
<g font-size="11" fill="#64748b" font-weight="600" letter-spacing="0.4">
<text x="0" y="14">SOURCES</text><text x="320" y="14">WHAT WENT INTO THE ICR</text><text x="620" y="14">DASHBOARDS</text>
</g>
<g>
<rect x="0" y="28" width="250" height="100" rx="8" fill="#eaf2fa" stroke="#518cc3" stroke-width="1.5"/>
<text x="14" y="52" font-size="14" font-weight="600" fill="#1e293b">MR campaign</text>
<text x="14" y="72" font-size="12" fill="#334155">EPI campaign DHIS2</text>
<text x="14" y="92" font-size="11.5" fill="#475569">Daily session totals: children</text>
<text x="14" y="108" font-size="11.5" fill="#475569">targeted and vaccinated, by age</text>
<rect x="0" y="148" width="250" height="100" rx="8" fill="#fbecee" stroke="#d74554" stroke-width="1.5"/>
<text x="14" y="172" font-size="14" font-weight="600" fill="#1e293b">Routine immunization</text>
<text x="14" y="192" font-size="12" fill="#334155">EPI e-Tracker, via the GIS dashboard</text>
<text x="14" y="212" font-size="11.5" fill="#475569">Monthly doses and the annual target</text>
<text x="14" y="228" font-size="11.5" fill="#475569">of children aged 0–11 months</text>
<rect x="0" y="268" width="250" height="100" rx="8" fill="#f1f5f9" stroke="#94a3b8" stroke-width="1.5"/>
<text x="14" y="292" font-size="14" font-weight="600" fill="#1e293b">WorldPop</text>
<text x="14" y="312" font-size="12" fill="#334155">Population estimate, 100 m grid</text>
<text x="14" y="332" font-size="11.5" fill="#475569">Children under 1 per upazila,</text>
<text x="14" y="348" font-size="11.5" fill="#475569">a third, independent figure</text>
</g>
<g stroke="#64748b" stroke-width="1.5" fill="none" marker-end="url(#about-arrow)">
<path d="M250,78 C285,78 285,150 318,150"/>
<path d="M250,198 L318,198"/>
<path d="M250,318 C285,318 285,246 318,246"/>
<path d="M550,198 L618,198"/>
</g>
<g>
<rect x="320" y="28" width="230" height="340" rx="8" fill="#ffffff" stroke="#334155" stroke-width="1.5"/>
<text x="334" y="52" font-size="14" font-weight="600" fill="#1e293b">The ICR: one FHIR server</text>
<text x="334" y="70" font-size="11.5" fill="#475569">kept offline</text>
<rect x="334" y="86" width="202" height="86" rx="6" fill="#fef9c3" stroke="#eab308"/>
<text x="346" y="108" font-size="12.5" font-weight="600" fill="#1e293b">A shared list of places</text>
<text x="346" y="126" font-size="11.5" fill="#475569">Each upazila is one record,</text>
<text x="346" y="142" font-size="11.5" fill="#475569">with a boundary and both</text>
<text x="346" y="158" font-size="11.5" fill="#475569">systems' identifiers</text>
<text x="334" y="200" font-size="12" fill="#334155">Indicators as Measures</text>
<text x="334" y="222" font-size="12" fill="#334155">Values as MeasureReports:</text>
<text x="334" y="240" font-size="11.5" fill="#475569">about 852,000 campaign,</text>
<text x="334" y="256" font-size="11.5" fill="#475569">about 257,000 routine</text>
<text x="334" y="284" font-size="12" fill="#334155">The campaign as a CarePlan</text>
<line x1="334" y1="304" x2="536" y2="304" stroke="#e2e8f0"/>
<text x="334" y="326" font-size="11.5" fill="#475569">Then a data warehouse</text>
<text x="334" y="342" font-size="11.5" fill="#475569">(SQL on FHIR) for the dashboards</text>
</g>
<g>
<rect x="620" y="28" width="240" height="340" rx="8" fill="#ffffff" stroke="#334155" stroke-width="1.5"/>
<text x="634" y="52" font-size="14" font-weight="600" fill="#1e293b">Questions the two sources</text>
<text x="634" y="70" font-size="14" font-weight="600" fill="#1e293b">answer together</text>
<g font-size="12" fill="#334155">
<text x="634" y="108">1. Do routine and the campaign</text>
<text x="650" y="124">plan for the same number</text>
<text x="650" y="140">of children?</text>
<text x="634" y="176">2. Where may the campaign</text>
<text x="650" y="192">have missed children?</text>
<text x="634" y="228">3. Did routine immunization</text>
<text x="650" y="244">change during the campaign?</text>
</g>
<line x1="634" y1="268" x2="846" y2="268" stroke="#e2e8f0"/>
<text x="634" y="292" font-size="11.5" fill="#475569">Compared for 439 upazilas, on</text>
<text x="634" y="308" font-size="11.5" fill="#475569">one group of children: those</text>
<text x="634" y="324" font-size="11.5" fill="#475569">born May 2024 to May 2025</text>
</g>
</svg>
</figure>

## The two sources

| | MR campaign | Routine immunization |
|---|---|---|
| **System** | EPI campaign DHIS2, "National EPI Campaign System" (epicampaign.dghs.gov.bd) | EPI e-Tracker, a DHIS2 Tracker (epietracker.dghs.gov.bd), read through the DGHS GIS dashboard (gisdashboard.dghs.gov.bd) |
| **What it records** | Totals reported by vaccination sessions each day of the campaign: children targeted and vaccinated, vaccine received and used | Doses given to individual children at routine sessions, summed by the dashboard into monthly totals per place |
| **Who it covers** | Children in the campaign's age groups, in community and school sessions | Children aged 0–11 months (the annual target), and the doses on the routine schedule |
| **Period** | The 2026 MR campaign, 5 April to 20 May 2026 | January 2024 to October 2026, by month and by year |
| **How it was read** | DHIS2 analytics API | The coverage files the dashboard publishes (read only) |

## What was imported

### From the campaign DHIS2

- **Places:** the org unit tree, 304,733 units over 7 levels, from the country down to wards, sub-blocks and session sites.
- **Indicators:** 143 indicator and data element definitions, loaded as FHIR Measures. The MR campaign uses 35 of them.
- **The campaign:** one FHIR CarePlan for the 2026 MR campaign.
- **Values:** about 852,000 values, loaded as FHIR MeasureReports, for the country, 8 divisions, 76 districts and city corporations and 805 upazilas. Each value is for a day, a week, a month or the whole campaign.
- **The figures used here:** target and children vaccinated by age group (6 months, 9 months, and each year from 1 to 4), by sex, and for school and community sessions; MR vaccine received and vials used; the reporting rate.

### From the routine e-Tracker

- **Indicators:** 27 measures: the annual target of children aged 0–11 months, and for BCG, Penta-1, Penta-2, Penta-3, MR-1 and MR-2 the doses given, coverage, and children not yet vaccinated, plus two dropout rates.
- **Values:** about 257,000 values for the country, 73 districts and city corporations and 451 upazilas. Each is for a month or a year, from 2024 to 2026.
- **Boundaries:** the dashboard's map boundaries from district down to sub-block, and the locations of EPI centres.

### Added to compare them

- **A shared list of places.** The routine places were matched to the campaign's org units, so one upazila has one record with both systems' figures. About 117,000 places now have a boundary. Places only the e-Tracker has (1,940) were added.
- **WorldPop.** Children under 1 per upazila for 2024 to 2026, from WorldPop Global2 R2025A (100 m grid, CC BY 4.0, DOI 10.5258/SOTON/WP00841), summed over each upazila's boundary. It is a third estimate of the same children, independent of both systems.

## How the two are compared

The comparison pages use one group of children: those born from about May 2024 to May 2025. Routine counted them in its 2025 target of children aged 0–11 months. The campaign counted them a year later as its 1-year age group.

Both systems have figures for 439 upazilas. The comparison pages use those.

## What to keep in mind

- **Campaign targets.** The campaign's target in an upazila is usually close to the number of children its teams vaccinated, so its own coverage is near 100% almost everywhere.
- **Routine reporting.** e-Tracker reporting fell in many upazilas from mid-2025. December 2025 is nearly empty and January 2026 holds late entries. A low routine figure can be missing reports, not missed children.
- **Routine targets.** A few targets are far off for single years (for one year the national target is 621 million). Those years are left out for that place.
- **Places not compared.** Chattogram, Rajbari and Shariatpur districts have no routine figures in the dashboard. City corporations are reported separately by the campaign, so a sadar upazila that shares a city can look low on the campaign side.
- **Campaign data date.** The campaign figures are DHIS2 analytics, last built by DHIS2 on 15 September 2026.
- **Not yet confirmed with the Bangladesh team.** That the campaign's "1 year" age group means children aged 12–23 months, and the campaign's full age range.

## Where the data is

The data is aggregated: totals per place, with no records of individual children. The FHIR server that holds it is kept offline. A private data warehouse is built from that server, and these dashboards, which need sign-in, are built from the warehouse. None of it is public.

</div>
