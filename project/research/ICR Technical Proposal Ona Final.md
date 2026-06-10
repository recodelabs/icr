Design, Development and Deployment of
the Integrated Campaign Registry (ICR)
Technical Proposal
April 15th, 2026
Prepared for UNICEF
Annex B – Terms of Reference
LOT 1C – Web Applications and Open Source Related

Technical Proposal – Integrated Campaign Registry (ICR)
Table of Contents
1. Understanding of UNICEF Requirements 5
1.1 Problem Statement 5
1.2 The Integrated Campaign Registry (ICR) Vision 5
1.3 Key Stakeholders and Ecosystem 6
2. Proposed Technical Approach 7
2.1 - ICR FHIR Implementation Guide Development 7
Deriving a Campaign Data Model in FHIR 7
Campaign Representation: CarePlan as the Architectural Foundation 8
Terminology Standards and Localization through ValueSets 10
Location Modeling, Administrative Hierarchies, and Geospatial Identity 10
2.2 IG Authoring, Validation, and Publication 11
Authoring in FSH with Standard Tooling 11
Technical Validation 11
Community Validation and Stakeholder Review 11
IG Publication and Release Lifecycle 12
2.3 ICR Reference Solution 13
Data Collection Layer 14
Data Transformation and Ingestion Layer 14
FHIR Store 14
Geospatial Visualization, Data Enrichment, and Microplanning 14
Integrate, Localize, Augment 15
Beyond Campaigns 15
3. Organization Expertise and Experience 16
3.1 Organization Profiles 16
Crosscut 16
3.2 WHO SMART Guidelines L3 Experience 17
3.3 HL7 FHIR Implementation Guide Experience 18
3.4 Digital Campaign Implementation Experience 18
Malaria IRS and ITN Campaigns 18
Immunization Campaigns 18
NTD Mass Drug Administration (MDA) 19
Understanding of Campaign Data Flows 20
3.7 Geospatial Microplanning Experience 20
3.8 Digital Public Good (DPG) Contributions 21
3.9 Production Data Integration Experience 22
3.10 Multi-Country Government Engagement 23
4. Implementation methodology/approach and workplan 25
4.1 Phase 1: Development of HL7 FHIR Implementation Guide (Months 1–2) 25
2

Technical Proposal – Integrated Campaign Registry (ICR)
4.1.1 Approach 25
4.1.2 Deliverables 26
4.1.3 Key Dependencies 27
4.2 Phase 2: ICR Platform Development and Deployment (Months 3–6) 27
4.2.1 Approach 27
4.2.2 ICR Solution Package 28
4.2.3 Deliverables 29
4.2.4 Key Dependencies 29
4.3 Phase 3: Capacity Building and Training (Months 7–12) 29
4.3.1 Approach 29
4.3.2 Deliverables 30
4.3.3 Key Dependencies 30
Phases 4, 5, and 6: Concurrent Workstreams (Months 13–17) 30
4.4 Phase 4: Global and National Reporting Alignment (Months 13–17) 30
4.4.1 Approach 30
4.4.2 Deliverables 31
4.4.3 Key Dependencies 31
4.5 Phase 5: Systems Integration (Months 13–17) 31
4.5.1 Approach 31
4.5.2 Deliverables 32
4.5.3 Key Dependencies 32
4.6 Phase 6: Sustainability and Continuity (Months 13–17) 32
4.6.1 Approach 32
4.6.2 Deliverables 33
4.6.3 Key Dependencies 33
4.7 Limitations and Exclusions 34
7. Project Team 35
7.1 Organization Responsibilities 35
7.2 Consortium Structure 35
7.3 Key Personnel 36
Appendix 3 40
Proof of Compliance — FHIR Implementation Guide Criteria 40
Criterion 1 — Published, inspectable FHIR IG 40
Criterion 2 — Working FSH/SUSHI profiles (R4) 40
Required artifacts — source and rendered evidence 41
What each artifact demonstrates 41
Compilation evidence 41
Summary 42
Service Level Agreement (SLA) 43
1. Support Model 43
3

Technical Proposal – Integrated Campaign Registry (ICR)
2. Response and Resolution Timelines 44
3. Issue Tracking, Reporting, and Resolution Management 44
4. Availability and Coverage 44
4

Technical Proposal – Integrated Campaign Registry (ICR)
1. Understanding of UNICEF Requirements
1.1 Problem Statement
UNICEF is the integrating entity for campaign-based health delivery, supporting countries across
immunization, polio, NTD mass drug administration, malaria prevention, and vitamin A
supplementation. These programs frequently target the same communities and the same children,
yet they have historically operated in isolation.
Campaign delivery has been verticalized for decades. Each campaign builds its own systems for
planning, implementation, and reporting. Communities are remapped and people re-registered for
every new round. Data from one program, whether household locations, population counts, or
coverage tallies, is rarely available to inform the next, even when both campaigns serve the same
villages.
This fragmentation is costly, particularly as resources tighten across global health. NTD programs
are a clear example. NTD mass drug administration campaigns could leverage the household maps,
population denominators, and geographic data that better-funded polio and immunization
campaigns have already collected, but today's siloed systems make that impossible. Integration
would benefit all sides: NTD programs gain data assets they cannot afford to build independently,
while immunization programs gain a broader base of community-level intelligence that improves
their own coverage tracking and microplanning.
Beyond inefficiency, fragmentation undermines data quality and timeliness. Campaign data is
frequently paper-based, weakly linked to national HMIS, and invisible across programs.
Governments and partners lack the cross-campaign visibility needed to identify coverage gaps,
coordinate co-delivery, and hold programs accountable.
The opportunity is to shift campaigns from isolated, disposable data events to contributors to a
cumulative, reusable corpus of public health intelligence, transforming each campaign's data
collection costs from a one-off expenditure into an investment that compounds across programs
and over time.
1.2 The Integrated Campaign Registry (ICR) Vision
UNICEF seeks to realize this shift through the Integrated Campaign Registry (ICR): a standards
framework and reference implementation that enables public health campaigns to share,
exchange, and reuse data and metadata in a structured, interoperable way. The ICR represents a
foundational shift in how campaign data is managed, establishing an open standard for how
campaign information is stored and exchanged so that what one campaign collects can be
repurposed by the next rather than re-collected from scratch.
At its core, the ICR acts as a metadata and data backbone for campaign integration. It receives
data from whichever collection tools countries already use (ODK, DHIS2 Tracker, CommCare, and
others), normalizes and harmonizes that data, and makes it available for planning, monitoring,
reporting, and reuse across programs. The ICR is designed to align with national HMIS and WHO
reporting requirements, strengthening rather than duplicating existing health system
infrastructure.
5

Technical Proposal – Integrated Campaign Registry (ICR)
The ICR will be built on HL7 FHIR (Fast Healthcare Interoperability Resources) standards to
ensure global interoperability and long-term sustainability. As outlined in the TOR, its architecture
spans seven interconnected components: a FHIR Implementation Guide defining the data model
and interoperability rules; a core registry database; integration and data flow tools bridging
diverse source systems to the registry; a standardized data model covering patients, households,
locations, services delivered, and campaign metadata; an analytics layer enabling data to flow into
warehouses for monitoring and decision-making; a data enrichment layer integrating with tools
like the WHO Geospatial Microplanner; and a capacity building framework including training,
documentation, and a replication toolkit.
More specifically, we understand the objectives of this assignment to be:
● Design and develop a scalable, interoperable ICR built on HL7 FHIR standards and aligned
with national and global reporting requirements.
● Facilitate the integration and repurposing of data and metadata from existing campaign
tools across immunization, NTD mass drug administration, and vitamin A supplementation,
avoiding duplication and enabling reuse across programs.
● Strengthen linkages between community-level reporting and national HMIS, ensuring
timely and accurate data flow and improved reporting of UNICEF-supported MDA
campaigns to relevant country and global platforms.
● Enhance the capacity of governments and partners in two pilot countries to use the ICR for
planning, monitoring, and reporting, supporting long-term institutionalization and
sustainability.
Our proposal responds to the full scope of this vision. In the sections that follow, we describe our
technical approach to each component, grounded in our direct experience building FHIR-based
health information systems at national scale and supporting campaign digitalization across
multiple countries and program areas.
1.3 Key Stakeholders and Ecosystem
This initiative sits within an ecosystem of stakeholders and digital platforms that the ICR must
integrate with and support.
● UNICEF is the system owner, with HQ teams across NTD, Community Health, Digital
Health, and DAPM, along with Regional and Country Offices in the pilot countries leading
coordination with governments and partners.
● Ministries of Health in each pilot country are the primary government counterparts
responsible for NTD programs, immunization, and national HMIS. The ICR must embed
within their reporting cycles and digital health architectures.
● WHO, including ESPEN, immunization and polio programs, and the Geospatial
Microplanner team. The ICR must align with JAP reporting formats and support data
exchange with WHO tools.
● Gavi, whose reporting requirements for immunization campaigns must be supported.
● Implementing partners, including community health organizations and NGOs engaged in
NTD MDA, immunization, and nutrition campaigns.
● Digital platforms already embedded in country workflows, including DHIS2, ODK,
OpenSRP, ESPEN tools, and the WHO Geospatial Microplanner. The ICR must be
interoperable with all of these.
6

Technical Proposal – Integrated Campaign Registry (ICR)
2. Proposed Technical Approach
2.1 - ICR FHIR Implementation Guide Development
A FHIR Implementation Guide (IG) is a specification that defines how FHIR resources should be
structured and constrained for a specific use case. It serves as a shared rulebook, ensuring that
different systems built by different teams can exchange the same data reliably.
Deriving a Campaign Data Model in FHIR
Public health campaigns present a fundamental modeling challenge in FHIR. The FHIR
specification was designed around clinical care encounters: a patient presents at a facility, receives
a service, and a record is created. Campaigns invert this model. They are population-level,
geographically driven, time-bounded events in which teams move outward into communities to
deliver services at scale. There is no native Campaign resource in FHIR or CampaignEvent. This
means the ICR IG must identify which existing FHIR resources can be profiled and extended to
carry campaign semantics faithfully, and it must do so in a way that is architecturally sound and
endorsed by the broader FHIR community.
The ICR FHIR IG will be grounded in operational reality. We will begin by reviewing data from 3–4
existing public health campaigns in collaboration with UNICEF, including NTD mass drug
administration, immunization, polio, etc. to extract the implicit data model that campaigns already
use in the field. For each campaign dataset, we will catalogue the data elements captured, identify
common and divergent structures across campaign types, and synthesize a canonical data model
covering the core entities: target populations and households, administrative and service delivery
locations, services delivered, commodities distributed and consumed, campaign teams and their
assignments, and campaign metadata including dates, target populations, implementing partners,
and coverage results.
We have navigated this exact challenge before. When we needed to represent households for
community health workflows, a concept with no native FHIR support, we identified the closest
base resources (the Group resource, linked to Location for the physical dwelling), defined the
necessary extensions, and worked through the HL7 community process to validate the approach.
That household representation has since been adopted and extended within the FHIR ecosystem.
We will follow the same methodology for campaign data, engaging the FHIR community early and
iteratively to ensure the ICR IG has both technical legitimacy and a path toward long-term
adoption.
As part of this data modeling work, we will define which components need to be captured and
reported in real-time during an active campaign versus those that are reconciled at campaign
close. Real-time components would typically include doses or commodities administered,
locations visited, and progress against targets, enabling campaign managers to monitor coverage
and redeploy teams while the campaign is still underway. Post-campaign components would
include reconciled stock counts, final coverage calculations, data quality reviews, and consolidated
reporting aligned to WHO Joint Application Package (JAP) forms for example. The data model will
be designed so that a single structure supports both operational monitoring during the campaign
and formal reporting afterward, rather than requiring separate systems for each.
7

