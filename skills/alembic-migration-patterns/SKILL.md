---
name: alembic-migration-patterns
description: Manage schema migrations across multiple services with isolated Alembic histories, additive changes, batch operations, index strategies, and idempotent data migrations. Use when creating or reviewing migrations in alembic/ or services/*/alembic/ directories.
---

# alembic-migration-patterns

Manage schema migrations across multiple services with isolated Alembic histories.

When to invoke: creating or reviewing migrations in `alembic/` (ingestor) or `services/*/alembic/` (per-service).

## Per-service migration isolation

Each service owns its own schema and migration history. Do not mix migrations across services:

- Ingestor: `alembic/` at repo root, configured by `alembic.ini`
- Inference: `services/inference/alembic/`, configured by `services/inference/alembic.ini`
- Future services: `<service>/alembic/` with their own `alembic.ini`

Each `alembic.ini` sets:
```
script_location = %(here)s/alembic
file_template = %%(rev)s_%%(slug)s
prepend_sys_path = .
path_separator = os
```

## Migration file conventions

```python
"""<slug> message.

Revision ID: <rev>
Revises: <parent_rev>
Create Date: <timestamp>
"""
from alembic import op
import sqlalchemy as sa

revision = "<rev>"
down_revision = "<parent_rev>"
branch_labels = None
depends_on = None

def upgrade():
    op.create_table(...)

def downgrade():
    op.drop_table(...)
```

Naming: `<revision_id>_<slug>.py` where `slug` is a short kebab-case description.

## Safe migration patterns

### Additive changes first

```python
def upgrade():
    op.add_column("users", sa.Column("display_name", sa.String(255), nullable=True))

def downgrade():
    op.drop_column("users", "display_name")
```

Add columns as nullable first. Backfill data in a separate data migration. Add `NOT NULL` constraint in a follow-up revision after backfill is verified.

### Rename with batch operations

```python
def upgrade():
    with op.batch_alter_table("users") as batch_op:
        batch_op.alter_column("old_name", new_column_name="new_name")
```

Use `batch_alter_table` for SQLite compatibility and online DDL on large tables.

### Indexes and constraints

```python
def upgrade():
    op.create_index("ix_users_email", "users", ["email"], unique=True)
    op.create_check_constraint("ck_users_age", "users", "age >= 0")
```

Name indexes and constraints explicitly. Avoid relying on auto-generated names.

### Data migrations

For non-trivial data changes, embed SQL in the migration:

```python
def upgrade():
    conn = op.get_bind()
    conn.execute(sa.text("UPDATE users SET status = 'active' WHERE status IS NULL"))
```

Keep data migrations idempotent and fast. For large tables, batch updates to avoid long locks.

## Multi-service ordering

- Ingestor migrations run first in CI because other services depend on its schema.
- Inference migrations run independently against their own database.
- Never add cross-service foreign keys across database boundaries.

## Testing migrations

```bash
# Upgrade to head
alembic upgrade head

# Downgrade one step
alembic downgrade -1

# Generate a new migration
alembic revision --autogenerate -m "add users table"
```

Run migrations up and down in CI for each service before deploying.

## References

- `alembic.ini` — ingestor Alembic config
- `services/inference/alembic.ini` — inference Alembic config
- `alembic/versions/` — ingestor migration history
- `services/inference/alembic/versions/` — inference migration history
