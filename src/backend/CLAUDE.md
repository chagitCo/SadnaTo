# src/backend — .NET services and platform packages

Loaded on demand when Claude works under `src/backend/`. Rules live in the standards; this file
gives local context, layout and commands only.

## Must read before changing code here

- [backend-csharp](../../docs/standards/backend-csharp.md) — BE rules
- [api-design](../../docs/standards/api-design.md) — API rules (endpoints, errors, paging, concurrency)
- [architecture](../../docs/standards/architecture.md) — ARCH rules (layering, boundaries)
- [security](../../docs/standards/security.md), [testing](../../docs/standards/testing.md), [observability](../../docs/standards/observability.md)

Most-cited IDs during review: ARCH-06/07 (layering, where rules live), BE-03 (data access path),
API-05/06 (Problem Details, concurrency), SEC-02/03 (tenant from principal), TEST-02 (AC → test).

## Layout

```
src/backend/
  Directory.Build.props            repo-wide build settings (added with the first service)
  services/<svc>/
    <Svc>.sln  Directory.Packages.props  Dockerfile  CLAUDE.md (service context)  .dlc/version
    src/<Svc>.Domain/              entities, value objects, invariants, domain events
    src/<Svc>.Application/         use cases, ports (interfaces), validation, authorization policies
    src/<Svc>.Infrastructure/      Npgsql + Dapper adapters for db/<svc> functions, SNS/SQS, secrets
    src/<Svc>.Api/                 ASP.NET Core host: endpoints, OpenAPI, Problem Details, health
    tests/<Svc>.{Domain,Application,Architecture,Integration,Contract}.Tests/
    contracts/openapi/v<N>.yaml    published API contract
    contracts/events/*.schema.json published event schemas (producers only)
    docs/runbook.md  docs/slo.md
  services/web-bff/                BFF host (YARP + OIDC), no Domain/DB layers (ADR-0005)
  platform/Workshop.Platform.*/    shared packages (ADR-0015), consumed by version, never by ProjectReference
```

The database for a service lives in `db/<svc>/`, its Terraform stack in `infra/services/<svc>/`.

## Commands (run from the service folder)

| Purpose | Command |
|---|---|
| Restore + build (warnings are errors) | `dotnet build -c Release` |
| Unit + architecture tests | `dotnet test --filter "Category!=Integration"` |
| Integration tests (Docker required) | `dotnet test --filter "Category=Integration"` |
| Format check | `dotnet format --verify-no-changes` |
| Export OpenAPI | `dotnet run --project src/<Svc>.Api -- --export-openapi contracts/openapi/v1.yaml` (wired in Phase 3) |
| Generate a new service | use the `new-service` skill |

Status: no service exists yet (Phase 3 creates `projects`). The .NET SDK is not yet installed on
the current dev machine — see the environment report.

## Typical flow here

1. Contract first: update `contracts/openapi/v<N>.yaml` or the event schema (`new-api-endpoint`, `new-event`).
2. Domain/Application change with unit tests.
3. Infrastructure adapter calling the `api.*` function defined in `db/<svc>/` (`new-db-function`).
4. Endpoint, then integration tests through the real database (Testcontainers).
5. Self-review with `architecture-reviewer`, `security-reviewer`, `test-reviewer`.
