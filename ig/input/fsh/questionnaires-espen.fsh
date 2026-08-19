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
* url = "https://icr.healthcampaigns.org/Questionnaire/espen-mda-location-registration"
* meta.tag = $ProjectTag#espen "ESPEN"
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
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRLocation"
* status = #active
* name.extension[+].url = $SDCTemplateExtractValue
* name.extension[=].valueString = "%resource.repeat(item).where(linkId='l_location').answer.value.first()"
* physicalType.coding = http://terminology.hl7.org/CodeSystem/location-physical-type#area "Area"
* position.latitude.extension[+].url = $SDCTemplateExtractValue
* position.latitude.extension[=].valueString = "%resource.repeat(item).where(linkId='l_gps_lat').answer.value.first()"
* position.longitude.extension[+].url = $SDCTemplateExtractValue
* position.longitude.extension[=].valueString = "%resource.repeat(item).where(linkId='l_gps_lng').answer.value.first()"
* identifier[0].system = "https://icr.healthcampaigns.org/identifier/espen-location-id"
* identifier[0].value.extension[+].url = $SDCTemplateExtractValue
* identifier[0].value.extension[=].valueString = "%resource.repeat(item).where(linkId='l_location_id').answer.value.first()"

Instance: EspenPopTotalTemplate
InstanceOf: Group
Usage: #inline
* id = "pop-total-template"
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRTargetPopulation"
* type = #person
* actual = false
* name = "Total population (village census, ESPEN Form 1)"
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/denominator-source"
* extension[0].valueCodeableConcept = $DenominatorSource#microcensus "Microcensus / enumeration"
* extension[1].url = "https://icr.healthcampaigns.org/StructureDefinition/estimate-date"
* extension[1].valueDate = "2026-01-01"
* extension[1].valueDate.extension[+].url = $SDCTemplateExtractValue
* extension[1].valueDate.extension[=].valueString = "%resource.authored.toString().substring(0,10)"
* quantity = 0
* quantity.extension[+].url = $SDCTemplateExtractValue
* quantity.extension[=].valueString = "%resource.repeat(item).where(linkId='l_total_pop').answer.value.first()"
* characteristic[0].code = $GroupCharacteristic#geography "Geographic scope"
* characteristic[0].valueReference.reference.extension[+].url = $SDCTemplateExtractValue
* characteristic[0].valueReference.reference.extension[=].valueString = "%newLocationId"
* characteristic[0].exclude = false

Instance: EspenPopEligibleTemplate
InstanceOf: Group
Usage: #inline
* id = "pop-eligible-template"
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRTargetPopulation"
* type = #person
* actual = false
* name = "Eligible population (village census, ESPEN Form 1)"
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/denominator-source"
* extension[0].valueCodeableConcept = $DenominatorSource#microcensus "Microcensus / enumeration"
* extension[1].url = "https://icr.healthcampaigns.org/StructureDefinition/estimate-date"
* extension[1].valueDate = "2026-01-01"
* extension[1].valueDate.extension[+].url = $SDCTemplateExtractValue
* extension[1].valueDate.extension[=].valueString = "%resource.authored.toString().substring(0,10)"
* quantity = 0
* quantity.extension[+].url = $SDCTemplateExtractValue
* quantity.extension[=].valueString = "%resource.repeat(item).where(linkId='l_eligible_pop').answer.value.first()"
* characteristic[0].code = $GroupCharacteristic#geography "Geographic scope"
* characteristic[0].valueReference.reference.extension[+].url = $SDCTemplateExtractValue
* characteristic[0].valueReference.reference.extension[=].valueString = "%newLocationId"
* characteristic[0].exclude = false

Instance: EspenPop14Template
InstanceOf: Group
Usage: #inline
* id = "pop-1-4-template"
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRTargetPopulation"
* type = #person
* actual = false
* name = "Population aged 1-4 (village census, ESPEN Form 1)"
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/denominator-source"
* extension[0].valueCodeableConcept = $DenominatorSource#microcensus "Microcensus / enumeration"
* extension[1].url = "https://icr.healthcampaigns.org/StructureDefinition/estimate-date"
* extension[1].valueDate = "2026-01-01"
* extension[1].valueDate.extension[+].url = $SDCTemplateExtractValue
* extension[1].valueDate.extension[=].valueString = "%resource.authored.toString().substring(0,10)"
* quantity = 0
* quantity.extension[+].url = $SDCTemplateExtractValue
* quantity.extension[=].valueString = "%resource.repeat(item).where(linkId='I_total_popn_1_4').answer.value.first()"
* characteristic[0].code = $GroupCharacteristic#geography "Geographic scope"
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
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRTargetPopulation"
* type = #person
* actual = false
* name = "Population aged 5-14 (village census, ESPEN Form 1)"
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/denominator-source"
* extension[0].valueCodeableConcept = $DenominatorSource#microcensus "Microcensus / enumeration"
* extension[1].url = "https://icr.healthcampaigns.org/StructureDefinition/estimate-date"
* extension[1].valueDate = "2026-01-01"
* extension[1].valueDate.extension[+].url = $SDCTemplateExtractValue
* extension[1].valueDate.extension[=].valueString = "%resource.authored.toString().substring(0,10)"
* quantity = 0
* quantity.extension[+].url = $SDCTemplateExtractValue
* quantity.extension[=].valueString = "%resource.repeat(item).where(linkId='I_total_popn_5_14').answer.value.first()"
* characteristic[0].code = $GroupCharacteristic#geography "Geographic scope"
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
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRTargetPopulation"
* type = #person
* actual = false
* name = "Population aged 15+ (village census, ESPEN Form 1)"
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/denominator-source"
* extension[0].valueCodeableConcept = $DenominatorSource#microcensus "Microcensus / enumeration"
* extension[1].url = "https://icr.healthcampaigns.org/StructureDefinition/estimate-date"
* extension[1].valueDate = "2026-01-01"
* extension[1].valueDate.extension[+].url = $SDCTemplateExtractValue
* extension[1].valueDate.extension[=].valueString = "%resource.authored.toString().substring(0,10)"
* quantity = 0
* quantity.extension[+].url = $SDCTemplateExtractValue
* quantity.extension[=].valueString = "%resource.repeat(item).where(linkId='I_total_popn_15_More').answer.value.first()"
* characteristic[0].code = $GroupCharacteristic#geography "Geographic scope"
* characteristic[0].valueReference.reference.extension[+].url = $SDCTemplateExtractValue
* characteristic[0].valueReference.reference.extension[=].valueString = "%newLocationId"
* characteristic[0].exclude = false
* characteristic[1].code = $GroupCharacteristic#age-band "Age band"
* characteristic[1].valueCodeableConcept.text = "15+ years"
* characteristic[1].exclude = false

// --- Form 2: MDA Medicine Receipt (health facility receipt of medicines) ------
// Extraction: one ICRSupplyMovement (facility receipt) per answered per-drug total, template-based
// (item-level templateExtract on each of the 8 drug items).

Instance: espen-mda-drug-receipt
InstanceOf: Questionnaire
Title: "ESPEN MDA — 2. Medicine Receipt Form"
Usage: #example
* url = "https://icr.healthcampaigns.org/Questionnaire/espen-mda-drug-receipt"
* meta.tag = $ProjectTag#espen "ESPEN"
* name = "EspenMDADrugReceipt"
* status = #active
* experimental = false
* description = "ESPEN MDA demo Form 2 (medicine receipt at health facility): disease and medicine-package scope, per-medicine received totals. Template-based extraction: one ICRSupplyMovement (facility receipt) per answered medicine total (espen-forms)."
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
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRSupplyMovement"
* status = #completed
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/record-origin"
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
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRSupplyMovement"
* status = #completed
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/record-origin"
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
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRSupplyMovement"
* status = #completed
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/record-origin"
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
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRSupplyMovement"
* status = #completed
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/record-origin"
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
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRSupplyMovement"
* status = #completed
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/record-origin"
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
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRSupplyMovement"
* status = #completed
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/record-origin"
* extension[0].valueCode = #campaign
* suppliedItem.itemCodeableConcept = $ATC#J01FA10 "azithromycin"
* suppliedItem.itemCodeableConcept.text = "azithromycin (suspension)"
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
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRSupplyMovement"
* status = #completed
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/record-origin"
* extension[0].valueCode = #campaign
* suppliedItem.itemCodeableConcept = $ATC#J01FA10 "azithromycin"
* suppliedItem.itemCodeableConcept.text = "azithromycin (tablets)"
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
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRSupplyMovement"
* status = #completed
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/record-origin"
* extension[0].valueCode = #campaign
* suppliedItem.itemCodeableConcept = $ATC#S01AA09 "tetracycline"
* suppliedItem.itemCodeableConcept.text = "tetracycline (eye ointment)"
* suppliedItem.quantity.system = "http://unitsofmeasure.org"
* suppliedItem.quantity.code = #{tube}
* suppliedItem.quantity.unit = "tubes"
* suppliedItem.quantity.value.extension[+].url = $SDCTemplateExtractValue
* suppliedItem.quantity.value.extension[=].valueString = "%resource.repeat(item).where(linkId='p_total_tetra').answer.value.first()"
// destination: the receiving facility is a registry cascade string in the source
// form; deployments bind it via launchContext against the Location hierarchy

// --- Form 3: MDA Medicine Treatment (tally) -----------------------------------
// Extraction: one ICRDeliveryUnit community Group (root templateExtract, allocate-id),
// one Group-subject ICRMedicationAdministration per answered drug block (the treatment
// event — espen-remap), and one ICRAdministrativeCoverage MeasureReport per answered
// drug block (item-level templateExtract on each drug's `<blk>_by_sex` group),
// stratified by sex, age-band, and disposition — the same cube as
// example-mda-treatment-tally (espen-forms).

