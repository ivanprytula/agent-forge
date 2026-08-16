#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(pwd)"
AGENT_FORGE="$(cd "$REPO_ROOT/../agent-forge" && pwd)"

# shellcheck source=../adapters/lib.sh
source "$AGENT_FORGE/adapters/lib.sh"

# 2. Create .codex/skills.yaml if missing
skills_yaml="$REPO_ROOT/.codex/skills.yaml"
if [ ! -f "$skills_yaml" ]; then
    mkdir -p "$REPO_ROOT/.codex"
    cat > "$skills_yaml" << EOF
skills:
  paths:
    - ../agent-forge/skills
EOF
    echo "Created .codex/skills.yaml"
else
    echo ".codex/skills.yaml already exists, skipping"
fi

echo "Codex adapter applied successfully"
