// Supervision checklist (working doc §17.3; espen-v4 round).
// The structured questionnaire behind ICRSupervisionReport — a coded, grouped
// version of the ESPEN supervision forms (Form 5 health-facility, Form 6 CDD
// observation). Representative items, not the full instrument; countries extend.

Instance: icr-mda-supervision-checklist
InstanceOf: Questionnaire
Title: "ICR MDA Supervision Checklist"
Usage: #definition
* url = "https://icr.healthcampaigns.org/Questionnaire/icr-mda-supervision-checklist"
* status = #active
* experimental = false
* name = "ICRMDASupervisionChecklist"
* description = "Structured supervision checklist for community-directed MDA (ESPEN Forms 5 & 6), grouped: supplies, CDD observation, stock & wastage, social mobilization."
* subjectType = #Group
* subjectType[+] = #Location
// --- Supplies available (Form 6) ---
* item[0].linkId = "supplies"
* item[0].text = "MDA supplies available"
* item[0].type = #group
* item[0].item[0].linkId = "supplies.height-chart"
* item[0].item[0].text = "Height chart / dose pole present"
* item[0].item[0].type = #boolean
* item[0].item[1].linkId = "supplies.register"
* item[0].item[1].text = "Register present"
* item[0].item[1].type = #boolean
* item[0].item[2].linkId = "supplies.checklist"
* item[0].item[2].text = "Records/checklist present"
* item[0].item[2].type = #boolean
// --- CDD observation (Form 6) ---
* item[1].linkId = "cdd-observation"
* item[1].text = "CDD observation"
* item[1].type = #group
* item[1].item[0].linkId = "cdd.doc"
* item[1].item[0].text = "Medicine taken in the presence of the distributor (DOC)"
* item[1].item[0].type = #boolean
* item[1].item[1].linkId = "cdd.height-chart-used"
* item[1].item[1].text = "Height chart used correctly"
* item[1].item[1].type = #boolean
* item[1].item[2].linkId = "cdd.ineligibles"
* item[1].item[2].text = "Ineligible individuals correctly identified"
* item[1].item[2].type = #boolean
* item[1].item[3].linkId = "cdd.side-effect-procedure"
* item[1].item[3].text = "Procedure for adverse events is known"
* item[1].item[3].type = #boolean
// --- Stock & wastage (Form 5) ---
* item[2].linkId = "stock"
* item[2].text = "Stock & wastage"
* item[2].type = #group
* item[2].item[0].linkId = "stock.remaining"
* item[2].item[0].text = "Remaining stock present"
* item[2].item[0].type = #boolean
* item[2].item[1].linkId = "stock.expired"
* item[2].item[1].text = "Any expired medicines"
* item[2].item[1].type = #boolean
* item[2].item[2].linkId = "stock.concordant"
* item[2].item[2].text = "Physical stock matches theoretical stock"
* item[2].item[2].type = #boolean
// --- Social mobilization (Form 5) ---
* item[3].linkId = "mobilization"
* item[3].text = "Social mobilization"
* item[3].type = #group
* item[3].item[0].linkId = "mob.informed"
* item[3].item[0].text = "Population informed before the campaign"
* item[3].item[0].type = #boolean

// --- v0.21.0 (forms-v1): pre-campaign readiness checklist ----------------------
// The pre-campaign / campaign-phase readiness instrument (UNICEF "Preparedness
// Validation" form), structurally the readiness sibling of the supervision
// checklist above but scoped to the pre-execution phase. Grouped: microplan,
// cold chain & logistics, social mobilization, trainings. Answered as a
// QuestionnaireResponse; rolled up by the icr-campaign-readiness Measure. (Whether
// to mint a dedicated ICRReadinessReport profile vs reuse the QuestionnaireResponse
// pattern is an open design decision — see jul3-form-analysis §Aggregate #2.)

