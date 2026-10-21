# Reference System: "Projects & Tasks" + "Notifications"

Status: **Proposed** (Phase 1 Inception artifact). Related: [catalog](../../services/catalog.md),
ADR-0002, 0005, 0006, 0011, 0012, 0014. Pending questions affecting this document: Q2, Q4, Q7, Q10.

## 1. Intent

Prove the AI-DLC end to end with two small, realistic microservices. They exercise multi-tenancy,
role-based authorization, function-only data access, optimistic concurrency, keyset pagination,
soft delete, audit fields, a transactional outbox, SNS→SQS delivery, an idempotent consumer, a BFF,
a Hebrew/RTL UI and full CI/CD. **Non-goals:** billing, file attachments, comments, real-time push,
email/SMS delivery, org self-service sign-up beyond the first Owner, and search beyond simple filters.

## 2. Domain model

### 2.1 Projects & Tasks service (`projects`, context: Work Management)

| Aggregate / entity | Key fields | Notes |
|---|---|---|
| **Organization** (tenant) | `id`, `name`, audit fields, `row_version` | `tenant_id = organization.id` |
| **Membership** | `tenant_id`, `user_id` (Cognito `sub`), `display_name`, `email`, `role` ∈ {Owner, Member, Viewer}, audit fields, soft delete | One per (tenant, user) |
| **Project** | `tenant_id`, `id`, `key` (e.g. `WEB`, unique per tenant), `name`, `description`, audit fields, `row_version`, soft delete | |
| **Task** | `tenant_id`, `id`, `project_id`, `number` (per project, sequential), `title`, `description`, `status` ∈ {Todo, InProgress, Done}, `assignee_user_id?`, `due_date?`, `completed_at?`, audit fields, `row_version`, soft delete | |

**Audit fields** on every table: `created_at`, `created_by`, `updated_at`, `updated_by`
(timestamptz in UTC, user ids). Soft delete adds `deleted_at`, `deleted_by`. **Concurrency:**
`row_version bigint` is incremented by every update function.

### 2.2 Task status state machine

```
        start (needs assignee)          complete
 Todo ─────────────────────────► InProgress ───────────► Done
  ▲                                 │  ▲                  │
  └──────────── stop ───────────────┘  └──── reopen ──────┘
```

| ID | Business rule |
|---|---|
| BR-1 | Allowed transitions: Todo→InProgress, InProgress→Done, InProgress→Todo, Done→InProgress. **Todo→Done is rejected** (422 `invalid-transition`). |
| BR-2 | Todo→InProgress requires a non-null assignee. |
| BR-3 | Entering Done sets `completed_at = now()`. Leaving Done (reopen) clears it. |
| BR-4 | Reopen (Done→InProgress) is allowed only for an **Owner** or the **current assignee**. |
| BR-5 | An assignee must be an active membership with role Owner or Member (not Viewer) in the same tenant. |
| BR-6 | Unassigning a task in InProgress moves it back to Todo in the same transaction. |
| BR-7 | Tasks of a soft-deleted project are not readable or writable (404). |
| BR-8 | An organization must always keep at least one Owner. Removing or demoting the last Owner is rejected (409). |
| BR-9 | Project `key` is 2–10 uppercase letters, unique per tenant among non-deleted projects. |
| BR-10 | Task `title` 1–200 chars. `description` ≤ 10,000 chars. Plain text only; the UI escapes on render. |

### 2.3 Role permissions

| Action | Owner | Member | Viewer |
|---|---|---|---|
| Read org, projects, tasks | ✓ | ✓ | ✓ |
| Create/edit project | ✓ | ✓ | ✗ |
| Delete (soft) project | ✓ | ✗ | ✗ |
| Create/edit/assign/transition task | ✓ | ✓ | ✗ |
| Reopen task (Done→InProgress) | ✓ | assignee only | ✗ |
| Delete (soft) task | ✓ | creator only | ✗ |
| Add/remove members, change roles | ✓ | ✗ | ✗ |

### 2.4 Event: `TaskAssigned` v1

