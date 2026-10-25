# Test plan — <UOW-n or feature>

Rules: TEST-01…TEST-13 in [testing.md](../docs/standards/testing.md).

## Acceptance criteria → tests

| AC | Level | Test name | Asserts |
|---|---|---|---|
| AC-n.1 | Integration | `<Action>_When<Condition>_<Outcome>` | status, body, persisted state, events |

## Failure paths (TEST-03)

| Scenario | Level | Test name |
|---|---|---|
| Invalid input | | |
| Unauthenticated / wrong role | | |
| Other tenant's resource → 404 | | |
| Conflict / stale version (409/412/428) | | |
| Dependency down / timeout | | |
| Duplicate message (consumer) | | |

## Database (pgTAP)

| Routine | Happy path | Error codes | Tenant isolation | Privileges |
|---|---|---|---|---|
| `api.<name>` | | | | |

## Frontend

| Component / flow | Test | Accessibility check |
|---|---|---|
| | Vitest + Testing Library (query by role) | axe in Playwright |

## Test data and determinism

- Builders: <names>
- Time: fake `TimeProvider` at <instant>
- Containers: PostgreSQL 18 via Testcontainers, migrations applied by Flyway

## Example shapes (reference)

```csharp
[Fact]
public async Task AssignTask_WhenAssigneeIsViewer_ReturnsInvalidAssignee()
{
    // Arrange
    var org = await Given.OrganizationWithMembers(owner: "o", viewer: "v");
    var task = await Given.Task(org);
    // Act
    var response = await Client.As(org.Owner).PutAsJsonAsync(TaskAssigneeUrl(task), new { userId = org.Viewer.Id },
        headers: IfMatch(task.ETag));
    // Assert
    await Then.ProblemAsync(response, 422, "invalid-assignee");
    (await Db.OutboxCount(org)).Should().Be(0);
}
```

```sql
-- pgTAP
SELECT throws_ok($$ SELECT api.task_assign('<tenantB>', '<actor>', '<taskOfTenantA>', 1, '<user>') $$,
                 'P0002', 'task-not-found', 'tenant B cannot assign tenant A task');
```
