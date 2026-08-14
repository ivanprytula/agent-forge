#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(pwd)"
AGENT_FORGE="$(cd "$REPO_ROOT/../agent-forge" && pwd)"

# shellcheck source=../adapters/lib.sh
source "$AGENT_FORGE/adapters/lib.sh"

# 1. Refresh all skills from agent-forge into .kilo/skills/
refresh_all_skills "$AGENT_FORGE" "$REPO_ROOT/.kilo/skills"

# 2. Copy agent-manager.example.json if missing
if [ ! -f "$REPO_ROOT/.kilo/agent-manager.json" ]; then
    cp "$AGENT_FORGE/agent-configs/kilo/agent-manager.example.json" "$REPO_ROOT/.kilo/agent-manager.json"
    echo "Created .kilo/agent-manager.json"
fi

# 3. Update AGENTS.md progressive-loading routes (idempotent)
agents_md="$REPO_ROOT/AGENTS.md"
if [ -f "$agents_md" ]; then
    if ! grep -q 'agent-forge/instructions/' "$agents_md"; then
        sed -i 's|\.github/instructions/|../agent-forge/instructions/|g' "$agents_md"
        sed -i 's|\.github/skills/|../agent-forge/skills/|g' "$agents_md"
        echo "Updated AGENTS.md progressive-loading routes"
    else
        echo "AGENTS.md already updated, skipping"
    fi
fi

echo "Kilo adapter applied successfully"
