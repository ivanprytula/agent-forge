#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(pwd)"
AGENT_FORGE="$(cd "$REPO_ROOT/../agent-forge" && pwd)"

# 1. Install self-improving-agent skill into .codex/skills/
mkdir -p "$REPO_ROOT/.codex/skills"
if [ ! -d "$REPO_ROOT/.codex/skills/self-improving-agent" ]; then
    cp -R "$AGENT_FORGE/skills/self-improving-agent" "$REPO_ROOT/.codex/skills/self-improving-agent"
    echo "Installed .codex/skills/self-improving-agent"
else
    echo ".codex/skills/self-improving-agent already exists, skipping"
fi

# 2. Create .codex/skills.yaml if missing
skills_yaml="$REPO_ROOT/.codex/skills.yaml"
if [ ! -f "$skills_yaml" ]; then
    mkdir -p "$REPO_ROOT/.codex"
    cat > "$skills_yaml" << EOF
skills:
  paths:
    - .codex/skills
EOF
    echo "Created .codex/skills.yaml"
else
    echo ".codex/skills.yaml already exists, skipping"
fi

echo "Codex adapter applied successfully"
