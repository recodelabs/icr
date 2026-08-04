---
version: 0.1.0
last_modified: 2026-08-04T13:57:28Z
tags:
  - icr
  - fhir
  - ig
  - validation
public: true
comments: true
---

# ICR FHIR Implementation Guide — Data Model Validation Report
<sub>`v0.1.0 · Last modified Aug 4, 2026 at 9:57 AM EDT`</sub>

*Scenario-based validation of the ICR IG (v0.1 draft, companion doc v0.28.1, commit
`d8cdacc`), conducted August 2026. — DRAFT for review.*

## Executive Summary

This validation stress-tested the ICR data model against 21 concerns raised during
Crosscut's review of the Implementation Guide. We built one integrated campaign world
— a Nigeria schistosomiasis MDA campaign plus IRS, ITN, and measles-rubella
satellites — as 89 real FHIR resources, and ran every instance through the official
HL7 validator. All 89 pass; every claim below is backed by a validated instance or a
deliberately non-conformant probe, preserved and re-runnable.

Result: 10 of 21 concerns fully supported, 9 tensions, 1 break, 1 duplicate. The
core architecture (campaigns, populations, locations) held up without strain; the
problems concentrate in the connections between resources, and in places where the
written specification and the implemented profiles disagree. Findings are presented
in descending order of importance, with supply-chain findings grouped at the end.

### 1. Tasks cannot identify their campaign

**Problem.** No element on a Task identifies the campaign it belongs to. The only
link runs the other way: the campaign's CarePlan must enumerate every one of its
Tasks in a single list.

**Example.** A round with 40,000 household Tasks is a campaign record holding 40,000
references, rewritten and re-versioned every time a field team registers another
household. IRS is the worst case: the per-structure spray record is the deliverable,
so a realistic round generates 100,000–1,000,000 Tasks every season with no
aggregate fallback.

**Fix (small — the highest-leverage change in this report).** Profile `Task.basedOn`
as a required reference to the campaign: two lines of FSH, using the base FHIR
element defined for exactly this purpose. The CarePlan's Task list then becomes
optional.

***Special note on discrepancy between companion doc and IG.*** The prose companion doc describes the IG but does not define it, and on this
point the two are out of sync: the companion doc's design does include a
Task→campaign link (it reserves `Task.focus` for "workflow lineage — the CarePlan,
activity, or prior Task this work derives from"), but the IG never implemented that
design and assigned `focus` to the target instead, leaving no campaign link.

The resolution is not simply to sync the IG to the companion doc, because the doc's
design is itself only a partial solution: `focus` is a single slot shared across
three lineage roles, so a follow-up Task that points `focus` at the prior Task that
missed a child has nowhere left for the campaign; and base FHIR defines `focus` as
"the thing being acted on," so the doc's usage conflicts with FHIR's own semantics
while the IG's compiled usage matches them. This is why the fix above uses
`basedOn` — the element base FHIR defines for "the plan this task fulfills" — rather
than adopting either side of the discrepancy.

### 2. The specification documents constraints that are not enforced

**Problem.** The documentation presents two named validation rules as active — admin
units must carry an identifier; supervisory areas must reference the unit(s) they
report into — but neither exists in the IG source. A reader of the documentation
believes data-quality guarantees the validator does not uphold.

**Example.** A supervisory area referencing nothing validates today — exactly the
failure the documentation says the rule prevents, since such an area cannot be
rolled up to any reporting unit. The rule's two written definitions also contradict
each other (targets restricted to admin units vs any Location), and "overlay"
misnames the mechanism, whose actual function is "reports into." The same gap
extends to the IG's examples: several shipped instances fail validation — coverage
scores recorded as "99%" where a unit-less 0–1 value is required, a drug
administration missing its required structured dose — unnoticed because the build
check (SUSHI) cannot evaluate these rules.

**Fix (small).** Resolve the target-type question, implement both rules (~6 lines
each), and rename the extension before v1.0; validate all shipped examples with the
full HL7 validator and repair the failures.

### 3. The specification contradicts itself about the Task's target field

**Problem.** The documentation says a Task's target goes in `Task.for` with lineage
in `Task.focus`; the compiled profile implements the opposite. The documentation's
own example is invalid against the shipped profile.

**Example.** Two CommCare integrations each write a Task for a visit to household
123. Vendor A follows the documentation; vendor B follows the compiled profile:

```
Vendor A (per the documentation):    for:   Group/household-123
                                     focus: CarePlan/kogi-round

Vendor B (per the compiled profile): focus: Group/household-123
                                     for:   (unconstrained — anything or nothing)
```

Both believe they are conformant. A report that counts visited households by reading
`for` sees vendor A's visits and misses vendor B's entirely — and vendor A's records
are, in fact, invalid against the shipped profile, though the validator does not
catch it (reference-type checks are skipped for unresolved references).

**Fix (small).** `focus` = the thing acted on (as compiled), `for` = the beneficiary
population, `basedOn` = the campaign (finding 1); correct the documentation and its
example.

### 4. Derived population estimates are indistinguishable from direct ones

**Problem.** An estimate produced by summing child geographies looks identical to a
direct enumeration at the same geography — the derivation is recorded only as free
text.

**Example.** Lokoja LGA carries its GRID3 estimate (19,500) beside the sum of its
wards' microcensuses (18,200); the side-by-side comparison works and validates, but
no query can tell which one is a roll-up.

**Fix (trivial).** A coded marker: a `derived-aggregate` source code, or a
`derived-from` extension referencing the constituent estimates (which also makes
roll-ups auditable).

### 5. Household-to-community membership is inferred, not recorded

**Problem.** No element records which community a household belongs to; the link is
inferred by matching the household's settlement against each community's base
Location. The underlying split — community as people, settlement as place — also
fights how planners think: in the field the two words are synonyms.

**Example.** Two community Groups registered at one settlement (two campaigns, or
one village split between two CDDs) make the inference ambiguous, and nothing in the
data can contradict a wrong guess. Note: the earlier review closed this question on
incorrect information — FHIR R4 *does* allow a Group to contain Groups, so explicit
membership was always an option.

**Fix (small).** Enforce a 1:1 relationship between settlements and communities —
one community per settlement, based at the settlement itself, reused across rounds —
as a registry ingestion rule, which makes the drill-down deterministic. Trade-off:
settlements must be defined at the level communities operate.

### 6. "Real-time" is the wrong name for the raw data stream

**Problem.** The model splits campaign data into two streams by a single flag:
`realtime` (in-campaign, uncleaned) and `reconciled` (corrected close-out figures).
The design is sound, but the `realtime` tag marks reconciliation status, not update
frequency — so the name promises a cadence the model doesn't require.

**Example.** A summary compiled once a day from the day's submissions carries the
`realtime` tag and is fully conformant — nothing about the tag implies intra-day
reporting. `raw` versus `reconciled` describes the actual distinction: as-collected
data versus cleaned final figures.

**Fix (trivial).** Rename the codes before v1.0 locks them. Two housekeeping items
travel with this finding, neither of which is broken behavior: the shipped Measure
definitions formally require every coverage report to include the declared
stratifier elements, while the documentation calls stratifiers optional — align the
two (the practical burden is low, since reports carry whatever breakdown they have);
and individual dose records carry no lineage flag, so their stream membership is
derived through the Task that references them rather than read directly — worth a
documented derivation rule.

### 7. Refusals are complete at visit level but undefined at person level

**Problem.** Visit-level refusals are well handled (coded reason on the Task). But
the IG's documentation says per-person reasons require person-level records — while
defining no person-level refusal record, since a refusal produces no dose.

**Example.** "Caregiver refused — concerned about side effects" is recordable as a
not-done immunization with the coded reason, and it validates — but the pattern
exists only in a review comment: undocumented, no vocabulary binding, and no rule
preventing the same refusal being counted twice (once on the Task, once on the
record).

**Fix (small).** Document the not-done pattern, bind its reason field to the refusal
vocabulary, and state the counting precedence.

### 8. Person-level fields lose their meaning on group-level records

**Problem.** On a community-level administration record, fields defined for a person
silently change meaning: "directly observed = true" can only mean the protocol was
applied — it cannot say who, or how many, actually swallowed.

**Example.** A distributor watches 305 of 312 people swallow. That split has no
home: no observed/not-observed stratifier exists, and adding one locally fails
validation, so the test world had to stretch the "disposition" axis to record it.

**Fix (small).** Add a directly-observed stratifier code to the treatment Measure;
define the group-scale meaning of the affected fields in the profile documentation.

---

**Supply-chain findings.** The three remaining findings concern supply-chain data.
They are grouped here because they share a pending context, not because they matter
least: a dedicated supply chain deep dive is planned, and its full analysis will
likely produce additional supply-chain-related adjustments beyond the targeted fixes
below.

### 9. Supporting supply chain work must claim a delivery strategy it doesn't have

**Problem.** Every Task must carry the `delivery-strategy` field — required, exactly
one value, from a closed set of seven codes, all describing ways of delivering
services/treatment to a population. Work that touches no beneficiary — drug
transport, mobilization — matches none, and omitting the field fails validation.

**Example.** A truck moves praziquantel from the state medical store to the LGA
staging store — a routine campaign Task that must be recorded. The seven available
`delivery-strategy` codes are:

- `fixed-post` — delivery at a permanent site
- `temporary-post` — delivery at a temporary community focal point
- `mobile` — team deployed to remote areas to deliver services
- `school` — delivery through schools
- `house-to-house` — teams visit every dwelling
- `community-directed` — community drug distributors treat their own communities
- `outreach` — vaccination at special-strategy sites (markets, transit points)

None of them describes moving stock between warehouses. The field cannot be omitted,
so the transport Task must record a value that is false.

**Fix (trivial).** Add a `logistics` code to the strategy vocabulary, or require the
field only on delivery-facing activities.

### 10. The stock ledger cannot balance at any node that ships stock onward

**Problem.** The documented reconciliation identity — received = used + remaining +
notUsable + returned — has no term for stock transferred onward, so it fails at
every node except the last in the chain.

**Example.** The test staging store received 120,000 tablets and issued 102,000
onward; its ledger fields sum to 18,000, so the formula reports a 102,000-tablet
loss at a store that lost nothing. And because transfers record no origin, there is
no queryable way to find the outbound transfers that explain the gap.

**Fix (small).** Add transferred-out and origin fields to the stock-accountability
model.

### 11. Drug lots cannot be identified anywhere in the model

**Problem.** Vaccine doses carry lot number and expiration date; drug records cannot
carry a lot at all — not on the administration (the profile closes the one path to
batch data) and not on supply events.

**Example.** The test round was descoped precisely because its praziquantel lot
expires in August — yet that lot exists only in free text, so "which areas received
stock from the expiring lot?" is unanswerable for drugs while routine for vaccines.

**Fix (small).** Add lot and expiry fields to the stock-accountability extension.

---

## Per-item findings

This section provides the full evidence behind each Executive Summary finding. Each
finding is followed by the scenario(s) that exercised it; scenarios that validated
without surfacing any problem are collected at the end. Scenario numbering follows
the finding order above.

Validation levels cited per scenario: **full** = the instances pass SUSHI compilation
and the HL7 validator; **SD-inspection** = the claim was verified by direct
inspection of the compiled StructureDefinition (used where the validator cannot check
it, as noted); **analysis** = an order-of-magnitude analysis with no instances by
design.

### Finding 1: Tasks cannot identify their campaign

#### Scenario 1 — partOf depth cap vs national→State→LGA→Ward tracking · **tension** · full + SD-inspection

**TL;DR.** Per-level denominators and coverage work, but there is no Task→campaign element — the only link is the CarePlan enumerating every Task, which doesn't scale.
**Fix:** profile `Task.basedOn → Reference(ICRCampaign)` (small). Highest-leverage change in this report.

> "Can/should this type of delegation be extended further? E.g., can the distribution
> within a specific Ward be tracked as `partOf` a district's round which is part of an
> umbrella campaign?" *(instruction: ensure the depth limitation does not hinder
> tracking data across national/State/LGA/Ward levels)*

