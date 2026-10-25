# Database standard — PostgreSQL 18 (DB)

Scope: everything under `db/`. Sources: ADR-0002 (functions only), 0003 (Flyway), 0006 (tenancy),
0013 (database per service), 0016 (paths).

## Rules

- **DB-01** Each service database has the schemas `core` (tables), `api` (callable functions and procedures), `outbox`/`inbox` (messaging, when used); objects belong to `<svc>_owner`, and `public` receives no objects.
- **DB-02** The runtime role `<svc>_app` has `CONNECT`, `USAGE` on schema `api` and `EXECUTE` on `api` routines only; it holds no table privileges, and `EXECUTE` is revoked from `PUBLIC` by default privileges.
- **DB-03** Every `api` routine is `SECURITY DEFINER` with `SET search_path = pg_catalog, core, pg_temp`; a definer routine without a pinned `search_path` is rejected.
- **DB-04** Tenant-scoped routines take `p_tenant_id uuid` as the first parameter and `p_actor_id uuid` as the second, and filter every statement by tenant.
- **DB-05** Every tenant table has `ENABLE` and `FORCE ROW LEVEL SECURITY` with a policy on `current_setting('app.tenant_id', true)::uuid`, and each routine sets `app.tenant_id` transaction-locally before touching data.
- **DB-06** Tenant tables carry `tenant_id uuid NOT NULL`, use composite foreign keys `(tenant_id, id)` and start every index with `tenant_id`.
- **DB-07** Tables carry `created_at`, `created_by`, `updated_at`, `updated_by` (`timestamptz`, UTC); updatable rows carry `row_version bigint` incremented by every update routine; soft-deletable rows carry `deleted_at` and `deleted_by`.
- **DB-08** Versioned migrations are named `V<yyyyMMddHHmm>__<snake_description>.sql`; repeatable routines are `R__<schema>.<object>.sql`, one object per file, written with `CREATE OR REPLACE`.
- **DB-09** Migrations are expand/contract: a migration must work with the currently deployed application version, and destructive steps (drop, rename, type narrowing) ship in a later release after the code stops using the object.
- **DB-10** Indexes on populated tables are created `CONCURRENTLY` in their own migration, and migrations set `lock_timeout` and `statement_timeout`.
- **DB-11** Routines raise errors with documented SQLSTATE codes and messages from the service's error catalog (`db/<svc>/ERRORS.md`): not-found, conflict, precondition-failed, forbidden, validation.
- **DB-12** Dynamic SQL is avoided; where unavoidable it is built with `format()` using `%I` and `%L`, never by string concatenation of inputs.
- **DB-13** List routines implement keyset pagination on an indexed, unique sort key (for example `(created_at, id)`), never `OFFSET`.
- **DB-14** Every `api` routine has pgTAP tests for its happy path, each error code it raises, tenant isolation and the privileges of `<svc>_app`.
- **DB-15** Primary keys default to `uuidv7()` (PostgreSQL 18) unless the application supplies a UUIDv7.
- **DB-16** Flyway runs as `<svc>_owner` from CI or a one-off task with `cleanDisabled=true`; the application never migrates at startup.
- **DB-17** Seed files contain synthetic data only and are applied to local and dev environments only.

## Routine skeleton (reference)

```sql
CREATE OR REPLACE FUNCTION api.task_get(p_tenant_id uuid, p_actor_id uuid, p_task_id uuid)
RETURNS SETOF core.task
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = pg_catalog, core, pg_temp
AS $$
BEGIN
  PERFORM set_config('app.tenant_id', p_tenant_id::text, true);
  RETURN QUERY
    SELECT t.* FROM core.task t
    WHERE t.tenant_id = p_tenant_id AND t.id = p_task_id AND t.deleted_at IS NULL;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'task-not-found';
  END IF;
END $$;
```

Templates: [db-function.sql](../../templates/db-function.sql), [migration.sql](../../templates/migration.sql).
Checklist: [db-change](../../checklists/db-change.md).
