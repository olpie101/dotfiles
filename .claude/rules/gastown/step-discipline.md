# Step Discipline

Strict step lifecycle enforcement for any role working through molecule steps. Prevents skipped work, unclaimed steps, and premature completion.

Step lifecycle: **Claim → Verify → Work → Close → (repeat)**

## Applicable Roles

| Role | Context |
|------|---------|
| Polecat | Molecule steps on hooked beads |
| Witness | Patrol cycle steps |
| Refinery | Patrol cycle steps |
| Deacon | Patrol cycle steps |

Any role executing molecule steps sequentially is subject to these rules.

## Rule 0: Claim Before Work

**CRITICAL**: A step MUST be claimed and verified before starting ANY work on it.

### How to Claim a Step

1. Run: `bd update <step-bead-id> --claim`
2. If that fails, use the explicit form: `bd update <step-bead-id> --status=in_progress --assignee=$BD_ACTOR`

### Verify Before Working

**CRITICAL**: After claiming, verify that BOTH conditions are true before starting work:

1. **Status is in_progress** — `bd show <step-bead-id>` confirms status
2. **Assignee is self** — `bd show <step-bead-id>` confirms assignee matches `$BD_ACTOR`

If either condition is not met, do NOT proceed. Re-attempt the claim or escalate.

### Enforcement

```
Ready to start work on a step?
  Have you claimed it?
    NO  → Claim it first (bd update <id> --claim)
    YES → Is status in_progress AND assignee is $BD_ACTOR?
            YES → Safe to begin work
            NO  → Do NOT start work. Re-attempt claim or escalate.
```

### Violations

Starting work on an unclaimed or unverified step results in:
- Work on a step that may be assigned to another agent
- Status tracking becomes unreliable
- Molecule progress is misrepresented

## Rule 1: Close Before Claim

**CRITICAL**: The current step MUST be closed before claiming the next step. Do NOT claim the next step while the current one is still open.

### Enforcement

```
Want to move to the next step?
  Is current step closed?
    YES → Claim the next step (Rule 0)
    NO  → Close the current step first
```

### How to Close a Step

1. Ensure all work for the step is complete (code committed, tests passing, etc.)
2. Close the step bead: `bd close <step-bead-id> --reason "completed"`
3. Verify closure: `bd show <step-bead-id>` confirms status is closed
4. Only then claim the next step

### Violations

Claiming a new step while the current one is open results in:
- Parallel step execution that these roles are not designed for
- Lost work if the unclosed step is forgotten
- Incorrect molecule progress tracking

## Polecat Only: All Steps Complete Before Done

**CRITICAL**: This rule applies to polecats only. ALL steps in the attached molecule MUST be complete before calling `gt done`.

Patrol roles do not call `gt done` — see `patrol-discipline.md` for patrol cycle completion.

### Pre-Done Checklist

Before running `gt done`, complete these steps **in order**:

1. **Every step is closed** — `bd ready --mol <mol-id>` shows no open steps
2. **No pending work** — No beads in the molecule remain open or in-progress
3. **Validation passed** — Final validation (if required by formula) has been executed
4. **Close the molecule** — `bd close <mol-id> --reason "completed"` (the molecule is an epic-type bead, sometimes a wisp)
5. **Then call `gt done`** — Only after the molecule itself is closed

### Enforcement

**CRITICAL**: The molecule MUST be closed before calling `gt done`. Calling `gt done` on an open molecule will result in the work bead remaining open causing upstream issues.

```
Ready to call gt done?
  Step 1: Run bd ready --mol <mol-id>
          Are all steps closed?
            NO  → Close remaining steps first
                   For each open step:
                     Can it be completed? → Complete and close it
                     Is it blocked?      → Resolve the blocker
                     Is it no longer needed? → Close with reason "not required"
            YES → Continue

  Step 2: Close the molecule
          Run: bd close <mol-id> --reason "completed"
          Did it succeed?
            NO  → Check for open children (bd show <mol-id>), resolve them
            YES → Continue

  Step 3: Run gt done
```

### Violations

Calling `gt done` without closing all steps and the molecule results in:
- `gt done` failure due to open beads
- Molecule marked complete with unfinished work
- Beads left in limbo (not closed, not tracked)
- Formula cannot properly finalize the molecule

## Deacon/Boot: Never Call gt done

**CRITICAL**: Deacon/boot roles MUST NEVER call `gt done`. The completion check for a boot is `gt boot triage`.

### Enforcement

```
Boot work complete?
  Run: gt boot triage
  Are there issues?
    NO  → All clear. The boot may exit.
    YES → Resolve issues before exiting.
```

### Violations

Calling `gt done` as a deacon/boot results in:
- Incorrect molecule lifecycle (boot molecules are not finalized via `gt done`)
- Broken audit trail for the boot triage process

## Summary

| Rule | Applies To | Invariant | Check Command |
|------|-----------|-----------|---------------|
| Claim Before Work | All | Step claimed and verified before work begins | `bd show <step-bead-id>` |
| Close Before Claim | All | Current step closed before claiming next | `bd show <step-bead-id>` |
| All Steps Before Done | Polecat only | Every step closed before `gt done` | `bd ready --mol <mol-id>` |
| Never gt done | Deacon/boot only | Use `gt boot triage` instead | `gt boot triage` |
