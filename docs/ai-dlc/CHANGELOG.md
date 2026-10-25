# AI-DLC changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning: SemVer for the DLC
itself ([VERSION](VERSION)). The DLC stays below 1.0.0 until both reference services are built with
it (Phase 5). Every entry carries an **upgrade action** for services generated from an earlier DLC
version — `none`, `automatic` (arrives by merge, no service change) or `manual` (steps in
[upgrading.md](upgrading.md)).

- **MAJOR**: a change that requires manual changes in existing services *and* breaks them if not applied.
- **MINOR**: new rules, skills, templates or checks; services may need manual follow-up.
- **PATCH**: clarifications and fixes with no behavior change for services.

## [Unreleased]

## [0.2.0] — 2026-10-25

Phase 2: process layer and Claude Code configuration.

### Added
- Root `CLAUDE.md` (mission, workflow, CORE-01…13, index) and folder `CLAUDE.md` for `src/backend`, `src/frontend`, `db`, `infra`. — upgrade action: automatic
- Twelve standards in `docs/standards/` with rule IDs (ARCH, BE, DB, FE, API, SEC, TEST, OBS, AWS, CICD, CR, GIT). — upgrade action: automatic
- Skills: `aidlc-inception`, `new-service`, `new-feature`, `new-api-endpoint`, `new-db-function`, `new-event`, `new-service-integration`, `new-adr`, `threat-model`, `production-readiness-review`, `release`. — upgrade action: automatic
- Read-only reviewer subagents: `security-reviewer`, `architecture-reviewer`, `test-reviewer`, `db-reviewer`. — upgrade action: automatic
- `.claude/settings.json` deny/ask/allow rules and hooks (PreToolUse guard, PostToolUse formatter, Stop state reminder, SessionStart banner) with tests. — upgrade action: automatic
- Templates (`templates/`), checklists (`checklists/`), PR and issue templates, CODEOWNERS, CONTRIBUTING, SECURITY. — upgrade action: automatic
- `scripts/validate-dlc` with self-tests and the `dlc-validate` workflow. — upgrade action: automatic
- DLC versioning: `VERSION`, this changelog, `upgrading.md`. — upgrade action: none
- ADR-0016: layer-first repository layout and instruction-file model (amends ADR-0001/0003/0007/0009/0010 paths). — upgrade action: none (no service exists yet)

### Changed
- ADR template moved from `docs/adr/0000-template.md` to `templates/adr.md`. — upgrade action: none

## [0.1.0] — 2026-10-21

Phase 1: Inception.

### Added
- MISSION, process, repository structure, environment report, questions, ADR-0001…0015, reference-service specification, service catalog, plan, state and audit logs. — upgrade action: none
