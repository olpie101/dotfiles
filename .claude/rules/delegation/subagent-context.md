# Subagent Context Provision

When delegating tasks to subagents, provide three elements.

## 1. Scoped Context

File paths + brief summaries (not full file contents):

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
- Touched (read/modified) by parent during exploration
- Explicitly marked relevant by parent agent

**Context budget by task type:**

| Signal | Budget |
|--------|--------|
| Change type = Explore/Design | Higher (more files, longer summaries) |
| Change type = Delete/Test | Lower (fewer files, brief summaries) |
| Estimated files touched > 10 | Expand budget |
| Simple single-file change | Minimal context |

## 2. Parent Summary

Full context brief including:
- **Decisions made** and rationale
- **Constraints** from spec/bead
- **Patterns discovered** during exploration
- **Files touched** by parent with relevance notes

## 3. Result Flow

**Builder agents** report completion by:
1. Returning a summary of changes in their output (files modified, key decisions)
2. Marking their TaskList item as `completed` via TaskUpdate
3. Closing their wisp if one was created: `bd close <wisp-id> --reason "completed"`

**The orchestrator** (not the builder) writes bead notes:
- `bd note add <bead-id> "Implementation complete: <summary>"` after all builders finish

**Research agents** write artifacts to disk:
- Output files in `{spec_directory}/research-*.md`
- The orchestrator reads and synthesizes these into the design/plan

**Discovery propagation** between builders in the same run:
- The orchestrator passes `prior_discoveries` in YAML frontmatter to subsequent builders
- This includes key decisions and patterns from earlier completed builders in the same `/gt:build` execution
