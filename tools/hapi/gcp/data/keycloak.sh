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
#
# Claude's connector to https://data.healthcampaigns.org/mcp (mcp/) signs people in with the
# client `claude-mcp`, and the people are users of the realm:
#
#   sudo docker compose exec -T keycloak bash -s -- claude             < data/keycloak.sh
#   sudo docker compose exec -T keycloak bash -s -- user jdoe          < data/keycloak.sh
#   sudo docker compose exec -T keycloak bash -s -- unuser jdoe        < data/keycloak.sh
set -euo pipefail
K=/opt/keycloak/bin/kcadm.sh
REALM=${REALM:-icr}
AUDIENCE=fhir-pipes
QUERY_SCOPE=system/Library.rs
ADMIN_SCOPE=fhir-pipes.admin
# The MCP server's URL: an audience of every token claude-mcp gets, which the MCP server checks.
MCP_URL=${MCP_URL:-https://data.healthcampaigns.org/mcp}
CLAUDE_CLIENT=claude-mcp
# Where Claude receives the sign-in: claude.ai today, claude.com if it moves there.
CLAUDE_CALLBACKS='["https://claude.ai/api/mcp/auth_callback","https://claude.com/api/mcp/auth_callback"]'
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
client_uuid_of() {
  $K get clients -r $REALM -q "clientId=$1" --fields id,clientId 2>/dev/null \
    | tr -d '\n ' | grep -o "\"id\":\"[^\"]*\",\"clientId\":\"$1\"" | cut -d'"' -f4 || true
}
user_id() {
  $K get users -r $REALM -q "username=$1" -q exact=true --fields id,username 2>/dev/null \
    | tr -d '\n ' | grep -o "\"id\":\"[^\"]*\",\"username\":\"$1\"" | cut -d'"' -f4 || true
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
  claude)
    # A confidential client for Claude (claude.ai, Desktop and the mobile apps share it):
    # authorization code with S256 PKCE, back to Claude's one callback URL. Its tokens are
    # issued for the MCP server (audience mapper) and carry system/Library.rs (a default
    # scope, whose own mapper adds the audience fhir-pipes), so the MCP server can send them
    # on to serve.
    sid=$(scope_id "$QUERY_SCOPE"); [ -n "$sid" ] || { echo "no client scope $QUERY_SCOPE: run setup" >&2; exit 1; }
    cid=$(client_uuid_of "$CLAUDE_CLIENT")
    if [ -z "$cid" ]; then
      cid=$($K create clients -r $REALM -i -s clientId=$CLAUDE_CLIENT \
        -s "name=Claude (data.healthcampaigns.org/mcp)" -s protocol=openid-connect \
        -s publicClient=false -s standardFlowEnabled=true -s implicitFlowEnabled=false \
        -s directAccessGrantsEnabled=false -s serviceAccountsEnabled=false -s consentRequired=false \
        -s "redirectUris=$CLAUDE_CALLBACKS" -s 'webOrigins=[]' \
        -s 'attributes."pkce.code.challenge.method"=S256')
      $K create "clients/$cid/protocol-mappers/models" -r $REALM \
        -s name=audience-mcp -s protocol=openid-connect -s protocolMapper=oidc-audience-mapper \
        -s "config.\"included.custom.audience\"=$MCP_URL" \
        -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=false' >/dev/null
      $K update "clients/$cid/default-client-scopes/$sid" -r $REALM
      echo "client $CLAUDE_CLIENT created"
    else
      $K update "clients/$cid" -r $REALM -s "redirectUris=$CLAUDE_CALLBACKS"
      echo "client $CLAUDE_CLIENT exists"
    fi
    secret=$($K get "clients/$cid/client-secret" -r $REALM 2>/dev/null | tr -d '\n ' | grep -o '"value":"[^"]*"' | cut -d'"' -f4)
    echo
    echo "In Claude: Settings > Connectors > Add custom connector"
    echo "  URL:            $MCP_URL"
    echo "  OAuth client:   use your own: client ID $CLAUDE_CLIENT"
    echo "  client secret:  $secret" ;;
  user)
    # A person who may sign in to the connector (any user of the realm can). They set their
    # own password at first sign-in.
    [[ "$name" =~ ^[a-z0-9][a-z0-9._-]{1,40}$ ]] || { echo "username: lowercase letters, digits, . _ -" >&2; exit 2; }
    [ -z "$(user_id "$name")" ] || { echo "user $name exists" >&2; exit 1; }
    uid=$($K create users -r $REALM -i -s "username=$name" -s enabled=true)
    pw=$(head -c 15 /dev/urandom | base64 | tr -d '/+=')
    $K set-password -r $REALM --userid "$uid" --new-password "$pw" --temporary
    echo "user $name created; temporary password (they choose a new one at first sign-in):"
    echo "  $pw" ;;
  unuser)
    [ -n "$name" ] || { echo "usage: unuser USERNAME" >&2; exit 2; }
    uid=$(user_id "$name"); [ -n "$uid" ] || { echo "no user $name" >&2; exit 1; }
    $K delete "users/$uid" -r $REALM && echo "user $name deleted" ;;
  *) echo "usage: keycloak.sh setup | grant NAME [admin] | ungrant NAME | claude | user NAME | unuser NAME" >&2; exit 2 ;;
esac
