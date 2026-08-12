// Team & supervision (working doc §5.5; §17.3; espen-v3/v4 rounds).
// ICRCareTeam answers "who did this work, and who is accountable for this number":
// the vaccinators/CDDs who deliver and the supervisor who oversees them and very
// often files the report (MeasureReport.reporter). v0.20.0 adds the microplan
// team-workload (oversees-area + workload-target) so the CareTeam is the typed
// team-area-workload unit. ICRCampaignFormResponse is the generic filled-campaign-form
// profile on QuestionnaireResponse — supervision, readiness, monitoring, and
// country-authored forms are all instances of it; the canonical Questionnaire a
// response answers is the type discriminator, so new form types cost a
// Questionnaire, never a profile (replaces the form-specific ICRSupervisionReport
// and the v0.19 lightweight text-component Observation).

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

Profile: ICRCampaignFormResponse
Parent: QuestionnaireResponse
Id: ICRCampaignFormResponse
Title: "ICR Campaign Form Response"
Description: "A filled-in campaign form — ONE generic profile for every structured form submission in a campaign: supervision visits (ESPEN Forms 5 health-facility and 6 CDD-observation via the icr-mda-supervision-checklist), pre-campaign readiness validations (icr-campaign-readiness-checklist), monitoring checks, and country-authored forms. The canonical Questionnaire a response answers is the TYPE DISCRIMINATOR — 'all supervision reports' is a query on the questionnaire canonical, and analytics key on the form's coded linkIds — so new form types cost a Questionnaire, never a new profile. basedOn ties every submission to its campaign (round); subject is the delivery unit or place the form is about; author is the individual (Practitioner/PractitionerRole) or Organization who filed it — R4 QuestionnaireResponse.author cannot reference a CareTeam. Replaces the form-specific ICRSupervisionReport (working doc §17.3, §4.6–4.7)."
* ^experimental = false
* questionnaire 1..1 MS
* questionnaire ^short = "The canonical campaign form this answers (e.g. icr-mda-supervision-checklist, icr-campaign-readiness-checklist) — the form type discriminator"
* status MS
* basedOn MS
* basedOn only Reference(ICRCampaign)
* basedOn ^short = "The campaign (round) this submission belongs to — makes every filled form attributable to its round"
* subject MS
* subject only Reference(ICRDeliveryUnit or ICRLocation)
* subject ^short = "What the form is about: the delivery-unit Group (household/community/school cohort) or the settlement/area/site Location"
* authored MS
* author MS
* author only Reference(Practitioner or PractitionerRole or Organization)
* author ^short = "The individual (Practitioner/PractitionerRole) or organization who filed the form — QuestionnaireResponse.author cannot be a CareTeam; the team is reached via the author's PractitionerRole / Task.owner"
* item MS
* item ^short = "One answered form item per question (linkId → answer)"
