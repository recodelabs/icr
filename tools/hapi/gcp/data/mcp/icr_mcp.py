"""MCP server for data.healthcampaigns.org: the saved queries (SQLQuery Libraries) of
fhir-pipes serve, as tools an agent such as Claude can call.

Tools:
  list_queries  the approved queries, with their parameters
  get_query     one query's SQL and the tables it reads
  run_query     run one, with optional filter parameters, and return its rows
  aggregate     run one, then group its rows and compute totals, averages and rates per group

It runs no SQL of its own: every call goes to serve's `/fhir/Library` and `$sql-run`, so a
caller can run only the Libraries serve has approved. aggregate groups the rows of one such
run in this process, with a fixed set of operations.

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
import tomllib
from contextlib import aclosing
from pathlib import Path
from typing import Any, AsyncIterator, Literal

import httpx2 as httpx
import jwt
import uvicorn
from mcp.server.auth.middleware.auth_context import get_access_token
from mcp.server.auth.provider import AccessToken
from mcp.server.auth.settings import AuthSettings
from mcp.server.mcpserver import MCPServer
from mcp.server.mcpserver.exceptions import ToolError
from mcp_types import ToolAnnotations
from pydantic import BaseModel, ConfigDict, Field

log = logging.getLogger("icr-mcp")

MCP_URL = os.environ.get("MCP_URL", "https://data.healthcampaigns.org/mcp")
ISSUER = os.environ.get("ISSUER", "https://auth.healthcampaigns.org/realms/icr")
JWKS_URL = os.environ.get("JWKS_URL", f"{ISSUER}/protocol/openid-connect/certs")
SERVE_URL = os.environ.get("SERVE_URL", "http://data-serve:8090/fhir").rstrip("/")

SCOPES = ["system/Library.rs", "offline_access"]
DEFAULT_LIMIT = 200
MAX_LIMIT = 1000
MAX_GROUPS = 1000  # the most groups aggregate returns
MAX_INPUT_ROWS = 500_000  # the most rows aggregate reads before it asks for filters
MAX_DISTINCT = 100_000  # the most distinct values or groups aggregate keeps in memory
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
            # offline_access is asked for so the sign-in lasts; a token without it may still
            # query, so it is counted as held and only system/Library.rs is really required.
            scopes=sorted({*(claims.get("scope") or "").split(), "offline_access"}),
            expires_at=claims["exp"],
            resource=self.audience,
            subject=claims["sub"],
            claims=claims,
        )


Scalar = str | int | float | bool | None


def load_one_kind(path: Path | None = None) -> dict[str, list[str]]:
    """queries.toml: for each query, the columns whose values must not be mixed in a total."""
    path = path or Path(__file__).with_name("queries.toml")
    with path.open("rb") as f:
        return {name: list(q.get("one_kind", [])) for name, q in tomllib.load(f).items()}


class Metric(BaseModel):
    """One figure to compute for each group."""

    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    op: Literal["count", "count_distinct", "sum", "avg", "min", "max", "ratio"] = Field(
        description="count: rows (or non-null values of `of`). count_distinct: distinct non-null values of `of`. "
        "sum, avg, min, max: over the non-null values of `of`. "
        "ratio: sum(of) / sum(per), over rows where both are present; use it for coverage and other rates."
    )
    of: str | None = Field(default=None, description="The column the figure is computed from (not needed for count).")
    per: str | None = Field(default=None, description="For ratio only: the denominator column.")
    label: str | None = Field(default=None, alias="as", description="The name of the output column.")

    def name(self) -> str:
        if self.label:
            return self.label
        if self.op == "ratio":
            return f"{self.of}_per_{self.per}"
        return f"{self.op}_{self.of}" if self.of else self.op


def number(v: Any, column: str) -> float | int:
    if isinstance(v, bool) or not isinstance(v, (int, float)):
        raise ToolError(f"{column} is not a number (found {v!r}), so it cannot be summed or averaged")
    return v


class Acc:
    """One metric's running figure for one group."""

    def __init__(self, m: Metric):
        self.m = m
        self.n = 0
        self.a: Any = 0
        self.b: Any = 0
        self.seen: set[Any] = set()
        self.best: Any = None

    def add(self, row: dict[str, Any]) -> None:
        m = self.m
        v = row.get(m.of) if m.of else None
        if m.op == "count":
            if m.of is None or v is not None:
                self.n += 1
            return
        if v is None:
            return
        if m.op == "count_distinct":
            if len(self.seen) >= MAX_DISTINCT and v not in self.seen:
                raise ToolError(f"{m.of} has more than {MAX_DISTINCT} distinct values; add filters")
            self.seen.add(v)
        elif m.op in ("sum", "avg"):
            self.a += number(v, m.of)
            self.n += 1
        elif m.op == "ratio":
            d = row.get(m.per)
            if d is None:
                return
            self.a += number(v, m.of)
            self.b += number(d, m.per)
            self.n += 1
        else:  # min, max
            try:
                if self.best is None or (v < self.best if m.op == "min" else v > self.best):
                    self.best = v
            except TypeError:
                raise ToolError(f"{m.of} mixes kinds of value, so it has no {m.op}") from None

    def value(self) -> Scalar:
        m = self.m
        if m.op == "count":
            return self.n
        if m.op == "count_distinct":
            return len(self.seen)
        if m.op in ("min", "max"):
            return self.best
        if self.n == 0:
            return None
        if m.op == "sum":
            return round(self.a, 6) if isinstance(self.a, float) else self.a
        if m.op == "avg":
            return round(self.a / self.n, 6)
        return round(self.a / self.b, 6) if self.b else None  # ratio


