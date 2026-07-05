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

// --- Form 2: MDA Medicine Receipt (health facility receipt of medicines) ------
// Extraction: one ICRSupplyDelivery per answered per-drug total, template-based
// (item-level templateExtract on each of the 8 drug items).

Instance: espen-mda-drug-receipt
InstanceOf: Questionnaire
Title: "ESPEN MDA — 2. Medicine Receipt Form"
Usage: #example
* url = "https://fhir.icr.unicef.org/Questionnaire/espen-mda-drug-receipt"
* name = "EspenMDADrugReceipt"
* status = #active
* experimental = false
* description = "ESPEN MDA demo Form 2 (medicine receipt at health facility): disease and medicine-package scope, per-medicine received totals. Template-based extraction: one ICRSupplyDelivery per answered medicine total (espen-forms)."
* subjectType = #Location
// registry cascade: choices are deployment entity data (bind::db_*) — in ICR these
// resolve against the Location hierarchy / CareTeam registry at capture time
* item[+].linkId = "p_recorder_id"
* item[=].text = "Select the recorder ID"
* item[=].type = #string
* item[+].linkId = "p_state"
* item[=].text = "Select State / Region / Province"
* item[=].type = #string
* item[=].required = true
* item[+].linkId = "p_district"
* item[=].text = "Select District / LGA / County"
* item[=].type = #string
* item[=].required = true
* item[+].linkId = "p_health_facility"
* item[=].text = "Enter the Health facility / Sub district"
* item[=].type = #string
* item[=].required = true
* item[+].linkId = "p_disease"
* item[=].text = "Disease covered by the MDA"
* item[=].type = #choice
* item[=].repeats = true
* item[=].required = true
* item[=].answerValueSet = Canonical(ICRNTDDiseaseVS)
* item[+].linkId = "p_medicine"
* item[=].text = "Select the medicine package"
* item[=].type = #choice
* item[=].repeats = true
* item[=].required = true
* item[=].answerValueSet = Canonical(ICRMDAMedicinePackageVS)
// combination-validity constraint enforced at the capture layer; not carried over
* item[+].linkId = "p_total_pzq"
* item[=].text = "Total Praziquantel received"
* item[=].type = #integer
* item[=].required = true
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#pzq
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#pzq-alb
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#pzq-meb
* item[=].enableBehavior = #any
* item[=].extension[+].url = $SDCTemplateExtract
* item[=].extension[=].extension[+].url = "template"
* item[=].extension[=].extension[=].valueReference.reference = "#sd-receipt-pzq"
* item[+].linkId = "p_total_alb"
* item[=].text = "Total Albendazole received"
* item[=].type = #integer
* item[=].required = true
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#alb
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#ivm-alb
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#ivm-alb-dec
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#pzq-alb
* item[=].enableBehavior = #any
* item[=].extension[+].url = $SDCTemplateExtract
* item[=].extension[=].extension[+].url = "template"
* item[=].extension[=].extension[=].valueReference.reference = "#sd-receipt-alb"
* item[+].linkId = "p_total_meb"
* item[=].text = "Total Mebendazole received"
* item[=].type = #integer
* item[=].required = true
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#meb
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#pzq-meb
* item[=].enableBehavior = #any
* item[=].extension[+].url = $SDCTemplateExtract
* item[=].extension[=].extension[+].url = "template"
* item[=].extension[=].extension[=].valueReference.reference = "#sd-receipt-meb"
* item[+].linkId = "p_total_ivm"
* item[=].text = "Total Ivermectin received"
* item[=].type = #integer
* item[=].required = true
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#ivm
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#ivm-alb
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#ivm-alb-dec
* item[=].enableBehavior = #any
* item[=].extension[+].url = $SDCTemplateExtract
* item[=].extension[=].extension[+].url = "template"
* item[=].extension[=].extension[=].valueReference.reference = "#sd-receipt-ivm"
* item[+].linkId = "p_total_dec"
* item[=].text = "Total Diethylcarbamazine received"
* item[=].type = #integer
* item[=].required = true
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#ivm-alb-dec
* item[=].extension[+].url = $SDCTemplateExtract
* item[=].extension[=].extension[+].url = "template"
* item[=].extension[=].extension[=].valueReference.reference = "#sd-receipt-dec"
* item[+].linkId = "p_total_az_sus"
* item[=].text = "Total Azithromycin suspension (in l) received"
* item[=].type = #integer
* item[=].required = true
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#azm-susp
* item[=].extension[+].url = $SDCTemplateExtract
* item[=].extension[=].extension[+].url = "template"
* item[=].extension[=].extension[=].valueReference.reference = "#sd-receipt-azm-susp"
* item[+].linkId = "p_total_az_tab"
* item[=].text = "Total Azithromycin tablets received"
* item[=].type = #integer
* item[=].required = true
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#azm-tab
* item[=].extension[+].url = $SDCTemplateExtract
* item[=].extension[=].extension[+].url = "template"
* item[=].extension[=].extension[=].valueReference.reference = "#sd-receipt-azm-tab"
* item[+].linkId = "p_total_tetra"
* item[=].text = "Total Tetracycline received"
* item[=].type = #integer
* item[=].required = true
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#tetra
* item[=].extension[+].url = $SDCTemplateExtract
* item[=].extension[=].extension[+].url = "template"
* item[=].extension[=].extension[=].valueReference.reference = "#sd-receipt-tetra"
* item[+].linkId = "p_add_note"
* item[=].text = "Additional Note"
* item[=].type = #text
// dropped: p_start / p_end (device timestamps)
* contained[+] = EspenSDReceiptPzq
* contained[+] = EspenSDReceiptAlb
* contained[+] = EspenSDReceiptMeb
* contained[+] = EspenSDReceiptIvm
* contained[+] = EspenSDReceiptDec
* contained[+] = EspenSDReceiptAzmSusp
* contained[+] = EspenSDReceiptAzmTab
* contained[+] = EspenSDReceiptTetra

