# Service Catalog

Source of truth for every deployable unit, its owner and boundary (Microservices rule 10,
[ADR-0011](../adr/0011-service-boundaries-and-catalog.md)). A row is added in the same PR that
creates the service. Status: **Accepted** (Phase 1 gate, 2026-10-25). Nothing is built yet.

| Service | Kind | Bounded context | Owner (CODEOWNERS) | Database | Publishes | Consumes | Sync API | ADR | Runbook | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| `projects` | Microservice | Work Management | `@org/team-projects` *(placeholder)* | `projects` (RDS shared instance, ADR-0013) | `TaskAssigned` v1 | — | `/api/projects/v1` | 0011 | `src/backend/services/projects/docs/runbook.md` | Planned (Phase 3) |
| `notifications` | Microservice | User Notifications | `@org/team-notifications` *(placeholder)* | `notifications` | — | `TaskAssigned` v1 | `/api/notifications/v1` | 0011 | `src/backend/services/notifications/docs/runbook.md` | Planned (Phase 5) |
| `web-bff` | Edge component | — (no domain) | `@org/team-web` *(placeholder)* | none | — | — | `/bff/*` | 0005 | `src/backend/services/web-bff/docs/runbook.md` | Planned (Phase 4) |
| `web` | SPA (S3 + CloudFront) | — | `@org/team-web` *(placeholder)* | none | — | — | — | 0004, 0005 | `src/frontend/docs/runbook.md` | Planned (Phase 4) |

## Paths (ADR-0016)

| Service | Code | Database | Infrastructure | Workflow |
|---|---|---|---|---|
| `projects` | `src/backend/services/projects/` | `db/projects/` | `infra/services/projects/` | `.github/workflows/svc-projects.yml` |
| `notifications` | `src/backend/services/notifications/` | `db/notifications/` | `infra/services/notifications/` | `.github/workflows/svc-notifications.yml` |
| `web-bff` | `src/backend/services/web-bff/` | — | `infra/services/web-bff/` | `.github/workflows/svc-web-bff.yml` |
| `web` | `src/frontend/` | — | `infra/live/<env>/edge/` (S3 + CloudFront) | `.github/workflows/web.yml` |

## Boundaries

### projects — Work Management

Owns organizations (tenants), memberships and roles (Owner, Member, Viewer), projects and tasks.
It answers "who may do what to which work item". It does **not** own user identity (Cognito) or
notification delivery.

### notifications — User Notifications

Owns each user's notification inbox: creating notifications from domain events, listing them and
marking them read. It keeps a minimal local projection (recipient, tenant, task id and title
snapshot). It never queries `projects` synchronously.
