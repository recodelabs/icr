// Cost profiles (cost-v1). The campaign-cost axis the field-evidence review flagged
// (§13.2). Two layers, matching the record / analysis split the rest of the IG uses:
//   ICRCampaignCost (Observation) — one budget or expenditure LINE ITEM, pointing AT
//     the round through basedOn (native on Observation, so no campaign extension is
//     needed) and attributed to a PLACE (subject = ICRLocation), never to a population
//     estimate: denominators are revisable and compete (GRID3 vs ward-sum vs census
//     for the same district), a cost is not, so the division happens later.
//   ICRCostReport (MeasureReport) — the computed figures: total cost and cost per
//     person targeted / reached / per dose, declaring which denominator was divided
//     by (the same denominator-source / denominator-type axes coverage uses) and
//     listing the line items and coverage report it was computed from.
// Counts and money stay in their native homes: person counts in the coverage
// reports, money here; a cost report joins the two through evaluatedResource.

Invariant: icr-cost-currency
Description: "The amount's Quantity.code must be an ISO 4217 currency code (three upper-case letters) under system urn:iso:std:iso:4217."
Severity: #error
Expression: "value.ofType(Quantity).system = 'urn:iso:std:iso:4217' and value.ofType(Quantity).code.matches('^[A-Z]{3}$')"

Invariant: icr-cost-driver-product
Description: "When both the driver units and the unit cost are given, the amount should equal units × unit-cost (within 1%). Warning severity — a gap is a reconciliation signal (rounding, partial payment), not always a recording error."
Severity: #warning
Expression: "component.where(code.coding.code = 'units').exists() and component.where(code.coding.code = 'unit-cost').exists() implies ((component.where(code.coding.code = 'units').value.ofType(Quantity).value * component.where(code.coding.code = 'unit-cost').value.ofType(Quantity).value) - value.ofType(Quantity).value).abs() <= (value.ofType(Quantity).value * 0.01)"

Profile: ICRCampaignCost
Parent: Observation
Id: ICRCampaignCost
Title: "ICR Campaign Cost"
Description: "One cost line item of a campaign — a budgeted or actual amount for one cost category, attributed to one place and (optionally) one team. Joined TO the campaign via basedOn (native on Observation — the only ICR event resource that needs no campaign extension), in the same direction as every other record, so the CarePlan is never rewritten as costs accumulate. Recorded at the grain the source document states (a national vaccine invoice is one national line on the umbrella; a district expenditure return is district lines on the round) and NEVER allocated downward — apportionment is a report-level statement on ICRCostReport. Budget vs expenditure is the cost-lineage axis, not status; status carries preliminary → final → amended for actuals, as the data-lineage axis does for coverage. Consumers read the newest final/amended line per (campaign, place, category, lineage, perspective). Ratios (cost per person) are NOT this profile — they are ICRCostReport (cost-v1)."
* ^experimental = false
* obeys icr-cost-currency and icr-cost-driver-product
* status MS
* status ^short = "final; preliminary for in-flight expenditure; amended when restated — a newer final/amended line supersedes"
* basedOn 1..1 MS
* basedOn only Reference(ICRCampaign)
* basedOn ^short = "The campaign this cost belongs to — the round for round-specific costs, the umbrella for costs shared across rounds (national vaccine, national training)"
* code 1..1 MS
* code from ICRCostCategoryVS (extensible)
* code ^short = "WHAT the money is for — the cost category (personnel, per-diem-incentive, transport, cold-chain, commodities, social-mobilization …)"
* subject 1..1 MS
* subject only Reference(ICRLocation)
* subject ^short = "WHERE the cost is attributed — an admin unit or operational area, at the grain the source states (country / district / ward). Must lie within the campaign's target geography. A place, not a population estimate: the denominator is chosen and declared in the cost report"
* focus 0..1 MS
* focus only Reference(ICRCareTeam)
* focus ^short = "Optional: the team, for team-level microplan budget lines (subject stays the team's area)"
* effective[x] only Period
* effective[x] 1..1 MS
* effective[x] ^short = "The period the amount covers — the round period for a budget line; the expenditure window for an actual"
* performer MS
* performer only Reference(Organization)
* performer ^short = "Who budgeted / spent / reported the line: the DHMT, the MoH programme, the UNICEF country office — the spending organization, as distinct from the funding source"
* value[x] only Quantity
* value[x] 1..1 MS
* valueQuantity.value 1..1 MS
* valueQuantity.system 1..1 MS
* valueQuantity.system = $ISO4217
* valueQuantity.code 1..1 MS
* valueQuantity ^short = "The amount in the currency incurred — Quantity with system urn:iso:std:iso:4217 and code = the ISO 4217 currency (SLE, NGN, USD …)"
* extension contains
    CostLineage named costLineage 1..1 MS and
    CostPerspective named costPerspective 0..1 MS and
    FundingSource named fundingSource 0..1 MS
* extension[costLineage] ^short = "budgeted | actual — required: the two are never summed"
* extension[costPerspective] ^short = "financial | economic; absent ⇒ financial"
* extension[fundingSource] ^short = "Who paid (government, gavi, gpei, unicef …) — the envelope, not the spender"
* component ^slicing.discriminator.type = #pattern
* component ^slicing.discriminator.path = "code"
* component ^slicing.rules = #open
* component ^short = "Optional decomposition: driver units × unit cost (so a budget can be generated from the microplan — workload-target days × roster × per-diem norm) and the USD-normalised amount"
* component contains
    units 0..1 MS and
    unitCost 0..1 MS and
    amountUsd 0..1 MS
