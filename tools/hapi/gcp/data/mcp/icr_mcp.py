"""MCP server for data.healthcampaigns.org: the saved queries (SQLQuery Libraries) of
fhir-pipes serve, as tools an agent such as Claude can call.

Tools:
  list_queries  the approved queries, with their parameters
  get_query     one query's SQL and the tables it reads
  run_query     run one, with optional filter parameters, and return its rows

It runs no SQL of its own: every call goes to serve's `/fhir/Library` and `$sql-run`, so a
caller can run only the Libraries serve has approved.

Sign-in: Claude gets a token from Keycloak (realm icr, client `claude-mcp`). The token is
issued for two audiences: this server's URL, which is checked here, and `fhir-pipes`, with
the scope `system/Library.rs`, which serve checks. The same token is sent on to serve, so
serve sees who is asking.

Settings (environment):
  MCP_URL      this server's public URL, e.g. https://data.healthcampaigns.org/mcp
  ISSUER       token issuer, e.g. https://auth.healthcampaigns.org/realms/icr
  JWKS_URL     where to read the issuer's keys (default: ISSUER/protocol/openid-connect/certs)
  SERVE_URL    serve's FHIR base, e.g. http://data-serve:8090/fhir
  PORT         default 8000
"""

from __future__ import annotations

import base64
import json
import logging
import os
import time
from typing import Any

import httpx2 as httpx
import jwt
import uvicorn
from mcp.server.auth.middleware.auth_context import get_access_token
from mcp.server.auth.provider import AccessToken
from mcp.server.auth.settings import AuthSettings
from mcp.server.mcpserver import MCPServer
from mcp.server.mcpserver.exceptions import ToolError
from mcp_types import ToolAnnotations

log = logging.getLogger("icr-mcp")

MCP_URL = os.environ.get("MCP_URL", "https://data.healthcampaigns.org/mcp")
ISSUER = os.environ.get("ISSUER", "https://auth.healthcampaigns.org/realms/icr")
JWKS_URL = os.environ.get("JWKS_URL", f"{ISSUER}/protocol/openid-connect/certs")
SERVE_URL = os.environ.get("SERVE_URL", "http://data-serve:8090/fhir").rstrip("/")

DEFAULT_LIMIT = 200
MAX_LIMIT = 1000
LIBRARY_TTL = 60  # seconds the Library list is kept before it is read again
TIMEOUT = httpx.Timeout(120.0, connect=10.0)


class KeycloakVerifier:
    """Checks a Keycloak access token: its signature (the realm's keys), issuer, expiry, and
    that this server's URL is one of its audiences."""

    def __init__(self, issuer: str, audience: str, jwks: jwt.PyJWKClient):
        self.issuer = issuer
        self.audience = audience
        self.jwks = jwks

    async def verify_token(self, token: str) -> AccessToken | None:
        try:
            key = self.jwks.get_signing_key_from_jwt(token)
            claims = jwt.decode(
                token,
                key.key,
                algorithms=["RS256", "PS256", "ES256"],
                audience=self.audience,
                issuer=self.issuer,
                options={"require": ["exp", "iss", "aud", "sub"]},
            )
        except (jwt.PyJWTError, jwt.PyJWKClientError) as e:
            log.info("token refused: %s", e)
            return None
        return AccessToken(
            token=token,
            client_id=claims.get("azp") or claims.get("client_id") or "",
            scopes=(claims.get("scope") or "").split(),
            expires_at=claims["exp"],
            resource=self.audience,
            subject=claims["sub"],
            claims=claims,
        )


INSTRUCTIONS = """\
ICR data: the Integrated Campaign Registry's warehouse (public health campaigns: NTD mass drug
administration, vaccination, malaria; Nigeria first). The data on this server is demo data.

You can run only the saved queries this server lists; there is no free-form SQL.
1. Call list_queries to see the queries, what each returns and the filters it takes.
2. Call run_query with a query name and, where it helps, filter parameters. A filter that is
   not given filters nothing. Filter on the server (year, state, lga, ...) rather than
   fetching everything: results are cut at the row limit.
3. get_query shows a query's SQL, which tells you its columns and how it joins tables.

Places: state is admin level 1, LGA admin level 2; names are as in the registry (e.g. Kano,
Ajingi). Coverage is a share (0-1). When you answer, say which query and filters you used.
"""


