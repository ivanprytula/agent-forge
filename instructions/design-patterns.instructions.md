---
applyTo: 'src/**/*.py, **/*.py'
description: "Design patterns in Python and FastAPI with a pain-first decision tree, 13 creational/structural/behavioral patterns, pattern selection guide, and 15 antipatterns to avoid. Use when selecting, applying, or reviewing design patterns in async Python services or FastAPI applications."
---

# Design Patterns in Python & FastAPI

> "Design patterns rarely fail because they are 'wrong.' They fail because we reach for them at the
> wrong moment, for the wrong reason." — the real failure is pattern-first thinking rather than
> problem-first thinking.

---

## Pain-First Decision Tree

**The single most important rule: diagnose the friction BEFORE picking a pattern.**

Reaching for a pattern without first identifying the pain it relieves leads to over-engineering,
unnecessary indirection, and code that is harder to read than what it replaced. Use this decision
tree as your entry point.

### Step 1: Identify Which Friction You Feel

```
What is actually hurting right now?
│
├─► "This object is complex to create — lots of params,
│    multiple steps, or many implementations to choose from."
│    └─► Friction Type 1: Object Creation → go to Creational Patterns
│
├─► "This code depends on something awkward — a legacy system,
│    a third-party lib with a bad interface, or I need transparent
│    access control / lazy loading around an object."
│    └─► Friction Type 2: Component Boundaries → go to Structural Patterns
│
└─► "This code is getting tangled with conditionals — if-elif
     chains that grow every time behavior changes, or I need to
     decouple event producers from consumers."
     └─► Friction Type 3: Changing Behavior → go to Behavioral Patterns
```

---

### Friction Type 1 — Object Creation Candidates

```
What about object creation is hurting?
│
├─► "I keep constructing this in multiple places and
│    need exactly one shared instance."
│    └─► Singleton
│
├─► "I need one of several concrete types, selected at
│    runtime, and callers shouldn't know which."
│    └─► Factory / Abstract Factory
│
├─► "The object has many optional fields and I'm tired
│    of huge constructors or long keyword-arg lists."
│    └─► Builder
│
└─► "Creating this object is expensive; I need similar
     copies with small variations."
      └─► Prototype
```

**Ask before choosing a Creational pattern:**

- [ ] Is the creation pain actually FROM the caller, or is the class itself too complex?
- [ ] Would a plain `dataclass` or `Pydantic` model solve it without a pattern?
- [ ] For Singleton: can FastAPI's `Depends()` injection serve the same purpose more testably?
- [ ] For Factory: are you sure there are multiple real implementations today (not hypothetical)?

---

### Friction Type 2 — Component Boundary Candidates

```
What about the object boundary is hurting?
│
├─► "I'm working with a legacy system / third-party lib
│    whose interface doesn't match what my code expects."
│    └─► Adapter
│
├─► "I need to add behavior (logging, caching, auth)
│    to objects dynamically without modifying them."
│    └─► Decorator
│
├─► "I have a complex hierarchy — leaves and composites —
│    and I want to treat them all the same way."
│    └─► Composite
│
├─► "My caller has to coordinate 5+ objects to accomplish
│    one task; I want to hide that complexity."
│    └─► Facade
│
└─► "I need to intercept access to an object — for lazy
     loading, access control, or logging."
      └─► Proxy
```

**Ask before choosing a Structural pattern:**

- [ ] Could simpler refactoring (extracting a method or class) remove the pain instead?
- [ ] For Facade: are you hiding complexity or just moving it?
- [ ] For Decorator: is this composable behavior (the pattern fits) or just one extra thing?
- [ ] For Proxy: is the same interface needed, or would a thin wrapper function suffice?

---

### Friction Type 3 — Behavior Change Candidates

```
What about behavior is hurting?
│
├─► "Something needs to react to events in another
│    object without tight coupling."
│    └─► Observer
│
├─► "I have interchangeable algorithms and a big if-elif
│    chain that grows when I add a new one."
│    └─► Strategy
│
├─► "I need to queue, log, or undo operations — requests
│    should be first-class objects."
│    └─► Command
│
└─► "Behavior depends on state and I have a tangled
     mess of if-elifs checking which state I'm in."
      └─► State
```

