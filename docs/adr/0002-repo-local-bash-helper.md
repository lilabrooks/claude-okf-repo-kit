---
type: ADR
title: Repo-local Bash helper
description: Implement OKF helper commands as scripts/okf instead of a global CLI or prompt-only workflow.
tags: [bash, okf, tooling]
generated: { by: claude-code/fable-5, at: 2026-07-05T00:00:00Z }
owner: Lila Brooks
deciders: [Lila Brooks]
status: accepted
---

# Status

Accepted

# Context

The kit needs commands for stale mapping checks, draft spec generation, and ADR suggestions.

Users should be able to install the kit into arbitrary repos without a package manager, global CLI install, or runtime dependency setup.

# Decision

Implement the helper as `scripts/okf`, a repo-local Bash script.

Run it with:

```bash
bash scripts/okf check-stale
bash scripts/okf draft [paths...]
bash scripts/okf adr-suggest
```

# Consequences

The helper is portable across many repos and easy for Claude Code hooks to invoke.

It is deliberately not branded as an official OKF CLI.

Behavior should remain conservative and dependency-light. More advanced parsing can be added later only if the benefit outweighs the install complexity.
