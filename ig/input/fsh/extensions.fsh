// ICR extensions (working doc §7). FHIR has no native campaign semantics; these
// extensions carry them on profiled core resources.

Extension: DeliveryStrategy
Id: delivery-strategy
Title: "Delivery Strategy"
Description: "How this activity/task reaches its target population. First-class and coded because a single campaign routinely mixes strategies, and the strategy governs which data elements exist. The protocol lists the options (1..*), the Task records the choice (1..1), the activity is an optional pin — the strategy is campaign programme state and deliberately does NOT live on Location: per the georegistry rule a site's durable kind is Location.type (facility, temporary-post, school…), and which strategy a site serves in a given campaign belongs to that campaign's Tasks (working doc §3)."
Context: PlanDefinition, ActivityDefinition, Task
* ^experimental = false
* value[x] only CodeableConcept
* value[x] from ICRDeliveryStrategyVS (required)

Extension: RecordOrigin
Id: record-origin
Title: "Record Origin"
Description: "Whether this delivery event was recorded during a campaign or a routine facility visit. REQUIRED on all ICR delivery-event profiles — without it, SIA doses contaminate routine coverage analytics (working doc §4.4). Also valid on AdverseEvent so a campaign-context AEFI/side-effect stays separable from routine pharmacovigilance (v0.19.0)."
Context: Immunization, MedicationAdministration, SupplyDelivery, AdverseEvent
* ^experimental = false
* value[x] only code
* value[x] from ICRRecordOriginVS (required)

Extension: Campaign
Id: campaign
Title: "Campaign"
Description: "The campaign round — the ICRCampaign CarePlan — this record belongs to. The uniform record→campaign join: delivery events (Immunization, MedicationAdministration, SupplyDelivery) and coverage reports (MeasureReport) all point AT their campaign, in the same direction as Task.basedOn — the CarePlan itself is never rewritten as records accumulate. Replaces the core event-basedOn extension previously used on the delivery profiles: its R4 context is Condition-only, so every use on a delivery resource was context-invalid, and MeasureReport needs the same link (a coverage report otherwise has no computable path back to its campaign)."
Context: Immunization, MedicationAdministration, SupplyDelivery, MeasureReport
* ^experimental = false
* value[x] only Reference(ICRCampaign)

Extension: CampaignRound
Id: campaign-round
Title: "Campaign Round"
Description: "Round number of this campaign execution. Each round is its own CarePlan instantiating the same protocol, linked to an umbrella campaign via CarePlan.partOf (working doc §6.3)."
Context: CarePlan
* ^experimental = false
* value[x] only positiveInt

Extension: TargetGeography
Id: target-geography
Title: "Target Geography"
Description: "The geography (admin unit or operational area) this campaign targets."
Context: CarePlan
* ^experimental = false
* value[x] only Reference(ICRLocation)

Extension: PlanningDenominator
Id: planning-denominator
Title: "Planning Denominator"
Description: "The target-population Group flagged as this campaign's planning denominator. Multiple competing estimates may exist per geography; exactly one is the planning denominator (working doc §4.2)."
Context: CarePlan
* ^experimental = false
* value[x] only Reference(ICRTargetPopulation)

Extension: RealtimeVsReconciled
Id: realtime-vs-reconciled
Title: "Real-time vs Reconciled"
Description: "Data lineage of this record: the real-time operational stream or the post-campaign reconciled stream. One structure serves both; consumers filter by lineage — dashboards read realtime, JAP exports read reconciled (working doc §4.3). Default semantics: ABSENT MEANS REALTIME — live-stream records may omit the flag, but reconciled records must carry it, and coverage MeasureReports always carry it (1..1 on both coverage profiles)."
Context: CarePlan, Task, MeasureReport
* ^experimental = false
* value[x] only code
* value[x] from ICRDataLineageVS (required)

Extension: TaskOrigin
Id: task-origin
Title: "Task Origin"
Description: "Whether this Task was generated in advance from the microplan or registered in the field on discovery. REQUIRED on ICRCampaignTask — field-registered counts per area measure how incomplete the microplan's enumeration was, feeding the next round's denominators (working doc §10 q1)."
Context: Task
* ^experimental = false
* value[x] only code
* value[x] from ICRTaskOriginVS (required)

