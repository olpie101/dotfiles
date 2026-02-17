# Patrol Role Discipline

Patrol roles operate on cyclic molecules. The patrol molecule defines the work — follow it as specified.

## Core Rule

**CRITICAL**: A patrol role MUST follow its patrol molecule as specified. The molecule defines the scope, sequence, and boundaries of each patrol cycle. Do not deviate from it.

## Applicable Roles

| Role | Patrol Type |
|------|------------|
| Witness | Observation patrols |
| Refinery | Integration patrols |
| Deacon | Governance patrols |

Any role operating in a patrol capacity (cyclic molecule assignment) is subject to these rules.

## Pre-Patrol Cleanup

**CRITICAL**: There must only ever be a single patrol epic per role at any given moment. Before creating a new patrol, ALL prior patrol epics must be resolved. Stale epics from previous cycles must be burned, and any current open patrol must be squashed.

### Steps

1. **List prior patrol epics**: Run `bd list --type=epic` and filter to your patrol type (e.g., `witness-patrol`, `refinery-patrol`, `deacon-patrol`)
2. **For each found epic**:
   - **Stale** (from a previous cycle, not current) → Burn it: `bd mol burn <bead-id> --force`
   - **Current** (open, active) → Squash it (follow Squash Checklist below)
3. **Verify no patrol epics remain open** — Only then create a new patrol

### Enforcement

```
Ready to create a new patrol?
  Step 1: Run bd list --type=epic
          Filter to your patrol type
          Any epics found?
            NO  → Safe to create new patrol
            YES → For each epic:
                    Is it stale (previous cycle)?
                      YES → bd mol burn <bead-id> --force
                    Is it the current open patrol?
                      YES → Follow Squash Checklist below

  Step 2: Verify no patrol epics remain open
          All clear? → Create new patrol
```

### Violations

Creating a new patrol with unresolved prior epics results in:
- Duplicate patrol molecules competing for the same work
- Stale beads polluting the bead list
- Broken audit trails across cycles

## Molecule Squash Requirement

**CRITICAL**: A patrol role MUST squash (close) its current molecule before spawning or claiming a new one.

### Squash Checklist

Before starting a new patrol cycle, verify ALL of:

1. **All beads closed** — Every bead in the current molecule is closed (`bd show <mol-id>` shows no open beads)
2. **Epic closed** — The epic associated with the current cycle is closed
3. **No orphaned wisps** — Run `/gt:sync` to confirm no orphaned wisps remain
4. **Molecule closed** — The molecule itself is closed: `bd close <mol-id> --reason "patrol cycle complete"`

### Enforcement

```
Is there an open molecule on your hook?
  YES → Are all beads in it closed?
         YES → Is the epic closed?
                YES → Close the molecule, then proceed to new cycle
                NO  → Close the epic first
         NO  → Complete or close remaining beads first
  NO  → Safe to spawn/claim a new molecule
```

### Violations

Spawning a new molecule while the current one is still open results in:
- Orphaned beads that lose tracking
- Broken audit trails across patrol cycles
- State leaks between cycles

### Commands Reference

| Step | Command |
|------|---------|
| Check current mol status | `bd show <mol-id>` |
| Close remaining beads | `bd close <bead-id> --reason "..."` |
| Close the epic | `bd close <epic-id> --reason "cycle complete"` |
| Sync to verify clean state | `/gt:sync` |
| Close the molecule | `bd close <mol-id> --reason "patrol cycle complete"` |
| Start new cycle | `gt hook <new-mol>` or await assignment |
