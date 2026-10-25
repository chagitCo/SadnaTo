# Runbook — <service>

- **Owner / on-call:** <@org/team> / <rotation link>
- **Dashboards:** <CloudWatch dashboard name per env>
- **SLOs:** `docs/slo.md` (same folder as this runbook)
- **Paths:** `src/backend/services/<svc>/`, `db/<svc>/`, `infra/services/<svc>/`

## Service overview

<What it does, dependencies (sync and async), data stores.>

## Deploy and rollback

| Action | How | Who |
|---|---|---|
| Deploy | Merge to `main` (dev); tag `<svc>/vX.Y.Z` (staging → prod with approval) | CI / human approver |
| Roll back | Re-run the deploy job of the previous tag (same digest); migrations are expand-only (DB-09) | Human |
| Pause deploys | Disable the service workflow in GitHub | Human |

## Alarms → actions

| Alarm | Meaning | First checks | Fix / escalation |
|---|---|---|---|
| 5xx rate | <…> | Logs by traceId, recent deploys | Roll back if correlated with deploy |
| p95 latency | <…> | DB Performance Insights, dependency latency | <…> |
| DLQ depth > 0 | Messages failed 5 times | Inspect message (no PII in tickets), fix cause | Redrive (below) |
| Outbox lag | Events not published | SNS errors, dispatcher logs | <…> |

## Procedures

### DLQ redrive

1. Identify the failure cause from logs (trace id in message attributes).
2. Deploy the fix.
3. Start a redrive from the DLQ to the source queue (console or `aws sqs start-message-move-task`, run by a human).

### Secret rotation

<Secrets Manager rotation steps; restart policy.>

### Database restore (point in time)

<Restore to a new instance, verify, switch, by a human; drill quarterly in staging.>

## Known limitations

- <…>