Instance: espen-mda-treatment
InstanceOf: Questionnaire
Title: "ESPEN MDA — 3. Medicine Treatment Form (tally)"
Usage: #example
* url = "https://icr.healthcampaigns.org/Questionnaire/espen-mda-treatment"
* meta.tag = $ProjectTag#espen "ESPEN"
* name = "EspenMDATreatment"
* status = #active
* experimental = false
* description = "ESPEN MDA demo Form 3 (the treatment tally): village census plus per-drug treated counts by sex and age band with reasons-not-treated. Template-based extraction: one ICRDeliveryUnit community Group for the village, one Group-subject ICRMedicationAdministration per answered drug block (the treatment event — tablets into people are treatment, not a supply transfer), and one ICRAdministrativeCoverage MeasureReport per answered drug block — measure icr-mda-treatment-coverage, stratified by sex, age-band, and disposition, the same cube as example-mda-treatment-tally (espen-forms, remapped espen-remap)."
* subjectType = #Location
// allocate the extracted community Group's id so the per-drug
// MedicationAdministration templates can reference it as their subject
* extension[+].url = $SDCExtractAllocateId
* extension[=].valueString = "newCommunityId"
* extension[+].url = $SDCTemplateExtract
* extension[=].extension[+].url = "template"
* extension[=].extension[=].valueReference.reference = "#community-template"
* extension[=].extension[+].url = "fullUrl"
* extension[=].extension[=].valueString = "%newCommunityId"
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
* item[=].text = "Select the Health facility / Sub district"
* item[=].type = #string
* item[=].required = true
* item[+].linkId = "p_location"
* item[=].text = "Enter the village / location / site"
* item[=].type = #string
* item[=].required = true
* item[+].linkId = "p_location_id"
* item[=].text = "Enter the ID of village / location / site"
* item[=].type = #string
* item[=].required = true
* item[+].linkId = "p_campaign_day"
* item[=].text = "Day of the campaign"
* item[=].type = #choice
* item[=].required = true
* item[=].answerOption[+].valueString = "Day 1"
* item[=].answerOption[+].valueString = "Day 2"
* item[=].answerOption[+].valueString = "Day 3"
* item[=].answerOption[+].valueString = "Day 4"
* item[=].answerOption[+].valueString = "Day 5"
* item[=].answerOption[+].valueString = "Day 6"
* item[=].answerOption[+].valueString = "Day 7"
* item[=].answerOption[+].valueString = "Day 8"
* item[=].answerOption[+].valueString = "Day 9"
* item[=].answerOption[+].valueString = "Day 10"
* item[+].linkId = "p_disease"
* item[=].text = "Disease covered by the TDM?"
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
// census: aggregate village census (household-level digitization or aggregate
// reporting), feeding the treatment-coverage denominator
* item[+].linkId = "census"
* item[=].text = "Population census"
* item[=].type = #group
* item[=].item[+].linkId = "census_method"
* item[=].item[=].text = "Cencus method"
* item[=].item[=].type = #choice
* item[=].item[=].required = true
* item[=].item[=].answerOption[+].valueString = "Household-Level Digitization"
* item[=].item[=].answerOption[+].valueString = "Aggregate Reporting"
* item[=].item[+].linkId = "census_house_hold"
* item[=].item[=].text = "Number of households"
* item[=].item[=].type = #integer
* item[=].item[+].linkId = "census_men"
* item[=].item[=].text = "Number of men"
* item[=].item[=].type = #integer
* item[=].item[+].linkId = "census_women"
* item[=].item[=].text = "Number of women"
* item[=].item[=].type = #integer
// DEC by_sex + reasons (standard block)
* item[+].linkId = "dec_by_sex"
* item[=].text = "DEC By sex"
* item[=].type = #group
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#ivm-alb-dec
* item[=].extension[+].url = $SDCTemplateExtract
* item[=].extension[=].extension[+].url = "template"
* item[=].extension[=].extension[=].valueReference.reference = "#mr-dec"
* item[=].extension[+].url = $SDCTemplateExtract
* item[=].extension[=].extension[+].url = "template"
* item[=].extension[=].extension[=].valueReference.reference = "#ma-dec"
* item[=].item[+].linkId = "dec_5_14_female_treated"
* item[=].item[=].text = "5-14 years old treated Female"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "dec_5_14_male_treated"
* item[=].item[=].text = "5-14 years old treated Male"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "dec_15_female_treated"
* item[=].item[=].text = "15 years and over treated Female"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "dec_15_male_treated"
* item[=].item[=].text = "15 years and over treated Male"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "dec_men_treated"
* item[=].item[=].text = "Men treated"
* item[=].item[=].type = #integer
* item[=].item[=].readOnly = true
* item[=].item[=].extension[+].url = $QHidden
* item[=].item[=].extension[=].valueBoolean = true
* item[=].item[=].extension[+].url = $SDCCalculatedExpression
* item[=].item[=].extension[=].valueExpression.language = #text/fhirpath
* item[=].item[=].extension[=].valueExpression.expression = "iif(%resource.repeat(item).where(linkId='dec_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='dec_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_15_male_treated').answer.value.first(), 0)"
* item[=].item[+].linkId = "dec_women_treated"
* item[=].item[=].text = "Women treated"
* item[=].item[=].type = #integer
* item[=].item[=].readOnly = true
* item[=].item[=].extension[+].url = $QHidden
* item[=].item[=].extension[=].valueBoolean = true
* item[=].item[=].extension[+].url = $SDCCalculatedExpression
* item[=].item[=].extension[=].valueExpression.language = #text/fhirpath
// source form has a copy-paste bug (sums 15_male into women); corrected here
* item[=].item[=].extension[=].valueExpression.expression = "iif(%resource.repeat(item).where(linkId='dec_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='dec_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_15_female_treated').answer.value.first(), 0)"
* item[+].linkId = "dec_reason_not_treated"
* item[=].text = "Reasons not treated with DEC"
* item[=].type = #group
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#ivm-alb-dec
* item[=].item[+].linkId = "dec_child"
* item[=].item[=].text = "Children <90 cm untreated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "dec_pregnant"
* item[=].item[=].text = "Pregnant women untreated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "dec_breastfeeding"
* item[=].item[=].text = "Breastfeeding women untreated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "dec_absent"
* item[=].item[=].text = "Absent"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "dec_refusal"
* item[=].item[=].text = "Refusal"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
// ALB by_sex + reasons (standard block)
* item[+].linkId = "alb_by_sex"
* item[=].text = "ALB By sex"
* item[=].type = #group
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#ivm-alb-dec
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#ivm-alb
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#alb
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#pzq-alb
* item[=].enableBehavior = #any
* item[=].extension[+].url = $SDCTemplateExtract
* item[=].extension[=].extension[+].url = "template"
* item[=].extension[=].extension[=].valueReference.reference = "#mr-alb"
* item[=].extension[+].url = $SDCTemplateExtract
* item[=].extension[=].extension[+].url = "template"
* item[=].extension[=].extension[=].valueReference.reference = "#ma-alb"
* item[=].item[+].linkId = "alb_5_14_female_treated"
* item[=].item[=].text = "5-14 years old treated Female"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "alb_5_14_male_treated"
* item[=].item[=].text = "5-14 years old treated Male"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "alb_15_female_treated"
* item[=].item[=].text = "15 years and over treated Female"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "alb_15_male_treated"
* item[=].item[=].text = "15 years and over treated Male"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "alb_men_treated"
* item[=].item[=].text = "Men treated"
* item[=].item[=].type = #integer
* item[=].item[=].readOnly = true
* item[=].item[=].extension[+].url = $QHidden
* item[=].item[=].extension[=].valueBoolean = true
* item[=].item[=].extension[+].url = $SDCCalculatedExpression
* item[=].item[=].extension[=].valueExpression.language = #text/fhirpath
* item[=].item[=].extension[=].valueExpression.expression = "iif(%resource.repeat(item).where(linkId='alb_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='alb_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='alb_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='alb_15_male_treated').answer.value.first(), 0)"
* item[=].item[+].linkId = "alb_women_treated"
* item[=].item[=].text = "Women treated"
* item[=].item[=].type = #integer
* item[=].item[=].readOnly = true
* item[=].item[=].extension[+].url = $QHidden
* item[=].item[=].extension[=].valueBoolean = true
* item[=].item[=].extension[+].url = $SDCCalculatedExpression
* item[=].item[=].extension[=].valueExpression.language = #text/fhirpath
// source form has a copy-paste bug (sums 15_male into women); corrected here
* item[=].item[=].extension[=].valueExpression.expression = "iif(%resource.repeat(item).where(linkId='alb_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='alb_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='alb_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='alb_15_female_treated').answer.value.first(), 0)"
* item[+].linkId = "alb_reason_not_treated"
* item[=].text = "Reasons not treated with ALB"
* item[=].type = #group
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#ivm-alb-dec
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#ivm-alb
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#alb
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#pzq-alb
* item[=].enableBehavior = #any
* item[=].item[+].linkId = "alb_child"
* item[=].item[=].text = "Children <90 cm untreated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "alb_pregnant"
* item[=].item[=].text = "Pregnant women untreated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "alb_breastfeeding"
* item[=].item[=].text = "Breastfeeding women untreated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "alb_absent"
* item[=].item[=].text = "Absent"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "alb_refusal"
* item[=].item[=].text = "Refusal"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
// MBD by_sex + reasons (standard block)
* item[+].linkId = "meb_by_sex"
* item[=].text = "MBD By sex"
* item[=].type = #group
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#pzq-meb
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#meb
* item[=].enableBehavior = #any
* item[=].extension[+].url = $SDCTemplateExtract
* item[=].extension[=].extension[+].url = "template"
* item[=].extension[=].extension[=].valueReference.reference = "#mr-meb"
* item[=].extension[+].url = $SDCTemplateExtract
* item[=].extension[=].extension[+].url = "template"
* item[=].extension[=].extension[=].valueReference.reference = "#ma-meb"
* item[=].item[+].linkId = "meb_5_14_female_treated"
* item[=].item[=].text = "5-14 years old treated Female"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "meb_5_14_male_treated"
* item[=].item[=].text = "5-14 years old treated Male"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "meb_15_female_treated"
* item[=].item[=].text = "15 years and over treated Female"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "meb_15_male_treated"
* item[=].item[=].text = "15 years and over treated Male"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "meb_men_treated"
* item[=].item[=].text = "Men treated"
* item[=].item[=].type = #integer
* item[=].item[=].readOnly = true
* item[=].item[=].extension[+].url = $QHidden
* item[=].item[=].extension[=].valueBoolean = true
* item[=].item[=].extension[+].url = $SDCCalculatedExpression
* item[=].item[=].extension[=].valueExpression.language = #text/fhirpath
* item[=].item[=].extension[=].valueExpression.expression = "iif(%resource.repeat(item).where(linkId='meb_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='meb_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='meb_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='meb_15_male_treated').answer.value.first(), 0)"
* item[=].item[+].linkId = "meb_women_treated"
* item[=].item[=].text = "Women treated"
* item[=].item[=].type = #integer
* item[=].item[=].readOnly = true
* item[=].item[=].extension[+].url = $QHidden
* item[=].item[=].extension[=].valueBoolean = true
* item[=].item[=].extension[+].url = $SDCCalculatedExpression
* item[=].item[=].extension[=].valueExpression.language = #text/fhirpath
// source form has a copy-paste bug (sums 15_male into women); corrected here
* item[=].item[=].extension[=].valueExpression.expression = "iif(%resource.repeat(item).where(linkId='meb_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='meb_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='meb_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='meb_15_female_treated').answer.value.first(), 0)"
* item[+].linkId = "meb_reason_not_treated"
* item[=].text = "Reasons not treated with MEB"
* item[=].type = #group
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#pzq-meb
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#meb
* item[=].enableBehavior = #any
* item[=].item[+].linkId = "meb_child"
* item[=].item[=].text = "Children <90 cm untreated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "meb_pregnant"
* item[=].item[=].text = "Pregnant women untreated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "meb_breastfeeding"
* item[=].item[=].text = "Breastfeeding women untreated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "meb_absent"
* item[=].item[=].text = "Absent"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "meb_refusal"
* item[=].item[=].text = "Refusal"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
// IVM by_sex + reasons (standard block)
* item[+].linkId = "ivm_by_sex"
* item[=].text = "IVM By sex"
* item[=].type = #group
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#ivm
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#ivm-alb-dec
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#ivm-alb
* item[=].enableBehavior = #any
* item[=].extension[+].url = $SDCTemplateExtract
* item[=].extension[=].extension[+].url = "template"
* item[=].extension[=].extension[=].valueReference.reference = "#mr-ivm"
* item[=].extension[+].url = $SDCTemplateExtract
* item[=].extension[=].extension[+].url = "template"
* item[=].extension[=].extension[=].valueReference.reference = "#ma-ivm"
* item[=].item[+].linkId = "ivm_5_14_female_treated"
* item[=].item[=].text = "5-14 years old treated Female"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "ivm_5_14_male_treated"
* item[=].item[=].text = "5-14 years old treated Male"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "ivm_15_female_treated"
* item[=].item[=].text = "15 years and over treated Female"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "ivm_15_male_treated"
* item[=].item[=].text = "15 years and over treated Male"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "ivm_men_treated"
* item[=].item[=].text = "Men treated"
* item[=].item[=].type = #integer
* item[=].item[=].readOnly = true
* item[=].item[=].extension[+].url = $QHidden
* item[=].item[=].extension[=].valueBoolean = true
* item[=].item[=].extension[+].url = $SDCCalculatedExpression
* item[=].item[=].extension[=].valueExpression.language = #text/fhirpath
* item[=].item[=].extension[=].valueExpression.expression = "iif(%resource.repeat(item).where(linkId='ivm_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='ivm_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='ivm_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='ivm_15_male_treated').answer.value.first(), 0)"
* item[=].item[+].linkId = "ivm_women_treated"
* item[=].item[=].text = "Women treated"
* item[=].item[=].type = #integer
* item[=].item[=].readOnly = true
* item[=].item[=].extension[+].url = $QHidden
* item[=].item[=].extension[=].valueBoolean = true
* item[=].item[=].extension[+].url = $SDCCalculatedExpression
* item[=].item[=].extension[=].valueExpression.language = #text/fhirpath
// source form has a copy-paste bug (sums 15_male into women); corrected here
* item[=].item[=].extension[=].valueExpression.expression = "iif(%resource.repeat(item).where(linkId='ivm_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='ivm_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='ivm_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='ivm_15_female_treated').answer.value.first(), 0)"
* item[+].linkId = "ivm_reason_not_treated"
* item[=].text = "Reasons not treated with IVM"
* item[=].type = #group
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#ivm
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#ivm-alb-dec
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#ivm-alb
* item[=].enableBehavior = #any
* item[=].item[+].linkId = "ivm_child"
* item[=].item[=].text = "Children <90 cm untreated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "ivm_pregnant"
* item[=].item[=].text = "Pregnant women untreated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "ivm_breastfeeding"
* item[=].item[=].text = "Breastfeeding women untreated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "ivm_absent"
* item[=].item[=].text = "Absent"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "ivm_refusal"
* item[=].item[=].text = "Refusal"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
// PZQ by_sex + reasons (standard block)
* item[+].linkId = "pzq_by_sex"
* item[=].text = "PZQ By sex"
* item[=].type = #group
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#pzq
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#pzq-alb
* item[=].enableBehavior = #any
* item[=].extension[+].url = $SDCTemplateExtract
* item[=].extension[=].extension[+].url = "template"
* item[=].extension[=].extension[=].valueReference.reference = "#mr-pzq"
* item[=].extension[+].url = $SDCTemplateExtract
* item[=].extension[=].extension[+].url = "template"
* item[=].extension[=].extension[=].valueReference.reference = "#ma-pzq"
* item[=].item[+].linkId = "pzq_5_14_female_treated"
* item[=].item[=].text = "5-14 years old treated Female"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "pzq_5_14_male_treated"
* item[=].item[=].text = "5-14 years old treated Male"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "pzq_15_female_treated"
* item[=].item[=].text = "15 years and over treated Female"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "pzq_15_male_treated"
* item[=].item[=].text = "15 years and over treated Male"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "pzq_men_treated"
* item[=].item[=].text = "Men treated"
* item[=].item[=].type = #integer
* item[=].item[=].readOnly = true
* item[=].item[=].extension[+].url = $QHidden
* item[=].item[=].extension[=].valueBoolean = true
* item[=].item[=].extension[+].url = $SDCCalculatedExpression
* item[=].item[=].extension[=].valueExpression.language = #text/fhirpath
* item[=].item[=].extension[=].valueExpression.expression = "iif(%resource.repeat(item).where(linkId='pzq_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='pzq_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='pzq_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='pzq_15_male_treated').answer.value.first(), 0)"
* item[=].item[+].linkId = "pzq_women_treated"
* item[=].item[=].text = "Women treated"
* item[=].item[=].type = #integer
* item[=].item[=].readOnly = true
* item[=].item[=].extension[+].url = $QHidden
* item[=].item[=].extension[=].valueBoolean = true
* item[=].item[=].extension[+].url = $SDCCalculatedExpression
* item[=].item[=].extension[=].valueExpression.language = #text/fhirpath
// source form has a copy-paste bug (sums 15_male into women); corrected here
* item[=].item[=].extension[=].valueExpression.expression = "iif(%resource.repeat(item).where(linkId='pzq_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='pzq_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='pzq_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='pzq_15_female_treated').answer.value.first(), 0)"
* item[+].linkId = "pzq_reason_not_treated"
* item[=].text = "Reasons not treated with PZQ"
* item[=].type = #group
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#pzq
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#pzq-alb
* item[=].enableBehavior = #any
* item[=].item[+].linkId = "pzq_child"
* item[=].item[=].text = "Children <90 cm untreated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "pzq_pregnant"
* item[=].item[=].text = "Pregnant women untreated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "pzq_breastfeeding"
* item[=].item[=].text = "Breastfeeding women untreated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "pzq_absent"
* item[=].item[=].text = "Absent"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "pzq_refusal"
* item[=].item[=].text = "Refusal"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
// AZM Suspension by_sex + reasons (non-standard block: 2 age-6mo-<7y items, no dec-style age split)
* item[+].linkId = "azm_susp_by_sex"
* item[=].text = "AZM Report Suspension by sex"
* item[=].type = #group
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#azm-susp
* item[=].extension[+].url = $SDCTemplateExtract
* item[=].extension[=].extension[+].url = "template"
* item[=].extension[=].extension[=].valueReference.reference = "#mr-azm-susp"
* item[=].extension[+].url = $SDCTemplateExtract
* item[=].extension[=].extension[+].url = "template"
* item[=].extension[=].extension[=].valueReference.reference = "#ma-azm-susp"
* item[=].item[+].linkId = "azm_susp_less7_boy_treated"
* item[=].item[=].text = "Boys from 6 months to less than 7 years treated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "azm_susp_less7_girl_treated"
* item[=].item[=].text = "Girls from 6 months to less than 7 years treated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[+].linkId = "azm_susp_reason_not_treated"
* item[=].text = "Reasons not treated with AZM Suspension"
* item[=].type = #group
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#azm-susp
* item[=].item[+].linkId = "azm_susp_child"
* item[=].item[=].text = "Children <90 cm untreated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "azm_susp_absent"
* item[=].item[=].text = "Absent"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "azm_susp_refusal"
* item[=].item[=].text = "Refusal"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
// AZM Tablet by_sex + reasons (non-standard block: azm_tb_child is an untreated
// count the source misplaces inside the by_sex group — kept in place here)
* item[+].linkId = "azm_tb_by_sex"
* item[=].text = "AZM Report Tablet by sex"
* item[=].type = #group
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#azm-tab
* item[=].extension[+].url = $SDCTemplateExtract
* item[=].extension[=].extension[+].url = "template"
* item[=].extension[=].extension[=].valueReference.reference = "#mr-azm-tb"
* item[=].extension[+].url = $SDCTemplateExtract
* item[=].extension[=].extension[+].url = "template"
* item[=].extension[=].extension[=].valueReference.reference = "#ma-azm-tb"
* item[=].item[+].linkId = "azm_tb_more7_boy_treated"
* item[=].item[=].text = "Boys more than 7 years treated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "azm_tb_more7_girl_treated"
* item[=].item[=].text = "Girls more than 7 years treated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "azm_tb_child"
* item[=].item[=].text = "Children <90 cm untreated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[+].linkId = "azm_tb_reason_not_treated"
* item[=].text = "Reasons not treated with AZM Tablet"
* item[=].type = #group
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#azm-tab
* item[=].item[+].linkId = "azm_tb_pregnant"
* item[=].item[=].text = "Pregnant women untreated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "azm_tb_breastfeeding"
* item[=].item[=].text = "Breastfeeding women untreated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "azm_tb_absent"
* item[=].item[=].text = "Absent"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "azm_tb_refusal"
* item[=].item[=].text = "Refusal"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
// tetra: pregnant women are a treated category in the source form (eye ointment is
// safe in pregnancy); counted in numerator and female stratum, outside the age-band axis
* item[+].linkId = "tetra_by_sex"
* item[=].text = "TETRA By sex"
* item[=].type = #group
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#tetra
* item[=].extension[+].url = $SDCTemplateExtract
* item[=].extension[=].extension[+].url = "template"
* item[=].extension[=].extension[=].valueReference.reference = "#mr-tetra"
* item[=].extension[+].url = $SDCTemplateExtract
* item[=].extension[=].extension[+].url = "template"
* item[=].extension[=].extension[=].valueReference.reference = "#ma-tetra"
* item[=].item[+].linkId = "tetra_baby_boy"
* item[=].item[=].text = "Baby boy less than six month"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "tetra_baby_girl"
* item[=].item[=].text = "Baby girl less than six month"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "tetra_pregnant_women"
* item[=].item[=].text = "Pregnant Women"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[+].linkId = "tetra_reason_not_treated"
* item[=].text = "reasons not treated with TETRA"
* item[=].type = #group
* item[=].enableWhen[+].question = "p_medicine"
* item[=].enableWhen[=].operator = #=
* item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#tetra
* item[=].item[+].linkId = "tetra_child"
* item[=].item[=].text = "Children <90 cm untreated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "tetra_pregnant"
* item[=].item[=].text = "Pregnant women untreated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "tetra_breastfeeding"
* item[=].item[=].text = "Breastfeeding women untreated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "tetra_absent"
* item[=].item[=].text = "Absent"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "tetra_refusal"
* item[=].item[=].text = "Refusal"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[+].linkId = "cd_who_distributed"
* item[=].text = "CD who distributed during this year"
* item[=].type = #group
* item[=].item[+].linkId = "cd_who_distributed_man"
* item[=].item[=].text = "Community DistributorMen"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "cd_who_distributed_woman"
* item[=].item[=].text = "Community Distributor Women"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "cd_trained"
* item[=].item[=].text = "CD newly trained"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "cd_recycled"
* item[=].item[=].text = "CD Recycled"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[+].linkId = "p_add_note"
* item[=].text = "Additional Note"
* item[=].type = #text
// dropped: p_start / p_end (device timestamps)
* contained[+] = EspenMRDec
* contained[+] = EspenMRAlb
* contained[+] = EspenMRMeb
* contained[+] = EspenMRIvm
* contained[+] = EspenMRPzq
* contained[+] = EspenMRAzmSusp
* contained[+] = EspenMRAzmTb
* contained[+] = EspenMRTetra
* contained[+] = EspenCommunityTemplate
* contained[+] = EspenMADec
* contained[+] = EspenMAAlb
* contained[+] = EspenMAMeb
* contained[+] = EspenMAIvm
* contained[+] = EspenMAPzq
* contained[+] = EspenMAAzmSusp
* contained[+] = EspenMAAzmTb
* contained[+] = EspenMATetra

