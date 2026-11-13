#!/usr/bin/env bash
# Keycloak (realm icr) for data.healthcampaigns.org: the client scopes serve checks, and which
# API keys (gateway/api-key.sh clients, key-<name>) may ask for them.
#
#   system/Library.rs   SMART on FHIR scope: query with $sql-run ([serve.auth] query_scope)
#   fhir-pipes.admin    start and read refreshes ([serve.auth] admin_scope)
#
# Each scope carries an audience mapper, so a token that has it is issued for `fhir-pipes`
# ([serve.auth] audience). The scopes are optional: a key gets them only when it asks
# (`-d scope=system/Library.rs`), and only once granted here.
#
# Runs inside the keycloak container (kcadm.sh; no python/jq there). From /opt/icr-hapi/gcp:
#
#   sudo docker compose exec -T keycloak bash -s -- setup              < data/keycloak.sh
#   sudo docker compose exec -T keycloak bash -s -- grant matt         < data/keycloak.sh
#   sudo docker compose exec -T keycloak bash -s -- grant matt admin   < data/keycloak.sh
#   sudo docker compose exec -T keycloak bash -s -- ungrant matt       < data/keycloak.sh
set -euo pipefail
K=/opt/keycloak/bin/kcadm.sh
REALM=${REALM:-icr}
AUDIENCE=fhir-pipes
QUERY_SCOPE=system/Library.rs
ADMIN_SCOPE=fhir-pipes.admin
cmd=${1:-}; name=${2:-}; level=${3:-}

$K config credentials --server http://localhost:8080 --realm master \
  --user "$KC_BOOTSTRAP_ADMIN_USERNAME" --password "$KC_BOOTSTRAP_ADMIN_PASSWORD" >/dev/null 2>&1

# The id of the client scope named $1, or nothing.
scope_id() {
  $K get client-scopes -r $REALM --fields id,name 2>/dev/null | tr -d '\n ' \
    | grep -o "\"id\":\"[^\"]*\",\"name\":\"${1//\*/\\*}\"" | cut -d'"' -f4 || true
}
client_uuid() {
  $K get clients -r $REALM -q "clientId=key-$1" --fields id,clientId 2>/dev/null \
    | tr -d '\n ' | grep -o "\"id\":\"[^\"]*\",\"clientId\":\"key-$1\"" | cut -d'"' -f4 || true
}
need_name() { [[ "$name" =~ ^[a-z0-9][a-z0-9-]{1,40}$ ]] || { echo "name: lowercase letters, digits, dashes" >&2; exit 2; }; }

make_scope() {
  local s=$1 id
  id=$(scope_id "$s")
  if [ -z "$id" ]; then
    id=$($K create client-scopes -r $REALM -i -s "name=$s" -s protocol=openid-connect \
      -s "description=data.healthcampaigns.org (fhir-pipes serve)" \
      -s 'attributes."include.in.token.scope"=true' \
      -s 'attributes."display.on.consent.screen"=false')
    $K create "client-scopes/$id/protocol-mappers/models" -r $REALM \
      -s name=audience-$AUDIENCE -s protocol=openid-connect -s protocolMapper=oidc-audience-mapper \
      -s "config.\"included.custom.audience\"=$AUDIENCE" \
      -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=false' >/dev/null
    echo "client scope $s created"
  else
    echo "client scope $s exists"
  fi
}

case "$cmd" in
  setup)
    make_scope "$QUERY_SCOPE"
    make_scope "$ADMIN_SCOPE" ;;
  grant)
    need_name; cid=$(client_uuid "$name"); [ -n "$cid" ] || { echo "no key-$name (create it with gateway/api-key.sh)" >&2; exit 1; }
    scopes=("$QUERY_SCOPE"); [ "$level" = admin ] && scopes+=("$ADMIN_SCOPE")
    for s in "${scopes[@]}"; do
      sid=$(scope_id "$s"); [ -n "$sid" ] || { echo "no client scope $s: run setup" >&2; exit 1; }
      $K update "clients/$cid/optional-client-scopes/$sid" -r $REALM
      echo "key-$name may ask for $s"
    done
    echo "token: curl -s -d grant_type=client_credentials -d client_id=key-$name -d client_secret=<secret> \\"
    echo "         -d scope='${scopes[*]}' https://$AUTH_HOST/realms/$REALM/protocol/openid-connect/token" ;;
  ungrant)
    need_name; cid=$(client_uuid "$name"); [ -n "$cid" ] || { echo "no key-$name" >&2; exit 1; }
    for s in "$QUERY_SCOPE" "$ADMIN_SCOPE"; do
      sid=$(scope_id "$s"); [ -n "$sid" ] || continue
      $K delete "clients/$cid/optional-client-scopes/$sid" -r $REALM 2>/dev/null && echo "key-$name: no $s" || true
    done ;;
  *) echo "usage: keycloak.sh setup | grant NAME [admin] | ungrant NAME" >&2; exit 2 ;;
esac
