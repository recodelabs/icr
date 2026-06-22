// Person-data governance (working doc §6.4 privacy, §14).
// Because the registry holds named individuals (ICRPatient), consent/permission
// for collecting, storing, and — critically — sharing a person's campaign data
// travels with the person. A v1 starting point, not the final governance model.

Profile: ICRConsent
Parent: Consent
Id: ICRConsent
Title: "ICR Consent (Person-Data Governance)"
Description: "Records the permission governing collection, storage, and cross-border sharing of a registered individual's (or a household's) campaign data. A v1 starting point: ICR holds named people (ICRPatient, §6.4), so a privacy/sharing permission and its scope are first-class. The grantor is typically the head of household or caregiver; the subject is the ICRPatient the data is about."
* ^experimental = false
* status MS
* status ^short = "draft | proposed | active | rejected | inactive | entered-in-error"
* scope MS
* scope ^short = "Use #patient-privacy for ICR data-governance consents"
* category MS
* patient 1..1 MS
* patient only Reference(ICRPatient)
* patient ^short = "The registered individual this consent is about"
* dateTime MS
* performer MS
* performer ^short = "Who granted it — typically the head of household or caregiver"
* policyRule MS
* policyRule ^short = "The data-governance policy this consent is taken under (placeholder text until the policy is published)"
* provision MS
* provision.type MS
* provision.type ^short = "permit | deny"
* provision.purpose MS
* provision.purpose ^short = "What the permission covers — e.g. cross-border sharing vs in-country use only"
