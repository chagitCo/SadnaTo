# Testing standard (TEST)

Scope: all automated tests. Sources: MISSION (Testing), process.md §3.2 and §7.

## Rules

- **TEST-01** Every change ships with tests at the lowest level that can prove it: unit for domain logic, pgTAP for routines, integration for wiring, contract for cross-service shapes, end-to-end for critical user flows only.
- **TEST-02** Every acceptance criterion maps to at least one automated test, and the PR description lists the mapping.
- **TEST-03** Tests cover failure paths, not just success: validation errors, authorization denials, not-found, conflicts, concurrency (412/428) and tenant isolation.
- **TEST-04** Integration tests use a real PostgreSQL 18 via Testcontainers with migrations applied by Flyway; the database is not mocked at that level.
- **TEST-05** Each .NET service has architecture tests (NetArchTest or ArchUnitNET) for layer dependencies, the absence of EF Core and the presence of an authorization policy on every endpoint.
- **TEST-06** Producers and consumers of an event or API between services have consumer-driven contract tests (PactNet), run in both pipelines.
- **TEST-07** Line coverage of Domain and Application projects stays at or above 80%; coverage is a floor, and assertions must check behavior, not only execute code.
- **TEST-08** Frontend component tests query by role, label or text (Testing Library), not by CSS selectors or test IDs unless no accessible query exists.
- **TEST-09** Playwright flows include an axe-core scan; serious or critical violations fail the test.
- **TEST-10** Tests are deterministic: time through a fake `TimeProvider`, no fixed sleeps (wait for conditions), unique data per test, and no dependence on execution order.
- **TEST-11** A flaky test is quarantined with a linked issue and an owner within one working day; quarantine never lasts beyond two weeks without a fix or an explicit decision.
- **TEST-12** Test names state the scenario and the expected outcome: `AssignTask_WhenAssigneeIsViewer_ReturnsInvalidAssignee`.
- **TEST-13** Test data is synthetic and created by builders or fixtures in the test; shared mutable fixtures across tests are not used.

## Test levels and locations (reference)

| Level | Tool | Location |
|---|---|---|
| Unit | xUnit | `src/backend/services/<svc>/tests/<Svc>.Domain.Tests`, `.Application.Tests` |
| Architecture | NetArchTest | `.../tests/<Svc>.Architecture.Tests` |
| Database | pgTAP | `db/<svc>/tests/*.test.sql` |
| Integration | xUnit + Testcontainers + WebApplicationFactory | `.../tests/<Svc>.Integration.Tests` |
| Contract | PactNet | `.../tests/<Svc>.Contract.Tests` |
| Frontend unit/component | Vitest + Testing Library | `src/frontend/src/**/*.test.tsx` |
| E2E + a11y | Playwright + axe-core | `src/frontend/tests/e2e` |

Template: [templates/test-plan.md](../../templates/test-plan.md). Reviewer: `test-reviewer`.
