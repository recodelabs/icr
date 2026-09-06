# Local HAPI FHIR server

A HAPI FHIR **R4** server (JPA starter on Postgres 15) for ICR development — the FHIR-store
slot of the reference stack, running on a laptop via Docker (OrbStack on macOS). Its first
job is to test [kiln](https://github.com/recodelabs/kiln) (Location registry ⇄ GeoParquet)
against ICR-shaped data; it is also the target for loading the IG's example scenario.

```
FHIR base URL   http://localhost:3447/fhir
Web tester UI   http://localhost:3447/
Postgres        localhost:3448  (user hapi / password hapi / db hapi) — for psql and SQL-on-FHIR experiments
```

## Start, seed, stop

```bash
cd tools/hapi
docker compose up -d                  # first run pulls the images (~1 GB) and takes ~1–2 min to boot
curl -s localhost:3447/fhir/metadata | head -c 200

python3 load.py ig                    # the IG's compiled resources: profiles, terminology, Measures,
                                      #   and the worked examples (Kambia MR SIA, Rokupr MDA, cost thread …)
python3 load.py kiln-demo             # the kiln demo registry: 1,468 Organizations + 1,834 Locations
                                      #   (Bauchi, Nigeria, with GRID3 ids and boundary polygons)
                                      #   default path: ../kiln/data/icr-demo/snapshot; override with --snapshot DIR

docker compose down                   # stop, keep the data
docker compose down -v                # stop AND wipe the database
```

`load.py` needs only the Python standard library. It PUTs every resource by its own id inside
transaction bundles, so re-running it is idempotent (200 for unchanged, 201 for new). `load.py
ndjson FILE…` loads any NDJSON of FHIR resources. The IG resources come from
`ig/fsh-generated/resources/`, so run `sushi build .` in `ig/` after changing FSH.

## Testing kiln against it

```bash
cd tools/hapi && mkdir -p .local           # .local/ is git-ignored scratch
KILN=~/github/kiln/target/debug/kiln       # or `cargo build --release` → target/release/kiln

$KILN run     --server http://localhost:3447/fhir --snapshot .local/snapshot --out .local/out
$KILN inspect --out .local/out

# round trip: edit .local/out in QGIS / DuckDB, then
$KILN diff --snapshot .local/snapshot --in edits.geojson --out .local/changes.ndjson --report .local/report.json
$KILN load --server http://localhost:3447/fhir --in .local/changes.ndjson --dry-run
$KILN load --server http://localhost:3447/fhir --in .local/changes.ndjson
$KILN run  --server http://localhost:3447/fhir --snapshot .local/snapshot --out .local/out   # incremental
```

No token is needed: the server is open on localhost.

Verified Sep 6, 2026 with kiln 0.2.0 against HAPI 8.12.0: `kiln run` paged 1,843 Locations and
1,469 Organizations (2 pages each at `_count=1000`) and wrote 1,819 rows across 6 partitions in ~9 s.

## Campaign visibility: which campaigns target this place, in this window?

The IG ships two custom SearchParameters (`ig/input/fsh/searchparameters.fsh`):
`CarePlan?target-geography=` indexes `ICRCampaign.extension[targetGeography]`, and
`Group?geography=` indexes `ICRTargetPopulation.characteristic[geography].valueReference`.
`load.py ig` loads SearchParameters in their own first bundle and then calls `$reindex` on their
base types, so resources stored before the parameters existed become searchable too. The reindex
is asynchronous and can take up to a minute; poll the status URL it prints. Verified Sep 6, 2026
against HAPI 8.12.0:

```bash
B=localhost:3447/fhir
# campaigns whose geography IS this district
curl -s "$B/CarePlan?target-geography=Location/example-district"
# campaigns in the district's direct children (one chain level; HAPI does not resolve deeper chains)
curl -s "$B/CarePlan?target-geography.partof=Location/example-district"
# the whole subtree AND every campaign targeting any node of it, in one call
curl -s "$B/Location?_id=example-district&_revinclude:iterate=Location:partof&_revinclude:iterate=CarePlan:target-geography"
# a date window on top: CarePlan `date` searches period
curl -s "$B/CarePlan?target-geography=Location/example-district&date=ge2026-06-01&date=le2026-09-30"
# OR several geographies (ids from the subtree call), sorted by start
curl -s "$B/CarePlan?target-geography=Location/example-district,Location/example-settlement&date=ge2026-01-01&_sort=date"
# reverse: places that have an active campaign
curl -s "$B/Location?_has:CarePlan:target-geography:status=active"
# denominators: every target-population estimate scoped to a place, and those in its direct children
curl -s "$B/Group?geography=Location/example-district"
curl -s "$B/Group?geography.partof=Location/example-district"
# the subtree, its campaigns AND its denominators, in one call
curl -s "$B/Location?_id=example-district&_revinclude:iterate=Location:partof&_revinclude:iterate=CarePlan:target-geography&_revinclude:iterate=Group:geography"
```

HAPI 8 does not implement the `:above` / `:below` reference modifiers, so "everything under X"
is the revinclude call above, or resolve the subtree first and pass the ids as a comma list.

## What is configured, and why (`hapi.application.yaml`)

| Setting | Value | Why |
| --- | --- | --- |
| `max_page_size` | 1000 | kiln pages with `_count=1000`; HAPI's default cap of 200 would silently shrink pages |
| `reuse_cached_search_results_millis` | 0 | an extract run right after a `kiln load` must see the new versions |
| `enforce_referential_integrity_on_write` | false | client-assigned ids arrive in arbitrary batch order (`partOf`, `managingOrganization`) |
| `allow_external_references` | true | canonical and cross-store references in the IG examples |
| `allow_multiple_delete` / `expunge_enabled` | true | dev box: wipe a resource type without dropping the volume |
| `validation.requests_enabled` | false | the IG Publisher validates the IG; the store stays fast |
| `defer_indexing_for_codesystems_of_size` | 101 | keeps startup quick with the IG's terminology loaded |

Ports 3447/3448 are deliberately unusual so the stack never collides with other local services on 8080/5432. The Postgres data lives in the named volume `icr-hapi-pgdata`, not in the repo.

## Useful checks

```bash
curl -s 'localhost:3447/fhir/Location?_summary=count'          | python3 -m json.tool | grep total
curl -s 'localhost:3447/fhir/Location?_count=1000&_lastUpdated=ge2026-01-01' | head -c 300
curl -s 'localhost:3447/fhir/CarePlan/example-mr-sia-2026'     | python3 -m json.tool | head -30
curl -s 'localhost:3447/fhir/Observation?_profile=https://icr.healthcampaigns.org/StructureDefinition/ICRCampaignCost&_summary=count'
docker compose logs -f hapi                                     # server log
```
