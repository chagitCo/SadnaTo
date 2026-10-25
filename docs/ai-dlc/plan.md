# AI-DLC Delivery Plan — Phases 2–5

Status: **Accepted** (Phase 1 gate, 2026-10-25). Each phase ends at a human gate (process.md §4). IDs are referenced
in PRs and `audit.md`. `→` means "depends on".

## Prerequisites (human, before Phase 2 can run any command)

- [ ] P-1 Install the toolchain (environment-report §3) and confirm the container runtime licence (Q11).
- [x] P-2 Create the GitHub repository and push the initial history, so the Phase 1 PR can be opened.
- [x] P-3 Answer or confirm Q1–Q11 (`inception/questions.md`). Accept or amend ADR-0001…0015.

## Phase 2 — AI-DLC process layer and Claude Code configuration (DLC 0.2.0)

Scope re-cut by the human's Phase 2 instruction (2026-10-25); layout per ADR-0016. Items that need
the .NET SDK or AWS moved to Phase 3 as 3.0x.

| ID | Item | State |
|---|---|---|
| 2.1 | Repo hygiene: `README.md`, `.gitignore`, `.gitattributes`, `.editorconfig`, `CONTRIBUTING.md`, `SECURITY.md` | [x] |
| 2.2 | Root `CLAUDE.md` (≤ 150 lines) + folder `CLAUDE.md` in `src/backend`, `src/frontend`, `db`, `infra` (≤ 120) | [x] |
| 2.3 | Twelve standards in `docs/standards/` with rule IDs (single home per rule) | [x] |
| 2.4 | Eleven skills (`aidlc-inception`, `new-service`, `new-feature`, `new-api-endpoint`, `new-db-function`, `new-event`, `new-service-integration`, `new-adr`, `threat-model`, `production-readiness-review`, `release`) | [x] |
| 2.5 | Four read-only reviewer subagents (security, architecture, test, db) | [x] |
| 2.6 | `.claude/settings.json` deny/ask/allow + hooks (guard, formatter, Stop reminder, SessionStart) with tests and README | [x] |
| 2.7 | Templates (artifacts, service questionnaire, SQL shapes), checklists, PR/issue templates, CODEOWNERS | [x] |
| 2.8 | DLC versioning: `VERSION`, `CHANGELOG.md`, `upgrading.md` | [x] |
| 2.9 | `scripts/validate-dlc` + self-tests + `dlc-validate` workflow | [x] |
| 2.10 | ADR-0016 (layout and instruction files) | [x] (Proposed) |
| 2.11 | Phase 2 exit: validation output, PR, `state.md`/`audit.md` | [x] |

## Phase 3 — Projects & Tasks service → Phase 2, P-1

| ID | Item (UOW) | Depends on |
|---|---|---|
| 3.01 | Reusable workflows: `_reusable-dotnet-service`, `_reusable-terraform`, `_reusable-deploy-ecs` (deploy jobs only become callable once real steps exist); `security.yml`, `pr-title.yml`, `release.yml` | Phase 2 |
| 3.02 | Platform packages v0.1.0: Logging, Telemetry, Auth, ProblemDetails, Messaging, with tests, PublicApi baselines and a publish workflow | P-1 |
| 3.03 | `dotnet new` template pack in `templates/service/dotnet/` + template CI (generate → build → test → validate-dlc) | 3.02 |
| 3.04 | Verify the Flyway Docker image licence (ADR-0003 open item); pin image digests (Flyway, PostgreSQL 18, pgTAP) | P-1 |
| 3.05 | `docs/guides/github-setup.md`: rulesets (squash-only, required checks incl. `dlc-validate`), environments, secret scanning, private vulnerability reporting. A human applies them | Phase 2 |
| 3.06 | `scripts/validate-dlc` checks `boundaries` (no cross-service references or `ProjectReference` to platform) and `github` (repo settings drift via `gh api`, read-only), with self-tests | 3.02 |
| 3.1 | Generate `src/backend/services/projects`, `db/projects`, `infra/services/projects` with `new-service`; catalog row, service CLAUDE.md | 3.03 |
| 3.2 | DB: roles, schemas, tables (V__), RLS policies, composite FKs | 3.1 |
| 3.3 | DB: `api` functions for orgs/members, projects, tasks (R__), error catalog, keyset helpers | 3.2 |
| 3.4 | pgTAP: privileges, RLS/tenant isolation, business rules BR-1…10 | 3.3 |
| 3.5 | Domain + Application: aggregates, state machine, role policies, validation (unit tests first) | 3.1 |
| 3.6 | Infrastructure: Dapper repositories, SQLSTATE → domain error mapping, signed cursors | 3.3, 3.5 |
| 3.7 | API: endpoints, versioning, OpenAPI export, Problem Details, ETag/If-Match, auth policies | 3.6 |
| 3.8 | Outbox: `outbox.message`, emit in `api.task_assign`, dispatcher BackgroundService, `TaskAssigned` v1 JSON Schema | 3.3, 3.02 |
| 3.9 | Integration tests (Testcontainers + Flyway): every AC in US-1…US-8 | 3.7, 3.8 |
| 3.10 | Architecture tests, security review (subagent), threat-model test mapping | 3.9 |
| 3.11 | Service Terraform stack in `infra/services/projects` (no apply): ECS service, TG/listener rule, API routes, SNS topic, DB/roles, alarms | 3.01 |
| 3.12 | Phase 3 exit: evidence, PR, gate | all |

