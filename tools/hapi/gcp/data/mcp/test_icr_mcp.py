import base64
import json
import re
import time
from types import SimpleNamespace

import httpx2 as httpx
import jwt
import pytest
from cryptography.hazmat.primitives.asymmetric import rsa
from mcp.server.auth.middleware.auth_context import auth_context_var
from mcp.server.auth.middleware.bearer_auth import AuthenticatedUser
from mcp.server.mcpserver.exceptions import ToolError

import icr_mcp

KEY = rsa.generate_private_key(public_exponent=65537, key_size=2048)
OTHER_KEY = rsa.generate_private_key(public_exponent=65537, key_size=2048)


class FakeJwks:
    def get_signing_key_from_jwt(self, token):
        return SimpleNamespace(key=KEY.public_key())


def make_token(key=KEY, **over):
    now = int(time.time())
    claims = {
        "iss": icr_mcp.ISSUER,
        "aud": [icr_mcp.MCP_URL, "fhir-pipes"],
        "sub": "user-1",
        "azp": "claude-mcp",
        "preferred_username": "demoicr",
        "scope": "openid system/Library.rs",
        "iat": now,
        "exp": now + 300,
    }
    claims.update(over)
    return jwt.encode(claims, key, algorithm="RS256")


VERIFIER = icr_mcp.KeycloakVerifier(icr_mcp.ISSUER, icr_mcp.MCP_URL, FakeJwks())

SQL = "SELECT * FROM coverage WHERE (:year IS NULL OR year = :year)"
LIBRARIES = {
    "resourceType": "Bundle",
    "entry": [
        {
            "resource": {
                "resourceType": "Library",
                "url": "https://icr.healthcampaigns.org/data/Library/IcrCoverageByLocation",
                "name": "IcrCoverageByLocation",
                "title": "Coverage reports with their campaign and place",
                "description": "Each IcrCoverage row ...",
                "relatedArtifact": [
                    {"type": "depends-on", "label": "coverage", "resource": "https://icr.healthcampaigns.org/ViewDefinition/IcrCoverage"}
                ],
                "parameter": [
                    {"name": "year", "use": "in", "type": "integer", "documentation": "The year"},
                    {"name": "state", "use": "in", "type": "string", "documentation": "The state"},
                    {"name": "has_census", "use": "in", "type": "boolean"},
                ],
                "content": [{"contentType": "application/sql", "data": base64.b64encode(SQL.encode()).decode()}],
            }
        }
    ],
}


class Serve:
    """A stand-in for fhir-pipes serve: records each request, answers from `rows`."""

    def __init__(self, rows=3, status=200):
        self.rows = rows
        self.status = status
        self.requests = []

    def handler(self, request):
        self.requests.append(request)
        if request.url.path == "/fhir/Library":
            return httpx.Response(200, json=LIBRARIES)
        if request.url.path == "/fhir/$sql-run":
            if self.status != 200:
                return httpx.Response(
                    self.status,
                    json={"resourceType": "OperationOutcome", "issue": [{"diagnostics": "nope"}]},
                )
            body = "".join(json.dumps({"state": "Kano", "year": 2024, "n": i}) + "\n" for i in range(self.rows))
            return httpx.Response(200, text=body, headers={"content-type": "application/x-ndjson"})
        return httpx.Response(404)

    def factory(self):
        return lambda: httpx.AsyncClient(transport=httpx.MockTransport(self.handler))


@pytest.fixture
def signed_in():
    access = icr_mcp.AccessToken(
        token="tok-abc", client_id="claude-mcp", scopes=[], subject="user-1",
        claims={"preferred_username": "demoicr"}, resource=icr_mcp.MCP_URL,
    )
    reset = auth_context_var.set(AuthenticatedUser(access))
    yield
    auth_context_var.reset(reset)


async def call(server, name, args):
    result = await server.call_tool(name, args)
    assert not result.is_error, result.content
    return result.structured_content


# --- tokens -------------------------------------------------------------------------------

