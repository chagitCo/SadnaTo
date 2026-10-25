# AWS infrastructure standard (AWS)

Scope: everything under `infra/`. Sources: MISSION (IaC, Edge, Database), ADR-0004, 0007, 0013,
0014, 0016. CORE-06 applies: Claude prepares Terraform and plans, and a human runs applies.

## Rules

- **AWS-01** Infrastructure is defined only in Terraform under `infra/` with the layout of ADR-0007 as amended by ADR-0016; console changes are treated as drift and reverted through code.
- **AWS-02** Every stack uses the S3 backend with `use_lockfile = true` and `encrypt = true`, one state per environment and stack; `dynamodb_table` is not used.
- **AWS-03** `required_version` pins Terraform `~> 1.16`, providers are pinned by major version, and `.terraform.lock.hcl` is committed.
- **AWS-04** Reusable logic lives in `infra/modules/<module>` with README, typed variables with descriptions and validation, outputs and an example; stacks compose modules instead of copying resources.
- **AWS-05** IAM policies grant only the actions and resources needed; `"Action": "*"` or `"Resource": "*"` on write actions needs a justification comment reviewed by the platform owner.
- **AWS-06** Data stores, queues, topics, buckets and log groups are encrypted with customer-managed KMS keys whose key policies name the roles that use them.
- **AWS-07** Only CloudFront and the API Gateway endpoint are reachable from the internet; load balancers are internal, ECS tasks and RDS run in private subnets, and security groups allow only the expected sources.
- **AWS-08** `terraform fmt`, `terraform validate`, `tflint`, `trivy config` and `checkov` pass on every change; a suppression carries an inline reason and a reference to an issue or ADR.
- **AWS-09** Every resource carries the tags `Service`, `Owner`, `Environment`, `DataClassification` and `CostCenter` through provider `default_tags`.
- **AWS-10** Names follow `<env>-<service>-<purpose>` (for example `prod-projects-events`).
- **AWS-11** Production RDS has Multi-AZ, deletion protection, 35-day point-in-time recovery and Performance Insights; production S3 buckets have versioning and Block Public Access.
- **AWS-12** GitHub Actions reach AWS only through OIDC roles: a read-only plan role per environment and an apply role assumable only from the matching GitHub Environment.
- **AWS-13** Every plan that changes cost-relevant resources includes a short cost note in the PR (resource, size, expected monthly delta).

## Module catalog (planned, Phase 4)

`network`, `edge-apigw`, `waf`, `ecs-cluster`, `ecs-service`, `rds-postgres`, `cognito`,
`sns-topic`, `sqs-consumer`, `static-site`, `observability`, `github-oidc-role`.

Checklist for releases: [checklists/production-readiness.md](../../checklists/production-readiness.md).
