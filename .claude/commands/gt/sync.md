---
description: Bidirectional beads-to-TaskList synchronization with wisp-based crash recovery
argument-hint: "[bead-id]"
---

## Variables

BEAD_ID: $ARGUMENTS

> Note: BEAD_ID is optional -- if not provided, sync all beads.

## Instructions

This command performs **bidirectional synchronization** between beads (the persistent source of truth) and Claude Code's TaskList (ephemeral runtime decomposition).

- **Beads** are the durable, canonical record of work items, steps, and status.
- **TaskList** is the in-session runtime decomposition used for orchestration during agent execution.

This command is available to **ALL Gas Town roles** (mayor, polecat, crew, witness, refinery).

It supports three sync scenarios:

1. **Bootstrap** -- Session start (after `gt prime`). Populates TaskList from beads when no TaskList items exist yet.
2. **Live Sync** -- During active work. Propagates status changes from TaskList back to beads and vice versa.
3. **Crash Recovery** -- After a restart or crash. Detects orphaned wisps and re-syncs them into the TaskList.

## Workflow

### Step 1: Determine Sync Scenario

Determine which sync scenario applies:

- **Bootstrap**: TaskList is empty and beads exist.
  - Check by running `TaskList()` -- if no items are returned, this is bootstrap.
- **Live Sync**: TaskList already has items (normal during-work synchronization).
- **Crash Recovery**: BEAD_ID was provided with `--recover` flag, OR open wisps are found without corresponding TaskList items.
  - Check for orphaned wisps by looking for open wisps parented to the current molecule step.

### Step 2: Beads to TaskList (Bootstrap)

Populate the TaskList from beads at session start:

1. Read beads:
   - If BEAD_ID is provided: `bd ready --mol $BEAD_ID --no-daemon`
   - Otherwise: `bd ready --json`
2. For each bead or step returned:
   ```
   TaskCreate(
     subject = bead.title,
     description = bead.description,
     metadata = {
       bead_id: bead.id,
       rig: bead.rig,
       priority: bead.priority
     }
   )
   ```
3. Map bead dependencies to `TaskUpdate(addBlockedBy)` for proper ordering.
4. For beads already marked `in_progress`: `TaskUpdate(status="in_progress")` on the corresponding TaskList item.

### Step 3: TaskList to Beads (Live Sync)

Propagate TaskList status changes back to beads:

For each TaskList item with a status change since last sync:

- **Item started** (status = `in_progress`):
  - `bd update <bead-step-id> --status in_progress` (if `bead_id` present in metadata).
- **Item completed** (status = `completed`):
  - `bd close <bead-step-id> --reason "Completed: <task subject>"` (if `bead_id` present in metadata).
- **Item failed** (status = `failed`):
  - `bd update <bead-step-id> --status blocked` with a note explaining the failure.

### Step 4: Crash Recovery (Wisp Sync)

On restart after a crash, recover orphaned wisps:

1. Find orphaned wisps parented to the current molecule step bead:
   - Run `bd show <parent-bead-id> --json` and inspect children for wisps.
2. For each orphaned wisp:
   - If **no corresponding TaskList item** exists:
     ```
     TaskCreate(
       subject = wisp.title,
       metadata = {
         bead_id: wisp.parent,
         wisp_id: wisp.id
       }
     )
     ```
   - If wisp is `in_progress`: mark the TaskList item as `in_progress`.
   - If wisp is `completed` but TaskList item is missing: create the TaskList item as `completed`.
3. Report recovery summary: N wisps found, M re-synced, K already complete.

### Step 5: Report

Output a sync summary:

```
GT Sync Complete
Direction: [Bootstrap | Live | Recovery]
Beads synced: N
TaskList items: M (N new, K updated)
Wisps recovered: P (if applicable)
Status: [aligned | issues found]
```
