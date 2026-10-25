---
name: new-adr
description: Write the next numbered Architecture Decision Record in MADR format from templates/adr.md, update the ADR index, and mark superseded or amended ADRs.
when_to_use: A decision with lasting impact is being made or changed — technology choice, boundary, data model, security model, process change, or any change to a locked decision (CORE-12).
argument-hint: "[decision title]"
---

# New ADR

## When to use

- Any decision that is costly to reverse or that others must follow.
- Every change to a MISSION locked decision or an Accepted ADR (CORE-12): the new ADR supersedes or amends the old one.

## Required inputs (ask if missing)

| Input | Notes |
|---|---|
| Problem statement | One paragraph |
| Options considered | At least two, including "do nothing" when realistic |
| Decision drivers | Security, cost, compatibility, operability, MISSION constraints |
| Decider | The human who approves (recorded at acceptance) |

## Steps

1. Read the ADR index and related ADRs (CORE-01). Find the next free number `NNNN`.
2. Copy [templates/adr.md](../../../templates/adr.md) to `docs/adr/NNNN-<kebab-title>.md`; status `Proposed`, today's date.
3. Fill context, drivers, options with pros/cons, decision, consequences (good and bad) and **Confirmation** (how compliance is checked: test, CI job, review rule).
4. Verify any external fact the decision depends on and cite the source with the date it was read.
5. If it supersedes or amends an ADR: add `Superseded by ADR-NNNN` or an "Amended by ADR-NNNN" note to the old ADR and its index row; do not rewrite the old decision text.
6. Add the row to `docs/adr/README.md`.
7. Append a row to `audit.md` with status "Proposed — pending approval" (CORE-02).

## Artifacts produced

`docs/adr/NNNN-*.md`, updated ADR index, notes on affected ADRs, audit row.

## Checks to run

`scripts/validate-dlc` (ADR index completeness, status values, links).

## Definition of done

The ADR states a single decision with its drivers, alternatives and confirmation method, is listed
in the index, and waits for human acceptance; it changes to `Accepted` only after approval is recorded.
