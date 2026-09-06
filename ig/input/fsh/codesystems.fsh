// ICR-defined code systems (working doc §8).
// Core campaign-semantics codes the IG itself must define; product codes come from
// CVX / ATC / GS1 (see valuesets.fsh). EN + FR designations on every system with a
// required binding (campaign-type, delivery-strategy, record-origin, data-lineage,
// coverage-source, group-kind, task-origin), matching the pilot-country contexts
// (working doc §8 localization pattern). Extensible-bound systems (missed/
// noncompliance reasons, denominator source, location-type) are translated as
// country localization packages mature.

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
* #house-to-house "House-to-house" "Teams systematically visit every dwelling (door-to-door); the only strategy that natively produces houses-visited, present/absent, and refusal data."
* #house-to-house ^designation[0].language = #fr
* #house-to-house ^designation[0].value = "Porte-à-porte"
* #community-directed "Community-directed distribution" "Community-selected drug distributors (CDDs) treat their own communities — the NTD MDA backbone (CDTI)."
* #community-directed ^designation[0].language = #fr
* #community-directed ^designation[0].value = "Distribution communautaire (TIDC)"
* #outreach "Outreach / special-strategy site" "Vaccination at outside-household special-strategy sites (water points, transit/bus stations, border-crossing points, food-distribution points) — the polio SIA 'outside household / special strategy' (OHH/SS) mode, broader than a single temporary post (forms-v1 / jul3-form-analysis §Aggregate #6)."
* #outreach ^designation[0].language = #fr
* #outreach ^designation[0].value = "Stratégie avancée / site spécial"

CodeSystem: ICRRecordOriginCS
Id: icr-record-origin-cs
Title: "ICR Record Origin"
Description: "Whether a delivery event originated in a campaign or a routine facility visit. Required on every ICR delivery event so SIA doses never contaminate routine coverage analytics, and routine history observed during campaigns stays analyzable (working doc §4.4)."
* ^caseSensitive = true
* ^experimental = false
* #campaign "Campaign / SIA" "Recorded during a time-bounded campaign (SIA, MDA round, distribution)."
* #campaign ^designation[0].language = #fr
* #campaign ^designation[0].value = "Campagne / AVS"
* #routine "Routine facility visit" "Recorded during routine service delivery."
* #routine ^designation[0].language = #fr
* #routine ^designation[0].value = "Visite de routine en établissement"

CodeSystem: ICRGroupKindCS
Id: icr-group-kind-cs
Title: "ICR Group Kind"
Description: "The kind of delivery-unit Group a campaign Task acts on. Households, communities, and school cohorts are groups: they have members and an associated Location, and share the same Group + Location pattern; this code distinguishes them. A delivery unit without members (a structure under IRS, a temporary service point, an area target) is a Location, not a Group (working doc §3.2, §7.5)."
* ^caseSensitive = true
* ^experimental = false
* #household "Household" "The people of one dwelling — the house-to-house delivery unit. Its Location is the dwelling."
* #household ^designation[0].language = #fr
* #household ^designation[0].value = "Ménage"
* #community "Community" "The people of a settlement or community — the community/MDA delivery unit. Its Location is the settlement or community point."
* #community ^designation[0].language = #fr
* #community ^designation[0].value = "Communauté"
* #school-cohort "School cohort" "The enrolled children of one school — the school-based delivery unit (HPV, school-based MDA/deworming). Its Location is the school. Also demonstrates that this system extends to further delivery-unit kinds (nomadic groups, camp populations) as country demand appears."
* #school-cohort ^designation[0].language = #fr
* #school-cohort ^designation[0].value = "Cohorte scolaire"

CodeSystem: ICRTaskOriginCS
Id: icr-task-origin-cs
Title: "ICR Task Origin"
Description: "Whether a campaign Task was generated in advance from the microplan or registered in the field on discovery. Field-registered counts per area measure how incomplete the microplan's enumeration was — input to the next round's denominators (working doc §10 q1)."
* ^caseSensitive = true
* ^experimental = false
* #pre-planned "Pre-planned" "Generated in advance from the microplan (e.g. one Task per enumerated household or planned site-session)."
* #pre-planned ^designation[0].language = #fr
* #pre-planned ^designation[0].value = "Planifiée à l'avance"
* #field-registered "Field-registered" "Created in the field on discovery — e.g. an unenumerated household found during a house-to-house sweep, registered as it is visited."
* #field-registered ^designation[0].language = #fr
* #field-registered ^designation[0].value = "Enregistrée sur le terrain"

CodeSystem: ICRLocationTypeCS
Id: icr-location-type-cs
Title: "ICR Location Type"
Description: "Campaign-relevant location types. Type — not tree position — is what distinguishes official administrative units from operational geography: every Location lives in the single partOf containment tree, and administrative rollups filter on type = admin-unit (working doc §9)."
* ^caseSensitive = true
* ^experimental = false
* #admin-unit "Administrative unit" "A unit of the administrative hierarchy: country, region, district, ward."
* #settlement "Settlement" "A settlement or village — operational geography below the formal admin hierarchy."
* #facility "Health facility" "A permanent health facility."
* #school "School" "A school used as a delivery site."
* #community-distribution-point "Community distribution point" "A community focal point used for distribution (market, place of worship, transit point)."
* #temporary-post "Temporary post" "A temporary or outreach vaccination/delivery post."
* #household "Household dwelling" "The physical dwelling of a household."
* #supervisory-area "Supervisory area" "An operational supervision area — a group of settlements or sites under one supervisor. Not an admin unit: it attaches via partOf at the lowest admin unit that fully contains it (its district; region/state if it spans districts)."
* #operational-area "Operational area" "An operational planning area that does not match an admin unit (e.g. polio operational boundaries differing from RI catchments). Not an admin unit: it attaches via partOf at the lowest admin unit that fully contains it."

