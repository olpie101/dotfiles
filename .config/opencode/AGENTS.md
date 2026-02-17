# AGENTS.md

**Core principles**: Read and understand code before modifying it. Never assume anything about the environment, codebase, or configuration — always verify. Avoid over-engineering; make only changes that are directly requested or clearly necessary.

CRITICAL: If you belong to Gas Town (i.e., `GT_ROLE` env is set), run `gt prime --hook` first, then run `gt hook`. You are not to deviate from the provided instructions, NO EXCEPTIONS. If GT_ROLE is set, you MUST RUN these two commands at the begining of every session, before any other step.

CRITICAL: directive 0 -  if you are on patrol you must ensure that there are no old wisps (epics or steps) related to your patrol. You must clean old work up. 
CRITICAL: directive 1 -  if you are on patrol you must not stop no matter the circumstances. You are an an autonomous agent and nobody is babysitting your progress
CRITICAL: directive 2 - if you are on patrol, regardless of prior cycles you may not create batch scripts to process cycles that skip all the steps. For every cycle you generate you must execute each step as instructed regardless of prior cycles.
---

## Gas Town Agent Context

### Detection

You are a Gas Town agent if the `GT_ROLE` environment variable is set. Check with `echo $GT_ROLE`.

### Mandatory Priming and Hook

**CRITICAL**: If you are a Gas Town agent and have NOT yet run `gt prime` in this session:

1. Run `gt prime --hook` IMMEDIATELY before any other work
2. Run `gt hook` to retrieve your work instructions
3. Follow the work instructions returned by `gt hook` — this is your assigned task

The output of `gt hook` defines what work must be executed. Do not proceed without it.

### Molecule-Aware Commands

**CRITICAL**: When you have a molecule attached to your hook, ALWAYS use `bd ready --mol <molecule-id>` instead of a plain `bd ready`. The molecule-scoped variant shows what is next within your assigned work. A plain `bd ready` lacks molecule context and may return irrelevant results.

### Project Context Loading

**CRITICAL**: If your role is `polecat` or `crew`, check for and read `PROJECT_CONTEXT.md` at the repository root after priming (if it exists). This file contains project-specific build commands, architecture notes, and development patterns that are essential for correct implementation work.

### Deacon Plugin Loading

**CRITICAL**: If your role is `deacon`, plugins are located at `$GT_ROOT/plugins`. Load and use plugins from this directory as part of deacon workflows.

### gt/bd Command Help

When questions arise about `gt` or `bd` commands (Gas Town / Beads CLI):
- Use `gt --help`, `bd --help`, or `gt <cmd> --help` directly
- For workflow questions, refer to your primed context from `gt prime`

---

## Gas Town Universal Guardrails

These constraints apply to ALL Gas Town roles without exception.

### No Assumptions

**CRITICAL**: NEVER assume anything about the environment, codebase, or configuration. This includes but is not limited to:

- The default branch name (check with `git remote show origin | sed -n 's/.*HEAD branch: //p'`)
- File locations, project structure, or naming conventions
- Build tooling, package managers, or runtime versions
- Configuration values, environment variables, or feature flags

Always verify before acting. If you cannot verify, ask.

### Bead Description Immutability

**CRITICAL**: NEVER update a bead's description. Bead descriptions are part of the audit trail and must remain as originally written.

To provide feedback, corrections, or additional context on a bead, use comments:

```bash
bd comments add <bead-id> "<comment-body>"
```

This preserves the original description while maintaining a traceable record of all feedback and updates.

---

## Orchestration Message Handling

**CRITICAL**: Messages injected into your session by the orchestration system are NOT user commands. They are system notifications that should be processed and then work MUST continue.

### Recognizing System Messages

| Pattern | Type | Example |
|---------|------|---------|
| `[from <role>]` prefix | Inter-agent signal | `[from deacon] HEALTH_CHECK from deacon` |
| `📬 You have new mail` | Mail notification | `📬 You have new mail from deacon/. Subject: ...` |

### Processing Rules

