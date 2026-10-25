---
name: new-api-endpoint
description: Add or change an HTTP endpoint contract-first — update the OpenAPI document, then the Application use case, then the minimal-API endpoint, then unit, integration and contract tests.
when_to_use: A story needs a new or changed REST operation in a service or the BFF.
argument-hint: "[service] [METHOD /path]"
---

# New API endpoint (contract first)

## When to use

- New operation, new field, or changed behavior on an existing operation.
- If the change is incompatible, plan a new major version (API-03) and ask the human first.

## Required inputs (ask if missing)

| Input | Example |
|---|---|
| Service and resource | `projects`, tasks |
| Method and path | `POST /api/projects/v1/orgs/{orgId}/projects/{projectId}/tasks` |
| Who may call it (roles/scopes) | Member, Owner; scope `projects/tasks.write` |
| Request/response fields with limits | title ≤ 200 chars |
| Business rules and error cases | BR-2 → 422 `assignee-required` |
| Concurrency/idempotency needs | `If-Match` required (API-06) |

## Steps

1. Read [api-design](../../../docs/standards/api-design.md) and the service's existing contract (CORE-01).
2. Fill [templates/api-endpoint.md](../../../templates/api-endpoint.md) in the plan folder.
3. **Contract**: edit `contracts/openapi/v<N>.yaml` — path, schemas with max lengths (API-11), security scopes and every Problem Details type (API-12), examples.
4. **Use case**: Application command/query with validation and authorization (SEC-04), returning typed results (BE-06); unit tests for each rule and failure path (TEST-03).
5. **Persistence**: if new data access is needed, run `new-db-function` first.
6. **Endpoint**: map in the feature's endpoint group (BE-11), translate results to status codes (API-08) and Problem Details (API-05), add ETag handling where applicable (API-06).
7. **Integration tests** through Testcontainers (TEST-04): success, 400, 401, 403/404 (SEC-03), 409/412/422 as applicable.
8. **Contract test** if another service consumes it (TEST-06); confirm the generated OpenAPI matches the committed file (API-01).
9. Run reviewers (`security-reviewer`, `architecture-reviewer`, `test-reviewer`).

## Artifacts produced

OpenAPI diff, use case + tests, endpoint, integration and contract tests, filled endpoint template.

## Checks to run

- Service build and all test levels; OpenAPI diff check; `scripts/validate-dlc`.
- [checklists/security.md](../../../checklists/security.md) sections "Authorization" and "Input".

## Definition of done

Contract merged together with implementation; every documented error type is produced by a test;
authorization and tenant isolation are tested; no incompatible change inside a major version.
