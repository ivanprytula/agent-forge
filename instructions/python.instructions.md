---
applyTo: 'src/**/*.py, **/*.py'
description: "Python code standards covering typing, formatting with Ruff, async/await, memory model, Pydantic v2 validation, SQLAlchemy 2.0 async, error handling, logging, functional programming, testing, resilience patterns, and design patterns. Use when writing, reviewing, or refactoring Python code in this project."
---

# Python Code Standards

## Language & Typing

### Python Version & Type Hints

- **Minimum**: Python 3.14 with modern syntax.
- **Type hints**: Mandatory for all function signatures and complex variables.
- **Modern syntax**: Use PEP 585 (`list[str]`, `dict[str, int]`) and PEP 604 (`str | None`) instead
  of `List`, `Dict`, `Optional`.
- **Return types**: Always annotate return types explicitly.
- **Type checker**: Run `ty check src/` regularly. All code must pass type checking.

### Examples

```python
# ✓ Good
async def get_user(user_id: int, db: AsyncSession) -> User | None:
    """Fetch user by ID. Returns None if not found."""
    query = select(UserModel).where(UserModel.id == user_id)
    result = await db.execute(query)
    return result.scalar_one_or_none()

# ✗ Bad
def get_user(user_id, db):  # Missing types
    query = select(UserModel).where(UserModel.id == user_id)
    return db.execute(query).scalar_one_or_none()
```

---

## Formatting & Linting

### Ruff Configuration

- **Line length**: 119 characters.
- **Quote style**: Double quotes (`"string"`).
- **Import style**: `from x import y` with double quotes.
- **Rules**: E (pycodestyle errors), W (warnings), F (pyflakes), I (isort), B (flake8-bugbear), UP
  (pyupgrade), SIM (simplify).
- **Run before commit**: `ruff check --fix && ruff format src/`.

### Naming Conventions

- **Functions/variables**: `snake_case`.
- **Classes**: `PascalCase`.
- **Constants**: `UPPERCASE_WITH_UNDERSCORES`.
- **Private members**: `_leading_underscore` (convention, not enforced).

### Imports

- Standard library first, then third-party, then local imports.
- Group imports using blank lines.
- For async imports, use `from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine`.

---

## Async/Await & Event Loop

### FastAPI Routes

- **All routes must be `async`**: Never use sync functions in FastAPI handlers.
- **Never block the event loop**: No `time.sleep()`, blocking I/O, or CPU-intensive work directly in
  handlers.
- **Async HTTP**: Use `httpx.AsyncClient` for external API calls.
- **Database queries**: Use `asyncpg` with SQLAlchemy 2.0 async patterns.
- **Offload heavy work**: Use background tasks or task queues for long-running operations.

### Good Pattern

```python
from fastapi import FastAPI
import httpx

app = FastAPI()

@app.get("/users/{user_id}")
async def get_user(user_id: int, db: AsyncSession) -> User:
    """Fetch user with async database query."""
    query = select(UserModel).where(UserModel.id == user_id)
    result = await db.execute(query)
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@app.post("/notify")
async def notify(user_id: int, db: AsyncSession) -> dict:
    """Send async notification without blocking."""
    async with httpx.AsyncClient() as client:
        response = await client.post("https://api.notification.com/send", json={"user_id": user_id})
    return {"status": "sent"}
```

### Bad Pattern

```python
@app.get("/users/{user_id}")
async def get_user(user_id: int):
    time.sleep(1)  # ✗ Blocks event loop
    return db.query(User).filter(User.id == user_id).first()  # ✗ Sync query in async context

@app.post("/notify")
async def notify(user_id: int):
    requests.post("https://...", json={"user_id": user_id})  # ✗ Blocking sync HTTP
```

---

## Python Memory Model & Object System

See `references/python-memory-model.md` for the deep dive: object identity vs equality,
memory architecture, mutable vs immutable, argument passing, common pitfalls, `__slots__`,
`array`/`bytes`, generators, and memory profiling.

## Pydantic v2 Validation

### Schemas & Models

- Use `BaseModel` for request/response schemas.
- Use `BaseSettings` (from `pydantic-settings`) for configuration.
- All schemas must have type hints and field descriptions where relevant.
- Use `Field()` for additional validation, examples, or descriptions (useful for OpenAPI docs).

