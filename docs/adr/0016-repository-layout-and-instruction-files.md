---
status: Proposed
date: 2026-10-25
deciders: Human approver (repo owner)
consulted: Principal Architect, DevSecOps Engineer
informed: All service teams
---

# 0016 — Repository layout by technology layer and instruction files (amends 0003, 0007, 0009, 0010)

## Context and Problem Statement

The Phase 2 instruction from the human approver asks for folder-scoped `CLAUDE.md` files in
`src/backend/`, `src/frontend/`, `db/` and `infra/`, detailed standards in `docs/standards/`
(referenced, not auto-loaded), a `scripts/validate-dlc` validator, and root `templates/` and
`checklists/` folders. The accepted `repository-structure.md` and ADRs 0003/0007/0009/0010 placed
each service under `services/<svc>/` with path-scoped `.claude/rules/` and a `.NET` `tools/dlc-check`.
The two layouts must be reconciled without silently editing Accepted ADRs.

## Decision Drivers

- Explicit human instruction (Phase 2).
- Context budget: Claude Code loads ancestor `CLAUDE.md` files at launch and subdirectory files only
  on demand. Standards that are not auto-loaded cost nothing until a skill or `CLAUDE.md` points to them.
- "No rule in two places": one home per rule, everything else links to it.
- The validator must run on a machine without the .NET SDK (the current state) and in CI.
- Per-service ownership and independent deploys (Microservices rules 1 and 7) must survive the layout change.

## Considered Options

1. Keep `services/<svc>/` (all layers of a service in one folder), plus `.claude/rules/`.
2. **Layer-first layout** (`src/backend`, `src/frontend`, `db`, `infra`), with per-service subfolders in each layer and ownership via CODEOWNERS path lists.

## Decision Outcome

Chosen option: **2**, as instructed.

```
CLAUDE.md                       root instructions (≤ 150 lines)
src/backend/CLAUDE.md           .NET context (≤ 120 lines, on demand)
src/backend/services/<svc>/     one .NET solution per service (Domain/Application/Infrastructure/Api, tests, contracts, Dockerfile, .dlc/version)
src/backend/platform/           Workshop.Platform.* NuGet packages (ADR-0015)
src/frontend/CLAUDE.md          React context
src/frontend/                   the web app (Vite); the BFF is a backend service: src/backend/services/web-bff
db/CLAUDE.md                    PostgreSQL context
db/<svc>/migrations|tests       Flyway V__/R__ scripts and pgTAP tests for that service's database
infra/CLAUDE.md                 Terraform context
infra/modules|bootstrap|live/<env>/<stack>|services/<svc>/envs/<env>
docs/standards/*.md             detailed standards, one home per rule (rule IDs such as SEC-03)
templates/  checklists/  scripts/
```

Amendments (the original ADRs stay Accepted; only the listed paths change):

| ADR | Was | Now |
|---|---|---|
| 0003 | `services/<svc>/db/migrations/` | `db/<svc>/migrations/`, pgTAP in `db/<svc>/tests/` |
| 0007 | `services/<svc>/infra/` | `infra/services/<svc>/` |
| 0009 | Template pack in `templates/content/workshop-service/`; `.NET` `tools/dlc-check` | Service template in `templates/service/` (`dotnet new` pack under `templates/service/dotnet/`, built in Phase 3 when the SDK is available); validator is `scripts/validate-dlc` (bash + gawk) |
| 0010 | Per-folder ownership `/services/<svc>/` | Ownership by path list per service (`src/backend/services/<svc>/`, `db/<svc>/`, `infra/services/<svc>/`) in CODEOWNERS; the catalog lists each service's paths |
| 0001 | `.claude/rules/` path-scoped rules | Folder `CLAUDE.md` + `docs/standards/` (no `.claude/rules/`) |
| 0002, 0003, 0008, 0009, 0010, 0011, 0015 | "Confirmation" sections cite `tools/dlc-check <check>` | Read as `scripts/validate-dlc`. Implemented in 0.2.0: sql, catalog, version, links, rule-ids, duplicates, conflicts, skills, agents, settings, adrs. Planned (Phase 3, plan item 3.06): `boundaries` (no cross-service references, platform consumed by version) and `github` (settings drift report) |

**Rule identity:** every rule has one ID and one home. `CORE-nn` rules live in the root `CLAUDE.md`.
All other rules live in `docs/standards/<area>.md` (`ARCH`, `BE`, `DB`, `FE`, `API`, `SEC`, `TEST`,
`OBS`, `AWS`, `CICD`, `CR`, `GIT`). Skills, subagents, checklists and folder `CLAUDE.md` files
reference IDs instead of restating rules. `scripts/validate-dlc` enforces this.

### Consequences

- Good, because instruction context stays small and each rule is edited in exactly one place.
- Good, because the validator runs anywhere Git Bash or Linux bash exists.
- Bad, because a service's code, database and infrastructure live in three folders. Mitigation: the
  catalog lists the paths, CODEOWNERS covers all three, and path filters in each service workflow include all three.

### Confirmation

- `scripts/validate-dlc` checks line budgets, single-definition of rule IDs, unknown ID references,
  duplicate and contradictory rule text, broken links, skill/agent frontmatter and required sections.
- CI workflow `dlc-validate` runs it on every PR.
