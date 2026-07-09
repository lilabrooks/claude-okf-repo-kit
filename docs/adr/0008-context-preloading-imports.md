---
type: ADR
title: Context preloading via CLAUDE.md imports
description: Preload the goal file and spec/ADR indexes into every session with CLAUDE.md @ imports instead of instructed reads.
tags: [claude-code, context, imports, template]
timestamp: 2026-07-08T00:00:00Z
owner: Lila Brooks
deciders: [Lila Brooks]
---

# Status

Accepted

# Context

The installed `CLAUDE.md` told Claude Code to read `docs/GOAL.md` and the spec/ADR indexes at the start of each session. Instructed reads are discretionary: they cost a read step every session and can be skipped under pressure, which undermines the goal loop the kit exists to run. The owner asked for repo context to be in place at session start without re-reading files each time.

Claude Code supports `@path` imports in `CLAUDE.md`: an import line inlines the referenced file when `CLAUDE.md` loads, resolving recursively up to five hops. Content imported this way is guaranteed to be in context, not merely requested.

# Decision

`templates/CLAUDE.md` (and this repo's own `CLAUDE.md`, dogfooding it) carries a "Preloaded context" section importing exactly 3 files:

- `@docs/GOAL.md` — the goal and milestone backlog, always relevant, small by design
- `@docs/specs/index.md` — one line per spec, the survey layer
- `@docs/adr/index.md` — one line per ADR, the survey layer

The grounding instructions change to match: the indexes are already in context, and the read instruction now covers only the specific spec or ADR governing the files a task touches.

The import list is deliberately closed. `docs/log.md` (unbounded growth), `docs/okf-map.yml` (only relevant to the stale check, which reads it itself), full specs, ADRs, and code are not imported: preloading them burns context on content most tasks never need, and the index files already make them one cheap read away.

The new-repo install smoke test verifies the installed `CLAUDE.md` contains the 3 import lines.

Alternatives considered:

- Instructed reads (status quo). Rejected: discretionary and repeated per session; imports make the same context guaranteed and free.
- SessionStart hook injecting file contents as additional context. Rejected for static files: it duplicates what imports do with more machinery and output-size limits. Hooks remain the right tool for dynamic context, as with the OKF version check (ADR 0003).
- Importing the whole knowledge bundle or code summaries. Rejected: dilutes the context window and worsens task focus; progressive disclosure through indexes is the point of the bundle layout.

# Consequences

Every session starts with the goal, milestone state, and a map of the knowledge bundle in context, with no read calls and no reliance on instruction-following.

The imported files are paid for in every session's context budget, so their discipline now matters more: `docs/GOAL.md` stays a goal file rather than a design document, and the indexes stay one line per entry.

In a bootstrapped repo the imports do not resolve until the docs tree exists; the bootstrap section says so, and the structure created there fixes it from the next session on. Previously installed repos pick the imports up through the `CLAUDE.2.md` candidate flow of the existing-repo installer.
