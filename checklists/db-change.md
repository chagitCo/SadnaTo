# Database change checklist

Reference: [database standard](../docs/standards/database-postgres.md).

## Migrations
- [ ] File names follow DB-08; one routine per `R__` file with `CREATE OR REPLACE`
- [ ] Backward compatible with the running app version (DB-09); release sequence written in the migration header
- [ ] `lock_timeout` / `statement_timeout` set; populated-table indexes `CONCURRENTLY` in their own file (DB-10)
- [ ] Applies cleanly on an empty database **and** on the previous release's schema (`flyway migrate`, `flyway validate`)

## Schema
- [ ] Objects in `core`/`api`/`outbox`/`inbox`, owned by `<svc>_owner`, nothing in `public` (DB-01)
- [ ] Tenant column, composite keys, tenant-first indexes (DB-06); RLS enabled + forced with policy (DB-05)
- [ ] Audit columns, row version, soft-delete columns where needed (DB-07); UUIDv7 keys (DB-15)

## Routines
- [ ] `SECURITY DEFINER` + pinned `search_path` (DB-03); tenant/actor parameters first (DB-04)
- [ ] Grants: `EXECUTE` to `<svc>_app` only, revoked from `PUBLIC` (DB-02)
- [ ] Errors use catalog codes, no sensitive data in messages (DB-11); `ERRORS.md` updated
- [ ] No dynamic SQL, or `format()` with `%I`/`%L` only (DB-12); keyset pagination (DB-13)
- [ ] Integrity only, no workflow decisions (ARCH-07)

## Tests and data
- [ ] pgTAP: happy path, every error code, tenant isolation, privileges (DB-14) — `pg_prove` output attached
- [ ] Infrastructure adapter integration test passes against Testcontainers (TEST-04)
- [ ] Seed data synthetic, dev/local only (DB-17)
- [ ] `db-reviewer` run, no Critical/High open (CR-03)
