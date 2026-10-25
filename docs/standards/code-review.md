# Code review standard (CR)

Scope: every pull request, human- or AI-authored. Sources: process.md §3.2 (C4/C5), ADR-0008.

## Rules

- **CR-01** Before requesting review, the author runs the relevant reviewer subagents (`security-reviewer`, `architecture-reviewer`, `test-reviewer`, `db-reviewer` for `db/**`) and records the findings and fixes in the PR.
- **CR-02** Findings use this severity scale: **Critical** — exploitable security flaw, data loss or cross-tenant exposure; **High** — broken requirement, missing authorization or tenant check, contract break, missing test for a business rule; **Medium** — maintainability or robustness problem likely to cause defects; **Low** — style, naming, minor clarity.
- **CR-03** Critical and High findings block merge until fixed; Medium findings are fixed or tracked in an issue linked from the PR; Low findings are at the author's discretion.
- **CR-04** Each finding cites the file and line, the rule ID it violates (if any), the risk, and a concrete fix.
- **CR-05** At least one CODEOWNER of every touched path approves; changes to `.claude/**`, `.github/**`, `CODEOWNERS`, `docs/standards/**` or `docs/adr/**` also need a DLC maintainer.
- **CR-06** A PR covers one unit of work and stays reviewable (guideline: under ~400 changed lines excluding generated files); larger changes are split or justified in the description.
- **CR-07** The PR description follows the template: unit of work, acceptance-criteria-to-test map, commands run with results, deferred work, and checklists used.
- **CR-08** Reviewers verify evidence rather than trust it: claims of passing checks must match CI results or attached output (CORE-05).

## Review focus by area (reference)

| Area | Checklist |
|---|---|
| Any change | [code-review](../../checklists/code-review.md) |
| Security-relevant change | [security](../../checklists/security.md) |
| Database change | [db-change](../../checklists/db-change.md) |
| First production release of a service | [production-readiness](../../checklists/production-readiness.md) |
| Release | [release](../../checklists/release.md) |
