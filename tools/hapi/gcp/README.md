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

Manage keys on the VM, from `/opt/icr-hapi/gcp`. On a first deploy run `k setup` once to
create the realm; the gateway reads the realm's public key at startup, so it restarts
(`unless-stopped`) until the realm exists and then stays up.

```bash
k() { sudo docker compose exec -T keycloak bash -s -- "$@" < gateway/api-key.sh; }
k setup          # first deploy only: creates realm icr
k create nkw      # prints client_id key-nkw and its secret (also in the admin console)
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

kiln takes the key itself and renews the token as it runs (`--client-id`, `--client-secret`,
`--token-url`, or `KILN_CLIENT_ID`/`KILN_CLIENT_SECRET`/`KILN_TOKEN_URL`); `--token` still takes
a fixed token. The warehouse refresh takes the key as `FHIR_CLIENT_ID`/`FHIR_CLIENT_SECRET`:

```bash
FHIR_BASE=https://gateway.healthcampaigns.org/fhir SERVER_NAME=hapi-gcp \
  FHIR_CLIENT_ID=key-nkw FHIR_CLIENT_SECRET="$SECRET" tools/warehouse/refresh.sh
```

Paging links and `fullUrl`s come back with the gateway's address (the gateway's `PROXY_TO` is
HAPI's public address, so it can rewrite them). Keycloak admin console: https://auth.healthcampaigns.org/admin (user `admin`,
`KEYCLOAK_ADMIN_PASSWORD` in `.env`).

Rollback: `sudo docker compose stop gateway keycloak` (HAPI, Postgres and Caddy keep running;
the two extra hostnames return 502). To remove them for good, deploy the previous
`docker-compose.yml`/`Caddyfile` and `sudo docker compose up -d --remove-orphans`;
`DROP DATABASE keycloak` removes Keycloak's data.

## Country servers

A country gets its own ICR server: its own HAPI and Postgres, and its own gateway at its own
address, with keys from its own Keycloak realm. A key for one country opens no other server, and
the country's HAPI has no open address. The country servers share this VM's Caddy (TLS) and
Keycloak (one realm each), so adding one costs about 1.5 GB of memory and no new machine.

```
                         ┌──────────────── main stack (icr-hapi) ─────────────────┐
https://hapi.…           │ Caddy ──▶ hapi ──▶ db                                  │
https://gateway.…        │   │  └──▶ gateway ──▶ hapi                             │
https://auth.…           │   │  └──▶ keycloak (realms icr, uga, …)                │
                         └───┼────────────────────────────────────────────────────┘
https://fhir-uga.…           └──▶ uga-gateway ──▶ country-hapi ──▶ db   (project icr-uga)
                                  token must come from realm uga         + daily pg_dump
```

| Country | Address | Realm | Env file on the VM |
| --- | --- | --- | --- |
| Uganda | `https://fhir-uga.healthcampaigns.org/fhir` | `uga` | `country/uga.env` |

The pieces, all in this folder:

- `country/docker-compose.yml`: one country's stack (Postgres, HAPI, gateway, a backup
  service). It's a separate compose project, `icr-<code>`. Only the gateway joins the main
  stack's network, as `<code>-gateway`, so Caddy can reach it.
- `country/<code>.env` (on the VM only): the country code, its address, the token issuer, its
  database password. `country/.env.example` shows the format.
- `sites/<code>.caddy`: the Caddy site for its address. The main `Caddyfile` imports `sites/*.caddy`.
- `country.sh`: the commands below. `add` writes the env and site files, creates the realm,
  starts the stack and reloads Caddy.

### Add a country

1. **DNS:** point the address at the VM: an A record `fhir-<code>` → `35.187.76.240`, DNS only (grey
   cloud), so Caddy can get a Let's Encrypt certificate.
