# db — PostgreSQL databases (one per service)

Loaded on demand when Claude works under `db/`. Rules live in the standards; this file gives local
context, layout and commands only.

## Must read before changing anything here

- [database-postgres](../docs/standards/database-postgres.md) — DB rules (schemas, roles, functions, RLS, migrations)
- [security](../docs/standards/security.md) — tenancy and data-classification items
- [testing](../docs/standards/testing.md) — pgTAP expectations
- [checklists/db-change.md](../checklists/db-change.md) — run it before opening the PR

Most-cited IDs during review: DB-03 (security definer + search_path), DB-04 (tenant parameter),
DB-05 (RLS), DB-08/09 (migration naming and expand/contract), DB-14 (pgTAP coverage).
Use the `new-db-function` skill and ask `db-reviewer` to review.

## Layout

```
db/<svc>/
  flyway.toml                         Flyway config without secrets (URL/user come from env)
  migrations/V<yyyyMMddHHmm>__<desc>.sql   versioned: roles, schemas, tables, indexes, policies
  migrations/R__<schema>.<object>.sql      repeatable: one function or procedure per file
  tests/<area>.test.sql               pgTAP tests (privileges, tenancy, business rules)
  seed/dev.sql                        synthetic data for local/dev only (never production data)
```

Each service owns exactly one database; nothing in `db/a/` may reference objects of `db/b/`.

## Commands (Docker required; run from repo root)

| Purpose | Command |
|---|---|
| Start a local PostgreSQL 18 | `docker run --rm -d --name pg-<svc> -e POSTGRES_PASSWORD=local-only -p 5432:5432 postgres:18` |
| Migrate | `docker run --rm --network host -v "$PWD/db/<svc>:/flyway/project" flyway/flyway -workingDirectory=/flyway/project migrate` |
| Validate migrations | same image, command `validate` then `info` |
| Run pgTAP | `pg_prove -h localhost -U postgres -d <svc> db/<svc>/tests/*.test.sql` (pgTAP image pinned in Phase 3) |

`psql`/`pg_prove` may only target local hosts; the guard hook blocks other hosts. Image versions
are pinned by digest in Phase 3. No database exists yet (Phase 3 creates `db/projects`).
