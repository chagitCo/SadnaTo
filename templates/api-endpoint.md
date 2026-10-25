# Endpoint design — <METHOD> <path>

- **Service / version:** <svc> / v<N>
- **Story / ACs:** <US-n>
- **Operation id:** `<verbNoun>` (e.g. `assignTask`)

## Contract (to add to `contracts/openapi/v<N>.yaml`)

```yaml
/api/<svc>/v1/orgs/{orgId}/<resource>/{id}/<sub-resource>:
  <method>:
    operationId: <operationId>
    summary: <one line>
    security:
      - bff: []                       # user via BFF, or
      - serviceAuth: [<svc>/<scope>]  # service-to-service (SEC-05)
    parameters:
      - { name: orgId, in: path, required: true, schema: { type: string, format: uuid } }
      - { name: If-Match, in: header, required: true, schema: { type: string } }   # if versioned (API-06)
    requestBody:
      required: true
      content:
        application/json:
          schema: { $ref: '#/components/schemas/<Request>' }
    responses:
      '200': { description: OK, headers: { ETag: { schema: { type: string } } }, content: { application/json: { schema: { $ref: '#/components/schemas/<Response>' } } } }
      '400': { $ref: '#/components/responses/ValidationProblem' }
      '401': { $ref: '#/components/responses/Unauthorized' }
      '404': { $ref: '#/components/responses/NotFound' }
      '412': { $ref: '#/components/responses/PreconditionFailed' }
      '422': { $ref: '#/components/responses/BusinessRuleProblem' }
      '428': { $ref: '#/components/responses/PreconditionRequired' }
```

## Behavior

| Item | Value |
|---|---|
| Allowed roles / scopes | <Owner, Member> / <scope> |
| Tenant source | Principal's active org (SEC-02) |
| Business rules | <BR-n → error type> |
| Idempotency | <safe / If-Match / Idempotency-Key> |
| Side effects | <events emitted via outbox> |
| Use case | `<Svc>.Application.<Feature>.<UseCase>` |
| DB routine | `api.<name>` |

## Problem Details types returned

| Status | type | When |
|---|---|---|
| 422 | `https://errors.workshop.example/<code>` | <condition> |

## Tests

| Scenario | Level | Expected |
|---|---|---|
| Happy path | Integration | 200 + body + new ETag + persisted state |
| Invalid input | Integration | 400 with `errors.<field>` |
| Other tenant's id | Integration | 404 |
| Role not allowed | Integration | 403 |
| Stale / missing If-Match | Integration | 412 / 428 |
| Rule violation | Unit + Integration | 422 `<code>` |
