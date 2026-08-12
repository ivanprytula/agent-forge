# Agent Evaluation

## Core Principle

An agent is software. Test it like software: define expected behavior, run it against inputs, and assert outcomes. Do not rely on vibes or manual prompting to judge quality.

## Evaluation Types

| Type | What it measures | When to use |
|------|------------------|-------------|
| **Prompt regression** | Does a prompt change break existing behavior? | Every prompt/tool change |
| **Functional eval** | Does the agent produce the correct final output? | After workflow or tool changes |
| **Tool-use correctness** | Does the agent call the right tools with the right args? | After adding/removing tools |
| **Safety / guardrail** | Does the agent refuse harmful requests or leak secrets? | After policy changes |
| **Performance** | Latency, token usage, step count | In CI for every PR |
| **Human feedback** | Subjective quality, tone, helpfulness | Periodic, not in CI |

## Prompt Regression Testing

- Maintain a **golden prompt set**: 10–50 representative inputs with expected outputs or output schemas.
- Run the agent in CI against the golden set after every prompt change.
- Use **assertions**, not string equality:
  - Assert output schema is valid.
  - Assert required fields are present.
  - Assert the agent did not call forbidden tools.
  - Assert token usage is within a tolerance band.
- If a prompt change is intentional, update the golden set.

## Functional Evaluation

- Define **pass/fail criteria** before running the agent.
- Use deterministic or mocked LLM responses for reproducibility.
- Test edge cases: empty input, malformed input, ambiguous input, conflicting instructions.
- Record the exact prompt, temperature, and model version used.

## Tool-Use Correctness

- Mock or sandbox tools during evaluation.
- Assert the agent calls the expected tool sequence.
- Assert tool arguments match expected schema and value ranges.
- Test error paths: tool returns error, timeout, or invalid output.

## Safety and Guardrails

- Include **adversarial inputs** in the test set (prompt injection, jailbreak attempts).
- Assert the agent refuses or sanitizes known bad patterns.
- Test that secrets are never echoed back in responses.
- Test that PII redaction works before logging or returning data.

## CI Integration

- Run fast evals (<30s) on every commit.
- Run full eval suite on PR merge to main.
- Set CI to **fail** on:
  - Golden set regressions.
  - Token usage increase >20% without approval.
  - New tool calls not in the approved tool list.
  - Secret or PII leakage in outputs.

## Evaluation Tools

- **Promptfoo**: prompt regression, guardrails, scoring. Good for CI.
- **LangSmith / Arize Phoenix**: tracing + human-in-the-loop eval. Good for exploration.
- **Custom pytest harness**: simplest for deterministic tool-use tests.

## Metrics to Track

- **Pass rate**: golden set pass/fail over time.
- **Token efficiency**: tokens per successful task.
- **Step count**: number of tool calls per task.
- **Error recovery**: does the agent self-correct after a tool failure?
- **Latency p50/p95**: wall-clock time per task.

## Anti-patterns

- **Eval-only on "good" paths**: test failure modes, edge cases, and adversarial inputs.
- **String equality on LLM outputs**: use schema validation, semantic similarity, or LLM-as-judge.
- **Flaky evals**: non-deterministic outputs without temperature control or mocked responses.
- **Eval as one-time effort**: evals must evolve with the agent.