// -- extraction templates for Form 3 --

// The community delivery unit (espen-remap): the register-level Group the treatment
// events act on. group-location is a logical (identifier) reference — the village
// Location is registered by Form 1, not re-extracted here.
Instance: EspenCommunityTemplate
InstanceOf: Group
Usage: #inline
* id = "community-template"
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRDeliveryUnit"
* type = #person
* actual = true
* code = $GroupKind#community "Community"
* name.extension[+].url = $SDCTemplateExtractValue
* name.extension[=].valueString = "%resource.repeat(item).where(linkId='p_location').answer.value.first() & ' community'"
* identifier[0].system = "https://icr.healthcampaigns.org/identifier/espen-community"
* identifier[0].value.extension[+].url = $SDCTemplateExtractValue
* identifier[0].value.extension[=].valueString = "%resource.repeat(item).where(linkId='p_location_id').answer.value.first()"
* quantity = 0
* quantity.extension[+].url = $SDCTemplateExtractValue
* quantity.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='census_men').answer.exists(), %resource.repeat(item).where(linkId='census_men').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='census_women').answer.exists(), %resource.repeat(item).where(linkId='census_women').answer.value.first(), 0)"
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/group-location"
* extension[0].valueReference.identifier.system = "https://icr.healthcampaigns.org/identifier/espen-location-id"
* extension[0].valueReference.identifier.value.extension[+].url = $SDCTemplateExtractValue
* extension[0].valueReference.identifier.value.extension[=].valueString = "%resource.repeat(item).where(linkId='p_location_id').answer.value.first()"

// Group-subject treatment events (espen-remap): tablets into people are treatment,
// not a supply transfer. One per answered drug block. The stratified MeasureReport
// carries the counts; these carry the event — and give ICRAdverseEvent.suspectEntity
// something to reference for MDA pharmacovigilance.

Instance: EspenMADec
InstanceOf: MedicationAdministration
Usage: #inline
* id = "ma-dec"
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRMedicationAdministration"
* status = #completed
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/record-origin"
* extension[0].valueCode = #campaign
* medicationCodeableConcept = $ATC#P02CB02 "diethylcarbamazine"
* subject.reference.extension[+].url = $SDCTemplateExtractValue
* subject.reference.extension[=].valueString = "%newCommunityId"
* effectiveDateTime = "2026-01-01"
* effectiveDateTime.extension[+].url = $SDCTemplateExtractValue
* effectiveDateTime.extension[=].valueString = "%resource.authored"

Instance: EspenMAAlb
InstanceOf: MedicationAdministration
Usage: #inline
* id = "ma-alb"
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRMedicationAdministration"
* status = #completed
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/record-origin"
* extension[0].valueCode = #campaign
* medicationCodeableConcept = $ATC#P02CA03 "albendazole"
* subject.reference.extension[+].url = $SDCTemplateExtractValue
* subject.reference.extension[=].valueString = "%newCommunityId"
* effectiveDateTime = "2026-01-01"
* effectiveDateTime.extension[+].url = $SDCTemplateExtractValue
* effectiveDateTime.extension[=].valueString = "%resource.authored"

Instance: EspenMAMeb
InstanceOf: MedicationAdministration
Usage: #inline
* id = "ma-meb"
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRMedicationAdministration"
* status = #completed
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/record-origin"
* extension[0].valueCode = #campaign
* medicationCodeableConcept = $ATC#P02CA01 "mebendazole"
* subject.reference.extension[+].url = $SDCTemplateExtractValue
* subject.reference.extension[=].valueString = "%newCommunityId"
* effectiveDateTime = "2026-01-01"
* effectiveDateTime.extension[+].url = $SDCTemplateExtractValue
* effectiveDateTime.extension[=].valueString = "%resource.authored"

Instance: EspenMAIvm
InstanceOf: MedicationAdministration
Usage: #inline
* id = "ma-ivm"
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRMedicationAdministration"
* status = #completed
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/record-origin"
* extension[0].valueCode = #campaign
* medicationCodeableConcept = $ATC#P02CF01 "ivermectin"
* subject.reference.extension[+].url = $SDCTemplateExtractValue
* subject.reference.extension[=].valueString = "%newCommunityId"
* effectiveDateTime = "2026-01-01"
* effectiveDateTime.extension[+].url = $SDCTemplateExtractValue
* effectiveDateTime.extension[=].valueString = "%resource.authored"

Instance: EspenMAPzq
InstanceOf: MedicationAdministration
Usage: #inline
* id = "ma-pzq"
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRMedicationAdministration"
* status = #completed
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/record-origin"
* extension[0].valueCode = #campaign
* medicationCodeableConcept = $ATC#P02BA01 "praziquantel"
* subject.reference.extension[+].url = $SDCTemplateExtractValue
* subject.reference.extension[=].valueString = "%newCommunityId"
* effectiveDateTime = "2026-01-01"
* effectiveDateTime.extension[+].url = $SDCTemplateExtractValue
* effectiveDateTime.extension[=].valueString = "%resource.authored"

Instance: EspenMAAzmSusp
InstanceOf: MedicationAdministration
Usage: #inline
* id = "ma-azm-susp"
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRMedicationAdministration"
* status = #completed
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/record-origin"
* extension[0].valueCode = #campaign
* medicationCodeableConcept = $ATC#J01FA10 "azithromycin"
* subject.reference.extension[+].url = $SDCTemplateExtractValue
* subject.reference.extension[=].valueString = "%newCommunityId"
* effectiveDateTime = "2026-01-01"
* effectiveDateTime.extension[+].url = $SDCTemplateExtractValue
* effectiveDateTime.extension[=].valueString = "%resource.authored"

Instance: EspenMAAzmTb
InstanceOf: MedicationAdministration
Usage: #inline
* id = "ma-azm-tb"
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRMedicationAdministration"
* status = #completed
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/record-origin"
* extension[0].valueCode = #campaign
* medicationCodeableConcept = $ATC#J01FA10 "azithromycin"
* subject.reference.extension[+].url = $SDCTemplateExtractValue
* subject.reference.extension[=].valueString = "%newCommunityId"
* effectiveDateTime = "2026-01-01"
* effectiveDateTime.extension[+].url = $SDCTemplateExtractValue
* effectiveDateTime.extension[=].valueString = "%resource.authored"

Instance: EspenMATetra
InstanceOf: MedicationAdministration
Usage: #inline
* id = "ma-tetra"
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRMedicationAdministration"
* status = #completed
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/record-origin"
* extension[0].valueCode = #campaign
* medicationCodeableConcept = $ATC#S01AA09 "tetracycline"
* subject.reference.extension[+].url = $SDCTemplateExtractValue
* subject.reference.extension[=].valueString = "%newCommunityId"
* effectiveDateTime = "2026-01-01"
* effectiveDateTime.extension[+].url = $SDCTemplateExtractValue
* effectiveDateTime.extension[=].valueString = "%resource.authored"

Instance: EspenMRDec
InstanceOf: MeasureReport
Usage: #inline
* id = "mr-dec"
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRAdministrativeCoverage"
* status = #complete
* type = #summary
* measure = "https://icr.healthcampaigns.org/Measure/icr-mda-treatment-coverage"
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/coverage-source"
* extension[0].valueCode = #administrative
* extension[1].url = "https://icr.healthcampaigns.org/StructureDefinition/realtime-vs-reconciled"
* extension[1].valueCode = #realtime
* period.start = "2026-01-01"
* period.start.extension[+].url = $SDCTemplateExtractValue
* period.start.extension[=].valueString = "%resource.authored"
* period.end = "2026-01-01"
* period.end.extension[+].url = $SDCTemplateExtractValue
* period.end.extension[=].valueString = "%resource.authored"
* reporter.display = "recorder"
* reporter.display.extension[+].url = $SDCTemplateExtractValue
* reporter.display.extension[=].valueString = "%resource.repeat(item).where(linkId='p_recorder_id').answer.value.first()"
* group[0].code = $ATC#P02CB02 "diethylcarbamazine"
* group[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].population[0].count = 0
* group[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='dec_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='dec_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='dec_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_15_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='dec_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_15_male_treated').answer.value.first(), 0)"
* group[0].population[1].code = $MeasurePopulation#denominator "Denominator"
* group[0].population[1].count = 0
* group[0].population[1].count.extension[+].url = $SDCTemplateExtractValue
* group[0].population[1].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='census_men').answer.exists(), %resource.repeat(item).where(linkId='census_men').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='census_women').answer.exists(), %resource.repeat(item).where(linkId='census_women').answer.value.first(), 0)"
// measureScore: unitless percentage — proportion-scored Measures must not carry units (validator businessrule)
* group[0].measureScore.value = 0
* group[0].measureScore.value.extension[+].url = $SDCTemplateExtractValue
* group[0].measureScore.value.extension[=].valueString = "iif((iif(%resource.repeat(item).where(linkId='census_men').answer.exists(), %resource.repeat(item).where(linkId='census_men').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='census_women').answer.exists(), %resource.repeat(item).where(linkId='census_women').answer.value.first(), 0)) > 0, (iif(%resource.repeat(item).where(linkId='dec_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='dec_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='dec_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_15_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='dec_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_15_male_treated').answer.value.first(), 0)) * 100 / (iif(%resource.repeat(item).where(linkId='census_men').answer.exists(), %resource.repeat(item).where(linkId='census_men').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='census_women').answer.exists(), %resource.repeat(item).where(linkId='census_women').answer.value.first(), 0)), 0)"
// sex stratifier
* group[0].stratifier[0].code = $CoverageStratifier#sex "Sex"
* group[0].stratifier[0].stratum[0].value.text = "female"
* group[0].stratifier[0].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[0].stratum[0].population[0].count = 0
* group[0].stratifier[0].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[0].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='dec_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='dec_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_15_female_treated').answer.value.first(), 0)"
* group[0].stratifier[0].stratum[1].value.text = "male"
* group[0].stratifier[0].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[0].stratum[1].population[0].count = 0
* group[0].stratifier[0].stratum[1].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[0].stratum[1].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='dec_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='dec_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_15_male_treated').answer.value.first(), 0)"
// age-band stratifier
* group[0].stratifier[1].code = $CoverageStratifier#age-band "Age band"
* group[0].stratifier[1].stratum[0].value.text = "5-14 years"
* group[0].stratifier[1].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[1].stratum[0].population[0].count = 0
* group[0].stratifier[1].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[1].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='dec_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='dec_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_5_14_male_treated').answer.value.first(), 0)"
* group[0].stratifier[1].stratum[1].value.text = "15+ years"
* group[0].stratifier[1].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[1].stratum[1].population[0].count = 0
* group[0].stratifier[1].stratum[1].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[1].stratum[1].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='dec_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_15_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='dec_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_15_male_treated').answer.value.first(), 0)"
// disposition stratifier — one stratum per reason item + treated
* group[0].stratifier[2].code = $CoverageStratifier#disposition "Disposition"
* group[0].stratifier[2].stratum[0].value.text = "treated"
* group[0].stratifier[2].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[0].population[0].count = 0
* group[0].stratifier[2].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='dec_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='dec_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='dec_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_15_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='dec_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='dec_15_male_treated').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[1].value.text = "excluded - under height/age"
* group[0].stratifier[2].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[1].population[0].count = 0
* group[0].stratifier[2].stratum[1].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[1].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='dec_child').answer.exists(), %resource.repeat(item).where(linkId='dec_child').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[2].value.text = "excluded - pregnant"
* group[0].stratifier[2].stratum[2].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[2].population[0].count = 0
* group[0].stratifier[2].stratum[2].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[2].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='dec_pregnant').answer.exists(), %resource.repeat(item).where(linkId='dec_pregnant').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[3].value.text = "excluded - breastfeeding"
* group[0].stratifier[2].stratum[3].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[3].population[0].count = 0
* group[0].stratifier[2].stratum[3].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[3].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='dec_breastfeeding').answer.exists(), %resource.repeat(item).where(linkId='dec_breastfeeding').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[4].value.text = "absent"
* group[0].stratifier[2].stratum[4].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[4].population[0].count = 0
* group[0].stratifier[2].stratum[4].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[4].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='dec_absent').answer.exists(), %resource.repeat(item).where(linkId='dec_absent').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[5].value.text = "refused"
* group[0].stratifier[2].stratum[5].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[5].population[0].count = 0
* group[0].stratifier[2].stratum[5].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[5].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='dec_refusal').answer.exists(), %resource.repeat(item).where(linkId='dec_refusal').answer.value.first(), 0)"

