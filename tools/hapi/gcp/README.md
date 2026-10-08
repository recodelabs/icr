# Hosted HAPI FHIR dev server (GCP)

The laptop stack in `../` (HAPI 8.12 + Postgres 15 + `../hapi.application.yaml`), hosted
on one Compute Engine VM behind Caddy so others can reach it. Lightly used: demos and
occasional kiln exports.

```
FHIR base URL   https://hapi.healthcampaigns.org/fhir       open, no auth (as before)
Web tester UI   https://hapi.healthcampaigns.org/
Gateway         https://gateway.healthcampaigns.org/fhir    same server, API key required
Token issuer    https://auth.healthcampaigns.org/realms/icr Keycloak
```

HAPI's own address stays open for reads and writes, so the warehouse refresh, kiln and
`load.py` work unchanged. The FHIR Info Gateway in front of it requires an API key (see
"API keys" below). No backups: everything on it is regenerated from this repo (see "Seed").

## Infrastructure

| What | Value |
| --- | --- |
| Project | `icr-registry` (same project as the Healthcare API store `icr-demo`) |
| VM | `icr-hapi`, e2-highmem-2 (2 vCPU / 16 GB), `europe-west1-b`, Debian 12, 50 GB pd-balanced |
| Static IP | `icr-hapi-ip` = `35.187.76.240` |
| Firewall | `icr-hapi-web` (tcp 80/443, tag `icr-hapi-web`); SSH only via IAP (`default-allow-ssh` limited to 35.235.240.0/20) |
| DNS | Cloudflare `hapi.healthcampaigns.org` A → 35.187.76.240, **DNS only (grey)** so Caddy gets its own Let's Encrypt cert |
| Cost | ≈ $83/month list (VM ~73, disk ~6, IP ~4) |

Memory split on the 16 GB box: HAPI `-Xmx6g`, Postgres `shared_buffers=4GB`
(`effective_cache_size=10GB`). Resize with stop → `gcloud compute instances
set-machine-type` → start; the data stays on the disk.

## Deploy / update

```bash
G() { gcloud --project=icr-registry compute "$@" --zone=europe-west1-b --tunnel-through-iap; }

# from the repo root: ship the shared config + this folder
tar czf /tmp/hapi-deploy.tgz -C tools/hapi hapi.application.yaml gcp
G scp /tmp/hapi-deploy.tgz icr-hapi:/tmp/
G ssh icr-hapi --command='sudo tar xzf /tmp/hapi-deploy.tgz -C /opt/icr-hapi && cd /opt/icr-hapi/gcp && sudo docker compose up -d'
```

`/opt/icr-hapi/gcp/.env` on the VM holds `FHIR_HOST` and `POSTGRES_PASSWORD` (see
`.env.example`); it is not in git. Settings that differ from the laptop stack are
environment overrides in `docker-compose.yml` (public `server_address` for paging links,
datasource password, heap), so `hapi.application.yaml` stays shared with `../`.

HAPI's port is not published on the VM. To reach it without going through Caddy, run
clients on the compose network, e.g.
`sudo docker run --rm --network icr-hapi_default curlimages/curl -s http://hapi:3447/fhir/Location?_summary=count`.

## API keys (FHIR Info Gateway)

[FHIR Info Gateway](https://github.com/google/fhir-gateway) v0.5.0 runs beside HAPI and
checks a Bearer token from Keycloak 26 (realm `icr`, database `keycloak` in the same
Postgres). An API key is a Keycloak client: the holder trades its id and secret for a
1-hour access token (OAuth client-credentials) and sends the token to the gateway. Any valid
token gets the whole FHIR API: `gateway/allowed-queries.json` lists every resource type and
system operation from HAPI's CapabilityStatement, so the stock `list` access checker is never
reached. No token → 401 (`/fhir/metadata` stays open).

Manage keys on the VM, from `/opt/icr-hapi/gcp`:

```bash
k() { sudo docker compose exec -T keycloak bash -s -- "$@" < gateway/api-key.sh; }
k create nkw      # prints client_id key-nkw and its secret; the secret is shown once
k list
k rotate nkw      # new secret, the old one stops working
k revoke nkw      # deletes the client; tokens already issued expire within the hour
```

Use a key:

```bash
TOKEN=$(curl -s https://auth.healthcampaigns.org/realms/icr/protocol/openid-connect/token \
  -d grant_type=client_credentials -d client_id=key-nkw --data-urlencode client_secret="$SECRET" \
  | jq -r .access_token)
curl -H "Authorization: Bearer $TOKEN" "https://gateway.healthcampaigns.org/fhir/Location?_count=5"
```

kiln takes the token as `--token` or `$KILN_TOKEN`. Paging links and `fullUrl`s come back with
the gateway's address (the gateway's `PROXY_TO` is HAPI's public address, so it can rewrite
them). Keycloak admin console: https://auth.healthcampaigns.org/admin (user `admin`,
`KEYCLOAK_ADMIN_PASSWORD` in `.env`).

Rollback: `sudo docker compose stop gateway keycloak` (HAPI, Postgres and Caddy keep running;
the two extra hostnames return 502). To remove them for good, deploy the previous
`docker-compose.yml`/`Caddyfile` and `sudo docker compose up -d --remove-orphans`;
`DROP DATABASE keycloak` removes Keycloak's data.

## Seed

Every dataset on the server is deterministic output of a generator in this repo, loaded with
`../load.py` (idempotent PUTs by id). Run the loads on the VM against `http://hapi:3447/fhir`
from a `python:3.13-alpine` container on `icr-hapi_default`, or from anywhere against the
public base URL.

1. IG resources (profiles, terminology, SearchParameters, worked examples):
   `sushi build .` in `ig/`, then `python3 load.py ig`.
2. Location registry (812 admin units, 51,022 facilities + paired Organizations, 292,438
   settlements): `uv run --no-project --with duckdb python ../registry-from-parquet.py`
   rebuilds the NDJSON from the kiln GeoParquet published at sdi.healthcampaigns.org (same
   ids, profiles and quadkey extension, boundaries re-attached), then
   `python3 load.py ndjson admin-unit.ndjson facility.ndjson settlement.ndjson`. WorldPop
   total-population Groups: `kiln population` over the admin-unit snapshot (see `../README.md`).
   The Nigeria demo campaigns reference the LGA ids minted here (`nga-<state>-<lgacode>`).
3. Nigeria demo campaigns: `tools/campaign-builder` (`python -m campaign_builder.build`,
   `python -m campaign_builder.totals --year 2026`), then
   `python3 load.py ndjson ../campaign-builder/out/0*.ndjson`.

> [!warning] Re-index after a fresh seed
> HAPI picks up new SearchParameters on a ~60 s cache refresh, so resources written right
> after `load.py ig` miss the custom indexes (`target-geography`, `geography`, `quadkey`).
> After the loads, `POST /fhir/$reindex` with `url` = `CarePlan?`, `Group?`, `Location?`.

> [!warning] The R2 parquet is the only full copy of the registry
> `tools/warehouse/push-r2.sh` mirrors `data/` to R2 with deletes. Run `refresh.sh` (no
> `--push`) against a loaded server first, so `data/parquet/locations` holds part files.
