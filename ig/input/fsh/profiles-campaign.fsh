// Campaign-architecture profiles (working doc §7.1–§7.4).
// CarePlan is the keystone: PlanDefinition = reusable protocol, CarePlan = a campaign
// execution, ActivityDefinition = discrete work type, Task = the operational unit.

Profile: ICRCampaignProtocol
Parent: PlanDefinition
Id: ICRCampaignProtocol
Title: "ICR Campaign Protocol"
Description: "The reusable, version-controlled template for a campaign type — what a measles SIA *is* (products, age bands, activity sequence, coverage goals), instantiated by every execution in every country (working doc §7.1)."
* ^experimental = false
* status MS
* version MS
* title MS
* type 1..1 MS
* type from ICRCampaignTypeVS (required)
* subject[x] MS
* subject[x] ^short = "Target population definition (age band, eligibility) — the protocol's eligibility restriction lives HERE, not on the ActivityDefinition: a definitional Group (actual=false, no count) with computable characteristics (e.g. age-band valueRange)"
* goal MS
* goal ^short = "Coverage targets / thresholds (e.g. ≥95% admin coverage; ≥65% epidemiological coverage for LF)"
* action MS
* action ^short = "The activity sequence, instantiated as ICRCampaignActivity definitions"
* action.definition[x] only Canonical(ICRCampaignActivity)
* action.definition[x] MS
* extension contains DeliveryStrategy named deliveryStrategy 1..* MS
* extension[deliveryStrategy] ^short = "Delivery strategies this protocol uses — campaigns routinely mix them"

Profile: ICRCampaign
Parent: CarePlan
Id: ICRCampaign
Title: "ICR Campaign"
Description: "A specific campaign execution — the keystone resource. Begins life as a microplan (intent=plan) and evolves into the execution record as Tasks complete and coverage accumulates. Rounds are sibling ICRCampaigns under an umbrella campaign via partOf (working doc §7.2, §6.3). Granularity: one ICRCampaign per REPORTING SCOPE — the highest level that carries the campaign's global target (typically the district round), with that scope's denominator as subject. Operational sub-units (wards, villages, communities) sit under it through the Location hierarchy and their own geography-scoped ICRTargetPopulation estimates; they do not each get a CarePlan. Child CarePlans (partOf) are reserved for genuine sub-rounds with their own period or reporting obligation, not for every level of geographic disaggregation."
* ^experimental = false
* instantiatesCanonical 1..1 MS
* instantiatesCanonical only Canonical(ICRCampaignProtocol)
* status MS
* status ^short = "Campaign lifecycle: draft → active → completed"
* intent MS
* intent ^short = "plan (microplan) transitioning to order (execution)"
* category 1..* MS
* category from ICRCampaignTypeVS (required)
* subject only Reference(ICRTargetPopulation)
* subject MS
* period 1..1 MS
* period ^short = "Campaign / round dates"
* careTeam MS
* careTeam only Reference(ICRCareTeam)
* careTeam ^short = "The campaign roster: the delivery team(s) and supervisor — same constraint as Task.owner, so 'who ran this campaign' is a real join"
* addresses MS
* addresses ^short = "The disease/condition targeted"
* partOf only Reference(ICRCampaign)
* partOf ^short = "Umbrella campaign this round belongs to (multi-round pattern, working doc §6.3)"
* activity.reference only Reference(ICRCampaignTask)
* activity ^short = "Optional curated Task list. The canonical link runs the other way — Task.basedOn points at this campaign — so the CarePlan is never rewritten as tasks are created"
* extension contains
    CampaignRound named campaignRound 0..1 MS and
    TargetGeography named targetGeography 0..* MS and
    PlanningDenominator named planningDenominator 0..1 MS and
    SocialMobilization named socialMobilization 0..1 MS and
    RealtimeVsReconciled named dataLineage 0..1 MS
* extension[socialMobilization] ^short = "Demand generation: population-informed + channels used (v0.20.0)"
* extension[targetGeography] ^short = "The Location this campaign targets — searchable as CarePlan?target-geography= (SearchParameter icr-campaign-target-geography): what is planned where, chainable through partof and reverse-includable from a Location subtree (campaign-visibility)"

