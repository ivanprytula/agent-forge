# opentelemetry-instrumentation

Wire OpenTelemetry distributed tracing into FastAPI services with graceful degradation.

When to invoke: adding or modifying OTel tracing in `libs/platform/tracing.py` or any FastAPI app lifespan.

## Setup pattern

```python
from libs.platform.tracing import setup_tracing

@app.on_event("startup")
async def startup():
    if settings.otel_enabled:
        setup_tracing(
            app,
            endpoint=settings.otel_exporter_otlp_endpoint,
            service_name=settings.otel_service_name,
        )
```

The `setup_tracing` helper is idempotent — safe to call multiple times.

## Instrumentation stack

```python
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

resource = Resource(attributes={"service.name": service_name})
provider = TracerProvider(resource=resource)
exporter = OTLPSpanExporter(endpoint=endpoint, insecure=True)
provider.add_span_processor(BatchSpanProcessor(exporter))
trace.set_tracer_provider(provider)

FastAPIInstrumentor.instrument_app(app)
SQLAlchemyInstrumentor().instrument(enable_commenter=True)
```

Key points:

- Always set `service.name` on the `Resource` so traces are identifiable in Grafana Tempo.
- Use `BatchSpanProcessor` for production; it buffers and exports asynchronously.
- `enable_commenter=True` on SQLAlchemy adds `db.statement` spans automatically.
- `insecure=True` is acceptable inside a trusted Docker network; use TLS for external collectors.

## Graceful degradation

Wrap imports and initialization in `try/except ImportError` and `except Exception`:

```python
try:
    from opentelemetry import trace
    # ... instrument
except ImportError:
    logger.warning("otel_tracing_unavailable", extra={"hint": "Install opentelemetry-sdk packages"})
except Exception as exc:
    logger.warning("otel_tracing_setup_failed", extra={"error": str(exc)})
```

If OTel packages are missing or the endpoint is unreachable, log a warning and continue without tracing.

## Trace correlation

```python
from libs.platform.tracing import get_trace_id

trace_id = get_trace_id()
logger.info("event", extra={"trace_id": trace_id, "user_id": user_id})
```

`get_trace_id()` returns a 32-char hex string or `None`. Use it to inject `trace_id` into structured log output so logs correlate with traces in Tempo.

## Suppress tzlocal noise

```python
os.environ.setdefault("TZ", os.environ.get("TZ", "UTC"))
```

Set `TZ` before importing OTel to suppress tzlocal's diagnostic print statements during tracer initialization.

## Configuration

Expose these settings per service:

- `otel_enabled: bool` — toggle tracing on/off
- `otel_exporter_otlp_endpoint: str` — e.g. `http://tempo:4317`
- `otel_service_name: str` — logical service name

## References

- `libs/platform/tracing.py` — shared tracing setup helper
- `services/inference/main.py` — inference service OTel wiring
- `services/ingestor/main.py` — ingestor service OTel wiring
- `infra/monitoring/grafana/provisioning/datasources/tempo.yml` — Tempo datasource config
