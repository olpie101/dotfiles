---
description: Decompose a gastown bead into a structured plan with parallel research delegation
argument-hint: "[bead-id]"
model: opus
---

## Variables

BEAD_ID: $ARGUMENTS
DESIGN_OUTPUT_DIRECTORY: .designs/
PLAN_OUTPUT_DIRECTORY: specs/
DECOMPOSITION_REGISTRY: ~/.claude/rules/decomposition/step-registry.md
CHANGE_TYPES: ~/.claude/rules/decomposition/change-types.md
GT_RESEARCH_AGENT: gt/gt-research-agent
GT_VALIDATOR_AGENT: gt/gt-validator-agent

## Instructions

This command produces a **plan or design document only**. Do NOT build, write code, deploy implementation agents, or execute any implementation steps. The sole output is a structured plan or design artifact written to disk.

If no BEAD_ID is provided (empty or missing), STOP immediately and ask the user:
> Please provide a bead ID: `/gt:plan <bead-id>`

**Operating mode** is auto-detected from context in Step 3. Do not ask the user which mode to use unless detection is genuinely ambiguous after checking all signals.

**Team member agent types** spawned by this command use Gas Town agent definitions:
- `gt/gt-research-agent` — for research and exploration tasks
- `gt/gt-builder-agent` — for implementation tasks referenced in plans (listed as assignees, NOT executed)
- `gt/gt-validator-agent` — for design review and validation tasks

**Research agent deployment** uses the `Task` tool with:
- `subagent_type: "gt/gt-research-agent"`
- YAML frontmatter prepended to the agent prompt containing bead metadata and research focus
- `run_in_background: true` for parallel execution

## Workflow

### Step 1: Validate Input

Check whether BEAD_ID has a value.

- If BEAD_ID is empty, blank, or was not provided, STOP all processing and respond with:
  > Please provide a bead ID: `/gt:plan <bead-id>`
- Do not proceed to any subsequent step without a valid BEAD_ID.

### Step 2: Read Bead Details

Run the following command to retrieve bead information:

```bash
bd show $BEAD_ID --json
```

Extract and store these fields for use in later steps:
- `title` — bead title
- `description` — full bead description
- `status` — current bead status
- `priority` — numeric priority (1 = highest, 5 = lowest)
- `rig` — the rig this bead belongs to
- `molecule` — attached molecule info (formula name, steps, current step)
- `labels` — all labels on the bead
- `linked_beads` — any referenced or linked beads

If the bead is not found or the command returns an error, STOP and report:
> Bead `$BEAD_ID` not found. Verify the bead ID and try again.

### Step 3: Auto-Detect Mode

Evaluate the following conditions in order to determine the operating mode:

**DESIGN-SPEC mode** — activate when ALL of:
- The bead has a molecule attached AND the molecule formula is `design-spec`

Output target: `.designs/<bead-id>-<slug>/` directory containing research files, `design.md`, and optional review artifacts.
Process: Full 6-step design cycle (research, alternatives, analysis, decision, design, review).

**INLINE-DESIGN mode** — activate when ALL of:
- The caller's `GT_ROLE` is `polecat`
- The caller's current molecule step name starts with `design` or `implement`

Output target: `.designs/<bead-id>-<slug>/design.md` (single file).
Process: Abbreviated cycle (research + combined design document). Skip review for beads with priority >= 3.

**PLAN mode** — activate when ANY of:
- The caller's `GT_ROLE` is `mayor` or `crew`
- Neither DESIGN-SPEC nor INLINE-DESIGN conditions are met

Output target: `specs/<bead-id>-plan.md` in `plan_w_team` format.
Process: Research + plan generation with team structure and task decomposition.

If mode detection is genuinely ambiguous after evaluating all signals, default to **PLAN mode**.

Log the detected mode before proceeding:
> Detected mode: **[MODE]** — [one-line rationale]

### Step 4: Check Existing Artifacts

Search these 4 locations for existing design or plan artifacts related to this bead:

1. **`.designs/<bead-id>-*/`** — look for any directory matching the bead ID prefix. Check for `design.md`, `research.md`, or other artifacts inside.
2. **`specs/`** — search for files named `<bead-id>-plan.md` or files whose content references this bead ID.
3. **Bead notes** — run `bd notes $BEAD_ID` and check for inline design content or plan references.
4. **Linked beads** — for each linked bead extracted in Step 2, check if it is a design bead (has `design-spec` formula or `design` label).

If any existing artifact is found:
- Report what was found, its location, and its last-modified date if available.
- Ask the user: "An existing [design/plan] was found at `<path>`. Do you want to (R)egenerate from scratch or (U)se the existing artifact?"
- If the user chooses to use the existing artifact, STOP and output its path.
- If the user chooses to regenerate, proceed with the workflow (the old artifact will be overwritten).

If no artifacts are found, proceed silently to Step 5.

### Step 5: Research Phase

Determine whether research should be performed inline or delegated to agents.

