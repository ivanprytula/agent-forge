#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(pwd)"
AGENT_FORGE="$(cd "$REPO_ROOT/../agent-forge" && pwd)"

# shellcheck source=../adapters/lib.sh
source "$AGENT_FORGE/adapters/lib.sh"

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

# 3. Ensure AGENTS.md references agent-behavior.instructions.md
agents_md="$REPO_ROOT/AGENTS.md"
if [ -f "$agents_md" ]; then
    if ! grep -q 'agent-behavior.instructions.md' "$agents_md"; then
        # Remove generic inline rules (Priority through the section before Patterns & Gotchas)
        if grep -q '^## Priority' "$agents_md"; then
            sed -i '/^## Priority/,/^## Patterns & Gotchas/{/^## Priority/d; /^## Patterns & Gotchas/!d}' "$agents_md"
        fi
        # Prepend centralized reference after title
        sed -i "2 i\\
Global rules for agents working in this repository. Generic behavior rules live in \`../agent-forge/instructions/agent-behavior.instructions.md\`." "$agents_md"
        echo "Updated AGENTS.md to reference agent-behavior.instructions.md"
    else
        echo "AGENTS.md already references agent-behavior.instructions.md, skipping"
    fi
fi

# 4. Replace verbose SECURITY.md with lean redirect to agent-forge
security_md="$REPO_ROOT/SECURITY.md"
if [ -f "$security_md" ]; then
    if [ "$(wc -l < "$security_md")" -gt 5 ]; then
        cat > "$security_md" <<'EOF'
# Security Instructions

Global secure-coding rules are maintained in `../agent-forge/instructions/security-and-owasp.instructions.md`.
EOF
        echo "Replaced SECURITY.md with lean redirect"
    else
        echo "SECURITY.md already lean, skipping"
    fi
fi

echo "Kilo adapter applied successfully"
