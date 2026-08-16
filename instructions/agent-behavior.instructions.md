---
applyTo: '*'
description: "Global agent behavior rules for code/plan modes. Covers priority, read scope, execution rules, mode gating, response style, working preferences, git operations, commit messages, and privacy/file access."
---

## Priority

Optimize for low token usage. Be brief in chat. Prefer file edits and focused commands over long prose. Do not narrate internal reasoning, tool choice, or step-by-step plans unless asked. Do not paste large code blocks when the file can be edited directly. Do not restate the same fact twice. Summarize important lines only.

## Read scope

Read this file first. Read only instruction files that match the files you touch. Do not read `.env`, secrets, vault files, or unrelated config unless explicitly asked. Do not scan `.venv`.

- Before reading a skill or instruction file, estimate its token cost. Prefer the core
  `SKILL.md` first; load `references/*.md` only when the specific section is needed.
  If the working set exceeds ~60% of the context window, compact or summarize stale content
  before loading more.

## Execution rules

Use tools immediately when the user asks to change files. Use `apply_patch` for manual edits. Use `uv run` for Python commands, tests, scripts, Alembic, Ruff, and Uvicorn. After refactoring — especially when changing test files or touching more than one module — run all code-quality pre-commit hooks (Ruff, docs, checker, Bandit, type checking, etc.) before running unit/integration/e2e tests. After testing, remove unneeded test artifacts; inspect targets first and never remove user or persistent data without explicit approval. Do not commit, amend, or create branches unless explicitly asked. Do not revert user changes unless explicitly asked. Never run destructive commands (`rm -rf`, `DROP TABLE`, `terraform apply`, `ansible-playbook`) without first showing the user what will change and getting explicit confirmation.

**Validate edits immediately.** After editing any code file, run the appropriate linter/type checker on that file before moving on. Do not batch edits across many files and validate only at the end. Catch syntax/indentation errors per file, then continue.

## CLI discovery contract

When a CLI flag or subcommand is unknown, run `tool --help` first and parse the output before constructing the command. If the tool is not installed, fall back to the documented alternative in the project's Justfile or shell scripts. Do not guess flags or subcommands from memory.

## Mode gating

At the start of each turn, check the current execution mode (ask, code, plan, etc.) before performing file operations. In ask/read-only modes, only read files; never write, edit, or execute side-effecting commands. File writes and edits are permitted only in code/plan modes.

## Response style

Default shape: result, key validation, next step if needed. Keep explanations short and technical. Prefer prose over lists unless the content is inherently list-shaped. For simple tasks, one short paragraph is enough.

## Working preferences

- Prefer small, reviewable patches over broad refactors.
- Offer one recommended approach; mention alternatives only when tradeoffs are material.
- Preserve backward compatibility unless the user explicitly authorizes a breaking change.
- Keep runtime dependencies minimal and explain why each new dependency is needed.
- When a product decision is ambiguous, present concrete options and wait for direction.
- Favor operationally simple solutions with explicit failure modes and useful observability.

## Git operations

Never use `git add .` or `git add -A`. When staging for commit, explicitly list only the files relevant to the current task. If the task scope is unclear, ask before staging. Never drop git stashes in any repository; preserve them across sessions. **Never git push code unless explicitly given such a task.**

## Commit messages

Write a short headline using the conventional commits framework (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, etc.). Optionally add a commit body that explains why the change was made and the motivation, but do not list the files changed — that is already visible in `git diff`.

## Privacy and file access

### Respect `.gitignore`

Treat `.gitignore`, `.dockerignore`, `.pre-commit-config.yaml` `exclude:` lists, or any project ignore file as out of scope. Do not read ignored files unless the user explicitly names that specific file. Typical ignored paths: `.venv/`, `.env`, `.env.*`, `node_modules/`, `_archive/`, `*.log`, build artifacts, `.copilot/`, `.kilo/`, `.cursor/`, `.aws/`, `.gcp/`, `.azure/`, `.ssh/`, `*.tfvars`, `*.tfstate*`, `vault.yml`.

### Never read secrets or credential stores

Never read `.env`, `.env.*`, `*.tfvars` (non-`.example`), `*.tfstate*`, `vault.yml`, `secrets/`, `credentials`, or any other file that contains secrets, API keys, passwords, or tokens — even if committed (`.env.example` fixtures are fine). If you need info from these files, ask the user to check and share only the relevant line/value, masked if needed. This overrides the general "read scope" allowance — these files are never in scope regardless of `.gitignore` status.

Never read `~/.aws/`, `~/.gcp/`, `~/.azure/`, `~/.kube/config`, `~/.docker/config.json`, `~/.netrc`, `~/.boto`, `~/.config/gcloud/`, `~/.config/gh/hosts.yml`, `~/.ssh/id_*`, `~/.gnupg/`. When a hook, linter, or CI rule appears to come from a credential file, fix the *configuration* (`.pre-commit-config.yaml`, exclude lists, env-var setup) — never the credential file itself. Treat placeholder values (`test`, `example`, `AKIAIOSFODNN7EXAMPLE`) the same as real values.

### Diagnostics without exposing secrets

For credential bugs, use only non-sensitive metadata: file existence (`ls -la`), file size, line count, env-var *names* (not values), or redacted output (`sed 's/=.*$/=***/'`). Never echo, log, or paste the value of an access key, secret key, session token, password, API token, or vault-decrypted value. Refer to credential values only by their masked prefix (e.g. `test****`) as the hook itself does.

### When the user mentions a credentials issue

Do not try to reproduce by reading the credential file. Pivot to: (a) reading the hook's source/regex, (b) reading the *committed* file the hook flagged, (c) suggesting a non-invasive fix in the repo config. Committed config/credential files (e.g. `terraform/**/*.tf`, sample `*.tfvars.example`, `backend.*.hcl.example`) are fine to read; the rule applies to the user's private local credential store and to real state/vault files.
