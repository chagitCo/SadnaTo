# SadnaTo — AI-Driven Development Lifecycle

A reusable AI-Driven Development Lifecycle (AI-DLC) for building secure, observable, tested
microservices with Claude Code on AWS, plus two reference services that prove it
(Projects & Tasks, Notifications).

| Start here | |
|---|---|
| Mission and locked decisions | [docs/ai-dlc/MISSION.md](docs/ai-dlc/MISSION.md) |
| Where the work stands | [docs/ai-dlc/state.md](docs/ai-dlc/state.md) · [plan](docs/ai-dlc/plan.md) · [audit log](docs/ai-dlc/audit.md) |
| How we work | [process](docs/ai-dlc/process.md) · [CONTRIBUTING](CONTRIBUTING.md) · [standards](docs/standards/README.md) |
| Decisions | [ADRs](docs/adr/README.md) · [service catalog](docs/services/catalog.md) |
| Claude Code setup | [CLAUDE.md](CLAUDE.md) · [skills](.claude/skills/) · [subagents](.claude/agents/) · [hooks and permissions](.claude/hooks/README.md) |
| Templates and checklists | [templates](templates/README.md) · [checklists](checklists/README.md) |
| DLC version | [VERSION](docs/ai-dlc/VERSION) · [CHANGELOG](docs/ai-dlc/CHANGELOG.md) · [upgrading services](docs/ai-dlc/upgrading.md) |
| Security | [SECURITY.md](SECURITY.md) |

## Stack

C# / .NET 10 (ASP.NET Core, Clean Architecture, Npgsql + Dapper, no EF Core) · PostgreSQL 18 on
Amazon RDS (functions and procedures only, Flyway) · React + TypeScript (Vite, TanStack Query,
Hebrew/RTL) · AWS: API Gateway + WAF, ECS Fargate, SNS/SQS, Cognito, CloudFront · Terraform ·
GitHub Actions with OIDC.

## Validate the DLC

```bash
scripts/validate-dlc
```

Checks instruction-file line budgets, rule IDs (single definition, no unknown references),
duplicate and contradictory rules, broken links, skill and subagent frontmatter, settings and the
DLC version. CI runs it on every pull request.
