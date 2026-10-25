# AI-DLC State

- **Updated:** 2026-10-25
- **DLC version:** 0.2.0
- **Current phase:** Phase 2 — AI-DLC process layer and Claude Code configuration: **complete, gate passed** (PR #3 merged 2026-10-25)
- **Status:** ⏸ **Waiting for the Phase 3 instruction.** Phase 3 starts only when the human explicitly asks (CORE-03).

## Done (Phase 2)

- All Phase 2 artifacts on `main` (chagitCo/SadnaTo PR #3, merge commit `7f23fb9`).
- ADR-0016 **Accepted**: layer-first layout, instruction-file model, `scripts/validate-dlc`.
- CI `dlc-validate` green on the PR and on `main` (GitHub-hosted ubuntu-24.04): the validator, its self-tests and hook tests also pass on Linux.
- Claude Code config is active for every session in this repo: deny/ask rules, guard, formatter, Stop reminder, SessionStart banner.

## Open items

- P-1: install the remaining toolchain (.NET 10 SDK, Node 24, Docker or Rancher Desktop, Terraform, AWS CLI, psql, tflint, trivy); environment-report §3. Phase 3 needs at least the .NET SDK and a container runtime.
- Repository settings (human, plan 3.05): ruleset on `main` with **squash-only merges** (PR #1–#3 were merged with merge commits) and the required check `Validate AI-DLC rules, links and config`; secret scanning with push protection; private vulnerability reporting; Dependabot alerts.
- NFR-11 dev cost ceiling (before Phase 4); T12 residual-risk acceptance (before Phase 5).
- Local folder rename `WorkshopSysten` → `SadnaTo` (human, while no session is open).

## Next

1. Human: give the Phase 3 instruction (Projects & Tasks service; plan items 3.01–3.12).
2. Claude: Phase 3 on a `feat/` branch, stopping at the Phase 3 gate.
