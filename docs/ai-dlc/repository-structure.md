# Repository Structure

Status: **Accepted** (Phase 1 gate, 2026-10-25); **revised in Phase 2** (accepted at the Phase 2 gate, 2026-10-25) for the layer-first layout of
[ADR-0016](../adr/0016-repository-layout-and-instruction-files.md) (Accepted).
Monorepo per [ADR-0010](../adr/0010-repository-strategy-monorepo.md).

Markers: **M** = mandatory (`scripts/validate-dlc` or CI fails without it), **C** = conditional
(required when the note applies), **E** = example (reference implementation; replaceable).
State column: ✅ exists now · ⏳ planned (phase).

## Root and AI configuration

| Path | M/C/E | State | Purpose |
|---|---|---|---|
| `CLAUDE.md` | M | ✅ | Root instructions (≤ 150 lines): mission, workflow, CORE rules, index of which file applies |
| `CLAUDE.local.md` | C | — | Personal, gitignored notes |
| `README.md`, `CONTRIBUTING.md`, `SECURITY.md` | M | ✅ | Entry point, contributor guide, vulnerability policy |
| `.gitignore`, `.gitattributes`, `.editorconfig` | M | ✅ | Ignore rules (secrets, local settings, build output), LF for scripts, code style |
| `.claude/settings.json` | M | ✅ | Shared permissions (deny/ask/allow) and hooks |
| `.claude/hooks/*.sh`, `lib/json.sh`, `README.md`, `tests/` | M | ✅ | Guard, formatter, Stop reminder, SessionStart banner; documentation and tests |
| `.claude/skills/<name>/SKILL.md` (11) | M | ✅ | One skill per repeatable workflow (list in `CLAUDE.md`) |
| `.claude/agents/*-reviewer.md` (4) | M | ✅ | Read-only reviewers with severity-rated findings |
| `.mcp.json` | C | — | Only if an MCP server is approved by ADR |

## GitHub

| Path | M/C/E | State | Purpose |
|---|---|---|---|
| `.github/CODEOWNERS` | M | ✅ | Ownership per path; one owner today, team handles noted |
| `.github/pull_request_template.md` | M | ✅ | AC→test map, evidence, self-review, deferred work |
| `.github/ISSUE_TEMPLATE/{intent,bug,change-request}.yml`, `config.yml` | M | ✅ | Issue forms; private vulnerability reporting link |
| `.github/dependabot.yml` | M | ✅ | GitHub Actions now; NuGet/npm/Terraform/Docker added with the first code |
| `.github/workflows/dlc-validate.yml` | M | ✅ | Runs `scripts/validate-dlc`, its self-tests and hook tests on every PR |
| `.github/workflows/_reusable-{dotnet-service,terraform,deploy-ecs,web}.yml` | M | ⏳ P3/P4 | Shared pipeline logic |
| `.github/workflows/{security,pr-title,release}.yml` | M | ⏳ P3 | CodeQL/dependency review/secret scan, Conventional Commit title, release-please |
| `.github/workflows/svc-<svc>.yml`, `web.yml`, `infra-<stack>.yml` | M | ⏳ P3–P5 | Thin per-deployable callers with path filters (CICD-04) |

## Documentation

| Path | M/C/E | State | Purpose |
|---|---|---|---|
| `docs/ai-dlc/MISSION.md` | M | ✅ | Verbatim mission and locked decisions |
| `docs/ai-dlc/process.md` | M | ✅ | Lifecycle definition |
| `docs/ai-dlc/state.md`, `audit.md`, `plan.md` | M | ✅ | Current position, append-only decision log, phase checklist |
| `docs/ai-dlc/VERSION`, `CHANGELOG.md`, `upgrading.md` | M | ✅ | DLC version, changes with upgrade actions, service upgrade procedure |
| `docs/ai-dlc/repository-structure.md` | M | ✅ | This file |
| `docs/ai-dlc/inception/*` | E | ✅ | Reference-system Inception artifacts |
| `docs/intents/<YYYYMMDD>-<slug>/**` | C | — | Per-intent artifacts for future work |
| `docs/standards/*.md` (12 + README) | M | ✅ | Detailed standards; one home per rule ID; not auto-loaded |
| `docs/adr/README.md`, `NNNN-*.md` | M | ✅ | ADR index and records (template in `templates/adr.md`) |
| `docs/services/catalog.md` | M | ✅ | Service catalog with owners and paths |
| `docs/services/<svc>/service-definition.md` | C | ⏳ | Filled questionnaire per service (`new-service`) |
| `docs/security/exceptions.md` | C | — | Dated vulnerability exceptions (SEC-15), created on first use |

## Templates, checklists, scripts

| Path | M/C/E | State | Purpose |
|---|---|---|---|
| `templates/README.md` + artifact templates (`inception/`, `construction/`, `operations/`, `adr.md`, `threat-model.md`, `runbook.md`, `feature-plan.md`, `api-endpoint.md`, `test-plan.md`) | M | ✅ | Starting points for every artifact in process.md |
| `templates/db-function.sql`, `templates/migration.sql` | M | ✅ | SQL shapes for `R__` routines and `V__` migrations |
| `templates/service/{README,questionnaire,service-definition}.md` | M | ✅ | Service questionnaire and skeleton specification |
| `templates/service/dotnet/**` (`Workshop.Templates` pack) | M | ⏳ P3 | `dotnet new workshop-service` (needs the .NET SDK to build and test) |
| `checklists/{code-review,security,db-change,production-readiness,release}.md` | M | ✅ | Verification lists that cite rule IDs |
| `scripts/validate-dlc`, `validate-dlc.conflicts`, `tests/validate-dlc.test.sh` | M | ✅ | DLC validator, locked-decision conflict phrases, self-tests |

