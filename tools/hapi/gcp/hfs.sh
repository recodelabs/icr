#!/usr/bin/env bash
# Named ICR servers on the Helios FHIR Server (hfs) — the go-forward alternative to HAPI's
# country.sh. One compose project per instance (hfs/docker-compose.yml), each with its own hfs,
# Postgres, gateway and (by default) Keycloak realm, behind the main stack's Caddy.
# Run on the VM from /opt/icr-hapi/gcp, with sudo.
#
#   ./hfs.sh add NAME HOST [REALM]    set up an instance: env file, Caddy site, realm, start it
#   ./hfs.sh up NAME                  start it, or apply changed config
#   ./hfs.sh down NAME               stop it (the data stays)
#   ./hfs.sh key NAME create KEY     API key in the instance's realm (also: list, rotate KEY, revoke KEY)
#   ./hfs.sh backup NAME             pg_dump now (the backup service also makes one daily)
#   ./hfs.sh ps                      every instance's containers
#
# NAME is the instance id (compose project icr-NAME, gateway alias NAME-gateway) — a country,
# programme, tenant, anything in [a-z][a-z0-9]{1,15}. HOST is its public FHIR server name (e.g.
# fhir-NAME.healthcampaigns.org). REALM is the Keycloak realm; it defaults to NAME and is created,
# or pass an existing realm to reuse it (nothing is created, so shared users/groups stay intact).
# Before `add`, point HOST's DNS at the VM (an A record; on Cloudflare, DNS only) so Caddy gets a cert.
set -euo pipefail
cd "$(dirname "$0")"

usage() { sed -n '7,13p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
name_ok() { [[ "${1:-}" =~ ^[a-z][a-z0-9]{1,15}$ ]] || { echo "NAME: lowercase letters and digits, e.g. uga" >&2; exit 2; }; }
env_file() { echo "hfs/$1.env"; }
realm_of() { grep -E '^REALM=' "$(env_file "$1")" | cut -d= -f2-; }
instance() {
  local env; env=$(env_file "$1")
  [ -f "$env" ] || { echo "no $env; run ./hfs.sh add $1 HOST first" >&2; exit 1; }
  docker compose -p "icr-$1" -f hfs/docker-compose.yml --env-file "$env" "${@:2}"
}
main() { docker compose "$@"; }   # the main stack (docker-compose.yml here: Caddy, Keycloak)
keys() { local realm=$1; shift; main exec -T -e REALM="$realm" keycloak bash -s -- "$@" < gateway/api-key.sh; }

cmd=${1:-}; [ -n "$cmd" ] || usage
case "$cmd" in
  add)
    name=${2:-}; host=${3:-}; realm=${4:-}; name_ok "$name"
    [[ "$host" =~ ^[a-z0-9.-]+\.[a-z]+$ ]] || { echo "HOST: the server's public name, e.g. fhir-$name.healthcampaigns.org" >&2; exit 2; }
    [ -f .env ] || { echo "no .env here; run this from the main stack's folder" >&2; exit 1; }
    auth=$(grep -E '^AUTH_HOST=' .env | cut -d= -f2-)
    reuse=1; [ -n "$realm" ] || { realm="$name"; reuse=0; }   # no REALM given → create one named NAME
    env=$(env_file "$name")
    caddy=$(main ps -q caddy)
    [ -n "$caddy" ] || { echo "the main stack's Caddy isn't running" >&2; exit 1; }
    if [ ! -f "$env" ]; then
      # the main stack's network, which the instance's gateway joins so Caddy can reach it
      net=$(docker inspect "$caddy" --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}')
      umask 077
      printf 'SERVER=%s\nFHIR_HOST=%s\nREALM=%s\nTOKEN_ISSUER=https://%s/realms/%s\nPOSTGRES_PASSWORD=%s\nMAIN_NETWORK=%s\n' \
        "$name" "$host" "$realm" "$auth" "$realm" "$(openssl rand -hex 24)" "$net" > "$env"
      echo "== wrote $env"
    fi
    site=sites/$name.caddy
    if [ ! -f "$site" ]; then
      printf '# %s ICR server on hfs (hfs/docker-compose.yml, env file %s): the gateway only.\n%s {\n\tencode gzip\n\treverse_proxy %s-gateway:8080\n}\n' \
        "$name" "$env" "$host" "$name" > "$site"
      echo "== wrote $site"
    fi
    main exec -T caddy test -d /etc/caddy/sites || {
      echo "Caddy has no sites folder; run 'docker compose up -d' for the main stack first" >&2; exit 1; }
    if [ "$reuse" = 0 ]; then keys "$realm" setup; else echo "== reusing realm $realm (not created)"; fi
    instance "$name" up -d
    main exec -T caddy caddy reload --config /etc/caddy/Caddyfile
    cat <<EOF
== $name is starting (hfs seeds SearchParameters on first boot, a minute or two). Next:
   ./hfs.sh key $name create KEY     an API key for the person or tool that loads data
   https://$host/fhir/metadata       open without a key once hfs is up
EOF
    ;;
  up) name_ok "${2:-}"; instance "$2" up -d ;;
  down) name_ok "${2:-}"; instance "$2" stop ;;
  key)
    name_ok "${2:-}"; [ -f "$(env_file "$2")" ] || { echo "no instance $2" >&2; exit 1; }
    keys "$(realm_of "$2")" "${@:3}" ;;
  backup)
    name_ok "${2:-}"
    instance "$2" exec -T backup sh -c 'set -o pipefail; f=/backups/$SERVER-$(date -u +%Y%m%dT%H%MZ)-manual.sql.gz;
      pg_dump | gzip > $f.tmp && mv $f.tmp $f && ls -l $f' ;;
  ps)
    docker ps --filter label=com.docker.compose.project --format '{{.Label "com.docker.compose.project"}}\t{{.Names}}\t{{.Status}}' \
      | grep -E '^icr-' | grep -v '^icr-hapi' | sort ;;
  *) usage ;;
esac
