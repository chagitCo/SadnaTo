# AI-DLC State

- **Updated:** 2026-10-25
- **DLC version:** 0.2.0
- **Current phase:** Phase 2 — AI-DLC process layer and Claude Code configuration: **complete, awaiting gate G-Phase2**
- **Status:** ⏸ **Waiting for human approval of the Phase 2 PR.** Do not start Phase 3 until approved (CORE-03).

## Done (Phase 2) — branch `feat/ai-dlc-phase-2`

- Root `CLAUDE.md` and folder `CLAUDE.md` for `src/backend`, `src/frontend`, `db`, `infra`.
- 12 standards in `docs/standards/` (162 rule IDs, one home each).
- 11 skills, 4 read-only reviewer subagents.
- `.claude/settings.json`: deny/ask/allow rules and 4 hooks with tests (guard: 97 cases, other hooks: 10). The guard is live in sessions (verified: it blocked `'terraform' apply`).
- Templates, checklists, PR/issue templates, CODEOWNERS, CONTRIBUTING, SECURITY, README.
- DLC versioning: `VERSION` 0.2.0, `CHANGELOG.md`, `upgrading.md`.
- `scripts/validate-dlc` (13 checks) + 18 self-tests + `dlc-validate` workflow.
- ADR-0016 (Proposed): layer-first layout; amended-by notes on ADR-0001/0003/0007/0009/0010.
- Phase 1 documents updated to the new layout (process, repository structure, catalog paths, plan, threat T16).

## Not done / deferred (explicit)

- `dotnet new` template pack, platform packages, reusable deploy workflows: Phase 3 (plan 3.01–3.03). They need the .NET SDK, which is not installed.
- `validate-dlc` checks `boundaries` and `github`: Phase 3 (plan 3.06).
- The `.cs` branch of the formatter hook is untested here (no .NET SDK); the skip paths are tested.
- Repository settings (squash-only ruleset, required `dlc-validate` check, secret scanning, private vulnerability reporting): human action, documented in plan 3.05.

## Open items

- Approve or amend ADR-0016 and the Phase 2 PR.
- P-1: install the remaining toolchain (environment-report §3); needed for Phase 3.
- NFR-11 dev cost ceiling (before Phase 4); T12 residual-risk acceptance (before Phase 5).
- Local folder rename `WorkshopSysten` → `SadnaTo` (human, while no session is open).

## Next

1. Human: review and **squash-merge** the Phase 2 PR (GIT-04); confirm ADR-0016.
2. Human: give the Phase 3 instruction.
