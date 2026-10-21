# Environment Report — Phase 1 (Inception)

- **Date:** 2026-10-21
- **Machine:** Windows 11 Home 10.0.26200, Windows PowerShell 5.1.26100, winget v1.29.380
- **Working directory:** `C:\Hagit\WorkshopSysten`
- **Method:** `Get-Command` for each tool on `PATH`, plus checks of default install locations
  (`Program Files\Git`, `Program Files\dotnet`, `Program Files\nodejs`, Docker Desktop, GitHub Desktop).
  Package IDs below were verified with `winget show --id <id> --exact --source winget` (read-only)
  on the same date.

## 1. Existing repository state

| Item | Finding |
|---|---|
| Repository | **None.** The directory was empty before Phase 0. It is **not a git repository** (git is not installed). |
| Files | Only `docs/ai-dlc/MISSION.md` (saved verbatim at the start of the session) and the Phase 1 artifacts. |
| CLAUDE.md | None (root or nested). |
| `.claude/` (settings, skills, agents, hooks, rules) | None. |
| CI workflows (`.github/`) | None. |
| Conventions to reuse | None. This is a greenfield repository; every convention comes from MISSION.md and the ADRs. |
| Remote / GitHub repository | None configured. No GitHub repo, so no PR can be opened yet (see §5). |

## 2. Installed toolchain

| Tool | Required for | Status | Version available on winget (2026-10-21) |
|---|---|---|---|
| git | Everything (branching, PRs) | **MISSING** | `Git.Git` 2.55.0.5 |
| gh (GitHub CLI) | PRs, branch protection, environments | **MISSING** | `GitHub.cli` 2.102.1 |
| dotnet SDK | Backend services, template pack | **MISSING** | `Microsoft.DotNet.SDK.10` 10.0.402 |
| node / npm | Frontend, Playwright | **MISSING** | `OpenJS.NodeJS.LTS` 24.20.0 |
| docker | Testcontainers, Flyway, pgTAP, local stack | **MISSING** | `Docker.DockerDesktop` 4.96.0 (needs WSL 2) |
| terraform | IaC | **MISSING** | `Hashicorp.Terraform` 1.16.6 |
| flyway | Migrations | **MISSING** | Not on winget. Default: Docker image `flyway/flyway` (pinned tag chosen in Phase 2) |
| psql | Local DB inspection, pgTAP runner | **MISSING** | `PostgreSQL.PostgreSQL.18` 18.6 (client tools; the server component is not needed) |
| aws CLI | Plan/inspect only, never apply | **MISSING** | `Amazon.AWSCLI` 2.38.3 |
| tflint | IaC lint | **MISSING** | `TerraformLinters.tflint` 0.64.0 |
| trivy | IaC / image / dependency scan | **MISSING** | `AquaSecurity.Trivy` 0.76.0 |
| checkov | IaC policy scan | **MISSING** | Needs Python (`pip install checkov`); Python is **not installed** (only the Microsoft Store stub is present). The default is to run checkov in CI only. |
| PowerShell 7 (`pwsh`) | Cross-platform scripts | **MISSING** | Optional. Scripts in this repo target bash in CI and PowerShell 5.1/7 locally where needed. |

**Consequence:** no build, test, scan, migration or `terraform` command can run on this machine yet.
Phase 1 is documents only, so this does not block Phase 1. It **does block** creating the branch
`docs/ai-dlc-phase-1` and opening the PR.

## 3. Missing prerequisites — install commands (a human runs these)

Run these in an elevated terminal, one at a time. Accepting the winget source and package
agreements is your decision, so I did not run any of these.

```powershell
winget install --id Git.Git --exact --source winget
winget install --id GitHub.cli --exact --source winget
winget install --id Microsoft.DotNet.SDK.10 --exact --source winget
winget install --id OpenJS.NodeJS.LTS --exact --source winget
winget install --id Docker.DockerDesktop --exact --source winget
winget install --id Hashicorp.Terraform --exact --source winget
winget install --id Amazon.AWSCLI --exact --source winget
winget install --id PostgreSQL.PostgreSQL.18 --exact --source winget
winget install --id TerraformLinters.tflint --exact --source winget
winget install --id AquaSecurity.Trivy --exact --source winget
```

After the install, open a new terminal and run:

```powershell
git --version; gh --version; dotnet --list-sdks; node --version; docker version; terraform version; aws --version; psql --version; tflint --version; trivy --version
docker pull flyway/flyway
gh auth login
git config --global user.name "<your name>"; git config --global user.email "<your email>"
```

Docker Desktop needs WSL 2 (`wsl --install`) and a reboot. Docker Desktop is free for small
businesses and education, but larger organizations need a paid subscription. **Check the licence
before installing it** (see `questions.md`). Rancher Desktop or Podman are licence-free
alternatives that Testcontainers supports.

## 4. Platform facts verified for this Phase (2026-10-21)

