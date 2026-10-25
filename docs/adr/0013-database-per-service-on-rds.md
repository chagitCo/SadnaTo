---
status: Proposed
date: 2026-10-21
deciders: Human approver (repo owner)
consulted: AWS Cloud Architect, Application Security Engineer
informed: All service teams
---

# 0013 — Database per service on Amazon RDS for PostgreSQL 18

## Context and Problem Statement

Microservices rule 2 requires each service to own its database. On RDS we can give each service its
own **instance**, or its own **database** on a shared instance. The trade-off is cost vs isolation
(blast radius, noisy neighbours, maintenance windows, version coupling).

## Decision Drivers

- Data ownership and access isolation (no service can touch another's data).
- Cost: two small reference services in three environments.
- Availability in prod (Multi-AZ).
- Operational simplicity (patching, backups).

## Considered Options

1. **Instance per service per environment.**
2. **Shared instance per environment, database + roles per service.**
3. Option 2 in dev/staging, option 1 in prod.

## Decision Outcome

Chosen option: **2 in every environment, with an explicit split trigger** (PENDING **Q3**).

| Environment | Topology (default) |
|---|---|
| dev | 1 RDS PostgreSQL 18 instance, Single-AZ, small Graviton class, 7-day backups |
| staging | Same as dev, plus snapshot-restore drills |
| prod | 1 RDS PostgreSQL 18 instance, **Multi-AZ**, encrypted with a CMK, 35-day PITR, deletion protection, Performance Insights, enhanced monitoring |

Isolation on the shared instance:

- **One database per service** (`projects`, `notifications`, …). Each service has its own `<svc>_owner` (migrations) and `<svc>_app` (runtime) roles (ADR-0002). `REVOKE CONNECT ON DATABASE <svc> FROM PUBLIC` is applied, and only that service's roles can connect.
- **Separate credentials per service** in Secrets Manager with rotation, or IAM DB auth (decided in Phase 3). Each ECS task role can read only its own secret.
- `rds.force_ssl = 1`. The instance lives in private DB subnets. The security group allows 5432 only from service security groups and the migration-task security group.
- Each service's Terraform stack creates its own database, roles and secret through the `postgresql` provider, run from inside the VPC (CI runner or ECS task). This is detailed in Phase 4.
- The master user is used **only** by the platform data stack, never by services.

**Split trigger:** a service gets its own instance if it has a stricter SLO than the shared instance's, a higher data classification (for example Restricted/PII at scale), sustained more than 30% of instance CPU or IOPS, or a need for a different major version or parameter group. A split needs a new ADR.

### Consequences

- Good, because one Multi-AZ instance costs much less than one per service.
- Bad, because the blast radius is shared for instance-level failures and maintenance windows, and major-version upgrades are coupled. These are accepted for reference-scale load.

### Confirmation

- pgTAP / integration test: `notifications_app` cannot `CONNECT` to `projects`.
- Checkov: RDS encrypted, not public, deletion protection on prod, backups ≥ 7 days.

## More Information

- PostgreSQL 18 on RDS: standard support to 28 Feb 2031 (https://docs.aws.amazon.com/AmazonRDS/latest/PostgreSQLReleaseNotes/postgresql-release-calendar.html, read 2026-10-21).
- Instance classes and pricing are finalised in Phase 4, once the Region is confirmed (Q6).
