#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(pwd)"
AGENT_FORGE="$(cd "$REPO_ROOT/../agent-forge" && pwd)"

# 1. Install self-improving-agent skill into .kilo/skills/
mkdir -p "$REPO_ROOT/.kilo/skills"
if [ ! -d "$REPO_ROOT/.kilo/skills/self-improving-agent" ]; then
    cp -R "$AGENT_FORGE/skills/self-improving-agent" "$REPO_ROOT/.kilo/skills/self-improving-agent"
    echo "Installed .kilo/skills/self-improving-agent"
else
    echo ".kilo/skills/self-improving-agent already exists, skipping"
fi

# 2. Copy agent-manager.example.json if missing
if [ ! -f "$REPO_ROOT/.kilo/agent-manager.json" ]; then
    cp "$AGENT_FORGE/agent-configs/kilo/agent-manager.example.json" "$REPO_ROOT/.kilo/agent-manager.json"
    echo "Created .kilo/agent-manager.json"
fi

# 3. Update AGENTS.md progressive-loading routes
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
