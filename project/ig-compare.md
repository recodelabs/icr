---
title: ICR IG ↔ ig-summary.md — Alignment Review
version: 0.1.0
last_modified: 2026-08-10T18:47:35Z
status: findings — resource-by-resource comparison of the FSH sources against the summary doc
tags:
  - icr
  - fhir
  - ig
  - review
---

# ICR IG ↔ ig-summary.md — Alignment Review
<sub>`v0.1.0 · Last modified Aug 10, 2026 at 2:47 PM EDT`</sub>

A resource-by-resource comparison of the IG's FSH sources (`ig/input/fsh/`, treated as ground truth) against [[ig-summary]] (`project/ig-summary.md`). Every profile, extension, CodeSystem, ValueSet, Measure, Questionnaire, ConceptMap, example instance, and the IG metadata was checked; findings below list only the mismatches, with a "confirmed aligned" digest at the end (§10).

**Severity legend**

| Tag | Meaning |
| --- | --- |
| 🔴 **Conflict** | The summary contradicts what the FSH actually ships — a reader would be misled. |
| 🟠 **Omission** | One side is silent about something real on the other side. |
| 🟡 **Drift / minor** | Wording imprecision, or an embedded JSON example that no longer matches the shipped instance. |
| 🔵 **IG defect** | The *summary is right* and the FSH itself is wrong or self-contradictory — fix belongs in the IG, not the doc. |

> [!done] Resolution log
> **2026-08-10 — Task reference-role fix (both sides).** Decision (Matt): target on `Task.for` (1..1 → DeliveryUnit | Location | Patient — R4 beneficiary semantics, standard `Task?patient=` search, OpenSRP/Reveal precedent); campaign link on `Task.basedOn` (1..1 → ICRCampaign, new — tasks point at the campaign, so the CarePlan is never updated as tasks are created); `CarePlan.activity` demoted to an optional curated list; `Task.focus` left unconstrained; `Task.reasonCode` now MS in the profile. Closes: the three §2 ICRCampaignTask conflicts (for/focus swap, invalid mop-up JSON, reasonCode), the §4 IRS for/focus repeat, §9 items 2 (revisit-outcome description) and the round→Task chain half of item 7 (a new STH-MDA protocol/denominator/round now frames the MDA scenario, so every Task example carries `basedOn`). Note: the fix adds 3 example instances, so the §1-flagged example count moves again (46 → 49 in `examples.fsh`); still open along with the other §1 counts.

