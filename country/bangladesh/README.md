# Bangladesh

Bangladesh's warehouse and the files that make it. There is no hosted ICR server for
Bangladesh: the FHIR server is kept offline, and only its warehouse is published.

- **FHIR server:** offline. The EPI campaign DHIS2 and the routine EPI e-Tracker (through the
  DGHS GIS dashboard) are imported into it with `tools/bd-fhir` (branch `bd/local-dhis2-import`).
- **Warehouse:** built offline with `fhir-pipes refresh`, then uploaded to `r2:icr/bgd/` by
  `push.sh`. Private: there is no SDI for Bangladesh.
- **Dashboards:** `dashboards/sites/bangladesh`, at https://dashboards.healthcampaigns.org/bd/,
  behind sign-in.

## What the warehouse holds

Aggregated figures only, with no records of individual children:

- **Places** (`locations`): the campaign DHIS2's org unit tree, with the boundaries matched from
  the routine system.
- **The 2026 MR campaign** (`campaign_calendar`, `target_population`).
- **Indicators** (`indicator`, `indicator_group`): 143 from the EPI campaign DHIS2 (`bd-epi-…`)
  and 27 for routine immunization (`bd-ri-…`).
- **Values** (`indicator_value`, `indicator_strata`): about 1.1 million, for the country,
  divisions, districts and upazilas. The campaign's by day, week, month and for the whole
  campaign; routine by month and year, 2024 to 2026.

## Publish the warehouse

```bash
./push.sh /path/to/offline/warehouse      # → r2:icr/bgd/
```

Then redeploy the dashboards: `cd dashboards && npx observatory deploy bangladesh`.

To build the site from the offline warehouse without R2, link it here as `warehouse/` (it is
git-ignored) and run `npx observatory build bangladesh --local`.

## WorldPop

`worldpop/zonal.py` sums WorldPop's children under 1 (Global2 R2025A, 100 m, f_00 + m_00) over
each place's boundary. Its output is `dashboards/sites/bangladesh/src/data/worldpop-under1.csv`.
The rasters' addresses come from https://api.worldpop.org/v3/countries/BGD/files.
