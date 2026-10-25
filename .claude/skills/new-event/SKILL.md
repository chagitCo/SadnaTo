---
name: new-event
description: Add a domain event between services — versioned JSON Schema, transactional outbox publisher in the producer, idempotent consumer with DLQ in the consumer, and a consumer-driven contract test.
when_to_use: One service must react to something that happened in another (ARCH-04), or an existing event needs a new version.
argument-hint: "[producer] [event name] [consumer]"
---

# New domain event

## When to use

- A new event type, or a new version of an existing event. Mechanics follow ADR-0012.
- Not for request/response needs: use `new-service-integration`.

## Required inputs (ask if missing)

| Input | Example |
|---|---|
| Producer service and trigger | `projects`, when an assignee changes to a new user |
| Event name and version | `TaskAssigned` v1 → type `com.workshop.projects.task.assigned.v1` |
| Payload fields with classification | taskTitle: Confidential (SEC-11 applies to logs) |
| Consumers and what they do | `notifications` stores a notification |
| Ordering and latency needs | none / p95 < 5 s |

## Steps

1. Read ADR-0012, [architecture](../../../docs/standards/architecture.md) and the producer's contracts (CORE-01).
2. **Schema**: `src/backend/services/<producer>/contracts/events/<name>.v<N>.schema.json` (ARCH-03); new version instead of incompatible change.
3. **Outbox write**: extend the producing `api` routine to insert into `outbox.message` in the same transaction (`new-db-function`); pgTAP proves "rollback ⇒ no outbox row".
4. **Publisher**: register the type with the platform outbox dispatcher; propagate trace context (OBS-02); metrics per OBS-05.
5. **Infrastructure (producer)**: SNS topic and its publish policy in `infra/services/<producer>/` (no apply).
6. **Consumer**: SQS queue + DLQ + subscription with filter policy in `infra/services/<consumer>/`; handler validates source/type/schema (SEC-06), records the message id in `inbox.processed_message` in the same transaction (idempotency), and lets poison messages reach the DLQ.
7. **Tests**: producer integration test (one outbox row per business change), consumer test (duplicate delivery → one effect), contract test (TEST-06), DLQ path test.
8. Document eventual consistency in the use case (ARCH-08); add DLQ alarm and runbook entry (OBS-07).
9. Run reviewers.

## Artifacts produced

Schema file, outbox changes, publisher registration, consumer handler, Terraform for topic/queue/DLQ,
tests, runbook entry, catalog row update (publishes/consumes columns).

## Checks to run

Producer and consumer builds and tests, pgTAP, contract tests, `terraform validate` for changed
stacks, `scripts/validate-dlc`.

## Definition of done

Event is versioned and documented, delivery is at-least-once with proven idempotency, DLQ and
alarms exist, the contract test runs in both pipelines, and the catalog lists the new relationship.