Instance: EspenMRAlb
InstanceOf: MeasureReport
Usage: #inline
* id = "mr-alb"
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRAdministrativeCoverage"
* status = #complete
* type = #summary
* measure = "https://icr.healthcampaigns.org/Measure/icr-mda-treatment-coverage"
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/coverage-source"
* extension[0].valueCode = #administrative
* extension[1].url = "https://icr.healthcampaigns.org/StructureDefinition/realtime-vs-reconciled"
* extension[1].valueCode = #realtime
* period.start = "2026-01-01"
* period.start.extension[+].url = $SDCTemplateExtractValue
* period.start.extension[=].valueString = "%resource.authored"
* period.end = "2026-01-01"
* period.end.extension[+].url = $SDCTemplateExtractValue
* period.end.extension[=].valueString = "%resource.authored"
* reporter.display = "recorder"
* reporter.display.extension[+].url = $SDCTemplateExtractValue
* reporter.display.extension[=].valueString = "%resource.repeat(item).where(linkId='p_recorder_id').answer.value.first()"
* group[0].code = $ATC#P02CA03 "albendazole"
* group[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].population[0].count = 0
* group[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='alb_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='alb_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='alb_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='alb_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='alb_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='alb_15_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='alb_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='alb_15_male_treated').answer.value.first(), 0)"
* group[0].population[1].code = $MeasurePopulation#denominator "Denominator"
* group[0].population[1].count = 0
* group[0].population[1].count.extension[+].url = $SDCTemplateExtractValue
* group[0].population[1].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='census_men').answer.exists(), %resource.repeat(item).where(linkId='census_men').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='census_women').answer.exists(), %resource.repeat(item).where(linkId='census_women').answer.value.first(), 0)"
* group[0].measureScore.value = 0
* group[0].measureScore.value.extension[+].url = $SDCTemplateExtractValue
* group[0].measureScore.value.extension[=].valueString = "iif((iif(%resource.repeat(item).where(linkId='census_men').answer.exists(), %resource.repeat(item).where(linkId='census_men').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='census_women').answer.exists(), %resource.repeat(item).where(linkId='census_women').answer.value.first(), 0)) > 0, (iif(%resource.repeat(item).where(linkId='alb_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='alb_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='alb_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='alb_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='alb_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='alb_15_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='alb_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='alb_15_male_treated').answer.value.first(), 0)) * 100 / (iif(%resource.repeat(item).where(linkId='census_men').answer.exists(), %resource.repeat(item).where(linkId='census_men').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='census_women').answer.exists(), %resource.repeat(item).where(linkId='census_women').answer.value.first(), 0)), 0)"
// sex stratifier
* group[0].stratifier[0].code = $CoverageStratifier#sex "Sex"
* group[0].stratifier[0].stratum[0].value.text = "female"
* group[0].stratifier[0].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[0].stratum[0].population[0].count = 0
* group[0].stratifier[0].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[0].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='alb_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='alb_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='alb_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='alb_15_female_treated').answer.value.first(), 0)"
* group[0].stratifier[0].stratum[1].value.text = "male"
* group[0].stratifier[0].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[0].stratum[1].population[0].count = 0
* group[0].stratifier[0].stratum[1].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[0].stratum[1].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='alb_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='alb_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='alb_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='alb_15_male_treated').answer.value.first(), 0)"
// age-band stratifier
* group[0].stratifier[1].code = $CoverageStratifier#age-band "Age band"
* group[0].stratifier[1].stratum[0].value.text = "5-14 years"
* group[0].stratifier[1].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[1].stratum[0].population[0].count = 0
* group[0].stratifier[1].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[1].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='alb_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='alb_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='alb_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='alb_5_14_male_treated').answer.value.first(), 0)"
* group[0].stratifier[1].stratum[1].value.text = "15+ years"
* group[0].stratifier[1].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[1].stratum[1].population[0].count = 0
* group[0].stratifier[1].stratum[1].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[1].stratum[1].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='alb_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='alb_15_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='alb_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='alb_15_male_treated').answer.value.first(), 0)"
// disposition stratifier — one stratum per reason item + treated
* group[0].stratifier[2].code = $CoverageStratifier#disposition "Disposition"
* group[0].stratifier[2].stratum[0].value.text = "treated"
* group[0].stratifier[2].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[0].population[0].count = 0
* group[0].stratifier[2].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='alb_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='alb_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='alb_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='alb_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='alb_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='alb_15_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='alb_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='alb_15_male_treated').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[1].value.text = "excluded - under height/age"
* group[0].stratifier[2].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[1].population[0].count = 0
* group[0].stratifier[2].stratum[1].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[1].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='alb_child').answer.exists(), %resource.repeat(item).where(linkId='alb_child').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[2].value.text = "excluded - pregnant"
* group[0].stratifier[2].stratum[2].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[2].population[0].count = 0
* group[0].stratifier[2].stratum[2].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[2].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='alb_pregnant').answer.exists(), %resource.repeat(item).where(linkId='alb_pregnant').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[3].value.text = "excluded - breastfeeding"
* group[0].stratifier[2].stratum[3].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[3].population[0].count = 0
* group[0].stratifier[2].stratum[3].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[3].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='alb_breastfeeding').answer.exists(), %resource.repeat(item).where(linkId='alb_breastfeeding').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[4].value.text = "absent"
* group[0].stratifier[2].stratum[4].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[4].population[0].count = 0
* group[0].stratifier[2].stratum[4].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[4].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='alb_absent').answer.exists(), %resource.repeat(item).where(linkId='alb_absent').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[5].value.text = "refused"
* group[0].stratifier[2].stratum[5].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[5].population[0].count = 0
* group[0].stratifier[2].stratum[5].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[5].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='alb_refusal').answer.exists(), %resource.repeat(item).where(linkId='alb_refusal').answer.value.first(), 0)"

Instance: EspenMRMeb
InstanceOf: MeasureReport
Usage: #inline
* id = "mr-meb"
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRAdministrativeCoverage"
* status = #complete
* type = #summary
* measure = "https://icr.healthcampaigns.org/Measure/icr-mda-treatment-coverage"
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/coverage-source"
* extension[0].valueCode = #administrative
* extension[1].url = "https://icr.healthcampaigns.org/StructureDefinition/realtime-vs-reconciled"
* extension[1].valueCode = #realtime
* period.start = "2026-01-01"
* period.start.extension[+].url = $SDCTemplateExtractValue
* period.start.extension[=].valueString = "%resource.authored"
* period.end = "2026-01-01"
* period.end.extension[+].url = $SDCTemplateExtractValue
* period.end.extension[=].valueString = "%resource.authored"
* reporter.display = "recorder"
* reporter.display.extension[+].url = $SDCTemplateExtractValue
* reporter.display.extension[=].valueString = "%resource.repeat(item).where(linkId='p_recorder_id').answer.value.first()"
* group[0].code = $ATC#P02CA01 "mebendazole"
* group[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].population[0].count = 0
* group[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='meb_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='meb_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='meb_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='meb_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='meb_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='meb_15_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='meb_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='meb_15_male_treated').answer.value.first(), 0)"
* group[0].population[1].code = $MeasurePopulation#denominator "Denominator"
* group[0].population[1].count = 0
* group[0].population[1].count.extension[+].url = $SDCTemplateExtractValue
* group[0].population[1].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='census_men').answer.exists(), %resource.repeat(item).where(linkId='census_men').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='census_women').answer.exists(), %resource.repeat(item).where(linkId='census_women').answer.value.first(), 0)"
* group[0].measureScore.value = 0
* group[0].measureScore.value.extension[+].url = $SDCTemplateExtractValue
* group[0].measureScore.value.extension[=].valueString = "iif((iif(%resource.repeat(item).where(linkId='census_men').answer.exists(), %resource.repeat(item).where(linkId='census_men').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='census_women').answer.exists(), %resource.repeat(item).where(linkId='census_women').answer.value.first(), 0)) > 0, (iif(%resource.repeat(item).where(linkId='meb_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='meb_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='meb_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='meb_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='meb_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='meb_15_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='meb_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='meb_15_male_treated').answer.value.first(), 0)) * 100 / (iif(%resource.repeat(item).where(linkId='census_men').answer.exists(), %resource.repeat(item).where(linkId='census_men').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='census_women').answer.exists(), %resource.repeat(item).where(linkId='census_women').answer.value.first(), 0)), 0)"
// sex stratifier
* group[0].stratifier[0].code = $CoverageStratifier#sex "Sex"
* group[0].stratifier[0].stratum[0].value.text = "female"
* group[0].stratifier[0].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[0].stratum[0].population[0].count = 0
* group[0].stratifier[0].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[0].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='meb_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='meb_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='meb_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='meb_15_female_treated').answer.value.first(), 0)"
* group[0].stratifier[0].stratum[1].value.text = "male"
* group[0].stratifier[0].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[0].stratum[1].population[0].count = 0
* group[0].stratifier[0].stratum[1].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[0].stratum[1].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='meb_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='meb_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='meb_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='meb_15_male_treated').answer.value.first(), 0)"
// age-band stratifier
* group[0].stratifier[1].code = $CoverageStratifier#age-band "Age band"
* group[0].stratifier[1].stratum[0].value.text = "5-14 years"
* group[0].stratifier[1].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[1].stratum[0].population[0].count = 0
* group[0].stratifier[1].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[1].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='meb_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='meb_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='meb_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='meb_5_14_male_treated').answer.value.first(), 0)"
* group[0].stratifier[1].stratum[1].value.text = "15+ years"
* group[0].stratifier[1].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[1].stratum[1].population[0].count = 0
* group[0].stratifier[1].stratum[1].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[1].stratum[1].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='meb_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='meb_15_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='meb_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='meb_15_male_treated').answer.value.first(), 0)"
// disposition stratifier — one stratum per reason item + treated
* group[0].stratifier[2].code = $CoverageStratifier#disposition "Disposition"
* group[0].stratifier[2].stratum[0].value.text = "treated"
* group[0].stratifier[2].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[0].population[0].count = 0
* group[0].stratifier[2].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='meb_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='meb_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='meb_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='meb_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='meb_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='meb_15_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='meb_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='meb_15_male_treated').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[1].value.text = "excluded - under height/age"
* group[0].stratifier[2].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[1].population[0].count = 0
* group[0].stratifier[2].stratum[1].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[1].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='meb_child').answer.exists(), %resource.repeat(item).where(linkId='meb_child').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[2].value.text = "excluded - pregnant"
* group[0].stratifier[2].stratum[2].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[2].population[0].count = 0
* group[0].stratifier[2].stratum[2].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[2].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='meb_pregnant').answer.exists(), %resource.repeat(item).where(linkId='meb_pregnant').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[3].value.text = "excluded - breastfeeding"
* group[0].stratifier[2].stratum[3].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[3].population[0].count = 0
* group[0].stratifier[2].stratum[3].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[3].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='meb_breastfeeding').answer.exists(), %resource.repeat(item).where(linkId='meb_breastfeeding').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[4].value.text = "absent"
* group[0].stratifier[2].stratum[4].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[4].population[0].count = 0
* group[0].stratifier[2].stratum[4].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[4].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='meb_absent').answer.exists(), %resource.repeat(item).where(linkId='meb_absent').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[5].value.text = "refused"
* group[0].stratifier[2].stratum[5].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[5].population[0].count = 0
* group[0].stratifier[2].stratum[5].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[5].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='meb_refusal').answer.exists(), %resource.repeat(item).where(linkId='meb_refusal').answer.value.first(), 0)"

