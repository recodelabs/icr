// ConceptMaps (working doc §17.2 C1, §18.3/§18.4; espen-v4 round).
// ICR adverse-event causality ↔ WHO SMART Immunizations AEFI causality. ICR's
// codes are the top-level WHO/CIOMS categories (A/B/C/D); the immunization arm of
// ICRAdverseEvent is meant to specialize WHO IMMZ.AdverseEvent, so a campaign AEFI
// is a valid WHO immunization adverse event. TARGET CODES ARE PROVISIONAL — confirm
// against the published smart.who.int/immunizations IG before relying on them.

Instance: icr-aefi-causality-to-immz
InstanceOf: ConceptMap
Title: "ICR ↔ WHO IMMZ AEFI Causality"
Usage: #definition
* url = "https://icr.healthcampaigns.org/ConceptMap/icr-aefi-causality-to-immz"
* status = #draft
* experimental = false
* name = "ICRAEFICausalityToIMMZ"
* description = "Maps ICRAdverseEventCausalityCS (WHO/CIOMS A/B/C/D) to the WHO SMART Immunizations AEFI causality categories. Provisional — target codes to be confirmed against the published IMMZ IG (§18.3)."
* sourceCanonical = "https://icr.healthcampaigns.org/ValueSet/icr-adverse-event-causality"
* targetCanonical = "http://smart.who.int/immunizations/ValueSet/IMMZ-aefi-causality"
* group.source = $AdverseEventCausality
* group.target = $IMMZAdverseEventCausality
* group.element[0].code = #a-consistent
* group.element[0].display = "A — Consistent causal association"
* group.element[0].target.code = #A
* group.element[0].target.display = "Consistent causal association to immunization"
* group.element[0].target.equivalence = #equivalent
* group.element[1].code = #b-indeterminate
* group.element[1].display = "B — Indeterminate"
* group.element[1].target.code = #B
* group.element[1].target.display = "Indeterminate"
* group.element[1].target.equivalence = #equivalent
* group.element[2].code = #c-coincidental
* group.element[2].display = "C — Coincidental / inconsistent"
* group.element[2].target.code = #C
* group.element[2].target.display = "Coincidental (inconsistent causal association)"
* group.element[2].target.equivalence = #equivalent
* group.element[3].code = #d-unclassifiable
* group.element[3].display = "D — Unclassifiable"
* group.element[3].target.code = #D
* group.element[3].target.display = "Unclassifiable"
* group.element[3].target.equivalence = #equivalent
