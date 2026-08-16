---
description: "Automatically compact the Kilo context window when it reaches 60% usage to maintain response quality, prevent context overflow, and ensure efficient token utilization."
---

# Kilo Context Compaction at 60%

## Overview

Proactively manage Kilo context window usage by compacting at 60% of taken space. This prevents degradation in response quality, avoids hard context limits, and keeps the working set focused on current task state rather than stale history.

## When to Compact

Compact when the conversation has reached approximately **60% context utilization**. This threshold balances:
- **Retaining enough history** to maintain coherence across the session
- **Preventing quality loss** that occurs near the context window limit
- **Avoiding emergency compaction** under pressure

## How to Estimate Usage

Agents should monitor these signals to estimate 60% usage:

1. **Conversation length**: After 10-15 substantive exchanges in a complex task, context is often approaching 50-70%.
2. **Tool output volume**: Large file reads, diffs, and command outputs consume context rapidly.
3. **Token density**: Dense technical discussions, long code blocks, and nested reasoning consume more tokens per exchange.
4. **Remaining headroom**: If you estimate you need 40% more context to complete the current subtask, you are likely near 60%.

## Triggering Compaction

When you determine context is at ~60%:

### Automatic (Preferred)

Ensure `compaction.auto` is enabled in `kilo.json`:
```jsonc
{
  "compaction.auto": true,
  "compaction.prune": true
}
```

With `compaction.auto` enabled, Kilo will compact automatically when context is full. However, the 60% threshold requires proactive agent behavior.

### Manual Trigger

Use the compact command before the conversation degrades:
- **Slash command**: `/compact`
- **Keybind**: `<leader>c` (Ctrl+X then C)
- **Alternative**: `/summarize`

After compacting, briefly restate the current task objective and key findings so the summarized context preserves essential state.

## Best Practices

1. **Compact early, not late**: Better to compact at 60% with a clean summary than at 90% with degraded responses.
2. **Preserve critical state**: Before compacting, mentally note the current goal, important decisions, and unresolved questions. These should be summarized or re-stated after compaction.
3. **Don't over-compact**: Compacting every 2-3 messages adds overhead. Aim for natural breakpoints or the 60% threshold.
4. **Checkpoint long tasks**: For multi-phase tasks, consider compacting at phase boundaries even if below 60%.

## Configuration

To make 60% compaction the default behavior, add to `kilo.json`:
```jsonc
{
  "compaction.auto": true,
  "compaction.prune": true
}
```

Note: Kilo does not currently expose a percentage-based compaction threshold in `kilo.json`. The 60% rule is an agent behavior guideline, not a hard configuration limit.

## Integration with Sessions

- After compacting, verify the summary captured the current task state.
- If the summary is insufficient, manually add the missing context before continuing.
- For fork/windowing workflows, compact each branch independently to keep contexts lean.
