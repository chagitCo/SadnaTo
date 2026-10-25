# Non-functional requirements — <intent id>

Every NFR has a measurable target and a verification method.

| ID | Category | Requirement | Target | Verification |
|---|---|---|---|---|
| NFR-1 | Performance | p95 latency | < <n> ms at <n> RPS | load test (k6) in staging, CloudWatch p95 |
| NFR-2 | Availability | monthly availability | <99.9%> | SLO + burn-rate alarms (OBS-07) |
| NFR-3 | Durability | RPO / RTO | <5 min / 4 h> | restore drill |
| NFR-4 | Security | <control> | <target> | <test / review> |
| NFR-5 | Privacy | <retention / deletion> | <target> | <test> |
| NFR-6 | Accessibility | WCAG 2.2 AA | 0 serious/critical axe violations | Playwright + axe |
| NFR-7 | i18n | he (RTL) + en | no hard-coded strings | lint rule |
| NFR-8 | Observability | traces/logs/metrics | <coverage> | telemetry tests |
| NFR-9 | Scalability | <…> | <…> | <…> |
| NFR-10 | Cost | monthly cost per env | < <amount> | AWS Budgets alarm |