**Scenario.** National umbrella (`sc-mda-umbrella`, intent=plan) → Kogi state round
(`sc-kogi-round`, intent=order) is the whole CarePlan chain. Below it, per the §4.2
granularity rule: LGA/ward/settlement work is Tasks at those Locations
(`sc-task-ward-mobilization`, `sc-task-settlement-sweep`, community/household Tasks),
ward denominators are geography-scoped Groups (`sc-pop-felele-sac-micro` …), and
ward-level coverage is its own MeasureReport (`sc-cov-felele-ward`).

**Evidence.** Everything the comment asks for *can* be tracked without ward CarePlans
— all instances validate, and per-level denominators and coverage work. But three
required joins are fragile, which is what "ensure the cap does not hinder" surfaced:

1. **There is no Task→campaign link in the compiled profile.** Prose §4.4 routes
   lineage through `Task.focus` = CarePlan — but the compiled profile reserves `focus`
   for the target and constrains it away from CarePlan (SD-inspection; see S4). The
   only conformant link is the reverse one: `CarePlan.activity.reference` must
   enumerate every Task. "Which campaign does this Task belong to" — the first
   question any ODK/CommCare payload must answer — has no profiled element on the Task.
2. **CarePlan.activity as the join means unbounded resource growth.** `sc-kogi-round`
   lists 6 Tasks; a real state round lists 10⁴–10⁵ (see S2). One resource
   accumulating every Task reference, re-versioned on each addition, is the pattern's
   scaling limit.
3. **Geography scoping of coverage is unprofiled.** `sc-cov-felele-ward` scopes via
   `MeasureReport.subject` → ward Location — valid base R4, passes full validation,
   but the profile neither mentions nor Must-Supports it; the shipped examples imply
   scope via `reporter.display` strings. Two implementations will disagree on where
   "which area is this figure for" lives.

**Recommendation (small).** Profile `Task.basedOn only Reference(ICRCampaign)` 1..1 MS
as the campaign link (base R4 element, exactly its intended meaning); document that
`CarePlan.activity` is optional/curated for bulk campaigns; add `subject` MS with
`Reference(ICRLocation)` guidance on both coverage profiles. The depth *cap* itself
can stand — it is the surrounding joins that need hardening.

#### Scenario 2 — IRS Task volume · **tension** · analysis (no instances by design)

**TL;DR.** 10⁵–10⁶ Tasks per round, every round, with no aggregate fallback. The row count itself is manageable; the constraint is `CarePlan.activity`, which must enumerate every Task in a single resource.
**Fix:** same as S1 — `Task.basedOn`, make the activity list optional (small).

> "…one consequence is that IRS campaigns are going to generate far, far more Tasks
> than campaigns where delivery events hang off of Tasks." *(instruction: confirm
> whether the scale of these Tasks is acceptable)*

**Estimate (realistic IRS round).** IRS rounds target bounded geographies; national
programme rounds (PMI-style) spray on the order of 10⁵–10⁶ structures per country
season — e.g. a two-LGA Kogi round ≈ 80,000–120,000 eligible structures; a large
multi-district round 300,000–1,000,000. One Task per structure (no aggregate fallback —
the structure *is* the unit of work, §6.4), plus ~10–15% revisit Tasks for
locked/refused structures, plus a structure *Location* per Task target the first time
through: ≈ **10⁵–10⁶ Tasks + a similar count of Locations per round, recurring every
round** (IRS is seasonal — annual or twice-yearly, so the corpus multiplies).

**Comparison the reply (c81) invites.** "Same order of magnitude as any Type-B
campaign" is arithmetically true (structures ≈ households ≈ population/5) — Nigeria-
scale Type-B polio is ~10⁷ households. But the comparison hides the operative
difference, which is James's point: Type B *degrades gracefully* — the IG itself
steers Type B/C toward one Task per **visit/session** with aggregate tallies, and
register-level MDA collapses a state to ~10³ community Tasks (this world: one
community Task covers 312 treatments). **IRS has no such collapse** — the per-structure
record *is* the deliverable (which house was sprayed, with how much), so lazy creation
changes when Tasks appear, not how many exist.

