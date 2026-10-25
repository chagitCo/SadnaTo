---
status: Accepted
date: 2026-10-21 (accepted 2026-10-25)
deciders: Human approver (repo owner)
consulted: Principal Architect
informed: All service teams
---

# 0011 — Service boundaries and the service catalog

## Context and Problem Statement

Microservices rule 10 requires every service, its owner and boundary to be recorded in
`docs/services/catalog.md` and an ADR. The reference system has two services. We must also decide
where identity, membership and roles live.

## Decision Drivers

- One bounded context per service (rule 1). Database per service (rule 2).
- Authorization decisions about projects and tasks need membership data synchronously and consistently.
- Split only along a clear domain boundary.

## Considered Options for membership/roles

1. Cognito groups/custom attributes.
2. A separate "Organizations/Identity" microservice.
3. **Inside the Projects & Tasks service** (organizations, memberships, roles as part of the Work Management context).

## Decision Outcome

| Unit | Kind | Bounded context | Owns (data) | Publishes | Consumes |
|---|---|---|---|---|---|
| `projects` | Microservice | **Work Management**: organizations (tenants), memberships + roles, projects, tasks | `projects` DB | `TaskAssigned` v1 | — |
| `notifications` | Microservice | **User Notifications**: per-user notification inbox | `notifications` DB | — (later: `NotificationRead`) | `TaskAssigned` v1 |
| `web-bff` | Edge component | None (no domain logic, no DB) | — | — | — |
| `web` | SPA | None | — | — | — |
| Cognito | Managed IdP | Authentication only (who you are) | user pool | — | — |

- Membership and roles live in **projects** (option 3). They are needed on every project/task write, and the context is still small. Splitting them out would create a chatty sync dependency without a clear second consumer. **Revisit trigger:** a second service needs authorization by org role. At that point, extract an `organizations` service and publish membership events.
- `notifications` stores a **local projection** of only what it needs (recipient user id, tenant id, task title snapshot). It never calls `projects` synchronously to render a notification.
- The catalog format is defined in `docs/services/catalog.md`. Each new service adds a row and a "boundary" paragraph in the same PR that creates it.

### Consequences

- Good, because there are two clear contexts and an async-only dependency, which exercises outbox/SQS end to end.
- Bad, because `projects` is the bigger service. This is accepted, with a defined split trigger.

### Confirmation

- `dlc-check catalog`: every folder under `services/` has a catalog row with owner, ADR link, contracts and runbook path.
