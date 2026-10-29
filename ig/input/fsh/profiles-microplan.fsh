// Microplan resource estimates (project/ig-gaps-from-digit.md §6). The planned
// quantity of each resource per area, so planned vs used can be compared against
// what the IG already records (movements, tasks, cost lines). One Observation per
// Location × resource kind (× product for commodities), following ICRCampaignCost.
// The components hold the numeric input assumptions only: a source microplan's
// formula chain (operators, order, rounding) is not represented, so an estimate
// cannot be recomputed from the ICR. The source plan is referenced through
// derivedFrom (the plan file as a DocumentReference) and identifier.

Invariant: icr-estimate-commodity-item
Description: "A commodity estimate names its product in the supplied-item extension."
Severity: #error
Expression: "code.coding.where(system = 'https://icr.healthcampaigns.org/CodeSystem/icr-resource-type-cs' and code = 'commodity').exists() implies extension('https://icr.healthcampaigns.org/StructureDefinition/supplied-item').exists()"

Profile: ICRResourceEstimate
Parent: Observation
Id: ICRResourceEstimate
Title: "ICR Resource Estimate"
Description: "A microplan's estimate of one resource for one area of a campaign — the number of nets, teams, team-days, supervisors, vehicles or cold-chain items — with the target populations it was computed from and its numeric assumptions (persons per net, buffer). Draft plans are preliminary, approved plans final."
* ^experimental = false
* obeys icr-estimate-commodity-item
* status MS
* status ^short = "preliminary while the plan is in draft; final once approved"
* code 1..1 MS
* code from ICRResourceTypeVS (required)
* code ^short = "commodity | teams | team-days | supervisors | vehicles | cold-chain-equipment"
* subject 1..1 MS
* subject only Reference(ICRLocation)
* subject ^short = "The area the estimate is for — any level"
* basedOn 1..1 MS
* basedOn only Reference(ICRCampaign)
* basedOn ^short = "The campaign (microplan or round) the estimate belongs to"
* value[x] 1..1 MS
* value[x] only Quantity
* valueQuantity.value 1..1 MS
* valueQuantity.system 1..1 MS
* valueQuantity.code 1..1 MS
* valueQuantity ^short = "The estimate, with a coded unit (system + code)"
* extension contains
    SuppliedItem named suppliedItem 0..1 MS and
    EstimateBasis named basis 0..* MS
* extension[suppliedItem] ^short = "The product, for commodity estimates; required when code = commodity (icr-estimate-commodity-item)"
* extension[basis] ^short = "The ICRTargetPopulation(s) the estimate was computed from. R4 derivedFrom cannot reference a Group"
* derivedFrom MS
* derivedFrom only Reference(DocumentReference)
* derivedFrom ^short = "The source microplan file or configuration, where it is kept"
* component MS
* component ^short = "One per numeric assumption, for example persons per net 1.8, buffer 10 %"
* component.code ^short = "The assumption; text where the source has only a key"
* component.value[x] 1..1
* component.value[x] only Quantity
* component.valueQuantity.value 1..1 MS
* component.valueQuantity.unit 1..1 MS
* component.valueQuantity ^short = "The assumed value, with a unit"
* identifier MS
* identifier ^short = "The source plan and plan-row ids"
* effective[x] MS
* effective[x] ^short = "When the estimate was made"
* performer MS
* performer only Reference(Organization or ICRCareTeam or Practitioner or PractitionerRole)
* performer ^short = "The accountable team or organization. A planning tool is not a legal performer: it goes in device"
* device MS
* device only Reference(Device)
* device ^short = "The planning tool, as a Device, where recorded"
* method MS
* method ^short = "How the estimate was made (microplanning tool, manual)"