**Feasibility.** As rows in a FHIR store, 10⁵–10⁶ Tasks/round is unremarkable (HAPI
handles orders more). The binding constraints are the model's joins, not the row
count: (a) `CarePlan.activity.reference` enumerating every Task makes the round
CarePlan a multi-megabyte resource re-versioned per registration — at 10⁵ Tasks this
is the first thing that breaks operationally (same joint as S1); (b) mobile-sync
payloads of 10⁵ pre-planned Tasks argue for field-registration, which §4.4 already
provides; (c) every structure Location needs GERS conflation eventually — a pipeline
cost, not a blocker. **Verdict per the brief's criterion:** the scale is workable
*only* via the §4.4 mitigations (lazy creation, bounded geographies) plus abandoning
the CarePlan.activity enumeration → **tension**, not supported.

**Recommendation.** Same fix as S1 (Task.basedOn as the campaign join; activity list
optional for bulk campaigns) — that single change removes the main scaling constraint for IRS. Pilot metric worth capturing: Tasks/round and sync payload size in
the first IRS-adjacent deployment.

### Finding 2: The specification documents constraints that are not enforced

#### Scenario 3 — Supervisory areas in three configurations · **supported** · full

**TL;DR.** Cutting across wards, nesting under a ward (anchored to a settlement), and grouping whole wards all validate.
**Caveat:** the invariants the prose claims (`icr-loc-overlays` etc.) don't exist in the FSH (trivial to add).

> "In the event that a campaign's supervisory areas nest under the country's admin
> hierarchy, would it be valid to draw the supervisory-area to the settlement node
> instead of the admin-unit?" *(instruction: show cutting-across / nesting-under /
> grouping-whole-wards)*

**Scenario.** Three supervisory-area Locations, none in the `partOf` chain:
`sc-sa-cross` overlays Felele + Adankolo wards (cuts across both); `sc-sa-nested`
overlays the **settlement** `sc-felele-central` (nests under one ward — the exact
c72 question); `sc-sa-grouping` overlays three whole wards. `sc-cdd-team-felele`
attaches to `sc-sa-cross` via `oversees-area`.