> **2026-08-10 (later) — Location identity (items 1+2 of the fix list).** Decisions (Matt): the three invariants now exist in the FSH — `icr-loc-admin-id` (**error**: admin-units need ≥1 identifier of any system), new `icr-loc-admin-official` (**warning**: mark the country's authoritative code `use = official` — the uniform join key replacing the fictional national-code URI), `icr-loc-overlays` (**warning** now, error at v1.0). Formal `isoCountry`/`isoSubdivision` slices added on FHIR's standard URNs (`urn:iso:std:iso:3166`, `…:-2`), optional + MS; the `national` slice and `$NationalAdminCode` placeholder are dropped from the doc. Closes: both §3 invariant conflicts, the `national`/`iso` slice conflict, and the `$ISO`/`$NationalAdminCode` alias conflict (§3, §6). Reviewer validation probes (scenario-validation branch) confirmed the gap independently; the admin-id probe now fails validation, the overlay probe warns.

> **2026-08-10 (evening) — `is-calculated` on denominator estimates (reviewer proposal c10, mckinnoj).** New optional boolean extension on ICRTargetPopulation (36th extension): marks an estimate as aggregated from other estimates (ward sums / apportionment) rather than independently sourced — `denominatorSource` keeps describing the underlying inputs' method. Closes the provenance gap where a summed district figure was indistinguishable from an independent measurement. Worked example `example-target-population-ward-sum` added (examples now 50). A `derived-from` reference list (actual inputs, recomputation tracing) is documented as the future enrichment.

> **2026-08-10 (evening) — items 3, 4, 5 decided.** Item 3 (`Organization.type` bindings): **deferral upheld** — the mCSD-alignment pass must re-slice the same element (its facility marker code shares `Organization.type`), so slicing waits to be designed once; doc wording to be softened to "planned" in the doc-alignment pass. Item 4: `CarePlan.careTeam only Reference(ICRCareTeam)` implemented (matches `Task.owner`; the Kambia round example now carries the roster). Item 5: `group.stratifier.code from ICRCoverageStratifierVS (extensible)` bound on both coverage profiles, plus the `group.stratifier MS` flag the summary already claimed. Items 4+5 were doc-correct/FSH-lagging — no summary changes needed.

> **2026-08-10 (night) — mechanical batch (§9 IG-side fix list).** (1) **Reporter design bug fixed**: `reporter` = accountable supervisor/organization (R4-legal), new `reporter-team` extension (37th) carries the CareTeam join on both coverage profiles; demonstrated on the admin-coverage example. (2) `icr-campaign-readiness` now declares `readiness-domain` (new 7th stratifier code) — its description and stratifiers agree. (3) Stock-ledger identity enforced as warning invariant `icr-stock-ledger`. (4) SupervisionReport + dose-pole-band descriptions de-contradicted. (5) background.md ViewDefinitions claim corrected. (6) Example gaps closed: district GeoJSON boundary (first boundary-extension use), full IRS chain (`example-irs-protocol`/`-target-population-irs`/`-irs-round`/`-irs-task` — §6.4's structure-Task claim now demonstrated), `example-zero-dose-coverage` + `example-readiness-coverage` (all 6 Measures now instantiated; examples.fsh = 57 instances). (7) Id normalization while cheap: `icr-team-role`→`icr-team-role-cs` (also un-collides with the same-id ValueSet), `icr-ntd-disease-vs`→`icr-ntd-disease`, `icr-mda-medicine-package-vs`→`icr-mda-medicine-package`. **Still open: the doc-alignment pass** (counts, stale embedded JSON, §11 gallery, recorder→enumerator, FR flags, §9 table gaps, Org.type "planned" softening, smaller table fixes).

> [!warning] The two biggest systematic problems
> 1. **`Task.for` vs `Task.focus` are swapped throughout the summary** (§4.4 table + prose, §5.4, §6.4, and the embedded Task JSON — which is actually invalid against the profile). The FSH puts the 1..1 target constraint (`ICRDeliveryUnit | ICRLocation | Patient`) on **`focus`** and leaves `for` unconstrained.
> 2. **The summary describes several constraints that were never implemented in FSH**: the `icr-loc-admin-id` / `icr-loc-overlays` invariants, the `national` / `iso` Location identifier slices, the `$ISO` / `$NationalAdminCode` aliases, the `Organization.type` bindings, the `CarePlan.careTeam` target restriction, and `Task.reasonCode`. Each needs a decision: **implement in FSH, or delete from the summary.**

---
## 1. Global counts & IG metadata (summary §1.4–§1.5, §2.2, §12)

- 🔴 **CodeSystem count: summary says 25, FSH ships 28.** (`ig-summary.md:181`, restated `:1968`; 28 `CodeSystem:` blocks in `codesystems.fsh`.) The §9 table itself has **27** rows — so prose (25), table (27) and FSH (28) all disagree. Missing from §9 entirely: `ICRProjectTagCS` (`codesystems.fsh:401`, mentioned only in §11).
- 🔴 **ValueSet count: summary says 28, FSH ships 30.** (`ig-summary.md:182`; 30 `ValueSet:` blocks in `valuesets.fsh`.) The missing pair is exactly `ICRNTDDiseaseVS` (`valuesets.fsh:192`) and `ICRMDAMedicinePackageVS` (`valuesets.fsh:199`) — never named anywhere in the summary.
- 🔴 **Example count: summary says 44, `examples.fsh` ships 46.** (`ig-summary.md:183`, `:2124`.) The two unlisted instances are the mCSD pair `example-facility-org` (`examples.fsh:863`) and `example-facility` (`examples.fsh:877`) — ironic, since §1.5 lists ICRFacilityOrganization as a headline profile. (IG-wide, `Usage: #example` totals 52 counting the 6 ESPEN Questionnaires.)
- 🔴 **Measure count self-contradiction: §2.2 and §7 say "four", §1.5 correctly says six.** (`ig-summary.md:269`, `:1753` vs `:178`; `measures.fsh` has 6 instances.) The §7 preamble's list omits `icr-zero-dose-coverage` and `icr-campaign-readiness`.
- 🟠 **§12 omits a whole background.md section** — `#### Relationship to the WHO IDHC toolkit` (`ig/input/pagecontent/background.md:109`) is not in the §12 enumeration (`ig-summary.md:2209`).
- ✅ Everything else in §1.4/§1.5 is exact: all sushi-config.yaml metadata fields, 18 profiles (4/5/3/2/3/1), 35 extensions, 8 Questionnaires + 1 ConceptMap, 2 narrative pages, and the 16-file file map.

---
## 2. Campaign architecture (summary §4)

### ICRCampaignProtocol (PlanDefinition)
- 🟠 **§4.1's delivery-strategy list shows 6 codes; the FSH (and the summary's own §9) have 7** — `outreach` is missing from the note at `ig-summary.md:413` (`codesystems.fsh:59`).
- 🟡 Embedded protocol JSON ≠ shipped `example-mr-sia-protocol`: different `title` and `action.title`, and it embeds the **proposed** `activity-type` extension inside what is presented as the shipped example (`ig-summary.md:337–405` vs `examples.fsh:311–325`). The extension is correctly flagged proposed at `:408`, but it shouldn't sit inside the "example" block.
- ✅ Property table fully aligned otherwise.

### ICRCampaign (CarePlan)
- 🔴 **`careTeam` is documented as `Reference(ICRCareTeam)` but the FSH applies no target constraint** — just `careTeam MS` (`ig-summary.md:462` vs `profiles-campaign.fsh:45`). Any base CareTeam validates. Decide: add `only Reference(ICRCareTeam)` to the profile (the profile's own Description implies it) or soften the summary row.
- 🟡 Embedded Kambia-round JSON ≠ shipped `example-mr-sia-2026`: summary shows `status: completed`, an `addresses` entry, and two `activity.reference` Tasks; the instance has `status = #active`, no `addresses`, **no `activity` at all** (`ig-summary.md:523–626` vs `examples.fsh:344–366`). The §4.2 mermaid also labels the round "completed". The national-umbrella JSON drops the instance's `name`/`title`.
- ✅ All other rows (instantiatesCanonical 1..1, category, subject, period, partOf, activity.reference, all five extensions) aligned.

### ICRCampaignActivity (ActivityDefinition)
- 🟡 Embedded `example-mcv-activity` JSON is embellished: shows `name`, a structured `dosage` (route + 0.5 mL doseQuantity) and a `delivery-strategy` extension; the instance has none of these — only `dosage.text = "0.5 mL subcutaneous, single dose"` (`ig-summary.md:659–714` vs `examples.fsh:260–270`).
- 🟡 The §4.3 activity-gallery "Dosage / rule" column attributes dosing rules ("1 net per 2 household members", "per eligible structure") that appear on **no** instance — neither `example-itn-activity` nor `example-irs-activity` carries a `dosage` (`ig-summary.md:723–724` vs `examples.fsh:289–310`).
- ✅ Property table aligned.

### ICRCampaignTask (Task) — **the section with the central error**
- 🔴 **`for` and `focus` are swapped.** Summary: `for` | MS | 1..1 | `Reference(ICRDeliveryUnit | ICRLocation | Patient)` and `focus` "reserved for workflow lineage" (`ig-summary.md:736`, `:747–748`). FSH: **`focus 1..1 MS`, `focus only Reference(ICRDeliveryUnit or ICRLocation or Patient)`**; `for` is merely MS with no type/cardinality constraint, and no lineage constraint exists on anything (`profiles-campaign.fsh:92–96`). The swap repeats at `:854` (follow-up prose), `:1454` (§5.4), and `:1722` (§6.4 IRS). Inline comment c7 at `:747` already suspects this.
- 🔴 **The embedded mop-up Task JSON is invalid against the profile**: `"focus": {"reference": "CarePlan/example-mr-sia-2026"}` (`ig-summary.md:783–785`) — the profile only allows DeliveryUnit/Location/Patient in `focus`. The shipped `example-mopup-task` has `focus` = `example-household` (`examples.fsh:394–395`).
- 🔴 **`reasonCode` is listed as a constrained MS element but the FSH never touches it** (`ig-summary.md:749`; no `reasonCode` rule in `profiles-campaign.fsh`). Implement or remove.
- 🔵 **FSH defect (summary is right):** the `revisit-outcome` extension's own Description says "Task.for = Patient, Task.focus = the originating Task" (`extensions.fsh:331`) — a shape the profile itself makes impossible. The shipped `example-followup-task` does what the summary's `:761` says (focus = Patient, partOf = originating Task, `examples.fsh:759–760`). Fix the extension description.
- 🟡 `Task.performer` cited as a team reference point (`ig-summary.md:866`, `:973`) — the FSH constrains only `owner`; `performer` is untouched (and R4's `Task.performerType` is a CodeableConcept). The FSH profile Description makes the same claim (`profiles-careteam.fsh:14`), so this is inherited prose.
- 🟡 Minor example drift: `code.text`, `output.type.text` ("administered" vs "delivered"), date-only `executionPeriod` vs the instance's timestamps.
- ✅ All eleven extension slices, `owner`, `location 1..1`, `output` — aligned exactly.

### ICRCareTeam (CareTeam)
- 🔴 **Team-role code `recorder` doesn't exist — the FSH code is `enumerator`** (`ig-summary.md:876` and `:1989` vs `codesystems.fsh:284`, `profiles-careteam.fsh:25`). The CS description notes "ESPEN instruments call this role the recorder"; the summary is stale against the WHO-IDHC rename.
- 🟡 Embedded `example-careteam` JSON shows two participants; the instance has three (vaccinator, **cdd** "Mariama Bangura", supervisor) and a `subject` (`ig-summary.md:898–929` vs `examples.fsh:697–704`). Also stale at §11 row 24 (`:2158`).
- ✅ Everything else aligned, including the workload-target sub-extension shapes.

### ICRSupervisionReport (QuestionnaireResponse)
- 🔵 **FSH defect (summary is right):** the profile Description says "author is the supervising ICRCareTeam" (`profiles-careteam.fsh:41`) while the profile itself excludes CareTeam from `author` (`only Reference(Practitioner | PractitionerRole | Organization)`, `:51–52`). The summary's `:986` is the correct reading; fix the FSH description.
- ✅ Profile table and the four checklist sections fully aligned.

---
## 3. Population & geography (summary §5)

### ICRLocation
- 🔴 **`national` and `iso` identifier slices do not exist.** Summary claims four slices (`ig-summary.md:1293`, prose at `:1263`, `:1369`); the FSH defines only `gers 0..1 MS` and `pcode 0..1 MS` (`profiles-population.fsh:111–117`).
- 🔴 **Aliases `$ISO` and `$NationalAdminCode` do not exist** (`ig-summary.md:286–287`, `:1362`); `aliases.fsh` has only `$GERSId`, `$PCode`, `$NationalId`, `$RegistryId`. Zero hits for `iso:std` / `national-admin-code` anywhere under `ig/input/`.
- 🔴 **Invariants `icr-loc-admin-id` and `icr-loc-overlays` do not exist.** (`ig-summary.md:1293`, `:1296`, `:1369–1370`, `:2078`.) There is **no `Invariant:` or `obeys` anywhere in the FSH**; `overlaysAdminUnit` is plain `0..*` (`profiles-population.fsh:121`). The margin comments at `:1369–1370` already suspected this. Decide: implement the invariants + slices, or strike them from the summary.
- 🔴 **The `example-district` JSON in §5.3 and the §11 row both claim a GeoJSON boundary (and a `position`) the instance doesn't have** (`ig-summary.md:1345–1358`, `:2131` vs `examples.fsh:27–42`). In fact **no example in the IG uses the `location-boundary-geojson` extension at all**. The GERS value also differs (`overture-division-kambia-example` vs `08f2a3b4c5d6e7f8-division-example`).
- 🟡 `position` described as "longitude/latitude"; FSH short says "longitude/latitude/altitude" (`:1291` vs `profiles-population.fsh:102`).
- ✅ Everything else (type binding, partOf, managingOrganization, boundary/deliveryStrategy/settlementType extensions) aligned; `locationAncestors` correctly labelled proposed.

### ICRFacilityOrganization
- 🔴 **`Organization.type` is documented as bound (extensible) to ICRFacilityTypeVS and ICROwnershipVS, but the FSH applies no binding at all** — just `type 1..* MS` with a `^short` noting "Formal per-axis slicing is deferred to the mCSD-alignment pass" (`ig-summary.md:1387`, `:1395`, §9 `:1995–1996` vs `profiles-population.fsh:137–138`). The ValueSets exist but are bound nowhere.

### ICRDeliveryUnit / ICRTargetPopulation
- 🔴 **The enumerated-household example is fabricated at 6 members; the instance has 3** (`example-head`, `example-sibling`, `example-child`; `quantity = 3`). Summary invents four Patients that exist nowhere (`example-caregiver`, `example-child-2`, `example-child-3`, `example-elder`) (`ig-summary.md:1082–1145`, §11 row at `:2140` vs `examples.fsh:158–172`).
- 🔴 **Systematic wrong `system` URIs in the §5 embedded JSON**: the summary uses ValueSet ids as coding systems where the real CodeSystem ids end in `-cs` — `icr-group-kind` (`:1056`, `:1096`), `icr-group-characteristic` (`:1211`), `icr-denominator-source` (`:1228`), `icr-location-type` (`:1326`). Correct systems: `…-cs` (`codesystems.fsh:77`, `:122`, `:183`, `:106`).
- 🟡 The TargetPopulation example JSON drops the instance's `name` (`examples.fsh:212`).
- ✅ Both profiles' tables fully aligned (fixed `type`/`actual`, characteristic slicing, all five TargetPopulation extensions).

### ICRPatient / ICRConsent
- 🟠 **Consent table omits `dateTime MS`** (`profiles-consent.fsh:20`) and the parent `provision MS` (`:25`) (`ig-summary.md:1462–1471`).
- 🟡 Patient identifier slice detail omitted: `nationalId 0..1 MS` / `registryId 0..1 MS` with fixed `$NationalId`/`$RegistryId` systems (`:1410` vs `profiles-population.fsh:18–24`).
- ✅ Otherwise aligned; `example-child` JSON matches the instance exactly.

---
## 4. Delivery events & safety (summary §6)

All four profile tables are essentially **aligned** — including the headline claim that `record-origin` is `1..1 MS` on every delivery event and the adverse event (`profiles-delivery.fsh:27, 50, 72`; `profiles-adverse.fsh:37`). The problems are almost all in the embedded example JSON:

### ICRImmunizationEvent
- 🔴 Example `performer.actor.display` "CDD team 7, Rokupr" — the instance says "Mop-up team 4, Rokupr" ("CDD team 7" belongs to `example-careteam`) (`ig-summary.md:1538` vs `examples.fsh:422`).
- 🟠 Example omits the instance's `priorDoseStatus = #zero-dose` extension — undercutting the table row the summary itself documents (`examples.fsh:426`).
- 🟡 `occurrenceDateTime` date-only vs the instance's timestamp (`:1527` vs `examples.fsh:418`).

### ICRMedicationAdministration
- 🔴 Example `effectiveDateTime` "2026-06-24" — wrong date *and wrong campaign*: the MDA round is February (`2026-02-10T11:00:00Z`, `examples.fsh:434`).
- 🔴 Example shows a structured `dosage.dose` 400 mg block and a `supportingInformation` entry — the instance has neither (only `dosage.text`; no `supportingInformation` at all) (`ig-summary.md:1609–1623` vs `examples.fsh:428–440`).
- 🟠 Example omits the instance's `dosePoleBand` extension — the one example demonstrating the extension the section is built around (`examples.fsh:440`).

### ICRSupplyDelivery
- 🟡 Binding described on `suppliedItem.item[x]`; FSH binds the typed path `suppliedItem.itemCodeableConcept` (`:1659` vs `profiles-delivery.fsh:66–67`). `destination` typed as `Reference(Location)` in the table but the FSH only flags MS — base R4 typing, not narrowed to ICRLocation (`:1660` vs `:69`).
- 🔵 **The stock ledger identity (`received = used + remaining + notUsable + returned`) is documented but neither enforced nor even shorted in the FSH** (`ig-summary.md:1662`; `extensions.fsh:244–270` has no invariant). Candidate invariant for the next IG round.
- 🟡 `vvmStage` is the one sub-extension without MS (`extensions.fsh:257`); example-JSON `unit` "{Net}" vs instance "nets".
- ✅ Sub-extension list and the `example-albendazole-supply` numbers match exactly.

### §6.4 IRS / structure-applied
- 🔴 `Task.for`/`focus` swap again (`:1722`) — see §2 above.
- 🔵 **No IRS Task instance ships** — only `example-irs-activity`; "fully recordable as structure-targeted Tasks" is undemonstrated (`examples.fsh:300–309`).

### ICRAdverseEvent + ConceptMap
- 🟠 Table omits the constrained parents `suspectEntity MS` and `suspectEntity.causality MS` (`profiles-adverse.fsh:29`, `:33`).
- 🟠 §6.5 doesn't note the ConceptMap's source/target asymmetry: `sourceCanonical`/`targetCanonical` are **ValueSets** while `group.source`/`target` are **CodeSystems** — relevant because both WHO IMMZ canonicals are provisional/unresolvable (`conceptmaps.fsh:17–20`).
- 🟡 Seriousness codes rendered lowercase as if ICR-minted; they're the HL7 `adverse-event-seriousness` codes reused via `$AESeriousness` (`valuesets.fsh:146–151`). `subject` prose says "Group"; profile narrows to `ICRDeliveryUnit`.
- ✅ Profile table, all four causality mappings, and the three AE examples aligned.

---
## 5. Coverage & Measures (summary §7)

- 🔴 **"Four canonical Measures" is stale — six ship** (see §1). §7.3 and §1.5 already say six.
- 🔵 **Shared modeling bug — `MeasureReport.reporter` cannot reference a CareTeam in R4.** Both the summary (`ig-summary.md:1769`, §2 diagram `:218`) and the FSH `^short`s (`profiles-coverage.fsh:19`, `:45`) describe the reporter as "the supervisor's ICRCareTeam", but R4 limits reporter targets to Practitioner | PractitionerRole | Location | Organization, and the profiles neither constrain nor extend the list. **This needs an IG-side design fix** (e.g. reporter = the team's `managingOrganization`, or a reporter extension).
- 🔴 **`group.stratifier` is flagged MS in the admin table; the FSH sets only a `^short`, no MS** (`ig-summary.md:1772` vs `profiles-coverage.fsh:21`; confirmed in the generated snapshot).
- 🔴 **The ICRCoverageStratifierVS "binding" exists only as prose** — named in `^short`s and even asserted "extensible" in the VS's own description and §9 (`:1985`), but no `from … (extensible)` rule exists anywhere (`profiles-coverage.fsh:21`, `:47`; `valuesets.fsh:107`). §7's open question at `:1947` half-acknowledges this.
- 🟠 SurveyCoverage's §7.2 table omits the `group.stratifier` row that the admin table has (`profiles-coverage.fsh:47`).
- 🟠 `icr-zero-dose-coverage` declares **three** stratifiers (dose-history, sex, age-band), not just dose-history (`ig-summary.md:1936` vs `measures.fsh:134–142`).
- 🔵 **`icr-campaign-readiness` is self-inconsistent in the FSH**: its description claims stratification "by readiness domain" but it declares only a `geography` stratifier, and no `readiness-domain` code exists in `ICRCoverageStratifierCS` (`measures.fsh:153`, `:161–163`; `codesystems.fsh:238–243`).
- 🟡 Wording: "fixes `coverageSource`" is actually a `pattern` (behaviourally identical for a primitive code); admin table attributes the `disposition` stratifier to a Measure that doesn't declare it (it belongs to the MDA/geographic Measures); survey Measure *does* declare numerator + denominator populations despite the "no population required" prose; Measure `scoring`/`status`/canonicals never stated; `coverageSource` base binding and the SurveyCoverage re-binding to `ICRIndependentCoverageSourceVS` not surfaced in §10's row.
- 🔴 **Embedded example JSON drift**: `measureScore` shown as `{"value": 0.99}` / `{"value": 0.76}` — instances use UCUM percent Quantities `99 '%'` / `76 '%'` (`examples.fsh:475`, `:493`); `reporter` shown as `Location/example-district` — instances use display-only text (`:469`, `:489`); sample-design string differs.
- 🔵 No MeasureReport example instantiates the two forms-v1 Measures (only 4 of 6 have worked reports).

---
## 6. Terminology (summary §9, §2.4)

- 🔴 Counts and the missing `ICRProjectTagCS` / `ICRNTDDiseaseVS` / `ICRMDAMedicinePackageVS` — see §1.
- 🔴 `recorder` → `enumerator` — see §2 (ICRCareTeam).
- 🔴 **FR-designation flags wrong for two systems**: `ICRFacilityTypeCS` and `ICROwnershipCS` are marked "FR —" in the §9 table but carry `#fr` designations on every code (`ig-summary.md:1995–1996` vs `codesystems.fsh:419–429`, `:438–453`). Actual FR coverage: 9 systems, not 7.
- 🔴 **§9 asserts three bindings that don't exist in FSH** (stratifier ×1, facility-type/ownership ×2) — detailed in §3 and §5 above.
- 🟠 "One whole-system ValueSet per CodeSystem except ICRGroupCharacteristicCS" — `ICRProjectTagCS` also has no ValueSet; and the "single code fixed in the slice" parenthetical is stale (the CS now has 2 codes; only `#geography` is profile-fixed) (`ig-summary.md:2000` vs `codesystems.fsh:122–128`).
- 🟡 `ICRMissedReasonCS` carries `en-US` designations ("Population refusal", "Absence of DC") that the FR-only framing never mentions (`codesystems.fsh:140–145`).
- 🔵 FSH-internal id inconsistency (no summary claim either way): the two espen-forms ValueSets use a `-vs` suffix unlike the other 28, and `icr-team-role` lacks the `-cs` suffix every other CodeSystem has.
- ✅ Code lists match **exactly** for 26 of 27 tabled systems (including all 18 communication-channel codes, all reason lists, denominator-source, settlement-type, MDA packages); all alias URIs that exist match; the binding-strength tables at `:2014–2016` match all 27 actual `from ICR…VS` bindings.

---
## 7. Extensions (summary §10)

- 🔴 The `icr-loc-overlays` invariant claim (`:2078`) — see §3.
- 🟠 `coverage-source` row hides the two profile-level narrowings (admin fixes `#administrative`; survey re-binds to `ICRIndependentCoverageSourceVS`) (`:2087` vs `profiles-coverage.fsh:28`, `:54`).
- 🟡 `denominator-source` "(0..1 on coverage reports)" — only the admin profile slices it; SurveyCoverage doesn't carry it at all (`:2067` vs `profiles-coverage.fsh:24`, `:48–53`).
- 🟡 The §10 design note "structural discriminators are required + `code`; field vocabularies extensible + CodeableConcept" is broken by its own lead example — `delivery-strategy` is a required-bound **CodeableConcept** (`:2093` vs `extensions.fsh:10–11`).
- 🟡 `exclusion-reason` alone shows "0..*" — its siblings `missedReason`/`noncomplianceReason` repeat too (`:2056–2058` vs `profiles-campaign.fsh:112–114`).
- 🔵 `dose-pole-band` claims "coded extensibly" in its own FSH description but has **no binding** and no dose-pole ValueSet exists (`extensions.fsh:229–232`). The summary is the accurate side.
- 🔵 `social-mobilization` declares `Context: CarePlan, Task` but no profile uses it on Task (`extensions.fsh:277`).
- ✅ Count (35) exact; all ids, value types, contexts, bindings, and the complex sub-extension shapes (stock-accountability, social-mobilization, workload-target) verified; `LocationAncestors` correctly flagged proposed; "cardinality where used" column matches the profiles.

---
## 8. Examples & the §2/§11 narrative chain

- 🔴 **The §11 mermaid asserts the round → Task edge that the shipped examples don't have**: `example-mr-sia-2026` has no `activity` element, and `example-mopup-task` has no `basedOn`/`partOf` back to the CarePlan (`ig-summary.md:2119` vs `examples.fsh:344–365`, `:386–409`). The "single traceable line from template to person" is broken at exactly that edge. (Also an IG-side gap worth fixing in `examples.fsh` — the §2 architecture diagram promises this link.)
- 🔴 Household 6-vs-3 members and the district boundary claim — see §3.
- 🟠 `gallery` tag scope understated: 6 instances carry it (ITN + IRS + the whole SCH descoping trio), not just "ITN, IRS" (`:2102` vs `examples.fsh:817–847`).
- 🟡 §11 row drift: `example-careteam` "vaccinator + supervisor" (actually 3 roles + subject); `example-fixed-post` name shortened; `example-settlement` row omits its `settlementType` extension.
- ✅ Every other named id resolves exactly; all 46 instances carry project tags as claimed; the numeric spot-checks (denominators, doses, stock ledger, coverage scores, strata) all match.

---
## 9. IG-side fix list (summary is right; FSH needs the change)

Collected from above — these belong in the IG repo, not the summary:

1. **`MeasureReport.reporter` cannot be a CareTeam in R4** — design fix needed on both coverage profiles (and the `^short`s). *(§5)*
2. `revisit-outcome` extension Description contradicts the Task profile's `focus` constraint (`extensions.fsh:331`). *(§2)*
3. `ICRSupervisionReport` Description says author = CareTeam; the profile forbids it (`profiles-careteam.fsh:41` vs `:51–52`). *(§2)*
4. `icr-campaign-readiness` Measure description promises a `readiness-domain` stratifier that is neither declared nor in the stratifier CS (`measures.fsh:153`). *(§5)*
5. `dose-pole-band` says "coded extensibly" but ships unbound, with no ValueSet (`extensions.fsh:229–232`). *(§7)*
6. Stock-accountability ledger identity documented but not enforced — candidate invariant (`extensions.fsh:244–270`). *(§4)*
7. Examples never link round → Task (`activity`/`basedOn`) and never use the boundary extension; no IRS Task, no zero-dose/readiness MeasureReport examples. *(§8, §4, §5)*
8. background.md claims "ViewDefinitions ship in the IG" — none exist; summary §13.1 correctly lists them as a gap (`background.md:~59`). *(§1)*
9. Cosmetic: id-suffix inconsistencies (`-vs` on the two espen ValueSets; `icr-team-role` without `-cs`); `social-mobilization`'s unused Task context; `vvmStage` the only non-MS stock sub-extension. *(§6, §7)*

---
## 10. Confirmed aligned — digest

For the record, the comparison **verified as exact**: all §1.4 IG metadata against `sushi-config.yaml`; the profile inventory (18) and file map; all 35 extensions (ids, types, contexts, bindings, complex shapes); 26/27 tabled code lists code-for-code, all existing alias URIs, and every binding-strength claim that has a real binding behind it; the full delivery-events profile tables including `record-origin 1..1 MS` on all four; the AEFI ConceptMap's four mappings; all 8 Questionnaire ids, the §4.6/§4.7 checklist structures answer-for-answer, and the §4.8 ESPEN template-extraction claims template-by-template (including forms 4–6 shipping zero extraction extensions); and the §11 numeric spot-checks (denominators, lot numbers, stock ledger, 91%/94%/99%/76% coverage figures and their strata).

The summary is structurally accurate about the IG's design; the misalignments concentrate in (a) the `for`/`focus` swap, (b) never-implemented constraints described as real, (c) stale counts from the espen-forms/forms-v1 rounds, and (d) embedded JSON "examples" that were hand-written rather than pasted from `examples.fsh`.
