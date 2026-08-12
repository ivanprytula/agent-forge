#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(pwd)"
AGENT_FORGE="$(cd "$REPO_ROOT/../agent-forge" && pwd)"

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

# 2. Update .github/copilot-instructions.md
copilot_instr="$REPO_ROOT/.github/copilot-instructions.md"
if [ -f "$copilot_instr" ]; then
    if ! grep -q 'agent-forge' "$copilot_instr"; then
        cat >> "$copilot_instr" << 'EOF'

## Shared Agent Standards

This project uses centralized agent standards from `agent-forge`:
EOF
        for skill_dir in "$AGENT_FORGE"/skills/*/; do
            skill_name="$(basename "$skill_dir")"
            echo "- **$skill_name** → ../agent-forge/skills/$skill_name/SKILL.md" >> "$copilot_instr"
        done
        echo "" >> "$copilot_instr"
        for instr in "$AGENT_FORGE"/instructions/*.instructions.md; do
            instr_name="$(basename "$instr")"
            echo "- $instr_name → ../agent-forge/instructions/$instr_name" >> "$copilot_instr"
        done
        echo "" >> "$copilot_instr"
        echo "Updated .github/copilot-instructions.md with agent-forge references"
    else
        echo ".github/copilot-instructions.md already references agent-forge, skipping"
    fi
fi

echo "Copilot adapter applied successfully"
