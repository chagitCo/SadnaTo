---
name: release
description: Prepare a SemVer release of one component — version from Conventional Commits, changelog, release PR/tag commands and the deployment checklist — leaving the tag push and production approval to a human.
when_to_use: The human asks to release, cut a version, or prepare a deployment of a service, platform package or the DLC itself.
argument-hint: "[component] [optional version]"
disable-model-invocation: true
---

# Release

User-invoked only (`disable-model-invocation: true`) because releases have side effects.

## When to use

- A component (`<svc>`, `platform/<package>`, or the DLC in `docs/ai-dlc/VERSION`) has merged changes to ship.
- For a first production release, run `production-readiness-review` first.

## Required inputs (ask if missing)

| Input | Notes |
|---|---|
| Component | Must be in the catalog or be a platform package / the DLC |
| Target version | Default: computed from commits since the last `<component>/v*` tag (GIT-06) |
| Target environments | staging (auto), prod (human approval, CICD-08) |

## Steps

1. Read the last tag for the component, the commits since then and the CHANGELOG (CORE-01).
2. Compute the version: breaking → major, `feat` → minor, `fix`/`perf` → patch. Show the reasoning; ask if commits are ambiguous.
3. Update `CHANGELOG.md` for the component (Keep a Changelog sections). For the DLC, also bump `docs/ai-dlc/VERSION` and state the upgrade action per entry ([upgrading.md](../../../docs/ai-dlc/upgrading.md)).
4. Verify on `main`: CI green for the commit to be tagged, migrations are expand/contract (DB-09), no open Critical/High findings.
5. Fill [checklists/release.md](../../../checklists/release.md) with evidence.
6. Open a `chore/release-<component>-vX.Y.Z` PR with the changelog/version changes.
7. After merge, give the human the exact commands (Claude does not push tags or approve deployments, CORE-06):
   `git tag -a <component>/vX.Y.Z -m "<component> vX.Y.Z" <sha>` and `git push origin <component>/vX.Y.Z`.
8. After the human's deployment, record the release in `audit.md` and update `state.md` (CORE-02).

## Artifacts produced

Changelog and version changes, release PR, filled release checklist, tag commands, audit row.

## Checks to run

CI status of the release commit, `scripts/validate-dlc`, release checklist.

## Definition of done

Release PR merged, tag command handed to the human, checklist complete with evidence, and the
production deployment approved by a human reviewer in the `prod` environment.
