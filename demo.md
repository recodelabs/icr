# ICR demo FHIR server

The ICR demo server is a HAPI FHIR R4 server with the [ICR Implementation Guide](https://icr.healthcampaigns.org/)
loaded and populated with a Nigerian location registry and demo campaign data. You can browse
it in a web browser with [Cinder](#browse-the-data-in-cinder), or reach it from code through
the FHIR Info Gateway with an API key.

| | |
| --- | --- |
| FHIR base URL | `https://gateway.healthcampaigns.org/fhir` |
| Token URL | `https://auth.healthcampaigns.org/realms/icr/protocol/openid-connect/token` |
| FHIR version | R4 (4.0.1), HAPI FHIR 8.12 |
| Implementation Guide | https://icr.healthcampaigns.org/ |
| CapabilityStatement | `https://gateway.healthcampaigns.org/fhir/metadata` (no key needed) |
| Browse in a web browser | https://cinder.recodelabs.org |

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

## Browse the data in Cinder

[Cinder](https://cinder.recodelabs.org) is a FHIR browser. It shows the server's resources in
a web browser, so you don't need an API key or any code. Cinder reads the server through the
gateway with its own key.

1. Get a Cinder login. You will receive either an ICR account or access for your Google
   account.
2. Open https://cinder.recodelabs.org and choose **Sign in with ICR** for an ICR account, or
   **Sign in with Google**.
3. Choose the org you were added to from **Select Org** at the top right, then the demo
   server's project from **Select Project**.

Then:

- Pick a resource type in the left sidebar, for example `Location`, `CarePlan` or `Group`, to
  list and search it. Open a resource to see its fields and follow its references, for
  example from a health facility's `Location` to its LGA.
- **Map** shows `Location` boundaries and points. Filter it by ICR location type and by
  parent, for example the LGAs in one state.

Signing out of Cinder doesn't sign you out of your ICR account. On a shared computer, close
the browser when you finish.

> [!warning] Cinder can also write
> Cinder can create, edit and delete resources on the server. This is a shared demo server,
> so read only unless you have agreed a test with the ICR team.

### Set up an org and project for the demo server in Cinder

Do this once to give a group access to the demo server in Cinder, or to use your own API key.
You need the API key's client id and secret; the secret is not in this document.

1. Sign in at https://cinder.recodelabs.org.
2. Create the org. Open **Select Org** at the top right and choose **Create Organization**.
   Enter a name, for example `ICR Demo`; the slug fills itself in. Leave the Google Cloud
   Healthcare API settings as they are, because FHIR server projects don't use them. Choose
   **Create Organization**. If Cinder then opens the **Credentials** tab, skip it.
3. Create the project. Open **Select Project** and choose **Create Project**. Enter a name, for
   example `ICR demo server`, and fill in:

   | Field | Value |
   | --- | --- |
   | Server type | **FHIR server (HAPI, etc.)** (the form starts on Google Cloud Healthcare) |
   | FHIR base URL | `https://gateway.healthcampaigns.org/fhir` |
   | OAuth client credentials | on |
   | Token URL | `https://auth.healthcampaigns.org/realms/icr/protocol/openid-connect/token` |
   | Client ID | `key-icrdemo` for the shared demo key, or your own `key-<name>` |
   | Client secret | the key's secret |

   Choose **Create Project**. Cinder stores the secret encrypted and never shows it again. To
   use a different key later, edit the project and enter its client id and secret.
4. Check it works. Pick `Location` in the left sidebar; you should see the location registry.
5. Add people. Open **Select Org** and choose **Org Settings**. On the **Members** tab, enter a
   person's email and choose **Add Member**. Someone who hasn't signed in to Cinder yet is
   listed as **Invited** and gets access the first time they sign in with that email, with
   ICR or Google.

## Get an API key

You will receive two values:

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

## fhir-pipes: export the location registry to GeoParquet

[fhir-pipes](https://github.com/ohs-foundation/fhir-pipes-rs) (formerly kiln) copies the
`Location` resources from a FHIR server into a GeoParquet dataset that QGIS, DuckDB,
GeoPandas and web maps read directly. It can also send edits made in those tools back to the
server, and it builds the ICR warehouse (`tools/warehouse/refresh.sh`). It is a single binary
with no runtime dependencies.

If you only need the data and not the FHIR round trip, the same registry is published as
GeoParquet at https://sdi.healthcampaigns.org with no key, for example:

```sql
-- DuckDB
SELECT count(*) FROM read_parquet('https://sdi.healthcampaigns.org/parquet/locations/country=NGA/geom_type=point/type=facility/part-0.parquet');
```

### Install fhir-pipes

fhir-pipes is built from source with Rust. On macOS or Linux:

```bash
# 1. Install Rust (skip if `cargo --version` already works)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"

# 2. Build and install fhir-pipes into ~/.cargo/bin (takes a few minutes)
cargo install --git https://github.com/ohs-foundation/fhir-pipes-rs --locked fhir-pipes

fhir-pipes --version
```

On Windows, install Rust with `rustup-init.exe` from https://rustup.rs, then run the same
`cargo install` command.

To update fhir-pipes later, run the `cargo install` command again with `--force`.

### Set up the key

fhir-pipes trades the key for tokens itself and gets a new token before the old one expires,
so a long run is not cut off. Set the key once per shell:

```bash
export FHIR_PIPES_CLIENT_ID=key-<name>
export FHIR_PIPES_CLIENT_SECRET=<secret>
export FHIR_PIPES_TOKEN_URL=https://auth.healthcampaigns.org/realms/icr/protocol/openid-connect/token
```

The same values can be passed as `--client-id`, `--client-secret` and `--token-url`. Using the
environment keeps the secret out of your shell history.

### Export the registry

```bash
fhir-pipes run --server https://gateway.healthcampaigns.org/fhir \
  --profile https://raw.githubusercontent.com/recodelabs/icr/main/ig/fhir-pipes-profile.toml \
  --snapshot icr-snapshot --out icr-out
```

`--profile` is ICR's fhir-pipes profile (`ig/fhir-pipes-profile.toml`): it adds
the ICR columns (`pcode`, `settlement_type`, `facility_level`, `nhfr_code`, …),
the admin hierarchy and the `country` partitions. The snapshot keeps a copy, so
later `fhir-pipes diff` and `transform locations` runs on it need no `--profile`.

- `icr-snapshot/` holds the raw `Location` and `Organization` resources (about 440 MB) and
  the point the next run continues from.
- `icr-out/locations/` is the GeoParquet dataset (about 100 MB), split by country, geometry
  type and location type, e.g. `country=NGA/geom_type=point/type=facility/part-0.parquet`.

The first run downloads every Location and takes about 15 minutes. Later runs with the same
`--snapshot` fetch only what changed since the last run and finish in about a minute.

Check what was written:

```bash
fhir-pipes inspect --out icr-out
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
[fhir-pipes QGIS guide](https://github.com/ohs-foundation/fhir-pipes-rs/blob/main/docs/qgis.md)
covers styling, editing and sending edits back.

### Send edits back

`fhir-pipes diff` compares an edited file with the snapshot and writes only the changed
resources, and `fhir-pipes load` sends them to the server with a version check on each one.
Run `fhir-pipes load --dry-run` first. Loading writes to the shared demo server, so agree it
with the ICR team before you load. See
[Round trip: diff and load](https://github.com/ohs-foundation/fhir-pipes-rs/blob/main/docs/locations.md#round-trip-diff-and-load)
in the fhir-pipes docs.