CodeSystem: ICRGroupCharacteristicCS
Id: icr-group-characteristic-cs
Title: "ICR Group Characteristic"
Description: "Characteristic codes for ICR Group profiles — the geographic-scope characteristic that links a target-population estimate to its Location, making estimates computably joinable to the location hierarchy (working doc §7.6), plus the age-band characteristic used to scope age-specific denominator Groups (espen-forms)."
* ^caseSensitive = true
* ^experimental = false
* #geography "Geographic scope" "The Location (admin unit, settlement, or operational area) this target-population estimate is scoped to."
* #age-band "Age band" "The age band (e.g. 1-4, 5-14, 15+ years) this target-population estimate is scoped to."

CodeSystem: ICRMissedReasonCS
Id: icr-missed-reason-cs
Title: "ICR Missed Reason"
Description: "Why an eligible person or household was not reached during a campaign visit."
* ^caseSensitive = true
* ^experimental = false
* #absent "Absent" "Eligible person not present at the time of the visit."
* #sleeping "Sleeping" "Child asleep and not woken (polio doorstep convention)."
* #sick "Sick" "Deferred due to illness or contraindication at time of visit."
* #refusal "Refusal" "Caregiver or individual refused — capture the refusal reason separately."
* #refusal ^designation[0].language = #en-US
* #refusal ^designation[0].value = "Population refusal"
* #inaccessible "Inaccessible" "Dwelling or settlement could not be reached (security, terrain, weather)."
* #not-visited "Not visited" "Household never reached by a team during the round."
* #not-visited ^designation[0].language = #en-US
* #not-visited ^designation[0].value = "Absence of DC"
* #not-revisited "House not revisited" "Household was flagged for a revisit (e.g. child absent on first pass) but the revisit did not happen before the round closed — distinct from never-visited. Polio house-to-house monitoring reason (forms-v1 / jul3-form-analysis §Aggregate #4)."
// Area-level non-treatment reasons (ESPEN supervision Form 5): why a whole
// settlement/operational area went untreated — distinct from a person being
// missed at a visit. Added v0.18.0 (espen.md rec 7 / §17.2 C3).
* #medication-shortage "Medication shortage" "Area not treated because the medicine/commodity ran out or never arrived."
* #insecurity "Insecurity" "Area not reached due to armed conflict, unrest, or security restrictions."
* #difficult-access "Difficult access" "Area not reached due to terrain, distance, or seasonal inaccessibility."
* #not-required "Not required" "Area not treated because it was not targeted this round (e.g. not co-endemic for the disease)."
* #other "Other" "Other reason — record detail in text."

CodeSystem: ICRNoncomplianceReasonCS
Id: icr-noncompliance-reason-cs
Title: "ICR Refusal Reason"
Description: "Why a household or caregiver refused the intervention (WHO IDHC: 'intervention refusal'; ESPEN forms say noncompliance) — drives social-mobilization targeting and mop-up planning."
* ^caseSensitive = true
* ^experimental = false
* #safety-concern "Safety concern / fear of adverse events" "Fear of AEFI or medicine side effects."
* #religious-objection "Religious or cultural objection" "Belief-based objection."
* #no-felt-need "No felt need" "Does not consider the intervention necessary (e.g. child already vaccinated, not at risk)."
* #campaign-fatigue "Campaign fatigue" "Too many rounds; declines further participation."
* #misinformation "Misinformation / rumor" "Declines based on circulating misinformation (including disease-specific rumours — e.g. 'Africa is polio-free', vaccine-specific concerns; localise via ConceptMap)."
* #not-decision-maker "Not the decision-maker" "The person present could not consent; the household decision-maker was absent. Recurring polio SIA refusal reason (forms-v1 / jul3-form-analysis §Aggregate #4)."
* #other "Other" "Other reason — record detail in text."

CodeSystem: ICRExclusionReasonCS
Id: icr-exclusion-reason-cs
Title: "ICR Exclusion Reason"
Description: "Why a PRESENT, age-eligible person was not treated because they are clinically ineligible/contraindicated for the intervention this round — as opposed to being MISSED (not reached, ICRMissedReasonCS) or DECLINING (ICRNoncomplianceReasonCS). The MDA case (ESPEN treatment Form 3): under the dose-pole minimum, pregnant, breastfeeding, acutely ill. Added v0.18.0 (espen.md rec 2 / §17.4 NTD specifics)."
* ^caseSensitive = true
* ^experimental = false
* #under-height-age "Below dose-pole minimum (height/age)" "Below the intervention's minimum dose-pole height or age threshold (e.g. children under ~90 cm for height-dosed PC-NTD drugs; under the minimum age for azithromycin)."
* #pregnant "Pregnant" "Excluded this round because pregnant (drug contraindicated in pregnancy)."
* #breastfeeding "Breastfeeding / lactating" "Excluded this round because breastfeeding (drug contraindicated while lactating, per protocol)."
* #acute-illness "Acute illness / clinical contraindication" "Excluded due to acute illness or a clinical contraindication at the time of the visit. Reconciles with the deferral sense of ICRMissedReasonCS#sick — see §17.2 C3."
* #other "Other contraindication" "Other clinical exclusion — record detail in text."

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
* #govt-estimate "Government estimate" "An official government figure whose underlying method is unspecified — the low-precision escape that lets early or administrative estimates declare a source (v0.1: denominator-source is mandatory on every estimate)."
* #unknown "Unknown" "Source not recorded — for historical/back-loaded datasets where provenance cannot be reconstructed."
* #other "Other" "Other source — record detail in text."

