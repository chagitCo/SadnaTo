---
status: Accepted
date: 2026-10-21 (accepted 2026-10-25)
deciders: Human approver (repo owner)
consulted: Application Security Engineer, Senior React/TypeScript Engineer, Senior C#/.NET Engineer
informed: All service teams
---

# 0005 — Browser authentication: Backend-for-Frontend (BFF) with HttpOnly cookies

## Context and Problem Statement

MISSION locks Cognito (or an enterprise IdP via OIDC), Authorization Code + PKCE, and **tokens never
in localStorage**. The choice between a BFF and in-memory tokens must be made in Phase 1.

## Decision Drivers

- Resistance to XSS token exfiltration (OAuth 2.0 for Browser-Based Apps BCP recommends a BFF for sensitive apps).
- Refresh-token handling without exposing it to JavaScript.
- Silent re-auth must not depend on third-party cookies, which browsers increasingly block.
- Operational cost of one more deployable.

## Considered Options

1. **BFF**: a confidential OIDC client on the server. The browser holds only an HttpOnly session cookie.
2. **SPA with in-memory tokens**: a public client with PKCE. Tokens live in JS memory and refresh through rotating refresh tokens or a hidden iframe.
3. Token-mediating backend (the backend obtains tokens, then hands the access token to the SPA).

## Decision Outcome

Chosen option: **1 — BFF**.

- **Implementation:** an ASP.NET Core service `web-bff` (`services/web-bff/`). It is an edge component, **not** a bounded context (ADR-0011). It uses OIDC code flow + PKCE as a **confidential client** against Cognito.
- **Session:** the cookie `__Host-session` has `Secure`, `HttpOnly`, `SameSite=Strict`, `Path=/` and an 8 h sliding / 12 h absolute lifetime. Tokens are stored **server-side-encrypted in the cookie ticket** (ASP.NET Core Data Protection, chunked cookies). Data Protection keys are persisted to SSM Parameter Store and encrypted with a dedicated KMS key, so tasks share keys without a cache or database (MISSION global rule 9). If the cookie size becomes a problem, revisit with a server-side ticket store in a new ADR.
- **Proxy:** YARP forwards `/bff/api/{svc}/…` to services through Service Connect, attaching the user's access token as a `Bearer` header. Services validate the JWT (issuer, audience, expiry, scopes) and never trust the BFF blindly.
- **CSRF:** `SameSite=Strict`, plus a required custom header (`X-CSRF: 1`) on non-GET requests, plus an `Origin` check.
- **Logout:** local cookie deletion plus a Cognito `/logout` redirect. Refresh tokens are revoked.
- **SPA:** calls only same-origin `/bff/*`. It never sees tokens. `/bff/user` returns the profile and roles for UI rendering (authorization is still enforced server-side).

### Consequences

- Good, because no token is reachable by JavaScript, removing the XSS-token-theft class of attack.
- Good, because there is no CORS (same origin through CloudFront, ADR-0004).
- Bad, because there is one more service to build, deploy and monitor, with an extra network hop.
- Bad, because cookie size limits apply. Mitigation: request minimal scopes, and drop the ID token after login.

### Confirmation

- Playwright test: after login, `document.cookie` contains no session cookie, and `localStorage`/`sessionStorage` contain no `eyJ` strings.
- ZAP/automated header test: session cookie flags present. A state-changing request without `X-CSRF` gets 403.

## Pros and Cons of the Options

### SPA with in-memory tokens

- Good, because there are fewer components.
- Bad, because an XSS can still read memory or call APIs as the user, and refresh tokens are exposed to JS. Silent renew is fragile without third-party cookies.

### Token-mediating backend

- Bad, because the access token still reaches JS, so it is a weaker version of the BFF.
