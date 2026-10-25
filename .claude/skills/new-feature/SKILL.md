---
name: new-feature
description: Deliver one unit of work in an existing service through the Construction loop — plan, implement in small increments, test, self-review with reviewer subagents, and open a PR with evidence.
when_to_use: A unit of work (UOW-n) is approved, or the human asks to implement a feature, fix a bug or make a change in an existing service.
argument-hint: "[UOW id or short description]"
---

# New feature (Construction loop C1–C5)

## When to use

- Any code change in an existing service, including bug fixes (adaptive depth, process.md §6).
- Use the specialised skills inside the loop: `new-api-endpoint`, `new-db-function`, `new-event`, `new-service-integration`.

## Required inputs (ask if missing)

| Input | Notes |
|---|---|
| Unit of work id or a clear description | For bugs: reproduction steps and expected behavior |
| Acceptance criteria | From `user-stories.md`; for bugs, the failing behavior becomes the first AC |
| Target service(s) | Must exist in the catalog |

## Steps

1. **Read** the UOW, its stories, the logical design and the standards for each area you will touch (CORE-01).
2. **Branch** `feat/<svc>-<slug>` or `fix/<svc>-<slug>` (GIT-02).
3. **C1 plan** — write `docs/intents/<id>/construction/<UOW>/plan.md` from [templates/feature-plan.md](../../../templates/feature-plan.md): files to change, tests to write first (one per AC, TEST-02), risks, rollback. For an L-size UOW, show the plan to the human before coding.
4. **C2/C3 implement in increments** — for each increment: write the failing test, make it pass, run the fast test suite, commit (GIT-03). Keep each increment small enough to review on its own.
5. Contract changes go first (API-01) and follow API-03 for compatibility.
6. **C3 test** — run all levels that apply (TEST-01, TEST-03); write `test-report.md` from [templates/construction/test-report.md](../../../templates/construction/test-report.md) with the exact commands and results (CORE-05).
7. **C4 self-review** — run `architecture-reviewer`, `security-reviewer`, `test-reviewer` (and `db-reviewer` if `db/**` changed); fix Critical/High findings (CR-03); record results in `review.md`.
8. **C5 PR** — fill `.github/pull_request_template.md` (CR-07); list deferred work (CORE-09).
9. Update `state.md` and `audit.md` (CORE-02).

## Artifacts produced

`plan.md`, code and tests, `test-report.md`, `review.md`, PR description, updated state/audit.

## Checks to run

- Service build and tests (commands in the folder `CLAUDE.md`), `dotnet format --verify-no-changes` / `npm run lint`.
- `scripts/validate-dlc`.
- [checklists/code-review.md](../../../checklists/code-review.md) and, for DB changes, [checklists/db-change.md](../../../checklists/db-change.md).

## Definition of done

process.md §7 (Definition of Done) is satisfied, every AC maps to a passing test, no Critical/High
finding is open, and the PR is ready for CODEOWNERS review.
