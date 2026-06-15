# Geo-enabled Microplanning (WHO GIS Centre / ESPEN / AMP) vs ICR FHIR IG — Alignment & Gap Analysis

*Sources: the ESPEN Microplanner one-pager (ESPEN / WHO AFRO NTD programme), the WHO GIS Centre for Health "Geo-enabled Digital Microplanning" deck (AMP / WHO-UNICEF COVAX GIS Working Group), the WHO-UNICEF COVAX GIS Working Group "Geo-enabled Microplanning Handbook" landing page, the GRID3 settlement-mapping / DRC immunisation-microplanning materials, and the AMP Nigeria (Kano/Osun/Kwara/Adamawa) ITN geospatial-microplanning case study. Compared against ICR FHIR R4 IG v0.1.0 (reviewer's explainer v0.8.0, with v0.7.0 additions folded in). This analysis centres on the **ICRLocation / geography / denominator layer** — administrative boundaries, catchment polygons, settlements/structures, sites, and gridded-population denominators.*

---

## 1. Executive summary

The "geo-enabled microplanning" direction described by these sources — build a **geographic foundation** of administrative boundaries, draw **catchment-area polygons** around distribution/vaccination points, register georeferenced **settlements and structures**, and **intersect gridded population (WorldPop, GRID3)** with those polygons to produce **denominators** — maps remarkably well onto the ICR IG's geography model. The IG's central design bet, that **operational geography overlays the administrative hierarchy rather than pretending to be it**, is directly and repeatedly validated by every source: ESPEN models sub-IU **supervisory areas** as a distinct layer over implementation units (ESPEN one-pager, p.1); the AMP deck maps **supervisor and team boundaries** that are digitized and aligned to remove gaps/overlaps independent of admin units (AMP deck, p.18); the GRID3-DRC work states outright that **health-area boundaries used for vaccination planning differ from standard administrative divisions** ([grid3.org/news/georeferenced-microplanning-for-immunisation-in-drc](https://grid3.org/news/georeferenced-microplanning-for-immunisation-in-drc)); and the classic polio lesson — polio operational boundaries differing from RI catchments — is the named justification for the IG's `operational-area` code. This is the single strongest cross-source validation of the IG's geography model.

The biggest **gaps** are not in the operational-vs-admin mechanism (which is well-built) but in the **catchment-polygon → denominator pipeline** and in **who/what executes** the geography. First, the IG carries denominator *sources* (`worldpop`, `grid3`) and a geography characteristic that joins an estimate to a Location, but it does **not** model the **method** by which a gridded raster is intersected with a catchment polygon to produce that estimate, nor the **version/date of the raster** consumed — the provenance the sources treat as load-bearing. Second, while the IG **does** now carry a `location-boundary-geojson` extension (a real, if recently-added, answer to the "GeoJSON-on-R4" open question — see §3b/§6), it is marked experimental and is not yet wired into the denominator workflow as the geometry that the population intersection runs against. Third, there is **no Team / microplan-resource profile**: every source spends as much time on **supervisor/team area demarcation and workload** as on population, and the IG has nowhere to put a team, its roster, or its assigned operational area. Fourth, **georeferenced structure/building footprints** (GRID3/Maxar/Ecopia) — the substrate from which settlement extents and household counts are derived — have no `structure`/`building` location type.

Highest-value additions, in order: (1) a **population-estimation-method** element plus the **source-raster version/date** on ICRTargetPopulation, so a catchment denominator is reproducible and auditable; (2) promote/confirm the **catchment-polygon geometry** mechanism (the existing `location-boundary-geojson` extension) from experimental to a first-class, documented part of the operational-geography pattern; (3) a **Team / CareTeam** (+ assigned operational area) concept; (4) a `structure`/`building` location type and a coded **geometry-representation** axis (point / polygon / none).

The IG's geography model is, net, **adequate and unusually well-aligned** for geo-enabled microplanning at the identity/boundary layer. Where it is thin is the **computational** layer — turning a polygon plus a raster into a defensible, provenance-bearing denominator — and the **operational-resource** layer (teams). Neither is fatal; both are additive.

---

## 2. Where the document ALIGNS with the IG

- **Operational-vs-administrative geography (the headline validation).** Every source builds an operational layer *over* admin units. ESPEN delineates **sub-IU Supervisory Area (SA) boundaries**, "modeled sub-IU supervisory area boundaries; manually edit them as needed," retained "to support future MDAs" (ESPEN one-pager, p.1). The AMP deck's Mogadishu exercise has the explicit objective "to spatially map the operation boundaries of DFAs and later team areas" and to "rationalize and validate the workload of team areas" (AMP deck, p.9–10); the Burundi/Bujumbura workshop digitizes "supervisor and team boundaries" and "align[s] the boundaries to remove gaps and overlaps" (AMP deck, p.18). GRID3-DRC states health-area planning boundaries "differ from standard administrative divisions" ([grid3 DRC](https://grid3.org/news/georeferenced-microplanning-for-immunisation-in-drc)). The IG models exactly this with the `location-type` codes **`supervisory-area`** ("overlays (but is distinct from) the admin hierarchy") and **`operational-area`** ("e.g. polio operational boundaries differing from RI catchments") plus the **`overlays-admin-unit`** extension that links the operational Location to the admin unit(s) it overlays (`codesystems.fsh` L115-116; `extensions.fsh` L164-170). This is a precise, strong match.

- **The polio-vs-RI denominator-non-transfer lesson.** Background literature confirms polio operational geography and RI catchments are managed as separate frames in northern Nigeria, with polio field-census/operational structures distinct from facility catchment denominators (Polio Field Census, Northern Nigeria 2012–2013, [PMC4604797](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4604797/); polio-programme-for-PHC implementation research, [PMC6307512](https://pmc.ncbi.nlm.nih.gov/articles/PMC6307512/)). The IG hard-codes this as the example justifying `operational-area` and notes it in `background.md` (L70-74). Direct validation.

- **Multi-system geospatial identity (GERS + P-code + national code).** The AMP case study explicitly intends "a georepository to improve planning and quantification" reusable "across campaign platforms and malaria interventions" and combines global/continental layers (building footprints, OSM roads) with national lists (health-facility master list) keyed to wards/LGAs (AMP case study, p.1, p.4). The IG's `identifier` slicing — **GERS preferred**, plus P-code, ISO 3166 admin 0–3, national-admin-code — is the right shape for exactly this multi-provenance georegistry. Aligns.

- **Settlement / household / facility location types.** GRID3 maps "all settlements (i.e. localities or populated places in which people live)" as points *and* polygons ([GRID3 settlement white paper](https://eprints.soton.ac.uk/469540/1/GRID3_Settlement_White_Paper_June2021.pdf)); the AMP case study clusters settlements to distribution-point catchments and registers health facilities and distribution hubs (AMP case study, p.4-7); the revised Kano household-based microplanning enumerates settlements → households → children. The IG's `location-type` set ({admin-unit, settlement, facility, school, community-distribution-point, temporary-post, household, …}) covers settlement, facility, household, and community-distribution-point cleanly. Aligns.

- **WorldPop / GRID3 as denominator sources.** The WHO GIS Centre defines population estimation as "the use of statistical models, remote sensing datasets and sampled census information to create spatially accurate … estimates of population density and distribution … used to create population denominators for the community to be served" (AMP deck, p.6); ESPEN benchmarks collected microplan estimates against "WorldPop, Grid3, Meta, and others" (ESPEN one-pager, p.1). The IG's `denominator-source` value set already includes **`worldpop`** and **`grid3`** (alongside census, census-projection, microcensus, hmis, other). Aligns.

- **Geography characteristic on the denominator.** GRID3-DRC and the AMP case study both attach population to a specific settlement/health-area/catchment so the estimate is computably tied to its geography. The IG's `ICRTargetPopulation` geography characteristic → `Reference(ICRLocation)` is precisely this join. Aligns, and is one of the IG's stronger ideas.

- **Hard-to-reach / accessibility flagging.** ESPEN: "Identify hard-to-reach settlements," "Visualize travel time and population heatmaps" (ESPEN one-pager, p.1); the AMP case study identifies "hard-to-reach areas" during field validation (p.6). The IG carries `delivery-strategy` (incl. `mobile`, `house-to-house`, `community-directed`) on site Locations, which partially covers the *response* to hard-to-reach but not the *attribute* itself (see §3a).

---

## 3. Gaps & divergences

### 3a. Things the document requires that the IG does NOT yet represent

- **Population-estimation METHOD + source-raster version/date (real gap).** The sources treat the denominator as the *output of a computation*: WorldPop models "high-resolution population mapping using machine learning and Bayesian statistical approaches" ([WorldPop GRID3](https://www.worldpop.org/current-projects/grid3-micro/)), GRID3 delineates settlement extents by "modeling the probability of … ~100 meter grid cells to be settled" then attaching population, and the AMP/Burundi workflow literally "count[s] households within that polygon, to be verified" (AMP deck, p.18). The IG records *which source* (`worldpop`/`grid3`) and *a date*, but **not the method** (raster-intersection vs field-enumeration vs microcensus) nor the **specific raster release/version** consumed. Two estimates both tagged `worldpop` against the same Location are not distinguishable or reproducible. **Real gap** — recommend a method element + raster-version (§5).

- **Catchment-polygon geometry as the object the raster is intersected against (open question, now partially answered).** The whole denominator method is *polygon ∩ raster*: "A polygon border was drawn for each distribution point's catchment area … Households within that polygon are counted" (AMP deck, p.18); GRID3 intersects gridded population with settlement-extent / health-area polygons. The IG flags GeoJSON-on-R4 as an open question (`background.md` L95) **but in fact already ships** a `location-boundary-geojson` extension (Attachment, `application/geo+json`, Context: Location — `extensions.fsh` L155-162). So the *geometry container exists*; what is missing is (a) confirming it out of experimental status, and (b) documenting it as the catchment geometry the population intersection operates on. **Open-question that is closer to resolved than `background.md` admits** — see §6.

- **Georeferenced structure / building footprints (real gap).** GRID3 settlement extents are built "by drawing contours around groups of building footprints" from "Ecopia Landbase Africa powered by Maxar's building footprints" ([GRID3 settlement extents v4](https://data.grid3.org/datasets/GRID3::grid3-nga-settlement-extents-v4-0/about)); the AMP Mogadishu maps flag "DFA areas having a greater number of building points than expected" (AMP deck, p.11) — building points are a first-class operational object. The IG's `location-type` set has `household` and `dwelling` (in the partOf hierarchy) but no **`structure`/`building`** type for an enumerated footprint that is not yet resolved to a household. **Real gap** (small) — recommend a code (§5).

- **Team / microplan-resource concept (real gap; IG-acknowledged absence).** Each source spends heavily on **teams**: Mogadishu maps DFAs (197) → teams (952) → vaccinators (1,904), with the explicit goal of validating **team workload** (AMP deck, p.10); Burundi digitizes "supervisor and team boundaries" and "Campaign resources can be assigned based on this catchment analysis" (AMP deck, p.18); ESPEN's SA maps exist to assign one supervisor per SA. The IG has **no Team/CareTeam profile and no microplan-resource/workload concept** — supervisory/operational areas exist as *Locations* but there is nobody assigned to them and no roster/workload. **Real gap** (the explainer notes there is no Team profile).

- **Travel-time / accessibility as a modelled attribute (real gap).** "Geographic accessibility … modelling … analyze[s] whether the target populations fall within an agreed-upon travel time or distance threshold" (AMP deck, p.7); ESPEN visualizes travel-time heatmaps and Burundi verified "less than 3km travel is needed for most areas" (AMP deck, p.19). The IG has `delivery-strategy` (the *response*) but **no travel-time / distance-to-service / hard-to-reach attribute** on a Location or settlement. **Real gap** — recommend an accessibility attribute (§5).

- **Georegistry REUSE across campaigns as a first-class lifecycle (partial gap).** ESPEN retains SA operational maps "to support future MDAs" (p.1); the AMP case study's goal is "a perennial mapping database … used across campaign platforms and malaria interventions" / "georepository" (p.1, p.5); GRID3-DRC turns the foundation into "a durable planning asset applicable across multiple health interventions" ([grid3 DRC](https://grid3.org/news/georeferenced-microplanning-for-immunisation-in-drc)). The IG's Location resources are inherently reusable and GERS is explicitly a cross-campaign join key (`background.md` L46), so the *identity* is reusable — but the IG has no notion of **versioning / data-quality status of the geographic foundation** as it is corrected campaign-over-campaign (the AMP case study's whole "iterative validation" loop, p.5). **Partial gap** — see data-quality below.

- **Data-quality / versioning of the geographic foundation (real gap).** The AMP case study's process is fundamentally about *correcting* the base map: validate, flag missing/wrong settlements, capture missing geo-coordinates, note "incorrect placement," resolve "missing settlement identities" (p.6-7). The IG has no completeness/validation-status or version concept on a Location to capture this iterative-correction lifecycle. **Real gap.**

### 3b. Things the IG models that the document treats differently (or contradicts)

- **GeoJSON-on-R4: the IG already answers an "open" question (modelling choice, mislabelled as open).** `background.md` lists "GeoJSON on R4" as open (L95), but `extensions.fsh` already defines `location-boundary-geojson` mirroring the R5 standard boundary extension. The sources show this geometry is *load-bearing* (catchment polygons drive the denominator), so the IG should **stop calling it open** and instead document the extension as the chosen mechanism. This is a documentation/maturity divergence, not a true gap.

- **`overlays-admin-unit` is 1..* on operational types — the sources support an even stronger stance.** The IG (v0.7.0, c90) puts a `1..*` invariant on `overlays-admin-unit` for supervisory/operational areas. The sources fully support this: operational areas in Mogadishu/Burundi routinely span or split admin units, so a 1..* (potentially many) link is correct. **Aligns / the IG is ahead** — no change needed; just confirming the modelling choice is well-founded.

- **The IG keys delivery units to *residence*, not service point; the sources distinguish the same way.** `group-location` is documented as residence, not service point (explainer §6.1) — and the AMP/Burundi pattern likewise distinguishes the **distribution hub** (a service Location) from the **catchment** of households it serves (residences clustered to it). The IG's split matches the source's; the **catchment relationship** between hub-site and the residences it covers, however, has no explicit modelling (households are `partOf` admin units, not "served-by" a site). **Minor divergence** — the catchment-membership link (residence → serving site) is implicit only.

---

## 4. Terminology comparison

| Geo-microplanning term | ICR IG equivalent | Aligns / Varies / Missing | Note |
|---|---|---|---|
| Geographic foundation / base map | (no single artifact) the set of ICRLocation resources + identifiers | Varies | IG has the pieces (Locations, GERS) but no named "foundation" object or its version/quality status. |
| Administrative boundary | `ICRLocation` admin-unit + `partOf` hierarchy; `location-boundary-geojson` for polygon | Aligns | Polygon now expressible via the boundary extension. |
| Catchment area / catchment polygon | `location-type` (operational-area / community-distribution-point) + `location-boundary-geojson` | Aligns (geometry) / Varies (semantics) | Geometry container exists; "catchment" not its own code, and residence→site catchment membership is implicit. |
| Settlement | `location-type #settlement` | Aligns | Point or polygon (via boundary ext). |
| Structure / building footprint | — | **Missing** | No `structure`/`building` type for enumerated footprints (GRID3/Maxar/Ecopia). |
| Vaccination / treatment site | `location-type #facility` / `#temporary-post` / `#community-distribution-point` + `delivery-strategy` | Aligns | Well covered. |
| Supervisory area | `location-type #supervisory-area` + `overlays-admin-unit` | Aligns | Direct match (ESPEN SA). |
| Operational / sub-IU zone | `location-type #operational-area` + `overlays-admin-unit` | Aligns | Direct match incl. polio-vs-RI example. |
| Georegistry / georepository | ICRLocation set + multi-system `identifier` (GERS preferred); GERS-enrichment lifecycle | Aligns (identity) / Varies (reuse) | Reusable identity, but no cross-campaign versioning/quality status. |
| Gridded / raster population (WorldPop, GRID3) | `denominator-source` codes `#worldpop`, `#grid3` | Aligns | Source coded; raster version/date not captured. |
| Population intersection (raster ∩ polygon) | — | **Missing** | No population-estimation-method element; method/provenance of the intersection absent. |
| Travel time / accessibility | (partial) `delivery-strategy` is the response only | **Missing** | No travel-time / distance-to-service attribute. |
| Hard-to-reach | (partial) `delivery-strategy #mobile/#house-to-house` | Varies | Response captured; no hard-to-reach *flag* on the Location. |
| Team / DFA / vaccinator team area | — | **Missing** | No Team/CareTeam or workload/roster; operational area Location has no assignee. |
| GERS / P-code | `identifier` slices (GERS preferred, P-code, ISO 3166, national code) | Aligns | Strong multi-system identity. |

---

## 5. Proposed terminology additions (flag for the IG)

1. **Population-estimation-METHOD element on ICRTargetPopulation** (highest value). A coded characteristic distinguishing how a denominator was derived: `{ raster-intersection, settlement-extent-allocation, field-enumeration, microcensus, census-projection }`. Justified by the AMP/GRID3 method being *polygon ∩ raster* vs the Kano household *enumeration* — both currently collapse to a `worldpop`/`grid3` source tag. **Where:** new code system + characteristic on `ICRTargetPopulation`.

2. **Source-raster version/date** on the denominator. A WorldPop/GRID3 estimate is only reproducible if the raster *release* is named (GRID3 ships settlement-extents v3.0, v4.0, etc.). **Where:** an extension on `ICRTargetPopulation` (or extend the existing denominator-source + date with a version string). Pairs with #1 for full provenance.

3. **Confirm `location-boundary-geojson` as the catchment-polygon mechanism** — promote from `experimental = false`-but-undocumented to a documented, recommended pattern for supervisory/operational/community-distribution-point Locations, and reference it from `background.md` (resolving the open question). **Where:** `extensions.fsh` (already exists) + `background.md`.

4. **`structure` / `building` `location-type` code** for an enumerated building footprint not yet resolved to a household. Justified by GRID3/Maxar footprints and Mogadishu "building points." **Where:** `codesystems.fsh` location-type CS.

5. **Team / CareTeam + assigned-operational-area concept.** A profile (CareTeam or a new ICRTeam Group) carrying roster + a reference to the supervisory/operational-area Location it covers, plus an optional workload (target population ÷ team). Justified by Mogadishu DFA→team→vaccinator workload validation and Burundi resource assignment. **Where:** new profile; link to `ICRLocation` operational-area.

6. **Accessibility / travel-time attribute** on Location (and a hard-to-reach boolean). E.g. an extension carrying travel-time-to-nearest-site and a `hard-to-reach` flag. Justified by ESPEN travel-time heatmaps, AMP accessibility modelling, Burundi 3km verification. **Where:** extension on `ICRLocation`.

---

## 6. Categories / value sets worth adding

- **Geometry-representation axis** — `{ point, polygon, none }` (or simply rely on presence/absence of `position` vs `location-boundary-geojson`). Recommend documenting it as guidance rather than a coded element, since FHIR already distinguishes `Location.position` (point) from the boundary extension (polygon). **Belongs in the IG** as narrative guidance.

- **Population-estimation-method value set** — `{ raster-intersection, settlement-extent-allocation, field-enumeration, microcensus, census-projection }` (see §5.1). **Belongs in the IG** — this is the most consequential missing axis.

- **Structure/footprint type** — `{ residential, non-residential, unknown }` if a `structure` location-type is added. **Optional**; add only if footprints are carried.

- **Georegistry-match status (extends the GERS-enrichment lifecycle)** — the IG already has an async GERS-enrichment lifecycle (create unmatched → conflate → backfill with Provenance). Add a coded match status `{ unmatched, candidate, matched, conflicted }` to make that lifecycle observable. **Belongs in the IG** — it formalizes a workflow the IG already narrates and the AMP iterative-validation loop demands.

- **Resolution of the GeoJSON-on-R4 open question:** **Adopt the existing `location-boundary-geojson` Attachment extension as the IG's canonical geometry mechanism** (it mirrors the R5 standard boundary extension, uses `application/geo+json`, and is already implemented). Carry polygons as GeoJSON attachments referenced from the Location; keep `Location.position` for the point. Do **not** wait for R5. This both answers the open question and supplies the object the population-intersection method (§5.1) runs against.

---

## 7. Use cases not yet identified in the IG

- **Build a geographic foundation + draw catchment polygons, then intersect a population raster to compute a catchment denominator with provenance.** FHIR: `ICRLocation` (operational-area / community-distribution-point) + `location-boundary-geojson` for the polygon; `ICRTargetPopulation` for the result with the proposed method + raster-version provenance; `Provenance` recording the intersection. *Currently the IG can hold the polygon and the result but not the method/version linking them.*

- **Reconcile polio-operational vs RI-admin boundaries (denominator non-transfer).** FHIR: two `ICRLocation` sets (admin-unit hierarchy vs `operational-area`) linked by `overlays-admin-unit`; two `ICRTargetPopulation` estimates, each with its own geography characteristic, that **must not be summed across frames**. *The IG models this well; worth an explicit example.*

- **Reuse a georegistry / microplan across campaigns, with iterative correction.** FHIR: persistent `ICRLocation` + GERS identity reused across campaigns; needs the proposed **georegistry-match status** and a **foundation version/quality** concept to capture the AMP correct-validate-recapture loop. *Partially covered; the versioning/quality piece is missing.*

- **Register settlements/structures + sites + teams as the operational substrate.** FHIR: `ICRLocation` (settlement, facility, community-distribution-point, proposed `structure`); **teams have no home** — needs the proposed Team/CareTeam profile. *Team registration is the clearest uncovered workflow.*

- **Flag hard-to-reach by travel time and route distribution accordingly.** FHIR: proposed accessibility/travel-time attribute + `hard-to-reach` flag on `ICRLocation`; `delivery-strategy` on the serving site captures the chosen response. *Response is modelled; the accessibility input is not.*

---

## 8. Bottom line

The IG's geography model is **adequate and notably well-aligned** for geo-enabled microplanning at the **identity and boundary layer** — and its central design bet is **strongly validated**: every source (ESPEN supervisory areas, AMP DFA/team areas, GRID3-DRC health areas, the polio-vs-RI literature) confirms that **operational geography must overlay, not impersonate, the admin hierarchy**, which is exactly what `supervisory-area` / `operational-area` + `overlays-admin-unit` deliver. That mechanism is the IG's biggest win against this body of work and should be foregrounded.

**On the GeoJSON / catchment-geometry open question:** it is effectively already answered — the IG ships `location-boundary-geojson` (an R4 Attachment extension mirroring the R5 boundary extension). **Recommendation: adopt it as canonical, take it out of "open question" status in `background.md`, and document it as the catchment-polygon geometry that the population-intersection denominator method runs against.** Do not wait for R5.

**Top recommended IG changes:**
1. Add a **population-estimation-METHOD** element + **source-raster version/date** to `ICRTargetPopulation` — turns a denominator from a labelled number into a reproducible, provenance-bearing computation (the single highest-value gap).
2. **Confirm and document `location-boundary-geojson`** as the catchment-polygon mechanism; close the GeoJSON-on-R4 open question.
3. Add a **Team / CareTeam (+ assigned operational area, roster, workload)** concept — the clearest entirely-uncovered workflow across every source.
4. Add a **`structure`/`building` location-type** and an **accessibility/travel-time + hard-to-reach** attribute on `ICRLocation`.
5. Add a **georegistry-match status** value set to make the existing GERS-enrichment lifecycle observable and support cross-campaign reuse/correction.

What **strongly validates the IG**: the operational-vs-admin overlay (`overlays-admin-unit`, `supervisory-area`, `operational-area`), the multi-system GERS-preferred identity, the geography characteristic joining a denominator to a Location, and the WorldPop/GRID3 denominator sources — all four are independently corroborated by these sources.