| Fact | Result | Source |
|---|---|---|
| Current .NET LTS | **.NET 10** (LTS, supported to Nov 2028). .NET 11 (STS) is expected on 10 Nov 2026. .NET 8 and 9 reach end of support on 10 Nov 2026. **Decision: target `net10.0`.** | Web search (secondary sources: gapvelocity.ai, herodevs.com). Confirm on https://dotnet.microsoft.com/platform/support/policy in Phase 2. |
| RDS PostgreSQL latest major | **PostgreSQL 18** (RDS since Nov 2025, standard support to 28 Feb 2031). Latest minor seen: 18.4 announced May 2026; the release calendar lists 18.6. | https://docs.aws.amazon.com/AmazonRDS/latest/PostgreSQLReleaseNotes/postgresql-release-calendar.html , https://aws.amazon.com/about-aws/whats-new/2026/05/amazon-rds-postgresql/ |
| API Gateway REST → private ALB | REST APIs support **VPC link V2** straight to an **ALB** (no NLB). V1 VPC links are legacy and AWS recommends against new ones. Same-account only. No Cloud Map. | https://docs.aws.amazon.com/apigateway/latest/developerguide/private-integration.html |
| Terraform S3 locking | `use_lockfile = true` (native S3 lock, `.tflock` object). `dynamodb_table` is **deprecated**. Terraform 1.16.6 is current on winget. | https://developer.hashicorp.com/terraform/language/backend/s3 |
| Flyway licence | The `flyway/flyway` GitHub repo is **Apache-2.0**. Redgate's "Flyway Community" edition is a separately licensed **freeware** product and is *not* part of the OSS project. Undo, cherry-pick and other paid features are not needed. See ADR-0003. | https://github.com/flyway/flyway , https://www.red-gate.com/support/license/software-editions/ |
| DbUp (alternative) | `dbup-postgresql` 7.0.1 (Feb 2026), actively maintained, MIT (from a third-party index; LICENSE file not opened). | https://www.nuget.org/packages/dbup-postgresql |
| AWS AI-DLC | `awslabs/aidlc-workflows` is now at **v2.11.1**: "5 phases and 33 stages", 11 workflow profiles, a Claude Code harness (`aidlc config --harness claude`, `/aidlc`). Our MISSION locks the classic 3-phase model. See ADR-0001. | https://github.com/awslabs/aidlc-workflows , https://awslabs.github.io/aidlc-workflows/reference/diagrams/ |

## 5. Claude Code conventions verified (official docs, 2026-10-21)

| Area | Convention we will follow | Doc page |
|---|---|---|
| Memory | `./CLAUDE.md` (or `./.claude/CLAUDE.md`) is shared and committed. `CLAUDE.local.md` is personal and gitignored. Files above the working dir load at launch and subdirectory files load **on demand**. Files are concatenated, not overridden. Keep each file **under ~200 lines**. Use `@path` imports (max 4 hops; they still cost context). If a `CLAUDE.md` exists, `AGENTS.md` is ignored unless imported. | https://code.claude.com/docs/en/memory |
| Rules | `.claude/rules/**/*.md`, one topic per file. A `paths:` frontmatter field scopes a rule so it loads only when matching files are touched. | https://code.claude.com/docs/en/memory |
| Skills | `.claude/skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description` (recommended), `when_to_use`, `argument-hint`, `disable-model-invocation`, `user-invocable`, `allowed-tools`, `context: fork`, `agent`, `paths`, …). Keep under 500 lines. Use `disable-model-invocation: true` for side-effecting workflows. Unknown fields are silently ignored. | https://code.claude.com/docs/en/skills |
| Subagents | `.claude/agents/*.md` (recursive). `name` and `description` are required. Optional: `tools`, `disallowedTools`, `model`, `permissionMode`, `skills`, `hooks`, `memory`, `isolation: worktree`, `effort`, … Field names are exact, and a file with invalid frontmatter is **skipped silently**. | https://code.claude.com/docs/en/sub-agents |
| Hooks | `hooks` key in settings: event → matcher group → handlers (`command`/`http`/`mcp_tool`/`prompt`/`agent`). Key events: `PreToolUse`, `PostToolUse`, `Stop`, `SessionStart`, `UserPromptSubmit`. A command hook gets JSON on stdin. **Exit 2 blocks** (stderr goes back to Claude). JSON `hookSpecificOutput.permissionDecision` is `allow/deny/ask/defer`. `"onFailure": "block"` gives fail-closed (v2.1.295+). Per-handler `if` uses permission-rule syntax. | https://code.claude.com/docs/en/hooks |
| Settings / permissions | Precedence: managed > `--settings` > `.claude/settings.local.json` > `.claude/settings.json` > `~/.claude/settings.json`. `permissions.allow/ask/deny` lists **merge** across scopes. Project `allow` rules wait for workspace trust, while `deny`/`ask` apply immediately. `defaultMode` `auto`/`bypassPermissions` are ignored in project files. Strict JSON (no comments). Add `$schema` for validation. | https://code.claude.com/docs/en/settings |

**Implications for Phase 2:**

- Guardrails such as no `terraform apply`, no push to `main`, no force-push and no secret reads go in
  `.claude/settings.json` `permissions.deny` **and** a `PreToolUse` hook. CLAUDE.md is guidance only,
  and the memory docs say to use hooks to enforce it.
- Long rule sets go into path-scoped `.claude/rules/` rather than one large CLAUDE.md.
- Each subagent and skill file is validated in CI, because malformed frontmatter is skipped silently.

## 6. What could not be checked here

- GitHub plan/organization features (branch protection, required reviewers on environments for private
  repos) depend on the GitHub plan. This is unknown and listed in `questions.md`.
- AWS account structure, Region service availability, SCPs: no AWS access (by design).
- Every exact version pin (NuGet, npm, Docker tags) is chosen and verified in Phase 2, when the
  toolchain can run.
