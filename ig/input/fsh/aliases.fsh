// Aliases — external code systems and value sets used across the IG
Alias: $CVX = http://hl7.org/fhir/sid/cvx
Alias: $MeasurePopulation = http://terminology.hl7.org/CodeSystem/measure-population
Alias: $ATC = http://www.whocc.no/atc
Alias: $VaccineCodeVS = http://hl7.org/fhir/ValueSet/vaccine-code
Alias: $LOINC = http://loinc.org
Alias: $ConsentScope = http://terminology.hl7.org/CodeSystem/consentscope
Alias: $MeasureScoring = http://terminology.hl7.org/CodeSystem/measure-scoring
Alias: $CareTeamCategory = http://loinc.org
Alias: $AESeriousness = http://terminology.hl7.org/CodeSystem/adverse-event-seriousness
Alias: $IMMZAdverseEventCausality = http://smart.who.int/immunizations/CodeSystem/IMMZ-aefi-causality
// Standard HL7 event-pattern extension (reused, not ICR-minted): supplies basedOn
// on Event resources that lack the element (R4 Immunization, MedicationAdministration,
// SupplyDelivery) — ICR constrains its value to Reference(ICRCampaign)

// ICR identifier system URIs (provisional — to be confirmed before v1.0)
Alias: $GERSId = https://icr.healthcampaigns.org/identifiers/overture-gers
Alias: $PCode = https://icr.healthcampaigns.org/identifiers/pcode
// FHIR-designated ISO 3166 system URIs (not ICR-minted): 3166-1 country / 3166-2 subdivision
Alias: $ISO3166 = urn:iso:std:iso:3166
Alias: $ISO3166v2 = urn:iso:std:iso:3166:-2
Alias: $NationalId = https://icr.healthcampaigns.org/identifiers/national-id
Alias: $RegistryId = https://icr.healthcampaigns.org/identifiers/registry-id

// ICR code systems
Alias: $CampaignType = https://icr.healthcampaigns.org/CodeSystem/icr-campaign-type-cs
Alias: $DeliveryStrategy = https://icr.healthcampaigns.org/CodeSystem/icr-delivery-strategy-cs
Alias: $RecordOrigin = https://icr.healthcampaigns.org/CodeSystem/icr-record-origin-cs
Alias: $MissedReason = https://icr.healthcampaigns.org/CodeSystem/icr-missed-reason-cs
Alias: $NoncomplianceReason = https://icr.healthcampaigns.org/CodeSystem/icr-noncompliance-reason-cs
Alias: $ExclusionReason = https://icr.healthcampaigns.org/CodeSystem/icr-exclusion-reason-cs
Alias: $DenominatorSource = https://icr.healthcampaigns.org/CodeSystem/icr-denominator-source-cs
Alias: $DataLineage = https://icr.healthcampaigns.org/CodeSystem/icr-data-lineage-cs
Alias: $CoverageSource = https://icr.healthcampaigns.org/CodeSystem/icr-coverage-source-cs
Alias: $GroupKind = https://icr.healthcampaigns.org/CodeSystem/icr-group-kind-cs
Alias: $TaskOrigin = https://icr.healthcampaigns.org/CodeSystem/icr-task-origin-cs
Alias: $LocationType = https://icr.healthcampaigns.org/CodeSystem/icr-location-type-cs
Alias: $GroupCharacteristic = https://icr.healthcampaigns.org/CodeSystem/icr-group-characteristic-cs
Alias: $CoverageStratifier = https://icr.healthcampaigns.org/CodeSystem/icr-coverage-stratifier-cs
Alias: $DenominatorType = https://icr.healthcampaigns.org/CodeSystem/icr-denominator-type-cs
Alias: $CoverageUnit = https://icr.healthcampaigns.org/CodeSystem/icr-coverage-unit-cs
Alias: $AdverseEventCausality = https://icr.healthcampaigns.org/CodeSystem/icr-adverse-event-causality-cs
Alias: $TeamRole = https://icr.healthcampaigns.org/CodeSystem/icr-team-role-cs
Alias: $CommunicationChannel = https://icr.healthcampaigns.org/CodeSystem/icr-communication-channel-cs
Alias: $SeriousCriteria = https://icr.healthcampaigns.org/CodeSystem/icr-serious-criteria-cs
Alias: $DoseHistory = https://icr.healthcampaigns.org/CodeSystem/icr-dose-history-cs
Alias: $RevisitOutcome = https://icr.healthcampaigns.org/CodeSystem/icr-revisit-outcome-cs
Alias: $SettlementType = https://icr.healthcampaigns.org/CodeSystem/icr-settlement-type-cs
Alias: $FacilityType = https://icr.healthcampaigns.org/CodeSystem/icr-facility-type-cs
Alias: $Ownership = https://icr.healthcampaigns.org/CodeSystem/icr-ownership-cs
Alias: $OrgType = http://terminology.hl7.org/CodeSystem/organization-type

// --- SDC (Structured Data Capture 4.0.0) — template-based extraction (espen-forms) ---
Alias: $SDCTemplateExtract = http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-templateExtract
Alias: $SDCTemplateExtractContext = http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-templateExtractContext
Alias: $SDCTemplateExtractValue = http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-templateExtractValue
Alias: $SDCExtractAllocateId = http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-extractAllocateId
Alias: $SDCCalculatedExpression = http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-calculatedExpression
Alias: $SDCLaunchContext = http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-launchContext
Alias: $QHidden = http://hl7.org/fhir/StructureDefinition/questionnaire-hidden
Alias: $NTDDisease = https://icr.healthcampaigns.org/CodeSystem/icr-ntd-disease-cs
Alias: $MedicinePackage = https://icr.healthcampaigns.org/CodeSystem/icr-mda-medicine-package-cs
Alias: $ProjectTag = https://icr.healthcampaigns.org/CodeSystem/icr-project-tag-cs
Alias: $LocationStatus = https://icr.healthcampaigns.org/CodeSystem/icr-location-status-cs
Alias: $EndemicityStatus = https://icr.healthcampaigns.org/CodeSystem/icr-endemicity-status-cs
Alias: $CommodityClass = https://icr.healthcampaigns.org/CodeSystem/icr-commodity-class-cs
