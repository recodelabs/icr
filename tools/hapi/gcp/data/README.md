# data.healthcampaigns.org: fhir-pipes serve

`fhir-pipes serve` keeps its own warehouse of the ICR's FHIR data and answers SQL on FHIR
`$sql-run` over it. It runs on the main VM (`icr-hapi`) as its own compose project,
`icr-data`, behind the main stack's Caddy.

```
https://data.healthcampaigns.org/fhir/$sql-run           a query (token with system/Library.rs)
https://data.healthcampaigns.org/fhir/Library            the queries there are, with their SQL
https://data.healthcampaigns.org/fhir/.well-known/smart-configuration   how to get a token (open)
https://data.healthcampaigns.org/status, /run, /runs     refreshes (token with fhir-pipes.admin)
```

- **Refreshes.** Once a day at 02:30 UTC, and when asked with `POST /run`, serve runs
  `fhir-pipes refresh` against `https://gateway.healthcampaigns.org/fhir`. It uses its own
  API key, `key-data`. A refresh downloads only what changed since the last one, runs the
  ViewDefinitions and writes their tables into the `warehouse` volume.
- **Queries.** There is one SQLQuery Library per ViewDefinition (`libraries/`), whose SQL is
  `SELECT * FROM v`, so `$sql-run` returns each view's whole table. Its canonical is
  `https://icr.healthcampaigns.org/data/Library/<View>`, for example `…/IcrCoverage`. Library
  parameters are not supported yet, so callers filter what they get.
- **Tokens.** `[serve.auth]` checks tokens from Keycloak, realm `icr`. A token needs the
  SMART scope `system/Library.rs` to query and `fhir-pipes.admin` to run refreshes; both
  scopes set the audience `fhir-pipes` that serve requires. `FHIR_PIPES_SERVE_TOKEN` in
  `data.env` opens everything, for the operator.

What each setting in `fhir-pipes.toml` means is in fhir-pipes' docs:
https://github.com/ohs-foundation/fhir-pipes-rs/blob/main/docs/serve.md

## Files

| File | |
|---|---|
| `Dockerfile` | the fhir-pipes 0.7.0 release binary (checked against SHA256SUMS), the duckdb CLI, and tippecanoe, built from source: every refresh runs the tiles step, Nigeria's only |
| `docker-compose.yml` | project `icr-data`: the serve container, on the main stack's network as `data-serve` |
| `fhir-pipes.toml` | the warehouse, the schedule, `[serve.query]` and `[serve.auth]` |
| `libraries/` | one SQLQuery per ViewDefinition, as `.sql` + `.toml` |
| `bundle.sh` | fills `build/` (mounted at `/config`): the config, the ICR profile, the ViewDefinitions and the Libraries as JSON |
| `keycloak.sh` | the two client scopes, and which API keys may ask for them |
| `data.env.example` | `data.env` on the VM, not in git: the API key and the operator token |
| `../sites/data.caddy` | Caddy's site for the host |

## First deploy

1. **DNS.** In Cloudflare, add an A record `data` → `35.187.76.240`, DNS only (grey cloud),
   so Caddy can get a Let's Encrypt certificate.
2. **Bundle** on a machine with this repo and fhir-pipes 0.7.0:
   `tools/hapi/gcp/data/bundle.sh`
3. **Ship** this folder, the site file and the main compose file (its Caddy now also has the
   gateway's hostname as an alias, so serve reaches the gateway without leaving the VM):

   ```bash
   G() { gcloud --project=icr-registry compute "$@" --zone=europe-west1-b --tunnel-through-iap; }
   tar czf /tmp/data-deploy.tgz -C tools/hapi gcp/data gcp/sites/data.caddy gcp/docker-compose.yml
   G scp /tmp/data-deploy.tgz icr-hapi:/tmp/
   G ssh icr-hapi --command='sudo tar xzf /tmp/data-deploy.tgz -C /opt/icr-hapi'
   ```

4. **On the VM**, from `/opt/icr-hapi/gcp`:

   ```bash
   k() { sudo docker compose exec -T keycloak bash -s -- "$@" < gateway/api-key.sh; }
   kd() { sudo docker compose exec -T keycloak bash -s -- "$@" < data/keycloak.sh; }
   k create data                       # serve's own gateway key: put it in data/data.env
   kd setup                            # the client scopes system/Library.rs and fhir-pipes.admin
   sudo cp data/data.env.example data/data.env && sudo chmod 600 data/data.env   # then edit it
   sudo docker compose up -d caddy     # the new alias and site
   sudo docker compose -f data/docker-compose.yml --env-file data/data.env up -d --build
   ```

5. **The first refresh**, with the operator token:
   `curl -X POST -H "Authorization: Bearer $FHIR_PIPES_SERVE_TOKEN" https://data.healthcampaigns.org/run`.
   Follow it at `/status` and `/runs/<id>/log`. Until it ends, a query answers `503`.

## Give someone access

An API key is a Keycloak client made with `gateway/api-key.sh`. That same key opens the
gateway; granting it here lets it also ask for the scopes serve checks:

```bash
k create dashboards           # a new key, if they have none
kd grant dashboards           # may query
kd grant matt admin           # may query and run refreshes
kd ungrant dashboards
```

The holder then gets a token and queries:

```bash
TOKEN=$(curl -s https://auth.healthcampaigns.org/realms/icr/protocol/openid-connect/token \
  -d grant_type=client_credentials -d client_id=key-dashboards --data-urlencode client_secret="$SECRET" \
  -d scope=system/Library.rs | jq -r .access_token)
curl -H "Authorization: Bearer $TOKEN" -G 'https://data.healthcampaigns.org/fhir/$sql-run' \
  --data-urlencode subjectCanonical=https://icr.healthcampaigns.org/data/Library/IcrCoverage \
  --data-urlencode _format=csv
```

The `scope` must be asked for: the scopes are optional, so a token without it gets `403`.

## Update

- **A new fhir-pipes release:** change `FHIR_PIPES_VERSION` in the `Dockerfile` and the
  image tag in `docker-compose.yml`, then ship and run the `up -d --build` line again.
- **New or changed ViewDefinitions:** rebuild the IG, run `bundle.sh`, ship, then restart
  serve (`… up -d --force-recreate`) and run a full refresh:
  `curl -X POST … -d '{"mode": "full"}' https://data.healthcampaigns.org/run`.
- **Logs:** `sudo docker compose -f data/docker-compose.yml --env-file data/data.env logs -f`.

## Memory

serve and its refreshes get `DATA_MEMORY` (3 GB) between them. The registry has about 350,000
Locations; a full refresh is the most memory a run needs.

## Rollback

`sudo docker compose -f data/docker-compose.yml --env-file data/data.env down` stops it (the
warehouse volume stays). Remove `sites/data.caddy` and reload Caddy to take the host away. The
Keycloak scopes do nothing without serve; `kd ungrant` each key, or delete the two client
scopes in the admin console.