## Phase 4 — Web, BFF, platform infrastructure, Operations → Phase 3

| ID | Item | Depends on |
|---|---|---|
| 4.1 | `infra/bootstrap` + `infra/live/<env>/*` stacks (network, platform/ECS, edge API GW + WAF + VPC link V2 + ALB, data/RDS, identity/Cognito, observability). Plans only | 3.01, Q6 |
| 4.2 | `src/backend/services/web-bff`: OIDC confidential client, cookie session, Data Protection keys in SSM, YARP routes, CSRF | 3.02, Q2 |
| 4.3 | `src/frontend/`: Vite + React + TS strict, he/en i18n + RTL, TanStack Query, RHF + Zod, features projects/tasks | 3.7, 4.2 |
| 4.4 | Web tests: Vitest + Testing Library, Playwright e2e + axe-core (US-9) | 4.3 |
| 4.5 | Pipelines wired: PR plan, deploy dev on merge, staging/prod on tag (prod gated) | 4.1, 3.11 |
| 4.6 | Observability: OTel → ADOT/CloudWatch/X-Ray, dashboards, alarms, SLOs (NFR-1, 2, 7) | 4.1 |
| 4.7 | Runbooks for projects and web-bff, load test plan (k6), restore drill procedure | 4.6 |
| 4.8 | Human-run: `terraform apply` dev + first deploy. Claude prepares commands and checklists | 4.1–4.5 |
| 4.9 | Phase 4 exit: smoke-test evidence from dev (human-run), PR, gate | all |

## Phase 5 — Notifications service + DLC upgrade proof → Phase 4

| ID | Item | Depends on |
|---|---|---|
| 5.1 | Generate `notifications` with the `new-service` skill (proves the generator) | 3.03 |
| 5.2 | DB: notifications + inbox tables, RLS, `api` functions, pgTAP (NBR-1…3) | 5.1 |
| 5.3 | SQS consumer (idempotent), schema validation, DLQ handling | 5.2, 3.02 |
| 5.4 | API `/me/notifications` (list, read, read-all) + web feature (bell + list) | 5.3, 4.3 |
| 5.5 | PactNet message pact: notifications (consumer) ↔ projects (provider) in CI | 5.3, 3.8 |
| 5.6 | Terraform: SQS queue + DLQ + subscription with filter policy, alarms. Retention purge job (NBR-4) | 4.1 |
| 5.7 | E2E: assign in UI → notification visible (NFR-3 measured) | 5.4, 5.6 |
| 5.8 | **DLC upgrade proof:** change the template + one rule, upgrade `projects` with `docs/ai-dlc/upgrading.md`, show the PR diff | 3.03 |
| 5.9 | Retrospective: what to change in the DLC (new ADRs if needed). Final `state.md`/`audit.md` | all |

## Deferred (explicitly out of scope until an intent asks for them)

Immutable audit log (T9), `MemberRemoved` event and notification purge (T12), notification
retraction on reassign, email/push delivery, Pact Broker, mTLS between services, separate RDS
instances per service.
