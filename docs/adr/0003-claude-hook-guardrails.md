---
type: ADR
title: Claude hook guardrails
description: Use Claude Code hooks to enforce docs sync and OKF version awareness.
tags: [claude-code, hooks, docs]
timestamp: 2026-07-05T00:00:00Z
owner: Lila Brooks
deciders: [Lila Brooks]
---

# Status

Accepted

# Context

The kit's purpose is to keep Claude Code grounded in specs, ADRs, and dated knowledge updates.

Prompt instructions alone are easy to miss at the end of a turn.

# Decision

Use Claude Code hooks:

- `Stop` runs `.claude/hooks/check-docs-sync.sh`
- `SessionStart` runs `.claude/hooks/check-okf-version.sh`

The Stop hook blocks missing docs updates and, when available, stale source-to-doc mappings through `scripts/okf check-stale`.

The SessionStart hook reports OKF version drift as additional context.

# Consequences

Claude Code gets a mechanical reminder before ending a turn with unsynchronized code and docs.

The hooks must be quiet when they cannot safely determine a problem.

The hooks must emit Claude Code-compatible JSON when blocking or injecting context.
