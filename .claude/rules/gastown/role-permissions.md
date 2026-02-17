# Gas Town Role Workflows

Check your role with `echo $GT_ROLE`.

## Role-Specific Command & Agent Access

### Mayor

Primary orchestrator — plans, delegates, monitors.

| Action | Command/Tool | Notes |
|--------|-------------|-------|
| Decompose work | `/gt:plan <bead-id>` | Full plan with team structure |
| Execute plans | `/gt:build <plan-path>` | Spawns builder/validator teams |
| Sync state | `/gt:sync` | Bootstrap + live sync |
| Manage beads | `bd create`, `bd update`, `bd close` | All bead operations |
| Dispatch work | `gt sling <bead-id> <target>` | Send beads to rigs/agents |

The mayor never codes directly. Uses `/gt:plan` → `/gt:build` pipeline.

### Polecat

Single-task executor — works on hooked beads through molecule steps.

| Action | Command/Tool | Notes |
|--------|-------------|-------|
| Start work | `/gt:work <bead-id>` | Primary entry point for `implement*` steps |
| Plan complex work | `/gt:plan <bead-id>` | INLINE-DESIGN mode (abbreviated) |
| Sync on restart | `/gt:sync` | Crash recovery for interrupted work |
| Complete work | `gt done` | Formula handles bead closure |

Typical flow: `gt prime` → `gt hook` → `/gt:sync` → `/gt:work` → `gt done`

Polecats use `/gt:work` which auto-detects artifacts and routes to the right strategy. For complex beads without design artifacts, `/gt:work` will suggest running `/gt:plan` first.

### Crew

Versatile workers — can plan and build within assigned rig.

| Action | Command/Tool | Notes |
|--------|-------------|-------|
| Plan work | `/gt:plan <bead-id>` | PLAN mode with team decomposition |
| Execute plans | `/gt:build <plan-path>` | Direct plan execution |
| Implement directly | `/gt:work <bead-id>` | Same routing as polecat |
| Sync state | `/gt:sync` | All sync scenarios |
| Manage beads | `bd create`, `bd update`, `bd close` | Within assigned rig |

Crew members have the flexibility of both mayor (planning) and polecat (executing).

### Witness

Read-only monitor — patrols and reports.

| Action | Command/Tool | Notes |
|--------|-------------|-------|
| Sync state | `/gt:sync` | Read-only sync for status awareness |
| Check status | `bd show`, `bd ready` | Query bead state |

Witnesses do not use `/gt:plan`, `/gt:build`, or `/gt:work`.

### Refinery

Merge and integration operations.

| Action | Command/Tool | Notes |
|--------|-------------|-------|
| Sync state | `/gt:sync` | For merge conflict awareness |

## Agent Spawning by Role

| Agent | Spawned By | Roles That Trigger |
|-------|-----------|-------------------|
| `gt/gt-research-agent` | `/gt:plan` Step 5 | mayor, crew, polecat |
| `gt/gt-builder-agent` | `/gt:build` Step 6, `/gt:work` Step 4 | mayor, crew, polecat (via /gt:work) |
| `gt/gt-validator-agent` | `/gt:build` Step 7, `/gt:work` Step 5, `/gt:plan` Step 6 | mayor, crew, polecat |
