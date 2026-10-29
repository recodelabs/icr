#!/usr/bin/env python3
"""Write the DIGIT demo warehouse's own ViewDefinitions (views/Digit*.json).

The IG's ViewDefinitions cover campaigns, activities, targets and tasks. The DIGIT dashboards
also need the delivery events, supply records, households, people, locations without geometry
and the protocol and activity names, which the IG has no views for yet. These are those views,
in the same SQL-on-FHIR form as the IG's, so fhir-pipes runs them alongside. If the IG gains
views that cover the same ground, drop these.

Run it after editing: python3 country/digit/views/make.py
"""
import json
from pathlib import Path

ICR = "https://icr.healthcampaigns.org"
SD = f"{ICR}/StructureDefinition"
VD = "https://sql-on-fhir.org/ig/StructureDefinition/ViewDefinition"
HERE = Path(__file__).parent


def col(name, path, type_="string", description=None):
    c = {"name": name, "path": path, "type": type_}
    if description:
        c["description"] = description
    return c


def ext(name, value):
    return f"extension('{SD}/{name}').value.ofType({value})"


def view(name, title, resource, description, select, where=None):
    v = {
        "resourceType": VD,
        "url": f"{ICR}/ViewDefinition/{name}",
        "name": name,
        "title": title,
        "status": "draft",
        "description": description,
        "fhirVersion": ["4.0.1"],
        "resource": resource,
    }
    if where:
        v["where"] = [{"path": w} for w in where]
    v["select"] = select
    (HERE / f"{name}.json").write_text(json.dumps(v, indent=2, ensure_ascii=False) + "\n")


view("DigitLocation", "DIGIT locations", "Location",
     "One row per Location, with or without coordinates: boundaries (admin units, which on the DIGIT "
     "server have no geometry), facilities and household dwellings. fhir-pipes' location table leaves "
     "out locations without geometry, so this view is the source for the boundary hierarchies.",
     [{"column": [
         col("location_id", "getResourceKey()", "id"),
         col("name", "name"),
         col("status", "status", "code"),
         col("type", f"type.coding.where(system = '{ICR}/CodeSystem/icr-location-type-cs').code.first()", "code",
             "admin-unit | facility | dwelling | …"),
         col("type_text", "type.where(coding.empty()).text.first()", "string",
             "DIGIT's own type, e.g. 'PHU (DIGIT SIERRALEONE hierarchy, level 7)'"),
         col("part_of_id", "partOf.getReferenceKey(Location)"),
         col("boundary_system", "identifier.where(system.contains('/digit-demo/boundary/')).system.first()", "uri",
             "The boundary code's identifier system; its last segment names the DIGIT hierarchy"),
         col("boundary_code", "identifier.where(system.contains('/digit-demo/boundary/')).value.first()"),
         col("code", "identifier.value.first()", "string", "The first identifier (DIGIT code or id)"),
         col("organization_id", "managingOrganization.getReferenceKey(Organization)"),
         col("pcode", f"identifier.where(system = '{ICR}/identifiers/pcode').value.first()", "string",
             "P-code, on the Nigerian states and LGAs matched to GRID3"),
         col("icr_location_id", f"identifier.where(system = '{ICR}/identifiers/icr-location').value.first()", "string",
             "The matching Location in the ICR's location registry (e.g. nga-na)"),
         col("alias", "alias.first()", "string", "GRID3's spelling, where it differs"),
         col("has_boundary", f"extension('{SD}/location-boundary-geojson').exists()", "boolean",
             "Whether the Location carries a boundary (GRID3, from the ICR's registry)"),
         col("lat", "position.latitude", "decimal"),
         col("lon", "position.longitude", "decimal"),
     ]}])

view("DigitHousehold", "DIGIT households", "Group",
     "One row per household (ICRDeliveryUnit: Group, actual = true).",
     [{"column": [
         col("group_id", "getResourceKey()", "id"),
         col("name", "name"),
         col("active", "active", "boolean"),
         col("quantity", "quantity", "unsignedInt", "Number of members"),
         col("location_id", ext("group-location", "Reference") + ".getReferenceKey(Location)", "string",
             "The dwelling Location"),
         col("household_code", f"identifier.where(system = '{ICR}/identifiers/digit-demo/household').value.first()"),
     ]}],
     where=["actual = true"])

view("DigitPatient", "DIGIT people", "Patient",
     "One row per Patient (the people registered in households).",
     [{"column": [
         col("patient_id", "getResourceKey()", "id"),
         col("gender", "gender", "code"),
         col("birth_date", "birthDate", "date"),
         col("deceased", "deceased.ofType(boolean)", "boolean"),
     ]}])

view("DigitMedicationAdministration", "DIGIT drug administrations", "MedicationAdministration",
     "One row per MedicationAdministration: a drug given (completed) or not given (not-done) to a "
     "person in a campaign visit.",
     [{"column": [
         col("event_id", "getResourceKey()", "id"),
         col("status", "status", "code"),
         col("status_reason", "statusReason.first().coding.first().code", "code"),
         col("status_reason_text", "statusReason.first().text"),
         col("campaign_id", ext("campaign", "Reference") + ".getReferenceKey(CarePlan)"),
         col("activity", ext("campaign-activity", "canonical"), "canonical"),
         col("patient_id", "subject.getReferenceKey(Patient)"),
         col("effective", "effective.ofType(dateTime)", "dateTime"),
         col("medication_code", "medication.ofType(CodeableConcept).coding.where(system = 'http://www.whocc.no/atc').code.first()", "code"),
         col("medication", "medication.ofType(CodeableConcept).text"),
         col("dose_value", "dosage.dose.value", "decimal"),
         col("dose_unit", "dosage.dose.unit"),
         col("directly_observed", ext("directly-observed-consumption", "boolean"), "boolean"),
     ]}])

