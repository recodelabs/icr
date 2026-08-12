// Team & supervision (working doc §5.5; §17.3; espen-v3/v4 rounds).
// ICRCareTeam answers "who did this work, and who is accountable for this number":
// the vaccinators/CDDs who deliver and the supervisor who oversees them and very
// often files the report (MeasureReport.reporter). v0.20.0 adds the microplan
// team-workload (oversees-area + workload-target) so the CareTeam is the typed
// team-area-workload unit. ICRSupervisionReport is now a STRUCTURED supervision/QA
// profile on QuestionnaireResponse, driven by the icr-mda-supervision-checklist
// Questionnaire (replacing the v0.19 lightweight text-component Observation).

Profile: ICRCareTeam
Parent: CareTeam
Id: ICRCareTeam
Title: "ICR Care Team"
Description: "The campaign delivery team — the vaccinators/CDDs who do the work and the supervisor who oversees them and typically files the report. Referenced from ICRCampaign.careTeam (the roster) and Task.owner/Task.performer (the team that worked a Task); the supervisor surfaces again as the MeasureReport.reporter on rolled-up coverage and often owns the supervisory-area Location via the oversees-area extension. With workload-target it carries the microplan workload assigned to the team (working doc §5.5, §17.3)."
* ^experimental = false
* status MS
* name MS
* name ^short = "Human-readable team label (the target of Task.owner)"
* subject MS
* subject only Reference(ICRTargetPopulation)
* subject ^short = "The campaign/population the team serves"
* participant 1..* MS
* participant.role 1..1 MS
* participant.role from ICRTeamRoleVS (extensible)
* participant.role ^short = "vaccinator | cdd | supervisor | social-mobilizer | enumerator"
* participant.member MS
* participant.member only Reference(Practitioner or PractitionerRole or RelatedPerson)
* participant.member ^short = "The CDD/vaccinator/supervisor — a community volunteer is a RelatedPerson"
* managingOrganization MS
* managingOrganization ^short = "Implementing partner / district health office (also carries supervisor level)"
* extension contains
    OverseesArea named overseesArea 0..* MS and
    WorkloadTarget named workloadTarget 0..1 MS
* extension[overseesArea] ^short = "Supervisory-area Location(s) this team's supervisor covers (§6.3)"
* extension[workloadTarget] ^short = "Microplan workload assigned to this team — area(s) + expected population/households/days (v0.20.0)"

Profile: ICRSupervisionReport
Parent: QuestionnaireResponse
Id: ICRSupervisionReport
Title: "ICR Supervision Report"
Description: "A STRUCTURED supervision-visit / QA record (ESPEN Forms 5 health-facility and 6 CDD-observation): a QuestionnaireResponse against the icr-mda-supervision-checklist Questionnaire, so each checklist answer (supplies present, DOC observed, height-chart used correctly, stock concordance, population informed, channels used…) links to a defined, coded question. Subject is the supervised area/community; author is the individual supervisor (Practitioner/PractitionerRole) or supervising Organization — R4 QuestionnaireResponse.author cannot reference a CareTeam. Replaces the v0.19 lightweight text-component Observation (working doc §17.3)."
* ^experimental = false
* questionnaire 1..1 MS
* questionnaire ^short = "The supervision checklist this answers — icr-mda-supervision-checklist"
* status MS
* subject MS
* subject only Reference(ICRDeliveryUnit or ICRLocation)
* subject ^short = "The supervised community/household or settlement/area"
* authored MS
* author MS
* author only Reference(Practitioner or PractitionerRole or Organization)
* author ^short = "The supervisor (Practitioner/PractitionerRole) or supervising organization — QuestionnaireResponse.author cannot be a CareTeam; the team is reached via the supervisor's PractitionerRole / Task.owner"
* item MS
* item ^short = "One answered checklist item per question (linkId → answer)"
