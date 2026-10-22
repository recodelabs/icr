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

## Refresh and build

```bash
./refresh.sh              # fhir-pipes: Uganda server → warehouse/ (locations, views, tiles)
npm install               # once
npm run dev               # preview
../deploy.sh uganda       # build and publish to /ug/
```

`refresh.sh` uses the API key in `~/.config/icr/uga-matt.env` and the IG's ViewDefinitions in
`ig/fsh-generated/resources` (run `sushi build .` in `ig/` first). `warehouse/` is not in git.

The boundary tiles' layers are named `states` (regions) and `lgas` (districts and cities):
fhir-pipes names admin levels 1 and 2 the Nigerian way for every country.
