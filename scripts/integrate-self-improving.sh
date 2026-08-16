#!/bin/bash
# integrate-self-improving.sh
# Integrates the self-improving-agent instructions into a target repository.
# The skill has been moved to instructions/self-improving-agent.instructions.md.
# This script creates .learnings/ infrastructure and appends guidance to AGENTS.md.

set -euo pipefail

REPO_ROOT="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_FORGE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
    cat << EOF
Usage: $(basename "$0") <repo-root>

Integrates self-improving-agent into <repo-root>:
  - Creates .learnings/ with LEARNINGS.md, ERRORS.md, FEATURE_REQUESTS.md
  - Updates .gitignore to ignore .learnings/
  - Appends self-improvement sections to existing AGENTS.md (preserves current content)

Example:
  $(basename "$0") ../api-observatory
  $(basename "$0") ../api-observatory-infra
EOF
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

if [ ! -d "${REPO_ROOT}" ]; then
    echo "Error: repo root not found: ${REPO_ROOT}" >&2
    exit 1
fi

REPO_ROOT="$(cd "${REPO_ROOT}" && pwd)"
echo "[*] Target repo: ${REPO_ROOT}"

# 1. Skill installation skipped
# The self-improving-agent skill has been moved to instructions/self-improving-agent.instructions.md.
# Agent-specific skill installation is no longer applicable.
echo "[*] Skill installation skipped — self-improving-agent is now an instruction file"

# 2. Create .learnings/
LEARNINGS_DIR="${REPO_ROOT}/.learnings"
mkdir -p "${LEARNINGS_DIR}"
for f in LEARNINGS.md ERRORS.md FEATURE_REQUESTS.md; do
    if [ ! -f "${LEARNINGS_DIR}/${f}" ]; then
        cp "${AGENT_FORGE_ROOT}/.learnings/${f}" "${LEARNINGS_DIR}/${f}"
        echo "[+] Created .learnings/${f}"
    else
        echo "[*] .learnings/${f} already exists — skipping"
    fi
done

# 3. Update .gitignore
GITIGNORE="${REPO_ROOT}/.gitignore"
if [ -f "${GITIGNORE}" ]; then
    if ! grep -qE '^\.learnings/?$' "${GITIGNORE}"; then
        echo ".learnings/" >> "${GITIGNORE}"
        echo "[+] Added .learnings/ to .gitignore"
    else
        echo "[*] .learnings/ already in .gitignore"
    fi
else
    echo ".learnings/" > "${GITIGNORE}"
    echo "[+] Created .gitignore with .learnings/"
fi

# 4. Append to AGENTS.md
AGENTS="${REPO_ROOT}/AGENTS.md"
if [ ! -f "${AGENTS}" ]; then
    echo "Error: ${AGENTS} not found. Cannot integrate self-improvement sections." >&2
    exit 1
fi

BACKUP="${AGENTS}.bak"
cp "${AGENTS}" "${BACKUP}"

python3 - << 'PYEOF' "${AGENTS}" "${BACKUP}"
import re, sys
path, backup = sys.argv[1], sys.argv[2]
with open(backup, 'r', encoding='utf-8') as f:
    original = f.read()

extra = """

---

## Skills

This repo includes reusable skills in agent-specific hidden directories (`.claude/skills/`, `.kilo/skills/`, `.codex/skills/`, etc.). Skills are agent playbooks — structured instructions for repeatable workflows.

| Skill                                                        | Purpose                                                     | Trigger                                                     |
| ------------------------------------------------------------ | ----------------------------------------------------------- | ----------------------------------------------------------- |
| [self-improving-agent](../agent-forge/instructions/self-improving-agent.instructions.md) | Improve this AGENTS.md, create new skills, encode learnings | After completing a task, or when noticing repeated friction |

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

3. **Repeated friction?** If you notice yourself doing the same multi-step workflow more than once, consider creating a new skill in the appropriate agent skills directory. Use the [self-improving-agent instructions](../agent-forge/instructions/self-improving-agent.instructions.md) for the procedure.

4. **Post-task reflection.** After completing a significant task, briefly review:
   - Did anything surprise you?
   - Did you take a path that could be shortcutted next time?
   - If yes, record the insight in this file or as a new skill.

5. **Promotion rule.** Before promoting a learning to this file, check `.learnings/LEARNINGS.md` for related entries. If a pattern has `Recurrence-Count >= 3`, has been seen across at least 2 distinct tasks, and occurred within a 30-day window, it qualifies for promotion. Write the promoted rule as a short prevention rule, not a long incident write-up.

---

## Template Usage

This repository is designed as a centralized skills and instructions repo for the `api-obs-stack` workspace. When integrating it into a project:

1. From the target project root, run the appropriate adapter:
   ```bash
   bash ../agent-forge/adapters/kilo/apply.sh
   ```
2. Update the **Codebase Map** to reflect the project's actual structure.
3. Update **Local Norms** with the project's build commands, test commands, and conventions.
4. Delete placeholder entries (the italicized examples) and replace with real ones.
5. Keep the **Self-Correction Protocol** and **Guardrails** — they apply universally.
6. Add project-specific skills to the appropriate agent skills directory as your workflows emerge.

## Notes

- Project-specific configs (MCP servers, plugin configs, local overrides, runtime state) stay in each project.
- `.github/` CI/CD workflows stay project-local.
- `.learnings/` is gitignored by default to keep developer logs local. Enable team-wide sharing by removing the `.gitignore` entry.
"""

if '## Self-Correction Protocol' in original:
    print("[*] Self-improvement sections already present — skipping append")
    with open(path, 'w', encoding='utf-8') as f:
        f.write(original)
    sys.exit(0)

merged = original.rstrip() + extra
with open(path, 'w', encoding='utf-8') as f:
    f.write(merged)
print("[+] Appended self-improvement sections to AGENTS.md")
PYEOF

rm -f "${BACKUP}"
echo "[+] Backup removed: ${BACKUP}"

echo ""
echo "Done. Summary of changes in ${REPO_ROOT}:"
echo "  - .learnings/ created"
echo "  - .gitignore updated"
echo "  - AGENTS.md updated"