Instance: icr-campaign-readiness-checklist
InstanceOf: Questionnaire
Title: "ICR Campaign Readiness Checklist"
Usage: #definition
* url = "https://icr.healthcampaigns.org/Questionnaire/icr-campaign-readiness-checklist"
* status = #active
* experimental = false
* name = "ICRCampaignReadinessChecklist"
* description = "Structured pre-campaign readiness/preparedness validation at operational level (UNICEF Preparedness Validation form), grouped: microplan, cold chain & logistics, social mobilization, trainings. Representative items, not the full instrument; countries extend (forms-v1)."
* subjectType = #Location
// --- Microplan ---
* item[0].linkId = "microplan"
* item[0].text = "Microplan"
* item[0].type = #group
* item[0].item[0].linkId = "microplan.available"
* item[0].item[0].text = "Microplan document available"
* item[0].item[0].type = #boolean
* item[0].item[1].linkId = "microplan.htra"
* item[0].item[1].text = "Hard-to-reach areas / special populations addressed with strategies"
* item[0].item[1].type = #boolean
* item[0].item[2].linkId = "microplan.maps"
* item[0].item[2].text = "Appropriate sketch maps present"
* item[0].item[2].type = #boolean
* item[0].item[3].linkId = "microplan.budget"
* item[0].item[3].text = "Budget / cost included"
* item[0].item[3].type = #boolean
* item[0].item[4].linkId = "microplan.tally-on-time"
* item[0].item[4].text = "Tally sheets arrived on time"
* item[0].item[4].type = #boolean
* item[0].item[5].linkId = "microplan.funds-on-time"
* item[0].item[5].text = "Funds arrived on time"
* item[0].item[5].type = #boolean
// --- Cold chain & logistics ---
* item[1].linkId = "cold-chain"
* item[1].text = "Cold chain & logistics"
* item[1].type = #group
* item[1].item[0].linkId = "cc.temperature"
* item[1].item[0].text = "Refrigerator temperature maintained +2 to +8 C"
* item[1].item[0].type = #boolean
* item[1].item[1].linkId = "cc.vvm-discard"
* item[1].item[1].text = "Any vials at VVM discard point (stage 3 or 4)"
* item[1].item[1].type = #boolean
* item[1].item[2].linkId = "cc.supplies-on-time"
* item[1].item[2].text = "Supplies arrived on time"
* item[1].item[2].type = #boolean
* item[1].item[3].linkId = "cc.vaccine-adequate"
* item[1].item[3].text = "Adequate vaccine & droppers"
* item[1].item[3].type = #boolean
* item[1].item[4].linkId = "cc.transport"
* item[1].item[4].text = "Adequate transport arrangements"
* item[1].item[4].type = #boolean
// --- Social mobilization ---
* item[2].linkId = "social-mobilization"
* item[2].text = "Social mobilization"
* item[2].type = #group
* item[2].item[0].linkId = "sm.committee"
* item[2].item[0].text = "Functional social-mobilization committee"
* item[2].item[0].type = #boolean
* item[2].item[1].linkId = "sm.announcements"
* item[2].item[1].text = "Campaign announcements started"
* item[2].item[1].type = #boolean
* item[2].item[2].linkId = "sm.stakeholders"
* item[2].item[2].text = "Key stakeholders informed"
* item[2].item[2].type = #boolean
// --- Trainings ---
* item[3].linkId = "trainings"
* item[3].text = "Trainings"
* item[3].type = #group
* item[3].item[0].linkId = "tr.teams-trained"
* item[3].item[0].text = "Supervisors and teams trained"
* item[3].item[0].type = #boolean
* item[3].item[1].linkId = "tr.small-groups"
* item[3].item[1].text = "Trainings conducted in small groups (<= 30)"
* item[3].item[1].type = #boolean
* item[3].item[2].linkId = "tr.agenda-complete"
* item[3].item[2].text = "Agenda covers rationale, cold chain/VVM, marking, recording, IEC, AFP"
* item[3].item[2].type = #boolean