CodeSystem: ICRDataLineageCS
Id: icr-data-lineage-cs
Title: "ICR Data Lineage"
Description: "Whether a record belongs to the real-time operational stream or the post-campaign reconciled stream. One structure serves both; consumers filter by lineage (working doc §4.3)."
* ^caseSensitive = true
* ^experimental = false
* #realtime "Real-time" "Captured during the active campaign for same-day operational monitoring."
* #realtime ^designation[0].language = #fr
* #realtime ^designation[0].value = "Temps réel"
* #reconciled "Reconciled" "Finalized at campaign close: reconciled stock, corrected tallies, final coverage."
* #reconciled ^designation[0].language = #fr
* #reconciled ^designation[0].value = "Réconcilié"

CodeSystem: ICRCoverageSourceCS
Id: icr-coverage-source-cs
Title: "ICR Coverage Source"
Description: "The measurement lineage of a coverage figure. Administrative and independently-measured coverage are separately-sourced, first-class measures of the same conceptual quantity and must never be collapsed (working doc §4.1)."
* ^caseSensitive = true
* ^experimental = false
* #administrative "Administrative" "Doses/treatments delivered ÷ planning denominator, from tallies."
* #administrative ^designation[0].language = #fr
* #administrative ^designation[0].value = "Couverture administrative"
* #survey "Coverage survey" "Post-campaign cluster survey estimate."
* #survey ^designation[0].language = #fr
* #survey ^designation[0].value = "Enquête de couverture"
* #lqas "LQAS" "Lot quality assurance sampling classification."
* #lqas ^designation[0].language = #fr
* #lqas ^designation[0].value = "Échantillonnage par lots pour l'assurance de la qualité (LQAS)"
* #rcm "Rapid convenience monitoring" "Non-probabilistic in-campaign spot checks."
* #rcm ^designation[0].language = #fr
* #rcm ^designation[0].value = "Monitorage rapide de convenance"

// --- v0.19.0 additions (espen-v3 round) ---------------------------------------

CodeSystem: ICRCoverageStratifierCS
Id: icr-coverage-stratifier-cs
Title: "ICR Coverage Stratifier"
Description: "The standard disaggregation axes a coverage MeasureReport stratifies by (and a Measure declares). Formalises the v0.18.0 stratified-tally pattern into a named contract (espen-v3 / §17.2 B1)."
* ^caseSensitive = true
* ^experimental = false
* #sex "Sex" "Disaggregation by administrative sex (maps to Patient.gender)."
* #age-band "Age band" "Disaggregation by the campaign's eligibility age bands (e.g. 5–14, 15+)."
* #delivery-strategy "Delivery strategy" "Disaggregation by ICRDeliveryStrategy (fixed-post, house-to-house, community-directed…)."
* #disposition "Disposition" "Disaggregation by treatment disposition (treated vs not-treated reason: absent, refused, excluded)."
* #geography "Geography" "Disaggregation by the location/admin level the figure covers."
* #dose-history "Dose history / zero-dose status" "Disaggregation by prior-dose status (ICRDoseHistoryCS: zero-dose | previously-received | no-recall) — the polio SIA tally's never-received / previously-received / no-recall split, and the zero-dose vs not-zero-dose axis (forms-v1 / jul3-form-analysis §Aggregate #1)."
* #readiness-domain "Readiness domain" "Disaggregation of the campaign-readiness measure by checklist domain (microplan | cold-chain | social-mobilization | trainings) (forms-v1 / jul3-form-analysis §Aggregate #2)."
* #cost-category "Cost category" "Disaggregation of a cost report's total-cost figure by ICRCostCategoryCS (personnel, transport, commodities…) (cost-v1)."
* #funding-source "Funding source" "Disaggregation of a cost report's total-cost figure by who paid (ICRFundingSourceCS) (cost-v1)."

CodeSystem: ICRDenominatorTypeCS
Id: icr-denominator-type-cs
Title: "ICR Denominator Type"
Description: "Whether a coverage figure (or a target-population estimate) is measured against the TOTAL population or the AT-RISK/eligible subset — the difference between programme coverage and epidemiological coverage in NTD MDA (espen-v3 / §17.2 B1)."
* ^caseSensitive = true
* ^experimental = false
* #total-population "Total population" "Denominator is the whole resident population of the area."
* #at-risk "At-risk / eligible" "Denominator is the eligible/at-risk subset (e.g. the MDA-eligible age band, or the at-risk population for epidemiological coverage)."

CodeSystem: ICRCoverageUnitCS
Id: icr-coverage-unit-cs
Title: "ICR Coverage Unit"
Description: "What is being counted in a coverage figure: people, or implementation units. Implementation-unit coverage is geographic coverage — villages/areas treated ÷ total (ESPEN supervision Form 5; espen-v3 / §17.2 B1)."
* ^caseSensitive = true
* ^experimental = false
* #people "People" "Numerator/denominator count individuals (the usual dose/treatment coverage)."
* #implementation-units "Implementation units" "Numerator/denominator count areas/units (villages, settlements, operational areas) — geographic coverage."

