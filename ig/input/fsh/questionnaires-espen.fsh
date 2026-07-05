// ESPEN MDA demo instruments (espen-forms) — the six ESPEN MDA XLSForms
// (forms/espen mda/) converted to FHIR Questionnaires with SDC template-based
// extraction into ICR-profiled resources. These are complete, source-faithful
// EXAMPLE instruments (Usage: #example) demonstrating how a country programme's
// forms plug into the ICR: the canonical condensed checklists in
// questionnaires.fsh remain the IG's normative instruments.
// Source-of-truth dump: docs/superpowers/plans/2026-07-05-espen-forms-reference.md
// Conversion conventions: linkId = XLSForm name verbatim; registry cascades
// (state/district/facility/village) → string items resolved against the Location
// hierarchy at capture time; select_one yes_no → boolean; calculates → hidden
// items with SDC calculatedExpression; device metadata (start/end) dropped.

// --- Form 1: MDA Location (village registration & census) ----------------------
// Extraction: ICRLocation (the village) + ICRTargetPopulation Groups (total,
// eligible, and age-band denominators), cross-linked via extractAllocateId.

Instance: espen-mda-location-registration
InstanceOf: Questionnaire
Title: "ESPEN MDA — 1. Location Registration Form"
Usage: #example
* url = "https://fhir.icr.unicef.org/Questionnaire/espen-mda-location-registration"
* name = "EspenMDALocationRegistration"
* status = #active
* experimental = false
* description = "ESPEN MDA demo Form 1 (village/location registration and census): admin cascade, population by age band, GPS. Template-based extraction: one ICRLocation for the village and ICRTargetPopulation Groups for the total, eligible, and age-band denominators (espen-forms)."
* subjectType = #Location
// allocate the extracted Location's id so the Group templates can reference it
* extension[+].url = $SDCExtractAllocateId
* extension[=].valueString = "newLocationId"
* extension[+].url = $SDCTemplateExtract
* extension[=].extension[+].url = "template"
* extension[=].extension[=].valueReference.reference = "#loc-template"
* extension[=].extension[+].url = "fullUrl"
* extension[=].extension[=].valueString = "%newLocationId"
* extension[+].url = $SDCTemplateExtract
* extension[=].extension[+].url = "template"
* extension[=].extension[=].valueReference.reference = "#pop-total-template"
* extension[+].url = $SDCTemplateExtract
* extension[=].extension[+].url = "template"
* extension[=].extension[=].valueReference.reference = "#pop-eligible-template"
* extension[+].url = $SDCTemplateExtract
* extension[=].extension[+].url = "template"
* extension[=].extension[=].valueReference.reference = "#pop-1-4-template"
* extension[+].url = $SDCTemplateExtract
* extension[=].extension[+].url = "template"
* extension[=].extension[=].valueReference.reference = "#pop-5-14-template"
* extension[+].url = $SDCTemplateExtract
* extension[=].extension[+].url = "template"
* extension[=].extension[=].valueReference.reference = "#pop-15-plus-template"
// registry cascade: choices are deployment entity data (bind::db_*) — in ICR these
// resolve against the Location hierarchy / CareTeam registry at capture time
* item[+].linkId = "l_recorder_id"
* item[=].text = "Select the recorder ID"
* item[=].type = #string
* item[+].linkId = "l_state"
* item[=].text = "Select State / Region / Province"
* item[=].type = #string
* item[=].required = true
* item[+].linkId = "l_district"
* item[=].text = "Select District / LGA / County"
* item[=].type = #string
* item[=].required = true
* item[+].linkId = "l_health_facility"
* item[=].text = "Enter the Health facility / Sub district"
* item[=].type = #string
* item[=].required = true
* item[+].linkId = "l_location"
* item[=].text = "Enter the village / location / site"
* item[=].type = #string
* item[=].required = true
* item[+].linkId = "l_location_id"
* item[=].text = "Enter the ID of village / location / site"
* item[=].type = #string
* item[=].required = true
* item[+].linkId = "l_total_pop"
* item[=].text = "Enter the total population of the village"
* item[=].type = #integer
* item[=].required = true
* item[+].linkId = "I_total_popn_1_4"
* item[=].text = "Total number of people aged 1-4 years of the village"
* item[=].type = #integer
* item[=].required = true
* item[+].linkId = "I_total_popn_5_14"
* item[=].text = "Total number of people aged 5-14 years of the Village"
* item[=].type = #integer
* item[=].required = true
* item[+].linkId = "I_total_popn_15_More"
* item[=].text = "Total number of people aged 15 years and above in the village"
* item[=].type = #integer
* item[=].required = true
* item[+].linkId = "l_eligible_pop"
* item[=].text = "Total eligible population of the village"
* item[=].type = #integer
* item[=].readOnly = true
* item[=].extension[+].url = $QHidden
* item[=].extension[=].valueBoolean = true
* item[=].extension[+].url = $SDCCalculatedExpression
* item[=].extension[=].valueExpression.language = #text/fhirpath
* item[=].extension[=].valueExpression.expression = "iif(%resource.repeat(item).where(linkId='I_total_popn_1_4').answer.exists(), %resource.repeat(item).where(linkId='I_total_popn_1_4').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='I_total_popn_5_14').answer.exists(), %resource.repeat(item).where(linkId='I_total_popn_5_14').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='I_total_popn_15_More').answer.exists(), %resource.repeat(item).where(linkId='I_total_popn_15_More').answer.value.first(), 0)"
// geopoint → lat/lng decimal pair (FHIR has no geopoint item type; extraction
// needs the parts)
* item[+].linkId = "l_gps"
* item[=].text = "GPS of the village"
* item[=].type = #group
* item[=].item[+].linkId = "l_gps_lat"
* item[=].item[=].text = "Latitude"
* item[=].item[=].type = #decimal
* item[=].item[+].linkId = "l_gps_lng"
* item[=].item[=].text = "Longitude"
* item[=].item[=].type = #decimal
* item[+].linkId = "l_submitting_report"
* item[=].text = "Enter name of person submitting report"
* item[=].type = #string
* item[=].required = true
* item[+].linkId = "l_additional_note"
* item[=].text = "Any other information"
* item[=].type = #text
// dropped: l_start / l_end (device timestamps)
* contained[+] = EspenLocTemplate
* contained[+] = EspenPopTotalTemplate
* contained[+] = EspenPopEligibleTemplate
* contained[+] = EspenPop14Template
* contained[+] = EspenPop514Template
* contained[+] = EspenPop15PlusTemplate

