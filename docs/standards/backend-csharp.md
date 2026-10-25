# Backend standard — C# / .NET (BE)

Scope: all code under `src/backend/`. Sources: MISSION (Backend, Data access), ADR-0002, 0012, 0015.

## Rules

- **BE-01** Target the current .NET LTS (`net10.0`) with `Nullable` enabled, `TreatWarningsAsErrors` true and the .NET analyzers at `latest-recommended`, set once in `Directory.Build.props`.
- **BE-02** Entity Framework Core and other ORMs are not used; no project references `Microsoft.EntityFrameworkCore*`.
- **BE-03** Only the Infrastructure project talks to PostgreSQL, through Npgsql + Dapper calling functions or procedures in the service's `api` schema with bound parameters; SQL text against tables does not appear in C#.
- **BE-04** Register one `NpgsqlDataSource` per database as a singleton and open connections per operation.
- **BE-05** I/O is async end to end with `CancellationToken` passed through; `.Result`, `.Wait()` and `async void` are not used (except event handlers required by a framework).
- **BE-06** Expected business failures are returned as typed results (for example `Result<T, Error>`), and exceptions are reserved for unexpected faults; the Api maps both to Problem Details per API-05.
- **BE-07** Configuration uses the options pattern with validation at startup (`ValidateOnStart`); secrets come from AWS Secrets Manager or the environment, never from committed files.
- **BE-08** Time comes from an injected `TimeProvider` and new identifiers are UUIDv7, so tests can control both.
- **BE-09** Outbound HTTP uses `IHttpClientFactory` with the standard resilience pipeline configured as in ADR-0012 (timeouts, retries for idempotent calls only, circuit breaker).
- **BE-10** Logging uses `ILogger` message templates with named placeholders; string interpolation inside log calls is not used.
- **BE-11** Endpoints are ASP.NET Core minimal APIs grouped per feature, with typed results and OpenAPI metadata (authorization per SEC-01).
- **BE-12** Request DTOs are validated at the API boundary before reaching a use case; domain invariants are enforced again inside the Domain.
- **BE-13** Package versions are managed centrally per service (`Directory.Packages.props`); platform packages are consumed by version, never by `ProjectReference`.
- **BE-14** No mutable static state; services are stateless so any task can serve any request.

## Conventions (reference)

| Item | Convention |
|---|---|
| Namespaces | `Workshop.<Service>.<Layer>.<Feature>` |
| Use case names | Verb + noun: `AssignTask`, `ListTasks` |
| Async methods | Suffix `Async` |
| Test projects | `<Svc>.<Layer>.Tests`, xUnit |
| Containers | Multi-stage Dockerfile, chiseled or distroless runtime image, non-root user |

## Mapping database errors

The Infrastructure layer translates SQLSTATE codes raised by `api.*` functions (catalog in
DB-11) into domain errors: not-found → `NotFound`, conflict/unique → `Conflict`, row-version
mismatch → `PreconditionFailed`, check/validation → `Validation`. Unmapped codes are unexpected
faults (BE-06).