* component[units].code = $CostComponent#units
* component[units].value[x] only Quantity
* component[units].value[x] 1..1
* component[units] ^short = "Driver quantity: 3,200 person-days, 12 vehicle-days, 50,000 doses"
* component[unitCost].code = $CostComponent#unit-cost
* component[unitCost].value[x] only Quantity
* component[unitCost].value[x] 1..1
* component[unitCost].valueQuantity.system = $ISO4217
* component[unitCost] ^short = "The norm — rate per driver unit in the line's currency; units × unit-cost = the amount (icr-cost-driver-product)"
* component[amountUsd].code = $CostComponent#amount-usd
* component[amountUsd].value[x] only Quantity
* component[amountUsd].value[x] 1..1
* component[amountUsd].valueQuantity.system = $ISO4217
* component[amountUsd].valueQuantity.code = #USD
* component[amountUsd] ^short = "USD-normalised amount for cross-country comparison — the conversion date defaults to the end of effectivePeriod (open decision §13.4)"
* derivedFrom MS
* derivedFrom ^short = "The evidentiary trail — the budget form response (ICRCampaignFormResponse) or the finance-system document the line came from"
* note MS
* note ^short = "Free-text detail (the named donor for other-donor, the country budget line label)"

Invariant: icr-cost-report-divisor
Description: "Every unit-cost figure (per-person-targeted, per-person-reached, per-dose-delivered) must state the count it divided by as a denominator population — a ratio without its divisor is not auditable."
Severity: #error
Expression: "group.where(code.coding.code.startsWith('per-')).all(population.where(code.coding.code = 'denominator').count.exists())"

Profile: ICRCostReport
Parent: MeasureReport
Id: ICRCostReport
Title: "ICR Cost Report"
Description: "The computed cost figures for a campaign at one geography, lineage, perspective and scope: total cost, and cost per person targeted / per person reached / per dose delivered — one MeasureReport.group per figure (ICRCostFigureCS). Money is the measureScore (a currency Quantity); the people or dose count each ratio divided by sits in group.population as a denominator count; evaluatedResource lists the ICRCampaignCost line items and the coverage report the figures were computed from, so a unit cost carries its own provenance and inherits the coverage figure's data lineage. The report declares which denominator it divided by (denominator-source / denominator-type — the same axes coverage uses) and whether higher-level lines were apportioned (cost-allocation). Want full and delivery-only side by side? Two reports, exactly as administrative and survey coverage are two reports (cost-v1)."
* ^experimental = false
* obeys icr-cost-report-divisor
* status MS
* type MS
* measure MS
* measure = "https://icr.healthcampaigns.org/Measure/icr-campaign-cost"
* measure ^short = "Fixed: the canonical icr-campaign-cost Measure"
* period 1..1 MS
* period ^short = "The campaign / round period the figures cover"
* reporter 1..1 MS
* reporter ^short = "Who computed / signed off the figures — the DHMT, the national programme, a costing study team (Organization) or the accountable officer"
* group 1..* MS
* group.code 1..1 MS
* group.code from ICRCostFigureVS (required)
* group.code ^short = "Which figure this group carries: total-cost | per-person-targeted | per-person-reached | per-dose-delivered"
* group.population MS
* group.population.count MS
* group.population ^short = "On the unit-cost groups: the divisor as a denominator count (planning denominator / persons reached / doses delivered) — required (icr-cost-report-divisor)"
* group.measureScore 1..1 MS
* group.measureScore.value 1..1 MS
* group.measureScore.system 1..1 MS
* group.measureScore.system = $ISO4217
* group.measureScore.code 1..1 MS
* group.measureScore ^short = "The figure as a currency Quantity (system urn:iso:std:iso:4217); unit text says 'per person reached' etc. — UCUM has no currency-per-person unit"
* group.stratifier MS
* group.stratifier.code from ICRCoverageStratifierVS (extensible)
* group.stratifier ^short = "Disaggregation: cost-category and funding-source on the total; geography and delivery-strategy on the unit costs — the shared stratifier vocabulary (ICRCoverageStratifierVS, extensible)"
* group.stratifier.stratum.measureScore MS
* evaluatedResource MS
* evaluatedResource ^short = "The inputs: the ICRCampaignCost line items summed, the coverage MeasureReport whose numerator was the divisor, and any higher-level lines apportioned in"
* extension contains
    Campaign named campaign 1..1 MS and
    CostLineage named costLineage 1..1 MS and
    CostPerspective named costPerspective 0..1 MS and
    CostScope named costScope 1..1 MS and
    CostAllocation named costAllocation 0..1 MS and
    DenominatorSource named denominatorSource 0..1 MS and
    DenominatorType named denominatorType 0..1 MS and
    RealtimeVsReconciled named dataLineage 1..1 MS
* extension[campaign] ^short = "The campaign (round or umbrella) the figures report against — the direct MeasureReport→ICRCampaign join, as on the coverage profiles"
* extension[costLineage] ^short = "budgeted | actual — a report never mixes the two"
* extension[costPerspective] ^short = "financial | economic; absent ⇒ financial"
* extension[costScope] ^short = "full | delivery-only — required; commodity value is the biggest swing between otherwise comparable unit costs"
* extension[costAllocation] ^short = "direct (subtree lines only) | fully-loaded (plus an apportioned share of umbrella lines, method stated); absent ⇒ direct"
* extension[denominatorSource] ^short = "Provenance of the planning denominator the per-person-targeted figure divided by"
* extension[denominatorType] ^short = "total-population vs at-risk — which denominator the per-person-targeted figure used"
* extension[dataLineage] ^short = "Required: preliminary in-campaign figures (realtime) vs close-out figures (reconciled) — inherited from the coverage report the divisor came from"