Extension: GroupLocation
Id: group-location
Title: "Group Location"
Description: "The physical Location of a delivery-unit Group — the validated Ona pattern: Group (who) + Location (where). For a household the Location is the dwelling (carrying the GERS building ID); for a community it is the settlement or community point; for a school cohort it is the school. This is the group's RESIDENCE/BASE, not its service point: where service actually happened is Task.location and the delivery event's own location — a household served at a village distribution center keeps its dwelling here unchanged (working doc §7.5, §9.1)."
Context: Group
* ^experimental = false
* value[x] only Reference(ICRLocation)

Extension: DenominatorSource
Id: denominator-source
Title: "Denominator Source"
Description: "The method/source behind this population estimate (census, microcensus, WorldPop, GRID3…). Reuse is only safe with provenance (working doc §2.3, §4.2)."
Context: Group, MeasureReport
* ^experimental = false
* value[x] only CodeableConcept
* value[x] from ICRDenominatorSourceVS (extensible)

Extension: EstimateDate
Id: estimate-date
Title: "Estimate Date"
Description: "When this population estimate was made. Denominators decay fast (1–3 years); a stale denominator silently reused produces confident, wrong coverage."
Context: Group
* ^experimental = false
* value[x] only date

Extension: IsPlanningDenominator
Id: is-planning-denominator
Title: "Is Planning Denominator"
Description: "True when this estimate is the one flagged as the campaign's planning denominator among competing estimates for the same geography."
Context: Group
* ^experimental = false
* value[x] only boolean

Extension: IsCalculated
Id: is-calculated
Title: "Is Calculated"
Description: "True when this estimate was computed by aggregating other estimates — ward figures summed to a district, or a share apportioned from a parent figure — rather than sourced independently; denominator-source then describes the method of the underlying inputs. A calculated figure is not independent evidence for its inputs (comparing it against them is not corroboration) and goes stale when any input is revised. Absent = not known to be calculated. A future derived-from reference list may carry the actual input estimates; its presence would imply this flag (reviewer proposal, working doc §5.2 c10)."
Context: Group
* ^experimental = false
* value[x] only boolean

Extension: EstimateConfidence
Id: estimate-confidence
Title: "Estimate Confidence"
Description: "Free-text or coded confidence qualifier on a population estimate."
Context: Group
* ^experimental = false
* value[x] only string

Extension: LocationBoundaryGeoJson
Id: location-boundary-geojson
Title: "Location Boundary (GeoJSON)"
Description: "Boundary geometry for a Location — district polygons, settlement areas, catchment zones — as a GeoJSON attachment. R4 extension mirroring the R5 standard boundary extension; alignment path is working doc §10 question 6."
Context: Location
* ^experimental = false
* value[x] only Attachment
* valueAttachment.contentType = #"application/geo+json"

Extension: DirectlyObservedConsumption
Id: directly-observed-consumption
Title: "Directly Observed Consumption"
Description: "Whether the community drug distributor physically observed the individual swallow the medication (MDA DOC protocol)."
Context: MedicationAdministration
* ^experimental = false
* value[x] only boolean

Extension: SampleDesign
Id: sample-design
Title: "Sample Design"
Description: "Sample design / method detail of an independently-measured coverage estimate — e.g. 'WHO 30×10 cluster survey, district-representative', LQAS lot definition, RCM site-selection note. Survey coverage without its design is uninterpretable (working doc §4.1)."
Context: MeasureReport
* ^experimental = false
* value[x] only string

Extension: CoverageSource
Id: coverage-source
Title: "Coverage Source"
Description: "The measurement lineage of this coverage report: administrative vs survey/LQAS/RCM. The two lineages routinely diverge (Cuamba: ~99% admin vs ~76% survey) and must never be merged (working doc §4.1)."
Context: MeasureReport
* ^experimental = false
* value[x] only code
* value[x] from ICRCoverageSourceVS (required)

// --- v0.19.0 additions (espen-v3 round) ---------------------------------------

Extension: DenominatorType
Id: denominator-type
Title: "Denominator Type"
Description: "Whether the denominator is the TOTAL population or the AT-RISK/eligible subset — programme vs epidemiological coverage in NTD MDA. On a coverage MeasureReport it qualifies the figure; on an ICRTargetPopulation it labels the estimate (espen-v3 / §17.2 B1)."
Context: MeasureReport, Group
* ^experimental = false
* value[x] only code
* value[x] from ICRDenominatorTypeVS (required)

