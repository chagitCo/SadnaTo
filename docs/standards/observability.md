# Observability standard (OBS)

Scope: logs, traces, metrics, health checks, alarms and SLOs. Sources: MISSION (Observability,
Microservices rule 8), ADR-0012, ADR-0015, reference-service NFR-2/3/7.

## Rules

- **OBS-01** Every service is instrumented with OpenTelemetry (traces, metrics, logs) through `Workshop.Platform.Telemetry`, exporting via OTLP to the ADOT collector, then CloudWatch and X-Ray.
- **OBS-02** W3C trace context (`traceparent`, `tracestate`) propagates across HTTP calls and messages; producers copy it into the event envelope and SNS/SQS message attributes, and consumers continue the trace.
- **OBS-03** Logs are structured JSON via Serilog with the fields `timestamp`, `level`, `message`, `service`, `environment`, `version`, `traceId`, `spanId`, `tenantId` (when known) and `userId` or `clientId` (when known).
- **OBS-04** Log levels: `Error` for faults needing action, `Warning` for handled anomalies, `Information` for business events and request summaries, `Debug` off in production.
- **OBS-05** Each endpoint and message handler emits RED metrics (rate, errors, duration); queues expose depth and age of the oldest message; the outbox exposes pending count and publish lag.
- **OBS-06** Services expose `/health/live` (process up) and `/health/ready` (dependencies reachable); readiness never performs writes.
- **OBS-07** Each service defines SLOs in `docs/slo.md` (availability and latency at minimum) with burn-rate alarms; every alarm links to a runbook section.
- **OBS-08** Dashboards and alarms are defined in Terraform within the service stack, not created by hand in the console.
- **OBS-09** Trace sampling keeps 100% of errors and a configured share of successful requests (production default 10%).
- **OBS-10** Business-significant actions (task assigned, member removed) are logged once at `Information` with identifiers only.

## Minimum alarms per service (reference)

| Alarm | Condition (default) |
|---|---|
| 5xx rate | > 1% for 5 min |
| p95 latency | > SLO target for 10 min |
| DLQ depth | > 0 |
| Oldest message age | > 5 min |
| Outbox publish lag | > 60 s |
| ECS task restarts | > 3 in 15 min |
| SLO burn rate | 2% budget in 1 h, or 5% in 6 h |

Runbook template: [templates/runbook.md](../../templates/runbook.md).
