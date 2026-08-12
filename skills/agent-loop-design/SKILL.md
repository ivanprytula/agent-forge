# Agent Loop Design

## When to Activate

Use this skill when designing, refactoring, or debugging an AI agent's control flow. It applies to custom loops, LangGraph graphs, CrewAI crews, AutoGen teams, Pydantic-AI agents, or any system where an LLM decides which tool to call, whether to branch, and when to stop.

## Quick Reference: Loop Patterns

| Pattern | Shape | When to Use | Key Trade-off |
|---------|-------|-------------|---------------|
| **ReAct** | Interleaved reasoning + action | Simple tool use, few steps, single path | Easy to implement; can loop forever without memory |
| **Plan-Execute** | Plan once, execute steps | Multi-step tasks with stable plan | Deterministic flow; brittle if plan is wrong |
| **Reflexion** | Trial + feedback + retry | Tasks where mistakes are learnable | Slower; needs good feedback signal |
| **Graph / State Machine** | Explicit nodes + edges | Complex workflows, branching, human-in-the-loop | More upfront design; clear debugging surface |
| **Agentic RAG** | Retrieve → reason → answer | Knowledge-heavy Q&A with sources | Retrieval quality dominates correctness |

## Decision Rules

- **Start simple.** Use ReAct for single-turn or short tool chains.
- **Add structure only when needed.** If you find yourself prompting "always do X before Y," move that rule into explicit control flow.
- **Prefer explicit state over prompt memory.** Store intermediate results, tool outputs, and errors in structured state, not in the conversation history alone.
- **Limit recursion depth.** Every loop pattern should have a hard step limit or timeout.
- **Separate planning from execution** when the task has >3 steps or >1 tool category.
- **Use graph-based control** when you need deterministic branching, human approval gates, or conditional retries.

## Pattern Details

### ReAct

```text
Thought → Action → Observation → Thought → Action → Observation → ... → Final Answer
```

Best for:
- 1–3 tool calls
- Single domain (e.g., search + summarize)
- Fast prototyping

Pitfalls:
- Context bloat from repeated reasoning traces
- No persistent memory across turns unless you add it
- Hard to enforce policies (e.g., "never call X before Y")

### Plan-Execute

```text
Plan (LLM or structured) → Execute step 1 → Execute step 2 → ... → Finalize
```

Best for:
- Stable, multi-step workflows
- Pipelines where order matters
- Batch or ETL-like tasks

Pitfalls:
- Fails badly if early steps produce bad data
- Recovery requires explicit replanning

### Reflexion

```text
Attempt → Critic → Feedback → Revised Attempt → Critic → ... → Accept
```

Best for:
- Code generation, writing, or structured output
- Tasks with an automated grader or self-check
- Learning from past failures

Pitfalls:
- Token-heavy
- Needs high-quality critique prompt
- Can oscillate without convergence criteria

### Graph / State Machine

```text
Node A → [condition] → Node B or Node C
         → [error] → Fallback Node
```

Best for:
- Multi-agent handoffs
- Human-in-the-loop approvals
- Retry/backoff with explicit policy
- Debugging and observability

Frameworks:
- **LangGraph**: graph-based state machine with persistence
- **CrewAI**: task delegation with role-based agents
- **AutoGen**: conversation-driven multi-agent
- **Pydantic-AI**: type-safe tool calling with structured outputs

## Anti-patterns

- **Prompt-only control flow**: burying "always do X" in the system prompt instead of code.
- **Infinite loops**: no step limit, no timeout, no escape hatch.
- **God prompt**: one giant system prompt handling all branches instead of modular nodes.
- **Tool spam**: calling 5 tools when 1 structured query would suffice.
- **Hidden state**: relying on conversation history to remember earlier tool outputs instead of explicit state.

## Observability Hooks

- Log every node/step transition with timestamp and input/output hashes.
- Record token usage per node, not just per request.
- Emit structured events: `agent.step.start`, `agent.step.end`, `agent.loop.complete`, `agent.loop.timeout`.
- Tag tool calls with the node that issued them.

## Validation

- Unit-test each node/step in isolation with mocked tool outputs.
- Run end-to-end loop tests with a fake LLM that returns deterministic responses.
- Set a max-step guard (e.g., 10 steps) in every loop and test that it triggers.
- Measure: step count, token usage per step, tool error rate, convergence rate.
