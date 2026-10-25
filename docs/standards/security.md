# Security standard (SEC)

Scope: every layer. Sources: ADR-0005 (BFF), 0006 (tenancy), 0014 (service-to-service),
reference-service §6–7 (data classification, STRIDE). OWASP Top 10 and OWASP API Security Top 10
are used as review checklists; this repo makes no compliance claim (CORE-11).

## Rules

- **SEC-01** Authorization is deny-by-default: every endpoint declares a policy, and a missing policy fails the build-time architecture test.
- **SEC-02** The tenant comes from the authenticated principal (active organization validated against membership), never from the request body or a client-supplied header alone.
- **SEC-03** A request for another tenant's resource returns 404, never 403, so resource existence is not revealed.
- **SEC-04** Role and ownership checks run in the Application layer for every command and query, including list filters.
- **SEC-05** Service-to-service calls carry a JWT from the client-credentials flow, and the callee validates issuer, audience, expiry and the scope required by the endpoint (ADR-0014).
- **SEC-06** Message consumers accept only events whose `source` and `type` are on an allowlist and whose payload passes the JSON Schema; the envelope `tenantid` scopes the consumer's own writes only.
- **SEC-07** Input is validated for type, length, range and format at the boundary; output to HTML is encoded by the framework, and free text is stored as plain text.
- **SEC-08** Runtime secrets live in AWS Secrets Manager (or SSM SecureString) and reach a service only through its task role; container images and Claude settings never embed them (CORE-07 covers the repository).
- **SEC-09** Browser code never stores tokens in `localStorage`, `sessionStorage`, IndexedDB or JavaScript-readable cookies; the BFF session cookie is `__Host-`, `Secure`, `HttpOnly`, `SameSite=Strict`.
- **SEC-10** State-changing BFF requests require the `X-CSRF` header and a same-origin `Origin`.
- **SEC-11** Logs, traces and error responses contain no tokens, passwords, connection strings, PII or Confidential free text; identifiers are allowed (classification in reference-service §6).
- **SEC-12** Responses set security headers via CloudFront or the host: strict CSP without `unsafe-inline` scripts, HSTS, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, frame-ancestors none.
- **SEC-13** Rate limits exist at the edge (WAF, API Gateway throttling) and per tenant in each service for expensive operations.
- **SEC-14** IAM roles and database roles follow least privilege; each service has its own task role, secret and database role.
- **SEC-15** Dependencies with known High or Critical vulnerabilities block merge unless an exception with an expiry date is recorded in the PR and `docs/security/exceptions.md`.
- **SEC-16** A change that adds a trust boundary, data store, external integration or new data class updates the threat model (`threat-model` skill) in the same PR.
- **SEC-17** Data is encrypted in transit (TLS 1.2+) and at rest (KMS customer-managed keys for RDS, SNS, SQS, S3 and log groups).
- **SEC-18** Non-production environments use synthetic data only.

## Where each OWASP risk is handled (reference)

| Risk | Main controls |
|---|---|
| Broken access control / BOLA (API1) | SEC-01…04, DB-05 |
| Broken authentication (API2) | ADR-0005, SEC-05, SEC-09 |
| Injection | BE-03, DB-12, SEC-07 |
| Security misconfiguration | SEC-12, AWS rules, CICD-02 |
| Unrestricted resource consumption (API4) | API-07, API-11, SEC-13 |
| Vulnerable components | SEC-15, CICD-07 |
| Logging/monitoring failures | OBS rules, SEC-11 |
| SSRF | Outbound calls only to configured service URLs (BE-09); no user-supplied URLs fetched |

Checklist: [checklists/security.md](../../checklists/security.md).