**Evidence.** All three validate; reply c72's core claim is proven — `overlays-admin-
unit` is `Reference(ICRLocation)` with no target-type restriction, so anchoring a
nested supervisory area to the settlement is conformant, and keeping even
cleanly-nesting areas out of `partOf` (surviving next round's redraw) works as
designed. Roll-up query: team → oversees-area → overlays → ward(s) → LGA. Two flags,
neither blocking the asked-for configurations: (1) **the `icr-loc-overlays` invariant
the prose leans on does not exist in the FSH** — a supervisory area overlaying
*nothing* validates today (grep: no invariant/`obeys` anywhere in the IG source; prose
§5.3 presents both `icr-loc-overlays` and `icr-loc-admin-id` as enforced). Prose-FSH
divergence, logged cross-cutting. (2) An overlay is all-or-nothing: `sc-sa-cross`
covering *part* of each ward is indistinguishable from covering all of it except via
boundary geometry — fine for roll-up, misleading for denominator apportionment.

**Recommendation (trivial + small).** Implement the two documented invariants as FSH
`obeys` rules (trivial — and it makes the prose true); note the partial-overlay
limitation in §5.3, pointing at `boundary` GeoJSON for exact extents.

### Finding 3: The specification contradicts itself about the Task's target field

#### Scenario 4 — `for` at multiple granularities (settlement, ward) · **tension** · full + SD-inspection

**TL;DR.** Location targets at any level work. But the profile makes `focus` the target and leaves `for` unconstrained, while the prose says the opposite — so which field the question refers to is currently undefined.
**Fix:** `focus` = target, `for` = beneficiary, `basedOn` = campaign; rewrite §4.4 (small).

> "We should construct a few example scenarios where the ICRLocation specified in the
> `for` field is set at various levels so we can confirm the model supports the
> required levels of granularity in different situations."

**Scenario.** Two new Tasks target Locations at previously-unexercised levels:
`sc-task-settlement-sweep` (mop-up over Geregu-Riverside settlement) and
`sc-task-ward-mobilization` (ward-wide mobilization over Felele Ward). Both populate
`focus` *and* `for` with the Location.

**Evidence.** Both validate; a settlement- or ward-level Location target is
representable, closing the gap reply c61 acknowledged. But the exercise exposed the
report's headline finding: **the profile and the prose assign the target role to
opposite fields, so which field the question refers to is undefined.**

- Compiled profile (SD-inspection): `focus` is the target — 1..1, restricted to
  `ICRDeliveryUnit | ICRLocation | Patient`; `for` is MS but **unconstrained**
  (base: any Resource, 0..1). "Confirm the model supports `for` at various levels"
  is therefore *vacuously* true — `for` accepts anything, enforcing nothing.
- Prose §4.4 (v0.28.1) documents the opposite: `for` = target (1..1, typed), `focus` =
  workflow lineage — and its example JSON (`for` = household, `focus` = CarePlan)
  violates the compiled profile: `focus`'s target types exclude CarePlan.
  (`probe-task-focus-careplan` passes the validator only because reference target
  types are unchecked for unresolved references — the compiled SD is unambiguous.)
- The FSH contradicts itself: the `revisit-outcome` extension description prescribes
  "Task.for = Patient, Task.focus = the originating Task", which the profile forbids;
  the shipped `example-followup-task` accordingly puts the Patient in `focus` and
  the originating Task in `partOf` instead.

Granularity: confirmed. Which field carries it: undefined. That ambiguity is a direct
integration hazard for exactly the ODK/CommCare feeds Crosscut consumes.

**Recommendation (small-to-structural).** Align on R4's own element meanings —
`focus` = the thing acted on (keep the FSH constraint), `for` = the beneficiary
population (profile it `only Reference(ICRTargetPopulation | ICRDeliveryUnit |
Patient)` MS), `basedOn` = campaign lineage (see S1) — then rewrite prose §4.4 and its
example, and fix the `revisit-outcome` description. Structural only in the sense that
§4.4's documented contract flips; no shipped instance changes shape.

### Finding 4: Derived population estimates are indistinguishable from direct ones

#### Scenario 5 — Different sources at different levels + carrying the ward-sum · **supported** · full

**TL;DR.** Different sources at different levels work (state census-projection / LGA GRID3 / ward microcensus). The requested check also works: Lokoja LGA carries its native GRID3 estimate (19,500) AND the sum of its ward microcensuses (18,200) as two separate sibling estimates at the same geography — the −6.7% divergence is read by direct comparison. Built and validated (`sc-pop-lokoja-sac-wardsum`).
**Note:** the derived estimate's origin ("sum of ward estimates") is recorded only in the source field's text; a coded derivation marker would be a trivial add.

> "I would think that we would want to enforce a rule that umbrellas and their children
> must share the same population estimate data source, but worth discussing." *(instruction:
> allow differing sources but ensure child estimates can be checked against parents)*

**Scenario.** Sources deliberately differ by level: Kogi State = census projection
(118,000 SAC), Lokoja LGA = GRID3 (19,500), its two wards = CDD microcensus (Felele
9,800 + Adankolo 8,400). The check: Lokoja carries a SECOND estimate alongside its
GRID3 number — the sum of its ward microcensuses (18,200), stored as its own
LGA-scoped estimate — so the parent-vs-children comparison is two numbers sitting at
the same geography, −6.7% apart.

**Instances.** `sc-pop-kogi-sac-censusproj`, `sc-pop-lokoja-sac-grid3`,
`sc-pop-lokoja-sac-wardsum` (the derived sum), `sc-pop-felele-sac-micro`,
`sc-pop-adankolo-sac-micro`.

**Evidence.** Both requested capabilities are demonstrated by validating instances.
Differing sources per level are the design working as intended — each estimate carries
its own source and date, nothing constrains the mix. The comparison capability rides
the same competing-estimates pattern as S17: an LGA geography holds the native GRID3
estimate and the derived ward-sum side by side, each with provenance
(`denominator-source = microcensus`, with the derivation stated in the source's text:
"Sum of ward-level CDD microcensus estimates: Felele (9,800) + Adankolo (8,400)").
Any consumer comparing estimates at one geography sees the divergence directly.

**The policy question, presented not decided.** Forcing one shared source up the
chain buys arithmetic coherence and loses the better local data (the microcensus is
more trustworthy than GRID3 where it exists). Allowing divergence — the current
design — keeps the best data at each level and treats parent-child divergence as
information; the derived ward-sum estimate is the mechanism that keeps that divergence
visible at the parent level.

**Recommendation (trivial).** The derived estimate's origin lives only in the source
field's free text. A coded way to say "derived by aggregation" — e.g. a
`derived-from` extension referencing the constituent estimates, or a
`derived-aggregate` code in `ICRDenominatorSourceCS` — would let queries distinguish
direct enumeration from roll-ups at the same geography.

### Finding 5: Household-to-community membership is inferred, not recorded

#### Scenario 6 — Drill-down: individual → household → community → Ward · **tension** · full

**TL;DR.** Person→household→ward is fully linked data. The "assigned to a community" hop is not — it's inferred by matching Locations, and breaks if a settlement has two community Groups.
**Fix:** assert membership (extension or relaxed Group member) or document the join's preconditions (small).

> "…and these households/communities/locations should be further broken down elsewhere
> in the schema, flagging this for follow up if not." *(instruction: view the treatment
> status of an individual assigned to a household assigned to a community assigned to a Ward)*

**Scenario.** Amina Bello: `sc-pzq-amina` (treated, 3 tablets, DOC) → subject
`sc-amina` → member of `sc-household-a12` → `group-location` → `sc-dwelling-a12` →
`partOf` → `sc-felele-central` (settlement) → `partOf` → `sc-felele-ward` → Lokoja LGA
→ Kogi → Nigeria. The community `sc-community-felele` sits at the settlement via its
own `group-location`.

**Evidence.** The person→household→**ward** chain is fully in-band and every link is a
real element — treatment status of Amina rolls up to her ward with no out-of-band
knowledge (each hop validated; joins: `MedicationAdministration.subject` →
`Group.member` reverse → `group-location` → `partOf`*). The reason for the tension
verdict is the middle of James's chain: **"assigned to a community" is never data.** The household↔
community relation is *inferred* — "the community Group whose `group-location` equals
the settlement my dwelling is `partOf`". That inference fails in ordinary cases:
two community Groups at one settlement (two campaigns each minting their own; a
settlement split into two CDD catchments) makes the join ambiguous; a community based
at a *community-distribution-point* Location (the profile's own alternative) breaks
the equality entirely. Nothing asserts membership, so nothing can contradict a wrong
guess. Amina also may belong to any number of household Groups (no constraint), which
cross-campaign merges will eventually produce.

**Recommendation (small).** Either document the Location-join as the normative
resolution *with its preconditions* (one community Group per settlement per campaign),
or add an optional `part-of-delivery-unit` extension on ICRDeliveryUnit
(`Reference(ICRDeliveryUnit)`) asserting household→community membership where
programmes track it. See S8 — the Group-in-Group finding makes a third option viable.

#### Scenario 7 — Community → household → person via Location `partOf` · **duplicate of S6** (model verdict) · full + R4 spec check

**TL;DR.** The model verdict is S6's finding (the community hop is inferred, not recorded) — counted once, there. S7's own contribution is the accuracy check it asked for: the described mechanism works, but the justification was wrong — R4 does allow Group-in-Group; excluding it is ICR's choice, not FHIR's.

> "Does this model support a community -> household -> person hierarchy?" *(instruction:
> evaluate the accuracy of Claude's quoted reply)*

**Scenario.** As built for S6: community `sc-community-felele` (at settlement) —
dwellings `partOf` the settlement — household Groups at dwellings — member Patients.
A community-scoped Task (`sc-task-community-felele`) acts on the community Group while
`sc-task-household-a12` acts on a household under it.

**Evaluation of the quoted reply (c62), claim by claim:**

| Claim | Verdict |
|---|---|
| Hierarchy expressed on the *where* axis, resolving settlement → dwelling → household Group → members | **Accurate** — demonstrated end-to-end by validated instances |
| Community-scoped Tasks and household delivery units coexist, joinable through dwellings | **Accurate** — both Tasks validate against the same world |
| "§5.1's 'Members are individuals, never sub-Groups' is the governing rule" | Accurate as a description of the profile (`member.entity only Reference(ICRPatient)`) |
| The rule is forced by FHIR — companion claim c66: "R4 `Group.member.entity` cannot reference another Group at all (group-in-group membership only arrives in R5)" | **False.** Official R4 StructureDefinition: `Group.member.entity` targets = Patient \| Practitioner \| PractitionerRole \| Device \| Medication \| Substance \| **Group**. Probe `probe-group-in-group-base` (plain R4 Group with a Group member) passes validation. |

So the mechanism works as described, but its justification is wrong: excluding
sub-Groups is an ICR profiling decision that R4 does not require. The model verdict
here is S6's finding, not a new one — the hierarchy is *derivable*, with the
community→household hop unrecorded — and it is graded once, under S6. S7's distinct
contribution is the accuracy evaluation above; an incorrect rationale in a review
reply is a record correction, not a data-model defect, so S7 adds no tension of its
own to the tally.

**Recommendation (trivial + small).** Correct the c66-derived rationale wherever it
reached the prose; then decide the S8 question on merits (below) rather than on
mistaken mechanics.

#### Scenario 8 — Households vs communities: profiles, resources, and nesting · **tension** · full + R4 spec check

**TL;DR.** They are the same resource type and same profile, differing by one code — "different resources" was wrong, and the R4 claim was wrong. Household→community membership is currently inference-only.
**Fix:** decide deliberately: allow Group members, add a memberOf extension, or canonize the Location join (small).

> "…having two separate profiles I believe would make it easier to nest households
> under communities." — mberg: "These are different resorces" *(instruction: establish
> what's actually true; can household→community membership be tracked?)*

**What is actually true, from the FSH and instances:**

1. **Households and communities are the SAME resource type (Group) and the SAME
   profile (`ICRDeliveryUnit`)**, distinguished only by the required `code`
   (`household` | `community` | `school-cohort`). `sc-household-a12` and
   `sc-community-felele` differ in one coded field. The doc's original claim (one
   profile, coded kind) is what ships; **mberg's "these are different resources" is
   incorrect** in FHIR terms — they are different *instances* of one resource type
   and profile.
2. **Claude's supporting FHIR-mechanics claim is false** (see S7): R4
   `Group.member.entity` *can* reference a Group. Nesting a household Group inside a
   community Group is base-R4-legal today; it is the ICR profile that forbids it
   (`member.entity only Reference(ICRPatient)`). Probes: the base-R4 shape passes;
   the profile-claiming shape is non-conformant per the compiled SD (the validator
   misses it only because it cannot type-check unresolved references — stated in the
   methods note).
3. **Household→community membership is currently trackable only by inference** (the
   S6/S7 Location join), with the failure modes listed there.

So James's skepticism was warranted on both counts: the "different resources" answer
was wrong, and the "R5-only" answer was wrong. What remains is a real design decision,
now correctly framed: ICR *could* allow `community` delivery units to list member
household Groups (R4-legal; one profile relaxation), or add an explicit `part-of-
delivery-unit` extension, or canonize the Location join. Two *profiles* were never
needed for any of these — that part of the original design holds.

**Recommendation (small).** Decide explicitly: (a) relax `member.entity` to
`Reference(ICRPatient or ICRDeliveryUnit)` with an invariant (household members only
under community-coded Groups) — most direct, cost: consumer complexity on `member`;
(b) `part-of-delivery-unit` extension — additive, keeps member lists person-only; or
(c) document the Location join + its preconditions as normative. Correct the record on
(1) and (2) in the prose either way (trivial).

### Finding 6: “Real-time” is the wrong name for the raw data stream

#### Scenario 9 — Real-time vs reconciled, with concrete examples · **tension** · full

**TL;DR.** Definition is clean: same structure, `dataLineage` flag, absent = realtime. But the shipped Measures make stratifiers mandatory, so a lightweight realtime report is non-conformant; and delivery events carry no lineage at all.
**Fix:** drop the stratifier declarations from the Measures or ship realtime variants (small).

> "I have a colloquial understanding of what real-time vs reconciled means but
> technically it's not clear to me."

**Scenario.** The same Kogi round quantity, twice: `sc-cov-round-realtime` (campaign
nights, numerator 15,900 from same-day CDD phone submissions, feeds the dashboard) and
`sc-cov-round-reconciled` (close-out: duplicate register rows removed, late paper
tallies added → 15,200, the figure exported to ESPEN). Below them,
`sc-task-community-felele` is a realtime-flagged Task (live submission) and
`sc-task-household-a12` a reconciled one (corrected after register reconciliation).

**Evidence.** The *definition* is crisp and demonstrable: same structure, two records,
`dataLineage` is the only discriminator; "final figures only" = filter `reconciled`;
absent ⇒ realtime. The tension verdict rests on three problems, two of them
found only because the instances went through the full validator:

1. **The realtime stream is non-conformant as designed.** The shipped Measures declare
   sex/age-band/disposition stratifiers, and the HL7 validator requires every declared
   stratifier on every report. A campaign-night quick figure without strata **fails**
   (`probe-report-realtime-unstratified`: *The MeasureReport does not include a
   stratifier for … #sex / #age-band / #disposition*). The committed realtime instance
   had to carry full disaggregation on night one to validate — exactly what a
   realtime stream doesn't have. The prose's claim that stratifiers are "illustrated,
   not mandated" (§7.3) is false under full validation.
2. **Delivery events have no lineage.** `dataLineage` sits on CarePlan/Task/
   MeasureReport only; an event's stream membership is derived by reverse-joining
   through whichever Task's `output` references it — fragile, and undefined for
   standalone events (which §5.1 explicitly allows).
3. Absent ⇒ realtime is documentation, not structure; a store cannot distinguish
   "realtime by default" from "lineage never assessed".

**Recommendation (small).** Ship realtime variants of the Measures without declared
stratifiers (or remove stratifier declarations and keep them as guidance — decide
against the validator, not the prose); document the event-lineage derivation rule;
consider making `dataLineage` 1..1 on Task for pilot data.

### Finding 7: Refusals are complete at visit level but undefined at person level

#### Scenario 10 — Vaccine refusal with reason · **tension** · full

**TL;DR.** The IG explicitly addresses refusals at visit level: a Task refusal-reason extension with a dedicated code system (`safety-concern` matches this exact scenario) plus a `refused` disposition in the coverage cube. The tension is per-person: §4.4 itself says per-person reasons require person-level records, but the IG defines no person-level refusal record — `Immunization.status=not-done` validates and works, yet exists only in a review-comment reply, with no reason binding. The Task route also cannot record who refused, or counts per reason.
**Fix:** document the person-level not-done pattern with a statusReason binding and a precedence rule (small).

> "How are refusals tracked under this system? Would we just record a
> `ICRImmunizationEvent` and make sure there is a field that indicates it was a
> refusal rather than a treatment?"

**Scenario (Satellite C).** MR SIA house-to-house visit at household G07; Zainab's
caregiver refuses, reason "concerned about negative side effects". Both IG mechanisms
built: (a) visit-level — the Task carries `noncompliance-reason = safety-concern`
(the code's definition, "Fear of AEFI or medicine side effects", matches the stated
reason exactly); (b) person-level — an `ICRImmunizationEvent` with
`status = not-done` + `statusReason` coded `safety-concern` with text.

**Instances.** `sc-task-mr-house-visit`, `sc-mcv-refusal`, `sc-zainab`.

**Evidence.** The IG addresses refusals explicitly at visit level — the
`noncompliance-reason` extension, its dedicated refusal-reason code system, and the
`refused` disposition in the coverage cube are all documented prose-and-FSH features,
and `safety-concern` matches this scenario's stated reason exactly. James's underlying
need (refusal + reason, queryable) is therefore *reachable*, which is why this is not
`breaks`. The gap is per-person, and §4.4 itself concedes the premise: "Task-level
`missed-reason`/`noncompliance-reason` aggregate over the whole visit, so per-person
reasons require person-level records" — while the IG defines no person-level refusal
record (a refusal produces no dose, so no Immunization exists to carry the reason). But it holds only through unenforced convention,
three ways: (1) Reply c46 says a refusal "is deliberately NOT an ICRImmunizationEvent"
— yet the profile has no constraint on `status`, so `sc-mcv-refusal` **validates as an
ICRImmunizationEvent** (full validator: Success). The design intent exists only in a
comment thread; the model neither enforces nor documents it. (2) The mainline
(Task-side) mechanism cannot answer *who* refused or count reasons: `noncompliance-
reason` is 0..* codes with no person link and no per-reason count — two refusals for
different reasons in one visit are two bare codes. (3) At person level, `statusReason`
is a base element with an *example* binding; using `ICRNoncomplianceReasonCS` there is
this exercise's invention, not the IG's rule — two implementations will code refusals
differently, and if a country records both the Task reason and the not-done event,
nothing prevents double-counting refusals in the §7.3 disposition cube.

**Recommendation (small).** Document the person-level refusal pattern in §6.1
(status=not-done + statusReason bound extensible to ICRNoncomplianceReasonVS), state
the precedence rule between it and the Task-side reason (count refusals from Tasks
unless person-level records exist — mirroring the aggregate-vs-individual rule), and
either enforce or drop the "delivery events are things that happened" doctrine.

### Finding 8: Person-level fields lose their meaning on group-level records

#### Scenario 11 — Group administration: partial swallowing and `directlyObserved` · **tension** · full

**TL;DR.** `directlyObserved=true` on a Group record can only mean "protocol applied" — it can't say who swallowed. The partial count has no conformant representation: no DOC stratifier code exists and a locally added stratifier fails validation.
**Fix:** add a `doc-observed` stratifier code; define Group-scale field semantics (small).

> "What does directlyObserved track in a group setting? What is recorded if the
> reporter sees some individuals swallow the medication but not all members of the group?"

**Scenario.** Felele-Central register-level administration
(`sc-medadmin-community-felele`, subject = community Group, `directlyObserved = true`):
of 312 treated, 305 were observed swallowing and 7 were dosed but not observed. Kemi
spat her tablets out — recorded person-level as `sc-pzq-kemi-notdone`
(`status = not-done`, reason text). The 305/7 split rides the tally.

**Evidence — James's question has no first-class answer; every route bends something:**

1. `directlyObserved = true` on a Group administration can only mean "the DOC protocol
   was applied to this administration" (the §6.2 open design note's proposal). It
   cannot say who, or how many, actually swallowed — the boolean's person-level
   meaning silently degrades at Group scale, and nothing in the *profile* (as opposed
   to a prose note marked "to be confirmed") defines which meaning was intended.
2. The partial count's designated home — "a DOC-observed stratum" per reply c77 —
   **does not exist and cannot be added by an implementer**: `ICRCoverageStratifierCS`
   has no DOC axis, and a locally-coded stratifier on a report fails full validation
   (`probe-tally-doc-stratifier`: *The code for this group stratifier has no match in
   the measure definition*). The committed tally therefore records the split as
   additional `disposition` sub-strata ("treated — swallowed under observation" 305 /
   "treated — dispensed, not observed" 7), which extends "disposition" beyond its
   defined meaning.
3. Base constraint `mad-1` forces `dosage.dose` on the Group administration; the only
   coherent value is the *total* dispensed (650 tablets) — so the same element means
   "dose given to the subject" on person records and "sum over everyone" on Group
   records. (The shipped `example-albendazole-administration` fails `mad-1` outright —
   cross-cutting.)
4. The person-level fallback (`sc-pzq-kemi-notdone`) works and validates, but only for
   enumerated individuals — the common register-level case has no person to hang it on.

**Recommendation (small).** Add a `doc-observed` code to `ICRCoverageStratifierCS` and
declare it on `icr-mda-treatment-coverage`; promote the "protocol-applied" Group-scale
semantics from open note to profile documentation on `directly-observed-consumption`;
define `dosage` semantics for Group subjects (total-dispensed) in §6.2.

### Finding 9: Supporting supply chain work must claim a delivery strategy it doesn't have

#### Scenario 12 — Supporting activity: "Delivered drugs to district staging location" · **tension** · full

**TL;DR.** The activity is definable, but the Task's required delivery-strategy field is limited to seven population-facing options, none of which describes drug transport; the test instance records `#mobile` as the least-wrong value.
**Fix:** expand the delivery-strategy option set (e.g. add a `logistics` code) (trivial).

