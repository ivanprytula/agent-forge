#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(pwd)"
AGENT_FORGE="$(cd "$REPO_ROOT/../agent-forge" && pwd)"

# 1. Copy .claude/.gitignore if missing
if [ ! -f "$REPO_ROOT/.claude/.gitignore" ]; then
    mkdir -p "$REPO_ROOT/.claude"
    cp "$AGENT_FORGE/agent-configs/claude/.gitignore" "$REPO_ROOT/.claude/.gitignore"
    echo "Created .claude/.gitignore"
fi

# 2. Install self-improving-agent skill into .claude/skills/
mkdir -p "$REPO_ROOT/.claude/skills"
if [ ! -d "$REPO_ROOT/.claude/skills/self-improving-agent" ]; then
    cp -R "$AGENT_FORGE/skills/self-improving-agent" "$REPO_ROOT/.claude/skills/self-improving-agent"
    echo "Installed .claude/skills/self-improving-agent"
else
    echo ".claude/skills/self-improving-agent already exists, skipping"
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

# 4. Update CLAUDE.md with Shared Agent Standards section
claude_md="$REPO_ROOT/CLAUDE.md"
if [ -f "$claude_md" ]; then
    if ! grep -q 'Shared Agent Standards' "$claude_md"; then
        cat >> "$claude_md" << 'EOF'

## Shared Agent Standards

This project uses centralized agent standards from `agent-forge`. Read these before
producing significant code in the matching area:

EOF
        for skill_dir in "$AGENT_FORGE"/skills/*/; do
            skill_name="$(basename "$skill_dir")"
            echo "- **$skill_name** → ../agent-forge/skills/$skill_name/SKILL.md" >> "$claude_md"
        done
        echo "" >> "$claude_md"
        for instr in "$AGENT_FORGE"/instructions/*.instructions.md; do
            instr_name="$(basename "$instr")"
            echo "- $instr_name → ../agent-forge/instructions/$instr_name" >> "$claude_md"
        done
        echo "" >> "$claude_md"
        echo "Updated CLAUDE.md with Shared Agent Standards"
    else
        echo "CLAUDE.md already has Shared Agent Standards, skipping"
    fi
fi

echo "Claude Code adapter applied successfully"
