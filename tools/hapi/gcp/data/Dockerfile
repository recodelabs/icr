# fhir-pipes serve for data.healthcampaigns.org: the fhir-pipes release binary, the duckdb CLI
# it runs SQL with, and tippecanoe for the tiles step (a refresh always runs it; fhir-pipes has
# no setting to leave it out). No rclone: serve does not push.

# tippecanoe, built from felt/tippecanoe's release.
FROM debian:12-slim AS tippecanoe
ARG TIPPECANOE_VERSION=2.79.0
RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential ca-certificates curl libsqlite3-dev zlib1g-dev \
 && curl -fsSL "https://github.com/felt/tippecanoe/archive/refs/tags/${TIPPECANOE_VERSION}.tar.gz" | tar xz -C /tmp \
 && make -C "/tmp/tippecanoe-${TIPPECANOE_VERSION}" -j"$(nproc)" tippecanoe \
 && install -m 0755 "/tmp/tippecanoe-${TIPPECANOE_VERSION}/tippecanoe" /usr/local/bin/tippecanoe

FROM debian:12-slim

ARG FHIR_PIPES_VERSION=0.7.0
# The duckdb version fhir-pipes' CI tests with.
ARG DUCKDB_VERSION=1.5.6

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl unzip libsqlite3-0 zlib1g libstdc++6 \
 && rm -rf /var/lib/apt/lists/*
COPY --from=tippecanoe /usr/local/bin/tippecanoe /usr/local/bin/tippecanoe

# The binary is checked against the release's SHA256SUMS.
RUN set -eu; \
    base="https://github.com/ohs-foundation/fhir-pipes-rs/releases/download/v${FHIR_PIPES_VERSION}"; \
    file=fhir-pipes-x86_64-unknown-linux-musl; \
    cd /tmp; \
    curl -fsSLO "$base/$file"; \
    curl -fsSLO "$base/SHA256SUMS"; \
    grep " $file\$" SHA256SUMS | sha256sum -c -; \
    install -m 0755 "$file" /usr/local/bin/fhir-pipes; \
    rm -f "$file" SHA256SUMS; \
    curl -fsSL -o duckdb.zip "https://github.com/duckdb/duckdb/releases/download/v${DUCKDB_VERSION}/duckdb_cli-linux-amd64.zip"; \
    unzip -q duckdb.zip -d /usr/local/bin; \
    rm duckdb.zip; \
    fhir-pipes --version; \
    duckdb --version; \
    tippecanoe --version

# serve and its refreshes run as this user. The warehouse volume is its home, so DuckDB keeps
# the extensions it downloads there.
RUN useradd --create-home --home-dir /warehouse --uid 10001 pipes
USER pipes
WORKDIR /warehouse
# duckdb 2.0 changes its output when it thinks an agent runs it; keep 1.x behaviour either way.
ENV DUCKDB_AGENT_MODE=0
# The tiles step needs spatial and the refresh does not install it. A new warehouse volume
# starts with what the image has here; on an existing one, run this line in the container.
RUN duckdb -c "INSTALL spatial"

ENTRYPOINT ["fhir-pipes"]
CMD ["serve", "--config", "/config/fhir-pipes.toml", "--listen", "0.0.0.0:8090"]