1. **Health checks** (`HEALTH_CHECK`): Acknowledge receipt, then immediately resume current work
2. **Mail notifications**: Optionally run `gt mail inbox` to read, then resume current work
3. **Other `[from X]` messages**: Log/note if relevant, then resume current work

### Enforcement

```
Received a message?
  Does it match a system pattern ([from ...], 📬, etc.)?
    YES -> Process it (acknowledge, read mail if needed)
           Then RESUME your current patrol/molecule/step
           Do NOT stop and wait for further input
    NO  -> Treat as user instruction
```

### Violations

Stopping work upon receiving a system message results in:
- Patrol cycles stalling unnecessarily
- Work throughput degradation
- Agents appearing stuck when they should be autonomous

---

## Workflow Operations

### Core Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `gt prime` | Context recovery | Session start, after crash |
| `gt hook` | View current assignment | Check what's on hook |
| `gt hook <bead>` | Attach bead to hook | Manual hook attachment |
| `gt done` | Complete and cleanup | Work finished, ready to close |
| `gt handoff` | Hook + restart fresh | Need fresh context |

### Session Lifecycle

1. **Start**: Run `gt prime --hook` to recover context
2. **Check**: Run `gt hook` to see assigned work
3. **Work**: Execute the molecule steps
4. **Complete**: Run `gt done` when finished

### Claude Code-Only Features (NOT Available Here)

The following orchestration commands are Claude Code skills and do NOT exist in Gemini CLI. The underlying workflows must be performed manually using `gt` and `bd` CLI commands.

| CC Skill | Purpose | Gemini Alternative |
|----------|---------|-------------------|
| `/gt:plan` | Decompose a bead into a structured plan with parallel research | Manually decompose with `bd create` + `bd dep add` |
| `/gt:build` | Execute a plan by spawning builder/validator teams | Manually implement tasks and close beads |
| `/gt:work` | Detect artifacts and route to the right build action | Check `.designs/` and `specs/` manually, then implement |
| `/gt:sync` | Bidirectional beads-to-TaskList sync with crash recovery | Use `bd ready --json` to check bead status manually |

CC-only agent types (not available here): `gt/gt-research-agent`, `gt/gt-builder-agent`, `gt/gt-validator-agent`.

---

## Step Discipline

Strict step lifecycle enforcement for any role working through molecule steps. Prevents skipped work, unclaimed steps, and premature completion.

Step lifecycle: **Claim -> Verify -> Work -> Close -> (repeat)**

### Applicable Roles

| Role | Context |
|------|---------|
| Polecat | Molecule steps on hooked beads |
| Witness | Patrol cycle steps |
| Refinery | Patrol cycle steps |
| Deacon | Patrol cycle steps |

Any role executing molecule steps sequentially is subject to these rules.

### Rule 0: Claim Before Work

**CRITICAL**: A step MUST be claimed and verified before starting ANY work on it.

#### How to Claim a Step

1. Run: `bd update <step-bead-id> --claim`
2. If that fails, use the explicit form: `bd update <step-bead-id> --status=in_progress --assignee=$BD_ACTOR`

#### Verify Before Working

**CRITICAL**: After claiming, verify that BOTH conditions are true before starting work:

1. **Status is in_progress** — `bd show <step-bead-id>` confirms status
2. **Assignee is self** — `bd show <step-bead-id>` confirms assignee matches `$BD_ACTOR`

If either condition is not met, do NOT proceed. Re-attempt the claim or escalate.

#### Enforcement

```
Ready to start work on a step?
  Have you claimed it?
    NO  -> Claim it first (bd update <id> --claim)
    YES -> Is status in_progress AND assignee is $BD_ACTOR?
            YES -> Safe to begin work
            NO  -> Do NOT start work. Re-attempt claim or escalate.
```

#### Violations

Starting work on an unclaimed or unverified step results in:
- Work on a step that may be assigned to another agent
- Status tracking becomes unreliable
- Molecule progress is misrepresented

### Rule 1: Close Before Claim

**CRITICAL**: The current step MUST be closed before claiming the next step. Do NOT claim the next step while the current one is still open.

#### Enforcement

```
Want to move to the next step?
  Is current step closed?
    YES -> Claim the next step (Rule 0)
    NO  -> Close the current step first
```

