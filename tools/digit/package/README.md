# icr-digit: the DIGIT import as an import package

The DIGIT HCM → ICR mapping as a `fhir-pipes import` package: logical models of the DIGIT
records, FML maps, ViewDefinitions and SQLQuery Libraries. It is a port of
`../transform/transform.py`, done in parts. This first part covers **boundaries** and
**facilities**: on the demo tenant's export it writes the same Locations and Organizations as
`transform.py`, apart from the differences listed in `known-differences.toml`.

It needs a fhir-pipes with `[records]`, `[maps]` and `[views]` in `import.toml` (branch
`feat/import-lenient-records`), and the `duckdb` command.

## Record types

`fhir-pipes import run --in` reads one file per record type, named after the type. Until a
connector writes these names, make a folder of links to the files `extract.py` and
`extract_ref.py` write:

| DIGIT export file | Record type | Model | Read by |
| --- | --- | --- | --- |
| `boundary_tree.ndjson` | `DIGITBoundaryTree` | `models/StructureDefinition-DIGITBoundaryTree.json` | the map `DIGITBoundaryTreeToICR`, the view `Boundary` |
| `facility.ndjson` | `DIGITFacility` | `models/StructureDefinition-DIGITFacility.json` | the view `Facility` |
| `boundary_hierarchy.ndjson` | `DIGITBoundaryHierarchy` | not yet | (`transform.py` does not read it either) |
| `product.ndjson`, `product_variant.ndjson` | `DIGITProduct`, `DIGITProductVariant` | not yet | |
| `mdms_project_type.ndjson` | `DIGITProjectType` | not yet | |
| `campaign.ndjson`, `project.ndjson` | `DIGITCampaign`, `DIGITProject` | not yet | |
| `individual.ndjson` | `DIGITIndividual` | not yet | |
| `household.ndjson`, `household_member.ndjson` | `DIGITHousehold`, `DIGITHouseholdMember` | not yet | |
| `project_beneficiary.ndjson` | `DIGITProjectBeneficiary` | not yet | |
| `task.ndjson` | `DIGITTask` | not yet | |
| `stock.ndjson` | `DIGITStock` | not yet | |
| `referral.ndjson` | `DIGITReferral` | not yet | |

A run refuses a record file that no step or view reads, so for now the folder holds only the first two:

```bash
mkdir -p digit-in
ln -s "$DIGIT_WORK/raw/boundary_tree.ndjson" digit-in/DIGITBoundaryTree.ndjson
ln -s "$DIGIT_WORK/raw/facility.ndjson"      digit-in/DIGITFacility.ndjson
fhir-pipes import check --package tools/digit/package --in digit-in
fhir-pipes import run   --package tools/digit/package --in digit-in --out digit-fhir --report digit-run.json
fhir-pipes import test  --package tools/digit/package
```

`DIGITFacilityRow` (`models/`) is not a record file: it is the shape of a row of the
`DigitFacility` Library, which `DIGITFacilityToICR` reads.

## The records as DIGIT returns them

The records are DIGIT search results as the API returns them. Most members are null when they
have no value, and every record carries members the mapping does not read (`auditDetails`,
`rowVersion`, `additionalFields`, address lines). `import.toml` sets `[records] null = "absent"`
and `unknown = "ignore"`, so the models describe only what the package reads; `import check
--in` lists the members it ignored. The elements the maps cannot do without are `min` 1
(`DIGITBoundaryTree.boundary.code`, `DIGITFacility.id`), so a rename at the source still stops
the run.

## Boundaries

`boundary_tree.ndjson` holds one record per hierarchy, with the boundaries nested in
`children` to any depth. `DIGITBoundaryTreeToICR` maps a tree with a group that calls itself:
`Children` writes the Location of each child of a boundary, with the boundary as `partOf` and
the level one below, and then calls itself on that child. The Locations come out in the same
order as `transform.py` writes them: each parent before its children.

A tree is one record, so one transform writes all its Locations. The demo's NIGERIA hierarchy
has 83,194 boundaries, more than the map engine's default limit of 2,000,000 values allows in
one transform; `import.toml` raises it with `[maps] max_values`.

