#!/usr/bin/env bash
# Match-bot (crosscutio/field-kit's match-bot web app) at https://HOST behind Keycloak sign-in:
# matchbot/docker-compose.yml (match-bot, oauth2-proxy, an uploads cleanup), Caddy site
# sites/matchbot.caddy, and realm matchbot on the main stack's Keycloak.
# Run on the VM from /opt/icr-hapi/gcp, with sudo.
#
#   ./matchbot.sh add HOST            set it up: realm and client, env file, Caddy site, start it
#   ./matchbot.sh up                  rebuild and start, or apply changed config
#   ./matchbot.sh down                stop it (uploads and the gazetteer cache stay)
#   ./matchbot.sh user EMAIL          add a user to realm matchbot; prints a temporary password
#   ./matchbot.sh logs                follow the containers' logs
#
# Before `add`, point HOST's DNS at the VM (an A record; on Cloudflare, DNS only) so Caddy gets a cert.
set -euo pipefail
cd "$(dirname "$0")"

usage() { sed -n '7,11p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
ENV=matchbot/matchbot.env
REALM=matchbot
app() { docker compose -p icr-matchbot -f matchbot/docker-compose.yml --env-file "$ENV" "$@"; }
main() { docker compose "$@"; }   # the main stack (docker-compose.yml here: Caddy, Keycloak)
kc() { main exec -T "$@" keycloak bash -s; }

cmd=${1:-}; [ -n "$cmd" ] || usage
case "$cmd" in
  add)
    host=${2:-}
    [[ "$host" =~ ^[a-z0-9.-]+\.[a-z]+$ ]] || { echo "HOST: the public name, e.g. matchbot.healthcampaigns.org" >&2; exit 2; }
    [ -f .env ] || { echo "no .env here; run this from the main stack's folder" >&2; exit 1; }
    auth=$(grep -E '^AUTH_HOST=' .env | cut -d= -f2-)
    caddy=$(main ps -q caddy)
    [ -n "$caddy" ] || { echo "the main stack's Caddy isn't running" >&2; exit 1; }
    secret=$(kc -e REALM=$REALM -e HOST="$host" < matchbot/keycloak-client.sh | tail -1)
    [[ "$secret" == CLIENT_SECRET=?* ]] || { echo "no client secret from Keycloak" >&2; exit 1; }
    if [ ! -f "$ENV" ]; then
      net=$(docker inspect "$caddy" --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}')
      umask 077
      printf 'HOST=%s\nAUTH_HOST=%s\nREALM=%s\n%s\nCOOKIE_SECRET=%s\nMAIN_NETWORK=%s\n' \
        "$host" "$auth" "$REALM" "$secret" "$(openssl rand -hex 16)" "$net" > "$ENV"
      echo "== wrote $ENV"
    else
      sed -i "s|^CLIENT_SECRET=.*|$secret|" "$ENV"
    fi
    site=sites/matchbot.caddy
    if [ ! -f "$site" ]; then
      printf '# Match-bot (matchbot/docker-compose.yml, env file %s): oauth2-proxy in front of the app.\n%s {\n\tencode gzip\n\trequest_body {\n\t\tmax_size 500MB\n\t}\n\treverse_proxy matchbot-proxy:4180\n}\n' \
        "$ENV" "$host" > "$site"
      echo "== wrote $site"
    fi
    app up -d --build
    main exec -T caddy caddy reload --config /etc/caddy/Caddyfile
    echo "== https://$host is starting. Add people with: ./matchbot.sh user EMAIL"
    ;;
  up)   app up -d --build ;;
  down) app down ;;
  logs) app logs -f --tail 100 ;;
  user)
    email=${2:-}; [[ "$email" == *@*.* ]] || { echo "EMAIL: the person's address" >&2; exit 2; }
    pw=$(openssl rand -base64 12 | tr -d '/+=' | cut -c1-14)
    kc -e REALM=$REALM -e EMAIL="$email" -e PW="$pw" <<'EOF'
set -euo pipefail
K=/opt/keycloak/bin/kcadm.sh
$K config credentials --server http://localhost:8080 --realm master \
  --user "$KC_BOOTSTRAP_ADMIN_USERNAME" --password "$KC_BOOTSTRAP_ADMIN_PASSWORD" >/dev/null 2>&1
if [ -z "$($K get users -r "$REALM" -q "email=$EMAIL" -q exact=true --fields id 2>/dev/null | tr -d '[] \n')" ]; then
  $K create users -r "$REALM" -s username="$EMAIL" -s email="$EMAIL" -s emailVerified=true -s enabled=true >/dev/null
fi
$K set-password -r "$REALM" --username "$EMAIL" --new-password "$PW" --temporary
EOF
    echo "== $email in realm $REALM; temporary password (changed at first sign-in): $pw"
    ;;
  *) usage ;;
esac
