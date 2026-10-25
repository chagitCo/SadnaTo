# infra — Terraform for AWS

Loaded on demand when Claude works under `infra/`. Rules live in the standards; this file gives
local context, layout and commands only.

## Must read before changing anything here

- [aws-infrastructure](../docs/standards/aws-infrastructure.md) — AWS rules (layout, state, IAM, encryption, tagging)
- [security](../docs/standards/security.md) — IAM and network items
- [ci-cd](../docs/standards/ci-cd.md) — how plans and applies run
- ADRs 0004 (edge), 0007 (layout and state), 0013 (RDS), 0016 (paths)

Most-cited IDs during review: AWS-02 (state backend), AWS-05 (IAM least privilege), AWS-06
(encryption), AWS-08 (scanners), CORE-06 (Claude never applies).

## Layout

```
infra/
  modules/<module>/            reusable modules: README, variables, outputs, examples/, tests/
  bootstrap/                   per account: state bucket, KMS key, GitHub OIDC provider and roles (human-run once)
  live/<env>/<stack>/          platform stacks: network, platform, edge, data, identity, observability
  services/<svc>/              service stack (main.tf) + envs/<env>/ (backend.tf, terraform.tfvars)
  .tflint.hcl  .checkov.yaml  trivy.yaml
```

Stack order: bootstrap → network → platform → data → identity → edge → observability → services.

## Commands (run inside a stack directory)

| Purpose | Command | Who |
|---|---|---|
| Format | `terraform fmt -recursive -check` | Claude or human |
| Init without backend (local validation) | `terraform init -backend=false` | Claude or human |
| Validate | `terraform validate` | Claude or human |
| Lint | `tflint --recursive` | Claude or human |
| Scan | `trivy config .` and `checkov -d .` | Claude or human |
| Plan | `terraform plan -out=tfplan` (needs the env's plan role via OIDC in CI) | CI |
| Apply | GitHub Actions environment job after approval | **Human only** |

`terraform apply`, `terraform destroy` and AWS write commands are blocked for Claude by
`.claude/settings.json` and the guard hook. Status: no stack exists yet (Phase 4). Terraform is
not yet installed on the current dev machine.
