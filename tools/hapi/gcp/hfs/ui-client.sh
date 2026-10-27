#!/usr/bin/env bash
# The Keycloak client for an hfs instance's web UI sign-in: a public client (PKCE S256) named
# `hfs-ui` in the instance's realm, whose tokens carry the SMART scope `user/*.rs` (read and
# search every resource type; no writes). hfs's own bundled realm (docker/keycloak/realm.json in
# HeliosSoftware/hfs) is set up the same way, with `user/*.cruds`.
#
# Runs inside the keycloak container (kcadm.sh). From /opt/icr-hapi/gcp, hfs.sh calls it as:
#
#   sudo docker compose exec -T -e REALM=uga -e UI_HOST=fhir-uga.healthcampaigns.org \
#     keycloak bash -s < hfs/ui-client.sh
#
# Safe to run again: it creates what is missing and resets the redirect URIs to UI_HOST.
set -euo pipefail
K=/opt/keycloak/bin/kcadm.sh
: "${REALM:?set REALM}" "${UI_HOST:?set UI_HOST}"
SCOPE='user/*.rs'
CLIENT=hfs-ui

$K config credentials --server http://localhost:8080 --realm master \
  --user "$KC_BOOTSTRAP_ADMIN_USERNAME" --password "$KC_BOOTSTRAP_ADMIN_PASSWORD" >/dev/null 2>&1

# id of a client scope / client by name (no jq in the image)
scope_id() { $K get client-scopes -r "$REALM" --fields id,name 2>/dev/null | tr -d '\n ' \
  | grep -o "\"id\":\"[^\"]*\",\"name\":\"$(printf '%s' "$1" | sed 's/[*.]/\\&/g')\"" | cut -d'"' -f4 || true; }
client_id() { $K get clients -r "$REALM" -q "clientId=$1" --fields id 2>/dev/null | tr -d '\n ' \
  | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4 || true; }

sid=$(scope_id "$SCOPE")
if [ -z "$sid" ]; then
  $K create client-scopes -r "$REALM" -s "name=$SCOPE" -s protocol=openid-connect \
    -s 'attributes."include.in.token.scope"=true' -s 'attributes."display.on.consent.screen"=false' >/dev/null
  sid=$(scope_id "$SCOPE"); echo "== created client scope $SCOPE"
fi

cid=$(client_id "$CLIENT")
if [ -z "$cid" ]; then
  $K create clients -r "$REALM" -s clientId=$CLIENT -s name="hfs web UI" -s publicClient=true \
    -s standardFlowEnabled=true -s directAccessGrantsEnabled=false -s serviceAccountsEnabled=false >/dev/null
  cid=$(client_id "$CLIENT"); echo "== created client $CLIENT"
fi
$K update "clients/$cid" -r "$REALM" \
  -s "redirectUris=[\"https://$UI_HOST/ui/callback\"]" -s "webOrigins=[\"https://$UI_HOST\"]" \
  -s 'attributes."pkce.code.challenge.method"=S256' \
  -s "attributes.\"post.logout.redirect.uris\"=https://$UI_HOST/*"
for s in basic profile email "$SCOPE"; do
  id=$(scope_id "$s"); [ -n "$id" ] && $K update "clients/$cid/default-client-scopes/$id" -r "$REALM" >/dev/null 2>&1 || true
done
echo "== $CLIENT in realm $REALM → https://$UI_HOST/ui/callback, scope $SCOPE"
