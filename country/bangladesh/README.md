# Bangladesh

The Bangladesh ICR server, its warehouse and the files that make them.

- **Server:** https://fhir-bgd.healthcampaigns.org/fhir, a Helios FHIR Server (hfs) instance
  `bgd` on the `icr-hapi` VM (`tools/hapi/gcp/hfs.sh`), behind the FHIR Info Gateway. API keys
  come from the Keycloak realm `bgd`.
- **Warehouse:** `warehouse/` here (not in git), pushed to `r2:icr/bgd/`. Private.
- **Dashboards:** `dashboards/sites/bangladesh`, at https://dashboards.healthcampaigns.org/bd/,
  behind sign-in.

## What the server holds

Aggregated figures only, with no records of individual children:

- **Places:** the country, divisions, districts, city corporations and upazilas, with their
  boundaries (969 Locations), and the 14 Organizations they name. The lower levels of the
  campaign DHIS2's org unit tree (unions, wards, sub-blocks, schools, session sites) are kept
  offline.
- **The 2026 MR campaign:** one CarePlan, its PlanDefinition, ActivityDefinition and target Group.
- **Indicators:** 170 Measures: 143 from the EPI campaign DHIS2 (`bd-epi-…`) and 27 for routine
  immunization from the EPI e-Tracker (`bd-ri-…`).
- **Values:** about 1.1 million MeasureReports: the campaign's by day, week, month and for the
  whole campaign; routine by month and year, 2024 to 2026.

The import from the two source systems is done offline with `tools/bd-fhir` (branch
`bd/local-dhis2-import`) into a local FHIR server. `export.py` then writes the files for this
server from that local server's snapshot, leaving out the lower places.

## Load the server

```bash
python3 -I export.py /path/to/offline/warehouse    # writes fhir/*.ndjson
set -a; . ~/.config/icr/bgd-loader.env; set +a
for t in Organization Location PlanDefinition ActivityDefinition Group CarePlan Measure MeasureReport; do
  fhir-pipes load --server https://fhir-bgd.healthcampaigns.org/fhir \
    --client-id "$FHIR_CLIENT_ID" --client-secret "$FHIR_CLIENT_SECRET" \
    --token-url https://auth.healthcampaigns.org/realms/bgd/protocol/openid-connect/token \
    --in fhir/$t.ndjson
done
```

## Refresh the warehouse

```bash
./warehouse.sh --push      # server → warehouse/ → r2:icr/bgd/
```

Then redeploy the dashboards: `cd dashboards && npx observatory deploy bangladesh`.

## WorldPop

`worldpop/zonal.py` sums WorldPop's children under 1 (Global2 R2025A, 100 m, f_00 + m_00) over
each place's boundary. Its output is `dashboards/sites/bangladesh/src/data/worldpop-under1.csv`.
The rasters' addresses come from https://api.worldpop.org/v3/countries/BGD/files.
