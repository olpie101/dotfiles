---
description: Execute a gastown plan by spawning builder/validator teams with tier-based parallelism. Use this proactively when you are poleacat executing the polecat-work formula.
argument-hint: "[path-to-plan]"
---

<!-- This command serves dual purpose:
  1. Slash command: /gt:build <plan-file>
  2. Skill: gt-build (invoked by /gt:work via Skill tool)
  When invoked as a skill, these instructions load into the invoking agent's context.
  The plan execution logic is the SINGLE SOURCE OF TRUTH — used by both interfaces. -->

## Variables

PLAN_FILE: $ARGUMENTS
GT_BUILDER_AGENT: gt/gt-builder-agent
GT_VALIDATOR_AGENT: gt/gt-validator-agent

## Instructions

- If no PLAN_FILE is provided, STOP immediately and ask the user for the path to a plan file.
- Detect input type by examining PLAN_FILE:
  - **File path**: contains `/`, ends with `.md`, or starts with `specs/` or `.designs/`.
  - **Bead ID**: matches a pattern like `xx-xxxxx` (short alphanumeric with hyphen, no `/` or `.md`).
  - If input looks like a bead ID, respond: "Use `/gt:work <bead-id>` for bead-based execution, or `/gt:plan <bead-id>` to create a plan first."
- This command is the **SINGLE SOURCE OF TRUTH** for plan execution logic. Both the slash command and the skill interface use these exact instructions.
- Deploy `gt/gt-builder-agent` for implementation and exploration tasks.
- Deploy `gt/gt-validator-agent` for validation tasks.
- Maintain TaskList as runtime focus. Create wisps for crash recovery when bead context is available.

## Workflow

### Step 1: Validate Input

1. If PLAN_FILE is not provided (empty or missing), STOP and ask: "Please provide the path to a plan file: `/gt:build <path-to-plan>`"
2. If input looks like a bead ID (matches pattern like `xx-xxxxx` with no `/` or `.md` extension):
   - Respond: "Use `/gt:work <bead-id>` for bead-based execution, or `/gt:plan <bead-id>` to create a plan first."
   - STOP execution.
3. Otherwise, treat PLAN_FILE as a file path and proceed.

### Step 2: Read Plan

1. Read the plan file at the PLAN_FILE path.
2. Parse the following sections from the plan:
   - **Task Description**: overall goal and scope.
   - **Team Members**: agent types and their roles.
   - **Step by Step Tasks**: for each task extract:
     - Task ID (e.g., `T1`, `T2`)
     - Task name/subject
     - Dependencies (blockedBy relationships)
     - Agent type (`builder` or `validator`)
     - Parallel execution flag
     - Action items (specific implementation instructions)
     - Files to modify (if listed)
   - **Acceptance Criteria**: success conditions for the overall plan.
   - **Validation Commands**: commands to run for verification (tests, lints, type checks).
3. If the file is not found or cannot be parsed, STOP and report the error with details.

### Step 3: Create TaskList Items

For each task in the "Step by Step Tasks" section:

1. Create the task:
   ```
   TaskCreate(
     subject = task.name,
     description = task.action_items,
     activeForm = "Working on: task.name"
   )
   ```
2. Map dependencies from the plan to TaskList blockedBy:
   ```
   TaskUpdate(taskId, addBlockedBy = [dep_task_ids])
   ```
3. Extract `bead_id` from the plan's context section if present. Store it for wisp creation and bead note updates.

### Step 4: Create Wisps for Crash Recovery

For each TaskList item, if bead context is available:

1. Create a wisp as a child of the current molecule step bead:
   ```bash
   bd create "<task-subject>" --wisp --parent <molecule-step-bead-id>
   ```
2. Store the wisp ID in task metadata:
   ```
   TaskUpdate(taskId, metadata = { wisp_id: "<wisp-id>" })
   ```
3. If no bead context is available (plan may be standalone), skip wisp creation entirely. Log: "No bead context -- skipping wisp creation."

### Step 5: Static File Conflict Analysis

Before spawning any builders, perform file conflict detection:

1. For each pair of tasks that share the same tier (no blockedBy relationship between them):
   - Extract `files_to_modify` from each task's action items.
   - Compute the intersection of file sets.
   - If file sets intersect:
     - Add a blockedBy constraint to serialize them:
       ```
       TaskUpdate(taskB.id, addBlockedBy = [taskA.id])
       ```
     - Log: "Serialized tasks {taskA.name} and {taskB.name} due to file overlap: [{overlapping files}]"
