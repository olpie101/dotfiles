# CLAUDE.md

**Core principles**: Use agents proactively. Preserve context through selective retrieval. When exploring unknowns, follow the hierarchy below. When location is known, read directly (unless extracting specific doc sections). When looking for a known symbol and LSP is available, prefer LSP for precision.

CRITICAL: If you belong to gastown (ie. `GT_ROLE` env set), run `gt prime --hook` first, then run `gt hook` and follow the work instructions it returns. You are not to deviate from the provided instructions NO EXCEPTIONS.
CRITICAL: If you belong to gastown, you MUST follow all rules in `~/.claude/rules/gastown/`. Key files: `workflow-ops.md` (priming, molecule-aware commands, project context), `patrol-discipline.md` (patrol lifecycle), `step-discipline.md` (step discipline), `guardrails.md` (universal constraints).
---

## Exploration & Retrieval Hierarchy

Use this hierarchy when you need to **explore or retrieve information** and the location is unknown.

> **If you already know where something is**: Read it directly. Only use `selective-doc-retriever` if you need targeted extraction from large documents.

### 0. LSP (Precise Symbol Lookup)
**Tool**: `mcp__ide__getDiagnostics` + IDE LSP capabilities

Use when **all** conditions are met:
- LSP plugin is available for the language being used
- You know **what** you're looking for (specific symbol, type, function, reference)
- Need precise, semantic results (not text-based search)

Best for:
- Go-to-definition for a known symbol
- Find all references to a function/class/variable
- Type information and signatures
- Rename refactoring targets

**NOT for**: Broad exploration, unknown locations, documentation retrieval.

### 1. Selective Doc Retriever (Documentation Retrieval)
**Agent**: `adw-utilities:selective-doc-retriever`

Use when the request is **explicitly or contextually documentation-bound**:
- Retrieving specs, READMEs, feature docs, references
- Extracting specific sections from large documents
- Following doc references mentioned in other specs
- Context hints suggest documentation (e.g., "what does the spec say", "according to the docs")

Preserves context by returning only targeted sections (~70% savings).

### 2. Code Explorer (Fallback for Exploration)
**Agent**: `adw-utilities:code-explorer`

Use when:
- It's **unclear** if the request is documentation-bound
- The request is explicitly about **code** (not docs)
- Exploring codebase structure, patterns, implementations
- Finding function definitions, API endpoints, identifiers

Takes precedence over the built-in `Explore` agent.

### 3. Smart Tree MCP (Direct File Operations)
Use for known-location file operations:
- Finding files by pattern (`mcp__smart-tree__find`)
- Searching content in files (`mcp__smart-tree__search`)
- Project overview (`mcp__smart-tree__overview`)

See `~/.claude/docs/smart-tree-advanced.md` for advanced patterns.

### Decision Flow
```
Is this about gt/bd commands or Gas Town related tasks?
  YES -> Use gt/bd --help directly (no agents), refer to primed context
  NO  -> Continue below

Do you know the exact location?
  YES -> Read directly (or selective-doc-retriever for targeted extraction)
  NO  -> Do you know the specific symbol/identifier AND LSP is available?
           YES -> Use LSP for precise lookup
           NO  -> Is it documentation-bound (explicit or contextual)?
                    YES -> selective-doc-retriever
                    UNCLEAR -> code-explorer (fallback)
                    NO (code) -> code-explorer
```

---

## Subagent-to-Subagent Spawning

Subagents do NOT have access to the Task tool and cannot spawn agents directly. To spawn another agent from within a subagent, use the SlashCommand tool to invoke `/adw-utilities:claude_ool`.

### Detecting Subagent Context

If you need to spawn an agent but don't have the Task tool available, you are likely running as a subagent. In this case:

1. **Check for Task tool**: If Task tool is unavailable, you are a subagent
2. **Use SlashCommand fallback**: Invoke `/adw-utilities:claude_ool` via SlashCommand tool
3. **Follow the same hierarchy**: Apply the Exploration & Retrieval Hierarchy above

### Proactive Spawning (IMPORTANT)

**When following the Exploration & Retrieval Hierarchy as a subagent, you MUST proactively use `claude_ool` to spawn the appropriate agent.** Do not skip agent usage just because you lack the Task tool.

Examples of when to proactively spawn via `claude_ool`:
- Task requires exploring documentation → spawn `selective-doc-retriever`
- Task requires exploring code → spawn `code-explorer`
- Task requires any agent from the hierarchy → spawn it via `claude_ool`