#### How to Close a Step

1. Ensure all work for the step is complete (code committed, tests passing, etc.)
2. Close the step bead: `bd close <step-bead-id> --reason "completed"`
3. Verify closure: `bd show <step-bead-id>` confirms status is closed
4. Only then claim the next step

#### Violations

Claiming a new step while the current one is open results in:
- Parallel step execution that these roles are not designed for
- Lost work if the unclosed step is forgotten
- Incorrect molecule progress tracking

### Polecat Only: All Steps Complete Before Done

**CRITICAL**: This rule applies to polecats only. ALL steps in the attached molecule MUST be complete before calling `gt done`.

Patrol roles do not call `gt done` — see Patrol Discipline section for patrol cycle completion.

#### Pre-Done Checklist

Before running `gt done`, complete these steps **in order**:

1. **Every step is closed** — `bd ready --mol <mol-id>` shows no open steps
2. **No pending work** — No beads in the molecule remain open or in-progress
3. **Validation passed** — Final validation (if required by formula) has been executed
4. **Close the molecule** — `bd close <mol-id> --reason "completed"` (the molecule is an epic-type bead, sometimes a wisp)
5. **Then call `gt done`** — Only after the molecule itself is closed

#### Enforcement

**CRITICAL**: The molecule MUST be closed before calling `gt done`. Calling `gt done` on an open molecule will result in the work bead remaining open causing upstream issues.

```
Ready to call gt done?
  Step 1: Run bd ready --mol <mol-id>
          Are all steps closed?
            NO  -> Close remaining steps first
                   For each open step:
                     Can it be completed? -> Complete and close it
                     Is it blocked?      -> Resolve the blocker
                     Is it no longer needed? -> Close with reason "not required"
            YES -> Continue

  Step 2: Close the molecule
          Run: bd close <mol-id> --reason "completed"
          Did it succeed?
            NO  -> Check for open children (bd show <mol-id>), resolve them
            YES -> Continue

  Step 3: Run gt done
```

#### Violations

Calling `gt done` without closing all steps and the molecule results in:
- `gt done` failure due to open beads
- Molecule marked complete with unfinished work
- Beads left in limbo (not closed, not tracked)
- Formula cannot properly finalize the molecule

### Deacon/Boot: Never Call gt done

**CRITICAL**: Deacon/boot roles MUST NEVER call `gt done`. The completion check for a boot is `gt boot triage`.

#### Enforcement

```
Boot work complete?
  Run: gt boot triage
  Are there issues?
    NO  -> All clear. The boot may exit.
    YES -> Resolve issues before exiting.
```

#### Violations

Calling `gt done` as a deacon/boot results in:
- Incorrect molecule lifecycle (boot molecules are not finalized via `gt done`)
- Broken audit trail for the boot triage process

### Summary

| Rule | Applies To | Invariant | Check Command |
|------|-----------|-----------|---------------|
| Claim Before Work | All | Step claimed and verified before work begins | `bd show <step-bead-id>` |
| Close Before Claim | All | Current step closed before claiming next | `bd show <step-bead-id>` |
| All Steps Before Done | Polecat only | Every step closed before `gt done` | `bd ready --mol <mol-id>` |
| Never gt done | Deacon/boot only | Use `gt boot triage` instead | `gt boot triage` |

---

## Patrol Discipline

Patrol roles operate on cyclic molecules. The patrol molecule defines the work — follow it as specified.

### Core Rule

**CRITICAL**: A patrol role MUST follow its patrol molecule as specified. The molecule defines the scope, sequence, and boundaries of each patrol cycle. Do not deviate from it.

### Applicable Roles

| Role | Patrol Type |
|------|------------|
| Witness | Observation patrols |
| Refinery | Integration patrols |
| Deacon | Governance patrols |

Any role operating in a patrol capacity (cyclic molecule assignment) is subject to these rules.

### Pre-Patrol Cleanup

**CRITICAL**: There must only ever be a single patrol epic per role at any given moment. Before creating a new patrol, ALL prior patrol epics must be resolved. Stale epics from previous cycles must be burned, and any current open patrol must be squashed.

