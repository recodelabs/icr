#!/usr/bin/env bash
# API keys for the FHIR Info Gateway. A key is a Keycloak client in realm `icr`
# (client id `key-<name>` + its secret); the holder trades it for a 1-hour access token
# with the OAuth client-credentials grant and sends that as `Authorization: Bearer`.
# Any valid token gets the whole FHIR API (see allowed-queries.json).
#
# Runs inside the keycloak container (kcadm.sh; no python/jq there). From /opt/icr-hapi/gcp:
#
#   sudo docker compose exec -T keycloak bash -s -- setup         < gateway/api-key.sh
#   sudo docker compose exec -T keycloak bash -s -- create nkw    < gateway/api-key.sh
#   sudo docker compose exec -T keycloak bash -s -- list          < gateway/api-key.sh
#   sudo docker compose exec -T keycloak bash -s -- rotate nkw    < gateway/api-key.sh
#   sudo docker compose exec -T keycloak bash -s -- revoke nkw    < gateway/api-key.sh
#
# Revoking deletes the client: no new tokens, and tokens already issued stop working
# when they expire (≤ 1 hour; the gateway checks the signature, it does not call back).
set -euo pipefail
K=/opt/keycloak/bin/kcadm.sh
REALM=icr
cmd=${1:-}; name=${2:-}

$K config credentials --server http://localhost:8080 --realm master \
  --user "$KC_BOOTSTRAP_ADMIN_USERNAME" --password "$KC_BOOTSTRAP_ADMIN_PASSWORD" >/dev/null 2>&1

client_uuid() {
  $K get clients -r $REALM -q "clientId=key-$1" --fields id,clientId 2>/dev/null \
    | tr -d '\n ' | grep -o "\"id\":\"[^\"]*\",\"clientId\":\"key-$1\"" | cut -d'"' -f4 || true
}
secret_of() { $K get "clients/$1/client-secret" -r $REALM | tr -d '\n ' | grep -o '"value":"[^"]*"' | cut -d'"' -f4; }
need_name() { [[ "$name" =~ ^[a-z0-9][a-z0-9-]{1,40}$ ]] || { echo "name: lowercase letters, digits, dashes" >&2; exit 2; }; }
show() {
  cat <<EOF
client_id:     key-$name
client_secret: $1
token:   curl -s -d grant_type=client_credentials -d client_id=key-$name -d client_secret=<secret> \\
           https://$AUTH_HOST/realms/$REALM/protocol/openid-connect/token
EOF
}

case "$cmd" in
  setup)
    $K get "realms/$REALM" >/dev/null 2>&1 || \
      $K create realms -s realm=$REALM -s enabled=true -s displayName="ICR dev" \
        -s accessTokenLifespan=3600 -s sslRequired=external
    echo "realm $REALM ready" ;;
  create)
    need_name
    [ -z "$(client_uuid "$name")" ] || { echo "key-$name exists (rotate or revoke it)" >&2; exit 1; }
    id=$($K create clients -r $REALM -i -s "clientId=key-$name" -s "name=API key: $name" \
      -s enabled=true -s publicClient=false -s serviceAccountsEnabled=true \
      -s standardFlowEnabled=false -s directAccessGrantsEnabled=false -s implicitFlowEnabled=false \
      -s "attributes.\"created\"=$(date -u +%FT%TZ)")
    show "$(secret_of "$id")" ;;
  rotate)
    need_name; id=$(client_uuid "$name"); [ -n "$id" ] || { echo "no key-$name" >&2; exit 1; }
    $K create "clients/$id/client-secret" -r $REALM >/dev/null
    show "$(secret_of "$id")" ;;
  revoke)
    need_name; id=$(client_uuid "$name"); [ -n "$id" ] || { echo "no key-$name" >&2; exit 1; }
    $K delete "clients/$id" -r $REALM && echo "revoked key-$name" ;;
  list)
    $K get clients -r $REALM --fields clientId,name | tr -d '\n ' | grep -o '"clientId":"key-[^"]*"' | cut -d'"' -f4 ;;
  *) echo "usage: api-key.sh setup | create NAME | list | rotate NAME | revoke NAME" >&2; exit 2 ;;
esac