Profile: ICRCampaignActivity
Parent: ActivityDefinition
Id: ICRCampaignActivity
Title: "ICR Campaign Activity"
Description: "A discrete work type within a campaign — 'administer albendazole to children 5–14', 'distribute ITNs to households' — instantiated as ICRCampaignTask resources (working doc §7.3). Activities form a shared catalog, not children of any one protocol: the reference runs PlanDefinition.action.definitionCanonical → ActivityDefinition, so the same activity is reusable across any number of protocols. topic tags the catalog by campaign type for menu filtering; the tag is advisory and never restricts which protocols may reference the activity. Eligibility criteria (age bands etc.) also do not live here — base ActivityDefinition has no eligibility element; they belong on the protocol (ICRCampaignProtocol.subject)."
* ^experimental = false
* status MS
* kind = #Task
* code 1..1 MS
* code ^short = "The intervention: vaccinate / treat / distribute / spray"
* topic MS
* topic from ICRCampaignTypeVS (extensible)
* topic ^short = "Catalog tag: campaign type(s) this activity is typically used in — advisory menu filtering only, never a restriction on which protocols may reference it"
* product[x] MS
* product[x] ^short = "Vaccine (CVX) / drug (ATC) / commodity (GS1)"
* dosage MS
* dosage ^short = "Where applicable; dose-pole logic references an Observation"
* extension contains DeliveryStrategy named deliveryStrategy 0..1 MS

Invariant: icr-task-h2h-outputs
Description: "House-to-house tally outputs (houses-visited, eligible-present, eligible-absent, children-already-marked) belong on house-to-house tasks — strategy determines which data elements exist (§8 principle 1), now machine-checkable. Warning severity: a mismatch is a data-quality signal, not always a recording error."
Severity: #warning
Expression: "extension('https://icr.healthcampaigns.org/StructureDefinition/delivery-strategy').value.ofType(CodeableConcept).coding.exists(code = 'house-to-house') or output.type.coding.where(code = 'houses-visited' or code = 'eligible-present' or code = 'eligible-absent' or code = 'children-already-marked').empty()"

Profile: ICRCampaignTask
Parent: Task
Id: ICRCampaignTask
Title: "ICR Campaign Task"
Description: "The assignable, trackable operational unit of work — one Task per site-session (for = the site Location) or per household, community, or school-cohort visit (for = the delivery-unit Group). Every Task points at its campaign via basedOn (the CarePlan is never updated as tasks are created). Tasks may be pre-planned from the microplan or field-registered on discovery (the required task-origin code records which). Whether Tasks are assigned at village or household level is a configuration choice (working doc §7.4)."
* ^experimental = false
* status MS
* status ^short = "requested → in-progress → completed / failed"
* intent MS
* code 1..1 MS
* code ^short = "The activity being performed"
* basedOn 1..1 MS
* basedOn only Reference(ICRCampaign)
* basedOn ^short = "The campaign (round) this task executes. Tasks point at the campaign — the CarePlan is never updated as tasks are created"
* instantiatesCanonical MS
* instantiatesCanonical only Canonical(ICRCampaignActivity)
* instantiatesCanonical ^short = "The activity this task carries out — the structured definition-to-execution link (same convention as CarePlan → Protocol). Carries the work definition (product, dose, intervention code) so multi-activity campaigns stay queryable per activity; Task.code is only the human-readable label. Optional: an ad-hoc field task may have no single activity"
// for: a delivery-unit Group when the unit has members (household, community,
// school cohort); a Location when it does not (a fixed/temporary-post site, a
// structure under IRS, an area target) — plus Patient as the
// deliberate exception: person-targeted FOLLOW-UP tasks (a specific missed or
// zero-dose child spawns a Task pointing at that child, working doc §4.4). The
// norm remains one Task per visit/session with person-level detail in the
// delivery events hanging off Task.output. R4 'for' is the beneficiary of the
// work and carries the standard Task?patient=/subject= searches (OpenSRP/Reveal
// precedent: the sprayed structure / visited family / traced person lives here).
// 'focus' (the request being actioned) is deliberately left unconstrained, free
// for deployments whose systems generate per-task order resources.
* for 1..1 MS
* for only Reference(ICRDeliveryUnit or ICRLocation or Patient)
* for ^short = "What the task acts on: a delivery-unit Group where the unit has members (household, community, school cohort) or a Location where it does not (site, structure, area); a Patient only for person-targeted follow-up tasks"
* reasonCode MS
* reasonCode ^short = "The disease/programme this Task serves — scopes a Task to one disease where a community runs several concurrent programmes (per-village disease scoping in co-endemic MDA)"
* owner MS
* owner only Reference(ICRCareTeam)
* owner ^short = "The assigned ICRCareTeam — a real join, not a display string (v0.20.0): 'who worked this' and (via the supervisor) 'who reports this'"
* location 1..1 MS
* location only Reference(ICRLocation)
* location ^short = "Where the work happens: settlement, school, post, or dwelling"
* executionPeriod MS
// Everything the visit PRODUCED rides Task.output as coded entries (task-outputs
// round — the former tally extensions are retired). Parameters of the work
// (deliveryStrategy, taskOrigin) stay extensions: known at creation, they
// describe the Task; results are outputs. A new tally axis is a new
// ICRTaskOutputTypeCS code, not a new extension.
* output MS
* output ^short = "Everything the visit produced, as coded entries: the scalar tally (treated-count), the house-to-house axes (houses-visited, eligible-present/absent, children-already-marked), reason codes (missed/refusal/exclusion), revisit outcome, and references to delivery events and the stratified coverage report"
* output ^slicing.discriminator.type = #pattern
* output ^slicing.discriminator.path = "type"
* output ^slicing.rules = #open
* output.type from ICRTaskOutputTypeVS (extensible)
* output contains
    treatedCount 0..1 and
    housesVisited 0..1 and
    eligiblePresent 0..1 and
    eligibleAbsent 0..1 and
    childrenAlreadyMarked 0..1 and
    missedReason 0..* and
    noncomplianceReason 0..* and
    exclusionReason 0..* and
    revisitOutcome 0..1