CodeSystem: ICRAdverseEventCausalityCS
Id: icr-adverse-event-causality-cs
Title: "ICR Adverse Event Causality"
Description: "WHO/CIOMS causality classification of an adverse event following an intervention — intervention-neutral: covers AEFI (immunization) and MDA drug pharmacovigilance alike. Top-level WHO categories; immunization implementations may use WHO IMMZ.AdverseEvent's finer A1–A4 subtypes (espen-v3 / §17.2 C1)."
* ^caseSensitive = true
* ^experimental = false
* #a-consistent "A — Consistent causal association" "Consistent causal association to the intervention (WHO category A; immunization subtypes A1 product, A2 quality defect, A3 administration error, A4 anxiety)."
* #b-indeterminate "B — Indeterminate" "Indeterminate: conflicting trends or insufficient evidence."
* #c-coincidental "C — Coincidental / inconsistent" "Inconsistent causal association — coincidental, due to underlying/emerging condition or other exposure."
* #d-unclassifiable "D — Unclassifiable" "Unclassifiable: insufficient information to assess."

CodeSystem: ICRTeamRoleCS
Id: icr-team-role-cs
Title: "ICR Team Role"
Description: "Role of a member within a campaign CareTeam — the front-line delivery and supervision roles (working doc §5.5). Bound extensible: countries add local roles. Supervisor *level* (national/regional/district/partner/health-facility, ESPEN Forms 5/6) is carried by managingOrganization or the overseen area, not multiplied into roles."
* ^caseSensitive = true
* ^experimental = false
* #vaccinator "Vaccinator" "Administers vaccines at a post or house-to-house."
* #cdd "Community drug distributor (CDD)" "Community-selected distributor who delivers MDA treatment (CDTI backbone)."
* #supervisor "Supervisor" "Oversees a team/area and very often files the report; see the oversees-area extension and MeasureReport.reporter."
* #social-mobilizer "Social mobilizer" "Conducts community sensitisation / demand generation (social and behaviour change, SBC) ahead of and during the campaign."
* #enumerator "Enumerator" "Registers households and individuals and captures/reports the data (enumeration, tally sheets, registers, digital forms) — WHO IDHC enumeration/registrar role; ESPEN instruments call this role the recorder."

// --- v0.20.0 additions (espen-v4 round: fuller supervision + AE finish) --------

CodeSystem: ICRCommunicationChannelCS
Id: icr-communication-channel-cs
Title: "ICR Communication Channel"
Description: "Social-mobilization / demand-generation channels used to inform the population ahead of and during a campaign (ESPEN supervision Form 5). Bound extensible (espen-v4 / §17.3)."
* ^caseSensitive = true
* ^experimental = false
* #radio "Radio" "Radio spots/announcements."
* #town-criers "Town criers" "Community announcers / town criers."
* #community-leaders "Community leaders" "Mobilization through community/religious leaders."
* #schools "Schools" "Sensitisation through schools."
* #posters "Posters" "Printed posters / banners."
* #megaphone "Megaphone / public address" "Mobile public-address announcements."
* #sms "SMS / mobile" "SMS or mobile-message campaigns."
* #health-worker "Health worker" "Information conveyed by a health worker."
* #religious-leader "Religious leader" "Mobilization through religious leaders (distinct from community leaders)."
* #social-mobilizer "Social mobilizer / CBV" "Community-based volunteer / social mobilizer outreach."
* #volunteer-chw "Volunteer community health worker" "Volunteer CHW household visits/announcements."
* #mobile-pa "Mobile van / public-address" "Mobile van or vehicle-mounted public-address announcements."
* #social-media "Mobile messaging / social media" "Social-media or mobile-messaging channels (WhatsApp, Facebook…)."
* #tv "Television" "Television spots/announcements."
* #newspaper "Newspaper" "Print newspaper."
* #iec-materials "IEC materials" "Printed information-education-communication materials."
* #neighbour "Neighbour / word of mouth" "Informed by a neighbour or word of mouth."
* #other "Other" "Other channel — record detail in text."

CodeSystem: ICRSeriousCriteriaCS
Id: icr-serious-criteria-cs
Title: "ICR Serious-Event Criteria"
Description: "WHO/CIOMS criteria that make an adverse event SERIOUS — the reason behind AdverseEvent.seriousness = serious. Intervention-neutral (AEFI and MDA pharmacovigilance) (espen-v4 / §17.2 C1)."
* ^caseSensitive = true
* ^experimental = false
* #death "Results in death" "The event resulted in death."
* #life-threatening "Life-threatening" "The event was life-threatening."
* #hospitalization "Requires/prolongs hospitalization" "Required inpatient hospitalization or prolonged an existing stay."
* #disability "Persistent / significant disability" "Resulted in persistent or significant disability/incapacity."
* #congenital-anomaly "Congenital anomaly / birth defect" "Resulted in a congenital anomaly/birth defect."
* #medically-important "Other medically important event" "A medically important condition not otherwise listed (clinical judgement)."

// --- v0.21.0 additions (forms-v1 round: UNICEF polio SIA form analysis) ---------
// Driven by jul3-form-analysis.md (Kenya nOPV2 + Ghana mOPV2 monitoring/tally/
// stock/supervision forms). Each addition promotes a §13.2-proposed item the forms
// field-validated, or a trivially-additive extensible code the forms surfaced.

CodeSystem: ICRDoseHistoryCS
Id: icr-dose-history-cs
Title: "ICR Dose History / Zero-dose Status"
Description: "A person's prior-dose status for the campaign antigen, at the time of a campaign contact — the polio SIA tally's core split (never received / previously received / no recall) and the zero-dose vs not-zero-dose axis. Carried per event by the prior-dose-status extension and aggregated as the dose-history coverage stratifier; feeds zero-dose reach and the proposed dropout/fully-immunized measures (forms-v1 / jul3-form-analysis §Aggregate #1)."
* ^caseSensitive = true
* ^experimental = false
* #zero-dose "Zero-dose" "Never received the antigen before this contact (the polio 'never received nOPV2 / >2 weeks old & never received OPV' cell). The zero-dose population."
* #previously-received "Previously received" "Had received the antigen before this contact (the 'previously received' / 'not zero-dose' cell)."
* #no-recall "No recall / no information" "Prior-dose status unknown — caregiver cannot recall and no record is available."