Extension: CoverageUnit
Id: coverage-unit
Title: "Coverage Unit"
Description: "What the coverage figure counts: people, or implementation units (villages/areas = geographic coverage). Absent ⇒ people (espen-v3 / §17.2 B1)."
Context: MeasureReport
* ^experimental = false
* value[x] only code
* value[x] from ICRCoverageUnitVS (required)

Extension: DosePoleBand
Id: dose-pole-band
Title: "Dose-pole Band"
Description: "The measured dose-pole height band that determined the tablet count for a PC-NTD treatment — makes the height-band → dose logic machine-readable rather than buried in dosage.text. Bands are drug-specific and carried as text or local codings; deliberately unbound — no universal band ValueSet exists (espen-v3 minor-issue)."
Context: MedicationAdministration, ActivityDefinition
* ^experimental = false
* value[x] only CodeableConcept

Extension: OverseesArea
Id: oversees-area
Title: "Oversees Area"
Description: "The supervisory/operational-area Location(s) a CareTeam's supervisor covers — ties the team to operational geography (working doc §5.5, §6.3)."
Context: CareTeam
* ^experimental = false
* value[x] only Reference(ICRLocation)

// --- v0.20.0 additions (espen-v4 round) ---------------------------------------

Invariant: icr-stock-ledger
Description: "Stock ledger identity: received = used + remaining + notUsable + returned (absent parts count as zero). Warning severity — a reconciliation gap is a data-quality signal worth surfacing, not always a recording error."
Severity: #warning
Expression: "extension('received').exists() and extension('used').exists() and extension('remaining').exists() implies extension('received').value.ofType(Quantity).value = extension('used').value.ofType(Quantity).value + extension('remaining').value.ofType(Quantity).value + iif(extension('notUsable').exists(), extension('notUsable').value.ofType(Quantity).value, 0) + iif(extension('returned').exists(), extension('returned').value.ofType(Quantity).value, 0)"

Extension: StockAccountability
Id: stock-accountability
Title: "Stock Accountability"
Description: "Vial/commodity accountability and wastage on a supply event — received / used / remaining / not-usable (expired/damaged) / returned, plus physical-vs-theoretical concordance and (vaccines) the VVM stage. Reusable for vaccines, drugs and ITNs; the ESPEN supervision Form 5 stock block (espen-v4 / §17.2 C2)."
Context: SupplyDelivery
* ^experimental = false
* obeys icr-stock-ledger
* extension contains
    received 0..1 MS and
    used 0..1 MS and
    remaining 0..1 MS and
    notUsable 0..1 MS and
    returned 0..1 MS and
    concordant 0..1 MS and
    vvmStage 0..1
* extension[received].value[x] only Quantity
* extension[received] ^short = "Quantity received"
* extension[used].value[x] only Quantity
* extension[used] ^short = "Quantity used/administered/distributed"
* extension[remaining].value[x] only Quantity
* extension[remaining] ^short = "Quantity remaining in stock"
* extension[notUsable].value[x] only Quantity
* extension[notUsable] ^short = "Expired / damaged / otherwise not usable"
* extension[returned].value[x] only Quantity
* extension[returned] ^short = "Quantity returned to the next level"
* extension[concordant].value[x] only boolean
* extension[concordant] ^short = "Does physical stock match the theoretical/recorded stock?"
* extension[vvmStage].value[x] only integer
* extension[vvmStage] ^short = "Vaccine vial monitor stage 1–4 (vaccines only)"

Extension: SocialMobilization
Id: social-mobilization
Title: "Social Mobilization"
Description: "Demand-generation for a campaign/round: whether the population was informed beforehand and the channels used (ESPEN supervision Form 5). The demand axis of §17.3 (espen-v4)."
Context: CarePlan, Task
* ^experimental = false
* extension contains
    populationInformed 0..1 MS and
    channel 0..* MS
* extension[populationInformed].value[x] only boolean
* extension[populationInformed] ^short = "Was the population informed before the campaign?"
* extension[channel].value[x] only CodeableConcept
* extension[channel].value[x] from ICRCommunicationChannelVS (extensible)
* extension[channel] ^short = "Communication channel(s) used (radio, town-criers, community-leaders, schools, posters…)"

