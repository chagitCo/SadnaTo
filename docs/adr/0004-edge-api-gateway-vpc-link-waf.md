---
status: Accepted
date: 2026-10-21 (accepted 2026-10-25)
deciders: Human approver (repo owner)
consulted: AWS Cloud Architect, Application Security Engineer
informed: All service teams
---

# 0004 — Edge topology: CloudFront → API Gateway REST (Regional) + WAF → VPC Link V2 → internal ALB → ECS Fargate

## Context and Problem Statement

MISSION locks API Gateway REST API (Regional) + AWS WAF + VPC Link to a private load balancer in
front of ECS Fargate, and asks us to verify the current VPC Link options. We must also fit the SPA
(S3 + CloudFront) and the BFF (ADR-0005) into one origin.

## Decision Drivers

- No public load balancer or task IPs. One controlled ingress per environment.
- WAF protection, throttling, request validation and access logging at the edge.
- Same-origin hosting for the SPA and the BFF, so cookies can be `SameSite=Strict` without CORS.
- Low fixed cost: avoid an NLB unless it is required.

## Verified facts (2026-10-21)

- REST APIs support **VPC link V2**, which can target an **ALB directly** (no NLB). V1 VPC links are legacy, and AWS recommends against creating new ones.
- All resources (API, VPC link, LB) must be in the **same account**. Cloud Map is not supported for REST private integrations.
- API Gateway passes the stage name in the path, so strip it with `$context.requestOverride.path` mapping or route on it.
- Source: https://docs.aws.amazon.com/apigateway/latest/developerguide/private-integration.html

## Considered Options

1. API Gateway REST (Regional) + VPC link **V2 → internal ALB** (path-based listener rules per service).
2. API Gateway REST + VPC link **V1 → NLB → ALB/targets** (legacy pattern).
3. API Gateway HTTP API + VPC link → ALB (cheaper, but REST is locked by MISSION and HTTP APIs lack WAF association and request validation).

## Decision Outcome

Chosen option: **1**.

```
Browser ──HTTPS──► CloudFront (WAF web ACL #1: CloudFront scope, managed rules + rate limit)
   ├── /*            → S3 (OAC, private bucket)              SPA static assets
   └── /bff/*, /api/* → API Gateway REST, Regional (WAF web ACL #2: regional scope)
                         ├── /bff/{proxy+} → VPC link V2 → internal ALB → web-bff (ECS)
                         └── /api/{svc}/v{n}/{proxy+} → VPC link V2 → internal ALB → <svc> (ECS)
ECS services ⇄ each other via ECS Service Connect (internal only, ADR-0014)
```

- **API Gateway** has one REST API per environment (owned by the platform stack). Each service contributes its routes through its own Terraform stack, using the OpenAPI export and `x-amazon-apigateway-integration`. Settings: stage-level throttling, per-method request validation, JSON access logs to CloudWatch, X-Ray tracing on, and the default `execute-api` endpoint **disabled** (CloudFront only, enforced by a custom-domain or origin-verify header with a WAF rule).
- **Authorization at the edge:** browser calls go through the BFF (cookie session, ADR-0005), so `/bff/*` uses no API Gateway authorizer. `/api/*` routes are not reachable by browsers directly. They exist for machine clients and require a Cognito user pool authorizer with scopes. **Every service still validates the JWT itself** (defence in depth).
- **ALB** is internal, HTTPS listener (ACM private or public cert), one target group per service, health checks on `/health/ready`.
- **WAF:** AWS managed rule groups (Core, KnownBadInputs, IP reputation, AnonymousIP for prod), plus a rate-based rule. Logs go to CloudWatch Logs or S3 with redaction of `authorization`/`cookie`.

### Consequences

- Good, because there is no NLB (lower cost, fewer hops) and no public compute.
- Good, because there is a single origin for SPA and BFF.
- Bad, because WAF runs twice (CloudFront + Regional), doubling WAF cost. It is acceptable for prod. In dev, the CloudFront ACL may be in count mode (assumption).
- Bad, because REST API payload limit (10 MB) and 29 s default integration timeout apply. They are acceptable for this domain.

### Confirmation

- Checkov/Trivy policies: no `internet-facing` ALB, API Gateway stage has access logging and tracing, WAF association exists.
- A smoke test confirms that the `execute-api` default endpoint returns 403/disabled.

## More Information

- Region choice is confirmed in Q6 (default). Confirm WAF, Cognito, VPC link V2 and Service Connect availability in the chosen Region before Phase 4.
