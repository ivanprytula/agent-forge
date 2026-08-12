---
name: 'Agent Cost Guardian'
description: 'Warns or blocks on high-token tool calls during development. Tracks token usage per agent run and enforces configurable limits to prevent runaway costs.'
tags: ['cost', 'budget', 'preToolUse', 'guardrails']
---

# Agent Cost Guardian Hook

Tracks token usage per agent run and enforces configurable limits. Designed for development environments where runaway agent loops can produce unexpectedly large LLM bills.

## Overview

AI agents can enter loops, call redundant tools, or generate excessive intermediate outputs. Without cost guardrails, a single misconfigured run can consume tens of thousands of tokens. This hook intercepts tool calls, checks the projected run total against configured limits, and warns or blocks before the budget is exceeded.

- **Per-run limit**: maximum total tokens for a single agent execution.
- **Per-step limit**: maximum tokens for a single tool call or reasoning step.
- **Warn threshold**: percentage of per-step limit that triggers a warning.
- **Block mode**: exit non-zero to prevent the tool call, or warn-only.

## Features

- Stateful token tracking across steps within a run.
- Configurable limits via `hooks.json`.
- Structured JSON Lines logging for cost auditing.
- Zero dependencies: bash + python3 standard library only.
- Fast execution: sub-millisecond check for most cases.

## Installation

1. Copy the hook folder to your repository:

    ```bash
    cp -r hooks/agent-cost-guardian your-repo/hooks/
    ```

2. Ensure the script is executable:

    ```bash
    chmod +x your-repo/hooks/agent-cost-guardian/guard-tool.sh
    ```

3. Configure limits in `hooks/agent-cost-guardian/hooks.json`:

    ```json
    {
      "config": {
        "max_tokens_per_run": 100000,
        "max_tokens_per_step": 16000,
        "warn_threshold": 0.8,
        "block_on_exceed": true
      }
    }
    ```

4. Wire the hook into your agent's `pre-tool-use` event.

## Configuration

| Field | Default | Description |
|-------|---------|-------------|
| `max_tokens_per_run` | `100000` | Hard limit on total tokens per agent run. |
| `max_tokens_per_step` | `16000` | Hard limit on tokens for a single step. |
| `warn_threshold` | `0.8` | Warn when step tokens exceed this fraction of `max_tokens_per_step`. |
| `block_on_exceed` | `true` | If `true`, exit non-zero to block the tool call. If `false`, warn only. |
| `log_file` | `.agent-cost-guardian.log` | Path to JSON Lines log file. |

## Environment Variables

- `AGENT_STEP_TOKENS`: number of tokens consumed by the current step/tool call. If unset or `0`, the hook assumes a no-op step.

## State File

The hook writes a JSON state file (`.agent-cost-state.json`) in the hook directory to track cumulative tokens across steps. Delete this file to reset the counter between runs.

## Log Format

Each log line is a JSON object:

```json
{"timestamp":"2026-08-12T14:00:00Z","level":"WARN","step_tokens":14500,"pct":91,"max_step":16000}
{"timestamp":"2026-08-12T14:00:05Z","level":"BLOCK","step_tokens":20000,"max_step":16000}
```

## Integration Notes

- For **Kilo**: hook into the `pre-tool-use` lifecycle event.
- For **Claude Code**: hook into the `pre-tool-use` event in `.claude/settings.json`.
- For **Copilot**: hook into the `pre-tool-use` event in `.github/copilot-instructions.md` or `.copilot/`.
- For **OpenCode**: hook into the `pre-tool-use` event in `opencode.jsonc`.

## Troubleshooting

- **Hook never triggers**: ensure `AGENT_STEP_TOKENS` is set by your agent runtime.
- **Blocking on every call**: set `block_on_exceed` to `false` for warn-only mode.
- **State persisting across runs**: delete `.agent-cost-state.json` between sessions.
