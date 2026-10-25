# Units of work — <intent id>

Each UOW is one PR-sized deliverable. Dependencies form a DAG (no cycles).

| ID | Title | Service | Stories / ACs | Depends on | Size (S/M/L) | Definition of done |
|---|---|---|---|---|---|---|
| UOW-1 | | | US-1 (AC-1.1, AC-1.2) | — | M | ACs tested, reviewers clean, docs updated |

```mermaid
flowchart LR
  UOW1 --> UOW2
```

## Deferred work

| Item | Reason | Tracked in |
|---|---|---|
