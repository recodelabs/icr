// ICR-defined code systems (working doc §8).
// Core campaign-semantics codes the IG itself must define; product codes come from
// CVX / ATC / GS1 (see valuesets.fsh). EN + FR designations on the two Required
// systems, matching the pilot-country contexts (working doc §8 localization pattern).

CodeSystem: ICRCampaignTypeCS
Id: icr-campaign-type-cs
Title: "ICR Campaign Type"
Description: "The type of public health campaign, grouped by delivery model rather than disease (working doc §3)."
* ^caseSensitive = true
* ^experimental = false
* #vaccination-sia "Vaccination campaign (SIA)" "Supplementary immunization activity delivering vaccines: measles–rubella, polio, HPV, yellow fever PMVC, OCV."
* #vaccination-sia ^designation[0].language = #fr
* #vaccination-sia ^designation[0].value = "Campagne de vaccination (AVS)"
* #mda "Mass drug administration (NTD preventive chemotherapy)" "Community-scale preventive chemotherapy for the PC-NTDs: LF, onchocerciasis, schistosomiasis, STH, trachoma."
* #mda ^designation[0].language = #fr
* #mda ^designation[0].value = "Distribution de masse de médicaments (chimioprévention MTN)"
* #itn-distribution "ITN mass distribution" "Mass replacement distribution of insecticide-treated nets, typically registration then distribution."
* #itn-distribution ^designation[0].language = #fr
* #itn-distribution ^designation[0].value = "Distribution de masse de MII"
* #irs "Indoor residual spraying" "Structure-by-structure insecticide spraying ahead of the malaria transmission season."
* #irs ^designation[0].language = #fr
* #irs ^designation[0].value = "Pulvérisation intradomiciliaire à effet rémanent"
* #vitamin-a "Vitamin A supplementation" "High-dose vitamin A capsule delivery to children 6–59 months, usually co-delivered."
* #vitamin-a ^designation[0].language = #fr
* #vitamin-a ^designation[0].value = "Supplémentation en vitamine A"
* #integrated "Integrated / multi-intervention campaign" "A campaign co-delivering more than one intervention (e.g. polio + vitamin A); the component activities carry their own types."
* #integrated ^designation[0].language = #fr
* #integrated ^designation[0].value = "Campagne intégrée / multi-interventions"

CodeSystem: ICRDeliveryStrategyCS
Id: icr-delivery-strategy-cs
Title: "ICR Delivery Strategy"
Description: "How a campaign activity reaches its target population. A first-class, coded attribute of every campaign activity, site, and task — campaigns routinely mix strategies, and the available data elements change with the strategy (working doc §3)."
* ^caseSensitive = true
* ^experimental = false
* #fixed-post "Fixed post" "Delivery at a permanent health facility site; people come to the site."
* #fixed-post ^designation[0].language = #fr
* #fixed-post ^designation[0].value = "Poste fixe"
* #temporary-post "Temporary / outreach post" "Delivery at a temporary community focal point: market, place of worship, transit point."
* #temporary-post ^designation[0].language = #fr
* #temporary-post ^designation[0].value = "Poste temporaire / avancé"
* #mobile "Mobile team" "Team deployed to remote areas for a few hours per site."
* #mobile ^designation[0].language = #fr
* #mobile ^designation[0].value = "Équipe mobile"
* #school "School-based" "Delivery through schools to enrolled (and catch-up for non-enrolled) school-age children."
* #school ^designation[0].language = #fr
* #school ^designation[0].value = "En milieu scolaire"
* #house-to-house "House-to-house" "Teams systematically visit every dwelling; the only strategy that natively produces houses-visited, present/absent, and noncompliance data."
* #house-to-house ^designation[0].language = #fr
* #house-to-house ^designation[0].value = "Porte-à-porte"
* #community-directed "Community-directed distribution" "Community-selected drug distributors (CDDs) treat their own communities — the NTD MDA backbone (CDTI)."
* #community-directed ^designation[0].language = #fr
* #community-directed ^designation[0].value = "Distribution communautaire (TIDC)"