**Inline research** (no agents spawned) when ALL of:
- Bead priority >= 3 (low priority)
- Bead description is fewer than 200 characters
- The bead appears to involve a single file or trivial change (infer from description keywords)

For inline research: read the relevant files mentioned in the bead description, summarize findings, and write a brief `research.md` in the output directory. Move to Step 6.

**Delegated research** (spawn parallel agents) otherwise:

Spawn 2-3 `gt/gt-research-agent` agents in parallel using the Task tool. Each agent receives a prompt with YAML frontmatter prepended:

```yaml
---
bead_id: <BEAD_ID>
bead_title: <title from Step 2>
bead_description: <description from Step 2>
spec_directory: <output directory for this bead>
research_focus: <focus area — see below>
---
```

**Agent 1** — `research_focus: codebase-patterns`
- Explore existing code patterns, conventions, and architecture relevant to the bead
- Identify files that will be affected
- Document current interfaces and data flows

**Agent 2** — `research_focus: domain-knowledge`
- Research the domain problem the bead addresses
- Identify constraints, edge cases, and requirements not explicit in the description
- Review any related documentation or specs

**Agent 3** (optional) — `research_focus: dependency-analysis`
- Spawn ONLY when the bead involves cross-module concerns, multiple rigs, or external dependencies
- Map dependency chains, integration points, and potential conflicts
- Identify shared resources and coordination requirements

Deploy agents with `run_in_background: true` for parallel execution. Maximum 3 research agents.

After all agents complete:
1. Read the distilled artifacts from `{spec_directory}/research-codebase-patterns.md`, `{spec_directory}/research-domain-knowledge.md`, and optionally `{spec_directory}/research-dependency-analysis.md`
2. Synthesize all findings into a single `{spec_directory}/research.md` that combines and deduplicates information from all sources
3. The synthesized `research.md` is the input for Step 6

### Step 6: Design/Plan Generation

Generate the output artifact based on the detected mode.

#### DESIGN-SPEC Mode

Execute the full 6-step design process:

1. **Research** — completed in Step 5. Load `{spec_directory}/research.md`.

2. **Alternatives Enumeration** — enumerate 2-4 distinct approaches to solving the bead. For each alternative, provide:
   - Name and one-sentence summary
   - High-level architecture sketch
   - Key implementation steps
   - Known limitations

3. **Analysis and Trade-offs** — evaluate each alternative against these dimensions:
   - Complexity (implementation effort)
   - Maintainability (long-term cost)
   - Performance implications
   - Risk (what could go wrong)
   - Alignment with existing patterns (from research)
   Present as a comparison table.

4. **Decision** — select the recommended approach with explicit rationale. Reference the analysis dimensions. Note any dissenting considerations.

5. **Design Document** — write `design.md` containing:
   - Overview and problem statement
   - Selected approach with rationale
   - Architecture (components, boundaries, data flow)
   - Interface definitions (function signatures, API contracts, data models)
   - Implementation sequence (ordered steps)
   - Edge cases and error handling
   - Migration or rollback strategy (if applicable)

6. **Review** — spawn validators via Task tool:
   - Spawn a `gt/gt-validator-agent` with `spawn_point: design-review` in the prompt frontmatter
     - Provide the full `design.md` content for review
     - The validator writes feedback to `{spec_directory}/review.md`
   - For high-priority beads (priority <= 2) or cross-module scope, additionally spawn a `gt/gt-validator-agent` with `spawn_point: architecture-review` in the prompt frontmatter
     - Provide `design.md` plus `research-codebase.md` for architectural pattern validation
     - The validator writes feedback to `{spec_directory}/review-architecture.md`
   - If either review surfaces critical issues, amend `design.md` accordingly

#### INLINE-DESIGN Mode

Abbreviated design process:

1. Load research from Step 5 (`research.md` or inline findings).
2. Write a single `design.md` that combines:
   - Problem statement (derived from bead description)
   - Recommended approach (skip alternatives enumeration — pick the best based on research)
   - Key interfaces and data flow
   - Implementation steps
   - Edge cases
3. **Review gate**: If bead priority < 3 (high priority), spawn a `gt/gt-validator-agent` with `spawn_point: design-review` for a quick review pass. For cross-module beads at priority <= 2, additionally spawn with `spawn_point: architecture-review`. If priority >= 3, skip review entirely.
4. Write `design.md` to `.designs/<bead-id>-<slug>/design.md`.

#### PLAN Mode

Decompose the bead into a structured plan:

1. Load research from Step 5.
2. Read change type definitions from `~/.claude/rules/decomposition/change-types.md`.
3. Decompose the work into tasks grouped by change type: **Explore**, **Design**, **Add**, **Modify**, **Delete**, **Test**.
4. For each task, determine:
   - Task ID (sequential, e.g., `T1`, `T2`, ...)
   - Title and description
   - Change type
   - Files affected
   - Dependencies (`Depends On` other task IDs)
   - Whether it can run in parallel with other tasks
   - Assigned agent type (`gt/gt-builder-agent`, `gt/gt-validator-agent`, or `gt/gt-research-agent`)
   - Estimated complexity (low / medium / high)