- CloudEvents `type`: `com.workshop.projects.task.assigned.v1`. `source`: `/services/projects`. `subject`: task id. Extensions: `tenantid`, `traceparent`.
- Emitted (via outbox, in the same transaction) when `assignee_user_id` changes to a **non-null** value that differs from the previous one. Not emitted on unassign.
- `data`: `{ taskId, projectId, projectKey, taskNumber, taskTitle, assigneeUserId, assignedByUserId, assignedAt }`
- Schema: `services/projects/contracts/events/task-assigned.v1.schema.json` (Phase 3).

### 2.5 Notifications service (`notifications`, context: User Notifications)

| Entity | Key fields |
|---|---|
| **Notification** | `tenant_id`, `id`, `recipient_user_id`, `kind` (`TaskAssigned`), `source_event_id` (unique), `payload` (task id, project key, task number, title snapshot, assigned by), `created_at`, `read_at?` |
| **ProcessedMessage** (inbox) | `message_id` PK, `processed_at` |

| ID | Business rule |
|---|---|
| NBR-1 | One notification per `TaskAssigned` event for the assignee. Duplicate deliveries create nothing (idempotent on the event `id`). |
| NBR-2 | If `assignedByUserId == assigneeUserId` (self-assignment), no notification is created. The message is still marked processed. |
| NBR-3 | A user sees only their own notifications in the active tenant. |
| NBR-4 | Notifications older than 90 days are purged (retention job, deferred to Phase 5, listed in plan). |

## 3. API outline (versioned `v1`, RFC 9457 errors, OpenAPI)

Base (through the BFF): `/bff/api/projects/v1` and `/bff/api/notifications/v1`.

| Method & path | Purpose | Notes |
|---|---|---|
| `GET /orgs/{orgId}` | Org details | |
| `GET /orgs/{orgId}/members?cursor=&limit=` | List members | Keyset |
| `POST /orgs/{orgId}/members` / `PATCH …/{userId}` / `DELETE …/{userId}` | Manage members | Owner only, BR-8 |
| `GET /orgs/{orgId}/projects?cursor=&limit=` | List projects | Keyset on (`name`, `id`) |
| `POST /orgs/{orgId}/projects` | Create project | 201 + `Location` + `ETag` |
| `GET/PATCH/DELETE /orgs/{orgId}/projects/{projectId}` | Read/update/soft delete | PATCH/DELETE need `If-Match` |
| `GET /orgs/{orgId}/projects/{projectId}/tasks?status=&assignee=&cursor=&limit=` | List tasks | Keyset on (`created_at`, `id`) desc |
| `POST /orgs/{orgId}/projects/{projectId}/tasks` | Create task | |
| `GET/PATCH/DELETE /orgs/{orgId}/projects/{projectId}/tasks/{taskId}` | Read/edit/soft delete | `If-Match` required |
| `POST …/tasks/{taskId}/transitions` `{ "to": "InProgress" }` | Status change | `If-Match`. BR-1…4 |
| `PUT …/tasks/{taskId}/assignee` `{ "userId": … }` / `DELETE …/assignee` | Assign / unassign | `If-Match`. BR-5, BR-6. Emits event |
| `GET /me/notifications?unread=true&cursor=&limit=` | My notifications (notifications svc) | Keyset on (`created_at`, `id`) desc |
| `POST /me/notifications/{id}/read`, `POST /me/notifications/read-all` | Mark read | Idempotent |

**Keyset pagination:** `limit` defaults to 25, maximum 100. Responses contain `items` and
`nextCursor` (opaque, base64url of the last sort key + id, HMAC-signed so it cannot be tampered
with). There is no total count. **Optimistic concurrency:** responses carry `ETag: "<row_version>"`.
A missing `If-Match` returns 428, and a mismatch returns 412 with the current representation link.
**Tenant:** `orgId` in the path must equal the active org in the session and must be a membership
of the caller. Otherwise the API returns **404** to avoid confirming the resource exists.

## 4. User stories and acceptance criteria

### Projects & Tasks

**US-1 Create a project.** As a Member, I want to create a project so that my team can track work.
- AC-1.1 Given I am a Member of org A, when I POST a valid project, then I get 201, an `ETag` and a `Location`, and `created_by` is me.
- AC-1.2 Given a non-deleted project with key `WEB` exists in org A, when I create another with `WEB`, then I get 409 `duplicate-key`.
- AC-1.3 Given I am a Viewer, when I POST a project, then I get 403.
- AC-1.4 Given an invalid key (`web1`), then I get 400 with a validation Problem Details listing `key`.

