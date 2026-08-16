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

# 3. Add compact Skill Discovery reference to copilot-instructions.md if missing
copilot_instr="$REPO_ROOT/.github/copilot-instructions.md"
if [ -f "$copilot_instr" ]; then
    if ! grep -q 'Skill Discovery' "$copilot_instr"; then
        cat >> "$copilot_instr" << 'EOF'

## Skill Discovery

For a lightweight catalog of all available skills, see `../agent-forge/skills/manifest.json` or `../agent-forge/skills/index.md`. Load the full `SKILL.md` only when the task matches the skill's trigger.

EOF
        echo "Added Skill Discovery section to copilot-instructions.md"
    else
        echo "copilot-instructions.md already has Skill Discovery, skipping"
    fi
fi

echo "Copilot adapter applied successfully"
