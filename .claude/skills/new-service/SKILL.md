---
name: new-service
description: Create a new microservice — collect the service questionnaire (purpose, consumers, auth, tenancy, data classification, traffic, availability/RTO/RPO, integrations, async needs, cost limits), record the boundary in an ADR and the catalog, and generate the service skeleton from templates/service.
when_to_use: The human asks for a new service or microservice, or an Inception unit of work says "new service".
argument-hint: "[service-name]"
---

# New service

## When to use

- A new bounded context has been approved in Inception (ARCH-01, ARCH-09).
- Not for adding an endpoint or a feature to an existing service (use `new-api-endpoint` / `new-feature`).

## Required inputs (ask if missing)

Collect the full questionnaire in [templates/service/questionnaire.md](../../../templates/service/questionnaire.md).
Ask all unanswered items in one message and propose defaults. These items have no safe default; do
not generate until they are answered:

1. Purpose and bounded context (one paragraph), and what it explicitly does **not** own.
2. Owning team (CODEOWNERS handle).
3. Data classification of the data it stores (highest class).
4. Tenancy: tenant-scoped or global.
5. Consumers (who calls it, sync or async) and dependencies (whom it calls).

## Steps

1. Read the catalog, ADR-0011 and ADR-0016 (CORE-01). Confirm the name is unique and kebab-case.
2. Fill `docs/services/<svc>/service-definition.md` from [templates/service/service-definition.md](../../../templates/service/service-definition.md) with the questionnaire answers.
3. Run `new-adr` for the boundary decision; add the catalog row (owner, database, contracts, paths, runbook, status "Planned").
4. Generate the skeleton listed in [templates/service/README.md](../../../templates/service/README.md):
   - Phase 3 onward: `dotnet new workshop-service -n <Svc> -o src/backend/services/<svc>` once the template pack exists.
   - Until then, create the folders and files listed in that README by hand from the templates, writing `.dlc/version` with the value of `docs/ai-dlc/VERSION`.
5. Create `db/<svc>/` (roles and schemas migration via `new-db-function` conventions) and `infra/services/<svc>/` stack files (no apply, CORE-06).
6. Add CODEOWNERS lines for all three paths and a `svc-<svc>.yml` workflow calling the reusable workflows with path filters (CICD-04).
7. Write `src/backend/services/<svc>/CLAUDE.md` (service context, under 120 lines) and `docs/runbook.md`, `docs/slo.md` from templates.
8. Run the checks below, then the reviewer subagents (CR-01).
9. Update `state.md` and `audit.md` (CORE-02) and open a `feat/` PR.

## Artifacts produced

Service definition, ADR, catalog row, `src/backend/services/<svc>/**`, `db/<svc>/**`,
`infra/services/<svc>/**`, CODEOWNERS entries, workflow, runbook and SLO documents.

## Checks to run

- `scripts/validate-dlc` (catalog paths exist, links, `.dlc/version` present).
- When the SDK is installed: `dotnet build -c Release` and `dotnet test` in the service folder (CORE-05).
- Architecture tests pass (TEST-05); Terraform `fmt` and `validate` pass for the new stack (AWS-08).

## Definition of done

- Questionnaire complete; boundary ADR and catalog row merged with the code.
- Skeleton builds and its tests pass, or the PR states exactly which checks could not run and why.
- Ownership, workflow, runbook and SLO files exist; no TODO or stub is described as complete (CORE-09).