5. Write the plan in `plan_w_team` format (see Plan Format section below).
6. Write to `specs/<bead-id>-plan.md`.

### Step 7: Generate Output Filename

Derive the output path based on mode:

- **DESIGN-SPEC or INLINE-DESIGN**:
  - Slug: take the bead title, lowercase it, replace non-alphanumeric characters with hyphens, collapse consecutive hyphens, trim to max 30 characters, remove trailing hyphens.
  - Path: `.designs/<bead-id>-<slug>/design.md`
  - Example: `.designs/nx-abc123-add-user-preferences-api/design.md`

- **PLAN**:
  - Path: `specs/<bead-id>-plan.md`
  - Example: `specs/nx-abc123-plan.md`

### Step 8: Save Artifact

1. Ensure the parent directory exists (create it if necessary using `mkdir -p`).
2. Write the plan or design document to the path generated in Step 7.
3. If in DESIGN-SPEC mode, also ensure `research.md` and any `review.md` are saved in the same directory.
4. Verify the file was written successfully by checking it exists.

### Step 9: Report

Output a summary to the user with the following information:

**For all modes:**
- Mode used (DESIGN-SPEC / INLINE-DESIGN / PLAN)
- File path(s) created (absolute paths)
- Number of research agents spawned (0 if inline)
- Key components or areas identified from research

**Additional for PLAN mode:**
- Team members listed (agent types and count)
- Total task count
- Task breakdown by change type (e.g., "2 Add, 1 Modify, 1 Test")
- Tasks eligible for parallel execution

**Additional for DESIGN-SPEC mode:**
- Number of alternatives evaluated
- Selected approach name
- Whether review was performed and outcome

Format the report as a concise summary block, not a wall of text.

## Plan Format

When operating in PLAN mode, the output document follows the `plan_w_team` format. The document structure is:

### Document Structure

```markdown
# Plan: <bead title>

**Bead**: `<bead-id>`
**Generated**: <ISO 8601 timestamp>
**Mode**: PLAN

## Task Description

<Summary of the bead — what needs to be done and why. Derived from the bead title and description, enriched with context from research.>

## Relevant Files

<List of files that will be created, modified, or deleted. Group by action.>

### Files to Create
- `path/to/new-file.ts` — <purpose>

### Files to Modify
- `path/to/existing-file.ts` — <what changes>

### Files to Delete
- `path/to/deprecated-file.ts` — <why>

## Team Orchestration

This plan uses the following Gas Town agent types for execution:

| Role | Agent Type | Purpose |
|------|-----------|---------|
| Builder | `gt/gt-builder-agent` | Implementation tasks (Add, Modify, Delete) |
| Validator | `gt/gt-validator-agent` | Validation, testing, and review tasks |
| Researcher | `gt/gt-research-agent` | Exploration and investigation tasks |

## Team Members

| Member ID | Agent Type | Assigned Tasks |
|-----------|-----------|----------------|
| builder-1 | `gt/gt-builder-agent` | T3, T4, T5 |
| builder-2 | `gt/gt-builder-agent` | T6, T7 |
| validator-1 | `gt/gt-validator-agent` | T8, T9 |
| researcher-1 | `gt/gt-research-agent` | T1 |

## Step by Step Tasks

### T1: <Task Title>
- **Change Type**: Explore
- **Depends On**: none
- **Assigned To**: researcher-1
- **Agent Type**: `gt/gt-research-agent`
- **Parallel**: yes
- **Complexity**: low
- **Actions**:
  1. <specific action item>
  2. <specific action item>

### T2: <Task Title>
- **Change Type**: Design
- **Depends On**: T1
- **Assigned To**: builder-1
- **Agent Type**: `gt/gt-builder-agent`
- **Parallel**: no
- **Complexity**: medium
- **Actions**:
  1. <specific action item>
  2. <specific action item>

<... continue for all tasks ...>

## Acceptance Criteria

<Bulleted list of conditions that must be true for this plan to be considered complete. Derived from the bead description, labels, and research findings.>

- [ ] <criterion 1>
- [ ] <criterion 2>
- [ ] <criterion 3>

## Validation Commands

<Commands to verify the work is correct after all tasks are executed.>

- `<command 1>` — <what it validates>
- `<command 2>` — <what it validates>
```

### Format Rules

1. Every task MUST have a Change Type from: Explore, Design, Add, Modify, Delete, Test.
2. Every task MUST have an Agent Type from the gt/ agent set.
3. Dependencies must reference valid Task IDs within the same plan.
4. The Parallel flag indicates whether this task CAN run concurrently with other tasks that share no dependency relationship. Set to `yes` only when the task has no file conflicts with concurrent tasks.
5. Team Members are assigned based on workload balancing — distribute tasks roughly evenly across members of the same agent type.
6. Acceptance Criteria should be testable and specific, not vague ("works correctly" is bad; "returns 200 with valid JSON for GET /api/preferences" is good).
7. Validation Commands should be runnable shell commands or test invocations, not prose descriptions.
