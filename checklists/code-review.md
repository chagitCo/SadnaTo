# Code review checklist

## Scope and traceability
- [ ] PR links its unit of work / issue (GIT-07) and has a Conventional Commit title (GIT-03)
- [ ] One unit of work, reviewable size or justified (CR-06)
- [ ] Description complete per template (CR-07); deferred work listed (CORE-09)

## Design
- [ ] Layer dependencies respected (ARCH-06); business rules in Domain/Application (ARCH-07)
- [ ] No cross-service data access or shared domain code (ARCH-02, ARCH-05)
- [ ] Contract changes compatible within the major version (API-03) and committed first (API-01)
- [ ] No new infrastructure technology without an ADR (CORE-10)

## Code
- [ ] Data access only via `api` routines from Infrastructure (BE-02, BE-03)
- [ ] Async with cancellation, no blocking calls (BE-05); typed results for expected failures (BE-06)
- [ ] Configuration validated at start (BE-07); time and IDs injectable (BE-08)
- [ ] Structured logging, no sensitive data in logs (BE-10, SEC-11)
- [ ] Frontend: strict TypeScript, Zod-parsed responses, translated strings, logical CSS (FE-01, FE-05, FE-07, FE-08)

## Tests
- [ ] Every AC has a test (TEST-02); failure paths covered (TEST-03)
- [ ] Right level and real database for integration (TEST-01, TEST-04)
- [ ] No weakened, skipped or deleted tests (CORE-08); deterministic (TEST-10)

## Evidence
- [ ] Commands and results attached or CI green; nothing claimed without running it (CORE-05, CR-08)
- [ ] Reviewer subagents run; Critical/High fixed (CR-01, CR-03)
- [ ] `scripts/validate-dlc` passes
- [ ] `docs/ai-dlc/state.md` and `audit.md` updated when a stage completes (CORE-02)
