---
status: Accepted
date: 2026-10-21 (accepted 2026-10-25)
deciders: Human approver (repo owner)
consulted: Principal Architect, Senior C#/.NET Engineer, Senior React/TypeScript Engineer
informed: All service teams
---

# 0015 — Shared platform packages: scope, versioning, publishing

## Context and Problem Statement

Microservices rule 6: no shared domain code. Shared code is limited to small, versioned platform
packages published to GitHub Packages. What is allowed, and how are the packages built and versioned?

## Decision Drivers

- Consistency of cross-cutting concerns (logging, telemetry, auth, errors).
- No hidden coupling of domain models.
- Independent upgrade cadence per service (Dependabot).

## Decision Outcome

**Allowed packages (initial set)**

| Package | Contents | Not allowed |
|---|---|---|
| `Workshop.Platform.Logging` | Serilog JSON config, enrichers (trace/span id, tenant, service), redaction of sensitive fields | Business log messages |
| `Workshop.Platform.Telemetry` | OpenTelemetry setup (traces, metrics, logs), OTLP → ADOT collector / CloudWatch / X-Ray, W3C propagation | Domain metrics names |
| `Workshop.Platform.Auth` | JWT validation defaults, scope policies, client-credentials token handler | Role/permission rules of any domain |
| `Workshop.Platform.ProblemDetails` | RFC 9457 mapping, exception → problem middleware, validation problem shape, error-type URI scheme | Domain error catalogs |
| `Workshop.Platform.Messaging` (confirmed, Q10) | CloudEvents envelope, SNS publisher, outbox dispatcher host, SQS consumer host with idempotency hooks, trace propagation | Event payload types (they belong to the producer's contracts) |
| `@workshop/web-platform` (npm) | i18n/RTL setup, HTTP client to the BFF with CSRF header, error boundary, a11y test helpers | Feature components |

**Rules**

1. A package must not reference any `services/*` code. No domain types, no DTOs of a service.
2. Event and API **contracts are not shared packages.** Consumers keep their own copies of message types and verify them with contract tests (ADR-0012).
3. SemVer. Tags `platform/<package>/vX.Y.Z`. Each package has a `CHANGELOG.md`. Breaking changes need a major version and migration notes.
4. Services consume **by version from GitHub Packages**, never through `ProjectReference` (ADR-0010). Central Package Management (`Directory.Packages.props`) lives per service.
5. Each package has unit tests, public API approval tests (`PublicApiGenerator`) and NuGet package validation (`EnablePackageValidation`). Packages are signed or have provenance attested.
6. **Adding a package needs an ADR.** The bar: needed by at least 2 services, technical not domain, small surface.

### Consequences

- Good, because there is consistent telemetry, logging and error shape, and one place to fix security defaults.
- Bad, because publishing adds release overhead. Mitigation: release-please automation.

### Confirmation

- `dlc-check boundaries`: platform projects do not reference `services/**`, and services do not `ProjectReference` platform.
- NetArchTest in each package: no dependency on Npgsql/Dapper/ASP.NET MVC controllers outside of the allowed packages.
