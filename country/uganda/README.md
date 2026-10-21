# Uganda

Data for the Uganda ICR server, `https://fhir-uga.healthcampaigns.org/fhir` (see
`tools/hapi/gcp/README.md`, "Country servers").

| File | What it is |
| --- | --- |
| `Oct 2026_ICHDs_EPI Targets.xlsx` | Ministry of Health targets for the October 2026 Integrated Child Health Days, per district and city (146) |
| `uga_admin_boundaries.geojson.zip` | OCHA COD-AB for Uganda, v01, valid from 24 Aug 2020: regions, districts (135), counties (203), sub-counties (1,520), with P-codes |
| `districts.sql` | Builds the districts GeoJSON from Overture and the COD-AB, and checks it |
| `enrich.py` | Adds identifiers and sources to the Locations fhir-pipes writes |
| `build.sh` | Runs it all; `--load` sends the result to the server |
| `fhir-pipes.toml`, `sdi.sh`, `sdi/.portolan/` | Uganda's SDI catalog: the server's Locations as GeoParquet, map tiles and Portolan metadata |

## Admin units on the server

151 Locations, loaded on 2026-10-21: Uganda, its 4 regions, and 146 districts and cities that
match the targets workbook one to one. Ids are `uga`, `uga-<region>` (`uga-n`, `uga-e`,
`uga-c`, `uga-w`) and `uga-<region>-<name>` (`uga-n-abim`, `uga-n-lira-city`).

**Boundaries.** Overture Maps release 2026-10-21.0, whose divisions come from OpenStreetMap
(ODbL: credit OpenStreetMap contributors, and share anything published from it under the same
licence). Overture's `county` level is Uganda's districts and cities. Two changes so the units
match the ministry's list:

- **Entebbe City** is a separate unit in Overture but not in the ministry's list, so its
  area is merged back into Wakiso.
- **Lira City** has no outline in Overture. It is the COD-AB's Lira Municipality (35 km²),
  cut out of Overture's Lira. The city is larger than the 2020 municipality, so this outline is
  an approximation until a current one is available.

Region and country boundaries are the union of their districts. Each Location's
`description` says where its boundary came from.

**Identifiers.** The P-code from the COD-AB (`use: official`) for the 135 districts that had
one in 2020. The 10 cities and Terego (created in 2020) have none yet. Also the Overture GERS
id, the Wikidata id, and ISO 3166 codes for the country (`UG`) and the regions (`UG-N`…). Lira
City carries Lira Municipality's P-code, not marked official.

**Names.** Overture's names (`Luweero`, `Sembabule`, `Madi Okollo`). The workbook's spellings
are kept as aliases (`Luwero District`), and so is the COD-AB's where it differs (`Ssembabule`),
so a search by any of them finds the unit.

## Rebuild or reload

```bash
./build.sh            # fetch Overture, build, check
./build.sh --load     # and load, with the key in ~/.config/icr/uga-matt.env
```

`build/districts-checks.txt` must show 146 units, all matched to the workbook, and the
districts' total area equal to the country's.

## SDI catalog

https://sdi.healthcampaigns.org/uga/ opens the Portolan browser on Uganda's catalog
(`/uga/catalog.json`), separate from the main ICR catalog at the site's root. It holds the
Locations of the Uganda server as GeoParquet (`parquet/locations/country=UGA/…`), the district
map as PMTiles (`tiles/admin.pmtiles`) and the catalog's metadata, under the ODbL with credit to
OpenStreetMap (via Overture Maps), OCHA and the ICR.

```bash
./sdi.sh            # refresh from the server: fhir-pipes refresh, then the Portolan catalog
./sdi.sh --push     # and upload to the uga/ folder of the icr R2 bucket
```

Run it after the Locations on the server change. `fhir-pipes.toml` is the refresh config;
`tools/warehouse/catalog.sh` builds the catalog with the metadata in `sdi/.portolan/`
(edit the descriptions, license and known issues there). The SDI Worker (`tools/sdi`) serves
the `uga/` folder; another country's catalog needs its code added to `COUNTRY_CATALOGS` there.

## Not yet loaded

- The October 2026 ICHD targets (the workbook's `Target_refined` sheet).
- Anything below district level. Overture has no outlines there (only about 61,800 village
  points); the COD-AB has counties and sub-counties from 2020.