**US-2 Create a task.** As a Member, I want to add tasks to a project so that the work is visible.
- AC-2.1 Given project P in org A, when I create a task with a title, then it is `Todo`, gets the next `number` in P, and returns 201.
- AC-2.2 Given an empty title or a title over 200 chars, then I get 400.
- AC-2.3 Given P is soft-deleted, then I get 404.

**US-3 Assign a task.** As a Member, I want to assign a task to a teammate so that ownership is clear.
- AC-3.1 Given task T and member M (Member role) in org A, when I PUT assignee M with a correct `If-Match`, then I get 200 with a new ETag, and exactly one `TaskAssigned` outbox row exists in the same transaction.
- AC-3.2 Given the target user is a Viewer, or not a member of org A, then I get 422 `invalid-assignee` and no outbox row is written.
- AC-3.3 Given T is already assigned to M, when I assign M again, then I get 200 and **no** new event.
- AC-3.4 Given a stale `If-Match`, then I get 412 and nothing changes.
- AC-3.5 Given T is InProgress, when I unassign, then T becomes Todo (BR-6) and no event is emitted.

**US-4 Move a task through its workflow.** As the assignee, I want to start, complete and reopen tasks so that status reflects reality.
- AC-4.1 Todo→InProgress with an assignee returns 200. Without an assignee it returns 422 `assignee-required`.
- AC-4.2 Todo→Done returns 422 `invalid-transition`.
- AC-4.3 InProgress→Done sets `completed_at`. Done→InProgress clears it.
- AC-4.4 A Member who is not the assignee and tries Done→InProgress gets 403. An Owner gets 200.
- AC-4.5 Without `If-Match`, the request gets 428.

**US-5 Browse tasks.** As any member, I want to list and filter tasks with stable paging so that I can find work.
- AC-5.1 Filtering by `status` and `assignee` returns only matching, non-deleted tasks of my tenant.
- AC-5.2 Given 60 tasks and `limit=25`, following `nextCursor` returns 25, 25 and 10 with no duplicates or gaps, even if new tasks are inserted between page requests.
- AC-5.3 A tampered cursor returns 400.
- AC-5.4 `limit=500` is clamped or rejected per the OpenAPI spec (400 above 100).

**US-6 Delete (soft).** As an Owner, I want to delete projects and tasks without losing history.
- AC-6.1 DELETE with a valid `If-Match` returns 204. Later GET and list calls exclude it, and `deleted_at`/`deleted_by` are set.
- AC-6.2 A Member deleting another user's task gets 403. Deleting their own task returns 204.

**US-7 Manage members.** As an Owner, I want to add members and change roles so that access is controlled.
- AC-7.1 Adding a user by Cognito `sub` with a role returns 201.
- AC-7.2 Demoting or removing the last Owner returns 409 `last-owner`.
- AC-7.3 After a member is removed, their requests to org A get 404 (no membership).

**US-8 Tenant isolation.** As an org, I want my data invisible to other orgs.
- AC-8.1 Any request from a member of org B for an org-A resource id gets 404, and no data from A appears in the response or logs.
- AC-8.2 pgTAP: calling each `api` function with tenant B and a tenant-A id returns no rows or raises not-found.

**US-9 Hebrew/RTL UI.** As a Hebrew-speaking user, I want the UI in Hebrew with RTL layout and accessible controls.
- AC-9.1 The default locale is `he` and `<html dir="rtl" lang="he">`. Switching to `en` flips to LTR without a reload.
- AC-9.2 axe-core reports no serious or critical violations on the project list, task list, task form and notifications pages.
- AC-9.3 All flows are keyboard operable with a visible focus. Form errors are announced (`aria-live`).

### Notifications

**US-10 Get notified when assigned.** As a user, I want a notification when someone assigns me a task.
- AC-10.1 Given a `TaskAssigned` event for me (by someone else), then within p95 5 s one unread notification appears in `GET /me/notifications`.
- AC-10.2 Given the same event delivered twice, then exactly one notification exists.
- AC-10.3 Given a self-assignment, then no notification is created.
- AC-10.4 Given a message that fails schema validation, then it is retried and moves to the DLQ after 5 receives, and a DLQ alarm fires.