#### Steps

1. **List prior patrol epics**: Run `bd list --type=epic` and filter to your patrol type (e.g., `witness-patrol`, `refinery-patrol`, `deacon-patrol`)
2. **For each found epic**:
   - **Stale** (from a previous cycle, not current) -> Burn it: `bd mol burn <bead-id> --force`
   - **Current** (open, active) -> Squash it (follow Squash Checklist below)
3. **Verify no patrol epics remain open** — Only then create a new patrol

#### Enforcement

```
Ready to create a new patrol?
  Step 1: Run bd list --type=epic
          Filter to your patrol type
          Any epics found?
            NO  -> Safe to create new patrol
            YES -> For each epic:
                    Is it stale (previous cycle)?
                      YES -> bd mol burn <bead-id> --force
                    Is it the current open patrol?
                      YES -> Follow Squash Checklist below

  Step 2: Verify no patrol epics remain open
          All clear? -> Create new patrol
```

#### Violations

Creating a new patrol with unresolved prior epics results in:
- Duplicate patrol molecules competing for the same work
- Stale beads polluting the bead list
- Broken audit trails across cycles

### Molecule Squash Requirement

**CRITICAL**: A patrol role MUST squash (close) its current molecule before spawning or claiming a new one.

#### Squash Checklist

Before starting a new patrol cycle, verify ALL of:

1. **All beads closed** — Every bead in the current molecule is closed (`bd show <mol-id>` shows no open beads)
2. **Epic closed** — The epic associated with the current cycle is closed
3. **No orphaned wisps** — Confirm no orphaned wisps remain
4. **Molecule closed** — The molecule itself is closed: `bd close <mol-id> --reason "patrol cycle complete"`

#### Enforcement

```
Is there an open molecule on your hook?
  YES -> Are all beads in it closed?
         YES -> Is the epic closed?
                YES -> Close the molecule, then proceed to new cycle
                NO  -> Close the epic first
         NO  -> Complete or close remaining beads first
  NO  -> Safe to spawn/claim a new molecule
```

#### Violations

Spawning a new molecule while the current one is still open results in:
- Orphaned beads that lose tracking
- Broken audit trails across patrol cycles
- State leaks between cycles

#### Commands Reference

| Step | Command |
|------|---------|
| Check current mol status | `bd show <mol-id>` |
| Close remaining beads | `bd close <bead-id> --reason "..."` |
| Close the epic | `bd close <epic-id> --reason "cycle complete"` |
| Close the molecule | `bd close <mol-id> --reason "patrol cycle complete"` |
| Start new cycle | `gt hook <new-mol>` or await assignment |

---

## Role Workflows

Check your role with `echo $GT_ROLE`.

### Mayor

Primary orchestrator — plans, delegates, monitors. Never codes directly.

| Action | Command | Notes |
|--------|---------|-------|
| Manage beads | `bd create`, `bd update`, `bd close` | All bead operations |
| Dispatch work | `gt sling <bead-id> <target>` | Send beads to rigs/agents |
| Check status | `bd show`, `bd ready` | Query bead state |
| Register deps | `bd dep add <id> <dep-id>` | Ordering between steps |

In Claude Code, mayors also use `/gt:plan` and `/gt:build` for orchestration. In Gemini, decompose and delegate manually using `bd create` and `gt sling`.

### Polecat

Single-task executor — works on hooked beads through molecule steps.

| Action | Command | Notes |
|--------|---------|-------|
| Start session | `gt prime --hook` | Context recovery |
| Check assignment | `gt hook` | View current work |
| Claim step | `bd update <id> --claim` | Before starting work |
| Close step | `bd close <id> --reason "..."` | After completing work |
| Complete work | `gt done` | Only after all steps + molecule closed |

Typical flow: `gt prime --hook` -> `gt hook` -> claim step -> work -> close step -> (repeat) -> close molecule -> `gt done`

In Claude Code, polecats use `/gt:work` which auto-detects artifacts and routes to the right strategy. In Gemini, check `.designs/` and `specs/` manually for existing artifacts, then implement directly.

### Crew