// -- extraction templates for Form 2 --

Instance: EspenSDReceiptPzq
InstanceOf: SupplyDelivery
Usage: #inline
* id = "sd-receipt-pzq"
* meta.profile = "https://fhir.icr.unicef.org/StructureDefinition/ICRSupplyDelivery"
* status = #completed
* extension[0].url = "https://fhir.icr.unicef.org/StructureDefinition/record-origin"
* extension[0].valueCode = #campaign
* suppliedItem.itemCodeableConcept = $ATC#P02BA01 "praziquantel"
* suppliedItem.quantity.system = "http://unitsofmeasure.org"
* suppliedItem.quantity.code = #{tbl}
* suppliedItem.quantity.unit = "tablets"
* suppliedItem.quantity.value.extension[+].url = $SDCTemplateExtractValue
* suppliedItem.quantity.value.extension[=].valueString = "%resource.repeat(item).where(linkId='p_total_pzq').answer.value.first()"
// destination: the receiving facility is a registry cascade string in the source
// form; deployments bind it via launchContext against the Location hierarchy

Instance: EspenSDReceiptAlb
InstanceOf: SupplyDelivery
Usage: #inline
* id = "sd-receipt-alb"
* meta.profile = "https://fhir.icr.unicef.org/StructureDefinition/ICRSupplyDelivery"
* status = #completed
* extension[0].url = "https://fhir.icr.unicef.org/StructureDefinition/record-origin"
* extension[0].valueCode = #campaign
* suppliedItem.itemCodeableConcept = $ATC#P02CA03 "albendazole"
* suppliedItem.quantity.system = "http://unitsofmeasure.org"
* suppliedItem.quantity.code = #{tbl}
* suppliedItem.quantity.unit = "tablets"
* suppliedItem.quantity.value.extension[+].url = $SDCTemplateExtractValue
* suppliedItem.quantity.value.extension[=].valueString = "%resource.repeat(item).where(linkId='p_total_alb').answer.value.first()"
// destination: the receiving facility is a registry cascade string in the source
// form; deployments bind it via launchContext against the Location hierarchy

Instance: EspenSDReceiptMeb
InstanceOf: SupplyDelivery
Usage: #inline
* id = "sd-receipt-meb"
* meta.profile = "https://fhir.icr.unicef.org/StructureDefinition/ICRSupplyDelivery"
* status = #completed
* extension[0].url = "https://fhir.icr.unicef.org/StructureDefinition/record-origin"
* extension[0].valueCode = #campaign
* suppliedItem.itemCodeableConcept = $ATC#P02CA01 "mebendazole"
* suppliedItem.quantity.system = "http://unitsofmeasure.org"
* suppliedItem.quantity.code = #{tbl}
* suppliedItem.quantity.unit = "tablets"
* suppliedItem.quantity.value.extension[+].url = $SDCTemplateExtractValue
* suppliedItem.quantity.value.extension[=].valueString = "%resource.repeat(item).where(linkId='p_total_meb').answer.value.first()"
// destination: the receiving facility is a registry cascade string in the source
// form; deployments bind it via launchContext against the Location hierarchy

