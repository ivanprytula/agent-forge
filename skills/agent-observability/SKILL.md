# Agent Observability

## Core Principle

An agent that cannot be inspected is an agent you cannot debug, optimize, or trust. Instrument every step, not just the final response.

## What to Log

For every agent invocation, capture:

- **Trace ID / Run ID**: unique identifier for the full agent execution.
- **Step ID**: sequential identifier within a run.
- **Node / Tool name**: which component produced this step.
- **Input**: serialized input to the node/tool (hash or truncated payload).
- **Output**: serialized output from the node/tool (hash or truncated payload).
- **Latency**: wall-clock time for the step.
- **Token usage**: prompt tokens, completion tokens, total tokens.
- **Model**: exact model ID and provider.
- **Status**: success, error, timeout, cancellation.
- **Error**: exception type, message, stack trace (redacted).

## Structured Event Schema

Use a consistent schema across all agents. Example:

```json
{
  "trace_id": "abc123",
  "step_id": 3,
  "node": "retrieve",
  "tool": "vector_search",
  "input_hash": "sha256:...",
  "output_hash": "sha256:...",
  "latency_ms": 142,
  "tokens_prompt": 850,
  "tokens_completion": 120,
  "model": "claude-3-5-haiku-20241022",
  "status": "success",
  "error": null
}
```

## Tracing Standards

- Use **OpenTelemetry** with gen-ai semantic conventions when possible.
- If OTel is unavailable, emit JSON Lines to a local log file with the schema above.
- Always propagate trace/span IDs across tool calls and sub-agents.
- Record **chain-of-thought** or **reasoning trace** as a separate field, not mixed into tool input/output.
- Tag traces with environment (`dev`, `staging`, `prod`) and agent version.

## Cost Attribution

- Sum token usage per run and per node.
- Estimate cost using the provider's published per-token rates.
- Emit a `agent.run.complete` event with total tokens and estimated cost.
- Set alerts for runs exceeding token or cost thresholds during development.

## Debugging Tips

- Replay a failed run by re-submitting the same inputs and tracing step-by-step.
- Diff two runs: compare step counts, token usage, and tool call order.
- When an agent loops, visualize the step graph (nodes + edges + timestamps).
- Log the **system prompt version** and **tool definitions hash** with every run.

## Evaluation Integration

- Store traces in a format consumable by evaluation tools (Promptfoo, Phoenix, LangSmith).
- Tag traces with the evaluation dataset ID if the run is part of a benchmark.
- Record ground-truth or gold-standard outputs alongside agent outputs for later scoring.

## Privacy and Secrets

- Never log raw secrets, API keys, tokens, or credentials.
- Redact PII from tool inputs/outputs before writing to logs.
- Use content hashes for correlation instead of raw payloads when payloads may contain sensitive data.
