# Service template

Used by the `new-service` skill. Three parts:

1. [questionnaire.md](questionnaire.md) — answers collected from the human before anything is generated.
2. [service-definition.md](service-definition.md) — the filled-in definition stored at `docs/services/<svc>/service-definition.md`.
3. The **skeleton** below, generated into three folders (ADR-0016).

## Skeleton (what a generated service contains)

| Path | Contents |
|---|---|
| `src/backend/services/<svc>/<Svc>.sln`, `Directory.Packages.props`, `global.json` link | Solution, central package versions |
| `src/backend/services/<svc>/src/<Svc>.Domain` | Empty domain project, no framework references |
| `src/backend/services/<svc>/src/<Svc>.Application` | Use-case base types, ports folder |
| `src/backend/services/<svc>/src/<Svc>.Infrastructure` | `NpgsqlDataSource` registration, Dapper base adapter, SQLSTATE mapping, outbox/consumer hosts (from platform packages) |
| `src/backend/services/<svc>/src/<Svc>.Api` | `Program.cs` with platform logging/telemetry/auth/Problem Details, health endpoints, API versioning, OpenAPI |
| `src/backend/services/<svc>/tests/*` | Domain, Application, Architecture (layering, no EF Core, endpoint policies), Integration (Testcontainers + Flyway), Contract projects |
| `src/backend/services/<svc>/contracts/openapi/v1.yaml` | Contract with health endpoints only |
| `src/backend/services/<svc>/Dockerfile` | Multi-stage, non-root, chiseled runtime |
| `src/backend/services/<svc>/CLAUDE.md`, `docs/runbook.md`, `docs/slo.md`, `CHANGELOG.md`, `.dlc/version` | Service context, operations docs, DLC version stamp |
| `db/<svc>/flyway.toml`, `migrations/V<ts>__init_roles_and_schemas.sql`, `ERRORS.md`, `tests/privileges.test.sql` | Roles, schemas, default privileges, error catalog, privilege tests |
| `infra/services/<svc>/main.tf`, `envs/{dev,staging,prod}/` | ECS service, target group + listener rule, API routes, DB role/secret, alarms, dashboard |
| `.github/workflows/svc-<svc>.yml` + CODEOWNERS lines | Pipeline calling reusable workflows with path filters |

## Status

The `dotnet new` template pack (`templates/service/dotnet/`, package `Workshop.Templates`) is
**deferred to Phase 3**: it must be compiled and tested with the .NET SDK, which is not yet
installed on the development machine (CORE-05, CORE-09). Until then, `new-service` creates the
skeleton from this list and the standards. Recorded in `docs/ai-dlc/plan.md`.