Instance: EspenMRIvm
InstanceOf: MeasureReport
Usage: #inline
* id = "mr-ivm"
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRAdministrativeCoverage"
* status = #complete
* type = #summary
* measure = "https://icr.healthcampaigns.org/Measure/icr-mda-treatment-coverage"
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/coverage-source"
* extension[0].valueCode = #administrative
* extension[1].url = "https://icr.healthcampaigns.org/StructureDefinition/realtime-vs-reconciled"
* extension[1].valueCode = #realtime
* period.start = "2026-01-01"
* period.start.extension[+].url = $SDCTemplateExtractValue
* period.start.extension[=].valueString = "%resource.authored"
* period.end = "2026-01-01"
* period.end.extension[+].url = $SDCTemplateExtractValue
* period.end.extension[=].valueString = "%resource.authored"
* reporter.display = "recorder"
* reporter.display.extension[+].url = $SDCTemplateExtractValue
* reporter.display.extension[=].valueString = "%resource.repeat(item).where(linkId='p_recorder_id').answer.value.first()"
* group[0].code = $ATC#P02CF01 "ivermectin"
* group[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].population[0].count = 0
* group[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='ivm_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='ivm_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='ivm_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='ivm_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='ivm_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='ivm_15_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='ivm_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='ivm_15_male_treated').answer.value.first(), 0)"
* group[0].population[1].code = $MeasurePopulation#denominator "Denominator"
* group[0].population[1].count = 0
* group[0].population[1].count.extension[+].url = $SDCTemplateExtractValue
* group[0].population[1].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='census_men').answer.exists(), %resource.repeat(item).where(linkId='census_men').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='census_women').answer.exists(), %resource.repeat(item).where(linkId='census_women').answer.value.first(), 0)"
* group[0].measureScore.value = 0
* group[0].measureScore.value.extension[+].url = $SDCTemplateExtractValue
* group[0].measureScore.value.extension[=].valueString = "iif((iif(%resource.repeat(item).where(linkId='census_men').answer.exists(), %resource.repeat(item).where(linkId='census_men').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='census_women').answer.exists(), %resource.repeat(item).where(linkId='census_women').answer.value.first(), 0)) > 0, (iif(%resource.repeat(item).where(linkId='ivm_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='ivm_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='ivm_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='ivm_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='ivm_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='ivm_15_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='ivm_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='ivm_15_male_treated').answer.value.first(), 0)) * 100 / (iif(%resource.repeat(item).where(linkId='census_men').answer.exists(), %resource.repeat(item).where(linkId='census_men').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='census_women').answer.exists(), %resource.repeat(item).where(linkId='census_women').answer.value.first(), 0)), 0)"
// sex stratifier
* group[0].stratifier[0].code = $CoverageStratifier#sex "Sex"
* group[0].stratifier[0].stratum[0].value.text = "female"
* group[0].stratifier[0].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[0].stratum[0].population[0].count = 0
* group[0].stratifier[0].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[0].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='ivm_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='ivm_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='ivm_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='ivm_15_female_treated').answer.value.first(), 0)"
* group[0].stratifier[0].stratum[1].value.text = "male"
* group[0].stratifier[0].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[0].stratum[1].population[0].count = 0
* group[0].stratifier[0].stratum[1].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[0].stratum[1].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='ivm_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='ivm_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='ivm_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='ivm_15_male_treated').answer.value.first(), 0)"
// age-band stratifier
* group[0].stratifier[1].code = $CoverageStratifier#age-band "Age band"
* group[0].stratifier[1].stratum[0].value.text = "5-14 years"
* group[0].stratifier[1].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[1].stratum[0].population[0].count = 0
* group[0].stratifier[1].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[1].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='ivm_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='ivm_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='ivm_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='ivm_5_14_male_treated').answer.value.first(), 0)"
* group[0].stratifier[1].stratum[1].value.text = "15+ years"
* group[0].stratifier[1].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[1].stratum[1].population[0].count = 0
* group[0].stratifier[1].stratum[1].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[1].stratum[1].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='ivm_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='ivm_15_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='ivm_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='ivm_15_male_treated').answer.value.first(), 0)"
// disposition stratifier — one stratum per reason item + treated
* group[0].stratifier[2].code = $CoverageStratifier#disposition "Disposition"
* group[0].stratifier[2].stratum[0].value.text = "treated"
* group[0].stratifier[2].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[0].population[0].count = 0
* group[0].stratifier[2].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='ivm_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='ivm_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='ivm_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='ivm_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='ivm_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='ivm_15_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='ivm_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='ivm_15_male_treated').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[1].value.text = "excluded - under height/age"
* group[0].stratifier[2].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[1].population[0].count = 0
* group[0].stratifier[2].stratum[1].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[1].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='ivm_child').answer.exists(), %resource.repeat(item).where(linkId='ivm_child').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[2].value.text = "excluded - pregnant"
* group[0].stratifier[2].stratum[2].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[2].population[0].count = 0
* group[0].stratifier[2].stratum[2].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[2].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='ivm_pregnant').answer.exists(), %resource.repeat(item).where(linkId='ivm_pregnant').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[3].value.text = "excluded - breastfeeding"
* group[0].stratifier[2].stratum[3].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[3].population[0].count = 0
* group[0].stratifier[2].stratum[3].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[3].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='ivm_breastfeeding').answer.exists(), %resource.repeat(item).where(linkId='ivm_breastfeeding').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[4].value.text = "absent"
* group[0].stratifier[2].stratum[4].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[4].population[0].count = 0
* group[0].stratifier[2].stratum[4].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[4].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='ivm_absent').answer.exists(), %resource.repeat(item).where(linkId='ivm_absent').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[5].value.text = "refused"
* group[0].stratifier[2].stratum[5].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[5].population[0].count = 0
* group[0].stratifier[2].stratum[5].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[5].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='ivm_refusal').answer.exists(), %resource.repeat(item).where(linkId='ivm_refusal').answer.value.first(), 0)"

Instance: EspenMRPzq
InstanceOf: MeasureReport
Usage: #inline
* id = "mr-pzq"
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRAdministrativeCoverage"
* status = #complete
* type = #summary
* measure = "https://icr.healthcampaigns.org/Measure/icr-mda-treatment-coverage"
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/coverage-source"
* extension[0].valueCode = #administrative
* extension[1].url = "https://icr.healthcampaigns.org/StructureDefinition/realtime-vs-reconciled"
* extension[1].valueCode = #realtime
* period.start = "2026-01-01"
* period.start.extension[+].url = $SDCTemplateExtractValue
* period.start.extension[=].valueString = "%resource.authored"
* period.end = "2026-01-01"
* period.end.extension[+].url = $SDCTemplateExtractValue
* period.end.extension[=].valueString = "%resource.authored"
* reporter.display = "recorder"
* reporter.display.extension[+].url = $SDCTemplateExtractValue
* reporter.display.extension[=].valueString = "%resource.repeat(item).where(linkId='p_recorder_id').answer.value.first()"
* group[0].code = $ATC#P02BA01 "praziquantel"
* group[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].population[0].count = 0
* group[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='pzq_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='pzq_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='pzq_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='pzq_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='pzq_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='pzq_15_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='pzq_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='pzq_15_male_treated').answer.value.first(), 0)"
* group[0].population[1].code = $MeasurePopulation#denominator "Denominator"
* group[0].population[1].count = 0
* group[0].population[1].count.extension[+].url = $SDCTemplateExtractValue
* group[0].population[1].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='census_men').answer.exists(), %resource.repeat(item).where(linkId='census_men').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='census_women').answer.exists(), %resource.repeat(item).where(linkId='census_women').answer.value.first(), 0)"
* group[0].measureScore.value = 0
* group[0].measureScore.value.extension[+].url = $SDCTemplateExtractValue
* group[0].measureScore.value.extension[=].valueString = "iif((iif(%resource.repeat(item).where(linkId='census_men').answer.exists(), %resource.repeat(item).where(linkId='census_men').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='census_women').answer.exists(), %resource.repeat(item).where(linkId='census_women').answer.value.first(), 0)) > 0, (iif(%resource.repeat(item).where(linkId='pzq_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='pzq_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='pzq_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='pzq_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='pzq_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='pzq_15_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='pzq_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='pzq_15_male_treated').answer.value.first(), 0)) * 100 / (iif(%resource.repeat(item).where(linkId='census_men').answer.exists(), %resource.repeat(item).where(linkId='census_men').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='census_women').answer.exists(), %resource.repeat(item).where(linkId='census_women').answer.value.first(), 0)), 0)"
// sex stratifier
* group[0].stratifier[0].code = $CoverageStratifier#sex "Sex"
* group[0].stratifier[0].stratum[0].value.text = "female"
* group[0].stratifier[0].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[0].stratum[0].population[0].count = 0
* group[0].stratifier[0].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[0].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='pzq_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='pzq_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='pzq_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='pzq_15_female_treated').answer.value.first(), 0)"
* group[0].stratifier[0].stratum[1].value.text = "male"
* group[0].stratifier[0].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[0].stratum[1].population[0].count = 0
* group[0].stratifier[0].stratum[1].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[0].stratum[1].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='pzq_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='pzq_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='pzq_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='pzq_15_male_treated').answer.value.first(), 0)"
// age-band stratifier
* group[0].stratifier[1].code = $CoverageStratifier#age-band "Age band"
* group[0].stratifier[1].stratum[0].value.text = "5-14 years"
* group[0].stratifier[1].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[1].stratum[0].population[0].count = 0
* group[0].stratifier[1].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[1].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='pzq_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='pzq_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='pzq_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='pzq_5_14_male_treated').answer.value.first(), 0)"
* group[0].stratifier[1].stratum[1].value.text = "15+ years"
* group[0].stratifier[1].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[1].stratum[1].population[0].count = 0
* group[0].stratifier[1].stratum[1].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[1].stratum[1].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='pzq_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='pzq_15_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='pzq_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='pzq_15_male_treated').answer.value.first(), 0)"
// disposition stratifier — one stratum per reason item + treated
* group[0].stratifier[2].code = $CoverageStratifier#disposition "Disposition"
* group[0].stratifier[2].stratum[0].value.text = "treated"
* group[0].stratifier[2].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[0].population[0].count = 0
* group[0].stratifier[2].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='pzq_5_14_female_treated').answer.exists(), %resource.repeat(item).where(linkId='pzq_5_14_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='pzq_5_14_male_treated').answer.exists(), %resource.repeat(item).where(linkId='pzq_5_14_male_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='pzq_15_female_treated').answer.exists(), %resource.repeat(item).where(linkId='pzq_15_female_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='pzq_15_male_treated').answer.exists(), %resource.repeat(item).where(linkId='pzq_15_male_treated').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[1].value.text = "excluded - under height/age"
* group[0].stratifier[2].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[1].population[0].count = 0
* group[0].stratifier[2].stratum[1].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[1].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='pzq_child').answer.exists(), %resource.repeat(item).where(linkId='pzq_child').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[2].value.text = "excluded - pregnant"
* group[0].stratifier[2].stratum[2].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[2].population[0].count = 0
* group[0].stratifier[2].stratum[2].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[2].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='pzq_pregnant').answer.exists(), %resource.repeat(item).where(linkId='pzq_pregnant').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[3].value.text = "excluded - breastfeeding"
* group[0].stratifier[2].stratum[3].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[3].population[0].count = 0
* group[0].stratifier[2].stratum[3].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[3].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='pzq_breastfeeding').answer.exists(), %resource.repeat(item).where(linkId='pzq_breastfeeding').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[4].value.text = "absent"
* group[0].stratifier[2].stratum[4].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[4].population[0].count = 0
* group[0].stratifier[2].stratum[4].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[4].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='pzq_absent').answer.exists(), %resource.repeat(item).where(linkId='pzq_absent').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[5].value.text = "refused"
* group[0].stratifier[2].stratum[5].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[5].population[0].count = 0
* group[0].stratifier[2].stratum[5].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[5].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='pzq_refusal').answer.exists(), %resource.repeat(item).where(linkId='pzq_refusal').answer.value.first(), 0)"

