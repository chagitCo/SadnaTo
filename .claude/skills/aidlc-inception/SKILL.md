---
name: aidlc-inception
description: Run the AI-DLC Inception phase for a new intent (feature, service or change request) — intent, requirements, user stories, NFRs, data classification, threat model, domain model, logical design and units of work — writing each artifact from templates and stopping at the human gate.
when_to_use: The human describes something new to build or change and no intent folder exists yet, or asks to "start inception", "elaborate requirements" or "plan a new feature/service".
argument-hint: "[short intent description]"
---

# AI-DLC Inception

Implements process.md §3.1 (stages I1–I12). Output folder: `docs/intents/<YYYYMMDD>-<slug>/`.

## When to use

- New service, new feature in an existing service, or a change request with business impact.
- Not for a bug fix or a dependency patch: use the adaptive-depth table in process.md §6 and go to `new-feature`.

## Required inputs (ask if missing)

| Input | Why |
|---|---|
| Intent in one or two sentences, plus who asked for it | Anchors scope (I2) |
| Affected service(s) or "new service" | Decides depth; a new service also triggers `new-service` |
| Known constraints: deadline, budget, compliance, data residency | NFRs and ADRs |
| Stakeholder who approves the gate | Recorded in audit.md |

Ask these in one message. Apply CORE-04 for everything else: propose defaults and record them as assumptions.

## Steps

1. Read `docs/ai-dlc/state.md`, the service catalog and the ADR index (CORE-01). Stop if another phase is open and unapproved (CORE-03).
2. Create the intent folder and copy templates from `templates/inception/`.
3. **I2 intent.md** — problem, goal, non-goals, success metrics.
4. **I3 questions.md** — only security/cost/compatibility/architecture questions, each with a proposed default (CORE-04). Send them to the human; continue on defaults marked "pending".
5. **I4 requirements.md** — `FR-n` and `BR-n`, each testable and traced to the intent.
6. **I5 user-stories.md** — `US-n` with Given/When/Then acceptance criteria; every FR covered.
7. **I6 nfr.md** — measurable target and verification method per NFR.
8. **I7 data-classification.md** — every data element classified with retention and logging rule (SEC-11).
9. **I8 threat-model.md** — run the `threat-model` skill.
10. **I9 domain-model.md** — contexts, aggregates, invariants, state machines, events; check ARCH-01/ARCH-09 if boundaries move.
11. **I10 logical-design.md** — APIs (draft OpenAPI), events (draft schemas), DB objects, sequence diagrams, eventual-consistency notes (ARCH-08).
12. **I11 ADRs** — for each lasting decision run `new-adr`.
13. **I12 units-of-work.md** — `UOW-n`, each one PR-sized, with dependencies forming a DAG and a definition of done.
14. Update `state.md` and append to `audit.md` (CORE-02). Open a `docs/` PR and stop at the gate.

## Artifacts produced

`docs/intents/<id>/{intent,questions,requirements,user-stories,nfr,data-classification,threat-model,domain-model,logical-design,units-of-work}.md`,
new ADRs in `docs/adr/`, catalog row for a new service, updated `state.md` and `audit.md`.

## Checks to run

- `scripts/validate-dlc` (links, rule references, ADR index).
- Traceability: every FR → ≥ 1 story, every story → ≥ 1 AC, every High threat → mitigation + test ID.
- Every UOW references the stories it delivers.

## Definition of done

- All twelve artifacts exist, or a skipped stage is recorded in `state.md` with its reason (process.md §6).
- Open questions are listed with defaults; nothing is decided silently.
- `validate-dlc` passes; the PR is open; the session stops for human approval.