### Example

```python
from pydantic import BaseModel, Field

class UserCreate(BaseModel):
    """Request schema for creating a user."""
    name: str = Field(..., min_length=1, max_length=255)
    email: str = Field(..., pattern=r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[A-Za-z]{2,}$")
    age: int = Field(None, ge=0, le=150)

class UserResponse(BaseModel):
    """Response schema for user data."""
    id: int
    name: str
    email: str
    created_at: datetime

    class Config:
        from_attributes = True  # For SQLAlchemy ORM models
```

### Configuration

```python
from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    """Application configuration from environment variables."""
    database_url: str
    redis_url: str
    api_key: str
    debug: bool = False

    class Config:
        env_file = ".env"

@lru_cache
def get_settings() -> Settings:
    return Settings()
```

---

## Database & ORM (SQLAlchemy 2.0 + asyncpg)

### Async Session Management

- Always use `AsyncSession` context managers for clean connection handling.
- Use dependency injection in FastAPI to pass sessions.

### Example

```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base

DATABASE_URL = "postgresql+asyncpg://user:password@localhost/dbname"

engine = create_async_engine(DATABASE_URL, echo=False, future=True)
AsyncSessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Dependency: get database session."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()

# Usage in routes
@app.get("/users")
async def list_users(db: AsyncSession = Depends(get_db)) -> list[UserResponse]:
    """Fetch all users."""
    query = select(UserModel).order_by(UserModel.created_at.desc())
    result = await db.execute(query)
    users = result.scalars().all()
    return [UserResponse.model_validate(u) for u in users]
```

### ORM Models

- Define models in `models.py` using `declarative_base()`.
- Use `__tablename__` explicitly.
- Always provide meaningful column names and types.
- Add foreign keys, indexes, and constraints as needed.

```python
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import declarative_base, relationship
from datetime import datetime, timezone

Base = declarative_base()

class UserModel(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    posts = relationship("PostModel", back_populates="author")
```

---

## Error Handling & Logging

### HTTP Exceptions

- Use `HTTPException` from FastAPI for client errors (4xx).
- Always provide meaningful `status_code` and `detail` messages.
- Log errors with structured JSON logging.

### Example

```python
from fastapi import HTTPException
from python_json_logger import jsonlogger
import logging

# Setup structured logging
logger = logging.getLogger(__name__)
handler = logging.StreamHandler()
formatter = jsonlogger.JsonFormatter()
handler.setFormatter(formatter)
logger.addHandler(handler)
logger.setLevel(logging.INFO)

@app.get("/users/{user_id}")
async def get_user(user_id: int, db: AsyncSession = Depends(get_db)) -> UserResponse:
    """Fetch user or raise 404."""
    try:
        query = select(UserModel).where(UserModel.id == user_id)
        result = await db.execute(query)
        user = result.scalar_one_or_none()
        if not user:
            logger.warning(f"User not found", extra={"user_id": user_id, "action": "get_user"})
            raise HTTPException(status_code=404, detail=f"User {user_id} not found")
        return UserResponse.model_validate(user)
    except SQLAlchemyError as e:
        logger.error(f"Database error", extra={"error": str(e), "user_id": user_id})
        raise HTTPException(status_code=500, detail="Internal server error")
```

### Structured Logging

- Always log in JSON format (via `python-json-logger`).
- Include request IDs for tracing across services.
- Log at appropriate levels: `DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`.
- Include relevant context (e.g., user_id, request_path, elapsed_time).

---

## Lambda & Functional Programming

See `references/lambda-functional-programming.md` for the deep dive: lambda syntax and limits,
best practices, closures, functional tools, and lambda code of conduct.

## Testing (pytest + pytest-asyncio)

### Test Structure

- Place tests in `tests/` directory alongside `app/`.
- Use `conftest.py` for shared fixtures (database, mock services, etc.).
- Name test functions/files with `test_` prefix.
- Organize tests: unit tests, integration tests, end-to-end tests.

### Async Tests

- Decorate with `@pytest.mark.asyncio`.
- Use async fixtures with `@pytest_asyncio.fixture`.

### Example

