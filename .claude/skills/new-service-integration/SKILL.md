---
name: new-service-integration
description: Add a synchronous call from one service to another over ECS Service Connect — typed client, timeouts, retry policy for idempotent calls, circuit breaker, client-credentials authentication, scopes on the callee, and a contract test.
when_to_use: A use case needs an immediate answer from data another service owns (ARCH-04), after confirming an event-driven design does not fit.
argument-hint: "[caller] -> [callee] [operation]"
---

# New service-to-service integration (sync)

## When to use

- The caller cannot proceed without the callee's answer now.
- First check whether a local projection fed by events would do (architecture.md communication guide). Record why sync is needed in the plan.

## Required inputs (ask if missing)

| Input | Example |
|---|---|
| Caller, callee, operation | `notifications` → `projects` `GET .../members/{userId}` |
| Why sync is required | Explicit justification |
| Idempotency of the operation | GET = idempotent → retries allowed |
| Latency budget | caller p95 budget 300 ms → callee timeout 2 s, total 10 s (ADR-0012 defaults) |
| Required scope | `projects/members.read` |
| Fallback when the callee is down | Fail with 503 Problem Details / degrade |

## Steps

1. Read ADR-0012, ADR-0014 and the callee's OpenAPI (CORE-01).
2. **Callee**: ensure the operation exists in its contract (API-01) and requires the scope (SEC-05, API-12); add a Cognito resource-server scope in the callee's Terraform (no apply).
3. **Caller client**: typed `HttpClient` in Infrastructure via `IHttpClientFactory` with the resilience pipeline (BE-09), the platform client-credentials handler, the Service Connect base URL from configuration, and trace propagation (OBS-02).
4. **Port**: Application interface owned by the caller; map callee Problem Details to caller errors; define the fallback behavior.
5. **Infrastructure**: caller app client (client credentials) and its secret readable only by the caller's task role (SEC-14); security group rule caller → callee.
6. **Tests**: caller unit tests for fallback/timeout handling, integration test against a stub server for retry/circuit behavior, consumer-driven contract test with the callee verifying it (TEST-06), callee test for 401/403 without scope.
7. Add metrics/alarms for the dependency (OBS-05) and a runbook section "callee unavailable".
8. Run reviewers; update the catalog (sync API relationship).

## Artifacts produced

Client + port, configuration, Terraform for scope/client/SG, tests, contract file, runbook section,
catalog update.

## Checks to run

Both services' builds and tests, contract verification in the callee, `terraform validate`,
`scripts/validate-dlc`.

## Definition of done

Timeouts and circuit breaker are configured and tested, retries apply only to idempotent calls,
calls are authenticated and scope-checked, a contract test protects the shape, and failure of the
callee has a defined, tested behavior.
