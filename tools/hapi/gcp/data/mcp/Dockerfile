# The MCP server for data.healthcampaigns.org/mcp (icr_mcp.py), with the versions in uv.lock.
FROM python:3.13-slim
COPY --from=ghcr.io/astral-sh/uv:0.10.8 /uv /usr/local/bin/uv
WORKDIR /app
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy UV_PYTHON_DOWNLOADS=never
COPY pyproject.toml uv.lock ./
RUN uv sync --locked --no-dev --no-install-project
COPY icr_mcp.py queries.toml ./
RUN useradd --system --uid 10001 mcp
USER mcp
ENV PATH=/app/.venv/bin:$PATH PYTHONUNBUFFERED=1
EXPOSE 8000
CMD ["python", "icr_mcp.py"]
