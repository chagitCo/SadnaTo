# AI-DLC Delivery Plan — Phases 2–5

Status: **Proposed** (Phase 1). Each phase ends at a human gate (process.md §4). IDs are referenced
in PRs and `audit.md`. `→` means "depends on".

## Prerequisites (human, before Phase 2 can run any command)

- [ ] P-1 Install the toolchain (environment-report §3) and confirm the container runtime licence (Q11).
- [ ] P-2 Create the GitHub repository and push the initial history, so the Phase 1 PR can be opened.
- [ ] P-3 Answer or confirm Q1–Q11 (`inception/questions.md`). Accept or amend ADR-0001…0015.

## Phase 2 — DLC foundation (Construction of the toolkit) → P-1, P-2, P-3

| ID | Item | Depends on |
|---|---|---|
| 2.1 | Repo skeleton: `README.md`, `.gitignore`, `.gitattributes`, `.editorconfig`, `global.json`, `Directory.Build.props` | — |
| 2.2 | Root `CLAUDE.md` (< 200 lines) + `.claude/rules/*.md` (path-scoped) | 2.1 |
| 2.3 | `.claude/settings.json`: permissions deny/ask/allow + hooks (guard, session-start, post-edit format) with hook scripts (PowerShell + bash) and **unit tests for the guard hook** | 2.1 |
| 2.4 | Subagents: security-reviewer, architecture-reviewer, test-engineer, db-engineer, frontend-a11y-reviewer | 2.2 |
| 2.5 | Skills: aidlc-inception, aidlc-construction, aidlc-operations, adr, phase-status, db-function | 2.2, 2.6 |
| 2.6 | Artifact templates `docs/ai-dlc/templates/*.md` (all artifacts in process.md) | — |
| 2.7 | `tools/dlc-check` (.NET console): structure, ADR/MADR, catalog, state/audit, SQL lint, boundaries, Claude-config frontmatter lint, Terraform backend lint. Includes its own tests | 2.1 |
| 2.8 | GitHub: CODEOWNERS, PR template, dependabot, `pr-title`, `dlc-validate`, `security` workflows | 2.7 |
| 2.9 | Reusable workflows: `_reusable-dotnet-service`, `_reusable-terraform`, `_reusable-deploy-ecs`, `_reusable-web` (deploy jobs stubbed **only** by being uncalled, not by fake steps) | 2.8 |
| 2.10 | Platform packages v0.1.0: Logging, Telemetry, Auth, ProblemDetails (+ Messaging if Q10 = yes), with tests, PublicApi baselines and a publish workflow | 2.1, 2.9 |
| 2.11 | `dotnet new` template pack `workshop-service` + template CI (generate → build → test → dlc-check) | 2.7, 2.10 |
| 2.12 | Skills: new-service, upgrade-service (uses 2.11) | 2.11 |
| 2.13 | Verify the Flyway Docker image licence (ADR-0003 open item); pin image digests (Flyway, PostgreSQL 18, pgTAP) | P-1 |
| 2.14 | Document the GitHub repo settings to apply (rulesets, environments) as `docs/guides/github-setup.md` + `dlc-check github` drift report. A human applies them | 2.8 |
| 2.15 | Phase 2 exit: all checks run locally with evidence, `state.md`/`audit.md` updated, PR opened | all |

## Phase 3 — Projects & Tasks service → Phase 2

