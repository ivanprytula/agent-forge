# PostgreSQL Optimization

Use for PostgreSQL performance tuning, query optimization, index strategies, and advanced
SQL patterns. Covers PostgreSQL 17+ features, async SQLAlchemy 2.0 patterns, and production
monitoring.

## When to Activate

- Optimizing slow queries (`EXPLAIN ANALYZE` shows seq scans or high latency)
- Designing indexes (composite, partial, covering, expression)
- Tuning connection pools or memory settings
- Implementing cursor-based pagination or advanced aggregations
- Using JSONB, arrays, window functions, full-text search, or custom types
- Setting up query performance monitoring or maintenance routines

## Core Workflow

1. **Profile first**: run `EXPLAIN (ANALYZE, BUFFERS)` on the target query
2. **Identify bottleneck**: seq scan, missing index, bad join order, or memory pressure
3. **Apply minimal fix**: index first, then query rewrite, then schema change
4. **Verify**: re-run `EXPLAIN ANALYZE`, confirm latency drop and index usage
5. **Monitor**: track via `pg_stat_statements`, `pg_stat_user_indexes`, connection pool metrics

## Async SQLAlchemy Patterns

```python
# Connection pool tuning (app/database.py)
engine = create_async_engine(
    DATABASE_URL,
    pool_size=20,
    max_overflow=10,
    pool_pre_ping=True,
    connect_args={'timeout': 10}
)

# Keyset pagination (avoid OFFSET on large offsets)
async def get_records_keyset(db: AsyncSession, pipeline_id: int, cursor: int = 0, limit: int = 10):
    stmt = select(Record).where(
        (Record.pipeline_id == pipeline_id) &
        (Record.id > cursor)
    ).order_by(Record.id.desc()).limit(limit)
    result = await db.execute(stmt)
    records = result.scalars().all()
    return {'records': records, 'cursor': records[-1].id if records else cursor}
```

## Reference Files

Load on demand for detailed patterns:

| File | Use When |
|------|----------|
| [advanced-sql.md](./references/advanced-sql.md) | JSONB, arrays, window functions, full-text search, custom/range/geometric types |
| [performance.md](./references/performance.md) | EXPLAIN ANALYZE, index strategies, connection management, monitoring, query patterns |
