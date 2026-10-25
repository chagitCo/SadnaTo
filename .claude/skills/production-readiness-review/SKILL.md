---
name: production-readiness-review
description: Assess whether a service is ready for its first (or a major) production release using checklists/production-readiness.md — evidence for security, reliability, observability, operations and data protection — and produce a go/no-go report for the human.
when_to_use: Before the first production deployment of a service, before a major version, or when the human asks "is this ready for prod?".
argument-hint: "[service]"
---

# Production readiness review

## When to use

- Gate G2 (Construction → Operations) for a service's first production release or a major release.
- Not a replacement for per-PR review; it checks the service as a whole.

## Required inputs (ask if missing)

| Input | Notes |
|---|---|
| Service and version/tag candidate | e.g. `projects/v1.0.0` |
| Links to latest CI runs on `main` and staging deployment | Evidence for CORE-05 |
| SLO targets and on-call owner | From `docs/slo.md` |

## Steps

1. Read the service's catalog row, runbook, SLO doc, threat model and open issues (CORE-01).
2. Copy [checklists/production-readiness.md](../../../checklists/production-readiness.md) to `docs/intents/<id>/operations/production-readiness.md` (or the service docs folder).
3. For every item, record **evidence** (link, file path, command output) or mark it failed; never mark an item passed without evidence (CORE-05, CR-08).
4. Run the read-only checks you can: `scripts/validate-dlc`, Terraform `plan` output review from CI, alarm and dashboard definitions in the stack, runbook coverage of every alarm (OBS-07).
5. Run `security-reviewer` on the service as a whole; include open Medium+ findings.
6. Summarize: **Go**, **Go with conditions** (each with owner and date), or **No-go** with blocking items.
7. Append the result to `audit.md` and update `state.md` (CORE-02). Stop for the human decision (CORE-03).

## Artifacts produced

Filled readiness checklist with evidence, go/no-go summary, audit row.

## Checks to run

Every checklist item; `scripts/validate-dlc`; CI status of `main`.

## Definition of done

Each checklist item has evidence or an explicit failure, blocking items are clear, and the human has
the information to approve or reject the release. Claude does not deploy (CORE-06).
