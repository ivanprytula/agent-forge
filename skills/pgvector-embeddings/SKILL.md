# pgvector-embeddings

Use pgvector with SQLAlchemy 2.0 async for semantic search in FastAPI services.

When to invoke: implementing or modifying embedding storage, similarity search, or vector indexes in `services/inference/` or any pgvector-backed service.

## Model definition

```python
from pgvector.sqlalchemy import Vector
from sqlalchemy import Index
from sqlalchemy.orm import Mapped, mapped_column

class IndexedDocument(Base):
    __tablename__ = "indexed_documents"

    id: Mapped[int] = mapped_column(primary_key=True)
    collection: Mapped[str] = mapped_column(String(128), nullable=False)
    external_id: Mapped[int] = mapped_column(Integer, nullable=False)
    text: Mapped[str] = mapped_column(Text, nullable=False)
    metadata_json: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)
    embedding: Mapped[list[float]] = mapped_column(
        Vector(settings.embedding_dim), nullable=False
    )
```

Key points:

- Store embeddings in a `Vector(dim)` column; dimension must match the model output.
- Use `JSONB` for metadata filters; query with `.contains()`.
- Always define a unique constraint on `(collection, external_id)` for idempotent upserts.

## Upsert pattern

```python
from sqlalchemy.dialects.postgresql import insert as pg_insert

stmt = pg_insert(IndexedDocument).values([...])
stmt = stmt.on_conflict_do_update(
    index_elements=["collection", "external_id"],
    set_={"text": stmt.excluded.text, "embedding": stmt.excluded.embedding},
)
await db.execute(stmt)
await db.commit()
```

Use `on_conflict_do_update` with `index_elements` pointing to the unique constraint columns.

## Similarity search

```python
from sqlalchemy import select

distance = IndexedDocument.embedding.cosine_distance(query_vector).label("distance")
stmt = (
    select(IndexedDocument, distance)
    .where(IndexedDocument.collection == collection)
    .order_by(distance)
    .limit(top_k)
)
rows = (await db.execute(stmt)).all()
```

- Use `cosine_distance` for normalized embeddings.
- Convert to score with `1.0 - float(distance)`.
- Filter with `.where(IndexedDocument.metadata_json.contains(filters))` for metadata constraints.

## Indexes

```python
Index("ix_indexed_documents_collection", "collection")
```

Create btree indexes on frequently filtered columns. Vector indexes (HNSW/IVFFlat) are created via Alembic migrations:

```python
def upgrade():
    op.create_index(
        "ix_indexed_documents_embedding",
        "indexed_documents",
        [text("embedding vector_cosine_ops")],
        postgresql_using="hnsw",
        postgresql_with={"m": 16, "ef_construction": 64},
    )
```

## Embedding generation

- Run blocking embedding calls in a threadpool: `await run_in_threadpool(embed_texts, texts)`.
- Cache embeddings for unchanged documents at the application layer.
- Keep vectorstore schema stable: `id`, `text`, `metadata`, `embedding`.

## References

- `services/inference/search.py` — upsert and search implementation
- `services/inference/models.py` — ORM model with pgvector column
- `docs/02-architecture/adr/015-inference-dedicated-pgvector-postgres.md` — architecture decision record
