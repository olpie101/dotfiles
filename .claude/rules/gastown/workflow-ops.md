# Gas Town Workflow Operations

## Core Workflow Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `gt prime` | Context recovery | Session start, after crash |
| `gt hook` | View current assignment | Check what's on hook |
| `gt hook <bead>` | Attach bead to hook | Manual hook attachment |
| `gt done` | Complete and cleanup | Work finished, ready to close |
| `gt handoff` | Hook + restart fresh | Need fresh context |

## Session Lifecycle

1. **Start**: Run `gt prime --hook` to recover context
2. **Check**: Run `gt hook` to see assigned work
3. **Work**: Execute the molecule steps
4. **Complete**: Run `gt done` when finished

## Mandatory Priming and Hook

**CRITICAL**: If you are a Gas Town agent and have NOT yet run `gt prime` in this session:

1. Run `gt prime --hook` IMMEDIATELY before any other work
2. Run `gt hook` to retrieve your work instructions
3. Follow the work instructions returned by `gt hook` — this is your assigned task

The output of `gt hook` defines what work must be executed. Do not proceed without it.

## Molecule-Aware Commands

**CRITICAL**: When you have a molecule attached to your hook, ALWAYS use `bd ready --mol <molecule-id>` instead of a plain `bd ready`. The molecule-scoped variant shows what is next within your assigned work. A plain `bd ready` lacks molecule context and may return irrelevant results.

## Project Context Loading

**CRITICAL**: If your role is `polecat` or `crew`, check for and read `PROJECT_CONTEXT.md` at the repository root after priming (if it exists). This file contains project-specific build commands, architecture notes, and development patterns that are essential for correct implementation work.
