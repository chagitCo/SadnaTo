# AI-DLC State

- **Updated:** 2026-10-21
- **Current phase:** Phase 1 — Inception (organization DLC + reference system)
- **Status:** ⏸ **Awaiting human approval (gate G1).** Do **not** start Phase 2.

## Done (Phase 1)

- MISSION saved verbatim → `docs/ai-dlc/MISSION.md`
- Environment report → `docs/ai-dlc/inception/environment-report.md`
- Questions + defaults + assumptions → `docs/ai-dlc/inception/questions.md`
- ADRs 0001–0015 (all **Proposed**) + template + index → `docs/adr/`
- Process → `docs/ai-dlc/process.md`
- Repository structure → `docs/ai-dlc/repository-structure.md`
- Reference system (stories, ACs, NFRs, data classification, STRIDE) → `docs/ai-dlc/inception/reference-service.md`
- Service catalog → `docs/services/catalog.md`
- Plan for phases 2–5 → `docs/ai-dlc/plan.md`

## Not done / blocked

- Git 2.55.0.5 and gh 2.102.1 installed (by Claude at the human's request). Phase 1 is committed locally on `docs/ai-dlc-phase-1`. **Not pushed, no remote configured, PR not opened.**
- The rest of the toolchain (dotnet, node, docker, terraform, …) is still missing. No build, test or scan was run in Phase 1 (documents only).

## Next (after approval)

1. Human: add the remote, push `main` and `docs/ai-dlc-phase-1`, open the PR (commands in the session summary). Review and merge.
2. Human: remaining prerequisites P-1 and P-3 in `plan.md` (install the rest of the toolchain, answer Q1–Q11).
3. Claude: start Phase 2 (`plan.md` items 2.1–2.15) only after explicit approval.

## Open questions

Q1–Q11 in `docs/ai-dlc/inception/questions.md`, all running on the proposed defaults
(**PENDING CONFIRMATION**). Also: NFR-11 dev cost ceiling, and acceptance of residual risk T12.
