---
status: Proposed
date: 2026-10-21
deciders: Human approver (repo owner)
consulted: Principal Architect, Application Security Engineer
informed: All service teams
---

# 0006 — Multi-tenancy: shared schema, row-level `tenant_id`, enforced in functions and by RLS

## Context and Problem Statement

The reference domain has organizations (tenants). We must choose an isolation model and how it is
enforced, given that all data access goes through PostgreSQL functions (ADR-0002).

## Decision Drivers

- No cross-tenant data access, even with an application bug.
- Cost: many small tenants.
- Simplicity of migrations, since a schema-per-tenant design multiplies them.
- Testability (pgTAP).

## Considered Options

1. Database per tenant.
2. Schema per tenant.
3. **Shared tables with a `tenant_id` column, checked in every function.**
4. Option 3 **plus PostgreSQL Row-Level Security (RLS)** as a second enforcement layer.

## Decision Outcome

Chosen option: **4** (PENDING **Q4**).

1. Every tenant-owned table has `tenant_id uuid NOT NULL`. The primary key includes `tenant_id` or is unique per tenant, and every index starts with `tenant_id`. Foreign keys are composite (`tenant_id, id`), so cross-tenant references are impossible.
2. **The tenant is never taken from the request body or the URL alone.** The API resolves `tenant_id` from the authenticated principal: the active organization claim, validated against membership in the Projects service. Every `api` function takes `p_tenant_id` as its first parameter and filters on it.
3. **RLS:** each `api` function begins with `PERFORM set_config('app.tenant_id', p_tenant_id::text, true)` (transaction-local). Every tenant table has `ENABLE` + `FORCE ROW LEVEL SECURITY` and a policy `USING (tenant_id = current_setting('app.tenant_id', true)::uuid)`. Because functions are `SECURITY DEFINER` owned by the table owner, `FORCE` is required for RLS to apply.
4. If `app.tenant_id` is missing, `current_setting(..., true)` returns NULL, so the query returns no rows (fail closed).
5. Background work that is legitimately cross-tenant (for example, the outbox dispatcher) uses dedicated functions on a separate role with `BYPASSRLS`. Those functions are reviewed and pgTAP-tested.

### Consequences

- Good, because a missed filter in one function is still caught by RLS.
- Good, because there is one schema and one migration path.
- Bad, because there is a small per-statement RLS overhead. Mitigation: composite indexes starting with `tenant_id`.
- Bad, because there is a noisy-neighbour risk. Mitigation: per-tenant rate limits at the API, and moving a big tenant to its own database later if needed (a new ADR).

### Confirmation

- pgTAP: for every `api` function, calling it with tenant A's id never returns tenant B's rows. Every tenant table has `relrowsecurity` and `relforcerowsecurity` set to true.
- Integration test (Testcontainers): API calls with an org-A token cannot read or modify org-B resources and get 404 (not 403, to avoid leaking existence).
