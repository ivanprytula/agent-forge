# Git Workflow

## Staging

Never use `git add .` or `git add -A`. When staging for commit, explicitly list only the files relevant to the current task. If the task scope is unclear, ask before staging. Never drop git stashes in any repository; preserve them across sessions.

## Commit Messages

Write a short headline using the conventional commits framework (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, etc.). Optionally add a commit body that explains why the change was made and the motivation, but do not list the files changed — that is already visible in `git diff`.

## Immediate Validation

After editing any `.py` file, run `python -m py_compile <file>` or `ruff check <file>` on that file before moving on. Do not batch edits across many files and validate only at the end. Catch syntax/indentation errors per file, then continue.

After refactoring — especially when changing test files or touching more than one module — run all code-quality pre-commit hooks (Ruff, docs, checker, Bandit, type checking, etc.) before running unit/integration/e2e tests.
