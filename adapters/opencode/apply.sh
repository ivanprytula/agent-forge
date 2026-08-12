#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(pwd)"
AGENT_FORGE="$(cd "$REPO_ROOT/../agent-forge" && pwd)"

# 1. Create .opencode/skills/agent-forge symlink
mkdir -p "$REPO_ROOT/.opencode/skills"
link="$REPO_ROOT/.opencode/skills/agent-forge"
if [ ! -e "$link" ]; then
        ln -s "../../../agent-forge/skills" "$link"
    echo "Created symlink: $link"
fi

# 2. Copy SECURITY.md if missing
if [ ! -f "$REPO_ROOT/SECURITY.md" ]; then
    cp "$AGENT_FORGE/instructions/security-and-owasp.instructions.md" "$REPO_ROOT/SECURITY.md"
    echo "Created SECURITY.md"
fi

# 3. Create or update opencode.jsonc
opencode_config="$REPO_ROOT/opencode.jsonc"
if [ ! -f "$opencode_config" ]; then
    cat > "$opencode_config" << 'EOF'
{
  "skills": {
    "paths": [".opencode/skills"]
  },
  "instructions": ["SECURITY.md"]
}
EOF
    echo "Created opencode.jsonc"
else
    if ! grep -q '\.opencode/skills' "$opencode_config"; then
        sed -i 's|"paths": \[.*\]|"paths": [".opencode/skills"]|g' "$opencode_config"
        echo "Updated opencode.jsonc skills.paths"
    fi
    if ! grep -q 'SECURITY.md' "$opencode_config"; then
        sed -i 's|"instructions": \[.*\]|"instructions": ["SECURITY.md"]|g' "$opencode_config"
        echo "Updated opencode.jsonc instructions"
    fi
fi

echo "OpenCode adapter applied successfully"
