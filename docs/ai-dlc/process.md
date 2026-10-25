# AI-DLC Process (organization standard)

Status: **Proposed** (Phase 1). Basis: [MISSION.md](MISSION.md), [ADR-0001](../adr/0001-adopt-ai-dlc.md).

## 1. Principles

1. **Artifacts over chat.** Every decision, requirement and plan is a file in the repo. Chat is transient.
2. **AI proposes, humans approve.** Each phase and each irreversible action has a human gate.
3. **Ask only what matters.** Questions are asked only for security, cost, compatibility or architecture. Otherwise apply a documented default and record it as an assumption.
4. **Evidence or it didn't happen.** A check counts as passed only if its command ran and its output was seen. Otherwise the artifact says "not run" and gives the exact command.
5. **Adaptive depth.** The size of the change decides which stages run (§6).

## 2. Roles

| Role | Who | Responsibility |
|---|---|---|
| **Approver** | Human (product/tech lead; for prod, a member of the `prod` reviewers group) | Approves phase gates, ADRs and irreversible actions |
| **Driver** | Engineer running the Claude Code session | Starts stages, answers questions, opens PRs |
| **AI** | Claude Code (main agent + subagents) | Produces artifacts and code, runs local checks, never performs gated actions |
| **Reviewers** | CODEOWNERS, plus subagents `security-reviewer` and `architecture-reviewer` | PR review. Subagent findings are advisory, and CODEOWNERS approval is binding |

## 3. Phases and stages

Notation: **Artifact** is the file path the stage must produce. **Template** is in
`docs/ai-dlc/templates/` (created in Phase 2; required sections are listed here). The gate type is
**H** (human approval required) or **A** (automatic, CI must be green).

### 3.1 Inception — *what* and *why*

Scope: one **intent** (a feature, a new service, a change request). The artifacts live in
`docs/intents/<YYYYMMDD>-<slug>/` (for the reference system: `docs/ai-dlc/inception/`).

| # | Stage | Inputs | Artifact | Template (required sections) | Approver | Exit criteria |
|---|---|---|---|---|---|---|
| I1 | Workspace detection | Repo, toolchain | `environment-report.md` | Repo state, toolchain table, missing prereqs + commands, conventions verified + sources | — (A) | Every row filled. Unknowns are listed explicitly |
| I2 | Intent | Request from the human | `intent.md` | Problem, goal, non-goals, success metrics, stakeholders, constraints | Approver (H) | Approver signs off on the scope |
| I3 | Questions | Intent, I1 | `questions.md` | Numbered Q + default + impact. Assumptions table | Approver answers | Every Q answered or default accepted |
| I4 | Requirements | I2, I3 | `requirements.md` | Functional reqs (IDs `FR-n`), business rules (`BR-n`), out of scope | Approver (H) | Each FR is testable and traced to the intent |
| I5 | User stories | I4 | `user-stories.md` | `US-n`: As/I want/So that. Acceptance criteria in Given/When/Then. FR trace | Approver (H) | Every FR is covered by ≥ 1 story. Every AC is testable |
| I6 | NFRs | I4 | `nfr.md` | Performance, availability/SLO, scalability, security, privacy, a11y, i18n, observability, cost. Each has a measurable target and a verification method | Approver (H) | Every NFR has a target and a verification method |
| I7 | Data classification | I4, I5 | `data-classification.md` | Each data element: class (Public/Internal/Confidential/Restricted), PII flag, retention, residency, encryption, logging rule | Approver + Security (H) | No unclassified field. Logging rules defined |
| I8 | Threat model | I5–I7 | `threat-model.md` | DFD with trust boundaries, STRIDE table (threat, asset, mitigation, test ID, residual risk) | Security (H) | Each High threat has a mitigation and a test |
| I9 | Domain model | I4, I5 | `domain-model.md` | Bounded contexts, aggregates, invariants, state machines, events, ubiquitous language | Architect (H) | Invariants map to BR-n. Events are named and versioned |
| I10 | Logical design | I6–I9 | `logical-design.md` | Services touched, APIs (draft OpenAPI), events (draft schema), DB objects (tables/functions), sequence diagrams, cross-service consistency notes | Architect (H) | Eventual-consistency notes for every cross-service use case |
| I11 | ADRs | Any decision with lasting impact | `docs/adr/NNNN-*.md` | MADR (`docs/adr/0000-template.md`) | Approver (H) | Status Accepted, or explicitly Proposed with a pending question |
| I12 | Units of work | I5, I10 | `units-of-work.md` | `UOW-n`: scope, stories, service, dependencies, estimate (S/M/L), definition of done | Approver (H) | Each UOW is ≤ 1 PR-sized deliverable or split. The DAG has no cycles |

**Inception gate (H):** the approver approves the whole intent folder in a PR. This is recorded in `audit.md`.

### 3.2 Construction — *how*, per unit of work

Each `UOW-n` runs this loop on a branch `feat/<svc>-<uow-slug>`:

