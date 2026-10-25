# Upgrading a service to a newer DLC version

A service records the DLC version it was generated from, or last upgraded to, in
`src/backend/services/<svc>/.dlc/version` (one line, SemVer). The current DLC version is
[VERSION](VERSION). This page explains how a service catches up. It applies ADR-0009 (layered
upgrades) with the paths of ADR-0016.

## What reaches a service without any work

Most of the DLC is shared by every service in the monorepo and applies as soon as it is merged to
`main`. These are the `automatic` entries in the [changelog](CHANGELOG.md):

| Layer | Location | How it applies |
|---|---|---|
| Instructions and rules | `CLAUDE.md`, folder `CLAUDE.md`, `docs/standards/` | Read by Claude in every session |
| Skills, subagents, hooks, permissions | `.claude/` | Loaded by Claude Code from the repo root |
| Templates and checklists | `templates/`, `checklists/` | Used for the next artifact |
| CI | reusable workflows `.github/workflows/_reusable-*.yml` | Next pipeline run (a breaking change ships as a new reusable workflow version) |
| Validation | `scripts/validate-dlc` | Next CI run |

## What needs a change in the service (manual entries)

| Layer | How it is upgraded |
|---|---|
| Platform packages (`Workshop.Platform.*`) | Dependabot PR bumping the version in the service's `Directory.Packages.props`; follow the package CHANGELOG for breaking changes |
| Terraform modules (`infra/modules/*`) | Update the service stack to the new module inputs; plan reviewed by a human; applied through the pipeline |
| Generated skeleton (Program.cs, test projects, Dockerfile, workflow) | Steps in the changelog entry; from Phase 3, the generator can also regenerate a reference copy to diff (below) |
| New mandatory artifacts (e.g. a new doc a standard requires) | Created by following the changelog entry |

## Procedure

1. **Find the gap.** Compare `.dlc/version` with `docs/ai-dlc/VERSION`. `scripts/validate-dlc` lists every service and its version, and warns when a service is more than one minor version behind.
2. **Read the changelog** entries after the service's version. Collect all entries marked `manual`.
3. **Branch** `chore/<svc>-dlc-<new-version>` (GIT-02).
4. **Apply each manual step** in changelog order. For skeleton changes, once the `dotnet new` pack exists (Phase 3):
   - generate a reference copy with the service's original parameters into a scratch folder: `dotnet new workshop-service -n <Svc> -o <scratch>/<svc>`,
   - diff it against the service and port only the DLC-owned parts (hosting, telemetry, test scaffolding, Dockerfile, workflow); domain code is never overwritten.
5. **Bump** `.dlc/version` to the new version.
6. **Verify**: service build and all tests, `scripts/validate-dlc`, Terraform `plan` if modules changed (CORE-05).
7. **PR** with title `chore(<svc>): upgrade to DLC <version>`, listing each applied entry and anything deferred (CORE-09).

A service can skip versions. Apply manual entries cumulatively, oldest first.

## Rules for DLC maintainers

- Every changelog entry states its upgrade action. `manual` entries include exact steps and how to verify them.
- A MAJOR DLC version is released only with migration steps tested on at least one reference service.
- Prefer changes that apply automatically (instructions, reusable workflows, platform packages) over changes that touch generated code in every service.

## Current status

No service exists yet, so there is nothing to upgrade. The first service (`projects`, Phase 3)
will be stamped with the DLC version current at generation.