Instance: EspenMRAzmSusp
InstanceOf: MeasureReport
Usage: #inline
* id = "mr-azm-susp"
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRAdministrativeCoverage"
* status = #complete
* type = #summary
* measure = "https://icr.healthcampaigns.org/Measure/icr-mda-treatment-coverage"
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/coverage-source"
* extension[0].valueCode = #administrative
* extension[1].url = "https://icr.healthcampaigns.org/StructureDefinition/realtime-vs-reconciled"
* extension[1].valueCode = #realtime
* period.start = "2026-01-01"
* period.start.extension[+].url = $SDCTemplateExtractValue
* period.start.extension[=].valueString = "%resource.authored"
* period.end = "2026-01-01"
* period.end.extension[+].url = $SDCTemplateExtractValue
* period.end.extension[=].valueString = "%resource.authored"
* reporter.display = "recorder"
* reporter.display.extension[+].url = $SDCTemplateExtractValue
* reporter.display.extension[=].valueString = "%resource.repeat(item).where(linkId='p_recorder_id').answer.value.first()"
* group[0].code = $ATC#J01FA10 "azithromycin"
* group[0].code.text = "azithromycin (suspension)"
* group[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].population[0].count = 0
* group[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='azm_susp_less7_boy_treated').answer.exists(), %resource.repeat(item).where(linkId='azm_susp_less7_boy_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='azm_susp_less7_girl_treated').answer.exists(), %resource.repeat(item).where(linkId='azm_susp_less7_girl_treated').answer.value.first(), 0)"
* group[0].population[1].code = $MeasurePopulation#denominator "Denominator"
* group[0].population[1].count = 0
* group[0].population[1].count.extension[+].url = $SDCTemplateExtractValue
* group[0].population[1].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='census_men').answer.exists(), %resource.repeat(item).where(linkId='census_men').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='census_women').answer.exists(), %resource.repeat(item).where(linkId='census_women').answer.value.first(), 0)"
* group[0].measureScore.value = 0
* group[0].measureScore.value.extension[+].url = $SDCTemplateExtractValue
* group[0].measureScore.value.extension[=].valueString = "iif((iif(%resource.repeat(item).where(linkId='census_men').answer.exists(), %resource.repeat(item).where(linkId='census_men').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='census_women').answer.exists(), %resource.repeat(item).where(linkId='census_women').answer.value.first(), 0)) > 0, (iif(%resource.repeat(item).where(linkId='azm_susp_less7_boy_treated').answer.exists(), %resource.repeat(item).where(linkId='azm_susp_less7_boy_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='azm_susp_less7_girl_treated').answer.exists(), %resource.repeat(item).where(linkId='azm_susp_less7_girl_treated').answer.value.first(), 0)) * 100 / (iif(%resource.repeat(item).where(linkId='census_men').answer.exists(), %resource.repeat(item).where(linkId='census_men').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='census_women').answer.exists(), %resource.repeat(item).where(linkId='census_women').answer.value.first(), 0)), 0)"
// sex stratifier
* group[0].stratifier[0].code = $CoverageStratifier#sex "Sex"
* group[0].stratifier[0].stratum[0].value.text = "female"
* group[0].stratifier[0].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[0].stratum[0].population[0].count = 0
* group[0].stratifier[0].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[0].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='azm_susp_less7_girl_treated').answer.exists(), %resource.repeat(item).where(linkId='azm_susp_less7_girl_treated').answer.value.first(), 0)"
* group[0].stratifier[0].stratum[1].value.text = "male"
* group[0].stratifier[0].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[0].stratum[1].population[0].count = 0
* group[0].stratifier[0].stratum[1].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[0].stratum[1].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='azm_susp_less7_boy_treated').answer.exists(), %resource.repeat(item).where(linkId='azm_susp_less7_boy_treated').answer.value.first(), 0)"
// age-band stratifier (single band — this block only covers 6 months-<7 years)
* group[0].stratifier[1].code = $CoverageStratifier#age-band "Age band"
* group[0].stratifier[1].stratum[0].value.text = "6 months - <7 years"
* group[0].stratifier[1].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[1].stratum[0].population[0].count = 0
* group[0].stratifier[1].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[1].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='azm_susp_less7_boy_treated').answer.exists(), %resource.repeat(item).where(linkId='azm_susp_less7_boy_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='azm_susp_less7_girl_treated').answer.exists(), %resource.repeat(item).where(linkId='azm_susp_less7_girl_treated').answer.value.first(), 0)"
// disposition stratifier — one stratum per reason item + treated
* group[0].stratifier[2].code = $CoverageStratifier#disposition "Disposition"
* group[0].stratifier[2].stratum[0].value.text = "treated"
* group[0].stratifier[2].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[0].population[0].count = 0
* group[0].stratifier[2].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='azm_susp_less7_boy_treated').answer.exists(), %resource.repeat(item).where(linkId='azm_susp_less7_boy_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='azm_susp_less7_girl_treated').answer.exists(), %resource.repeat(item).where(linkId='azm_susp_less7_girl_treated').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[1].value.text = "excluded - under height/age"
* group[0].stratifier[2].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[1].population[0].count = 0
* group[0].stratifier[2].stratum[1].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[1].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='azm_susp_child').answer.exists(), %resource.repeat(item).where(linkId='azm_susp_child').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[2].value.text = "absent"
* group[0].stratifier[2].stratum[2].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[2].population[0].count = 0
* group[0].stratifier[2].stratum[2].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[2].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='azm_susp_absent').answer.exists(), %resource.repeat(item).where(linkId='azm_susp_absent').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[3].value.text = "refused"
* group[0].stratifier[2].stratum[3].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[3].population[0].count = 0
* group[0].stratifier[2].stratum[3].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[3].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='azm_susp_refusal').answer.exists(), %resource.repeat(item).where(linkId='azm_susp_refusal').answer.value.first(), 0)"

Instance: EspenMRAzmTb
InstanceOf: MeasureReport
Usage: #inline
* id = "mr-azm-tb"
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRAdministrativeCoverage"
* status = #complete
* type = #summary
* measure = "https://icr.healthcampaigns.org/Measure/icr-mda-treatment-coverage"
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/coverage-source"
* extension[0].valueCode = #administrative
* extension[1].url = "https://icr.healthcampaigns.org/StructureDefinition/realtime-vs-reconciled"
* extension[1].valueCode = #realtime
* period.start = "2026-01-01"
* period.start.extension[+].url = $SDCTemplateExtractValue
* period.start.extension[=].valueString = "%resource.authored"
* period.end = "2026-01-01"
* period.end.extension[+].url = $SDCTemplateExtractValue
* period.end.extension[=].valueString = "%resource.authored"
* reporter.display = "recorder"
* reporter.display.extension[+].url = $SDCTemplateExtractValue
* reporter.display.extension[=].valueString = "%resource.repeat(item).where(linkId='p_recorder_id').answer.value.first()"
* group[0].code = $ATC#J01FA10 "azithromycin"
* group[0].code.text = "azithromycin (tablets)"
* group[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].population[0].count = 0
* group[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='azm_tb_more7_boy_treated').answer.exists(), %resource.repeat(item).where(linkId='azm_tb_more7_boy_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='azm_tb_more7_girl_treated').answer.exists(), %resource.repeat(item).where(linkId='azm_tb_more7_girl_treated').answer.value.first(), 0)"
* group[0].population[1].code = $MeasurePopulation#denominator "Denominator"
* group[0].population[1].count = 0
* group[0].population[1].count.extension[+].url = $SDCTemplateExtractValue
* group[0].population[1].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='census_men').answer.exists(), %resource.repeat(item).where(linkId='census_men').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='census_women').answer.exists(), %resource.repeat(item).where(linkId='census_women').answer.value.first(), 0)"
* group[0].measureScore.value = 0
* group[0].measureScore.value.extension[+].url = $SDCTemplateExtractValue
* group[0].measureScore.value.extension[=].valueString = "iif((iif(%resource.repeat(item).where(linkId='census_men').answer.exists(), %resource.repeat(item).where(linkId='census_men').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='census_women').answer.exists(), %resource.repeat(item).where(linkId='census_women').answer.value.first(), 0)) > 0, (iif(%resource.repeat(item).where(linkId='azm_tb_more7_boy_treated').answer.exists(), %resource.repeat(item).where(linkId='azm_tb_more7_boy_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='azm_tb_more7_girl_treated').answer.exists(), %resource.repeat(item).where(linkId='azm_tb_more7_girl_treated').answer.value.first(), 0)) * 100 / (iif(%resource.repeat(item).where(linkId='census_men').answer.exists(), %resource.repeat(item).where(linkId='census_men').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='census_women').answer.exists(), %resource.repeat(item).where(linkId='census_women').answer.value.first(), 0)), 0)"
// sex stratifier
* group[0].stratifier[0].code = $CoverageStratifier#sex "Sex"
* group[0].stratifier[0].stratum[0].value.text = "female"
* group[0].stratifier[0].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[0].stratum[0].population[0].count = 0
* group[0].stratifier[0].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[0].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='azm_tb_more7_girl_treated').answer.exists(), %resource.repeat(item).where(linkId='azm_tb_more7_girl_treated').answer.value.first(), 0)"
* group[0].stratifier[0].stratum[1].value.text = "male"
* group[0].stratifier[0].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[0].stratum[1].population[0].count = 0
* group[0].stratifier[0].stratum[1].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[0].stratum[1].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='azm_tb_more7_boy_treated').answer.exists(), %resource.repeat(item).where(linkId='azm_tb_more7_boy_treated').answer.value.first(), 0)"
// age-band stratifier (single band — this block only covers 7+ years)
* group[0].stratifier[1].code = $CoverageStratifier#age-band "Age band"
* group[0].stratifier[1].stratum[0].value.text = "7+ years"
* group[0].stratifier[1].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[1].stratum[0].population[0].count = 0
* group[0].stratifier[1].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[1].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='azm_tb_more7_boy_treated').answer.exists(), %resource.repeat(item).where(linkId='azm_tb_more7_boy_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='azm_tb_more7_girl_treated').answer.exists(), %resource.repeat(item).where(linkId='azm_tb_more7_girl_treated').answer.value.first(), 0)"
// disposition stratifier — azm_tb_child is an untreated count (NOT part of the
// numerator, despite living in the by_sex group in the source form)
* group[0].stratifier[2].code = $CoverageStratifier#disposition "Disposition"
* group[0].stratifier[2].stratum[0].value.text = "treated"
* group[0].stratifier[2].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[0].population[0].count = 0
* group[0].stratifier[2].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='azm_tb_more7_boy_treated').answer.exists(), %resource.repeat(item).where(linkId='azm_tb_more7_boy_treated').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='azm_tb_more7_girl_treated').answer.exists(), %resource.repeat(item).where(linkId='azm_tb_more7_girl_treated').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[1].value.text = "excluded - under height/age"
* group[0].stratifier[2].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[1].population[0].count = 0
* group[0].stratifier[2].stratum[1].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[1].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='azm_tb_child').answer.exists(), %resource.repeat(item).where(linkId='azm_tb_child').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[2].value.text = "excluded - pregnant"
* group[0].stratifier[2].stratum[2].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[2].population[0].count = 0
* group[0].stratifier[2].stratum[2].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[2].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='azm_tb_pregnant').answer.exists(), %resource.repeat(item).where(linkId='azm_tb_pregnant').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[3].value.text = "excluded - breastfeeding"
* group[0].stratifier[2].stratum[3].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[3].population[0].count = 0
* group[0].stratifier[2].stratum[3].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[3].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='azm_tb_breastfeeding').answer.exists(), %resource.repeat(item).where(linkId='azm_tb_breastfeeding').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[4].value.text = "absent"
* group[0].stratifier[2].stratum[4].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[4].population[0].count = 0
* group[0].stratifier[2].stratum[4].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[4].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='azm_tb_absent').answer.exists(), %resource.repeat(item).where(linkId='azm_tb_absent').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[5].value.text = "refused"
* group[0].stratifier[2].stratum[5].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[5].population[0].count = 0
* group[0].stratifier[2].stratum[5].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[5].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='azm_tb_refusal').answer.exists(), %resource.repeat(item).where(linkId='azm_tb_refusal').answer.value.first(), 0)"

// tetra: pregnant women are a treated category in the source form (eye ointment is safe
// in pregnancy); counted in numerator and female stratum, outside the age-band axis

Instance: EspenMRTetra
InstanceOf: MeasureReport
Usage: #inline
* id = "mr-tetra"
* meta.profile = "https://icr.healthcampaigns.org/StructureDefinition/ICRAdministrativeCoverage"
* status = #complete
* type = #summary
* measure = "https://icr.healthcampaigns.org/Measure/icr-mda-treatment-coverage"
* extension[0].url = "https://icr.healthcampaigns.org/StructureDefinition/coverage-source"
* extension[0].valueCode = #administrative
* extension[1].url = "https://icr.healthcampaigns.org/StructureDefinition/realtime-vs-reconciled"
* extension[1].valueCode = #realtime
* period.start = "2026-01-01"
* period.start.extension[+].url = $SDCTemplateExtractValue
* period.start.extension[=].valueString = "%resource.authored"
* period.end = "2026-01-01"
* period.end.extension[+].url = $SDCTemplateExtractValue
* period.end.extension[=].valueString = "%resource.authored"
* reporter.display = "recorder"
* reporter.display.extension[+].url = $SDCTemplateExtractValue
* reporter.display.extension[=].valueString = "%resource.repeat(item).where(linkId='p_recorder_id').answer.value.first()"
* group[0].code = $ATC#S01AA09 "tetracycline"
* group[0].code.text = "tetracycline (eye ointment)"
* group[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].population[0].count = 0
* group[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='tetra_baby_boy').answer.exists(), %resource.repeat(item).where(linkId='tetra_baby_boy').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='tetra_baby_girl').answer.exists(), %resource.repeat(item).where(linkId='tetra_baby_girl').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='tetra_pregnant_women').answer.exists(), %resource.repeat(item).where(linkId='tetra_pregnant_women').answer.value.first(), 0)"
* group[0].population[1].code = $MeasurePopulation#denominator "Denominator"
* group[0].population[1].count = 0
* group[0].population[1].count.extension[+].url = $SDCTemplateExtractValue
* group[0].population[1].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='census_men').answer.exists(), %resource.repeat(item).where(linkId='census_men').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='census_women').answer.exists(), %resource.repeat(item).where(linkId='census_women').answer.value.first(), 0)"
* group[0].measureScore.value = 0
* group[0].measureScore.value.extension[+].url = $SDCTemplateExtractValue
* group[0].measureScore.value.extension[=].valueString = "iif((iif(%resource.repeat(item).where(linkId='census_men').answer.exists(), %resource.repeat(item).where(linkId='census_men').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='census_women').answer.exists(), %resource.repeat(item).where(linkId='census_women').answer.value.first(), 0)) > 0, (iif(%resource.repeat(item).where(linkId='tetra_baby_boy').answer.exists(), %resource.repeat(item).where(linkId='tetra_baby_boy').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='tetra_baby_girl').answer.exists(), %resource.repeat(item).where(linkId='tetra_baby_girl').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='tetra_pregnant_women').answer.exists(), %resource.repeat(item).where(linkId='tetra_pregnant_women').answer.value.first(), 0)) * 100 / (iif(%resource.repeat(item).where(linkId='census_men').answer.exists(), %resource.repeat(item).where(linkId='census_men').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='census_women').answer.exists(), %resource.repeat(item).where(linkId='census_women').answer.value.first(), 0)), 0)"
// sex stratifier
* group[0].stratifier[0].code = $CoverageStratifier#sex "Sex"
* group[0].stratifier[0].stratum[0].value.text = "female"
* group[0].stratifier[0].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[0].stratum[0].population[0].count = 0
* group[0].stratifier[0].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[0].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='tetra_baby_girl').answer.exists(), %resource.repeat(item).where(linkId='tetra_baby_girl').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='tetra_pregnant_women').answer.exists(), %resource.repeat(item).where(linkId='tetra_pregnant_women').answer.value.first(), 0)"
* group[0].stratifier[0].stratum[1].value.text = "male"
* group[0].stratifier[0].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[0].stratum[1].population[0].count = 0
* group[0].stratifier[0].stratum[1].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[0].stratum[1].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='tetra_baby_boy').answer.exists(), %resource.repeat(item).where(linkId='tetra_baby_boy').answer.value.first(), 0)"
// age-band stratifier (single band — pregnant women intentionally outside this axis)
* group[0].stratifier[1].code = $CoverageStratifier#age-band "Age band"
* group[0].stratifier[1].stratum[0].value.text = "<6 months"
* group[0].stratifier[1].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[1].stratum[0].population[0].count = 0
* group[0].stratifier[1].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[1].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='tetra_baby_boy').answer.exists(), %resource.repeat(item).where(linkId='tetra_baby_boy').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='tetra_baby_girl').answer.exists(), %resource.repeat(item).where(linkId='tetra_baby_girl').answer.value.first(), 0)"
// disposition stratifier — one stratum per reason item + treated
* group[0].stratifier[2].code = $CoverageStratifier#disposition "Disposition"
* group[0].stratifier[2].stratum[0].value.text = "treated"
* group[0].stratifier[2].stratum[0].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[0].population[0].count = 0
* group[0].stratifier[2].stratum[0].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[0].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='tetra_baby_boy').answer.exists(), %resource.repeat(item).where(linkId='tetra_baby_boy').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='tetra_baby_girl').answer.exists(), %resource.repeat(item).where(linkId='tetra_baby_girl').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='tetra_pregnant_women').answer.exists(), %resource.repeat(item).where(linkId='tetra_pregnant_women').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[1].value.text = "excluded - under height/age"
* group[0].stratifier[2].stratum[1].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[1].population[0].count = 0
* group[0].stratifier[2].stratum[1].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[1].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='tetra_child').answer.exists(), %resource.repeat(item).where(linkId='tetra_child').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[2].value.text = "excluded - pregnant"
* group[0].stratifier[2].stratum[2].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[2].population[0].count = 0
* group[0].stratifier[2].stratum[2].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[2].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='tetra_pregnant').answer.exists(), %resource.repeat(item).where(linkId='tetra_pregnant').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[3].value.text = "excluded - breastfeeding"
* group[0].stratifier[2].stratum[3].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[3].population[0].count = 0
* group[0].stratifier[2].stratum[3].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[3].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='tetra_breastfeeding').answer.exists(), %resource.repeat(item).where(linkId='tetra_breastfeeding').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[4].value.text = "absent"
* group[0].stratifier[2].stratum[4].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[4].population[0].count = 0
* group[0].stratifier[2].stratum[4].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[4].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='tetra_absent').answer.exists(), %resource.repeat(item).where(linkId='tetra_absent').answer.value.first(), 0)"
* group[0].stratifier[2].stratum[5].value.text = "refused"
* group[0].stratifier[2].stratum[5].population[0].code = $MeasurePopulation#numerator "Numerator"
* group[0].stratifier[2].stratum[5].population[0].count = 0
* group[0].stratifier[2].stratum[5].population[0].count.extension[+].url = $SDCTemplateExtractValue
* group[0].stratifier[2].stratum[5].population[0].count.extension[=].valueString = "iif(%resource.repeat(item).where(linkId='tetra_refusal').answer.exists(), %resource.repeat(item).where(linkId='tetra_refusal').answer.value.first(), 0)"

