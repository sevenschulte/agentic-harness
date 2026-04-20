# SQL — Coding Standards

> Illustrative example. Replace with your team's actual SQL conventions.
> Loaded on demand when the agent is writing migrations, queries, or schema.

## Formatting

- Keywords UPPERCASE, identifiers `snake_case`
- One clause per line for anything beyond a trivial query:
  ```sql
  SELECT u.id, u.email, p.name
  FROM users u
  JOIN profiles p ON p.user_id = u.id
  WHERE u.org_id = $1
    AND u.deleted_at IS NULL
  ORDER BY u.created_at DESC
  LIMIT 50;
  ```
- Trailing comma style for column lists when the list is likely to grow

## Naming

- Tables: plural (`users`, `orders`, `payment_events`)
- Columns: singular, snake_case (`user_id`, `created_at`)
- Foreign keys: `<referenced_table_singular>_id` (`user_id`, not `users_id`
  or `userid`)
- Booleans read like a question: `is_active`, `has_paid`, not `active` /
  `paid` (which can mean either the state or an event)
- Timestamps end in `_at` (`created_at`, `deleted_at`); dates end in
  `_on` (`birthday_on`)

## Schema

- Every table has `id` (UUID or bigint, pick one and stick with it),
  `created_at`, `updated_at` defaulted to `now()`
- Soft delete via `deleted_at TIMESTAMPTZ NULL`; queries always filter
  `WHERE deleted_at IS NULL`
- Multi-tenant tables have `org_id` (or your tenant column). Every query
  filters by it. Add a CHECK or RLS policy where the platform supports it
- Indexes on every foreign key and every column used in a `WHERE` or `ORDER BY`
  in a hot path. Don't index speculatively

## Queries

- Always parameterise. No string concatenation into SQL, ever — this is a rule,
  not a style preference, and lives in `.claude/rules/conventions.md` too
- `SELECT *` only in ad-hoc exploration. Production code lists columns
- `LIMIT` on anything that could return more than a handful of rows
- `EXPLAIN ANALYZE` anything that runs in a hot path before merging

## Migrations

- Forward-only by default. If you need a rollback, write it explicitly
- One logical change per migration. Don't batch unrelated changes
- Long-running migrations (touching > ~1M rows, or holding a lock) need a
  separate plan — don't run them in the standard migration job
- Never edit a migration that's been applied to any environment beyond your
  local. Add a new migration instead
