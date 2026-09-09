# Catchment areas → registry Locations, denominators and building counts

Turns Crosscut catchment exports into ICR resources and loads them beside the facilities
and settlements they belong to. First use: Toro LGA, Bauchi State, Nigeria (Sep 2026) —
159 facility catchments (ward-bounded) and 2,087 settlement catchments (bounded by the
facility catchments).

## Model

A catchment is its **own** Location, not a boundary on the site's record, so that its
polygon, its place in the containment tree and the figures scoped to it stay separate
from the site's point:

| | id | type (`icr-location-type-cs`) | physicalType | partOf | catchment-of |
| --- | --- | --- | --- | --- | --- |
| facility catchment | `catchment-<facility id>` | `facility-catchment` | `area` | the LGA (`nga-ba-5018`) | `Location/<facility id>` |
| settlement catchment | `catchment-<settlement id>` | `settlement-catchment` | `area` | the facility catchment | `Location/<settlement id>` |

The polygon rides the IG's `location-boundary-geojson` extension (bare GeoJSON geometry,
base64, `application/geo+json`) exactly as the admin boundaries do, so kiln writes the
catchments as `geom_type=polygon/type=<type>` partitions of `data/parquet/locations`.
`catchment-of` is an IG extension with a reference-typed SearchParameter.

The site records (facility and settlement points) are not touched: they stay `partOf`
the LGA. Settlements are *assigned* to a facility catchment (every settlement point lies
inside its facility catchment; ~300 settlement footprints spill a little over the
catchment edge, which is fine for assignment).

### What hangs off a catchment

| Figure | Resource | Where it comes from |
| --- | --- | --- |
| Total population, WorldPop 2026 | `ICRTargetPopulation` Group `pop-worldpop-2026-catchment-<site id>` (geography = the catchment; `denominator-source` worldpop; not the planning denominator) | `kiln population --type facility-catchment` / `--type settlement-catchment` — the same raster and pixel-centroid rule as the admin units, so the 159 facility catchments add up to the LGA's own figure (553,772 vs 553,764) |
| Population by walking time to the facility (under 1 h / 1–4 h / over 4 h) | three `ICRTargetPopulation` Groups `acc-walk-<band>-2026-<site id>`, geography = the catchment plus a `travel-time` characteristic (`icr-travel-time-band-cs`) | the CSV's "People … of walking" columns (Crosscut accessibility model over WorldPop 2026) |
| Building counts | `building-count` extensions on the catchment Location, one per dataset: OSM and Overture (2026-02-20), Google Open Buildings at ≥ 60 / 70 / 80 % confidence (2023-05) | the CSV's building columns |

Not loaded (still in the CSV): the Meta, Kontur, GRID3 and WorldPop-UN population columns,
the age/sex splits, the driving-time bands and the average building footprint. The
Crosscut WorldPop column is kept only as a cross-check: kiln's sums agree with it to a
median 1–2 % per catchment (Crosscut apportions edge pixels; kiln assigns them whole).

```bash
B=localhost:3447/fhir
curl -s "$B/Location?type=facility-catchment&partof=Location/nga-ba-5018"      # Toro's facility catchments
curl -s "$B/Location?catchment-of=Location/<facility-id>"                     # one facility's catchment
curl -s "$B/Location?_id=<facility-id>&_revinclude=Location:catchment-of"     # facility + catchment in one call
curl -s "$B/Location?partof=Location/catchment-<facility-id>"                 # settlement catchments inside it
curl -s "$B/Group?geography=Location/catchment-<facility-id>"                 # its WorldPop total + 3 walking bands
```

In the warehouse: `parquet/target_population` has a `travel_time` column (null for the
all-of-the-area rows); the building counts stay inside `fhir_json` for now.

## Inputs (`data/imports/`)

Crosscut exports, two per layer: a GeoJSON with the polygons and the registry ids, and
the matching Google Sheets CSV (two header rows) with the population, building and
accessibility columns. The GeoJSON is the geometry source; the CSV supplies the
attributes and, for settlements, the parent facility (`organization_id` =
`org-<facility id>`), which the GeoJSON does not carry. The CSVs' uuid columns are
unusable (Sheets coerced them to numbers): facilities join on `organization_id`,
settlements on `grid3_settlement_id`. One settlement (Gidan Sarkin Kafanchu) has an
empty polygon in the export and is skipped.

## Run

```bash
python3 tools/catchments/build.py                       # → out/nga-ba-toro-catchments.ndjson (Locations)
                                                        #   out/nga-ba-toro-access-groups.ndjson (walking-band Groups)
(cd ig && npx -y fsh-sushi build .) && python3 tools/hapi/load.py ig    # once, after an FSH change
python3 tools/hapi/load.py ndjson tools/catchments/out/nga-ba-toro-catchments.ndjson
python3 tools/hapi/load.py ndjson tools/catchments/out/nga-ba-toro-access-groups.ndjson

# WorldPop totals per catchment: kiln reads the polygons back from the registry snapshot
tools/warehouse/refresh.sh --locations                  # snapshot must contain the catchments
K=~/github/kiln/target/release/kiln
R=https://pub-e6e33253461449dfb455784209fd31bb.r2.dev/nga_pop_2026_CN_100m_cog.tif   # WorldPop 2026, cached under data/raw/hapi-local/locations/rasters
for t in facility settlement; do
  $K population --snapshot data/raw/hapi-local/locations --raster $R --type $t-catchment --year 2026 \
     --out tools/catchments/out/pop-worldpop-2026-$t-catchments.ndjson --report tools/catchments/out/pop-$t-catchments-report.json
  python3 tools/hapi/load.py ndjson tools/catchments/out/pop-worldpop-2026-$t-catchments.ndjson
done
tools/warehouse/refresh.sh                              # parquet + tiles + catalog (add --push for R2)
```

`build.py` takes `--hf`, `--hf-csv`, `--settlements`, `--settlements-csv`, `--out`,
`--groups-out` for other LGAs / exports. Every load is idempotent (PUT by id). Output is
git-ignored (`tools/catchments/out/`).

Downstream: `tools/warehouse/tiles.sh` writes the polygons to `data/tiles/catchments.pmtiles`
(layers `facility_catchments`, `settlement_catchments`), and the Campaign Dashboards
Georegistry page (`campaignhq/src/georegistry.md`) shows them as two toggleable layers
with a Catchments KPI card; clicking a polygon lists its properties including `catchment_of`.