// --- Form 4: MDA Medicine Use & Case Management -------------------------------
// No extraction (espen-remap): distributed totals are not custody transfers, so no
// SupplyDelivery is minted — the treatment events are Form 3's Group-subject
// MedicationAdministrations, and the distributed counts fold into the Form 2
// receipt's stock-accountability in the transform layer (a cross-form merge
// extraction cannot express). Side-effect and other-NTD counts remain QR-only —
// person-level ICRAdverseEvent records cannot be minted from aggregate counts.

Instance: espen-mda-case-management
InstanceOf: Questionnaire
Title: "ESPEN MDA — 4. Medicine Use & Case Management Form"
Usage: #example
* url = "https://icr.healthcampaigns.org/Questionnaire/espen-mda-case-management"
* meta.tag = $ProjectTag#espen "ESPEN"
* name = "EspenMDACaseManagement"
* status = #active
* experimental = false
* description = "ESPEN MDA demo Form 4 (medicine use and case management): per-drug distributed totals, side-effect counts, other-NTD case counts. No template-based extraction (espen-remap): a distributed total is not a custody transfer, so it does not mint a SupplyDelivery — the treatment events are Form 3's Group-subject ICRMedicationAdministrations, and the distributed counts are folded into the stock-accountability extension on the Form 2 receipt ICRSupplyMovement by the ingestion pipeline (a cross-form merge extraction cannot express). Side-effect and other-NTD counts remain on the QuestionnaireResponse: person-level ICRAdverseEvent records cannot be minted from aggregate counts."
* subjectType = #Location
// registry cascade: choices are deployment entity data (bind::db_*) — in ICR these
// resolve against the Location hierarchy / CareTeam registry at capture time
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
* item[=].text = "Disease covered by the TDM"
* item[=].type = #choice
* item[=].repeats = true
* item[=].required = true
* item[=].answerValueSet = Canonical(ICRNTDDiseaseVS)
* item[+].linkId = "p_medicine"
* item[=].text = "Select the medcine package"
* item[=].type = #choice
* item[=].repeats = true
* item[=].required = true
* item[=].answerValueSet = Canonical(ICRMDAMedicinePackageVS)
// combination-validity constraint enforced at the capture layer; not carried over
* item[+].linkId = "med_distr"
* item[=].text = "Medicines Distributed"
* item[=].type = #group
* item[=].item[+].linkId = "p_total_pzq_dist"
* item[=].item[=].text = "Total Praziquantel distributed"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[=].enableWhen[+].question = "p_medicine"
* item[=].item[=].enableWhen[=].operator = #=
* item[=].item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#pzq
* item[=].item[=].enableWhen[+].question = "p_medicine"
* item[=].item[=].enableWhen[=].operator = #=
* item[=].item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#pzq-alb
* item[=].item[=].enableWhen[+].question = "p_medicine"
* item[=].item[=].enableWhen[=].operator = #=
* item[=].item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#pzq-meb
* item[=].item[=].enableBehavior = #any
* item[=].item[+].linkId = "p_total_alb_dist"
* item[=].item[=].text = "Total Albendazole distributed"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[=].enableWhen[+].question = "p_medicine"
* item[=].item[=].enableWhen[=].operator = #=
* item[=].item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#alb
* item[=].item[=].enableWhen[+].question = "p_medicine"
* item[=].item[=].enableWhen[=].operator = #=
* item[=].item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#ivm-alb
* item[=].item[=].enableWhen[+].question = "p_medicine"
* item[=].item[=].enableWhen[=].operator = #=
* item[=].item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#ivm-alb-dec
* item[=].item[=].enableWhen[+].question = "p_medicine"
* item[=].item[=].enableWhen[=].operator = #=
* item[=].item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#pzq-alb
* item[=].item[=].enableBehavior = #any
* item[=].item[+].linkId = "p_total_meb_dist"
* item[=].item[=].text = "Total Mebendazole distributed"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[=].enableWhen[+].question = "p_medicine"
* item[=].item[=].enableWhen[=].operator = #=
* item[=].item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#meb
* item[=].item[=].enableWhen[+].question = "p_medicine"
* item[=].item[=].enableWhen[=].operator = #=
* item[=].item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#pzq-meb
* item[=].item[=].enableBehavior = #any
* item[=].item[+].linkId = "p_total_ivm_dist"
* item[=].item[=].text = "Total Ivermectin distributed"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[=].enableWhen[+].question = "p_medicine"
* item[=].item[=].enableWhen[=].operator = #=
* item[=].item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#ivm
* item[=].item[=].enableWhen[+].question = "p_medicine"
* item[=].item[=].enableWhen[=].operator = #=
* item[=].item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#ivm-alb
* item[=].item[=].enableWhen[+].question = "p_medicine"
* item[=].item[=].enableWhen[=].operator = #=
* item[=].item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#ivm-alb-dec
* item[=].item[=].enableBehavior = #any
* item[=].item[+].linkId = "p_total_dec_dist"
* item[=].item[=].text = "Total Diethylcarbamazine distributed"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[=].enableWhen[+].question = "p_medicine"
* item[=].item[=].enableWhen[=].operator = #=
* item[=].item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#ivm-alb-dec
* item[=].item[+].linkId = "p_total_az_sus_dist"
* item[=].item[=].text = "Total Azithromycin suspension (in l) distributed"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[=].enableWhen[+].question = "p_medicine"
* item[=].item[=].enableWhen[=].operator = #=
* item[=].item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#azm-susp
* item[=].item[+].linkId = "p_total_az_tab_dist"
* item[=].item[=].text = "Total Azithromycin tablets distributed"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[=].enableWhen[+].question = "p_medicine"
* item[=].item[=].enableWhen[=].operator = #=
* item[=].item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#azm-tab
* item[=].item[+].linkId = "p_total_tetra_dist"
* item[=].item[=].text = "Total Tetracycline distributed"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[=].enableWhen[+].question = "p_medicine"
* item[=].item[=].enableWhen[=].operator = #=
* item[=].item[=].enableWhen[=].answerCoding = ICRMDAMedicinePackageCS#tetra
* item[=].item[+].linkId = "p_minor_side_effect"
* item[=].item[=].text = "Number of cases of minor side effects"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "p_serious_side_effect"
* item[=].item[=].text = "Number of cases of serious side effects"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[+].linkId = "other_ntd_rep"
* item[=].text = "Cases of other NTDs identified"
* item[=].type = #group
* item[=].item[+].linkId = "p_guinea_worm_rumor"
* item[=].item[=].text = "Number of Guinea Worm rumors"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "p_leish_suspect"
* item[=].item[=].text = "Number of suspected cases of Leishmaniasis"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "p_buruli_ulcer_suspect"
* item[=].item[=].text = "Number of suspected cases of Buruli ulcer"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "p_Lymphoedema_LF"
* item[=].item[=].text = "Number of cases with LF lymphoedema"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "P_hydrocele_LF"
* item[=].item[=].text = "Number of cases with LF Hydrocele"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[+].linkId = "p_add_note"
* item[=].text = "Additional Note"
* item[=].type = #text
// dropped: p_start / p_end (device timestamps)

// --- Form 5: MDA Supervision — Health Facility --------------------------------
// No extraction templates, by design: this is a supervision report, not a stock
// or coverage event — the QuestionnaireResponse itself is the record
// (an ICRCampaignFormResponse, working doc §4.6).

