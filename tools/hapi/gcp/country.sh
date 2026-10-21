#!/usr/bin/env bash
# Country ICR servers on the hosted VM: one compose project per country (country/docker-compose.yml),
# each with its own HAPI, Postgres, gateway and Keycloak realm, behind the main stack's Caddy.
# Run on the VM from /opt/icr-hapi/gcp, with sudo.
#
#   ./country.sh add CODE HOST          set up a country: env file, Caddy site, realm, start it
#   ./country.sh up CODE                start it, or apply changed config
#   ./country.sh down CODE              stop it (the data stays)
#   ./country.sh key CODE create NAME   API key in the country's realm (also: list, rotate NAME, revoke NAME)
#   ./country.sh backup CODE            pg_dump now (the backup service also makes one daily)
#   ./country.sh ps                     every country's containers
#
# CODE is the realm name and the id prefix of the country's resources (e.g. uga), HOST the
# public name of its FHIR server (e.g. fhir-uga.healthcampaigns.org). Before `add`, point HOST's
# DNS at the VM (an A record; on Cloudflare, DNS only) so Caddy can get a certificate.
set -euo pipefail
cd "$(dirname "$0")"

usage() { sed -n '5,10p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
code_ok() { [[ "${1:-}" =~ ^[a-z][a-z0-9]{1,15}$ ]] || { echo "CODE: lowercase letters and digits, e.g. uga" >&2; exit 2; }; }
env_file() { echo "country/$1.env"; }
country() {
  local env; env=$(env_file "$1")
  [ -f "$env" ] || { echo "no $env; run ./country.sh add $1 HOST first" >&2; exit 1; }
  docker compose -p "icr-$1" -f country/docker-compose.yml --env-file "$env" "${@:2}"
}
main() { docker compose "$@"; }   # the main stack (docker-compose.yml here: Caddy, Keycloak)
keys() { local realm=$1; shift; main exec -T -e REALM="$realm" keycloak bash -s -- "$@" < gateway/api-key.sh; }

cmd=${1:-}; [ -n "$cmd" ] || usage
case "$cmd" in
  add)
    code=${2:-}; host=${3:-}; code_ok "$code"
    [[ "$host" =~ ^[a-z0-9.-]+\.[a-z]+$ ]] || { echo "HOST: the server's public name, e.g. fhir-$code.healthcampaigns.org" >&2; exit 2; }
    [ -f .env ] || { echo "no .env here; run this from the main stack's folder" >&2; exit 1; }
    auth=$(grep -E '^AUTH_HOST=' .env | cut -d= -f2-)
    env=$(env_file "$code")
    caddy=$(main ps -q caddy)
    [ -n "$caddy" ] || { echo "the main stack's Caddy isn't running" >&2; exit 1; }
    if [ ! -f "$env" ]; then
      # the main stack's network, which the country's gateway joins so Caddy can reach it
      net=$(docker inspect "$caddy" --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}')
      umask 077
      printf 'COUNTRY=%s\nFHIR_HOST=%s\nTOKEN_ISSUER=https://%s/realms/%s\nPOSTGRES_PASSWORD=%s\nMAIN_NETWORK=%s\n' \
        "$code" "$host" "$auth" "$code" "$(openssl rand -hex 24)" "$net" > "$env"
      echo "== wrote $env"
    fi
    site=sites/$code.caddy
    if [ ! -f "$site" ]; then
      printf '# %s ICR server (country/docker-compose.yml, env file %s): the gateway only.\n%s {\n\tencode gzip\n\treverse_proxy %s-gateway:8080\n}\n' \
        "$code" "$env" "$host" "$code" > "$site"
      echo "== wrote $site"
    fi
    main exec -T caddy test -d /etc/caddy/sites || {
      echo "Caddy has no sites folder; run 'docker compose up -d' for the main stack first" >&2; exit 1; }
    keys "$code" setup
    country "$code" up -d
    main exec -T caddy caddy reload --config /etc/caddy/Caddyfile
    cat <<EOF
== $code is starting (HAPI takes a minute or two). Next:
   ./country.sh key $code create NAME     an API key for the person or tool that loads data
   https://$host/fhir/metadata            open without a key once HAPI is up
EOF
    ;;
  up) code_ok "${2:-}"; country "$2" up -d ;;
  down) code_ok "${2:-}"; country "$2" stop ;;
  key)
    code_ok "${2:-}"; [ -f "$(env_file "$2")" ] || { echo "no country $2" >&2; exit 1; }
    keys "$2" "${@:3}" ;;
  backup)
    code_ok "${2:-}"
    country "$2" exec -T backup sh -c 'set -o pipefail; f=/backups/$COUNTRY-$(date -u +%Y%m%dT%H%MZ)-manual.sql.gz;
      pg_dump | gzip > $f.tmp && mv $f.tmp $f && ls -l $f' ;;
  ps)
    docker ps --filter label=com.docker.compose.project --format '{{.Label "com.docker.compose.project"}}\t{{.Names}}\t{{.Status}}' \
      | grep -E '^icr-' | grep -v '^icr-hapi' | sort ;;
  *) usage ;;
esac
