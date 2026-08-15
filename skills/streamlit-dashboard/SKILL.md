# streamlit-dashboard

Build the Streamlit dashboard UI using the project's framework-agnostic core and adapter pattern.

When to invoke: modifying or extending `services/dashboard/ui/streamlit/` or `services/dashboard/core/`.

## Architecture

```
services/dashboard/
  core/           # Framework-agnostic business logic, state, data fetching
  ui/
    streamlit/    # Streamlit-specific adapters and panels
      app.py      # Entry point
      adapter.py  # Converts core state to Streamlit widgets
      panels/     # Reusable UI sections (incidents, live_stream, observations, source_manager)
```

The entry point `streamlit_app.py` delegates entirely to `ui.streamlit.app.main()`.

## Adapter pattern

`adapter.py` bridges the framework-agnostic `core/` layer to Streamlit primitives:

- Convert core state objects to Streamlit widget calls (`st.metric`, `st.dataframe`, `st.plotly_chart`).
- Keep all business logic in `core/`; `ui/streamlit/` contains only rendering code.
- If the dashboard framework ever changes (e.g. to Chainlit or Reflex), only `ui/` adapters need rewriting.

## Panel structure

Each panel in `ui/streamlit/panels/` is a self-contained section:

- `incidents.py` — dependency incident list and detail view
- `live_stream.py` — real-time observation feed
- `observations.py` — historical observation table with filters
- `source_manager.py` — source registry CRUD and health

Panels receive state from the core layer and render independently. Use `st.session_state` only for transient UI state (expanders, selected rows).

## Adding a new panel

1. Create `ui/streamlit/panels/<feature>.py` with a `render(state)` function.
2. Import and call it from `ui/streamlit/app.py` in the desired page order.
3. Keep data access inside the core layer; panels must not call HTTP clients directly.

## Dependencies

- Streamlit is installed in the dashboard service's `pyproject.toml`.
- Plotly is used for charts; prefer `st.plotly_chart` over raw HTML.
- Prometheus metrics are auto-exposed by the dashboard app if configured.

## References

- `services/dashboard/streamlit_app.py` — entry point
- `services/dashboard/ui/streamlit/app.py` — Streamlit app layout
- `services/dashboard/ui/streamlit/adapter.py` — core-to-Streamlit adapter
- `services/dashboard/ui/streamlit/panels/` — existing panels