CodeSystem: ICRRevisitOutcomeCS
Id: icr-revisit-outcome-cs
Title: "ICR Revisit Outcome"
Description: "The outcome of a follow-up visit to a household/person previously missed — the 'outcome of the revisit' block of the missed-children recording forms. Carried on the follow-up Task via the revisit-outcome extension (forms-v1 / jul3-form-analysis §Aggregate #4)."
* ^caseSensitive = true
* ^experimental = false
* #already-vaccinated "Already vaccinated" "On revisit the person was found already vaccinated (e.g. reached elsewhere / in routine)."
* #vaccinated-on-revisit "Vaccinated on revisit" "The person was vaccinated during the revisit."
* #still-missing "Still missing" "The person was still not reached on revisit."

CodeSystem: ICRSettlementTypeCS
Id: icr-settlement-type-cs
Title: "ICR Settlement / Special-population Type"
Description: "The settlement or special-population classification of a place — the recurring 'type of settlement' axis on the polio SIA monitoring/tally forms (urban / rural / slum / refugee-IDP / nomad-pastoralist / security-compromised / hard-to-reach / cross-border / immigrant). A vulnerability/equity attribute of a Location, carried by the settlement-type extension; drives hard-to-reach-area (HTRA) targeting and equity disaggregation (forms-v1 / jul3-form-analysis §Aggregate #5). Bound extensible — countries add local codes."
* ^caseSensitive = true
* ^experimental = false
* #ordinary "Ordinary / general population" "Standard resident population, no special classification."
* #urban "Urban" "Urban settlement."
* #rural "Rural" "Rural settlement."
* #urban-slum "Urban slum / informal settlement" "Dense informal urban settlement."
* #refugee-idp "Refugee / IDP" "Refugee or internally-displaced-person population/camp."
* #nomad-pastoralist "Nomadic / pastoralist" "Mobile nomadic or pastoralist population."
* #security-compromised "Security-compromised" "Area with insecurity / access constraints."
* #hard-to-reach "Hard-to-reach" "Area hard to reach for terrain, distance or seasonal reasons (HTRA)."
* #cross-border "Cross-border" "Cross-border / border-crossing population."
* #immigrant "Immigrant" "Immigrant population."
* #other "Other" "Other settlement/special-population type — record detail in text."

// --- espen-forms: NTD-MDA vocabulary from the ESPEN demo instruments -----------

CodeSystem: ICRNTDDiseaseCS
Id: icr-ntd-disease-cs
Title: "ICR NTD Disease"
Description: "The preventive-chemotherapy NTDs an MDA campaign addresses — the disease-scope axis of the ESPEN MDA instruments (espen-forms)."
* ^caseSensitive = true
* ^experimental = false
* #lf "Lymphatic filariasis (LF)"
* #oncho "Onchocerciasis"
* #schisto "Schistosomiasis"
* #sth "Soil-transmitted helminthiasis (STH)"
* #trachoma "Trachoma"

CodeSystem: ICRMDAMedicinePackageCS
Id: icr-mda-medicine-package-cs
Title: "ICR MDA Medicine Package"
Description: "The medicine package distributed in an MDA round — single drugs and the standard co-administration combinations (ESPEN medicine list, espen-forms)."
* ^caseSensitive = true
* ^experimental = false
* #ivm "IVM (ivermectin)"
* #ivm-alb "IVM + ALB"
* #ivm-alb-dec "IVM + ALB + DEC"
* #alb "ALB (albendazole)"
* #meb "MEB (mebendazole)"
* #pzq "PZQ (praziquantel)"
* #pzq-alb "PZQ + ALB"
* #pzq-meb "PZQ + MEB"
* #azm-tab "AZM tablets (azithromycin)"
* #azm-susp "AZM suspension (azithromycin)"
* #tetra "TETRA (tetracycline eye ointment)"

CodeSystem: ICRProjectTagCS
Id: icr-project-tag-cs
Title: "ICR Project Tag"
Description: "Project/programme provenance tags applied as meta.tag on example instances, so the example gallery can be filtered by the source project or instrument set (espen-forms)."
* ^caseSensitive = true
* ^experimental = false
* #espen "ESPEN" "The ESPEN MDA demo instrument set and its scenario examples."
* #mr-sia "MR SIA (Sierra Leone)" "The worked Sierra Leone measles-rubella SIA scenario (working doc §11): protocol, umbrella + round campaigns, site-session/mop-up/follow-up tasks, dose, AEFIs, and the admin-vs-survey coverage pair."
* #mda "MDA (Rokupr)" "The community-directed albendazole MDA thread: drug supply, community task, register entry, stratified treatment tally, geographic coverage, and supervision."
* #gallery "Gallery" "Standalone activity-gallery pieces demonstrating other campaign types (ITN distribution, IRS)."