**US-11 Read my notifications.** As a user, I want to list and mark notifications read.
- AC-11.1 The list shows only my notifications in the active tenant, newest first, keyset-paged.
- AC-11.2 Marking one read sets `read_at`. Repeating it is idempotent (200/204).
- AC-11.3 Another user's notification id returns 404.

## 5. Non-functional requirements

| ID | Category | Target | Verification |
|---|---|---|---|
| NFR-1 | Latency | p95 < 300 ms reads, < 500 ms writes at 50 RPS per service (prod sizing) | k6 load test in staging (Phase 4), CloudWatch p95 |
| NFR-2 | Availability | 99.9% monthly per service (prod) | SLO + burn-rate alarms |
| NFR-3 | Event latency | `TaskAssigned` → notification visible p95 < 5 s, p99 < 30 s | Custom metric (event time → insert), e2e test |
| NFR-4 | Durability | RPO ≤ 5 min (RDS PITR), RTO ≤ 4 h | Quarterly restore drill in staging (runbook) |
| NFR-5 | Security | OWASP ASVS 4.0 Level 2 used as a **target checklist** (no compliance claim) | `security-reviewer` checklist, ZAP baseline in staging |
| NFR-6 | Tenancy | 0 cross-tenant reads/writes | pgTAP + integration tests (US-8) |
| NFR-7 | Observability | 100% of requests traced (sampling: 100% errors, 10% success in prod), JSON logs with trace id, RED metrics per endpoint | Telemetry tests, dashboard review |
| NFR-8 | Accessibility | WCAG 2.2 AA on all pages | axe-core in Playwright + manual keyboard/screen-reader checklist |
| NFR-9 | i18n | he (default, RTL) + en. No hard-coded UI strings | ESLint rule + i18n key check |
| NFR-10 | Scalability | Stateless services. ECS autoscaling 2–6 tasks on CPU 60% (prod) | Load test |
| NFR-11 | Cost | dev environment < $X/month (**X to be set by approver**) | AWS Budgets alarm |
| NFR-12 | Supply chain | Pinned dependencies, SBOM per image, signed provenance | CI attestation step |

## 6. Data classification

Classes: **Public**, **Internal**, **Confidential** (business data, PII), **Restricted** (credentials, secrets, tokens).

| Data element | Service | Class | PII | Retention | Logging rule |
|---|---|---|---|---|---|
| Organization name | projects | Confidential | No | Life of org + 90 d after deletion | IDs only, not names |
| Membership `email`, `display_name` | projects | Confidential | **Yes** | Until member removed + 90 d | Never logged |
| Cognito `sub` / user id | all | Internal | Pseudonymous | As above | May be logged |
| Project name/description, task title/description | projects | Confidential | Possibly (free text) | Life of record + 90 d after soft delete | **Never logged**. Only IDs |
| Task status, dates, numbers | projects | Internal | No | As above | May be logged |
| Notification payload (title snapshot) | notifications | Confidential | Possibly | 90 days | Never logged |
| Outbox / inbox rows | both | Confidential (contain payload) | Possibly | Sent rows purged after 7 days | Only message id/type |
| Access/refresh/ID tokens, session cookie | web-bff | **Restricted** | Yes | Session lifetime | Never logged (redaction in Logging package) |
| DB credentials, client secrets, KMS keys | infra | **Restricted** | — | Rotated | Never logged |
| Audit fields (`created_by`, …) | all | Internal | Pseudonymous | Life of record | May be logged |

**Controls:** encryption at rest everywhere (RDS, SNS, SQS, S3, CloudWatch Logs with CMK),
TLS 1.2+ in transit, data residency per Q6, and no production data in non-prod environments
(synthetic seed data only).

## 7. STRIDE threat model

**Trust boundaries:** (TB1) Internet ↔ CloudFront/WAF; (TB2) API Gateway ↔ VPC (VPC link);
(TB3) service ↔ database; (TB4) service ↔ SNS/SQS; (TB5) BFF ↔ Cognito; (TB6) CI ↔ AWS (OIDC).