@pytest.mark.anyio
async def test_a_good_token_is_accepted():
    t = await VERIFIER.verify_token(make_token())
    assert t is not None
    assert t.subject == "user-1" and t.client_id == "claude-mcp"
    assert t.resource == icr_mcp.MCP_URL
    assert "system/Library.rs" in t.scopes


@pytest.mark.anyio
@pytest.mark.parametrize(
    "over",
    [
        {"aud": "fhir-pipes"},  # issued for serve only, not for this server
        {"aud": "account"},
        {"iss": "https://auth.healthcampaigns.org/realms/uga"},
        {"exp": int(time.time()) - 10},
    ],
)
async def test_a_wrong_token_is_refused(over):
    assert await VERIFIER.verify_token(make_token(**over)) is None


@pytest.mark.anyio
async def test_a_token_signed_by_another_key_is_refused():
    assert await VERIFIER.verify_token(make_token(key=OTHER_KEY)) is None


@pytest.mark.anyio
async def test_garbage_is_refused():
    assert await VERIFIER.verify_token("not-a-jwt") is None


# --- HTTP: what Claude sees before and after sign-in ----------------------------------------

def app(serve=None):
    server = icr_mcp.make_server(VERIFIER, (serve or Serve()).factory())
    return server.streamable_http_app(streamable_http_path="/mcp", stateless_http=True, json_response=True, host="0.0.0.0")


def http(application):
    return httpx.AsyncClient(transport=httpx.ASGITransport(app=application), base_url="https://data.healthcampaigns.org")


INIT = {
    "jsonrpc": "2.0", "id": 1, "method": "initialize",
    "params": {"protocolVersion": "2025-06-18", "capabilities": {}, "clientInfo": {"name": "t", "version": "0"}},
}
HEADERS = {"Accept": "application/json, text/event-stream", "Content-Type": "application/json"}


@pytest.mark.anyio
async def test_no_token_gets_401_pointing_at_the_metadata():
    async with http(app()) as c:
        r = await c.post("/mcp", json=INIT, headers=HEADERS)
    assert r.status_code == 401
    assert 'resource_metadata="https://data.healthcampaigns.org/.well-known/oauth-protected-resource/mcp"' in r.headers["www-authenticate"]


@pytest.mark.anyio
async def test_the_metadata_names_keycloak():
    async with http(app()) as c:
        r = await c.get("/.well-known/oauth-protected-resource/mcp")
    assert r.status_code == 200
    body = r.json()
    assert body["resource"] == icr_mcp.MCP_URL
    assert body["authorization_servers"] == [icr_mcp.ISSUER]


@pytest.mark.anyio
async def test_a_token_for_serve_only_gets_401():
    async with http(app()) as c:
        r = await c.post("/mcp", json=INIT, headers=HEADERS | {"Authorization": f"Bearer {make_token(aud='fhir-pipes')}"})
    assert r.status_code == 401


@pytest.mark.anyio
async def test_signed_in_a_tool_call_reaches_serve_with_the_callers_token():
    serve = Serve(rows=2)
    token = make_token()
    auth = HEADERS | {"Authorization": f"Bearer {token}", "MCP-Protocol-Version": "2025-06-18"}
    application = app(serve)
    # ASGITransport does not run the app's lifespan, which starts the session manager.
    async with application.router.lifespan_context(application), http(application) as c:
        r = await c.post("/mcp", json=INIT, headers=auth)
        assert r.status_code == 200, r.text
        r = await c.post(
            "/mcp",
            json={"jsonrpc": "2.0", "id": 2, "method": "tools/call",
                  "params": {"name": "run_query", "arguments": {"name": "IcrCoverageByLocation", "parameters": {"year": 2024}}}},
            headers=auth,
        )
    assert r.status_code == 200, r.text
    result = r.json()["result"]
    assert not result.get("isError"), result
    assert result["structuredContent"]["row_count"] == 2
    assert all(req.headers["authorization"] == f"Bearer {token}" for req in serve.requests)


# --- tools ----------------------------------------------------------------------------------

