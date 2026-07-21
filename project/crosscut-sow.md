# Crosscut SOW
# **Phase 1: IG Development Support (Months 1–2) - $10,360**
Crosscut participates in the FHIR Implementation Guide (IG) design process, contributing domain expertise in geospatial microplanning and campaign data flows. 
## **1.1 - IG Review: General review - $4,000**
**Lead:** James McKinnon

Support design of the initial HL7 FHIR IG through a detailed review of the draft, providing comments and suggested edits. This includes cross-referencing the data model against typical NTD microplan data, WHO JAP reporting requirements for NTD programs, known CommCare/ODK data models in use by NTD implementing partners, supply chain management requirements.
## **1.2 - IG Review: Crosscut App Integration Requirements - $3,360**
**Lead:** Brianna Poulos, Coite Manuel

Review the draft IG from Crosscut's perspective as a geospatial data consumer. Specifically review and provide feedback on:  
• FHIR Location resource extensions for GeoJSON boundary polygons, administrative hierarchies, and multi-identifier systems (P-codes, Overture GERS IDs, national facility codes)  
• CarePlan/Task resource structure for representing campaign execution at geographic units  
• Data elements needed for Crosscut App to generate catchment areas to pass back to ICR (e.g. site coordinates, population data, administrative level assignments)

• Data elements needed for Crosscut App to generate geospatial layers (e.g. travel time isochrone layer) to pass back to ICR (e.g. travel time color thresholds)  
• Terminology ValueSets relevant to microplanning outputs (campaign types, drug/vaccine products, reporting indicators)
## **1.3 - Integration Request/Response Schema Design - $3,000**
**Lead:** Brianna Poulos, Sam Hoogewind

Author the technical schema that defines data exchange between the ICR (via OpenFn) and the Crosscut API. This covers:  
• Input schema: structure for pushing geographic hierarchies, geocoded sites, campaign events, and survey data to Crosscut, including required vs. optional fields, coordinate formats, and attribute specifications  
• Output schema: structure for returning catchment area polygons with attributes, accessibility/isochrone layers, and tile references  
• Parameter schema: how external callers specify desired algorithm type (site-based, settlement-based), travel-time/distance limits, population thresholds, and output format preferences  
• Error response schema: validation errors, partial success handling  
• Authentication and authorization model for API access by ICR/OpenFn
# **Phase 2: Platform Development and Country Pilots (Months 3–6) - $89,262**
  

- I would rather define what are the core APIs that need to be built within crosscut that support the current data model and then support the specific integration work via OpenFN.  Don’t want to spend the entire budget on API integrations and not adding new functionality to help address the needs of the project.
- Need to understand the use cases for viewing data within crosscut.  I think there is value but we need to discuss how crosscut fits in that capacity.
- Want to preserve budget for new activities which include the potential of new tools outside of crosscut and/or the new catchment area calculators ideas you showed me.

In summary - I’d like to do proper walk through of Crosscut platform to understand the proposed integrations and improvements to the project.  Ideally I would like to keep the Crosscut platform improvements to ~$40K so we can have ~$50K, for crosscut team to contribute to core tool building and innovations for the project.   We can shift this once we have better discussions on role of crosscut platform.  Right now the two main things are catchment area generation / data enrichment.  Data enrichment can be done generically with a lot of non-proprietary tools so I’m a bit on the fence on that and as an interface for microplanning.

Main thing is to leverage the Crosscut team to help bring your capabilities and experience to help figure out how to make the ICR work and be adopted.  That’s the core focus on the grant.  I want crosscut platform to play an important role in that but I am hoping to be able to work together to pursue new ideas / opportunities that emerge through this work where we think we can have the most impact.

  
  

Proposed Activities