| # | Stage | Inputs | Artifact | Approver | Exit criteria |
|---|---|---|---|---|---|
| C1 | Plan | UOW, logical design | `docs/intents/<id>/construction/UOW-n/plan.md`: files to change, functions, endpoints, tests to write first, risks, rollback | Driver (H for L-size UOWs) | Each AC has a planned test |
| C2 | Implement | Plan | Code and SQL under `services/<svc>/**` | — | Builds with `-warnaserror`. No TODO/stub in delivered code |
| C3 | Test | Plan, code | Tests (unit, pgTAP, integration, contract, arch, frontend, e2e as applicable), plus `test-report.md` with the commands run and their results | — (A) | All pass locally. Coverage gate met (≥ 80% line in Domain/Application). No skipped tests without a linked issue |
| C4 | Self-review | Diff | `review.md`: checklist results from the `security-reviewer` and `architecture-reviewer` subagents, plus fixes applied | — | No unresolved High/Critical findings |
| C5 | PR | All the above | GitHub PR from the template: links UOW, ACs → tests, evidence, deferred work | CODEOWNERS (H) + CI (A) | Required checks green, approvals given, squash-merged |

### 3.3 Operations — run it

| # | Stage | Inputs | Artifact | Approver | Exit criteria |
|---|---|---|---|---|---|
| O1 | IaC plan | Service and platform stacks | `terraform plan` output attached to the PR (CI, plan role) + `docs/intents/<id>/operations/iac-plan.md` summary (adds/changes/destroys, cost delta) | Platform owner (H) | No unexpected destroys. Scans green |
| O2 | Deploy | Merged `main` / tag | GitHub deployment record. Flyway task log. ECS deployment events | dev/staging: A. **prod: H (Environment reviewers)** | Deployment circuit breaker not triggered |
| O3 | Smoke test | Deployed env | CI smoke job output (health, one authenticated read, one write in a test tenant) | — (A) | All smoke checks pass. Otherwise auto rollback |
| O4 | Observe | Dashboards, alarms, SLOs | `services/<svc>/docs/slo.md` + dashboards/alarms in Terraform | Service owner (H at first release) | Alarms wired to on-call. SLO burn-rate alerts defined |
| O5 | Runbook | All the above | `services/<svc>/docs/runbook.md`: deploy, rollback, DLQ redrive, secret rotation, DB restore, common alerts → actions | Service owner (H) | Each alarm has a runbook entry |

## 4. Human approval gates

| Gate | When | Who | How it is recorded |
|---|---|---|---|
| G1 Inception → Construction | All Inception artifacts merged | Approver | PR approval + `audit.md` row |
| G2 Construction → Operations | UOWs for the release merged, CI green | Service owner | Release PR / tag + `audit.md` row |
| G3 Each irreversible action | `terraform apply`, prod deploy, data migration on prod, DB restore, secret rotation, deleting resources, repo setting changes | A human executes it. Claude only prepares commands/plans | Environment approval in GitHub + `audit.md` row |
| G4 ADR acceptance | Any ADR moving to Accepted | Approver | ADR status change in a PR + `audit.md` |

**Mechanical enforcement** (Phase 2): `.claude/settings.json` deny rules and a `PreToolUse` hook
block `terraform apply|destroy`, `git push` to `main`, `git push --force`, `aws * create|delete|put*`,
reading `.env`/secrets, and `rm -rf` outside the scratch dirs. Branch rulesets protect `main`. The
`prod` Environment requires reviewers.

## 5. State, audit and resuming work

| File | Purpose | Rules |
|---|---|---|
| `docs/ai-dlc/state.md` | Current phase, stage, done, next, open questions, blockers | **Overwritten** at the end of every stage. Kept ≤ 100 lines |
| `docs/ai-dlc/audit.md` | Append-only decision log: date, phase, decision, reason, approved by, evidence link | **Append only.** Never edit past rows. A correction is a new row |
| `docs/ai-dlc/plan.md` | Checklist of phases/UOWs with dependencies | Checkboxes updated when items merge |
| `docs/intents/<id>/**` | Per-intent artifacts | Immutable after the gate, except through a change request |

**Resuming in a new session:** the root `CLAUDE.md` (Phase 2) instructs Claude to, at session start,
(1) read `docs/ai-dlc/state.md`, (2) read the last 20 rows of `audit.md`, (3) read the artifacts that
`state.md` names under "Next", and (4) summarize the position and ask before continuing. A
`SessionStart` hook prints the `state.md` header, so this happens even if instructions are skipped.

## 6. Adaptive depth

| Change type | Stages that run |
|---|---|
| New service | All Inception stages + ADR + catalog entry. Full Construction and Operations |
| New feature in an existing service | I2, I4–I8 (delta only), I10, I12. Construction. O1–O3 |
| Bug fix | Short `intent.md` (repro + expected), C1–C5 with a failing test first. O2–O3 |
| Dependency/security patch | C2–C5. O2–O3 |
| DLC change (rules, skills, templates) | `intent.md` + ADR if it changes a locked decision. C2–C5 with `dlc-check` |

Skipping a stage is recorded in `state.md` with its reason.

## 7. Definition of Done (every UOW)

- Acceptance criteria → tests mapped in the PR description. All tests pass in CI.
- No new High/Critical findings in SAST, dependency, secret, container or IaC scans.
- Logs are structured, with no Restricted/Confidential data. Traces cover the new endpoints and handlers.
- OpenAPI/event schemas updated and contract tests green.
- Docs updated: catalog (if relevant), runbook entries for new alarms, CHANGELOG.
- `state.md` and `audit.md` updated.
