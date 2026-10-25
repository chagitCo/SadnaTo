# Templates

Starting points for every AI-DLC artifact (process.md §3) and for recurring code shapes. Copy, then
fill. Templates contain structure and placeholders (`<…>`), not rules: rules live in
`docs/standards/` and templates cite rule IDs.

| Template | Used by | Produces |
|---|---|---|
| [inception/intent.md](inception/intent.md) | `aidlc-inception` I2 | `docs/intents/<id>/intent.md` |
| [inception/questions.md](inception/questions.md) | I3 | `questions.md` |
| [inception/requirements.md](inception/requirements.md) | I4 | `requirements.md` |
| [inception/user-stories.md](inception/user-stories.md) | I5 | `user-stories.md` |
| [inception/nfr.md](inception/nfr.md) | I6 | `nfr.md` |
| [inception/data-classification.md](inception/data-classification.md) | I7 | `data-classification.md` |
| [threat-model.md](threat-model.md) | I8, `threat-model` | `threat-model.md` |
| [inception/domain-model.md](inception/domain-model.md) | I9 | `domain-model.md` |
| [inception/logical-design.md](inception/logical-design.md) | I10 | `logical-design.md` |
| [adr.md](adr.md) | I11, `new-adr` | `docs/adr/NNNN-*.md` |
| [inception/units-of-work.md](inception/units-of-work.md) | I12 | `units-of-work.md` |
| [service/](service/README.md) | `new-service` | questionnaire, service definition, skeleton list |
| [feature-plan.md](feature-plan.md) | `new-feature` C1 | `construction/<UOW>/plan.md` |
| [api-endpoint.md](api-endpoint.md) | `new-api-endpoint` | endpoint design notes |
| [db-function.sql](db-function.sql) | `new-db-function` | `db/<svc>/migrations/R__api.<name>.sql` |
| [migration.sql](migration.sql) | `new-db-function` | `db/<svc>/migrations/V<ts>__<desc>.sql` |
| [test-plan.md](test-plan.md) | `new-feature`, `test-reviewer` | test plan section of a UOW |
| [construction/test-report.md](construction/test-report.md) | C3 | `test-report.md` |
| [construction/review.md](construction/review.md) | C4 | `review.md` |
| [runbook.md](runbook.md) | `new-service`, O5 | `src/backend/services/<svc>/docs/runbook.md` |
| [operations/slo.md](operations/slo.md) | O4 | `src/backend/services/<svc>/docs/slo.md` |
| [PR description](../.github/pull_request_template.md) | C5 | every PR |
| [Issue forms](../.github/ISSUE_TEMPLATE/) | humans | intents, bugs, change requests |
