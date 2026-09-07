# data/ — the ICR analytics hub

Everything the FHIR registry exports for external analytics lives here: the
location registry as GeoParquet, and every SQL-on-FHIR ViewDefinition in the IG
as a flat parquet table. DuckDB (or DuckDB-WASM in a browser dashboard) reads
the parquet in place; nothing here is a database.

**Everything in `raw/` and `parquet/` is derived and disposable.** FHIR is the
master. If a file looks wrong, delete it and run the refresh again. Git tracks
only the layout, the view definitions and the manifest — the big files are
ignored (see `.gitignore`); this directory doubles as the local mirror of an
object-store bucket with the same paths.

```
data/
  raw/                     verbatim server output (NDJSON), one folder per source server
    hapi-local/
      locations/           kiln snapshot: locations.ndjson, organizations.ndjson, state.json (extract cursor)
      CarePlan.ndjson      the resources each ViewDefinition was run over
  parquet/                 the warehouse: one folder per table, hive-partitioned, read in place
    locations/             country=NGA/geom_type=…/type=…/part-0.parquet   (kiln transform)
    campaign_calendar/     country=NGA/part-0.parquet                      (ViewDefinition IcrCampaignCalendar)
    _report.json           kiln's transform report (geometry issues etc.)
  views/                   the exact ViewDefinition JSON each table was built from (from the IG build)
  catalog.sql              CREATE VIEW per table over the parquet globs — `FROM campaign_calendar`
  manifest.json            when, from which server, row counts, view canonicals (written by the refresh)
```

## Refresh

```bash
tools/warehouse/refresh.sh            # kiln run (incremental) + every ViewDefinition in the IG
tools/warehouse/refresh.sh --views    # views only (seconds)
```

Needs: the local HAPI (`tools/hapi`), `kiln` (`~/github/kiln/target/debug/kiln`
or `KILN=`), `octofhir-sof` (the recodelabs/sof fork build, on the PATH or
`SOF=`), `duckdb`, and a sushi build of the IG (`ig/fsh-generated/`) for the
ViewDefinitions.

## Query

```bash
cd data && duckdb -init catalog.sql
```

```sql
-- campaigns per state per year, from the calendar view joined to the registry
SELECT l.admin1_name, year(c.period_start) AS yr, count(*) AS lga_rounds
FROM campaign_calendar c JOIN locations l ON l.id = c.location_id
WHERE l.type = 'admin-unit' GROUP BY 1, 2 ORDER BY 1, 2;
```

Table names are the ViewDefinition names in snake case, so a new view in the
IG becomes a new folder here with no naming decision. `locations` is kiln's
table (columns: id, name, type, part_of, admin0..4 names/codes, path,
ancestor_ids, quadkey, geometry…). Views are partitioned by `country`, taken
from the registry by joining `location_id`; rows whose geography is not in the
registry land in `country=__HIVE_DEFAULT_PARTITION__`.

## Conventions

- One folder per table under `parquet/`; hive partitioning (`key=value/`);
  `part-N.parquet` files. Never write a file directly under `parquet/`.
- `raw/<server>/` — snapshots carry a server cursor, so they are keyed to the
  server they came from. A Google Healthcare API snapshot and a HAPI snapshot
  can coexist.
- Loading inputs (GRID3 CSVs, baked NDJSON) are not exports and do not live
  here; they stay with kiln.
