---
status: Accepted
date: 2026-10-21 (accepted 2026-10-25)
deciders: Human approver (repo owner)
consulted: Senior C#/.NET Engineer, DevSecOps Engineer
informed: All service teams
---

> **Amended by [ADR-0016](0016-repository-layout-and-instruction-files.md)** (2026-10-25): repository paths and instruction-file mechanism changed; the decision below is otherwise unchanged.

# 0003 — Database migration tool: Flyway OSS (Apache-2.0), DbUp as fallback

## Context and Problem Statement

MISSION locks Flyway (`V__` versioned for schema, `R__` repeatable for functions/procedures) and asks
for a licence check against DbUp.

## Decision Drivers

- First-class **repeatable** migrations, so function bodies are re-applied when their checksum changes.
- The licence must be acceptable for commercial use without per-user fees.
- Must run identically in CI (GitHub Actions), locally (Docker) and in AWS (one-off ECS task in the VPC).
- Works with pgTAP and Testcontainers.

## Considered Options

1. **Flyway OSS** (`flyway/flyway` Docker image / CLI).
2. Redgate Flyway Community/Teams/Enterprise editions.
3. DbUp (`dbup-postgresql`), embedded in a .NET migrator console app.

## Licence check result (2026-10-21)

| Tool | Finding | Source |
|---|---|---|
| Flyway OSS | GitHub repo `flyway/flyway` is **Apache-2.0**. | https://github.com/flyway/flyway |
| Redgate Flyway Community | A separate Redgate product labelled **"Freeware"**, governed by Redgate's EULA. The repo states that Redgate editions are *not part of the open source project*. | https://www.red-gate.com/support/license/software-editions/ |
| Flyway Teams/Enterprise | Commercial, per-user. Adds undo, cherry-pick, drift reports and similar. **None are required.** | Redgate site |
| DbUp | `dbup-postgresql` 7.0.1 (Feb 2026), actively maintained, **MIT** per a third-party index. | https://www.nuget.org/packages/dbup-postgresql |

**Open item:** the distribution that the official Docker image installs must be confirmed to carry the
Apache-2.0 licence and not the Redgate EULA. Do this in Phase 2 by inspecting the image's licence
files. If legal requires it, or the image turns out to be EULA-only, switch to option 3 (Q5).

## Decision Outcome

Chosen option: **1 — Flyway OSS**, invoked as a container with a pinned digest.

- Layout per service: `services/<svc>/db/migrations/V<yyyymmddHHmm>__<desc>.sql` (timestamp versions avoid merge collisions) and `services/<svc>/db/migrations/R__<schema>.<object>.sql`, one object per file.
- `flyway.validateMigrationNaming=true`, `cleanDisabled=true` (always), `outOfOrder=false`, `baselineOnMigrate=false`.
- Flyway runs as `<svc>_owner`. The app never runs migrations at startup.
- Execution: CI runs migrations against Testcontainers PostgreSQL 18, then pgTAP. Deploys run a one-off ECS Fargate task (same VPC) **before** the new app version. Migrations must be **expand/contract** (backward compatible with the running version).
- Repeatable files must be idempotent (`CREATE OR REPLACE`; drop and recreate only when the signature changes, inside the same file).

### Consequences

- Good, because it is a widely known tool with clear `V__`/`R__` semantics, a fit for function-only data access.
- Good, because the tool runs as a container, so no Java is needed on dev machines.
- Bad, because the JVM-based image is large (~hundreds of MB). This is acceptable for CI and one-off tasks.
- Bad, because there is licence ambiguity between OSS and the Redgate distribution. It is tracked as Q5.

### Confirmation

- CI step `db-validate`: `flyway validate` + `flyway info` against an ephemeral database, followed by pgTAP.
- `tools/dlc-check sql` rejects badly named files and any `R__` file without `CREATE OR REPLACE`.

## Pros and Cons of the Options

### DbUp

- Good, because it is MIT, .NET-native and needs no JVM.
- Bad, because repeatable semantics need custom journaling or script options (to be verified). It also departs from the MISSION lock.