CodeSystem: ICRFacilityTypeCS
Id: icr-facility-type-cs
Title: "ICR Facility Type"
Description: "National facility-classification tiers for the mCSD-style facility Organization (working doc §5.3 facility pairing). The authoritative classification axis lives on Organization.type — not Location.type — because facility level is an administrative designation (funding, staffing norms, reporting), which is an Organization concern. Codes are the broad tiers shared across national MFLs; the country-specific kind (e.g. Nigeria NHFR 'Primary Health Center' vs 'Health Post') travels as the coding display/text or a country localization system."
* ^caseSensitive = true
* ^experimental = false
* #primary "Primary care facility" "First-contact care: health posts, dispensaries, primary health clinics and centres."
* #primary ^designation[0].language = #fr
* #primary ^designation[0].value = "Établissement de soins primaires"
* #secondary "Secondary care facility" "Referral care: general/district hospitals."
* #secondary ^designation[0].language = #fr
* #secondary ^designation[0].value = "Établissement de soins secondaires"
* #tertiary "Tertiary care facility" "Specialized referral care: teaching, specialist and federal medical centres."
* #tertiary ^designation[0].language = #fr
* #tertiary ^designation[0].value = "Établissement de soins tertiaires"
* #unknown "Unknown level" "The national registry does not record or know the facility's tier — the low-precision escape so unclassified facilities aren't blocked."
* #unknown ^designation[0].language = #fr
* #unknown ^designation[0].value = "Niveau inconnu"

CodeSystem: ICROwnershipCS
Id: icr-ownership-cs
Title: "ICR Facility Ownership"
Description: "Ownership / managing-authority classification for the facility Organization — a second Organization.type axis (base FHIR Organization has no ownership element; carrying it as a type coding is the mCSD/OpenHIE convention). The governmental tier detail (local/state/federal) travels as display/text or a country localization."
* ^caseSensitive = true
* ^experimental = false
* #public "Public" "Government-owned at any tier (local, state/regional, federal/national)."
* #public ^designation[0].language = #fr
* #public ^designation[0].value = "Public"
* #private-for-profit "Private for-profit" "Privately owned, operated for profit."
* #private-for-profit ^designation[0].language = #fr
* #private-for-profit ^designation[0].value = "Privé à but lucratif"
* #private-not-for-profit "Private not-for-profit" "Privately owned, operated not for profit (NGO, community)."
* #private-not-for-profit ^designation[0].language = #fr
* #private-not-for-profit ^designation[0].value = "Privé à but non lucratif"
* #faith-based "Faith-based" "Owned or operated by a religious organization or faith-based network."
* #faith-based ^designation[0].language = #fr
* #faith-based ^designation[0].value = "Confessionnel"
* #military "Military / paramilitary" "Owned by military or paramilitary formations."
* #military ^designation[0].language = #fr
* #military ^designation[0].value = "Militaire / paramilitaire"
* #unknown "Unknown ownership" "The national registry does not record or know the owner — the low-precision escape."
* #unknown ^designation[0].language = #fr
* #unknown ^designation[0].value = "Propriété inconnue"

CodeSystem: ICRLocationStatusCS
Id: icr-location-status-cs
Title: "ICR Location Status"
Description: "Pre-coordinated property codes for location-scoped status assertions (ICRLocationStatus): WHAT is being asserted about a place. One code per property × disease — the same pre-coordination pattern as the campaign-type and stratifier vocabularies — so 'which districts are LF-endemic' is a single-code query. A new location property is a new code here, not a new profile."
* ^caseSensitive = true
* ^experimental = false
* #lf-endemicity "Lymphatic filariasis endemicity" "Endemicity status of the location for lymphatic filariasis."
* #oncho-endemicity "Onchocerciasis endemicity" "Endemicity status of the location for onchocerciasis."
* #schisto-endemicity "Schistosomiasis endemicity" "Endemicity status of the location for schistosomiasis."
* #sth-endemicity "Soil-transmitted helminthiasis endemicity" "Endemicity status of the location for the soil-transmitted helminthiases."
* #trachoma-endemicity "Trachoma endemicity" "Endemicity status of the location for trachoma."

CodeSystem: ICREndemicityStatusCS
Id: icr-endemicity-status-cs
Title: "ICR Endemicity Status"
Description: "The endemicity classification ladder for a location, aligned with the WHO JRSM district-level endemicity categories — the value side of the ICRLocationStatus endemicity property codes."
* ^caseSensitive = true
* ^experimental = false
* #endemic-mda-not-started "Endemic, MDA not started" "The disease is endemic in this location and preventive chemotherapy has not yet begun."
* #endemic-under-mda "Endemic, under MDA" "The disease is endemic and the location is under active preventive-chemotherapy rounds."
* #post-mda-surveillance "Under post-MDA surveillance" "MDA has stopped after meeting stopping criteria; the location is under post-treatment surveillance (e.g. TAS for LF)."
* #elimination-validated "Elimination validated" "WHO has validated or verified elimination (of transmission, or as a public-health problem) for this disease in the geography covering this location."
* #non-endemic "Non-endemic" "The disease is not endemic in this location."
* #unknown "Unknown (mapping required)" "Endemicity has not been determined; mapping is required."

CodeSystem: ICRCommodityClassCS
Id: icr-commodity-class-cs
Title: "ICR Commodity Class"
Description: "Analytics-stable classes for physical campaign commodities. GS1 GTINs identify a specific manufacturer's product and cannot be enumerated in a value set; the class code is what measures count ('how many nets'), while a GTIN coding may sit alongside it in the same CodeableConcept ('which net'). Drug commodities do not live here — they stay WHO ATC (supply-split round)."
* ^caseSensitive = true
* ^experimental = false
* #llin "Long-lasting insecticidal net (LLIN)" "An insecticide-treated bed net for malaria prevention."
* #irs-insecticide "IRS insecticide" "Insecticide consumable for indoor residual spraying (e.g. Pirimiphos-methyl 300CS)."
* #rdt "Rapid diagnostic test" "A rapid diagnostic test kit (e.g. malaria RDT)."