* output[treatedCount].type = $TaskOutputType#treated-count
* output[treatedCount].value[x] only unsignedInt
* output[housesVisited].type = $TaskOutputType#houses-visited
* output[housesVisited].value[x] only unsignedInt
* output[housesVisited] ^short = "(house-to-house, area/team-day granularity) Houses visited"
* output[eligiblePresent].type = $TaskOutputType#eligible-present
* output[eligiblePresent].value[x] only unsignedInt
* output[eligiblePresent] ^short = "(house-to-house) Eligible persons present — program-neutral: under-5s for polio, household members for ITN registration, the eligible band for MDA"
* output[eligibleAbsent].type = $TaskOutputType#eligible-absent
* output[eligibleAbsent].value[x] only unsignedInt
* output[eligibleAbsent] ^short = "(house-to-house) Eligible persons absent — feeds same-day mop-up lists"
* output[childrenAlreadyMarked].type = $TaskOutputType#children-already-marked
* output[childrenAlreadyMarked].value[x] only unsignedInt
* output[childrenAlreadyMarked] ^short = "(house-to-house) Children found already finger-marked on arrival — a count, since a visit sees several children (replaces the retired boolean finger-marked extension)"
* output[missedReason].type = $TaskOutputType#missed-reason
* output[missedReason].value[x] only CodeableConcept
* output[missedReason].valueCodeableConcept from ICRMissedReasonVS (extensible)
* output[missedReason] ^short = "Why eligible person(s) were missed — person-level (absent, sleeping) and area-level (insecurity, shortage, access) causes"
* output[noncomplianceReason].type = $TaskOutputType#noncompliance-reason
* output[noncomplianceReason].value[x] only CodeableConcept
* output[noncomplianceReason].valueCodeableConcept from ICRNoncomplianceReasonVS (extensible)
* output[noncomplianceReason] ^short = "Why the household/caregiver refused (WHO IDHC 'intervention refusal')"
* output[exclusionReason].type = $TaskOutputType#exclusion-reason
* output[exclusionReason].value[x] only CodeableConcept
* output[exclusionReason].valueCodeableConcept from ICRExclusionReasonVS (extensible)
* output[exclusionReason] ^short = "Why a present, age-eligible person was clinically excluded this round (under-height/age, pregnant, breastfeeding)"
* output[revisitOutcome].type = $TaskOutputType#revisit-outcome
* output[revisitOutcome].value[x] only CodeableConcept
* output[revisitOutcome].valueCodeableConcept from ICRRevisitOutcomeVS (extensible)
* output[revisitOutcome] ^short = "On a person-targeted follow-up Task: already-vaccinated | vaccinated-on-revisit | still-missing"
* obeys icr-task-h2h-outputs
* extension contains
    DeliveryStrategy named deliveryStrategy 1..1 MS and
    TaskOrigin named taskOrigin 1..1 MS and
    RealtimeVsReconciled named dataLineage 0..1
