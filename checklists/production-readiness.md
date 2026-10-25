# Production readiness checklist — <service> <version>

Every item needs evidence (link, path, output). Used by the `production-readiness-review` skill.

## Ownership and documentation
- [ ] Catalog row complete: owner, paths, contracts, runbook (ARCH-01)
- [ ] Runbook covers deploy, rollback, every alarm, DLQ redrive, secret rotation, restore (OBS-07)
- [ ] SLOs defined with error-budget policy (OBS-07)

## Security
- [ ] Threat model current; High threats mitigated and tested; residual risks accepted by a human (SEC-16)
- [ ] Security checklist passed for the release scope; no open Critical/High findings (CR-03)
- [ ] Secrets in Secrets Manager with rotation documented (SEC-08); least-privilege roles (SEC-14)
- [ ] Encryption at rest and in transit verified in Terraform (SEC-17, AWS-06)

## Reliability
- [ ] At least 2 tasks in prod across AZs; autoscaling policy defined
- [ ] Health checks wired to the target group (OBS-06)
- [ ] Timeouts, retries (idempotent only) and circuit breakers on every outbound call (BE-09)
- [ ] DLQ + alarms for every queue; outbox lag alarm (OBS-05)
- [ ] RDS Multi-AZ, PITR, deletion protection (AWS-11); restore drill done in staging (date)
- [ ] Load test against NFR targets in staging (results attached)

## Observability
- [ ] Traces span BFF → service → DB → messages (OBS-01, OBS-02)
- [ ] Dashboards and alarms in Terraform (OBS-08); alarms route to on-call
- [ ] Logs structured with required fields and no sensitive data (OBS-03, SEC-11)

## Delivery
- [ ] Pipeline: required checks green on the release commit (CICD-06)
- [ ] Image attested and verified at deploy (CICD-07); prod environment approval configured (CICD-08)
- [ ] Rollback tested in staging (redeploy previous digest) (CICD-11)
- [ ] Migrations expand/contract for this release (DB-09)

## Decision
- [ ] Go / Go with conditions / No-go — recorded in `docs/ai-dlc/audit.md` with approver
