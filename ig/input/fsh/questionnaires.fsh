// Supervision checklist (working doc §17.3; espen-v4 round).
// The structured questionnaire behind ICRSupervisionReport — a coded, grouped
// version of the ESPEN supervision forms (Form 5 health-facility, Form 6 CDD
// observation). Representative items, not the full instrument; countries extend.

Instance: icr-mda-supervision-checklist
InstanceOf: Questionnaire
Title: "ICR MDA Supervision Checklist"
Usage: #definition
* url = "https://fhir.icr.unicef.org/Questionnaire/icr-mda-supervision-checklist"
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
