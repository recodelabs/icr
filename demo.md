# ICR demo FHIR server

The ICR demo server is a HAPI FHIR R4 server with the [ICR Implementation Guide](https://icr.healthcampaigns.org/)
loaded and populated with a Nigerian location registry and demo campaign data. You reach it
through the FHIR Info Gateway with an API key.

| | |
| --- | --- |
| FHIR base URL | `https://gateway.healthcampaigns.org/fhir` |
| Token URL | `https://auth.healthcampaigns.org/realms/icr/protocol/openid-connect/token` |
| FHIR version | R4 (4.0.1), HAPI FHIR 8.12 |
| Implementation Guide | https://icr.healthcampaigns.org/ |
| CapabilityStatement | `https://gateway.healthcampaigns.org/fhir/metadata` (no key needed) |

## What is on the server

| Data | Resources | Source |
| --- | --- | --- |
| Admin units: Nigeria, 37 states, 774 LGAs, with boundaries | 812 `Location` | GRID3 |
| Health facilities, each with its `Organization` | 51,022 `Location` + `Organization` | GRID3 |
| Settlements | 292,438 `Location` | GRID3 |
| Schools, community distribution points, facility and settlement catchments | about 2,500 `Location` | demo microplanning data |
| Campaigns (immunization, polio, NTD MDA, malaria) across Nigerian LGAs, 2022–2027 | 3,201 `CarePlan` (ICRCampaign) | generated demo data |
| Target populations (WorldPop and planning denominators) | 14,120 `Group` (ICRTargetPopulation) | WorldPop, generated demo data |
| Campaign protocols | 13 `PlanDefinition`, 12 `ActivityDefinition` | IG |
| Coverage, cost and readiness measures and results | 7 `Measure`, 2,892 `MeasureReport` | IG, generated demo data |
| Profiles, terminology, SearchParameters and the IG's worked examples | `StructureDefinition`, `ValueSet`, `CodeSystem`, … | IG |

The campaigns, coverage results and microplanning data are generated for the demo. They are
not real campaign records.

## Get an API key

Ask Matt Berg (Ona) for a key. You will receive two values:

- `client_id`, in the form `key-<name>`
- `client_secret`

Keep the secret private. Each person or organization gets its own key so that one key can be
revoked without affecting anyone else.

## Get an access token

The key is an OAuth 2.0 client. Trade it for an access token with the client-credentials
grant, then send the token as `Authorization: Bearer <token>` on every request. A token lasts
one hour. When a request returns 401, get a new token.

```bash
export CLIENT_ID=key-<name>
export CLIENT_SECRET=<secret>

TOKEN=$(curl -s https://auth.healthcampaigns.org/realms/icr/protocol/openid-connect/token \
  -d grant_type=client_credentials -d client_id="$CLIENT_ID" \
  --data-urlencode client_secret="$CLIENT_SECRET" | jq -r .access_token)

curl -H "Authorization: Bearer $TOKEN" \
  "https://gateway.healthcampaigns.org/fhir/Location?name=Akko&type=admin-unit"
```

Python:

```python
import os
import requests

TOKEN_URL = "https://auth.healthcampaigns.org/realms/icr/protocol/openid-connect/token"
BASE = "https://gateway.healthcampaigns.org/fhir"

token = requests.post(TOKEN_URL, data={
    "grant_type": "client_credentials",
    "client_id": os.environ["CLIENT_ID"],
    "client_secret": os.environ["CLIENT_SECRET"],
}).json()["access_token"]

fhir = requests.Session()
fhir.headers["Authorization"] = f"Bearer {token}"

bundle = fhir.get(f"{BASE}/CarePlan", params={"target-geography": "Location/nga-go-16001"}).json()
for entry in bundle.get("entry", []):
    print(entry["resource"]["title"])
```

In Postman or Insomnia, choose OAuth 2.0 with grant type **Client Credentials**, the token URL
above, and your client id and secret. Sending the credentials in the request body and sending
them as a Basic Auth header both work.

## Example queries

Every query below needs the `Authorization` header. Add `&_summary=count` to get only the
total.

```bash
B=https://gateway.healthcampaigns.org/fhir
H="Authorization: Bearer $TOKEN"

# Find an LGA by name
curl -H "$H" "$B/Location?name=Akko&type=admin-unit"

# The LGAs in a state (Gombe), and the health facilities in one LGA (Akko)
curl -H "$H" "$B/Location?partof=Location/nga-go&type=admin-unit"
curl -H "$H" "$B/Location?partof=Location/nga-go-16001&type=facility"

# Campaigns that target an LGA, all years and in 2026 only
curl -H "$H" "$B/CarePlan?target-geography=Location/nga-go-16001"
curl -H "$H" "$B/CarePlan?target-geography=Location/nga-go-16001&date=ge2026-01-01&date=le2026-12-31"

# Campaigns in every LGA of a state
curl -H "$H" "$B/CarePlan?target-geography.partof=Location/nga-go"

# Target populations (denominators) for an LGA
curl -H "$H" "$B/Group?geography=Location/nga-go-16001"

# Campaign protocols and measures
curl -H "$H" "$B/PlanDefinition?_elements=title"
curl -H "$H" "$B/Measure?_elements=title"
```

`target-geography`, `geography` and `quadkey` are search parameters defined in the IG.
Location ids follow the admin hierarchy: `nga` is Nigeria, `nga-go` is Gombe State and
`nga-go-16001` is Akko LGA.

Results come back in pages. Follow the `link` with `relation` = `next` in each Bundle until
there is none. The links point at the gateway, so the same token works on them.

> [!warning] The key can also write
> An API key can create, update and delete resources. This is a shared demo server, so read
> only unless you have agreed a test with the ICR team. Anything written may be lost when the
> server is reloaded.

## kiln: export the location registry to GeoParquet

[kiln](https://github.com/recodelabs/kiln) copies the `Location` resources from a FHIR server
into a GeoParquet dataset that QGIS, DuckDB, GeoPandas and web maps read directly. It can also
send edits made in those tools back to the server. It is a single binary with no runtime
dependencies.

If you only need the data and not the FHIR round trip, the same registry is published as
GeoParquet at https://sdi.healthcampaigns.org with no key, for example:

```sql
-- DuckDB
SELECT count(*) FROM read_parquet('https://sdi.healthcampaigns.org/parquet/locations/country=NGA/geom_type=point/type=facility/part-0.parquet');
```

### Install kiln

kiln is built from source with Rust. On macOS or Linux:

```bash
# 1. Install Rust (skip if `cargo --version` already works)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"

# 2. Build and install kiln into ~/.cargo/bin (takes a few minutes)
cargo install --git https://github.com/recodelabs/kiln --locked kiln

kiln --version
```

On Windows, install Rust with `rustup-init.exe` from https://rustup.rs, then run the same
`cargo install` command.

To update kiln later, run the `cargo install` command again with `--force`.

### Set up the key

kiln trades the key for tokens itself and gets a new token before the old one expires, so a
long run is not cut off. Set the key once per shell:

```bash
export KILN_CLIENT_ID=key-<name>
export KILN_CLIENT_SECRET=<secret>
export KILN_TOKEN_URL=https://auth.healthcampaigns.org/realms/icr/protocol/openid-connect/token
```

The same values can be passed as `--client-id`, `--client-secret` and `--token-url`. Using the
environment keeps the secret out of your shell history.

### Export the registry

```bash
kiln run --server https://gateway.healthcampaigns.org/fhir --snapshot icr-snapshot --out icr-out
```

- `icr-snapshot/` holds the raw `Location` and `Organization` resources (about 440 MB) and
  the point the next run continues from.
- `icr-out/locations/` is the GeoParquet dataset (about 100 MB), split by country, geometry
  type and location type, e.g. `country=NGA/geom_type=point/type=facility/part-0.parquet`.

The first run downloads every Location and takes about 15 minutes. Later runs with the same
`--snapshot` fetch only what changed since the last run and finish in about a minute.

Check what was written:

```bash
kiln inspect --out icr-out
```

### Use the output

DuckDB:

```sql
-- Health facilities per state
SELECT admin1_name AS state, count(*) AS facilities
FROM read_parquet('icr-out/locations/country=NGA/geom_type=point/type=facility/*.parquet')
GROUP BY state ORDER BY facilities DESC;

-- Every location, by type
SELECT country, type, count(*) AS n
FROM read_parquet('icr-out/locations/**/*.parquet', hive_partitioning = true)
GROUP BY ALL ORDER BY n DESC;
```

QGIS: drag a `part-0.parquet` file onto the map. The
[kiln QGIS guide](https://github.com/recodelabs/kiln/blob/main/docs/qgis.md) covers styling,
editing and sending edits back.

### Send edits back

`kiln diff` compares an edited file with the snapshot and writes only the changed resources,
and `kiln load` sends them to the server with a version check on each one. Run `kiln load
--dry-run` first. Loading writes to the shared demo server, so agree it with the ICR team
before you load. See [Round trip: diff and load](https://github.com/recodelabs/kiln#round-trip-diff-and-load)
in the kiln README.
