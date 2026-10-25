# Git workflow standard (GIT)

Scope: branches, commits, pull requests and tags. Sources: MISSION (Source control), ADR-0008, 0010.

## Rules

- **GIT-01** `main` is protected by a ruleset; changes reach it only through pull requests (pushes are covered by CORE-06).
- **GIT-02** Branches are short-lived and named `feat/`, `fix/`, `chore/` or `docs/` followed by a kebab-case slug (`feat/projects-assign-task`).
- **GIT-03** Commit messages and PR titles follow Conventional Commits with the service or area as scope: `feat(projects): assign task`, `chore(infra): pin aws provider`.
- **GIT-04** Pull requests are squash-merged; the PR title becomes the commit on `main`.
- **GIT-05** Feature branches are brought up to date with `main` (rebase or merge) before the final review.
- **GIT-06** Releases are tagged per component as `<component>/vX.Y.Z` (SemVer), created by the release workflow from Conventional Commits.
- **GIT-07** Every PR links its unit of work, issue or intent folder.
- **GIT-08** Generated files, build outputs and personal settings (`CLAUDE.local.md`, `.claude/settings.local.json`) are excluded by `.gitignore` (secrets: CORE-07).

## Commit types (reference)

| Type | Use for | Version bump |
|---|---|---|
| `feat` | New behavior | minor |
| `fix` | Bug fix | patch |
| `feat!` / `BREAKING CHANGE:` footer | Incompatible change | major |
| `docs`, `test`, `refactor`, `perf`, `build`, `ci`, `chore` | No behavior change for users | none (patch for `perf`) |

Contributor-facing summary: [CONTRIBUTING.md](../../CONTRIBUTING.md).
