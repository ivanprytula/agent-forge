---
name: repo-standards
description: Repository standards for response style, working preferences, privacy, and file access across AI coding agents. Use when reviewing or modifying repo-level behavior rules, deciding on patch scope, or determining which files are out of scope for agent reads.
---

# Repo Standards

## Read Scope

Read this file first. Read only instruction files that match the files you touch. Do not read `.env`, secrets, vault files, or unrelated config unless explicitly asked. Do not scan `.venv`.

## Response Style

Default shape: result, key validation, next step if needed. Keep explanations short and technical. Prefer prose over lists unless the content is inherently list-shaped. For simple tasks, one short paragraph is enough.

## Working Preferences

- Prefer small, reviewable patches over broad refactors.
- Offer one recommended approach; mention alternatives only when tradeoffs are material.
- Preserve backward compatibility unless the user explicitly authorizes a breaking change.
- Keep runtime dependencies minimal and explain why each new dependency is needed.
- When a product decision is ambiguous, present concrete options and wait for direction.
- Favor operationally simple solutions with explicit failure modes and useful observability.

## Privacy and File Access

### Respect `.gitignore`

Treat `.gitignore`, `.dockerignore`, `.pre-commit-config.yaml` `exclude:` lists, or any project ignore file as out of scope. Do not read ignored files unless the user explicitly names that specific file. Typical ignored paths: `.venv/`, `.env`, `.env.*`, `node_modules/`, `_archive/`, `*.log`, build artifacts, `.copilot/`, `.kilo/`, `.cursor/`, `.aws/`, `.gcp/`, `.azure/`, `.ssh/`.

### Never read secrets or credential stores

Never read `.env`, `.env.*`, `secrets/`, `credentials`, or any file with secrets, API keys, passwords, or tokens — even if committed (`.env.example` fixtures are fine). Ask the user to share only the relevant masked value. This overrides read-scope allowance.

Never read `~/.aws/`, `~/.gcp/`, `~/.azure/`, `~/.kube/config`, `~/.docker/config.json`, `~/.netrc`, `~/.boto`, `~/.config/gcloud/`, `~/.config/gh/hosts.yml`, `~/.ssh/id_*`, `~/.gnupg/`. When a hook appears to come from a credential file, fix the *configuration*, never the credential file itself. Treat placeholder values (`test`, `example`, `AKIAIOSFODNN7EXAMPLE`) as real values.

### Diagnostics without exposing secrets

For credential bugs, use only non-sensitive metadata: file existence, size, line count, env-var *names* (not values), or redacted output. Never echo, log, or paste actual credential values. Refer to values by masked prefix only.

### When the user mentions a credentials issue

Do not reproduce by reading the credential file. Pivot to: (a) the hook's source/regex, (b) the committed file the hook flagged, (c) a non-invasive fix in repo config. Committed config/credential files (e.g. `infra/terraform/**/*.tf`, `.env.example`) are fine to read.