Technical Proposal – Integrated Campaign Registry (ICR)
Campaign Representation: CarePlan as the Architectural Foundation
Based on our analysis of campaign workflows and FHIR's resource model, we believe the CarePlan
resource provides the most natural and powerful foundation for representing public health
campaigns. In clinical FHIR, a CarePlan represents a coordinated set of activities to address a
health concern for a patient or group; a campaign is the same concept at population scale. The
campaign data model we will develop and validate builds on this foundation using several
interconnected FHIR resources. PlanDefinition would serve as the reusable campaign protocol,
the template that defines what a given type of campaign involves (drugs, target age groups, activity
sequence) and that can be instantiated consistently across geographies and time periods. Each
specific campaign execution would be represented as a CarePlan referencing its parent
PlanDefinition and carrying the campaign-specific details: dates, target geography, target
population, and a status lifecycle from draft through active to completed. Within the CarePlan,
ActivityDefinition resources define the discrete types of work (e.g., "administer albendazole to
children aged 5–14," "distribute ITNs to households"), while Task resources make the plan
operational. Each Task is an assignable, trackable unit of work tied to a specific Location (a
settlement, a school, a set of households), assigned to a member of the CareTeam, and carrying a
status that tracks progress from requested through completed. Individual service delivery events
would be recorded using Immunization (for vaccinations), MedicationAdministration (for MDA
drugs), and SupplyDelivery (for commodity distribution), each linked back to the relevant Task and
Location. Households would be represented using the Group resource, with members referencing
individual Patient records where person-level data is collected, linked to the Location where the
household is situated.
8

Technical Proposal – Integrated Campaign Registry (ICR)
HL7 FHIR CarePlan for modeling Campaigns
This architecture has a critical additional benefit: it unifies campaign planning and campaign
execution within a single data model. A CarePlan that begins as a microplan, defining what needs
to happen, where, by whom, and with what supplies, evolves into a campaign execution record as
Tasks are completed and coverage data accumulates. This directly supports the project's objective
of linking campaign execution ultimately to microplanning, and it provides a clean integration path
with tools like the WHO Geospatial Microplanner, where CarePlans, Tasks, and Locations can flow
bidirectionally as FHIR resources. Design decisions around granularity (whether Tasks are
assigned at the village level or down to individual households), performance at national scale, and
real-time versus post-campaign reconciliation are precisely the types of questions we will work
through with the FHIR community and validate against real campaign data during the IG
development process.
9

Technical Proposal – Integrated Campaign Registry (ICR)
Terminology Standards and Localization through ValueSets
Since the ICR will span multiple campaign types, including immunization, NTD MDA, malaria
prevention, and vitamin A supplementation, each with its own product formularies, target
population definitions, and reporting categories. The IG must define terminology bindings that are
internationally standardized yet locally adaptable. For immunization events, CVX (CDC's Vaccines
Administered code system) is well-established and already supported by FHIR's Immunization
resource. For pharmaceutical products used in MDA campaigns (praziquantel, albendazole,
ivermectin, mebendazole), the WHO ATC (Anatomical Therapeutic Chemical) classification
provides an internationally recognized coding system appropriate for a global IG. For commodity
identification in supply chain tracking, including specific drug formulations, ITN products, and IRS
chemicals, GS1 GTINs offer product-level identification, while broader supply chain workflows can
reference WHO Essential Medicines List categories.
The IG will define standardized code lists (ValueSets) for key data elements. For core campaign
types (vaccination, MDA, ITN distribution, IRS, vitamin A supplementation), implementations will
be required to use the codes defined in the IG to ensure consistency. For drug and vaccine
products, implementations will be expected to use international codes (such as CVX or ATC) when
applicable, but will be able to add local codes for country-specific products. The IG will include
mapping resources (ConceptMaps) that show how local codes relate back to the international
standards. This approach allows countries to incorporate their own product names and
registration numbers while keeping data comparable across countries and compatible with the
international IG.
Location Modeling, Administrative Hierarchies, and Geospatial Identity
The FHIR Location resource will require the most customization of any resource in the ICR IG.
Campaign data is fundamentally organized by geography: administrative hierarchies (country →
region → district → sub-district → ward → village/settlement), service delivery points (health
facilities, schools, community distribution sites), and individual structures (households). Every
aspect of campaign planning, execution, and reporting depends on a well-defined and performant
location model.
FHIR Location supports parent-child relationships, allowing locations to be nested within
administrative hierarchies (e.g., a village within a ward within a district). However, the deep nesting
typical of campaign countries, often six or more levels, creates performance challenges that must
be carefully designed around to keep mobile and web applications responsive. This will be a
particular area of focus during IG development, drawing on our experience with nested location
hierarchies in production FHIR implementations at national scale.
The Location resource will also need to be extended to support not just point coordinates (GPS
lat/long) but geographic boundary data such as district polygons, settlement areas, and facility
catchment zones. We will define a GeoJSON extension on the Location resource to carry these
shapes. Stable identification of locations across campaigns is equally important. The IG will
support multiple identifier systems: P-codes (the OCHA standard for administrative boundaries),
Overture Maps GERS IDs (a global, open identifier system covering over 2.6 billion buildings and
64 million places, offering a way to consistently identify the same household or settlement across
10

Technical Proposal – Integrated Campaign Registry (ICR)
campaigns), and country-specific identifiers such as national facility registry codes. This
multi-identifier approach ensures locations can be reliably linked regardless of which system a
given country uses.
2.2 IG Authoring, Validation, and Publication
Authoring in FSH with Standard Tooling
The ICR IG will be authored in FHIR Shorthand (FSH), the HL7-endorsed domain-specific language
for IG development. FSH is concise, human-readable, and, critically, text-based, which means all IG
source files are managed under version control in a public GitHub repository with full change
history, branching, and collaborative review through pull requests. The FSH source files are
compiled by SUSHI into FHIR R4 conformance artifacts (StructureDefinitions, ValueSets,
CodeSystems, Extensions, ConceptMaps, and example instances), which are then rendered into a
browsable HTML publication by the HL7 IG Publisher. This toolchain (FSH → SUSHI → IG
Publisher) is the standard used by the vast majority of contemporary FHIR IGs, including WHO
SMART Guideline IGs, and ensures that the ICR IG is structurally consistent with the broader
FHIR ecosystem.
Technical Validation
Validation will happen at multiple levels. The FHIR toolchain (SUSHI and the IG Publisher)
automatically checks that all profiles, ValueSets, and examples conform to the FHIR R4
specification and are internally consistent. We will configure continuous integration so that every
change to the IG is automatically built and validated, surfacing errors immediately. Beyond this
automated validation, we will perform data conformance testing by taking real campaign datasets
and attempting to convert them into the ICR FHIR model, identifying where the model fits cleanly
and where it needs adjustment. This ensures the IG works with real-world data, not just in theory.
Community Validation and Stakeholder Review
Beyond technical validation, the IG must be reviewed by both the FHIR standards community and
the public health stakeholders who will use it. We will engage the HL7 community through
established channels, including chat.fhir.org, relevant working group calls, and Connectathon
events where implementers test IGs against real systems. This builds consensus for the
campaign-related extensions to be adopted broadly, as happened with the household
representation we developed for community health.
On the stakeholder side, each draft will be circulated to MoH, UNICEF, WHO, and implementing
partners as a versioned, browsable IG so reviewers can inspect actual profiles and examples rather
than static documents. Feedback will be tracked in GitHub and incorporated into subsequent
revisions.
11

Technical Proposal – Integrated Campaign Registry (ICR)
IG Publication and Release Lifecycle
IG Publication Lifecycle
The IG will follow FHIR community publication conventions, with each formal release published as
a versioned, browsable IG with a stable URL, accompanied by an NPM package that enables other
IGs and FHIR tools to declare a dependency on it. All source, generated artifacts, and published
output will be hosted on GitHub under an open-source license, ensuring transparency and
community contribution.
We envision the following release cadence aligned to the project phases: a v0.1 draft IG produced
during Phase 1 and circulated for stakeholder and community review; a revised draft
incorporating that feedback and endorsed for use in the initial pilot; updated versions
12

Technical Proposal – Integrated Campaign Registry (ICR)
incorporating learnings from pilot country deployments during Phase 2; and a v1.0 release
representing the validated, production-ready IG. Each release will include a changelog and
maintain backward compatibility where possible, with clear migration guidance where breaking
changes are necessary.
2.3 ICR Reference Solution
Proposed ICR Package Architecture
The ICR will be conceived not as a software platform but as a packaged reference solution, an
open-source, standards-based blueprint that demonstrates how campaign data can be integrated,
harmonized, and reused across programs. The reference solution will be composed of
interchangeable open-source components that can be substituted or adapted based on country
context, existing infrastructure, and institutional preferences. What will remain constant across
any implementation is the HL7 FHIR Implementation Guide, which serves as the DNA of the entire
system. The IG will define the data model, the structure and semantics of campaign resources, and
any conformant implementation, regardless of the specific software stack, will need to adhere to
it.
Our proposed reference ICR solution will be organized into the following functional layers:
Data Collection Layer
The ICR will not prescribe a single data collection tool. Campaigns will continue to use the
platforms already embedded in their workflows, including ODK, DHIS2 Tracker, CommCare,
OpenSRP, and others. The ICR will be designed to receive data from any of these systems, meeting
13

Technical Proposal – Integrated Campaign Registry (ICR)
countries where they are rather than requiring adoption of a new collection tool. This is a
foundational design principle: enhance existing country systems, not replace them.
Data Transformation and Ingestion Layer
To bridge the gap between the diverse data formats produced by collection platforms and the
normalized FHIR data model required by the ICR, we will implement a middleware layer using
OpenFn or Airbyte as the primary integration engine. Using a tool like OpenFn, we will build
connectors that extract data from source systems, transform it into FHIR-conformant resources
as defined by the IG, and load it into the FHIR store. The connectors developed through this
project will be openly available and documented as part of the replication toolkit, allowing other
implementers to adapt them for additional source systems.
FHIR Store
The core registry database will be a FHIR R4-compliant server, with the open-source HAPI FHIR
as the primary reference implementation and the Google Healthcare API as an alternative for
cloud-hosted deployments. This choice is well aligned with the direction many countries across
Africa are already taking: HAPI is increasingly being adopted as the default FHIR server and
shared health record store within national health information exchange architectures, making the
ICR immediately compatible with the infrastructure these countries are building. The FHIR store
will serve as the canonical repository. Once data passes through the transformation layer and is
loaded, it will exist in a standardized, interoperable format regardless of its origin. The store will
expose RESTful APIs that enable all downstream components, including browsing, analytics,
planning, and reporting, to consume data consistently.
Data Browsing and Quality Management. We will integrate Cinder (https://cinder.recodelabs.org),
a FHIR resource browser developed by Recode Labs as part of the OHS project, to provide a
user-facing interface for exploring and managing the data held in the FHIR store. Cinder will
enable users to browse resources, inspect records, and navigate the relationships between
campaign entities such as patients, locations, encounters, and observations. Critically, Cinder will
also support data quality management functions, including deduplication, validation, and anomaly
detection, which will be a major workstream in this project. Given that the ICR will receive data
from multiple campaigns using different collection tools, deduplication of patients, households,
and locations across sources will be essential to the integrity of the registry. Cinder will provide
the tooling needed to identify, review, and resolve duplicate records and other data quality issues.
Geospatial Visualization, Data Enrichment, and Microplanning
The ICR will integrate with Crosscut, which will serve as the geospatial and planning layer of the
solution. Under this project, Crosscut will be adapted to consume FHIR data from the ICR to
visualize health facilities, service delivery points, settlements, and other campaign-relevant
locations on a map. Beyond visualization, Crosscut will support data enrichment workflows. For
example, if the ICR contains a set of health facilities or villages identified as campaign targets,
those entities can be imported into Crosscut to define catchment areas, assign population
estimates, calculate distances, and perform other spatial analyses needed for microplanning. Once
enriched, this data will be pushed back into the ICR, creating a bidirectional flow that strengthens
both the registry and the planning process. This integration directly supports the TOR
14

Technical Proposal – Integrated Campaign Registry (ICR)
requirement for two-way integration with microplanning tools and will ensure that ICR data feeds
meaningfully into campaign planning, not just reporting.
FHIR-to-Data-Warehouse Layer. To make the structured FHIR data accessible for broader
analytical use, we will implement a SQL on FHIR layer that will transform FHIR resources into flat,
queryable tables in a relational data warehouse. This transformation will be driven by FHIR
ViewDefinition resources, themselves part of the IG, which will formally define how FHIR
resources should be projected into tabular views. By including ViewDefinitions in the IG, we will
ensure that the analytical layer is as standardized and portable as the data model itself: any
implementer using the ICR IG will be able to generate the same warehouse schema from their
FHIR store. We have already validated this methodology in prior work in Uganda with the MoH
and UNICEF and will implement it as a core component of the reference package.
DHIS2 Integration and Reporting. From the data warehouse, we will use OpenFn to build
connectors that synchronize ICR data with DHIS2, supporting both import and export of
aggregate and tracker data. This approach, from FHIR store to data warehouse to DHIS2, has been
proven in our prior implementations and offers significant advantages over direct FHIR-to-DHIS2
mapping. The warehouse layer will provide a stable, well-understood relational structure that
simplifies the alignment of ICR data elements with DHIS2 data sets and program indicators. This
same pathway will support the generation of JAP-aligned reporting outputs.
Integrate, Localize, Augment
The ICR is designed to work with, not replace, the tools countries are already using. Where
national systems have existing platforms, APIs, and workflows, the ICR will plug into them through
interoperability layers built on HL7 FHIR. Where gaps exist, it will fill them in alignment with
national digital health architectures. Because no two country contexts are the same, the registry is
built to be localized—adapting ValueSets, workflows, and data models to each country's health
system rather than imposing a one-size-fits-all approach.
Beyond Campaigns
A core ambition of this work is to establish a common data model backbone that starts with
campaigns but extends to broader health system use. A location registry built for NTD mass drug
administration, for example, should be equally useful for routine community health programs
which is why the DHIS2 integration is critical. From a sustainability standpoint, grounding this
work in FHIR Implementation Guides aligns with how countries are increasingly designing their
digital health architectures.
15

Technical Proposal – Integrated Campaign Registry (ICR)
3. Organization Expertise and Experience
Ona and Crosscut are bidding on this assignment as a consortium, with Ona serving as the prime
contractor. Ona will hold the contractual relationship with UNICEF and bear primary
responsibility for all deliverables, project management, stakeholder coordination, and reporting.
Crosscut will serve as a subcontractor to Ona, contributing its geospatial microplanning expertise,
DHIS2 integration capabilities, and NTD campaign experience to the technical delivery of the ICR.
3.1 Organization Profiles
Ona Systems
Ona is a technology solutions company that uses data to address large, intractable problems such
as equitable access to basic healthcare services. Founded in 2013 and headquartered in
Burlington, VT, Ona is the creator and technical steward of OpenSRP, a global good digital health
platform that has been adopted at national scale in several countries. Ona partnered with the
World Health Organization and Google to develop a next-generation version of OpenSRP built
natively on HL7 FHIR and designed to support WHO's SMART Guidelines. Ona has also played a
key contributing role in the creation of several other global goods, including Google's Open Health
Stack and Reveal, a precision health delivery platform.
Ona has successfully delivered hundreds of projects in over 30 countries with the world's leading
development agencies and practitioners. As an organization, Ona has a proven track record of
working with and supporting UN partners. Ona holds active LTAs with UNICEF (and previously
with WHO) and has successfully completed close to 100 contracts across the UN system, including
with UNICEF, WHO, WFP, UNDP, UNEP, UNOPS, and UN Women. Ona also provides enterprise
data solutions adopted corporately by UN agencies, including UNICEF's Inform platform and
WFP's MoDa mobile data collection system.
Crosscut
Crosscut is a certified U.S. small business founded in 2017 and headquartered in Washington, DC,
with a mission to unlock data to make global health programs more efficient and effective. The
company specializes in geospatial microplanning technology for public health campaigns,
operating across Sub-Saharan Africa with a platform now available in 43 countries and three
languages.
Crosscut's team of five full-time engineers, data scientists, and global health professionals has
worked together for years under a disciplined agile development model with rigorous quarterly
planning, two-week sprints, daily standups, and formal testing and code review. The company
maintains a broad network of geospatial health analytics specialists and can expand capacity on
short notice when project demands require it.
Since 2020, Crosscut has implemented projects across more than 10 countries in geospatial
microplanning, immunization supply chain analytics, and NTD campaign support. Clients and
funders have included UNICEF, WHO AFRO/ESPEN, USAID/PMI, the Gates Foundation,
VillageReach, The Carter Center, Sightsavers, Abt Associates, Amentum, Task Force for Global
Health, and the IDA Foundation. Crosscut's CEO, Coite Manuel, brings more than 15 years in
16

Technical Proposal – Integrated Campaign Registry (ICR)
global health supply chain management, including prior service as Senior Supply Chain Advisor in
USAID's Global Health Office.
Crosscut's core platform, the Crosscut App (app.crosscut.io), is a freely available, registered
Digital Public Good that delivers hyperlocal geospatial maps to support health programming and
analysis at sub-district and 100m² granularity or lower across Sub-Saharan Africa and other
geographies. The app powers the WHO ESPEN Geospatial Microplanner and holds formal status
as a DHIS2 Tier 2 Strategic Technology Partner (Digital Public Good) under a signed agreement
with the HISP Centre at the University of Oslo.
3.2 WHO SMART Guidelines L3 Experience
Ona has extensive experience designing and implementing WHO SMART Guideline-based L3
applications, having been involved in conceiving and developing the approach from its earliest
stages. This work began when Ona built the first ANC digital health reference application for
WHO, prior to the formal launch of the SMART Guidelines initiative. Ona then partnered with
WHO and Google to create Open Health Stack, the first reference implementation of the SMART
Guidelines framework, which established the foundational architecture for translating L2 clinical
recommendations into executable L3 software. From there, Ona developed the first SMART
Guidelines L3 application for COVID-19 and subsequently worked with WHO to build a SMART
Guidelines-compliant immunization reference application, which was later adapted in partnership
with PATH into a global immunization reference product suite. Ona has also led country-level
SMART Guidelines adaptation work, including developing a base SMART Guidelines FHIR
Implementation Guide for Peru and training the Ministry of Health to customize it for
national-level use. In addition, Ona has built SMART Guidelines-informed FHIR-native
applications across multiple countries, including a community health worker application now
deployed by the Ministry of Health in Uganda with support from UNICEF. While not all of these
implementations constitute full published IGs, each represents a complete FHIR-based
community health implementation grounded in SMART Guidelines methodology.
OpenSRP 2, Ona's FHIR-native platform, was purpose-built to serve as the L3 execution layer for
WHO SMART Guidelines content. Built on Google's Android FHIR SDK as part of the Open Health
Stack collaboration, OpenSRP 2 uses HL7 FHIR resources, Structured Data Capture (SDC), and
Clinical Quality Language (CQL) to allow subject matter experts to define clinical workflows,
decision-support logic, and data capture forms through dynamic configuration rather than code
changes. This design enables countries to take WHO's machine-readable L2 guideline content and
rapidly adapt it into functional, deployable L3 applications.
Ona's team is deeply embedded in the HL7 FHIR community. Team members have participated in
multiple HL7 FHIR DevDays conferences, FHIR training sessions led by the HL7 team, and
connectathons. This sustained engagement has led to direct contributions to the FHIR
specification itself, including work on how to represent and manage households in the context of
primary healthcare delivery in FHIR, as well as contributions to the authoring and implementation
of FHIR Implementation Guides. In 2024, Ona worked with the Ministry of Health of Peru
(MINSA) in collaboration with PAHO to train MINSA staff on FHIR and support the authoring of a
Immunization FHIR Implementation Guide tailored to Peru's national health system. As part of
this engagement, Ona helped develop a FHIR-native application for initial pilot testing in the
country. This work has had a lasting institutional impact: MINSA has since implemented HAPI
FHIR and begun adopting FHIR internally as a foundation for health data exchange across the
17

Technical Proposal – Integrated Campaign Registry (ICR)
organization. Across these efforts, Ona has delivered SMART Guidelines L3 implementations
spanning multiple countries, clinical domains, and partner organizations — a depth of applied L3
experience that is, to our knowledge, unmatched in the FHIR community.
3.3 HL7 FHIR Implementation Guide Experience
We have experience authoring and publishing IGs as required in the TOR. Members of our team
including Matt Berg and Peter Lubell-Doughtie have been authors on published IGs. Our work in
helping to initiate the WHO SMART Guidelines made us very familiar in both the FHIR IG
authoring and consuming (L3) process. This includes using FSH/SUSHI to profile, create
StructureDefinitions, ValueSets, etc. See Appendix 3 where we provide links to a published IG
which our team contributed to authoring with the requested validation criteria.
3.4 Digital Campaign Implementation Experience
Ona and Crosscut bring deep, complementary experience supporting digital implementation of
public health campaigns across immunization, NTD mass drug administration, and malaria vector
control, with direct engagement at national and subnational government levels across multiple
countries and partners.
Malaria IRS and ITN Campaigns
Ona developed with Akros mSpray, one of the earliest digital tools purpose-built for indoor
residual spraying campaigns, and supported its use for multiple years in Zambia at national scale,
covering over one million structures. Published research demonstrated that IRS campaigns using
mSpray achieved statistically significant reductions in malaria incidence compared to IRS without
it, validating the impact of geospatial guidance on campaign effectiveness. mSpray was
subsequently expanded and rebranded as Reveal, an open-source, Digital Square-approved Global
Good that uses spatial intelligence to guide and track delivery of household-level health
interventions. In partnership with CHAI, Reveal was extended to additional countries across
sub-Saharan Africa for IRS, ITN distribution, and other campaign use cases.
Crosscut was selected as a resource partner on USAID's PMI Evolve Project (prime contractor Abt
Associates), a five-year program spanning 21 countries. In the first year, Crosscut conducted
design sessions and user testing in Uganda and Ghana for IRS supply estimation, with plans to
extend to 10 countries and expand functionality for ITN distribution planning. Crosscut also
provided ML-based building classification (85%+ accuracy for identifying spray-eligible structures)
to generate printable PDF operational maps for IRS campaigns.
Immunization Campaigns
Ona worked with UNICEF to develop RT-VaMA (Real-time Vaccination Monitoring and Analysis), a
digital monitoring tool that enables daily tracking of vaccine coverage, utilization, and wastage
during immunization campaigns. Built on ODK technology, RT-VaMA allows health workers to
collect data on mobile devices — including in offline settings — and surfaces that data through
visualization dashboards that enable decision-makers to identify bottlenecks and course-correct
in real time. RT-VaMA was first piloted with over 1,500 health workers across the Philippines
during a polio outbreak response and has since been deployed in Papua New Guinea, where it
supported a measles and rubella campaign targeting 1.3 million children across 22 provinces.
18

Technical Proposal – Integrated Campaign Registry (ICR)
UNICEF has adopted RT-VaMA as a core component of its immunization innovation portfolio and
has developed a toolkit to support its adoption in additional countries.
More broadly, Ona supports UNICEF and WHO's immunization and polio programs through Ona
Data, Ona's mobile data collection platform, which serves as a primary tool for campaign data
collection and monitoring across Africa. Through this sustained engagement, Ona has developed
deep operational familiarity with immunization campaign data flows, including coverage tracking,
supply chain visibility, and integration with national reporting systems. Ona has also implemented
OpenSRP as an electronic immunization registry in Zambia, Mauritania, and Tunisia, and is
currently working with WHO to develop a global reference EIR application based on the SMART
Guidelines.
Crosscut has worked directly with UNICEF on digitized electronic microplanning strategies for
immunization campaigns in The Gambia, supporting the government in making evidence-based
platform decisions. The Crosscut App explicitly supports supplemental immunization activity (SIA)
planning, vaccination post identification, session planning, and population-benchmarked coverage
estimation. Crosscut was also selected as a Gavi global partner in supply chain analytics (2022,
prequalified in Ethiopia), supporting vaccine supply chain visibility through integration with
UNICEF's Stock Management Tool (SMT), which is in active use in 20+ countries. This integration
enables batch-level visibility from health facility to central medical store to support expiry
prevention and stockout detection. Crosscut has since been selected (with its prime partner
VillageReach) by Gavi as part of the 6.0 Technical Assistance framework for geospatial
microplanning.
NTD Mass Drug Administration (MDA)
In Nigeria, Crosscut partnered with Sightsavers and the Kogi State Ministry of Health to support
planning for a schistosomiasis MDA campaign across Lokoja, Kogi, and Ibaji LGAs, targeting
152,724 children aged 5–14. Crosscut provided accessibility analysis, supervisory area
delineation, and a CommCare integration for real-time supervision monitoring during the
campaign. Crosscut has also integrated with Open Data Kit (ODK) for NTD MDA supervision data
management, with The Carter Center's Nigeria program as a named deployment. In addition,
Crosscut has developed a CommCare integration for MDA supervision deployed with Sightsavers
across Liberia, Guinea-Bissau, and Nigeria, enabling field supervisors to log visits through
CommCare while program managers see coverage and supervision status overlaid on catchment
maps.
In Liberia, Crosscut piloted the ESPEN Geospatial Microplanner across three counties (Maryland,
Grand Cape Mount, and Montserrado) in partnership with Sightsavers to prepare
catchment-based microplans for an upcoming NTD MDA campaign. In Haiti, Crosscut
collaborated with The Carter Center on MDA campaigns targeting lymphatic filariasis, where
Crosscut's population estimates directly informed the decision to shift from fixed-point to
door-to-door drug distribution in specific areas. In 2026, Crosscut is expanding NTD program
microplanning support to Nigeria, Senegal, Madagascar, Guinea-Bissau, Burundi, Tanzania, Ghana,
and Chad.
19

Technical Proposal – Integrated Campaign Registry (ICR)
Understanding of Campaign Data Flows
Across these engagements, the team brings direct operational experience with the full spectrum
of campaign data flows. Ona's platforms produce and consume FHIR-based health data and
integrate with DHIS2 and other national HMIS. Crosscut's platform outputs include
population-benchmarked coverage estimates, supply plan tables, and catchment-area boundaries
exportable as GeoJSON and ingestible directly into DHIS2. Crosscut integrates with WHO ESPEN
for MDA-specific workflows and DHIS2 via a signed MOU and DHIS2 App Hub app. Together, the
team has hands-on experience with coverage tracking, campaign deduplication, Gavi/COVAX
reporting requirements, and the DHIS2/OpenSRP ecosystem, the exact data flows that the
Integrated Campaign Registry is designed to standardize and connect.
3.7 Geospatial Microplanning Experience
Crosscut's core business is geospatial microplanning, and its technology powers the WHO AFRO
ESPEN Geospatial Microplanner, the primary sub-district microplanning tool for NTD preventive
chemotherapy programs across 43 African countries.
WHO ESPEN Geospatial Microplanner
The ESPEN Geospatial Microplanner is a white-label version of the Crosscut App, built in
partnership with WHO AFRO's ESPEN program and funded by the Gates Foundation. It supports
microplanning for NTD MDA campaigns across all WHO AFRO countries. Crosscut also built the
ESPEN Schisto Mapper Tool, piloted in Senegal, which transforms schistosomiasis survey and
environmental data into actionable sub-district treatment maps within the ESPEN Portal.
In December 2025, Crosscut participated in a WHO workshop in Brazzaville with representatives
from 13 countries to demonstrate the ESPEN Microplanner and gather country feedback on
microplanning workflows. Earlier in 2025, Crosscut conducted a landscape survey of 56 NTD
program leaders across 27 WHO Africa region countries, including 13 in-depth interviews, to
understand microplanning practice gaps. The survey found that 82% of respondents engaged in
microplanning, but only 46% estimated populations at the community or sub-district level, and
97% relied on Excel with no geospatial tools.
GIS-Based Household Enumeration and Settlement-Level Mapping
The Crosscut App integrates building-level data from Overture and Google Open Buildings (with
configurable confidence thresholds) alongside population data from WorldPop, Meta Data for
Good, GRID3, and Kontur. The platform pre-generates geographic "land blocks," which are
sub-settlement polygons that adapt to local geography rather than rigid administrative grids,
enabling health planners to delineate boundaries that reflect actual community structures
whether or not they align with formal administrative boundaries. Building classification outputs
are compatible with IRS campaign planning, including identifying spray-eligible versus non-spray
structures at greater than 85% accuracy via ML.
20

Technical Proposal – Integrated Campaign Registry (ICR)
Key Microplanning Capabilities Deployed In-Country
● Automated catchment area generation from geocoded health facility locations
● Paintbrush-style boundary editing with real-time population updates, requiring no GIS
expertise or desktop GIS software
● Fair Supervisory Areas algorithm that automatically divides administrative units into
equitable supervisor territories based on population density, geographic barriers, travel
time, and configurable supervisor-to-CDD ratios, with support for constrained calculation
under fixed budgets
● Travel time heatmaps (walking and driving) with configurable time-band thresholds
● Microplan Collector that allows national planners to disseminate Excel templates to
districts, ingest returned files at scale, and visualize aggregated data with population
benchmarking
Country Deployments
Countries with named NTD geospatial microplanning deployments include Nigeria, Senegal,
Guinea-Bissau, and Liberia, with several additional countries planned for 2026. In 2023, over 50
Ministry of Health staff across multiple countries were trained to independently generate
catchment areas and microplans within DHIS2 as part of the DHIS2 Academy.
3.8 Digital Public Good (DPG) Contributions
OpenSRP 2 OpenSRP is an open-source digital health platform in active development by Ona for
over 10 years. OpenSRP 2, released in 2022, combines WHO health workflows with the HL7 FHIR
data exchange standard to transform how healthcare is delivered and managed at the facility and
community level. Core functionalities include client registration and management with automated
scheduling and reminders, complete offline functionality with online FHIR server synchronization,
in-app reporting, multi-language support, role-based access control, and interoperability with
DHIS2, OpenMRS, and other national health information systems.
● DPG Registry: https://www.digitalpublicgoods.net/r/opensrp
● Ona's role: Lead developer and maintainer
Open Health Stack OpenSRP 2 is built on Open Health Stack, an initiative Ona contributed to
alongside Google and WHO. OHS provides a suite of open-source tools including a FHIR-native
Android SDK, Info Gateway, and FHIR Data Pipes tooling. OHS is a registered global good.
● Registry: https://developers.google.com/open-health-stack
● Ona's role: Co-developer and maintainer
Crosscut Platform Crosscut is a verified Digital Public Good registered with the Digital Public
Goods Alliance. The registered DPG covers the open datasets produced by the Crosscut App:
catchment area maps, microplan tables with population estimates, and supply plan tables, all
published under a CC0 1.0 license. Outputs are also published on the Humanitarian Data
Exchange (HDX). All 11 DPG Standard indicators have been met. Self-reported organizational
users include the Ministry of Health EPI program in The Gambia, WHO, and more than 30 MoH
users who have incorporated the open datasets into DHIS2 and other national health information
systems. Crosscut's open-source footprint extends beyond the dataset DPG to include a publicly
21

Technical Proposal – Integrated Campaign Registry (ICR)
available DHIS2 integration app, six additional public repositories on GitHub
(github.com/crosscutio), and Field-Kit, an open-source geospatial data preparation toolkit
released in March 2026.
● DPG Registry: https://www.digitalpublicgoods.net/r/crosscut (DPG ID: GID0090906)
● Crosscut's role: Lead developer and maintainer
Reveal Reveal is an open-source platform that uses spatial intelligence to guide and track delivery
of household-level health interventions, including case detection, contact tracing, and outbreak
management. It supports real-time data collection, analysis, and reporting to enable rapid
response to public health threats. Ona contributed to the initial development and field
implementation of the platform in partnership with Akros.
● Registry: https://revealprecision.com/
● Ona's role: Co-developer (with Akros)
3.9 Production Data Integration Experience
DHIS2
Ona has extensive production DHIS2 integration experience across multiple country deployments.
This includes leading the integration of Uganda's FHIR data warehouse, which OpenSRP 2 feeds
into, with the Ministry of Health's DHIS2 instance, a project that included building MoH capacity
to adapt, manage, and maintain the integration independently. Ona also developed a packaged
DHIS2 immunization reporting module as part of its work with PATH on the global immunization
product suite, and integrated the Zambia Electronic Immunization Registry (ZEIR) platform with
the Zambia MoH's DHIS2 system.
Crosscut holds a signed Technology Partner Agreement with the HISP Centre at the University of
Oslo, establishing Crosscut as a DHIS2 Tier 2 Strategic Technology Partner (Digital Public Good), a
formal designation for DPG-aligned technologies recognized as strategic ecosystem collaborators.
The agreement covers API-level integration, joint reference architectures, coordinated country
deployments, and joint engagement with donors and governments. Under this partnership,
Crosscut has built and maintains a dedicated DHIS2 Microplanning app available on the DHIS2
App Hub. The app enables national DHIS2 administrators to create sub-district catchment areas
directly within their DHIS2 instance without needing GIS expertise, connecting to Crosscut's
geospatial engine via read-only token authentication and GeoJSON-formatted API endpoints.
DHIS2 v41 (May 2024) includes native support for Crosscut catchment visualization with linked
data tables. Crosscut was a finalist for DHIS2 App of the Year in 2022, and more than 30 Ministry
of Health users have incorporated Crosscut data into DHIS2 instances across Sub-Saharan Africa.
ODK
Ona has deep roots in the ODK ecosystem. Ona developed the XLSForm standard, which is now
the dominant form authoring format across ODK, KoboToolbox, and other data collection
platforms. Ona also developed Ona Data, a mobile data collection and management platform that
powers UNICEF's Inform platform and is used by WHO AFRO to support immunization and NTD
campaign programs across Africa.
22

Technical Proposal – Integrated Campaign Registry (ICR)
Crosscut has integrated with ODK for NTD MDA supervision data management, with The Carter
Center's Nigeria program as a named production deployment. ODK-based supervision forms are
used by field supervisors to record visit data during campaigns, which Crosscut ingests and
renders geographically over catchment maps, enabling program managers to track field team
coverage in real time.
CommCare
Crosscut has developed and deployed a CommCare integration for MDA supervision monitoring
across three countries with Sightsavers: Liberia, Guinea-Bissau, and Nigeria. Field supervisors log
visit data through CommCare, and Crosscut connects to the CommCare API to surface
supervision coverage alongside catchment boundaries for geographically-informed campaign
monitoring. This integration is structurally similar to the ICR's requirement for data connectors
between campaign tools and a central registry.
WHO ESPEN Portal
Crosscut powers the ESPEN Geospatial Microplanner and the Schisto Mapper Tool in production
across 43 African countries. These are live, Ministry-of-Health-facing tools integrated into the
ESPEN Portal, not prototypes or demonstrations.
Data Flows in Low-Connectivity Environments
Both Ona and Crosscut's platforms are designed for low-bandwidth and offline-first conditions.
OpenSRP 2 provides complete offline functionality at the point of service, synchronizing with the
FHIR server when connectivity becomes available. The Crosscut App supports pre-generated
microplan distribution via Excel or PDF for fully offline use, and both its CommCare and ODK
integrations use asynchronous sync patterns appropriate for field environments with intermittent
connectivity. The Microplan Collector workflow aggregates district-level Excel submissions
nationally without requiring internet access at the field level.
Export and Interoperability
All Crosscut outputs are exportable as GeoJSON and compatible with QGIS, ArcGIS, ODK-based
tools, and DHIS2 organization unit hierarchies. Supply plan tables are structured for compatibility
with UNICEF's Stock Management Tool (SMT) and WHO Joint Application Package (JAP)
reporting formats. Ona's platforms export data via standardized FHIR APIs and support
integration with national HMIS through established data pipelines.
3.10 Multi-Country Government Engagement
Ona
Ona has supported UNICEF and partners across over 100 projects in more than 30 countries
spanning Sub-Saharan Africa and Southeast Asia. This work has involved direct engagement with
Ministries of Health, coordination with UN agencies and implementing partners, and sustained
programme management across diverse country contexts. Named Ministry of Health
engagements include Uganda, where Ona leads the development and integration of the national
community health worker platform with UNICEF support; Zambia and Malawi, where Ona
23

Technical Proposal – Integrated Campaign Registry (ICR)
implemented electronic immunization registries integrated with national DHIS2 systems; Liberia,
where OpenSRP was selected for national community health use; Tunisia and Mauritania, where
Ona deployed electronic immunization registries; Peru, where Ona worked with MINSA and
PAHO on FHIR adoption and capacity building; and Papua New Guinea, where Ona partnered with
UNICEF, WHO, and the National Department of Health on the RT-VaMA immunization monitoring
initiative. Ona also maintains ongoing operational relationships with UNICEF, WHO, PATH, and
Gavi through its work on OpenSRP, Ona Data, and the global immunization product suite.
Crosscut
Crosscut has direct engagement with Ministries of Health in at least 10 countries, coordinating
across WHO, UNICEF, USAID, Gavi, and implementing partners simultaneously in several of these.
Direct Ministry of Health engagements include:
● Nigeria: Kogi State Ministry of Health, schistosomiasis MDA microplanning
● Ethiopia: Ministry of Health (via UNICEF), supply chain design
● Uganda: Ministry of Health (via PMI Evolve), malaria IRS
● Ghana: Ministry of Health (direct and via PMI Evolve), malaria IRS, CHPS zone mapping
● Liberia: Ministry of Health, ESPEN Microplanner pilot, NTD MDA
● Guinea-Bissau: Ministry of Health, app training and deployment
● Burundi: Ministry of Health, onchocerciasis endemicity mapping
● The Gambia: Ministry of Health EPI, supply chain design, microplanning, and catchment
area mapping
● Haiti: Ministry of Health (via The Carter Center), lymphatic filariasis MDA
● DRC: Ministry of Health (via Unlimit Health), schistosomiasis boundary delineation
Crosscut has active relationships with UNICEF, WHO AFRO/ESPEN, Gavi (global partner in
geospatial microplanning and supply chain analytics, 2022 and 2025), and USAID/PMI (resource
partner on PMI Evolve). Crosscut's current Gates Foundation-funded project requires
simultaneous coordination across multiple African countries' NTD programs, WHO AFRO's
ESPEN secretariat, and country-level Ministry of Health and implementing partner users, all while
maintaining a continuously deployed production application. This is the same model of
multi-stakeholder management required for the ICR assignment.
French Language Capacity
The team has strong French-language capacity across both organizations. Matt Berg (Ona) has
lived and worked in Mali and Senegal and has led technical trainings, workshops, and consulting
engagements in French, including for UNICEF Senegal. Crosscut has a French-speaking team
member able to lead capacity-building workshops in French and has conducted training in
Francophone African countries including Guinea-Bissau and the DRC. The Crosscut App and its
documentation are available in French. Together, the team is fully equipped to deliver all aspects of
the assignment in French.
24

Technical Proposal – Integrated Campaign Registry (ICR)
4. Implementation methodology/approach and workplan
The following is our proposed approach to implement the project in 6 phases of a span of 17
months which Ona and Crosscut will work together to implement for UNICEF.
Project Governance
Effective delivery depends on close coordination between Ona and UNICEF. We will follow an
agile development process, delivering work in iterations that give UNICEF and partners regular
opportunities to provide feedback and course-correct as the project evolves. Our proposed
cadence includes:
● Weekly check-ins with the UNICEF project contact and relevant HQ staff (e.g., Sean
Blaschke)
● Bi-weekly sprint demos during active development phases
● Quarterly steering committee reviews with broader stakeholder participation
● Defined decision gates at the completion of each phase before proceeding
We request that UNICEF designate a primary point of contact responsible for ensuring timely
feedback, facilitating access to subject matter experts, and managing other key dependencies on
the UNICEF side.
25

Technical Proposal – Integrated Campaign Registry (ICR)
4.1 Phase 1: Development of HL7 FHIR Implementation Guide (Months 1–2)
4.1.1 Approach
Sections 2.1 and 2.2 describe our intended approach to develop and publish the ICR IG for
campaign data which will be implemented in this phase.
Stage 1: Inception and Campaign Data Review (Weeks 1–3).
● Inception - The project will start off with a set of project inception calls with the UNICEF
team. From this we will develop a project work plan for UNICEF's feedback and sign-off.
● Data review - UNICEF will facilitate access to data from 3–4 existing campaigns which may
include NTD mass drug administration (SCH/STH), immunization, malaria, etc. We will
review each campaign dataset, cataloguing every data element captured to identify and
map the commonalities and divergences against the campaign types to come up with a
canonical data model to represent campaigns that we will build into the IG.
● Data components and terminology - We will begin to define which data components must
be captured in real-time during active campaigns (doses administered, locations visited,
progress against targets) versus reconciled at campaign close (stock counts, final coverage
calculations, data quality reviews, JAP-aligned reporting). We will also begin to map out
the terminology ValueSets for this
Stage 2: Draft IG Authoring (Weeks 3–6).
In this phase we will develop the v0.1 draft IG following a process detailed in Section 2.2. Key
activities include:
● Profile FHIR R4 resources around the CarePlan-based architecture, define ValueSets for
campaign types and drug/vaccine products (eg. CVX, WHO ATC, ConceptMaps for local
code alignment), and extend the Location resource for GeoJSON boundaries and
multi-identifier systems (P-codes, Overture GERS IDs, national facility codes).
● Compile the draft via FSH/SUSHI and the HL7 IG Publisher, with continuous integration
configured to validate every change automatically.
● Perform initial data conformance testing by converting real campaign datasets into the
proposed FHIR model, identifying where the model fits and where it needs adjustment.
● Circulate the draft as a versioned, browsable publication so reviewers — MoH, UNICEF,
WHO, ESPEN, and implementing partners — can inspect actual profiles and examples
rather than static documents. Track all feedback in GitHub.
Stage 3: Revision and Endorsement (Weeks 6–8). We will incorporate stakeholder and
community feedback, resolve issues identified during data conformance testing, and produce the
revised IG endorsed for pilot use.
4.1.2 Deliverables
● Project workplan developed and validated with UNICEF, including the stakeholder
engagement plan for IG development and review.
● Draft HL7 FHIR IG for campaign data published as a versioned browsable IG with a public
GitHub repository.
26

Technical Proposal – Integrated Campaign Registry (ICR)
● Documented definition of data elements and reporting requirements, including
specification of components to be reported in real-time versus reconciled at campaign
close, with rationale for each classification.
● Revised HL7 FHIR IG incorporating stakeholder and community feedback, endorsed for
pilot deployment, with changelog documenting all changes from the initial draft.
4.1.3 Key Dependencies
This phase produces the IG that serves as the DNA of the entire ICR system. Any delay here
cascades directly into Phase 2 development.
● UNICEF must facilitate timely access to campaign data from 3–4 campaigns. If data access
is delayed, the 8-week window compresses and either the depth of the data review or the
stakeholder feedback cycle will be affected.
● Stakeholder availability for structured IG review within a two-week feedback window
(Weeks 6–8). This requires coordination across MoH, WHO, ESPEN, and implementing
partners across multiple time zones.
● Campaign data quality. The data provided must be of sufficient quality and completeness
to inform meaningful FHIR profiles. If data is incomplete or heavily aggregated, we may
need to supplement with additional campaign datasets.
4.2 Phase 2: ICR Platform Development and Deployment (Months 3–6)
4.2.1 Approach
Building on the reference solution architecture described in Section 2.3, this phase develops,
deploys, and validates the ICR in two pilot countries through an iterative, sprint-based process.
Development and in-country engagement are tightly coupled: the optional in-country trip for each
pilot (up to 10 days, subject to UNICEF approval) will serve double duty, supporting both
prototype testing and initial hands-on training with MoH and implementing partners.
Months 3–4: First Pilot Country — Development and Deployment (Sprints 1–4)
Development will follow two-week Agile sprints with planning, development, testing, review, and
stakeholder demo at each cycle.
Sprint 1: Infrastructure and Core FHIR Store. We will stand up the HealthCare API server in a hosting
cloud hosting environment agreed with UNICEF during inception, configured with the IG profiles,
extensions, and terminology from Phase 1. We will deploy Cinder alongside the FHIR store for
data browsing, validation, and quality management.
Note: To meet the tight timelines and security requirements for the project cloud hosting will likely be
required for the initial pilot testing. After the pilot phase, we will work with UNICEF and the MoH to
explore what in-country hosting solutions could look like if required by their preferences and
requirements. These are details that are unknown now that must be explored and figured out during the
project to ensure they align with expectations, available resourcing, etc.
Sprint 2–3: Campaign Integration Connectors
27

Technical Proposal – Integrated Campaign Registry (ICR)
For the two campaigns identified by the UNICEF Country Office, we will build OpenFn connectors
that extract data from whatever collection tools those campaigns use (ODK, DHIS2 Tracker,
CommCare, or others), transform it into FHIR-conformant resources per the IG, and test loading
data it into the FHIR store. Each connector will follow the transformation layer design described in
Section 2.3. Critically, the campaigns continue using their existing data collection tools — the ICR
meets countries where they are rather than requiring new tools. During these sprints we will also
configure Cinder's deduplication and data quality functions for the specific data types flowing
from each campaign, as cross-campaign deduplication of households and locations will be essential
to registry integrity.
Sprint 4: In-Country Testing, Validation, and Training
We will travel to the first selected country for initial piloting of the ICR approach. During this trip,
we will conduct end-to-end testing with actual campaign data alongside MoH and UNICEF
Country Office staff, validate cross-campaign data reuse (e.g., household locations collected by
one campaign available to the next), and document integration workflows. The trip will also serve
as the primary opportunity for hands-on training with MoH data managers, campaign
coordinators, and IT staff in this country (see Phase 3). We will work directly with MoH
counterparts to walk through ICR operations, conduct UAT to identify usability issues, and gather
feedback that will inform the v2 update. This combined testing-and-training approach ensures
that MoH staff are engaged from the moment the system is live, not trained on it months later as a
separate exercise.
Month 5: Pilot Feedback and IG/System Update (v2)
Based on feedback from the first pilot deployment, we will update the IG and ICR system to
produce a v2 version. This update cycle will address issues identified during live testing — data
model gaps, integration edge cases, performance issues and usability feedback from MoH and
UNICEF staff. All changes will be documented in the IG and ICR reference system change-logs
Month 6: Second Country Deployment
We will deploy the updated ICR (v2) in the second pilot country, adapting the system for the local
context. This includes configuring connectors for the two campaigns identified by that country's
UNICEF Country Office, adapting ValueSets and ConceptMaps for country-specific terminology,
and configuring the Location hierarchy for the country's administrative structure. As with the first
country, the optional in-country trip (up to 10 total days) will combine prototype testing with
hands-on training and stakeholder engagement, onboarding MoH and partner staff while the
system is being validated. The second deployment will test the portability of the reference
solution and surface any country-specific adaptations needed for the replication toolkit.
Training will be conducted in both English and French as required by the pilot country context. For
Francophone countries, Team Lead Matt Berg, who grew up and worked extensively in French
West Africa and/or
Clara Burgert, a bilingual epidemiologist with extensive experience supporting Francophone
country programs will support the in-country piloting and training.
28

Technical Proposal – Integrated Campaign Registry (ICR)
4.2.2 ICR Solution Package
As part of this phase, we will complete the initial implementation of the ICR solution documented
in Section 2.3. This is minus some of the later phase integrations like the data warehouse and
DHIS2 integrations. The software will be developed in an agile methodology with code being made
available in Github. The ICR will be built using open-source technologies with any new software
developed made available under Apache 2.0 or equivalent open source license.
4.2.3 Deliverables
● Prototype ICR system built and tested in the first pilot country, including FHIR store, data
browsing interface (Cinder), and transformation connectors for two campaigns.
● Documented workflows for the integration of two campaigns in the first pilot country,
including data flow diagrams, connector configurations, and data quality management
procedures.
● Updated IG and ICR Solution package system (v2) incorporating pilot feedback.
● Second-country deployment with at least two campaigns integrated, including
country-specific adaptations documented.
● Packaged ICR solution with: user manual and administration guide, technical
documentation for replication, security and data protection documentation, and
open-source licensing framework (Apache 2.0).
4.2.4 Key Dependencies
● Finalized IG from Phase 1 (deliverable d). Platform development cannot begin until the IG
is endorsed for pilot use.
● UNICEF Country Offices must identify the two campaigns for integration in each pilot
country and facilitate MoH engagement before Month 3. Late campaign identification will
compress development sprints.
● Campaign schedules in pilot countries must overlap with the project timeline. If no
campaign runs during Months 3–6, there will be no live data to integrate and validate,
limiting testing to historical data.
● API availability from country systems (DHIS2, ODK, etc.) is dependent on country system
readiness. UNICEF does not guarantee API availability from government systems. Where
APIs are unavailable, we will use file-based or bulk-export integration approaches.
● In-country travel (up to one trip per pilot country, maximum 10 days) requires prior
written UNICEF approval. Travel timing affects our ability to conduct on-the-ground
testing and training.
4.3 Phase 3: Capacity Building and Training (Months 7–12)
Note: Due to travel limitations, the in-country training will be done in Phase 2 during the country
site visits when the system is being tested with live data and MoH staff are directly engaged. Phase
3 will therefore focus on formalizing, documenting, and extending what was learned during the
pilots into documentation and improved training materials.
29

Technical Proposal – Integrated Campaign Registry (ICR)
4.3.1 Approach
Documentation, Job Aids, and SOPs (Months 7–12)
Following the pilot deployments and in-country training (in Phase 2), we will develop SOPS,
job-aids and training materials that will enable UNICEF and MoH staff to operate the ICR
independently with minimal support and train additional resources.
The training / documentation materials will be made available online format and will include:
● Step-by-step job aids for each user role, grounded in the actual workflows established
during the pilots
● Standard operating procedures (SOPs) for integrating ICR data across current and future
campaigns
● Visual workflows showing how data moves between campaign tools, the ICR, DHIS2, and
reporting outputs
● Troubleshooting guides for common issues encountered during the pilots
Integration with Microplanning Workflows
We will work to provide guidance to UNICEF DAPM teams leading the microplanning to ensure
they know how to access the ICR data for microplanning purposes. The Crosscut platform, which
is part of the ICR package, will be made available for microplanning in this phase if desired.
4.3.2 Deliverables
● Training and/or Training-of-Trainers (ToT) sessions conducted in each pilot country for
MoH and implementing partners (delivered during Phase 2 in-country engagements), with
documented attendance and curricula delivered.
● Role based guides, standard operating procedures (SOPs) for integrating ICR data across
current and future campaigns
● Documented approach and implementation of integration of ICR data into national
reporting and microplanning workflows.
4.3.3 Key Dependencies
● Working ICR system from Phase 2. Training is delivered during the pilot trips;
documentation is developed afterward based on lessons learned. If Phase 2 deployment is
delayed or incomplete, both training and documentation quality will be affected.
Phases 4, 5, and 6: Concurrent Workstreams (Months 13–17)
30

Technical Proposal – Integrated Campaign Registry (ICR)
4.4 Phase 4: Global and National Reporting Alignment (Months 13–17)
4.4.1 Approach
Ensure that UNICEF-supported MDA campaigns report using data formats aligned with the WHO
Joint Application Package (JAP) and that reporting processes are embedded within national cycles
so they survive beyond the project period.
JAP Reporting Support
We will work with WHO and ESPEN focal points to map ICR data elements to specific (JAP) form
fields, covering campaign coverage by administrative unit, drug consumption and wastage,
demographic breakdowns, and program performance indicators. We will configure the ICR
package export modules to generate submission-ready outputs that country teams can validate
and submit to WHO/AFRO/ESPEN through established channels. The mapping and export logic
will be documented so that future changes to JAP specifications can be accommodated without
vendor involvement.
UNICEF DAPM Monitoring Support
We will support the UNICEF DAPM team in accessing ICR data for microplanning and real-time
monitoring activities they lead. This will primarily consist of ensuring that DAPM can
independently access and use ICR data without ongoing vendor support.
4.4.2 Deliverables
● JAP-aligned data outputs and export functionality developed and validated for
UNICEF-supported MDA campaigns, including documented field-level mapping between
ICR data elements and JAP form specifications.
● Reporting outputs aligned with JAP forms and validated against WHO and national
requirements, with documented procedures for MoH staff to independently generate and
submit reports.
● Data access workflows established and documented to enable use of ICR data by UNICEF
DAPM for real-time monitoring.
4.4.3 Key Dependencies
● Operational ICR with real campaign data from Phases 2–3. Reporting alignment requires
actual data flowing through the system.
● WHO/ESPEN for current JAP form specifications and validation of the mapping. If WHO
updates JAP requirements during the project, this may require a change order.
● UNICEF DAPM team availability to define data access needs.
31

Technical Proposal – Integrated Campaign Registry (ICR)
4.5 Phase 5: Systems Integration (Months 13–17)
4.5.1 Approach
During Phase 2, we will have already built the data collection connectors for campaign data
needed for country piloting. This phase will thus focus on integrations for DHIS2, the data
warehouse and two-way integration and WHO's Geospatial Microplanner (Crosscut Platform).
Analytics Add-On: FHIR-to-Data-Warehouse
The SQL on FHIR layer described in Section 2.3 transforms FHIR resources into flat, queryable
tables in a relational data warehouse using ViewDefinition resources that are part of the IG.
During this phase, we will put in place the tools to automate these processes to help generate the
reporting requirements identified during Phase 3 and 4 and to populate the JAP forms.
DHIS2 Integration
We will develop a connector that will enable importing data from the ICR into DHIS2. This will
include importing of location data (organization units), aggregate indicators into the ICR. We will
leverage an existing platform like OpenFN to do this vs. developing a bespoke solution. The
connector will be openly available, documented and included in the replication toolkit in Phase 6.
Two-Way WHO Geospatial Microplanner Integration
The WHO Geospatial Microplanner is powered by the Crosscut platform (see Section 3.7),
meaning this integration is between two components within our consortium's technical control,
significantly reducing integration risk. The Crosscut will extend its platform to consume FHIR data
from the ICR eg. health facility locations enabling users to define catchment areas, assign
population estimates, calculate risk scores, and delineate supervisory zones. Enriched data will be
pushed back into the ICR's FHIR store, creating a bidirectional flow that will help bolster the use of
ICR data for microplanning.
4.5.2 Deliverables
● ViewDefinition based data warehouse connector developed and documented that is able
to meet JAP / country reporting and analytical needs.
● Production-grade data connectors for DHIS2 (bidirectional) and the UNICEF-designated
platform (ODK or as confirmed), with documented data flows, error handling, and testing
evidence.
● Two-way WHO Geospatial Microplanner integration established and tested, with
documented data flows for ICR-to-Microplanner import and Microplanner-to-ICR
pushback.
4.5.3 Key Dependencies
● Stable ICR platform with real campaign data from Phases 2–3.
● DHIS2 API availability from country instances. DHIS2 versions and API capabilities vary
by country and are not guaranteed by UNICEF. Where APIs are limited, we will use
DHIS2's import/export functionality as a fallback.
32

Technical Proposal – Integrated Campaign Registry (ICR)
● Crosscut platform readiness for FHIR data consumption and pushback. As a consortium
partner, this dependency is managed internally through joint sprint planning.
4.6 Phase 6: Sustainability and Continuity (Months 13–17)
4.6.1 Approach
Sustainability is not a bolt-on activity at the end of the project — it is a design principle embedded
from Phase 1 (open-standard IG, open-source licensing) through Phase 3 (capacity building, MoH
ownership orientation). Phase 6 formalizes the sustainability outcomes of these earlier
investments, ensures the ICR is institutionalized within national systems, and packages the
solution for replication.
Institutionalization within National Reporting Cycles
Working with MoH and UNICEF in each pilot country, we will work to embed ICR reporting
processes into MoH systems (eg. via DHIS2 and JAP reporting). We will work with UNICEF to try
and ensure that integrated campaign reporting is recognized as a standardized requirement within
government systems, not a project-specific activity. This may involve supporting MoH directives or
SOPs that formalize ICR-based reporting, integrating ICR data submission into existing HMIS
reporting calendars, and documenting the reporting workflow for independent MoH maintenance.
The specific mechanisms will vary by country and will be developed in close consultation with
MoH leadership and UNICEF Country Offices.
System Handover and Government Ownership
We will execute a structured handover to ensure MoH technical counterparts can maintain and
extend the ICR beyond the project period. This includes transferring the source code repository
with CI/CD pipeline documentation and build/deployment instructions, delivering a system
administration and ICR maintenance guide covering FHIR store management, connector
monitoring, data quality procedures, and troubleshooting.
Replication Toolkit
The replication toolkit will package the documentation and developed systems to enable
expansion for additional countries. This will include:
● The published IG with instructions with data governance / instructions on how to localize
modify by country.
● ICR package including all software components with documentation, supporting
deployment scripts, etc.
● Connector templates for common campaign data sources (ODK, DHIS2 Tracker,
CommCare) with documented configuration points
● Training materials developed in from Phase 3, packaged for reuse
The toolkit will be hosted in a public GitHub repository under the Apache 2.0 license, ensuring any
country, organization, or donor can access, use, and extend it without restriction.
33

Technical Proposal – Integrated Campaign Registry (ICR)
4.6.2 Deliverables
● ICR reporting processes embedded and documented within national MoH reporting cycles
in each pilot country, including any supporting MoH directives, SOPs, or calendar
integrations.
● System components and maintenance documentation (source code, documentation,
maintenance guides) shared with MoH counterparts.
● Replication toolkit for expansion to additional countries, published in a public GitHub
repository under Apache 2.0 license.
4.6.3 Key Dependencies
● Successful Phase 2 and 3 outcomes. Sustainability is only meaningful if the ICR is
operational and MoH staff are trained.
● MoH institutional commitment. Embedding the ICR into national reporting cycles
requires political will and institutional buy-in that UNICEF can influence but the vendor
cannot unilaterally deliver.
● Lessons from both pilot countries. The replication toolkit depends on sufficient
implementation experience to produce credible, tested guidance.
4.7 Limitations and Exclusions
• Integrations are limited to country-owned systems and globally recognized platforms
(DHIS2, OpenSRP, ODK, and other government-approved tools). No integration with
UNICEF internal systems is required. Integration with custom, bespoke, or locally
developed solutions is not in scope for this phase.
• The ICR does not replace existing data collection tools. Campaigns continue using their
existing tools; the ICR provides the interoperability and exchange layer.
• The Vendor is not responsible for procuring or distributing NTD medicines, conducting
MDAs, or leading microplanning activities.
• Any development requirements that arise outside the scope of this ToR will be managed
through a formal Change Order process, with scope, pricing, and timeline mutually agreed
through contract amendment.
• The scope of this engagement covers the initial 17-month period of performance.
Maintenance and support services beyond this period are optional and subject to
UNICEF's decision to exercise the extension.
• Data ownership rests with country governments. Data sharing and access will be governed
by the respective government entity's data-sharing policies. Ona cannot guarantee the
availability or shareability of datasets generated during the project.
• The Vendor is not responsible for generating geospatial data (e.g., building footprints,
satellite imagery, or population estimates). Where such data is needed, it is expected to be
provided by UNICEF, MoH, or sourced from publicly available datasets.
34

Technical Proposal – Integrated Campaign Registry (ICR)
• Deployment is limited to two pilot countries as defined in the ToR. Scale-up beyond these
countries is outside the scope of this engagement, though a replication toolkit will be
delivered to support future expansion.
35

Technical Proposal – Integrated Campaign Registry (ICR)
7. Project Team
This project is led by Ona Systems, Inc. as Prime/Lead Contractor. Ona holds full contractual
accountability to UNICEF for performance of the entire assignment and is responsible for overall
technical direction, quality, and timely completion of all deliverables. Crosscut serves as a named
consortium partner, contributing specialized capabilities in geospatial microplanning, campaign
data analysis, and country engagement.
7.1 Organization Responsibilities
Ona Systems leads the development of the HL7 FHIR Implementation Guide, the ICR reference
platform and all data integrations, documentation, standard operating procedures, training
materials, and quality assurance. Ona leads in-country technical engagement for the country pilots
and coordinates all project reporting to UNICEF.
Crosscut leads geospatial platform adaptation for FHIR data consumption from the ICR, two-way
integration with the WHO ESPEN Geospatial Microplanner. Crosscut will provide support in the
design of the initial IG, on ground-support for the country piloting and ongoing documentation
and replication package development.
7.2 Consortium Structure
This proposal is submitted by Ona Systems, Inc. as Prime/Lead Contractor. Ona holds the relevant
Long-Term Agreement (LTAS) with UNICEF and retains full contractual accountability to UNICEF
for performance of the entire assignment, including all activities carried out by consortium
members Crosscut serves as a consortium partner for the full duration of the engagement.
The consortium arrangement is additive: Crosscut brings specialized capabilities in geospatial
microplanning technology, campaign data analysis, and in-country implementation that
complement and strengthen Ona's core competencies in HL7 FHIR standards, digital health
platform development, and health system interoperability. Crosscut's scope does not substitute
for any of the core competencies required of the Prime/Lead Contractor under this ToR.
Coordination between Ona and Crosscut is managed through joint sprint planning under Ona's
two-week Agile development cycle, a shared project management platform for task tracking and
issue management, and regular synchronization between Matt Berg (Ona) and Coite Manuel
(Crosscut). All project-related Crosscut activities are coordinated through and accountable to
Matt Berg as project lead. Decisions affecting scope, timeline, or deliverables are escalated to
UNICEF through Ona. Crosscut commits to full compliance with UNICEF's applicable policies and
requirements for the duration of the engagement.
A signed letter of commitment by Crosscut is attached in the Appendix.
36

Technical Proposal – Integrated Campaign Registry (ICR)
7.3 Key Personnel
Matt Berg — Project Lead Organization: Ona Systems, Inc. Role on this project: Project Manager,
System Architect, Named FHIR IG Author, In-Country Lead for Côte d'Ivoire Overall LOE: 50%
across 17 months Languages: English, French CV: Annex B
Matt Berg is the Chief Executive Officer of Ona Systems and the named FHIR IG author for this
assignment. He brings close to 20 years of experience in digital health with deep expertise in HL7
FHIR standards and health data systems. Matt was instrumental in developing the WHO SMART
Guidelines framework and has been a leading advocate for FHIR adoption across global health
systems, having built and overseen FHIR-native applications across multiple country deployments.
He has driven the concept of integrated campaign registries through sustained engagement with
UNICEF, WHO, and other global partners. Matt is fluent in French, having grown up and worked
extensively in Francophone West Africa, and will serve as the in-country technical lead for the
Côte d'Ivoire pilot. His CV, including links to previously authored and publicly inspectable FHIR
Implementation Guides, is provided in Annex B.
John Mashuma — Lead Developer and Interoperability Specialist Organization: Ona Systems, Inc.
Role on this project: Lead Developer, SRE, Security and Interoperability Specialist Overall LOE: 60%
across 17 months Location: Nairobi, Kenya Languages: English CV: Annex B
John Mashuma is a senior software engineer and SRE expert at Ona Systems based in Nairobi,
Kenya. He serves as Lead Developer and Interoperability Specialist for this assignment, with
primary responsibility for the ICR platform build, FHIR store configuration and management,
integration connectors and system hosting and security. John has direct experience developing
and maintaining secure software systems that have been implemented at scale. His full CV is
provided in Annex B.
Faith Mutua— Documentation, Training and QA Specialist Organization: Ona Systems, Inc. Role on
this project: Documentation, Training and QA Specialist Overall LOE: 33% across 17 months
Location: Nairobi, Kenya Languages: English CV: Annex B
Faith is a member of the Ona team in Nairobi, holding a BSc in Mathematics and Computer Science
with a background in data analysis and implementation support. On this project, she leads the
development of standard operating procedures, role-based job aids, and training materials for
Ministry of Health and implementing partner staff in both pilot countries, and supports quality
assurance across project deliverables. Her work is concentrated in Phase 3 (Months 7–12),
building on operational learning from the Phase 2 pilot deployments. Her full CV is provided in
Annex B.
37

Technical Proposal – Integrated Campaign Registry (ICR)
Coite Manuel — Senior Advisor Organization: Crosscut Role on this project: Senior Advisor,
Strategic Partnerships; in-country participation for Sierra Leone pilot Overall LOE: 5% across 17
months, with higher engagement during Phase 2 Location: Washington, DC Languages: English,
Spanish
Coite Manuel is the Founder and Chief Executive Officer of Crosscut, a verified Digital Public
Good and DHIS2 Tier 2 Strategic Technology Partner. He brings more than 20 years of experience
in global health supply chain strategy, digital health system design, and multi-country
implementation leadership, including five years as Senior Supply Chain Advisor in USAID's Global
Health Office. He has led complex multi-country engagements with Ministries of Health, UNICEF,
WHO/ESPEN, and USAID/PMI across more than 10 Sub-Saharan African countries across NTD
mass drug administration, immunization, and malaria programs. He holds an M.S. in Industrial
Engineering from Georgia Institute of Technology and a B.S. in Applied Mathematics and
Mathematical Economics from Hampden-Sydney College. On this project, Coite serves as Senior
Advisor, providing strategic oversight and supporting stakeholder engagement, and joins the
in-country deployment to the Sierra Leone pilot during Phase 2. His full CV is provided in Annex B.
James McKinnon — Senior Business Analyst Organization: Crosscut Role on this project: Senior
Business Analyst, Campaign Data Lead Overall LOE: 21% across 17 months Location: Atlanta, GA
Languages: English
James McKinnon is a global health senior data analyst and geospatial data specialist with more
than 10 years of experience delivering analytics and field operations across Sub-Saharan Africa,
South Asia, and beyond. At Crosscut, he leads data-intensive analytical work including GIS-based
operational map production, raster analysis, and network modelling for health campaigns. He has
led UNICEF-funded supply chain and immunization assessments in Ethiopia and The Gambia —
including the personal geocoding of The Gambia's entire national vaccination network — and
served as Head of Supply for Médecins Sans Frontières in South Sudan, where he designed and
executed a cold chain strategy for an emergency measles vaccination campaign. He coordinated
supply chain data across 38 countries during his time with USAID. On this project, James leads
campaign data discovery and analysis in Phase 1, country implementation support for the Sierra
Leone pilot in Phase 2, JAP output coordination and NTD reporting workflows in Phase 4, and
contributes to systems integration and sustainability activities in Phases 5 and 6. He holds an M.A.
in International Development from the Josef Korbel School of International Studies and a B.A. in
Mathematics and Philosophy (Summa Cum Laude, Phi Beta Kappa) from Wabash College. His full
CV is provided in Annex B.
Clara Burgert — Country Engagement Lead, Sierra Leone Organization: Crosscut Role on this
project: Senior Country Engagement Lead for Sierra Leone pilot Overall LOE: 5%, concentrated in
Phase 2 Location: Silver Spring, MD Languages: English (fluent), French (fluent)
Clara Burgert is a PhD-trained infectious disease epidemiologist with more than 20 years of
experience applying advanced quantitative and spatial methods to neglected tropical disease
programs, immunization campaigns, malaria surveillance, and public health intervention
evaluation across more than 20 countries. She holds a PhD in Infectious and Tropical Diseases
38

Technical Proposal – Integrated Campaign Registry (ICR)
Epidemiology from the London School of Hygiene and Tropical Medicine and an MPH in Global
Epidemiology from Emory University. She currently leads multi-country evaluations of geospatial
microplanning for community drug distribution programs and serves as project lead for
Francophone country activities, managing stakeholder engagement with Ministries of Health and
implementing partners in French. She has facilitated more than 10 regional trainings in
epidemiology, GIS, and data visualization for Ministry of Health and partner staff across multiple
countries. On this project, Clara serves as the senior country engagement lead for the Sierra Leone
pilot deployment in Phase 2, drawing on her deep NTD program knowledge and MoH engagement
experience. Her full CV is provided in Annex B.
Sam Hoogewind — Software Engineer, Crosscut Platform Development Organization: Crosscut
Role on this project: Software Engineer, Crosscut platform FHIR adaptation and analytics layer
Overall LOE: 25% across 17 months, concentrated in Phase 5 Location: Washington, DC Languages:
English
Sam Hoogewind is a software engineer at Crosscut specializing in cloud-based geospatial data
pipelines, population modelling algorithms, and frontend visualization for global health
applications. He engineers scalable AWS data pipelines supporting real-time geospatial data
access across 45+ African countries at 99%+ uptime, and designed the foundational population
raster algorithm that serves as the core population data layer across Crosscut's platform. He holds
a B.S. in Computer Science (Magna Cum Laude, GPA 3.80) from Calvin University. On this project,
Sam supports Crosscut platform adaptation for FHIR data consumption in Phase 2 and leads
development of the Crosscut platform FHIR integration and analytics layer components in Phase
5. His full CV is provided in Annex B.
Emmanuel Koh — Software Engineer, WHO ESPEN Geospatial Microplanner Integration
Organization: Crosscut Role on this project: Software Engineer, WHO ESPEN Geospatial
Microplanner two-way integration Overall LOE: 5%, concentrated in Phase 5 Location: Boston, MA
Languages: English
Emmanuel Koh is a full-stack software engineer at Crosscut who owns the WHO ESPEN
Schistosomiasis Mapper Tool end-to-end — a publicly deployed platform on WHO's ESPEN Portal
supporting NTD preventive chemotherapy campaign planning across 30+ countries and 88,000
administrative boundaries. He coordinated with WHO's ESPEN team to define a dedicated survey
data API and established the boundary-matching workflow for 40+ countries, giving him direct
institutional knowledge of the ESPEN API and data architecture that the ICR's Phase 5 integration
requires. On this project, Emmanuel leads the two-way integration between the ICR and the WHO
ESPEN Geospatial Microplanner during Phase 5, drawing on his existing ESPEN API relationships
and platform ownership to minimize integration complexity and risk. His full CV is provided in
Annex B.
39

Technical Proposal – Integrated Campaign Registry (ICR)
Brianna Poulos — Technical Advisor Organization: Crosscut Role on this project: Technical Advisor
Overall LOE: 2% Location: Washington, DC Languages: English
Brianna Poulos is a senior software engineer and technical leader with 15 years of experience
designing and operating large-scale cloud-native systems. She leads engineering for Crosscut's
geospatial modelling platform, which powers national-scale public health campaign planning
across 43 Sub-Saharan African countries including the WHO AFRO ESPEN Geospatial
Microplanner. Prior to Crosscut, she spent eight years at the Johns Hopkins University Applied
Physics Laboratory as a Senior Staff Engineer on mission-critical secure systems, where she led
OpenStack deployment initiatives and authored research on cloud data protection. She holds an
M.S. in Computer Science from Johns Hopkins University and a B.S. in Computer Engineering
(Valedictorian) from North Carolina State University. On this project, Brianna provides technical
advisory and security architecture review, drawing on her expertise in secure cloud system design
relevant to UNICEF's information security requirements. Her full CV is provided in Annex B.
40

Technical Proposal – Integrated Campaign Registry (ICR)
Appendix 3
Proof of Compliance — FHIR Implementation Guide Criteria
The following evidence demonstrates that our submission meets the requirements for the IG
deliverable.
1. Published, inspectable FHIR IG
● Live IG (browsable): https://ona-health.github.io/smart-immunizations-minsa/
● GitHub repository (FSH/SUSHI source):
https://github.com/ona-health/smart-immunizations-minsa
○ FSH resources -
https://github.com/ona-health/smart-immunizations-minsa/tree/main/input/fsh
● Artifact index (profiles, extensions, value sets, code systems, examples):
https://ona-health.github.io/smart-immunizations-minsa/artifacts.html
● ImplementationGuide FHIR resource (JSON):
https://ona-health.github.io/smart-immunizations-minsa/ImplementationGuide-minsa.gob
.pe.immunizations.json
2. Working FSH/SUSHI profiles (R4)
This IG is authored in FHIR Shorthand (FHS) and compiled with SUSHI.
● FHIR version: R4 (4.0.1) is configured here. Sushi-config.yaml. Note this includes
the IG author Matt Berg (team lead on this project).
● FSH source location:
https://github.com/ona-health/smart-immunizations-minsa/tree/main/input/fsh — 26 FSH
files totaling 3 profiles, 3 extensions, 4 value sets, 2 code systems, 7 PlanDefinitions, and 6
Questionnaires.
FSH Source and SUSHI compiled FHIR artifacts
Artifact type FSH source (GitHub) Rendered page (live IG)
StructureDefinition MINSAImmunization.fsh StructureDefinition-MINSA.Imm
(profile) unization.html
ValueSet MINSAVaccineVS.fsh ValueSet-MINSAVaccineVS.html
41

Technical Proposal – Integrated Campaign Registry (ICR)
Extension MINSADepartamento.fsh StructureDefinition-MINSADep
artamento.html
Compilation evidence
All three required artifact types render cleanly on GitHub Pages — HTML pages exist, snapshots
and differentials resolve, base resource references bind. If any FSH file had failed to compile, the
corresponding page would not exist on the published site.
3. Named FHIR IG author on proposed team with verifiable CV
Matt Berg who is the project lead for Ona for the project is a listed author on this IG that was
developed in collaboration with MINSA in Peru as part of the FHIR adoption support Ona provided
MINSA through Paho.
Matt Berg can be found on the authors list here:
https://ona-health.github.io/smart-immunizations-minsa/
And also on the SUSHI config here IG authors can be listed.
https://github.com/ona-health/smart-immunizations-minsa/blob/main/sushi-config.yaml
42

Technical Proposal – Integrated Campaign Registry (ICR)
Service Level Agreement (SLA)
Maintenance and Support Services – Integrated Campaign Registry
Note: this is meant to indicate how an SLA for the ICR could be structured. It is impossible at this time
(before the project has even started) to understand what the final terms and conditions of the SLA will be.
There are many factors that would need to be understood and accounted for before we could develop an
SLA that we would ensure would meet the needs of both UNICEF and Ona.
The following provides a very basic example of what an SLA for an Ona managed, cloud hosted version of
ICR could look like.
Things it does not include or would need to be accounted for:
● It does not include a cost for hosting. We do not know what the needs would be in terms of
number of countries, campaigns, etc.
● If support for in-country hosting is required, the SLA would need to be developed on a per-country
basis. If the system is hosted by a MoH, for example, many factors related to the hosting of the
system would be completely out of our control.
● This does not account for source systems - eg. ODK potentially not working.
● It does not account for any additional feature development or capacity building. Those would
need to be budged scoped exercises.
If an SLA is required, we would request to UNICEF that development of the SLA is built into the process.
This could be added scope in a final phase deliverable.
1. Support Model
The Vendor will provide maintenance and support for all ICR components, including the FHIR
store (HealthCare API), data transformation and ingestion connectors (OpenFn), the data
browsing and quality management layer (Cinder), the geospatial and microplanning layer
(Crosscut), the analytics/data warehouse layer, and DHIS2 integration connectors.
Helpdesk and Ticketing. All support requests will be submitted through a dedicated ticketing
system (e.g., GitHub Issues or Jira Service Management). Each ticket will be assigned a unique
identifier, a severity level, and an assigned owner. UNICEF and MoH focal points will have direct
access to submit, track, and comment on tickets.
Escalation Procedures. Issues not resolved within the target resolution window will be
automatically escalated. Level 1 (Support Engineer) handles initial triage and known‑issue
resolution. Level 2 (Senior Developer) handles complex bugs and configuration issues. Level 3
(Technical Lead / Architect) handles critical system failures, data integrity issues, and architectural
decisions. Escalation from L1 to L2 occurs if no resolution is achieved within 50% of the target
resolution time. L2 to L3 escalation occurs at 75% of the target resolution time.
43

Technical Proposal – Integrated Campaign Registry (ICR)
2. Response and Resolution Timelines
All response and resolution times are measured in business hours (see Section 4 for hours of operation).
Severity Definition Response Resolution Example
Critical (P1) Production system down or data loss 2 business 8 business FHIR store
affecting all users; no workaround hour hours unresponsive; data
available. ingestion pipeline
failure during active
campaign.
High (P2) Major feature degraded with 4 business 3 business DHIS2 connector
significant user impact; workaround hours days failing for one pilot
may exist but is not sustainable. country; deduplication
engine producing
incorrect matches.
Medium (P3) Minor feature issue or degradation; 1 business day 5 business Dashboard
workaround available and acceptable days visualization
for continued operations. rendering incorrectly;
non-critical report
formatting error.
Low (P4) Cosmetic issue, enhancement 2 business Next UI label correction;
request, or documentation update days scheduled documentation
with no operational impact. release clarification.
Response time is defined as acknowledgment of the ticket with an assigned severity and owner.
Resolution time is defined as delivery of a fix, workaround, or patch that restores functionality.
Permanent fixes may follow in a subsequent release if an interim workaround resolves the
immediate impact.
3. Issue Tracking, Reporting, and Resolution Management
• Ticket Lifecycle: Each issue follows a standard lifecycle: Open → Triaged → In Progress →
Resolved → Closed. Tickets are closed only after confirmation from the reporting party.
• Monthly Reporting: The Vendor will deliver a monthly support summary to UNICEF
including: total tickets opened and closed, breakdown by severity, mean response and
resolution times, SLA compliance rate, and a summary of outstanding issues.
• Quarterly Review: The Vendor and UNICEF will conduct a quarterly service review to
assess SLA performance, identify systemic issues, and agree on improvement actions or
SLA adjustments as needed.
4. Availability and Coverage
• Hours of Operation: Monday through Friday, 08:00–17:00 East Africa Time (EAT, UTC+3),
excluding public holidays observed in pilot countries.
• Critical Issue Coverage: For P1 (Critical) issues occurring during an active campaign
window, the Vendor will provide best‑effort after‑hours response within 4 hours of
notification via a designated emergency contact.
44

Technical Proposal – Integrated Campaign Registry (ICR)
• System Uptime Target: The Vendor will target 99.5% uptime for cloud-hosted ICR
components during business hours, excluding scheduled maintenance windows
communicated at least 48 hours in advance.
45

Geospatial Microplanning and Supply Chain Analytics crosscut.io
coite@crosscut.io
+1-703-727-8784
Washington, DC | USA
April 14, 2026
To:
UNICEF
Supply Division
Re: Letter of Commitment — Consortium Partner Participation, UNICEF Terms of Reference for the
Design, Development, and Deployment of the Integrated Campaign Registry (ICR), Annex B – LOT 1C
Dear Sir/Madam,
Crosscut hereby confirms its participation as a consortium partner to Ona Systems, Inc. ("Ona"), the
Prime/Lead Contractor, in Ona's proposal submitted in response to the above-referenced UNICEF Terms
of Reference.
Crosscut is available for the full duration of the engagement and commits to fulfilling its agreed
responsibilities within the consortium as defined in the proposal.
Crosscut acknowledges that Ona Systems retains full contractual accountability to UNICEF for
performance of the entire assignment, and that any changes to consortium membership after contract
award require prior written approval from UNICEF.
Yours sincerely,
Coite Manuel
Founder & Chief Executive Officer
Crosscut
April 14, 2026

|                   |          | MATTHEW    | L. BERG |     |                  |     |
| ----------------- | -------- | ---------- | ------- | --- | ---------------- | --- |
| 46 Brewer Parkway |          |            |         |     | mlberg@gmail.com |     |
| South Burlington, | Vermont, | 05403, USA |         |     |                  |     |
+1.202.823.5864
| PROFESSIONAL | EXPERIENCE |     |     |     |                      |     |
| ------------ | ---------- | --- | --- | --- | -------------------- | --- |
| Ona          |            |     |     |     | October 2013-Present |     |
Co-Founder and Chief Executive O!cer Nairobi, KE & Burlington, VT
Co-FounderofaKenyan/USsocialenterprisethatdevelopstechnologysolutionstohelporganizations
| make smarter | use of data | to address important | global challenges. |     |     |     |
| ------------ | ----------- | -------------------- | ------------------ | --- | --- | --- |
Overseegrowthofaglobalteamof70+peoplethathasdeliveredover 15MUSDinprojectssupporting
| global development | partners. |     |     |     |     |     |
| ------------------ | --------- | --- | --- | --- | --- | --- |
Contributed to the creation and development of OpenSRP, Reveal and Open Health Stack as digital
| global goods. |     |     |     |     |     |     |
| ------------- | --- | --- | --- | --- | --- | --- |
LeaddevelopmentofOnaDataandAkukoSAASproductsthathavebeenusedtoprovidecriticaldata
collection and analysis services to 1000’s of organizations globally including key UN organizations.
InvolvedintheinceptionoftheWHOSMARTGuidelinesincludinghelpingcreateinpartnershipwith
| Google initial | L4 reference | applications. |     |     |     |     |
| -------------- | ------------ | ------------- | --- | --- | --- | --- |
Developed Electronic Immunization Registry systems deployed in Zambia, Mauritania and Tunisia.
WorkedinpartnershipwithGIZandWHOtodevelopreferenceWHOSMARTGuidelineApplications
for Immunizations.
Developed national level community health worker applications (eCHIS) systems in Liberia, Uganda
| and Bangladesh | that | in aggregate are registered | over 90M+ | clients. |     |     |
| -------------- | ---- | --------------------------- | --------- | -------- | --- | --- |
Led design, development and implementation of digital health solutions in over a dozen countries.
The Earth Institute at Columbia University July 2007-September 2013
ICT Director for the Modi Research Group & Millennium Villages Project New York, NY
Implement and provide strategic oversight of the Information & Communication Technology (ICT)
| sector for | the Earth Institute. |     |     |     |     |     |
| ---------- | -------------------- | --- | --- | --- | --- | --- |
Led NYC and field based engineering team consisting of African regional and site based programming
| and technical | sta! |     |     |     |     |     |
| ------------- | ---- | --- | --- | --- | --- | --- |
Technical lead of the development of the Smart Registry platform for the NRHM in Karnataka, India.
Led design and development of open source mobile data collection platform Formhub
Design, develop and implement innovative mobile platforms including ChildCount+ - a mHealth plat-
form that uses SMS text messages to monitor the health of women and children
Development of a national scale SMS based clinic based monitoring system in Uganda
Coordinate with field sta! to design and implement ICT interventions in the Millennium Villages
including the establishment of community radios, wifi-networks, school computer labs, medical record
systems in clinics, ICT kiosks, phone charging booths and mobile phone application pilots
| IESC Geekcorps   | Mali |     |     |     | October 2005-July | 2007 |
| ---------------- | ---- | --- | --- | --- | ----------------- | ---- |
| Country Director |      |     |     |     | Bamako,           | Mali |
Chief of Party for a 2.6 million dollar USAID Mali Communications for Development and Last Mile
| Initiative | grant program |     |     |     |     |     |
| ---------- | ------------- | --- | --- | --- | --- | --- |
Managementofprogramo”ceinFrenchwith13localsta!andvolunteerprogramwith10international
volunteers
Implemented and developed appropriate technology solutions: LTSP Linux thin clients and multi-
terminalcomputers, asynchronousInternetviaUSBkey, low-powerGeekcorps’DesertPC,video-over-
Wi-Fi CanTV, bandwidth limiting RGBAN remote networking system, Wikipedia CD, Solar/LED
| lighting systems | and low-cost | solar FM Transmitter | and | studio |     |     |
| ---------------- | ------------ | -------------------- | --- | ------ | --- | --- |

IESC Geekcorps & Digital Freedom Initiative in Senegal May-August 2005
| Geekcorps | Volunteer |     |     |     |     |     |     | Dakar, Senegal |
| --------- | --------- | --- | --- | --- | --- | --- | --- | -------------- |
Developed/implemented a web/paper based accounting system for African merchants and women
| groups      | (www.baolbaol.com) |       |                 |     |      |     |     |             |
| ----------- | ------------------ | ----- | --------------- | --- | ---- | --- | --- | ----------- |
| Inspidered, |                    | Inc – | Web Development |     | Firm |     |     | 2003-2005   |
| Co-founder  |                    |       |                 |     |      |     |     | Chicago, IL |
Provided web programming and design and database development services for non-profits in Chicago.
| Meritum          | Corporation |       | –   | Internet | Startup |     |     | 2002-2003   |
| ---------------- | ----------- | ----- | --- | -------- | ------- | --- | --- | ----------- |
| Chief Technology |             | O!cer |     |          |         |     |     | Chicago, IL |
Oversaw the system design, programming, and billing support for a web-system built on open source
standards that created a turnkey solution that allowed clients to sell self-replicating websites to over
| 20,000 | paying |     | members |     |     |     |     |     |
| ------ | ------ | --- | ------- | --- | --- | --- | --- | --- |
Infocast Community – ISP & Internet Services Startup 2000-2002
| Director | of Creative |     | Services |     |     |     |     | Tucson, AZ |
| -------- | ----------- | --- | -------- | --- | --- | --- | --- | ---------- |
Managed creative service team: 5 programmers, 2 designers and 2 support sta!
Oversaw the system design, programming, and billing support for a web-systems built on open source
standards
EDUCATION
| Thunderbird, |               | School        | of International |      | Management    |     |     |              |
| ------------ | ------------- | ------------- | ---------------- | ---- | ------------- | --- | --- | ------------ |
| MBA in       | International |               | Management,      |      | GPA 3.80      |     |     | Spring 2005  |
| Ambassador   |               | Assistantship |                  | (1/3 | tuition)      |     |     | Glendale, AZ |
| Beta         | Gamma         |               | Sigma Business   |      | Honor Society |     |     |              |
Universidad Aut´onoma de Guadalajara Thunderbird Program (Guadalajara, Mexico, Summer 2004)
Knox College
Bachelor of Science Computer Science & Bachelor of Arts Integrated International Studies Spring 2000
| Lincoln |     | Scholar       | (full tuition) |       |             |           |             | Galesburg, IL |
| ------- | --- | ------------- | -------------- | ----- | ----------- | --------- | ----------- | ------------- |
| Honors  |     | Dissertation: | The            | State | of Computer | Education | in Zimbabwe |               |
University of Zimbabwe: 8 month academic and cultural exchange (Harare, Zimbabwe, 1999)
| AWARDS | &       | HONORS   |                   |             |           |             |        |     |
| ------ | ------- | -------- | ----------------- | ----------- | --------- | ----------- | ------ | --- |
| 2018   | Time    | Magazine | 50                | Genius      | Companies |             |        |     |
| 2010   | Time    | 100      | List of           | the World’s | Most      | Influential | People |     |
| 2010   | PopTech |          | Social Innovation |             | Fellow    |             |        |     |
| 2010   | Knox    | College  | Young             | Alumni      | Award     |             |        |     |
| 2006   | Tech    | Museum   | Award             | Laureate    |           |             |        |     |
Publications
Garrett L Mehl, Martin G Seneviratne, Matt L Berg, Suhel Bidani, Rebecca L Distler, Marelize
Gorgens,KarinEKallander,AlainBLabrique,MarkSLandry,CarlLeitner,PeterBLubell-Doughtie,
Alvin D Marcelo, Yossi Matias, Jennifer Nelson, Von Nguyen, Jean Philbert Nsengimana, Maeghan
Orton, Daniel R Otzoy Garcia, Daniel R Oyaole, Natschja Ratanaprayul, Susann Roth, Merrick P
Schaefer, Dykki Settle, Jing Tang, Barakissa Tien-Wahser, Steven Wanyee, Fred Hersch. “A full-
STACremedyforglobaldigitalhealthtransformation: openstandards,technologies,architecturesand
| content”. |     | Oxford | Open | Digital | Health, | Volume | 1, 2023. |     |
| --------- | --- | ------ | ---- | ------- | ------- | ------ | -------- | --- |
Nandini Oomman, Garrett Mehl, Matt Berg, Rachel Silverman. “Modernising vital registration sys-
tems: why now?” The Lancet, Volume 381, Issue 9875, 2013, Pages 1336-1337.
Berg, Matt, et al. “Cellular citizenship: invigorating development through mobile.” Harvard Interna-
| tional | Review, |     | vol. 34, | no. 3, winter | 2013, | pp. 28+ |     |     |
| ------ | ------- | --- | -------- | ------------- | ----- | ------- | --- | --- |

Caroline Asiimwe, David Gelvin, Evan Lee, Yanis Ben Amor, Ebony Quinto, Charles Katureebe,
Lakshmi Sundaram, David Bell, and Matt Berg. “Use of an Innovative, A!ordable, and Open-Source
Short Message Service–Based Tool to Monitor Malaria in Remote Areas of Uganda”. The American
| Journal | of Tropical Medicine | and Hygiene. 2011 | July 1; 85(1): | 26–33. |
| ------- | -------------------- | ----------------- | -------------- | ------ |
Activities
| Thunderbird | Global Council | Member (2012-2014)    |             |     |
| ----------- | -------------- | --------------------- | ----------- | --- |
| WHO mHealth | Technical      | Advisory Group (mTag) | (2012-2014) |     |
LANGUAGES
| English (Native), | French (Fluent), | Spanish (Basic) |     |     |
| ----------------- | ---------------- | --------------- | --- | --- |
| GEOGRAPHIC        | WORK EXPERIENCE  |                 |     |     |
Afghanistan,Ethiopia,Ghana,India,Indonesia,Kenya,Mauritania,Malawi,Mali,Mexico,Nigeria,Rwanda,
Senegal, Somalia, South Africa, Tanzania, Uganda, Rwanda, Sri Lanka, Viet Nam, Zambia, Zimbabwe

|     |                         |     |     | John |     | Mwashuma         |     |          |        |
| --- | ----------------------- | --- | --- | ---- | --- | ---------------- | --- | -------- | ------ |
|     | john.mwashuma@gmail.com |     |     |      |     | +254-716-647-845 |     | LinkedIn | Github |
|     |                         |     |     |      |     | |                |     | |        | |      |
Summary
SeniorSoftwareEngineerwithover6yearsofexperienceinfull-stackdevelopment, cloud-native
architectures, and microservices. Expert in leading backend teams, migrating applications to
Kubernetes, and automating CI/CD pipelines. Proven track record of delivering high-impact
solutions—such as the TallyHo election tallying system and the Akuko BI platform—through
technical leadership, rigorous roadmap, sprint planning, and e!ective cross-functional team
collaboration.
| Professional |     | Experience |     |     |     |     |     |     |     |
| ------------ | --- | ---------- | --- | --- | --- | --- | --- | --- | --- |
Senior Software Engineer III / SRE Liason, Ona.io Dec 2023 – Present
Key Achievements:
• Team Leadership: Lead backend microservices teams, and directed strategic roadmap
planning and sprint sessions to prioritize feature development and ensure timely delivery.
Security & Scalability: IntegratedOpenIDConnectwithKeycloakandenhancedproduct
•
reliability through proactive alerts using UptimeRobot, Prometheus, and OpsGenie.
• Project Leadership – TallyHo: As the technical lead for TallyHo, an open source Django
electiontallyingsystem, Icoordinatewithstakeholders—includingtheLibyanelectoralbody
and UNDP—to deliver resilient, scalable, and timely election results, including the recent
| December |     | 2024 Libyan | Elections. |     |     |     |     |     |     |
| -------- | --- | ----------- | ---------- | --- | --- | --- | --- | --- | --- |
Cross-Functional Collaboration: As an SRE liaison, I work closely with the SRE team
•
to optimize infrastructure and ensure high system uptime. I have migrated microservices
from EC2 to AWS EKS using Helm charts, GoCD and automated Docker image builds and
deployments to AWS ECR via GitHub Actions, which improved performance and reduced
costs. I also collaborate with the product and data engineering teams to drive continuous
| improvements |     | on our | BI  | platform | data | engineering | workflows. |     |     |
| ------------ | --- | ------ | --- | -------- | ---- | ----------- | ---------- | --- | --- |
Key Projects:
• Akuko: A BI platform for creating interactive maps, charts, and tables from diverse data
sources.
| • TallyHo: |     | An open-source |     | Django | election | tallying | system. |     |     |
| ---------- | --- | -------------- | --- | ------ | -------- | -------- | ------- | --- | --- |
Tech Stack:
• Backend: Microservices (Golang, Python, Node.js/Typescript), Django/Python
| • CI/CD: | GithubActions/AWS |     |     | ECR/GOCD |     |     |     |     |     |
| -------- | ----------------- | --- | --- | -------- | --- | --- | --- | --- | --- |
• Infrastructure: AWS EKS(K8’s), Helm Charts, Terraform, Ansible, Packer
| • Monitoring: |                       | Prometheus, |             | Grafana,  | UptimeRobot, |           | OpsGenie |       |     |
| ------------- | --------------------- | ----------- | ----------- | --------- | ------------ | --------- | -------- | ----- | --- |
| • Databases:  |                       | Clickhouse, | PostgreSQL, |           |              | DuckDB,   | Cube.js  |       |     |
| • Task        | Queues/Orchestrators: |             |             | Temporal, |              | RabbitMQ, | Celery,  | Redis |     |
1

Senior Software Engineer II / SRE Liason, Ona.io Nov 2022 – Dec 2023
Key Achievements:
• Research on Architecture Improvement: Improved asynchronous task management by
| introducing | Temporal |     | workflows |     | to replace | legacy | queuing | systems. |
| ----------- | -------- | --- | --------- | --- | ---------- | ------ | ------- | -------- |
• End to End Ownership: Built end-to-endfeatures by developing React-based clientinter-
faces and rolling out asynchronous backend tasks with Temporal workflows for long running
| tasks | such as | PMTiles | generation |     | for maps. |     |     |     |
| ----- | ------- | ------- | ---------- | --- | --------- | --- | --- | --- |
DeveloperExperience: RefactoredcoremicroservicesAPIsfromJavaScripttoTypeScript
•
to enhance maintainability and refactored IO bound services to Golang.
• Data Engineering Collaboration: Streamlineddataengineeringworkflowsbyintegrating
the Temporal orchestrator for automated data ingestion and implementing a Python-based
RESTAPIsemanticlayerwithCube.js, enablingrapidqueriesonDBT-powereddatamarts.
• Training and Mentorship: Conducted workshop training sessions on system functionality
and code walkthroughs for the TallyHo project in preparation for elections.
Key Projects:
Temporal orchestrator: A durable execution orchestrator simplifies building scalable dis-
•
| tributed | systems. |     |     |     |     |     |     |     |
| -------- | -------- | --- | --- | --- | --- | --- | --- | --- |
• Cube.js: An abstraction layer in modern data stack that sits between your data sources and
data consumers.
Tech Stack:
| • Frontend: | React/Typescript |     |     |     |     |     |     |     |
| ----------- | ---------------- | --- | --- | --- | --- | --- | --- | --- |
• Backend: Microservices (Golang, Python, Node.js/Typescript), Django/Python
| • Mordern | Data                  | Stack | Tools: | Cube.js,  | DBT |           |         |       |
| --------- | --------------------- | ----- | ------ | --------- | --- | --------- | ------- | ----- |
| • Task    | Queues/Orchestrators: |       |        | Temporal, |     | RabbitMQ, | Celery, | Redis |
Senior Software Engineer I / SRE Liaison, Ona.io Nov 2021 – Dec 2022
Key Achievements:
• Architecture Performance Improvement: Implemented compute and storage separa-
tion by deploying an internal ClickHouse database on Kubernetes to query Parquet files
stored in any object store such as AWS S3, thereby eliminating the need for AWS Glue and
| Athena | removing | vendor |     | lock-ins. |     |     |     |     |
| ------ | -------- | ------ | --- | --------- | --- | --- | --- | --- |
Product Stabilization and Reliability: Improved the performance and reliability of our
•
BI tool source creation workflows by implementing asynchronous CSV source creation using
| DuckDB, | which | significantly |     | boosted | query | performance. |     |     |
| ------- | ----- | ------------- | --- | ------- | ----- | ------------ | --- | --- |
Key Projects:
• Akuko: A BI platform for creating interactive maps, charts, and tables from diverse data
sources.
Tech Stack:
| • Backend: | Microservices |     | (Golang, |     | Python, | Node.js/Typescript) |     |     |
| ---------- | ------------- | --- | -------- | --- | ------- | ------------------- | --- | --- |
• Databases: Clickhouse, PostgreSQL, DuckDB, Cube.js, AWS Glue, AWS Athena
2

| Software | Engineer, |     | Ona.io |     |     |     |     |     | Dec 2017 | – Nov 2021 |
| -------- | --------- | --- | ------ | --- | --- | --- | --- | --- | -------- | ---------- |
Key Achievements:
• Revamped CI/CD pipelines with GitHub Actions, reducing deployment times by 50%.
• Led a client project integrating Onadata, Enketo, Apache Superset, and Box using a Re-
| act/TypeScript |     | frontend |     | and Django |     | REST | backend. |     |     |     |
| -------------- | --- | -------- | --- | ---------- | --- | ---- | -------- | --- | --- | --- |
• Established staging and production environments using Terraform, Ansible, and Packer.
Key Projects:
• GRP: Resilience Platform, an online space to capture, access, co-create and advance the
| latest     | resilience | knowledge. |        |            |      |     |          |             |     |     |
| ---------- | ---------- | ---------- | ------ | ---------- | ---- | --- | -------- | ----------- | --- | --- |
| • Ona:     | A web      | based      | data   | collection | app. |     |          |             |     |     |
| • Onadata: | An         | open       | source | Django     | REST | API | for data | collection. |     |     |
Tech Stack:
• Frontend: React, Typescript, Clojure, ClojureScript, Reagent, Om
| • Backend:        | Django                |            | Rest | API (Python) |     |          |        |     |     |     |
| ----------------- | --------------------- | ---------- | ---- | ------------ | --- | -------- | ------ | --- | --- | --- |
| • CI/CD:          | Github                | Actions    |      |              |     |          |        |     |     |     |
| • Infrastructure: |                       | AWS        | EC2, | Terraform,   |     | Ansible, | Packer |     |     |     |
| • Databases:      |                       | PostgreSQL |      |              |     |          |        |     |     |     |
| Task              | Queues/Orchestrators: |            |      | RabbitMQ,    |     | Celery,  | Redis  |     |     |     |
•
| Software | Engineer |     | Intern, | Ona.io |     |     |     |     | Sep 2017 | – Nov 2017 |
| -------- | -------- | --- | ------- | ------ | --- | --- | --- | --- | -------- | ---------- |
Key Achievements:
• Enhanced a ClojureScript-based frontend for a data collection tool by debugging and imple-
| menting | feature | improvements. |     |     |     |     |     |     |     |     |
| ------- | ------- | ------------- | --- | --- | --- | --- | --- | --- | --- | --- |
ASP.NET Developer (Contract), GrandLab Digital Fixers Apr 2016 – May 2017
• Developed a shopping website by building both frontend and backend components.
| IT Support | Intern, |     | Base | Titanium |     | Limited |     |     | Apr | 2014 – Aug 2014 |
| ---------- | ------- | --- | ---- | -------- | --- | ------- | --- | --- | --- | --------------- |
• Developed an internal web application using CodeIgniter to improve data management and
| reporting | workflows. |     |     |     |     |     |     |     |     |     |
| --------- | ---------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
Education
| • Bachelor | of         | Science |     | in Information |        | Technology |       |           |     | 2012 – 2016 |
| ---------- | ---------- | ------- | --- | -------------- | ------ | ---------- | ----- | --------- | --- | ----------- |
| Technical  | University |         | of  | Mombasa,       | Second | Class      | Upper | Division. |     |             |
• Master of Computational Intelligence - MCI, Artificial Intelligence 2020 – Present
| University | of  | Nairobi | (Coursework |     | completed; |     | project | pending). |     |     |
| ---------- | --- | ------- | ----------- | --- | ---------- | --- | ------- | --------- | --- | --- |
3

Faith Mutua
faithkanini18@gmail.com +254726133241 LinkedIn Github
| | |
Professional Summary
SeasonedQualityAssuranceEngineerwith7+yearsofexperienceindeliveringhigh-qualitysoftware. Proficient
invarioustestingmethodologies,includingmanual,automated,API,andperformancetesting. Demonstrated
successinleadingtestingefforts,mentoringjuniorteammembers,anddrivingprocessimprovementswithin
collaborative,fast-pacedenvironments. Provenexpertiseinanalyzingcomplexrequirements,designing
comprehensivetestplansandcases,andensuringsoftwarequalitywithintightdeadlines.
Skills
ProgrammingLanguages: Java,Python,ClojureScript,JavaScript
•
TestingFrameworks: Selenium,Espresso,Cypress,Appium,Cucumber,RestAssured
•
LoadTestingtools: JMeter,locust.io
•
ContinuousIntegration/ContinuousDelivery(CI/CD):Jenkins,GithubActions,Docker
•
SoftwareDevelopmentMethodologies: Agile(Kanban,Scrum),Waterfall
•
LogsandMetricsPlatforms: Sentry,Graylogs
•
ComputingPlatforms: AWS,Azure
DefectTrackingSystems: Github,Jira
•
Testcasemanagement: Testrail
•
Databases: PostgresandMySQL
•
Work Experience
SeniorSoftwareEngineerinTestI,OnaSystemsInc Jan2023–Present
LeveragedEspressotoautomatemobileapplicationtests,boostingregressionandend-to-endtesting
•
efficiencyby40%perreleasecycle.
ChampionedtheimplementationofShift-Lefttestingforona.iousingClojurescriptdecreasingdebuggingtime
•
by30%andensuringearlydefectdetectionandprevention.
ImprovedusabilityoftheResilientPlanetInitiativewebapplicationandchatbotby45%throughdirect
•
communityUserAcceptanceTesting,drivingkeyuserexperienceandfunctionalityenhancements.
Implementedateamupskillinginitiative,addressingidentifiedskillsgapsandleadingtoa50%improvement
•
intaskefficiencythroughcustomizedlearningpathsandafocusedcurriculum.
Mentored3juniorteammembersinbestpracticesforQualityEngineering,enhancingtheirskillswhile
•
boostingteamefficiencyby25%.
EmployedproactiveerrorloganalysiswithSentryduringtechnicalsupportforona.io,achievingan85%
•
reductioninclientcommunicationandsignificantlyboostingcustomersatisfactionscoresby75%.
SoftwareEngineerinTest,OnaSystemsInc Jan2020–Dec2022
DevelopedandmaintainedautomatedtestframeworksfordatabasetestinginKubernetes-basedCI/CD
•
environmentsusingJUnitandCucumber,achievinga60%reductioninmanualtestingeffortsandimproved
testcoverageby50%.
Conducted5+performancetestspermonthincludingstress,loadandvolumetesting,usingJMeterandlocust,
•
resultingina40%increaseinconcurrentusercapacityandenhancedsupportforpeaktraffic.
Performedthoroughmobileappperformancetesting,improvingapploadtimesby75%andidentifying10
•
criticalperformancebottlenecks,whilealsoconductingthoroughdevicecompatibilityandbugrootcause
analysisacross5deviceconfigurations.
Investigatedandreportedsoftwaredefectsusingdefecttrackingsystems(GithubandJira),ensuringaccurate
•
documentationandtimelyresolutionofissuescontributingtoa20%reductionincriticalbugs.

Ensuredsoftwarequalitybyproactivelyevaluatingsystemrequirementsanddesignspecifications,
•
identifyingpotentialrisks,andimplementingtargetedtestingstrategiestomitigatethem,preventingcostly
defectsandensuringproductstability.
QualityAssuranceEngineer,OnaSystemsInc Aug2017–Dec2019
Demonstratedexpertiseintestcasedesignbyconstructing500+comprehensivetestcasesforcomplex
•
softwarerequirements,resultingina25%increaseintestcoverageandacceleratedtestingcyclesforcritical
products.
ExecutedAPIautomationtestingusingRestAssured,Java,andCucumbertoensurerobustnessandreliability
•
ofbackendsystems,reducingmanualtestingtimeforAPIsby90%andincreasingtestcoverageby95%.
StreamlinedtheQualityEngineeringprocess,significantlyreducingcriticalbugsby80%,throughthorough
•
functionality,acceptance,regression,andcompatibilitytesting.
Activelyparticipatedinarchitectureanddesignreviewstopreventfaultydesigndecisionsbefore
•
implementation.
Ledprocessimprovementinitiativeswithincollaborativeteams,achievinga15%reductionintestingcycle
•
timesandfastersoftwaredeliverywithoutcompromisingquality.
Education
JomoKenyattaUniversityofAgricultureandTechnology, May2009–Dec2012
BScinMathematicsandComputerScience
Affiliations
MemberofMinistryofTestingCommunity
WomenTechmakersAmbassadorKenyanChapter

COITE MANUEL
Founder & Chief Executive Officer | Crosscut
Washington, DC | coite@crosscut.io | +1-703-727-8784 | crosscut.io
1. Executive Summary
Coite Manuel is the Founder and Chief Executive Officer of Crosscut, a certified Digital Public Good and DHIS2 Tier
2 Strategic Technology Partner that powers the WHO AFRO ESPEN Geospatial Microplanner and supports
geospatial campaign planning across 43 countries. He brings more than 20 years of experience spanning global
health supply chain strategy, digital health system design, interoperable platform development, and multi-country
implementation leadership — including five years as Senior Supply Chain Advisor in USAID's Global Health Office.
He brings direct operational experience integrating campaign data systems across NTD mass drug administration,
immunization, malaria IRS/ITN, and vitamin A supplementation programs, and has coordinated complex, multi-
country digital health initiatives with Ministries of Health, UNICEF, WHO/ESPEN, Gavi, and implementing partners.
Crosscut has led the development of open-source, DHIS2-compatible production integrations with ODK, CommCare,
and the WHO ESPEN Portal. The company holds formal DPG status and a signed DHIS2 Technology Partner
Agreement, directly supporting UNICEF's ICR objectives of interoperability, sustainability, and government
institutionalisation.
2. Core Technical Competencies
▪ Multi-country program management ▪ Campaign data integration & interoperability
▪ Geospatial microplanning & GIS analytics ▪ DHIS2 production integration (Tier 2 Partner)
▪ NTD MDA, immunization & malaria campaign systems ▪ ODK & CommCare data connectors (production)
▪ Digital Public Goods design & stewardship ▪ WHO ESPEN / JAP reporting workflows
▪ Stakeholder engagement: MoH, UN, Gavi, USAID ▪ Open-source platform architecture & licensing
▪ Capacity building & knowledge transfer ▪ Low-connectivity & offline-first deployment
3. Professional Experience
Crosscut | Founder & Chief Executive Officer | Washington, DC | Apr 2017 – Present
Founded and leads a digital health technology company specialising in geospatial campaign planning, population
estimation, and interoperable data integration for public health programs in low- and middle-income countries
(LMICs). Manages strategy, product direction, client delivery, and partner engagement across concurrent multi-
country programmes funded by UNICEF, WHO, Gavi, USAID/PMI, and the Gates Foundation.
• Directs a multidisciplinary team of engineers, data scientists, and global health professionals operating across
10+ Sub-Saharan African countries simultaneously, under a disciplined agile development model (quarterly
planning, two-week sprints, daily standups, formal code review).
• Leads all client-facing engagement with Ministries of Health, UN agencies, and international donors — serving
as principal contact for UNICEF HQ, WHO AFRO/ESPEN, Gavi, and USAID/PMI — coordinating technical
delivery across stakeholder groups in both English and French-speaking contexts.
• Oversees design and maintenance of open-source production integrations with DHIS2, ODK, CommCare, and
the WHO ESPEN Portal, enabling campaign data to flow from community-level collection tools into national
health management information systems.
• Positioned Crosscut as a DHIS2 Tier 2 Strategic Technology Partner (signed agreement with HISP Centre,
University of Oslo) and as a verified Digital Public Good (DPG ID: GID0090906, Digital Public Goods Alliance),
directly aligning with UNICEF's ICR interoperability and sustainability requirements.
• Secured recognition as 2023–2024 COR-NTD Innovator of the Year (Task Force for Global Health) and
selection as a Gavi 6.0 global geospatial partner (with VillageReach), underscoring domain credibility across
NTD and immunization programs.

U.S. Agency for International Development (USAID) | Senior Supply Chain Advisor, Global Health
Office | Washington, DC | Jan 2012 – Mar 2017
• Managed a broad portfolio of projects related to the strategy, policy, and operational improvement of USAID's
$1B per year global health pharmaceutical and medical supplies procurement and logistics programme spanning
multiple countries and health commodity areas.
• Provided senior technical guidance on supply chain design, analytics platforms, and operational strengthening in
collaboration with implementing partners, host-government Ministries of Health, and multilateral counterparts.
• Contributed subject-matter expertise at the intersection of supply chain management, health system
strengthening, and programme data use — experience directly applicable to embedding campaign data
workflows within national reporting cycles.
Independent Supply Chain Consultant | Washington, DC | May–Dec 2011
• Provided technical expertise and strategic advisement on the distribution of medical supplies in developing
countries for the World Bank and John Snow Inc. (JSI).
Accenture | Manager, Supply Chain Strategy Practice | Jan 2004 – Sep 2006 | Ranked Exceptional, Top 5%
• Led supply chain strategy engagements across the public and private sectors, achieving a top-5% internal
performance ranking. Selected project highlights:
• Department of Health and Human Services (HHS): Led study to determine optimal inventory storage and
distribution strategy; developed warehouse consolidation plan representing a 22% reduction in annual operating
expense.
• Office supply retailer: Performed inventory optimisation analysis reducing stock levels by more than 20% while
maintaining service levels.
• Fashion retailer: Led distribution capacity planning and analysis for domestic processing centres, modelling
processing capabilities against forecasted demand.
• Clothing retailer: Performed distribution network optimisation to support a doubling of store count over five years.
• Electronics retailer: Determined optimal product flow path from vendor to customer through mathematical
optimisation.
Accenture | Analyst, Supply Chain Strategy Practice | Jan 2001 – Sep 2001
• Contributed to supply chain strategy engagements as an analyst, building foundational expertise in supply chain
modelling, network design, and operational analytics.
4. Selected Project Experience (ICR-Relevant)
WHO AFRO ESPEN Geospatial Microplanner — Lead Developer & Maintainer
Partners WHO AFRO / ESPEN, Gates Foundation
Geography 43 Sub-Saharan African countries, all WHO AFRO member states
Relevance ICR Phase 5 directly requires two-way integration with this same tool
• Built and maintains the WHO ESPEN Geospatial Microplanner (espen.afro.who.int) — the primary sub-district
NTD MDA planning tool across 43 countries — as a white-label deployment of the Crosscut platform. This is the
exact tool the ICR must establish two-way integration with under Phase 5.
• Developed the ESPEN Schisto Mapper Tool (piloted Senegal) — translates schistosomiasis survey and
environmental data into actionable sub-district treatment maps within the ESPEN Portal.
• Participated in WHO workshop (Brazzaville, December 2025) with representatives from 13 countries to
demonstrate the Microplanner and gather country feedback, providing ground-level insight into NTD
microplanning workflow gaps across the region.
DHIS2 Microplanning App & Tier 2 Technology Partnership
Partners HISP Centre, University of Oslo; 30+ Ministry of Health DHIS2 administrators
Geography Multi-country; 30+ MoH users in Sub-Saharan Africa
Relevance ICR Phase 5 DHIS2 connector; ICR institutionalisation within national HMIS
• Holds a signed Technology Partner Agreement with the HISP Centre designating Crosscut as a DHIS2 Tier 2
Strategic Technology Partner (Digital Public Good) — covering API-level integration, joint reference
architectures, coordinated country deployments, and joint donor/government engagement.

• Built and maintains a dedicated DHIS2 Microplanning app on the DHIS2 App Hub enabling national
administrators to create sub-district catchment areas directly within DHIS2 without GIS expertise; DHIS2 v41
(May 2024) ships with native support for Crosscut catchment visualisation.
• Trained 50+ Ministry of Health staff across multiple countries at the 2023 DHIS2 Academy to independently
generate catchment areas and microplans within their national DHIS2 instances.
NTD Mass Drug Administration Campaign Systems — Multi-Country
Partners Sightsavers, The Carter Center, WHO ESPEN, Task Force for Global Health
Geography Nigeria, Liberia, Guinea-Bissau, Haiti, plus 2026 expansion to 8 additional countries
Relevance ICR core use case: NTD MDA campaign data integration, coverage tracking, JAP reporting
• Nigeria (Sightsavers / Kogi State MoH): Led schistosomiasis MDA microplanning across Lokoja, Kogi, and Ibaji
LGAs, targeting 152,724 children aged 5–14. Delivered accessibility analysis, supervisory area delineation, and
a CommCare integration for real-time supervision monitoring.
• Liberia (Sightsavers / MoH): Piloted ESPEN Geospatial Microplanner across three counties (Maryland, Grand
Cape Mount, Montserrado), building catchment-based microplans for NTD MDA campaigns from geocoded
facility data.
• Haiti (The Carter Center / MoH): Supported lymphatic filariasis MDA campaigns; Crosscut population estimates
directly informed a shift from fixed-point to door-to-door drug distribution, demonstrating data-to-decision impact
on campaign design.
• Nigeria (The Carter Center): Production ODK integration for MDA supervision — field supervisors log visits via
ODK; Crosscut ingests and maps data geographically, enabling program managers to track field team coverage
in real time.
• Liberia, Guinea-Bissau, Nigeria (Sightsavers): Production CommCare integration for MDA supervision
monitoring — field supervisors log via CommCare; Crosscut surfaces supervision coverage alongside catchment
boundaries.
Immunization Campaign Microplanning & Supply Chain Analytics
Partners UNICEF, Gavi, VillageReach
Geography The Gambia, Ethiopia; Gavi global partner framework (20+ countries)
Relevance ICR immunization campaign data flows, Gavi/COVAX reporting, SIA microplanning
• The Gambia (UNICEF / MoH EPI): Supported digitised electronic microplanning for immunization campaigns,
helping government make evidence-based platform decisions. Platform supports SIA planning, vaccination post
identification, session planning, and population-benchmarked coverage estimation.
• Ethiopia (UNICEF, Gavi): Selected as a Gavi global partner in supply chain analytics (2022, prequalified
Ethiopia). Integrated with UNICEF's Stock Management Tool (SMT), in active use in 20+ countries, enabling
batch-level vaccine visibility from health facility to central medical store — supporting expiry prevention and
stockout detection.
• Selected as Gavi 6.0 Technical Assistance global partner in geospatial microplanning (with prime partner
VillageReach, 2024–2025).
Malaria IRS & ITN Campaign Planning — USAID/PMI Evolve
Partners Abt Associates (prime), USAID/PMI
Geography 21-country programme; design sessions in Uganda and Ghana in Year 1
Relevance Campaign planning for large-scale public health interventions; IRS/ITN data flows
• Selected as resource partner on USAID's PMI Evolve Project (Abt Associates prime), a five-year IRS program
spanning 21 countries. Conducted design sessions and user testing in Uganda and Ghana for IRS supply
estimation and ITN distribution planning.
• Developed ML-based building classification (>85% accuracy, identifying spray-eligible structures) generating
printable PDF operational maps for IRS campaigns — demonstrating AI-assisted campaign data use in LMIC
field contexts.
5. Digital Public Goods & Open Source Contributions
• Verified Digital Public Good — Crosscut is registered with the Digital Public Goods Alliance (DPG ID:
GID0090906; registry: digitalpublicgoods.net/r/crosscut). All 11 DPG Standard indicators met, including open
licensing (CC0 1.0), platform independence, technical documentation, non-PII data extraction pathways, privacy

compliance (GDPR), and protection from harassment. Output datasets also published on the Humanitarian Data
Exchange (HDX).
• DHIS2 App Hub — Maintains the dhis2-crosscut-app (github.com/crosscutio), enabling national DHIS2
administrators to import Crosscut catchment areas directly into their DHIS2 instances. More than 30 Ministry of
Health users have incorporated Crosscut data into DHIS2 instances across Sub-Saharan Africa.
• Field-Kit (released March 2026) — Open-source geospatial data preparation toolkit published under Apache 2.0
license, available on GitHub.
• 6 additional public repositories on GitHub (github.com/crosscutio) covering platform integrations and data
pipelines.
• Organisational users of Crosscut's open datasets include the Ministry of Health EPI programme in The Gambia,
the World Health Organization, and 30+ MoH users who have incorporated the data into DHIS2 and other
national health information systems.
6. Country & Stakeholder Engagement
Ministries of Health — Direct Engagement (10+ Countries)
Country MoH Counterpart Programme Area
Nigeria Kogi State Ministry of Health Schistosomiasis MDA microplanning
Ethiopia Ministry of Health (via UNICEF) Immunization supply chain design
Uganda Ministry of Health (via PMI Evolve) Malaria IRS planning
Ghana Ministry of Health (direct + PMI Evolve) Malaria IRS; CHPS zone mapping
Liberia Ministry of Health ESPEN Microplanner pilot; NTD MDA
Guinea-Bissau Ministry of Health App training, deployment, MDA support
Burundi Ministry of Health Onchocerciasis endemicity mapping
The Gambia Ministry of Health, EPI Supply chain design; microplanning
Haiti Ministry of Health (via Carter Center) Lymphatic filariasis MDA
DRC Ministry of Health (via Unlimit Health) Schistosomiasis boundary delineation
UN Agencies, Donors & Multilateral Partners
• UNICEF — Active engagement at HQ and Country Office levels on digital health, geospatial microplanning,
immunization supply chain, and NTD integration programmes.
• WHO / ESPEN — Lead developer and partner for the ESPEN Geospatial Microplanner (43 countries);
participant in WHO technical workshops on NTD microplanning.
• Gavi — Prequalified global partner in supply chain analytics (2022) and geospatial microplanning (6.0
framework, 2024–2025) in collaboration with VillageReach.
• USAID / PMI — Resource partner on PMI Evolve Project (Abt Associates prime), a five-year IRS programme
across 21 countries.
• Gates Foundation — Grand Challenge grant recipient (selected from 1,100+ applications, 2020); ongoing
technical collaboration on NTD microplanning.
• Task Force for Global Health — COR-NTD Innovator of the Year (2023–2024); technical partner for NTD
campaign planning.
7. Education & Professional Recognition
M.S., Industrial Engineering | Georgia Institute of Technology | 2000
B.S., Applied Mathematics & Mathematical Economics | Hampden-Sydney College | 1999
Selected Recognition
2025 Gavi 6.0 global geospatial microplanning partner (with VillageReach)

2024 Certified Digital Public Good — Digital Public Goods Alliance (DPG ID: GID0090906)
2024 Selected as 1 of 10 technology companies to present at Alliance for Malaria Prevention annual meeting
2023 COR-NTD Innovator of the Year — Task Force for Global Health (retained 2023–2024)
2022 DHIS2 App of the Year finalist — DHIS2 Annual Conference
2022 Gavi global partner in supply chain analytics (prequalified Ethiopia)
2020 Gates Foundation Grand Challenge grant — selected from 1,100+ applications

JAMES McKINNON, M.A.
Supply Chain Data Analyst & Geospatial Health Specialist | Crosscut
St Paul's Bay, Malta | james@crosscut.io | +1 260-433-6426
1. Executive Summary
Global health supply chain analyst and geospatial data specialist with 10+ years of experience delivering analytics
and field operations across 10+ countries in Sub-Saharan Africa, South Asia, and beyond. At Crosscut, James leads
data-intensive analytical work including GIS-based operational map production for health campaigns, raster analysis,
and network modelling for vaccine supply chains. He has led UNICEF-funded supply chain assessments in Ethiopia
and The Gambia — including personal geocoding of The Gambia's entire national vaccination network — managed
emergency health campaign logistics for Médecins Sans Frontières in South Sudan (including a measles vaccination
cold chain strategy), and coordinated supply chain data across 38 countries as part of the USAID Global Health
Fellows Program.
2. Core Technical Competencies
▪ Supply chain analytics & quantitative modelling ▪ GIS / geospatial analysis (QGIS, ArcMap, Python)
▪ Immunization supply chain assessment ▪ Raster & network analysis for health campaigns
▪ UNICEF programme support (field & HQ) ▪ Dashboard development (Tableau, Power BI,
MicroStrategy)
▪ Field data collection & logistics management ▪ Mixed-methods research design & implementation
▪ Multi-country data coordination (38 countries) ▪ Emergency health campaign logistics
3. Professional Experience
Crosscut | Supply Chain Data Analyst | The Gambia; Senegal; Ethiopia | 2018–Present (intermittent)
• Conducts advanced GIS data analysis including aggregation of raster-based datasets summarising
environmental suitability scores for disease-causing parasites, network analyses assessing optimal vaccine
supply chain design, and automated production of operational maps supporting health campaigns — using
Python (geopandas, rasterio, osgeo) and QGIS.
• Led data collection and analysis for a UNICEF-funded assessment of the Ethiopian government's public health
supply chain, using a mixed-methods approach combining quantitative supply chain modelling with site visits to
all government medical stores (assessing accessibility, warehouse design, and inventory management policies).
• Personally geocoded all sites within The Gambia's public vaccination network: visited each facility to collect GPS
coordinates, photographs, and cold chain equipment inventories within a tightly managed schedule.
• Collected and analysed data for a UNICEF-funded country-wide immunization supply chain assessment in The
Gambia, incorporating quantitative supply chain modelling and qualitative inputs from UNICEF and Ministry of
Health personnel, including scenario analysis of alternative network designs.
Médecins Sans Frontières (MSF) | Project Supply Chain Manager | Upper Nile State, South Sudan | Jan–Oct
2022
• Served as Head of Supply for the Maban project (outpatient clinic and 7 outreach sites), managing a team of 6
staff with responsibility for procurement, inventory management, forecasting, and cargo flight coordination.
• Developed and executed a cold chain strategy for an emergency measles vaccination campaign in a remote
area more than half a day from any active cold chain equipment — using passive cold chain devices for the full
6-day campaign duration, with detailed ice pack management and replenishment planning.
• Coordinated delivery and storage of 90+ tonnes of non-food item material for a flood emergency distribution,
requiring cargo flight coordination with the MSF Juba office and synchronisation with field distribution teams.
HOPE Foundation for Women and Children of Bangladesh | Program Manager | Cox's Bazar, Bangladesh
| Mar–Sep 2019

• Led programme design and management of the Emergency Response Team project, keeping mobile medical
teams on standby for Rohingya refugee and host Bangladeshi communities during Cyclone Fani and subsequent
monsoon flooding.
• Represented HOPE at the UN-coordinated Logistics Sector and Health Sector Emergency Preparedness
Working Group, coordinating with UN agencies and partner organisations.
USAID Global Health Fellows Program II | Supply Chain Data Analyst | Washington, DC | Mar 2015–Dec 2017
• Coordinated collection of supply chain data for health commodities across 38 countries under the SCMS and
DELIVER projects, enabling visibility into in-country supply chains and building a model for future implementing
partner data submissions.
• Served as primary point of contact for supply chain technical assistance and pharmaceutical shipments to Benin
and Mali, including stock monitoring, importation support, and USAID budget cycle coordination.
• Developed MicroStrategy dashboards consolidating logistics data from multiple sources to support the
Commodities Security and Logistics Division; contributed to M&E procedures for USAID Global Health Supply
Chain awards.
JVA Consulting LLC | Research & Evaluation Assistant | Denver, CO | Nov 2013–Feb 2015
• Managed 3 projects from start to completion as Project Lead, including a county-wide service provider
assessment. Developed Social Network Analysis, Excel-based dashboards, and trained staff on data analytics
and M&E practices.
4. Selected Project Experience (ICR-Relevant)
UNICEF Ethiopia Public Health Supply Chain Assessment
Partners UNICEF, Ethiopian Federal Ministry of Health
Scope Site visits to all government medical stores; national supply chain assessment
Methods Mixed methods: quantitative supply chain modelling + qualitative field assessment
Relevance ICR Phases 3 & 4: MoH data flows, national reporting integration, country engagement
• Applied mixed-methods approach combining quantitative supply chain modelling with direct site visits to all
government medical stores — generating facility-level data on accessibility, warehouse design, inventory
management, and cold chain performance directly analogous to the ICR's Location and Campaign Metadata
data model elements.
UNICEF Gambia Immunization Supply Chain Assessment & Vaccination Network Geocoding
Partners UNICEF, Gambia Ministry of Health EPI Programme
Scope Full national vaccination network; country-wide supply chain assessment
Methods Personal site visits; GPS coordinates; cold chain inventory; quantitative + qualitative analysis
Relevance ICR data model: Location resource, GPS facility data, immunization supply chain reporting
• Personally visited every site in The Gambia's national vaccination network to collect GPS coordinates,
photographs, and cold chain equipment inventories — producing a geocoded facility dataset directly analogous
to the ICR Location resource requirements for health facility catchment area and service delivery point data.
• Conducted a country-wide immunization supply chain assessment incorporating UNICEF and MoH inputs,
quantitative modelling, and scenario analysis of alternative network designs, informing national EPI programme
planning.
Emergency Measles Vaccination Campaign — Cold Chain Strategy (MSF, South Sudan)
Partners Médecins Sans Frontières, Upper Nile State health authorities
Scope 6-day vaccination campaign, remote area; passive cold chain management throughout
Relevance ICR campaign execution understanding: Services Received, cold chain metadata, campaign
logistics
• Designed and executed a cold chain strategy enabling a measles vaccination campaign in a setting without
active cold chain access, managing passive cold chain devices and ice pack replenishment for 6 days —
providing hands-on operational understanding of the campaign execution data flows the ICR is designed to
capture and standardise.

5. Open Source & Data Contributions
• Produced automated operational maps for public health campaigns distributed to implementing partners and
health authorities across Sub-Saharan Africa through Crosscut's platform.
• Contributed to supply chain data infrastructure under USAID's SCMS and DELIVER projects, supporting data
visibility and reporting standardisation for 38 countries.
6. Country & Stakeholder Engagement
Countries with Direct Programme Engagement
Country Organisation / Context Programme Area
The Gambia UNICEF / Ministry of Health EPI Immunization supply chain; vaccination network
geocoding
Ethiopia UNICEF / Federal Ministry of Health Public health supply chain assessment
South Sudan Médecins Sans Frontières Measles vaccination campaign; emergency logistics
Bangladesh HOPE Foundation / UN Agencies Emergency health response; cyclone preparedness
Benin & Mali USAID / SCMS / DELIVER Supply chain technical assistance; stock monitoring
Additional country experience (data analysis, site-based work): Ghana, Tanzania, Senegal (Crosscut platform
analytics); India (evaluation internship, Odisha); Russia (academic abroad).
Key Partner Engagements
• UNICEF — direct project delivery in Ethiopia and The Gambia on supply chain assessments.
• Médecins Sans Frontières — project supply chain management and emergency vaccination campaign, South
Sudan.
• USAID / Global Health Fellows Program II — 38-country supply chain data coordination; primary liaison for
Benin and Mali.
• UN Logistics Sector & Health Sector Emergency Preparedness Working Group — represented HOPE
Foundation, Bangladesh.
7. Education & Technical Skills
M.A., International Development | Josef Korbel School of International Studies, University of Denver | 2014
• Relevant coursework: Information Management in Humanitarian Crises; Field Operations for Humanitarian
Assistance; Mobile Technology for International Development; Introduction to Epidemiology; Time Series
Analysis; Econometrics for Decision Making.
B.A., Mathematics and Philosophy | Wabash College | 2007 | Summa cum laude, Phi Beta Kappa
Languages: English (native speaker)
Technical tools: Python (geopandas, rasterio, osgeo), R, Stata, SQL, QGIS, ArcMap, Tableau, Power BI, MicroStrategy,
Excel

CLARA R. BURGERT, PhD, MPH
Infectious Disease Epidemiologist & Geospatial Health Specialist | Crosscut
Silver Spring, MD | crburgert@gmail.com | +1 202-203-8236 | English & French (fluent)
1. Executive Summary
PhD-trained infectious disease epidemiologist with 20+ years of experience applying advanced quantitative and
spatial methods to neglected tropical disease programs, immunization campaigns, malaria surveillance, and public
health intervention evaluation across 20+ countries. Clara currently leads multi-country evaluations of geospatial
microplanning for community drug distribution programs and serves as project lead for Francophone country
activities, managing stakeholder engagement with Ministries of Health and implementing partners in French. She
brings 100+ multi-country epidemiological studies, 30+ peer-reviewed publications, and direct technical engagement
with WHO, Gavi, USAID, and Ministries of Health to the ICR assignment. Fluent in English and French, she is
positioned to lead all French-language country engagement and capacity-building activities required by the ToR.
2. Core Technical Competencies
▪ NTD programme epidemiology (20+ countries) ▪ French-language MoH & partner engagement (fluent)
▪ Geospatial & geostatistical modelling (R) ▪ Model-based geostatistical models (MBG)
▪ Infectious disease surveillance & evaluation ▪ WHO & Ministry of Health technical engagement
▪ Data pipelines, QA & reproducible workflows ▪ Capacity building (10+ regional trainings)
▪ Study design, protocols & statistical analysis ▪ Evidence-to-policy translation for WHO/Gavi/USAID
3. Professional Experience
Epidemiology Consultant (Self-employed) | Remote | Oct 2025–Present
• Leads executive-level, multi-country evaluations of geospatial microplanning initiatives for community drug
distribution programs; designs evaluation frameworks, data collection tools, and integrates quantitative and
qualitative data to assess implementation effectiveness, coverage implications, and scalability.
• Serves as project lead for Francophone country activities, managing timelines, deliverables, and stakeholder
engagement with Ministries of Health and implementing partners in French.
• Supports digital health tool adoption through stakeholder interviews, usability assessments, and training
development; translates user feedback into actionable recommendations.
RTI International | Epidemiologist, Manager | Washington DC / Remote | Oct 2017–May 2025
• Designed, implemented, and analysed infectious disease surveillance and epidemiologic evaluation studies
across 20+ countries, supporting neglected tropical disease programmes in collaboration with Ministries of
Health, WHO, and implementing partners.
• Served as technical and project lead for 100+ multi-country studies: authored study protocols, statistical analysis
plans, and data collection tools; coordinated multidisciplinary teams and managed timelines, deliverables, and
partner communications.
• Led advanced statistical, spatial, and model-based geostatistical analyses in R to assess infectious disease risk
and evaluate public health intervention performance; developed, calibrated, and validated MBG models against
observed epidemiological data, informing national surveillance strategies and WHO policy guidance.
• Developed and maintained reproducible data pipelines and quality assurance scripts in R supporting data
cleaning, integrity monitoring, and analysis across large multi-country datasets.
• Produced technical reports, policy briefs, and analytical summaries for donors, Ministries of Health, and global
health partners; supported 20+ conference presentations and 30+ peer-reviewed publications.
• Supervised 3 staff; provided technical training in applied epidemiology, surveillance analytics, and data
visualisation.

ICF International | Technical Specialist | Rockville, MD | Jan 2011–Oct 2017
• Contributed to applied epidemiology, surveillance, and evaluation activities across HIV, malaria, vaccine-
preventable diseases, and MCH programmes under USAID-funded initiatives including the Demographic and
Health Surveys (DHS) Programme and MEASURE Evaluation.
• Conducted statistical and spatial analyses assessing disease burden, surveillance performance, and programme
outcomes; produced evidence-based recommendations for WHO, Gavi, and USAID stakeholders.
• Collaborated with Ministries of Health, academic partners, and multidisciplinary teams across multiple countries
to translate epidemiological findings into programme planning and policy decisions.
• Facilitated 10+ regional trainings in epidemiology, GIS, and data visualisation, strengthening analytical capacity
among Ministry of Health and partner staff.
• Managed technical deliverables, timelines, and budgets for large, multi-year USAID-funded programmes;
supervised 3 staff; served as primary technical contact for partner and donor engagements.
Blue Raster | Research Analyst | Calverton, MD | 2009–2010
• Conducted spatial and epidemiologic analyses for malaria surveillance and prevalence under USAID-funded
programmes.
• Managed field data collection in Haiti with UNICEF, supporting emergency response surveillance.
Catholic Relief Services (CRS) | International Development Fellow | Dakar, Senegal | 2008–2009
• Designed and implemented a community-based health survey covering HIV, malaria, and nutrition in
collaboration with the Senegal Ministry of Health; supported indicator-based surveillance, analysis, and reporting
for donors and national stakeholders.
Centers for Disease Control (CDC) | Research Assistant | Atlanta, GA & Kisumu, Kenya | 2007–2008
• Supported infectious disease surveillance studies through data analysis, reporting, and interpretation in Atlanta
and in the field in Kisumu, Kenya.
4. Selected Project Experience (ICR-Relevant)
Geospatial Microplanning Evaluation — Community Drug Distribution Programs (Multi-Country)
Partners Ministries of Health; implementing partners (current engagement)
Scope Multi-country evaluation: geospatial microplanning for NTD community drug distribution
Language Francophone country activities led entirely in French
Relevance ICR Phase 3: capacity building, Francophone country engagement, implementation evaluation
• Leads executive-level evaluations of geospatial microplanning for NTD community drug distribution programs —
directly relevant to the ICR's requirement for evaluating and institutionalising campaign data workflows in pilot
countries.
• Serves as Francophone country project lead — managing MoH and implementing partner engagement in French
— meeting the ToR's explicit requirement for French-language capacity-building workshop leadership.
NTD Programme Surveillance & Epidemiological Studies — RTI International, 20+ Countries
Partners WHO, Ministries of Health, USAID, implementing partners
Scale 100+ multi-country studies; 20+ countries; 30+ peer-reviewed publications
Methods Advanced statistical, spatial, and geostatistical modelling in R; MBG model development
Relevance ICR NTD domain expertise; campaign coverage evaluation; data standards and quality assurance
• Led 100+ multi-country NTD epidemiological studies across lymphatic filariasis, schistosomiasis, trachoma,
onchocerciasis, and soil-transmitted helminths — providing deep understanding of the NTD disease landscape,
treatment protocols, and data standards the ICR must accommodate and standardise.
• Developed, calibrated, and validated model-based geostatistical models against population-level epidemiological
data across 30+ countries, informing national surveillance strategies and WHO policy guidance — directly
relevant to the ICR's analytics layer and data quality objectives.
PhD Research: Trachoma Geostatistical Modelling — London School of Hygiene & Tropical Medicine
Degree PhD, Infectious and Tropical Diseases Epidemiology (awarded Sept 2025)
Thesis Exploratory geospatial analysis and modelling to support trachoma elimination and surveillance

Scope Model-based geostatistical models across 30+ trachoma-endemic countries
Relevance ICR: geospatial NTD disease modelling; evidence-to-WHO-policy translation
• Developed and calibrated model-based geostatistical models to population-level trachoma prevalence data
across 30+ endemic countries — the same geostatistical modelling approach the ICR analytics layer will use to
translate campaign coverage data into actionable microplanning intelligence for Ministries of Health.
DHS Programme & MEASURE Evaluation — ICF International, USAID (Multi-Country)
Partners USAID, Ministries of Health, WHO, Gavi
Scope Multi-country HIV, malaria, VPD, MCH surveillance; 10+ regional trainings delivered
Relevance ICR: health information systems, national data flows, capacity building, MoH engagement
• Contributed to the DHS Programme and MEASURE Evaluation — building a multi-decade understanding of
national health information systems, data flows, and reporting standards that underpin ICR design requirements.
• Facilitated 10+ regional trainings in epidemiology, GIS, and data visualisation for Ministry of Health and partner
staff across multiple countries — directly applicable to the ICR Phase 3 capacity-building mandate.
5. Selected Peer-Reviewed Publications
• Harte A, Sasanami M, Burgert-Brucker CR, et al. (2025). Using Model-Based Geostatistics to Refine Population-
Based Estimates of Trachoma Prevalence. American Journal of Tropical Medicine and Hygiene.
• Sasanami M, Burgert-Brucker CR, et al. (2025). Understanding the impact of covariates for trachoma prevalence
prediction using geostatistical methods. BMC Global and Public Health.
• Burgert-Brucker CR, Adams MW, Solomon AW, Harding-Esch EM. (2022). Community-level trachoma
ecological associations and geospatial analysis: A systematic review. PLoS NTD.
• Burgert-Brucker CR, et al. (2020). Risk factors associated with failing pre-transmission assessment surveys in
lymphatic filariasis elimination programs. PLoS NTD.
• Burgert CR, Bradley SEK, Arnold F, Eckert E. (2014). Improving estimates of insecticide-treated mosquito net
coverage using geographic coordinates. Malaria Journal.
Full list (30+ publications): orcid.org/0000-0002-6001-4960
6. Country & Stakeholder Engagement
Select Countries with Direct Programme Engagement
Country Organisation / Context Programme Area
Senegal Catholic Relief Services / Ministry of Community health survey; HIV, malaria, nutrition
Health
Haiti Blue Raster / UNICEF Emergency response surveillance; field data
collection
Kenya Centers for Disease Control (CDC) Infectious disease surveillance, Kisumu
20+ LMICs RTI / ICF / USAID NTD surveillance, malaria, DHS, MEASURE
Evaluation
Key Institutional Partnerships
• WHO — Direct technical engagement on NTD surveillance and policy guidance through RTI International;
trachoma PhD research informing WHO elimination targets.
• UNICEF — Field data collection in Haiti for emergency response surveillance (Blue Raster); ongoing Crosscut
engagement.
• Gavi — Evidence production for vaccine-preventable disease programme planning (ICF / USAID collaboration).
• USAID — Technical lead on DHS Programme and MEASURE Evaluation; 10+ year partnership across multiple
country programmes.
• Ministries of Health — Direct engagement in 20+ countries across NTD, immunization, malaria, and MCH
programmes; Francophone country lead for current microplanning evaluations.
7. Education

PhD, Infectious and Tropical Diseases Epidemiology | London School of Hygiene & Tropical Medicine |
2025
• Thesis: 'Exploratory geospatial analysis and modelling to support trachoma elimination and surveillance.'
Developed and calibrated MBG models across 30+ endemic countries.
M.P.H., Global Epidemiology | Rollins School of Public Health, Emory University | 2008
B.S., International Relations (Minor: Biology) | St. Catherine University | 2003
Languages: English (fluent) | French (fluent)
Technical Skills: R, Stata, ArcGIS, QGIS, ODK, MS Excel, Git; statistical and geostatistical modelling; data pipeline
development; protocol and SAP design

SAMUEL HOOGEWIND, B.S.
Software Engineer | Crosscut
Washington, DC | samuel.hoogewind@gmail.com | (616) 406-9208
1. Executive Summary
Software engineer with expertise in cloud-based geospatial data pipelines, population modelling algorithms, and
frontend visualisation for global health applications. At Crosscut, Sam engineers scalable AWS data pipelines
supporting real-time geospatial data access for public health planning across 45+ African countries, maintaining 99%
+ system uptime. He designed the foundational population raster algorithm now serving as the core data layer for
downstream infrastructure analytics across the platform, and builds QGIS plugins to automate internal geospatial
workflows. His work directly supports the data infrastructure that feeds into campaign microplanning and the
analytics layer the ICR will integrate with.
2. Core Technical Competencies
▪ AWS data pipeline engineering (Python, R) ▪ Geospatial data processing (45+ African countries)
▪ Population raster algorithm design ▪ React / JavaScript frontend development
▪ QGIS plugin development (Python automation) ▪ ECS / Docker cloud infrastructure
▪ High-availability backend systems (99%+ uptime) ▪ Data integrity across multi-region datasets
3. Professional Experience
Crosscut | Software Engineer | Washington, DC | June 2025–Present
• Engineers scalable data pipelines on AWS using Python and R to process and manage geospatial datasets for
45+ African countries, supporting real-time data access for hundreds of users.
• Designed a foundational population raster algorithm, migrating legacy hexagonal models to a high-performance
grid-based architecture that now serves as the core population data layer for downstream infrastructure analytics
across the platform.
• Maintains and updates the multi-component React/JavaScript frontend, optimising the visualisation of large-
scale geographic datasets and improving interface responsiveness for complex user queries.
• Builds custom Python plugins for QGIS to automate internal geospatial workflows, reducing manual data
processing time and increasing delivery speed.
• Optimises backend data structures for high-intensity geographic processing, maintaining 99%+ system uptime
and ensuring data integrity across disparate regional datasets.
Salesforce Analyst, Calvin University | Remote | Dec 2024–Jun 2025
• Automated data extraction and integration for 15,000+ alumni records using Apex and Python; built custom
Apsona reports and scripts reducing manual research time by 200%.
Development and Advancement Intern, Calvin University | Grand Rapids, MI | May 2023–Jun 2024
• Engineered data structures for a 10,000-record database migration; designed custom object mappings
correlating zip codes with urban areas, providing first-ever geospatial engagement metrics for university
leadership.
4. Selected Project Experience (ICR-Relevant)
Population Raster Algorithm — Core Data Layer for 45+ Country Platform
Scale 45+ African countries; hundreds of active platform users
Stack Python, R, AWS; grid-based raster processing architecture
Relevance ICR analytics layer: population data infrastructure, data normalisation for warehouse integration

• Designed and implemented the foundational population raster algorithm migrating legacy hexagonal models to a
high-performance grid-based architecture — the data layer underpinning all downstream analytics across
Crosscut's platform, directly feeding into the same infrastructure the ICR will leverage for population-
denominated campaign coverage analysis.
Geospatial Data Pipelines — 45+ African Country Coverage
Scale 45+ Sub-Saharan African countries
Infrastructure AWS ECS, Python, R, Docker; 99%+ uptime SLA
Relevance ICR Phase 5: analytics add-on, FHIR data warehouse synchronisation, structured data accessibility
• Engineers and maintains AWS data pipelines processing geospatial datasets across 45+ African countries with
99%+ uptime, directly relevant to the ICR's requirement for reliable, automated synchronisation of structured
campaign data to a data warehouse for external analytical use.
5. Technical Tools & Open Source
• Contributes to open-source repositories at github.com/crosscutio, including geospatial data pipeline and platform
tooling supporting Crosscut's Digital Public Good.
• QGIS plugin development (Python) for geospatial workflow automation.
6. Technical Expertise
Languages
• Python, R, JavaScript, HTML/CSS, SQL, Rust
Infrastructure & Frameworks
• AWS (ECS, S3, and related services), React, Git, Docker, QGIS
7. Education
B.S., Computer Science | Calvin University | May 2024 | Magna Cum Laude (GPA: 3.80)

Appendix 2 – UNICEF Information Security and Platform & Infrastructure Requirements
NOTE: Architecture Summary: All ICR data is stored in the Google Cloud Healthcare API (managed FHIR server). Cinder (web client) and OpenFn (integration
middleware) are hosted on GCP VMs. Keycloak provides identity and access management for in-country solutions. For in-country deployments, Ona will follow
best practices within the constraints of national data center infrastructure.
Table A – Security Requirements
Compli
Requirement ed?(Ye Proposer’s Response / Reference
s/No)
General Security Requirements
Assessment of, or validation of connectivity controls between UNICEF and any third party / service provider are required before any physical or logical connection can be
made.
Internally hosted systems that connect and access a Cloud system will use UNICEF standard network deployment topology for the following system components:
• For frontend systems
• In between systems / containers
• Databases
End point security controls will be implemented similar if not the same to the ones listed for the top 20 CIS controls. These controls shall be kept functional and updated
considering the following domains:
• Virus protection
• Data exfiltration
• Unauthorized access to and/or changing of critical system(s)/application files
• Zero-day vulnerabilities
Vendor agrees to the rights of UNICEF to assess the Ona agrees. The ICR is developed as open-source software (GitHub), and UNICEF is
quality and accurateness of outsourced software welcome to conduct security assurance testing, code audits, or engage third-party assessors
development and operational maintenance of the system at any time. Ona will provide full cooperation, access to repositories, and documentation to
/ application; whether it be through security assurance support any such assessment.
testing or through external security assessment.
Ona will coordinate with UNICEF ICTD to validate all connectivity controls prior to
Yes establishing any connection. The ICR’s data layer is the Google Cloud Healthcare API, a fully
managed, HIPAA- and HITRUST-certified service. All connectivity to the Healthcare API is
governed by Google’s IAM policies and VPC Service Controls. During pilot (cloud-hosted),
Ona will complete a formal connectivity review with UNICEF during Phase 2 deployment. For
subsequent in-country deployments, connectivity validation will be conducted in coordination
with each country’s Ministry of Health and UNICEF Country Office, in accordance with
national data center and infrastructure requirements.

The ICR architecture consists of three components, each with a clear security boundary:
• Data store (Google Cloud Healthcare API): All patient, campaign, and health data is stored
exclusively in the Healthcare API’s managed FHIR server. Ona does not operate or manage
the underlying database infrastructure — Google handles all storage, replication, and network
security for this tier. The Healthcare API is SOC 1/2/3, ISO 27001, HIPAA, and HITRUST
certified.
• Integration layer (OpenFn): Campaign data from DHIS2, ODK, and other sources is
transformed and loaded into the Healthcare API via OpenFn, either using OpenFn’s hosted
(SaaS) platform or a dedicated GCP VM. OpenFn connects to the Healthcare API via
authenticated HTTPS only.
• Client application (Cinder): Cinder is a client-side application hosted on a GCP VM that
provides the user interface for the ICR. Cinder stores no data; it reads from and writes to the
Healthcare API via authenticated API calls.
Ona will align the deployment topology with UNICEF’s standard network architecture. For
in-country deployments, Ona will endeavor to follow these standards while working within the
constraints of national data center infrastructure.
Solution / Service shall be protected from unwanted network The ICR is protected by multiple layers of network filtering:
traffic by network filtering or separating measures that lay • Google Cloud Healthcare API: Protected by Google’s global edge network, DDoS mitigation,
outside of the system such as, externally controlled routers and API-level access controls. Only authenticated, authorized requests reach the FHIR data
and firewalls. store.
Yes • Cinder and OpenFn VMs: Protected by GCP VPC firewall rules restricting ingress to only
required ports (443/HTTPS) and source ranges. VMs have no public-facing services beyond
the application endpoints.
• Cloud Armor WAF can be configured in front of the Cinder web application for additional
Layer 7 protection if required.
The system shall have proper end-point protection with the • Malicious code protection: VM instances run hardened OS images with automated security
following minimum requirements: patching. Google’s Security Command Center provides threat detection across the GCP
• Malicious code protection measures project.
• Host firewall configured utilizing, at a minimum, least Yes • Host firewall: GCP VPC firewall rules enforce least-privilege network access for each VM.
privileged access controls (services, user, communication Only the specific ports and protocols required for each component are permitted. Cinder and
access) OpenFn VMs communicate only with the Healthcare API and Keycloak — no other outbound
connections are allowed.
Validation of Security Controls
Impartial security and vulnerability assessment testing shall be performed to determine the effectiveness of security controls for:
• Frontend systems
• In between systems / containers
• Databases
Independent penetration testing agent or teams will perform penetration testing on information systems prior to production release.

Vendor agrees to the rights of UNICEF to periodically Ona agrees to UNICEF’s right to periodically validate all security requirements through any of
validate the implementation of the security requirements the listed methods. Ona will cooperate fully with UNICEF-initiated or UNICEF-contracted
outlined in this document via: assessments. The ICR source code is open-source and continuously available for inspection
• Security Assurance Testing on GitHub.
• Vulnerability Testing
Yes
• Penetration Testing
• Audits
• On-site checks
Compliance & Certifications (OPTIONAL)
Vendor shall carry ISO2700K certification and/or SOC-2 Ona does not currently hold ISO 27001 or SOC-2 certification at the organizational level.
audits as mandatory or other international standards. The However, the ICR’s data layer — the Google Cloud Healthcare API — is certified under ISO
Vendor shall provide information about the certification 27001, SOC 1/2/3, HIPAA, and HITRUST CSF. Since all data is stored and managed within
and/or the SOC-2 report and audit findings or equivalent the Healthcare API (not on Ona-managed infrastructure), the most critical security controls
certifications and/or reports. are inherited from Google’s certified platform. Ona’s internal development and operational
practices are aligned with ISO 27001 controls. For in country implementations, Ona will work
Yes
with MoH counterparts to ensure we align with their security and compliance standards as
applicable.
[GCP Healthcare API compliance:
https://cloud.google.com/healthcare-api/docs/concepts/compliance]
Identification, Authentication and Authorization
These new groups/roles created must follow the principle of The ICR implements role-based access control (RBAC) via Keycloak. All roles are defined
least privilege requiring that these groups/roles be given the following the principle of least privilege. The Google Cloud Healthcare API enforces additional
minimum privileges necessary for their job function.
Yes
access controls at the FHIR resource level, ensuring each authenticated user or service
account can only access the specific data types and operations permitted by their role.
By default, all information systems will rely on existing Keycloak supports federation and identity brokering. Ona will configure Keycloak to integrate
organization wide security groups and roles that exist on with UNICEF’s Identity Access Management system (e.g., via SAML 2.0 or OpenID Connect)
UNICEF’s Identity Access Management Services. In cases so that existing UNICEF security groups can be mapped to ICR application roles. Where
where applications/services permission cannot be matched ICR-specific roles are needed (e.g., Campaign Manager, Data Analyst, System
to existing groups/roles, a request for new application Administrator), Ona will submit role definitions to UNICEF ICTD for approval before creation.
specific groups/roles creation must be submitted for:
Yes
For in-country deployments, roles will also accommodate MoH and partner staff as defined in
• Frontend systems coordination with UNICEF Country Offices.
• External partner / other systems / accounts
• In between systems / containers (including Staging area)
• For privileged accounts accessing the backend systems
such as the databases

All UNICEF staff accounts shall be created on an automated Since this is a facing solution this is not applicable.
fashion, based on the connection between the IAM System.
Yes
The service provider shall follow the principle of least Each user and service account in the ICR will be uniquely identified. Application-level RBAC
privilege, guaranteeing that users, group, role, and device (Keycloak) maps to FHIR resource-level access controls enforced by the Google Cloud
identifiers will be unique, assigned to each entity (user or Healthcare API. Service accounts used by OpenFn and Cinder have scoped IAM permissions
Yes
process). Each application user role shall have a limited to the specific Healthcare API operations they require. No shared or generic accounts
correspondent database connection according to its are used.
privileges.
The service provider shall centrally manage the user account Since this is a facing solution this is not applicable.
using federated identities and whenever possible integrate
their solution with the UNICEF Identity Management System.
Yes
In case authentication is password based; the password
shall forcefully adhere to the common best practice quality
requirements and will be forcefully renewed frequently.
Multi-factor authentication will be used for: Keycloak supports multi-factor authentication (MFA) including TOTP (e.g., Google
• Privileged accounts and Yes Authenticator) and WebAuthn. MFA will be enforced for:
• User access outside of UNICEF trusted network • All administrative and privileged accounts (system admins, GCP project owners).
All the user and system accounts shall be disabled after a Keycloak supports session timeout and account inactivity policies. Accounts inactive beyond
defined period of inactivity, in accordance with organizational a configurable threshold will be automatically disabled. All default credentials are changed
standards. All default accounts and/or passwords shall be Yes during initial deployment. Account lifecycle management (creation, modification, deletion)
removed or changed. Approvals will be required for creation, follows an approval workflow documented in the ICR operations manual.
deletion, or modification of any account.
Account lockout features will be used for invalid Keycloak’s brute-force detection can be enabled, providing automatic temporary account
authentication attempts. Yes lockout after a configurable number of failed login attempts. Lockout duration increases
progressively. Administrators are notified of repeated failed authentication events.
Application code shall never contain any credentials. No credentials, API keys, or secrets are stored in application source code. All secrets are
managed via Google Cloud Secret Manager and injected at runtime. GCP service account
Yes keys for Healthcare API access use workload identity or short-lived tokens rather than stored
key files. The CI/CD pipeline includes automated secret scanning (e.g., git-secrets) to prevent
accidental credential commits.
Availability and Deletion
The system will have a HIGH Level of Availability. Availability The ICR’s availability is anchored by the Google Cloud Healthcare API, which provides a
requirements and recovery mechanisms shall comply with 99.95% uptime SLA with built-in replication, automatic failover, and managed backups:
UNICEF BCM requirements covering critical business • Data store (Healthcare API): Fully managed by Google with multi-zone redundancy. No
processes for: Yes single point of failure. Google handles all backup, replication, and disaster recovery for the
• Frontend systems FHIR data store.
• In between systems / containers • Cinder VM: Can be redeployed rapidly from infrastructure-as-code. Since Cinder stores no
• Databases data, recovery is straightforward — provision a new VM and redeploy.

• OpenFn: If using OpenFn’s hosted SaaS, availability is governed by OpenFn’s SLA. If
self-hosted on a GCP VM, the same rapid redeployment applies.
RPO and RTO will be aligned with UNICEF BCM requirements during the deployment
planning phase. For in-country deployments tied to national data centers, Ona will work with
UNICEF Country Offices to achieve the best feasible availability within local infrastructure
constraints.
For the deletion of data, a process is required for deletion of The Google Cloud Healthcare API supports both logical deletion (soft delete with audit trail)
any information system data. and permanent deletion of FHIR resources. Deletion requests are handled through authorized
Yes API calls with appropriate access controls. Since Cinder stores no data and OpenFn
processes data in transit only, deletion is managed centrally at the Healthcare API layer. All
deletion actions are logged.
Any deletion of confidential / personal data must be done so When permanent deletion of personal data is required, Ona will perform hard deletion via the
that it cannot be reconstructed. Healthcare API’s FHIR delete operations, which purge data from the underlying storage.
Google’s storage systems perform cryptographic erasure, ensuring deleted data is
Yes
irrecoverable. Deletion procedures will align with UNICEF’s data retention and disposal
policies.
[Reference: https://cloud.google.com/security/deletion]
Cryptography
Strong cryptographic algorithms shall be used for encrypting data at rest with a minimum standard of AES 256, or in accordance with existing industry best practice or
published UNICEF standard, whichever is more restrictive.
Data on the following systems must follow the above minimum standards while in transit and at rest for:
• Frontend systems
• In between systems / containers
• Databases
The organization will escrow encryption keys to maintain the availability of information in the event of loss of encryption keys. Where applicable, key management
guidelines from a trusted Cloud service provider will be followed.
The service provider shall use best practice or industry All data exchange uses current, industry-standard protocols:
standard secure data exchange protocols and keep them up • HTTPS with TLS 1.2+ for all API communications (Healthcare API FHIR endpoints,
to date. Outdated and/or compromised protocols shall never Keycloak OIDC, DHIS2 integration, OpenFn data flows).
be used. Yes • The Healthcare API enforces TLS and rejects connections using deprecated protocols.
• Deprecated protocols (SSLv3, TLS 1.0/1.1, RC4, 3DES) are not supported.
Protocol configurations are reviewed and updated as part of regular security maintenance.
All passwords shall be encrypted with best current practices Passwords stored in Keycloak are hashed using PBKDF2-SHA256 with a high iteration count
or strong industry standards cryptographic algorithms and and unique per-user salt. Passwords are never stored in plaintext or reversible encryption.
secure keys.
Yes
Service account credentials for the Healthcare API use Google-managed keys or short-lived
OAuth 2.0 tokens rather than static passwords.
Key files must be protected from unauthorized modification All infrastructure configuration is managed as code (e.g., Terraform) stored in
using an application that enforces automatic reconciliation Yes version-controlled Git repositories. Changes require peer-reviewed pull requests and are
from an authoritative source. deployed via CI/CD pipeline. Any drift from the declared configuration is detected and

reconciled. Secrets are sourced from Cloud Secret Manager; Healthcare API encryption keys
are managed by Google Cloud KMS.
Encryption keys shall be securely stored outside of the Healthcare API encryption keys are managed by Google Cloud KMS, which stores key
systems on which they are used. material in FIPS 140-2 Level 3 validated hardware security modules (HSMs), physically and
Yes
logically separated from the systems that use them. Application-level secrets are stored in
Cloud Secret Manager, separate from the VMs that consume them.
Secure Development (if applicable)
The system shall be developed following the ‘data protection The ICR is a reference FHIR implementation and will use Google’s Healthcare API as the
by design and by default’ principle. data store — it provides built-in HIPAA compliance, audit logging, and fine-grained access
Yes
controls by design. Data minimization, purpose limitation, and role-based access controls are
embedded in the platform architecture.
A documented policy and/or process that indicates the use Ona follows a secure SDLC that includes: threat modeling during design, secure coding
of a known secure development methodology throughout the guidelines, mandatory code review for all changes, static analysis (SAST) and dependency
entire life cycle of the software (SDLC). Yes scanning in CI/CD, dynamic application security testing (DAST) before production releases,
and security-focused QA testing. The project will maintain public contribution guidelines and
code review standards on GitHub.
The security assurance code must be done using the Security testing follows OWASP Testing Guide methodology. The CI/CD pipeline includes
international and best practices in security, such as OWASP, Yes automated SAST and DAST scans. UNICEF’s InfoSec team will be notified before and after
PCI, others. QA security assurance testing is performed on each release.
The system shall be engineered following the ‘security by Security by design is a core principle of the ICR architecture. Defense in depth is
design’ principles. implemented across layers: authentication (Keycloak + MFA), authorization (Healthcare API
Yes FHIR access controls + Keycloak RBAC), encryption (TLS + AES-256 via Google), network
segmentation (VPC firewall rules), and audit logging (Healthcare API audit logs + Cloud Audit
Logs).
Development and tests of the system will be done with All development, staging, and test environments use synthetic or pseudonymized data. No
fictitious or pseudonymized information. real patient or beneficiary data is used outside of production environments. Test data
Yes
generation follows FHIR Synthea-based approaches to create realistic but entirely fictitious
campaign data.
Access to program source code and associated items shall Source code is hosted on GitHub with branch protection rules requiring: pull request approval
be strictly controlled; to prevent the introduction of from at least one authorized reviewer before merge, passing CI checks (tests, linting, security
unauthorized functionality. Yes scans), and signed commits where possible. Direct pushes to main/production branches are
prohibited. Access to repositories is governed by team-based permissions with regular
access reviews.
The system shall display generic error messages that do not Cinder and the ICR API layer are configured to return generic, user-friendly error messages in
disclose detailed information such as process logs, account production. Detailed error information (stack traces, system paths) is logged server-side only
or system information.
Yes
via Cloud Logging and never exposed to end users. The Healthcare API itself returns
standardized FHIR OperationOutcome responses without internal system details.

Executable code will not be implemented on an operational All code deployments to production follow a gated CI/CD pipeline that requires: passing unit
system until evidence of conforming to the testing criteria is and integration tests, passing security scans (SAST/DAST), QA sign-off or User Acceptance
Yes
acquired and the associated program source libraries have Testing (UAT) approval, and successful deployment to a staging environment. No code
been updated. reaches production without passing all gates.
Security Operations
Based on UNICEF’s security program requirements, all Ona will align the ICR’s security operations with UNICEF ICTD and SOC procedures. The
systems shall follow ICTD and the SOC procedures and Healthcare API’s infrastructure security is managed by Google’s dedicated security
provisions to maintain a secured network of interconnected operations team with 24/7 monitoring. For the application layer (Cinder, OpenFn, Keycloak),
devices internally and externally for: Yes Ona’s operations team will follow documented incident response and escalation procedures
• Frontend systems coordinated with UNICEF’s SOC.
• In between systems / containers
• Databases
UNICEF / third party hosted solutions shall incorporate The ICR incorporates controls at every layer: network security (VPC firewalls), application
appropriate controls to meet this requirement. security (Keycloak authentication and authorization), data security (Healthcare API encryption
Yes
and access controls), and monitoring (Cloud Audit Logs, Security Command Center).
Controls are documented and available for UNICEF review.
The system shall be hardened, which means that: • Minimal services: VMs run only the required application processes. Only port 443/HTTPS is
• Only the services and network ports necessary for efficient exposed externally. The Healthcare API is a fully managed service with no user-configurable
operation are up and running attack surface.
• All application code is patched and kept up to date
Yes
• Patching: VMs use GCP’s OS patch management for automated security updates.
• Limiting the accounts and removing, changing, or disabling Application dependencies are updated via dependency scanning on a regular cycle. Critical
default accounts and passwords patches are applied within 48 hours.
• Accounts: All default accounts and passwords are removed or changed during initial
provisioning. GCP service accounts follow least-privilege IAM scoping.
Servers and applications shall be configured to run with the VM instances run application processes under dedicated non-root service users. GCP IAM
minimum system authorizations necessary. service accounts are scoped to the minimum required permissions (e.g., Cinder’s service
Yes
account can read/write FHIR resources but cannot modify IAM policies or access other GCP
services). The Healthcare API enforces resource-level access controls.
The production environment shall be separated from the test Production, staging, and development environments are hosted in separate GCP projects
and development environments; preferably on logically and with distinct VPCs, service accounts, and access controls. Each environment has its own
physically different systems.
Yes
Healthcare API dataset, Keycloak realm, and VM instances. There is no network connectivity
between production and non-production environments.
Development and test environment shall have the same All environments are deployed using the same infrastructure-as-code templates and
patch level as the production environment. Yes application images, ensuring identical patch levels. Staging is updated before production,
serving as a validation gate.
The production environment shall not have any development Production VMs do not include compilers, debuggers, package managers, or development
tools.
Yes
tools. Only the application runtime and its dependencies are present.

Configuration/Application source code / customized work Source code is stored in GitHub with branch protection and access controls. Infrastructure
shall be protected from unauthorized access / modification configuration is managed via version-controlled code with full audit history. Production data is
Yes
and reside in non-production environment with proper backed up via Healthcare API’s managed backup capabilities. All configuration changes are
back-up / resiliency policy. tracked.
The system shall have malicious code protection measures. GCP’s Security Command Center provides threat detection and vulnerability scanning across
Logs generated by malicious code protection measures shall the project. VM instances use automated OS security updates. The Healthcare API’s
be monitored. Yes managed infrastructure includes Google’s proprietary malware and intrusion detection. All
security events and alerts are logged in Cloud Logging and monitored by Ona’s operations
team.
Vulnerability Management
Assessment of, or validation of connectivity controls between UNICEF and any third party / service provider are required before any physical or logical connection can be
made for:
• Frontend systems
• In between systems / containers
Patch management of vulnerable system shall be consistent with UNICEF ICTD patch management process.
The service provider is required to report on the results of Ona will provide regular vulnerability scan reports to UNICEF’s designated focal point where
the security scans and the remediations taken. Any applicable. Critical and high-severity vulnerabilities will be reported immediately upon
Yes
vulnerability identified that affects the scope shall be discovery along with a remediation plan and timeline. A summary of all scan results and
reported to the UNICEF focal point. remediations will be included in quarterly status reports.
The service provider is required to run security tests. Tests Security testing will be conducted:
will run prior to the launch of the system and periodically • Prior to initial production launch (penetration test + vulnerability assessment).
afterwards; with a minimum frequency of once a year. • Before each major release.
Yes • At minimum annually via an independent third-party penetration test.
• Continuously via automated SAST/DAST in the CI/CD pipeline.
The Healthcare API’s infrastructure is continuously tested by Google as part of their security
program.
The service provider is required to report on the results of All security scan and penetration test reports, including findings, severity ratings, and
the security scans and the remediations taken. These remediation actions taken, will be sent to UNICEF’s Chief of IT Security or designated focal
reports will be sent to UNICEF’s Chief of IT Security or the
Yes
point(s) within 5 business days of report completion.
relevant focal point(s).
Critical security patches shall be applied following Critical patches are fast-tracked through an expedited change management process: patch is
established testing / change management processes. tested in staging, validated, and deployed to production within 48 hours. All critical patch
Yes
deployments are documented with pre/post validation results and communicated to UNICEF.
Healthcare API patches are handled automatically by Google.
Change Management
Changes to the system and/or application post-baseline will be documented (i.e. ver. / build number, etc.), along with description via a formal UNICEF change
management process for:
• Frontend systems

• In between systems / containers
• Databases
Any changes to UNICEF system(s) or software shall be This will not be UNICEF systems in country systems so not applicable.
agreed upon between ICT and the business division / office
owner of the affected system and third party. All changes are tracked via GitHub (version-controlled commits, tagged releases with
semantic versioning) and a project management tool. Each release includes a changelog
documenting changes, version number, and deployment date. Ona will follow UNICEF’s
formal change management process for production deployments.
Yes
Changes to system and/or application post baseline will be Each deployment includes documentation of: change type (feature, bugfix, patch,
documented (version / build number), along with description configuration), version/build number, reason for change, test results (pre and post
via a formal change management process. The service deployment), and rollback status if applicable. Failed patches are logged with root cause
provider shall report: type, version, reason, post test results
Yes
analysis and re-test plans. Change logs are available to UNICEF upon request.
after implementation. Patches that fail testing will also be
recorded and documented.
The updating of the operational software, applications and Production deployments are executed only by authorized Ona DevOps engineers via the
program libraries will only be performed by trained and CI/CD pipeline. Manual access to production VMs and GCP resources requires MFA and is
Yes
qualified administrators upon appropriate management restricted to a small group of trained administrators. All production actions are logged via
authorization. Cloud Audit Logs.
Log Management and Monitoring
Logs/events will be generated in a format that can be easily parsed and used as an input for logging process management for:
• Frontend systems
• In between systems / containers
• Databases
Event filtering will be enabled on logs for analysis to fine tune the results and consolidate logs into single entry containing count of number of occurrences of events to
save space.
Analysis will be performed on communication patterns to generate profiles for information systems for detecting unusual activities in the network.
The system shall generate and process auditing tracks The Google Cloud Healthcare API maintains a complete audit trail of all FHIR resource
covering all actions taken on personal data, including data operations (create, read, update, delete) with user attribution, timestamp, and resource
access only. Yes identifiers via Cloud Audit Logs (Data Access logs). This covers all actions on personal data
including read-only access. Keycloak logs all authentication and authorization events.
Together these provide a comprehensive audit trail.

Authentication validation activities and all changes in Keycloak logs all authentication events (successful logins, failed attempts, token issuance)
authorization shall be logged and securely stored, with and authorization changes (role assignments, permission modifications). Logs are stored in
limited access.
Yes
Cloud Logging with access restricted to authorized administrators only. Log data cannot be
modified or deleted by application users.
Access to content, key information and/or any modifications Access to production configuration, encryption keys (Cloud KMS), and GCP resources is
to operational program libraries shall be logged and Yes logged via Cloud Audit Logs (Admin Activity and Data Access logs). Access is restricted to
restricted. authorized personnel via IAM policies with MFA enforcement.
Logs and events will be generated in a format that can be All logs are emitted in structured JSON format, compatible with standard log management
easily parsed and used as an input for logging process Yes and SIEM tools. Logs can be exported via Cloud Logging sinks to BigQuery, Pub/Sub, or
management. Cloud Storage for integration with UNICEF’s logging infrastructure if required.
Integrity log checking shall be performed to ensure Cloud Logging provides tamper-evident log storage. Cloud Audit Logs are immutable and
consistency. Yes managed by Google. Critical audit logs can also be exported to locked Cloud Storage buckets
with retention policies to prevent tampering.
The system, application, as well as underlying services Comprehensive monitoring is implemented via Google Cloud Monitoring covering:
and/or networks, shall be monitored and activities logged. • Infrastructure: VM health, CPU, memory, disk, network metrics.
• Application: Cinder and Keycloak health, API response times, error rates.
Yes
• Healthcare API: FHIR operation latency, error rates, quota usage.
• Security: Failed auth attempts, firewall denials, anomalous traffic.
Alerts are configured for critical thresholds with notification to the Ona operations team.
Security Incident Management
Reporting of security incidents shall be in coordination with the SOC whether internally or externally.
A security breach shall be viewed as:
• A failure in security controls which leads to the accidental, unlawful, or unauthorized access, destruction, loss or alteration of data/information processed/stored on the
system
• A failure in security controls which leads to the accidental, unlawful, or unauthorized access to ICT resources
Security breaches shall immediately be communicated Ona commits to immediately notifying UNICEF’s designated Point of Contact upon
to UNICEF’s Point of Contact. confirmation of any security breach. Initial notification will include: nature of the breach,
Yes
systems/data affected, containment actions taken, and estimated timeline for full assessment.
Follow-up reports will be provided as the investigation progresses.
A security incident notification and escalation procedure Ona will work with UNICEF to develop and formally document a security incident notification
shall be formally documented and contractually and escalation procedure prior to production deployment. This procedure will define severity
enforced between the service provider and UNICEF’s
Yes
levels, notification timelines, escalation paths, communication channels, and responsibilities.
Security Operations Centre.

Table B – Platform and Infrastructure Requirements
Compli
Requirement ed?(Ye Proposer’s Response / Reference
s/No)
The Vendor shall integrate their solution with the established The ICR uses Keycloak as its identity provider, which natively supports SSO via SAML 2.0
authentication and identity framework; implementation / Yes and OpenID Connect.
adoption of Single Sign-On when available.
Documented firewall considerations and required Firewall configurations are managed as code and include:
configurations. • GCP VPC firewall rules (ingress/egress restrictions by port, protocol, and source range for
Cinder and OpenFn VMs).
• Cloud Armor WAF policies can be configured for additional Layer 7 protection.
Yes
• Healthcare API access is controlled via IAM and OAuth 2.0 scopes, not network firewalls —
only authenticated, authorized requests are processed.
Documentation of all firewall rules and their rationale will be provided to UNICEF as part of
the deployment package.
Vendor to provide a clear, publicly stated stance on privacy Ona maintains a public privacy policy (available at ona.io). Ona commits to processing data
protection and data use, re: Privacy Policy. under this engagement solely for the purposes defined in the contract with UNICEF. No data
Yes
processed through the ICR will be used for any other purpose, including Ona’s own analytics,
marketing, or product development.
Documented high-availability and disaster recovery The ICR’s HA/DR capabilities are anchored by the Google Cloud Healthcare API:
capabilities and procedures. • Healthcare API: Fully managed with multi-zone redundancy, automatic failover, and 99.95%
uptime SLA. Google handles all backup and disaster recovery for the FHIR data store.
Yes • Cinder / OpenFn VMs: Stateless (no data stored); can be redeployed from
infrastructure-as-code within minutes. VM snapshots provide additional recovery options.
• Documented DR runbook covering component failure scenarios will be provided.
For in-country deployments, HA/DR will be adapted to available local infrastructure.
Adherence to GDPR or DoD 5220.22-M or NIST SP 800-88 GCP handles physical storage device retirement and sanitization in compliance with NIST SP
for data sanitization on retirement of storage devices. 800-88 guidelines. Google’s data destruction process uses cryptographic erasure and
Yes physical destruction of storage media. Since all ICR data resides in the Healthcare API (no
local data on VMs), data sanitization is fully covered by Google’s processes.
[Reference: https://cloud.google.com/security/deletion]
Publish/provide locations of data centers storing data. For cloud-hosted piloting, the ICR will be hosted in a GCP region selected in consultation with
UNICEF, considering data sovereignty requirements of the pilot countries. Initial candidate
regions include europe-west1 (Belgium) or a region closer to the pilot countries. Specific data
Yes center locations will be documented and confirmed with UNICEF prior to deployment.
For in-country deployments, data center locations will be determined by national infrastructure
and data sovereignty requirements, in coordination with UNICEF Country Offices and
Ministries of Health.

Documentation of data retention procedures and backup Data retention and backup procedures:
facilities. • Healthcare API FHIR data store: Automated backups managed by Google with configurable
retention.
• Application logs: Retained in Cloud Logging per UNICEF’s requirements (configurable).
Yes
• Audit logs: Retained for the duration of the engagement plus a post-contract retention period
agreed with UNICEF.
• Backup storage is encrypted (AES-256) by Google.
Full data retention SOP will be provided.
Business Continuity Plan including backup and restore Ona will develop and maintain a Business Continuity Plan (BCP) for the ICR covering: backup
procedures. and restore procedures (tested periodically), failover processes, communication plans during
Yes
outages, and recovery priorities aligned with UNICEF’s BCM requirements. The BCP will be
reviewed and updated annually or after any significant incident.
Describe in detail all the annual support and maintenance Ona’s annual support and maintenance includes:
schemes that they provide. • Technical support via email and ticketing system during business hours (with critical issue
escalation 24/7).
Yes
• Regular software updates (security patches, bug fixes, feature enhancements).
• Periodic system health reviews and performance optimization.
Detailed support SOP will be included in the deployment documentation.
Clearly define the procedure to handle escalation issues, Escalation procedure:
bugs, and service packs. 1. Issues reported via ticketing system with severity classification.
2. Triage by Ona support team within SLA response time.
3. Escalation path: Support Engineer → Senior Engineer → Technical Lead → CTO.
Yes
4. UNICEF focal point notified of critical/high severity issues within 4 hours.
5. Hotfixes follow expedited change management with staging validation before production
deployment.
6. Post-incident reports provided for all critical issues.

Table C – Privacy and Data Protection Requirements
Compli
Requirement ed?(Ye Proposer’s Response / Reference
s/No)
Privacy Governance and Management
Proposer has implemented a comprehensive privacy Ona’s privacy program is informed by:
program to comply with applicable data protection laws, • GDPR: As a company working with international organizations and processing data of
regulations and international best practices of personal data individuals globally, Ona’s data handling practices align with GDPR principles (lawful basis,
protection, including a personal data breach procedure. data minimization, purpose limitation, data subject rights).
• UN Privacy Principles: Given Ona’s extensive work with UN agencies (UNICEF, WFP), our
Kindly identify which framework was used: Yes practices are aligned with the UN Personal Data Protection and Privacy Principles.
• GDPR Ona follows a data breach response procedure that includes detection, assessment,
• Generally Accepted Privacy Principles (GAPP)
notification (to data controllers and relevant authorities), containment, and remediation.
• HIPAA
• UN Privacy Principles
• Other (please clearly identify)
Proposer oversees and enforces compliance with the privacy Privacy compliance is overseen by Ona’s management team with support from legal counsel.
programme. Key activities include:
• Privacy impact assessments for new projects involving personal data.
Kindly describe how such activities are carried out and Yes • Annual review of data handling practices and privacy policies.
specify the frequency and audit activities performed. • Staff training on data protection during onboarding and annually thereafter.
• Code review processes that include privacy-relevant checks (data minimization, access
controls, logging of personal data access).
Proposer agrees not to use any data (even if anonymized) Ona agrees. All data processed through the ICR will be used exclusively for the purposes
processed for any other purpose than for the purposes of the defined in the UNICEF contract. Ona will not use any ICR data — including anonymized or
Proposal (e.g., AI/machine learning, deriving other data, etc.)
Yes
aggregated data — for its own research, product development, AI/ML training, marketing, or
any purpose outside the scope of this engagement.
The solution complies with best industry standards of The ICR is designed with privacy by design and default:
“privacy by design and default”. • Data minimization: Only data necessary for campaign operations is collected.
• Centralized data store: All personal data resides in the Google Cloud Healthcare API, which
provides built-in HIPAA compliance and fine-grained access controls. Cinder (client) and
OpenFn (integration) store no personal data.
Yes
• Access controls: RBAC via Keycloak ensures users only access data relevant to their role.
• Pseudonymization: The FHIR data model supports patient identifiers separate from personal
details.
• Encryption: All data encrypted in transit (TLS) and at rest (AES-256) by Google.
• Audit trail: All access to personal data is logged via Healthcare API audit logs.

Describe the implementation of an easily visible and The ICR will implement consent management aligned with the specific requirements of each
understandable appropriate “opt-out” mechanism when pilot country’s data protection regulations. The FHIR data model includes a Consent resource
collecting consent. that can record and enforce consent status per individual. Where applicable, the data
Yes
collection interface (e.g., OpenSRP mobile app, ODK forms) will include clear, user-friendly
consent screens in local languages with an opt-out option. Consent status is stored as a FHIR
Consent resource in the Healthcare API and enforced at the data access layer.