| ID | STRIDE | Threat | Asset | Mitigation | Test / evidence | Residual |
|---|---|---|---|---|---|---|
| T1 | Spoofing | Stolen browser token reused | User session | BFF: tokens never in JS. `__Host-` HttpOnly SameSite=Strict cookie. Short access-token TTL | Playwright storage check (ADR-0005) | Low |
| T2 | Spoofing | Internal caller impersonates a service | Projects API | Client-credentials JWT + scope per endpoint. SG allowlist | Integration 401/403 tests | Low |
| T3 | Spoofing | Forged `TaskAssigned` message | Notifications DB | SNS publish limited to the producer role. SQS `aws:SourceArn`. Envelope `source`/`type` allowlist | Checkov custom check + consumer test | Low |
| T4 | Tampering | Cross-tenant write via a manipulated `orgId` or ids | Tasks | Tenant from session/membership. Composite FKs. RLS FORCE | US-8 tests, pgTAP | Low |
| T5 | Tampering | Lost update from concurrent edits | Tasks | `row_version` + `If-Match` (412/428) | AC-3.4, AC-4.5 | Low |
| T6 | Tampering | SQL injection | DBs | Functions only, bound parameters, no dynamic SQL (or `format %I/%L`), app role EXECUTE-only | SQL lint, CodeQL, pgTAP privilege tests | Low |
| T7 | Tampering | Cursor manipulation to page other data | Lists | HMAC-signed cursor. Tenant filter regardless of cursor | AC-5.3 | Low |
| T8 | Tampering | CSRF on state-changing BFF calls | All writes | SameSite=Strict, `X-CSRF` header, Origin check | Automated CSRF test | Low |
| T9 | Repudiation | User denies changing or deleting a task | Audit trail | `created_by/updated_by/deleted_by`, soft delete, structured access logs with user id + trace id | Integration test asserts audit fields | Medium (no immutable audit log yet; deferred) |
| T10 | Info disclosure | Confidential text or PII in logs | Titles, emails | Logging package redaction. Logging rules in §6 | Log-scrubbing unit tests | Low |
| T11 | Info disclosure | Resource enumeration across tenants | IDs | 404 instead of 403 for foreign resources. UUIDv7 ids | US-8 | Low |
| T12 | Info disclosure | Removed member still sees old notifications (title snapshots) | Notification payload | Accepted for v1. **Future:** `MemberRemoved` event purges or locks notifications | Documented | **Medium** (approver to accept) |
| T13 | Info disclosure | XSS steals data via the UI | Browser | React escaping, no `dangerouslySetInnerHTML`, strict CSP via CloudFront response headers, Trusted Types where supported | ESLint rule, CSP header test | Low |
| T14 | DoS | Request floods / expensive list queries | APIs, DB | WAF rate rules, API Gateway throttling, `limit` max 100, keyset indexes, statement_timeout per role | Load test, WAF config scan | Medium |
| T15 | DoS | Poison message blocks the consumer | Notifications | maxReceiveCount 5 → DLQ, alarm, redrive runbook | AC-10.4 | Low |
| T16 | Elevation | Viewer performs writes, or a Member reopens others' tasks | Tasks | Role policy in the Application layer, checked again in `api` functions | AC-1.3, AC-4.4 | Low |
| T17 | Elevation | App DB role escalates via `SECURITY DEFINER` search_path hijack | DB | Pinned `search_path`, `REVOKE CREATE ON SCHEMA public`, owner-only schemas | pgTAP + SQL lint | Low |
| T18 | Elevation | Compromised CI workflow deploys to prod | AWS prod | OIDC trust limited to `environment:prod`, required reviewers, pinned action SHAs, CODEOWNERS on `.github/` | `dlc-check github`, Checkov on IAM | Medium (depends on Q9) |
| T19 | Elevation | AI agent runs destructive or irreversible commands | Repo, AWS | Deny rules + PreToolUse hook, no AWS write credentials on dev machines | Hook unit tests (Phase 2) | Low |

## 8. Cross-service consistency (eventual)

- **Assign → notify:** `projects` commits the task and the outbox row atomically. The dispatcher publishes to SNS, then SQS delivers to `notifications`. The user may see the assignment in the task list **before** the notification appears (target p95 < 5 s). If SNS is unavailable, the outbox retries. If `notifications` is down, SQS holds messages (queue retention set to the 14-day maximum).
- **Unassign/reassign:** a reassignment produces a new event for the new assignee. The old assignee's notification is **not** retracted in v1 (documented limitation).
- **Task title change after assignment:** the notification keeps the snapshot title. This is intentional (a historical record).
- No distributed transactions. No saga is needed for v1, since there is no multi-step cross-service business process.
