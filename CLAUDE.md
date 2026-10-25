# CLAUDE.md — SadnaTo AI-DLC

## Mission (3 lines)

Build a reusable AI-Driven Development Lifecycle (AI-DLC) for this organization: process, rules,
templates and validation that make Claude Code produce secure, observable, tested services.
Two reference microservices (Projects & Tasks, Notifications) prove it. Full text: [MISSION](docs/ai-dlc/MISSION.md).

## Start of every session

1. Read [state.md](docs/ai-dlc/state.md) (current phase, next steps, open questions).
2. Read the last 20 rows of [audit.md](docs/ai-dlc/audit.md).
3. Read the artifacts that `state.md` lists under "Next", then summarize where things stand
   and confirm with the human before continuing a phase.

## AI-DLC workflow (details: [process.md](docs/ai-dlc/process.md))

| Phase | What happens | Skill to use | Gate |
|---|---|---|---|
| Inception | intent → requirements → stories → NFRs → data classification → threat model → domain model → logical design → units of work | `aidlc-inception`, `threat-model`, `new-adr` | Human approves the intent folder |
| Construction | per unit of work: plan → implement in small increments → test → self-review → PR | `new-feature`, `new-api-endpoint`, `new-db-function`, `new-event`, `new-service-integration`, `new-service` | CODEOWNERS review + green CI |
| Operations | IaC plan → deploy → smoke test → observe → runbook | `production-readiness-review`, `release` | Human runs apply and prod deploys |

Change size decides depth (process.md §6). Reviews use the subagents `security-reviewer`,
`architecture-reviewer`, `test-reviewer`, `db-reviewer` (read-only, severity-rated findings).

## Non-negotiable rules

These apply everywhere. Every other rule lives in exactly one file under `docs/standards/` and has an ID.

- **CORE-01** Inspect before you write: read a file before changing it and reuse the conventions you find.
- **CORE-02** Every phase or stage ends by overwriting `docs/ai-dlc/state.md` and appending a row to `docs/ai-dlc/audit.md`.
- **CORE-03** Stop at each phase gate; start the next phase only after explicit human approval in chat.
- **CORE-04** Ask the human only about decisions that affect security, cost, compatibility or architecture; otherwise apply the documented default and record it as an assumption.
- **CORE-05** Report a build, test, scan, migration or deployment as successful only after running it and seeing the result; otherwise state "not run" and give the exact command.
- **CORE-06** Never run `terraform apply`/`destroy`, create or change AWS resources, touch production, push to `main`, force-push or run destructive commands; prepare them for a human.
- **CORE-07** Keep secrets, real credentials, customer data and production dumps out of the repo, prompts, logs and tests; use placeholders.
- **CORE-08** Never weaken, skip or delete a test to make a build pass.
- **CORE-09** Code described as complete contains no TODO, stub or fake implementation; list deferred work explicitly in the PR and in `docs/ai-dlc/plan.md`.
- **CORE-10** Prefer the smallest working, validated change; a cache, Kubernetes, an extra database or new messaging technology needs an ADR first.
- **CORE-11** Never claim compliance with a standard without evidence.
- **CORE-12** Locked decisions (MISSION, Accepted ADRs) change only through a new ADR approved by a human.
- **CORE-13** Never bypass git hooks or signing (`--no-verify`, `--no-gpg-sign`).

Enforcement: `.claude/settings.json` deny rules and hooks block the dangerous commands behind
CORE-06/07/13 — see [hooks README](.claude/hooks/README.md). CI runs `scripts/validate-dlc`.

## Which file applies to what

| When you work on… | Read | Standards (rule IDs) |
|---|---|---|
| Anything | this file | [code-review](docs/standards/code-review.md) (CR), [git-workflow](docs/standards/git-workflow.md) (GIT) |
| Service boundaries, layering, events vs sync | — | [architecture](docs/standards/architecture.md) (ARCH) |
| `src/backend/**` (.NET services, BFF, platform packages) | [src/backend/CLAUDE.md](src/backend/CLAUDE.md) | [backend-csharp](docs/standards/backend-csharp.md) (BE), [api-design](docs/standards/api-design.md) (API) |
| `src/frontend/**` (React web app) | [src/frontend/CLAUDE.md](src/frontend/CLAUDE.md) | [frontend-react](docs/standards/frontend-react.md) (FE) |
| `db/**` (Flyway, functions, pgTAP) | [db/CLAUDE.md](db/CLAUDE.md) | [database-postgres](docs/standards/database-postgres.md) (DB) |
| `infra/**` (Terraform) | [infra/CLAUDE.md](infra/CLAUDE.md) | [aws-infrastructure](docs/standards/aws-infrastructure.md) (AWS) |
| `.github/**` (workflows) | — | [ci-cd](docs/standards/ci-cd.md) (CICD) |
| Auth, tenancy, secrets, input handling | — | [security](docs/standards/security.md) (SEC) |
| Tests of any kind | — | [testing](docs/standards/testing.md) (TEST) |
| Logs, traces, metrics, alarms | — | [observability](docs/standards/observability.md) (OBS) |
| Templates and checklists | [templates/](templates/README.md), [checklists/](checklists/README.md) | — |
| Decisions | [ADR index](docs/adr/README.md), [service catalog](docs/services/catalog.md) | — |
| DLC version and upgrades | [VERSION](docs/ai-dlc/VERSION), [CHANGELOG](docs/ai-dlc/CHANGELOG.md), [upgrading](docs/ai-dlc/upgrading.md) | — |

Read the relevant standard before changing code in its area; cite rule IDs in plans, reviews and PRs.

## Repository map

```
CLAUDE.md, README.md, CONTRIBUTING.md, SECURITY.md
.claude/       settings.json (permissions + hooks), hooks/, skills/, agents/
.github/       CODEOWNERS, PR and issue templates, workflows/
docs/          ai-dlc/ (process, state, audit, plan, VERSION), adr/, services/catalog.md, standards/
src/backend/   services/<svc>/ (.NET), platform/ (shared NuGet packages)
src/frontend/  web app (React + Vite)
db/<svc>/      migrations/ (Flyway V__ and R__), tests/ (pgTAP)
infra/         modules/, bootstrap/, live/<env>/<stack>/, services/<svc>/
templates/     artifact and code templates      checklists/   review checklists
scripts/       validate-dlc and helpers
```

## Commands

| Purpose | Command |
|---|---|
| Validate the DLC (rules, links, budgets, config) | `scripts/validate-dlc` |
| Test the guard hook | `bash .claude/hooks/tests/guard-command.test.sh` |
| Test the validator | `bash scripts/tests/validate-dlc.test.sh` |

Service build/test commands live in the folder `CLAUDE.md` files.

## Writing these instruction files

Root file ≤ 150 lines, folder `CLAUDE.md` ≤ 120 lines, `SKILL.md` ≤ 500 lines. Link, don't inline.
A new rule gets the next free ID in exactly one standards file; everything else references the ID.
