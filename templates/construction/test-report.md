# Test report — <UOW-n>

Only commands that were actually run, with their real results (CORE-05).

| # | Command (exact) | Where | Result | Notes |
|---|---|---|---|---|
| 1 | `dotnet test --filter "Category!=Integration"` | `src/backend/services/<svc>` | <n passed, n failed> | |
| 2 | `dotnet test --filter "Category=Integration"` | | | Docker required |
| 3 | `pg_prove …` | | | |
| 4 | `npm test` / `npm run test:e2e` | | | |
| 5 | `scripts/validate-dlc` | repo root | | |

## Not run (and why)

| Check | Reason | Exact command for a human or CI |
|---|---|---|

## AC → test mapping

| AC | Test | Result |
|---|---|---|

## Coverage

Domain/Application line coverage: <n%> (floor 80%, TEST-07)
