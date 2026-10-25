# SLOs — <service>

Defined per OBS-07. Alarms live in `infra/services/<svc>/` (OBS-08).

| SLI | Definition | SLO (30-day) | Error budget | Burn-rate alarms |
|---|---|---|---|---|
| Availability | successful (non-5xx) requests / all requests at the ALB | 99.9% | 43 min | 2% in 1 h (page), 5% in 6 h (ticket) |
| Latency | requests under <300 ms> (reads) / all reads | 95% | 5% | p95 > target for 10 min |
| Event freshness | events processed within <5 s> of publish | 95% | 5% | oldest message age > 5 min |

## Error budget policy

When the budget is exhausted: <freeze feature releases for the service; reliability work first; owner decides with on-call>.

## Review

<Quarterly review date and owner.>
