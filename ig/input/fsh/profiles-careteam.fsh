// Team & supervision (working doc §5.5; §17.3; espen-v3 round).
// ICRCareTeam answers "who did this work, and who is accountable for this number":
// the vaccinators/CDDs who deliver and the supervisor who oversees them and very
// often files the report (MeasureReport.reporter). ICRSupervisionReport is a
// LIGHTWEIGHT v1 mechanism for supervision-visit findings (ESPEN Forms 5 & 6) — an
// Observation with checklist components — pending the fuller supervision/QA +
// microplan/stock-readiness/social-mobilization bundle scoped for the next round
// (working doc §17.3).

Profile: ICRCareTeam
Parent: CareTeam
Id: ICRCareTeam
Title: "ICR Care Team"
Description: "The campaign delivery team — the vaccinators/CDDs who do the work and the supervisor who oversees them and typically files the report. Referenced from ICRCampaign.careTeam (the roster) and Task.owner/Task.performer (the team that worked a Task); the supervisor surfaces again as the MeasureReport.reporter on rolled-up coverage and often owns the supervisory-area Location via the oversees-area extension (working doc §5.5)."
* ^experimental = false
* status MS
* name MS
* name ^short = "Human-readable team label (replaces today's display-only Task.owner string)"
* subject MS
* subject only Reference(ICRTargetPopulation)
* subject ^short = "The campaign/population the team serves"
* participant 1..* MS
* participant.role 1..1 MS
* participant.role from ICRTeamRoleVS (extensible)
* participant.role ^short = "vaccinator | cdd | supervisor | social-mobilizer | recorder"
* participant.member MS
* participant.member only Reference(Practitioner or PractitionerRole or RelatedPerson)
* participant.member ^short = "The CDD/vaccinator/supervisor — a community volunteer is a RelatedPerson"
* managingOrganization MS
* managingOrganization ^short = "Implementing partner / district health office (also carries supervisor level)"
* extension contains OverseesArea named overseesArea 0..* MS
* extension[overseesArea] ^short = "Supervisory-area Location(s) this team's supervisor covers (§6.3)"

Profile: ICRSupervisionReport
Parent: Observation
Id: ICRSupervisionReport
Title: "ICR Supervision Report"
Description: "A LIGHTWEIGHT v1 record of a supervision-visit finding (ESPEN Forms 5 health-facility and 6 CDD-observation): an Observation whose subject is the supervised area/community, performer is the supervisor (CareTeam), and components carry the checklist items (supplies present, DOC observed, height-chart used correctly, stock concordance, population informed…). A deliberate stopgap — the full supervision/QA profile with workforce, stock-readiness and social-mobilization structure is scoped for the next major round (working doc §17.3)."
* ^experimental = false
* status MS
* code MS
* code ^short = "What was assessed — e.g. 'MDA supervision visit' / a specific checklist topic (text or local code)"
* subject MS
* subject only Reference(ICRDeliveryUnit or ICRLocation)
* subject ^short = "The supervised community/household or settlement/area"
* effective[x] MS
* performer MS
* performer ^short = "The supervisor / supervising team (reference an ICRCareTeam)"
* component MS
* component ^short = "One checklist item per component: component.code = the question, component.value = the answer (boolean/coded/count)"