CodeSystem: ICRRecordOriginCS
Id: icr-record-origin-cs
Title: "ICR Record Origin"
Description: "Whether a delivery event originated in a campaign or a routine facility visit. Required on every ICR delivery event so SIA doses never contaminate routine coverage analytics, and routine history observed during campaigns stays analyzable (working doc §4.4)."
* ^caseSensitive = true
* ^experimental = false
* #campaign "Campaign / SIA" "Recorded during a time-bounded campaign (SIA, MDA round, distribution)."
* #routine "Routine facility visit" "Recorded during routine service delivery."

CodeSystem: ICRMissedReasonCS
Id: icr-missed-reason-cs
Title: "ICR Missed Reason"
Description: "Why an eligible person or household was not reached during a campaign visit."
* ^caseSensitive = true
* ^experimental = false
* #absent "Absent" "Eligible person not present at the time of the visit."
* #sleeping "Sleeping" "Child asleep and not woken (polio doorstep convention)."
* #sick "Sick" "Deferred due to illness or contraindication at time of visit."
* #refusal "Refusal" "Caregiver or individual refused — capture the noncompliance reason separately."
* #inaccessible "Inaccessible" "Dwelling or settlement could not be reached (security, terrain, weather)."
* #not-visited "Not visited" "Household never reached by a team during the round."
* #other "Other" "Other reason — record detail in text."

CodeSystem: ICRNoncomplianceReasonCS
Id: icr-noncompliance-reason-cs
Title: "ICR Noncompliance Reason"
Description: "Why a household or caregiver declined the intervention — drives social-mobilization targeting and mop-up planning."
* ^caseSensitive = true
* ^experimental = false
* #safety-concern "Safety concern / fear of adverse events" "Fear of AEFI or medicine side effects."
* #religious-objection "Religious or cultural objection" "Belief-based objection."
* #no-felt-need "No felt need" "Does not consider the intervention necessary (e.g. child already vaccinated, not at risk)."
* #campaign-fatigue "Campaign fatigue" "Too many rounds; declines further participation."
* #misinformation "Misinformation / rumor" "Declines based on circulating misinformation."
* #other "Other" "Other reason — record detail in text."

CodeSystem: ICRDenominatorSourceCS
Id: icr-denominator-source-cs
Title: "ICR Denominator Source"
Description: "The method/source behind a target-population estimate. Every estimate carries its source and date — the denominator is the dominant source of error in campaign analytics (working doc §4.2)."
* ^caseSensitive = true
* ^experimental = false
* #census "National census" "Direct census count."
* #census-projection "Census projection" "Forward-projected census figure."
* #microcensus "Microcensus / enumeration" "Local enumeration from microplanning or household registration."
* #worldpop "WorldPop modelled estimate" "Modelled gridded population estimate (WorldPop)."
* #grid3 "GRID3 modelled estimate" "Modelled gridded population estimate (GRID3)."
* #hmis "HMIS-derived" "Derived from routine HMIS targets or registers."
* #other "Other" "Other source — record detail in text."

CodeSystem: ICRDataLineageCS
Id: icr-data-lineage-cs
Title: "ICR Data Lineage"
Description: "Whether a record belongs to the real-time operational stream or the post-campaign reconciled stream. One structure serves both; consumers filter by lineage (working doc §4.3)."
* ^caseSensitive = true
* ^experimental = false
* #realtime "Real-time" "Captured during the active campaign for same-day operational monitoring."
* #reconciled "Reconciled" "Finalized at campaign close: reconciled stock, corrected tallies, final coverage."

CodeSystem: ICRCoverageSourceCS
Id: icr-coverage-source-cs
Title: "ICR Coverage Source"
Description: "The measurement lineage of a coverage figure. Administrative and independently-measured coverage are separately-sourced, first-class measures of the same conceptual quantity and must never be collapsed (working doc §4.1)."
* ^caseSensitive = true
* ^experimental = false
* #administrative "Administrative" "Doses/treatments delivered ÷ planning denominator, from tallies."
* #survey "Coverage survey" "Post-campaign cluster survey estimate."
* #lqas "LQAS" "Lot quality assurance sampling classification."
* #rcm "Rapid convenience monitoring" "Non-probabilistic in-campaign spot checks."
