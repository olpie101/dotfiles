---
description: Proactive polecat orchestrator — detects design artifacts and routes to appropriate build action. Use this proactively when you are polecat executing the polecat-work formula.
argument-hint: "[bead-id]"
---

## Variables

BEAD_ID: $ARGUMENTS
GT_BUILDER_AGENT: gt/gt-builder-agent
GT_VALIDATOR_AGENT: gt/gt-validator-agent

## Instructions

This command is the primary entry point for polecats on `implement*` steps. It detects existing design and plan artifacts produced by earlier formula steps and routes to the appropriate build action based on what it finds.

When a structured plan exists (containing explicit task breakdowns), this command uses the `gt-build` skill via the Skill tool to load build instructions into the current agent context (skill delegation pattern). When only a design narrative exists, it decomposes directly and spawns builder agents.

This command is available to polecat and crew roles. It does NOT duplicate formula steps -- it helps execute them by detecting artifacts and routing to the correct implementation strategy.

**CRITICAL**: While executing this workflow you must still follow rules for gastown provided by your rules.

## Workflow

### Step 1: Validate Input

- If BEAD_ID is not provided (empty or blank), check if a bead is on hook by running `gt hook` and parsing the output.
- If the hook has a bead attached, use that bead ID as BEAD_ID.
- Otherwise STOP and ask the user: "Please provide a bead ID: `/gt:work <bead-id>`"

### Step 2: Read Bead Context

- Run `bd show $BEAD_ID --json` to fetch bead details. Extract title, description, priority, and molecule info.
- Run `bd ready --mol $BEAD_ID --no-daemon` to see the current molecule step.
- Confirm the current step matches the `implement*` pattern. If it does not, warn but continue: "Current step is '{step_name}', not an implement step. Proceeding anyway."

### Step 3: Detect Artifacts

Search 4 locations in priority order for existing design or plan artifacts:

1. `.designs/<bead-id>-*/design.md` -- bead-specific design document (highest priority).
2. `.designs/<bead-id>-*/` -- bead-specific design directory (any `.md` files within it).
3. `specs/<bead-id>-plan.md` -- structured plan file.
4. `specs/` directory -- any plan files that reference this bead ID in their content.

Record:
- **Artifact type**: `structured-plan` | `design-document` | `none`
- **Artifact path**: the resolved file path(s) found.

### Step 4: Route to Action

Use the following decision tree to determine the build strategy:

#### Branch A: Structured plan exists

The artifact contains a `## Step by Step Tasks` section (or equivalent structured task breakdown).

- Invoke the `gt-build` skill via `Skill("gt-build", args: "<plan-file-path>")`.
- The skill's instructions load into the current agent's context.
- Follow those instructions to create TaskList items from the plan and spawn builder agents accordingly.

#### Branch B: Design exists but no structured tasks

A design document or directory was found but it does not contain a structured task breakdown.

- Decompose from the design narrative.
- Identify deliverables and group them by change type (Explore / Design / Add / Modify / Delete / Test).
- Create 1 task per logical unit of work.
- Create TaskList items for each task.
- Spawn `gt/gt-builder-agent` instances directly, providing the design document as scoped context.

#### Branch C: No artifacts and bead is complex

No design or plan artifacts were found AND the bead appears complex (priority <= 1 OR description length > 500 characters).

- Suggest running the plan command first.
- Output: "This bead appears complex and has no design artifacts. Run `/gt:plan $BEAD_ID` to create a design before implementing."
- Do NOT proceed with implementation.

#### Branch D: No artifacts and bead is simple

No design or plan artifacts were found AND the bead is simple (priority > 1 AND description length <= 500 characters).

- Spawn `gt/gt-builder-agent` directly from the bead description.
- Create 1-4 TaskList items based on the bead description.
- Apply minimal decomposition -- group by change type where obvious, otherwise treat as a single deliverable.

### Step 5: Self-Review Support

If the current molecule step matches `self-review` or `review*` pattern:

- Run `git diff --stat` to measure the size of changes.
- **Small changes** (<=500 lines changed AND <=10 files changed):
  - Spawn a single `gt/gt-validator-agent` in the background with `spawn_point: self-review` and the full git diff as context.
- **Large changes** (>500 lines changed OR >10 files changed):
  - Spawn multiple specialized validators:
    - One for **correctness, completeness, and cruft** detection.
    - One for **security and style** validation.
    - One for **architectural compliance** (`spawn_point: architecture-review`) — evaluates component boundaries, dependency direction, SOLID compliance, coupling, and pattern consistency.
- The polecat performs its own review concurrently per formula instructions.
- Validator findings are ADVISORY -- the polecat decides what to fix based on the findings.

### Step 6: Completion

After all builders finish and validation passes:

- Do NOT close the bead. The molecule's `submit-and-exit` step handles bead closure.
- Add a bead note summarizing the work: `bd note add $BEAD_ID "Implementation complete via /gt:work: <summary>"`
- Suggest the next molecule step if one is applicable.