| ID | Item (UOW) | Depends on |
|---|---|---|
| 3.1 | Generate `services/projects` from the template, catalog row, service CLAUDE.md | 2.11, 2.12 |
| 3.2 | DB: roles, schemas, tables (V__), RLS policies, composite FKs | 3.1 |
| 3.3 | DB: `api` functions for orgs/members, projects, tasks (R__), error catalog, keyset helpers | 3.2 |
| 3.4 | pgTAP: privileges, RLS/tenant isolation, business rules BR-1…10 | 3.3 |
| 3.5 | Domain + Application: aggregates, state machine, role policies, validation (unit tests first) | 3.1 |
| 3.6 | Infrastructure: Dapper repositories, SQLSTATE → domain error mapping, signed cursors | 3.3, 3.5 |
| 3.7 | API: endpoints, versioning, OpenAPI export, Problem Details, ETag/If-Match, auth policies | 3.6 |
| 3.8 | Outbox: `outbox.message`, emit in `api.task_assign`, dispatcher BackgroundService, `TaskAssigned` v1 JSON Schema | 3.3, 2.10 |
| 3.9 | Integration tests (Testcontainers + Flyway): every AC in US-1…US-8 | 3.7, 3.8 |
| 3.10 | Architecture tests, security review (subagent), threat-model test mapping | 3.9 |
| 3.11 | Service Terraform stack (no apply): ECS service, TG/listener rule, API routes, SNS topic, DB/roles, alarms | 2.9 |
| 3.12 | Phase 3 exit: evidence, PR, gate | all |

## Phase 4 — Web, BFF, platform infrastructure, Operations → Phase 3

| ID | Item | Depends on |
|---|---|---|
| 4.1 | `infra/bootstrap` + `infra/live/<env>/*` stacks (network, platform/ECS, edge API GW + WAF + VPC link V2 + ALB, data/RDS, identity/Cognito, observability). Plans only | 2.9, Q6 |
| 4.2 | `services/web-bff`: OIDC confidential client, cookie session, Data Protection keys in SSM, YARP routes, CSRF | 2.10, Q2 |
| 4.3 | `web/`: Vite + React + TS strict, he/en i18n + RTL, TanStack Query, RHF + Zod, features projects/tasks | 3.7, 4.2 |
| 4.4 | Web tests: Vitest + Testing Library, Playwright e2e + axe-core (US-9) | 4.3 |
| 4.5 | Pipelines wired: PR plan, deploy dev on merge, staging/prod on tag (prod gated) | 4.1, 3.11 |
| 4.6 | Observability: OTel → ADOT/CloudWatch/X-Ray, dashboards, alarms, SLOs (NFR-1, 2, 7) | 4.1 |
| 4.7 | Runbooks for projects and web-bff, load test plan (k6), restore drill procedure | 4.6 |
| 4.8 | Human-run: `terraform apply` dev + first deploy. Claude prepares commands and checklists | 4.1–4.5 |
| 4.9 | Phase 4 exit: smoke-test evidence from dev (human-run), PR, gate | all |

## Phase 5 — Notifications service + DLC upgrade proof → Phase 4

| ID | Item | Depends on |
|---|---|---|
| 5.1 | Generate `services/notifications` with the `new-service` skill (proves the generator) | 2.12 |
| 5.2 | DB: notifications + inbox tables, RLS, `api` functions, pgTAP (NBR-1…3) | 5.1 |
| 5.3 | SQS consumer (idempotent), schema validation, DLQ handling | 5.2, 2.10 |
| 5.4 | API `/me/notifications` (list, read, read-all) + web feature (bell + list) | 5.3, 4.3 |
| 5.5 | PactNet message pact: notifications (consumer) ↔ projects (provider) in CI | 5.3, 3.8 |
| 5.6 | Terraform: SQS queue + DLQ + subscription with filter policy, alarms. Retention purge job (NBR-4) | 4.1 |
| 5.7 | E2E: assign in UI → notification visible (NFR-3 measured) | 5.4, 5.6 |
| 5.8 | **DLC upgrade proof:** change the template + one rule, run `upgrade-service` on `projects`, show the PR diff | 2.12 |
| 5.9 | Retrospective: what to change in the DLC (new ADRs if needed). Final `state.md`/`audit.md` | all |

## Deferred (explicitly out of scope until an intent asks for them)

Immutable audit log (T9), `MemberRemoved` event and notification purge (T12), notification
retraction on reassign, email/push delivery, Pact Broker, mTLS between services, separate RDS
instances per service.