```python
import pytest
from pytest_asyncio import fixture
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from app.models import Base, UserModel
from app.api import app

@fixture
async def db_session():
    """Fixture: in-memory test database."""
    engine = create_async_engine("sqlite+aiosqlite:///:memory:", future=True)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    AsyncSessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with AsyncSessionLocal() as session:
        yield session

@pytest.mark.asyncio
async def test_get_user_not_found(db_session: AsyncSession):
    """Test: fetching non-existent user returns 404."""
    client = TestClient(app)
    response = client.get("/users/999")
    assert response.status_code == 404
    assert "not found" in response.json()["detail"].lower()

@pytest.mark.asyncio
async def test_create_user(db_session: AsyncSession):
    """Test: creating a user stores data correctly."""
    client = TestClient(app)
    payload = {"name": "Alice", "email": "alice@example.com"}
    response = client.post("/users", json=payload)
    assert response.status_code == 201
    assert response.json()["name"] == "Alice"

    # Verify in database
    query = select(UserModel).where(UserModel.email == "alice@example.com")
    result = await db_session.execute(query)
    user = result.scalar_one_or_none()
    assert user is not None
    assert user.name == "Alice"
```

### Coverage

- Aim for >80% coverage on critical paths (services, API handlers).
- Test error cases, edge cases, and failure scenarios.
- Use `pytest --cov=src` to measure coverage.

---

## Resilience Patterns

### Retry Logic with Backoff

When calling external services, always implement retry logic with exponential backoff:

```python
import asyncio
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=2, max=10))
async def call_external_api(user_id: int) -> dict:
    """Call external API with retry logic."""
    async with httpx.AsyncClient() as client:
        response = await client.post("https://api.example.com/process", json={"user_id": user_id})
        response.raise_for_status()
        return response.json()
```

### Circuit Breaker Pattern

For services prone to cascading failures, use a circuit breaker:

```python
from pybreaker import CircuitBreaker

breaker = CircuitBreaker(fail_max=5, reset_timeout=60)

async def get_from_cache(key: str) -> str | None:
    """Get from cache with circuit breaker protection."""
    try:
        result = await breaker.call(redis_client.get, key)
        return result
    except Exception as e:
        logger.error(f"Circuit breaker open or cache error: {e}")
        return None
```

---

## Design Patterns

> See [design-patterns.instructions.md](../instructions/design-patterns.instructions.md) for the full guide:
> pain-first decision tree, 13 patterns (creational, structural, behavioral), pattern selection
> guide, and 15 antipatterns to avoid.

---

## Docstrings & Comments

### Comment & Docstring Policy

Do not write comments or docstrings that restate the obvious. The file name, module path, class name, and function signature are already visible in the repo. Comments and docstrings should explain non-obvious behavior, trade-offs, gotchas, or intent that cannot be inferred from the name alone.

- Remove module-level docstrings that merely describe what the file contains (e.g., `"""ORM models..."""`, `"""Unit tests for..."""`).
- Remove docstrings that parrot the function/class name (e.g., `"""Return X."""` on `get_x()`, `"""List X."""` on `list_x()`).
- Remove test docstrings that duplicate the test name (e.g., `"""Test connection pool."""` on `test_connection_pool`).
- Keep docstrings only when they document non-obvious parameters, return contracts, side effects, or rationale.

### Google-Style Docstrings

- Use for all functions and classes, especially complex ones.
- Include: Args, Returns, Raises, Examples.

### Example

```python
async def process_payment(user_id: int, amount: float, db: AsyncSession) -> Transaction:
    """Process a payment transaction for a user.

    This function creates a new transaction record, deducts from the user's balance,
    and notifies the payment service. It uses retry logic to handle transient failures.

    Args:
        user_id: The ID of the user making the payment.
        amount: The payment amount in cents.
        db: Database session for ORM queries.

    Returns:
        Transaction: The created transaction record with status and timestamp.

    Raises:
        HTTPException: If user not found (404) or insufficient balance (400).
        PaymentServiceError: If the payment service is unreachable after retries.

    Example:
        >>> transaction = await process_payment(user_id=123, amount=5000, db=session)
        >>> print(transaction.id)
        456
    """
    # Fetch user and validate balance
    user = await get_user(user_id, db)
    if user.balance < amount:
        raise HTTPException(status_code=400, detail="Insufficient balance")

    # Create transaction (eventually consistent with payment service)
    transaction = TransactionModel(user_id=user_id, amount=amount, status="pending")
    db.add(transaction)
    await db.commit()

    # Notify payment service (with retry)
    await call_payment_service(transaction.id, amount)
    return transaction
```

