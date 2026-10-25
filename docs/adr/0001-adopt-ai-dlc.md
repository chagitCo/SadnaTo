---
status: Accepted
date: 2026-10-21 (accepted 2026-10-25)
deciders: Human approver (repo owner)
consulted: Principal Architect, DevSecOps Engineer (Claude Code roles)
informed: All service teams
---

# 0001 — Adopt AI-DLC, implemented natively in Claude Code

## Context and Problem Statement

The organization wants Claude Code to produce secure, observable, tested services *consistently*.
Ad-hoc prompting gives inconsistent results and leaves no trail of decisions. AWS publishes the
AI-Driven Development Lifecycle (AI-DLC) methodology and an open-source rule set
(`awslabs/aidlc-workflows`). Which parts do we adopt, and how?

## Decision Drivers

- MISSION locks the phases **Inception → Construction → Operations**, persisted artifacts, human approval gates and question-driven elaboration.
- MISSION locks Claude Code as the AI tool, configured via CLAUDE.md, skills, subagents and settings/hooks.
- A stack that is already decided (.NET 10, PostgreSQL functions, Terraform, AWS), so generic rules must be specialized.
- Auditability: every decision must be traceable to a human approval.
- Upstream churn: `aidlc-workflows` moved from v1 (3 phases) to **v2.11.1: 5 phases / 33 stages / 11 profiles** (verified 2026-10-21).

## Considered Options

1. Install the upstream `aidlc-workflows` v2 harness for Claude Code (`aidlc config --harness claude`).
2. Implement the AI-DLC **classic 3-phase model** natively with Claude Code primitives, specialized to our stack.
3. No formal lifecycle. Use CLAUDE.md coding rules only.

## Decision Outcome

Chosen option: **2**. It satisfies the locked phases, uses only first-party Claude Code mechanisms,
and lets us encode stack-specific rules (no EF Core, Flyway naming, tenancy, edge topology) that a
generic rule set cannot.

**What we take from AWS AI-DLC**

- The three phases and the "AI proposes, human approves" loop at each phase gate.
- Persisted artifacts in the repo as the single source of truth. A state file and an append-only audit log let any new session resume work.
- Question-driven elaboration: questions are asked only when needed, with a proposed default, and recorded.
- Adaptive depth: a bug fix skips Inception stages that do not apply (see `docs/ai-dlc/process.md` §6).
- Units of work as the bridge from Inception to Construction.

**What we change, and why**

| Change | Why |
|---|---|
| Artifact root `docs/ai-dlc/` instead of `aidlc-docs/` | Keeps all documentation under `docs/` next to `docs/adr/` and `docs/services/`. |
| 3 phases, not v2's 5 phases / 33 stages | MISSION lock. Fewer gates suit a small org. Stages are defined in `process.md`. |
| Mandatory **data classification** and **STRIDE threat model** in Inception | Security is a first-class requirement here. Upstream treats it as an optional extension. |
| Enforcement by **hooks and CI**, not prose rules alone | The Claude Code docs say CLAUDE.md is context, not enforcement. Guardrails such as no `terraform apply` and no push to `main` must be blocked mechanically. |
| Stack-specific skills/subagents (`new-service`, `db-function`, `security-reviewer`, …) | Gives consistent output on the locked stack. |
| Operations stops at "prepared" for irreversible actions | MISSION global rule 6: a human runs `terraform apply` and prod deploys. |

### Consequences

- Good, because the process is versioned with the code and reviewed by PR like any other change.
- Good, because guardrails are enforced, not merely suggested.
- Bad, because we must track upstream AI-DLC ideas ourselves. Mitigation: review upstream every 6 months and record adopted changes in a new ADR.
- Bad, because the process artifacts add overhead to small changes. Mitigation: adaptive depth.

### Confirmation

- `tools/dlc-check` (Phase 2) validates that `state.md` and `audit.md` exist and are updated in every phase PR, and that every ADR has a valid status.
- The CI job `dlc-validate` fails a PR that changes `services/**` without a linked unit of work.

## More Information

- https://github.com/awslabs/aidlc-workflows (v2.11.1, read 2026-10-21)
- https://aws.amazon.com/blogs/devops/building-with-ai-dlc-using-amazon-q-developer
- Revisit if upstream ships a stable Claude Code harness that supports org-specific rule overlays.
