---
status: Proposed
date: 2026-10-21
deciders: Human approver (repo owner)
consulted: Application Security Engineer, AWS Cloud Architect
informed: All service teams
---

# 0014 — Service-to-service authentication and authorization

## Context and Problem Statement

Microservices rule 4: service-to-service calls are authenticated and authorized, and network
location is never trusted. This applies to sync calls (Service Connect, API Gateway) and to
async messaging.

## Decision Drivers

- Zero trust inside the VPC.
- No long-lived shared secrets in code or config.
- Fine-grained, auditable permissions.
- Low operational burden (no private PKI unless required).

## Considered Options

1. **OAuth2 client-credentials JWTs from Cognito** (resource servers + custom scopes) + IAM for AWS-native channels.
2. mTLS with a private CA (ACM PCA) between services.
3. Network-only controls (security groups).

## Decision Outcome

Chosen option: **1** (PENDING **Q8**), with network controls as an additional layer.

**Sync calls**

- Each callable service defines a **Cognito resource server** (`https://api.workshop/<svc>`) with scopes such as `projects/tasks.read`.
- Each calling service has its own **app client** (client-credentials grant). Its secret lives in Secrets Manager and is readable only by that service's task role. Tokens are cached in memory until shortly before expiry, using a platform `Auth` package (ADR-0015).
- The callee validates issuer, audience, `exp`/`nbf`, `client_id` and the required **scope per endpoint** (ASP.NET Core authorization policies). On-behalf-of-user calls through the BFF carry the **user** token and are authorized by user + tenant + role.
- Transport: Service Connect with TLS, and security groups allowing only the callers that are expected.

**Async messaging**

- **Publish:** the SNS topic policy allows `sns:Publish` only from the producer's task role.
- **Subscribe:** the SQS queue policy allows `sqs:SendMessage` only from the specific topic ARN (`aws:SourceArn`). Only the consumer's task role may receive or delete.
- **Message trust:** the consumer validates the CloudEvents `source` and `type` against an allowlist and the JSON Schema, and uses `tenantid` from the envelope **only** to scope its own writes. It never trusts it to grant access to other data.
- Encryption: SSE-KMS on topics and queues, with key policies that grant only the producer and consumer roles.

**Auditing:** each service logs the `client_id`/`sub` and tenant for every authorized request (no token contents). CloudTrail covers SNS/SQS/KMS.

### Consequences

- Good, because it reuses Cognito (already required for users), uses standard JWT validation, and needs no PKI.
- Bad, because client secrets need rotation. Mitigation: Secrets Manager rotation through a runbook. Revisit mTLS if a compliance requirement demands it.
- Bad, because Cognito machine-to-machine token pricing applies. It is a small cost at this scale. Verify current pricing in Phase 4.

### Confirmation

- Integration tests: calls without a token, with the wrong audience, or with a missing scope all return 401/403.
- Checkov/Trivy custom check: every SQS queue policy has an `aws:SourceArn` condition.
