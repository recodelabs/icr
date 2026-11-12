# icr-digit: the DIGIT import as an import package

The DIGIT HCM → ICR mapping as a `fhir-pipes import` package: logical models of the DIGIT
records, FML maps, ViewDefinitions and SQLQuery Libraries. It is a port of
`../transform/transform.py`, done in parts. This first part covers **boundaries** and
**facilities**: on the demo tenant's export it writes the same Locations and Organizations as
`transform.py`, apart from the differences listed in `known-differences.toml`.

It needs a fhir-pipes with `[records]` and `[views]` in `import.toml` (its `main` branch
has them), and the `duckdb` command.

## Record types

`fhir-pipes import run --in` reads one file per record type, named after the type. Until a
connector writes these names, make a folder of links to the files `extract.py` and
`extract_ref.py` write:

| DIGIT export file | Record type | Model | Read by |
| --- | --- | --- | --- |
| `boundary_tree.ndjson` | `DIGITBoundaryTree` | `models/StructureDefinition-DIGITBoundaryTree.json` | the views `BoundaryTree` and `Boundary` |
| `facility.ndjson` | `DIGITFacility` | `models/StructureDefinition-DIGITFacility.json` | the view `Facility` |
| `boundary_hierarchy.ndjson` | `DIGITBoundaryHierarchy` | not yet | (`transform.py` does not read it either) |
| `product.ndjson` | `DIGITProduct` | `models/StructureDefinition-DIGITProduct.json` | the view `Product` |
| `product_variant.ndjson` | `DIGITProductVariant` | `models/StructureDefinition-DIGITProductVariant.json` | the view `ProductVariant` |
| `mdms_project_type.ndjson` | `DIGITProjectType` | not yet | |
| `campaign.ndjson`, `project.ndjson` | `DIGITCampaign`, `DIGITProject` | not yet | |
| `individual.ndjson` | `DIGITIndividual` | not yet | |
| `household.ndjson`, `household_member.ndjson` | `DIGITHousehold`, `DIGITHouseholdMember` | not yet | |
| `project_beneficiary.ndjson` | `DIGITProjectBeneficiary` | not yet | |
| `task.ndjson` | `DIGITTask` | not yet | |
| `stock.ndjson` | `DIGITStock` | not yet | |
| `referral.ndjson` | `DIGITReferral` | not yet | |

A run refuses a record file that no step or view reads, so for now the folder holds only the types with a model:

```bash
mkdir -p digit-in
ln -s "$DIGIT_WORK/raw/boundary_tree.ndjson" digit-in/DIGITBoundaryTree.ndjson
ln -s "$DIGIT_WORK/raw/facility.ndjson"      digit-in/DIGITFacility.ndjson
ln -s "$DIGIT_WORK/raw/product.ndjson"       digit-in/DIGITProduct.ndjson
ln -s "$DIGIT_WORK/raw/product_variant.ndjson" digit-in/DIGITProductVariant.ndjson
fhir-pipes import check --package tools/digit/package --in digit-in
fhir-pipes import run   --package tools/digit/package --in digit-in --out digit-fhir --report digit-run.json
fhir-pipes import test  --package tools/digit/package
```

`DIGITBoundaryRow` and `DIGITFacilityRow` (`models/`) are not record files: they are the
shapes of the rows of the `DigitBoundary` and `DigitFacility` Libraries, which
`DIGITBoundaryToICR` and `DIGITFacilityToICR` read.

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
`children` to any depth. The boundaries are mapped one row at a time:

1. The view `BoundaryTree` has one row per tree: its line, its hierarchy and the codes of
   its top boundaries. The view `Boundary` has one row per boundary of every tree, at any
   depth: its code, server id, boundary type and the codes of its children.
2. The `DigitBoundary` Library walks the trees from the top boundaries down, with a
   recursive query, and gives one row per boundary with its hierarchy, its level (0 at the
   top) and its parent's code. Its rows are `DIGITBoundaryRow` records.
3. `DIGITBoundaryToICR` maps each row to a Location.

The Locations come out in the same order as `transform.py` writes them: tree by tree in the
order of the file, and in each tree each boundary before its children, the children in the
order DIGIT lists them. SQL keeps no order, so the Library builds an explicit sort key on
the way down: the tree's line (`%recordLine`), then the position of each boundary among its
siblings. The views give a list of codes as JSON text, so the Library reads the positions
with `from_json` and `unnest ... WITH ORDINALITY`.

On the demo tenant's export this takes about 11 s and 370 MB for the 113,176 boundaries
(2.4 s for the views and the Library, the rest for the map on every core). An earlier
version mapped each tree as one record with a group that called itself; the NIGERIA tree
(83,194 boundaries) was then one transform on one thread, and the boundaries took 43 s and
3.5 GB.

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
boundary itself and `repeat: ["children"]`. The `DigitFacility` Library reads its `code`. `repeat: ["boundary", "children"]` from the tree
would be shorter, but fhir-pipes' FHIRPath engine reads `boundary` on a boundary, which has no
such member, as the choice element `boundary[x]` and returns its `boundaryType`.

The data test `one row per facility` stops the run if two different rows have one facility id;
`one boundary per Location id` stops it if two boundary codes would give one Location id
(`transform.py` stops on that too).

## The product catalogue

`transform.py` writes no resource for a product. It keeps a catalogue of the product
variants (`products.py`) and writes a variant into other resources: the `product` of an
ActivityDefinition and the `title` of a PlanDefinition action, and, in parts not yet ported,
the medication, vaccine or item of a delivery or a stock movement.

The `DigitProductVariant` Library is that catalogue. It reads the views `Product` and
`ProductVariant` and gives one row per variant whose product was exported:

| Column | Value |
| --- | --- |
| `product_variant_id` | The variant's id |
| `label` | The SKU, or the product name when the SKU is empty, trimmed |
| `kind` | `vaccine`, `drug` or `commodity`, from the product type (`TONIC`, `DRUG`, `TABLET`, `BEDNET`, `RESIDUAL_SPRAY`); empty for another type |
| `standard_system`, `standard_code`, `standard_display` | The ATC code of a drug or the CVX code of a vaccine, by product name, or the ICR commodity class of a commodity, by product type; empty when the tables have none |
| `unit`, `unit_code` | The UCUM unit for a quantity: nets, tablets, doses or units |

The tables in the SQL are the demo tenant's, as in `products.py` (its comments call them the
per-instance ConceptMap). A variant that is not in the catalogue, or whose product was not
exported, is written with a local code only and the label `DIGIT product variant <id>`, as
`transform.py` does.

`products.py` also splits a co-packed variant (SPAQ) into its two drugs. Only the
administrations of a delivery use that, so the package does not have it yet.

On the demo export the catalogue has 276 rows. Each gives the same code, label, kind and unit
as `products.py`, and the same codes and units as the 79 variants in the reference
ActivityDefinitions and the 34 in the reference SupplyDeliveries.

## What the run reports

`transform.py` writes counts, skips and notes to `report.json`. For this part:

| `transform.py` report | Package | Demo tenant |
| --- | --- | --- |
| `notes`: "facility: locality boundary not exported (partOf left empty)" | rows of the `DigitFacilityLocalityNotExported` Library, in the run report's step 4 tables | 110 and 110 |
| `duplicate_ids_refused` (Location 96, Organization 96) | `facility` rows less `digit_facility` rows, in the step 3 tables | 192 (96 each) and 5,258 − 5,162 = 96 |
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