view("DigitImmunization", "DIGIT vaccinations", "Immunization",
     "One row per Immunization given (completed) or not given (not-done) in a campaign.",
     [{"column": [
         col("event_id", "getResourceKey()", "id"),
         col("status", "status", "code"),
         col("status_reason", "statusReason.coding.first().code", "code"),
         col("campaign_id", ext("campaign", "Reference") + ".getReferenceKey(CarePlan)"),
         col("activity", ext("campaign-activity", "canonical"), "canonical"),
         col("patient_id", "patient.getReferenceKey(Patient)"),
         col("occurrence", "occurrence.ofType(dateTime)", "dateTime"),
         col("vaccine_code", "vaccineCode.coding.first().code", "code"),
         col("vaccine", "vaccineCode.text"),
         col("location_id", "location.getReferenceKey(Location)"),
         col("dose_value", "doseQuantity.value", "decimal"),
     ]}])

SA = f"extension('{SD}/stock-accountability')"
view("DigitSupplyDelivery", "DIGIT supply records", "SupplyDelivery",
     "One row per SupplyDelivery: distributions to households (ICRSupplyDistribution) and stock "
     "movements between facilities and teams (ICRSupplyMovement), told apart by `profile`.",
     [{"column": [
         col("supply_id", "getResourceKey()", "id"),
         col("profile", "meta.profile.first()", "canonical"),
         col("status", "status", "code", "completed (received) | in-progress (dispatched, not received) | …"),
         col("campaign_id", ext("campaign", "Reference") + ".getReferenceKey(CarePlan)"),
         col("activity", ext("campaign-activity", "canonical"), "canonical"),
         col("item_class", f"suppliedItem.item.ofType(CodeableConcept).coding.where(system = '{ICR}/CodeSystem/icr-commodity-class-cs').code.first()", "code"),
         col("item_code", "suppliedItem.item.ofType(CodeableConcept).coding.first().code", "code"),
         col("item", "suppliedItem.item.ofType(CodeableConcept).text"),
         col("quantity", "suppliedItem.quantity.value", "decimal"),
         col("unit", "suppliedItem.quantity.unit"),
         col("supplier", "supplier.reference", "string", "Organization, Practitioner or Location reference"),
         col("destination_id", "destination.getReferenceKey(Location)"),
         col("recipient_group_id", ext("distribution-recipient", "Reference") + ".getReferenceKey(Group)"),
         col("issued_to_team_id", ext("issued-to-team", "Reference") + ".getReferenceKey(CareTeam)"),
         col("part_of_id", "partOf.first().getReferenceKey(SupplyDelivery)"),
         col("occurrence", "occurrence.ofType(dateTime)", "dateTime"),
         col("returned", f"{SA}.extension('returned').value.ofType(Quantity).value", "decimal"),
         col("not_usable", f"{SA}.extension('notUsable').value.ofType(Quantity).value", "decimal"),
     ]}])

view("DigitTaskOutput", "DIGIT task outputs", "Task",
     "One row per Task output (registered household, delivery event, missed or refusal reason, "
     "counts), with the Task's campaign and status.",
     [{"column": [
         col("task_id", "getResourceKey()", "id"),
         col("campaign_id", "basedOn.first().getReferenceKey(CarePlan)"),
         col("status", "status", "code"),
         col("code", "code.text"),
     ]},
      {"forEach": "output", "column": [
          col("output_type", "type.coding.first().code", "code"),
          col("value_code", "value.ofType(CodeableConcept).coding.first().code", "code"),
          col("value_text", "value.ofType(CodeableConcept).text"),
          col("value_count", "value.ofType(unsignedInt)", "unsignedInt"),
          col("value_reference", "value.ofType(Reference).reference"),
      ]}],
     where=["basedOn.exists()"])

view("DigitActivity", "DIGIT campaign activities", "ActivityDefinition",
     "One row per ActivityDefinition (ICRCampaignActivity): the activity's title and product.",
     [{"column": [
         col("activity_id", "getResourceKey()", "id"),
         col("url", "url", "uri"),
         col("title", "title"),
         col("code", "code.text"),
         col("campaign_type", "topic.first().coding.first().code", "code"),
         col("product_class", f"product.ofType(CodeableConcept).coding.where(system = '{ICR}/CodeSystem/icr-commodity-class-cs').code.first()", "code"),
         col("product_atc", "product.ofType(CodeableConcept).coding.where(system = 'http://www.whocc.no/atc').code.first()", "code"),
         col("product", "product.ofType(CodeableConcept).text"),
     ]}])

view("DigitCampaignPeriod", "DIGIT campaign periods", "CarePlan",
     "One row per campaign with its period as dateTimes. IcrCampaignCalendar writes the period as "
     "dates, and DIGIT's periods start at local midnight in India Standard Time (18:30 UTC the day "
     "before), so the date alone is a day early.",
     [{"column": [
         col("campaign_id", "getResourceKey()", "id"),
         col("period_start", "period.start", "dateTime"),
         col("period_end", "period.end", "dateTime"),
     ]}])

view("DigitProtocol", "DIGIT campaign protocols", "PlanDefinition",
     "One row per PlanDefinition (ICRCampaignProtocol): DIGIT's project types.",
     [{"column": [
         col("protocol_id", "getResourceKey()", "id"),
         col("url", "url", "uri"),
         col("title", "title"),
         col("name", "name"),
     ]}])
