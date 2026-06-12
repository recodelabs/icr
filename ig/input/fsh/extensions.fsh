// ICR extensions (working doc §7). FHIR has no native campaign semantics; these
// extensions carry them on profiled core resources.

Extension: DeliveryStrategy
Id: delivery-strategy
Title: "Delivery Strategy"
Description: "How this activity/site/task reaches its target population. First-class and coded because a single campaign routinely mixes strategies, and the strategy governs which data elements exist (working doc §3)."
Context: PlanDefinition, ActivityDefinition, Task, Location
* ^experimental = false
* value[x] only CodeableConcept
* value[x] from ICRDeliveryStrategyVS (required)

Extension: RecordOrigin
Id: record-origin
Title: "Record Origin"
Description: "Whether this delivery event was recorded during a campaign or a routine facility visit. REQUIRED on all ICR delivery-event profiles — without it, SIA doses contaminate routine coverage analytics (working doc §4.4)."
Context: Immunization, MedicationAdministration, SupplyDelivery
* ^experimental = false
* value[x] only code
* value[x] from ICRRecordOriginVS (required)

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
Description: "Data lineage of this record: the real-time operational stream or the post-campaign reconciled stream. One structure serves both; consumers filter by lineage — dashboards read realtime, JAP exports read reconciled (working doc §4.3)."
Context: CarePlan, Task, MeasureReport
* ^experimental = false
* value[x] only code
* value[x] from ICRDataLineageVS (required)

Extension: HousesVisited
Id: houses-visited
Title: "Houses Visited"
Description: "Number of houses visited — aggregate output of a house-to-house task."
Context: Task
* ^experimental = false
* value[x] only unsignedInt

Extension: ChildrenPresent
Id: children-present
Title: "Children Present"
Description: "Number of eligible children present at the visit(s)."
Context: Task
* ^experimental = false
* value[x] only unsignedInt

Extension: ChildrenAbsent
Id: children-absent
Title: "Children Absent"
Description: "Number of eligible children absent at the visit(s) — feeds same-day mop-up lists."
Context: Task
* ^experimental = false
* value[x] only unsignedInt

Extension: MissedReason
Id: missed-reason
Title: "Missed Reason"
Description: "Why eligible person(s) were missed at this visit. House-to-house campaigns produce this natively (working doc §3.1)."
Context: Task
* ^experimental = false
* value[x] only CodeableConcept
* value[x] from ICRMissedReasonVS (extensible)

Extension: NoncomplianceReason
Id: noncompliance-reason
Title: "Noncompliance Reason"
Description: "Why the household/caregiver declined — drives social mobilization and mop-up targeting."
Context: Task
* ^experimental = false
* value[x] only CodeableConcept
* value[x] from ICRNoncomplianceReasonVS (extensible)

Extension: TaskOrigin
Id: task-origin
Title: "Task Origin"
Description: "Whether this Task was generated in advance from the microplan or registered in the field on discovery. REQUIRED on ICRCampaignTask — field-registered counts per area measure how incomplete the microplan's enumeration was, feeding the next round's denominators (working doc §10 q1)."
Context: Task
* ^experimental = false
* value[x] only code
* value[x] from ICRTaskOriginVS (required)

Extension: FingerMarked
Id: finger-marked
Title: "Finger Marked"
Description: "Whether the child was finger-marked — the in-field 'already covered' flag of house-to-house campaigns."
Context: Task
* ^experimental = false
* value[x] only boolean

Extension: GroupLocation
Id: group-location
Title: "Group Location"
Description: "The physical Location of a delivery-unit Group — the validated Ona pattern: Group (who) + Location (where). For a household the Location is the dwelling (carrying the GERS building ID); for a community it is the settlement or community point (working doc §7.5, §9.1)."
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

Extension: OverlaysAdminUnit
Id: overlays-admin-unit
Title: "Overlays Admin Unit"
Description: "Links an operational-geography Location (supervisory area, operational area) to the administrative unit(s) it overlays. Operational ≠ administrative geography: partOf can only express one hierarchy, so this extension is what makes operational areas linkable-but-distinct rather than just distinct (working doc §9, identity principle 3)."
Context: Location
* ^experimental = false
* value[x] only Reference(ICRLocation)

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