> "I take it this would also include supporting activities such as 'Delivered drugs to
> district staging location.' Though the interventions listed next to `code` don't seem
> to include this kind of activity."

**Scenario.** The state store positions 120,000 PZQ tablets at the Lokoja LGA staging
store. Modeled as a `sc-logistics-activity` (ActivityDefinition, `code.text = "Deliver
drugs to district staging location"`), a Task acting on the staging-store Location,
and the `sc-supply-state-to-lokoja` receipt as `Task.output`.

**Instances.** `sc-logistics-activity`, `sc-task-logistics-leg`, `sc-supply-state-to-lokoja`.

**Evidence.** James's reading is right on both halves. The activity `code` is unbound,
so a logistics work type is definable (reply c45 accurate). The limitation is on the
Task: `delivery-strategy` is 1..1 with a **required** binding to seven
population-facing modes (fixed-post, house-to-house, CDD…). A drug-transport task
matches none of them. `probe-task-no-strategy` (the honest shape, no strategy) fails:
`Task.extension: minimum required = 2, but only found 1 … Slice
'Task.extension:deliveryStrategy' … a matching slice is required, but not found`.
The committed instance records `#mobile` as the least-wrong value; this is inaccurate
data, and it will distort any analytics segmented by delivery strategy — the axis
dashboards commonly filter on. Reply c45's deferral ("worth settling — flagging for
§13.4") never landed anywhere in the FSH.

