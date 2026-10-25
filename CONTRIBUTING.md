# Contributing

This repository is built with an AI-Driven Development Lifecycle. Humans and Claude Code follow the
same process and rules. This page is the practical guide; the rules themselves live in
[docs/standards/](docs/standards/README.md) (each has an ID) and in the root [CLAUDE.md](CLAUDE.md).

## Before you start

1. Read [docs/ai-dlc/process.md](docs/ai-dlc/process.md) and [docs/ai-dlc/state.md](docs/ai-dlc/state.md).
2. Install the toolchain listed in [the environment report](docs/ai-dlc/inception/environment-report.md).
3. New work starts from an issue: **Intent** (feature/service), **Bug report** or **Change request**.

## Branching, commits and pull requests

| Topic | Rule IDs | In short |
|---|---|---|
| Branch names | GIT-02 | `feat/`, `fix/`, `chore/`, `docs/` + kebab-case slug |
| Commit messages and PR titles | GIT-03 | Conventional Commits with scope: `feat(projects): assign task` |
| Merging | GIT-01, GIT-04 | PR only, squash merge |
| Keeping up to date | GIT-05 | Rebase or merge `main` before final review |
| Linking work | GIT-07 | Every PR links its unit of work or issue |
| Releases | GIT-06 | Tags `<component>/vX.Y.Z`, created through the `release` skill |

Full details: [git-workflow standard](docs/standards/git-workflow.md).

## Pull request expectations

- Fill in the [PR template](.github/pull_request_template.md): AC-to-test map, evidence, self-review, deferred work.
- Run the relevant [checklists](checklists/README.md).
- Approval rules and severity levels: [code-review standard](docs/standards/code-review.md).
- CI must be green, including `dlc-validate`.

## Working with Claude Code

- Claude reads `CLAUDE.md` automatically; folder `CLAUDE.md` files load when it works in that folder.
- Use the skills in `.claude/skills/` (`/new-feature`, `/new-api-endpoint`, `/new-db-function`, `/new-event`, …).
- Ask the reviewer subagents (`security-reviewer`, `architecture-reviewer`, `test-reviewer`, `db-reviewer`) before requesting human review.
- `.claude/settings.json` blocks dangerous commands; see [the hooks README](.claude/hooks/README.md). Personal overrides go in `.claude/settings.local.json` (gitignored), not in the shared file.

## Changing the DLC itself

Changes to `CLAUDE.md`, `.claude/**`, `docs/standards/**`, `templates/**`, `checklists/**` or
`scripts/**` are DLC changes: run `scripts/validate-dlc`, add an entry to
[docs/ai-dlc/CHANGELOG.md](docs/ai-dlc/CHANGELOG.md) with its upgrade action, and get a DLC
maintainer's approval.
