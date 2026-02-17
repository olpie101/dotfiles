# Gas Town Routing System

Routing is handled automatically by the `gt`/`bd` CLI. Agents do not need to understand the internal routing mechanism. However, when creating a bead in a **different rig** from the current one, the agent must specify either the `--rig <name>` flag or use the correct prefix.

## Cross-Rig Bead Creation

```bash
# By rig name
bd create "Fix auth bug" -d "..." --rig nexus

# By prefix (prefix determines the target rig)
bd create "Fix auth bug" -d "..." --prefix nx
```

If neither `--rig` nor `--prefix` is provided, the bead is created in the current rig context.

## Prefix Semantics

| Prefix | Target | Description |
|--------|--------|-------------|
| `hq-` | Town (`.`) | Town-level/cross-cutting work |
| `hq-cv-` | Town (`.`) | Town-level convoys |
| `<rig>-` | Rig path | Project-specific work |