2. **Deploy** this folder (see "Deploy / update"), then on the VM, from `/opt/icr-hapi/gcp`:

   ```bash
   sudo ./country.sh add uga fhir-uga.healthcampaigns.org
   sudo ./country.sh key uga create matt        # prints key-matt and its secret
   ```

   HAPI takes a minute or two to start. `https://fhir-uga.healthcampaigns.org/fhir/metadata` is
   open; everything else needs a token from realm `uga`.
3. **Load the IG's definitions** (profiles, terminology, search parameters, questionnaires,
   protocols, indicators; not its example data), from the repo root on any machine:

   ```bash
   python3 tools/hapi/load.py ig --definitions-only --base https://fhir-uga.healthcampaigns.org/fhir \
     --client-id key-matt --client-secret "$SECRET" \
     --token-url https://auth.healthcampaigns.org/realms/uga/protocol/openid-connect/token
   ```

4. **Load the country's data** with the same key: `load.py ndjson FILE…`, or `fhir-pipes load` with
   `--client-id`/`--client-secret`/`--token-url`. Give the country's resources ids with its code
   as prefix (`uga-…`), as Nigeria's are `nga-…`, so they can be moved or merged later.

### Run it

```bash
sudo ./country.sh ps                       # every country's containers
sudo ./country.sh up uga                   # start, or apply a changed config or image
sudo ./country.sh down uga                 # stop; the data stays
sudo ./country.sh key uga list             # also: rotate NAME, revoke NAME
sudo ./country.sh backup uga               # a pg_dump now
```

**Backups.** Unlike the main server, a country's data may not be regenerable from this repo, so
each country has a `backup` service. It runs `pg_dump` once a day after 02:00 UTC into the
volume `icr-<code>_backups` and keeps the last 14. The volume is on the VM's disk, so copy the
dumps off the VM if losing the VM must not lose the data. To restore, load a dump into an
empty `db` with `psql` before HAPI starts.

**Memory.** A country's HAPI gets a 1.5 GB heap (`HAPI_HEAP` in its env file). Its Postgres gets 256 MB
of shared buffers (`PG_SHARED_BUFFERS`). The whole stack uses about 1.5 GB idle. The main stack has
about 12.5 GB of the 16 GB allocated, so there is room for one or two countries before the main
HAPI's heap (`-Xmx6g`) or the machine size has to change.

**Moving a country to its own VM.** The stack needs only a Caddy and a Keycloak realm it can reach:

1. Run the main stack there, or just Caddy, with the same `sites/<code>.caddy`.
2. Copy the env file and start the country with `country.sh up`. Its gateway can keep trusting
   `auth.healthcampaigns.org`.
3. Restore the latest dump.
4. Move the DNS record.

### Using this elsewhere

Nothing in `country/` is specific to ICR's hosts. To copy the setup:

1. Run the main stack, `docker-compose.yml` and `Caddyfile`, with your own `.env`: hostnames,
   passwords.
2. Run `sudo docker compose exec -T keycloak bash -s -- setup < gateway/api-key.sh` once.
3. Add countries with `country.sh add CODE HOST`. It reads the Keycloak address from the main
   `.env` and finds the main stack's network itself.

The HAPI settings are `../hapi.application.yaml`, shared with the laptop stack.

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
> `tools/warehouse/refresh.sh --push` mirrors `data/` to R2 with deletes. Run `refresh.sh` (no
> `--push`) against a loaded server first, so `data/parquet/locations` holds part files.

## ICR servers on the Helios FHIR Server (hfs)

