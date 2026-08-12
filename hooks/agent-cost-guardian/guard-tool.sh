#!/usr/bin/env bash
set -euo pipefail

HOOK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${HOOK_ROOT}/hooks.json"
LOG_FILE="${HOOK_ROOT}/.agent-cost-guardian.log"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[agent-cost-guardian] hooks.json not found at $CONFIG_FILE" >&2
    exit 1
fi

MAX_TOKENS_PER_RUN=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['config']['max_tokens_per_run'])")
MAX_TOKENS_PER_STEP=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['config']['max_tokens_per_step'])")
WARN_THRESHOLD=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['config']['warn_threshold'])")
BLOCK_ON_EXCEED=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['config']['block_on_exceed'])")

RUN_STATE_FILE="${HOOK_ROOT}/.agent-cost-state.json"

if [ -f "$RUN_STATE_FILE" ]; then
    RUN_TOKENS=$(python3 -c "import json; print(json.load(open('$RUN_STATE_FILE')).get('total_tokens', 0))")
else
    RUN_TOKENS=0
fi

STEP_TOKENS="${AGENT_STEP_TOKENS:-0}"
if [ -z "$STEP_TOKENS" ] || [ "$STEP_TOKENS" = "0" ]; then
    STEP_TOKENS=0
fi

PROJECTED_RUN_TOTAL=$((RUN_TOKENS + STEP_TOKENS))

if [ "$PROJECTED_RUN_TOTAL" -gt "$MAX_TOKENS_PER_RUN" ]; then
    echo "[agent-cost-guardian] BLOCK: projected run total ${PROJECTED_RUN_TOTAL} exceeds max ${MAX_TOKENS_PER_RUN}" >&2
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) BLOCK run_total=${PROJECTED_RUN_TOTAL} max=${MAX_TOKENS_PER_RUN}" >> "$LOG_FILE"
    if [ "$BLOCK_ON_EXCEED" = "true" ]; then
        exit 1
    fi
elif [ "$STEP_TOKENS" -gt "$MAX_TOKENS_PER_STEP" ]; then
    echo "[agent-cost-guardian] BLOCK: step tokens ${STEP_TOKENS} exceeds max per step ${MAX_TOKENS_PER_STEP}" >&2
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) BLOCK step_tokens=${STEP_TOKENS} max_step=${MAX_TOKENS_PER_STEP}" >> "$LOG_FILE"
    if [ "$BLOCK_ON_EXCEED" = "true" ]; then
        exit 1
    fi
elif [ "$STEP_TOKENS" -gt "$((MAX_TOKENS_PER_STEP * WARN_THRESHOLD / 1))" ]; then
    WARN_PCT=$((STEP_TOKENS * 100 / MAX_TOKENS_PER_STEP))
    echo "[agent-cost-guardian] WARN: step tokens ${STEP_TOKENS} is ${WARN_PCT}% of max ${MAX_TOKENS_PER_STEP}" >&2
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) WARN step_tokens=${STEP_TOKENS} pct=${WARN_PCT}" >> "$LOG_FILE"
fi

python3 -c "
import json
from pathlib import Path
state_path = Path('${RUN_STATE_FILE}')
new_total = ${PROJECTED_RUN_TOTAL}
if state_path.exists():
    state = json.loads(state_path.read_text())
else:
    state = {'total_tokens': 0, 'step_count': 0}
state['total_tokens'] = new_total
state['step_count'] = state.get('step_count', 0) + 1
state_path.write_text(json.dumps(state))
"

exit 0