**Recommendation (trivial).** Add a `logistics` (or `support-activity`) code to
`ICRDeliveryStrategyCS` — or, cleaner but small: introduce the proposed
`activity-type` axis and make `delivery-strategy` conditional on delivery-facing
activity types. Either unblocks honest logistics Tasks.

### Finding 10: The stock ledger cannot balance at any node that ships stock onward

#### Scenario 13 — Supply-chain sweep · **breaks** · full

**TL;DR.** Transfers, returns, last-mile handovers, and person-receivers all work. But the ledger identity gives a wrong answer at every mid-chain node (no transferred-out field: 120,000 received, extension sums to 18,000). Also missing: origin node, lot/expiry on stock, shipped-vs-received quantities.
**Fix:** add `transferredOut`, `lot`, `expiry` to stock-accountability + an `origin` Location extension (small).

> "Would `used` track product being issued from 1 warehouse to another as well as a
> distribution to a household?" + the delivery-level flag *(instruction: generate the
> full range of events; enumerate significant events the model does NOT support)*

**Scenario — seven custody events across the chain, all validating:**

| Event | Instance | Ledger |
|---|---|---|
| National → state store (600,000 PZQ) | `sc-supply-national-to-state` | — |
| State → LGA staging (120,000) — the S12 leg | `sc-supply-state-to-lokoja` | received 120,000 / used 0 / remaining 13,000 / notUsable 1,000 / returned 4,000 |
| LGA → ward health post (24,000, onward issue) | `sc-supply-lokoja-to-post` | — |
| Post → CDD (800; receiver is a *person*) | `sc-supply-post-to-cdd` | received 800 / used 650 / remaining 140 / notUsable 10 → **balances** |
| Return leg: LGA → state (4,000 near-expiry) | `sc-supply-return-to-state` | — |
| ITN upstream: LGA store → post (5,000 nets) | `sc-itn-post-delivery` | — |
| ITN last-mile: post → household A12 (2 nets) | `sc-itn-household-handover` | — |

