---
name: across
description: Apply ACROSS design principles (Abstractions & Decomposition, Composition by Default, Escape the Rabbit Hole, Optimize for Change, Simple As Possible, Screaming Contract) when writing, reviewing, or refactoring code. Use as the primary design lens for architecture and module-level decisions.
---

# ACROSS Design Principles

Apply these principles when writing, reviewing, or refactoring code across all projects.

## A — Abstractions & Decomposition

- Extract an interface/protocol when two consumers need different implementations, not before.
- Each module has a defined responsibility with explicit contracts (function signatures, Pydantic schemas, Protocol classes). "Defined" does not mean "single" — a module can do several related things.
- Separate lifecycle management (DI/factory) from business logic. Never make a class manage its own creation.
- Use facades to hide multi-step coordination. A caller should see one function, not a chain of internal calls.

## C — Composition by Default

- Default to composition (pass collaborators in, use Strategy/callback patterns).
- Use inheritance only when building a class hierarchy with intentional extension points (abstract methods, protected hooks) — primarily in framework/infrastructure code.
- If you reach for a base class, ask: "Would a plain function or Protocol work here?" Usually yes.
- Never create a base class to share two methods between two classes. Extract a helper function instead.

## R — Escape from the Rabbit Hole

- Keep refactoring scoped: define what changes, what metric improves, and when to stop before starting.
- Do not refactor adjacent code while fixing a bug or adding a feature unless it directly blocks the task.
- Methods over ~100 lines are a smell. Methods over 200 lines must be split. But splitting into 20-deep call chains within one layer is worse than a long method.
- Prefer short iterations: implement, test, commit. Do not batch multiple features into one large change.

## O — Optimize for Change

- Design so anticipated changes are local, safe, and reversible.
- **Locality**: A change to one business rule should touch one module, not cascade across layers.
- **Minimal coordination**: Adding a new payment provider / data source / API version should require updating one adapter + one registration point, not modifying shared interfaces.
- **Reversibility**: Use expand-contract for data migrations (write both old+new fields, read new-first with fallback). Use feature flags for risky behavioral changes.
- Never leak third-party SDK types into domain code. Wrap external dependencies behind a project-owned interface.
- Never let multiple services read the same database column directly — expose it through an API or shared schema contract.

## S — Simple As Possible

- Match the solution to today's requirements. A CRUD endpoint can call the repository directly — it does not need a service layer, command handler, and mediator.
- Generalize only after the third occurrence. Two similar blocks are not duplication — they are two blocks.
- Do not add abstractions "for testability" if the code is already testable. Do not add abstractions "for future extensibility" if no extension is planned.
- A working 30-line function is better than a 5-class hierarchy that does the same thing.

## S — Screaming Contract

- Name functions and classes with domain verbs: `reserve_inventory()`, `capture_payment()`, `detect_schema_drift()`. Never `process()`, `handle()`, `do_thing()`.
- API endpoints speak domain language: `POST /orders/{id}/payment/capture`, not `POST /api/process`.
- Events reflect domain state changes: `DriftDetected`, `ProbeSucceeded`, not `EventProcessed`.
- Use typed Result/outcome returns instead of bool or raising generic exceptions. The caller should know what went wrong without catching and inspecting.
- Error messages describe the domain problem: `"Source profile not found"`, not `"Object reference error"`.
