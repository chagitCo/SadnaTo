# Service definition — <service-name>

- **Status:** Planned | Active | Deprecated
- **Owner:** <@org/team>
- **Bounded context:** <name>
- **ADR:** <link to boundary ADR>
- **DLC version at generation:** <value of docs/ai-dlc/VERSION>

## Purpose

<One paragraph: the capability it owns.>

**Not owned:** <capabilities that belong elsewhere and where they live>

## Interfaces

| Kind | Name / path | Version | Consumers / producers | Contract file |
|---|---|---|---|---|
| Sync API | `/api/<svc>/v1` | v1 | <BFF, services> | `src/backend/services/<svc>/contracts/openapi/v1.yaml` |
| Event published | `<Name>` | v1 | <consumers> | `contracts/events/<name>.v1.schema.json` |
| Event consumed | `<Name>` | v1 | from <producer> | contract test in `tests/<Svc>.Contract.Tests` |

## Data

| Store | Classification | Tenancy | Retention |
|---|---|---|---|
| `<svc>` database | <highest class> | tenant-scoped / global | <policy> |

## Quality targets

| Target | Value |
|---|---|
| Availability | <99.9%> |
| Latency p95 (read / write) | <300 / 500 ms> |
| RTO / RPO | <4 h / 5 min> |
| Peak load | <RPS> |
| Monthly cost limit (prod) | <amount> |

## Paths

`src/backend/services/<svc>/`, `db/<svc>/`, `infra/services/<svc>/`, `.github/workflows/svc-<svc>.yml`

## Consistency notes

<For every use case involving another service: expected delay, failure handling (ARCH-08).>