`hfs/` and `hfs.sh` are the go-forward way to run a named ICR server on the
[Helios FHIR Server](https://github.com/HeliosSoftware/hfs) (hfs, Rust, R4) on Postgres,
instead of HAPI's `country.sh`/`country/`. Each instance is one compose project
(`hfs/docker-compose.yml`, `icr-<name>`) with its own hfs, Postgres, FHIR Info Gateway and
daily backup, behind the main stack's Caddy. The name is free — a country, a programme, a
tenant — so it isn't tied to `country`.

hfs serves the FHIR base at root; the gateway exposes it at `/fhir` and strips the prefix
forwarding to hfs, so the public base is `…/fhir`, identical to HAPI. Auth is unchanged: the
gateway validates tokens from the instance's Keycloak realm, so an API key opens only its own
instance. hfs seeds ~1,372 spec SearchParameters into Postgres on first boot (a minute or two)
before it listens.

```bash
# point fhir-<name>.healthcampaigns.org at the VM (Cloudflare, DNS only) first, then on the VM:
sudo ./hfs.sh add NAME HOST [REALM]   # env file, Caddy site, realm (new, or REALM to reuse one), start
sudo ./hfs.sh key NAME create loader  # an API key in the instance's realm
sudo ./hfs.sh up NAME                 # start / apply config    down NAME: stop (data stays)
sudo ./hfs.sh backup NAME             # pg_dump now             ps: every instance's containers
```

**Web UI.** `sudo ./hfs.sh ui NAME` adds hfs's own web UI on the instance's host:
`https://HOST/fhir` stays the API behind the gateway (API keys, unchanged), and everything else
goes to a second hfs process (`hfs-ui`, profile `ui`) on the same Postgres, with auth on and
Keycloak sign-in at `https://HOST/ui`. Anyone with an account in the instance's realm can sign
in; the realm's `hfs-ui` client (`hfs/ui-client.sh`) grants `user/*.rs`, so it is read-only.

Copy data from an existing HAPI server with `hfs/migrate.py` (conformance first, batch bundles,
PUT by id; run it in a container on both compose networks — see the header in the file).

> [!note] The live Uganda instance
> Uganda was the first hfs cutover: compose project `icr-ugahfs` (env `hfs/ugahfs.env`), reusing
> the `uga` realm, at `fhir-uga.healthcampaigns.org` — `/fhir` the API, `/ui` the web UI. It is
> equivalent to `hfs.sh add ugahfs fhir-uga.healthcampaigns.org uga` then `hfs.sh ui ugahfs`;
> its Caddy site is `sites/ugahfs.caddy` (the HAPI-era one is kept as `sites/uga.caddy.hapi.bak`).
> The HAPI `icr-uga` and `icr-digit` stacks are stopped (volumes kept).

## Match-bot

[Match-bot](https://github.com/crosscutio/field-kit/tree/main/match-bot) (Crosscut's tool for
reconciling place names across datasets) runs at `https://matchbot.healthcampaigns.org`, behind
Keycloak sign-in. `matchbot/docker-compose.yml` (compose project `icr-matchbot`) has three
services:

- `app`: match-bot's web app under gunicorn, built from a pinned field-kit commit
  (`FIELD_KIT_REF` in `matchbot/Dockerfile`) on James McKinnon's `community-geocoder` branch,
  which has the Community Geocoder and the ICR SDI/FHIR import and is not yet on `main`. Uploads
  (each browser session's project) and the gazetteer cache are volumes.
- `proxy`: oauth2-proxy, the only service on the main stack's network; Caddy
  (`sites/matchbot.caddy`) sends the host to it. It signs people in with the `matchbot` client in
  realm `matchbot` (`matchbot/keycloak-client.sh`).
- `cleanup`: deletes uploads of sessions older than 14 days, daily; the app never removes them.

The chat box is off: it needs the Claude Code CLI, which the image does not include. Matching,
lookups, suggestions and geocoding don't use it.

```bash
# point matchbot.healthcampaigns.org at the VM (Cloudflare, DNS only) first, then on the VM:
sudo ./matchbot.sh add matchbot.healthcampaigns.org   # realm and client, env file, Caddy site, start
sudo ./matchbot.sh user someone@example.org           # add a user; prints a temporary password
sudo ./matchbot.sh up                                 # rebuild / apply config   down: stop (data stays)
sudo ./matchbot.sh logs
```

`matchbot/matchbot.env` (made by `add`, not in git) holds the host, the client secret, the
cookie secret and the main network's name; see `matchbot/matchbot.env.example`.
