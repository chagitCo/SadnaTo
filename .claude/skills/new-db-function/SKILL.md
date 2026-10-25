---
name: new-db-function
description: Add a table, function or procedure to a service database via Flyway (V__ for schema, R__ for routines), with grants, RLS, pgTAP tests and the Dapper adapter in the Infrastructure layer.
when_to_use: A use case needs new or changed persistence, or the human asks for a migration, table, index, function or procedure.
argument-hint: "[service] [object name]"
---

# New database object

## When to use

- New table/column/index (versioned migration) or new/changed `api` routine (repeatable migration).
- Destructive changes (drop, rename, type change) follow the expand/contract plan in DB-09 and need the human's confirmation of the release sequence.

## Required inputs (ask if missing)

| Input | Notes |
|---|---|
| Service | Must own the data (ARCH-02) |
| Purpose of the routine and its callers | Use case name |
| Parameters and result shape | Tenant and actor first (DB-04) |
| Error cases | Codes from `db/<svc>/ERRORS.md` (DB-11) |
| Data classification of new columns | SEC-11, reference to data-classification.md |
| Expected volume / access pattern | Index design, keyset key (DB-13) |

## Steps

1. Read [database-postgres](../../../docs/standards/database-postgres.md) and existing migrations in `db/<svc>/migrations` (CORE-01).
2. **Schema change** → new `V<yyyyMMddHHmm>__<desc>.sql` from [templates/migration.sql](../../../templates/migration.sql) (DB-08): columns with audit fields (DB-07), tenant column and composite keys (DB-06), RLS enable+force+policy (DB-05), indexes per DB-10.
3. **Routine** → `R__api.<name>.sql` from [templates/db-function.sql](../../../templates/db-function.sql): definer + pinned search_path (DB-03), tenant setting (DB-05), errors (DB-11), grants to `<svc>_app` only (DB-02).
4. **pgTAP** in `db/<svc>/tests/<area>.test.sql`: happy path, each error code, tenant isolation, privileges (DB-14).
5. **Adapter** in `src/backend/services/<svc>/src/<Svc>.Infrastructure`: Dapper call with bound parameters (BE-03), SQLSTATE → domain error mapping, integration test through Testcontainers (TEST-04).
6. Run [checklists/db-change.md](../../../checklists/db-change.md) and ask `db-reviewer` for a review.

## Artifacts produced

Migration files, pgTAP tests, updated `ERRORS.md` if new codes, Infrastructure adapter and tests.

## Checks to run (Docker required; commands in `db/CLAUDE.md`)

- `flyway migrate` then `flyway validate` against a local PostgreSQL 18 container.
- `pg_prove` for the service's tests.
- Integration tests for the adapter; `scripts/validate-dlc`.

## Definition of done

Migrations apply cleanly on an empty database and on the previous release's schema; all pgTAP tests
pass; `<svc>_app` still has no table privileges; `db-reviewer` reports no Critical/High finding.
