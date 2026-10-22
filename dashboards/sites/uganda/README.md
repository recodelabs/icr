# Uganda campaign dashboards

Served at https://dashboards.healthcampaigns.org/ug/. The planning data on the Uganda ICR
server (https://fhir-uga.healthcampaigns.org/fhir), to start with the October 2026 ICHDs:

- **ICHD targets** (`/`): the Ministry of Health's targets per activity, by district, region and
  for Uganda, read from the campaigns' activity list (each district campaign names a target
  Group for each of its six activities).
- **Campaign plan** (`/plan`): the protocol's activities, the 147 draft campaigns and the 876
  tasks, by delivery strategy.
- **Population estimates** (`/population`): the Ministry's 2026 population against WorldPop
  2026 for every district.
- **Georegistry** (`/georegistry`): the country, regions and districts and cities, with their
  codes and boundaries.

## Data, refresh and build

The data is Uganda's warehouse, built from the Uganda server by `country/uganda/warehouse.sh`
(fhir-pipes: locations, the IG's views, boundary tiles) and pushed to `r2:icr/uga/`.
`npx observatory deploy uganda` (in `dashboards/`) pulls it from R2 and builds the site from
it, so an update is:

```bash
country/uganda/warehouse.sh --push            # (repo root) Uganda server → r2:icr/uga/
cd dashboards && npx observatory deploy uganda   # R2 warehouse → build → /ug/
```

For a preview, `npm install` in `dashboards/` once, then `npx observatory dev uganda`: data
from the cached R2 warehouse, or with `--local` from `country/uganda/warehouse/` (run
`warehouse.sh` first). The maps are Observatory's `adminMap`
(`src/components/uganda-map.js` sets Uganda's bounds).

The boundary tiles' layers are `country`, `regions` and `districts` (districts and cities),
named by the Uganda profile, `ig/fhir-pipes-profile-uganda.toml`.