Instance: espen-mda-supervision-hf
InstanceOf: Questionnaire
Title: "ESPEN MDA — 5. Supervision: Health Facility"
Usage: #example
* url = "https://icr.healthcampaigns.org/Questionnaire/espen-mda-supervision-hf"
* meta.tag = $ProjectTag#espen "ESPEN"
* name = "EspenMDASupervisionHF"
* status = #active
* experimental = false
* description = "ESPEN MDA demo Form 5 (supervision at health facility): geographic coverage of villages treated, per-drug stock triplets (remaining/expired/concordance), distributor training, social mobilization, supervision area, pharmacovigilance, and free-text challenges/solutions/recommendations. No extraction templates: per the campaign-form pattern (ICRCampaignFormResponse, working doc §4.6) the QuestionnaireResponse itself is the supervision record."
* subjectType = #Location
// registry cascade: choices are deployment entity data (bind::db_*) — in ICR these
// resolve against the Location hierarchy / CareTeam registry at capture time
* item[+].linkId = "s_recorder_id"
* item[=].text = "Select the recorder ID"
* item[=].type = #string
* item[+].linkId = "s_state"
* item[=].text = "Select region"
* item[=].type = #string
* item[=].required = true
* item[+].linkId = "s_district"
* item[=].text = "Select district"
* item[=].type = #string
* item[=].required = true
* item[+].linkId = "s_health_facility"
* item[=].text = "Health facility"
* item[=].type = #string
* item[=].required = true
* item[+].linkId = "s_location"
* item[=].text = "Village"
* item[=].type = #string
* item[=].required = true
// stable domain list (National/Regional/District/Partner/Health facility), not a
// registry cascade — inline choice options
* item[+].linkId = "s_supervisor_Level"
* item[=].text = "Supervisor level"
* item[=].type = #choice
* item[=].required = true
* item[=].answerOption[+].valueString = "National"
* item[=].answerOption[+].valueString = "Regional"
* item[=].answerOption[+].valueString = "District"
* item[=].answerOption[+].valueString = "Partner"
* item[=].answerOption[+].valueString = "Health facility"
* item[+].linkId = "s_date_start"
* item[=].text = "Campaign start date"
* item[=].type = #date
* item[=].required = true
* item[+].linkId = "s_date_end"
* item[=].text = "Campaign end date"
* item[=].type = #date
* item[=].required = true
* item[+].linkId = "s_disease"
* item[=].text = "Disease covered by the MDA"
* item[=].type = #choice
* item[=].repeats = true
* item[=].required = true
* item[=].answerValueSet = Canonical(ICRNTDDiseaseVS)
* item[+].linkId = "s_medicine"
* item[=].text = "Select the medicine package"
* item[=].type = #choice
* item[=].repeats = true
* item[=].required = true
* item[=].answerValueSet = Canonical(ICRMDAMedicinePackageVS)
// combination-validity constraint enforced at the capture layer; not carried over
* item[+].linkId = "location"
* item[=].text = "Geographic coverage"
* item[=].type = #group
* item[=].item[+].linkId = "s_nb_villages_total"
* item[=].item[=].text = "Total number of villages"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_nb_villages_treated"
* item[=].item[=].text = "Number of villages treated"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_nb_villages_non_treated"
* item[=].item[=].text = "Number of villages not treated"
* item[=].item[=].type = #integer
* item[=].item[+].linkId = "s_reason_non_treatment"
* item[=].item[=].text = "Reasons for non-treatment"
* item[=].item[=].type = #choice
* item[=].item[=].repeats = true
* item[=].item[=].enableWhen[+].question = "s_nb_villages_non_treated"
* item[=].item[=].enableWhen[=].operator = #>
* item[=].item[=].enableWhen[=].answerInteger = 0
* item[=].item[=].answerOption[+].valueCoding = ICRMissedReasonCS#not-visited "Absence of DC"
* item[=].item[=].answerOption[+].valueCoding = ICRMissedReasonCS#refusal "Population refusal"
* item[=].item[=].answerOption[+].valueCoding = ICRMissedReasonCS#medication-shortage "Medication shortage"
* item[=].item[=].answerOption[+].valueCoding = ICRMissedReasonCS#insecurity "Insecurity"
* item[=].item[=].answerOption[+].valueCoding = ICRMissedReasonCS#difficult-access "Difficult access"
* item[=].item[=].answerOption[+].valueCoding = ICRMissedReasonCS#not-required "Not required"
// per-drug stock triplets: the source form has no `relevant` on these groups
// (unlike Forms 2-4's medicine-gated blocks) — converted without enableWhen, faithful
* item[+].linkId = "logistic_ivm"
* item[=].text = "Ivermectine Medication Management"
* item[=].type = #group
* item[=].item[+].linkId = "s_stock_remain_ivm"
* item[=].item[=].text = "Is there any Ivermectine remaining stock?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_stock_expired_ivm"
* item[=].item[=].text = "Are there any expired Ivermectine medications?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_stock_concordance_ivm"
* item[=].item[=].text = "Does the physical stock of Ivermectine match the theoretical stock?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[+].linkId = "logistic_alb"
* item[=].text = "Albendazole Medication Management"
* item[=].type = #group
* item[=].item[+].linkId = "s_stock_remain_alb"
* item[=].item[=].text = "Is there any Albendazole remaining stock?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_stock_expired_alb"
* item[=].item[=].text = "Are there any expired Albendazole medications?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_stock_concordance_alb"
* item[=].item[=].text = "Does the physical stock of Albendazole match the theoretical stock?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[+].linkId = "logistic_meb"
* item[=].text = "Mebendazole Medication Management"
* item[=].type = #group
* item[=].item[+].linkId = "s_stock_remain_meb"
* item[=].item[=].text = "Is there any Mebendazole remaining stock?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_stock_expired_meb"
* item[=].item[=].text = "Are there any expired Mebendazole medications?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_stock_concordance_meb"
* item[=].item[=].text = "Does the physical stock of Mebendazole match the theoretical stock?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[+].linkId = "logistic_dec"
* item[=].text = "Diethylcarbamazine Medication Management"
* item[=].type = #group
* item[=].item[+].linkId = "s_stock_remain_dec"
* item[=].item[=].text = "Is there any Diethylcarbamazine remaining stock?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_stock_expired_dec"
* item[=].item[=].text = "Are there any expired Diethylcarbamazine medications?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_stock_concordance_dec"
* item[=].item[=].text = "Does the physical stock of Diethylcarbamazine match the theoretical stock?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[+].linkId = "logistic_pzq"
* item[=].text = "Praziquantel Medication Management"
* item[=].type = #group
* item[=].item[+].linkId = "s_stock_remain_pzq"
* item[=].item[=].text = "Is there any Praziquantel remaining stock?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_stock_expired_pzq"
* item[=].item[=].text = "Are there any Praziquantel expired medications?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_stock_concordance_pzq"
* item[=].item[=].text = "Does the physical stock of Praziquantel match the theoretical stock?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[+].linkId = "logistic_az_sus"
* item[=].text = "Azytromicine Suspension Medication Management"
* item[=].type = #group
* item[=].item[+].linkId = "s_stock_remain_az_sus"
* item[=].item[=].text = "Is there any remaining stock of Azytromicine Suspension?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_stock_expired_az_sus"
* item[=].item[=].text = "Are there any expired Azytromicine suspension?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_stock_concordance_az_sus"
* item[=].item[=].text = "Does the physical stock of Azytromicine suspension match the theoretical stock?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[+].linkId = "logistic_az_tab"
* item[=].text = "Azytromicine tablet Medication Management"
* item[=].type = #group
* item[=].item[+].linkId = "s_stock_remain_az_tab"
* item[=].item[=].text = "Is there any remaining stock of Azytromicine tablet?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_stock_expired_az_tab"
* item[=].item[=].text = "Are there any expired medications of Azytromicine tablet?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_stock_concordance_az_tab"
* item[=].item[=].text = "Does the physical stock of Azytromicine tablet match the theoretical stock?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[+].linkId = "logistic_tetra"
* item[=].text = "Medication Management"
* item[=].type = #group
* item[=].item[+].linkId = "s_stock_remain_tetra"
* item[=].item[=].text = "Is there any remaining stock?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_stock_expired_tetra"
* item[=].item[=].text = "Are there any expired medications?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_stock_concordance_tetra"
* item[=].item[=].text = "Does the physical stock match the theoretical stock?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[+].linkId = "s_training"
* item[=].text = "Distributor training"
* item[=].type = #group
* item[=].item[+].linkId = "s_dc_trained_h"
* item[=].item[=].text = "Number of male distributors trained"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_dc_trained_f"
* item[=].item[=].text = "Number of female distributors trained"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_manual_used"
* item[=].item[=].text = "Distributor manual used?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[+].linkId = "s_mobilisation"
* item[=].text = "Social Mobilisation"
* item[=].type = #group
* item[=].item[+].linkId = "s_population_informed"
* item[=].item[=].text = "Was the population informed before the campaign?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_chanel_utilises"
* item[=].item[=].text = "Communication channels used"
* item[=].item[=].type = #choice
* item[=].item[=].repeats = true
* item[=].item[=].required = true
* item[=].item[=].answerOption[+].valueCoding = ICRCommunicationChannelCS#radio "Radio"
* item[=].item[=].answerOption[+].valueCoding = ICRCommunicationChannelCS#town-criers "Town criers"
* item[=].item[=].answerOption[+].valueCoding = ICRCommunicationChannelCS#community-leaders "Community leaders"
* item[=].item[=].answerOption[+].valueCoding = ICRCommunicationChannelCS#schools "Schools"
* item[=].item[=].answerOption[+].valueCoding = ICRCommunicationChannelCS#posters "Posters"
* item[+].linkId = "s_supervision"
* item[=].text = "Area of supervision"
* item[=].type = #group
* item[=].item[+].linkId = "s_dc_supervised"
* item[=].item[=].text = "Number of distributors supervised"
* item[=].item[=].type = #integer
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_villages_supervised"
* item[=].item[=].text = "Number of villages supervised"
* item[=].item[=].type = #integer
* item[+].linkId = "s_pharmacovigilance"
* item[=].text = "Pharmacovigilance"
* item[=].type = #group
* item[=].item[+].linkId = "s_side_effect"
* item[=].item[=].text = "Were any adverse effects reported?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_sever_side_effect"
* item[=].item[=].text = "Were any serious adverse effects reported?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[+].linkId = "s_difficultes"
* item[=].text = "Challenges encountered"
* item[=].type = #text
* item[+].linkId = "s_solutions"
* item[=].text = "Proposed solutions"
* item[=].type = #text
* item[+].linkId = "s_recommandations"
* item[=].text = "Supervisor recommendations"
* item[=].type = #text
// dropped: start / end (device timestamps)

// --- Form 6: MDA Supervision — CDD Observation --------------------------------
// No extraction templates, by design: this is a supervision report, not a stock
// or coverage event — the QuestionnaireResponse itself is the record
// (an ICRCampaignFormResponse, working doc §4.6).

Instance: espen-mda-supervision-cdd
InstanceOf: Questionnaire
Title: "ESPEN MDA — 6. Supervision: CDD Observation"
Usage: #example
* url = "https://icr.healthcampaigns.org/Questionnaire/espen-mda-supervision-cdd"
* meta.tag = $ProjectTag#espen "ESPEN"
* name = "EspenMDASupervisionCDD"
* status = #active
* experimental = false
* description = "ESPEN MDA demo Form 6 (CDD observation supervision): direct observation of a community drug distributor's technique and attitude during treatment, MDA-supplies availability, CDD training coverage, and free-text challenges/solutions/recommendations. No extraction templates: per the campaign-form pattern (ICRCampaignFormResponse, working doc §4.6) the QuestionnaireResponse itself is the supervision record."
* subjectType = #Location
// stable domain list (National/Regional/Partner/District/Health Facility), not a
// registry cascade — inline choice options
* item[+].linkId = "s_supervisor"
* item[=].text = "Supervisor Team"
* item[=].type = #choice
* item[=].answerOption[+].valueString = "National"
* item[=].answerOption[+].valueString = "Regional"
* item[=].answerOption[+].valueString = "Partner"
* item[=].answerOption[+].valueString = "District"
* item[=].answerOption[+].valueString = "Health Facility"
// registry cascade: choices are deployment entity data (bind::db_*) — in ICR these
// resolve against the Location hierarchy / CareTeam registry at capture time
* item[+].linkId = "s_state"
* item[=].text = "Select region"
* item[=].type = #string
* item[=].required = true
* item[+].linkId = "s_district"
* item[=].text = "Select district"
* item[=].type = #string
* item[=].required = true
* item[+].linkId = "s_health_facility"
* item[=].text = "Health facility"
* item[=].type = #string
* item[=].required = true
* item[+].linkId = "s_location"
* item[=].text = "Village"
* item[=].type = #string
* item[=].required = true
* item[+].linkId = "s_date_start"
* item[=].text = "Campaign start date"
* item[=].type = #date
* item[=].required = true
* item[+].linkId = "s_date_end"
* item[=].text = "Campaign end date"
* item[=].type = #date
* item[=].required = true
* item[+].linkId = "s_disease"
* item[=].text = "Disease covered by the MDA"
* item[=].type = #choice
* item[=].repeats = true
* item[=].required = true
* item[=].answerValueSet = Canonical(ICRNTDDiseaseVS)
* item[+].linkId = "s_medicine"
* item[=].text = "Select the medicine package"
* item[=].type = #choice
* item[=].repeats = true
* item[=].required = true
* item[=].answerValueSet = Canonical(ICRMDAMedicinePackageVS)
// combination-validity constraint enforced at the capture layer; not carried over
* item[+].linkId = "s_medicine_sufficient"
* item[=].text = "Do the distributors have the medications in sufficient quantities?"
* item[=].type = #boolean
* item[=].required = true
* item[+].linkId = "s_total_dist_trained_male"
* item[=].text = "Total Distributor Male Trained for the campagne"
* item[=].type = #integer
* item[=].required = true
* item[+].linkId = "s_total_dist_trained_female"
* item[=].text = "Total Distributor Female Trained for the campagne"
* item[=].type = #integer
* item[+].linkId = "s_total_dist"
* item[=].text = "Total Distributor Trained"
* item[=].type = #integer
* item[=].readOnly = true
* item[=].extension[+].url = $QHidden
* item[=].extension[=].valueBoolean = true
* item[=].extension[+].url = $SDCCalculatedExpression
* item[=].extension[=].valueExpression.language = #text/fhirpath
* item[=].extension[=].valueExpression.expression = "iif(%resource.repeat(item).where(linkId='s_total_dist_trained_male').answer.exists(), %resource.repeat(item).where(linkId='s_total_dist_trained_male').answer.value.first(), 0) + iif(%resource.repeat(item).where(linkId='s_total_dist_trained_female').answer.exists(), %resource.repeat(item).where(linkId='s_total_dist_trained_female').answer.value.first(), 0)"
* item[+].linkId = "MDA_supplies"
* item[=].text = "Avaialability of MDA supplies"
* item[=].type = #group
* item[=].item[+].linkId = "s_hieght_chart"
* item[=].item[=].text = "Height chart"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_register"
* item[=].item[=].text = "Register"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_records_checklist"
* item[=].item[=].text = "Records/checklist"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_med_bag"
* item[=].item[=].text = "The CDD uses a medication bag"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[+].linkId = "attitude_CDD"
* item[=].text = "Observe the actions, attitudes, and skills of the community health worker during the treatment of a family"
* item[=].type = #group
* item[=].item[+].linkId = "attitude_CDD-hint"
* item[=].item[=].text = "wearing a vest, wearing a mask, using hand sanitizer, standard greetings - introduction -, administering medication, data collection"
* item[=].item[=].type = #display
* item[=].item[+].linkId = "s_wear_vest"
* item[=].item[=].text = "Is the community health worker/healthcare worker team identifiable by a vest?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_usual_greetings"
* item[=].item[=].text = "The CDD proceeds with the usual greetings"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_introduced_patient"
* item[=].item[=].text = "The CDD  introduces the patient by specifying the reason for their visit and the treatment being administered."
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_used_height_chart_correctly"
* item[=].item[=].text = "The CDD  uses the height chart correctly."
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_gave_write_dosage"
* item[=].item[=].text = "The CDD  administers the medication correctly according to the height chart reading."
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_medicine_took_in_front_of_dc"
* item[=].item[=].text = "The medicine is taken in the presence of the DC"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_filled_form"
* item[=].item[=].text = "Does the CDD complete the data collection forms (checklist and register) correctly?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_investigated_cases"
* item[=].item[=].text = "Does the CDD investigate and report cases of FL, Buruli ulcer, leishmaniasis and rumours of VG?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_identified_ineligible"
* item[=].item[=].text = "Are ineligible individuals identified?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[=].item[+].linkId = "s_follow_side_effect_procedure"
* item[=].item[=].text = "Is the procedure to follow in the event of side events known?"
* item[=].item[=].type = #boolean
* item[=].item[=].required = true
* item[+].linkId = "s_date_training"
* item[=].text = "Date of training session"
* item[=].type = #date
* item[=].required = true
* item[+].linkId = "s_traning_duration"
* item[=].text = "Duration of training session (in days)"
* item[=].type = #integer
* item[=].required = true
* item[=].item[+].linkId = "s_traning_duration-hint"
* item[=].item[=].text = "In days"
* item[=].item[=].type = #display
* item[+].linkId = "s_training_topic"
* item[=].text = "What topics were covered during the training?"
* item[=].type = #choice
* item[=].repeats = true
* item[=].required = true
* item[=].answerOption[+].valueString = "Using the measuring stick"
* item[=].answerOption[+].valueString = "Completing the checklists"
* item[=].answerOption[+].valueString = "Supervised taking"
* item[=].answerOption[+].valueString = "Marking concessions"
* item[=].answerOption[+].valueString = "Monitoring refusals"
* item[=].answerOption[+].valueString = "Revisit"
* item[=].answerOption[+].valueString = "Practical exercise"
* item[=].answerOption[+].valueString = "Interpersonal communication"
* item[=].answerOption[+].valueString = "Other"
* item[+].linkId = "s_took_med_in_training"
* item[=].text = "Did you take the medication during the training?"
* item[=].type = #boolean
* item[=].required = true
* item[+].linkId = "s_complete_form"
* item[=].text = "Does the CDD complete the data collection forms (checklist and register) correctly?"
* item[=].type = #boolean
* item[=].required = true
* item[+].linkId = "s_case_mngt"
* item[=].text = "Does the CDD investigate and report cases of FL, Buruli ulcer, leishmaniasis and rumours of VG?"
* item[=].type = #boolean
* item[=].required = true
* item[+].linkId = "s_has_inegidible"
* item[=].text = "Are ineligible individuals identified?"
* item[=].type = #boolean
* item[=].required = true
* item[+].linkId = "s_follow_side_effect"
* item[=].text = "Is the procedure to follow in the event of adverse events known?"
* item[=].type = #boolean
* item[=].required = true
* item[+].linkId = "s_difficultes"
* item[=].text = "Challenges encountered"
* item[=].type = #text
* item[+].linkId = "s_solutions"
* item[=].text = "Proposed solutions"
* item[=].type = #text
* item[+].linkId = "s_recommandations"
* item[=].text = "Supervisor recommendations"
* item[=].type = #text
// dropped: start / end (device timestamps)
