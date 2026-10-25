# Security policy

## Reporting a vulnerability

Please **do not** open a public issue for security problems. Report them privately through
GitHub's private vulnerability reporting:
https://github.com/chagitCo/SadnaTo/security/advisories/new

Include what you found, how to reproduce it, the affected component or path, and the impact you
expect. Do not include real customer data or live credentials.

We aim to acknowledge reports within 3 working days and to agree a fix and disclosure timeline
with you after triage. *(Placeholder targets; the repository owner should confirm them.)*

## Supported versions

| Component | Supported |
|---|---|
| `main` branch | Yes |
| Latest release tag of each service (`<service>/vX.Y.Z`) | Yes |
| Older tags | No; upgrade to the latest release |

No service has been released yet.

## How security is handled in this repository

- Security rules: [docs/standards/security.md](docs/standards/security.md); review checklist: [checklists/security.md](checklists/security.md).
- Every PR is reviewed by the `security-reviewer` subagent and a CODEOWNER.
- Threat models are maintained per intent and service (`threat-model` skill).
- AI agents are prevented from reading secret files and from running destructive or production-changing commands ([.claude/hooks/README.md](.claude/hooks/README.md)).

This repository does not claim compliance with any external standard.

## Repository settings to enable (human action)

Private vulnerability reporting, secret scanning with push protection, Dependabot alerts and security
updates, and code scanning (CodeQL). These are settings a repository admin enables; they are
tracked in `docs/ai-dlc/plan.md`.