CodeSystem: ICRTaskOutputTypeCS
Id: icr-task-output-type-cs
Title: "ICR Task Output Type"
Description: "The standard axes of what a campaign visit produced — the coded vocabulary of Task.output.type (task-outputs round). Parameters of the work (delivery strategy, task origin) stay Task extensions; RESULTS of executing the visit are coded outputs. A new tally axis is a new code here, not a new extension. The house-to-house axes (houses-visited, eligible-present, eligible-absent, children-already-marked) have no meaning at a fixed post — strategy determines which outputs exist (icr-task-h2h-outputs)."
* ^caseSensitive = true
* ^experimental = false
* #treated-count "Persons treated / vaccinated (scalar tally)" "The visit's scalar result tally: persons treated or vaccinated."
* #houses-visited "Houses visited" "Number of houses visited — house-to-house tasks at area/team-day granularity."
* #eligible-present "Eligible persons present" "Number of eligible persons (per the protocol's target definition) present at the visit(s). Program-neutral."
* #eligible-absent "Eligible persons absent" "Number of eligible persons absent at the visit(s) — feeds same-day mop-up lists."
* #children-already-marked "Children already finger-marked" "Number of children found already finger-marked (already covered this round) on arrival — house-to-house campaigns."
* #missed-reason "Missed reason" "Why eligible person(s) were missed at this visit — person-level (absent, sleeping) and area-level (insecurity, shortage, access) causes."
* #noncompliance-reason "Refusal reason" "Why the household/caregiver refused the intervention (WHO IDHC 'intervention refusal') — drives social mobilization and mop-up targeting."
* #exclusion-reason "Exclusion reason" "Why a present, age-eligible person was clinically excluded this round (under dose-pole height/age, pregnant, breastfeeding, acutely ill)."
* #revisit-outcome "Revisit outcome" "Outcome of a person-targeted follow-up revisit: already-vaccinated | vaccinated-on-revisit | still-missing."
* #delivery-event "Delivery event reference" "Reference to an Immunization / MedicationAdministration / supply event captured inside the visit workflow."
* #coverage-report "Coverage report reference" "Reference to the stratified MeasureReport that disaggregates this visit's tally."

// --- cost-v1: campaign cost -----------------------------------------------------
// The cost axis the field-evidence review flagged (§13.2 "campaign-cost axes").
// Costs are line-item Observations (ICRCampaignCost) that point AT the round;
// unit costs (cost per person targeted / reached, per dose) are MeasureReports
// (ICRCostReport). Category vocabulary follows the Global Health Cost Consortium
// reference-case cost groupings and the recurring line structure of the GPEI SIA,
// Gavi operational-cost and ESPEN MDA budget templates.

CodeSystem: ICRCostCategoryCS
Id: icr-cost-category-cs
Title: "ICR Cost Category"
Description: "The cost category of a campaign cost line item — WHAT the money was budgeted for or spent on. Derived from the line structure shared by the GPEI SIA budget, the Gavi campaign operational-cost template and the ESPEN MDA budget, grouped per the Global Health Cost Consortium reference case. A country line that does not fit is a country code or text (extensible binding), never a new profile (cost-v1)."
* ^caseSensitive = true
* ^experimental = false
* #personnel "Personnel (salaried)" "Salaried staff time attributed to the campaign — programme officers, facility staff, drivers on payroll. Usually an economic-perspective line."
* #per-diem-incentive "Per diems & incentives" "Per diems, allowances and incentives paid to vaccinators, CDDs, volunteers, supervisors and mobilizers — the largest financial line in most campaigns."
* #training "Training" "Training of trainers, cascade trainings, venue, materials and participant allowances."
* #transport "Transport & fuel" "Vehicle hire, fuel, motorbikes, boats, vaccine/drug transport to and within the district."
* #cold-chain "Cold chain" "Ice packs, cold boxes, vaccine carriers, refrigerator fuel/power, cold-chain maintenance."
* #commodities "Commodities" "The delivered product itself — vaccine, drugs, ITNs, insecticide, vitamin A — including freight and insurance. Excluded from delivery-only cost scope."
* #consumables "Consumables & supplies" "Syringes, safety boxes, dose poles, finger markers, tally sheets, registers, printing."
* #social-mobilization "Social mobilization & communication" "Radio, town criers, community-leader engagement, IEC materials, mobile PA, SMS."
* #supervision-monitoring "Supervision & monitoring" "Supervisory visits, in-process monitoring (RCM), data collection and data management."
* #waste-management "Waste management" "Sharps and medical-waste collection, transport and disposal."
* #planning "Planning & microplanning" "Microplanning workshops, coordination meetings, mapping and enumeration."
* #post-campaign-survey "Post-campaign survey" "Independent coverage survey, LQAS or evaluation."
* #other "Other" "A cost line that fits no listed category — carry the detail in text."

CodeSystem: ICRCostLineageCS
Id: icr-cost-lineage-cs
Title: "ICR Cost Lineage"
Description: "Whether a cost figure is a BUDGET (planned, from the microplan) or an ACTUAL (expenditure). Separate from the realtime-vs-reconciled data-lineage axis, which applies to actuals (preliminary vs close-out) and rides Observation.status / the data-lineage extension (cost-v1)."
* ^caseSensitive = true
* ^experimental = false
* #budgeted "Budgeted" "A planned amount from the microplan budget."
* #actual "Actual" "Expenditure — what was actually spent."

