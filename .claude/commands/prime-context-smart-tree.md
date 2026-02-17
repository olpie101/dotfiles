
---
description: Establish comprehensive project context using Smart Tree MCP tools following the proven prompt workflow
---

# Smart Tree Context Prime

Use Smart Tree's MCP tools to rapidly understand any codebase through the systematic workflow from the MCP prompts cheat sheet.

## Execute

### Phase 0: Memory Check (Required)
Check for existing project memories:

1. **memory** tool with:
   ```
   {
     operation: 'find',
     keywords: ['project:<project-name>'],
   }
   ```

### Phase 1: Essential Overview (Required)
**Token Budget: ~5-10% of context**

1. **overview** tool with `{mode: 'quick', path: '.'}`
   - Get 3-level instant overview with 10x compression
   - Identify project type, structure, and key files
   - Provides file discovery (no need for separate find)

2. **overview** tool with `{mode: 'project', path: '.'}` (Optional)
   - Only if quick mode insufficient
   - Full project analysis with statistics
   - Warning: Can consume more tokens on large projects

### Phase 2: Compressed Analysis (Required)
**Token Budget: ~10-15% of context**

1. **analyze** tool with `{mode: 'quantum-semantic'}`
   - Maximum compression with semantic understanding
   - Essential for large codebases (500+ files)
   - Provides wave signatures and tokenization

### Phase 3: Task-Specific Discovery (Conditional)
**Execute ONLY tools relevant to current task:**

For **Code Understanding**:
- **find** `{type: 'code', languages: ['<relevant>']}`
- **smart_edit** `{operation: 'get_functions', file_path: '<key-file>'}`

For **Testing/Quality**:
- **find** `{type: 'tests'}`
- **search** specific error patterns (NOT generic TODOs)

For **Recent Work**:
- **find** `{type: 'recent', days: 7}`
- **analyze** `{mode: 'git_status'}`

For **Configuration**:
- **find** `{type: 'config'}`
- **find** `{type: 'documentation'}`

**⚠️ Token Warnings:**
- Skip `{mode: 'directory'}` on repos >1000 files
- Avoid broad searches without file type filters
- Never auto-search TODO/FIXME (can exceed 100K tokens) without narrowing the path

### Phase 4: Memory Preservation (Conditional)
**Only execute if new insights discovered:**

1. **memory** tool for new findings:
   ```
   {
     operation: 'anchor',
     anchor_type: '<appropriate-type>',
     keywords: ['project:<project-name>', '<specific-feature>'],
     context: '<new-insight-only>',
     origin: 'ai:claude'
   }
   ```
   - Skip if no novel insights found
   - Use project-specific keywords
   - Avoid duplicating Phase 0 memories
   - You can add multiple keywords but be conservative (no more than 10, including the project name)

2. **compare** tool (task-specific):
   - Only for branch/version comparisons
   - Skip for initial exploration

## Read

### Essential Files (via Read tool)
- README.md or README.*
- Main configuration file (package.json, Cargo.toml, etc.)
- Primary entry point (main.*, index.*, app.*)
- Test examples (to understand testing approach)

## Analyze

### Using MCP Tool Outputs

1. **Project Classification** (from overview)
   - Type, size, language distribution
   - Key directories and their purposes

2. **Code Quality** (from search)
   - Technical debt indicators
   - Documentation coverage
   - Testing presence

3. **Architecture** (from analyze)
   - Module organization
   - Dependency patterns
   - Semantic groupings

4. **Development Flow** (from git_status)
   - Active areas
   - Recent changes
   - Commit patterns

## Report

### Structured Output Format

1. **Quick Summary** (from first_steps workflow)
   - What the project does
   - Technology stack
   - Current state

2. **Deep Insights** (from codebase_detective workflow)
   - Architecture patterns
   - Code organization
   - Quality indicators

3. **Actionable Context** (from search_master workflow)
   - Key files to examine
   - Areas needing attention
   - Quick command reference

4. **Preserved Knowledge** (from project_memory workflow)
   - Anchor key findings
   - Build knowledge base
   - Enable future recall

## Streamlined Workflow (Optimized)

**Minimal context consumption (~20% total):**

1. **Memory Check** (if returning to project): `memory find project:<name>`
2. **Quick Overview** (always): `overview {mode: 'quick'}`
3. **Compressed Analysis** (always): `analyze {mode: 'quantum-semantic'}`
4. **Task Tools** (only as needed): Specific find/search for current task
5. **Memory Save** (only new insights): `memory anchor` with project keyword

## Cheat Sheet Reference

Maps to Smart Tree workflows: `first_steps` (Phase 1), `codebase_detective` (Phase 2),
`search_master` (Phase 3), `project_memory` (Phase 4)

## Usage Tips

- Always use `quantum-semantic` over `semantic` for large repos
- Skip Phase 1 step 2 unless quick mode insufficient
- Never run automatic TODO searches (massive token cost)
- Use file type filters on all searches
- Only anchor truly new insights to memory
- For repos >1000 files, avoid uncompressed modes

## IMPORTANT
- When achoring and finding memories you must use a project specific keyword for all memories. The keywords must follow this specifc format `project:<project-name>`. This can be based on upstream repository name. It should only inlcude the name and not the full path (ie. "sample-project" not "github.com/sample-org/sample-project"). If the project is a github worktree use the base project name, not the worktree name.
