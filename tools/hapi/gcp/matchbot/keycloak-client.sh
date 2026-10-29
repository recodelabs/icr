#!/usr/bin/env bash
# The Keycloak realm and client for match-bot's sign-in: realm $REALM (default matchbot) and a
# confidential client `matchbot` for oauth2-proxy, redirecting to https://$HOST/oauth2/callback.
# Prints the client secret as the last line (CLIENT_SECRET=…), which matchbot.sh writes to
# matchbot.env.
#
# Runs inside the keycloak container (kcadm.sh). From /opt/icr-hapi/gcp, matchbot.sh calls it as:
#
#   sudo docker compose exec -T -e REALM=matchbot -e HOST=matchbot.healthcampaigns.org \
#     keycloak bash -s < matchbot/keycloak-client.sh
#
# Safe to run again: it creates what is missing and resets the redirect URIs to HOST.
set -euo pipefail
K=/opt/keycloak/bin/kcadm.sh
REALM=${REALM:-matchbot}
: "${HOST:?set HOST}"
CLIENT=matchbot

$K config credentials --server http://localhost:8080 --realm master \
  --user "$KC_BOOTSTRAP_ADMIN_USERNAME" --password "$KC_BOOTSTRAP_ADMIN_PASSWORD" >/dev/null 2>&1

if ! $K get "realms/$REALM" >/dev/null 2>&1; then
  $K create realms -s realm="$REALM" -s enabled=true -s displayName="Match-bot" \
    -s registrationAllowed=false -s resetPasswordAllowed=false >/dev/null
  echo "== created realm $REALM" >&2
fi

client_id() { $K get clients -r "$REALM" -q "clientId=$1" --fields id 2>/dev/null | tr -d '\n ' \
  | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4 || true; }

cid=$(client_id "$CLIENT")
if [ -z "$cid" ]; then
  $K create clients -r "$REALM" -s clientId=$CLIENT -s name="Match-bot" -s publicClient=false \
    -s standardFlowEnabled=true -s directAccessGrantsEnabled=false -s serviceAccountsEnabled=false >/dev/null
  cid=$(client_id "$CLIENT"); echo "== created client $CLIENT" >&2
fi
$K update "clients/$cid" -r "$REALM" \
  -s "redirectUris=[\"https://$HOST/oauth2/callback\"]" -s "webOrigins=[\"https://$HOST\"]" \
  -s 'attributes."pkce.code.challenge.method"=S256' \
  -s "attributes.\"post.logout.redirect.uris\"=https://$HOST/*"
echo "== $CLIENT in realm $REALM → https://$HOST/oauth2/callback" >&2

# oauth2-proxy's keycloak-oidc provider checks the access token's audience, which Keycloak sets
# to `account` unless an audience mapper adds the client.
if ! $K get "clients/$cid/protocol-mappers/models" -r "$REALM" --fields name 2>/dev/null | grep -q '"matchbot-audience"'; then
  $K create "clients/$cid/protocol-mappers/models" -r "$REALM" -s name=matchbot-audience \
    -s protocol=openid-connect -s protocolMapper=oidc-audience-mapper \
    -s 'config."included.client.audience"=matchbot' -s 'config."access.token.claim"=true' \
    -s 'config."id.token.claim"=false' >/dev/null
  echo "== added audience mapper matchbot-audience" >&2
fi

# The secret is the last line of stdout.
$K get "clients/$cid/client-secret" -r "$REALM" --fields value | tr -d '\n ' \
  | grep -o '"value":"[^"]*"' | cut -d'"' -f4 | sed 's/^/CLIENT_SECRET=/'
