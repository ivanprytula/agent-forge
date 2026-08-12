# agent-forge

Centralized, agent-agnostic skills and instructions repo for the `api-obs-stack` workspace.

## Structure

- `skills/` — Agent skill definitions (SKILL.md with frontmatter stripped)
- `instructions/` — Shared progressive-loading instruction files
- `hooks/` — Normalized hook definitions + scripts
- `prompts/` — Reusable prompt templates
- `conventions/` — Shared conventions (commits, bash, etc.)
- `agent-configs/` — Generic agent config templates (`.gitignore`, `AGENT_COMMANDS.md`, etc.)
- `adapters/` — Agent-specific scripts to wire this repo into a project

## Setup

This repo is designed to live as a sibling to your project repos:

```text
api-obs-stack/
├── agent-forge/
├── api-observatory/
└── api-observatory-infra/
```

## Adapters

Each adapter script is idempotent and can be run from the project directory:

```bash
# Kilo
bash ../agent-forge/adapters/kilo/apply.sh

# Claude Code
bash ../agent-forge/adapters/claude-code/apply.sh

# OpenCode
bash ../agent-forge/adapters/opencode/apply.sh

# GitHub Copilot
bash ../agent-forge/adapters/copilot/apply.sh
```

## Agent Development Learning Resources

- `skills/agent-loop-design/SKILL.md` — compare ReAct, Plan-Execute, Reflexion, and graph-based agent control flow.
- `instructions/agent-observability.instructions.md` — tracing, logging, cost attribution, and debug standards for agents.
- `instructions/agent-evaluation.instructions.md` — prompt regression, functional eval, tool-use correctness, and CI integration.
- `hooks/agent-cost-guardian/` — warn/block on high-token tool calls during development.
- `skills/self-improving-agent/SKILL.md` — capture learnings, errors, and corrections; promote recurring patterns to `AGENTS.md` or new skills.
- `.learnings/` — project-local learning logs (`LEARNINGS.md`, `ERRORS.md`, `FEATURE_REQUESTS.md`); gitignored by default.

## Notes

- Project-specific configs (MCP servers, plugin configs, local overrides, runtime state) stay in each project.
- CLAUDE.md stays project-local (project-specific stack context).
- `.github/` CI/CD workflows stay project-local.