**What works (and answers the c79 question):** `used` = consumed at that node — correct
at terminal nodes (the CDD's 800 = 650+140+10 reconciles); onward issues and returns
are indeed their own SupplyDeliveries; a person-receiver rides `receiver` (base
element) since `destination` is Location-only; last-mile vs upstream is expressible on
one resource type, distinguishable — but only heuristically, by the destination's type
(the c78 `delivery-level` axis remains unbuilt).

**Why `breaks`: the reconciliation identity gives a wrong answer at every non-terminal
node.** c79's rule — "a node's ledger reconciles as received = used + remaining +
notUsable + returned" (now §6.3 prose) — fails wherever stock moves onward, which is
*every node except the last*: at Lokoja staging, 120,000 received vs 0 + 13,000 +
1,000 + 4,000 = 18,000. The 102,000 issued onward has **no field**; the extension
cannot state it, so a conformant consumer computing the documented identity concludes
the node lost 102,000 tablets (`concordant = false` on a physically concordant store).
Recovering the truth requires aggregating *other resources* (all outbound
SupplyDeliveries whose supplier-string matches this node — and supplier is a
Practitioner/Organization reference or display, while nodes are modeled as Locations,
so there is not even a typed join from a node's Location to its outbound legs).

**Significant supply-chain events the model does not support** (considered from a
supply-chain perspective rather than from what the model happens to offer):

1. **Onward-transfer quantity in the ledger** — the `breaks` above.
2. **Origin of a transfer.** SupplyDelivery has no source-Location element;
   "from where" is a display string on `supplier` (a party, not a place). Chain
   reconstruction by query is impossible without naming conventions.
3. **Lot/batch and expiry on stock movements.** No slot on the event or the
   extension; the S16 expiring-lot story — the round's entire premise — cannot name
   its lot. (Base `itemReference → Medication.batch` survives unprofiled; see S14.)
4. **Shipped vs received / in-transit loss.** One `suppliedItem.quantity` per event,
   semantics (dispatched? received?) undefined; a 120,000-dispatched/119,200-received
   discrepancy — the classic supply-chain signal — has no representation. `status =
   abandoned` exists but carries no quantities.
5. **Orders/requisitions and fulfillment** — `basedOn` targets SupplyRequest, which
   the IG deliberately leaves out (scope decision, fairly documented in c78; noted,
   not counted against the model).
6. **Stock-on-hand snapshots** — accountability exists only as an appendage of a
   transfer event; "how much does Lokoja hold today" requires replaying all history.
7. **Quarantine/recall of a lot** — follows from 3; unrepresentable.
8. **Cold-chain excursions** beyond a vaccine `vvmStage` integer.

**Recommendation (small, targeted — not an LMIS).** Add `transferredOut 0..1 Quantity`,
`lot 0..1 string`, `expiry 0..1 date` to the stock-accountability extension, and an
`origin 0..1 Reference(ICRLocation)` extension on ICRSupplyDelivery; define
`suppliedItem.quantity` as *received at destination*. That fixes 1–4 for campaign
accountability while keeping LMIS territory (5–8) explicitly out of scope, and it
makes c78's `delivery-level` axis cheap to add at the same time.

### Finding 11: Drug lots cannot be identified anywhere in the model

#### Scenario 14 — Lot expiration date alongside lotNumber · **supported** (vaccine arm) · full

**TL;DR.** `Immunization.expirationDate` exists, is MS, and validates next to `lotNumber`.
**Gap:** the drug arm has no lot/expiry slot anywhere — the MDA world's expiring lot is free text only (small fix: lot+expiry on stock-accountability).

> "Should we also include the lot's expiration date? Technically we should be able to
> look this up based on the lotNumber, but I'm just used to seeing the expiration date
> and lotNumber reported side by side."

**Scenario.** `sc-mcv-dose-ok` (MR dose to Tunde): `lotNumber = "MR-KJ-2026-118"` and
`expirationDate = 2027-03-31` side by side, exactly as field forms report them.

**Evidence.** Reply c75's asserted resolution is proven: base R4
`Immunization.expirationDate` exists, the profile flags it MS (landed in v0.1 as the
c89 changelog says), and the instance passes full validation. The comment, attached to
the Immunization row, is answered: **yes.** One significant adjacent gap, discovered
because the core world is an MDA with an *expiring drug lot* (S16): **the drug arm has
no lot/expiry slot anywhere.** R4 `MedicationAdministration` has no `lotNumber`
element; batch data lives on a referenced `Medication` resource, but
`ICRMedicationAdministration` constrains `medication[x]` to CodeableConcept only —
profiling the `medicationReference` path *out*. On the supply side, neither
`ICRSupplyDelivery` nor the stock-accountability extension carries lot or expiry
(`suppliedItem.itemReference → Medication.batch` survives in base but is unprofiled
and un-exampled). The S16 round's "PZQ lot expires 2026-08-31" exists only as free
text in a note. Filed as a recommendation here and in S13 rather than downgrading the
verdict, since the comment's own question was the vaccine row.

**Recommendation (small).** Add `lot` + `expiry` subfields to the stock-accountability
extension (drug/commodity lots live on supply events, as c75 itself suggested), or
re-open `medicationReference` with a profiled Medication carrying `batch`.

### Scenarios that cleared validation without findings

#### Scenario 15 — School-based SCH distribution · **supported** · full

**TL;DR.** Works as-is: `school` strategy + `school-cohort` Group + session Task + person-level dose all validate.

> "NTD campaigns are sometimes based out of schools under the logic that students can
> be treated during a regular school day. I believe this would count as Type A, but
> worth confirming there isn't any special nuance behind them worth considering."

**Scenario.** SCH MDA day 2 runs as a session at Felele Model Primary School: the
enrolled pupils are a `school-cohort` ICRDeliveryUnit based at the school Location;
one Type-A session Task acts on the cohort; Tunde (10) receives dose-pole-banded
praziquantel as a person-level event off `Task.output`.

**Instances.** `sc-felele-school`, `sc-school-cohort-felele`, `sc-task-school-session`,
`sc-pzq-tunde`.

**Evidence.** Type A confirmed — the IG carries every needed piece natively: `school`
delivery strategy, `school` location type, `school-cohort` group kind. The claimed
nuance in reply c44 (cohort roster = cleaner denominator) holds: the cohort Group's
`quantity` (640 enrolled) is a real, listable denominator, unlike walk-in posts.
Query: "doses delivered school-based" = Tasks with `delivery-strategy = school` →
`output` → MedicationAdministrations; "which pupils" = cohort `member` roster.
Two genuine nuances, neither blocking: (a) the profile allows the session Task's
target to be *either* the school Location (per the Type-A comment in the profile) or
the cohort Group — both validate, and the IG gives no rule, so two implementers will
disagree; (b) non-enrolled catch-up children fall outside the cohort and ride as bare
event subjects, which the IG explicitly supports (§5.1).

**Recommendation (hygiene, trivial).** One sentence in §4.4/§5.1: school-based session
Tasks SHOULD target the cohort Group when a roster exists, the school Location otherwise.

#### Scenario 16 — Round deviates from the standard protocol · **supported** · full

**TL;DR.** The descope (SAC-only vs protocol's "everyone 2+") is fully representable; deviation is visible by comparing round subject vs protocol subject.
**Nice-to-have:** a coded deviation-reason; today the "why" is free text (trivial).

> "How does this approach handle cases where a program has to deviate from the SOP for
> a particular campaign? … a country's policy for SCH might be to treat the entire
> population over 2, but for one distribution they might only target school-aged children."

**Scenario.** Exactly James's case, on the core world: `sc-sch-protocol` states the
SOP (`subjectCodeableConcept.text` = entire population ≥2y); the PZQ lot expires
2026-08-31 and covers only SAC, so `sc-kogi-round.subject` is the narrower
SAC-footprint denominator, with the geography also narrowed (two wards). The deviation
is visible by comparing the round's `subject` against the protocol's subject template;
the *why* is captured in `CarePlan.note`.

**Instances.** `sc-sch-protocol`, `sc-pop-footprint-sac`, `sc-kogi-round`
(plus the shipped v0.1 descoping trio, which this replays at larger scale).

**Evidence.** The protocol/execution split does the work claimed in c47: no protocol
fork, geography deviations free, and the mberg-approved (c88) worked example already
ships. Query: "rounds that deviated from protocol" = compare each round's subject
characteristics against its protocol's `subject[x]` — answerable, though it is a
*comparison*, not a flag. Two honest caveats, neither verdict-changing: the
deviation *reason* has no coded slot (free-text note only — you cannot query "rounds
descoped for supply reasons"); and the protocol's subject template is itself free text,
so the comparison is human-readable rather than computable.

**Recommendation (trivial).** A `descope-reason` (or `deviation-reason`) coded
extension on ICRCampaign (supply-shortfall | expiring-stock | security | funding |
other) would make deviation analytics a query. Longer term, a computable protocol
`subject` (age-range characteristics) makes the planned-vs-targeted diff mechanical.

#### Scenario 17 — Three sources for SAC, each with its Total Population · **supported** · full

**TL;DR.** Six sibling Groups, per-source provenance, `at-risk` vs `total-population` axis. Pairing SAC↔total is a (source, geography, date) group-by.

> "Does this allow us to track Total Population in the same place? … it would be
> greatly enriched if it included each source's estimate of the total population as well."

**Scenario.** Kogi State carries six sibling ICRTargetPopulation Groups: SAC 5–14 and
total population from census-projection (118,000 / 3,595,000), GRID3 (126,500 /
3,830,000), and HMIS (109,000 / 3,310,000) — same geography, per-source provenance
and dates, `denominator-type` separating `at-risk` from `total-population`, exactly
one SAC estimate flagged planning.

**Instances.** `sc-pop-kogi-sac-censusproj`, `sc-pop-kogi-total-censusproj`,
`sc-pop-kogi-sac-grid3`, `sc-pop-kogi-total-grid3`, `sc-pop-kogi-sac-hmis`,
`sc-pop-kogi-total-hmis`.

**Evidence.** Reply c48's claim is proven by instances. The analytical question —
"give me each source's SAC estimate with that source's total" — is a natural group-by:
`Group WHERE characteristic[geography] = Kogi GROUP BY denominator-source`, pairing
`at-risk` with `total-population` rows. All six validate. One caveat: the
SAC↔total pairing is by matching `(source, geography, estimate-date)` — nothing
*links* the pair, so a source publishing two vintages must keep dates straight or the
join picks the wrong total. That is a data-hygiene convention, but a natural one, and
no information is lost — hence supported, not tension.

**Recommendation (trivial).** Note the (source, geography, date) pairing convention in
§5.2; consider the already-proposed source-raster version/date extension, which would
make the pairing key explicit.

#### Scenario 18 — "Per-house insecticide quantity rides Task.output" · **supported** · full

**TL;DR.** Meaning, illustrated: the activity says sachets-per-structure in principle; each spray Task's `output` records what THIS house consumed (2 sachets, 4 rooms).

> *(James: "I don't understand what 'per-house insecticide quantity rides Task.output'
> means, use the scenario to illustrate this point.")*

**Scenario (Satellite A).** IRS at compound G07, which has two eligible structures
(main building, kitchen outbuilding). Each structure gets its own Task — the Task *is*
the spray event (no delivery-event resource exists for "treat a place", §6.4). On each
Task, `output` carries the per-structure results as typed entries: spray status
("sprayed"), **insecticide used (2 sachets / 1 sachet)** — this is the sentence's
meaning — and rooms sprayed (4 / 1).

**Instances.** `sc-structure-g07-main`, `sc-structure-g07-kitchen`,
`sc-task-spray-main`, `sc-task-spray-kitchen`, `sc-irs-spray-activity` (whose `dosage`
now reads units-per-structure, per the c57 commitment).

**Evidence.** Plainly: the ActivityDefinition says *how much per structure in
principle* ("1 sachet per 250 m²"); what THIS house actually consumed is recorded as a
`Task.output` entry (`valueQuantity` 2 `{sachet}`) on that house's Task. Both Tasks
validate; "total sachets used in Geregu ward" = sum of `output` quantities over spray
Tasks at Locations under the ward. Caveat (not verdict-changing, feeds S2 and the
cross-cutting notes): `output.type` is free text — `"Insecticide used"` vs
`"Sachets consumed"` are different strings, so the roll-up depends on text discipline.

**Recommendation (trivial).** A small coded CS for IRS output types (spray-status /
insecticide-used / rooms-sprayed / surface-area) — or fold into the proposed
`ICRStructureTreatment` event when it lands.

#### Scenario 19 — People treated AND tablets dispensed, one distributor · **supported** · full

**TL;DR.** Both counts, one Task, two homes: people → tally/MedicationAdministration; tablets → stock-accountability. The promised prose rewrite did land (§4.8).

> "I can see a case where distributors are expected to capture both the number of
> people treated AND the count of tablets dispensed. I think it's better to resolve
> this ambiguity by checking the type of Activity/Task." *(instruction: check whether
> the promised rewrite happened; count both in the scenario)*

**Scenario.** CDD Mariam Adamu, Felele-Central, both counts on one community Task:
`output[0]` = 312 persons treated (people count → treatment home), `output[1]` → the
register-level Group-subject MedicationAdministration, `output[2]` → her tablet ledger
(`sc-supply-post-to-cdd`: received 800, used 650, remaining 140, notUsable 10 —
**balances**, as a terminal node should), `output[3]` → the stratified tally.

**Instances.** `sc-task-community-felele`, `sc-medadmin-community-felele`,
`sc-supply-post-to-cdd`, `sc-tally-felele`.

**Evidence.** (1) **The rewrite happened**: prose §4.8 (v0.28) now reads "The decision
rule anchors on the Task's activity, not on the unit of the count… a distributor
capturing *both* records both, on those two homes respectively", with the units
phrasing demoted to a mnemonic — precisely what James asked for and c64 promised.
(2) The dual capture works cleanly and validates: the two counts live on different
resources with different semantics off one Task, no overloading. Queries: people
treated = tally/MedAdmin side; tablets = stock-accountability side; the 650-used vs
312-treated ratio (≈2.1 tablets/person) is even a plausibility check the model makes
possible. Caveat carried to cross-cutting: the rule branches on "the type of
Activity/Task", but `ActivityDefinition.code` and `Task.code` are unbound free text —
so the branch a *pipeline* must take is keyed on strings; a coded activity axis
(same fix as S12) would make the James-rule machine-checkable.

#### Scenario 20 — Same Location, different types per campaign · **supported** · full

**TL;DR.** `Location.type` is 0..*; the school carries `school` + `community-distribution-point` and validates. Confirmed.

> "How do we handle the same location having multiple types depending on the campaign?
> For example … a `school` but in another it could be a `community-distribution-point`."

**Scenario.** `sc-felele-school` carries **both** `type` codings (`school`,
`community-distribution-point`). The SCH world uses it as a school
(`sc-task-school-session`, strategy `school`); the MR SIA uses it as a vaccination
site (`sc-mcv-dose-ok.location`).

**Evidence.** Reply c73's asserted resolution is proven, not just asserted: base
`Location.type` is 0..* (confirmed on the R4 SD), the profile keeps it repeatable with
an extensible binding, and the dual-typed instance passes full validation. Queries
from both campaigns' viewpoints work: "all schools" and "all distribution points" both
match this Location. The known residual (as c73 itself noted) is that `type` is
timeless — the campaign-scoped role ("distribution point *during the MR SIA only*")
either stays as a standing second type or becomes a separate `temporary-post` Location
at the same GPS with its own lifecycle and `delivery-strategy`. Both patterns are
available; the IG should say when to use which. GERS identity keeps the two joined if
the second pattern is chosen.

**Recommendation (trivial).** The §5.3 sentence c73 promised ("intrinsic type vs
campaign role") with the two patterns named.

#### Scenario 21 — Target geography: wards from different LGAs · **supported** · full

**TL;DR.** `target-geography` lists wards from different LGAs directly; validates. Denominator scoping needs a minted footprint Location (works, should be documented).

> "We've supported campaigns where the target geography was a subset of Wards
> belonging to different LGAs. I'm leaving this comment as a reminder to confirm that
> this setup supports this scenario."

**Scenario.** `sc-kogi-round.targetGeography` = [Felele Ward (Lokoja LGA), Geregu Ward
(Ajaokuta LGA)] — two wards, two different parents, listed directly. The round's
denominator is scoped to exactly that footprint via a minted operational-area Location
(`sc-target-footprint`, overlaying both wards) referenced by
`sc-pop-footprint-sac.characteristic[geography]`.

**Evidence.** Reply c86's claim is proven by validated instances: `target-geography`
is 0..* `Reference(ICRLocation)` with no shared-parent or same-level requirement, and
roll-ups follow each ward's own `partOf` chain into its own LGA. Two conventions were
needed, both workable and worth documenting: (1) the *denominator* side cannot list
two Locations (`characteristic[geography]` is 0..1), so the cross-LGA footprint needs
either per-ward sibling estimates (also built: `sc-pop-felele-sac-micro`) or a minted
footprint Location — the operational-area type plus `overlays-admin-unit` fits this
exactly, but nothing tells an implementer to do it; (2) LGA-level coverage roll-ups
must scope to the targeted wards, not the whole LGA — Lokoja's denominator (19,500)
includes untargeted Adankolo (8,400), so naive LGA coverage under-reports by
construction. Neither is information loss; both are query discipline. Supported.

**Recommendation (trivial).** Document the footprint pattern (mint an operational-area
Location for a cross-cutting target set; scope the planning denominator to it) in
§4.2/§5.2, and warn that admin-level roll-ups over partial targeting must use
targeted-geography denominators.

---

## Validation methodology

**Sources under test.** All findings compare a single snapshot: commit `d8cdacc` on
the repository's `main` branch, from which the `scenario-validation` working branch
was cut. That commit contains the Implementation Guide source (`ig/input/fsh/`,
package `unicef.fhir.icr` version 0.1.0, FHIR R4 4.0.1) and the prose companion
document (`project/icr-ig.md`, v0.28.1, last modified 2026-07-27). Every
"documentation vs implementation" finding compares that version of the prose against
the profiles compiled from the FSH it describes — same commit, both sides.

**Approach.** The 21 review concerns were tested by construction, not argument: one
integrated campaign world — a Nigeria schistosomiasis MDA umbrella campaign with a
Kogi State round, plus IRS, ITN-distribution, and measles-rubella satellite
campaigns — built as 89 FHIR resource instances (`sc-*` ids, in
`ig/input/fsh/examples-scenarios.fsh` on the `scenario-validation` branch). An
integrated world was chosen over isolated per-concern examples deliberately:
limitations tend to hide at the intersections (population provenance × admin
hierarchy × task granularity), and a shared world forces those intersections to
exist. The world spans a six-level administrative hierarchy, three population data
sources at four levels, a five-node drug supply chain, school-based and
community-directed delivery, supervisory areas in three configurations, and both
data streams.

**Verdict rubric.** Each concern was graded: *supported* — representable as
designed, instances validate, and the analytical question behind the concern is
answerable from the data without unenforced conventions; *tension* — representable,
but only by overloading semantics, relying on unenforced conventions, losing
information, or where the documentation and the implementation disagree; *breaks* —
not representable without violating a constraint, or the best available
representation gives a wrong or ambiguous answer to the concern's core question.

**Toolchain.** Two levels of checking, both applied to every instance:

1. **SUSHI 3.20.0** (the FSH compiler): the full IG including the scenario instances
   compiles with 0 errors, 0 warnings.
2. **The official HL7 validator** (`validator_cli`, current release, run against the
   compiled profiles with `-version 4.0.1 -ig fsh-generated/resources -tx n/a`):
   all 89 instances pass. This is the same validation engine embedded in the FHIR
   IG Publisher; no custom rules were added — the IG's own compiled profiles plus
   base FHIR R4 are the entire rule set.

**Negative testing.** Claims that the model *rejects* something are backed by
probes: deliberately non-conformant instances run through the same validator, with
their output captured. Claims that the model *fails to reject* something (the
unenforced-constraints finding) are likewise probe-backed. The probe files, the
validator logs for probes, scenario instances, and shipped examples, and re-run
instructions are preserved in `project/scenario-validation-evidence/`.

**Known limits of the validation, and how they were handled.** Two limitations of
the validator configuration shape what "passes validation" can prove:

- *Reference target types are not checked for unresolved references.* A Task whose
  `focus` points at a CarePlan passes the validator even though the compiled profile
  forbids it. Wherever a finding depends on reference-target rules, the claim was
  verified by direct inspection of the compiled StructureDefinition instead, and the
  finding says so ("SD-inspection"). This limitation is itself operationally
  relevant: profile reference-type "enforcement" only holds on servers configured to
  resolve and validate reference targets.
- *No terminology server* (`-tx n/a`): the presence of required bindings is
  validated, but deep code-membership in external systems (CVX, ATC) is not.

**Independent verification of FHIR claims.** Where findings assert what base FHIR
R4 does or does not allow (for example, that `Group.member.entity` may reference
another Group), the claims were verified against the official R4
StructureDefinitions published at hl7.org — not against secondary descriptions or
prior review discussion.

**Reproduction.** Check out the `scenario-validation` branch; run `sushi .` in
`ig/`; run the HL7 validator with the command recorded in `project/scenario-validation-evidence/README.md`. One
scenario (IRS task volume) is an order-of-magnitude analysis by design and produced
no instances; every other verdict is re-derivable from the committed artifacts.
