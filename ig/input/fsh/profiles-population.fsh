// Population & geography profiles (working doc §7.5–§7.7, §9).
// Delivery unit = Group + Location (the validated Ona pattern, generalized from
// household to household-or-community); target population = conceptual Group with
// denominator provenance and a computable geography characteristic; Location is the
// most-customized resource — multi-identifier with GERS as the cross-campaign join key.

Profile: ICRDeliveryUnit
Parent: Group
Id: ICRDeliveryUnit
Title: "ICR Delivery Unit (Household / Community)"
Description: "The actual Group of people a campaign Task acts on — a household (Type B house-to-house), a community (Type C MDA), or a school cohort (school-based delivery), distinguished by the required group-kind code. The validated Group + Location pattern, generalized: the Group is who, the Location (group-location extension) is where it lives or is based — the dwelling for a household, the settlement or community point for a community, the school for a school cohort — with the Location carrying the Overture GERS ID for stable cross-campaign identity. Type A's delivery unit is a site, which is a Location, not a Group (working doc §3.2, §7.5, §9.1)."
* ^experimental = false
* type = #person
* actual = true
* code 1..1 MS
* code from ICRGroupKindVS (required)
* code ^short = "household | community | school-cohort"
* member MS
* member.entity only Reference(Patient)
* member.entity ^short = "Members, where person-level data is collected"
* quantity MS
* quantity ^short = "Group size where individuals are not enumerated"
* extension contains GroupLocation named groupLocation 1..1 MS
* extension[groupLocation] ^short = "Residence/base, not service point: the dwelling (household), settlement/community point (community), or school (school-cohort)"

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
* characteristic ^slicing.discriminator.type = #pattern
* characteristic ^slicing.discriminator.path = "code"
* characteristic ^slicing.rules = #open
* characteristic contains geography 0..1 MS
* characteristic[geography].code = $GroupCharacteristic#geography
* characteristic[geography] ^short = "The Location this estimate is scoped to — any level: country, district, ward, settlement, or operational area. Makes estimates computably joinable to the location hierarchy."
* characteristic[geography].value[x] only Reference(ICRLocation)
* characteristic[geography].exclude = false
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
* type from ICRLocationTypeVS (extensible)
* type ^short = "admin-unit / settlement / facility / school / community-distribution-point / temporary-post / household / supervisory-area / operational-area"
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
    DeliveryStrategy named deliveryStrategy 0..1 and
    OverlaysAdminUnit named overlaysAdminUnit 0..*
* extension[boundary] ^short = "District polygon, settlement area, or catchment zone — the geometry Crosscut enriches and pushes back"
* extension[deliveryStrategy] ^short = "For delivery sites (fixed/temporary posts): the strategy this site serves"
* extension[overlaysAdminUnit] ^short = "For operational geography (supervisory/operational areas): the admin unit(s) this area overlays — linkable-but-distinct from the admin hierarchy (working doc §9)"
