# AGENTS.md

> This file is the **always-on context** for any coding agent working in this repository.
> It is a living document — agents and humans should update it as the project evolves.

---

## Codebase Map

<!-- Update this section whenever the project structure changes meaningfully. -->
<!-- If you discover this map is stale, update it immediately before continuing your task. -->

```
.
├── AGENTS.md                 # This file — repo memory for agents
├── skills/                   # Agent skill definitions (SKILL.md with frontmatter)
│   └── self-improving-agent/ # Meta-skill: capture learnings, promote to AGENTS.md, extract skills
├── instructions/             # Shared progressive-loading instruction files
├── hooks/                    # Normalized hook definitions + scripts
├── prompts/                  # Reusable prompt templates
├── conventions/              # Shared conventions (commits, bash, etc.)
├── agent-configs/            # Generic agent config templates
├── adapters/                 # Agent-specific scripts to wire this repo into a project
├── .learnings/               # Self-improvement logs (gitignored; see skills/self-improving-agent)
│   ├── LEARNINGS.md
│   ├── ERRORS.md
│   └── FEATURE_REQUESTS.md
├── README.md
└── pyproject.toml
```

**Entry points:**
- `adapters/` — idempotent setup scripts for Kilo, Claude Code, OpenCode, Copilot
- `skills/` — installable skill folders, each with `SKILL.md`
- `hooks/` — reusable hook scripts keyed by agent

**Configuration:**
- `pyproject.toml` — repo metadata and tooling config
- `.pre-commit-config.yaml` — lint/format hooks
- `.markdownlint.yaml`, `.markdownlint-cli2.jsonc` — markdown rules

**Tests:**
- _(none yet — add `tests/` when CI/eval scripts are added)_

---

## Local Norms

<!-- These are repo-specific conventions that agents must follow. -->
<!-- Add entries here as you discover them. Keep them short and actionable. -->

### Build & Run

- Use `uv` for Python dependency management.
- Use `python` from `.venv` when running repo tooling.

### Testing

- Run all tests before marking a task as done.
- Never modify existing tests to make them pass. Fix the code instead.

### Code Style

- Follow PEP 8 for Python.
- Markdown: follow `.markdownlint.yaml` rules.
- Skill SKILL.md files: follow [Agent Skills spec](https://agentskills.io/specification).

### Dependencies

- Do not introduce new dependencies unless the task explicitly requires it.
- If a new dependency is needed, note it in the commit message.

### Git

- Write clear, atomic commits. One logical change per commit.
- Commit messages should describe **what** changed and **why**.

---

## Guardrails

<!-- Things the agent must NOT do. Add entries as you encounter bad agent behavior. -->

- **Never push to main directly.** Always work on a feature branch.
- **Never delete files** unless the task explicitly says to.
- **Never run destructive commands** (e.g., `rm -rf`, `DROP TABLE`) without explicit human approval.
- **Never hardcode secrets or API keys.** Use environment variables.
- **Never ignore failing tests.** If tests fail after your change, fix the code or ask for help.
- **Do not cheat by modifying tests to make them pass.**
- **Never commit `.learnings/` entries** — they are developer-local logs.

---

## Patterns & Gotchas

<!-- Hard-won knowledge. When you discover something non-obvious, record it here. -->
<!-- Format: short statement of the gotcha, followed by what to do instead. -->

- _(e.g., "The v1/users API is deprecated — use v2/users instead.")_
- _(e.g., "When adding a new enum value, also update `constants.ts` or tests will fail.")_
- _(e.g., "The CI uses Node 20 — don't use Node 22 features.")_

---

## Skills

This repo includes reusable skills in the `skills/` directory. Skills are agent playbooks — structured instructions for repeatable workflows.

| Skill                                                        | Purpose                                                     | Trigger                                                     |
| ------------------------------------------------------------ | ----------------------------------------------------------- | ----------------------------------------------------------- |
| [self-improving-agent](skills/self-improving-agent/SKILL.md) | Improve this AGENTS.md, create new skills, encode learnings | After completing a task, or when noticing repeated friction |

### Using Skills

- Read the skill's `SKILL.md` when the trigger condition is met.
- Follow the steps exactly as written.
- If a skill's instructions are stale or wrong, update the skill.

### Creating New Skills

When a workflow repeats — especially across projects — promote it to a skill. Use the `self-improving-agent` skill for guidance on when and how.

---

## Self-Correction Protocol

> This section defines how this file stays alive and accurate.

1. **Stale map?** If you discover that the Codebase Map above doesn't match reality, **update it now** before continuing your task. Don't leave it for later.

2. **User correction?** If a human corrects your behavior (e.g., "don't use that API", "run tests this way"), add the correction to the appropriate section of this file (Local Norms, Guardrails, or Patterns & Gotchas) so future sessions inherit it.

3. **Repeated friction?** If you notice yourself doing the same multi-step workflow more than once, consider creating a new skill in `skills/`. Use the [self-improving-agent skill](skills/self-improving-agent/SKILL.md) for the procedure.

4. **Post-task reflection.** After completing a significant task, briefly review:
   - Did anything surprise you?
   - Did you take a path that could be shortcutted next time?
   - If yes, record the insight in this file or as a new skill.

5. **Promotion rule.** Before promoting a learning to this file, check `.learnings/LEARNINGS.md` for related entries. If a pattern has `Recurrence-Count >= 3`, has been seen across at least 2 distinct tasks, and occurred within a 30-day window, it qualifies for promotion. Write the promoted rule as a short prevention rule, not a long incident write-up.

---

## Template Usage

This repository is designed as a **centralized skills and instructions repo** for the `api-obs-stack` workspace. When integrating it into a project:

1. From the target project root, run the appropriate adapter:
   ```bash
   bash ../agent-forge/adapters/kilo/apply.sh
   ```
2. Update the **Codebase Map** to reflect the project's actual structure.
3. Update **Local Norms** with the project's build commands, test commands, and conventions.
4. Delete placeholder entries (the italicized examples) and replace with real ones.
5. Keep the **Self-Correction Protocol** and **Guardrails** — they apply universally.
6. Add project-specific skills to `skills/` as your workflows emerge.

## Notes

- Project-specific configs (MCP servers, plugin configs, local overrides, runtime state) stay in each project.
- `.github/` CI/CD workflows stay project-local.
- `.learnings/` is gitignored by default to keep developer logs local. Enable team-wide sharing by removing the `.gitignore` entry.
