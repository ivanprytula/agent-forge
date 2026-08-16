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
        "command": "\${CLAUDE_PROJECT_DIR}/../agent-forge/skills/self-improving-agent/scripts/activator.sh"
      }]
    }]
  }
}
EOF
    echo "Created .claude/settings.json with self-improvement hooks"
else
    echo ".claude/settings.json already exists, skipping"
fi

# 4. Add compact skill discovery reference to CLAUDE.md if missing
claude_md="$REPO_ROOT/CLAUDE.md"
if [ -f "$claude_md" ]; then
    if ! grep -q 'Skill Discovery' "$claude_md"; then
        cat >> "$claude_md" << 'EOF'

## Skill Discovery

For a lightweight catalog of all available skills, see `../agent-forge/skills/manifest.json` or `../agent-forge/skills/index.md`. Load the full `SKILL.md` only when the task matches the skill's trigger.

EOF
        echo "Added Skill Discovery section to CLAUDE.md"
    else
        echo "CLAUDE.md already has Skill Discovery, skipping"
    fi
fi

echo "Claude Code adapter applied successfully"
