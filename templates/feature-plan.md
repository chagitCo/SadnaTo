# Plan — <UOW-n>: <title>

- **Service(s):** <svc>
- **Stories / ACs:** <US-n: AC-n.1, AC-n.2>
- **Size:** S | M | L (L requires human review of this plan before coding)
- **Branch:** `feat/<svc>-<slug>`

## Goal

<What is true when this UOW is done, in one or two sentences.>

## Design

| Layer | Change |
|---|---|
| Contract (OpenAPI / event schema) | <…> |
| Domain | <…> |
| Application | <…> |
| Infrastructure | <…> |
| Api | <…> |
| Database (`db/<svc>`) | <migrations / routines> |
| Infrastructure as code | <…> |
| Frontend | <…> |

Rules that apply (cite IDs): <ARCH-07, API-06, DB-04, …>

## Tests first

| AC | Test (level, name) | Fails today because |
|---|---|---|
| AC-n.1 | Integration: `<Name>_When<Condition>_<Outcome>` | <…> |

## Increments

1. <smallest change that compiles and has a passing test>
2. <…>

## Risks and rollback

| Risk | Mitigation |
|---|---|
| <…> | <…> |

Rollback: <redeploy previous digest; migrations are expand-only (DB-09)>

## Deferred (explicit)

- <item, reason, where tracked> — or "none"