**Ask before choosing a Behavioral pattern:**

- [ ] Is the real problem too many responsibilities in one class (SRP violation)?
- [ ] For Observer: does simpler function callbacks solve it without the Observer ceremony?
- [ ] For Strategy: is there actually more than one algorithm today, or is this speculative?
- [ ] For State: are there at least 3 states with different rules? Fewer may not justify the
       pattern.
- [ ] For Command: do you need undo, queue, or audit log? Without these, a plain function suffices.

---

## Creational Patterns

See `references/creational-patterns.md` for Singleton, Factory/Abstract Factory, Builder, and Prototype with FastAPI-specific guidance.

## Structural Patterns

See `references/structural-patterns.md` for Adapter, Decorator, Composite, Facade, and Proxy with production-ready FastAPI examples.

## Behavioral Patterns

See `references/behavioral-patterns.md` for Observer, Strategy, Command, and State patterns with event systems, caching, task queues, and workflow engines.

## Pattern Selection Guide

| Pattern       | Solves                           | Use When                                               |
| ------------- | -------------------------------- | ------------------------------------------------------ |
| **Singleton** | Single global instance           | Shared resource (config, logger, connection pool)      |
| **Factory**   | Object creation logic            | Multiple implementations, runtime selection            |
| **Builder**   | Complex construction             | Many optional params, fluent API                       |
| **Prototype** | Expensive object cloning         | Deep copying needed, template-based creation           |
| **Adapter**   | Incompatible interfaces          | Legacy system integration, third-party libs            |
| **Decorator** | Dynamic behavior attachment      | Composable features (logging, caching, auth)           |
| **Composite** | Tree structures                  | Hierarchical data (file system, org chart)             |
| **Facade**    | Complex subsystem simplification | Hiding internal complexity                             |
| **Proxy**     | Object access control            | Lazy loading, access control, logging                  |
| **Observer**  | One-to-many event notification   | Event systems, pub-sub, reactive updates               |
| **Strategy**  | Interchangeable algorithms       | Runtime algorithm selection, avoiding `if-elif` chains |
| **Command**   | Request encapsulation            | Task queues, undo/redo, operation logging              |
| **State**     | State-dependent behavior         | State machines, workflow engines, complex transitions  |

---

## Antipatterns to Avoid

See `references/antipatterns.md` for 15 antipatterns including catching `Exception`, magic numbers, mutable defaults, heavy work in `__init__`, wildcard imports, shadowing built-ins, and more.

## Design Pattern Application Checklist

### Before Reaching for a Pattern

- [ ] Can you describe the pain in one sentence without naming a pattern?
- [ ] Is the friction coming from object creation, component boundaries, or behavior change?
- [ ] Would a simpler refactoring (extract method/class) remove the pain without a pattern?
- [ ] Does the pattern solve a problem you have TODAY, not a hypothetical future problem?
- [ ] If this is "for flexibility," can you name a concrete scenario where that flexibility is
      needed?

### Pattern-Specific Checks

- [ ] **Singleton**: Is there only ONE shared instance? (config, logger) — prefer `Depends()` in
      FastAPI.
- [ ] **Factory**: Are there multiple REAL implementations already selected at runtime?
- [ ] **Builder**: Does the object have many optional parameters causing caller confusion?
- [ ] **Prototype**: Is copying genuinely cheaper than constructing from scratch?
- [ ] **Adapter**: Are you bridging an incompatible external/legacy interface?
- [ ] **Decorator**: Is this behavior composable — can multiple decorators stack independently?
- [ ] **Decorator NOT overused**: Would straightforward inheritance or a plain function be simpler?
- [ ] **Composite**: Is the hierarchy actually recursive (nodes contain nodes)?
- [ ] **Facade**: Is complexity genuinely hidden, or just moved one level deeper?
- [ ] **Proxy**: Same interface as the real object? If not, consider Adapter instead.
- [ ] **Observer**: Are there truly multiple independent consumers of the same event?
- [ ] **Strategy**: More than one algorithm exists today (not speculative)?
- [ ] **Command**: Undo, audit log, or queue are concrete requirements?
- [ ] **State**: At least three distinct states with different transition rules?
- [ ] **All patterns**: Is the added indirection justified by the complexity being removed?
