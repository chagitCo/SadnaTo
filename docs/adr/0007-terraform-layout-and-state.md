---
status: Accepted
date: 2026-10-21 (accepted 2026-10-25)
deciders: Human approver (repo owner)
consulted: AWS Cloud Architect, DevSecOps Engineer
informed: All service teams
---

> **Amended by [ADR-0016](0016-repository-layout-and-instruction-files.md)** (2026-10-25): repository paths and instruction-file mechanism changed; the decision below is otherwise unchanged.

# 0007 — Terraform layout and state strategy

## Context and Problem Statement

MISSION locks Terraform, remote state in S3 with **native S3 locking**, one state per environment,
reusable modules, tflint + checkov/trivy. Microservices rule 7 requires a Terraform stack per service
that deploys independently.

## Decision Drivers

- Blast radius: a service change must not plan or lock platform resources.
- Independent service deploys.
- No static AWS keys (GitHub OIDC).
- No human-free `apply`. Claude never applies.

## Verified facts (2026-10-21)

- The S3 backend supports `use_lockfile = true` (lock object `<key>.tflock`). `dynamodb_table` is **deprecated**. Source: https://developer.hashicorp.com/terraform/language/backend/s3
- Terraform 1.16.6 is the current release (winget).

## Considered Options

1. One state per environment for everything.
2. **Layered stacks: one state per (environment × stack)**, where a stack is either a platform layer or a service.
3. Terraform workspaces for environments.

## Decision Outcome

Chosen option: **2**. "One state per environment" from MISSION is interpreted as **no state shared
across environments**. Each environment has several small states. This is a recorded deviation, so
that services deploy independently.

```
infra/
  modules/                         # reusable, versioned by git path; README + examples + tests each
    network/  edge-apigw/  waf/  ecs-cluster/  ecs-service/  rds-postgres/  cognito/
    sns-topic/  sqs-consumer/  static-site/  observability/  github-oidc-role/
  bootstrap/                       # per account: state bucket, KMS key, GitHub OIDC provider + roles
  live/
    dev|staging|prod/
      network/ platform/ edge/ data/ identity/ observability/   # each: backend.tf, main.tf, terraform.tfvars
services/<svc>/infra/
  envs/dev|staging|prod/ backend.tf + terraform.tfvars          # service stack: ECS service, TG/listener rule,
  main.tf (uses infra/modules/ecs-service, sqs-consumer, …)     #   API routes, SNS/SQS, alarms, dashboards, DB role
```

- **State:** one S3 bucket per AWS account (`<org>-tfstate-<account-id>-<region>`), with versioning, SSE-KMS (CMK), Block Public Access, TLS-only bucket policy, and access limited to the environment's plan/apply roles. Key: `<stack>/terraform.tfstate`, for example `services/projects/terraform.tfstate`. Backend: `use_lockfile = true`, `encrypt = true`. **No DynamoDB.**
- **Cross-stack data:** read through `terraform_remote_state` (read-only) **or** SSM parameters published by the producing stack. Prefer SSM, because it gives looser coupling.
- **Versions:** `required_version = "~> 1.16"`, AWS provider pinned `~> <major>` (exact value chosen in Phase 2), and a committed `.terraform.lock.hcl`.
- **Roles (GitHub OIDC):** each environment has a `plan` role (read-only + state read/lock), used on PRs, and an `apply` role, assumable **only** from the GitHub Environment of the same name (`sub` claim `repo:<org>/<repo>:environment:<env>`). There are no static keys.
- **Quality gates:** `terraform fmt -check`, `terraform validate`, `tflint` (AWS ruleset), `trivy config` and `checkov`. Terraform tests (`terraform test`) run for modules.
- **Apply:** only in GitHub Actions, in the environment job after approval. Claude prepares plans but never runs `apply` (MISSION global rule 6; enforced by a deny rule and hook in Phase 2).

### Consequences

- Good, because plans are small and fast, and services deploy independently.
- Bad, because stack ordering has to be managed (bootstrap → network → platform → data → service). Document it in `infra/README.md`.

### Confirmation

- A CI job fails if any `backend.tf` lacks `use_lockfile = true` or contains `dynamodb_table`.
- Checkov/Trivy run on every PR that touches `infra/**` or `services/*/infra/**`.

## More Information

- The account structure (one account per environment) is confirmed in Q6 (default).
