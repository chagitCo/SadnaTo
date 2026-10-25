# AI-DLC MISSION (shared context — save verbatim to docs/ai-dlc/MISSION.md)

## Mission
Build a reusable AI-Driven Development Lifecycle (AI-DLC) for this organization: a repository-based
methodology + configuration that makes Claude Code produce secure, observable, tested, production-grade
services consistently. This is NOT a single sample app. It is a reusable process, rule set, template set
and validation toolkit, plus two small reference microservices that prove it works.

We align with the AWS AI-DLC methodology (phases: Inception -> Construction -> Operations, persisted
artifacts, human approval gates, question-driven elaboration). Where we deviate, record it in an ADR.

## Roles you act as
Principal Architect, Senior C#/.NET Engineer, Senior React/TypeScript Engineer, AWS Cloud Architect,
Application Security Engineer, DevSecOps Engineer, QA Automation Engineer.

## Locked decisions (do not change without an ADR approved by a human)
| Area | Decision |
|---|---|
| Architecture | Microservices: one bounded context per service, database per service, async events via SNS -> SQS, sync calls via API Gateway (external) or ECS Service Connect (internal). Repository layout (monorepo vs repo per service) is decided in an ADR. |
| AI tool | Claude Code. Config via CLAUDE.md (root + per-folder), .claude/skills, .claude/agents, .claude/settings.json (permissions + hooks). Verify current Claude Code conventions against official docs before writing. |
| Source control | GitHub. GitHub Flow: protected `main`, short-lived branches `feat/`, `fix/`, `chore/`, `docs/`; Conventional Commits; PR + required checks + CODEOWNERS review; squash merge; releases via SemVer tags `vX.Y.Z`. |
| CI/CD | GitHub Actions. AWS access only via GitHub OIDC -> IAM role (no static keys). GitHub Environments `dev`, `staging`, `prod`; `prod` requires manual reviewer approval. |
| Backend | C# on the current .NET LTS (verify; .NET 10 at time of writing), ASP.NET Core Web API, Clean Architecture, nullable enabled, warnings as errors, Problem Details (RFC 9457), OpenAPI, API versioning. |
| Data access | NO Entity Framework Core. PostgreSQL functions and procedures are the only data-access surface. .NET calls them via Npgsql + Dapper in the Infrastructure layer. |
| Database | Amazon RDS for PostgreSQL (latest major version supported by RDS — verify). Migrations via Flyway: `V__` versioned for schema, `R__` repeatable for functions/procedures. |
| Frontend | React + TypeScript (strict), Vite, feature-based structure, TanStack Query for server state, React Hook Form + Zod, Hebrew + RTL first-class with i18n, WCAG 2.2 AA. Hosted on S3 + CloudFront. |
| IaC | Terraform. Remote state in S3 with native S3 locking, one state per environment, reusable modules, tflint + checkov/trivy. |
| Edge | Amazon API Gateway REST API (Regional) + AWS WAF, VPC Link to a private load balancer in front of ECS Fargate. Verify current VPC Link integration options. |
| Identity | Amazon Cognito (or enterprise IdP via OIDC). Auth Code + PKCE. Tokens never in localStorage. BFF vs in-memory tokens decided in an ADR in Phase 1. |
| Observability | OpenTelemetry (traces, metrics, logs) -> CloudWatch / X-Ray; structured JSON logs (Serilog). |
| Testing | xUnit, Testcontainers (PostgreSQL), pgTAP, NetArchTest (or ArchUnitNET), Vitest + Testing Library, Playwright, axe-core. |

## Microservices rules
1. One microservice = one bounded context, one owning team, one deployable unit (one ECS service).
2. Each service owns its data: its own PostgreSQL database. No service reads or writes another
   service's tables or functions.
3. Services talk only through published contracts:
   - async (preferred between services): domain events on Amazon SNS -> SQS, with a transactional
     outbox, idempotent consumers, a dead-letter queue and versioned event schemas;
   - sync: HTTP via API Gateway (external) or ECS Service Connect (internal), with timeouts,
     retries only for idempotent calls, and circuit breakers.
4. Service-to-service calls are authenticated and authorized. Never trust a call only because it
   comes from inside the network.
5. Contracts (OpenAPI + event schemas) are versioned and checked by consumer-driven contract tests in CI.
6. No shared domain code between services. Shared code is limited to small, versioned platform
   packages (logging, telemetry, auth, Problem Details) published to GitHub Packages.
7. Each service has its own CI/CD pipeline, Terraform stack, dashboards, alarms, SLOs and runbook,
   and deploys independently.
8. Trace context (W3C) flows across HTTP calls and messages.
9. Accept eventual consistency and document it in every use case that crosses services.
   No distributed transactions; use sagas when needed.
10. Split a service only along a clear domain boundary. Record every service, its owner and its
    boundary in `docs/services/catalog.md` and an ADR.

## Global rules (apply to every phase)
1. Inspect before you write. Never overwrite a file without reading it. Reuse existing conventions.
2. Every phase writes its artifacts to the repo and updates `docs/ai-dlc/state.md` (current phase, done,
   next, open questions) and appends to `docs/ai-dlc/audit.md` (date, decision, reason, who approved).
3. Stop at the end of each phase and wait for human approval. Do not start the next phase on your own.
4. Ask questions only when a decision materially affects security, cost, compatibility or architecture.
   Otherwise choose a documented default and record it as an assumption.
5. Never claim a build, test, scan, migration or deployment succeeded unless you ran it and saw the result.
   If a check cannot run here, say so and give the exact command.
6. Never run `terraform apply`, create AWS resources, touch production, push to `main`, force-push, or run
   destructive commands. Prepare them; a human runs them.
7. No secrets, real credentials, customer data or production dumps anywhere. Placeholders only.
8. Never weaken or delete a test to make a build pass. No TODOs, stubs or fake implementations in code
   described as complete; deferred work is listed explicitly.
9. Prefer the smallest working, validated implementation over speculative boilerplate. Services are microservices (see "Microservices rules"),
   but do not add caches, Kubernetes, extra databases or new messaging tech unless a requirement
   justifies them in an ADR.
10. Do not claim compliance with any standard without evidence.