CodeSystem: ICRCostPerspectiveCS
Id: icr-cost-perspective-cs
Title: "ICR Cost Perspective"
Description: "Financial vs economic costing perspective (Global Health Cost Consortium reference case). Financial = money actually disbursed for the campaign. Economic = financial plus the value of donated commodities, salaried staff time and other in-kind resources. Absent ⇒ financial (cost-v1)."
* ^caseSensitive = true
* ^experimental = false
* #financial "Financial" "Cash outlay only."
* #economic "Economic" "Full resource cost including in-kind and opportunity costs."

CodeSystem: ICRCostScopeCS
Id: icr-cost-scope-cs
Title: "ICR Cost Scope"
Description: "Which cost categories a cost report's figures include: FULL (all categories) or DELIVERY-ONLY (all categories except commodities — the standard published unit-cost metric, e.g. the Immunization Delivery Cost Catalogue's 'cost per dose delivered excluding vaccine') (cost-v1)."
* ^caseSensitive = true
* ^experimental = false
* #full "Full" "All cost categories, including commodities."
* #delivery-only "Delivery only" "All cost categories except commodities."

CodeSystem: ICRCostAllocationBasisCS
Id: icr-cost-allocation-basis-cs
Title: "ICR Cost Allocation Basis"
Description: "Whether a cost report at a geography counts only the line items attributed to that geography's subtree (DIRECT) or also apportions a share of higher-level lines — national vaccine, national training — to it (FULLY-LOADED). The ledger (ICRCampaignCost) is never allocated downward; allocation is a report-level statement (cost-v1)."
* ^caseSensitive = true
* ^experimental = false
* #direct "Direct" "Only line items whose subject is in the report geography's subtree."
* #fully-loaded "Fully loaded" "Direct lines plus an apportioned share of umbrella / higher-level lines — the allocation method is stated alongside."

CodeSystem: ICRFundingSourceCS
Id: icr-funding-source-cs
Title: "ICR Funding Source"
Description: "Who paid for a cost line item — the funding envelope, not the spending organization (which is Observation.performer). Extensible: named donors and country mechanisms are country codes (cost-v1)."
* ^caseSensitive = true
* ^experimental = false
* #government "Government" "Domestic government budget (national or sub-national)."
* #gavi "Gavi" "Gavi, the Vaccine Alliance (vaccine and/or operational-cost support)."
* #gpei "GPEI" "Global Polio Eradication Initiative."
* #unicef "UNICEF" "UNICEF core or programme funds."
* #who "WHO" "World Health Organization."
* #global-fund "Global Fund" "The Global Fund to Fight AIDS, Tuberculosis and Malaria (ITN/IRS campaigns)."
* #other-donor "Other donor" "Any other bilateral, multilateral, philanthropic or NGO funder — name it in text."
* #unknown "Unknown" "Funding source not recorded."

CodeSystem: ICRCostComponentCS
Id: icr-cost-component-cs
Title: "ICR Cost Component"
Description: "The coded components of a cost line item (ICRCampaignCost.component.code): the driver quantity, the unit cost (norm), and the USD-normalised amount. Fixed per component slice — no ValueSet (cost-v1)."
* ^caseSensitive = true
* ^experimental = false
* #units "Driver units" "The quantity that drives the line: person-days, vehicle-days, doses, km."
* #unit-cost "Unit cost" "The rate per driver unit (the norm) in the line's currency — units × unit-cost = the amount."
* #amount-usd "Amount (USD)" "The amount converted to US dollars for cross-country comparison."

CodeSystem: ICRCostFigureCS
Id: icr-cost-figure-cs
Title: "ICR Cost Figure"
Description: "The figures a cost report carries, one per MeasureReport.group: the total and the unit costs (per person targeted, per person reached, per dose/treatment delivered). Bound required on ICRCostReport.group.code so the figures are queryable by code (cost-v1)."
* ^caseSensitive = true
* ^experimental = false
* #total-cost "Total cost" "Sum of the in-scope line items for the report geography, lineage and perspective."
* #per-person-targeted "Cost per person targeted" "Total cost ÷ the planning denominator (the flagged ICRTargetPopulation for the geography)."
* #per-person-reached "Cost per person reached" "Total cost ÷ persons reached (the administrative-coverage numerator for the same round, geography and data lineage)."
* #per-dose-delivered "Cost per dose / treatment delivered" "Total cost ÷ doses or treatments delivered (Immunization / MedicationAdministration count, record-origin = campaign)."

// Spatial index schemes (spatial-index round, Sep 2026). A Location's point can carry
// the cell it falls in under one or more tiling schemes, so that de-duplication,
// tile-level joins (GRID3, Overture) and containment queries need no geometry engine.
CodeSystem: ICRSpatialIndexCS
Id: icr-spatial-index-cs
Title: "ICR Spatial Index Scheme"
Description: "The tiling scheme a spatial-index cell belongs to. Each scheme has its own notion of level: quadkey zoom (1–23; the cell string is the zoom-length base-4 tile key, so a prefix is the containing tile at a coarser zoom), H3 resolution (0–15; the cell is the 15-hex-character index), geohash precision (the character count)."
* ^caseSensitive = true
* ^experimental = false
* #quadkey "Quadkey (XYZ tile key)" "Bing/XYZ tile quadkey: base-4 digits, one per zoom level from 1; the string length is the zoom; every prefix is the containing tile at that shorter zoom."
* #h3 "H3 cell" "Uber H3 hexagonal cell index (15 hex characters); level = resolution 0–15. Not prefix-hierarchical as a string — join on exact cell."
* #geohash "Geohash" "Base-32 geohash; level = precision (character count); prefixes are containing cells."
