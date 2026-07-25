---
type: ADR
title: Goal file template
description: Capture the target repo's goal and milestone backlog in an installed docs/GOAL.md.
tags: [goal, template, iteration]
generated: { by: claude-code/fable-5, at: 2026-07-07T00:00:00Z }
owner: Lila Brooks
deciders: [Lila Brooks]
status: accepted
---

# Status

Accepted

# Context

The kit's guide argues a goal Claude Code can iterate on needs current state, target state, constraints, and mechanically verifiable done criteria. The installed `CLAUDE.md` Master objective carries a one-screen version of that, but it has no room for an evolving milestone backlog, and rewriting `CLAUDE.md` every time a milestone lands churns the file that governs agent behavior.

Users want to define a clear goal for an app, service, or utility repo from a template at install time, then have Claude Code iterate toward it across sessions without re-explaining the goal.

# Decision

Add one install artifact, `templates/GOAL.md`, copied to target `docs/GOAL.md` by both installers.

- A single template serves all repo kinds. A `Kind: [app | service | utility]` field plus kind-specific hints replaces separate per-kind templates.
- `docs/GOAL.md` holds the durable goal definition: problem, target state, verifiable success criteria, non-goals, constraints, and an ordered milestone checklist.
- The milestone checklist is the iteration backlog. The installed `CLAUDE.md` instructs Claude Code to read `docs/GOAL.md` each session, take the first unchecked milestone when asked to continue without a specific task, check a milestone off only when its verification passes, and log progress in `docs/log.md`.
- The Master objective in `CLAUDE.md` stays the one-screen summary; `docs/GOAL.md` carries the detail. Changing the goal remains the owner's decision.
- The existing-repo installer treats `docs/GOAL.md` like other kit Markdown: never overwrite, write a numbered candidate on collision. As part of this change, all installer candidate writes skip files that already match the kit content byte for byte, so repeated updates stay idempotent for kit-created files.
- Starter `docs/index.md` files created by the installers link the goal file alongside specs and ADRs, keeping the bundle root index current.
- `verify-install` checks the file exists; `check-placeholders` reports its unfilled template placeholders.

# Consequences

Every installed repo starts with an explicit, verifiable goal file, so "continue" has a defined meaning for Claude Code across sessions.

`docs/GOAL.md` becomes part of the tested install contract: installers, verification helpers, placeholder checks, and smoke tests must stay in sync with it.

The goal appears in two places at different zoom levels. The `CLAUDE.md` instructions make `docs/GOAL.md` authoritative for detail, but users still own keeping the summary consistent.