### Inline Comments

- Explain the "why," not the "what" (code should be self-documenting).
- Use for non-obvious logic or trade-off justifications.

```python
# Good comment: explains why
# We retry with exponential backoff because the payment service may be temporarily overloaded
# during peak hours. A linear backoff would waste resources; exponential gives the service time to recover.
await call_with_backoff(payment_service_url, transaction_data)

# Bad comment: just describes the code
# Loop through users and send email
for user in users:
    send_email(user.email)
```

---

## Code Organization

### File Structure

```
backend/app/
  ├── main.py              # FastAPI initialization, app setup, middleware
  ├── config.py            # Settings (Pydantic BaseSettings)
  ├── api.py               # Route handlers (v1 of API endpoints)
  ├── models.py            # SQLAlchemy ORM models
  ├── schemas.py           # Pydantic request/response models
  ├── database.py          # Session management, connection pooling
  ├── middleware.py        # Logging, error handling, CORS setup
  ├── services/            # Business logic (decoupled from routes)
  │   ├── user_service.py  # User-related operations
  │   └── payment_service.py
  ├── utils/               # Utilities (helpers, constants)
  │   ├── logger.py        # Logging setup
  │   ├── decorators.py    # Custom decorators (e.g., @require_auth)
  │   └── constants.py
  └── exceptions.py        # Custom exception classes

tests/
  ├── conftest.py          # Pytest fixtures
  ├── unit/
  │   ├── test_services.py
  │   └── test_utils.py
  ├── integration/
  │   ├── test_api_users.py
  │   └── test_api_payments.py
  └── fixtures/
      └── sample_data.py   # Test data fixtures
```

### Single Responsibility

- Each module should have a clear, single purpose.
- Move business logic to `services/` instead of leaking into routes.
- Keep models, schemas, and database concerns separate.

---

## Data Structures & Performance

See `references/data-structures-performance.md` for the deep dive: lists, dicts, sets, deques,
tuples, performance characteristics, and guidance on choosing the right structure.

## Generators & Iterators

See `references/generators-iterators.md` for the deep dive: generator basics, expressions, use
cases, `send()`/`throw()`/`close()`, generators vs lists, and production guidelines.

## Performance & Observability

### Metrics & Health Checks

- Expose Prometheus metrics on `/metrics`.
- Implement `/health` endpoint for liveness/readiness checks.
- Track key metrics: request latency, error rates, queue depth, database connection pool.

### Example

```python
from prometheus_client import Counter, Histogram, Gauge
from fastapi import FastAPI
from prometheus_client import generate_latest, CollectorRegistry, REGISTRY

REGISTRY = CollectorRegistry()
request_duration = Histogram("request_duration_seconds", "Request latency", registry=REGISTRY)
request_count = Counter("requests_total", "Total requests", ["method", "endpoint", "status"], registry=REGISTRY)
db_connection_pool = Gauge("db_connection_pool_current", "Current DB connections", registry=REGISTRY)

@app.get("/health")
async def health_check() -> dict:
    """Health check endpoint."""
    return {"status": "healthy"}

@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint."""
    return generate_latest(REGISTRY)
```

---

## Quick Checklist

Before committing Python code:

- [ ] Type hints on all function signatures
- [ ] `ty check src/` passes without errors
- [ ] `ruff check --fix && ruff format` applied
- [ ] All routes are `async`
- [ ] Database queries use `AsyncSession`
- [ ] Errors are logged with structured JSON
- [ ] Tests exist for critical paths (>80% coverage)
- [ ] Docstrings on complex functions/classes
- [ ] No sync I/O (no `time.sleep()`, `requests.get()`, etc.)
- [ ] Pydantic v2 schemas for request/response validation

### Antipattern Checks

