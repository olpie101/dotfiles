# TaskList Decomposition Pattern

## Overview

TaskList provides ephemeral sub-task orchestration during agent execution. It is NOT a mirror of beads — beads are the persistent source of truth, TaskList items are runtime decompositions.

## Beads-to-TaskList Bridge

Use `/gt:sync` for bidirectional synchronization. Three scenarios:

| Scenario | When | What Happens |
|----------|------|-------------|
| **Bootstrap** | Session start (after `gt prime --hook`) | Populates TaskList from beads |
| **Live sync** | During active work | Propagates status changes both directions |
| **Crash recovery** | After restart | Detects orphaned wisps, re-syncs to TaskList |

### Bootstrap (manual, without /gt:sync)

```
bd ready --json
    ↓
For each bead:
    TaskCreate(
        subject = bead.title,
        description = bead.description,
        metadata = {bead_id, rig, priority}
    )
    ↓
Map bead dependencies to blockedBy
```

### Live Sync

| Event | Action |
|-------|--------|
| TaskList item started | `bd update <id> --status in_progress` |
| TaskList item completed | `bd close <id> --reason "..."` |
| New bead created | `TaskCreate` with bead metadata |
| Bead closed externally | `TaskUpdate(status=completed)` |

## Wisp Recovery Principle

Wisps provide crash recovery for TaskList state:

- `/gt:build` creates one wisp per TaskList item (orchestrator-driven, not builder-driven)
- Open wisps after a crash = incomplete work
- `/gt:sync` recovers orphaned wisps into TaskList on restart
- Wisps replace the old checkpoint-metadata approach entirely

## Key Principles

1. **Beads are source of truth** — TaskList is ephemeral runtime state
2. **Group by change type** — Not by file (see `change-types.md`)
3. **Proper dependencies** — Use blockedBy for ordering
4. **Metadata for tracking** — Include bead_id, change_type, files, wisp_id
5. **Use /gt:sync** — The canonical mechanism for bidirectional sync and crash recovery
6. **Wisps for persistence** — Crash recovery via wisps, not checkpoint metadata
