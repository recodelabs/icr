# data.healthcampaigns.org: fhir-pipes serve

`fhir-pipes serve` keeps its own warehouse of the ICR's FHIR data and answers SQL on FHIR
`$sql-run` over it. It runs on the main VM (`icr-hapi`) as its own compose project,
`icr-data`, behind the main stack's Caddy.

```
https://data.healthcampaigns.org/fhir/$sql-run           a query (token with system/Library.rs)
https://data.healthcampaigns.org/fhir/Library            the queries there are, with their SQL
https://data.healthcampaigns.org/fhir/.well-known/smart-configuration   how to get a token (open)
https://data.healthcampaigns.org/status, /run, /runs     refreshes (token with fhir-pipes.admin)
https://data.healthcampaigns.org/mcp                     the saved queries as MCP tools, for Claude
```

- **Refreshes.** Once a day at 02:30 UTC, and when asked with `POST /run`, serve runs
  `fhir-pipes refresh` against `https://gateway.healthcampaigns.org/fhir`. It uses its own
  API key, `key-data`. A refresh downloads only what changed since the last one, runs the
  ViewDefinitions and writes their tables into the `warehouse` volume.
- **Queries.** There is one SQLQuery Library per ViewDefinition (`libraries/`), whose SQL is
  `SELECT * FROM v`, so `$sql-run` returns each view's whole table. Its canonical is
  `https://icr.healthcampaigns.org/data/Library/<View>`, for example `…/IcrCoverage`. A Library
  can declare parameters (`[[parameter]]` in its `.toml`, `:name` in its SQL) that a caller
  gives as query parameters; one that is not given is NULL. Three more Libraries join
  tables: `IcrLocationStatusLocation`, the LocationHierarchy rows of the admin units that have an
  IcrLocationStatus row, so a caller who wants endemicity by place does not download every
  Location; and `IcrCoverageByLocation`, each IcrCoverage row with its campaign and its place's
  names, to filter coverage by year, state or programme; and `IcrPopulationByLocation`, the census
  projection and WorldPop total population per admin unit, side by side. `datapi.md` at the repo root is the
  guide for callers.
- **Tokens.** `[serve.auth]` checks tokens from Keycloak, realm `icr`. A token needs the
  SMART scope `system/Library.rs` to query and `fhir-pipes.admin` to run refreshes; both
  scopes set the audience `fhir-pipes` that serve requires. `FHIR_PIPES_SERVE_TOKEN` in
  `data.env` opens everything, for the operator.

What each setting in `fhir-pipes.toml` means is in fhir-pipes' docs:
https://github.com/ohs-foundation/fhir-pipes-rs/blob/main/docs/serve.md

## Files

| File | |
|---|---|
| `Dockerfile` | the fhir-pipes 0.8.0 release binary (checked against SHA256SUMS), the duckdb CLI, and tippecanoe, built from source: every refresh runs the tiles step, Nigeria's only |
| `docker-compose.yml` | project `icr-data`: the serve container, on the main stack's network as `data-serve` |
| `fhir-pipes.toml` | the warehouse, the schedule, `[serve.query]` and `[serve.auth]` |
| `libraries/` | one SQLQuery per ViewDefinition, as `.sql` + `.toml` |
| `bundle.sh` | fills `build/` (mounted at `/config`): the config, the ICR profile, the ViewDefinitions and the Libraries as JSON |
| `keycloak.sh` | the two client scopes, and which API keys may ask for them |
| `data.env.example` | `data.env` on the VM, not in git: the API key and the operator token |
| `mcp/` | the MCP server (`icr_mcp.py`, its tests, `Dockerfile`, `uv.lock`) |
| `../sites/data.caddy` | Caddy's site for the host: `/mcp` to the MCP server, the rest to serve |

## First deploy

1. **DNS.** In Cloudflare, add an A record `data` → `35.187.76.240`, DNS only (grey cloud),
   so Caddy can get a Let's Encrypt certificate.
2. **Bundle** on a machine with this repo and fhir-pipes 0.8.0 or later (a Library's `[[parameter]]` entries need it):
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

## Claude (MCP)

`mcp/` is an MCP server at `https://data.healthcampaigns.org/mcp`, in the same compose project
(service `mcp`, alias `data-mcp`). Claude adds it as a custom connector; people then ask
questions in Claude (typed or by voice) and Claude runs the saved queries. It has four tools:

- `list_queries`: the approved Libraries, with their parameters
- `get_query`: one Library's SQL and the tables it reads
- `run_query`: run one with filter parameters; at most 1,000 rows come back (200 by default)
- `aggregate`: run one, then group its rows and compute figures per group (`count`,
  `count_distinct`, `sum`, `avg`, `min`, `max`, and `ratio`, which is sum over sum, for coverage
  and other rates), with a `where` on any column. The grouping happens in the MCP server, over
  the rows `run_query` would return, so it reaches no other data. It reads at most 500,000 rows.

**Totals over one kind of row.** A query can return rows that must not be added together: a
state's row and its LGAs' rows, an administrative report and a survey of the same place, two
programmes. `mcp/queries.toml` lists these columns for each query (`one_kind`). `aggregate`
refuses a sum, average, ratio, minimum or maximum over rows that differ in one of them, and
its error lists the values found; the agent then fixes one value (a parameter or `where`) or
groups by the column. Counts are not checked. Each result says which kind of row it is for
(`kinds`). When a Library is added or gains such a column, add it to `queries.toml`. The check
cannot see what a query has no column for: `ViewIcrCoverage` has no admin level, so use
`IcrCoverageByLocation` for totals by place.

It runs no SQL of its own, only serve's approved Libraries through `$sql-run`.

**Sign-in.** People sign in with an account in realm `icr`, through the Keycloak client
`claude-mcp`. Its tokens are issued for two audiences: the MCP URL, which the MCP server
checks, and `fhir-pipes`, with `system/Library.rs`, which serve checks. The MCP server sends
the caller's token on to serve, so serve sees each person. Any enabled user of the realm can
use the connector.

```bash
kd claude        # once: the client; prints the client ID and secret for Claude
kd user jdoe     # a person; prints a temporary password, changed at first sign-in
kd unuser jdoe
```

**Connect in Claude** (web, Desktop or mobile, which share the connector): Settings → Connectors →
Add custom connector. URL `https://data.healthcampaigns.org/mcp`; under the OAuth client, use
your own client: ID `claude-mcp` and the secret `kd claude` printed. Claude cannot change a
connector's sign-in settings later: to change them, remove the connector and add it again.

**Deploy or update:** ship this folder and `../sites/data.caddy`, then on the VM
`sudo docker compose -f data/docker-compose.yml --env-file data/data.env up -d --build mcp`, then
`sudo docker compose exec -T caddy caddy reload --config /etc/caddy/Caddyfile`.
Logs show each call with the person's username:
`sudo docker compose -f data/docker-compose.yml --env-file data/data.env logs -f mcp`.

**Tests:** `cd mcp && uv run pytest`.

## Update

- **A new fhir-pipes release:** change `FHIR_PIPES_VERSION` in the `Dockerfile` and the
  image tag in `docker-compose.yml`, then ship and run the `up -d --build` line again.
- **A new or changed Library:** edit `libraries/`, run `bundle.sh`, ship, then restart serve
  (`… up -d --force-recreate`).
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