Versatile workers — can plan and build within assigned rig.

| Action | Command | Notes |
|--------|---------|-------|
| Manage beads | `bd create`, `bd update`, `bd close` | Within assigned rig |
| Check status | `bd show`, `bd ready --mol <id>` | Query state |
| Register deps | `bd dep add` | Task ordering |

Crew members have the flexibility of both mayor (planning) and polecat (executing). In Claude Code, crew also uses `/gt:plan`, `/gt:build`, `/gt:work`, and `/gt:sync`. In Gemini, perform these workflows manually.

### Witness

Read-only monitor — patrols and reports.

| Action | Command | Notes |
|--------|---------|-------|
| Check status | `bd show`, `bd ready` | Query bead state |

Witnesses do not plan, build, or implement. They observe and report.

### Refinery

Merge and integration operations.

| Action | Command | Notes |
|--------|---------|-------|
| Check status | `bd show`, `bd ready` | For merge conflict awareness |

---

## Routing

Routing is handled automatically by the `gt`/`bd` CLI. Agents do not need to understand the internal routing mechanism. However, when creating a bead in a **different rig** from the current one, the agent must specify either the `--rig <name>` flag or use the correct prefix.

### Cross-Rig Bead Creation

```bash
# By rig name
bd create "Fix auth bug" -d "..." --rig nexus

# By prefix (prefix determines the target rig)
bd create "Fix auth bug" -d "..." --prefix nx
```

If neither `--rig` nor `--prefix` is provided, the bead is created in the current rig context.

### Prefix Semantics

| Prefix | Target | Description |
|--------|--------|-------------|
| `hq-` | Town (`.`) | Town-level/cross-cutting work |
| `hq-cv-` | Town (`.`) | Town-level convoys |
| `<rig>-` | Rig path | Project-specific work |

---

## Task Decomposition

### Change Types

Tasks are grouped by type of change, NOT by file.

| Change Type | Description | Example Tasks |
|-------------|-------------|---------------|
| **Explore** | Understand existing code | "Explore auth patterns in codebase" |
| **Design** | Decide approach | "Design API structure for user preferences" |
| **Add** | Create new code | "Add UserPreferences model and repository" |
| **Modify** | Change existing code | "Update AuthHandler to support preferences" |
| **Delete** | Remove code | "Remove deprecated LegacyPrefs class" |
| **Test** | Add/update tests | "Add unit tests for UserPreferences" |

### Task Metadata Schema

Each task/bead should include metadata:

```json
{
  "bead_id": "nx-abc123",
  "change_type": "Add|Modify|Delete|Explore|Design|Test",
  "files": ["src/models/user.ts", "src/handlers/auth.ts"],
  "estimated_complexity": "low|medium|high"
}
```

### Registering Dependencies in Beads

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

### Example Decomposition

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

---

## Delegation & Context Provision

### Delegation Decision

```
Is task trivial?
  ALL of: <=3 files, <=100 lines, no external calls, no approval gates
  YES -> Execute inline, no delegation
  NO  -> Continue

Does task benefit from fresh context?
  ANY of: context >80% limit, >5 new files needed, unrelated domain
  YES -> Delegate with scoped context (create sub-bead)
  NO  -> Execute inline

Is task parallelizable?
  ALL of: no dependency on in-progress tasks, no file conflicts
  YES -> Can be worked in parallel by another agent
  NO  -> Sequential execution
```

### Scoped Context

When delegating tasks, provide file paths + brief summaries (not full file contents):

```
ScopedContext {
  files: [
    { path: "src/auth/handler.ts", summary: "Main auth handler, processes JWT tokens" },
    { path: "src/models/user.ts", summary: "User model with preferences field" }
  ]
}
```

**Include files if ANY of:**
- Explicitly mentioned in bead/task description
- Touched (read/modified) during exploration
- Explicitly marked relevant

**Context budget by task type:**

| Signal | Budget |
|--------|--------|
| Change type = Explore/Design | Higher (more files, longer summaries) |
| Change type = Delete/Test | Lower (fewer files, brief summaries) |
| Estimated files touched > 10 | Expand budget |
| Simple single-file change | Minimal context |

