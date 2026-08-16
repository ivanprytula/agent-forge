---
name: fastmcp-server-patterns
description: Build application-layer FastMCP servers that expose internal tool surfaces to LLM clients. Use when creating or modifying services/mcp/ tools, FastMCP tool definitions, argument patterns, or the ingestor HTTP client layer in this project.
---

# fastmcp-server-patterns

Build application-layer FastMCP servers that expose internal tool surfaces to LLM clients.

When to invoke: creating or modifying `services/mcp/` tools or FastMCP servers in this project.

## Distinction from Kilo-side MCP

This project's `services/mcp/` is an **application FastMCP server** (HTTP client to the ingestor). It is distinct from Kilo-side MCP servers configured in `~/.config/kilo/kilo.jsonc`. Do not mix these concepts in workflow recommendations.

## Tool definition pattern

Each tool is a thin async wrapper over an internal HTTP client:

```python
from fastmcp import FastMCP

mcp = FastMCP("api-observatory")

@mcp.tool()
async def list_sources(is_active: bool | None = None, offset: int = 0, limit: int = 20) -> Any:
    """List registered API source profiles being monitored.

    Use `is_active=True` to see only sources currently being probed.
    """
    return await ingestor_client.list_sources(
        is_active=is_active, offset=offset, limit=limit
    )
```

Key points:

- Docstrings are what MCP clients see as tool descriptions. Write them as real usage guidance, not restated function names.
- Keep tools focused: one responsibility per tool, thin wrapper over the ingestor client.
- Use typed parameters; FastMCP derives the tool schema from type hints.

## Argument patterns

- Filter parameters: use `bool | None` and `int | None` with sensible defaults.
- Pagination: always expose `offset` and `limit`; default `limit=20`.
- IDs: use `int` for resource identifiers.

## Client layer

The real HTTP calls live in `services.mcp.ingestor_client`. The server module only defines the LLM-facing surface:

- Names
- Docstrings
- Argument shapes

Never embed HTTP logic directly in tool functions. Delegate to the client module.

## Available tools

- `list_sources` — list source profiles with optional active filter
- `get_source` — get one source by ID
- `get_source_summary` — aggregate stats across sources
- `probe_source_health` — live reachability/latency check
- `list_scorecards` / `get_scorecard` — reliability metrics
- `list_contract_snapshots` / `list_drift_events` / `get_compatibility_report` — contract drift
- `get_agent_run` / `resume_agent_run` — incident triage agent control

## References

- `services/mcp/server.py` — tool definitions and FastMCP app
- `services/mcp/ingestor_client.py` — HTTP client layer