Instance: EspenSDReceiptIvm
InstanceOf: SupplyDelivery
Usage: #inline
* id = "sd-receipt-ivm"
* meta.profile = "https://fhir.icr.unicef.org/StructureDefinition/ICRSupplyDelivery"
* status = #completed
* extension[0].url = "https://fhir.icr.unicef.org/StructureDefinition/record-origin"
* extension[0].valueCode = #campaign
* suppliedItem.itemCodeableConcept = $ATC#P02CF01 "ivermectin"
* suppliedItem.quantity.system = "http://unitsofmeasure.org"
* suppliedItem.quantity.code = #{tbl}
* suppliedItem.quantity.unit = "tablets"
* suppliedItem.quantity.value.extension[+].url = $SDCTemplateExtractValue
* suppliedItem.quantity.value.extension[=].valueString = "%resource.repeat(item).where(linkId='p_total_ivm').answer.value.first()"
// destination: the receiving facility is a registry cascade string in the source
// form; deployments bind it via launchContext against the Location hierarchy

Instance: EspenSDReceiptDec
InstanceOf: SupplyDelivery
Usage: #inline
* id = "sd-receipt-dec"
* meta.profile = "https://fhir.icr.unicef.org/StructureDefinition/ICRSupplyDelivery"
* status = #completed
* extension[0].url = "https://fhir.icr.unicef.org/StructureDefinition/record-origin"
* extension[0].valueCode = #campaign
* suppliedItem.itemCodeableConcept = $ATC#P02CB02 "diethylcarbamazine"
* suppliedItem.quantity.system = "http://unitsofmeasure.org"
* suppliedItem.quantity.code = #{tbl}
* suppliedItem.quantity.unit = "tablets"
* suppliedItem.quantity.value.extension[+].url = $SDCTemplateExtractValue
* suppliedItem.quantity.value.extension[=].valueString = "%resource.repeat(item).where(linkId='p_total_dec').answer.value.first()"
// destination: the receiving facility is a registry cascade string in the source
// form; deployments bind it via launchContext against the Location hierarchy

Instance: EspenSDReceiptAzmSusp
InstanceOf: SupplyDelivery
Usage: #inline
* id = "sd-receipt-azm-susp"
* meta.profile = "https://fhir.icr.unicef.org/StructureDefinition/ICRSupplyDelivery"
* status = #completed
* extension[0].url = "https://fhir.icr.unicef.org/StructureDefinition/record-origin"
* extension[0].valueCode = #campaign
* suppliedItem.itemCodeableConcept = $ATC#J01FA10 "azithromycin (suspension)"
* suppliedItem.quantity.system = "http://unitsofmeasure.org"
* suppliedItem.quantity.code = #L
* suppliedItem.quantity.unit = "liters"
* suppliedItem.quantity.value.extension[+].url = $SDCTemplateExtractValue
* suppliedItem.quantity.value.extension[=].valueString = "%resource.repeat(item).where(linkId='p_total_az_sus').answer.value.first()"
// destination: the receiving facility is a registry cascade string in the source
// form; deployments bind it via launchContext against the Location hierarchy

Instance: EspenSDReceiptAzmTab
InstanceOf: SupplyDelivery
Usage: #inline
* id = "sd-receipt-azm-tab"
* meta.profile = "https://fhir.icr.unicef.org/StructureDefinition/ICRSupplyDelivery"
* status = #completed
* extension[0].url = "https://fhir.icr.unicef.org/StructureDefinition/record-origin"
* extension[0].valueCode = #campaign
* suppliedItem.itemCodeableConcept = $ATC#J01FA10 "azithromycin (tablets)"
* suppliedItem.quantity.system = "http://unitsofmeasure.org"
* suppliedItem.quantity.code = #{tbl}
* suppliedItem.quantity.unit = "tablets"
* suppliedItem.quantity.value.extension[+].url = $SDCTemplateExtractValue
* suppliedItem.quantity.value.extension[=].valueString = "%resource.repeat(item).where(linkId='p_total_az_tab').answer.value.first()"
// destination: the receiving facility is a registry cascade string in the source
// form; deployments bind it via launchContext against the Location hierarchy

Instance: EspenSDReceiptTetra
InstanceOf: SupplyDelivery
Usage: #inline
* id = "sd-receipt-tetra"
* meta.profile = "https://fhir.icr.unicef.org/StructureDefinition/ICRSupplyDelivery"
* status = #completed
* extension[0].url = "https://fhir.icr.unicef.org/StructureDefinition/record-origin"
* extension[0].valueCode = #campaign
* suppliedItem.itemCodeableConcept = $ATC#S01AA09 "tetracycline (eye ointment)"
* suppliedItem.quantity.system = "http://unitsofmeasure.org"
* suppliedItem.quantity.code = #{tube}
* suppliedItem.quantity.unit = "tubes"
* suppliedItem.quantity.value.extension[+].url = $SDCTemplateExtractValue
* suppliedItem.quantity.value.extension[=].valueString = "%resource.repeat(item).where(linkId='p_total_tetra').answer.value.first()"
// destination: the receiving facility is a registry cascade string in the source
// form; deployments bind it via launchContext against the Location hierarchy