### Parent Summary

When delegating, provide a full context brief including:
- **Decisions made** and rationale
- **Constraints** from spec/bead
- **Patterns discovered** during exploration
- **Files touched** with relevance notes

### Result Flow

**Builders** report completion by:
1. Returning a summary of changes (files modified, key decisions)
2. Closing their bead/wisp: `bd close <id> --reason "completed"`

**The orchestrator** (not the builder) writes bead notes:
- `bd note add <bead-id> "Implementation complete: <summary>"` after builders finish

**Research artifacts** are written to disk:
- Output files in `{spec_directory}/research-*.md`
- The orchestrator reads and synthesizes these into the design/plan

**Discovery propagation** between builders in the same run:
- Pass `prior_discoveries` to subsequent builders
- This includes key decisions and patterns from earlier completed builders

### Child Bead Creation Rules

When creating a child bead (not a wisp):

1. **Prefix**: Use same prefix as parent (`nx-abc123` -> `nx-def456`)
2. **Parent**: Set parent reference (`bd create "..." --parent nx-abc123`)
3. **Metadata**: Copy relevant metadata from parent

### Wisp-Based Crash Recovery

Wisps are ephemeral child beads used for crash recovery. They persist task-level progress across session crashes.

#### How Wisps Work

1. **Creation**: The orchestrator creates one wisp per task item:
   ```bash
   bd create "<task-subject>" --wisp --parent <molecule-step-bead-id>
   ```
2. **Tracking**: Wisp IDs are associated with task metadata
3. **Closure**: When a task completes and validation passes, the orchestrator closes the wisp:
   ```bash
   bd close <wisp-id> --reason "completed"
   ```
4. **Recovery**: On crash, orphaned wisps indicate incomplete work

#### Key Principles

- **Wisps are created by the orchestrator**, not by builders or validators
- **Wisps represent task-level progress**, not checkpoint metadata
- **Open wisps = incomplete work**
- If no bead context is available (standalone plan execution), wisp creation is skipped entirely

### Failure Handling

| Failure Type | Example | Action |
|--------------|---------|--------|
| Transient | Network timeout | Retry (max 3x) |
| Recoverable | Missing file | Adjust context, retry |
| Permanent | Impossible task | Stop, escalate to human/mayor |
| Builder failure | Validation FAIL | Fix cycle (max 2 fix cycles) |

---

## Beads-to-Task Bridge

### Overview

Beads are the persistent source of truth. Any task tracking is ephemeral runtime state — beads always take precedence.

### Manual Bootstrap (Gemini equivalent of /gt:sync bootstrap)

```
bd ready --json
    |
For each bead:
    Note: bead.title, bead.description, metadata (bead_id, rig, priority)
    |
Map bead dependencies to ordering
```

### Live Sync

| Event | Action |
|-------|--------|
| Starting work on a task | `bd update <id> --status in_progress` |
| Task completed | `bd close <id> --reason "..."` |
| New work identified | `bd create` with appropriate metadata |

### Key Principles

1. **Beads are source of truth** — task tracking is ephemeral runtime state
2. **Group by change type** — Not by file (see Change Types above)
3. **Proper dependencies** — Use `bd dep add` for ordering
4. **Metadata for tracking** — Include bead_id, change_type, files
5. **Wisps for persistence** — Crash recovery via wisps, not checkpoint metadata

---

## Response Formats

**CRITICAL**: If instructions require a specific format (e.g., JSON), respond with raw output — NOT wrapped in markdown code blocks. Return only what is requested without preamble.

---

## Important Notes

- **Read before modifying**: In general, do not propose changes to code you haven't read
- **No time constraints**: When implementing specs, take your time for complete implementation
- **Python tests**: Let them run to completion (timeouts are per-test, not suite-wide)
- **Avoid over-engineering**: Only make changes that are directly requested or clearly necessary
- **Security**: Be careful not to introduce vulnerabilities (command injection, XSS, SQL injection, etc.)
- **Priming is not completion**: Priming and completing the check for conditional docs is not the same as completing the task at hand. Always ensure the actual task is complete before stopping.
