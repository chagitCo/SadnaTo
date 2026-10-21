---
status: Proposed
date: 2026-10-21
deciders: Human approver (repo owner)
consulted: DevSecOps Engineer, QA Automation Engineer
informed: All service teams
---

# 0008 — GitHub Flow, environments and release strategy

## Context and Problem Statement

MISSION locks GitHub Flow (protected `main`, short-lived `feat/ fix/ chore/ docs/` branches),
Conventional Commits, PR + required checks + CODEOWNERS review, squash merge, SemVer tags
`vX.Y.Z`, GitHub Actions with OIDC, and Environments `dev`/`staging`/`prod` (prod with manual
approval). In a monorepo (ADR-0010) several services release independently.

## Decision Drivers

- Independent deploys per service (Microservices rule 7).
- Build once and promote the same artifact.
- A human approves prod.
- Traceability from commit to deployed version.

## Decision Outcome

1. **Branches:** `main` is protected with a ruleset: PRs required, 1+ CODEOWNERS approval, required status checks, linear history (squash only), no force-push, no deletion, and stale approvals dismissed on push. Branch names follow `^(feat|fix|chore|docs)/[a-z0-9._-]+$`, and the AI-DLC phase branches use `docs/` or `feat/`.
2. **Commits:** Conventional Commits with **scope = service or area** (`feat(projects): …`, `chore(infra): …`). The PR title is checked by CI and becomes the squash commit.
3. **Tags (deviation from MISSION `vX.Y.Z`):** **per-service tags `<service>/vX.Y.Z`** (for example `projects/v1.2.0`), because one monorepo hosts several independently versioned services. Platform packages use `platform/<package>/vX.Y.Z`. Version bumps come from Conventional Commits filtered by path (release-please in monorepo mode, decided in Phase 2).
4. **Pipeline per service** (`.github/workflows/svc-<name>.yml`, calling reusable workflows):
   - **PR:** build, unit, architecture, pgTAP, integration (Testcontainers), contract, SAST (CodeQL), dependency review, secret scan, IaC scan, `terraform plan` (dev) as a PR comment.
   - **Merge to `main`:** build the image once, tag it with the git SHA, push to ECR (immutable tags), sign it/record provenance (artifact attestation), then auto-deploy to **dev** (Flyway task, ECS deploy, smoke test).
   - **Tag `<svc>/vX.Y.Z`:** promote the **same image digest** to **staging** (auto) and then to **prod** (GitHub Environment `prod` with required reviewers and wait timer). The deploy jobs use per-environment OIDC roles.
5. **Environments:** `dev` (auto), `staging` (auto on tag), `prod` (required reviewers; deployment branch/tag rule `*/v*`). Environment secrets hold no AWS keys, only role ARNs as variables.
6. **Rollback:** redeploy the previous tag's digest. DB migrations are expand/contract, so a rollback does not need a down-migration.

### Consequences

- Good, because each service has independent cadence and immutable promoted artifacts.
- Bad, because per-service tags are not the plain `vX.Y.Z` named in MISSION. This is a recorded deviation.
- Bad, because required reviewers on Environments and rulesets for **private** repos depend on the GitHub plan (pending **Q9**). The fallback is a `workflow_dispatch` prod job restricted to CODEOWNERS plus a CODEOWNERS-protected `deploy/prod` approval file.

### Confirmation

- `tools/dlc-check github` (Phase 2) reads the repo settings with `gh api` and reports drift from this ADR. A human applies the fix, since changing repo settings is a human action.