INSTRUCTIONS = """\
ICR data: the Integrated Campaign Registry's warehouse (public health campaigns: NTD mass drug
administration, vaccination, malaria; Nigeria first). The data on this server is demo data.

You can run only the saved queries this server lists; there is no free-form SQL.
1. Call list_queries to see the queries, what each returns and the filters it takes.
2. Call run_query with a query name and, where it helps, filter parameters. A filter that is
   not given filters nothing. Filter on the server (year, state, lga, ...) rather than
   fetching everything: results are cut at the row limit.
3. For totals, averages, rankings or "which place has the most/least", call aggregate, not
   run_query: it groups and totals a query's rows on the server and returns only the groups.
4. get_query shows a query's SQL, which tells you its columns and how it joins tables.

Rates: a rate for a group (coverage of a state, say) is sum(numerator) / sum(denominator),
which is aggregate's `ratio`. Do not average the rows' own rates (score): that weights a small
place the same as a large one.
Double counting: a query can return rows of more than one kind: a state's row and its LGAs'
rows, or an administrative report and a survey of the same place. list_queries names these
columns for each query (`one_kind`). aggregate refuses a total that mixes them and lists the
values found: choose one value (parameter or `where`) or group by the column. If the person
did not say which kind they mean (administrative or survey, say), tell them which you used.
"""