- [ ] No `except Exception:` or bare `except:` — use specific exceptions
- [ ] No magic numbers/strings — use `Enum` or named constants
- [ ] No mutable default arguments (e.g., `items=[]`)
- [ ] No heavy work in `__init__` — defer to explicit `start()`, `connect()` methods
- [ ] No wildcard imports (`from x import *`)
- [ ] No shadowing of built-ins (`list`, `id`, `filter`, etc.)
- [ ] No global mutable state — inject dependencies or wrap in classes
- [ ] Exception handlers are tight (not too many lines in `try` block)
- [ ] Comparisons to `None` use `is` / `is not` , not `==` / `!=`
- [ ] No list comprehensions for side effects — use explicit `for` loops
- [ ] Using `logger` (not `print()`) for all logging
- [ ] Resources use context managers (`with` / `async with`)

### Lambda & Functional Programming Checks

- [ ] Lambda used only for simple, single-line expressions
- [ ] Lambda fits comfortably on one line (no wrapping)
- [ ] No duplicated lambdas — extract to named function if used 2+ times
- [ ] Lambda used appropriately: `sorted(key=lambda ...)`, not `map(lambda ...)` when list
      comprehension is clearer
- [ ] Late binding in loops captured explicitly (default args: `lambda x, f=factor:` or
      `functools.partial`)
- [ ] No complex logic in lambda — if it needs parentheses to parse visually, use `def`
- [ ] Prefer `list`/`dict`/`set` comprehensions over `map()`/`filter()` with lambdas
- [ ] No lambda in business logic — if debugging is needed, use named function
- [ ] Short callbacks (UI, event handlers) are reasonable uses of lambda
- [ ] `operator.itemgetter()` or `operator.attrgetter()` preferred over `lambda` for simple key
      extraction
- [ ] No docstrings expected in lambda — if you'd need to explain it with docs, use `def`
- [ ] No breakpoints expected in lambda — if it needs debugging, use `def`

### Memory Model & Object System Checks

- [ ] No mutable default arguments (e.g., `func(items: list = [])`)
- [ ] Mutable kwargs defaults checked for shared state issues
- [ ] Multiple assignment with mutable objects avoided unless intentional
- [ ] Deep copy used where needed (not just shallow copy)
- [ ] No mutation during iteration (use list comprehension or iterate over copy)
- [ ] `is` used for identity checks (`None`, singletons), `==` for value comparison
- [ ] `__slots__` considered for memory-heavy classes with fixed attributes
- [ ] Generators used for large datasets (not loading all into memory)
- [ ] `array` or `bytes` considered for dense numeric data
- [ ] Closure variables captured correctly (default args for lambdas to capture by value)

### Object Reference & Passing Checks

- [ ] Immutable arguments assumed safe from external changes
- [ ] Mutable arguments understood to be passed by reference
- [ ] Function return values clarified if returning same object or new
- [ ] Call sites checked for unintended aliasing with mutable objects
- [ ] Shallow copy implications understood for nested structures

### Data Structure Performance Checks

- [ ] Not using `list` for frequent front/middle inserts/deletes — use `deque` instead
- [ ] Not using `list` for frequent membership tests on large collections — consider `set`
- [ ] Not using repeated linear search (`x in list`) — use `dict` or `set` for O(1) lookup
- [ ] Using `dict` keys instead of list for deduplication where applicable
- [ ] Not mutating dict keys after insertion (keys are immutable/hashable)
- [ ] Efficient data structure choice for the access pattern (index, lookup, uniqueness)

### Generator & Iterator Checks

- [ ] Large file processing uses generators (not loading entire file into memory)
- [ ] Infinite sequences or pipelines use generators for lazy evaluation
- [ ] Generator expressions preferred over list comprehensions for one-time iteration
- [ ] Generator functions primer called before send() (use `next(gen)` to prime)
- [ ] No reusing exhausted generators without reinitializing
- [ ] Cleanup logic in generators wrapped in try/except for GeneratorExit
- [ ] Bidirectional communication (send/throw) only used in advanced coroutines
- [ ] Database queries paginated with generators to avoid OOM on large result sets

### Design Pattern Application Checks

> See the full checklist in [design-patterns.instructions.md](../instructions/design-patterns.instructions.md).

- [ ] Pain diagnosed before pattern chosen: friction identified (creation / boundary / behavior)?
- [ ] Pattern solves a real TODAY problem, not a hypothetical future one?
- [ ] Patterns used judiciously: not over-engineering simple features