2. If file targets are unknown for a task (not specified in the plan), default to **sequential execution** for that task relative to others in the same tier.
3. Re-compute tiers after adding any new constraints.

### Step 6: Tier-Based Builder Spawning

Analyze the dependency graph into execution tiers:

- **Tier 0**: tasks with no blockedBy (root tasks).
- **Tier N**: tasks whose blockedBy dependencies are all in Tier 0 through Tier N-1.

For each tier, in order:

1. **1 task in tier**: Spawn in foreground (blocking).
   - Use `Task` tool with `run_in_background: false`.
   - Subagent type from plan (typically `gt/gt-builder-agent`).

2. **2-3 tasks in tier**: Spawn all in parallel (background).
   - Use `Task` tool with `run_in_background: true` for each.
   - Wait for all to complete via `TaskOutput`.

3. **4+ tasks in tier**: Rolling window execution.
   - Spawn the first 3 tasks in background.
   - As each completes, spawn the next pending task.
   - Cap at 3 concurrent builders at any time.

Each builder is a **THROWAWAY agent** -- spawn fresh, complete the task, discard. Never reuse a builder agent across tasks.

Each builder receives a prompt with YAML frontmatter prepended:

```yaml
---
bead_id: <from plan context, if available>
step_id: <molecule step if known>
task_subject: <task name>
task_description: <task action items>
design_file: <path to .designs/ artifact if exists>
wisp_id: <from task metadata, if created>
prior_discoveries: <key decisions from earlier completed builders in this run>
files_to_modify: <list of target files from action items>
---
```

After frontmatter, include the full task action items and any relevant context from the plan.

### Step 7: Post-Builder Validation

After **EACH** builder completes:

1. Spawn `gt/gt-validator-agent` with `spawn_point: post-builder`, passing:
   - `changed_files`: list of files modified by the builder (from builder output).
   - `task_subject`: the task name.
   - `design_file`: path to the design artifact, if available.
   - `acceptance_criteria`: from the plan, if available.

2. Handle validator outcome:
   - **PASS**: Continue to next tier. Close the completed wisp:
     ```bash
     bd close <wisp-id> --reason "completed"
     ```
   - **FAIL**: Enter fix cycle:
     1. Create a fix task from the validator's failure report.
     2. Spawn a **fresh** builder agent with the fix task and validator findings.
     3. After the fix builder completes, re-validate with a fresh validator.
     4. Maximum **2 fix cycles** (3 total attempts including the original).
     5. After 3 failures: report to the user with all findings from each attempt. Do **NOT** auto-escalate or auto-close anything.

3. Validator sizing:
   - **Small changes** (<=500 lines changed, <=10 files): single validator.
   - **Large changes** (>500 lines or >10 files): spawn multiple specialized validators (e.g., one for tests, one for lint, one for type checks).
   - **Multi-module changes** (3+ distinct modules/packages or 10+ files across different directories): additionally spawn a `gt/gt-validator-agent` with `spawn_point: architecture-review` to evaluate component boundaries, dependency direction, and pattern consistency.

### Step 8: Completion

After all tasks in all tiers are complete:

1. Spawn a **final** `gt/gt-validator-agent` with:
   - Full `git diff` of all changes.
   - Validation commands from the plan.
   - Acceptance criteria from the plan.

2. Handle final validation outcome:
   - **PASS**:
     - Add a bead note summarizing the work:
       ```bash
       bd note add <bead-id> "Implementation complete: <summary of changes>"
       ```
     - Close all remaining wisps:
       ```bash
       bd close <wisp-id> --reason "completed"
       ```
   - **FAIL**:
     - Report which tasks succeeded and which failed.
     - Leave wisps open for human review.
     - Do NOT attempt further fixes at this stage.

3. Do **NOT** close the bead itself. Bead closure is the responsibility of the molecule's `submit-and-exit` step.

## Report

```
Gastown Build Complete

Plan: {PLAN_FILE}
Bead: {bead-id if available}

Work Summary:
- {task name} - {PASS/FAIL} - {files changed}

Validation: {PASS/FAIL with details}
Wisps: {N closed, M remaining}

Next Steps: {any remaining work}
```
