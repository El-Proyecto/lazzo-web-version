# Database & Supabase

**Repository:** lazzo-web-version.

*Quick reference: schema source of truth, Supabase rules (RLS, minimal select, storage), performance & optimization.*

## Schema documentation (source of truth)

The schema is documented only via two SQL files (auto-exported from Supabase, updated by P2 team). Both must be referenced; they serve different use cases:

- **`supabase_structure.sql`** — Use for: quick schema lookups, reading table and column definitions, and context when writing queries. Human-oriented structure (CREATE TABLE…); not meant to be executed. Ideal for agents and developers to inspect tables and fields.
- **`supabase_schema.sql`** — Use for: exact schema state, migrations, and runnable SQL. Full PostgreSQL dump (e.g. `pg_dump`); includes types, indexes, RLS, triggers. Single source of truth for applying or comparing schema changes.

## Supabase guidelines

- **RLS first**: queries must satisfy row-level policies. No admin keys in app.
- **Minimal select**: only fields required by the **entity**.
- **Indexes**: sort & filter by indexed columns; always `limit`.
- **Storage**: path convention `/eventId/userId/uuid.jpg` + metadata (uploader, type, ts).
- **RPC/Triggers**: live in DB; expose via repository method signatures.
- **Database reference**: Use `supabase_structure.sql` for quick lookups and table/column context; use `supabase_schema.sql` for full schema (types, indexes, triggers, RLS) and runnable dumps.

### Performance & optimization (always recommend when possible)

- **Query optimization**: Select only required columns; use indexed columns for filtering/sorting; always add `LIMIT`; leverage materialized views for complex aggregations; batch operations to reduce round trips.
- **Schema design**: Denormalize strategically with materialized views; use foreign keys with CASCADE; validate data with DB constraints; use UUIDs for primary keys.
- **Caching strategies**: Use materialized views for expensive queries; client-side caching with Riverpod; consider local database (SQLite/Isar) for offline-first features; stale-while-revalidate pattern for non-critical data.
- **Efficient indexing**: Composite indexes for common query patterns; partial indexes for filtered queries; monitor index usage and drop unused ones; B-tree indexes for equality/range queries.
- **Local database usage**: Cache frequently accessed data; optimistic updates (local first, sync async); conflict resolution with `updated_at` timestamps; selective sync for active events only.
- **Payload size minimization**: Paginate all lists with `limit + offset` or cursor-based; compress images before upload; JSON field pruning (only non-null fields); use storage CDN for images (never fetch full blobs via API).
