# Standards

Detailed engineering standards. They are **not auto-loaded** into Claude's context: the root
`CLAUDE.md`, folder `CLAUDE.md` files and skills point to the file that applies.

**One home per rule.** Each rule has an ID (`PREFIX-nn`) and is defined in exactly one file.
Anything else (skills, subagents, checklists, folder `CLAUDE.md` files, PRs) cites the ID.
`scripts/validate-dlc` fails if an ID is defined twice, if a referenced ID does not exist, or if the
same rule text appears in two places.

| File | Prefix | Covers |
|---|---|---|
| [architecture.md](architecture.md) | ARCH | Service boundaries, layering, communication, consistency |
| [backend-csharp.md](backend-csharp.md) | BE | .NET code, data access adapters, configuration, errors |
| [database-postgres.md](database-postgres.md) | DB | Schemas, roles, functions, RLS, Flyway migrations |
| [frontend-react.md](frontend-react.md) | FE | TypeScript, React structure, state, forms, i18n/RTL, accessibility |
| [api-design.md](api-design.md) | API | HTTP contracts, versioning, errors, paging, concurrency |
| [security.md](security.md) | SEC | AuthN/AuthZ, tenancy, secrets, input/output, data protection |
| [testing.md](testing.md) | TEST | Test levels, coverage, determinism, test data |
| [observability.md](observability.md) | OBS | Logs, traces, metrics, health, alarms, SLOs |
| [aws-infrastructure.md](aws-infrastructure.md) | AWS | Terraform layout and state, IAM, network, encryption |
| [ci-cd.md](ci-cd.md) | CICD | GitHub Actions, environments, artifacts, supply chain |
| [code-review.md](code-review.md) | CR | Review flow, severity scale, merge criteria |
| [git-workflow.md](git-workflow.md) | GIT | Branches, commits, PRs, tags |

The `CORE-nn` rules are defined in the root [CLAUDE.md](../../CLAUDE.md).

## Changing a standard

Changing a rule's meaning in a way that contradicts a locked decision needs an ADR (CORE-12).
Otherwise, edit the rule in place, keep its ID, and add a line to
[the DLC changelog](../ai-dlc/CHANGELOG.md). Retired IDs are marked `(retired)` and never reused.
