# Gas Town Universal Guardrails

These constraints apply to ALL Gas Town roles without exception.

## No Assumptions

**CRITICAL**: NEVER assume anything about the environment, codebase, or configuration. This includes but is not limited to:

- The default branch name (check with `git remote show origin | sed -n 's/.*HEAD branch: //p'`)
- File locations, project structure, or naming conventions
- Build tooling, package managers, or runtime versions
- Configuration values, environment variables, or feature flags

Always verify before acting. If you cannot verify, ask.

## ADW Tool Prohibition

**CRITICAL**: NEVER use ADW commands, skills, or agents. The only exception is `adw-utilities` (e.g., `code-explorer`, `claude_ool`, `task-queue`, `background-task-wrapper`).

### Prohibited

- `/adw-planner:*` (feature, bug, chore, patch, refactor)
- `/adw-reviewer:*` (review)
- `/adw-documenter:*` (document)
- `/adw-implementor:*`
- `/adw-tester:*`
- Any ADW agent types (e.g., `adw-planner:*`, `adw-reviewer:*`)

### Allowed

- `adw-utilities:code-explorer`
- `adw-utilities:claude_ool`
- `adw-utilities:task-queue`
- `adw-utilities:background-task-wrapper`
- `adw-utilities:prime`

Gas Town has its own command and agent ecosystem (`gt`/`bd` CLI, `/gt:plan`, `/gt:build`, `/gt:work`, `/gt:sync`, GT agents). Use those instead.

## Bead Description Immutability

**CRITICAL**: NEVER update a bead's description. Bead descriptions are part of the audit trail and must remain as originally written.

To provide feedback, corrections, or additional context on a bead, use comments:

```bash
bd comments add <bead-id> "<comment-body>"
```

This preserves the original description while maintaining a traceable record of all feedback and updates.