def make_server(
    verifier: Any,
    client_factory: Any = None,
) -> MCPServer:
    """The MCP server. `client_factory` returns the httpx client used to call serve (tests
    pass one with a mock transport)."""

    client_factory = client_factory or (lambda: httpx.AsyncClient(timeout=TIMEOUT))
    # The approved Libraries are the same for every caller; each run_query still goes to serve
    # with the caller's own token, so serve decides every time whether they may run it.
    cache: dict[str, Any] = {"at": 0.0, "libraries": None}

    mcp = MCPServer(
        name="icr-data",
        title="ICR data",
        instructions=INSTRUCTIONS,
        website_url="https://github.com/recodelabs/icr/blob/main/datapi.md",
        token_verifier=verifier,
        auth=AuthSettings(
            issuer_url=ISSUER,
            resource_server_url=MCP_URL,
            validate_token_resource=True,
        ),
    )

    def caller() -> AccessToken:
        token = get_access_token()
        if token is None:
            raise ToolError("not signed in")
        return token

    def who(token: AccessToken) -> str:
        c = token.claims or {}
        return c.get("preferred_username") or token.subject or "?"

    async def serve_get(path: str, params: dict[str, str], token: AccessToken) -> httpx.Response:
        async with client_factory() as client:
            try:
                r = await client.get(
                    f"{SERVE_URL}/{path}",
                    params=params,
                    headers={"Authorization": f"Bearer {token.token}", "Accept": "application/fhir+json"},
                )
            except httpx.HTTPError as e:
                raise ToolError(f"the data server did not answer: {type(e).__name__}") from e
        check(r)
        return r

    async def libraries(token: AccessToken) -> list[dict[str, Any]]:
        fresh = time.monotonic() - cache["at"] < LIBRARY_TTL
        if not (fresh and cache["libraries"] is not None):
            bundle = (await serve_get("Library", {}, token)).json()
            cache["libraries"] = [e["resource"] for e in bundle.get("entry", [])]
            cache["at"] = time.monotonic()
        return cache["libraries"]

    async def library(name: str, token: AccessToken) -> dict[str, Any]:
        libs = await libraries(token)
        for lib in libs:
            if lib.get("name") == name:
                return lib
        names = ", ".join(sorted(lib.get("name", "") for lib in libs))
        raise ToolError(f"no query named {name!r}. The queries are: {names}")

    def in_params(lib: dict[str, Any]) -> list[dict[str, str]]:
        return [
            {"name": p["name"], "type": p.get("type", "string"), "documentation": p.get("documentation", "")}
            for p in lib.get("parameter", [])
            if p.get("use", "in") == "in"
        ]

    @mcp.tool(
        title="List the saved queries",
        annotations=ToolAnnotations(readOnlyHint=True, openWorldHint=False),
    )
    async def list_queries() -> list[dict[str, Any]]:
        """The saved queries you can run, each with its name, what it returns, and the filter
        parameters it takes (none are required). Call this first."""
        token = caller()
        out = []
        for lib in await libraries(token):
            out.append(
                {
                    "name": lib.get("name"),
                    "title": lib.get("title"),
                    "description": lib.get("description"),
                    "parameters": in_params(lib),
                }
            )
        log.info("%s list_queries", who(token))
        return out

    @mcp.tool(
        title="Show a query's SQL",
        annotations=ToolAnnotations(readOnlyHint=True, openWorldHint=False),
    )
    async def get_query(name: str) -> dict[str, Any]:
        """One saved query in full: its description, parameters, the tables it reads, and its
        SQL, which shows the columns it returns."""
        token = caller()
        lib = await library(name, token)
        sql = None
        for c in lib.get("content", []):
            if c.get("contentType", "").startswith("application/sql") and c.get("data"):
                sql = base64.b64decode(c["data"]).decode("utf-8", "replace")
                break
        log.info("%s get_query %s", who(token), name)
        return {
            "name": lib.get("name"),
            "title": lib.get("title"),
            "description": lib.get("description"),
            "parameters": in_params(lib),
            "reads": [
                {"table": a.get("label"), "definition": a.get("resource")}
                for a in lib.get("relatedArtifact", [])
                if a.get("type") == "depends-on"
            ],
            "sql": sql,
        }

    @mcp.tool(
        title="Run a saved query",
        annotations=ToolAnnotations(readOnlyHint=True, idempotentHint=True, openWorldHint=False),
    )
    async def run_query(
        name: str,
        parameters: dict[str, str | int | float | bool] | None = None,
        limit: int = DEFAULT_LIMIT,
    ) -> dict[str, Any]:
        """Run a saved query and return its rows.

        name: a query name from list_queries.
        parameters: filters, by the names list_queries gives, e.g. {"year": 2024, "state": "Kano"}.
            Leave one out to not filter on it.
        limit: the most rows to return (default 200, at most 1000). If the result is cut,
            `truncated` is true: add filters rather than raising the limit.
        """
        token = caller()
        if not 1 <= limit <= MAX_LIMIT:
            raise ToolError(f"limit must be between 1 and {MAX_LIMIT}")
        lib = await library(name, token)
        declared = {p["name"] for p in in_params(lib)}
        given = parameters or {}
        unknown = sorted(set(given) - declared)
        if unknown:
            takes = ", ".join(sorted(declared)) or "no parameters"
            raise ToolError(f"{name} does not take {', '.join(unknown)}; it takes {takes}")

        query: dict[str, str] = {"subjectCanonical": lib["url"], "_format": "ndjson"}
        for k, v in given.items():
            if v is None:
                continue
            query[k] = ("true" if v else "false") if isinstance(v, bool) else str(v)

        started = time.monotonic()
        rows: list[dict[str, Any]] = []
        truncated = False
        async with client_factory() as client:
            try:
                async with client.stream(
                    "GET",
                    f"{SERVE_URL}/$sql-run",
                    params=query,
                    headers={"Authorization": f"Bearer {token.token}"},
                ) as r:
                    if r.status_code >= 400:
                        await r.aread()
                        check(r)
                    async for line in r.aiter_lines():
                        if not line.strip():
                            continue
                        if len(rows) == limit:
                            truncated = True
                            break
                        rows.append(json.loads(line))
            except httpx.HTTPError as e:
                raise ToolError(f"the data server did not answer: {type(e).__name__}") from e

        columns: list[str] = []
        for row in rows:
            for k in row:
                if k not in columns:
                    columns.append(k)
        log.info(
            "%s run_query %s %s -> %d rows%s in %.1fs",
            who(token), name, json.dumps(given, sort_keys=True), len(rows),
            " (truncated)" if truncated else "", time.monotonic() - started,
        )
        return {
            "query": name,
            "parameters": given,
            "columns": columns,
            "rows": [[row.get(c) for c in columns] for row in rows],
            "row_count": len(rows),
            "truncated": truncated,
        }

    return mcp


def check(r: httpx.Response) -> None:
    """Turns serve's error answers into a message for the agent."""
    if r.status_code < 400:
        return
    detail = ""
    try:
        body = r.json()
        detail = "; ".join(i.get("diagnostics", "") for i in body.get("issue", []) if i.get("diagnostics"))
    except ValueError:
        detail = r.text[:300]
    if r.status_code in (401, 403):
        raise ToolError(f"the data server refused this sign-in ({r.status_code}). {detail}".strip())
    if r.status_code == 503:
        raise ToolError("the data server is refreshing its warehouse; try again in a few minutes")
    raise ToolError(f"the data server answered {r.status_code}: {detail}".strip())


def main() -> None:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")
    jwks = jwt.PyJWKClient(JWKS_URL, cache_keys=True, lifespan=3600, timeout=10)
    mcp = make_server(KeycloakVerifier(ISSUER, MCP_URL, jwks))
    # Behind Caddy, which serves the public host: one request per call, JSON answers.
    app = mcp.streamable_http_app(streamable_http_path="/mcp", stateless_http=True, json_response=True, host="0.0.0.0")
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", "8000")), proxy_headers=True, forwarded_allow_ips="*")


if __name__ == "__main__":
    main()
