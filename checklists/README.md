# Checklists

Verification lists used during review and release. Items reference rule IDs instead of restating
rules (one home per rule: `docs/standards/`). Mark each item `[x]` with evidence (link, file:line,
command output) or `[ ] N/A — reason`. An unchecked item without a reason means "not verified".

| Checklist | When | Used by |
|---|---|---|
| [code-review.md](code-review.md) | Every PR | Author (CR-01) and reviewers |
| [security.md](security.md) | PRs touching auth, data, endpoints, messaging, infra | `security-reviewer`, author |
| [db-change.md](db-change.md) | Any change under `db/**` | `new-db-function`, `db-reviewer` |
| [production-readiness.md](production-readiness.md) | First prod release or major version | `production-readiness-review` |
| [release.md](release.md) | Every release | `release` |
