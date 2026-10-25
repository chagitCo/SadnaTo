# Security checklist

Reference: [security standard](../docs/standards/security.md) (OWASP mapping table).

## Authorization and tenancy
- [ ] Every new endpoint has an explicit policy; deny by default (SEC-01)
- [ ] Tenant derived from the principal, not the request (SEC-02); foreign-tenant access returns 404 (SEC-03)
- [ ] Role/ownership checks for commands, queries and list filters (SEC-04)
- [ ] Database routines filter by tenant and RLS is forced (DB-04, DB-05)

## Authentication
- [ ] Service calls use client-credentials JWT with endpoint scopes (SEC-05)
- [ ] Browser: no tokens in browser storage, cookie flags correct (SEC-09); CSRF header + Origin check (SEC-10)

## Input and output
- [ ] Input validated with length/range/format limits (SEC-07, API-11)
- [ ] No string-built SQL (DB-12); no HTML injection sinks (FE-11)
- [ ] Message consumers validate source/type/schema (SEC-06)

## Secrets and data
- [ ] No secrets or real data in code, tests, fixtures, images or settings (CORE-07, SEC-08)
- [ ] Logs, traces and errors free of tokens, PII and Confidential free text (SEC-11)
- [ ] New data elements classified; encryption in transit/at rest (SEC-17)

## Platform
- [ ] Least-privilege IAM and DB roles (SEC-14, AWS-05); no new public endpoints (AWS-07)
- [ ] Security headers unchanged or improved (SEC-12); rate limits for expensive operations (SEC-13)
- [ ] No new High/Critical dependency vulnerabilities, or a dated exception (SEC-15)
- [ ] Threat model updated if a trust boundary, store, integration or data class was added (SEC-16)
