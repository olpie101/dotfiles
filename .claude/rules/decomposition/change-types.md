# Change Type Grouping

Tasks are grouped by type of change, NOT by file.

## Change Types

| Change Type | Description | Example Tasks |
|-------------|-------------|---------------|
| **Explore** | Understand existing code | "Explore auth patterns in codebase" |
| **Design** | Decide approach | "Design API structure for user preferences" |
| **Add** | Create new code | "Add UserPreferences model and repository" |
| **Modify** | Change existing code | "Update AuthHandler to support preferences" |
| **Delete** | Remove code | "Remove deprecated LegacyPrefs class" |
| **Test** | Add/update tests | "Add unit tests for UserPreferences" |

## Task Metadata Schema

Each TaskList item should include metadata:

```json
{
  "bead_id": "nx-abc123",
  "change_type": "Add|Modify|Delete|Explore|Design|Test",
  "files": ["src/models/user.ts", "src/handlers/auth.ts"],
  "estimated_complexity": "low|medium|high"
}
```

## Registering Dependencies in Beads

When decomposing a bead into sub-beads or steps, dependencies must be registered in the bead system using `bd dep add`. The hooked bead shows the work item, but the ordering between steps is not automatic — it must be explicitly declared.

```bash
# Step nx-002 depends on nx-001 (nx-001 blocks nx-002)
bd dep add nx-002 nx-001

# Equivalent shorthand
bd dep nx-001 --blocks nx-002

# Cross-project dependency
bd dep add nx-042 external:beads:mol-run-assignee
```

Available dependency types (`-t` flag): `blocks` (default), `tracks`, `related`, `parent-child`, `validates`, `supersedes`, and others.

Check for circular dependencies after adding:
```bash
bd dep cycles
```

## Example Decomposition

For bead `nx-abc123 "Add user preferences API"`:

| ID | Subject | Type | BlockedBy |
|----|---------|------|-----------|
| #1 | Explore existing API patterns | Explore | - |
| #2 | Design preferences API structure | Design | #1 |
| #3 | Add UserPreferences model | Add | #2 |
| #4 | Add PreferencesRepository | Add | #2 |
| #5 | Add PreferencesController | Add | #3, #4 |
| #6 | Modify AuthHandler for preferences | Modify | #3 |
| #7 | Delete deprecated SettingsManager | Delete | #5 |
| #8 | Add unit tests for model/repository | Test | #3, #4 |
| #9 | Add integration tests for API | Test | #5 |

When these are created as sub-beads, register each dependency:
```bash
bd dep add #2 #1
bd dep add #3 #2
bd dep add #4 #2
bd dep add #5 #3
bd dep add #5 #4
# ... and so on for all BlockedBy relationships
```