def make_server(
    verifier: Any,
    client_factory: Any = None,
    one_kind: dict[str, list[str]] | None = None,
) -> MCPServer:
    """The MCP server. `client_factory` returns the httpx client used to call serve (tests
    pass one with a mock transport)."""

    client_factory = client_factory or (lambda: httpx.AsyncClient(timeout=TIMEOUT))
    one_kind = load_one_kind() if one_kind is None else one_kind
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
            # Named in the metadata Claude reads, so it asks Keycloak for these and no others
            # (with none named it asks for every scope the realm has, and Keycloak refuses).
            # offline_access keeps the sign-in past the 30-minute idle session.
            required_scopes=SCOPES,
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

    def checked_params(lib: dict[str, Any], parameters: dict[str, Any] | None) -> dict[str, Any]:
        declared = {p["name"] for p in in_params(lib)}
        given = {k: v for k, v in (parameters or {}).items() if v is not None}
        unknown = sorted(set(given) - declared)
        if unknown:
            takes = ", ".join(sorted(declared)) or "no parameters"
            raise ToolError(f"{lib.get('name')} does not take {', '.join(unknown)}; it takes {takes}")
        return given

    async def stream_rows(
        lib: dict[str, Any], given: dict[str, Any], token: AccessToken, at_most: int | None = None
    ) -> AsyncIterator[dict[str, Any]]:
        """The rows of one Library from serve's $sql-run, one at a time. `at_most` is passed to
        serve as `_limit`, so it stops early instead of writing every row."""
        query: dict[str, str] = {"subjectCanonical": lib["url"], "_format": "ndjson"}
        if at_most is not None:
            query["_limit"] = str(at_most)
        for k, v in given.items():
            query[k] = ("true" if v else "false") if isinstance(v, bool) else str(v)
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
                        if line.strip():
                            yield json.loads(line)
            except httpx.HTTPError as e:
                raise ToolError(f"the data server did not answer: {type(e).__name__}") from e

    @mcp.tool(
        title="List the saved queries",
        annotations=ToolAnnotations(readOnlyHint=True, openWorldHint=False),
    )
    async def list_queries() -> list[dict[str, Any]]:
        """The saved queries you can run, each with its name, what it returns, and the filter
        parameters it takes (none are required). Call this first.

        `one_kind` lists the columns that split a query's rows into kinds that must not be added
        together (a state's row and its LGAs' rows, an administrative report and a survey of
        the same place). aggregate refuses a total that mixes them."""
        token = caller()
        out = []
        for lib in await libraries(token):
            out.append(
                {
                    "name": lib.get("name"),
                    "title": lib.get("title"),
                    "description": lib.get("description"),
                    "parameters": in_params(lib),
                    "one_kind": one_kind.get(lib.get("name", ""), []),
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
            "one_kind": one_kind.get(name, []),
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
        given = checked_params(lib, parameters)

        started = time.monotonic()
        rows: list[dict[str, Any]] = []
        truncated = False
        # One row more than the limit, to know whether the result was cut.
        async with aclosing(stream_rows(lib, given, token, at_most=limit + 1)) as stream:
            async for row in stream:
                if len(rows) == limit:
                    truncated = True
                    break
                rows.append(row)

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

    @mcp.tool(
        title="Group and total a saved query",
        annotations=ToolAnnotations(readOnlyHint=True, idempotentHint=True, openWorldHint=False),
    )
    async def aggregate(
        name: str,
        metrics: list[Metric],
        group_by: list[str] | None = None,
        parameters: dict[str, str | int | float | bool] | None = None,
        where: dict[str, Scalar | list[Scalar]] | None = None,
        order_by: str | None = None,
        descending: bool = True,
        limit: int = 100,
    ) -> dict[str, Any]:
        """Run a saved query, then group its rows and compute figures per group. Use this for
        totals, averages, rates and rankings; it reads every row of the query, so it is not
        cut at run_query's row limit.

        name, parameters: as for run_query.
        metrics: the figures, e.g. [{"op": "ratio", "of": "numerator", "per": "denominator", "as": "coverage"},
            {"op": "count", "as": "reports"}]. For a rate such as coverage use ratio, not avg of the rows' rates.
        group_by: columns of the query to group on, e.g. ["state"]. Leave out for one total.
        where: keep only rows where a column equals a value, or one of a list:
            {"admin_level": 2, "source": ["administrative", "survey"]}. Use it for columns the
            query has no parameter for.
        One kind of row: a total (anything but a count) must be over rows of one kind. For each
            of the query's `one_kind` columns (see list_queries), either fix one value with a
            parameter or `where`, or put the column in group_by. Otherwise the call is refused
            and the error lists the values found, so you can choose. The result's `kinds` says
            which kind of row each figure is for: say it in your answer.
        order_by: a group_by column or a metric's name; descending by default.
        limit: the most groups to return (default 100, at most 1000).
        """
        token = caller()
        if not 1 <= limit <= MAX_GROUPS:
            raise ToolError(f"limit must be between 1 and {MAX_GROUPS}")
        if not metrics:
            raise ToolError("give at least one metric")
        group_by = group_by or []
        names = group_by + [m.name() for m in metrics]
        if len(set(names)) != len(names):
            raise ToolError("two output columns have the same name; give each metric its own `as`")
        for m in metrics:
            if m.op != "count" and not m.of:
                raise ToolError(f"{m.op} needs `of`, the column to compute it from")
            if (m.op == "ratio") != bool(m.per):
                raise ToolError("`per` goes with ratio, and ratio needs it")
        if order_by is not None and order_by not in names:
            raise ToolError(f"order_by must be one of: {', '.join(names)}")
        lib = await library(name, token)
        given = checked_params(lib, parameters)
        filters = {k: set(v) if isinstance(v, list) else {v} for k, v in (where or {}).items()}
        used = set(group_by) | set(filters) | {c for m in metrics for c in (m.of, m.per) if c}

        # The columns whose values must not be mixed within a group, when a metric totals rows.
        totals = any(m.op not in ("count", "count_distinct") for m in metrics)
        guard = [c for c in one_kind.get(name, []) if c not in group_by]
        kinds: dict[str, set[Any]] = {c: set() for c in guard}  # every value among the rows used
        in_group: dict[tuple[Any, ...], list[Any]] = {}  # each group's first value per guard column
        mixed: set[str] = set()  # guard columns that some group has two values of

        started = time.monotonic()
        groups: dict[tuple[Any, ...], list[Acc]] = {}
        read = kept = 0
        async with aclosing(stream_rows(lib, given, token)) as stream:
            async for row in stream:
                if read == 0:
                    missing = sorted(used - set(row))
                    if missing:
                        raise ToolError(f"{name} has no column {', '.join(missing)}; its columns are: {', '.join(row)}")
                    absent = [c for c in guard if c not in row]
                    if absent:
                        log.warning("queries.toml: %s has no column %s", name, ", ".join(absent))
                        guard = [c for c in guard if c in row]
                read += 1
                if read > MAX_INPUT_ROWS:
                    raise ToolError(f"{name} returns more than {MAX_INPUT_ROWS} rows with these parameters; add filters")
                if any(row.get(k) not in allowed for k, allowed in filters.items()):
                    continue
                kept += 1
                key = tuple(row.get(g) for g in group_by)
                accs = groups.get(key)
                if accs is None:
                    if len(groups) >= MAX_DISTINCT:
                        raise ToolError(f"more than {MAX_DISTINCT} groups; group on fewer columns or add filters")
                    accs = groups[key] = [Acc(m) for m in metrics]
                    in_group[key] = [row[c] for c in guard]
                for acc in accs:
                    acc.add(row)
                first = in_group[key]
                for i, c in enumerate(guard):
                    v = row[c]
                    if v != first[i]:
                        mixed.add(c)
                    if len(kinds[c]) <= 20:
                        kinds[c].add(v)
        if not group_by and not groups:
            groups[()] = [Acc(m) for m in metrics]  # one total, even over no rows

        def values(c: str) -> list[Any]:
            return sorted(kinds[c], key=lambda v: (v is None, str(v)))

        if totals and mixed:
            found = "; ".join(f"{c}: {', '.join(json.dumps(v) for v in values(c))}" for c in guard if c in mixed)
            raise ToolError(
                f"These rows are of more than one kind, so a total over them would count the same thing more than "
                f"once. They differ in {found}. For each of these columns, either fix one value with a parameter "
                f"or `where`, or add the column to group_by."
            )

        out = [list(key) + [acc.value() for acc in accs] for key, accs in groups.items()]
        if order_by is not None:
            i = names.index(order_by)
            found = [r for r in out if r[i] is not None]
            try:
                found.sort(key=lambda r: r[i], reverse=descending)
            except TypeError:
                raise ToolError(f"{order_by} mixes kinds of value, so it cannot be ordered") from None
            out = found + [r for r in out if r[i] is None]  # groups with no figure go last
        log.info(
            "%s aggregate %s %s by %s where %s -> %d groups from %d of %d rows in %.1fs",
            who(token), name, json.dumps(given, sort_keys=True), group_by, sorted(filters),
            len(out), kept, read, time.monotonic() - started,
        )
        return {
            "query": name,
            "parameters": given,
            "columns": names,
            "rows": out[:limit],
            "group_count": len(out),
            "truncated": len(out) > limit,
            "rows_read": read,
            "rows_used": kept,
            # What kind of rows the figures are over: each one_kind column's value, or that
            # the groups are split by it.
            "kinds": {c: "grouped" for c in one_kind.get(name, []) if c in group_by}
            | {c: (values(c)[0] if len(kinds[c]) == 1 else values(c)) for c in guard if kinds[c]},
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
