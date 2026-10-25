---
status: Accepted
date: 2026-10-21 (accepted 2026-10-25)
deciders: Human approver (repo owner)
consulted: Principal Architect, DevSecOps Engineer
informed: All service teams
---

> **Amended by [ADR-0016](0016-repository-layout-and-instruction-files.md)** (2026-10-25): repository paths and instruction-file mechanism changed; the decision below is otherwise unchanged.

# 0010 — Repository strategy: monorepo with strong per-service boundaries

## Context and Problem Statement

MISSION leaves monorepo vs repo-per-service open. The organization is building a reusable DLC plus
two reference services, a web app and a BFF. Teams and service count are small today.

## Decision Drivers

- The DLC (rules, skills, hooks, templates, reusable workflows) must reach every service with minimal friction.
- Independent deploys and ownership per service.
- Contract tests between producer and consumer.
- Claude Code's CLAUDE.md hierarchy: root rules load for every session, and per-service CLAUDE.md loads on demand.

## Considered Options

1. **Monorepo**: `services/<svc>/`, `web/`, `platform/`, `infra/`, `templates/`, `.claude/`.
2. Repo per service plus a "DLC" repo and a "platform" repo.
3. Hybrid: monorepo for the DLC and platform, separate repos for services.

## Decision Outcome

Chosen option: **1 — Monorepo**.

- **CI:** one workflow per deployable, triggered by `paths:` filters (`services/projects/**`, `platform/**` for dependants, and so on). Shared logic lives in reusable workflows. A `changes` job (dorny/paths-filter or native `paths`) keeps PR CI proportional.
- **CODEOWNERS:** per folder (`/services/projects/ @org/team-projects`, `/infra/ @org/platform`, `/.claude/ @org/dlc-maintainers`, `/docs/adr/ @org/architects`). Changes to `.claude/**`, `.github/**` and `CODEOWNERS` need DLC-maintainer approval.
- **Versioning:** per-service tags `<svc>/vX.Y.Z` (ADR-0008). Platform packages are versioned independently and **consumed by version from GitHub Packages, never by project reference**, even inside the monorepo. This keeps the "no shared domain code" rule enforceable and mimics the multi-repo contract.
- **Isolation rules** (checked by CI): no `ProjectReference` across `services/*`, no file under `services/a` importing from `services/b`, and no DB credentials shared across services.

### Consequences

- Good, because one PR can update a producer's event schema and a consumer's contract test together, and DLC upgrades are immediate.
- Good, because Claude Code sees the full context (ADRs, contracts) in one checkout.
- Bad, because there is a coupling temptation. Mitigation: the CI isolation rules above plus NetArchTest.
- Bad, because the repo grows. Revisit when there are more than 3 owning teams or more than 10 services, or if a team needs different access controls.

### Confirmation

- `tools/dlc-check boundaries` runs on every PR.
