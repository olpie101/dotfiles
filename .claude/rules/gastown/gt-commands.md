# GT-CC Command & Agent Guide

When `$GT_ROLE` is set, these Claude Code commands and agents are available for Gas Town workflows.

## Commands

| Command | Purpose | Invocation |
|---------|---------|------------|
| `/gt:plan` | Decompose a bead into a design or structured plan | `/gt:plan <bead-id>` |
| `/gt:build` | Execute a plan by spawning builder/validator teams | `/gt:build <path-to-plan>` |
| `/gt:work` | Detect artifacts and route to the right build action | `/gt:work <bead-id>` |
| `/gt:sync` | Bidirectional beads-to-TaskList sync with crash recovery | `/gt:sync [bead-id]` |

## Agent Types

| Agent | Subagent Type | Purpose | Access |
|-------|--------------|---------|--------|
| Research | `gt/gt-research-agent` | Parallel codebase/domain research | Read + write artifacts only |
| Builder | `gt/gt-builder-agent` | Implementation with bead/molecule awareness | Full write |
| Validator | `gt/gt-validator-agent` | Post-builder, self-review, design-review, architecture-review | Read-only |

## When to Use Each Command

### /gt:plan

Use when you need to decompose work before implementation:

- **Polecat** on a `design*` or `implement*` step with a complex bead (priority <= 2 or description > 500 chars)
- **Mayor** or **crew** preparing work for delegation
- Auto-detects mode: DESIGN-SPEC (design-spec formula), INLINE-DESIGN (polecat on design/implement step), PLAN (all other cases)
- Spawns `gt/gt-research-agent` instances in parallel for non-trivial beads
- Spawns `gt/gt-validator-agent` for design review on high-priority beads

### /gt:build

Use when a structured plan already exists:

- Input is a **file path** to a plan (e.g., `specs/nx-abc123-plan.md`), not a bead ID
- Analyzes the plan's dependency graph into execution tiers
- Spawns `gt/gt-builder-agent` per task with tier-based parallelism (1=foreground, 2-3=parallel, 4+=rolling cap 3)
- Spawns `gt/gt-validator-agent` after each builder (post-builder) and at completion (final validation)
- Creates wisps for crash recovery when bead context is available
- Also available as the `gt-build` skill (invoked internally by `/gt:work`)

### /gt:work

Use as the primary entry point for polecats on `implement*` steps:

- Detects existing design/plan artifacts in `.designs/` and `specs/`
- Routes to the appropriate strategy:
  - **Structured plan exists** → invokes `gt-build` skill
  - **Design exists, no tasks** → decomposes and spawns builders directly
  - **No artifacts, complex bead** → suggests `/gt:plan` first
  - **No artifacts, simple bead** → spawns builders from bead description
- Handles self-review by spawning specialized validators (correctness, security, architecture)

### /gt:sync

Use for session bootstrap, live sync, and crash recovery:

- **Bootstrap**: Populates TaskList from beads at session start (after `gt prime`)
- **Live sync**: Propagates status changes between TaskList and beads
- **Crash recovery**: Detects orphaned wisps and re-syncs them into TaskList
- Available to all GT roles

## Command Flow

Typical polecat workflow:
```
gt prime → gt hook → /gt:sync → /gt:work <bead-id>
                                    ↓
                        (detects artifacts, routes to build)
                                    ↓
                        /gt:build or direct builder spawning
                                    ↓
                        gt done (when molecule complete)
```

Typical mayor/crew workflow:
```
gt prime → /gt:sync → /gt:plan <bead-id> → /gt:build <plan-path>
```

## Proactive Activation Rules

When `$GT_ROLE` is set and you are working within a molecule, these rules activate automatically:

| Condition | Action | Mode |
|-----------|--------|------|
| Polecat hits `implement*` step | Suggest `/gt:work $BEAD_ID` | Suggest |
| Polecat on complex bead, no design artifact | Suggest `/gt:plan $BEAD_ID` first | Suggest |
| Design-spec formula step 1 (research) | Suggest `/gt:plan $BEAD_ID` for parallel research | Suggest |
| All molecule steps closed | Verify via `bd ready --mol <mol-id>`, then `gt done` | See `step-discipline.md` |
