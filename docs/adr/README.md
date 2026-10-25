# Architecture Decision Records

Format: [MADR 4](https://adr.github.io/madr/). File name: `NNNN-kebab-title.md`. Start from
[`templates/adr.md`](../../templates/adr.md) (the `new-adr` skill does this). ADRs are immutable once
**Accepted**. To change a decision, write a new ADR that supersedes the old one and update the old
one's status to `Superseded by ADR-NNNN`. A partial change is recorded as "Amended by ADR-NNNN" in
the old ADR's index row and a note at its top; the original decision text is not rewritten.

Status values: `Proposed` → `Accepted` | `Rejected` → `Superseded by ADR-NNNN` | `Deprecated`.
ADRs 0001–0015 were **accepted** at the Phase 1 gate on 2026-10-25 (PR #1 merged, all question defaults confirmed). The
approval is recorded in `docs/ai-dlc/audit.md`.

| ADR | Title | Status | Related question (confirmed) |
|---|---|---|---|
| [0001](0001-adopt-ai-dlc.md) | Adopt AI-DLC (Claude Code-native) | Accepted; amended by 0016 | — |
| [0002](0002-data-access-postgresql-functions.md) | Data access via PostgreSQL functions/procedures, no EF Core | Accepted | — |
| [0003](0003-migration-tool-flyway.md) | Migration tool: Flyway OSS | Accepted; amended by 0016 | Q5 |
| [0004](0004-edge-api-gateway-vpc-link-waf.md) | Edge: API Gateway REST + WAF + VPC Link V2 → ALB → ECS | Accepted | Q6 |
| [0005](0005-browser-auth-bff.md) | Browser auth: BFF with HttpOnly cookies | Accepted | Q2, Q7 |
| [0006](0006-multi-tenancy-row-level.md) | Multi-tenancy: row-level `tenant_id` + RLS | Accepted | Q4 |
| [0007](0007-terraform-layout-and-state.md) | Terraform layout and state | Accepted; amended by 0016 | Q6 |
| [0008](0008-github-flow-environments-releases.md) | GitHub Flow, environments, releases | Accepted | Q9 |
| [0009](0009-service-generation-and-dlc-upgrades.md) | Service generation (`dotnet new` pack) and DLC upgrades | Accepted; amended by 0016 | — |
| [0010](0010-repository-strategy-monorepo.md) | Repository strategy: monorepo | Accepted; amended by 0016 | Q1 |
| [0011](0011-service-boundaries-and-catalog.md) | Service boundaries and service catalog | Accepted | — |
| [0012](0012-inter-service-communication.md) | Inter-service communication: events first | Accepted | Q10 |
| [0013](0013-database-per-service-on-rds.md) | Database per service on RDS | Accepted | Q3 |
| [0014](0014-service-to-service-authn-authz.md) | Service-to-service authentication and authorization | Accepted | Q8 |
| [0015](0015-shared-platform-packages.md) | Shared platform packages | Accepted | Q10 |
| [0016](0016-repository-layout-and-instruction-files.md) | Layer-first repository layout and instruction files (amends 0001, 0003, 0007, 0009, 0010) | Accepted | Phase 2 instruction |
