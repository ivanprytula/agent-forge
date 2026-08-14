#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(pwd)"
AGENT_FORGE="$(cd "$REPO_ROOT/../agent-forge" && pwd)"

# shellcheck source=../adapters/lib.sh
source "$AGENT_FORGE/adapters/lib.sh"

# 1. Copy .claude/.gitignore if missing
if [ ! -f "$REPO_ROOT/.claude/.gitignore" ]; then
    mkdir -p "$REPO_ROOT/.claude"
    cp "$AGENT_FORGE/agent-configs/claude/.gitignore" "$REPO_ROOT/.claude/.gitignore"
    echo "Created .claude/.gitignore"
fi

# 2. Refresh all skills from agent-forge into .claude/skills/
refresh_all_skills "$AGENT_FORGE" "$REPO_ROOT/.claude/skills"

# 3. Create .claude/settings.json with hooks if missing
settings="$REPO_ROOT/.claude/settings.json"
if [ ! -f "$settings" ]; then
    mkdir -p "$REPO_ROOT/.claude"
    cat > "$settings" << EOF
{
  "hooks": {
    "UserPromptSubmit": [{
      "hooks": [{
        "type": "command",
        "command": "\${CLAUDE_PROJECT_DIR}/.claude/skills/self-improving-agent/scripts/activator.sh"
      }]
    }]
  }
}
EOF
    echo "Created .claude/settings.json with self-improvement hooks"
else
    echo ".claude/settings.json already exists, skipping"
fi

# 4. Add compact Shared Standards reference to CLAUDE.md if missing
claude_md="$REPO_ROOT/CLAUDE.md"
if [ -f "$claude_md" ]; then
    if ! grep -q 'Shared Standards' "$claude_md"; then
        cat >> "$claude_md" << 'EOF'

## Shared Standards

Centralized standards in `../agent-forge/`:
- Skills → `../agent-forge/skills/<name>/SKILL.md` (linked into `.claude/skills/`)
- Instructions → `../agent-forge/instructions/<topic>.instructions.md`
- Read the matching file before producing significant code in that area.

EOF
        echo "Added Shared Standards section to CLAUDE.md"
    else
        echo "CLAUDE.md already has Shared Standards, skipping"
    fi
fi

echo "Claude Code adapter applied successfully"
