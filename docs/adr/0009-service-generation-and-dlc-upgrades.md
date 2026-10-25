---
status: Accepted
date: 2026-10-21 (accepted 2026-10-25)
deciders: Human approver (repo owner)
consulted: Principal Architect, Senior C#/.NET Engineer, DevSecOps Engineer
informed: All service teams
---

> **Amended by [ADR-0016](0016-repository-layout-and-instruction-files.md)** (2026-10-25): repository paths and instruction-file mechanism changed; the decision below is otherwise unchanged.

# 0009 — Service generation via a `dotnet new` template pack; DLC upgrades via versioned layers

## Context and Problem Statement

New services must start compliant: Clean Architecture, function-only data access, Flyway layout,
telemetry, tests, CI and Terraform stack. Existing services must also receive later DLC improvements
without hand-copying. How do we generate services, and how do upgrades reach them?

## Decision Drivers

- Native to the locked stack. Avoid adding a Python toolchain only for scaffolding.
- Generated output must build and pass tests in CI (the template itself is tested).
- An upgrade path for services that already exist.
- Monorepo (ADR-0010, pending Q1).

## Considered Options

1. **`dotnet new` template pack** (`Workshop.Templates`, NuGet on GitHub Packages).
2. **Copier** (Python, Jinja). It supports `copier update` with a 3-way merge.
3. Custom scripts (PowerShell/bash).

## Decision Outcome

Chosen option: **1 for generation, combined with "thin services" so upgrades rarely touch generated code.**

The DLC is split into **layers by how it reaches services**:

| Layer | Where it lives | How a service gets upgrades |
|---|---|---|
| AI rules: CLAUDE.md, `.claude/rules`, skills, agents, hooks | Repo root `.claude/` and `CLAUDE.md` | **Automatic**: shared by every service in the monorepo |
| CI/CD | Reusable workflows `.github/workflows/_reusable-*.yml` | **Automatic** on merge. Breaking changes ship as a new reusable workflow version that services switch to |
| Cross-cutting runtime code | Platform NuGet packages (ADR-0015) | **Dependabot** bumps the version. Renovate is an alternative |
| Terraform | `infra/modules/*` | The service stack picks up module changes. Breaking changes come with a module `CHANGELOG` and migration notes |
| Generated skeleton (projects, Program.cs, test projects, Dockerfile) | Template pack | **`upgrade-service` skill** (Phase 2): reads the service's `.dlc/version` (the template version it was generated from), diffs it against the current template output for the same parameters, and opens a PR applying the relevant hunks, with the template `CHANGELOG` as the guide |

- Generate: `dotnet new workshop-service --name Notifications --owner @org/team-x --port 8080`. It produces `services/notifications/**`, `.dlc/version`, catalog entry stub, workflow stub and Terraform stack stub.
- The template pack is tested in CI: it generates a throwaway service, then runs `dotnet build -warnaserror` + tests + `dlc-check`.
- The `new-service` skill wraps generation and also writes the ADR/catalog entries (ADR-0011).

### Consequences

- Good, because there is no extra runtime (`dotnet` is already required), and the template is testable.
- Good, because most upgrades (rules, CI, packages, modules) need **no** code merge.
- Bad, because `dotnet new` has no native update/3-way merge. The `upgrade-service` skill and a regenerate-and-diff approach cover the residue. If skeleton drift becomes painful, revisit Copier in a new ADR.

### Confirmation

- `dlc-check` reports each service's `.dlc/version` against the latest template version and warns when it is more than one minor version behind.
- Template CI job: generate a service, then build, test and `dlc-check` it.

## Pros and Cons of the Options

### Copier

- Good, because `copier update` is a real upgrade mechanism with conflict markers.
- Bad, because it adds Python and Jinja to a .NET/TS org, and its templates are not compiled or tested by `dotnet`.

### Scripts

- Bad, because they are hard to test, drift, and give no upgrade story.
