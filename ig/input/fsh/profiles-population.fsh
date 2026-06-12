// Population & geography profiles (working doc §7.5–§7.7, §9).
// Household = Group + Location (the validated Ona pattern); target population =
// conceptual Group with denominator provenance; Location is the most-customized
// resource — multi-identifier with GERS as the cross-campaign join key.

Profile: ICRHousehold
Parent: Group
Id: ICRHousehold
Title: "ICR Household"
Description: "A household: Group (who lives there) + Location (the dwelling, via the household-location extension). The dwelling Location carries the Overture GERS building ID, giving the household stable identity across campaigns (working doc §7.5, §9.1)."
* ^experimental = false
* type = #person
* actual = true
* member MS
* member.entity only Reference(Patient)
* member.entity ^short = "Household members, where person-level data is collected"
* quantity MS
* quantity ^short = "Household size where individuals are not enumerated"
* extension contains HouseholdLocation named householdLocation 1..1 MS

Profile: ICRTargetPopulation
Parent: Group
Id: ICRTargetPopulation
Title: "ICR Target Population"
Description: "A target-population denominator: a conceptual cohort (actual=false) with a count, eligibility characteristics, and — critically — source and date provenance. Multiple competing estimates per geography are retained; exactly one is flagged as the planning denominator (working doc §7.6, §4.2)."
* ^experimental = false
* type = #person
* actual = false
* quantity 1..1 MS
* quantity ^short = "The denominator count"
* characteristic MS
* characteristic ^short = "Age band, sex, eligibility rule, geography"
* extension contains
    DenominatorSource named denominatorSource 1..1 MS and
    EstimateDate named estimateDate 1..1 MS and
    IsPlanningDenominator named isPlanningDenominator 0..1 MS and
    EstimateConfidence named confidence 0..1

Profile: ICRLocation
Parent: Location
Id: ICRLocation
Title: "ICR Location"
Description: "The most-customized ICR resource: nested administrative hierarchy (6+ levels in campaign countries), operational geography linkable-but-distinct from admin units, GeoJSON boundaries, and multi-system geospatial identity — Overture Maps GERS IDs (building / place / division) as the preferred cross-campaign join key, with P-codes and national codes as coequal aliases (working doc §7.7, §9)."
* ^experimental = false
* name MS
* status MS
* partOf only Reference(ICRLocation)
* partOf MS
* partOf ^short = "Nested admin hierarchy: country → region → district → ward → settlement"
* physicalType MS
* physicalType ^short = "jurisdiction / site / building / household"
* type MS
* type ^short = "facility / school / community-distribution-point / temporary-post / household"
* position MS
* position ^short = "GPS point (longitude/latitude/altitude)"
* identifier MS
* identifier ^slicing.discriminator.type = #value
* identifier ^slicing.discriminator.path = "system"
* identifier ^slicing.rules = #open
* identifier ^short = "Multi-system identity: GERS (preferred cross-campaign join key), P-code, national codes"
* identifier contains
    gers 0..1 MS and
    pcode 0..1 MS
* identifier[gers].system = $GERSId
* identifier[gers] ^short = "Overture Maps GERS ID (building / place / division). Record the Overture release version alongside (working doc §9.1)."
* identifier[pcode].system = $PCode
* identifier[pcode] ^short = "OCHA P-code for administrative units"
* extension contains
    LocationBoundaryGeoJson named boundary 0..1 MS and
    DeliveryStrategy named deliveryStrategy 0..1
* extension[boundary] ^short = "District polygon, settlement area, or catchment zone — the geometry Crosscut enriches and pushes back"
* extension[deliveryStrategy] ^short = "For delivery sites (fixed/temporary posts): the strategy this site serves"