## Backend — `src/backend/` (one folder per service)

| Path | M/C/E | State | Purpose |
|---|---|---|---|
| `src/backend/CLAUDE.md` | M | ✅ | .NET context and commands (on demand) |
| `src/backend/Directory.Build.props` | M | ⏳ P3 | Nullable, warnings as errors, analyzers (BE-01) |
| `src/backend/services/<svc>/<Svc>.sln`, `Directory.Packages.props`, `Dockerfile`, `CLAUDE.md`, `.dlc/version`, `CHANGELOG.md` | M | ⏳ P3 | Service solution, packages, image, context, DLC stamp |
| `src/backend/services/<svc>/src/<Svc>.{Domain,Application,Infrastructure,Api}/` | M | ⏳ P3 | Clean Architecture layers (ARCH-06) |
| `src/backend/services/<svc>/tests/<Svc>.{Domain,Application,Architecture,Integration}.Tests/` | M | ⏳ P3 | Tests per TEST rules |
| `src/backend/services/<svc>/tests/<Svc>.Contract.Tests/` | C | ⏳ P5 | When the service has cross-service consumers/providers |
| `src/backend/services/<svc>/contracts/openapi/v<N>.yaml`, `contracts/events/*.schema.json` | M / C | ⏳ P3 | Published contracts (events only for producers) |
| `src/backend/services/<svc>/docs/{runbook,slo}.md` | M | ⏳ P3 | Operations documents |
| `src/backend/services/projects/**`, `notifications/**` | E | ⏳ P3, P5 | Reference services |
| `src/backend/services/web-bff/**` | M | ⏳ P4 | BFF (ADR-0005), no Domain/DB layers |
| `src/backend/platform/Workshop.Platform.{Logging,Telemetry,Auth,ProblemDetails,Messaging}/` | M | ⏳ P3 | Shared NuGet packages (ADR-0015) |

## Frontend — `src/frontend/`

| Path | M/C/E | State | Purpose |
|---|---|---|---|
| `src/frontend/CLAUDE.md` | M | ✅ | React context and commands (on demand) |
| `src/frontend/{package.json,tsconfig.json,vite.config.ts,eslint.config.js}` | M | ⏳ P4 | Toolchain, strict TypeScript |
| `src/frontend/src/{app,features,shared,i18n}/` | M | ⏳ P4 | Feature-based app, he/en translations |
| `src/frontend/tests/e2e/` | M | ⏳ P4 | Playwright + axe-core |

## Database — `db/`

| Path | M/C/E | State | Purpose |
|---|---|---|---|
| `db/CLAUDE.md` | M | ✅ | PostgreSQL context and commands (on demand) |
| `db/<svc>/flyway.toml`, `ERRORS.md` | M | ⏳ P3 | Flyway config (no secrets), SQLSTATE error catalog |
| `db/<svc>/migrations/V*__*.sql`, `R__*.sql` | M | ⏳ P3 | Versioned schema, repeatable routines |
| `db/<svc>/tests/*.test.sql` | M | ⏳ P3 | pgTAP tests |
| `db/<svc>/seed/dev.sql` | C | ⏳ P3 | Synthetic local/dev data |

## Infrastructure — `infra/`

| Path | M/C/E | State | Purpose |
|---|---|---|---|
| `infra/CLAUDE.md` | M | ✅ | Terraform context and commands (on demand) |
| `infra/modules/<module>/` | M | ⏳ P4 | Reusable modules with README, examples, tests |
| `infra/bootstrap/` | M | ⏳ P4 | Per-account state bucket, KMS, GitHub OIDC (human-run once) |
| `infra/live/<env>/<stack>/` | M | ⏳ P4 | Platform stacks per environment |
| `infra/services/<svc>/main.tf`, `envs/<env>/` | M | ⏳ P3–P5 | Service stacks |
| `infra/README.md`, `.tflint.hcl`, `.checkov.yaml`, `trivy.yaml` | M | ⏳ P4 | Stack order, scanner config |

## Deviations from MISSION and earlier decisions (and where they are recorded)

| Deviation | Reason | Record |
|---|---|---|
| Per-service tags `<svc>/vX.Y.Z` instead of plain `vX.Y.Z` | Several independently versioned services in one repo | ADR-0008 |
| Several Terraform states per environment (one per stack) | Independent service deploys; still no state shared across environments | ADR-0007 |
| An extra deployable `web-bff` that is not a bounded context | Chosen browser-auth model | ADR-0005, ADR-0011 |
| Artifact root `docs/ai-dlc/` instead of upstream `aidlc-docs/` | All docs under `docs/` | ADR-0001 |
| Layer-first layout (`src/backend`, `src/frontend`, `db`, `infra`) replacing `services/<svc>/`; `docs/standards/` + folder `CLAUDE.md` replacing `.claude/rules/`; `scripts/validate-dlc` replacing `tools/dlc-check` | Phase 2 instruction; context budget; validator must run without the .NET SDK | ADR-0016 |
