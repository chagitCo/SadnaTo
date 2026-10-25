# API design standard (API)

Scope: every HTTP API exposed by a service or the BFF. Sources: MISSION (Backend: Problem Details,
OpenAPI, versioning), ADR-0004, ADR-0012, reference-service §3.

## Rules

- **API-01** The OpenAPI document (`contracts/openapi/v<N>.yaml`) is written or updated before the implementation, committed, and compared in CI against the running service's generated document.
- **API-02** Paths use plural nouns and the major version as a URL segment: `/api/<svc>/v1/orgs/{orgId}/projects/{projectId}`; actions that are not CRUD use a sub-resource (`/tasks/{id}/transitions`).
- **API-03** Within a major version, changes are backward compatible (add optional fields, add endpoints); removing or renaming fields, changing types or tightening validation requires a new major version.
- **API-04** Deprecated endpoints send `Deprecation` and `Sunset` headers and stay available for at least one release after the replacement ships.
- **API-05** All error responses are RFC 9457 Problem Details with a stable `type` URI (`https://errors.workshop.example/<code>`), a `title`, the `status`, and, for validation failures, an `errors` map keyed by field.
- **API-06** Updates and deletes of versioned resources require `If-Match` with the resource `ETag` (the row version); a missing header returns 428 and a mismatch returns 412.
- **API-07** Collections use keyset pagination: request `limit` (default 25, maximum 100) and an opaque, signed `cursor`; responses return `items` and `nextCursor` without a total count.
- **API-08** Status codes: 200 read/update, 201 create with `Location`, 204 delete, 400 malformed or invalid input, 401 unauthenticated, 403 authenticated but not allowed, 404 not found, 409 conflict, 412/428 concurrency, 422 business-rule violation, 429 throttled.
- **API-09** JSON uses camelCase, enums as strings, timestamps as ISO 8601 UTC (`2026-10-25T09:13:18Z`) and identifiers as UUID strings.
- **API-10** A POST that creates a resource accepts an optional `Idempotency-Key` header, and a repeated key returns the original result.
- **API-11** Request bodies have explicit size limits, and every string field has a maximum length in the OpenAPI schema.
- **API-12** Each operation in OpenAPI declares its security requirement (scopes) and documents every Problem Details `type` it can return.

## Example error (reference)

```json
{
  "type": "https://errors.workshop.example/invalid-transition",
  "title": "Invalid status transition",
  "status": 422,
  "detail": "A task cannot move from Todo to Done.",
  "instance": "/api/projects/v1/orgs/…/tasks/…/transitions",
  "traceId": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
}
```

Template for a new endpoint: [templates/api-endpoint.md](../../templates/api-endpoint.md).