The boundary name is made from the code as `transform.py`'s `boundary_name` makes it (DIGIT
keeps names in its localisation service, which is not exported): the segments after the last
numeric segment that has a non-numeric one after it, joined with spaces, each run of letters
capitalised. Like Python's `str.title()`, which `transform.py` uses, that gives `7Th` and
`2Nd` for ordinals (84 names in the demo); the package keeps that, to match.

## Facilities and the boundary they are in

A facility's `partOf` is its locality boundary only when that boundary was exported; otherwise
it is left out. A map sees one record, so that lookup is done in SQL:

1. The views `Boundary` and `Facility` read the record files directly: `Boundary` has one row
   per boundary code of every tree, at any depth, and `Facility` one row per line of
   `facility.ndjson`, with the line number (`%recordLine`) as `line`.
2. The `DigitFacility` Library joins them: each facility once (the facility search returned
   96 facilities twice, as identical rows), with `boundaryCode` only when the boundary was
   exported, in the order of the first line of each facility. Its rows are `DIGITFacilityRow`
   records.
3. `DIGITFacilityToICR` maps each row to a Location and an Organization.

The facilities are written in the order of `facility.ndjson`, as `transform.py` writes them.

The two views are *record views*: their `resource` is a record type (`DIGITBoundaryTree`,
`DIGITFacility`), not a FHIR resource type. That goes beyond the SQL on FHIR specification, so
`import.toml` allows it with `[views] records = "allow"`; see fhir-pipes' `docs/import.md`,
"Record views". A view reads the records after `[records]` has been applied, as the maps do,
and `import check` checks the views' paths against the models.

`Boundary` flattens a tree with `forEach` over the top boundaries and a `unionAll` of the
boundary itself and `repeat: ["children"]`. `repeat: ["boundary", "children"]` from the tree
would be shorter, but fhir-pipes' FHIRPath engine reads `boundary` on a boundary, which has no
such member, as the choice element `boundary[x]` and returns its `boundaryType`.

The data test `one row per facility` stops the run if two different rows have one facility id;
`one boundary per Location id` stops it if two boundary codes would give one Location id
(`transform.py` stops on that too).

## What the run reports

`transform.py` writes counts, skips and notes to `report.json`. For this part:

| `transform.py` report | Package | Demo tenant |
| --- | --- | --- |
| `notes`: "facility: locality boundary not exported (partOf left empty)" | rows of the `DigitFacilityLocalityNotExported` Library, in the run report's step 3 tables | 110 and 110 |
| `duplicate_ids_refused` (Location 96, Organization 96) | `facility` rows less `digit_facility` rows, in the step 2 tables | 192 (96 each) and 5,258 − 5,162 = 96 |
| boundary id collision (stops the run) | data test `one boundary per Location id` | none |
| `counts` by profile | `output` and each step's `resources` | the same for these parts |

`transform.py` counts the note once per row of `facility.ndjson`, duplicates included; the
Library counts facilities. On the demo they agree, as no duplicated facility has an
unexported locality.

## Comparing with transform.py

`compare.py` compares one resource type of an `import run` output folder with `transform.py`'s
output, optionally only the resources a `--where` selects on both sides:

```bash
python3 -I compare.py --new digit-fhir --ref "$DIGIT_WORK/out" --type Location --where type.coding.code=admin-unit
python3 -I compare.py --new digit-fhir --ref "$DIGIT_WORK/out" --type Location --where type.coding.code=facility,temporary-post
python3 -I compare.py --new digit-fhir --ref "$DIGIT_WORK/out" --type Organization
```

In `transform.py`'s output, the first `type` coding of a Location says what it is:
`admin-unit` for a boundary, `facility` or `temporary-post` for a facility, `household` for a
dwelling. Every Organization is a facility's.

`known-differences.toml` lists the differences the package has on purpose, each with its
reason; `compare.py` counts them apart and exits 0 when nothing else differs. `--no-known`
counts everything.

## Where this follows transform.py rather than project/digit.md

- The boundary code identifier has no `use = official`, and non-administrative hierarchies
  (MICROPLAN) are admin-unit Locations too.
- A facility's `usage` goes to `type` as text; there is no storage-node type for warehouses.
- Ids, identifier systems and the `meta.tag` are those of the demo tenant (`dgt-`,
  `.../identifiers/digit-demo/`, `digit-demo`), written in the maps.
