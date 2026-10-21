# Phase 1 — Questions for the human approver

These questions cover only decisions that materially affect **security, cost, compatibility or
architecture**. Each one has a proposed default. All Phase 1 artifacts are written with these
defaults and marked **PENDING CONFIRMATION**. Answer with the number and "OK", or give your choice.

| # | Question | Proposed default | Why it matters | Affects |
|---|---|---|---|---|
| Q1 | **Repository strategy:** one monorepo, or one repo per microservice? | **Monorepo** with per-service folders, path-filtered workflows, per-folder CODEOWNERS and per-service tags `<service>/vX.Y.Z`. Re-evaluate once more than 3 teams own services. | Architecture, CI cost, upgrade mechanism | ADR-0010, 0008, 0009 |
| Q2 | **Browser auth:** BFF with HttpOnly cookies, or SPA with in-memory tokens? | **BFF** (ASP.NET Core and YARP, `__Host-` cookie, `SameSite=Strict`, behind CloudFront on the same origin). | Security (XSS token theft), one more deployable | ADR-0005 |
| Q3 | **RDS topology:** one instance per service, or separate databases on a shared instance? | **dev/staging:** one shared single-AZ instance per environment. **prod:** one shared **Multi-AZ** instance, with one database, owner role, app role and secret per service. Split a service onto its own instance when its SLO, load or data class requires it. | Cost vs blast radius | ADR-0013 |
| Q4 | **Multi-tenancy enforcement:** function parameters only, or also PostgreSQL RLS? | **Both:** `tenant_id` comes from the authenticated context and is passed to every function, **and** RLS with `FORCE ROW LEVEL SECURITY` acts as defence in depth. | Security (cross-tenant leak) | ADR-0006 |
| Q5 | **Migration tool licence:** may we use Flyway OSS (Apache-2.0) via the `flyway/flyway` Docker image? Does legal need to review Redgate's terms? | **Flyway OSS, Apache-2.0 artefacts only**, with no Redgate Community/Teams features. Fall back to DbUp (MIT) if legal objects. | Compatibility, licence | ADR-0003 |
| Q6 | **AWS accounts and Region:** one account per environment? Which Region? | **One AWS account per environment** (dev, staging, prod) plus a tooling/state account under AWS Organizations. **Region `eu-central-1`**. `il-central-1` (Tel Aviv) is the alternative if data residency in Israel is required, but service availability (WAF, Cognito, Service Connect) must be checked first. | Security isolation, data residency, cost | ADR-0007, 0004 |
| Q7 | **Identity provider:** Amazon Cognito user pool, or an enterprise IdP via OIDC? | **Cognito user pool** (Auth Code + PKCE through the BFF). Organization membership and roles live in the Projects service, not in Cognito groups. An enterprise IdP can federate into Cognito later. | Security, cost (Cognito MAU tier) | ADR-0005, 0011, 0014 |
| Q8 | **Service-to-service auth:** OAuth2 client-credentials JWTs, or mTLS? | **Cognito client-credentials JWTs** with per-service scopes for sync calls, and **IAM resource policies** on SNS/SQS for events. Service Connect TLS for transport. No mTLS PKI for now. | Security, operational cost | ADR-0014 |
| Q9 | **GitHub plan:** which plan does the org have? Is the repo private? | **Assume GitHub Team or Enterprise Cloud, private repo.** Required reviewers on the `prod` Environment and branch rulesets for private repos depend on the plan. If they are unavailable, the prod gate falls back to a manual `workflow_dispatch` restricted by CODEOWNERS. | Security (prod gate), cost | ADR-0008 |
| Q10 | **Shared messaging package:** may the platform packages include `Platform.Messaging` (event envelope, outbox dispatcher, idempotent SQS consumer)? | **Yes.** It is technical code, not domain code, and is versioned like the other platform packages. | Architecture (Microservices rule 6) | ADR-0015, 0012 |
| Q11 | **Container runtime licence:** may developers use Docker Desktop? | Docker Desktop only if the org qualifies for the free tier or holds a subscription; otherwise **Rancher Desktop**. CI uses GitHub-hosted runners with Docker Engine. | Cost, licence | environment-report §3 |

## Assumptions made without asking (documented defaults)

| # | Assumption |
|---|---|
| A1 | Target framework `net10.0` (current LTS). Do not move to .NET 11 (STS, Nov 2026). |
| A2 | RDS for PostgreSQL **18**. |
| A3 | .NET namespaces and package IDs use the prefix `Workshop.` (taken from the folder name) until you give a product/org name. |
| A4 | Node.js 24 LTS for the frontend toolchain. |
| A5 | Terraform `~> 1.16` with the S3 backend and `use_lockfile = true`, without DynamoDB. |
| A6 | Event envelope: CloudEvents 1.0 JSON. W3C `traceparent` travels in SNS/SQS message attributes. |
| A7 | Contract tests: PactNet. Pact files are committed in the monorepo, with no Pact Broker, so there is no extra infrastructure. |
| A8 | Languages: Hebrew (default, RTL) and English. |
| A9 | We implement AI-DLC natively in Claude Code and do not install the `aidlc-workflows` v2 harness (ADR-0001). |
