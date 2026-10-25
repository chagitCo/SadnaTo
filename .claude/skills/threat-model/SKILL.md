---
name: threat-model
description: Create or update a STRIDE threat model — data-flow diagram with trust boundaries, threats per element, mitigations mapped to rule IDs and tests, and residual risk for human acceptance.
when_to_use: Inception stage I8, or any change that adds a trust boundary, data store, external integration or data class (SEC-16).
argument-hint: "[intent folder or service]"
---

# Threat model (STRIDE)

## When to use

- Every new intent that touches data or interfaces; every new service.
- Updates when SEC-16 triggers. Small internal refactors without new flows do not need one.

## Required inputs (ask if missing)

| Input | Source |
|---|---|
| Scope (service/feature) and its user stories | Intent folder |
| Data classification | `data-classification.md` (must exist first) |
| Components and flows | Logical design or existing architecture |
| Existing threat model, if updating | e.g. `docs/ai-dlc/inception/reference-service.md` §7 |

## Steps

1. Read the inputs and [security](../../../docs/standards/security.md) (CORE-01).
2. Copy [templates/threat-model.md](../../../templates/threat-model.md).
3. Draw the data-flow diagram (Mermaid) with external entities, processes, data stores, flows and numbered trust boundaries (TB1…).
4. For each element crossing a boundary, walk STRIDE: Spoofing, Tampering, Repudiation, Information disclosure, Denial of service, Elevation of privilege.
5. For each threat: asset, likelihood × impact → risk (High/Medium/Low), mitigation (cite rule IDs or ADRs), the test or evidence that proves it, residual risk.
6. Every High threat needs a mitigation **and** a test ID; residual Medium/High risks go to the human for explicit acceptance (record in `audit.md`).
7. Feed new mitigations back into stories (acceptance criteria) or units of work.
8. Ask `security-reviewer` to review the model.

## Artifacts produced

`threat-model.md` in the intent folder (or service docs), new ACs/UOWs for mitigations, audit row for accepted residual risks.

## Checks to run

`scripts/validate-dlc` (links and rule IDs exist); traceability: each High threat → test ID present in the test plan.

## Definition of done

All boundaries and flows are covered by STRIDE, each threat has an owner-ready mitigation and
verification, residual risks are listed for acceptance, and the reviewer reports no unaddressed Critical/High item.
