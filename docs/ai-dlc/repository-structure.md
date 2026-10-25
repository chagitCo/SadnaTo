# Proposed Repository Structure

Status: **Accepted** (Phase 1 gate, 2026-10-25). Assumes a **monorepo** ([ADR-0010](../adr/0010-repository-strategy-monorepo.md), Q1 confirmed).
Markers: **M** = mandatory (CI `dlc-check` fails without it), **C** = conditional (required when the
condition in the note applies), **E** = example (reference implementation that shows the pattern and
can be replaced).

## Root and AI configuration

| Path | M/C/E | Purpose |
|---|---|---|
| `CLAUDE.md` | M | Root instructions under 200 lines: mission summary, golden rules, how to resume (read `state.md`), pointers to rules and skills |
| `CLAUDE.local.md` | C | Personal, gitignored notes (only if a developer wants them) |
| `README.md` | M | What the repo is, quick start, links to process, catalog and ADRs |
| `.gitignore` / `.gitattributes` / `.editorconfig` | M | Ignore rules (incl. `CLAUDE.local.md`, `.claude/settings.local.json`, `*.tfstate`, `.env*`), line endings, code style |
| `global.json` | M | Pins the .NET SDK (10.0.x, `rollForward: latestFeature`) |
| `Directory.Build.props` | M | Repo-wide MSBuild: `Nullable=enable`, `TreatWarningsAsErrors=true`, analyzers, `AnalysisLevel=latest-recommended`, deterministic builds |
| `.claude/settings.json` | M | Team permissions (allow/ask/**deny**) and hooks (PreToolUse guard, PostToolUse format, SessionStart state banner, Stop checks) |
| `.claude/hooks/guard-commands.ps1` + `.sh` | M | PreToolUse: blocks `terraform apply/destroy`, push to `main`, force-push, AWS mutating calls and secret reads. Exits 2 with a reason |
| `.claude/hooks/session-start.ps1` + `.sh` | M | Prints the phase, next steps and open questions from `docs/ai-dlc/state.md` |
| `.claude/hooks/post-edit-format.ps1` + `.sh` | C | Runs `dotnet format`/`prettier` on edited files (when the toolchain is present) |
| `.claude/rules/security.md` | M | Secrets, input validation, authz, logging redaction (always loaded) |
| `.claude/rules/dotnet.md` | M | `paths: services/**/*.cs, platform/dotnet/**`: Clean Architecture layering, Problem Details, versioning, no EF Core |
| `.claude/rules/sql.md` | M | `paths: **/db/**/*.sql`: function-only access, SECURITY DEFINER + search_path, tenant first parameter, RLS, Flyway naming |
| `.claude/rules/frontend.md` | M | `paths: web/**`: strict TS, feature folders, TanStack Query, RHF + Zod, i18n/RTL, WCAG 2.2 AA |
| `.claude/rules/terraform.md` | M | `paths: **/*.tf`: module usage, tagging, no `apply`, backend rules |
| `.claude/rules/testing.md` | M | Test pyramid, naming, Testcontainers, pgTAP, no weakening tests |
| `.claude/rules/messaging.md` | M | `paths: **/contracts/events/**, **/Messaging/**`: outbox, envelope, idempotency, versioning |
| `.claude/skills/aidlc-inception/SKILL.md` | M | Runs Inception stages I1–I12 and writes the artifacts from templates |
| `.claude/skills/aidlc-construction/SKILL.md` | M | Runs C1–C5 for one UOW |
| `.claude/skills/aidlc-operations/SKILL.md` | M | Prepares O1–O5 (plans, runbook, SLOs). Never applies (`disable-model-invocation: true`) |
| `.claude/skills/new-service/SKILL.md` | M | Wraps `dotnet new workshop-service` and adds the catalog row, ADR stub, workflow and infra stack |
| `.claude/skills/upgrade-service/SKILL.md` | M | Brings a service up to the current template version (ADR-0009) |
| `.claude/skills/db-function/SKILL.md` | M | Scaffolds an `R__` function + pgTAP test + Dapper repository method |
| `.claude/skills/adr/SKILL.md` | M | Creates the next numbered MADR and updates the ADR index |
| `.claude/skills/phase-status/SKILL.md` | M | Updates `state.md` and appends `audit.md` in the standard format |
| `.claude/agents/security-reviewer.md` | M | Read-only reviewer: OWASP ASVS-oriented checklist, tenancy, secrets, authz |
| `.claude/agents/architecture-reviewer.md` | M | Read-only reviewer: boundaries, layering, ADR conformance |
| `.claude/agents/test-engineer.md` | M | Writes or extends tests from ACs. Never deletes or weakens tests |
| `.claude/agents/db-engineer.md` | C | SQL/pgTAP specialist (recommended for services with a DB) |
| `.claude/agents/frontend-a11y-reviewer.md` | C | WCAG 2.2 AA + RTL review (when `web/` changes) |
| `.mcp.json` | C | Only if an MCP server is approved by ADR |

## GitHub

| Path | M/C/E | Purpose |
|---|---|---|
| `.github/CODEOWNERS` | M | Ownership per folder. `.claude/`, `.github/`, `docs/adr/` owned by DLC maintainers/architects |
| `.github/pull_request_template.md` | M | UOW link, AC→test map, evidence of commands run, deferred work, gates |
| `.github/ISSUE_TEMPLATE/*.yml` | C | Intent / bug / change request forms |
| `.github/dependabot.yml` | M | NuGet, npm, GitHub Actions, Terraform, Docker updates |
| `.github/workflows/_reusable-dotnet-service.yml` | M | Build, test, arch tests, pgTAP, contract tests, image build + attestation |
| `.github/workflows/_reusable-terraform.yml` | M | fmt/validate/tflint/trivy/checkov/plan. Apply only in Environment jobs |
| `.github/workflows/_reusable-deploy-ecs.yml` | M | Flyway task → ECS deploy → smoke test, per environment via OIDC |
| `.github/workflows/_reusable-web.yml` | M | Lint, typecheck, Vitest, Playwright + axe, build, S3 sync + CloudFront invalidation |
| `.github/workflows/dlc-validate.yml` | M | Runs `tools/dlc-check` (structure, ADRs, catalog, state/audit, boundaries, Claude config lint) |
| `.github/workflows/security.yml` | M | CodeQL, dependency review, secret scanning (gitleaks), Trivy fs |
| `.github/workflows/pr-title.yml` | M | Conventional Commit check on the PR title |
| `.github/workflows/svc-<name>.yml` | M (per service) | Thin caller of the reusable workflows with path filters |
| `.github/workflows/infra-<stack>.yml` | M (per platform stack) | Platform Terraform stacks |
| `.github/workflows/release.yml` | M | release-please (monorepo mode) creating `<component>/vX.Y.Z` tags |

## Documentation

| Path | M/C/E | Purpose |
|---|---|---|
| `docs/ai-dlc/MISSION.md` | M | Verbatim mission (locked decisions) |
| `docs/ai-dlc/process.md` | M | Lifecycle definition |
| `docs/ai-dlc/state.md` | M | Current position (overwritten each stage) |
| `docs/ai-dlc/audit.md` | M | Append-only decision log |
| `docs/ai-dlc/plan.md` | M | Phase/UOW checklist |
| `docs/ai-dlc/repository-structure.md` | M | This file |
| `docs/ai-dlc/templates/*.md` | M | Templates for every artifact in process.md (intent, requirements, user-stories, nfr, data-classification, threat-model, domain-model, logical-design, units-of-work, plan, test-report, review, runbook, slo) |
| `docs/ai-dlc/inception/*` | E | Reference-system Inception artifacts (this phase) |
| `docs/intents/<YYYYMMDD>-<slug>/**` | C | Per-intent artifacts for future work |
| `docs/adr/0000-template.md`, `README.md`, `NNNN-*.md` | M | ADRs (MADR) + index |
| `docs/services/catalog.md` | M | Service catalog |
| `docs/guides/*.md` | C | How-tos (onboarding, local setup, upgrade a service) |

## Templates, tools, platform

| Path | M/C/E | Purpose |
|---|---|---|
| `templates/Workshop.Templates.csproj` | M | Template pack project (NuGet) |
| `templates/content/workshop-service/**` | M | `dotnet new` service template: solution, 4 layers, tests, db/, contracts/, infra/, Dockerfile, CLAUDE.md, `.dlc/version` |
| `templates/content/workshop-service/.template.config/template.json` | M | Template parameters (name, owner, port, hasDatabase, publishesEvents, consumesEvents) |
| `templates/CHANGELOG.md` | M | Template versions + upgrade notes consumed by `upgrade-service` |
| `tools/dlc-check/` | M | Validation toolkit (a .NET console app, so no new runtime): structure, ADR format, catalog, state/audit, SQL lint, boundaries, Claude config frontmatter lint, Terraform backend lint |
| `tools/scripts/*.ps1` + `*.sh` | C | Local helpers (db up, run migrations, run pgTAP) |
| `platform/dotnet/Workshop.Platform.{Logging,Telemetry,Auth,ProblemDetails,Messaging}/**` | M | Shared NuGet packages (ADR-0015), each with tests and CHANGELOG |
| `platform/web/web-platform/**` | C | `@workshop/web-platform` npm package (when ≥ 2 web apps, else lives in `web/`) |

## Services (per-service layout; `projects` shown)

| Path | M/C/E | Purpose |
|---|---|---|
| `services/projects/CLAUDE.md` | M | Service context: bounded context, invariants, commands to build/test, links to contracts |
| `services/projects/.dlc/version` | M | Template version this service was generated from |
| `services/projects/Projects.sln` + `Directory.Packages.props` | M | Solution and central package versions |
| `services/projects/src/Projects.Domain/` | M | Entities, value objects, invariants, domain events. No infrastructure references |
| `services/projects/src/Projects.Application/` | M | Use cases (commands/queries), ports (repository interfaces), validation, authorization rules |
| `services/projects/src/Projects.Infrastructure/` | M | Npgsql + Dapper repositories calling `api.*` functions, SNS publisher, outbox dispatcher, secrets |
| `services/projects/src/Projects.Api/` | M | ASP.NET Core host: endpoints, versioning, OpenAPI, Problem Details, auth policies, health checks |
| `services/projects/tests/Projects.Domain.Tests/` | M | xUnit unit tests |
| `services/projects/tests/Projects.Application.Tests/` | M | Use-case tests with fakes |
| `services/projects/tests/Projects.Architecture.Tests/` | M | NetArchTest layering + "no EF Core" rules |
| `services/projects/tests/Projects.Integration.Tests/` | M | Testcontainers PostgreSQL 18 + Flyway + API (WebApplicationFactory) |
| `services/projects/tests/Projects.Contract.Tests/` | C | PactNet provider/message verification (when it has consumers or providers) |
| `services/projects/db/migrations/V*__*.sql` | M | Versioned schema migrations |
| `services/projects/db/migrations/R__*.sql` | M | Repeatable functions/procedures (one object per file) |
| `services/projects/db/tests/*.sql` | M | pgTAP tests |
| `services/projects/db/flyway.toml` | M | Flyway config (no secrets) |
| `services/projects/contracts/openapi/v1.yaml` | M | Published OpenAPI (generated + checked in, diffed in CI) |
| `services/projects/contracts/events/*.schema.json` | C | Event schemas (when it publishes events) |
| `services/projects/infra/` | M | Service Terraform stack + `envs/{dev,staging,prod}` |
| `services/projects/Dockerfile` | M | Multi-stage build, chiseled/distroless runtime, non-root |
| `services/projects/docs/runbook.md`, `slo.md` | M | Operations docs |
| `services/projects/CHANGELOG.md` | M | Generated by release-please |
| `services/notifications/**` | E | Second reference service, same layout (Phase 5) |
| `services/web-bff/**` | M (if ADR-0005 BFF accepted) | BFF host (YARP, OIDC). No Domain/DB layers |

## Web

| Path | M/C/E | Purpose |
|---|---|---|
| `web/package.json`, `tsconfig.json` (strict), `vite.config.ts`, `eslint.config.js` | M | Toolchain |
| `web/src/app/` | M | App shell, providers (QueryClient, i18n, router), error boundary |
| `web/src/features/<feature>/{api,components,hooks,schemas,routes}/` | M | Feature-based modules (projects, tasks, notifications) |
| `web/src/shared/` | M | Design-system components, a11y helpers, BFF HTTP client |
| `web/src/i18n/{he,en}/*.json` | M | Translations. Hebrew default, `dir="rtl"` |
| `web/tests/e2e/` | M | Playwright + axe-core |
| `web/infra/` | M | S3 bucket + CloudFront + WAF association stack (or part of `infra/live/*/edge`) |

## Infrastructure

| Path | M/C/E | Purpose |
|---|---|---|
| `infra/modules/<module>/` | M | Reusable modules (see ADR-0007), each with README, `examples/` and `tests/` |
| `infra/bootstrap/` | M | Per-account state bucket, KMS, GitHub OIDC provider + roles. Run once by a human |
| `infra/live/<env>/<stack>/` | M | Platform stacks per environment |
| `infra/README.md` | M | Stack order, how to plan, who applies |
| `.tflint.hcl`, `.checkov.yaml`, `trivy.yaml` | M | IaC scanner configuration |

## Deviations from MISSION (and where they are recorded)

| Deviation | Reason | Record |
|---|---|---|
| Per-service tags `<svc>/vX.Y.Z` instead of plain `vX.Y.Z` | Several independently versioned services in one repo | ADR-0008 |
| Several states per environment (one per stack) | Independent service deploys, smaller blast radius. Still no state shared across environments | ADR-0007 |
| An extra deployable `web-bff` that is not a bounded context | Chosen browser-auth model | ADR-0005, ADR-0011 |
| Artifact root `docs/ai-dlc/` instead of upstream `aidlc-docs/` | Keep all docs under `docs/` | ADR-0001 |
