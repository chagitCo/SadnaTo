---
status: Accepted
date: 2026-10-21 (accepted 2026-10-25)
deciders: Human approver (repo owner)
consulted: Principal Architect, Senior C#/.NET Engineer, Application Security Engineer
informed: All service teams
---

# 0002 — Data access only through PostgreSQL functions and procedures (no EF Core)

## Context and Problem Statement

MISSION locks "NO Entity Framework Core. PostgreSQL functions and procedures are the only
data-access surface; Npgsql + Dapper in the Infrastructure layer". This ADR records the rationale
and the concrete rules that make the decision enforceable and secure.

## Decision Drivers

- Least privilege: the application role must not be able to run arbitrary SQL against tables.
- A single, reviewable, testable (pgTAP) data contract per service.
- Tenant isolation enforced close to the data (ADR-0006).
- Predictable performance and explicit queries (keyset pagination, concurrency checks).

## Considered Options

1. EF Core with migrations.
2. Dapper with inline SQL against tables.
3. **Dapper/Npgsql calling only functions/procedures in an `api` schema.**

## Decision Outcome

Chosen option: **3** (locked by MISSION), with these rules:

1. **Schemas per service database:** `core` (tables, owned by `<svc>_owner`), `api` (functions/procedures, the only callable surface), `outbox` (ADR-0012), `audit` (optional).
2. **Roles:** `<svc>_owner` runs migrations (Flyway) and owns everything. `<svc>_app` is the runtime role with `CONNECT`, `USAGE ON SCHEMA api` and `EXECUTE` on `api` functions **only**. It has **no** table privileges. `PUBLIC` loses `EXECUTE` by default (`ALTER DEFAULT PRIVILEGES … REVOKE EXECUTE … FROM PUBLIC`).
3. **Function security:** `api` functions are `SECURITY DEFINER`, owned by `<svc>_owner`, with a pinned `SET search_path = pg_catalog, core, pg_temp`. Tables use `FORCE ROW LEVEL SECURITY`, so RLS still applies to the owner (ADR-0006).
4. **Signatures:** the first parameter of every tenant-scoped function is `p_tenant_id uuid`, and the second is `p_actor_id uuid` for audit fields. Inputs are typed, never dynamic SQL built from strings. Where dynamic SQL is unavoidable, use `format()` with `%I`/`%L` only.
5. **Reads** are `STABLE` functions returning `SETOF` a composite or `TABLE(...)`. **Writes** are functions returning the affected row (they need a result: new `row_version`). Procedures are used only for multi-statement batch work that needs transaction control.
6. **Errors:** functions raise SQLSTATE codes from a documented catalog (`P0001` with `MESSAGE`/`DETAIL`/`HINT`, or custom `PXXXX` classes: not-found, conflict, forbidden, validation). The Infrastructure layer maps them to domain errors, and the API maps those to RFC 9457 Problem Details.
7. **.NET side:** one repository class per aggregate in `Infrastructure`, calling `CommandType.Text` with `select * from api.fn(@p…)` via Dapper. Parameters are always bound. `NpgsqlDataSource` is a singleton. The connection string comes from Secrets Manager / IAM auth (decided in Phase 3).
8. Migrations: `V__` for `core` objects, `R__` for `api` functions (ADR-0003).

### Consequences

- Good, because a compromised app role cannot read or alter tables directly.
- Good, because each function is unit-tested with pgTAP and the API surface is diffable.
- Bad, because there is more SQL to write and review, and no LINQ. Mitigation: a `db-function` skill and SQL templates.
- Bad, because `SECURITY DEFINER` is dangerous without a pinned `search_path`. Mitigation: CI lint (`tools/dlc-check sql`) rejects any `SECURITY DEFINER` without `SET search_path`.

### Confirmation

- NetArchTest: no reference to `Microsoft.EntityFrameworkCore*` in any project. Only `Infrastructure` references `Npgsql`/`Dapper`.
- CI grep/lint: no `FROM core.` / `INSERT INTO core.` SQL strings in C#.
- pgTAP: `<svc>_app` has no table privileges (`table_privs_are`), and every `api` function is `SECURITY DEFINER` with a configured `search_path`.

## Pros and Cons of the Options

### EF Core

- Good, because it is productive and familiar.
- Bad, because it is excluded by MISSION and needs table-level grants.

### Dapper with inline table SQL

- Good, because it is simple.
- Bad, because the app role needs table DML privileges and tenancy checks scatter across C#.