@pytest.mark.anyio
async def test_list_queries(signed_in):
    server = icr_mcp.make_server(VERIFIER, Serve().factory())
    out = await call(server, "list_queries", {})
    (q,) = out["result"]
    assert q["name"] == "IcrCoverageByLocation"
    assert [p["name"] for p in q["parameters"]] == ["year", "state", "has_census"]
    assert q["parameters"][0] == {"name": "year", "type": "integer", "documentation": "The year"}


@pytest.mark.anyio
async def test_get_query_shows_the_sql(signed_in):
    server = icr_mcp.make_server(VERIFIER, Serve().factory())
    out = await call(server, "get_query", {"name": "IcrCoverageByLocation"})
    assert out["sql"] == SQL
    assert out["reads"] == [{"table": "coverage", "definition": "https://icr.healthcampaigns.org/ViewDefinition/IcrCoverage"}]


@pytest.mark.anyio
async def test_run_query_sends_the_filters(signed_in):
    serve = Serve(rows=3)
    server = icr_mcp.make_server(VERIFIER, serve.factory())
    out = await call(server, "run_query", {"name": "IcrCoverageByLocation", "parameters": {"year": 2024, "state": "Kano", "has_census": True}})
    run = [r for r in serve.requests if r.url.path.endswith("$sql-run")][0]
    q = dict(run.url.params)
    assert q == {
        "subjectCanonical": "https://icr.healthcampaigns.org/data/Library/IcrCoverageByLocation",
        "_format": "ndjson", "year": "2024", "state": "Kano", "has_census": "true",
    }
    assert run.headers["authorization"] == "Bearer tok-abc"
    assert out["columns"] == ["state", "year", "n"]
    assert out["rows"] == [["Kano", 2024, 0], ["Kano", 2024, 1], ["Kano", 2024, 2]]
    assert out["row_count"] == 3 and out["truncated"] is False


@pytest.mark.anyio
async def test_run_query_cuts_at_the_limit(signed_in):
    server = icr_mcp.make_server(VERIFIER, Serve(rows=50).factory())
    out = await call(server, "run_query", {"name": "IcrCoverageByLocation", "limit": 10})
    assert out["row_count"] == 10 and out["truncated"] is True


@pytest.mark.anyio
async def test_run_query_exactly_at_the_limit_is_not_truncated(signed_in):
    server = icr_mcp.make_server(VERIFIER, Serve(rows=10).factory())
    out = await call(server, "run_query", {"name": "IcrCoverageByLocation", "limit": 10})
    assert out["row_count"] == 10 and out["truncated"] is False


@pytest.mark.anyio
@pytest.mark.parametrize(
    "args, message",
    [
        ({"name": "Nope"}, "no query named 'Nope'"),
        ({"name": "IcrCoverageByLocation", "parameters": {"disease": "lf"}}, "does not take disease; it takes has_census, state, year"),
        ({"name": "IcrCoverageByLocation", "limit": 5000}, "limit must be between 1 and 1000"),
    ],
)
async def test_run_query_errors(signed_in, args, message):
    server = icr_mcp.make_server(VERIFIER, Serve().factory())
    with pytest.raises(ToolError, match=re.escape(message)):
        await server.call_tool("run_query", args)


@pytest.mark.anyio
@pytest.mark.parametrize("status, message", [(403, "refused this sign-in (403). nope"), (503, "refreshing"), (400, "answered 400: nope")])
async def test_serve_errors_reach_the_agent(signed_in, status, message):
    server = icr_mcp.make_server(VERIFIER, Serve(status=status).factory())
    with pytest.raises(ToolError, match=re.escape(message)):
        await server.call_tool("run_query", {"name": "IcrCoverageByLocation"})


@pytest.mark.anyio
async def test_tools_need_a_sign_in():
    server = icr_mcp.make_server(VERIFIER, Serve().factory())
    with pytest.raises(ToolError, match="not signed in"):
        await server.call_tool("list_queries", {})


@pytest.fixture
def anyio_backend():
    return "asyncio"