// -- extraction templates for Form 1 --

Instance: EspenLocTemplate
InstanceOf: Location
Usage: #inline
* id = "loc-template"
* meta.profile = "https://fhir.icr.unicef.org/StructureDefinition/ICRLocation"
* status = #active
* name.extension[+].url = $SDCTemplateExtractValue
* name.extension[=].valueString = "%resource.repeat(item).where(linkId='l_location').answer.value.first()"
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#area "Area"
* position.latitude.extension[+].url = $SDCTemplateExtractValue
* position.latitude.extension[=].valueString = "%resource.repeat(item).where(linkId='l_gps_lat').answer.value.first()"
* position.longitude.extension[+].url = $SDCTemplateExtractValue
* position.longitude.extension[=].valueString = "%resource.repeat(item).where(linkId='l_gps_lng').answer.value.first()"
* identifier[0].system = "https://fhir.icr.unicef.org/identifier/espen-location-id"
* identifier[0].value.extension[+].url = $SDCTemplateExtractValue
* identifier[0].value.extension[=].valueString = "%resource.repeat(item).where(linkId='l_location_id').answer.value.first()"

Instance: EspenPopTotalTemplate
InstanceOf: Group
Usage: #inline
* id = "pop-total-template"
* meta.profile = "https://fhir.icr.unicef.org/StructureDefinition/ICRTargetPopulation"
* type = #person
* actual = false
* name = "Total population (village census, ESPEN Form 1)"
* extension[0].url = "https://fhir.icr.unicef.org/StructureDefinition/denominator-source"
* extension[0].valueCodeableConcept = $DenominatorSource#microcensus "Microcensus / enumeration"
* extension[1].url = "https://fhir.icr.unicef.org/StructureDefinition/estimate-date"
* extension[1].valueDate = "2026-01-01"
* extension[1].valueDate.extension[+].url = $SDCTemplateExtractValue
* extension[1].valueDate.extension[=].valueString = "%resource.authored.toString().substring(0,10)"
* quantity = 0
* quantity.extension[+].url = $SDCTemplateExtractValue
* quantity.extension[=].valueString = "%resource.repeat(item).where(linkId='l_total_pop').answer.value.first()"
* characteristic[0].code = $GroupCharacteristic#geography "Geography"
* characteristic[0].valueReference.reference.extension[+].url = $SDCTemplateExtractValue
* characteristic[0].valueReference.reference.extension[=].valueString = "%newLocationId"
* characteristic[0].exclude = false

Instance: EspenPopEligibleTemplate
InstanceOf: Group
Usage: #inline
* id = "pop-eligible-template"
* meta.profile = "https://fhir.icr.unicef.org/StructureDefinition/ICRTargetPopulation"
* type = #person
* actual = false
* name = "Eligible population (village census, ESPEN Form 1)"
* extension[0].url = "https://fhir.icr.unicef.org/StructureDefinition/denominator-source"
* extension[0].valueCodeableConcept = $DenominatorSource#microcensus "Microcensus / enumeration"
* extension[1].url = "https://fhir.icr.unicef.org/StructureDefinition/estimate-date"
* extension[1].valueDate = "2026-01-01"
* extension[1].valueDate.extension[+].url = $SDCTemplateExtractValue
* extension[1].valueDate.extension[=].valueString = "%resource.authored.toString().substring(0,10)"
* quantity = 0
* quantity.extension[+].url = $SDCTemplateExtractValue
* quantity.extension[=].valueString = "%resource.repeat(item).where(linkId='l_eligible_pop').answer.value.first()"
* characteristic[0].code = $GroupCharacteristic#geography "Geography"
* characteristic[0].valueReference.reference.extension[+].url = $SDCTemplateExtractValue
* characteristic[0].valueReference.reference.extension[=].valueString = "%newLocationId"
* characteristic[0].exclude = false

