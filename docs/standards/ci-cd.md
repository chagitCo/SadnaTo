# CI/CD standard (CICD)

Scope: `.github/workflows/**` and release mechanics. Sources: MISSION (CI/CD), ADR-0008, 0010.

## Rules

- **CICD-01** Third-party actions are pinned to a full commit SHA with the version in a trailing comment (`actions/checkout@<sha> # v7.0.1`); Dependabot keeps them current.
- **CICD-02** Every workflow declares top-level `permissions: {}` or the minimum set, and jobs add only what they need (for example `id-token: write` for OIDC).
- **CICD-03** Workflows triggered by `pull_request_target` or `workflow_run` never check out or execute code from the pull request head.
- **CICD-04** Each deployable has its own workflow with `paths:` filters covering its code, database and infrastructure folders, calling shared reusable workflows (`_reusable-*.yml`).
- **CICD-05** An image is built once per commit on `main`, pushed to ECR with an immutable SHA tag, and the same digest is promoted to staging and production.
- **CICD-06** Required checks on `main`: build, unit, architecture, database (pgTAP), integration, contract, `dlc-validate`, SAST (CodeQL), dependency review, secret scan, IaC scan and the Conventional Commit PR-title check, as applicable to the changed paths.
- **CICD-07** Images and packages get an SBOM and a build-provenance attestation; the deploy job verifies the attestation before deploying.
- **CICD-08** The `prod` GitHub Environment requires reviewer approval and allows deployments only from release tags (`<svc>/v*`).
- **CICD-09** Secrets in workflows come from GitHub Environments and hold no AWS keys; AWS access uses OIDC roles (AWS-12).
- **CICD-10** Deploy jobs use a `concurrency` group per service and environment, so two deploys of the same service never overlap.
- **CICD-11** A deployment runs migrations (Flyway task), deploys the service, runs smoke tests, and rolls back automatically when the smoke tests or the ECS deployment circuit breaker fail.
- **CICD-12** Workflow scripts run with `set -euo pipefail` (bash) and never echo secrets.

## Pipeline shape (reference)

```
PR:        lint → build → unit/arch → pgTAP → integration → contract → scans → terraform plan (dev) → dlc-validate
main:      build image → attest → push ECR → deploy dev → smoke
tag:       promote digest → deploy staging → smoke → [approval] → deploy prod → smoke
```

The release procedure is in the `release` skill and [checklists/release.md](../../checklists/release.md).
