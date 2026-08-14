#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(pwd)"
AGENT_FORGE="$(cd "$REPO_ROOT/../agent-forge" && pwd)"

# shellcheck source=../adapters/lib.sh
source "$AGENT_FORGE/adapters/lib.sh"

# 1. Copy agent config files if missing
if [ ! -f "$REPO_ROOT/.copilot/AGENT_COMMANDS.md" ]; then
    mkdir -p "$REPO_ROOT/.copilot"
    cp "$AGENT_FORGE/agent-configs/copilot/AGENT_COMMANDS.md" "$REPO_ROOT/.copilot/AGENT_COMMANDS.md"
    echo "Created .copilot/AGENT_COMMANDS.md"
fi

if [ ! -f "$REPO_ROOT/.copilot/README.md" ]; then
    mkdir -p "$REPO_ROOT/.copilot"
    cp "$AGENT_FORGE/agent-configs/copilot/README.md" "$REPO_ROOT/.copilot/README.md"
    echo "Created .copilot/README.md"
fi

# 2. Refresh all skills from agent-forge into .github/copilot/skills/
refresh_all_skills "$AGENT_FORGE" "$REPO_ROOT/.github/copilot/skills"

# 3. Add compact Shared Standards reference to copilot-instructions.md if missing
copilot_instr="$REPO_ROOT/.github/copilot-instructions.md"
if [ -f "$copilot_instr" ]; then
    if ! grep -q 'Shared Standards' "$copilot_instr"; then
        cat >> "$copilot_instr" << 'EOF'

## Shared Standards

Centralized standards in `../agent-forge/`:
- Skills → `../agent-forge/skills/<name>/SKILL.md` (linked into `.github/copilot/skills/`)
- Instructions → `../agent-forge/instructions/<topic>.instructions.md`
- Read the matching file before producing significant code in that area.

EOF
        echo "Added Shared Standards section to copilot-instructions.md"
    else
        echo "copilot-instructions.md already has Shared Standards, skipping"
    fi
fi

echo "Copilot adapter applied successfully"
