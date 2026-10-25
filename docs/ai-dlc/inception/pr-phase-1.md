# PR: docs(ai-dlc): Phase 1 — Inception (process, ADRs 0001–0015, reference system)

Branch: `docs/ai-dlc-phase-1` → `main` · Type: documents only (no code)

## Summary

Phase 1 of the AI-DLC: environment inspection, the org lifecycle process, 15 ADRs (Proposed), the
repository structure, the reference system spec (Projects & Tasks + Notifications) and the plan for
phases 2–5.

## Decisions taken (all ADRs are Proposed until this PR is approved)

- AI-DLC classic 3-phase model, implemented natively in Claude Code. Guardrails enforced by hooks/CI (0001)
- Function-only data access: `api` schema, SECURITY DEFINER + pinned search_path, app role EXECUTE-only (0002)
- Flyway OSS (Apache-2.0) via Docker, timestamped `V__`, `R__` per object (0003)
- CloudFront → API GW REST (Regional) + WAF → VPC link **V2 → internal ALB** (no NLB) → ECS (0004)
- BFF with `__Host-` HttpOnly SameSite=Strict cookie (0005)
- `tenant_id` + composite FKs + RLS FORCE (0006)
- Layered Terraform states per env × stack, S3 `use_lockfile`, no DynamoDB, OIDC plan/apply roles (0007)
- GitHub Flow, build once/promote digest, per-service tags `<svc>/vX.Y.Z` (0008)
- `dotnet new` template pack + layered upgrades + `upgrade-service` skill (0009)
- Monorepo (0010). Two bounded contexts (Work Management, User Notifications) (0011)
- SNS→SQS + outbox + inbox idempotency, CloudEvents, PactNet message pacts (0012)
- Shared RDS PostgreSQL 18 instance per env, DB + roles per service (0013)
- Cognito client-credentials JWT + IAM resource policies for messaging (0014)
- Platform packages: Logging, Telemetry, Auth, ProblemDetails (+ Messaging pending) (0015)

## Assumptions pending confirmation

Q1–Q11 and A1–A9 in `docs/ai-dlc/inception/questions.md`.

## Open questions

Dev cost ceiling (NFR-11). Acceptance of residual risk T12 (removed member keeps old notifications).

## Risks

- Toolchain absent on the dev machine. Nothing has been built or tested yet.
- Flyway Docker image licence is unconfirmed (ADR-0003 open item).
- GitHub plan may not support required reviewers on private-repo environments (Q9).
- Region service availability is unverified if `il-central-1` is chosen (Q6).
- `aidlc-workflows` upstream moves quickly (v2.11.1). Our process is a deliberate fork.

## Evidence

Documents only. No build, test or scan applies. Verification sources are listed with dates in
`environment-report.md` §4–5.

## Gate

Approval of this PR = gate G1 (Inception → Phase 2). Record it in `docs/ai-dlc/audit.md`.
