---
status: Accepted
date: 2026-10-21 (accepted 2026-10-25)
deciders: Human approver (repo owner)
consulted: Principal Architect, Senior C#/.NET Engineer, AWS Cloud Architect
informed: All service teams
---

# 0012 — Inter-service communication: domain events (SNS → SQS + transactional outbox) first, sync via Service Connect

## Context and Problem Statement

Microservices rule 3 prefers async events between services, with an outbox, idempotent consumers, a
DLQ and versioned schemas. Sync calls go through API Gateway (external) or ECS Service Connect
(internal). This ADR defines the concrete mechanics.

## Decision Drivers

- No lost or phantom events (DB write and publish must be atomic from the business view).
- At-least-once delivery, so consumers must be idempotent.
- Trace continuity (rule 8). Tenant context on every message.
- No new messaging technology beyond SNS/SQS (global rule 9).

## Decision Outcome

**Async (default between services)**

1. **Topic per producer per event family:** standard SNS topic `<env>-<svc>-events`. Ordering is not required for `TaskAssigned`, so FIFO is not used, which keeps cost and complexity down. Each consumer has its **own SQS queue** subscribed with a **filter policy** on `type`, plus a **DLQ** (`maxReceiveCount` = 5), raw message delivery enabled, SSE-KMS, and alarms on DLQ depth > 0 and on oldest message age.
2. **Transactional outbox:** the business function writes to `outbox.message` in the **same transaction** (inside the `api` function, for example `api.task_assign`). A dispatcher hosted in the producer service as a `BackgroundService` claims batches with `FOR UPDATE SKIP LOCKED` through `api.outbox_claim(batch)`, publishes to SNS, marks them sent, and retries with backoff. Sent rows are purged after N days (procedure).
3. **Envelope:** **CloudEvents 1.0 JSON**: `specversion`, `id` (uuid v7), `source` (`/services/projects`), `type` (`com.workshop.projects.task.assigned.v1`), `time`, `subject` (task id), `datacontenttype`, plus extensions `tenantid`, `traceparent`, `tracestate`, `dataschema`. `traceparent` is also copied to SNS/SQS message attributes for X-Ray/OTel propagation.
4. **Schemas:** JSON Schema in `services/<producer>/contracts/events/<type>.v<N>.schema.json`. Adding optional fields is compatible. Removing, renaming or changing a type means a **new version** and a dual-publish period.
5. **Idempotent consumers:** the consumer's DB has `inbox.processed_message(message_id PK, processed_at)`. Handling plus the inbox insert happen in one transaction (an `api` function), and duplicates are no-ops. Poison messages go to the DLQ after retries. A runbook covers redrive.
6. **Contract tests:** PactNet **message pacts**. The consumer writes the pact, and the producer verifies it in CI. Pact files are committed (no broker; monorepo).

**Sync (only when the caller needs an immediate answer)**

- Internal: **ECS Service Connect** (`http://<svc>.<namespace>:8080`) with TLS enabled, and a JWT from client credentials (ADR-0014).
- Resilience: `Microsoft.Extensions.Http.Resilience` standard pipeline. Total timeout 10 s, attempt timeout 2 s. **Retries only for idempotent methods** (GET/PUT/DELETE with idempotency key). A circuit breaker is always on.
- **No distributed transactions.** Multi-service workflows use choreographed sagas with compensating events, documented in the use case.

### Consequences

- Good, because the outbox removes the dual-write problem without a new technology.
- Bad, because there is an outbox polling cost and latency (default poll 1 s). This is acceptable for notifications.
- Bad, because consumers see **eventual consistency**. Each use case that crosses services documents the expected delay (target p95 < 5 s for `TaskAssigned` → notification visible).

### Confirmation

- Integration test: the task-assign transaction rolls back, so no outbox row exists. On success, exactly one row exists.
- Consumer test: the same message delivered twice creates exactly one notification.
- Contract tests run in CI for each producer and consumer pair.