### Pattern
Use the **SlashCommand tool** with:
```
/adw-utilities:claude_ool inherit Use the <agent-name> agent (subagent_type: <agent-type>) via the Task tool to <task description>
```

### Examples
```
# From a subagent, spawn selective-doc-retriever
SlashCommand: /adw-utilities:claude_ool inherit Use the selective-doc-retriever agent (subagent_type: adw-utilities:selective-doc-retriever) via the Task tool to find authentication documentation

# From a subagent, spawn code-explorer
SlashCommand: /adw-utilities:claude_ool inherit Use the code-explorer agent (subagent_type: adw-utilities:code-explorer) via the Task tool to find all database models
```

### Subagent Limitations
- **No Task tool**: Cannot spawn agents directly
- **Has SlashCommand**: Can invoke slash commands including `claude_ool`
- **Has Skill tool**: Can invoke skills in-context

---

## Important Notes

- **Agents are tools**: Use them proactively, especially ADW agents that recommend proactive use
- **Worktree isolation**: When in a project worktree/ADW, make ALL changes inside the worktree only
- **No time constraints**: When implementing specs, take your time for complete implementation
- **Python tests**: Let them run to completion (timeouts are per-test, not suite-wide)
- **factmem MCP**: Always use `olpie101` as user_id; add `project:<repo_name>` tag in git repos
- **sequential-thinking MCP**: Use when planning or answering non-trivial questions
- DO NOT use `Search` tool, `Bash` with `ls`/`find`/`grep`, or similar for searching
- CRITICAL: priming and completing the check for conditional docs is not the same as completing the task at hand. Always ensure check before stopping.

---

## Gas Town Agent Context

**Detection**: You are a Gas Town agent if the `GT_ROLE` environment variable is set (check with `echo $GT_ROLE`).

### gt/bd Command Questions

When the user asks about `gt` or `bd` commands (Gas Town / Beads CLI):
- **DO NOT** use explore/documentation agents
- These are internal tools - use `gt --help`, `bd --help`, or `gt <cmd> --help` directly
- For workflow questions, refer to your primed context from `gt prime`

Examples of gt/bd questions (handle directly, no agents):
- "How do I use gt sling?"
- "What does bd close do?"
- "How do I check my hook?"

### Gas Town Rules

Detailed Gas Town instructions are in `~/.claude/rules/`:
- `gastown/` - Commands, routing, roles, workflow operations, discipline rules, universal guardrails
- `decomposition/` - Step registry, change types, TaskList patterns
- `delegation/` - Subagent context, persistence decisions

---

## Response Formats

**CRITICAL**: If instructions require a specific format (e.g., JSON), respond with raw output - NOT wrapped in markdown code blocks. Return only what is requested without preamble.

Example instruction:
```json
{"a": 1, "b": "hello"}
```

**GOOD** - Raw output:
```
{"a": 1, "b": "hello"}
```

**BAD** - Wrapped in code block or with commentary.

---

## Smart Tree MCP Basics

Use `smart-tree` MCP (preferred) or `st` command for file discovery and content search.

### Core Tools
- `mcp__smart-tree__find` - Find files by type/pattern (use `format: 'toon'`)
- `mcp__smart-tree__search` - Search content in files (use `format: 'toon'`)
- `mcp__smart-tree__overview` - Project overview

### Search Tips
1. Initial search: set `include_content: false` to get file paths only
2. Refined search: set `include_content: true` with `context_lines: 5` or less
3. Never set `include_content: true` when `path` is `.`
4. The `keyword` parameter does NOT support regex - invoke multiple times in parallel for multiple keywords

### Commands
```bash
st -m context .          # Full context with git info
st -m quantum .          # Compressed for large contexts
st -m summary .          # Human-readable summary
st --search <TERM>       # Search in files
```

For advanced patterns, compression strategies, and memory management, read `~/.claude/docs/smart-tree-advanced.md`.

---

## Progressive Disclosure Reference

Load these docs/rules when working on specific areas:

| Topic | Location |
|-------|----------|
| Smart Tree Advanced | `~/.claude/docs/smart-tree-advanced.md` |
| Gas Town Commands | `~/.claude/rules/gastown/` |
| Decomposition Patterns | `~/.claude/rules/decomposition/` |
| Delegation Architecture | `~/.claude/rules/delegation/` |
| Workflow Integration Report | `~/.claude/docs/workflow-integration-report.md` |
