# Persistence Decision Logic

## Wisp-Based Crash Recovery

Wisps are ephemeral child beads created by `/gt:build` for crash recovery. They persist TaskList state across session crashes.

### How Wisps Work

1. **Creation**: The orchestrator (`/gt:build` Step 4) creates one wisp per TaskList item:
   ```bash
   bd create "<task-subject>" --wisp --parent <molecule-step-bead-id>
   ```
2. **Tracking**: Wisp IDs are stored in TaskList metadata via `TaskUpdate(metadata = { wisp_id: "<id>" })`
3. **Closure**: When a builder completes and validation passes, the orchestrator closes the wisp:
   ```bash
   bd close <wisp-id> --reason "completed"
   ```
4. **Recovery**: On crash, `/gt:sync` (crash recovery scenario) detects orphaned wisps and re-syncs them into TaskList

### Key Principle

- **Wisps are created by the orchestrator**, not by builders or validators
- **Wisps represent task-level progress**, not checkpoint metadata
- **Open wisps = incomplete work** — `/gt:sync` recovers them on restart
- If no bead context is available (standalone plan execution), wisp creation is skipped entirely

## Delegation Decision

```
Is task trivial?
  ALL of: ≤3 files, ≤100 lines, no external calls, no approval gates
  YES → Execute inline, no delegation
  NO  → Continue

Does task benefit from fresh context?
  ANY of: context >80% limit, >5 new files needed, unrelated domain
  YES → Delegate to subagent with scoped context
  NO  → Execute inline

Is task parallelizable?
  ALL of: no blockedBy on in-progress tasks, no file conflicts
  YES → Spawn background subagent
  NO  → Sequential execution
```

## Child Bead Creation Rules

When creating a child bead (not a wisp):

1. **Prefix**: Use same prefix as parent (`nx-abc123` → `nx-def456`)
2. **Parent**: Set parent reference (`bd create "..." --parent nx-abc123`)
3. **Metadata**: Copy relevant metadata from parent

## Failure Handling

| Failure Type | Example | Action |
|--------------|---------|--------|
| Transient | Network timeout | Retry (max 3x) |
| Recoverable | Missing file | Adjust context, retry |
| Permanent | Impossible task | Stop, escalate to human/mayor |
| Builder failure | Validation FAIL | Fix cycle (max 2 fix cycles per `/gt:build`) |
