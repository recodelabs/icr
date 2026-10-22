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
| `targets.sh`, `targets.py` | The workbook's ICHD targets, loaded as ICRTargetPopulation Groups |
| `population.sh` | WorldPop population estimates for every district, region and the country, loaded as ICRTargetPopulation Groups |
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

## WorldPop population

`./population.sh --load` extracts the server's Locations, sums WorldPop's constrained 100 m grid
for 2026 (release R2025A) under each district and city with `fhir-pipes population`, and loads
151 Groups: one per district and city, plus region and country totals (`is-calculated`). Ids are
`pop-worldpop-2026-<location id>`. They are total-population estimates with
`denominator-source = worldpop`, not the planning denominator.

R2025A rasters are LZW-compressed, which fhir-pipes 0.6.0 can't read, so the script rewrites the
raster once with `gdal_translate` as DEFLATE (needs GDAL).

Compared with the Ministry's `Population_2026` (2026-10-21): Uganda 52.0 million against 49.6
million (×1.05); 110 of 146 districts within ±20%. The largest differences:

| District | Ministry | WorldPop | Ratio | Likely reason |
| --- | ---: | ---: | ---: | --- |
| Obongi | 149,750 | 23,756 | 0.16 | Refugee settlements (Palorinya), which WorldPop's grid may undercount |
| Lira City | 267,150 | 75,724 | 0.28 | Its boundary is the 2020 municipality, smaller than the city; with Lira District the two are 588,000 against 532,000 |
| Soroti City | 284,640 | 132,728 | 0.47 | To check: city boundary or the Ministry's figure |
| Lira | 264,560 | 512,088 | 1.94 | Holds most of Lira City's people (see above) |
| Sironko | 148,080 | 321,823 | 2.17 | To check |

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

## ICHD targets, October 2026

`./targets.sh --load` reads the workbook's `Target_refined` sheet and loads the targets the
October 2026 ICHDs will plan against, ahead of the campaign itself: 1,661 ICRTargetPopulation
Groups, one per target column for each of the 146 districts and cities, plus region and country
totals. Ids are `ichd-2026-10-<target>-<location id>`.

| Workbook column | `Group.code` | How the workbook gets it | Uganda |
| --- | --- | --- | ---: |
| Population_2026 | `population-2026` | as given | 49,554,040 |
| Catch Population_2025 | `catch-population-2025` | as given | 48,152,090 |
| Target Population<1Yr | `under-1` | catch population × 4.3% | 2,070,540 |
| Unimmunized | `under-1-unimmunized` | under 1 × 2% | 41,411 |
| Under Immunized | `under-1-under-immunized` | under 1 × 3% | 62,116 |
| (headed April 2025) | `born-2025-04` | population 2026 × 4.3% ÷ 12 | 177,569 |
| Total <1Yr Target | `under-1-total` | the three above | 281,096 |
| MR2 Target_April 2024 | `mr2-born-2024-04` | catch population × 4.3% ÷ 12 | 172,545 |
| Deworming+VitA | `deworming-vitamin-a` | as given | 11,897,101 |
| HPV | `hpv` | as given | 371,634 |
| Td2+ | `td2-plus` | as given | 11,100,743 |

Every Group has `denominator-source = govt-estimate` (the workbook named in its text), the
estimate date 2026-09-28 (when the workbook was last saved), `denominator-type`, and
`is-calculated` where the workbook computes the figure or it is a region or country sum. The
targets are flagged `is-planning-denominator`; the two population columns are not, as the targets
are derived from them. The under-1 targets carry the age band 0–11 months; the other targets
have no age band yet, because the workbook doesn't give the ages. Counts are rounded to whole people.
`Total target` is left out: it adds up targets of different interventions.

Two code systems on the server go with them:

- `…/fhir/CodeSystem/uga-ichd-target`: the target columns, used as `Group.code`.
- `…/fhir/CodeSystem/uga-campaign-round`: the round, `ichd-2026-10`, 1–31 October 2026, used as
  `meta.tag` until the campaign is stored.

Searches (URL-encode the system):

```
Group?_tag=https://fhir-uga.healthcampaigns.org/fhir/CodeSystem/uga-campaign-round|ichd-2026-10
Group?code=https://fhir-uga.healthcampaigns.org/fhir/CodeSystem/uga-ichd-target|hpv&geography=Location/uga-n-abim
```

To confirm with the Ministry:

- The ages for deworming and vitamin A, HPV and Td2+, so those Groups can carry an age band.
- The column headed April 2025 is recorded as an MR2 target (children born in April 2025, 18 months
  old in October 2026), but the workbook also counts it in the under-1 total.
- What "Catch Population" is (taken to be the health facility catchment population).

The campaign itself (ICRCampaign CarePlans pointing at these Groups as their planning
denominators, and the protocol with one activity per intervention) comes next.

## Not yet loaded

- Anything below district level. Overture has no outlines there (only about 61,800 village
  points); the COD-AB has counties and sub-counties from 2020.