Instance: EspenPop14Template
InstanceOf: Group
Usage: #inline
* id = "pop-1-4-template"
* meta.profile = "https://fhir.icr.unicef.org/StructureDefinition/ICRTargetPopulation"
* type = #person
* actual = false
* name = "Population aged 1-4 (village census, ESPEN Form 1)"
* extension[0].url = "https://fhir.icr.unicef.org/StructureDefinition/denominator-source"
* extension[0].valueCodeableConcept = $DenominatorSource#microcensus "Microcensus / enumeration"
* extension[1].url = "https://fhir.icr.unicef.org/StructureDefinition/estimate-date"
* extension[1].valueDate = "2026-01-01"
* extension[1].valueDate.extension[+].url = $SDCTemplateExtractValue
* extension[1].valueDate.extension[=].valueString = "%resource.authored.toString().substring(0,10)"
* quantity = 0
* quantity.extension[+].url = $SDCTemplateExtractValue
* quantity.extension[=].valueString = "%resource.repeat(item).where(linkId='I_total_popn_1_4').answer.value.first()"
* characteristic[0].code = $GroupCharacteristic#geography "Geography"
* characteristic[0].valueReference.reference.extension[+].url = $SDCTemplateExtractValue
* characteristic[0].valueReference.reference.extension[=].valueString = "%newLocationId"
* characteristic[0].exclude = false
* characteristic[1].code = $GroupCharacteristic#age-band "Age band"
* characteristic[1].valueCodeableConcept.text = "1-4 years"
* characteristic[1].exclude = false

Instance: EspenPop514Template
InstanceOf: Group
Usage: #inline
* id = "pop-5-14-template"
* meta.profile = "https://fhir.icr.unicef.org/StructureDefinition/ICRTargetPopulation"
* type = #person
* actual = false
* name = "Population aged 5-14 (village census, ESPEN Form 1)"
* extension[0].url = "https://fhir.icr.unicef.org/StructureDefinition/denominator-source"
* extension[0].valueCodeableConcept = $DenominatorSource#microcensus "Microcensus / enumeration"
* extension[1].url = "https://fhir.icr.unicef.org/StructureDefinition/estimate-date"
* extension[1].valueDate = "2026-01-01"
* extension[1].valueDate.extension[+].url = $SDCTemplateExtractValue
* extension[1].valueDate.extension[=].valueString = "%resource.authored.toString().substring(0,10)"
* quantity = 0
* quantity.extension[+].url = $SDCTemplateExtractValue
* quantity.extension[=].valueString = "%resource.repeat(item).where(linkId='I_total_popn_5_14').answer.value.first()"
* characteristic[0].code = $GroupCharacteristic#geography "Geography"
* characteristic[0].valueReference.reference.extension[+].url = $SDCTemplateExtractValue
* characteristic[0].valueReference.reference.extension[=].valueString = "%newLocationId"
* characteristic[0].exclude = false
* characteristic[1].code = $GroupCharacteristic#age-band "Age band"
* characteristic[1].valueCodeableConcept.text = "5-14 years"
* characteristic[1].exclude = false

Instance: EspenPop15PlusTemplate
InstanceOf: Group
Usage: #inline
* id = "pop-15-plus-template"
* meta.profile = "https://fhir.icr.unicef.org/StructureDefinition/ICRTargetPopulation"
* type = #person
* actual = false
* name = "Population aged 15+ (village census, ESPEN Form 1)"
* extension[0].url = "https://fhir.icr.unicef.org/StructureDefinition/denominator-source"
* extension[0].valueCodeableConcept = $DenominatorSource#microcensus "Microcensus / enumeration"
* extension[1].url = "https://fhir.icr.unicef.org/StructureDefinition/estimate-date"
* extension[1].valueDate = "2026-01-01"
* extension[1].valueDate.extension[+].url = $SDCTemplateExtractValue
* extension[1].valueDate.extension[=].valueString = "%resource.authored.toString().substring(0,10)"
* quantity = 0
* quantity.extension[+].url = $SDCTemplateExtractValue
* quantity.extension[=].valueString = "%resource.repeat(item).where(linkId='I_total_popn_15_More').answer.value.first()"
* characteristic[0].code = $GroupCharacteristic#geography "Geography"
* characteristic[0].valueReference.reference.extension[+].url = $SDCTemplateExtractValue
* characteristic[0].valueReference.reference.extension[=].valueString = "%newLocationId"
* characteristic[0].exclude = false
* characteristic[1].code = $GroupCharacteristic#age-band "Age band"
* characteristic[1].valueCodeableConcept.text = "15+ years"
* characteristic[1].exclude = false
