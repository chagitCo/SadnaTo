# Service questionnaire — <service-name>

Fill every row. "Default" shows what `new-service` proposes when the human has no preference.
Rows marked ★ have no safe default and block generation until answered.

| # | Question | Answer | Default |
|---|---|---|---|
| 1 ★ | **Purpose**: what business capability does it own? What does it explicitly not own? | | — |
| 2 ★ | **Owning team** (GitHub team handle) and on-call contact | | — |
| 3 ★ | **Consumers**: who calls it (services, BFF, external), sync or async? | | — |
| 4 | **Dependencies**: which services/AWS services does it call or subscribe to? | | none |
| 5 | **Auth model**: user calls via BFF (user JWT), service calls (client credentials + scopes), public? | | user JWT via BFF + service scopes (ADR-0014) |
| 6 ★ | **Tenancy**: tenant-scoped data or global? Tenant id source? | | — |
| 7 ★ | **Data classification**: highest class stored (Public/Internal/Confidential/Restricted); PII? | | — |
| 8 | **Data retention** and deletion requirements | | soft delete + purge after 90 days |
| 9 | **Traffic**: expected RPS (avg/peak), payload sizes, growth | | 50 RPS peak |
| 10 | **Latency target**: p95 reads / writes | | 300 ms / 500 ms |
| 11 | **Availability target** (monthly) | | 99.9% |
| 12 | **RTO / RPO** | | 4 h / 5 min |
| 13 | **Integrations**: third-party APIs, webhooks, files | | none |
| 14 | **Async needs**: events published (names), events consumed, ordering, max acceptable delay | | none |
| 15 | **Database needs**: expected rows per table in 12 months, heavy queries, reporting | | shared RDS instance, own database (ADR-0013) |
| 16 | **Cost limit**: monthly budget for this service per environment | | to be set by owner |
| 17 | **Compliance / residency** constraints | | per Q6 (eu-central-1) |
| 18 | **UI**: does the web app need screens? Which features? | | none |

## Derived decisions (filled by `new-service`)

| Item | Value | Basis |
|---|---|---|
| Service name / namespace | `<svc>` / `Workshop.<Svc>` | ARCH-01 |
| Database | `<svc>` on the environment's shared instance | ADR-0013 |
| Sync API base path | `/api/<svc>/v1` | API-02 |
| Topics/queues | `<env>-<svc>-events`, `<env>-<svc>-<source>-queue` | ADR-0012, AWS-10 |
| ECS sizing (start) | 0.5 vCPU / 1 GB, 2 tasks prod | NFR answers |
| SLOs | from rows 10–11 | OBS-07 |
