# Architecture standard (ARCH)

Scope: service boundaries, internal layering, inter-service communication and consistency.
Sources: MISSION "Microservices rules", ADR-0010, 0011, 0012, 0014, 0015, 0016.

## Rules

- **ARCH-01** Each microservice implements exactly one bounded context, has one owning team and is one deployable unit (one ECS service); it is listed in `docs/services/catalog.md` with its owner and paths.
- **ARCH-02** A service owns its database; it never reads or writes another service's tables or calls another service's database functions.
- **ARCH-03** Services interact only through published, versioned contracts: OpenAPI for HTTP and JSON Schema for events.
- **ARCH-04** Between services, prefer asynchronous domain events (SNS → SQS with a transactional outbox, ADR-0012); use a synchronous call only when the caller needs the answer to continue.
- **ARCH-05** Services share no domain code; shared code is limited to the platform packages allowed by ADR-0015.
- **ARCH-06** Inside a .NET service, dependencies point inward: Api and Infrastructure depend on Application, Application depends on Domain, and Domain references no framework, database or HTTP library.
- **ARCH-07** Business rules and workflow decisions live in Domain and Application; endpoints only translate HTTP to use cases, and SQL functions only persist and enforce data integrity (constraints, tenant scope, concurrency).
- **ARCH-08** A use case that spans services accepts eventual consistency, documents the expected delay and failure handling, and uses a saga with compensating events when several steps must succeed together; distributed transactions are not allowed.
- **ARCH-09** Split a service only along a clear domain boundary, recorded in an ADR and the catalog before code moves.
- **ARCH-10** Each service has its own pipeline, Terraform stack, dashboards, alarms, SLOs and runbook, and deploys without coordinating with other services.
- **ARCH-11** The BFF (`web-bff`) contains no domain logic and no database; it authenticates the browser and forwards calls with the user's token.

## Layer responsibilities (reference)

| Layer | Contains | Typical files |
|---|---|---|
| Domain | Entities, value objects, invariants, state machines, domain events | `Task.cs`, `TaskStatus.cs`, `TaskAssigned.cs` |
| Application | Use cases (commands/queries), ports, validation, authorization policies, transaction boundary | `AssignTask.cs`, `ITaskRepository.cs` |
| Infrastructure | Adapters for ports: Dapper calls to `api.*`, SNS publisher, SQS consumer, secrets | `TaskRepository.cs`, `OutboxDispatcher.cs` |
| Api | Endpoint mapping, auth policies wiring, OpenAPI, Problem Details, health checks | `TaskEndpoints.cs`, `Program.cs` |

Architecture tests (NetArchTest) encode ARCH-06; see TEST-05.

## Communication decision guide

| Need | Use |
|---|---|
| Another service must react to something that happened | Domain event (`new-event` skill) |
| Caller needs data or a decision now, and the callee owns it | Sync call via Service Connect (`new-service-integration` skill) |
| Browser needs data | BFF → service (user token) |
| Data from another service is needed often for reads | Local projection built from that service's events |
