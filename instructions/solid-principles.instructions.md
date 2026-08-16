---
applyTo: 'src/**/*.py, **/*.py'
description: "SOLID principles for clean, maintainable code with pain-first decision trees, production-ready Python/FastAPI examples, antipatterns, and integration with design patterns. Use when reviewing, designing, or refactoring object-oriented code for single responsibility, open-closed design, Liskov substitution, interface segregation, or dependency inversion."
---

# SOLID Principles for Clean, Maintainable Code

## Overview

SOLID is an acronym for **five design principles** that help make code more maintainable, flexible,
testable, and understandable. These principles are not Python-specific—they apply to all
object-oriented languages—but are especially powerful when applied consistently in distributed
systems and microservices.

| Principle                 | Purpose                                              | Symbol |
| ------------------------- | ---------------------------------------------------- | ------ |
| **S**ingle Responsibility | One reason to change per class                       | 🎯     |
| **O**pen-Closed           | Open for extension, closed for modification          | 🔒     |
| **L**iskov Substitution   | Subtypes substitutable without breaking behavior     | 🔄     |
| **I**nterface Segregation | Clients depend only on methods they use              | ✂️     |
| **D**ependency Inversion  | Depend on abstractions, not concrete implementations | 🔗     |

---

## 1. Single Responsibility Principle (SRP)

See `references/srp.md` for the full antipattern, solution, FastAPI example, and checklist.

## 2. Open-Closed Principle (OCP)

See `references/ocp.md` for the full antipattern, polymorphism solution, FastAPI example, and checklist.

## 3. Liskov Substitution Principle (LSP)

See `references/lsp.md` for the full antipattern, correct hierarchy solution, FastAPI example, and checklist.

## 4. Interface Segregation Principle (ISP)

See `references/isp.md` for the full antipattern, segregated interfaces solution, FastAPI example, and checklist.

## 5. Dependency Inversion Principle (DIP)

See `references/dip.md` for the full antipattern, abstraction solution, dependency injection, FastAPI example, and checklist.

## SOLID in api-observatory

### Example: Applying SOLID to Scenario 1

**Single Responsibility:**

- `UserService`: User CRUD only
- `OrderService`: Order management only
- `NotificationService`: Notifications only

**Open-Closed:**

- New order types added via `OrderProcessor` subclasses
- New payment methods added via `PaymentMethod` subclasses

**Liskov Substitution:**

- All `OrderProcessor` implementations honor the processing contract
- All `PaymentMethod` implementations honor the charging contract

**Interface Segregation:**

- `OrderCreator`, `DiscountApplier`, `DeliveryScheduler` as separate interfaces
- Offline orders implement only what they need

**Dependency Inversion:**

- `CheckoutService` depends on `PaymentProcessor` abstraction, not `CreditCardProcessor`
- `OrderService` depends on `NotificationService` abstraction, not `EmailService`
- Implementations selected via dependency injection

---

## SOLID Violations Checklist

### Red Flags to Watch For

- [ ] Class/function name includes "Service", "Manager", "Processor", "Controller" (>1
      responsibility?)
- [ ] Giant if-elif chains instead of polymorphism
- [ ] Subclass throws `NotImplementedError` or `raise NotImplemented`
- [ ] Class implements methods it doesn't use
- [ ] Service creates its own dependencies (`self.dependency = DependencyClass()`)
- [ ] High-level code imports and uses low-level concrete classes
- [ ] Tests require complex setup of multiple mocked services
- [ ] Changes to one service break other services
- [ ] Reusing code requires copying-and-pasting

### When Something Smells Wrong

**Question to ask:**

1. Does this class have multiple reasons to change? → SRP violation
2. Would adding a new feature require modifying this class? → OCP violation
3. Would substituting this subtype break the program? → LSP violation
4. Does this class implement methods it doesn't use? → ISP violation
5. Does this depend on concrete details instead of abstractions? → DIP violation

**Fix approach:**

1. Extract responsibilities into separate classes (SRP)
2. Use polymorphism instead of conditionals (OCP)
3. Fix the class hierarchy or use composition (LSP)
4. Split the interface into smaller contracts (ISP)
5. Inject abstractions instead of creating concrete instances (DIP)

---

## Integration with Design Patterns

SOLID principles complement design patterns:

| Pattern   | Primary SOLID Principle |
| --------- | ----------------------- |
| Factory   | SRP, OCP, DIP           |
| Strategy  | OCP, DIP                |
| Decorator | OCP                     |
| Adapter   | OCP, LSP                |
| Proxy     | DIP                     |
| Observer  | DIP                     |
| Command   | DIP, ISP                |
| State     | OCP                     |

---

## Practical Guidelines

1. **Start with SRP:** Make sure each class does one thing.
2. **Then apply OCP:** When changes come, extend (don't modify).
3. **Ensure LSP:** All subtypes are safe substitutes.
4. **Keep ISP in mind:** Don't force unnecessary dependencies.
5. **End with DIP:** Depend on abstractions, inject concrete details.

**Order of Application:** Start with dependencies (DIP) → Shape interfaces (ISP) → Define behaviors
(OCP) → Structure hierarchies (LSP) → Isolate responsibilities (SRP).

---

## Quick Checklist: Code Review

- [ ] **S**: Each class has one reason to change
- [ ] **O**: New features addable without modifying existing classes
- [ ] **L**: Subtypes safely substitutable for base types
- [ ] **I**: Classes depend only on methods they use
- [ ] **D**: High-level depends on abstractions, not low-level concretions
- [ ] **Tests**: Testable with minimal mocking/setup
- [ ] **Reusability**: Services reusable in different contexts
- [ ] **Maintenance**: Changes don't cascade unpredictably
