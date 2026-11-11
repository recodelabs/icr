# Bangladesh EPI dashboards

Served at https://dashboards.healthcampaigns.org/bd/, behind sign-in: admins and accounts
with a grant for this site only.

The pages compare two Bangladesh immunization systems on the same children and places:

- the 2026 MR campaign, from the EPI campaign DHIS2;
- routine immunization, from the EPI e-Tracker through the DGHS GIS dashboard.

`src/about.md` describes the sources, what was imported and the cautions.

## Data

The loaders in `src/data/` read the Bangladesh warehouse (`$DATA`, which `observatory` sets
to its copy of `r2:icr/bgd/`; without it, `country/bangladesh/warehouse/`). The warehouse
comes from the Bangladesh ICR server (`fhir-bgd.healthcampaigns.org`); see
`country/bangladesh/README.md`.

`src/data/worldpop-under1.csv` holds WorldPop's children under 1 per place, made by
`country/bangladesh/worldpop/zonal.py` (WorldPop Global2 R2025A, CC BY 4.0,
DOI 10.5258/SOTON/WP00841).

The data is aggregated to upazila level and above. It is not public: the warehouse folder
and the built site are private in R2, and the site needs sign-in.

## Build and deploy

```bash
cd dashboards
npx observatory dev bangladesh       # preview
npx observatory deploy bangladesh    # pull the warehouse, build, upload
```