Extension: WorkloadTarget
Id: workload-target
Title: "Workload Target"
Description: "The microplan workload assigned to a CareTeam — the area(s) it covers and the expected volume (population / households / days). With oversees-area, makes the CareTeam the typed team-area-workload unit of the microplan (the ICRCampaign with intent=plan is the microplan itself) (espen-v4 / §17.3)."
Context: CareTeam
* ^experimental = false
* extension contains
    targetArea 0..* MS and
    targetPopulation 0..1 MS and
    targetHouseholds 0..1 MS and
    targetDays 0..1 MS
* extension[targetArea].value[x] only Reference(ICRLocation)
* extension[targetArea] ^short = "Area(s) the team is assigned to cover"
* extension[targetPopulation].value[x] only unsignedInt
* extension[targetPopulation] ^short = "Expected eligible population to reach"
* extension[targetHouseholds].value[x] only unsignedInt
* extension[targetHouseholds] ^short = "Expected households to visit"
* extension[targetDays].value[x] only unsignedInt
* extension[targetDays] ^short = "Planned working days"

Extension: SeriousCriteria
Id: serious-criteria
Title: "Serious-Event Criteria"
Description: "Why an adverse event is serious — the WHO/CIOMS criterion/criteria behind AdverseEvent.seriousness = serious (death, life-threatening, hospitalization, disability, congenital anomaly, other medically important) (espen-v4 / §17.2 C1)."
Context: AdverseEvent
* ^experimental = false
* value[x] only CodeableConcept
* value[x] from ICRSeriousCriteriaVS (extensible)

// --- v0.21.0 additions (forms-v1 round) ---------------------------------------

Extension: PriorDoseStatus
Id: prior-dose-status
Title: "Prior-dose Status (Zero-dose)"
Description: "The person's prior-dose status for this antigen at the time of the campaign contact: zero-dose (never received before), previously-received, or no-recall. The per-event carrier of the polio SIA tally's never/previously/no-recall split; aggregates to the dose-history coverage stratifier and feeds zero-dose reach / dropout measures. Distinct from Immunization.protocolApplied.doseNumber, which counts this series' doses, not prior status of the antigen (forms-v1 / jul3-form-analysis §Aggregate #1)."
Context: Immunization, MedicationAdministration
* ^experimental = false
* value[x] only code
* value[x] from ICRDoseHistoryVS (required)

// --- v0.1.1 additions (ig-compare fix round) -----------------------------------

Extension: ReporterTeam
Id: reporter-team
Title: "Reporter Team"
Description: "The ICRCareTeam whose figures this MeasureReport rolls up. R4 MeasureReport.reporter cannot reference a CareTeam (legal targets: Practitioner | PractitionerRole | Location | Organization), so reporter carries the accountable supervisor or organization, and this extension carries the team join — 'which team's numbers are these' stays a single hop (ig-compare §9 item 1)."
Context: MeasureReport
* ^experimental = false
* value[x] only Reference(ICRCareTeam)

Extension: SettlementType
Id: settlement-type
Title: "Settlement / Special-population Type"
Description: "The settlement or special-population classification of a place (urban / rural / slum / refugee-IDP / nomad-pastoralist / security-compromised / hard-to-reach / cross-border / immigrant) — the recurring 'type of settlement' axis on the polio SIA monitoring/tally forms. A vulnerability/equity attribute of a Location that drives hard-to-reach-area targeting and equity disaggregation (forms-v1 / jul3-form-analysis §Aggregate #5)."
Context: Location
* ^experimental = false
* value[x] only CodeableConcept
* value[x] from ICRSettlementTypeVS (extensible)

Extension: DistributionRecipient
Id: distribution-recipient
Title: "Distribution Recipient"
Description: "Who received a distributed commodity — the delivery-unit Group (household, community, school cohort) or a registered person. R4 SupplyDelivery.patient targets only Patient, but ICR's usual recipient is the household; this extension supplies the Group join that per-capita coverage (e.g. 1 net per 2 household members: quantity ÷ Group.quantity) computes against (supply-split round)."
Context: SupplyDelivery
* ^experimental = false
* value[x] only Reference(ICRDeliveryUnit or ICRPatient)

Extension: IssuedToTeam
Id: issued-to-team
Title: "Issued To Team"
Description: "The CareTeam a supply movement was issued to. R4 SupplyDelivery.receiver targets only individual practitioners — the same gap (and same fix) as MeasureReport.reporter → reporter-team. One issuance per team per day, with its stock-accountability ledger, is the field-team daily-stock pattern (supply-split round)."
Context: SupplyDelivery
* ^experimental = false
* value[x] only Reference(ICRCareTeam)