- {==Strengthening of the Crosscut APIs and internal data models to meet ICR needs - $5K==}{>>This is what I want to rewrite this section to be based around.  Can you take the relevant items below (if any and flesh out these proposed activities section.<<}{id="c1" by="mberg" at="2026-07-21T18:38:07.016Z"}
- {==OpenFn Integrations for ingesting and exporting ICR and enriched data - $10K==}{>>This is what I want to rewrite this section to be based around.  Can you take the relevant items below (if any and flesh out these proposed activities section.<<}{id="c1" by="mberg" at="2026-07-21T18:38:07.016Z"}
- {==Static Asset / Map tile generation - $5K==}{>>This is what I want to rewrite this section to be based around.  Can you take the relevant items below (if any and flesh out these proposed activities section.<<}{id="c1" by="mberg" at="2026-07-21T18:38:07.016Z"}
- {==Crosscut App improvements - To better visualize ICR data - $10K==}{>>This is what I want to rewrite this section to be based around.  Can you take the relevant items below (if any and flesh out these proposed activities section.<<}{id="c1" by="mberg" at="2026-07-21T18:38:07.016Z"}
- {==Catchment area calculation and sharing - development of at least 2 new catchment areas approaches and ability to share.  - $30K==}{>>This is what I want to rewrite this section to be based around.  Can you take the relevant items below (if any and flesh out these proposed activities section.<<}{id="c1" by="mberg" at="2026-07-21T18:38:07.016Z"}
- {==New ICR tool development - eg. the community identifier / dedupper - $30K==}{>>This is what I want to rewrite this section to be based around.  Can you take the relevant items below (if any and flesh out these proposed activities section.<<}{id="c1" by="mberg" at="2026-07-21T18:38:07.016Z"}

This is the core development phase. Crosscut builds new API endpoints to receive data from the ICR, adapts the backend to transform FHIR-structured inputs into its internal data model, and exposes geospatial analysis capabilities as automated operations callable by external systems. Development follows two-week Agile sprints coordinated with Ona.
## **Data Ingestion API**
Build new API endpoints on the Crosscut backend that accept data pushed from the ICR via OpenFn. These endpoints supplement the current model where data is entered through the Crosscut frontend using a CSV.
### **2.1 — Geographic Hierarchy Ingestion Endpoint - $7,970**
**Lead:** Sam Hoogewind

Design and implement an API endpoint to receive geographic hierarchy data from the ICR. This data represents administrative boundaries (e.g. country → region → district → sub-district → ward → village/settlement) with polygon geometries and attributes.  
  
Technical scope:  
• New POST endpoint accepting structured geographic hierarchy data (derived from FHIR Location resources with GeoJSON extensions)  
• Transformation logic to map incoming hierarchy to Crosscut's internal admin boundary model (admin levels 0–5, boundary versions, land-block associations)  
• Storage following the existing Crosscut App data format (GeoJSON line-delimited files, FGB, etc.) so that the catchment engine can consume it without modification  
• Validation: coordinate integrity, hierarchy consistency (no orphaned nodes), polygon validity checks  
• Reconciliation with existing Crosscut App data where available (e.g., pilot countries where Crosscut already has boundaries)
### **2.2 — Geocoded Sites/Facilities Ingestion Endpoint - $1,596**
**Lead:** Sam Hoogewind

Design and implement an API endpoint to receive geocoded health facility and service delivery point data from the ICR.  
  
Technical scope:  
• New POST endpoint accepting structured facility data (derived from FHIR Location resources for health facilities, schools, community distribution sites)  
• Transformation to the CSV-equivalent format used internally by the Crosscut App for catchment job creation (fields: name, latitude, longitude, plus configurable attribute fields)  
• Site validation via Crosscut App (coordinate bounds, point-in-boundary checks, duplicate detection)  
• Support for incremental updates (adding/removing sites between campaign rounds)  
• Storage in Crosscut App (e.g. catchment job records, site data files)
### **2.3 — Campaign Event Data Ingestion Endpoint - $3,985**
**Lead:** Sam Hoogewind

Design and implement an API endpoint to receive geocoded campaign event data from the ICR. This is new functionality — the Crosscut backend does not currently store campaign execution data (e.g. doses administered, coverage results, commodity distribution records).  
  
Technical scope:  
• New POST endpoint accepting campaign event data with geographic coordinates and attributes (derived from FHIR Task, Immunization, MedicationAdministration, SupplyDelivery, and Observation resources)  
• Data model design for storing campaign events associated with catchment areas and geographic units  
• Association logic: link incoming events to existing land blocks and catchment areas using point-in-polygon matching  
• Support for real-time campaign monitoring data (partial results during active campaigns) and post-campaign reconciliation data
### **2.4 — Survey Data Ingestion Endpoint - $7,970**
**Lead:** Sam Hoogewind

Design and implement an API endpoint to receive geocoded survey/assessment data from the ICR (e.g., prevalence surveys, coverage surveys, WASH assessments).  
  
Technical scope:  
• New POST endpoint accepting survey data with geographic coordinates and typed attributes  
• Storage and association with geographic units (land blocks, admin areas)  
• Support for survey data as an input layer for risk scoring and prioritization analysis
## **Automated Geospatial Analysis API**
Expose Crosscut's core geospatial analysis capabilities as fully automated API operations that can be triggered programmatically by external systems (ICR/OpenFn), rather than requiring a Crosscut user to configure and initiate analysis through the frontend.
### **2.5 — On-Demand Catchment Analysis Endpoint - $2,390**
**Lead:** Sam Hoogewind

Build an API endpoint that accepts analysis parameters and triggers automated catchment delineation using the existing graph-catch engine.  
  
Technical scope:  
• New POST endpoint accepting analysis parameters:  
  - Algorithm type: site-based, settlement-based, and others as developed  
  - Limit parameters: travel-time (minutes), distance (km), target population  
  - Geographic scope: boundary ID, optional admin-level restrictions  
  - Reference to previously ingested sites and boundaries  
• Orchestration of the existing async catchment creation pipeline (catchment-assignment → merge → tile generation)  
• Job status polling endpoint for external callers to track progress  
• Result retrieval endpoint returning catchment polygons with attributes (GeoJSON)  
  
The underlying catchment algorithms in Crosscut App do not need modification — this activity wraps the existing pipeline with an externally-callable API layer. The current backend already supports this flow for Crosscut frontend users; the work here is to create equivalent endpoints accessible to the ICR/OpenFn with appropriate authentication.
### **2.6 — Accessibility/Isochrone Layer Exposure - $6,375**
**Lead:** Sam Hoogewind

Expose the travel-time/accessibility data that Crosscut App already generates as retrievable outputs for external consumers.  
  
Technical scope:  
• Currently, travel-time heatmap data (walking/driving isochrones with configurable time-band thresholds) is generated by Crosscut App and served as MVT tiles, but only accessible to authenticated Crosscut frontend users  
• Build an API mechanism for external consumers to access these layers — options include:  
  - Tile URL endpoint with ICR-scoped authentication tokens  
  - Static tile file generation and export (pre-rendered tilesets)  
  - GeoJSON/FlatGeoBuf export of isochrone polygons  
• The specific approach depends on how downstream consumers (DHIS2 Maps, IASO, ODK) will render the data — this will be determined during schema design (Activity 1.3)
## **Output and Enrichment Pushback**
### **2.7 — Enriched Data Export to ICR - $2,390**
**Lead:** Sam Hoogewind

Build the mechanism to push Crosscut's enriched geospatial outputs back to the ICR.  
  
Technical scope:  
• Export catchment area polygons with attributes (assigned sites, population estimates, area in km², admin assignments) in a format compatible with the ICR FHIR store  
• Export population estimates and other available attributes at the catchment/admin-area level  
• Export supply plan parameters (drug/commodity quantities derived from population estimates)  
• The pushback mechanism may go through the ICR FHIR store (via OpenFn)  
• API endpoint(s) or webhook mechanism for the ICR to retrieve completed results  
  
This creates the bidirectional flow described in the proposal: data flows from the ICR into Crosscut for analysis, and enriched data flows back to strengthen both the registry and downstream planning workflows.
### **2.8 — Static Open Tile Generation for Offline Use - $6,375**
**Lead:** Sam Hoogewind

Generate pre-rendered tile sets that can be served without Crosscut's Lambda tile server infrastructure, enabling offline or low-connectivity use by field teams.  
  
Technical scope:  
• Extend the existing tile pipeline to produce downloadable static tile packages  
• Output as MBTiles, PMTiles, or equivalent static tile format  
• Include catchment boundaries, population layers, and accessibility heatmaps  
• Package for distribution via the ICR or direct download
## **Systems Integration**
Harden the integration for production use and complete the two-way integration with the WHO ESPEN Geospatial Microplanner.
### **2.9 — Two-Way WHO ESPEN Geospatial Microplanner Integration - $7,970**
**Lead:** Emmanuel Koh

Build the bidirectional data flow between the ICR and the WHO ESPEN Geospatial Microplanner (which is powered by Crosscut).  
  
Technical scope:  
• Extend the Crosscut platform to consume FHIR data from the ICR for use in the ESPEN Microplanner context — e.g., health facility locations, survey data, campaign targets defined in the ICR can be imported into the Microplanner to define catchment areas, assign population estimates, calculate risk scores, and delineate supervisory zones  
• Push enriched Microplanner outputs (catchment areas, population estimates, treatment plans, supply estimates) back into the ICR FHIR store  
• Leverage Emmanuel Koh's existing relationships with the ESPEN API and boundary-matching workflows across 40+ countries to minimize integration complexity  
• This integration is between two components within Crosscut's technical control, significantly reducing integration risk compared to external system integrations
### **2.10 — FHIR Data Consumption and Pushback Finalization - $7,970**
**Lead:** Sam Hoogewind

Harden the integration APIs for production use.  
  
• Error handling and retry logic for failed data ingestion or analysis jobs  
• Input validation strengthening based on real-world data issues encountered during pilots  
• Performance optimization for large-country datasets  
• Monitoring and alerting for integration pipeline health  
• Final reconciliation of data formats between Crosscut outputs and ICR FHIR resource expectations
### **2.11 — Authentication and Access Control for External API Consumers - $10,361**
**Lead:** Sam Hoogewind, Brianna Poulos

Implement the authentication and authorization model for ICR/OpenFn to access Crosscut's new API endpoints.  
  
• The existing backend supports Cognito user authentication and custom read-only/partner tokens (JWT-based) — extend this model for ICR service-to-service authentication  
• Define permission scopes for ICR API access (which endpoints, which data)  
• Security review of the integration surface (Brianna Poulos)  
• Token lifecycle management for long-running integrations
## **Country Pilot Support**
### **2.12 — First Pilot Country: Campaign Data Analysis and Integration Testing - $7,970**
**Lead:** James McKinnon

Support the first pilot country deployment by analyzing campaign data, testing the integration pipeline end-to-end, and validating that Crosscut's geospatial outputs are correct for the pilot country's geography and campaign context.  
  
• Analyze pilot country campaign datasets to validate data quality and completeness  
• Test the full data flow: ICR → OpenFn → Crosscut API → analysis → output pushback  
• Validate catchment areas against known facility service areas  
• Document integration issues and feed back to development sprints
### **2.13 — On-Site Pilot Support (Sierra Leone) - $7,970**
**Lead:** Coite Manuel

Provide on-the-ground support for the 1st country pilot deployment (up to 10 days in-country, subject to UNICEF approval).  
  
• Support end-to-end testing with actual campaign data alongside MoH and UNICEF Country Office staff  
• Validate cross-campaign data reuse (e.g., household locations from one campaign available to the next)  
• Stakeholder engagement with MoH data managers, campaign coordinators, and IT staff  
• Gather feedback on geospatial outputs and usability for microplanning  
• Document integration workflows and country-specific adaptations
### **2.14 — Second Pilot Country Deployment Support - $7,970**
**Lead:** James McKinnon

Support the second pilot country deployment by adapting the integration for that country's administrative structure, campaign types, and data context.  
  
• Configure geographic hierarchy for the second country (boundary versions, admin levels)  
• Adapt parameters for country-specific campaign types  
• Test and validate integration pipeline  
• Document country-specific adaptations needed for the replication toolkit
# **Phase 3: Capacity Building and Training (Months 7–12) - $9,620**
Phase 3 focuses on documentation and training materials for the integration components that Crosscut is responsible for. In-country training is delivered during the Phase 2 pilot trips; this phase formalizes those learnings into reusable materials.
## **3.1 — Integration Technical Documentation - $3,000**
**Lead:** Sam Hoogewind, James McKinnon

Develop technical documentation for the Crosscut integration components:  
• API reference documentation for all new endpoints (request/response formats, authentication, error codes)  
• Data flow diagrams showing the complete pipeline from ICR → Crosscut → ICR/downstream  
• Configuration guide for adapting the integration to new countries (boundary versions, admin levels, parameter defaults)  
• Troubleshooting guide for common integration issues
## **3.2 — Microplanning Workflow Guidance - $6,620**
**Lead:** James McKinnon

Provide guidance to UNICEF DAPM teams on accessing and using ICR data for microplanning purposes through the Crosscut platform.  
• Document how catchment areas, population estimates, and accessibility layers generated through the ICR integration can be used for campaign microplanning  
• Support DAPM in establishing data access workflows
# **Phase 4: Global and National Reporting Alignment (Months 13–17) - $4,440**
Crosscut supports the alignment of ICR outputs with WHO Joint Application Package (JAP) reporting formats and national reporting requirements.
## **4.1 — JAP Output Coordination for NTD/MDA Reporting - $4,440**
**Lead:** James McKinnon

Work with Recode, WHO, and ESPEN focal points to map ICR outputs to specific JAP form fields.  
  
• Map data elements (coverage by administrative unit, population denominators, drug consumption and wastage, demographic breakdowns) to JAP reporting fields  
• Support configuration of export modules that generate JAP-compatible outputs from enriched ICR data
# **Phase 5: Sustainability and Continuity (Months 13–17) - $0**
# **Phase 6: Sustainability and Continuity (Months 13–17) - $11,840**
## **6.1 — Integration Maintenance Documentation - $4,000**
**Lead:** Sam Hoogewind, James McKinnon

Deliver system maintenance documentation for the integration components:  
• Source code repository documentation (build/deploy instructions, CI/CD pipeline)  
• System administration guide for the integration API endpoints  
• Runbook for common operational tasks (adding new countries, updating boundaries, troubleshooting failed jobs)  
  
## **6.2 — Replication Toolkit Contributions - $4,000**
**Lead:** James McKinnon

Contribute Crosscut-specific components to the project's replication toolkit for expansion to additional countries:  
• Country configuration templates (boundary versions, admin levels, parameter defaults)  
• Integration connector templates for the Crosscut API  
• Documentation of country-specific adaptations from both pilot deployments  
• Guide for setting up Crosscut's geographic data pipeline for new countries
## **6.3 — Ongoing Technical Support - $3,840**
**Lead:** Coite Manuel, James McKinnon

Provide ongoing strategic advisory and technical support throughout the sustainability phase:  
• Participate in stakeholder engagement and steering committee activities  
• Support system handover to MoH technical counterparts  
• Advise on institutionalization of the integration within national reporting cycles
